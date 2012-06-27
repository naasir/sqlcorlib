SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sgp_link_check_table_exists]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_link_check_table_exists]
GO
/*******************************************************************************

    Name:           sgp_link_check_table_exists
    Description:    check if a table on a linked server exists

    Usage Notes:
    (1) The procedure will return 1 for true, 0 for false.

    Design Notes:
    (1)

    TODO:
    (1)

    History:
    05/08/2009       nramji      Original Coding.

********************************************************************************/
CREATE PROCEDURE sgp_link_check_table_exists
    @name NVARCHAR(512)     -- the fully qualified name of the table to check
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- validate input
    IF (dbo.sgf_is_full_name(@name) = 0)
    BEGIN
        RAISERROR('The specified object is not fully qualified. It must be in the following format: [server].[catalog].[schema].[object]'
                , 16-- Severity: Levels 11-16 for errors that can be corrected by user
                , 1 -- State
                ) WITH NOWAIT
        RETURN 0
    END

    -- parse name
	DECLARE @server sysname
    SET @server = dbo.sqlcorlib_format_full_name(@name, '@server')

    DECLARE @catalog sysname
    SET @catalog = dbo.sqlcorlib_format_full_name(@name, '@catalog')

    DECLARE @schema sysname
    SET @schema = dbo.sqlcorlib_format_full_name(@name, '@schema')

    DECLARE @table sysname
    SET @table = dbo.sqlcorlib_format_full_name(@name, '@table')

    -- check if exists
    EXEC sp_tables_ex @table_server=@server
                    , @table_catalog=@catalog
                    , @table_schema=@schema
                    , @table_name=@table

    DECLARE @result BIT
    SET @result = CONVERT(BIT, @@ROWCOUNT)

    RETURN @result

END
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

