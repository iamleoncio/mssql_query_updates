WITH base AS (
    SELECT 
        ln.cid,
        lo.acc,
        lo.duedate,
        DATEADD(DAY, ce.CENTER_MEET_DAY + 1 - DATEPART(WEEKDAY, lo.duedate), lo.duedate) AS checkdue,
        lo.prin
    FROM loaninst lo
    INNER JOIN lnmaster ln ON ln.acc = lo.acc
    INNER JOIN customer c ON c.cid = ln.cid
    INNER JOIN center ce ON ce.center_code = c.center_code
    LEFT JOIN writeoff w ON w.acc = ln.acc, ORGPARMS
    WHERE ln.status NOT IN (25,20)
      AND w.acc IS NULL
      AND ln.DISBDATE BETWEEN DATEADD(YEAR, -3, EBSYSDATE) AND DATEADD(DAY, -2, EBSYSDATE)
      AND lo.DUEDATE <= DATEADD(DAY, -7, EBSYSDATE)
),
payments AS (
    SELECT 
        acc, 
        trndate, 
        SUM(CASE WHEN trntype IN (3001,3099,3201,3097,3098,3899,3202) THEN prin ELSE 0 END) AS prin
    FROM trnmaster
    GROUP BY acc, trndate
),
base_with_payments AS (
    SELECT 
        b.*,
        (
            SELECT SUM(p.prin)
            FROM payments p
            WHERE p.acc = b.acc 
              AND DATEPART(WEEK, p.trndate) = DATEPART(WEEK, b.checkdue)
              AND DATEPART(YEAR, p.trndate) = DATEPART(YEAR, b.checkdue)
        ) AS paid_this_week
    FROM base b
),
running_check AS (
    SELECT *,
        SUM(prin) OVER (PARTITION BY cid, acc ORDER BY checkdue ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_due,
        SUM(paid_this_week) OVER (PARTITION BY cid, acc ORDER BY checkdue ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_paid
    FROM base_with_payments
),
checkWhitelist AS (
    SELECT 
        cid, acc, checkdue, prin, cumulative_due, cumulative_paid,
        CASE 
            WHEN cumulative_paid >= cumulative_due THEN 0
            ELSE 1
        END AS unpaid_flag
    FROM running_check
),
fn_check AS (
    SELECT cid, SUM(unpaid_flag) AS pdctrl 
    FROM checkWhitelist 
    GROUP BY cid
)
SELECT DISTINCT  
    '' AS newcid, 
    orgname, 
    newbrcode, 
    m.unit, 
    ce.center_name, 
    c.cid, 
    a.phone4, 
    c.cname, 
    c.fname, 
    c.mname, 
    c.dobirth, 
    s.doentry
FROM customer c
LEFT JOIN fn_check cw ON cw.cid = c.cid
LEFT JOIN (
    SELECT s.cid, MIN(trndate) AS doentry 
    FROM samaster s
    INNER JOIN satrnmaster st ON st.acc = s.acc
    WHERE st.trntype = 3  
      AND st.trnamt > 0  
      AND s.balance >= 5 
    GROUP BY s.cid, s.balance
) s ON s.cid = c.cid
LEFT JOIN inActiveCID ia ON ia.cid = c.cid AND ia.inactive = 1 
INNER JOIN center ce ON ce.center_code = c.center_code 
INNER JOIN managers m ON m.mancode = ce.unit
LEFT JOIN addresses a ON a.cid = c.cid
CROSS JOIN orgparms
WHERE DATEDIFF(YEAR, s.doentry, ebsysdate) >= 3
  AND ia.cid IS NULL
  AND (cw.pdctrl = 0 OR cw.cid IS NULL)
