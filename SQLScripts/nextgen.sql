--get loan balance within date range 

 select  * from (
 select c.brcode, c.cid,a.acc, a.principal - a.prin + interest - a.intr  + 
 		coalesce(sum(case when dt.trntype<>0 and mod(dt.trntype,2)=0 and dt.particulars<>'Purchase Load Reversal'  then -dt.trnamt else dt.trnamt end),0) LoanBal
	  		from accounts  a 
	  		left join (
			  		select * from transactiondetails dt 
					where dt.trndate> '2025-07-25'  and
						dt.accttype not in(5000,600,6000,7000) and dt.trntype in(3001,3899) 
					union
					select * from trandetailshistory dt
					where dt.trndate> '2025-07-25' and 
					dt.accttype not in(5000,600,6000,7000) and dt.trntype in(3001,3899)  
		   ) dt on dt.acc = a.acc 
		   inner join customer c on c.cid = a.cid 
		   group by c.cid,a.acc, a.principal , a.prin ,a.interest , a.intr 
		   ) x 
		   where loanbal > 0 



-- get CBU Balance As of
with TrnBal as (
select acc , sum(balance ) balance
	from  (
	SELECT a.acc,
           SUM(CASE WHEN trntype % 2 = 1 THEN trnamt ELSE -trnamt END) AS balance
    FROM trandetailshistory t
    inner join accounts a on a.acc = t.acc and a.accttype = 60
    GROUP BY a.acc
    union
    SELECT a.acc,
           SUM(CASE WHEN trntype % 2 = 1 THEN trnamt ELSE -trnamt END) AS balance
    FROM transactiondetails t
    inner join accounts a on a.acc = t.acc and a.accttype = 60
    GROUP BY a.acc
    )trn
    group by acc
)
select a.acc,a.balance,t.balance from accounts a 
inner join trnbal t on t.acc = a.acc
where a.balance <> t.balance


--Generate Waive

	with param as (
			select '2025-07-29'::date date1 ,'2025-07-29'::date date2
			)
	,trn as (
			select x.*, a.accdesc, (a.domaturity + (COALESCE(mora.mora, 0) || ' days')::interval) AS xdomaturity,
					case 
						when a.frequency in (0,50) then  trndate + ((5 - EXTRACT(DOW FROM trndate))::int) % 7
						when a.frequency in (1,12) then  (DATE_TRUNC('month', trndate) + INTERVAL '1 month - 1 day')::date
						else 
							case 
								when DATE_PART('day', trndate)::int <= 15 
								then DATE_TRUNC('month', trndate)::date + INTERVAL '14 days'
								else
								(DATE_TRUNC('month', trndate) + INTERVAL '1 month - 1 day')::date
							end 
						end refdate
			from (
					select acc, trndate , trntype, trndesc, trnamt, prin, intr  from transactiondetails t  where trntype = 3899
					union 
					select acc, trndate , trntype, trndesc, trnamt,prin, intr  from  trandetailshistory t2   where trntype = 3899
				)x
				inner join accounts a on a.acc = x.acc and a.accttype not in (420,461,475,323,321) 
				left join (select acc, sum(days) mora from 
							 (select distinct acc , days from moratoriumhistory
							 )x
							 group by acc
							 having sum(days)> 0 ) mora on mora.acc = a.acc
				,param 
				where x.trndate between date1 and date2 
			)
			select o3.officename area, o2.officename unit, o.officename center, c.cid, concat(c.lastname, ', ', c.firstname, ' ',c.middlename)Memname,
			a.acc,a.accdesc, t.trndesc, t.trndate,t.trnamt, t.prin, t.intr,
			sum(lo.intr) waived
			from trn t 
				inner join accounts a on a.acc = t.acc
				inner join loaninst lo on lo.acc = t.acc and lo.duedate > t.refdate and lo.duedate <= t.xdomaturity + (((5 - EXTRACT(DOW FROM t.xdomaturity))::int % 7) || ' days')::interval
				inner join customer c on c.cid = a.cid
				inner join office o on o.officeid = c.centercode
				inner join office o2 on o2.officeid = o.parentid
				inner join office o3 on o3.officeid = o2.parentid
			group by o3.officename , o2.officename , o.officename , c.cid,
			a.acc,a.accdesc, t.trndesc, t.trndate,t.trnamt,  t.prin, t.intr
			order by o3.officename , o2.officename , o.officename , c.cid

--nextgen air
with param as (
select '2025-06-30'::date date1
),
trn as (	
select acc, max(trndate)lasttrndate from (
	select * from transactiondetails dt , param
	where dt.trndate<= date1   and
	dt.accttype not in(5000,600,6000,7000) and dt.trntype in(3001,3899) 
	union
	select * from trandetailshistory dt, param
	where dt.trndate<=date1 and 
	dt.accttype not in(5000,600,6000,7000) and dt.trntype in(3001,3899)  
	  )x 
	  group by x.acc 
	)
select o3.officename area, o2.officename unit, o.officename, c.cid,e.acc,x.accttype ,x.term ,x.annumdiv,x.dopen,trn.lasttrndate  ,x.principal ,x.interest ,x.loanbal ,e.carval, sum(lo.intr)ReqInt, sum(lo.upint)ActualIntPaid
from (
 select c.brcode, c.cid,a.acc,a.dopen,a.accttype , a.term,a.annumdiv  ,a.principal ,a.interest , a.principal - a.prin + interest - a.intr  + 
 		coalesce(sum(case when dt.trntype<>0 and mod(dt.trntype,2)=0 and dt.particulars<>'Purchase Load Reversal'  then -dt.trnamt else dt.trnamt end),0) LoanBal,date1
	  		from accounts  a 
	  		left join (
			  		select * from transactiondetails dt , param
					where dt.trndate> date1   and
						dt.accttype not in(5000,600,6000,7000) and dt.trntype in(3001,3899) 
					union
					select * from trandetailshistory dt, param
					where dt.trndate> date1 and 
					dt.accttype not in(5000,600,6000,7000) and dt.trntype in(3001,3899)  
		   ) dt on dt.acc = a.acc 
		   inner join customer c on c.cid = a.cid 
		   group by c.cid,a.acc, a.principal , a.prin ,a.interest , a.intr ,dt.date1 ,a.accttype ,a.term ,a.annumdiv 
		   ) x
		   inner join lpp_accruals(971,'2025-06-30'::date) e on e.acc = x.acc 
		   inner join loaninst lo on lo.acc = x.acc and lo.Duedate <=  x.date1 
		   inner join customer c on c.cid = x.cid 
		   inner join office o on o.officeid = c.centercode 
		   inner join office o2 on o2.officeid = o.parentid
		   inner join office o3 on o3.officeid = o2.parentid
		   left join trn on trn.acc = x.acc
		   where x.loanbal > 0 
		   group  by o3.officename , o2.officename , o.officename, c.cid,e.acc,x.accttype ,x.term ,x.annumdiv ,x.dopen ,x.principal ,x.interest ,x.loanbal ,e.carval,trn.lasttrndate
		   order by o3.officename , o2.officename , o.officename, c.cid,e.acc