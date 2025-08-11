CREATE VIEW dbo.EVC_LoanSubLed_View          
AS          
SELECT OrgName, OrgAddress, Center_Name, Center_Address, c.CID, dbo.FullName(cname,fname,mname) ClientName,          
       a.Acc, AcctType, Trn, TrnDate, TrnType, TrnDesc, a.Principal+a.Interest TrnAmt, a.Principal, a.Interest, a.Balance,           
       UserName          
   FROM (SELECT Acc, Trn, TrnDate, t.TrnType, y.TrnDesc, Prin Principal, IntR Interest, Balance, UserName          
              FROM trnMaster t          
                 INNER JOIN TrnTypes y on y.TrnType = t.TrnType, ActRef          
              WHERE Acc = Act_Acc and t.TrnType not in (3400, 3100,3098)      
                    
         UNION          
         SELECT Acc, 0, DisbDate, 3100, 'Loan Release', Principal, Interest-Discounted , Principal+Interest-Discounted, DisbBy          
                   FROM lnMaster, ActRef          
                   WHERE Act_Acc = Acc      
         UNION     
         SELECT Acc, Trn, TrnDate, t.TrnType, 'Waived Interest' TrnDesc, 0 Principal, WAIVEDINT Interest, Balance, UserName          
              FROM trnMaster t          
              INNER JOIN TrnTypes y on y.TrnType = t.TrnType, ActRef          
              WHERE Acc = Act_Acc and t.WAIVEDINT > 0    
              GROUP BY ACC, TRN , TRNDATE,T.TRNTYPE,BALANCE,USERNAME, WAIVEDINT    
         ) a          
      Inner Join lnMaster m on m.Acc = a.Acc          
      Inner Join Customer c on c.CID = m.CID          
      Inner Join Center cen on cen.Center_Code = c.Center_Code, OrgParms