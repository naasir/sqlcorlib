IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgp_link_snapshot_data]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_link_snapshot_data]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************
**
** Name:            sgp_link_snapshot_data
** Purpose:         Create a snapshot of data and transfer it to a linked server
**
** Dependencies:    Requires sgp_link_pull_data to exist on linked server
**
** Usage Notes
** (1)  you can explicilty set the timestamp signature for the snapshot data
**      by specifying a value for the optional 'timestamp' parameter.
**      The default 'timestamp' value is the current time.
**
** (2)  if you specify a pre-snapshot hook, you will want to reference the
**      'snapshot buffer table' to perform your custom manipulations.
**      The snapshot buffer table has the following name format:
**
**          [SNAPSHOT_BUFFER_{id}]
**
**          where {id} is the value you specify for the 'id' parameter.
**
**      In your pre-snapshot hook procedure, you could then do something like:
**
**      Update  [SNAPSHOT_BUFFER_{id}]
**      Set     SSN = 'xxx-xx-xxxx'
**
** Design Notes:
** (1)  This procedure will automatically add a timestamp column called 'SnapshotTimeStamp'
**      to the data.
** (2)  The buffer table created below is NOT a temp table for two reasons:
**      1.  on the linked server side, we have to reference this table to pull data.
**          We can't reference a TEMP table over a linked connection.
**      2.  the snapshot buffer is what the user will specify in their 'format procedure',
**          if they would like to do some data manipulation (without affecting the original data)
**          prior to transferring the data over. This is especially useful
**          for when the source is a view.
**
** Modifications:
** 04/20/2009       nramji      Original coding.
**
** TODO:
** 04/28/2009       nramji      Make this a transaction like sgp_add_temp_job
********************************************************************************/
CREATE PROCEDURE sgp_link_snapshot_data
    @id sysname                                 -- label for the snapshot
	, @source NVARCHAR(512)                     -- fully qualified name of source table/view
	, @destination NVARCHAR(512)                -- fully qualified name of destination table
	, @pre_snapshot_hook NVARCHAR(512) = NULL   -- fully qualified name of pre-snapshot hook
	, @post_snapshot_hook NVARCHAR(512) = NULL  -- fully qualified name of post-snapshot hook
    , @timestamp DATETIME = NULL OUTPUT         -- (optional) snapshot timestamp signature

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- validate input
    -- (sp_validname will raise an error if it fails)
    EXEC sp_validname @id

    IF ((dbo.sgf_is_full_name(@source) = 0)
    OR (dbo.sgf_is_full_name(@destination) = 0)
    OR ((@pre_snapshot_hook IS NOT NULL) AND (dbo.sgf_is_full_name(@destination) = 0))
    OR ((@pre_snapshot_hook IS NOT NULL) AND (dbo.sgf_is_full_name(@destination) = 0)))
    BEGIN
        RAISERROR('The specified object is not fully qualified. It must be in the following format: [server].[catalog].[schema].[object]'
                , 16-- Severity: Levels 11-16 for errors that can be corrected by user
                , 1 -- State
                ) WITH NOWAIT
        RETURN 1
    END

    -- if timestamp parameter not specifyed, use current time
    SET @timestamp = COALESCE(@timestamp, GETDATE())

    -- insert the data into a buffer table
    DECLARE @sql NVARCHAR(2000)
    DECLARE @params NVARCHAR(2000)

    DECLARE @snapshot_buffer sysname
    SET @snapshot_buffer = N'SNAPSHOT_BUFFER_{id}'
    SET @snapshot_buffer = REPLACE(@snapshot_buffer, '{id}', UPPER(@id))

    -- just in case buffer table already exists, drop it
    -- as we are dynamically creating it below
    EXEC sgp_drop_table @snapshot_buffer

    SET @sql = N'SELECT @timestamp AS SnapshotTimeStamp
                        , *
                INTO {snapshotBuffer}
                FROM {source}'
    SET @sql = REPLACE(@sql, '{snapshotBuffer}', QUOTENAME(@snapshot_buffer))
    SET @sql = REPLACE(@sql, '{source}', @source)

    SET @params = N'@timestamp datetime'

    EXEC sp_executesql @sql, @params, @timestamp=@timestamp

    -- run the pre-snapshot hook
    IF @pre_snapshot_hook IS NOT NULL
        EXEC @pre_snapshot_hook

    -- transfer the data
    -- *NOTE* can't PUSH the data into a dynamically created table on a linked server
    -- so we're going to call sgp_link_pull_data on the linked server to PULL the data
    DECLARE @snapshot_buffer_full NVARCHAR(512)
    SET @snapshot_buffer_full = dbo.sqlcorlib_get_full_name(  @@SERVERNAME
                                                            , DB_NAME()
                                                            , 'dbo'
                                                            , @snapshot_buffer)
    DECLARE @server_path NVARCHAR(512)
    SET @server_path = dbo.sqlcorlib_format_full_name(@destination
                                            ,'[@server].[@catalog].[@schema]')

    SET @sql =  N'EXEC {serverPath}.[sgp_link_pull_data] @source, @destination'
    SET @sql = REPLACE(@sql, '{serverPath}', @server_path)

    SET @params = N'@source nvarchar(512), ' +
                  N'@destination nvarchar(512)';

    EXEC sp_executesql @sql
                        , @params
                        , @source = @snapshot_buffer_full
                        , @destination = @destination

    -- run the post-snapshot hook
    IF @post_snapshot_hook IS NOT NULL
        EXEC @post_snapshot_hook

    -- drop buffer table
    EXEC sgp_drop_table @snapshot_buffer

END
GO

