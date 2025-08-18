	
	--deletion
    truncate table Modified;
    drop table Modified;
	delete from DataAudit where trndate <='2020-12-31';
	delete from Client_UpdateLogs where date_encoded <='2020-12-31';

	delete from tAcc;
	delete from tLN_PROFESSION;
	delete from tCENTER;
	delete from tCustAddInfo;
	delete from tCustomer;
	delete from tCID;
	delete from tAddresses;
	delete from tsaMaster;
	delete from tsaTrnMaster;
	delete from tlnMaster;
	delete from tTrnMaster;
	delete from tlnChrgData;
	delete from tCenter;
	delete from tACCTPARMS;
	delete from tLoanInst;

	--drop triggers
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Area')
    DROP TRIGGER trgModCtr_Area;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Area_Del')
    DROP TRIGGER trgModCtr_Area_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Managers')
    DROP TRIGGER trgModCtr_Managers;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Managers_Del')
    DROP TRIGGER trgModCtr_Managers_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Center')
    DROP TRIGGER trgModCtr_Center;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Center_Del')
    DROP TRIGGER trgModCtr_Center_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Customer')
    DROP TRIGGER trgModCtr_Customer;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Customer_Del')
    DROP TRIGGER trgModCtr_Customer_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Addresses')
    DROP TRIGGER trgModCtr_Addresses;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Addresses_Del')
    DROP TRIGGER trgModCtr_Addresses_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_lnMaster')
    DROP TRIGGER trgModCtr_lnMaster;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_lnMaster_Del')
    DROP TRIGGER trgModCtr_lnMaster_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_saMaster')
    DROP TRIGGER trgModCtr_saMaster;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_saMaster_Del')
    DROP TRIGGER trgModCtr_saMaster_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_trnMaster')
    DROP TRIGGER trgModCtr_trnMaster;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_trnMaster_Del')
    DROP TRIGGER trgModCtr_trnMaster_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_satrnMaster')
    DROP TRIGGER trgModCtr_satrnMaster;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_satrnMaster_Del')
    DROP TRIGGER trgModCtr_satrnMaster_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_LoanInst')
    DROP TRIGGER trgModCtr_LoanInst;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_LoanInst_Del')
    DROP TRIGGER trgModCtr_LoanInst_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_lnChrgData')
    DROP TRIGGER trgModCtr_lnChrgData;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_lnChrgData_Del')
    DROP TRIGGER trgModCtr_lnChrgData_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfoList')
    DROP TRIGGER trgModCtr_CustAddInfoList;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfoList_Del')
    DROP TRIGGER trgModCtr_CustAddInfoList_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfoGroup')
    DROP TRIGGER trgModCtr_CustAddInfoGroup;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfoGroup_Del')
    DROP TRIGGER trgModCtr_CustAddInfoGroup_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfoGroupNeed')
    DROP TRIGGER trgModCtr_CustAddInfoGroupNeed;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfoGroupNeed_Del')
    DROP TRIGGER trgModCtr_CustAddInfoGroupNeed_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfo')
    DROP TRIGGER trgModCtr_CustAddInfo;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_CustAddInfo_Del')
    DROP TRIGGER trgModCtr_CustAddInfo_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Mutual_Fund')
    DROP TRIGGER trgModCtr_Mutual_Fund;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Mutual_Fund_Del')
    DROP TRIGGER trgModCtr_Mutual_Fund_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_ReferencesDetails')
    DROP TRIGGER trgModCtr_ReferencesDetails;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_ReferencesDetails_Del')
    DROP TRIGGER trgModCtr_ReferencesDetails_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Center_Worker')
    DROP TRIGGER trgModCtr_Center_Worker;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Center_Worker_Del')
    DROP TRIGGER trgModCtr_Center_Worker_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Writeoff')
    DROP TRIGGER trgModCtr_Writeoff;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Writeoff_Del')
    DROP TRIGGER trgModCtr_Writeoff_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Accounts')
    DROP TRIGGER trgModCtr_Accounts;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Accounts_Del')
    DROP TRIGGER trgModCtr_Accounts_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_jnlHeaders')
    DROP TRIGGER trgModCtr_jnlHeaders;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_jnlHeaders_Del')
    DROP TRIGGER trgModCtr_jnlHeaders_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_jnlDetails')
    DROP TRIGGER trgModCtr_jnlDetails;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_jnlDetails_Del')
    DROP TRIGGER trgModCtr_jnlDetails_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Ledger_Details')
    DROP TRIGGER trgModCtr_Ledger_Details;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_Ledger_Details_Del')
    DROP TRIGGER trgModCtr_Ledger_Details_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_MultiplePaymentReceipt')
    DROP TRIGGER trgModCtr_MultiplePaymentReceipt;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_MultiplePaymentReceipt_Del')
    DROP TRIGGER trgModCtr_MultiplePaymentReceipt_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_UsersList')
    DROP TRIGGER trgModCtr_UsersList;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_UsersList_Del')
    DROP TRIGGER trgModCtr_UsersList_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_InactiveCID')
    DROP TRIGGER trgModCtr_InactiveCID;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_InactiveCID_Del')
    DROP TRIGGER trgModCtr_InactiveCID_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_ReactivateWriteoff')
    DROP TRIGGER trgModCtr_ReactivateWriteoff;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_ReactivateWriteoff_Del')
    DROP TRIGGER trgModCtr_ReactivateWriteoff_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_LnBeneficiary')
    DROP TRIGGER trgModCtr_LnBeneficiary;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_LnBeneficiary_Del')
    DROP TRIGGER trgModCtr_LnBeneficiary_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_LoanApplication')
    DROP TRIGGER trgModCtr_LoanApplication;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'trgModCtr_LoanApplication_Del')
    DROP TRIGGER trgModCtr_LoanApplication_Del;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE Name = 'StopDelta')
    DROP TRIGGER StopDelta;
GO

--alter check version
ALTER  PROCEDURE [dbo].[Usp_CheckVersion] (@eSystemVer as VarChar(100)) 
AS
DECLARE @Msg AS VarChar(100);

IF pwdCompare(CAST(@eSystemVer AS VarBinary(100)), (SELECT eSystemVer FROM orgparms)) <> 1
BEGIN
 SET @Msg = 'Access Denied! This version is not compatible with the current Database. Contact your administrator.';
 RAISERROR (@Msg, 16, 1);
 RETURN 1;
END


--reconfigure 
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;


