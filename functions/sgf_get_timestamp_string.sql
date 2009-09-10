IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgf_get_timestamp_string]') AND xtype IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [dbo].[sgf_get_timestamp_string]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************************
**
** Name:            sgf_get_timestamp_string
** Purpose:         return the current timestamp as a string
**
** Usage:
** select dbo.sgf_get_timestamp_string(getdate())
** returns> Apr_29_2009__1_33_24PM
**
** Usage Notes:
** (1)  returned string is delimited with underscores
**      and thus safe to append to object names without the need to quote them
** (2)  returned string is in custom format: mon_dd_yyyy_hh_mm_ssAM(or PM)
**
** Design Notes:
** (1)  can't call getdate() within a UDF, so we have to pass in the time
**
** Modifications:
** 04/27/2009       nramji      Original coding.
** 
********************************************************************************/
CREATE FUNCTION sgf_get_timestamp_string
(
    @timestamp datetime
)
RETURNS sysname
AS
BEGIN
    
    -- convert style of 109 yields the following format:
    -- mon dd yyyy hh:mi:ss:mmmAM (or PM)
    Declare @timestamp_string sysname
    Set @timestamp_string = convert(varchar, @timestamp, 109)
    
    -- replace unsafe characters with an underscore
    Declare @delimiter nvarchar(1)
    Set @delimiter = N'_'
    Set @timestamp_string = replace(@timestamp_string, ' ', @delimiter)
    Set @timestamp_string = replace(@timestamp_string, '-', @delimiter)
    Set @timestamp_string = replace(@timestamp_string, ':', @delimiter)

    -- trim off milliseconds
    -- (don't need that much precision, and it makes filenames longer)
    set @timestamp_string = stuff(@timestamp_string, 21, 4, '')
    
    -- return the formatted string
	RETURN @timestamp_string

END
GO

