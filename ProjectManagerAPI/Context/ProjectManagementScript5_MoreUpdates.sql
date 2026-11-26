-- ProjectManagement ("TaskDB") upgrade script 5
-- Adds: label filtering on the task board, a project filter on the dashboard procs,
-- an activity-log feed, and an upcoming-milestones feed.
-- Safe to run more than once (CREATE OR ALTER throughout). Does NOT touch any other database.
USE [ProjectManagement]
GO

-- ============================================================
-- 1. Label filter on the task board (optional @LabelID, default 0 = no filter;
--    fully backward compatible with every existing caller)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetTaskByUser]
	@User int,
	@Status int,
	@LabelID int = 0
AS
BEGIN
	IF(@Status=5)
	Begin
		with WLog AS(
			select intTaskID, MAX(dteInsert) as LastWorkTime
			from ProjectManagement.dbo.tblWorkLog
			group by intTaskID
			)
		select t.intTaskID, t.strTaskName, t.strDescription, t.strRequestFrom, t.intPriroty, t.dteDeadLine, td.tmWorking, CAST(DATEDIFF(DAY, t.dteCreated, GETDATE()) AS VARCHAR) + ' days ' + CAST(DATEDIFF(HOUR, t.dteCreated, GETDATE()) % 24 AS VARCHAR) + ' hours' AS Agging, p.strProjectName
		from ProjectManagement.dbo.tblTaskDetail td
		inner join ProjectManagement.dbo.tblTask t on t.intTaskID=td.intTaskID
		inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
		inner join WLog on WLog.intTaskID=t.intTaskID
		where td.intUserID=@User and td.intStatusID=@Status and WLog.LastWorkTime between DATEADD(MONTH,-1,GETDATE()) and GETDATE()
		  and (@LabelID = 0 OR EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblTaskLabel tl WHERE tl.intTaskID = t.intTaskID AND tl.intLabelID = @LabelID))
		order by WLog.LastWorkTime desc
	End
	Else
	Begin
		select t.intTaskID, t.strTaskName, t.strDescription, t.strRequestFrom, t.intPriroty, t.dteDeadLine, td.tmWorking, CAST(DATEDIFF(DAY, t.dteCreated, GETDATE()) AS VARCHAR) + ' days ' + CAST(DATEDIFF(HOUR, t.dteCreated, GETDATE()) % 24 AS VARCHAR) + ' hours' AS Agging, p.strProjectName
		from ProjectManagement.dbo.tblTaskDetail td
		inner join ProjectManagement.dbo.tblTask t on t.intTaskID=td.intTaskID
		inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
		where td.intUserID=@User and td.intStatusID=@Status
		  and (@LabelID = 0 OR EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblTaskLabel tl WHERE tl.intTaskID = t.intTaskID AND tl.intLabelID = @LabelID))
		order by t.intPriroty desc, t.dteDeadLine, t.intTaskID
	End
END
GO

-- ============================================================
-- 2. Dashboard project filter (optional @ProjectID, default 0 = no filter;
--    same backward-compatibility guarantee)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetDashboardSummary]
	@Enroll int,
	@ProjectID int = 0
AS
BEGIN
	DECLARE @ScopeUsers TABLE (intUserID int PRIMARY KEY)
	INSERT INTO @ScopeUsers
		select u.intUserID from ProjectManagement.dbo.tblUser u
		inner join ProjectManagement.dbo.tblTeam tm on tm.intTeamID=u.intTeamID
		where tm.intUserID=@Enroll
		union
		select @Enroll

	select
		CASE WHEN s.intStatusID IN (7,8) THEN 5 ELSE s.intStatusID END AS intStatusID,
		CASE WHEN s.intStatusID IN (7,8) THEN 'Complete' ELSE s.strStatus END AS strStatus,
		count(td.intTaskDetail) as TaskCount
	from ProjectManagement.dbo.tblStatus s
	left join ProjectManagement.dbo.tblTaskDetail td on td.intStatusID=s.intStatusID
		and td.intUserID in (select intUserID from @ScopeUsers)
		and (@ProjectID = 0 OR EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblTask t WHERE t.intTaskID = td.intTaskID AND t.intProjectID = @ProjectID))
	group by CASE WHEN s.intStatusID IN (7,8) THEN 5 ELSE s.intStatusID END,
	         CASE WHEN s.intStatusID IN (7,8) THEN 'Complete' ELSE s.strStatus END
	order by 1
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetWorkloadByTeam]
	@Enroll int,
	@ProjectID int = 0
AS
BEGIN
	select u.intUserID, u.strUserName, count(td.intTaskDetail) as OpenTaskCount
	from ProjectManagement.dbo.tblUser u
	inner join ProjectManagement.dbo.tblTeam tm on tm.intTeamID=u.intTeamID
	left join ProjectManagement.dbo.tblTaskDetail td on td.intUserID=u.intUserID and td.intStatusID not in (5,6,7,8)
		and (@ProjectID = 0 OR EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblTask t WHERE t.intTaskID = td.intTaskID AND t.intProjectID = @ProjectID))
	where tm.intUserID=@Enroll and u.isActive=1
	group by u.intUserID, u.strUserName
	order by OpenTaskCount desc
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetOverdueTasks]
	@Enroll int,
	@ProjectID int = 0
AS
BEGIN
	select t.intTaskID, t.strTaskName, t.dteDeadLine, p.strProjectName, u.strUserName, s.strStatus
	from ProjectManagement.dbo.tblTask t
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
	inner join ProjectManagement.dbo.tblUser u on u.intUserID=td.intUserID
	inner join ProjectManagement.dbo.tblStatus s on s.intStatusID=td.intStatusID
	where t.dteDeadLine < CAST(GETDATE() as date)
	  and td.intStatusID not in (5,6,7,8)
	  and (@ProjectID = 0 OR t.intProjectID = @ProjectID)
	  and td.intUserID in (
		select u2.intUserID from ProjectManagement.dbo.tblUser u2
		inner join ProjectManagement.dbo.tblTeam tm on tm.intTeamID=u2.intTeamID
		where tm.intUserID=@Enroll
		union
		select @Enroll
	  )
	order by t.dteDeadLine
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetProjectProgress]
	@Enroll int,
	@ProjectID int = 0
AS
BEGIN
	select p.intProjectID, p.strProjectName,
		count(t.intTaskID) as TotalTasks,
		isnull(sum(case when td.intStatusID in (5,6,7,8) then 1 else 0 end), 0) as DoneTasks
	from ProjectManagement.dbo.tblProject p
	left join ProjectManagement.dbo.tblTask t on t.intProjectID=p.intProjectID
	left join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	where p.isActive=1
	  and (@ProjectID = 0 OR p.intProjectID = @ProjectID)
	  and (
		p.intTeamID in (select intTeamID from ProjectManagement.dbo.tblTeam where intUserID=@Enroll)
		or exists (select 1 from ProjectManagement.dbo.tblProjectAssign a where a.intProjectID=p.intProjectID and a.intUserID=@Enroll and a.isActive=1)
	  )
	group by p.intProjectID, p.strProjectName
	order by p.intProjectID
END
GO

-- ============================================================
-- 3. Activity log viewer (Admin-only in the UI; this proc itself has no
--    scoping since the audit trail is a global admin concern)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetActivityLog]
	@From datetime = NULL,
	@To datetime = NULL
AS
BEGIN
	SELECT TOP 300 al.intActivityID, al.strType, al.strProcess, al.strDescription, al.dteAction, u.strUserName
	FROM ProjectManagement.dbo.tblActivityLog al
	INNER JOIN ProjectManagement.dbo.tblUser u ON u.intUserID = al.intActionBy
	WHERE (@From IS NULL OR al.dteAction >= @From)
	  AND (@To IS NULL OR al.dteAction <= @To)
	ORDER BY al.dteAction DESC
END
GO

-- ============================================================
-- 4. Upcoming milestones feed (same team-boss-or-assigned scope as
--    sprGetProjectProgress, so it works for both a TL and a regular member)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetUpcomingMilestones]
	@Enroll int
AS
BEGIN
	SELECT m.intMilestoneID, m.strName, m.dteDate, m.isCompleate, p.strProjectName, p.intProjectID
	FROM ProjectManagement.dbo.tblMilestone m
	INNER JOIN ProjectManagement.dbo.tblProject p ON p.intProjectID = m.intProjectID
	WHERE p.isActive = 1
	  AND (
		p.intTeamID IN (SELECT intTeamID FROM ProjectManagement.dbo.tblTeam WHERE intUserID = @Enroll)
		OR EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblProjectAssign a WHERE a.intProjectID = p.intProjectID AND a.intUserID = @Enroll AND a.isActive = 1)
	  )
	ORDER BY m.isCompleate ASC, m.dteDate ASC
END
GO

-- ============================================================
-- 5. Team Activity ("what is everyone on my team working on right now")
--    Scoped to the caller's OWN team (tblUser.intTeamID), not "teams I manage" --
--    this is peer visibility for any team member, not a boss-only report.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetTeamActivity]
	@Enroll int
AS
BEGIN
	DECLARE @MyTeam int = (SELECT TOP 1 intTeamID FROM ProjectManagement.dbo.tblUser WHERE intUserID = @Enroll)

	SELECT u.intUserID, u.strUserName,
		t.intTaskID, t.strTaskName, p.strProjectName,
		(SELECT COUNT(*) FROM ProjectManagement.dbo.tblTaskDetail td2 WHERE td2.intUserID = u.intUserID AND td2.intStatusID = 2) AS PendingCount
	FROM ProjectManagement.dbo.tblUser u
	LEFT JOIN ProjectManagement.dbo.tblTaskDetail td ON td.intUserID = u.intUserID AND td.intStatusID = 1
	LEFT JOIN ProjectManagement.dbo.tblTask t ON t.intTaskID = td.intTaskID
	LEFT JOIN ProjectManagement.dbo.tblProject p ON p.intProjectID = t.intProjectID
	WHERE u.intTeamID = @MyTeam AND u.isActive = 1
	ORDER BY u.strUserName
END
GO
