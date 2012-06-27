IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgp_link_pull_data]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_link_pull_data]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************
**
** Name:            sgp_link_pull_data
** Purpose:         Pull data from the specified "source" table on a linked or local server,
**                  into a "destination" table on the local server
**
** Usage Notes:
** (1) If the destination table doesn't exist, it will be created
** (2) If the destination table exists,
**     and the source table has different columns than the destination table,
**     the existing destination table will be renamed with a timestamp suffix as a backup.
**     The source data will then be inserted into a new table with the intended name.
**
** TODO:
** (1)
**
** Modifications:
** 04/21/2009       nramji      Original coding.
**
********************************************************************************/
CREATE PROCEDURE sgp_link_pull_data

	@source NVARCHAR(512),      -- the fully qualified name of the source table/view
	@destination NVARCHAR(512)  -- the fully qualified name of the destination table
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- validate input
    IF ((dbo.sgf_is_full_name(@source) = 0) OR (dbo.sgf_is_full_name(@destination) = 0))
    BEGIN
        RAISERROR('The specified object is not fully qualified. It must be in the following format: [server].[catalog].[schema].[object]'
                , 16-- Severity: Levels 11-16 for errors that can be corrected by user
                , 1 -- State
                ) WITH NOWAIT
        RETURN 1
    END

    -- pull the source data into a temp table
    DECLARE @destination_table sysname
    SET @destination_table = dbo.sqlcorlib_format_full_name(@destination, '@table')

    DECLARE @temp_table sysname
    SET @temp_table = 'SNAPSHOT_TEMP_{destinationTable}'
    SET @temp_table = REPLACE(@temp_table, '{destinationTable}', UPPER(@destination_table))

    -- just in case temp table already exists, drop it
    -- as we are dynamically creating it below
    EXEC sgp_drop_table @temp_table

    DECLARE @sql NVARCHAR(2000)
    SET @sql = N' SELECT * INTO {tempTable} FROM {source}'
    SET @sql = REPLACE(@sql, '{tempTable}', QUOTENAME(@temp_table))
    SET @sql = REPLACE(@sql, '{source}', @source)
    EXEC sp_executesql @sql

    -- check if the destination table we really want exists
    IF NOT EXISTS (SELECT *
                    FROM information_schema.tables
                    WHERE table_name = @destination_table)
    BEGIN
        -- doesn't exist
        -- so we can just rename the temp table to the intended name
        EXEC sp_rename @temp_table, @destination_table
    END

    ELSE
    BEGIN
        -- exists

        -- check if there is a column mismatch between our source data
        -- and the destination table we are trying to insert into
        IF (dbo.sgf_has_same_table_def(@destination_table, @temp_table) = 0)
        BEGIN
            -- column mismatch:
            -- rename the existing table by appending the current timestamp
            -- (this will be left as a backup for later reconciliation)
            DECLARE @archive_table sysname
            SET @archive_table = @destination_table + '_' +
                                dbo.sgf_get_timestamp_string(GETDATE())

            EXEC sp_rename @destination_table, @archive_table

            -- now rename our temp table to be the intended destination table
            EXEC sp_rename @temp_table, @destination_table
        END

        ELSE
        BEGIN
            -- NO column mismatch:
            -- just insert into the existing table
            SET @sql =  N'  INSERT INTO {destinationTable}
                            SELECT * FROM {tempTable}'
            SET @sql = REPLACE(@sql, '{destinationTable}', QUOTENAME(@destination_table))
            SET @sql = REPLACE(@sql, '{tempTable}', QUOTENAME(@temp_table))
            EXEC sp_executesql @sql
        END
    END

    -- drop temp table
    EXEC sgp_drop_table @temp_table

END
GO

