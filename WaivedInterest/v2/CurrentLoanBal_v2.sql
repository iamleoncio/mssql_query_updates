    ALTER FUNCTION CurrentLoanBal        
     (@Acc as VarChar(22))        
    RETURNS TABLE        
    AS        
        
    RETURN         
        
    SELECT m.Status, m.Acc,        
           Sum(a.Prin-CASE WHEN InstPD>a.IntR           THEN         
                                  CASE WHEN InstPD-a.IntR>a.Prin THEN a.Prin ELSE InstPD-a.IntR END          
                                                                          ELSE 0      END) BalPrin,        
           Sum(a.IntR-CASE WHEN InstPD>a.IntR           THEN a.IntR             ELSE InstPD  END)  BalInt,        
           Sum(IsNull(a.Oth,0)-CASE WHEN InstPD>a.IntR+a.Prin THEN InstPD-a.IntR-a.Prin ELSE 0      END)  BalOth,        
           Sum( CASE        
                          when m.DOMATURITY >= ebsysdate and  m.frequency in (12,1) and amortCnt  =1 and m.accttype not in (420,461,475,323)   
                          then CEILING((m.interest  / datediff(dd,m.disbdate,a.duedate)) * datediff(dd,m.disbdate,ebsysdate))   
                          WHEN DueDate-DatePart(dw,DueDate)+DatePart(dw,dbo.RefDueDate(m.Frequency,ebsysDate,0)) >         
                          dbo.RefDueDate(m.Frequency,ebSysDate,0) AND IsNull(WaivableInt,1) = 1 and duedate <=DOMATURITY    
                          and m.accttype not in (420,461,475,323)    
                          THEN a.IntR  
                          ELSE 0 END) WaivedInt        
      FROM lnMaster m   
      INNER JOIN LoanInst a  ON m.Acc = a.Acc  
      inner join (select acc, count(*) amortCnt from loaninst  group by acc)a2 on a2.acc = a.acc, OrgParms        
      WHERE m.Acc = @Acc        
      Group by m.Acc,m.Status