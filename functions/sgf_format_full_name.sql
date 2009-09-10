IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgf_format_full_name]') AND xtype IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [dbo].[sgf_format_full_name]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************************
**
** Name:            sgf_format_full_name
**
** Purpose:         format a fully qualified database object name
**
** Usage:       
** select dbo.sgf_format_full_name('[bigapple].[adept40].[dbo].[trip]', '@schema.@table')
** returns> dbo.trip
**
** select dbo.sgf_format_full_name('[bigapple].[adept40].[dbo].[trip]', '[@server]')
** returns> [bigapple]
**
** Usage Notes:
** (1)  'pattern' parameter acknowledges the following key words:
**      @server, @catalog, @schema, @table
**
** Modifications:
** 04/24/2009       nramji      Original coding.
** 
** TODO:
** 04/27/2009       nramji      Validate input?
** 04/27/2009       nramji      Handle 3-part and 2-part names? (might have to search right-to-left for delimiters)
********************************************************************************/
CREATE FUNCTION sgf_format_full_name
(
	-- Add the parameters for the function here
    @name NVARCHAR(512),
    @pattern NVARCHAR(128) = N'[@server].[@catalog].[@schema].[@table]'
)
RETURNS NVARCHAR(512)
AS
BEGIN

    DECLARE @delimiter NVARCHAR(10)
    SET @delimiter = '%.%'
    
	DECLARE @delimiter_index INT
	
	-- append a period since this is our delimiter
    DECLARE @text NVARCHAR(512)
    SET @text = @name + '.'
    
    -- dequote
    SET @text = dbo.sgf_dequotename(@text)

    -- parse the qualified name
    DECLARE @server sysname
    SET @delimiter_index = PATINDEX(@delimiter, @text)
    SET @server = LEFT(@text, @delimiter_index - 1)
    SET @text = SUBSTRING(@text, @delimiter_index + 1, LEN(@text))
    
    DECLARE @catalog sysname
    SET @delimiter_index = PATINDEX(@delimiter, @text)
    SET @catalog = LEFT(@text, @delimiter_index - 1)
    SET @text = SUBSTRING(@text, @delimiter_index + 1, LEN(@text))
    
    DECLARE @schema sysname
    SET @delimiter_index = PATINDEX(@delimiter, @text)
    SET @schema = LEFT(@text, @delimiter_index - 1)
    SET @text = SUBSTRING(@text, @delimiter_index + 1, LEN(@text))
    
    DECLARE @table sysname
    SET @delimiter_index = PATINDEX(@delimiter, @text)
    SET @table = LEFT(@text, @delimiter_index - 1)
    SET @text = SUBSTRING(@text, @delimiter_index + 1, LEN(@text))
    
	-- substitute the variables in the pattern
	DECLARE @result NVARCHAR(512)
	SET @result = @pattern
	SET @result = REPLACE(@result, '@server', @server)
	SET @result = REPLACE(@result, '@catalog', @catalog)
	SET @result = REPLACE(@result, '@schema', @schema)
	SET @result = REPLACE(@result, '@table', @table)

    -- return the formatted name
	RETURN @result

END
GO

