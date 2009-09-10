SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sgp_drop_foreign_keys]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_drop_foreign_keys]
GO
/*******************************************************************************

    Name:           sgp_drop_foreign_keys
    Description:    drops all (or a subset) of the foriegn keys in the database

    Usage Notes:
    (1) Use the 'pattern' parameter to drop foreign keys for all or only a subset of tables,
        for example, those that may start with a prefix.
        
        To drop all: @pattern = '%'
        To drop a subset @pattern = 'mmt_%'
    
    Design Notes:
    (1) Inspired by the script found here:
        http://www.thestidhams.com/tom/wp/2007/07/23/drop-all-foreign-keys/
    
    
    TODO:
    (1)
    
    History:
    05/27/2009      nramji      Original Coding.
    09/10/2009      nramji      Made 'pattern' parameter required, rather than optional, 
                                to make it harder to accidentally drop all.
    
********************************************************************************/
CREATE PROCEDURE sgp_drop_foreign_keys
    @pattern sysname        -- pattern to define the tables to drop foreign keys for
    , @debug INT = 0        -- (optional) output the dynamic sql text, without executing
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(4000)
    Set @sql = N'SELECT 
        ''ALTER TABLE [''+ TABLE_SCHEMA + ''].['' + TABLE_NAME + ''] '' +
        ''DROP CONSTRAINT [''+ CONSTRAINT_NAME + '']''
    FROM information_schema.table_constraints
    WHERE CONSTRAINT_TYPE = ''FOREIGN KEY''
    AND TABLE_NAME LIKE {pattern}'

    set @sql = replace(@sql, '{pattern}', QUOTENAME(@pattern, ''''))
                        
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



