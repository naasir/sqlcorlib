SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgp_add_temp_job]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_add_temp_job]
GO

/*******************************************************************************
**
** Name:            sgp_add_temp_job
** Purpose:         Create amd fire a temporary sql server agent job.
**
** Design Notes:
** (1)  This sproc was designed to be lightweight and easy to use,
**      and therefore exposes only a minute subset of the job config parameters.
**
** Usage Notes:
** (1)  The job will work against the database that called it, on the local server.
** (2)  If a job category is specified, but it doesn't exist, it will be created.
** (3)  The default job category is 'Temp Jobs'
** (4)  'delete_level' parameter controls when the job should delete itself:
**      0 = never delete
**      1 = delete on success
**      2 = delete on failure
**      3 = always delete (default)
**
** (5)  By default, if the job fails, it will retry once more immediately.
**
** Modifications:
** 04/24/2009       nramji      Original coding.
** 
********************************************************************************/
CREATE PROC dbo.sgp_add_temp_job
    
    @job_name sysname                       -- the name of the temp job
    , @category_name sysname = N'Temp Jobs' -- the category of the temp job
    , @description NVARCHAR(512)            -- a description for this temp job
    , @step_command NVARCHAR(4000)          -- the T-SQL command that this job will perform
    , @delete_level int = 3                 -- controls when the job will delete itself.
    , @retry_attempts int = 1               -- number of retry attempts
    , @retry_interval int = 0               -- amount of time in minutes between retry attempts
AS
BEGIN

    SET NOCOUNT ON
    
    -- start job creation
    BEGIN TRANSACTION
    
    DECLARE @ReturnCode INT
    SET @ReturnCode = 0
    
    -- delete job if already exists
    IF  EXISTS (SELECT job_id 
                FROM msdb.dbo.sysjobs_view 
                WHERE name = @job_name)
    BEGIN
        EXEC @ReturnCode = msdb.dbo.sp_delete_job @job_name=@job_name
        
        IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO Catch
    END
    
    -- add job category
    IF NOT EXISTS (SELECT name 
                    FROM msdb.dbo.syscategories 
                    WHERE name=@category_name 
                    AND category_class=1)
    BEGIN
        EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB'
                                                    , @type=N'LOCAL'
                                                    , @name=@category_name
        
        IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO Catch
    END

    -- add job
    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode = msdb.dbo.sp_add_job 
                                @job_name=@job_name, 
                                @enabled=1, 
                                @notify_level_eventlog=0, 
                                @notify_level_email=0, 
                                @notify_level_netsend=0, 
                                @notify_level_page=0, 
                                @delete_level=@delete_level,
                                @description=@description,
                                @category_name=@category_name, 
                                @job_id = @jobId OUTPUT
    
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO Catch

    -- add job step
    IF NOT EXISTS (SELECT * 
                    FROM msdb.dbo.sysjobsteps 
                    WHERE job_id = @jobId 
                    AND step_id = 1)
    BEGIN
        DECLARE @database_name sysname
        SET @database_name = DB_NAME()
        
        EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
                                    @job_id=@jobId, 
                                    @step_name=N'Process temp command',
                                    @step_id=1, 
                                    @cmdexec_success_code=0, 
                                    @on_success_action=1, 
                                    @on_success_step_id=0, 
                                    @on_fail_action=2, 
                                    @on_fail_step_id=0, 
                                    @retry_attempts=@retry_attempts, 
                                    @retry_interval=@retry_interval, 
                                    @os_run_priority=0, 
                                    @subsystem=N'TSQL', 
                                    @command=@step_command, 
                                    @database_name=@database_name, 
                                    @flags=0
        
        IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO Catch
    END
    
    -- update job with step
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId
                                            , @start_step_id = 1
                                            
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO Catch

    -- target the job to the local server
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId
                                                
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO Catch

    -- start the job
    EXEC @ReturnCode = msdb.dbo.sp_start_job @job_name = @job_name
    
    COMMIT TRANSACTION
    GOTO Finally
    
    Catch:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

    Finally:
        Return @ReturnCode
        
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

