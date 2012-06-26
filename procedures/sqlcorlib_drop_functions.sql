IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sqlcorlib_drop_functions]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sqlcorlib_drop_functions]
GO
/*******************************************************************************

    Name:           sqlcorlib_drop_functions
    Description:    drops all (or a subset) of the functions in the database.

    Dependencies:
    (1) sqlcorlib_exec_resultset

    Usage Notes:
    (1) Use the 'pattern' parameter to drop all or a subset of functions,
        for example, those that may start with a prefix.

        To drop all: @pattern = '%'
        To drop a subset @pattern = 'mmt_%'

    Design Notes:
    (1)

    TODO:
    (1)

********************************************************************************/
CREATE PROCEDURE sqlcorlib_drop_functions
    @pattern sysname        -- pattern to define which tables to drop
    , @debug INT = 0        -- (optional) output the dynamic sql text, without executing
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(4000)
    Set @sql = N'SELECT
        ''DROP FUNCTION ['' + ROUTINE_NAME + '']''
    FROM information_schema.routines
    WHERE ROUTINE_NAME LIKE {pattern}
    AND ROUTINE_TYPE = ''FUNCTION'''

    set @sql = replace(@sql, '{pattern}', QUOTENAME(@pattern, ''''))

    -- if debug, print sql without executing
    IF @debug = 1
    BEGIN
        PRINT @sql
        RETURN
    END

    -- execute
    DECLARE @error_code INT
    EXEC @error_code = sqlcorlib_exec_resultset @sql

    IF @error_code <> 0
    BEGIN
       RAISERROR('Error executing command %s'
                , 16
                , 1
                , @sql)
       RETURN -1
    END

END
GO
