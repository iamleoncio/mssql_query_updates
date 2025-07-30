with param as (
select '2025-07-28'::date date1
)
,loan as (
select brcode , sum(Prinbal)PrinBal,sum(x.intbal )IntBal,sum(LoanOutstanding)LoanBal  from (
select ln.brcode,ln.acc, ln.Principal - ln.prin +  sum(case when t.trndate > date1 then t.prin else 0 end) PrinBal , 
ln.interest - ln.intr +  sum(case when t.trndate > date1 then t.intr else 0 end) IntBal,
ln.Principal - ln.prin +  sum(case when t.trndate > date1 then t.prin else 0 end)  + 
ln.interest - ln.intr +  sum(case when t.trndate > date1 then t.intr else 0 end) LoanOutstanding
from staging.lnmaster ln 
left  join staging.trnmaster t on t.acc = ln.acc and t.brcode = ln.brcode  and t.trntype  in (3001,3099,3201,3097,3098,3899,3202) 
left join staging.writeoff w on w.acc = ln.acc  and w.brcode  = ln.brcode,param
where  ln.status not in ('25','20')   and  ln.disbdate <= date1 and w.acc is null--and ln.acc ='0308-4041-0046271'
group by ln.brcode,ln.acc, ln.principal, ln.interest, ln.prin , ln.intr
)x
where PrinBal > 0 or IntBal > 0
group by brcode 
),
sav as (
select  brcode,sum(case when endbal >=5 then 1 else 0 end )Client, SUM(ENDBAL)balance from (
    SELECT s.brcode ,s.balance 
            - SUM(
                CASE  
                    WHEN st.trndate > date1 AND st.trnType % 2 = 0 AND st.pendapprove = 'A' THEN -st.trnamt
                    WHEN st.trndate > date1 AND st.pendapprove = 'A' THEN st.trnamt
                    ELSE 0 
                END
            ) AS endbal
    FROM staging.satrnmaster st
    INNER JOIN staging.samaster s  ON s.acc = ltrim(st.acc) AND s.brcode = st.brcode,param
    GROUP BY s.brcode, s.cid, s.acc, s.balance, s.dopen, s.dolasttrn
)x
group by x.brcode 
			   )
		select b.areaname,client, Balance,lo.prinbal, lo.intbal,lo.loanbal from sav s 
		left join loan lo on lo.brcode  = s.brcode 
		inner join staging.brcodebranch b on b.brcode = s.brcode 
		where  (Balance > 0 or lo.loanbal > 0 )