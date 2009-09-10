IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sgf_is_full_name]') AND xtype IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [dbo].[sgf_is_full_name]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************

    Name:           sgf_is_full_name
    Description:    checks whether the input string is a fullly qualified object identifier

    Usage Notes:
    (1) The function will return 1 for true, 0 for false.
    (2) A valid full name has the following format:
        [x].[x].[x].[x]
        where x is one or more characters, each surrounded by brackets (quoted identifiers)
    
    Design Notes:
    (1)
    
    TODO:
    (1)
    
    History:
    05/09/2009       nramji      Original Coding.
    
********************************************************************************/
CREATE FUNCTION sgf_is_full_name
(
    @string NVARCHAR(512)
)
RETURNS BIT
AS
BEGIN

    DECLARE @result BIT
    IF @string LIKE '[[]_%].[[]_%].[[]_%].[[]_%]'
        SET @result = 1
    ELSE
        SET @result = 0
        
    RETURN @result

END
GO



