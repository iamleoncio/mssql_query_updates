---added not allowing to void when cagabay  
---added to void to loanapplication when voiding normal release to F2  
  
alter PROCEDURE LNCancel(@Acc VarChar(20), @PostBy  VarChar(15) = '')        
-- ********************************************************************************************        
        
AS        
DECLARE @CID     Int        
DECLARE @PrevAcc VarChar(20)        
DECLARE @Paid    Numeric(14,2)        
DECLARE @BegBal  Numeric(14,2)        
DECLARE @dNum    Int        
DECLARE @BalPrin Numeric(14,2)        
DECLARE @BalInt Numeric(14,2)        
DECLARE @BalOth Numeric(14,2)        
DECLARE @WaivedInt Numeric(14,2)        
DECLARE @PlgAcc VarChar(17)        
DECLARE @PlgTrn Int        
DECLARE @Pledge Numeric(14,2)        
DECLARE @PrevVal Numeric(14,2)        
DECLARE @DisbDate DateTime        
DECLARE @DisbBy VarChar(100)        
DECLARE @NetProceed Numeric(14,2)        
DECLARE @Status Int        
DECLARE @SysDate DateTime        
        
--'0307-4043-0003287'        
        
   SELECT @Cid = Cid,         
--          @PrevAcc = RenAcc,        
          @DisbDate = DisbDate,        
          @Status = Status        
      FROM lnMaster WHERE Acc = @Acc        
        
   SELECT @SysDate = ebSysDate from OrgParms            
        
   IF NOT Exists (SELECT Acc FROM lnMaster where Acc = @Acc)        
   BEGIN        
      RAISERROR ('Cannot find Loan to Void...', 16, 1)        
      RETURN        
   END        
 ----Added by fritz to check cagabay  not allowing to void  
IF EXISTS (SELECT 1 FROM lnMaster WHERE Acc = @Acc AND DISBBY = 'CAGABAY')  
BEGIN  
    RAISERROR ('Cannot Void Release from CAGABAY ..', 16, 1)  
    RETURN  
END  
  
       
        
   IF Exists (SELECT Acc FROM trnMaster where Acc = @Acc and TrnType in (3001,3097,3098,3099,3899,3201,3202))        
   BEGIN        
      RAISERROR ('Cannot Void Loan with Existing Collection...', 16, 1)        
      RETURN        
   END        
        
    IF @Status in (30,91) and @SysDate <> @DisbDate        
    BEGIN        
       RAISERROR ('Cannot Void Loan: Disbursement Date is earlier than Transaction Date...', 16, 1)        
       RETURN        
    END        
          
    IF @Status IN (20) AND @SysDate =@DisbDate      
    BEGIN        
       RAISERROR ('Cannot Void Loan: WITH FOR APPROVAL STATUS...', 16, 1)        
       RETURN        
    END        
        
   SELECT @Paid      = Prin+IntR,        
          @BalPrin   = Prin,         
          @BalInt    = IntR,         
          @BalOth    = Oth,         
          @WaivedInt = ISNULL(WaivedInt,0)         
      FROM trnMaster        
      WHERE TRNTYPE = 3899 AND Acc = @PrevAcc        
           
-- Get the Net Proceeds of Loan Released and Staff name who released the Loan        
   SELECT @NetProceed = Max(TrnAmt),        
          @DisbBy     = Max(UserName)        
       FROM trnMaster where TrnType in (3100,3400) and Acc = @Acc           
        
   SET @NetProceed = IsNull(@NetProceed,0)        
                
   SELECT @dNum = dNum - CASE WHEN @BalPrin + @BalInt + @BalOth + @WaivedInt =         
                      i.ENDBal+i.ENDInt+i.EndOth+i.Prin+i.IntR+i.Oth THEN 1 else 0 END,        
          @BegBal = i.ENDBal+i.ENDInt+i.EndOth+i.Prin+i.IntR+i.Oth        
      FROM LoanInst i        
      WHERE @PrevAcc = Acc and @Paid Between         
            ENDBal+ENDInt+EndOth + .0001 and ENDBal+ENDInt+EndOth+Prin+IntR+Oth        
        
-- Delete Savings Retention        
   SELECT @Pledge = ChrAmnt  FROM lnChrgData  WHERE Acc = @Acc and chrgcode = 14         
   IF IsNull(@Pledge,0) > 0         
   BEGIN        
      SELECT @PlgAcc = Acc      FROM saMaster    WHERE CID = @CID and Type = 60        
        
      SELECT @PlgTrn = Max(Trn) FROM saTrnMaster WHERE Acc = @PlgAcc and TrnAmt = @Pledge         
                                               and TrnType = 3 and TrnDate = @DisbDate        
        
      DELETE SACOCIDATA  WHERE TrnDate = @DisbDate and Trn = @PlgTrn        
      UPDATE saTrnMaster SET TrnAmt = 0 WHERE TrnDate = @DisbDate and Trn = @PlgTrn        
      UPDATE saMaster            
          SET Balance = Balance - @Pledge,        
              PBBal   = PBBal - @Pledge        
          WHERE Acc = @PlgAcc        
      EXEC FixSavTran @PlgAcc        
   END        
        
   DECLARE Prev CURSOR KEYSET        
   FOR            
        
   SELECT RefAcc,ChrAmnt        
      FROM lnChrgData         
      WHERE Acc = @Acc         
           and ChrgCode = 18         
           and not RefAcc is null and ChrAmnt <> 0        
        
   OPEN Prev        
        
   FETCH NEXT FROM Prev INTO @PrevAcc, @PrevVal        
   WHILE (@@fetch_status <> -1)         
   BEGIN        
      IF (@@fetch_status <> -2)         
      BEGIN                 
        
         --DELETE FROM lnrenewal WHERE acc = @PrevAcc        
         UPDATE trnmaster SET Prin = 0, IntR = 0, Oth = 0, Penalty = 0, WaivedInt = 0, RefNo = 'Cancel Renewal'        
              WHERE Trntype = 3899         
                   and acc = @PrevAcc         
                   and TrnDate = @DisbDate        
         EXEC FixLoanTran @PrevAcc,0,1        
        
         SELECT @PlgAcc = Acc         
            FROM saTrnMaster        
            WHERE Particulars = 'Excess ' + @PrevAcc and TrnType = 3 and trnMnem_CD = 903        
        
-- select 'sadd',@PlgAcc, 'Excess ' + @PrevAcc        
        
        UPDATE saTrnMaster         
            SET TrnAmt = 0        
            WHERE Particulars = 'Excess ' + @PrevAcc and TrnType = 3 and trnMnem_CD = 903        
        Exec FixSavTran @PlgAcc         
        
      END        
      FETCH NEXT FROM Prev INTO @PrevAcc, @PrevVal        
   END        
   CLOSE Prev        
   DEALLOCATE Prev        
        
   DELETE lnChrgData  WHERE Acc = @Acc        
   UPDATE trnMaster SET Prin = 0, IntR = 0, Oth = 0, Penalty = 0, WaivedInt = 0, RefNo = 'Cancel Loan'        
          WHERE Acc = @Acc        
   DELETE cocidata    WHERE Acc = @Acc        
   DELETE COLLDATA    WHERE Acc = @Acc        
   DELETE Loaninst    WHERE Acc = @Acc        
        
   --DELETE FROM lnMaster   WHERE Acc = @Acc        
   UPDATE lnMaster         
         SET Status = 25,         
             DisbBy = Left(rTrim(DisbBy)+' xby '+@PostBy,15),        
             Prin   = Principal,        
             IntR   = Interest-Discounted,        
             Oth    = Others        
         WHERE Acc = @Acc --id Released        
        
    IF @NetProceed > 0 AND @Status = 30        
       UPDATE SAF         
          SET Cash_On_Hand = Cash_On_Hand + @NetProceed        
          WHERE TlrName = @DisbBy  
     ----  
---added by fritz to update status to cancel when voiding in f2  
      UPDATE loanapplication         
         SET Status = 3,         
            acc=null,  
            daterelease=null  
          WHERE Acc = @Acc         
         