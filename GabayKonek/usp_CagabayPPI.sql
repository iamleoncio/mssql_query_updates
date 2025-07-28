CREATE PROCEDURE usp_CagabayPPi            
(            
    @pcid INT,            
    @pinfodate DATE,            
    @pinfocode INT,            
    @pinfo INT,            
    @pinfovalue INT            
)            
AS            
BEGIN            
    DECLARE @vcid INT;               
    DECLARE @infodate DATE;            
      
    SELECT @vcid = cid FROM customer WHERE cid = @pcid;                 
    SELECT @infodate = ebsysdate FROM ORGPARMS;          
      
    INSERT INTO EditedCust (cid) VALUES (@pcid);            
            
    IF @vcid IS NOT NULL            
    BEGIN                 
        INSERT INTO custaddinfo (cid, infoDate, infoCode, info, infoValue)            
        VALUES (@pcid, @infodate, @pinfocode, @pinfo, @pinfovalue);            
            
        PRINT 'PPI Inserted';            
    END            
    ELSE            
    BEGIN            
        PRINT 'Customer not found';            
    END            
END; 