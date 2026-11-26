-- ProjectManagement ("TaskDB") upgrade script
-- Adds: subtasks (tblTask.intParentTaskID), task comments, task attachments,
--       task dependencies, project milestones, and dashboard reporting procs.
-- Safe to run more than once (guarded with existence checks / CREATE OR ALTER).
-- Does NOT touch any other database (HR DB is out of scope).
USE [ProjectManagement]
GO

-- ============================================================
-- 1. Subtasks: self-referencing parent task column
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tblTask') AND name = 'intParentTaskID')
BEGIN
	ALTER TABLE [dbo].[tblTask] ADD [intParentTaskID] [int] NULL
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_tblTask_tblTask_Parent')
BEGIN
	ALTER TABLE [dbo].[tblTask] WITH CHECK ADD CONSTRAINT [FK_tblTask_tblTask_Parent] FOREIGN KEY([intParentTaskID])
	REFERENCES [dbo].[tblTask] ([intTaskID])
	ALTER TABLE [dbo].[tblTask] CHECK CONSTRAINT [FK_tblTask_tblTask_Parent]
END
GO

-- ============================================================
-- 2. Task comments
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTaskComment')
BEGIN
	CREATE TABLE [dbo].[tblTaskComment](
		[intCommentID] [int] IDENTITY(1,1) NOT NULL,
		[intTaskID] [int] NOT NULL,
		[intUserID] [int] NOT NULL,
		[strComment] [varchar](max) NOT NULL,
		[dteCreated] [datetime] NOT NULL,
	 CONSTRAINT [PK_tblTaskComment] PRIMARY KEY CLUSTERED ([intCommentID] ASC)
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

	ALTER TABLE [dbo].[tblTaskComment] ADD CONSTRAINT [DF_tblTaskComment_dteCreated] DEFAULT (getdate()) FOR [dteCreated]

	ALTER TABLE [dbo].[tblTaskComment] WITH CHECK ADD CONSTRAINT [FK_tblTaskComment_tblTask] FOREIGN KEY([intTaskID])
	REFERENCES [dbo].[tblTask] ([intTaskID])
	ALTER TABLE [dbo].[tblTaskComment] CHECK CONSTRAINT [FK_tblTaskComment_tblTask]

	ALTER TABLE [dbo].[tblTaskComment] WITH CHECK ADD CONSTRAINT [FK_tblTaskComment_tblUser] FOREIGN KEY([intUserID])
	REFERENCES [dbo].[tblUser] ([intUserID])
	ALTER TABLE [dbo].[tblTaskComment] CHECK CONSTRAINT [FK_tblTaskComment_tblUser]

	CREATE NONCLUSTERED INDEX [IX_tblTaskComment_intTaskID] ON [dbo].[tblTaskComment] ([intTaskID])
END
GO

-- ============================================================
-- 3. Task attachments (metadata only — bytes live in the existing
--    external file API used elsewhere in this codebase)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTaskAttachment')
BEGIN
	CREATE TABLE [dbo].[tblTaskAttachment](
		[intAttachmentID] [int] IDENTITY(1,1) NOT NULL,
		[intTaskID] [int] NOT NULL,
		[intUserID] [int] NOT NULL,
		[strFileName] [varchar](500) NOT NULL,
		[strRemotePath] [varchar](max) NOT NULL,
		[strContentType] [varchar](200) NULL,
		[intSizeBytes] [bigint] NULL,
		[dteUploaded] [datetime] NOT NULL,
		[isActive] [bit] NOT NULL,
	 CONSTRAINT [PK_tblTaskAttachment] PRIMARY KEY CLUSTERED ([intAttachmentID] ASC)
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

	ALTER TABLE [dbo].[tblTaskAttachment] ADD CONSTRAINT [DF_tblTaskAttachment_dteUploaded] DEFAULT (getdate()) FOR [dteUploaded]
	ALTER TABLE [dbo].[tblTaskAttachment] ADD CONSTRAINT [DF_tblTaskAttachment_isActive] DEFAULT ((1)) FOR [isActive]

	ALTER TABLE [dbo].[tblTaskAttachment] WITH CHECK ADD CONSTRAINT [FK_tblTaskAttachment_tblTask] FOREIGN KEY([intTaskID])
	REFERENCES [dbo].[tblTask] ([intTaskID])
	ALTER TABLE [dbo].[tblTaskAttachment] CHECK CONSTRAINT [FK_tblTaskAttachment_tblTask]

	ALTER TABLE [dbo].[tblTaskAttachment] WITH CHECK ADD CONSTRAINT [FK_tblTaskAttachment_tblUser] FOREIGN KEY([intUserID])
	REFERENCES [dbo].[tblUser] ([intUserID])
	ALTER TABLE [dbo].[tblTaskAttachment] CHECK CONSTRAINT [FK_tblTaskAttachment_tblUser]

	CREATE NONCLUSTERED INDEX [IX_tblTaskAttachment_intTaskID] ON [dbo].[tblTaskAttachment] ([intTaskID])
END
GO

-- ============================================================
-- 4. Task dependencies ("blocked by")
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTaskDependency')
BEGIN
	CREATE TABLE [dbo].[tblTaskDependency](
		[intDependencyID] [int] IDENTITY(1,1) NOT NULL,
		[intTaskID] [int] NOT NULL,
		[intDependsOnTaskID] [int] NOT NULL,
		[dteCreated] [datetime] NOT NULL,
	 CONSTRAINT [PK_tblTaskDependency] PRIMARY KEY CLUSTERED ([intDependencyID] ASC),
	 CONSTRAINT [UQ_tblTaskDependency] UNIQUE ([intTaskID],[intDependsOnTaskID])
	) ON [PRIMARY]

	ALTER TABLE [dbo].[tblTaskDependency] ADD CONSTRAINT [DF_tblTaskDependency_dteCreated] DEFAULT (getdate()) FOR [dteCreated]

	ALTER TABLE [dbo].[tblTaskDependency] WITH CHECK ADD CONSTRAINT [FK_tblTaskDependency_tblTask] FOREIGN KEY([intTaskID])
	REFERENCES [dbo].[tblTask] ([intTaskID])
	ALTER TABLE [dbo].[tblTaskDependency] CHECK CONSTRAINT [FK_tblTaskDependency_tblTask]

	ALTER TABLE [dbo].[tblTaskDependency] WITH CHECK ADD CONSTRAINT [FK_tblTaskDependency_tblTask_DependsOn] FOREIGN KEY([intDependsOnTaskID])
	REFERENCES [dbo].[tblTask] ([intTaskID])
	ALTER TABLE [dbo].[tblTaskDependency] CHECK CONSTRAINT [FK_tblTaskDependency_tblTask_DependsOn]

	ALTER TABLE [dbo].[tblTaskDependency] WITH CHECK ADD CONSTRAINT [CK_tblTaskDependency_NoSelf] CHECK ([intTaskID] <> [intDependsOnTaskID])

	CREATE NONCLUSTERED INDEX [IX_tblTaskDependency_intTaskID] ON [dbo].[tblTaskDependency] ([intTaskID])
	CREATE NONCLUSTERED INDEX [IX_tblTaskDependency_intDependsOnTaskID] ON [dbo].[tblTaskDependency] ([intDependsOnTaskID])
END
GO

-- ============================================================
-- 5. Project milestones
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblMilestone')
BEGIN
	CREATE TABLE [dbo].[tblMilestone](
		[intMilestoneID] [int] IDENTITY(1,1) NOT NULL,
		[intProjectID] [int] NOT NULL,
		[strName] [varchar](300) NOT NULL,
		[dteDate] [date] NOT NULL,
		[isCompleate] [bit] NOT NULL,
		[dteCreated] [datetime] NOT NULL,
	 CONSTRAINT [PK_tblMilestone] PRIMARY KEY CLUSTERED ([intMilestoneID] ASC)
	) ON [PRIMARY]

	ALTER TABLE [dbo].[tblMilestone] ADD CONSTRAINT [DF_tblMilestone_isCompleate] DEFAULT ((0)) FOR [isCompleate]
	ALTER TABLE [dbo].[tblMilestone] ADD CONSTRAINT [DF_tblMilestone_dteCreated] DEFAULT (getdate()) FOR [dteCreated]

	ALTER TABLE [dbo].[tblMilestone] WITH CHECK ADD CONSTRAINT [FK_tblMilestone_tblProject] FOREIGN KEY([intProjectID])
	REFERENCES [dbo].[tblProject] ([intProjectID])
	ALTER TABLE [dbo].[tblMilestone] CHECK CONSTRAINT [FK_tblMilestone_tblProject]

	CREATE NONCLUSTERED INDEX [IX_tblMilestone_intProjectID] ON [dbo].[tblMilestone] ([intProjectID])
END
GO

-- ============================================================
-- 6. Comments procs
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
		set @Msg='Comment Added Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetTaskComments]
	@TaskID int
AS
BEGIN
	select c.intCommentID, c.intTaskID, c.intUserID, u.strUserName, c.strComment, c.dteCreated
	from ProjectManagement.dbo.tblTaskComment c
	inner join ProjectManagement.dbo.tblUser u on u.intUserID=c.intUserID
	where c.intTaskID=@TaskID
	order by c.dteCreated asc
END
GO

-- ============================================================
-- 7. Attachment procs
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprAddTaskAttachment]
	@TaskID int,
	@Enroll int,
	@FileName varchar(500),
	@RemotePath varchar(max),
	@ContentType varchar(200),
	@SizeBytes bigint,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		insert into [ProjectManagement].[dbo].[tblTaskAttachment] (intTaskID, intUserID, strFileName, strRemotePath, strContentType, intSizeBytes)
		values (@TaskID, @Enroll, @FileName, @RemotePath, @ContentType, @SizeBytes)
		declare @Details varchar(MAX)='Attachment added to Task ID - '+cast(@TaskID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Insert', 'Task Attachment', @Details, @Enroll
		set @Msg='Attachment Uploaded Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetTaskAttachments]
	@TaskID int
AS
BEGIN
	select a.intAttachmentID, a.intTaskID, a.intUserID, u.strUserName, a.strFileName, a.strRemotePath, a.strContentType, a.intSizeBytes, a.dteUploaded
	from ProjectManagement.dbo.tblTaskAttachment a
	inner join ProjectManagement.dbo.tblUser u on u.intUserID=a.intUserID
	where a.intTaskID=@TaskID and a.isActive=1
	order by a.dteUploaded desc
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprDeleteTaskAttachment]
	@AttachmentID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		update [ProjectManagement].[dbo].[tblTaskAttachment] set isActive=0 where intAttachmentID=@AttachmentID
		declare @Details varchar(MAX)='Attachment Removed ID - '+cast(@AttachmentID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Update', 'Task Attachment Remove', @Details, @Enroll
		set @Msg='Attachment Removed Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

-- ============================================================
-- 8. Subtask procs
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprCreateSubtask]
	@Name Varchar(max),
	@Description Varchar(max),
	@ParentTaskID int,
	@Priroty int,
	@DeadLine date,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		Declare @Project int, @ParentName varchar(500)
		select top 1 @Project=intProjectID, @ParentName=strTaskName from ProjectManagement.dbo.tblTask where intTaskID=@ParentTaskID
		if(@Project is null)
		Begin
			set @Msg='Parent task not found!!!'
		End
		Else
		Begin
			Declare @intPk int
			Insert into ProjectManagement.dbo.tblTask (strTaskName, strDescription, strRequestFrom, intPriroty, dteDeadLine, intUserID, intProjectID, intParentTaskID)
			values(@Name, @Description, @ParentName, @Priroty, @DeadLine, @Enroll, @Project, @ParentTaskID)
			set @intPk= SCOPE_IDENTITY()
			Insert into ProjectManagement.dbo.tblTaskDetail (intTaskID, intUserID, intStatusID, tmWorking)
			Values (@intPk, @Enroll, 2, '00:00:00')
			declare @Details varchar(MAX)='New Subtask Created ID - '+cast(@intPk as varchar(100))+' under Task - '+cast(@ParentTaskID as varchar(100))
			EXEC ProjectManagement.dbo.sprLog 'Insert', 'Subtask Create', @Details, @Enroll
			set @Msg='Subtask Created Successfully'
		End
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetSubtasksByTask]
	@ParentTaskID int
AS
BEGIN
	select t.intTaskID, t.strTaskName, t.strDescription, t.intPriroty, t.dteDeadLine, td.tmWorking, td.intStatusID, s.strStatus
	from ProjectManagement.dbo.tblTask t
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblStatus s on s.intStatusID=td.intStatusID
	where t.intParentTaskID=@ParentTaskID
	order by t.intTaskID
END
GO

-- ============================================================
-- 9. Dependency procs
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetTasksForDependencyPicker]
	@TaskID int
AS
BEGIN
	DECLARE @ProjectID int = (SELECT TOP 1 intProjectID FROM ProjectManagement.dbo.tblTask WHERE intTaskID=@TaskID)
	-- Only still-actionable tasks (1=Current,2=Pending,3=OnHold,4=Review) are valid blockers --
	-- depending on something already Complete/Removed/Meeting/Emergency Support is meaningless.
	SELECT t.intTaskID, t.strTaskName, t.strDescription, t.intPriroty, t.dteDeadLine, td.tmWorking, td.intStatusID, s.strStatus
	FROM ProjectManagement.dbo.tblTask t
	INNER JOIN ProjectManagement.dbo.tblTaskDetail td ON td.intTaskID = t.intTaskID
	INNER JOIN ProjectManagement.dbo.tblStatus s ON s.intStatusID = td.intStatusID
	WHERE t.intProjectID = @ProjectID AND t.intTaskID <> @TaskID AND td.intStatusID IN (1,2,3,4)
	ORDER BY t.intTaskID DESC
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprAddTaskDependency]
	@TaskID int,
	@DependsOnTaskID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		IF(@TaskID=@DependsOnTaskID)
		Begin
			set @Msg='A task cannot depend on itself!!!'
		End
		ELSE IF EXISTS(select * from ProjectManagement.dbo.tblTaskDependency where intTaskID=@TaskID and intDependsOnTaskID=@DependsOnTaskID)
		Begin
			set @Msg='This dependency already exists!!!'
		End
		ELSE IF EXISTS(select * from ProjectManagement.dbo.tblTaskDependency where intTaskID=@DependsOnTaskID and intDependsOnTaskID=@TaskID)
		Begin
			set @Msg='This would create a circular dependency!!!'
		End
		ELSE
		Begin
			insert into [ProjectManagement].[dbo].[tblTaskDependency] (intTaskID, intDependsOnTaskID)
			values (@TaskID, @DependsOnTaskID)
			declare @Details varchar(MAX)='Task - '+cast(@TaskID as varchar(100))+' now depends on Task - '+cast(@DependsOnTaskID as varchar(100))
			EXEC ProjectManagement.dbo.sprLog 'Insert', 'Task Dependency', @Details, @Enroll
			set @Msg='Dependency Added Successfully'
		End
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprRemoveTaskDependency]
	@DependencyID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		delete from [ProjectManagement].[dbo].[tblTaskDependency] where intDependencyID=@DependencyID
		declare @Details varchar(MAX)='Dependency Removed ID - '+cast(@DependencyID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Delete', 'Task Dependency Remove', @Details, @Enroll
		set @Msg='Dependency Removed Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetTaskDependencies]
	@TaskID int
AS
BEGIN
	select d.intDependencyID, d.intTaskID, d.intDependsOnTaskID, t.strTaskName as strDependsOnTaskName, s.strStatus, td.intStatusID
	from ProjectManagement.dbo.tblTaskDependency d
	inner join ProjectManagement.dbo.tblTask t on t.intTaskID=d.intDependsOnTaskID
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblStatus s on s.intStatusID=td.intStatusID
	where d.intTaskID=@TaskID
	order by d.intDependencyID
END
GO

-- ============================================================
-- 10. Milestone procs
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprCreateMilestone]
	@ProjectID int,
	@Name varchar(300),
	@Date date,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		insert into [ProjectManagement].[dbo].[tblMilestone] (intProjectID, strName, dteDate)
		values (@ProjectID, @Name, @Date)
		declare @Details varchar(MAX)='Milestone Created for Project - '+cast(@ProjectID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Insert', 'Milestone Create', @Details, @Enroll
		set @Msg='Milestone Created Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetMilestonesByProject]
	@ProjectID int
AS
BEGIN
	select intMilestoneID, intProjectID, strName, dteDate, isCompleate
	from ProjectManagement.dbo.tblMilestone
	where intProjectID=@ProjectID
	order by dteDate
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprToggleMilestone]
	@MilestoneID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		Declare @Current bit = (select top 1 isCompleate from ProjectManagement.dbo.tblMilestone where intMilestoneID=@MilestoneID)
		update [ProjectManagement].[dbo].[tblMilestone] set isCompleate = case when @Current=1 then 0 else 1 end where intMilestoneID=@MilestoneID
		declare @Details varchar(MAX)='Milestone Toggled ID - '+cast(@MilestoneID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Update', 'Milestone Toggle', @Details, @Enroll
		set @Msg='Milestone Updated Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprDeleteMilestone]
	@MilestoneID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		delete from [ProjectManagement].[dbo].[tblMilestone] where intMilestoneID=@MilestoneID
		declare @Details varchar(MAX)='Milestone Removed ID - '+cast(@MilestoneID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Delete', 'Milestone Remove', @Details, @Enroll
		set @Msg='Milestone Removed Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

-- ============================================================
-- 11. Dashboard procs (team-scoped: @Enroll is the supervisor if
--     they have one in tblTeam, otherwise falls back to their own tasks)
-- ============================================================
-- Meeting (7) and Emergency Support (8) are rolled into the Complete (5) bucket here -- they're
-- terminal/closed activity-log entries (see note above sprGetWorkloadByTeam), not an ongoing
-- status a user would want broken out as its own slice on the status chart.
CREATE OR ALTER PROCEDURE [dbo].[sprGetDashboardSummary]
	@Enroll int
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
	group by CASE WHEN s.intStatusID IN (7,8) THEN 5 ELSE s.intStatusID END,
	         CASE WHEN s.intStatusID IN (7,8) THEN 'Complete' ELSE s.strStatus END
	order by 1
END
GO

-- Note: 5=Complete, 6=Removed are the normal terminal statuses; 7=Meeting and 8=Emergency
-- Support are also terminal in practice (sprRequetAction converts an approved ad-hoc request
-- into a task permanently parked at status 7/8 with dteDeadLine copied from its creation date,
-- so it can never reach 5/6 and would otherwise look perpetually overdue/incomplete) -- treated
-- as closed here alongside 5/6.
CREATE OR ALTER PROCEDURE [dbo].[sprGetWorkloadByTeam]
	@Enroll int
AS
BEGIN
	select u.intUserID, u.strUserName, count(td.intTaskDetail) as OpenTaskCount
	from ProjectManagement.dbo.tblUser u
	inner join ProjectManagement.dbo.tblTeam tm on tm.intTeamID=u.intTeamID
	left join ProjectManagement.dbo.tblTaskDetail td on td.intUserID=u.intUserID and td.intStatusID not in (5,6,7,8)
	where tm.intUserID=@Enroll and u.isActive=1
	group by u.intUserID, u.strUserName
	order by OpenTaskCount desc
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetOverdueTasks]
	@Enroll int
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
	@Enroll int
AS
BEGIN
	select p.intProjectID, p.strProjectName,
		count(t.intTaskID) as TotalTasks,
		isnull(sum(case when td.intStatusID in (5,6,7,8) then 1 else 0 end), 0) as DoneTasks
	from ProjectManagement.dbo.tblProject p
	left join ProjectManagement.dbo.tblTask t on t.intProjectID=p.intProjectID
	left join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	where p.isActive=1
	  and (
		p.intTeamID in (select intTeamID from ProjectManagement.dbo.tblTeam where intUserID=@Enroll)
		or exists (select 1 from ProjectManagement.dbo.tblProjectAssign a where a.intProjectID=p.intProjectID and a.intUserID=@Enroll and a.isActive=1)
	  )
	group by p.intProjectID, p.strProjectName
	order by p.intProjectID
END
GO

-- ============================================================
-- 12. Dependency-aware completion guard in the existing task-status proc
--     (adds a check before Status=5/Complete; preserves all existing behavior)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprtaskManager]
	@Type int,
	@TaskID int,
	@User int,
	@Status int,
	@tmTime time,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
BEGIN TRANSACTION;
	BEGIN TRY

	Declare @Details varchar(max)
	Declare @NewTime time = (select top 1 tmWorking from ProjectManagement.dbo.tblTaskDetail where intTaskID=@TaskID)
	set @NewTime= convert(time,convert(datetime,@NewTime)+convert(datetime,@tmTime))
	IF(@Type=0) --Status and time Update
	Begin
		if exists(select * from ProjectManagement.dbo.tblTaskDetail where intStatusID=1 and intUserID=@Enroll and intTaskID!=@TaskID and @Status=1)
		Begin
			set @Msg='Please finish the current task at hand!!!'
		End
		Else if (@Status=5 and exists(
			select 1
			from ProjectManagement.dbo.tblTaskDependency d
			inner join ProjectManagement.dbo.tblTaskDetail dtd on dtd.intTaskID=d.intDependsOnTaskID
			where d.intTaskID=@TaskID and dtd.intStatusID not in (5,6)
		))
		Begin
			Declare @BlockCount int = (
				select count(*)
				from ProjectManagement.dbo.tblTaskDependency d
				inner join ProjectManagement.dbo.tblTaskDetail dtd on dtd.intTaskID=d.intDependsOnTaskID
				where d.intTaskID=@TaskID and dtd.intStatusID not in (5,6)
			)
			set @Msg='Cannot complete: blocked by '+cast(@BlockCount as varchar(20))+' incomplete task(s).'
		End
		Else
		Begin
			Update  ProjectManagement.dbo.tblTaskDetail set tmWorking=@NewTime, intStatusID=@Status where intTaskID=@TaskID
			exec ProjectManagement.dbo.sprWorkLog @Enroll, @tmTime, @Status, @TaskID
			set @Details='Task Status Change ID- '+cast(@TaskID as varchar(100))
			EXEC ProjectManagement.dbo.sprLog 'Update', 'Status and Time Change', @Details, @Enroll
			set @Msg='Status Updated Successfully.'
		End
	End
	Else IF(@Type=1) --Transfer and time Update
	Begin
		Update  ProjectManagement.dbo.tblTaskDetail set tmWorking=@NewTime, intStatusID=2, intUserID=@User where intTaskID=@TaskID
		exec ProjectManagement.dbo.sprWorkLog @Enroll, @tmTime, 2, @TaskID
		set @Details='Task Transfer ID- '+cast(@TaskID as varchar(100))+' Transfer to -'+cast(@User as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Update', 'Status, Transfer and Time Change', @Details, @Enroll
		set @Msg='Task Transfer Successfully.'
		Declare @TaskName varchar(500)=(select top 1 strTaskName from ProjectManagement.dbo.tblTask where intTaskID=@TaskID)
		Declare @Notify varchar(MAX) =@TaskName+' Transfered to you.'
		exec dbo.sprNotify @User, @Notify
	End

	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
        ROLLBACK TRANSACTION;
        set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH;
END
GO
