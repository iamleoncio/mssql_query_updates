CREATE   FUNCTION fn_intrate                              
(                              
    @pPrincipal NUMERIC(16,4),                                
    @pFrequency INT,                                
    @pAccttype INT,                                
    @pTerm INT                              
)                              
RETURNS DECIMAL(16,7)                              
AS                              
BEGIN                              
    DECLARE @Intrate DECIMAL(16,7);                              
                    
    IF @pAccttype = 344                            
    BEGIN                            
        SELECT @Intrate = CAST(                            
            CEILING(                            
                (((-((@pPrincipal * (0.12 / 50)) /                            
                (1 - POWER(1 + (0.12 / 50), -@pTerm))) * @pTerm                            
                - @pPrincipal) / @pPrincipal) + 2.0) * -1 * 100 * 100) / 100.0                            
            AS NUMERIC(16,4)                            
        );                            
    END                            
    ELSE                            
    BEGIN                            
        SELECT @Intrate = CAST(                            
            ROUND(                            
                CASE                                  
                    WHEN @pFrequency IN (50, 0) THEN                                  
                        CASE                                  
                            WHEN @pAccttype IN (418, 419) THEN (0.18 / 50) * @pTerm                                  
                            WHEN @pAccttype IN (420, 461,475,483,478,323) THEN (@pTerm / 50.0) * 0.24                               
                            WHEN @pTerm / 50.0 > 0.5 THEN (@pTerm / 50.0) * 0.24 + 0.04                                 
                            ELSE (0.32 / 50) * @pTerm                                  
                        END                                  
                    WHEN @pFrequency in (1,12) THEN                                  
                        CASE                                  
                            WHEN @pTerm / 12.0 > 0.5 THEN 0.24 / 12 * @pTerm + 0.04                                  
                            ELSE (0.32 / 12) * @pTerm                                  
                        END                                  
                    WHEN @pFrequency in (2,24) THEN                                  
                        CASE                                  
                            WHEN @pTerm / 24.0 > 0.5 THEN 0.24 / 24 * @pTerm + 0.04                                  
                            ELSE (0.32 / 24) * @pTerm                                  
                        END                                  
                END, 7                                  
            ) AS NUMERIC(16,7)                            
        );                              
    END                            
                            
    RETURN @Intrate;                            
END; 