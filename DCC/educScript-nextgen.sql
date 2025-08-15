--Active HS
with param as (
    select '2025-06-01'::date as startDate, '2025-06-30'::date as endDate
),
uuid as (
select a.cid, a.acc, case when a.source = 'Migrated' then a.localacc when a.source ='Konek2Loan' then a.loanid else l.uuid end uuid  from accounts a
left join lnaccountsinfo l on l.loanid  = a.loanid 
where a.accttype in (343,418,445,455,456)
union all
select a.cid, a.acc,m."uuid" from accounts a 
inner join draft.migratedlnbeneficiary m on m.localacc  = a.localacc
where a.accttype  in (343,418,445,455,456)
), 
trn as (
select acc, max(maxDate)tmaxdate from (
select acc, max(trndate)maxDate from trandetailshistory t,param  where accttype in (343,418,445,455,456) and t.trndate between param.startDate and param.endDate
group by acc
union all 
select acc, max(trndate)maxDate from transactiondetails t,param where accttype in (343,418,445,455,456) and t.trndate between param.startDate and param.endDate
group by acc
) b group by acc
)
select c.cid, a.acc,o3.officename area, o2.officename unit, o.officename Center, concat(c.lastname,', ',c.firstname,' ',c.middlename)MemName,initcap(concat_ws(' ', CASE WHEN l.lname IS NOT NULL AND l.fname IS NOT NULL THEN l.lname || ',' ELSE l.lname END, l.fname, l.mname)) Beneficiary,r.title gender,l.birthdate,DATE_PART('year', AGE(l.birthdate)) AS benAge,r2.title GradeLevel,a.dopen,a.domaturity,cast(a.interest/a.principal as decimal(16,4))intrate,a.term,a.principal,a.interest,a.prin,a.intr,a.principal -a.prin PrinBal ,a.interest - a.intr IntrBal,a.cycle,
coalesce(tmaxdate,a.lasttransactiondt) lasttrndate ,a.source,
case when a.status in (30, 91) then 'Active' else 'Closed' end LnStatus, 
case 
    when c.customerstatus = 611 then 'Active'
    when c.customerstatus = 613 then 'Inactive'
    else 'Resigned'
end as CusStatus
from customer c 
inner join office o on o.officeid = c.centercode
inner join office o2 on o2.officeid = o.parentid
inner join office o3 on o3.officeid = o2.parentid
inner join accounts a  on a.cid = c.cid and a.accttype in (343,418,445,455,456) 
left join uuid u on u.acc = a.acc
left join lnbeneficiary l  on l.uuid = u.uuid
left join referenceview r  on r.refid  = l.genderid  and  r.reftypeid =5
left join referenceview r2  on r2.refid  = l.educationalattainmentid  and r2.reftypeid =70
left join trn t on t.acc = a.acc , param p 
where coalesce(tmaxdate,a.lasttransactiondt) between p.startDate and p.endDate
and r.title is not null
order by o3.officename,o2.officename,o.officename,c.cid





--zedress
--Active HS
with param as (
    select '2025-06-01'::date as startDate, '2025-06-30'::date as endDate
),
uuid as (
select a.cid, a.acc, case when a.source = 'Migrated' then a.localacc when a.source ='Konek2Loan' then a.loanid else l.uuid end uuid  from accounts a
left join lnaccountsinfo l on l.loanid  = a.loanid 
where a.accttype in (344,444,454)
union all
select a.cid, a.acc,m."uuid" from accounts a 
inner join draft.migratedlnbeneficiary m on m.localacc  = a.localacc
where a.accttype  in (344,444,454)
), 
trn as (
select acc, max(maxDate)tmaxdate from (
select acc, max(trndate)maxDate from trandetailshistory t,param  where accttype in (344,444,454) and t.trndate between param.startDate and param.endDate
group by acc
union all 
select acc, max(trndate)maxDate from transactiondetails t,param where accttype in (344,444,454) and t.trndate between param.startDate and param.endDate
group by acc
) b group by acc
)
select c.cid, a.acc,o3.officename area, o2.officename unit, o.officename Center, concat(c.lastname,', ',c.firstname,' ',c.middlename)MemName,initcap(concat_ws(' ', CASE WHEN l.lname IS NOT NULL AND l.fname IS NOT NULL THEN l.lname || ',' ELSE l.lname END, l.fname, l.mname)) Beneficiary,r.title gender,l.birthdate,DATE_PART('year', AGE(l.birthdate)) AS benAge,r2.title GradeLevel,a.dopen,a.domaturity,cast(a.interest/a.principal as decimal(16,4))intrate,a.term,a.principal,a.interest,a.prin,a.intr,a.principal -a.prin PrinBal ,a.interest - a.intr IntrBal,a.cycle,
coalesce(tmaxdate,a.lasttransactiondt) lasttrndate ,a.source,
case when a.status in (30, 91) then 'Active' else 'Closed' end LnStatus, 
case 
    when c.customerstatus = 611 then 'Active'
    when c.customerstatus = 613 then 'Inactive'
    else 'Resigned'
end as CusStatus
from customer c 
inner join office o on o.officeid = c.centercode
inner join office o2 on o2.officeid = o.parentid
inner join office o3 on o3.officeid = o2.parentid
inner join accounts a  on a.cid = c.cid and a.accttype in (344,444,454)
left join uuid u on u.acc = a.acc
left join lnbeneficiary l  on l.uuid = u.uuid
left join referenceview r  on r.refid  = l.genderid  and  r.reftypeid =5
left join referenceview r2  on r2.refid  = l.educationalattainmentid  and r2.reftypeid =70
left join trn t on t.acc = a.acc , param p 
where  coalesce(tmaxdate,a.lasttransactiondt) between p.startDate and p.endDate
and r.title is not null
order by o3.officename,o2.officename,o.officename,c.cid




