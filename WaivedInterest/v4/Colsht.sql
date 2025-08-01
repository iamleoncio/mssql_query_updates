alter VIEW [dbo].[ColSht]                                            
------ *******************************************************************************************                                              
-- Added by Macky                                 
-- Modified by Nelmore 2021-02-21                          
-- Add Classification SALP and QSL 10-06-2023                          
-- Added by Fritz 4-2-2024  to indicate ipl 420 and 46                         
 --                       
as                                            
SELECT                                             
  APPTYPE,cd.Code,                                             
CASE WHEN IsNull(l.BalPrin+l.balint,0) <= 0 THEN 1 ELSE           ---modified by fritz                                 
    CASE                                             
      WHEN AcctDesc LIKE '%Special%'   THEN .1                                            
      WHEN AcctDesc LIKE '%Agri%'  THEN .2                                            
      WHEN AcctDesc LIKE '%Quick%'  THEN .3                                            
      WHEN AcctDesc LIKE '%Unlad%'  THEN .4                            
     -- WHEN AcctDesc LIKE '%Special%'  THEN .6                                            
      ELSE .5 END                                             
    END 'Status',                                              
  CASE cd.Code                                             
     WHEN 3 THEN l.Acc                                             
     WHEN 1 THEN s.Acc ELSE '' END Acc, c.CID,                                            
   dbo.FullName(Man.lName, Man.fName, Man.mName) UM,                                              
   CASE WHEN ISNULL(AccWriteOff,0) = 1 then 'WO - '+ dbo.FullName(c.cName, c.fName, c.mName) else dbo.FullName(c.cName, c.fName, c.mName) end ClientName,                                              
   c.Center_Code, Center_Name, ManCode, Man.Unit, Man.AreaCode, Ar.Area, StaffName,                                              
   CASE WHEN cd.Code = 0   THEN 0    WHEN cd.Code = 2   THEN 2      ELSE y.AcctType END AcctType,                                            
   CASE WHEN cd.Code = 0 THEN 'MBA'   WHEN cd.Code = 2 THEN 'Katuparan'     ELSE y.AcctDesc END AcctDesc,                                            
   CASE WHEN cd.Code = 3 THEN l.DisbDate  ELSE 0 END DisbDate,                                            
   CASE WHEN cd.Code = 3 THEN l.DateStart ELSE 0 END DateStart,                                            
   CASE WHEN cd.Code = 3 THEN l.Maturity  ELSE 0 END Maturity,                                            
   CASE WHEN cd.Code = 3 and l.BalPrin + l.BalInt >= 1 THEN l.Principal ELSE 0 END Principal,                                               
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN 0                                   
     WHEN 2 THEN 0                                            
     WHEN 3 THEN l.Interest ELSE 0 END Interest,                                            
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN 0                                    
     WHEN 2 THEN 0                                           
     WHEN 3 THEN l.Gives ELSE 0 END Gives,                                            
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN s.SaveBal                                   
     WHEN 2 THEN 0                                            
     WHEN 3 THEN l.iBalPrin ELSE 0 END iBalPrin,                                            
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN 0                                   
     WHEN 2 THEN 0                                            
   WHEN 3 THEN l.iBalInt+l.iBalOth ELSE 0 END iBalInt,                                            
   CASE cd.Code                                             
     WHEN 0 THEN 0                                   
    WHEN 2 THEN 0                                            
     WHEN 1 THEN s.SaveBal                    
     WHEN 3 THEN l.BalPrin ELSE 0 END BalPrin,                                            
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN 0                              
     WHEN 2 THEN 0                                           
     WHEN 3 THEN l.iBalInt+l.iBalOth ELSE 0 END BalInt,                                            
   CASE cd.Code                                             
     WHEN 0 THEN mf.Amort                           
     WHEN 2 THEN ins.Amort                                              
     WHEN 1 THEN s.Amort                                            
     WHEN 3 THEN l.Amort ELSE 0 END Amort,                                            
   CASE cd.Code                                             
     WHEN 0 THEN mf.DuePrin                                 
     WHEN 2 THEN ins.DuePrin                                            
     WHEN 1 THEN s.DuePrin                                            
     WHEN 3 THEN l.DuePrin ELSE 0 END DuePrin,                                          
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN 0                                            
     WHEN 3 THEN l.DueInt ELSE 0 END DueInt,                            
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN 0                                            
     WHEN 3 THEN l.BalPrin+l.iBalInt+l.iBalOth ELSE 0 END LoanBal,                                            
   CASE cd.Code                                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN s.SaveBal                                            
     WHEN 3 THEN 0 ELSE 0 END SaveBal,                                            
   CASE cd.Code                             
     WHEN 0 THEN 0                                            
     WHEN 1 THEN 0                                            
     WHEN 3 THEN l.WaivedInt ELSE 0 END WaivedInt,                                            
   IsNull(UnPaidCtr,0) UnPaidCtr, IsNull(WritenOff,0) WritenOff,                                      
   OrgName,  Man.UnitAddress + char(13) + man.vatReg OrgAddress, ebSysDate-DatePart(dw,ebSysDate)+Center_Meet_Day+1 MeetingDate,                                               
   Center_Meet_Day MeetingDay,                                              
   LoanLmt SharesOfStock, cen.DateEstablished,                                             
   CASE WHEN Mutual_Amount > 20 AND DateAdd(yy,70,DoBirth) <= GetDate() AND DoBirth >= '1901-01-01'                                            
     THEN 99 ELSE c.subclassification END Classification  ,ISNULL(AccWriteOff,0) WriteOff                                         
FROM Customer c                                              
INNER JOIN                                             
  AcctParms y on 0=0                                            
INNER JOIN                                            
 (SELECT 0 Code UNION All SELECT 1 Code UNION All SELECT 3 Code UNION All SELECT 2 Code) cd on 0=0                                            
-- Loans                                            
LEFT JOIN                                              
 (SELECT                                             
    3 AppCode, c.Center_Code, m.CID, m.Acc, m.AcctType, m.DisbDate,                                      
    Min(DueDate) DateStart, Max(DueDate) Maturity,                                            
    m.Principal, m.Interest, m.Gives,                                            
    Sum(CASE WHEN InstPD > a.IntR                                            
             THEN a.Prin - (InstPD-a.IntR) ELSE a.Prin END) iBalPrin,                                        
    Sum(CASE WHEN InstPD > a.IntR                                             
             THEN 0 ELSE a.IntR - InstPD END) iBalInt,                                              
    Sum(CASE WHEN InstPD > a.IntR+a.Prin                                             
             THEN a.Oth - (InstPD-a.IntR-a.Prin) ELSE a.Oth END) iBalOth,                                              
    m.Principal-m.Prin BalPrin, m.Interest-m.Others-m.Intr-m.Oth BalInt,                                            
           CASE WHEN m.FREQUENCY not in (0,50) and amortCnt <> 1 
                   THEN dbo.fn_semimonthly(m.acc)
                   ELSE
                      Sum( CASE            
                                      when m.DOMATURITY >= ebsysdate and  amortCnt  =1 and m.accttype not in (420,461,475,323,321,483)       
                                      then m.INTEREST - CEILING((m.interest  / 7 ) * CEILING(DATEDIFF(DAY, m.disbdate, ebsysdate) / 7.0))   
                                      WHEN DueDate-DatePart(dw,DueDate)+DatePart(dw,dbo.RefDueDate(m.Frequency,ebsysDate,0)) >             
                                      dbo.RefDueDate(m.Frequency,ebSysDate,0) --AND IsNull(WaivableInt,1) = 1   
                                      and duedate <= DOMATURITY + 6 - Datepart(dw,domaturity)    
                                      and m.accttype not in (420,461,475,323,321,483)       
                                      THEN a.IntR      
                                      ELSE 0 END) 
                     END 
                     WaivedInt  ,                                              
   SUM(CASE WHEN dNum = 1                                             
             THEN a.Prin+a.IntR ELSE 0 END) Amort,                                              
    SUM(CASE WHEN DBO.Friday(ebSysDate) < DBO.Friday(a.DueDate) THEN 0                                             
             ELSE                                             
               CASE WHEN InstPD > a.IntR+a.Prin                            
                    THEN a.Oth - (InstPD-a.IntR-a.Prin) ELSE a.Oth END END) DueOth,                                              
    SUM(CASE WHEN DBO.Friday(ebSysDate) < DBO.Friday(a.DueDate) THEN 0                      
             ELSE                                            
               CASE WHEN InstPD > a.IntR                                            
                    THEN a.Prin - (InstPD-a.IntR) ELSE a.Prin END END) DuePrin,                                              
    SUM(CASE WHEN DBO.Friday(ebSysDate) < DBO.Friday(a.DueDate) THEN 0                                            
             ELSE                                            
               CASE WHEN InstPD > a.IntR                                             
                    THEN 0 ELSE a.IntR - InstPD END END) DueInt,                                            
    SUM(CASE WHEN DBO.Friday(ebSysDate) > DBO.Friday(a.DueDate)                                               
                  AND m.Status in (30,91)                          
                     AND m.PRIN <> 0 --AND m.AcctType IN (420, 461)               ---added 4-2-2024 by vladymrputik  to indicate ipl 420 and 46                                          
                  AND a.Prin+a.IntR+a.Oth > a.InstPD THEN 1 ELSE 0 END) UnPaidCtr,                                            
    CASE WHEN w.ACC IS NOT NULL THEN 1 ELSE 0 END WritenOff ,                                      
    CASE WHEN r.AccWriteOff  IS NOT NULL THEN 1 ELSE 0 END AccWriteOff                                           
                                          
  FROM lnMaster m                                              
  INNER JOIN Customer c on m.CID = c.CID                                 
  INNER JOIN LoanInst a  ON m.Acc = a.Acc         
  inner join (select acc, count(*) amortCnt from loaninst lo group by acc ) a2 on a2.acc = a.ACC        
  LEFT  JOIN WriteOff w on w.Acc = m.Acc                                      
  LEFT JOIN (select r.cid,w.Acc AccWriteOff from reactivateWriteoff r                                      
              Inner join LNMASTER l on l.CID = r.cid                                      
              Inner join WriteOff w on w.acc= l.ACC)r on r.AccWriteOff = w.Acc                                          
  ,OrgParms                                              
  WHERE m.Status in (30,91)                            
                                        
  GROUP BY                                             
    c.Center_Code, m.CID, m.Acc, m.AcctType, m.DisbDate,  m.FREQUENCY,a2.amortCnt,                                           
    m.Principal, m.Interest, m.Others, m.Prin, m.INTR, m.Oth, m.Gives, w.ACC ,AccWriteOff                                           
  ) l on l.CID = c.CID and y.AcctType = l.AcctType and cd.Code = 3                         
                      
                                   
-- Savings                                            
LEFT JOIN                                              
 (SELECT                                             
    1 Code, c.Center_Code, IsNull(Acc,'') Acc, c.CID, IsNull(Type,60) AcctType,                                             
    CAST(IsNull(Balance,0) as Numeric(18,2)) SaveBal,                                             
    CASE WHEN Type = 60 THEN Pledge_Amount When TYPE = o.katuparanCode then katuparan_amount ELSE Pangarap_Amount END Amort,                                              
    CASE WHEN Type = 60                                             
         THEN CASE WHEN AccPledge > 0 THEN AccPledge ELSE 0 END                                      
         WHEN Type = o.katuparanCode                                        
 THEN CASE WHEN ACCTKATUPARAN > 0 THEN ACCTKATUPARAN ELSE 0 END                                          
         ELSE CASE WHEN AccPang   > 0 THEN AccPang   ELSE 0 END END DuePrin                             
  FROM saMaster m                                              
  INNER JOIN Customer c on c.CID = m.CID ,orgparms o                                             
  WHERE                                                  
   (Type in (60, 80,o.KATUPARANCODE)                                             
   and m.Status in (20,10,90))                                         
  ) s on s.CID = c.CID and cd.Code = 1                                             
    and (s.AcctType = y.AcctType)                                                 
-- Mutual Fund                                            
LEFT JOIN                                            
 (SELECT                                             
    0 AppCode, c.Center_Code, CID, 0 AcctType,                                            
    Mutual_Amount Amort,                                             
    CASE WHEN AccMutual > 0 THEN AccMutual ELSE 0 END DuePrin                                            
  FROM Customer c                                               
  WHERE                                             
     Mutual_Amount > 0 and Status in (0,1,4)                                               
     and cid in (SELECT cid FROM SaMaster WHERE Type = 60 and Status <> 99)                                            
     ) mf on mf.CID = c.CID and cd.Code = mf.AppCode and (y.AcctType = 60)                                             
LEFT JOIN Center Cen on Cen.Center_Code = c.Center_Code                                              
LEFT JOIN                                     
 (SELECT                                             
    wd.Center_Code, dbo.FullName(Centerw_lName,                                              
    Centerw_fName,Centerw_mName) StaffName                                               
  FROM CentWorker_Det wd                                              
  INNER JOIN Center_Worker w on w.CenterW_ID = wd.CenterW_ID                                              
  GROUP BY                                             
    wd.Center_Code,Centerw_lName,                                
    Centerw_fName,Centerw_mName) ST                                              
    ON ST.Center_Code = C.Center_Code                                              
LEFT JOIN Managers Man on Man.ManCode = Cen.Unit                                              
LEFT JOIN Area Ar on Ar.AreaCode = Man.AreaCode                                              
  --MORA                                              
  ----------------------------------------------------------------------------                                                                 
LEFT JOIN                                             
 (SELECT M.CID           
  FROM OrgParms,lnMaster M                                              
  INNER JOIN MoraDetail MD ON M.ACC = MD.ACC                                              
  INNER JOIN MoraHead   MH ON MD.MoraID = MH.MoraID                                              
  WHERE                                              
     M.STATUS IN (30,91) AND                                              
     ebSysDate BETWEEN MH.StartDate AND MH.EndDate                                            
  GROUP BY m.CID) Moratorium  ON  Moratorium.CID = c.CID                                                 
  ----------------------------------------------------------------------------                                     
  LEFT JOIN                                            
 (SELECT                                             
    2 AppCode, c.Center_Code, CID, 1 AcctType,                                   
    INSURANCE_AMOUNT Amort,                                             
    CASE WHEN ACCTINSURANCE > 0 THEN ACCTINSURANCE ELSE 0 END DuePrin                                            
  FROM Customer c                                               
  WHERE                                             
     INSURANCE_AMOUNT > 0 and Status in (0,1,4)                                               
     and cid in (SELECT cid FROM SaMaster WHERE Type = 60 and Status <> 99)                                         
     ) ins on ins.CID = c.CID and cd.Code = ins.AppCode and (y.AcctType = 60)                                         
 ------------------------------------------------------------------------------                                            
  , OrgParms                                             
  WHERE                                             
    c.Status in (0,1,4) and c.Center_Code <> '00'                                             
    and c.CID not in (SELECT CID FROM inActiveCID WHERE inActive = 1)                                              
    and (l.ACC is Not Null or s.Acc is not Null or mf.CID is not Null or ins.CID is not null) 