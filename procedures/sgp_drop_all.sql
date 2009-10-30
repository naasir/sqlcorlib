IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sgp_drop_all]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_drop_all]
GO
/*******************************************************************************

    Name:           sgp_drop_all
    Description:    drops all (or a subset) of objects in the database.

    Usage Notes:
    (1) Use the 'pattern' parameter to drop all or a subset of objects,
        for example, those that may start with a prefix.
    
        To drop all: @pattern = '%'
        To drop a subset @pattern = 'mmt_%'
    
    Design Notes:
    (1) This procedure will drop (in-order):
        - foreign-keys
        - tables
        - procedures
        - functions
        - views

    TODO:
    (1) May want to expand this to drop UDTs (user-defined types)
         
    History:
    10/30/2009      nramji      Original coding.
        
********************************************************************************/
CREATE PROCEDURE sgp_drop_all
    @pattern sysname        -- pattern to define which tables to drop
    , @debug INT = 0        -- (optional) output the dynamic sql text, without executing
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    EXEC sgp_drop_foreign_keys  @pattern = @pattern, @debug = @debug
    EXEC sgp_drop_tables        @pattern = @pattern, @debug = @debug
    EXEC sgp_drop_procedures    @pattern = @pattern, @debug = @debug
    EXEC sgp_drop_functions     @pattern = @pattern, @debug = @debug
    EXEC sgp_drop_views         @pattern = @pattern, @debug = @debug
	
END
GO