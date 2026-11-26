-- ProjectManagement ("TaskDB") upgrade script 4
-- Adds: labels/tags, offboarding/bulk-task tooling, and a project timeline (Gantt-style) feed.
-- Safe to run more than once (guarded with existence checks / CREATE OR ALTER).
-- Does NOT touch any other database (HR DB is out of scope).
USE [ProjectManagement]
GO

-- ============================================================
-- 1. Labels / tags
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblLabel')
BEGIN
	CREATE TABLE [dbo].[tblLabel](
		[intLabelID] [int] IDENTITY(1,1) NOT NULL,
		[strName] [varchar](100) NOT NULL,
		[strColor] [varchar](20) NOT NULL,
		[isActive] [bit] NOT NULL,
	 CONSTRAINT [PK_tblLabel] PRIMARY KEY CLUSTERED ([intLabelID] ASC),
	 CONSTRAINT [UQ_tblLabel_strName] UNIQUE ([strName])
	) ON [PRIMARY]

	ALTER TABLE [dbo].[tblLabel] ADD CONSTRAINT [DF_tblLabel_isActive] DEFAULT ((1)) FOR [isActive]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTaskLabel')
BEGIN
	CREATE TABLE [dbo].[tblTaskLabel](
		[intTaskLabelID] [int] IDENTITY(1,1) NOT NULL,
		[intTaskID] [int] NOT NULL,
		[intLabelID] [int] NOT NULL,
	 CONSTRAINT [PK_tblTaskLabel] PRIMARY KEY CLUSTERED ([intTaskLabelID] ASC),
	 CONSTRAINT [UQ_tblTaskLabel] UNIQUE ([intTaskID],[intLabelID])
	) ON [PRIMARY]

	ALTER TABLE [dbo].[tblTaskLabel] WITH CHECK ADD CONSTRAINT [FK_tblTaskLabel_tblTask] FOREIGN KEY([intTaskID])
	REFERENCES [dbo].[tblTask] ([intTaskID])
	ALTER TABLE [dbo].[tblTaskLabel] CHECK CONSTRAINT [FK_tblTaskLabel_tblTask]

	ALTER TABLE [dbo].[tblTaskLabel] WITH CHECK ADD CONSTRAINT [FK_tblTaskLabel_tblLabel] FOREIGN KEY([intLabelID])
	REFERENCES [dbo].[tblLabel] ([intLabelID])
	ALTER TABLE [dbo].[tblTaskLabel] CHECK CONSTRAINT [FK_tblTaskLabel_tblLabel]

	CREATE NONCLUSTERED INDEX [IX_tblTaskLabel_intTaskID] ON [dbo].[tblTaskLabel] ([intTaskID])
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprCreateLabel]
	@Name varchar(100),
	@Color varchar(20),
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblLabel WHERE strName=@Name)
		Begin
			set @Msg='A label with this name already exists!!!'
		End
		ELSE
		Begin
			insert into [ProjectManagement].[dbo].[tblLabel] (strName, strColor)
			values (@Name, @Color)
			declare @Details varchar(MAX)='Label Created - '+@Name
			EXEC ProjectManagement.dbo.sprLog 'Insert', 'Label Create', @Details, @Enroll
			set @Msg='Label Created Successfully'
		End
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetLabels]
AS
BEGIN
	select intLabelID, strName, strColor
	from ProjectManagement.dbo.tblLabel
	where isActive=1
	order by strName
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetLabelsByTask]
	@TaskID int
AS
BEGIN
	select l.intLabelID, l.strName, l.strColor
	from ProjectManagement.dbo.tblTaskLabel tl
	inner join ProjectManagement.dbo.tblLabel l on l.intLabelID=tl.intLabelID
	where tl.intTaskID=@TaskID
	order by l.strName
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprAssignLabel]
	@TaskID int,
	@LabelID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblTaskLabel WHERE intTaskID=@TaskID AND intLabelID=@LabelID)
		Begin
			set @Msg='Label already assigned!!!'
		End
		ELSE
		Begin
			insert into [ProjectManagement].[dbo].[tblTaskLabel] (intTaskID, intLabelID)
			values (@TaskID, @LabelID)
			declare @Details varchar(MAX)='Label '+cast(@LabelID as varchar(50))+' assigned to Task - '+cast(@TaskID as varchar(100))
			EXEC ProjectManagement.dbo.sprLog 'Insert', 'Label Assign', @Details, @Enroll
			set @Msg='Label Assigned Successfully'
		End
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprRemoveLabel]
	@TaskID int,
	@LabelID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		delete from [ProjectManagement].[dbo].[tblTaskLabel] where intTaskID=@TaskID and intLabelID=@LabelID
		declare @Details varchar(MAX)='Label '+cast(@LabelID as varchar(50))+' removed from Task - '+cast(@TaskID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Delete', 'Label Remove', @Details, @Enroll
		set @Msg='Label Removed Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

-- ============================================================
-- 2. Offboarding / bulk-task tooling
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetAllUsersForOffboarding]
AS
BEGIN
	-- Unlike sprGetAllUser (which only returns isActive=1), this intentionally includes
	-- inactive users, since offboarding is precisely about finding THEM.
	select u.intUserID, u.strUserName, u.isActive, t.strTeamName
	from ProjectManagement.dbo.tblUser u
	inner join ProjectManagement.dbo.tblTeam t on t.intTeamID=u.intTeamID
	order by u.isActive asc, u.strUserName
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetOpenTasksByUser]
	@UserID int
AS
BEGIN
	select t.intTaskID, t.strTaskName, p.strProjectName, t.dteDeadLine, td.intStatusID, s.strStatus
	from ProjectManagement.dbo.tblTask t
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblProject p on p.intProjectID=t.intProjectID
	inner join ProjectManagement.dbo.tblStatus s on s.intStatusID=td.intStatusID
	where td.intUserID=@UserID and td.intStatusID in (1,2,3,4)
	order by t.intTaskID
END
GO

-- ============================================================
-- 3. Project timeline (Gantt-style feed; bars use dteCreated->dteDeadLine as a
--    proxy for start/end since tblTask has no separate "start date" column).
--    Restricted to active tasks (1,2,3,4) -- a project with years of history can
--    have hundreds of Complete/Removed tasks, which would make an unreadable Gantt.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprGetProjectTimeline]
	@ProjectID int
AS
BEGIN
	select t.intTaskID, t.strTaskName, t.dteCreated as dteStart, t.dteDeadLine as dteEnd, td.intStatusID, s.strStatus
	from ProjectManagement.dbo.tblTask t
	inner join ProjectManagement.dbo.tblTaskDetail td on td.intTaskID=t.intTaskID
	inner join ProjectManagement.dbo.tblStatus s on s.intStatusID=td.intStatusID
	where t.intProjectID=@ProjectID and t.intParentTaskID is null and td.intStatusID in (1,2,3,4)
	order by t.dteCreated
END
GO
