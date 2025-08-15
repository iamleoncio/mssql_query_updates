update orgparms set WaivableInt = 1;
update loanapplication set contactNumber = a.PHONE4 from ADDRESSES a where a.cid = loanapplication.cid and loanapplication.contactNumber = '' and loanapplication.loanId like '%PN%';
 update loaninst  set OrigDueDt = ori.OrigDueDt from dbo.fn_getOrigDueDate() ori where   ori.acc = loaninst.acc AND ori.dnum = loaninst.dnum