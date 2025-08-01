--select dbo.fn_semimonthly('03xx-4016-0000004')  
  
CREATE FUNCTION dbo.fn_SemiMonthly  
(  
    @acc VARCHAR(22)  
)  
RETURNS NUMERIC(18,2)  
AS  
BEGIN  
    DECLARE @smIntr NUMERIC(18,2)  
  
    SELECT @smIntr = SUM(x.smIntr)  
    FROM (  
        SELECT   DATEADD(DAY, -7, l.duedate) AS duedate,  
            CASE   
                WHEN lm.frequency in  (1,12) THEN CEILING(l.intr / 4.0)  
                WHEN lm.frequency in  (2,24) THEN CEILING(l.intr / 2.0)  
                ELSE 0  
            END AS smIntr  
        FROM loaninst l  
        JOIN lnmaster lm ON l.acc = lm.acc  
        CROSS JOIN orgparms  
        WHERE l.acc = @acc  
        UNION ALL  
        SELECT    
            l.duedate,  
            CASE  
                WHEN lm.frequency = 1 THEN l.intr - CEILING(l.intr / 4.0)  
                WHEN lm.frequency = 2 THEN l.intr - CEILING(l.intr / 2.0)  
                ELSE 0  
            END AS smIntr  
        FROM loaninst l  
        JOIN lnmaster lm ON l.acc = lm.acc  
        CROSS JOIN orgparms  
        WHERE l.acc = @acc  
    ) x  
    inner join lnmaster ln on ln.acc =@acc ,ORGPARMS  
    WHERE x.duedate > EBSYSDATE + 6 - DATEPART(dw, EBSYSDATE) and x.duedate<=ln.DOMATURITY + 6 - Datepart(dw,ln.domaturity)   
    RETURN ISNULL(@smIntr, 0)  
END  
  