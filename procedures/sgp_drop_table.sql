IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgp_drop_table]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sgp_drop_table]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************
**
** Name:            sgp_drop_table
**
** Purpose:         Drop the specified table if it exits
**
** Modifications:
** 04/21/2009       nramji      Original coding.
** 04/30/2009       nramji      Now handles quoted names.
**
** TODO:
** 
********************************************************************************/
CREATE PROCEDURE sgp_drop_table

	@table sysname          -- the name of the table to drop                

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(500)
    SET @sql = N' DROP TABLE {table}'
    SET @sql = REPLACE(@sql, '{table}', @table)
    
    -- check for normal table
    IF EXISTS (SELECT * 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE table_name = dbo.sgf_dequotename(@table))
    BEGIN
        EXEC sp_executesql @sql
    END
    
    
    -- check for temp table
    ELSE
    BEGIN
        IF object_id('tempdb..' + @table) IS NOT NULL
        BEGIN
            EXEC sp_executesql @sql
        END
    END

END
GO

