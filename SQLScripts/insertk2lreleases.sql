CREATE PROCEDURE insertK2lReleases  
@date1 Date,  
@date2 Date  
AS  
BEGIN  
MERGE lpp_whitelist.dbo.k2lReleases AS target  
USING (  
    SELECT brcode, prov, region, areaname, unit, center_name, cid, Memname, contactnum,  
           acctdesc, principal, interest, datereleased, status, loanid, source,  
           acc, par, loanoutstanding, DefAmount, WOPayprin  
    FROM econsoweekly1.dbo.k2lReleases(@date1,@date2)  
) AS source  
ON target.loanid = source.loanid  
  
WHEN MATCHED THEN   
    UPDATE SET   
        target.par = source.par,  
        target.AdjEndbalprin = source.loanoutstanding,  
        target.DefAmount = source.DefAmount,  
        target.WOPayprin = source.WOPayprin  
  
WHEN NOT MATCHED BY TARGET THEN   
    INSERT (  
        brcode, prov, region, areaname, unit, centername, cid, Memname, contactnum,  
        acctdesc, principal, interest, datereleased, status, loanid, source,  
        acc, par, AdjEndbalprin, DefAmount, WOPayprin  
    )  
    VALUES (  
        source.brcode, source.prov, source.region, source.areaname, source.unit,  
        source.center_name, source.cid, source.Memname, source.contactnum,  
        source.acctdesc, source.principal, source.interest, source.datereleased,  
        source.status, source.loanid, source.source, source.acc, source.par,  
        source.loanoutstanding, source.DefAmount, source.WOPayprin  
    );  
END