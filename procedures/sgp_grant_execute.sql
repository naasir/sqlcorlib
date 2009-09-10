SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sgp_grant_execute]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_grant_execute]
GO
/*******************************************************************************

    Name:           sgp_grant_execute
    Description:    grants the specefied user EXECUTE permission on all* stored procedures

    Usage Notes:
    (1) *Use the 'pattern' parameter to grant permission to only a subset of sprocs,
        for example, those that may start with a prefix.
    
    Design Notes:
    (1) This is a cleaned up version of the procedure found here:
        http://www.sqldbatips.com/showarticle.asp?ID=8
    
    (2) For 2005 and above, this entire procedure is unneccessary, 
        as you can simply add the user to the the built-in db_executor role 
        to achieve the same effect.
    
    TODO:
    (1)
    
    History:
    05/08/2009      nramji      Original Coding.
    05/27/2009      nramji      replaced use of SQL2K-only 'xp_execresultset' sproc,
                                with custom 'sgp_execresultset'
    
********************************************************************************/
CREATE PROCEDURE sgp_grant_execute
    @user sysname           -- the user to grant permission to
    , @pattern sysname = '%'-- (optional) name pattern of procedures to grant permission to
    , @debug INT = 0        -- (optional) print dynamic sql text, without executing
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(4000)
    SET @sql =N'SELECT ''GRANT EXEC ON '' 
                        + QUOTENAME(ROUTINE_SCHEMA) + ''.'' + QUOTENAME(ROUTINE_NAME) 
                        + '' TO {user} '' 
              FROM INFORMATION_SCHEMA.ROUTINES 
              WHERE (OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),''IsMSShipped'') = 0)
              AND ROUTINE_NAME LIKE {pattern}'

    SET @sql = REPLACE(@sql, '{user}', QUOTENAME(@user))
    SET @sql = REPLACE(@sql, '{pattern}', QUOTENAME(@pattern, ''''))
                        
    
    -- if debug, print sql without executing
    IF @debug = 1
    BEGIN
        PRINT @sql
        RETURN
    END
    
    -- execute
    DECLARE @error_code INT
    EXEC @error_code = sgp_execresultset @sql

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

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
