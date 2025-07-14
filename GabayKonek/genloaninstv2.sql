                 
CREATE  Function GenLoaninstv2                
 (@pAcc as VarChar(22),                 
 @pPrincipal as money,                 
 @pInterest as money,                
 @pTerms as integer,                      
 @pEffrate as float,                
 @pDateRel as datetime            
 )                
                 
                
Returns @Amort Table                 
       ([DNUM] [smallint],                
 [ACC] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,                
 [DUEDATE] [smalldatetime],                
 [INSTFLAG] [smallint],                
 [PRIN] [numeric],                
 [INTR] [numeric],                
 [Oth] [numeric],                
 [PENALTY] [numeric],                
 [ENDBAL] [numeric],                
 [ENDINT] [numeric],                
 [EndOth] [numeric],                
 [INSTPD] [numeric],                
 [PenPD] [numeric],                
 [CarVal] [numeric],                
 [UpInt] [numeric],                
 [ServFee] [numeric],              
 PledgeAmort [numeric] ,    
 amort_oth [numeric],    
 bal_oth [numeric]    
 )                
                
as                 
Begin                
 DECLARE @vSTOP AS INTEGER                
 Declare @vAmort as Money                
 DECLARE @vBegPrin  AS Money                
 DECLARE @vBegInt  AS Money                
 DECLARE @vPrin    AS Money                
 DECLARE @vIntR    AS Money                
 DECLARE @vdNum    AS Int                
 DECLARE @vDate    AS DateTime                
 DECLARE @vsAcc    AS VarChar(22)                
 DECLARE @vEndPrin  AS Money                
 DECLARE @vEndInt  AS Money                
 DECLARE @vFlag    AS Int                
 DECLARE @pAnnumDiv as SmallInt = 0            
 DECLARE @pPerWeek as Bit = 0            
 DECLARE @pStart as DateTime = 0            
                
                
SET @vBEGPRIN = @pPRINCIPAL                
SET @vBEGINT = @pInterest                
SET @vAmort = (@pPrincipal + @pInterest) / @pTerms                 
                
if ceiling(@vAmort/5) > @vAmort/5 SET @vAmort = (ceiling(@vAmort/5)-1)*5 + 5                
                
SET @vSTOP = 1                
Set @vdate = @pdaterel                
WHILE @vSTOP <= @pTERMS                
   BEGIN                
 Set @vBegPrin = @vBegPrin                
 Set @vBegInt = @vBegInt                
        if @pEffrate > 0.0                
            begin                
        Set @vIntr = round((@vBegPrin * @pEffrate) / @pTerms,0)                
            end                
         else                
             Begin                
                Set @vIntr = round(@pInterest / @pTerms,2)                
             end                
        set @vPrin = @vAmort - @vIntr                
        Set @vEndPrin = @vBegPrin - @vPrin                
 Set @vEndInt = @vBegInt - @vIntr                
        IF @pStart <> 0 and @vStop = 1                
        BEGIN                
            SET @vDate = @pStart                
        END ELSE                   
            SET @vDate =  dbo.NextDue(@vDate,@pAnnumDiv,@pPerWeek)                
        if  @vStop = @pTERMS                
          Begin                
            set @vprin = @vbegprin                 
            Set @vIntr = @vbegInt                
     Set @vEndPrin = @vBegPrin - @vPrin                
            Set @vEndInt = @vBegInt - @vIntr                
          End                
        Insert into @Amort Values                 
                       (@vStop,                 
   @pACC,                
   @vDate,                
   0,                
   @vPrin,                
   @vIntr,                
   0,                
   0,                
   @vEndPrin,                
   @vEndint,                
   0,                
   0,                
   0,                
   0,                
   0,                
   0,              
   0 ,    
   0,    
   0    
   )                
        Set @vBegPrin = @vBegPrin - @vPrin                
 Set @vBegInt = @vBegInt - @vIntr             
 set @vStop = @vStop + 1                 
        continue                
   end                
                
Return                
end 