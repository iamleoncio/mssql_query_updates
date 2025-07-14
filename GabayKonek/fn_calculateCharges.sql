CREATE FUNCTION fn_CalculateCharges      
(      
    @paccttype INT,      
    @pfrequency INT,      
    @Principal DECIMAL(10, 2),      
    @Term INT      
)      
RETURNS NUMERIC(16, 2)      
AS      
BEGIN      
    DECLARE @Charges NUMERIC(16, 2);      
      
    IF @pfrequency IN (0, 50)      
        SET @Charges = CEILING((@Principal / 1000.0) * 0.3 * @Term);      
    ELSE IF @pfrequency IN (1, 12)      
        SET @Charges = CEILING(((0.015 / 12.0) * @Term) * @Principal);      
    ELSE IF @pfrequency in(2,24)      
        SET @Charges = CEILING(((0.015 / 24.0) * @Term) * @Principal);      
    ELSE      
        SET @Charges = 0;      
      
    RETURN @Charges;      
END; 