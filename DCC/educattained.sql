
select o3.officename, o2.officename ,o2.officeid ,o3.officename,c.cid,concat(c.lastname,', ',c.firstname ,' ',c.middlename )Memname ,c.birthday ,r2.title ,r.title,ky.salaryrange  ,ky.educational   from customer c 
inner join office o on o.officeid =  c.centercode
inner join office o2 on o2.officeid = o.parentid
inner join office o3 on o3.officeid = o2.parentid
inner join customerppi cp on cp.cid = c.cid
inner join referenceview r on r.refid  = (case when cp.indivclassification  is null then cp.memberclassificationid  else cp.indivclassification  end)  and (r.reftype ='SubClassification' or r.reftype ='IndivClassification')
inner join referenceview r2 on r2.refid  = c.customerstatus  and r2.reftype ='CustomerStatus'
left join (select cid, r.title SalaryRange,
			case 
				when k.preschool  = 1 then 'Pre-School'
				when k.elementary  = 1 then 'Elementary'
				when k.highschool   = 1 then 'High-School'
				when k.seniorhighschool   = 1 then 'Senior High School'
				when k.college   = 1 then 'College'
				when k.postgraduate    = 1 then 'Post-Graduate'
				when k.postgraduate    = 1 then 'Post-Graduate'
				when k.outofschool     = 1 then 'Out of School'
			end Educational
			from kyc k 
			left join referenceview r on r.refid  = k.householdmonthlyincome  and r.reftype ='HouseholdMonthlyInc'   ) ky on ky.cid = c.cid 
where r2.title  = 'Active' and o3.officename  not ilike '%ORT%'
order by o3.officename , o2.officename , o.officename, c.cid