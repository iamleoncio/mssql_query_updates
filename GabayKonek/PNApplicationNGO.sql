CREATE view PNApplicationNGO                            
                   
AS                                          
select   distinct c.cid,dbo.FullName(c.CNAME,c.FNAME,c.mname)fullname,c.CNAME,c.FNAME,c.MNAME,l.acc,l.PRINCIPAL,l.GIVES,l.INTEREST,l.DISBDATE,l.ConIntRate,                              
l.FREQUENCY,a.ACCTDESC,                              
i.DUEDATE datestart,i.PRIN+i.INTR amort,l.DOMATURITY , 'ES-'+o.DEFBRANCH_CODE+'-'+cast(ct.unit as varchar(5))+'-PN-'+ la.messengerID PN,                            
ad.CITYTOWN+' '+ad.STATEPROV addresses,l.NETPROCEED,Case when ceiling(cast(l.GIVES as numeric(18,2))/4) >12 then 12 else ceiling(cast(l.GIVES as numeric(18,2))/4) end buwan,isnull(ch.chramnt,0)lrf,                            
i.intr/l.principal/DateDiff(dd,DisbDate,i.duedate) * 360*100 eir,i.intr,(interest/principal)*100 intrate,center_name,ct.unit,dobirth,datediff(year,dobirth,getdate())edad,m.unit unitname,                      
round(e.rate*100,2)erate ,Region,FamilyMembers,EducationalLevel_headofthefamily,RoofMaterials,HouseOuterWalls,Electricity,WaterSupply,Refrigerator,TV,WashingMachine,                    
dbo.fullname(m.LNAME,m.FNAME,m.MNAME)UM  ,ad.PHONE4,/*                  
 STUFF(STUFF(SUBSTRING(REPLACE(sss.IDnumber, '-', ''), 1, 10), 3, 0, '-'), 11, 0, '-') AS sssno,                        
STUFF(STUFF(SUBSTRING(REPLACE(tin.IDnumber, '-', ''), 1, 9), 4, 0, '-'), 8, 0, '-') AS tinno,                        
STUFF(STUFF(SUBSTRING(REPLACE(love.IDnumber, '-', ''), 1, 12), 3, 0, '-'), 13, 0, '-') AS pagibigno  ,        */        
c.DORECOGNIZED  ,   
--------------------------------------------------------------added by Leon 06/10/2025  
g.midasdate, g.midasresult,g.midasremarks,g.recommender,g.recommenddate,g.UMApprover,g.UMApproverDate,  g.AMApprover, g.AMApproverdate,g.RDApprover,g.RDApproverDate,   
g.AOName,g.UMName,g.CoborrowerName,g.Corelationship  
--------------------------------------------------------------  
from LNMASTER  l                              
inner join CUSTOMER c on c.CID = l.CID                            
inner join ADDRESSES ad on ad.CID = c.cid                            
inner join center ct on ct.CENTER_CODE = c.CENTER_CODE                             
inner join managers m on m.mancode = ct.unit                            
inner join loanapplication la on la.acc = l.ACC                            
inner join ACCTPARMS a on l.accttype = a.ACCTTYPE                               
inner join loaninst i on l.ACC = i.ACC and DNUM = 1                             
left join lnchrgdata ch on ch.acc = l.acc  and ch.CHRGCODE=16               
inner join CENTWORKER_DET cd on cd.CENTER_CODE =ct.CENTER_CODE                    
inner join CENTER_WORKER cw on cw.CENTERW_ID = cd.CENTERW_ID                    
inner join ACTREF r on l.acc = r.act_Acc           
left join gabaykonekdtls g on g.loanid =  la.LoanId  
LEFT JOIN (select CID,                    
        MAX(CASE WHEN InfoCode = 13 THEN InfoValue END) AS Total,                    
  MAX(CASE WHEN InfoCode = 14 THEN InfoValue END) AS Region,                    
  MAX(CASE WHEN InfoCode = 15 THEN InfoValue END) AS FamilyMembers,                    
  MAX(CASE WHEN InfoCode = 16 THEN InfoValue END) AS EducationalLevel_HeadOftheFamily,                    
  MAX(CASE WHEN InfoCode = 17 THEN InfoValue END) AS RoofMaterials,                    
  MAX(CASE WHEN InfoCode = 18 THEN InfoValue END) AS HouseOuterWalls,                    
  MAX(CASE WHEN InfoCode = 19 THEN InfoValue END) AS Electricity,                    
  MAX(CASE WHEN InfoCode = 20 THEN InfoValue END) AS WaterSupply,                    
  MAX(CASE WHEN InfoCode = 21 THEN InfoValue END) AS Refrigerator,                    
  MAX(CASE WHEN InfoCode = 22 THEN InfoValue END) AS TV,                    
  MAX(CASE WHEN InfoCode = 23 THEN InfoValue END) AS WashingMachine,                        
 InfoDate                    
 from CustAddInfo I        
 group by cid,InfoDate)ppi on           
 ppi.cid = l.cid and ppi.InfoDate = l.DISBDATE                    
left join eir e on e.frequency = l.FREQUENCY and e.term = l.GIVES  and e.eirid =                  
CASE   WHEN l.accttype IN (316, 416, 462, 318, 463, 311, 332, 301, 302) THEN 3   WHEN l.ACCTTYPE IN (475, 420, 321, 336, 323) THEN 1   WHEN l.ACCTTYPE IN (419, 344, 418) THEN 2 ELSE 4 END                   ,                  
orgparms o     