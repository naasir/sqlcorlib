IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sqlcorlib_exec_resultset]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sqlcorlib_exec_resultset]
GO
/*******************************************************************************

    Name:           sqlcorlib_exec_resultset
    Description:    Executes sql statements defined in the records of a query.

    Usage Notes:
    (1)

    Design Notes:
    (1) This is a replacement for the hidden MS sproc 'xp_execresultset',
        only found in SQL Server 2000. This mimics the functionality of that sproc,
        for all versions of SQL Server (2K+).

    TODO:
    (1)

********************************************************************************/
CREATE PROCEDURE sqlcorlib_exec_resultset
    @cmd NVARCHAR(4000)             -- the query to execute
    , @db_name NVARCHAR(128) = NULL -- (optional) the database to run against
    , @debug INT = 0                -- (optional) print dynamic sql text, without executing
    , @stats INT = 0                -- (optional) print execution stats
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- handle defaults
    SET @db_name = COALESCE(@db_name, DB_NAME())

    CREATE TABLE #resultset
    (
        row_index INT IDENTITY(1,1)
        , cmd NVARCHAR(4000)
        , error_code INT
    )

    DECLARE @input_sql NVARCHAR(512)
    SET @input_sql = N'EXEC {dbname}..sp_executesql @stmt=@cmd'
    SET @input_sql = REPLACE(@input_sql, '{dbname}', @db_name)

    INSERT INTO #resultset (cmd)
    EXEC sp_executesql  @input_sql,
                        N'@cmd NVARCHAR(4000)',
                        @cmd

    -- process each record
    DECLARE @row_index INT
    SET @row_index = 1

    DECLARE @row_count INT
    SELECT @row_count = COUNT(*) FROM #resultset

    DECLARE @sql NVARCHAR(4000)
    DECLARE @error_code INT

    WHILE (@row_index <= @row_count)
    BEGIN

        SELECT  @sql = cmd
        FROM #resultset
        WHERE row_index = @row_index

        -- if debug, print sql without executing
        IF @debug = 1
        BEGIN
            PRINT @sql
        END

        ELSE
        BEGIN

            EXEC @error_code = sp_executesql @input_sql,
                                                N'@cmd NVARCHAR(4000)',
                                                @sql

            -- update temp table
            UPDATE #resultset
            SET error_code = @error_code
            WHERE row_index = @row_index

        END

        SET @row_index = @row_index + 1

    END

    -- aggregate error codes
    DECLARE @sum_error_codes INT
    SELECT @sum_error_codes = ISNULL(SUM(error_code), 0)
    FROM #resultset

    DROP TABLE #resultset

    -- print stats
    IF @stats = 1
    BEGIN
        PRINT   'sqlcorlib_exec_resultset query:'
        PRINT   '   ' + @cmd
        PRINT   ''
        PRINT   'sqlcorlib_exec_resultset stats:'
        PRINT   '   total: ' + CONVERT(VARCHAR, @row_count)
        PRINT   '   passed: ' + CONVERT(VARCHAR, @row_count - @sum_error_codes)
        PRINT   '   failed: ' + CONVERT(VARCHAR, @sum_error_codes)
        PRINT   ''
        PRINT   '------------------------'
        PRINT   ''
    END

    -- return
    RETURN @sum_error_codes

END
GO
