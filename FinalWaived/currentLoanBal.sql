 ALTER FUNCTION CurrentLoanBal                
     (@Acc as VarChar(22))                
    RETURNS TABLE                
    AS                
                
    RETURN                 
                
    SELECT m.Status, m.Acc,                
           Sum(a.Prin-CASE WHEN InstPD>a.IntR              
           THEN                 
             CASE WHEN InstPD-a.IntR>a.Prin THEN a.Prin ELSE InstPD-a.IntR END                  
                                                                          ELSE 0      END) BalPrin,                
           Sum(a.IntR-CASE WHEN InstPD>a.IntR           THEN a.IntR             ELSE InstPD  END)  BalInt,                
           Sum(IsNull(a.Oth,0)-CASE WHEN InstPD>a.IntR+a.Prin THEN InstPD-a.IntR-a.Prin ELSE 0      END)  BalOth,                
           CASE WHEN m.FREQUENCY not in (0,50) and amortCnt <> 1     
                   THEN dbo.fn_semimonthly(@acc)    
                   ELSE    
                      Sum( CASE                
                                      when m.DOMATURITY >= ebsysdate and  amortCnt  =1 and m.accttype not in (420,461,475,323,321,483)           
                                      then m.INTEREST - CEILING((m.interest  / 7 ) * CEILING(DATEDIFF(DAY, m.disbdate, ebsysdate) / 7.0))       
                                      WHEN OrigDueDt-DatePart(dw,OrigDueDt)+DatePart(dw,dbo.RefDueDate(m.Frequency,ebsysDate,0)) >                 
                                      dbo.RefDueDate(m.Frequency,ebSysDate,0) --AND IsNull(WaivableInt,1) = 1       
                                      and m.accttype not in (420,461,475,323,321,483)           
                                      THEN a.IntR          
                                      ELSE 0 END)     
                     END     
                     WaivedInt            
      FROM lnMaster m           
      INNER JOIN LOANINST a   ON m.Acc = a.Acc          
      inner join (select acc, count(*) amortCnt from loaninst  group by acc)a2 on a2.acc = a.acc, OrgParms                
      WHERE m.Acc = @Acc                
      Group by m.Acc,m.Status,FREQUENCY,amortCnt 