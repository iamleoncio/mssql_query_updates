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
    SELECT   
        DATEADD(DAY, 7 * (n.n - 1), DATEADD(DAY, -21, l.duedate)) AS duedate,  
        CASE n.n  
            WHEN 1 THEN CEILING(l.intr * 0.35)  
            WHEN 2 THEN CEILING(l.intr * 0.30)  
            WHEN 3 THEN CEILING(l.intr * 0.20)  
            ELSE l.intr - (CEILING(l.intr * 0.35) + CEILING(l.intr * 0.30) + CEILING(l.intr * 0.20))  
        END AS smIntr  
    FROM loaninst l  
    JOIN lnmaster lm ON l.acc = lm.acc  
    JOIN (VALUES (1), (2), (3), (4)) AS n(n) ON 1 = 1  
    WHERE l.acc = @acc  
      AND lm.frequency IN (1, 12)  
  
    UNION ALL  
    SELECT   
        DATEADD(DAY, -7, l.duedate) AS duedate,    
        CEILING(l.intr * 0.6) AS smIntr  
    FROM loaninst l    
    JOIN lnmaster lm ON l.acc = lm.acc    
    WHERE l.acc = @acc  
      AND lm.frequency IN (2, 24)  
  
    UNION ALL   
  
    SELECT   
        l.duedate,    
        l.intr - CEILING(l.intr * 0.6) AS smIntr    
    FROM loaninst l    
    JOIN lnmaster lm ON l.acc = lm.acc    
    WHERE l.acc = @acc  
      AND lm.frequency IN (2, 24)  
    ) x    
    inner join lnmaster ln on ln.acc =@acc ,ORGPARMS    
    WHERE x.duedate > EBSYSDATE + 6 - DATEPART(dw, EBSYSDATE) and x.duedate<=ln.DOMATURITY + 6 - Datepart(dw,ln.domaturity)     
    RETURN ISNULL(@smIntr, 0)    
END 