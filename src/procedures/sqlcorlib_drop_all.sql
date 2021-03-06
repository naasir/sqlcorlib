IF EXISTS (SELECT * FROM dbo.sysobjects WHERE Id = OBJECT_ID(N'[dbo].[sqlcorlib_drop_all]') AND OBJECTPROPERTY(Id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sqlcorlib_drop_all]
GO
/*******************************************************************************

    Name:           sqlcorlib_drop_all
    Description:    drops all (or a subset) of objects in the database.

    Dependencies:
    (1) sqlcorlib_drop_foreign_keys
    (2) sqlcorlib_drop_functions
    (3) sqlcorlib_drop_procedures
    (4) sqlcorlib_drop_tables
    (5) sqlcorlib_drop_triggers
    (6) sqlcorlib_drop_views

    Usage Notes:
    (1) Use the 'pattern' parameter to drop all or a subset of objects,
        for example, those that may start with a prefix.

        To drop all: @pattern = '%'
        To drop a subset @pattern = 'mmt_%'

    Design Notes:
    (1) This procedure will drop (in-order):
        - views
        - foreign-keys
        - triggers
        - tables
        - procedures
        - functions

    TODO:
    (1) May want to expand this to drop UDTs (user-defined types)

********************************************************************************/
CREATE PROCEDURE sqlcorlib_drop_all
    @pattern sysname        -- pattern to define which tables to drop
    , @debug INT = 0        -- (optional) output the dynamic sql text, without executing
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    EXEC sqlcorlib_drop_views           @pattern = @pattern, @debug = @debug
    EXEC sqlcorlib_drop_foreign_keys    @pattern = @pattern, @debug = @debug
    EXEC sqlcorlib_drop_triggers        @pattern = @pattern, @debug = @debug
    EXEC sqlcorlib_drop_tables          @pattern = @pattern, @debug = @debug
    EXEC sqlcorlib_drop_procedures      @pattern = @pattern, @debug = @debug
    EXEC sqlcorlib_drop_functions       @pattern = @pattern, @debug = @debug

END
GO
