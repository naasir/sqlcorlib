IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgf_generate_full_name]') AND xtype IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [dbo].[sgf_generate_full_name]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************************
**
** Name:            sgf_generate_full_name
**
** Purpose:         generates a quoted four-part name for a database object
**
** Usage:
** select dbo.sgf_generate_full_name('myserver', 'mydatabase', 'dbo', 'mytable')
** returns> [MYSERVER].[MYDATABASE].[DBO].[MYTABLE]
**
** select dbo.sgf_generate_full_name(default, default, default, 'trip')
** returns> [BIGAPPLE].[ADEPT40].[DBO].[TRIP]
**
** Modifications:
** 04/17/2009       nramji      Original coding.
** 
********************************************************************************/
CREATE FUNCTION sgf_generate_full_name 
(
	-- Add the parameters for the function here
	@server sysname = NULL
	, @catalog sysname = NULL
	, @schema sysname = 'dbo'
	, @table sysname
)
RETURNS sysname
AS
BEGIN

    -- handle defaults
    SET @server = COALESCE(@server, @@SERVERNAME)
    SET @catalog = COALESCE(@catalog, DB_NAME())
    
    -- validate input for empty strings
    IF (LEN(@server) = 0) 
    OR (LEN(@catalog) = 0) 
    OR (LEN(@schema) = 0) 
    OR (LEN(@table) = 0)
    BEGIN
        RETURN ''
    END
    
    -- de-quote all the parameters (in case they are already quoted)
    SET @server = dbo.sgf_dequotename(@server)
    SET @catalog = dbo.sgf_dequotename(@catalog)
    SET @schema = dbo.sgf_dequotename(@schema)
    SET @table = dbo.sgf_dequotename(@table)
    
    -- format
	DECLARE @full_name sysname
	SELECT @full_name = (SELECT QUOTENAME(UPPER(@server)) + '.' + 
                                QUOTENAME(UPPER(@catalog)) + '.' + 
                                QUOTENAME(UPPER(@schema)) + '.' + 
                                QUOTENAME(UPPER(@table)))

	-- Return the result of the function
	RETURN @full_name

END
GO

