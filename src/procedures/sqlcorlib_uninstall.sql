IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sqlcorlib_uninstall]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sqlcorlib_uninstall]
GO
/*******************************************************************************

    Name:           sqlcorlib_uninstall

    Description:    Uninstalls sqlcorlib from the database.

    Usage Notes:
    (1) This sproc will uninstall itself after it is done.

    Design Notes:
    (1) This was intentionally designed to have no dependencies.

********************************************************************************/
CREATE PROCEDURE sqlcorlib_uninstall

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- create temp table with all drop statements
    CREATE TABLE #drop_statements
    (
        row_index INT IDENTITY(1,1)
        , statement NVARCHAR(4000)
    )

    INSERT INTO #drop_statements
    SELECT ('DROP ' +
            CASE type
                WHEN 'P' THEN 'PROCEDURE '
                WHEN 'FN' THEN 'FUNCTION '
            END +
            name)
    FROM sysobjects
    WHERE name like 'sqlcorlib_%'

    -- initialize loop variables
    DECLARE @row_index INT
    SET @row_index = 1

    DECLARE @row_count INT
    SELECT @row_count = COUNT(*) FROM #drop_statements

    DECLARE @sql NVARCHAR(4000)
    DECLARE @error_code INT

    -- process each record
    WHILE (@row_index <= @row_count)
    BEGIN

        SELECT  @sql = statement
        FROM #drop_statements
        WHERE row_index = @row_index

        EXEC sp_executesql @sql

        -- increment loop counter
        SET @row_index = @row_index + 1

    END

END
GO
