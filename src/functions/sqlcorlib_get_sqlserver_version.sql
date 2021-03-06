IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sqlcorlib_get_sqlserver_version]') AND xtype IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [dbo].[sqlcorlib_get_sqlserver_version]
GO
/*******************************************************************************

    Name:           sqlcorlib_get_sqlserver_version
    Description:    Gets the major version number of the running sql server instance.

    Usage Notes:
    (1) The function will return an int of the major version number:
        8   = SQL Server 2K
        9   = SQL Server 2K5
        10  = SQL Server 2K8
        .
        .
        .

    Design Notes:
    (1) Tested on SQL2K and SQL2K8

    TODO:
    (1)

********************************************************************************/
CREATE FUNCTION sqlcorlib_get_sqlserver_version
(
)
RETURNS INT
AS
BEGIN

    --SERVERPROPERTY('productversion') returns an nvarchar(128)
	Declare @sqlversion nvarchar(128)
	set @sqlversion = convert(nvarchar, SERVERPROPERTY('productversion'))

	--extract just the major number
	set @sqlversion = LEFT(@sqlversion, charindex('.', @sqlversion) - 1)

	-- Return the result as an int
	DECLARE @Result int
	set @Result = convert(int, @sqlversion)

	RETURN @Result

END
GO
