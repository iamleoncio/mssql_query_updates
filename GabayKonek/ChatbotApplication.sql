ALTER view [dbo].[ChatbotApplication]             
/*        
Edited by Leon         
05/29/2025        
GabayKonek Application Report        
*/        
as                
select top 10000 *  from (          
select l.*,  
-----------------------------------------------------------------------added by Leon 06/10/2025  
case   
 when l.paymentMode in (0,50) then 'Weekly'  
 when l.paymentMode in (12,1) then 'Monthly'  
 else 'Semi-Monthly'  
end as PaymentDesc  
  
-----------------------------------------------------------------------  
,dbo.FullName(c.CNAME,c.FNAME,c.MNAME)fullname,a.ACCTDESC,c.dobirth,                  
case when l.status = 0 then 'Pending'                
when l.status = 1 then 'Released'                  
when l.status = 3 then 'Cancelled'                
else 'Disapproved' end remarks,ct.center_Name,m.Unit,                
o.ORGNAME,o.ORGADDRESS,ac.act_date1,ac.act_date2, isnull(lm.Cycle, 0) Cycle  ,       
DISBBY, g.recommender,g.UMApprover    -----------------------------------------------------------------------added by Leon 06/10/2025  
from LoanApplication l            
inner join CUSTOMER c on c.CID = l.cid                
inner join center ct on ct.center_Code = c.center_code                
inner join managers m on m.mancode = ct.unit                
left join addresses ad on ad.cid = c.cid                
inner join ACCTPARMS a on a.ACCTTYPE = l.loanType                
inner join actref ac on 1=1                
inner join orgparms o on 1=1                
inner  join LNMASTER lm on lm.ACC = l.acc --added By Kent on 2021-07-16 for additonal fields                
left join gabaykonekdtls g on g.loanid = l.LoanId -- added by Leon 06/10/2025  
where dateRelease >= ac.act_date1 and  dateRelease <= ac.act_date2         
and DISBBY ='CAGABAY'    
group by l.cid,loantype,loanterm,loanamount,paymentmode,messengerid,purposeofloan,dateapply,                
daterelease,l.acc,l.status,uploaded,l.loanId,dbo.FullName(c.CNAME,c.FNAME,c.MNAME),a.ACCTDESC,c.dobirth,ct.center_Name,m.Unit,contactNumber,                
o.ORGNAME,o.ORGADDRESS,ac.act_date1,ac.act_date2,ebsysdate,lm.cycle, l.beneficiaryName,l.Bday, l.Gender, l.Age,l.Educ_Lvl, l.BFFNAME,              
l.BFLNAME, l.BFMNAME,l.id    ,DISBBY, g.recommender,g.UMApprover      
) b           
order by dateRelease desc