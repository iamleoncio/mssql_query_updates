-- **********************************************************************************    
    
ALTER  FUNCTION RefDueDate(@AnnumDiv as SmallInt,    
                            @dTrn     as DateTime,    
                            @bStart   as Bit = 0)    
RETURNS DATETIME    
AS    
  BEGIN    
--    DECLARE @dTrn     as DateTime    
    DECLARE @dRel     as DateTime    
    DECLARE @dRef     as DateTime    
    
--    SET @dTrn = (Select ebSysDate From OrgParms)    
    
 IF @bStart = 0  --Get the last Due Date Reference    
 BEGIN          
    SET @dRef = CASE    
             WHEN @AnnumDiv  in (0,50) THEN -- Weekly (Every Friday)    
    
                  @dTrn + 6 - DatePart(dw,@dTrn)    
             WHEN @AnnumDiv  in (2,24) THEN -- Semi-Monthly (Every 15 and End of the month)    
                  CASE WHEN Day(@dTrn) <= 15 THEN    
                                 DateAdd(day,15-day(@dTrn),@dTrn)    
                       ELSE DateAdd(Day,-1,DateAdd(Month,1,    
                                    DateAdd(day,1-day(@dTrn),@dTrn)))    
                  END    
             WHEN @AnnumDiv  in (1,12) THEN -- Monthly      (Every End of the month)    
                  DateAdd(Day,-1,DateAdd(Month,1,    
                          DateAdd(day,1-day(@dTrn),@dTrn)))    
    
--             WHEN 4  THEN -- Quarterly    (Every End of the month)    
--                  DateAdd(Day,-1,DateAdd(Month,1,    
--                          DateAdd(day,1-day(@dTrn),@dTrn)))    
--             WHEN 2  THEN -- Semi-Annualy (Every End of the month)    
--                  DateAdd(Day,-1,DateAdd(Month,1,    
--                          DateAdd(day,1-day(@dTrn),@dTrn)))    
    
             WHEN @AnnumDiv  in (3)  THEN -- Every Year   (Every End of the month)    
                  DateAdd(Day,-1,DateAdd(Month,1,    
                          DateAdd(day,1-day(@dTrn),@dTrn)))    
    END    
 END    
 ELSE    
 BEGIN    
    SET @dRef = @dTrn + 1 - DatePart(dw,@dTrn)    
    
/*    
    SET @dRef = CASE @AnnumDiv    
             WHEN 0 THEN -- Weekly (Every Friday)    
    
                  @dTrn + 1 - DatePart(dw,@dTrn)    
             WHEN 1 THEN -- Semi-Monthly (Every 15 and End of the month)    
                  CASE WHEN Day(@dTrn) <= 15 THEN    
                            DateAdd(day, 1-day(@dTrn),@dTrn)     
                       ELSE DateAdd(day,16-day(@dTrn),@dTrn) -- DateAdd(Day,-1,DateAdd(Month,1,    
                                    -- DateAdd(day,17-day(@dTrn),@dTrn)))    
                  END    
--select dbo.RefDueDate(24,1), dbo.RefDueDate(24,0)    
    
             WHEN 2 THEN -- Monthly      (Every End of the month)    
                  DateAdd(day, 1-day(@dTrn),@dTrn)     
--             WHEN 4  THEN -- Quarterly    (Every End of the month)    
--                  DateAdd(day, 1-day(@dTrn),@dTrn)     
--             WHEN 2  THEN -- Semi-Annualy (Every End of the month)    
--                  DateAdd(day, 1-day(@dTrn),@dTrn)     
             WHEN 3  THEN -- Every Year   (Every End of the month)    
                  DateAdd(day, 1-day(@dTrn),@dTrn)     
*/    
    END    
    
    RETURN @dRef    
  END 