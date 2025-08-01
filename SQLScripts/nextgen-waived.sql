
	with param as (
			select '2025-07-01'::date date1 
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
						select acc, trndate , trntype, trndesc, trnamt, prin, intr  from transactiondetails t  where trntype = 3899 or (particulars  = 'Offsetting' and trndesc in ('Business Failure','Health Problem'))
						union 
						select acc, trndate , trntype, trndesc, trnamt,prin, intr  from  trandetailshistory t2   where trntype = 3899 or (particulars  = 'Offsetting' and trndesc in ('Business Failure','Health Problem'))
					)x
					inner join accounts a on a.acc = x.acc and a.accttype not in (420,461,475,323,321,483) 
					left join (select acc, sum(days) mora from 
								 (select distinct acc , days from moratoriumhistory
								 )x
								 group by acc
								 having sum(days)> 0 ) mora on mora.acc = a.acc
					,param 
					where x.trndate =date1
				)
		,SemiMonthly as (
					SELECT x.acc,sum(smintr)smintr FROM (
							    SELECT 
							        l.acc, l.duedate - INTERVAL '21 days' + (n.n - 1) * INTERVAL '7 days' AS duedate,
							        CASE n.n
							            WHEN 1 THEN CEIL(l.intr * 0.35)
							            WHEN 2 THEN CEIL(l.intr * 0.30)
							            WHEN 3 THEN CEIL(l.intr * 0.20)
							            ELSE l.intr - (CEIL(l.intr * 0.35) + CEIL(l.intr * 0.30) + CEIL(l.intr * 0.20))
							        END AS smintr
							    FROM loaninst l
							    JOIN accounts lm ON l.acc = lm.acc
							    JOIN (VALUES (1), (2), (3), (4)) AS n(n) ON true
							    WHERE lm.frequency IN (1, 12)
							    UNION ALL
							    SELECT  l.acc, l.duedate - INTERVAL '7 days' AS duedate,CEIL(l.intr * 0.6) AS smintr
							    FROM loaninst l  
							    JOIN accounts lm ON l.acc = lm.acc  
							    WHERE  lm.frequency IN (2, 24)
							    UNION ALL
							    SELECT  l.acc, l.duedate, l.intr - CEIL(l.intr * 0.6) AS smintr
							    FROM loaninst l  
							    JOIN accounts lm ON l.acc = lm.acc  
							    WHERE lm.frequency IN (2, 24)
							    union all
							    SELECT  l.acc, l.duedate, l.intr  AS smintr
							    FROM loaninst l  
							    JOIN accounts lm ON l.acc = lm.acc  
							    WHERE  lm.frequency IN (0, 50)
					) x
					JOIN accounts ln ON ln.acc = x.acc
					join trn on trn.acc  = ln.acc 
					cross join PARAM 
					WHERE x.duedate > param.date1 + (6 - EXTRACT(DOW FROM ln.domaturity))::int
						and x.duedate <= trn.xdomaturity
						group by x.acc
		)
			select * from (
					select o3.officename area, o2.officename unit, o.officename center, c.cid, concat(c.lastname, ', ', c.firstname, ' ',c.middlename)Memname,
					a.acc,a.accdesc, t.trndesc, t.trndate,t.trnamt, t.prin, t.intr,
					case 
							 WHEN max(am.amortCnt) = 1 THEN a.interest - CEIL((a.interest / 7) *  CEIL((t.trndate - a.dopen) / 7.0))
							else
							sm.smintr
					end waived,sav.acc CBUAcc
					from trn t 
						inner join accounts a on a.acc = t.acc
						inner join (select acc , count(*)amortCnt from loaninst group by acc ) am on am.acc = a.acc
						left join semimonthly sm on sm.acc = t.acc
						inner join customer c on c.cid = a.cid
						inner join office o on o.officeid = c.centercode
						inner join office o2 on o2.officeid = o.parentid
						inner join office o3 on o3.officeid = o2.parentid
						inner join accounts sav on sav.cid = c.cid and sav.apptype = 0 
					group by o3.officename , o2.officename , o.officename , c.cid,
					a.acc,a.accdesc, t.trndesc, t.trndate,t.trnamt,  t.prin, t.intr,sav.acc,smintr
					order by o3.officename , o2.officename , o.officename , c.cid
			) x where x.waived > 0 
			