                                                
CREATE   PROCEDURE usp_k2lapply                                                              
(                                                              
    @pPrincipal NUMERIC(16,2),                                                              
    @pTerms INT,                                                              
    @pFrequency INT,                                                              
    @pType INT,                                                              
    @pDateRel DATETIME,                                                              
    @pCID NUMERIC(18,0),                                                              
    @pRefno VARCHAR(100),                                                              
    @pbeneficiaryGender VARCHAR(200),                                                              
    @pbeneficiaryAge VARCHAR(200),                                                              
    @pbeneficiaryBirthday DATETIME,                                                              
    @pbeneficiaryFirstName VARCHAR(200),                                                              
    @pbeneficiaryGrdLevel VARCHAR(200),                                                              
    @pbeneficiaryLastName VARCHAR(200),                                                              
    @pbeneficiaryMiddleName VARCHAR(200),                                                              
    @pContactno VARCHAR(20),                                                              
    @pDateapply DATETIME,                                                              
    @pApprovedBy VARCHAR(20),                                                              
    @pContractualRate decimal(16,2),                                                                           
    @pMidasdate VARCHAR(200),                                                              
    @pMidasresult VARCHAR(200),                                                              
    @pMidasremarks VARCHAR(200),                                                              
    @pRecommender VARCHAR(200),                                                              
    @pRecommendDate VARCHAR(200),                                                              
    @pUMApprover VARCHAR(200),                                                              
    @pUMApproverDate VARCHAR(200),                                                              
    @pAMApprover VARCHAR(200),                                                              
    @pAMApproverDate VARCHAR(200),                                                              
    @pRDApprover VARCHAR(200),                                                              
    @pRDApproverDate VARCHAR(200),                                                              
    @pAOname VARCHAR(200),                                                              
    @pUMname VARCHAR(200),                                                              
    @pCoborrowerName VARCHAR(200),                                                              
    @pCoRelationship VARCHAR(200),                                          
    @peSignAO VARCHAR(MAX) ='',                                          
    @peSignUM VARCHAR(MAX) ='' ,                                           
    @peSignAM VARCHAR(MAX) = '',                                        
    @peSignClient VARCHAR(MAX)='',                                          
    @pbusinesstype varchar(20)                                          
    --------------------------------------------------                                                              
)                                                              
AS                                                              
BEGIN                                                              
------------------------- check of loanid already exist -----------------                                                             
    IF EXISTS (SELECT loanid FROM loanapplication WHERE loanid = @pRefno)            
    BEGIN                                          
        RAISERROR('Loanid already Exists', 16, 1);                        
        RETURN;            
    END                                                              
                      
    DECLARE                                                              
        @vMatDate DATETIME,                             
        @pAcc VARCHAR(22),                                                            
        @pEffrate FLOAT = 0,                                                              
        @pCharges NUMERIC(16,2),                           
        @pInterest NUMERIC(16,2),                                                              
        @pBalance NUMERIC(16,2),                                                                                         
        @areacode VARCHAR(4),                                                                   
        @contact VARCHAR(15),                                                              
        @nextAccNumber VARCHAR(22),                                                              
        @loanbal NUMERIC(14,2),                                    
        @pbtype INT,                
        @pAge int,                
        @pSubclass int                
                 
select @pAge = DATEDIFF(YEAR, doBirth, @pdaterel)                   
                            - CASE                   
                                  WHEN MONTH(@pdaterel) < MONTH(doBirth)                   
                                       OR (MONTH(@pdaterel) = MONTH(doBirth) AND DAY(@pdaterel) < DAY(doBirth))                   
                                  THEN 1                   
                                  ELSE 0                   
                              END ,                 
                              @pSubclass = subclassification,                
                              @pDaterel = ebsysdate from customer c,ORGPARMS                
                              where cid = @pCID                 
                                              
                
IF NOT EXISTS (SELECT 1 FROM refmapping WHERE refid = @pbusinesstype) OR @pbusinesstype = ''                                
    SET @pbtype = 1588                                
ELSE                                
    SELECT @pbtype = ISNULL(localcode, 1588)                                
    FROM refmapping                                
    WHERE refid = @pbusinesstype                                
                                           
                                                              
                                                              
    IF @pType NOT IN (420, 421, 461, 475, 323, 332, 336)                                                              
    BEGIN                                                              
        SELECT @loanbal = (prin / principal) * 100                                                              
        FROM LNMASTER                                                              
        WHERE CID = @pCID AND STATUS IN (30, 91) AND @pType = ACCTTYPE;                                                              
                                         
        IF (@loanbal < 70)                                                              
        BEGIN                                                              
            RAISERROR('WALA PANG 70 PERCENT ANG NABAYARAN!', 16, 1);                                          
            RETURN;                                                              
        END                                                              
    END  ;                                                            
                                                              
------------------------- CREATE ACC -----------------                                                         
    SELECT @areacode = RIGHT('0000' + defreg_areacode + defngo_offcode, 4) FROM orgparms;                                                                SELECT @pAcc = @areacode + '-' + Module_Code + Code + '-' FROM AcctParms WHERE accttype = @pType;    
   
    
    SELECT @nextAccNumber = RIGHT('0000000' + CAST(ISNULL(MAX(CAST(RIGHT(LEFT(Acc, 22), 7) AS INT)), 0) + 1 AS VARCHAR(7)), 7)                                                              
    FROM lnMaster                                                   
    WHERE LEFT(Acc, LEN(@pAcc)) = @pAcc;                                                              
    SET @pAcc = @pAcc + @nextAccNumber;                    
                                
------------------------- INSERT TO LOANAPPLICATION -----------------                                                              
  INSERT INTO loanapplication (                                      
        cid, loanType, loanTerm, loanAmount, paymentMode, messengerID, purposeOfLoan, dateApply, dateRelease, acc,                                                            
        status, uploaded, LoanId, contactNumber, beneficiaryName, Bday, Age, Educ_Lvl, Gender, BFFNAME, BFLNAME, BFMNAME                                                              
    )                                                              
    VALUES (                                                              
        @pCID, @pType, @pTerms, @pPrincipal, @pFrequency, RIGHT(@pRefno, 10), 1552, @pDateapply, @pDateRel, @pAcc,                                                              
        1, 2, @pRefno, @pContactno, dbo.FullName(@pbeneficiaryLastName, @pbeneficiaryFirstName, @pbeneficiaryMiddleName),                                                              
        ISNULL(@pbeneficiaryBirthday, '1900-01-01'), CAST(@pbeneficiaryAge AS SMALLINT), @pbeneficiaryGrdLevel, @pbeneficiaryGender,                                        
        @pbeneficiaryFirstName, @pbeneficiaryLastName, @pbeneficiaryMiddleName                                                              
    );                             
                                                              
------------------------- CREATE LOAN DETAILS -----------------                                             
    IF @pType = 344                                                              
    BEGIN                                                              
 SET @pInterest =                                                               
        round(@pPrincipal*(((-((@pPrincipal * (0.12000 / 50)) /   (1 - POWER(1 + (0.12000 / 50), -@pTerms))) * @pTerms   - @pPrincipal) / @pPrincipal) + 2.0) * -1,2)                                                              
        ;                                                   
    END                                                              
    ELSE                                                              
    BEGIN                                                              
        SET @pInterest = CEILING(      
                               ROUND( (@pPrincipal * dbo.fn_intrate(@pPrincipal, @pFrequency, @pType, @pTerms)),2)      
                                );                                                              
    END    ;                                                          
                                    
                
  EXEC usp_CalculateCharges @pType, @pFrequency, @pPrincipal, @pTerms,@pAge,@pSubclass, @pCharges OUTPUT;                       
                
                                         
     INSERT INTO lnmaster ( CID, ACC, ACCTTYPE, DISBDATE, GIVES, WEEKSPAID, PRINCIPAL, INTEREST,OTHERS,                                                                                                
      DISCOUNTED, NETPROCEED, PNVAL, DISBAMT, PRIN, INTR, OTH,PENALTY, WaivedInt, STATUS, DOPEN, DOMATURITY,                                      
      DOLASTTRN, LASTTRN,DISBBY, APPROVBY, CYCLE, FREQUENCY, ANNUMDIV, LNGRPCODE, PROFF,FUNDSOURCE, DOSRI,                                                                                                 
      INTRATE, LNCATEGORY, CONINTRATE, AmortCond,AmortCondValue, AccruedIntr, BRR)                                                                                                
    VALUES ( @pCID, @pAcc, @pType, @pDateRel, @pTerms, 0, @pPrincipal, @pInterest,0, 0, @pPrincipal - @pCharges, @pPrincipal,                                                                                                
       @pPrincipal,0, 0, 0,0, 0, '20', @pDateRel, '', @pDateRel, 0, 'CAGABAY',@pApprovedBy,1 ,                                 
       case when @pFrequency = 12 then 1 when @pfrequency = 24 then 2 else @pFrequency end  , @pTerms * 7, 24, @pbtype, 'CARD', 0,                                 
       round(dbo.fn_intrate(@pPrincipal, @pFrequency, @pType, @pTerms),4),0, 0,  @pContractualRate, 0, 0, 0);                                                  
                                                                        
    INSERT INTO loaninst                                             
    SELECT * FROM dbo.genloaninstv2(@pAcc, @pPrincipal, @pInterest, @pTerms, @pEffrate, @pDateRel);                              
                                                            
                                                              
    IF @pType IN (344, 418)                                                      
BEGIN                                                              
        INSERT INTO lnbeneficiary (acc, Beneficiary, Bday, age, Educ_Lvl, Gender, BFFNAME, BFLNAME, BFMNAME, remarks)                                                              
        VALUES (                                                              
            @pAcc,                                                              
            dbo.FullName(@pbeneficiaryLastName, @pbeneficiaryFirstName, @pbeneficiaryMiddleName),                                                              
            @pbeneficiaryBirthday,                     
            CAST(@pbeneficiaryAge AS SMALLINT),                                                              
            @pbeneficiaryGrdLevel,                                                              
            CASE WHEN @pbeneficiaryGender = 'Male' THEN '1' ELSE '2' END,                                                              
            @pbeneficiaryFirstName,                                                   
            @pbeneficiaryLastName,                                                              
            @pbeneficiaryMiddleName,                                                              
            ''                                                              
        );                                                              
    END    ;                                                          
------------------------- COMPUTE LRF -----------------                                                              
    INSERT INTO LNCHRGDATA (acc, chd, CHRGCODE, CHRDESC, CHRAMNT, CHRBAL, RefAcc)                                                              
    VALUES (@pAcc, 0, 16, 'MBA Premium (LRF)', @pCharges, @pCharges, '');                                             
                                                              
    IF EXISTS (                                                              
        SELECT 1 FROM lnmaster WHERE cid = @pCID AND ACCTTYPE = @pType AND status = 30 AND ACCTTYPE NOT IN (420, 421, 461, 475, 323, 332, 336)                                                              
    )                                                              
    BEGIN                                                              
  DECLARE @pCharges2 NUMERIC(18,2);                                                              
        DECLARE @pprevACC VARCHAR(22);                                                              
                                                              
        SELECT @pCharges2 = (PRINCIPAL - prin) + (INTEREST - intr), @pprevACC = acc                                                              
FROM lnmaster                                                              
 WHERE cid = @pCID AND ACCTTYPE = @pType AND status IN (30, 91);                                                              
                                                              
        INSERT INTO LNCHRGDATA (acc, chd, CHRGCODE, CHRDESC, CHRAMNT, CHRBAL, RefAcc)                                                              
        VALUES (@pAcc, 0, 18, 'Previous Loan', @pCharges2, @pCharges2, @pprevACC);                                                              
                                                              
        UPDATE LNMASTER SET NETPROCEED = NETPROCEED - @pCharges2 WHERE acc = @pAcc;                                                              
    END    ;                       
                                                              
    EXEC usp_Released @pAcc, 'CAGABAY', @pApprovedBy, @pRefno, 0;                                                              
    EXEC FixLoanTran @pAcc, @pBalance, 0;                                                              
                                         
                                                              
------------------------- UPDATE CYCLE -----------------                                                              
    WITH pcycle AS (                                                              
        SELECT acc, ACCTTYPE, ROW_NUMBER() OVER (PARTITION BY cid, accttype ORDER BY disbdate ASC) pCyc                                                              
        FROM LNMASTER                                                              
        WHERE status NOT IN (25, 20) AND cid = @pCID AND ACCTTYPE = @pType                                                              
    )                                                              
    UPDATE LNMASTER SET cycle = p.pCyc                                                              
    FROM pcycle p                                                              
    WHERE LNMASTER.ACC = p.ACC AND LNMASTER.DISBBY = 'CAGABAY';                    
                                                              
------------------------ RECHECK LOANINST --------------                                         
DECLARE @tAmortAcc varchar(22)                                                          
   SELECT TOP 1   @tAmortAcc = lo.acc                                                           
            FROM loaninst lo                                                            
            INNER JOIN LNMASTER ln ON ln.ACC = lo.ACC AND ln.STATUS IN (30, 91)                          
            WHERE                                    
                GIVES = @pTerms AND                                                           
                ln.ACCTTYPE = @pType AND                                                           
                principal = @pPrincipal AND                                                           
                frequency = @pFrequency AND                                                           
                ln.DISBBY <> 'CAGABAY'                                        
            GROUP BY lo.ACC, ln.DOMATURITY                                                            
            HAVING MAX(lo.DUEDATE) = ln.DOMATURITY                                                          
    if @tAmortAcc is not null                                                           
    BEGIN                                                           
        UPDATE loaninst SET                                                            
        PRIN = CaAmort.prin,                                                            
    INTR = CaAmort.intr,                                                            
        ENDBAL = CaAmort.endbal,                                                            
        ENDINT = CaAmort.endint,                                                            
        CarVal = CaAmort.Carval,                                                            
        UpInt = CaAmort.upint                                                            
    FROM                                                           
        (select * from loaninst where acc = @tamortAcc)CaAmort                                                            
    WHERE loaninst.acc = @pAcc AND loaninst.DNUM = CaAmort.DNUM;                                                          
                                                          UPDATE lnmaster                                                           
    SET DOMATURITY = (SELECT MAX(duedate) FROM LOANINST WHERE acc = @pAcc)                                                           
    WHERE acc = @pAcc;                                                          
                                                          
    UPDATE lnmaster                                                           
    SET DOMATURITY = (SELECT MAX(duedate) FROM LOANINST WHERE acc = @pAcc)                                
    WHERE acc = @pAcc;                                                          
    END                                                       
    ELSE                                                          
    BEGIN                                                                                     
    exec RecomSched3 @pacc;                                                          
    END;                                                          
                                                              
                                                                                        
------------------------- INSERT TO GABAYKONEKDTLS -----------------                                                                 
INSERT INTO gabayKonekDtls ( loanid, midasdate, midasresult,midasremarks,recommender, recommenddate,UmApprover,UMApproverDate, AMApprover,AMApproverDate,RDApprover,RDApproverDate,AOName,UMName,CoborrowerName,Corelationship,eSignAO,eSignUM,esignAM,eSignCl
Ient)                                        
VALUES(@pRefno, @pMidasdate,@pMidasresult,@pMidasremarks, @pRecommender,@pRecommendDate,@pUMApprover,@pUMApproverDate,@pAMApprover,@pAMApproverDate,@pRDApprover,@pRDApproverDate,@pAOname,@pUMname,@pCoborrowerName,@pCoRelationship,'','','','')             
  
                        
                
                  
                    
                      
                                                     
END ;                                                
                          
  PRINT 'Successfully Released from CAGABAY LOS'; 