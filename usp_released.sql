        
 /*            
 Edited by : Leoncio P. Pasiliao Jr.                        
Date      : 06-20-2025                          
Reason    :             
 -- added control for PNPL - Leon            
 -- added control to avoid single beneficiary for multiple educ loan - Leon            
 -- Add Semi- Monthly and Monthly LRF for Housing and BAL            
 -- add control on exceeding age 70            
 */            
             
 CREATE OR ALTER PROCEDURE usp_Released(@Acc         as VarChar(20),                                                       
                              @PostBy      as VarChar(15),                                                      
                              @TermID      as VarChar(15),                                                      
                              @RefNo       as VarChar(50) = '',                                                      
                              @lnStatus    as SmallInt = 0)                                                      
AS                                                       
    DECLARE @Trn     as Int                                                      
    DECLARE @TrnAmt  as Numeric(14,2)                                                      
    DECLARE @TrnDate as DateTime                                                      
    DECLARE @TrnType as SmallInt                                                       
    DECLARE @BalPrin as Numeric(14,2)                                                      
    DECLARE @BalInt  as Numeric(14,2), @BalOth as Numeric(14,2)                                                      
    DECLARE @pAcc    as Varchar(20), @PlgAcc VarChar(20),                                                      
            @CID     as Int,                                                      
            @PrevVal as Numeric(14,2),                                                      
            @OthCr   as Numeric(14,2),                                                      
            @OthDr   as Numeric(14,2),                                                      
            @Penalty as Numeric(14,2),                                                      
            @Msg     as VarChar(30),                                                      
            @TrnDesc as VarChar(100),                                                      
            @Disc    as Numeric(14,2),                                                      
            @PlgAmt  as Numeric(14,2),                                                      
            @AcctType as Int,                                                
            @cid2 as int,                                        
            @cid3 as int,                                                
            @SumMFSk as numeric(14,2),                                                      
            @RunState as Int,                                              
            @lnbcname varchar(200),                                              
            @lnbfname varchar (200),                                              
            @lnbmname varchar (200),                                              
            @lnbbday datetime,                                  
            @lrfcharge int,                          
            @pPrincipal decimal(16,2),                          
            @lnbbene varchar(200),                                              
            @lnbage int,                                              
            @lnblvl varchar(200),                 
            @plngender INT,      
            @pdisbby varchar(20),      
   @pterm int,                   
   @pfrequency int,                          
   @pintrate decimal(14,5)                            
   Declare @inst int,                                                      
   @savParticular as varchar(100),                                                      
   @lnParticular as varchar(100),                                                      
@isDeposit int,                                        
   @Subclassf int               
   SET @lnParticular = 'Loan Disburesement'         
         
select @pdisbby = disbby from lnmaster where acc =@acc;      
                                                         
    SELECT @CID = CID,                                                      
           @BalPrin  = Principal,                                                 
           @BalInt   = Interest,                                                      
           @BalOth   = Interest,                                                      
           @TrnAmt   = Principal - Discounted,                                                      
           @Disc     = Discounted,                                                      
           @lnStatus = Status,                                                      
           @AcctType = AcctType                                                      
       FROM lnMaster Where Acc = @Acc                                                      
    IF EXISTS (SELECT CID FROM inactiveCID WHERE inActive = 1 and CID = @CID)                                                   
    BEGIN                                                      
       RAISERROR ('Cannot Transaction with inActive Clients...', 16, 1)                                                      
       RETURN                                          END                                                      
    SET @TrnType  = 3100                                                      
    SELECT @TrnDate  = ebSysDate, @RunState = RunState                                                      
        from OrgParms                                                      
    IF @RunState <> 0                                                      
    BEGIN                                                      
       RAISERROR ('Cannot Transaction. Paki Check ng Status ng System...', 16, 1)                                          
       RETURN                                                      
    END                                     
    IF @lnStatus not in (0,10,20)                                                      
    BEGIN                                            
       RAISERROR ('Cannot Released Loan: Loan Status is not Approved Pending (0,10,20)', 16, 1)                                                      
       RETURN                                                      
    END                                        
                                  
-----------------------LNBENEFICIARY -----------------------------------------------------------                                           
IF @AcctType IN (344, 418)                
BEGIN                
    SELECT                 
        @lnbcname = BFLNAME,                
        @lnbfname = BFFNAME,                
        @lnbmname = BFMNAME,                
        @lnbage = Age,                
        @lnblvl = Educ_Lvl,                
        @lnbbene = Beneficiary,                
        @lnbbday = Bday,                
        @plngender = gender                
    FROM lnbeneficiary                
    WHERE ACC = @Acc;                
                
    IF (                
        @lnbcname = '' OR len(@lnbcname) <= 1 OR                
        @lnbfname = '' OR len(@lnbfname) <= 1 OR                
        @lnblvl = '' OR                 
        @lnbage = '' OR                 
        @lnbbene = '' OR len(@lnbbene) <= 1 OR                
        @lnbbday = '' OR                
        @plngender = '' OR @plngender = 0  or @plngender = -1                 
    )                
    BEGIN                
        RAISERROR ('INCOMPLETE BENEFICIARY INFO, PLEASE CHECK BENEFICIARY', 16, 1);                
        RETURN;                
    END                
end                     
-----------------------PNPL -----------------------------------------------------------                   
IF @AcctType = 476            
BEGIN             
    SELECT @pPrincipal = principal, @pterm = GIVES             
    FROM lnmaster             
    WHERE acc = @Acc;            
            
    IF EXISTS (            
        SELECT 1             
        FROM CUSTOMER C, ORGPARMS             
        WHERE cid = @CID             
        AND DATEDIFF(YEAR, DORECOGNIZED, EBSYSDATE) < 3            
    )            
    BEGIN            
        IF @pPrincipal > 5000            
        BEGIN            
            RAISERROR('Putek ka bawal yan ! - Jade.', 16, 1);            
            RETURN;            
        END            
    END            
    ELSE IF @pterm > 23            
    BEGIN            
        RAISERROR('Putek ka bawal yan ! - Jade.', 16, 1);            
        RETURN;            
    END            
END              
-----------------------HOUSING -----------------------------------------------------------                                           
IF @AcctType IN (318,487)  and @pdisbby <> 'CAGABAY'                                  
BEGIN                   
    SELECT                   
        @pterm = gives,                            
        @pintrate = intrate,                            
        @lrfcharge = lc.CHRAMNT,                          
        @pPrincipal = principal,                  
        @pfrequency = frequency                          
    FROM LNMASTER ln                            
    LEFT JOIN LNCHRGDATA lc ON lc.ACC = ln.acc                            
    WHERE ln.acc = @Acc;                    
               
    IF @pterm < 50 AND @pfrequency IN (0, 50)                  
    BEGIN                  
        UPDATE LNCHRGDATA                   
        SET CHRAMNT = CEILING((@pprincipal / 1000.00) * 0.3 * @pterm)                  
        WHERE ACC = @Acc AND CHRGCODE = 16;                  
    END                  
             
    IF @pterm < 12 AND @pfrequency = 1                  
    BEGIN                  
        UPDATE LNCHRGDATA                   
        SET CHRAMNT = CEILING((0.015 / 12 * @pterm) * @pprincipal)                  
        WHERE ACC = @Acc AND CHRGCODE = 16;                  
    END                  
              
        IF @pterm < 24 AND @pfrequency = 2                  
    BEGIN                  
        UPDATE LNCHRGDATA                   
        SET CHRAMNT = CEILING((0.015 / 24 * @pterm) * @pprincipal)                  
        WHERE ACC = @Acc AND CHRGCODE = 16;                  
    END                      
    IF (                  
        (@pterm > 50 AND @pintrate IN (0.5200, 0.7600, 1.00, 1.2400)) OR                    
        (@pterm > 50 AND @lrfcharge = CEILING((@pPrincipal / 1000) * 0.3 * 50)) OR                     
        (@pterm > 50 AND @lrfcharge <= 0) OR                     
        (@pterm > 50 AND @lrfcharge IS NULL)                      
    )                    
    BEGIN                                                
        RAISERROR ('Please edit Interest Rate then change LRF Amount', 16, 1);                                                
        RETURN;                                                
    END                                               
END                  
            
------------------ GLIP  Control ------------------             
    DECLARE @pdobirth DATE, @pseventy DATE, @pdorecognized DATE, @pdomaturity DATE, @pseventypayb DATE, @ebsysdate DATE;            
    SELECT             
        @pdobirth = DOBIRTH,             
        @pdorecognized = DORECOGNIZED,        
        @ebsysdate = ebsysdate        
    FROM CUSTOMER, ORGPARMS             
    WHERE CID = @CID;            
            
    SELECT             
        @pdomaturity = DOMATURITY             
    FROM LNMASTER             
    WHERE ACC = @Acc;            
    SET @pseventy = DATEADD(YEAR, 70, @pdobirth);            
    SET @pseventypayb = DATEADD(YEAR, 75, @pdobirth);            
            
    IF           
    (@pdorecognized > '2006-06-01' AND @pdomaturity > @pseventy and DATEDIFF(YEAR,@pdobirth, @ebSysDate) < 70  )          
            
 BEGIN            
        RAISERROR('Loan term should not extend beyond age 70.', 16, 1);            
        RETURN;            
    END              
       IF           
    (@pdorecognized > '2006-06-01' AND @pdomaturity > @pseventypayb and DATEDIFF(YEAR,@pdobirth, @ebSysDate) between 70 and  74)            
            
    BEGIN            
        RAISERROR('Loan term should not extend beyond age 75.', 16, 1);            
        RETURN;            
    END              
             
------------ for below4wks                    
IF @AcctType not in (451,449,316,485,318,450)                                          
BEGIN                                            
                                   
                              
    SELECT @pterm = gives                           
                            
     from  LNMASTER ln                            
                      
     where ln.acc = @Acc;                            
                                 
    IF @pterm < =3                     
    BEGIN                                                
   RAISERROR ('Cannot Proceed with 4 weeks below term, Click Continue and Correct the Loan Term', 16, 1);                                                
        RETURN;                                                
    END                                               
END                          
                    
------------ not allowing lumpsum semi and monthly                    
IF @AcctType not in (451,449,316,485,318,450)                                        
BEGIN                                            
                                            
                              
    SELECT @pterm = gives                           
                            
     from  LNMASTER ln                            
                            
     where ln.acc = @Acc                            
             and frequency not in (50,0)                    
    IF @pterm < 4                    
    BEGIN                                                
        RAISERROR ('Not Allowing Lumpsum/Monthly or Semi Monthly in Non Agri or QSL Loan', 16, 1);                                                
        RETURN;                                                
    END                                               
END                          
------------------------------------IT MONITORING CONTROLS-------------------------------                    
--EXEC esystem_controls @acc, @AcctType, @pterm, @cid                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                            
-----------------------------------------------------------------------------                                                      
-- Get Upfront Charges                                                      
-----------------------------------------------------------------------------                                                         
    SELECT @PlgAmt  = Sum(CASE WHEN ChrgCode = 14 THEN ChrAmnt ELSE 0 END),                                                      
           @PrevVal = Sum(CASE WHEN ChrgCode = 18 THEN ChrAmnt ELSE 0 END),                                                      
           @OthCr   = SUM(ChrAmnt)                                                      
      FROM lnchrgdata WHERE Acc = @Acc                                                      
-----------------------------------------------------------------------------                                                      
-- Get Other Charges                                                      
-----------------------------------------------------------------------------                                                         
    SELECT @OthDr   = SUM(Oth)                                                      
      FROM LoanInst WHERE Acc = @Acc                                           
   --- for Revision                                               
    SET @Penalty = 0                                                      
-----------------------------------------------------------------------------                                                      
-- Updating Pledge Deposit                                                      
-----------------------------------------------------------------------------                                                         
IF IsNull(@PlgAmt,0) <> 0                                                       
    BEGIN                                                      
       SELECT @PlgAcc = Acc FROM saMaster Where CID = @CID and Type = 60 and Status in (20,10,90)                                                      
       IF IsNull(@PlgAcc,'') = ''                                                       
       BEGIN                                            
          RAISERROR ('Cannot Released Loan: There is no existing Pledge Account...', 16, 1)                                                      
     RETURN                                                      
       END                                                      
       --select ACC,* from samaster where CID= 2498 and type = 60                                                      
    -- LAst Paramater is 0 or SAF is not Updated                                                      
       EXEC Usp_Updsatran @PlgAcc, 3, 7012, @PlgAmt, 0, 0, @PostBy, @TermID, 'Loan Release',0, 'A', 0                                                       
    END                                                      
-----------------------------------------------------------------------------                                 
-- Updating Previous Loan                                  
-----------------------------------------------------------------------------                                                           
   SET @MSG = 'Loan Renewal-'+@Acc                             
   DECLARE Prev CURSOR KEYSET                                                      
   FOR                                                          
   SELECT RefAcc,ChrAmnt                    
 FROM lnChrgData                                                       
      WHERE Acc = @Acc and ChrgCode = 18 and not RefAcc is null and ChrAmnt <> 0                                                      
   OPEN Prev                                       
   FETCH NEXT FROM Prev INTO @pAcc, @PrevVal                                                      
WHILE (@@fetch_status <> -1)                                                       
   BEGIN                                                      
      IF (@@fetch_status <> -2)                                                       
      BEGIN                                                               
-- select 'prev', @pAcc, 3899, @PrevVal, 0, @PostBy,                                                       
--                            @TermID,@MSG, ''                                                      
        EXEC usp_UpdlnTran @pAcc, 3899, @PrevVal, 0, @PostBy,                                   
                           @TermID,@MSG, ''                                                      
      END                                            
                                                  
    --------------added by SKA TRIGGER CREDIT LIMIT--------------------                                              
    -----DATE MODIFIED 11/08/2023                                          
    -----Modified by Nel                                          
    -----DATE MODIFIED 11/17/2023                                          
                                             
     IF @AcctType in (311,302,475,480)                                                
 BEGIN                                                
    -- Check if the total principal amount for the CID in the inserted data exceeds 50,000                                                
    SELECT @cid2 = CID                   
    FROM LNMASTER                                                
    WHERE ACC = @acc;                                   
                                                   
    SELECT @SumMFSk = SUM(PRINCIPAL)                                                
    FROM LNMASTER                                                
    WHERE CID = @cid2                                                
      AND ACCTTYPE in (311,302,475,480)                                            
      AND STATUS in (30,20) and CID in (select CID from CUSTOMER where subclassification in (1565,1566) and STATUS in (0,1));                                    
                                        
    IF @SumMFSk > 50000                                                
    BEGIN                                                
        RAISERROR ('GLIP Client has already reached the maximum Php 50,000 loanable amount.', 16, 1);                                                
        RETURN;                                                
    END                                  
                                      
 END                                          
                                             
      FETCH NEXT FROM Prev INTO @pAcc, @PrevVal                                                      
   END                                                      
  CLOSE Prev                                                      
   DEALLOCATE Prev                                                      
    SET @OthCr = isNull(@OthCr,0)                                                      
    SET @TrnAmt  = @TrnAmt - @OthCr                                                      
-----------------------------------------------------------------------------                                                      
-- Post Release Transaction                                                      
-----------------------------------------------------------------------------             
--      SELECT @TrnDesc = TrnDesc from trnTypes where TrnType = @TrnType                                                      
--      SELECT @Trn = Max(Trn) from trnMaster Where TrnDate = @TrnDate                                                      
     SET @Trn = 0 --isnull(@Trn,0) + 1                                                      
-----*****************************Added by Anthony Caya 2019-04-15************--                                                      
select @inst = InstitutionID from orgparms                                       
select @isDeposit = isnull(PARM_VAL,0) from Parameters where PARM_CODE = 904 and ACCTTYPE = @AcctType                                           
SET @savParticular = 'Loan Disburesement from  '+@Acc                                                      
print @TrnType                                                      
IF @isDeposit=1 and @TrnType = 3100                                                      
BEGIN                                                      
 DECLARE @savAcc as VarChar(20)                          
 SELECT @savAcc = Acc from saMaster                                                        
 WHERE CID = @CID and Type = 60 and Status in (10,20,90)                                         
                                                       
 IF @savAcc <>'' or @savAcc is not null                                                      
  BEGIN                                                      
   SET @lnParticular = 'Loan Disburesement to ' + @savAcc                                                      
   Exec usp_UpdSaTran  @savAcc,1,7012, @TrnAmt,0, 0,@PostBy,@TermID,@savParticular,0,'A',1,1                                                      
  END                                                      
END                                                      
print @lnParticular                                                      
-----------------------***********************************************************                                                      
     INSERT trnMaster                                                       
        (ACC, trnDate, TRN, TrnType, OrNo, TrnAmt, Prin,                                                      
                IntR, Oth, Penalty,                                                      
                WaivedInt, Balance, UserName, TermID,                                             
                RefNo, TrnDesc, TrnMnem_CD, Particulars,                                                       
                [Time], Cancel)                                                      
         VALUES(@Acc, @TrnDate, @Trn, 3100, 0, Abs(@TrnAmt), -@TrnAmt,                                                       
                @BalInt, -@OthDr, @Penalty,                                                      
                0, @BalPrin+@BalInt, @PostBy, @TermID,                                                       
  @RefNo, @TrnDesc, 42, @lnParticular,                                                      
                GetDate(), 0)                                              
    SET @lnStatus = 30                                                      
     UPDATE lnMaster                                                       
          SET DisbDate   = @TrnDate,                                                      
              OTHERS     = @OthDr,           
              Oth        = 0,                                                      
              NetProceed = @TrnAmt,                                                      
              DisbAmt    = Principal-@OthCr-@Disc,                                                      
              DoLastTrn  = @TrnDate,                                                      
  LastTrn    = @Trn,                                                      
--              LastTrnType= 3100,                                                      
              Prin       = 0,                                                      
              IntR       = 0,                                                      
              Status     = @lnStatus,                           
              DisbBy     = @PostBy           
--              Cycle      = @Cycle                                                      
          WHERE Acc = @Acc                                                      
     UPDATE SAF SET Cash_On_Hand = Cash_On_Hand - @TrnAmt                                                      
         WHERE TlrName = @PostBy                                     
                                     
--for semi monthly release (449,450)                                      
if exists (select acc from LNMASTER where acc=@acc and frequency=2 and DISBDATE=@TrnDate and ACCTTYPE in (449,450))                                               
begin                                      
DECLARE @duedate as DateTime                                      
                                    
Set @duedate = @TrnDate+14                                      
update loaninst set DUEDATE=@Duedate where DNUM=1 and acc=@Acc                             
exec FixMymoraSemiSALPQSL @acc,@duedate,1                                      
end                                      
                                
                                
                                
exec  DueDateCorrect   @Acc                                
-------------------------------------------------------------------------------------------------                                      
                              
--Additional deletion of LRF Charges for GLIP 75 y/0 above / by: MONSKIE    mod:CC   magbase sa client age popup error 3.7.2025                              
   IF EXISTS (                              
    SELECT 1                               
    FROM CUSTOMER                               
    WHERE CID = @CID                               
    AND YEAR(SYSDATETIME() - doBirth) - 1900 >= 75  ---identify if age 75yrs old  above                              
    AND subclassification in ('1565','1566')        ---trigger only sa GLIP1 at GLIP2 Client added 3.19.2025                              
)                              
BEGIN                                    
    SELECT @cid3 = @CID                                                  
    FROM LNMASTER                                                  
    WHERE ACC = @acc;                                    
                                       
    SELECT @lrfcharge = chramnt                               
    FROM lnchrgdata                               
    WHERE acc = @Acc                               
    AND CHRGCODE = 16                                    
    AND acc IN (                              
        SELECT acc                       
        FROM LNMASTER                               
        WHERE acc = @Acc                                     
        AND status IN (30,20)                                     
        AND cid IN (                              
            SELECT cid                               
            FROM CUSTOMER                               
            WHERE CID = @cid3                               
            AND YEAR(SYSDATETIME() - doBirth) - 1900 >= 75                              
        )                              
    );                                 
                                     
    IF @lrfcharge > 0                                    
    BEGIN                                                      
       RAISERROR (' Operation failed: Clients aged 75 years or older cannot proceed with GLIP release. Please remove LRF charges before proceeding.', 16, 1);                              
       RETURN                                                      
    END                    
   -- Check for account type 485 or 311 and verify GLIP client subclassification                    
-- added CC 4/25/25 along with AGRI - GLIP                    
IF @AcctType IN (311, 485)                      
BEGIN                    
    IF NOT EXISTS (                      
        SELECT 1                       
        FROM CUSTOMER                       
        WHERE CID = @CID                       
        AND subclassification IN ('1565', '1566')                      
    )                      
    BEGIN                      
  RAISERROR ('Operation failed: Only GLIP clients are allowed to avail the GLIP loan product.', 16, 1);                      
  RETURN;                      
    END                      
    END                 
END 