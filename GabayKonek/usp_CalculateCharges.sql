CREATE PROCEDURE usp_CalculateCharges                    
(                    
    @paccttype INT,                  
    @pfrequency INT,                  
    @Principal DECIMAL(10, 2),                      
    @Term INT,      
    @pAge int,      
    @psubclass int,      
    @pCharges NUMERIC(16, 2) OUTPUT                    
)                    
AS                    
BEGIN           
    IF @pAge >= 75 and @psubclass in (1565,1566)      
        SET @pCharges = 0      
    ELSE IF @pfrequency IN (0, 50)            
    BEGIN            
        SET @pCharges = CEILING((@Principal / 1000.0) * 0.3 * @Term)            
    END             
    ELSE IF @pfrequency IN (1, 12)            
    BEGIN            
        SET @pCharges = CEILING(((0.015 / 12.0) * @Term) * @Principal)            
    END             
    ELSE IF @pfrequency in (2,24)            
    BEGIN            
        SET @pCharges = CEILING(((0.015 / 24.0) * @Term) * @Principal)            
    END             
END; 