-- ============================================================
-- Script 6: Global Search, @Mentions in comments, Full Calendar
-- Additive only (CREATE OR ALTER / existence checks) -- safe to re-run.
-- ============================================================

-- ============================================================
-- 1. Global Search
--    Scoped the same way as the Dashboard procs: a boss sees their
--    team's results, a regular user sees only their own.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGlobalSearch]
	@Enroll int,
	@Keyword varchar(200)
AS
BEGIN
	DECLARE @ScopeUsers TABLE (intUserID int PRIMARY KEY)
	INSERT INTO @ScopeUsers
		select u.intUserID from ProjectManagement.dbo.tblUser u
		inner join ProjectManagement.dbo.tblTeam tm on tm.intTeamID=u.intTeamID
		where tm.intUserID=@Enroll
		union
		select @Enroll

	DECLARE @Like varchar(204) = '%' + @Keyword + '%'

	-- Id is the underlying row's OWN primary key (never the task id it belongs to) so that
	-- (ResultType, Id) is always unique -- several comments/attachments can point at the same
	-- task, and reusing the task id here would collide in EF's identity map and silently drop
	-- rows. TaskID is reported separately for anything that needs to point back at a task.
	select 'Task' as ResultType, t.intTaskID as Id, t.intTaskID as TaskID, t.strTaskName as Title,
		LEFT(ISNULL(t.strDescription,''), 160) as Snippet, p.strProjectName as ProjectName,
		s.strStatus as ExtraInfo, CAST(t.dteDeadLine as datetime) as SortDate
	from ProjectManagement.dbo.tblTask t
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
	inner join ProjectManagement.dbo.tblStatus s on s.intStatusID=td.intStatusID
	where td.intUserID in (select intUserID from @ScopeUsers)
	  and (t.strTaskName like @Like or t.strDescription like @Like)

	UNION ALL

	select 'Project' as ResultType, p.intProjectID as Id, CAST(NULL as int) as TaskID, p.strProjectName as Title,
		CAST(NULL as varchar(160)) as Snippet, p.strProjectName as ProjectName,
		CAST(NULL as varchar(500)) as ExtraInfo, p.dteCreated as SortDate
	from ProjectManagement.dbo.tblProject p
	where p.strProjectName like @Like
	  and EXISTS (
		select 1 from ProjectManagement.dbo.tblTask t2
		inner join ProjectManagement.dbo.tblTaskDetail td2 on td2.intTaskID=t2.intTaskID
		where t2.intProjectID=p.intProjectID and td2.intUserID in (select intUserID from @ScopeUsers)
	  )

	UNION ALL

	select 'Comment' as ResultType, c.intCommentID as Id, c.intTaskID as TaskID, t.strTaskName as Title,
		LEFT(c.strComment,160) as Snippet, p.strProjectName as ProjectName,
		u.strUserName as ExtraInfo, c.dteCreated as SortDate
	from ProjectManagement.dbo.tblTaskComment c
	inner join ProjectManagement.dbo.tblTask t on t.intTaskID=c.intTaskID
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
	inner join ProjectManagement.dbo.tblUser u on u.intUserID=c.intUserID
	where td.intUserID in (select intUserID from @ScopeUsers)
	  and c.strComment like @Like

	UNION ALL

	select 'Attachment' as ResultType, a.intAttachmentID as Id, a.intTaskID as TaskID, t.strTaskName as Title,
		a.strFileName as Snippet, p.strProjectName as ProjectName,
		u.strUserName as ExtraInfo, a.dteUploaded as SortDate
	from ProjectManagement.dbo.tblTaskAttachment a
	inner join ProjectManagement.dbo.tblTask t on t.intTaskID=a.intTaskID
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
	inner join ProjectManagement.dbo.tblUser u on u.intUserID=a.intUserID
	where td.intUserID in (select intUserID from @ScopeUsers)
	  and a.strFileName like @Like and a.isActive=1

	order by SortDate desc
END
GO

-- ============================================================
-- 2. @Mentions: notify a teammate when "@TheirName" appears in a comment.
--    Reuses the existing sprNotify (no new notification plumbing needed).
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprAddTaskComment]
	@TaskID int,
	@Enroll int,
	@Comment varchar(max),
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		insert into [ProjectManagement].[dbo].[tblTaskComment] (intTaskID, intUserID, strComment)
		values (@TaskID, @Enroll, @Comment)
		declare @Details varchar(MAX)='Comment added to Task ID - '+cast(@TaskID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Insert', 'Task Comment', @Details, @Enroll

		DECLARE @TaskName varchar(500) = (SELECT TOP 1 strTaskName FROM ProjectManagement.dbo.tblTask WHERE intTaskID=@TaskID)
		DECLARE @FromName varchar(500) = (SELECT TOP 1 strUserName FROM ProjectManagement.dbo.tblUser WHERE intUserID=@Enroll)
		DECLARE @MyTeam int = (SELECT TOP 1 intTeamID FROM ProjectManagement.dbo.tblUser WHERE intUserID=@Enroll)
		DECLARE @MentionUserID int, @MentionName varchar(500)
		DECLARE mention_cursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT intUserID, strUserName FROM ProjectManagement.dbo.tblUser
			WHERE intTeamID=@MyTeam AND intUserID<>@Enroll AND isActive=1
		OPEN mention_cursor
		FETCH NEXT FROM mention_cursor INTO @MentionUserID, @MentionName
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF CHARINDEX('@' + @MentionName, @Comment) > 0
			BEGIN
				DECLARE @NotifyMsg varchar(max) = @FromName + ' mentioned you in a comment on "' + @TaskName + '": ' + LEFT(@Comment, 150)
				EXEC ProjectManagement.dbo.sprNotify @MentionUserID, @NotifyMsg
			END
			FETCH NEXT FROM mention_cursor INTO @MentionUserID, @MentionName
		END
		CLOSE mention_cursor
		DEALLOCATE mention_cursor

		set @Msg='Comment Added Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		IF CURSOR_STATUS('local','mention_cursor') >= 0
		BEGIN
			CLOSE mention_cursor
			DEALLOCATE mention_cursor
		END
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetTeammates]
	@Enroll int
AS
BEGIN
	DECLARE @MyTeam int = (SELECT TOP 1 intTeamID FROM ProjectManagement.dbo.tblUser WHERE intUserID = @Enroll)
	SELECT intUserID, strUserName
	FROM ProjectManagement.dbo.tblUser
	WHERE intTeamID = @MyTeam AND intUserID <> @Enroll AND isActive = 1
	ORDER BY strUserName
END
GO

-- ============================================================
-- 3. Full calendar: every in-scope task's deadline in a date range
--    (same @ScopeUsers pattern as the Dashboard/Overdue procs).
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetCalendarTasks]
	@Enroll int,
	@From date,
	@To date
AS
BEGIN
	DECLARE @ScopeUsers TABLE (intUserID int PRIMARY KEY)
	INSERT INTO @ScopeUsers
		select u.intUserID from ProjectManagement.dbo.tblUser u
		inner join ProjectManagement.dbo.tblTeam tm on tm.intTeamID=u.intTeamID
		where tm.intUserID=@Enroll
		union
		select @Enroll

	select t.intTaskID, t.strTaskName, p.strProjectName, t.dteDeadLine, td.intStatusID, s.strStatus, u.strUserName
	from ProjectManagement.dbo.tblTask t
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
	inner join ProjectManagement.dbo.tblStatus s on s.intStatusID=td.intStatusID
	inner join ProjectManagement.dbo.tblUser u on u.intUserID=td.intUserID
	where td.intUserID in (select intUserID from @ScopeUsers)
	  and td.intStatusID <> 6
	  and t.dteDeadLine between @From and @To
	order by t.dteDeadLine, t.intPriroty desc
END
GO
