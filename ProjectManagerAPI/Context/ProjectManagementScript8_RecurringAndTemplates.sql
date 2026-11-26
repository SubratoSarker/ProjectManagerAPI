-- ============================================================
-- Script 8: Recurring tasks + Task templates
-- Additive only (CREATE TABLE IF NOT EXISTS pattern / CREATE OR ALTER) -- safe to re-run.
-- ============================================================

-- ============================================================
-- 1. Recurring tasks
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblRecurringTask')
BEGIN
	CREATE TABLE [dbo].[tblRecurringTask](
		[intRecurringID] [int] IDENTITY(1,1) NOT NULL,
		[strTaskName] [varchar](500) NOT NULL,
		[strDescription] [varchar](max) NULL,
		[intPriroty] [int] NOT NULL,
		[intProjectID] [int] NOT NULL,
		[intUserID] [int] NOT NULL,            -- who the spawned task gets assigned to
		[strRecurrence] [varchar](20) NOT NULL, -- 'Daily' | 'Weekly' | 'Monthly'
		[dteNextRun] [date] NOT NULL,
		[isActive] [bit] NOT NULL DEFAULT 1,
		[dteCreated] [datetime] NOT NULL DEFAULT GETDATE(),
		[intCreatedBy] [int] NOT NULL,
		CONSTRAINT [PK_tblRecurringTask] PRIMARY KEY CLUSTERED ([intRecurringID] ASC)
	)
	ALTER TABLE [dbo].[tblRecurringTask] ADD CONSTRAINT [FK_tblRecurringTask_tblProject]
		FOREIGN KEY ([intProjectID]) REFERENCES [dbo].[tblProject] ([intProjectID])
	ALTER TABLE [dbo].[tblRecurringTask] ADD CONSTRAINT [FK_tblRecurringTask_tblUser]
		FOREIGN KEY ([intUserID]) REFERENCES [dbo].[tblUser] ([intUserID])
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprCreateRecurringTask]
	@Name varchar(500),
	@Description varchar(max),
	@Priroty int,
	@ProjectID int,
	@AssignTo int,
	@Recurrence varchar(20),
	@StartDate date,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		IF @Recurrence NOT IN ('Daily','Weekly','Monthly')
		Begin
			set @Msg = 'Recurrence must be Daily, Weekly or Monthly.'
		End
		ELSE
		Begin
			INSERT INTO ProjectManagement.dbo.tblRecurringTask
				(strTaskName, strDescription, intPriroty, intProjectID, intUserID, strRecurrence, dteNextRun, intCreatedBy)
			VALUES (@Name, @Description, @Priroty, @ProjectID, @AssignTo, @Recurrence, @StartDate, @Enroll)
			declare @Details varchar(MAX)='New recurring task template created: '+@Name
			EXEC ProjectManagement.dbo.sprLog 'Insert', 'Recurring Task Create', @Details, @Enroll
			set @Msg='Recurring Task Created Successfully'
		End
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetRecurringTasks]
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

	select r.intRecurringID, r.strTaskName, r.strDescription, r.intPriroty, r.intProjectID, p.strProjectName,
		r.intUserID, u.strUserName, r.strRecurrence, r.dteNextRun, r.isActive, r.dteCreated
	from ProjectManagement.dbo.tblRecurringTask r
	inner join ProjectManagement.dbo.tblProject p on p.intProjectID = r.intProjectID
	inner join ProjectManagement.dbo.tblUser u on u.intUserID = r.intUserID
	where r.intCreatedBy in (select intUserID from @ScopeUsers)
	order by r.isActive desc, r.dteNextRun
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprToggleRecurringTask]
	@RecurringID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		update ProjectManagement.dbo.tblRecurringTask set isActive = CASE WHEN isActive=1 THEN 0 ELSE 1 END where intRecurringID=@RecurringID
		declare @Details varchar(MAX)='Recurring task toggled ID - '+cast(@RecurringID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Update', 'Recurring Task Toggle', @Details, @Enroll
		set @Msg='Updated Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprDeleteRecurringTask]
	@RecurringID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		delete from ProjectManagement.dbo.tblRecurringTask where intRecurringID=@RecurringID
		declare @Details varchar(MAX)='Recurring task deleted ID - '+cast(@RecurringID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Delete', 'Recurring Task Delete', @Details, @Enroll
		set @Msg='Deleted Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

-- Spawns (at most once per template per call) any task whose dteNextRun has arrived,
-- scoped to the caller's team the same way the dashboard procs are. Deliberately never
-- backfills more than one task per template no matter how many periods were missed --
-- it just fast-forwards dteNextRun past every missed occurrence without creating one
-- for each, so a vacation doesn't flood the board.
CREATE OR ALTER PROCEDURE [dbo].[sprProcessDueRecurring]
	@Enroll int
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		DECLARE @ScopeUsers TABLE (intUserID int PRIMARY KEY)
		INSERT INTO @ScopeUsers
			select u.intUserID from ProjectManagement.dbo.tblUser u
			inner join ProjectManagement.dbo.tblTeam tm on tm.intTeamID=u.intTeamID
			where tm.intUserID=@Enroll
			union
			select @Enroll

		DECLARE @RecurringID int, @Name varchar(500), @Desc varchar(max), @Priroty int,
			@ProjectID int, @AssignTo int, @Recurrence varchar(20), @NextRun date, @SpawnCount int = 0

		DECLARE recur_cursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT intRecurringID, strTaskName, strDescription, intPriroty, intProjectID, intUserID, strRecurrence, dteNextRun
			FROM ProjectManagement.dbo.tblRecurringTask
			WHERE isActive=1 AND intCreatedBy IN (SELECT intUserID FROM @ScopeUsers) AND dteNextRun <= CAST(GETDATE() AS date)

		OPEN recur_cursor
		FETCH NEXT FROM recur_cursor INTO @RecurringID, @Name, @Desc, @Priroty, @ProjectID, @AssignTo, @Recurrence, @NextRun
		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @NewTaskID int
			INSERT INTO ProjectManagement.dbo.tblTask (strTaskName, strDescription, strRequestFrom, intPriroty, dteDeadLine, intUserID, dteCreated, intProjectID)
			VALUES (@Name, ISNULL(@Desc,''), 'Recurring', @Priroty, DATEADD(DAY,7,CAST(GETDATE() AS date)), @AssignTo, GETDATE(), @ProjectID)
			SET @NewTaskID = SCOPE_IDENTITY()
			INSERT INTO ProjectManagement.dbo.tblTaskDetail (intTaskID, intUserID, intStatusID, tmWorking)
			VALUES (@NewTaskID, @AssignTo, 2, '00:00:00')

			WHILE @NextRun <= CAST(GETDATE() AS date)
			BEGIN
				SET @NextRun = CASE @Recurrence
					WHEN 'Daily' THEN DATEADD(DAY,1,@NextRun)
					WHEN 'Weekly' THEN DATEADD(DAY,7,@NextRun)
					WHEN 'Monthly' THEN DATEADD(MONTH,1,@NextRun)
					ELSE DATEADD(DAY,1,@NextRun)
				END
			END
			UPDATE ProjectManagement.dbo.tblRecurringTask SET dteNextRun=@NextRun WHERE intRecurringID=@RecurringID

			declare @Details varchar(MAX)='Recurring task spawned Task ID - '+cast(@NewTaskID as varchar(100))+' from template - '+cast(@RecurringID as varchar(100))
			EXEC ProjectManagement.dbo.sprLog 'Insert', 'Recurring Task Spawn', @Details, @AssignTo
			SET @SpawnCount = @SpawnCount + 1

			FETCH NEXT FROM recur_cursor INTO @RecurringID, @Name, @Desc, @Priroty, @ProjectID, @AssignTo, @Recurrence, @NextRun
		END
		CLOSE recur_cursor
		DEALLOCATE recur_cursor

		SELECT @SpawnCount AS SpawnCount
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		IF CURSOR_STATUS('local','recur_cursor') >= 0
		BEGIN
			CLOSE recur_cursor
			DEALLOCATE recur_cursor
		END
		ROLLBACK TRANSACTION;
		SELECT 0 AS SpawnCount
	END CATCH;
END
GO

-- ============================================================
-- 2. Task templates
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTaskTemplate')
BEGIN
	CREATE TABLE [dbo].[tblTaskTemplate](
		[intTemplateID] [int] IDENTITY(1,1) NOT NULL,
		[strName] [varchar](300) NOT NULL,
		[strTaskName] [varchar](500) NOT NULL,
		[strDescription] [varchar](max) NULL,
		[intPriroty] [int] NOT NULL,
		[intTeamID] [int] NOT NULL,
		[dteCreated] [datetime] NOT NULL DEFAULT GETDATE(),
		[intCreatedBy] [int] NOT NULL,
		CONSTRAINT [PK_tblTaskTemplate] PRIMARY KEY CLUSTERED ([intTemplateID] ASC)
	)
	ALTER TABLE [dbo].[tblTaskTemplate] ADD CONSTRAINT [FK_tblTaskTemplate_tblTeam]
		FOREIGN KEY ([intTeamID]) REFERENCES [dbo].[tblTeam] ([intTeamID])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTaskTemplateStep')
BEGIN
	CREATE TABLE [dbo].[tblTaskTemplateStep](
		[intTemplateStepID] [int] IDENTITY(1,1) NOT NULL,
		[intTemplateID] [int] NOT NULL,
		[strStep] [varchar](500) NOT NULL,
		[intOrder] [int] NOT NULL DEFAULT 0,
		CONSTRAINT [PK_tblTaskTemplateStep] PRIMARY KEY CLUSTERED ([intTemplateStepID] ASC)
	)
	ALTER TABLE [dbo].[tblTaskTemplateStep] ADD CONSTRAINT [FK_tblTaskTemplateStep_tblTaskTemplate]
		FOREIGN KEY ([intTemplateID]) REFERENCES [dbo].[tblTaskTemplate] ([intTemplateID])
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprCreateTaskTemplate]
	@Name varchar(300),
	@TaskName varchar(500),
	@Description varchar(max),
	@Priroty int,
	@StepsPipeDelimited varchar(max), -- e.g. "Step one|Step two|Step three", '' if none
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		DECLARE @MyTeam int = (SELECT TOP 1 intTeamID FROM ProjectManagement.dbo.tblUser WHERE intUserID=@Enroll)
		DECLARE @TemplateID int

		INSERT INTO ProjectManagement.dbo.tblTaskTemplate (strName, strTaskName, strDescription, intPriroty, intTeamID, intCreatedBy)
		VALUES (@Name, @TaskName, @Description, @Priroty, @MyTeam, @Enroll)
		SET @TemplateID = SCOPE_IDENTITY()

		IF @StepsPipeDelimited IS NOT NULL AND LEN(@StepsPipeDelimited) > 0
		BEGIN
			INSERT INTO ProjectManagement.dbo.tblTaskTemplateStep (intTemplateID, strStep, intOrder)
			SELECT @TemplateID, value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
			FROM STRING_SPLIT(@StepsPipeDelimited, '|')
			WHERE LEN(TRIM(value)) > 0
		END

		declare @Details varchar(MAX)='New task template created: '+@Name
		EXEC ProjectManagement.dbo.sprLog 'Insert', 'Task Template Create', @Details, @Enroll
		set @Msg='Template Created Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetTaskTemplates]
	@Enroll int
AS
BEGIN
	DECLARE @MyTeam int = (SELECT TOP 1 intTeamID FROM ProjectManagement.dbo.tblUser WHERE intUserID=@Enroll)
	SELECT t.intTemplateID, t.strName, t.strTaskName, t.strDescription, t.intPriroty, t.dteCreated,
		(SELECT COUNT(*) FROM ProjectManagement.dbo.tblTaskTemplateStep s WHERE s.intTemplateID = t.intTemplateID) AS StepCount
	FROM ProjectManagement.dbo.tblTaskTemplate t
	WHERE t.intTeamID = @MyTeam
	ORDER BY t.strName
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprGetTemplateSteps]
	@TemplateID int
AS
BEGIN
	SELECT intTemplateStepID, intTemplateID, strStep, intOrder
	FROM ProjectManagement.dbo.tblTaskTemplateStep
	WHERE intTemplateID = @TemplateID
	ORDER BY intOrder
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprDeleteTaskTemplate]
	@TemplateID int,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		delete from ProjectManagement.dbo.tblTaskTemplateStep where intTemplateID=@TemplateID
		delete from ProjectManagement.dbo.tblTaskTemplate where intTemplateID=@TemplateID
		declare @Details varchar(MAX)='Task template deleted ID - '+cast(@TemplateID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Delete', 'Task Template Delete', @Details, @Enroll
		set @Msg='Deleted Successfully'
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[sprApplyTaskTemplate]
	@TemplateID int,
	@ProjectID int,
	@DeadLine date,
	@Enroll int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
		DECLARE @TaskName varchar(500), @Description varchar(max), @Priroty int
		SELECT TOP 1 @TaskName=strTaskName, @Description=strDescription, @Priroty=intPriroty
		FROM ProjectManagement.dbo.tblTaskTemplate WHERE intTemplateID=@TemplateID

		IF @TaskName IS NULL
		Begin
			set @Msg = 'Template not found!!!'
		End
		ELSE
		Begin
			DECLARE @NewTaskID int
			INSERT INTO ProjectManagement.dbo.tblTask (strTaskName, strDescription, strRequestFrom, intPriroty, dteDeadLine, intUserID, intProjectID)
			VALUES (@TaskName, ISNULL(@Description,''), 'Template', @Priroty, @DeadLine, @Enroll, @ProjectID)
			SET @NewTaskID = SCOPE_IDENTITY()
			INSERT INTO ProjectManagement.dbo.tblTaskDetail (intTaskID, intUserID, intStatusID, tmWorking)
			VALUES (@NewTaskID, @Enroll, 2, '00:00:00')

			INSERT INTO ProjectManagement.dbo.tblSteps (strStep, intTaskID, isDone)
			SELECT strStep, @NewTaskID, 0
			FROM ProjectManagement.dbo.tblTaskTemplateStep
			WHERE intTemplateID = @TemplateID
			ORDER BY intOrder

			declare @Details varchar(MAX)='Task created from template ID - '+cast(@TemplateID as varchar(100))+' -> Task ID - '+cast(@NewTaskID as varchar(100))
			EXEC ProjectManagement.dbo.sprLog 'Insert', 'Task Template Apply', @Details, @Enroll
			set @Msg='Task Created Successfully'
		End
	COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
		ROLLBACK TRANSACTION;
		set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
	END CATCH;
END
GO
