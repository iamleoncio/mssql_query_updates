with ppi as (
select cid,infodate,
		(
        MAX(CASE WHEN x.ppiquestionid IN (13,23) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (14,24) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (15,25) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (16,26) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (17,27) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (18,28) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (19,29) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (20,30) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (21,31) THEN value ELSE 0 END) +
        MAX(CASE WHEN x.ppiquestionid IN (22,32) THEN value ELSE 0 END)
    	) AS totalppi,
	   max(case when x.ppiquestionid  in(13,23) then value else  0 end ) as q1,
	   max(case when x.ppiquestionid  in(14,24) then value else  0 end ) as q2,
	   max(case when x.ppiquestionid  in(15,25) then value else  0 end ) as q3,
	   max(case when x.ppiquestionid  in(16,26) then value else  0 end ) as q4,
	   max(case when x.ppiquestionid  in(17,27) then value else  0 end ) as q5,
	   max(case when x.ppiquestionid  in(18,28) then value else  0 end ) as q6,
	   max(case when x.ppiquestionid  in(19,29) then value else  0 end ) as q7,
	   max(case when x.ppiquestionid  in(20,30) then value else  0 end ) as q8,
	   max(case when x.ppiquestionid  in(21,31) then value else  0 end ) as q9,
	   max(case when x.ppiquestionid  in(22,32) then value else  0 end ) as q10,
	   ROW_NUMBER() OVER(PARTITION BY cid ORDER BY infodate desc) AS row_num
		  from (
			select cid, c.ppiquestionid ,value, datetimeupdated ::date infodate from customerppidetails c 
			union 
			select cid, c.ppiquestionid ,value,  timeencoded ::date infodate from custppidetailshistory  c

			)x
		group by cid,infodate 
 		)
	select a.officename area, u.officename  unit, cen.officename center, c.cid,c.localcid eSystemCID, c.lastname,c.firstname,c.middlename,c.birthday,c.dorecognized,
	ac.dopen,ac.accdesc,ac.status,ppi.infodate, totalppi,q1,q2,q3,q4,q5,q5,q7,q8,q9,q10 
	from customer c 
	inner join office cen on cen.officeid  = c.centercode
	inner join office u on u.officeid  = cen.parentid
	inner join office a on a.officeid  = u.parentid
	inner join accounts ac on ac.cid = c.cid and  ac.accttype IN ('301','311','314','316','317','449','450','451','453','463','464','466','474','478','479')
	inner join ppi on ppi.cid = c.cid and ppi.infodate = ac.dopen
	where ac.dopen between '2025-05-01' and '2025-05-30' --and c.cid = 10004432
	order by a.officename , u.officename  , cen.officename