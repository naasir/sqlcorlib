IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sqlcorlib_is_same_table]') AND xtype IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [dbo].[sqlcorlib_is_same_table]
GO
/*******************************************************************************

    Name:           sqlcorlib_is_same_table
    Description:    Checks if the column definitions of two tables are equal.

    Example:
    select dbo.sqlcorlib_is_same_table('table_a', 'table_b')
    returns> 0 if not equal, 1 if equal

    Usage Notes:
    (1) currently does NOT handle comparing temp tables

    Design Notes:
    (1) Inspired by Jeff Smith's snippet:
    http://weblogs.sqlteam.com/jeffs/archive/2004/11/10/2737.aspx

    TODO:
    (1) handle comparing temp tables?

********************************************************************************/
CREATE FUNCTION sqlcorlib_is_same_table
(
    @table_a sysname,
    @table_b sysname
)
RETURNS BIT
AS
BEGIN

    DECLARE @isEqual BIT

    IF EXISTS(  SELECT MIN(TableName), column_name
                FROM
                    (SELECT 'Table A' AS TableName
                    , a.column_name
                    , a.ordinal_position
                    , a.column_default
                    , a.is_nullable
                    , a.data_type
                    , a.character_maximum_length
                    , a.character_octet_length
                    , a.numeric_precision
                    , a.numeric_precision_radix
                    , a.numeric_scale
                    , a.datetime_precision
                    FROM information_schema.columns a
                    WHERE table_name = @table_a

                    UNION ALL

                    SELECT 'Table B' AS TableName
                    , b.column_name
                    , b.ordinal_position
                    , b.column_default
                    , b.is_nullable
                    , b.data_type
                    , b.character_maximum_length
                    , b.character_octet_length
                    , b.numeric_precision
                    , b.numeric_precision_radix
                    , b.numeric_scale
                    , b.datetime_precision
                    FROM information_schema.columns b
                    WHERE table_name = @table_b

                    ) tmp

                GROUP BY column_name
                , ordinal_position
                , column_default
                , is_nullable
                , data_type
                , character_maximum_length
                , character_octet_length
                , numeric_precision
                , numeric_precision_radix
                , numeric_scale
                , datetime_precision
                HAVING COUNT(*) = 1)

    BEGIN
        SET @isEqual = 0
    END

    ELSE
    BEGIN
        SET @isEqual = 1
    END

    RETURN @isEqual

END
GO
