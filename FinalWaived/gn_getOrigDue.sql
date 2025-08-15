CREATE FUNCTION dbo.fn_getOrigDuedate
(
    @ACC VARCHAR(22)
)
RETURNS TABLE
AS
RETURN
(
    WITH RecCTE AS 
    (
        SELECT 
            ln.cid,
            ce.CENTER_MEET_DAY,
            lo.*, 
            lo.duedate AS CorrectDueDate
        FROM LoanInst lo
        INNER JOIN lnmaster ln ON ln.acc = lo.acc
        INNER JOIN customer c ON c.cid = ln.cid
        INNER JOIN center ce ON ce.CENTER_CODE = c.CENTER_CODE
        WHERE lo.acc = @ACC AND lo.dnum = 1

        UNION ALL

        SELECT 
            ln.CID,
            ce.CENTER_MEET_DAY,
            lo.*,
            CASE 
                WHEN (DATEPART(MONTH, NextDate) = 12 AND DATEPART(DAY, NextDate) >= 21)
                  OR (DATEPART(MONTH, NextDate) = 1 AND DATEPART(DAY, NextDate) <= 4)
                THEN DATEADD(DAY, DATEDIFF(DAY, NextDate, DATEFROMPARTS(
                        CASE WHEN DATEPART(MONTH, NextDate) = 12 
                             THEN YEAR(NextDate) + 1 ELSE YEAR(NextDate) END,
                        1, 5)), NextDate)
                ELSE NextDate
            END AS CorrectDueDate
        FROM LoanInst lo
        INNER JOIN lnmaster ln ON ln.acc = lo.acc
        INNER JOIN customer c ON c.cid = ln.cid
        INNER JOIN center ce ON ce.CENTER_CODE = c.CENTER_CODE
        INNER JOIN RecCTE prev 
            ON prev.acc = lo.acc
           AND prev.dnum = lo.dnum - 1
        CROSS APPLY (
            SELECT CASE 
                WHEN ln.Frequency IN (0,50) THEN DATEADD(DAY,   7, prev.CorrectDueDate)
                WHEN ln.Frequency IN (1,12) THEN DATEADD(MONTH, 1, prev.CorrectDueDate)
                WHEN ln.Frequency IN (2,24) THEN DATEADD(DAY,  14, prev.CorrectDueDate)
                ELSE DATEADD(DAY, 7, prev.CorrectDueDate)
            END
        ) AS X(NextDate)
    )
    SELECT 
        dnum, acc, duedate, instflag, prin, intr, oth, penalty, endbal, endint, endoth,
        instpd, penpd, carval, upint, servFee, Pledgeamort, amort_oth, balance_oth,
        DATEADD(DAY, CENTER_MEET_DAY + 1 - DATEPART(WEEKDAY, CorrectDueDate), CorrectDueDate) AS OrigDueDt
    FROM RecCTE
)
