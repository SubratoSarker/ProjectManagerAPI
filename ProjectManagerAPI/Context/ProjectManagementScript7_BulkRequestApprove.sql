-- ============================================================
-- Script 7: guard against re-actioning an already-approved/rejected request.
-- Additive only (CREATE OR ALTER) -- safe to re-run.
--
-- sprGetRequestList already only ever returns rows where isAction IS NULL, so a
-- single click can't hit this. The guard is defense-in-depth for the new bulk
-- approve/reject flow (API/Controllers/Project/ProjectController.cs ->
-- BulkRequestAction), which loops this same proc over several ids per click --
-- without it, a double-submit would insert a duplicate tblTask/tblTaskDetail/
-- tblWorkLog row for the same request instead of just no-op'ing.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sprRequetAction]
	@RequestID int,
	@Enroll int,
	@Type int,
	@Msg varchar(MAX) out
AS
BEGIN
 BEGIN TRANSACTION;
	BEGIN TRY
	IF EXISTS (SELECT 1 FROM ProjectManagement.dbo.tblRequest WHERE intID=@RequestID AND isAction IS NOT NULL)
	Begin
		set @Msg='This request has already been actioned.'
	End
	Else
	Begin
	declare @Details varchar(max)
	Declare @Notify varchar(MAX), @TaskName varchar(MAX)
	set @TaskName =(select top 1 strTaskName from ProjectManagement.dbo.tblRequest where intID=@RequestID)
	if(@Type=1)
	Begin

		DECLARE @TaskID int = (SELECT TOP 1 intTaskID FROM ProjectManagement.dbo.tblRequest WHERE intID = @RequestID)

		IF @TaskID IS NULL
		BEGIN
			-- New task flow
			INSERT INTO ProjectManagement.dbo.tblTask (strTaskName, strDescription, strRequestFrom, intPriroty, dteDeadLine, intUserID, dteCreated, intProjectID)
			SELECT strTaskName, strDescription, strRequestFrom, 3, dteCreated, intUserID, dteCreated, intProjectID
			FROM ProjectManagement.dbo.tblRequest WHERE intID = @RequestID

			SET @TaskID = SCOPE_IDENTITY()

			INSERT INTO ProjectManagement.dbo.tblTaskDetail (intTaskID, intUserID, intStatusID, tmWorking)
			SELECT @TaskID, intUserID, intStatusID, tmWorking
			FROM ProjectManagement.dbo.tblRequest WHERE intID = @RequestID

			INSERT INTO ProjectManagement.dbo.tblWorkLog (dteInsert, intUserID, tmWorking, intStatusID, intTaskID)
			SELECT dteCreated, intUserID, tmWorking, intStatusID, @TaskID
			FROM ProjectManagement.dbo.tblRequest WHERE intID = @RequestID
		END
		ELSE
		BEGIN
			-- Adjustment flow: UPDATE existing tblTaskDetail row, INSERT into tblWorkLog
			UPDATE td
			   SET td.tmWorking = CAST(DATEADD(SECOND,
											   DATEDIFF(SECOND, 0, td.tmWorking)
											 + DATEDIFF(SECOND, 0, r.tmWorking),
											   CAST('00:00:00' AS time)) AS time)
			  FROM ProjectManagement.dbo.tblTaskDetail td
			 INNER JOIN ProjectManagement.dbo.tblRequest r
					 ON r.intID = @RequestID
					AND r.intUserID = td.intUserID
			 WHERE td.intTaskID = @TaskID

			INSERT INTO ProjectManagement.dbo.tblWorkLog (dteInsert, intUserID, tmWorking, intStatusID, intTaskID)
			SELECT dteCreated, intUserID, tmWorking, intStatusID, @TaskID
			FROM ProjectManagement.dbo.tblRequest WHERE intID = @RequestID
		END


		update ProjectManagement.dbo.tblRequest set isAction=1, dteAction=GETDATE(), intTaskID=@TaskID where intID=@RequestID

		set @Details='Request Approved ID - '+cast(@RequestID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Insert & Update', 'Request Approve', @Details, @Enroll

		set @Msg='Request Approved Successfully'
		set @Notify = @TaskName+' Request have been approved.'
		exec dbo.sprNotify @Enroll, @Notify


	End
	else if(@Type=2)
	Begin

		update ProjectManagement.dbo.tblRequest set isAction=0, dteAction=GETDATE() where intID=@RequestID

		set @Details='Request Reject ID - '+cast(@RequestID as varchar(100))
		EXEC ProjectManagement.dbo.sprLog 'Update', 'Request Reject', @Details, @Enroll
		set @Msg='Request Rejected Successfully'
		set @Notify = @TaskName+' Request have been Rejected.'
		exec dbo.sprNotify @Enroll, @Notify
	End
	else
	Begin
		set @Msg='Sorry There wasn an error!!!'
	End
	End
COMMIT TRANSACTION;
	END TRY
 BEGIN CATCH
        ROLLBACK TRANSACTION;
        set @Msg= 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH;
END
GO
