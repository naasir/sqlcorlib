IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sgp_drop_tables]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_drop_tables]
GO
/*******************************************************************************

    Name:           sgp_drop_tables
    Description:    drops all (or a subset) of the tables in the database.

    Usage Notes:
    (1) Use the 'pattern' parameter to drop all or a subset of tables,
        for example, those that may start with a prefix.
    
        To drop all: @pattern = '%'
        To drop a subset @pattern = 'mmt_%'
        
    Design Notes:
    (1) 
    
    
    TODO:
    (1)
    
    History:
    09/09/2009      nramji      Original Coding.
    09/10/2009      nramji      Made 'pattern' parameter required, rather than optional, 
                                to make it harder to accidentally drop all.
    10/30/2009      nramji      Removed dependency on sgp_drop_table;
                                that sproc was designed to drop temp tables too, 
                                which is functionality we don't really need here.
    
********************************************************************************/
CREATE PROCEDURE sgp_drop_tables
    @pattern sysname        -- pattern to define which tables to drop
    , @debug INT = 0        -- (optional) output the dynamic sql text, without executing
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(4000)
    Set @sql = N'SELECT 
        ''DROP TABLE ['' + TABLE_NAME + '']''
    FROM information_schema.tables
    WHERE TABLE_NAME LIKE {pattern}
    AND TABLE_TYPE = ''BASE TABLE'''

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