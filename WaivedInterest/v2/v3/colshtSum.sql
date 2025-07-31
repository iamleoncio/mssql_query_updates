ALTER VIEW [dbo].[ColShtSum]      
--Added by Macky       
--Modified by Nelmore 2021-02-21      
-- *****************************************                  
-- 2017-04-03  *****************************                  
-- Altered by Anthony Caya  ****************                  
-- *****************************************                                
AS                                
  SELECT                                 
     WriteOff,            
    acctabbr,OrgName, OrgAddress, StaffName, ManCode, Unit, AreaCode, Area,                                
    Center_Code, Center_Name, CID,             
    ClientName,             
    Amort, MBADue, SaveDue,                                
    LoanDue,DuePrin,DueInt, Due, LoanBal, SaveBal, Principal, MeetingDay,                                
    MeetingDate, UM, PlgAcc, DateEstablished, SharesOfStock,                                 
    CASE WHEN WritenOff>0 THEN 99 ELSE Class END Class,                                 
    CASE WHEN WritenOff>0 THEN 'BAD DEBTS' ELSE                                
    CASE Class                                 
          WHEN 2 THEN 'CLIENT''S SPOUSE'                                
          WHEN 3 THEN 'GOLDEN LIFE'                                
          WHEN 4 THEN 'HARDCORE POOR'                                
          WHEN 5 THEN 'IP MEMBERS'                                
          ELSE  r.PurposeDescription END END ClassDesc,                                
    CASE WHEN WritenOff>0 THEN 9900+Status ELSE                                
      CASE                                 
        WHEN WritenOff>0 THEN 4+Status                                
        WHEN UnPaidCtr>0 THEN 3+Status                                
        WHEN LoanBal<=0  THEN 2                                
        WHEN LoanBal>0   THEN 1+Status END + Class*100 END 'Status',                                
    CASE                                 
      WHEN WritenOff>0 THEN 'Bad Debts: '                                
      WHEN UnPaidCtr>0 THEN 'Pastdue: '                                
      WHEN LoanBal<=0  THEN 'Current w/o Loan: '                                
      WHEN LoanBal>0   THEN 'Current: ' END                        
   + CASE                                 
      WHEN Status=0.1 THEN 'Sipag Loans'                                
      WHEN Status=0.2 THEN 'Agri Loan Program'                                
      WHEN Status=0.3 THEN 'Small Business Loans'                                
      WHEN Status=0.4 THEN 'UNLAD Loans'                                
      ELSE CASE WHEN LoanBal > 0  THEN 'w/ Loans' ELSE '' END END                                
      StatusDesc, Classification,                    
      CASE WHEN WritenOff>0 THEN 9900+Status ELSE                                
      CASE                                 
        WHEN WritenOff>0 THEN 4+Status                                
        WHEN UnPaidCtr>0 THEN 3+Status                                
        WHEN LoanBal<=0  THEN 2                                
        WHEN LoanBal>0   THEN 1+Status END + 100 END 'StatusBank',        
  ' ES - ' +defbranch_code+' - ' +'CCS - '+  Right('00000000000000' + CONVERT(NVARCHAR, serial), 10) serial                                    
  FROM                                
   (SELECT                                
      Max(isnull(b.acctabbr,''))acctabbr,a.OrgName, a.OrgAddress, a.StaffName, a.ManCode, a.Unit, a.AreaCode,                                 
      a.Area, a.Center_Code, a.Center_Name, a.CID, a.ClientName,                                     
      SUM(a.Amort) AS Amort,                                     
      SUM(CASE WHEN a.AcctType = 0 THEN DuePrin + DueInt ELSE 0 END) AS MBADue,                                    
      SUM(CASE WHEN a.AcctType IN (60, 80) THEN DuePrin + DueInt ELSE 0 END)  AS SaveDue,                                     
      SUM(CASE WHEN a.AcctType NOT IN (0, 60, 80) THEN DuePrin + DueInt ELSE 0 END) AS LoanDue,               
      SUM(CASE WHEN a.AcctType NOT IN (0, 60, 80) THEN DuePrin  ELSE 0 END)DuePrin,                  
     SUM( CASE WHEN a.AcctType NOT IN (0, 60, 80) THEN  DueInt ELSE 0 END)  DueInt,                              
      SUM(a.DuePrin + a.DueInt) AS Due,                                 
      SUM(a.LoanBal - WaivedInt) AS LoanBal,                                     
      SUM(CASE WHEN a.AcctType = 60 THEN SaveBal ELSE 0 END) AS SaveBal,                                     
      SUM(a.Principal) AS Principal,                                 
      CASE                                 
        WHEN Classification = 5  THEN 2                                
        WHEN Classification = 99 THEN 3                                
        WHEN Classification = 6  THEN 4                                
        WHEN Classification = 7  THEN 5                                
        ELSE Classification END Class,                                
      SUM(WritenOff) WritenOff,                                
      SUM(UnPaidCtr) UnPaidCtr,                                
      MIN(Status) Status,                   
      a.MeetingDay, a.MeetingDate, a.UM,                                 
      MAX(CASE WHEN AcctDesc = 'Pledge Account' THEN Acc ELSE '' END) AS PlgAcc,                                 
      DateEstablished, SharesOfStock, a.Classification ,a.WriteOff ,Serial ,defbranch_code                             
    FROM                          
      dbo.ColSht AS a                          
      LEFT JOIN ACCTPARMS_abbr b on a.AcctType = b.accttype                                   
     Left join centerSerial c on c.centerCode = Center_code and DATEPART(WEEK, TrnDate)  = DATEPART(WEEK, MeetingDate) and year(TrnDate) = year(MeetingDate),orgparms o       
    WHERE                                 
      a.Center_Name not like '%(Maagap)%'                              
    GROUP BY                                 
      a.OrgName, a.OrgAddress, a.StaffName, a.ManCode, a.Unit, a.AreaCode,                                 
      a.Area, a.Center_Code, a.Center_Name, a.CID, a.ClientName,                                 
      a.MeetingDay, a.MeetingDate, a.UM, DateEstablished, SharesOfStock, a.Classification,WriteOff,Serial,defbranch_code) a                             
       left Join (select ID,REFID,purposedescription,CODEID,stat from ReferencesDetails where REFID =1005) r on a.Classification = r.CODEID 