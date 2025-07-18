alter FUNCTION CurrentLoanBal    
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
       Sum( CASE WHEN DueDate-DatePart(dw,DueDate)+DatePart(dw,dbo.RefDueDate(m.Frequency,ebsysDate,0)) >     
                      dbo.RefDueDate(m.Frequency,ebSysDate,0) AND IsNull(WaivableInt,1) = 1 and duedate <=DOMATURITY
                 THEN a.IntR ELSE 0 END) WaivedInt    
  FROM lnMaster m INNER JOIN LoanInst a  ON m.Acc = a.Acc, OrgParms    
  WHERE m.Acc = @Acc    
  Group by m.Acc,m.Status