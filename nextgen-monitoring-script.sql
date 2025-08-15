--Clients with Incorrect MBA Due or Subclassifications
select * from (
select ar.officename Area,u.officename Unit ,ce.officename Center,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName, r.title, m.principal mbadue,s.balance CBU,c.glipdate GoldenLifeDate  ,case when ln.cid is null then  r2.title else 'Bad Debts' end Status,
case when c.localcid is not null then 'Migrated' else '' end source from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts s on s.cid = c.cid and s.apptype  = 0
inner join accounts m on m.cid = c.cid  and m.apptype = 1
left join (select distinct a.cid  from accounts a
			inner join writeoff w on w.acc = a.acc
			where a.status in (30,91) and apptype = 3) ln on ln.cid = c.cid
inner join customerppi cp on cp.cid = c.cid
inner join referenceview r on r.refid  = (case when cp.indivclassification  is null then cp.memberclassificationid  else cp.indivclassification  end)  and (r.reftype ='SubClassification' or r.reftype ='IndivClassification')
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
where c.customerstatus <> 618 and s.balance >= 0 
order by ar.officename,u.officename ,ce.officename,c.cid
) b where status = 'Active' and ((title in ('Regular Client','DSHP') and mbadue <> 20  and Status <> 'Bad Debts') or 
		   (title in ('GLIP 1') and mbadue < 50  and Status <> 'Bad Debts') OR
		(title in ('GLIP 2') and mbadue < 100  and Status <> 'Bad Debts') OR
		(mbadue <> 20 and (goldenlifedate = '1900-01-01' or GoldenLifeDate is null) and b.Status <> 'Bad Debts'))


	
--Below 34 PPI (Huwag na muna itu kasi sa migration ito)
select * from (
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName,c.dorecognized , r.title,s.balance CBU,cp.totalppi ,case when ln.cid is null then  r2.title else 'Bad Debts' end Status,
case when c.localcid is not null then 'Migrated' else '' end source from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts s on s.cid = c.cid and s.apptype  = 0
left join (select distinct a.cid  from accounts a
			inner join writeoff w on w.acc = a.acc
			where a.status = 91 and apptype = 3) ln on ln.cid = c.cid
inner join customerppi cp on cp.cid = c.cid
inner join referenceview r on r.refid  = (case when cp.memberclassificationid  is null then cp.indivclassification  else cp.memberclassificationid  end)  and (r.reftype ='SubClassification' or r.reftype ='IndivClassification')
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
where c.customerstatus <> 618 and s.balance >= 0 
order by ar.officename,u.officename ,ce.officename,c.cid
)b 
where b.title <> 'DSHP' and b.totalppi < 34 and b.status <> 'Bad Debts'
 and source <> 'Migrated'


--ageat75 with LRF
select * from (
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName, r.title, m.principal mbadue,c.glipdate ,s.balance CBU,a.acc,a.accdesc,a.dopen,a.principal,l.chramnt,
DATE_PART('year', AGE(a.dopen, birthday)) ageatDisbdate,
case when ln.cid is null then  r2.title else 'Bad Debts' end Status,
case when c.localcid is not null then 'Migrated' else '' end source from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts s on s.cid = c.cid and s.apptype  = 0
inner join accounts m on m.cid = c.cid  and m.apptype = 1
left join (select distinct a.cid  from accounts a
			inner join writeoff w on w.acc = a.acc
			where a.status = 91 and apptype = 3) ln on ln.cid = c.cid
inner join accounts a on a.cid = c.cid and a.apptype = 3 and a.status not in (25,20)
inner join lnchrgdata l  on l.acc = a.acc and l.chrgcode  = 16 
inner join customerppi cp on cp.cid = c.cid and cp.indivclassification  in (673,672)
inner join referenceview r on r.refid  = cp.indivclassification
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
where c.customerstatus <> 618 and s.balance >= 0 
order by ar.officename,u.officename ,ce.officename,c.cid
)b
where ageatDisbdate >= 75




--Clients Subclass not valid based on age
select * from (
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName,c.birthday,c.dorecognized , r.title, m.principal mbadue, DATE_PART('year', AGE(NOW(), birthday)) age,s.balance,
case when ln.cid is null then  r2.title else 'Bad Debts' end Status,
case when c.localcid is not null then 'Migrated' else '' end source from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts s on s.cid = c.cid and s.apptype  = 0
inner join accounts m on m.cid = c.cid  and m.apptype = 1
left join (select distinct a.cid  from accounts a
			inner join writeoff w on w.acc = a.acc
			where a.status in (30,91) and apptype = 3) ln on ln.cid = c.cid
inner join customerppi cp on cp.cid = c.cid
inner join referenceview r on r.refid  = (case when cp.indivclassification  is null then cp.memberclassificationid  else cp.indivclassification  end)  and (r.reftype ='SubClassification' or r.reftype ='IndivClassification')
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
where c.customerstatus <> 618 and s.balance >= 0  and c.dorecognized  >'2006-05-30'
order by ar.officename,u.officename ,ce.officename,c.cid
) b where  (title in ('Regular Client','DSHP') and age  >= 70   and Status <> 'Bad Debts') or 
		   (title in ('GLIP 1','GLIP 2') and age <   70  and Status <> 'Bad Debts') 
	

--Resigned Clients with Loan Balance
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName ,ln.acc,ln.accdesc,ln.dopen,case when ln.disbby = '0' then u2.username else ln.disbby end, ln.balance,  
case 
	when ln.lnStatus = 30 then 'Active'
	when ln.lnStatus = 91 then 'Pastdue'
	when ln.lnStatus in (99,98) then 'Closed'
	else 'Writeoff'
end
LoanStatus
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts s on s.cid = c.cid and s.apptype  = 0
inner join accounts m on m.cid = c.cid  and m.apptype = 1
left join (select a.cid,a.acc, accdesc,a.disbby ,a.encoderuserid, a.principal,a.balance,a.dopen , case when w.acc  is null then a.status else 1  end lnStatus from accounts a
			left join writeoff w on w.acc = a.acc
			where a.status in (30,91) and apptype = 3) ln on ln.cid = c.cid
inner join customerppi cp on cp.cid = c.cid
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
inner join userslist u2  on u2.userid = ln.encoderuserid
where c.customerstatus = 618 and ln.balance > 0 
order by ar.officename,u.officename ,ce.officename,c.cid




--Resigned Clients with CBU Balance
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName ,s.acc,s.accdesc ,s.dopen,s.balance ,case when s.disbby = '0' then u2.username else s.disbby end,
s."source" 
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts s on s.cid = c.cid and s.apptype  = 0
inner join customerppi cp on cp.cid = c.cid
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
inner join userslist u2  on u2.userid = s.encoderuserid
where c.customerstatus = 618 and s.balance > 0 
order by ar.officename,u.officename ,ce.officename,c.cid


--Client with Invalid Details
select * from (
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName , c.birthday,c.dorecognized ,DATE_PART('year', AGE(c.dorecognized, c.birthday)) AS AgeatRecognized,  r.title,
case when c.localcid is not null then 'Migrated' else '' end source
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join referenceview r  on r.refid  = c.customerstatus
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
where c.customerstatus <> 618  
order by ar.officename,u.officename ,ce.officename,c.cid
)b  where b.ageatrecognized  < 18 or b.ageatrecognized  > 64 or Clientname ~ '[^A-Za-z0-9ñÑ.,\- ]'


--Incorrect Purpose
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName,a.acc, a.accdesc,a.dopen ,pur.title,a.source
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join (select cid, acc,accttype, accdesc, dopen,balance,source, case when source ='Migrated'  then acc else loanid end lnid from accounts where apptype =3  and status not in (25,20)) a on a.cid = c.cid 
left join  (select loanid,loanpurpose  from lnaccountsinfo l union all select acc, businesstypeid from migratedbusinesstype) lc on lc.loanid  = a.lnid
left join referenceview pur on pur.refid = lc.loanpurpose and pur.reftype in   ('LoanBusinessType','LoanPurpose','LoanCategory')
left  join referenceview r on r.refid  = c.customerstatus  and r.reftype ='CustomerStatus'
where a.accttype in (301,317,410,449,450,451,463,464)  and ( pur.title  is null or pur.title ilike  ('%Non%'))
order by ar.officename,u.officename ,ce.officename



--konek2loanLapses
select *,case when yearsatdisbdate < 2 then 'Below 2 Years'  when  DATE_PART('day', dopen - dateapply) > 7 then 'Not Cancelled' else '' end Remarks from (
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName,c.dorecognized ,a.acc, a.accdesc,a.datetimeencoded dateapply,a.dopen ,c.cellphoneno ,a.source,r.title ,
round(EXTRACT(EPOCH FROM AGE(dopen, dorecognized)) / (365 * 24 * 60 * 60),2)  yearsatdisbdate
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts a on a.cid = c.cid  and a.source ='Konek2Loan'
left  join referenceview r on r.code  = cast(a.status as varchar(2))  and r.reftype ='LoanStatus'
where a.status not in (25)
order by ar.officename,u.officename ,ce.officename,c.cid
)b where yearsatdisbdate < 2 or DATE_PART('day', dopen - dateapply) > 7



--Incorrect Loanterm
select ar.officename,u.officename ,ce.officename,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName,c.dorecognized ,a.acc, a.accdesc,a.dopen,lo.duedate firstPayment,a.term ,       
		case
		WHEN frequency in (0,50) THEN 'Weekly'                                                        
        WHEN FREQUENCY=1 THEN 'Monthly'                                                        
        WHEN FREQUENCY=2 THEN 'Semi-Monthly' 
        end Frequency,
        a."source"
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts a on a.cid = c.cid   and a.term <> 25 
inner join loaninst lo on lo.acc= a.acc and dnum = 1 
left  join referenceview r on r.code  = cast(a.status as varchar(2))  and r.reftype ='LoanStatus'
where (a.accttype =323 and a.term  <> 23) or  (a.accttype not in (316,317,449) and a.frequency not in (0,50) )


--Incorrect Increment
select * from (
select ar.officename area,u.officename unit ,ce.officename center,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName,c.dorecognized ,a.acc, a.accdesc,a.principal Current,pAcc.principal  Previous, a.principal - pacc.principal difference 
, a.cycle ,a.term ,a."source"
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts a on a.cid = c.cid   and a.status not in (25,20)  and a.apptype = 3 
inner join accounts pAcc on pacc.cid = a.cid and pacc.accttype = a.accttype and a.status not in (25,20)  and pacc.cycle = a.cycle -1 
left  join referenceview r on r.code  = cast(a.status as varchar(2))  and r.reftype ='LoanStatus'
) b 
where (b.accdesc in ('SIKAP 1','SIKAP 2','RPA - REGULAR AGRI LOAN') and difference  > 10000 and cycle < 5 ) or
	  (b.accdesc in ('RPA - REGULAR AGRI LOAN') and difference  > 5000 and term <= 4  ) or 
	  (b.accdesc in ('QUICK S.M.E. LOAN','AGRI LOAN') and difference  > 20000 and cycle <= 4  ) or
	  (b.accdesc in ('HOUSING REPAIRS/IMPROVEMENTS','AGRI LOAN') and difference  > 5000 and cycle < 5  )
	  order by area,unit,center,cid

--Incorrect First Cycle
select ar.officename area,u.officename unit ,ce.officename center,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName ,a.acc,a.dopen , a.accdesc,a.principal, a.cycle,
				case 
					when a.status = 30 then 'Active'
					when a.status = 91 then 'Pastdue'
					else 'Closed'
				end
				LoanStatus,a.source,
concat(us.lastname,', ',us.firstname,' ',us.middlename)AoName
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts a on a.cid = c.cid   and a.status not in (25,20)  and a.apptype = 3  and a.cycle = 1 
left  join referenceview r on r.code  = cast(a.status as varchar(2))  and r.reftype ='LoanStatus'	
inner join userslist us on us.staffid = ce.contactperson
where a.dopen between '2025-03-01' and '2025-03-31' 
	 and( (a.accttype in (301,316,302,462,318,419) and a.principal > 20000) 
	 or (a.accttype = 311 and a.principal > 50000) 
	 or (a.accttype  in (317,449) and a.principal not between 30000 and 70000)
	 or (a.accttype in (344) and a.principal > 5000) 
	 or (a.accttype in (418,476) and a.principal > 10000) 
	 or (a.accttype in (321) and a.principal not between 900 and 4800 ) )
order by ar.officename ,u.officename  ,ce.officename 



--	Educ Loan Beneficiary 
	 select *, case when beneficiary ~ '[^A-Za-z0-9ñÑ.,\- ]'  then 'Invalid Name' else 'Invalid Age' end  from (
	 select ar.officename area,u.officename unit ,ce.officename center,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName ,a.acc,a.dopen , a.accdesc,a.principal,
	 lb.Beneficiary,lb.birthdate,lb.gradelvl,gender,DATE_PART('year', AGE(dopen, lb.birthdate)) ageatDisbdate,a.LoanStatus,a.source,
	 case
	 	when a.disbby is null or a.disbby in  ('',',')  then us.username
	 	else disbby 
	 end tlr
	from customer c
	inner join office ce on ce.officeid  = c.centercode
	inner join office u on u.officeid = ce.parentid
	inner join office ar on ar.officeid = u.parentid
	inner join (select cid,acc,dopen,accdesc,principal,updateruserid,disbby,source , case when source ='Migrated' then localacc else loanid end lnloanid ,
				case 
					when status = 30 then 'Active'
					when status = 91 then 'Pastdue'
					else 'Closed'
				end
				LoanStatus
				from accounts where status not in (25,20)  and apptype = 3  and accttype in (344,418)) a on a.cid = c.cid  
	left join (select case when lf.uuid  is  not null then lf.loanid else lb.uuid end lbloanid, concat(lb.lname,', ',lb.fname,' ',lb.mname)Beneficiary,lb.birthdate,r.title gradelvl,r2.title gender
				from lnbeneficiary lb 
				left join lnaccountsinfo lf on lf.uuid = lb.uuid
				inner join referenceview r  on r.refid = lb.educationalattainmentid  and r.reftype ='GradeLevel'
				inner join referenceview r2 on r2.refid = lb.genderid and r2.reftype ='Gender')lb on lb.lbloanid = a.lnloanid
	left join userslist us on us.USERID = a.updateruserid 
	) b 
	where beneficiary ~ '[^A-Za-z0-9ñÑ.,\- ]' 	
			OR (b.gradelvl = 'Day Care' AND (ageatdisbdate < 3 OR ageatdisbdate > 5))
			OR (b.gradelvl = 'Grade 1' AND (ageatdisbdate < 6 OR ageatdisbdate > 7))
			OR (b.gradelvl = 'Grade 2' AND (ageatdisbdate < 7 OR ageatdisbdate > 8))
			OR (b.gradelvl = 'Grade 3' AND (ageatdisbdate < 8 OR ageatdisbdate > 9))
			OR (b.gradelvl = 'Grade 4' AND (ageatdisbdate < 9 OR ageatdisbdate > 10))
			OR (b.gradelvl = 'Grade 5' AND (ageatdisbdate < 10 OR ageatdisbdate > 11))
			OR (b.gradelvl = 'Grade 6' AND (ageatdisbdate < 11 OR ageatdisbdate > 12))
			OR (b.gradelvl = 'Grade 7' AND (ageatdisbdate < 12 OR ageatdisbdate > 13))
			OR (b.gradelvl = 'Grade 8' AND (ageatdisbdate < 13 OR ageatdisbdate > 15))
			OR (b.gradelvl = 'Grade 9' AND (ageatdisbdate < 14 OR ageatdisbdate > 15))
			OR (b.gradelvl = 'Grade 10' AND (ageatdisbdate < 16 OR ageatdisbdate > 17))
			and dopen >='2025-01-01'
	order by area,unit,center



--Improper Loan Combinations
select * from (			
select ar.officename area,u.officename unit ,ce.officename center,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName ,
a.acc loanacc1,a.dopen disbdate1,a.accttype accttype1, a.accdesc accdesc1,a.principal principal1,r.title status1
,a2.acc acc2,a2.accdesc accdesc2,a2.principal principal2,a2.dopen disbdat2,a2.accttype accttype2,r2.title status2,a.source,
 case
	 	when a.disbby is null or a.disbby in  ('',',')  then us.username
	 	else a.disbby 
	 end tlr
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts a on a.cid = c.cid   and a.status  in (30,91)  
inner join accounts a2 on a2.cid = a.cid and a2.status  in (30,91) and a2.acc <> a.acc  and a2.acc > a.acc
left  join referenceview r on r.code  = cast(a.status as varchar(2))  and r.reftype ='LoanStatus'
left  join referenceview r2 on r2.code  = cast(a2.status as varchar(2))  and r2.reftype ='LoanStatus'
left join userslist us on us.USERID = a.updateruserid 
where a.dopen between '2025-03-01' and '2025-03-31'
) b 
where accttype1  in (301,311,314,316,317,450,451) and accttype2  in (301,311,314,316,317,450,451)
order by area,unit,center,cid
	

--Improper Renewal
select ar.officename area,u.officename unit ,ce.officename center,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName ,
a.acc loanacc1,a.dopen disbdate, a.accdesc accdesc,a.principal principal,r.title status,a2.acc,trn.prin RenewalAmount, 100 - round((trn.prin/a2.principal)*100,2) RenewalPercentage,a.source,
 case
	 	when a.disbby is null or a.disbby in  ('',',')  then us.username
	 	else a.disbby 
	 end tlr
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts a on a.cid = c.cid   and a.apptype = 3 
inner join (select acc, prin, replace(trndesc,'Loan Renewal-','') prevAcc  from trandetailshistory t  where trndesc ilike '%Renew%'
			union all 
			select acc, prin, replace(trndesc,'Loan Renewal-','') prevAcc from transactiondetails   where trndesc ilike '%Renew%') trn on trn.acc = a.acc
inner join accounts a2 on a2.acc = trn.prevacc  
left  join referenceview r on r.code  = cast(a.status as varchar(2))  and r.reftype ='LoanStatus'
left  join referenceview r2 on r2.code  = cast(a2.status as varchar(2))  and r2.reftype ='LoanStatus'
left join userslist us on us.USERID = a.updateruserid 
where a.dopen  >='2025-01-01' and 100 - round((trn.prin/a2.principal)*100,2) < 70 
order by ar.officename,u.officename,ce.officename

--Incorrect LRF
select * from (
select ar.officename area,u.officename unit ,ce.officename center,c.cid,concat(c.lastname,', ',c.firstname,' ',c.middlename)ClientName ,
a.acc loanacc1,a.dopen disbdate, a.accdesc,a.principal,a.frequency ,term,l.chramnt LRF, case when a.accttype  in (316,449,317) and frequency <> 50  then CEILING((0.015/12*term)*principal) else CEILING((a.principal / 1000) * 0.3 * @term) end ReqLRF,r.title status,
a.source,
 case
	 	when a.disbby is null or a.disbby in  ('',',')  then us.username
	 	else a.disbby 
	 end tlr,a.source
from customer c
inner join office ce on ce.officeid  = c.centercode
inner join office u on u.officeid = ce.parentid
inner join office ar on ar.officeid = u.parentid
inner join accounts a on a.cid = c.cid   and a.apptype = 3 and a.status not in (25,20)
inner join lnchrgdata l  on l.acc = a.acc and l.chrgcode  = 16 
left  join referenceview r on r.code  = cast(a.status as varchar(2))  and r.reftype ='LoanStatus'
left join userslist us on us.USERID = a.updateruserid 
order by ar.officename,u.officename,ce.officename
) b 
where lrf <> reqlrf and disbdate >='2024-08-01'