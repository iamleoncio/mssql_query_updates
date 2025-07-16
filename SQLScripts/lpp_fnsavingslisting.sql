CREATE OR REPLACE FUNCTION lpp_fnsavingslisting(p_date1 DATE, p_date2 DATE, p_brcode TEXT)
RETURNS TABLE (
    brcode character varying(2),
    cid BIGINT,
    acc character varying(22),
    begbal decimal(10,2),
    depositcount BIGINT,
    deposit decimal(10,2),
    withdrawcount BIGINT,
    withdrawals decimal(10,2),
    new_actcount INTEGER,
    closedcount BIGINT,
    closed decimal(10,2),
    interestcount BIGINT,
    interest decimal(10,2),
    taxcount BIGINT,
    tax decimal(10,2),
    incomecount INTEGER,
    income INTEGER,
    other INTEGER,
    othercount INTEGER,
    endbal decimal(10,2),
    doentry DATE,
    dopen DATE,
    dolasttrn DATE,
    maturity DATE,
    date1 DATE,
    date2 DATE,
    intrate DECIMAL(10,2),
    balance decimal(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
RETURN QUERY
WITH savtrn AS (
    SELECT 
        s.brcode,
        s.cid,
        s.acc,
        s.balance 
            - SUM(
                CASE  
                    WHEN st.trndate > p_date1 AND st.trnType % 2 = 0 AND st.pendapprove = 'A' THEN -st.trnamt
                    WHEN st.trndate > p_date1 AND st.pendapprove = 'A' THEN st.trnamt
                    ELSE 0 
                END
            ) AS begbal,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType % 2 <> 0 THEN 1 ELSE 0 END) AS depositcount,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType % 2 <> 0 THEN st.trnamt ELSE 0 END) AS deposit,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType % 2 = 0 THEN 1 ELSE 0 END) AS withdrawcount,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType % 2 = 0 THEN st.trnamt ELSE 0 END) AS withdrawals,
        0 AS new_actcount,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType = 506 THEN 1 ELSE 0 END) AS closedcount,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType = 506 THEN st.trnamt ELSE 0 END) AS closed,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType = 233 THEN 1 ELSE 0 END) AS interestcount,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType = 233 THEN st.trnamt ELSE 0 END) AS interest,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType = 234 THEN 1 ELSE 0 END) AS taxcount,
        SUM(CASE WHEN st.trndate BETWEEN p_date1 AND p_date2 AND st.trnType = 234 THEN st.trnamt ELSE 0 END) AS tax,
        0 AS incomecount,
        0 AS income,
        0 AS other,
        0 AS othercount,
        s.balance 
            - SUM(
                CASE  
                    WHEN st.trndate > p_date2 AND st.trnType % 2 = 0 AND st.pendapprove = 'A' THEN -st.trnamt
                    WHEN st.trndate > p_date2 AND st.pendapprove = 'A' THEN st.trnamt
                    ELSE 0 
                END
            ) AS endbal,
        MIN(CASE WHEN st.trntype = 3 THEN st.trndate END) AS doentry,
        s.dopen,
        s.dolasttrn,
        DATE '1900-01-01' AS maturity,
        p_date1 AS date1,
        p_date2 AS date2,
        2.5::DECIMAL(10,2) AS intrate,
        s.balance
    FROM staging.satrnmaster st
    INNER JOIN staging.samaster s 
        ON s.acc = ltrim(st.acc) AND s.brcode = st.brcode
    WHERE st.brcode = p_brcode
    GROUP BY s.brcode, s.cid, s.acc, s.balance, s.dopen, s.dolasttrn
)
SELECT *
FROM savtrn s
WHERE (
        s.dopen <= s.date2 AND NOT (s.endbal = 0 AND (s.dolasttrn < s.date1 OR s.dolasttrn > s.date2))
    )
    OR (s.doentry > s.date2 - INTERVAL '8 days' AND s.doentry <= s.date2)
    OR s.endbal > 0
    OR s.dopen BETWEEN s.date1 AND s.date2;
END;
$$;