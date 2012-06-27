IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sqlcorlib_dequote_name]') AND xtype IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [dbo].[sqlcorlib_dequote_name]
GO
/*******************************************************************************

    Name:           sqlcorlib_dequote_name
    Description:    Dequotes the specified quoted name.

    Usage Notes:
    (1)  this function will only work on names quoted with brackets. Ex: [object]

    Design Notes:
    (1)  the 'name' parameter is of type nvarchar(258)
         as this is the return type of the built-in SQL function 'quotename'

********************************************************************************/
CREATE FUNCTION sqlcorlib_dequote_name
(
    @name nvarchar(258)     -- the name to dequote
)
RETURNS sysname
AS
BEGIN

    -- dequote
    Declare @dequoted_name nvarchar(258)
    Set @dequoted_name = @name

    SET @dequoted_name = REPLACE(@dequoted_name, '[', '')
    SET @dequoted_name = REPLACE(@dequoted_name, ']', '')

    -- return the formatted name
	RETURN @dequoted_name

END
GO
