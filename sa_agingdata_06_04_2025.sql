-- DROP FUNCTION public.sa_agingdatalpp(int4, date);

CREATE OR REPLACE FUNCTION public.sa_agingdatalpp(p_brcode integer, p_act_date1 date)
 RETURNS TABLE(brcode integer, mancode integer, accttype integer, ord integer, loanctr bigint, endbalprin numeric, endbalint numeric, llprate numeric, llpamt numeric, dueprin integer, dueint integer)
 LANGUAGE plpgsql
AS $function$
begin

return query 
with ActRef as(
				select p_Act_Date1::date as Act_Date1
			),
			AgingData as (
			 	SELECT 
			 		CID, ACC, m.ManCode, m.AcctType, r.Ord, Item, r.LLPRate, MeetingDay,  
			    	SUM(CASE WHEN m.EndBalPrin > 0 THEN 1 ELSE 0 END) LoanCtr,   
			        Sum(m.EndBalPrin) EndBalPrin, Sum(m.EndBalInt) EndBalInt,   
			        Sum(Round(m.EndBalPrin*r.LLPRate/100,2)) LLPAmt, Date1  
				from (  
			  		SELECT l.Acc, l.ManCode, l.CID, l.AcctType, MeetingDay,  
			         	l.Principal, l.Interest, l.EndBalPrin, l.EndBalInt,   
			         	dueDate-EXTRACT(DOW FROM dueDate)::int+MeetingDay+CASE WHEN AcctDesc Like '%Salary%' THEN 45 ELSE 0 END StartArrears, 
			         	Date1  
			  		FROM (
			  			SELECT cen.parentid ManCode, c.CID, m.Acc, m.AcctType,   
			            	case cen.MeetingDay when 92 then 1
								            	when 93 then 2
								            	when 94 then 3
								            	when 95 then 4
								            	when 96 then 5
								            	else 1 end MeetingDay,   
			            	m.Principal, m.Interest-Discounted Interest,  
			            	m.Principal - m.Prin               + coalesce(Sum(t.Prin),0) EndBalPrin,  
			            	m.Interest  - m.IntR - m.WaivedInt + coalesce(Sum(t.IntR+t.WaivedInt),0) EndBalInt, Act_Date1 Date1  
			        	FROM accounts m  
			           	INNER JOIN Customer c  on c.CID = m.CID  
			           	inner join ActRef a on m.dopen <= Act_Date1
			           	INNER JOIN office cen  on cen.officeid = c.CenterCode  
			           	LEFT JOIN 
			           		(select * from transactiondetails union all select * from trandetailshistory) t on t.Acc = m.Acc and t.TrnDate > Act_Date1 and t.trnType in (3001,3097,3098,3099,3899,3201,3202)   
			           	LEFT JOIN WriteOff  w on w.Acc = m.Acc and w.TrnDate <= Act_Date1  
			          	WHERE (m.Status in (30,91) OR (m.Status in (98,99) and t.Acc is not Null)) and w.Acc is null and c.brcode = p_brcode
			          	GROUP BY cen.MeetingDay, c.CID, cen.parentid, m.Acc, Act_Date1,  
			             	m.AcctType, m.Principal, m.Interest, Discounted, m.WaivedInt, m.Prin, m.IntR
						) l  
			  			INNER JOIN AcctParms y on y.AcctType = l.AcctType  
			      		LEFT JOIN LoanInst i on i.Acc = l.Acc   
			  			WHERE (l.EndBalPrin + l.EndBalInt Between  
			          		EndBal+EndInt + .0001 and EndBal+EndInt+Prin+IntR+Oth  
			          		OR (l.EndBalPrin+l.EndBalInt<=0 and EndBal+EndInt = 0)  
			          		OR (l.EndBalPrin+l.EndBalInt>Principal+Interest and dNum = 1))
					) m  
					INNER JOIN ActRef on 0=0
			 		LEFT  JOIN 
			 			(SELECT l.AcctType,  a.Ord, Item, rMin, rMax,   
			            		CASE a.ORD WHEN  1 THEN CurrentLoan  
			                             WHEN  2 THEN PAR1to7  
			                             WHEN  3 THEN PAR8to30  
			                             WHEN  4 THEN PAR31to60  
			                             WHEN  5 THEN PAR61to90  
			                             WHEN  6 THEN PAR91to180  
			                             WHEN  7 THEN PAR181to365 
			                             ELSE PAR365More END LLPRate  
			          	FROM AgingTable a
			          	INNER JOIN llprate l on 0=0 
			            ) r on ((StartArrears Between Act_Date1 -rMax and Act_Date1 -rMin) or   
			                    (StartArrears > Act_Date1 and rMin = 0) or  
			                    (StartArrears < Act_Date1 -rMin and rMax = -1)) and r.AcctType = m.AcctType  
			            
			  		GROUP BY CID, Acc, m.ManCode, m.AcctType, Item, r.LLPRate, r.Ord, MeetingDay, Date1
			)
			select  man.parentid Brcode , a.ManCode, a.AcctType, a.Ord, a.LoanCtr, a.EndBalPrin, a.EndBalInt, a.LLPRate, a.LLPAmt, 0 DuePrin, 0 DueInt  FROM AgingData  a 
			inner join office man on man.officeid =  a.mancode
			where man.parentid = p_Brcode;

END;				
$function$
;