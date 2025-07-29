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