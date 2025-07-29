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
