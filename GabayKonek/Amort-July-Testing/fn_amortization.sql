alter FUNCTION dbo.fn_amortization          
(          
    @pAcc VARCHAR(22),      
    @pPrincipal INT,          
    @pTerm INT,          
    @pFrequency INT,          
    @pAccttype INT,          
    @DateReleased DATE,    
    @pInterest DECIMAL(16,2)    
)          
RETURNS @amort TABLE          
(          
    DNUM INT,      
    ACC VARCHAR(22),    
    DUEDATE DATE,          
    AMORT DECIMAL(18,2),          
    PRIN DECIMAL(18,2),          
    INTR DECIMAL(18,2),          
    ENDBALPRIN DECIMAL(18,2),          
    ENDBALINT DECIMAL(18,2),          
    CARVAL DECIMAL(18,2),          
    UPINT DECIMAL(18,2),      
    Oth DECIMAL(18,2),      
    Penalty DECIMAL(18,2),      
    EndOth DECIMAL(18,2),      
    InstPd DECIMAL(18,2),      
    InstFlag DECIMAL(18,2),      
    PenPd DECIMAL(18,2),      
    ServFee DECIMAL(18,2),      
    PledgeAmort DECIMAL(18,2),      
    Amort_Oth DECIMAL(18,2),      
    Balance_Oth DECIMAL(18,2)      
)          
AS          
BEGIN          
    DECLARE               
        @pAmort DECIMAL(18,2),          
        @pIntratePerWeek FLOAT,          
        @dnum INT = 1,          
        @EndBalPrin INT = @pPrincipal,          
        @CumIntr DECIMAL(18,2) = 0,          
        @Intr DECIMAL(18,2),          
        @Prin INT,          
        @WeeklyAmort DECIMAL(18,2),          
        @PrevDate DATE = @DateReleased,          
        @DueDate DATE;        
      
    SET @pAmort =          
        CASE          
            WHEN @pAccttype = 344          
            THEN ROUND((@pPrincipal * (1 + CAST(@pInterest AS FLOAT) / @pPrincipal)) / @pTerm, 2)    
            WHEN @pAccttype in (420,461,476) THEN CEILING((@pPrincipal*(1+(0.24/50) * @pTerm)/@pTerm)/ 5.0) * 5     
            ELSE CEILING((@pPrincipal * (1 + CAST(@pInterest AS FLOAT) / @pPrincipal) / @pTerm) / 5.0) * 5          
        END;         
      
    IF @pAccttype <> 461   
    SET @pIntratePerWeek = dbo.fn_rate(@pTerm, -@pAmort, @pPrincipal);          
    ELSE   
    SET @pIntratePerWeek = 0.009249743  
  
  
    WHILE @dnum <= @pTerm          
    BEGIN          
        -- Compute next due date  
        SET @DueDate =   
            CASE          
                WHEN @pFrequency = 50 THEN DATEADD(DAY, 7, @PrevDate)          
                WHEN @pFrequency = 1 THEN DATEADD(MONTH, 1, @PrevDate)          
                WHEN @pFrequency = 2 THEN DATEADD(DAY, 14, @PrevDate)          
                ELSE DATEADD(DAY, 7, @PrevDate)          
            END;  
  
        -- Skip holiday range: Dec 21 – Jan 4  
    WHILE @DueDate BETWEEN 
        CAST(CAST(YEAR(@DueDate) AS VARCHAR(4)) + '-12-21' AS DATETIME) 
        AND 
        CAST(CAST(YEAR(@DueDate) + 1 AS VARCHAR(4)) + '-01-04' AS DATETIME)
        BEGIN  
            SET @PrevDate = @DueDate;  
            SET @DueDate =   
                CASE          
                    WHEN @pFrequency = 50 THEN DATEADD(DAY, 7, @PrevDate)          
                    WHEN @pFrequency = 1 THEN DATEADD(MONTH, 1, @PrevDate)          
                    WHEN @pFrequency = 2 THEN DATEADD(DAY, 14, @PrevDate)          
                    ELSE DATEADD(DAY, 7, @PrevDate)          
                END;  
        END  
      
        SET @Intr =          
            CASE          
                WHEN @pAccttype = 344 THEN ROUND(@EndBalPrin * @pIntratePerWeek, 2)  
                ELSE ROUND(@EndBalPrin * @pIntratePerWeek, 0)          
            END;        
      
        IF @CumIntr + @Intr > @pInterest          
            SET @Intr = @pInterest - @CumIntr;        
      
        SET @Prin = CAST(@pAmort AS INT) - CAST(@Intr AS INT);        
      
        IF @dnum = @pTerm OR @Prin >= @EndBalPrin OR @EndBalPrin - @Prin <= 1        
        BEGIN        
            SET @Prin = @EndBalPrin;        
            SET @Intr = @pInterest - @CumIntr;        
            SET @WeeklyAmort = @Prin + @Intr;        
        END         
        ELSE          
        BEGIN          
            SET @WeeklyAmort = @Prin + @Intr;          
        END;          
      
        INSERT INTO @amort (      
            dnum, acc, DueDate, Amort, Prin, Intr, EndBalPrin, EndbalInt,      
            CarVal, UpInt,      
            Oth, Penalty, EndOth, InstPd, InstFlag, PenPd, ServFee, PledgeAmort, Amort_Oth, Balance_Oth      
        )          
        VALUES (      
            @dnum, @pAcc, @DueDate, @WeeklyAmort, @Prin, @Intr,       
            @EndBalPrin - @Prin,       
            @pInterest - (@CumIntr + @Intr),       
            CAST(@EndBalPrin - @Prin AS DECIMAL(18,2)),       
            CAST(@pInterest - (@CumIntr + @Intr) AS DECIMAL(18,2)),      
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0      
        );          
      
        SET @EndBalPrin -= @Prin;          
        SET @CumIntr += @Intr;          
        SET @PrevDate = @DueDate;  
        SET @dnum += 1;          
    END          
      
    RETURN;          
END;  