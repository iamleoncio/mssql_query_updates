CREATE FUNCTION [dbo].[EVC_USERTOTAL]()                  
RETURNS @TEMP TABLE (                  
     ACCT_TYPE  INT,                  
        ACCT_DESC  varchar(100),                  
        ACCT_DRAMT  Numeric(14,2),                  
        ACCT_CRAMT Numeric(14,2),                  
 ACCT_CASH  INT)                  
AS                  
BEGIN                  
Declare @user as varchar(15)                  
Declare @dyte as Datetime                  
Set @dyte = (Select ebsysdate from orgparms)                  
Set @user = (Select Act_user from Actref)                  
--Set @user = 'adeleon'                  
INSERT INTO @TEMP                    
select 0,'Begining Balance',beg_balance,0,1 from saf where tlrname IN (@USER)                  
INSERT INTO @TEMP                     
SELECT 1,'Deposit->'+AcctDesc + ' (' +  Particulars + ')' ,                  
    Sum(Case WHEN TrnType%2 = 0 THEN -TrnAmt ELSE TrnAmt END) AS DEBIT,0 CREDIT,1                   
   FROM             
   (select acc,TrnType,TrnAmt,             
   case when Particulars like '%Loan Disburesement from%'  then 'Loan Disburesement' else PARTICULARS end PARTICULARS,TRNDATE,            
   USERNAME,PENDAPPROVE,trn,orno            
   from SATRNMASTER ) t                  
       INNER JOIN saMaster m on m.Acc = t.Acc                  
       INNER JOIN AcctParms y on y.AcctType = m.Type                  
       LEFT JOIN SACOCIDATA on t.trn = sacocidata.trn                  
            and t.TRNDATE = SACOCIDATA.TRNDATE                   
   WHERE t.TRNTYPE in (1,3,13,5)                  
     AND (t.TRNDATE = @dyte) and not (Particulars = 'Loan Release' OR (Particulars like 'Excess %' AND ORNo = 0))                  
     AND (UPPER(t.USERNAME) IN (@USER,'CAGABAY')) AND t.PENDAPPROVE ='A'                   
     AND ISNull(SACOCIDATA.COCICODE,0) = 0                   
--      AND  TrnMnem_CD in ( Select Gl_mnem_code from Gl_auto_entry                   
--                                  where GL_APPTYPE = 0 and Gl_acct_Codes = '1-1-02-01-01-00' )                  
                                
  GROUP BY AcctDesc, Particulars                  
INSERT INTO @TEMP                    
SELECT 2,'Cancel Deposit->'+AcctDesc,0,                   
         Sum(Case WHEN TrnType%2 = 0 THEN TrnAmt ELSE -TrnAmt END), 1                  
    FROM SATRNMASTER t                  
       INNER JOIN saMaster m on m.Acc = t.Acc                  
       INNER JOIN AcctParms y on y.AcctType = m.Type                  
    WHERE (TRNTYPE = 227) AND (TRNDATE = @dyte) AND (UPPER(USERNAME) IN (@USER,'CAGABAY'))                  
          AND PENDAPPROVE ='A'                   
    group by AcctDesc                  
INSERT INTO @TEMP                    
SELECT 2,'Close->'+AcctDesc,0 ,                   
       Sum(Case WHEN TrnType%2 = 0 THEN TrnAmt ELSE -TrnAmt END) , 1                  
   FROM SATRNMASTER t                  
       INNER JOIN saMaster m on m.Acc = t.Acc                  
       INNER JOIN AcctParms y on y.AcctType = m.Type                  
   WHERE (TRNTYPE = 506) AND (TRNDATE = @dyte) AND (UPPER(USERNAME) IN (@USER,'CAGABAY'))                  
        AND PENDAPPROVE ='A'                   
   group by AcctDesc                  
INSERT INTO @TEMP                    
SELECT 2,'Cash Withdrawal->'+AcctDesc,0 ,                   
       Sum(Case WHEN TrnType%2 = 0 THEN TrnAmt ELSE -TrnAmt END) , 1                  
   FROM SATRNMASTER t                  
       INNER JOIN saMaster m on m.Acc = t.Acc                  
       INNER JOIN AcctParms y on y.AcctType = m.Type                  
   WHERE TRNTYPE in (2,214,560) AND (TRNDATE = @dyte) AND (UPPER(USERNAME) IN (@USER,'CAGABAY'))                  
         AND PENDAPPROVE ='A'                   
   group by AcctDesc                  
INSERT INTO @TEMP                    
SELECT 1,'CA Cash Deposit', isnull(SUM(t.TRNAMT),0) , 0 ,1 FROM                   
   CATRNMASTER t                   
       LEFT JOIN CACOCIDATA c on c.trn = t.trn and t.TrnDate = c.TrnDate                  
WHERE t.TRNTYPE in (1001, 1013, 1013, 1003)                   
      AND (t.TRNDATE = @dYte) AND UPPER(t.USERNAME) IN (@USER,'CAGABAY')                  
      AND IsNull(CociCode,0) = 0                   
INSERT INTO @TEMP                    
SELECT 2,'CA Withdrawal',0 , isnull(SUM(TRNAMT),0) ,1  FROM CATRNMASTER                   
where (TRNTYPE = 1002 OR TRNTYPE = 1004 OR TRNTYPE = 1028 OR TRNTYPE = 1008)                   
AND (TRNDATE = @dyte) AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE = 'A'                  
INSERT INTO @TEMP                    
SELECT 1,'Collection->'+AcctDesc , isnull(SUM(a.Prin+a.IntR),0), 0 ,1                  
  FROM trnmaster a                  
     INNER JOIN lnMaster m on m.Acc = a.Acc                  
     INNER JOIN AcctParms y on m.AcctType = y.AcctType                  
  WHERE trntype IN (3001, 3099, 3097) AND (trndate = @dyte) AND (UPPER(username) IN (@USER,'CAGABAY'))                   
   group by AcctDesc                  
INSERT INTO @TEMP                    
-- SELECT 2, 'Releases-'+AcctDesc,0,  isnull(SUM(m.NetProceeds),0) ,1                  
-- FROM lnMaster m on m.Acc = a.Acc                  
--    INNER JOIN AcctParms y on m.AcctType = y.AcctType                  
-- WHERE m.DisbDate = @Dyte                  
--       AND UPPER(a.DisbBy) IN (@USER,'CAGABAY')                  
-- GROUP BY AcctDesc                  
SELECT 2, 'Releases->'+AcctDesc,0,  isnull(SUM(m.NetProceed),0) ,1                  
FROM lnMaster m                   
   INNER JOIN AcctParms y on m.AcctType = y.AcctType                  
WHERE m.DisbDate = @Dyte                  
      AND UPPER(DisbBy) IN (@USER,'CAGABAY') and Status in (30,91,98,99)                  
GROUP BY AcctDesc                  
INSERT INTO @TEMP                    
SELECT 1,'Cancel Collection->'+AcctDesc ,0, isnull(SUM(trnamt),0) ,1                  
   FROM trnmaster  a                  
    INNER JOIN lnMaster m on m.Acc = a.Acc                  
       INNER JOIN AcctParms y on m.AcctType = y.AcctType                  
   WHERE trntype IN (3098) AND (trndate = @dyte) AND (UPPER(username) IN (@USER,'CAGABAY'))                   
group by AcctDesc                  
--SELECT 1,'loan Void Release',isnull(SUM(TRNMASTER.TRNAMT),0) AS 'TOTAL'                   
--FROM TRNMASTER,COCIDATA WHERE (trnmaster.trn = cocidata.trn)                   
--and (COCIDATA.COCICODE = 0) and TRNMASTER.TRNTYPE = 3199 AND                   
--(TRNMASTER.TRNDATE = @dyte) AND (UPPER(TRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                  
-- and (CASHITEM = 1)                  
INSERT INTO @TEMP                    
SELECT 1,'Tiwala Cash Deposits',isnull(SUM(TDTRNMASTER.TRNAMT),0), 0 ,1                  
FROM TDTRNMASTER,TDCOCIDATA WHERE (TDtrnmaster.trn = TDcocidata.trn)                  
and (TDCOCIDATA.COCICODE = 0) and (TDTRNMASTER.TRNTYPE = 2021                   
OR TDTRNMASTER.TRNTYPE = 2001 OR TDTRNMASTER.TRNTYPE = 2013                   
OR TDTRNMASTER.TRNMNEM_CD = 96  OR TDTRNMASTER.TRNTYPE = 2017                   
OR TDTRNMASTER.TRNTYPE = 2025) AND (TDTRNMASTER.TRNMNEM_CD <> 21                   
AND TDTRNMASTER.TRNMNEM_CD <> 22) AND TDTRNMASTER.TRNDATE = TDCOCIDATA.TRNDATE                   
AND (TDTRNMASTER.TRNDATE = @dyte) AND (UPPER(TDTRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                  
INSERT INTO @TEMP                    
SELECT 2,'Tiwala Cash withdrawal',0 ,isnull(SUM(TRNAMT),0) ,1                  
   FROM TDTRNMASTER                    
   WHERE    (TRNTYPE in (2506,2560,2508) OR TRNMNEM_CD = 41)                  
        AND  TRNMNEM_CD not in (19,18,21,22,23,24)                   
        AND (TRNDATE = @dyte)                   
AND (UPPER(USERNAME) IN (@USER,'CAGABAY'))                  
-- SELECT  1,'Misc. Receipt',isnull(SUM(MISC_TRNMASTER.TRNAMT),0),0 ,1                  
-- FROM MISC_TRNMASTER                  
--      LEFT JOIN MISC_COCIDATA on                   
--            (MISC_trnmaster.trn = MISC_cocidata.trn)                  
--          AND (MISC_COCIDATA.COCICODE = 0)                   
--          AND MISC_TRNMASTER.TRNDATE = MISC_COCIDATA.TRNDATE                   
--          AND MISC_TRNMASTER.TRNAMT = MISC_COCIDATA.AMOUNT                  
--   WHERE MISC_TRNMASTER.TRNTYPE = (7001,7005)                   
--         AND (MISC_TRNMASTER.TRNDATE = @dyte)                  
--         AND (UPPER(MISC_TRNMASTER.USERNAME) IN (@USER,'CAGABAY')) AND MISC_TRNMASTER.PENDAPPROVE ='A'                  
INSERT INTO @TEMP                    
SELECT  1,'Misc. Receipt',isnull(SUM(MISC_TRNMASTER.TRNAMT),0),0 ,1                  
FROM MISC_TRNMASTER                  
  WHERE MISC_TRNMASTER.TRNTYPE in (7001,7005)                   
        AND (MISC_TRNMASTER.TRNDATE = @dyte)                  
        AND (UPPER(MISC_TRNMASTER.USERNAME) IN (@USER,'CAGABAY')) AND MISC_TRNMASTER.PENDAPPROVE ='A'                  
INSERT INTO @TEMP                    
SELECT 2,'Misc. Payment',0,isnull(SUM(TRNAMT),0),1                  
FROM MISC_TRNMASTER  where  (TRNTYPE = 7002 OR TRNTYPE = 7006)  AND (TRNDATE = @dyte)                  
AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE ='A'                   
--/*                  
INSERT INTO @TEMP                    
SELECT 1,'Receive Cash from Cashier',isnull(SUM(TRNAMT),0),0,1                  
FROM MISC_TRNMASTER   where  (TRNTYPE = 9001)   AND (TRNDATE = @dyte)                  
AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE ='A'                   
INSERT INTO @TEMP                    
SELECT 1,'Receive Cash from Teller',isnull(SUM(TRNAMT),0),0,1                  
FROM MISC_TRNMASTER   where  (TRNTYPE = 9003)   AND (TRNDATE = @dyte)                  
AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE ='A'             
INSERT INTO @TEMP                    
SELECT 1,'Receive Cash from Depository',isnull(SUM(TRNAMT),0),0,1                  
FROM MISC_TRNMASTER   where  (TRNTYPE = 9005)   AND (TRNDATE = @dyte)                  
AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE ='A'                   
INSERT INTO @TEMP                    
SELECT 2,'Deliver Cash to Cashier',0,isnull(SUM(TRNAMT),0),1                  
FROM MISC_TRNMASTER   where  (trntype = 9002)  AND (TRNDATE = @dyte)                  
AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE ='A'                   
INSERT INTO @TEMP                    
SELECT 2,'Deliver Cash to Teller',0,isnull(SUM(TRNAMT),0),1                  
FROM MISC_TRNMASTER   where  (trntype = 9004)  AND (TRNDATE = @dyte)                  
AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE ='A'                   
INSERT INTO @TEMP                    
SELECT 2,'Deliver Cash to Depository',0,isnull(SUM(TRNAMT),0),1                  
FROM MISC_TRNMASTER   where  (trntype = 9006)  AND (TRNDATE = @dyte)                  
AND (UPPER(USERNAME) IN (@USER,'CAGABAY')) AND PENDAPPROVE ='A'                   
--*/                  
--SELECT * FROM MISC_TRNMASTER WHERE TRNDATE = '2005-02-11' AND USERNAME = 'CEL'                  
INSERT INTO @TEMP                    
--SELECT 1,'MBA Collection',isnull(SUM(MFAMOUNT),0),0,1 FROM  MUTUAL_FUND                  
--WHERE MFDATE = @DYTE AND MFUID IN (@USER,'CAGABAY') AND MFTEMPFIELD = 3001                
--INSERT INTO @TEMP               
--SELECT 1,'MBA Collection',isnull(SUM(INSAMOUNT),0),0,1 FROM  KATUPARAN_FUND                
--WHERE INSDATE = @DYTE AND INSUID IN (@USER,'CAGABAY') AND INSTEMPFIELD = 3001              
SELECT 1,'MBA Collection',isnull(SUM(MFAMOUNT),0),0,1 FROM               
(              
SELECT isnull(SUM(MFAMOUNT),0)MFAMOUNT FROM  MUTUAL_FUND                  
WHERE MFDATE = @DYTE AND MFUID IN (@USER,'CAGABAY') AND MFTEMPFIELD = 3001                
Union all              
SELECT isnull(SUM(INSAMOUNT),0)MFAMOUNT FROM  KATUPARAN_FUND                
WHERE INSDATE = @DYTE  AND INSUID IN (@USER,'CAGABAY') AND INSTEMPFIELD = 3001              
)a              
INSERT INTO @TEMP                    
SELECT 1,'Penalty Collection',isnull(SUM(AMTPAID),0),0 ,1 FROM multiplepaymentreceipt                  
WHERE PAYMENTDATE = @DYTE AND USERNAME IN (@USER,'CAGABAY') AND REMARKS = 'Penalty Payment'                  
--***********************checks                  
INSERT INTO @TEMP                   
SELECT 1,'SA Check Deposits', isnull(SUM(SACOCIDATA.AMOUNT),0),0,2                   
FROM SACOCIDATA,SATRNMASTER  WHERE (SACOCIDATA.COCICODE > 0)                   
AND SATRNMASTER.TRNTYPE in (1,13)                   
AND (SACOCIDATA.TRNDATE = @DYTE)                   
AND (SATRNMASTER.TRN = SACOCIDATA.TRN) AND (UPPER(SATRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                   
AND (SACOCIDATA.CLEARED = 0 or SACOCIDATA.CLEARED = -1)                   
AND SATRNMASTER.TRNDATE = SACOCIDATA.TRNDATE AND SATRNMASTER.PENDAPPROVE ='A'                  
INSERT INTO @TEMP                   
SELECT 2,'SA Returned Checks', 0,isnull(SUM(AMOUNT),0),2                    
FROM SACOCIDATA,SATRNMASTER WHERE (SACOCIDATA.COCICODE >= 1)                   
AND (SATRNMASTER.TRNTYPE = 210)   AND ( SACOCIDATA.TRNDATE = @DYTE)                  
AND (SACOCIDATA.CLEARED = -1) AND ( SATRNMASTER.TRN = SACOCIDATA.REFNO  )                   
AND SATRNMASTER.TRNDATE = SACOCIDATA.TRNDATE AND (UPPER(SATRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                  
AND SATRNMASTER.PENDAPPROVE ='A'                  
INSERT INTO @TEMP                    
SELECT 1,'CA Check Deposits', isnull(SUM(CACOCIDATA.AMOUNT),0),0,2                   
FROM CACOCIDATA,CATRNMASTER  WHERE (CACOCIDATA.COCICODE > 0)                   
AND(CATRNMASTER.TRNTYPE = 1001  OR CATRNMASTER.TRNTYPE = 1013)                   
AND (CACOCIDATA.TRNDATE = @DYTE) AND (CATRNMASTER.TRN = CACOCIDATA.TRN)                   
AND CATRNMASTER.TRNDATE = CACOCIDATA.TRNDATE AND (UPPER(CATRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                   
AND (CACOCIDATA.CLEARED = 0 or CACOCIDATA.CLEARED = -1)                  
INSERT INTO @TEMP                    
SELECT 2,'CA Returned Checks',0,isnull(SUM(AMOUNT),0),2                    
FROM CACOCIDATA,CATRNMASTER WHERE (CACOCIDATA.COCICODE >= 1)                   
AND (CATRNMASTER.TRNTYPE = 1010)   AND ( CACOCIDATA.TRNDATE = @DYTE)                  
AND (CACOCIDATA.CLEARED = -1) AND (  CATRNMASTER.TRN = CACOCIDATA.REFNO)                  
AND CATRNMASTER.TRNDATE = CACOCIDATA.TRNDATE AND (UPPER(CATRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                  
INSERT INTO @TEMP                    
SELECT 1,'TD Check Deposits',isnull(SUM(TDCOCIDATA.AMOUNT),0),0,2                    
FROM TDCOCIDATA,TDTRNMASTER  WHERE (TDCOCIDATA.COCICODE > 0)                   
AND(TDTRNMASTER.TRNTYPE = 2013 OR TDTRNMASTER.TRNTYPE = 2025                    
OR TDTRNMASTER.TRNTYPE = 2001 or TDTRNMASTER.TRNMNEM_CD = 13                   
OR TDTRNMASTER.TRNMNEM_CD = 4 OR TDTRNMASTER.TRNMNEM_CD = 3)                   
AND (TDCOCIDATA.TRNDATE = @DYTE) AND (TDTRNMASTER.TRN = TDCOCIDATA.TRN)                   
AND TDTRNMASTER.TRNDATE = TDCOCIDATA.TRNDATE AND (UPPER(TDTRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                  
AND (TDCOCIDATA.CLEARED = 0 or TDCOCIDATA.CLEARED = -1 OR TDCOCIDATA.CLEARED = 1 )                  
INSERT INTO @TEMP                    
SELECT 2,'TD Returned Checks',0,isnull(SUM(AMOUNT),0),2                    
FROM TDCOCIDATA,TDTRNMASTER WHERE (TDCOCIDATA.COCICODE >= 1)                   
AND (TDTRNMASTER.TRNTYPE = 2510)   AND ( TDCOCIDATA.TRNDATE = @DYTE)                   
AND (TDCOCIDATA.CLEARED = -1) AND (  TDTRNMASTER.TRN = TDCOCIDATA.REFNO)                   
AND TDTRNMASTER.TRNDATE = TDCOCIDATA.TRNDATE AND (UPPER(TDTRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                  
INSERT INTO @TEMP                    
SELECT 1,'Misc. Check Receipt',isnull(SUM(MISC_COCIDATA.AMOUNT),0),0,2                   
  FROM MISC_TRNMASTER                    
     LEFT JOIN MISC_COCIDATA on                   
         MISC_COCIDATA.COCICODE > 0 and                  
         MISC_TRNMASTER.TRNDATE = MISC_COCIDATA.TRNDATE and                  
         MISC_TRNMASTER.TRN = MISC_COCIDATA.TRN and                  
         MISC_TRNMASTER.TRNAMT = MISC_COCIDATA.AMOUNT                  
  WHERE MISC_TRNMASTER.TRNTYPE in (7001,7003,7005)                  
        AND UPPER(MISC_TRNMASTER.USERNAME) IN (@USER,'CAGABAY')                   
        AND MISC_TRNMASTER.PENDAPPROVE ='A'                  
        AND MISC_TRNMASTER.TrnDate = @DYTE                  
INSERT INTO @TEMP                    
SELECT 2,'Misc. Check Desbursement',0,isnull(SUM(AMOUNT),0),2                   
  FROM MISC_TRNMASTER                   
      LEFT JOIN MISC_COCIDATA ON                   
           MISC_COCIDATA.COCICODE > 0                   
       AND MISC_COCIDATA.CLEARED = 1                  
       AND MISC_TRNMASTER.TRNDATE = MISC_COCIDATA.TRNDATE                   
       AND MISC_COCIDATA.TRN = MISC_TRNMASTER.TRN                  
       AND MISC_COCIDATA.AMOUNT = MISC_TRNMASTER.TRNAMT                  
   WHERE MISC_TRNMASTER.TRNTYPE = 7003                  
      AND (UPPER(MISC_TRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                   
      AND MISC_TRNMASTER.PENDAPPROVE ='A'                  
        AND MISC_TRNMASTER.TrnDate = @DYTE                  
--INSERT INTO @TEMP                    
-- SELECT 2,'CA Inward Total',0,isnull(SUM(TRNAMT),0),2                    
-- FROM CATRNMASTER WHERE UPPER(USERNAME) IN (@USER,'CAGABAY') AND  TRNTYPE = 1016 AND TRNDATE = @DYTE                  
INSERT INTO @TEMP                    
SELECT 1,'CA Cancelled Inward',isnull(SUM(TRNAMT),0) ,0,2                   
FROM CATRNMASTER WHERE UPPER(USERNAME) IN (@USER,'CAGABAY') AND  TRNTYPE = 1030 AND TRNDATE = @DYTE                  
-- REVERSAL                  
INSERT INTO @TEMP                   
SELECT 1,'SA Check Transfer',0, isnull(SUM(SACOCIDATA.AMOUNT),0),2                   
FROM SACOCIDATA,SATRNMASTER  WHERE (SACOCIDATA.COCICODE > 0)                   
AND(SATRNMASTER.TRNTYPE = 1  OR SATRNMASTER.TRNTYPE = 13)                   
AND (SACOCIDATA.TRNDATE = @DYTE)                   
AND (SATRNMASTER.TRN = SACOCIDATA.TRN) AND (UPPER(SATRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                   
AND (SACOCIDATA.CLEARED = 0 or SACOCIDATA.CLEARED = -1)                   
AND SATRNMASTER.TRNDATE = SACOCIDATA.TRNDATE AND SATRNMASTER.PENDAPPROVE ='A'                  
INSERT INTO @TEMP                    
SELECT 1,'CA Check Transfer',0, isnull(SUM(CACOCIDATA.AMOUNT),0),2                   
FROM CACOCIDATA,CATRNMASTER  WHERE (CACOCIDATA.COCICODE > 0)                   
AND(CATRNMASTER.TRNTYPE = 1001  OR CATRNMASTER.TRNTYPE = 1013)                   
AND (CACOCIDATA.TRNDATE = @DYTE) AND (CATRNMASTER.TRN = CACOCIDATA.TRN)                   
AND CATRNMASTER.TRNDATE = CACOCIDATA.TRNDATE AND (UPPER(CATRNMASTER.USERNAME) IN (@USER,'CAGABAY'))                   
AND (CACOCIDATA.CLEARED = 0 or CACOCIDATA.CLEARED = -1)                  
INSERT INTO @TEMP                    
SELECT                   
  1, JNLH_Explanation, IsNull(Sum(JNLD_DB_AMT),0), IsNull(Sum(JNLD_CR_AMT),0), 1                   
FROM                   
  JNLDETAILS a                  
INNER JOIN                   
  JNLHEADERS b on a.JNLD_JNLH_TRAN=b.JNLH_TRAN                  
INNER JOIN                   
  glAutomated g on Cash = Jnld_Acnt_CD                  
WHERE b.JNLH_POST_BY IN (@USER,'CAGABAY') --and JNLH_EXPLANATION = 'Account Opening Transaction For Matapat'                  
and Jnlh_Code = 0                  
GROUP BY                  
  JNLH_Explanation                  
                    
/*                  
-- select * from glautomated                  
sp_help jnldetails                  
INSERT INTO @TEMP                    
Select 1, 'ATM Account Deposit', IsNull(Sum(JNLD_DB_AMT),0), 0, 1 from JNLDETAILS a                  
Inner JOIN JNLHEADERS b on a.JNLD_JNLH_TRAN=b.JNLH_TRAN                  
Where b.JNLH_POST_BY IN (@USER,'CAGABAY') and JNLH_EXPLANATION = 'Deposit Transaction For Matapat'                  
INSERT INTO @TEMP                    
Select 0, 'ATM Account Withdrawal', 0, IsNull(Sum(JNLD_CR_AMT),0), 1 from JNLDETAILS a                  
Inner JOIN JNLHEADERS b on a.JNLD_JNLH_TRAN=b.JNLH_TRAN                  
Where b.JNLH_POST_BY IN (@USER,'CAGABAY') and JNLH_EXPLANATION = 'Withdrawal Transaction For Matapat'                  
INSERT INTO @TEMP                    
Select 0, 'ATM Account Closed', 0, IsNull(Sum(JNLD_CR_AMT),0), 1 from JNLDETAILS a                  
Inner JOIN JNLHEADERS b on a.JNLD_JNLH_TRAN=b.JNLH_TRAN                  
Where b.JNLH_POST_BY IN (@USER,'CAGABAY') and JNLH_EXPLANATION = 'Closed Account Transaction For Matapat'                  
*/                  
return                  
end 