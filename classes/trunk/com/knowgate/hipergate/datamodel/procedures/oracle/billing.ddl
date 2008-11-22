 CREATE PROCEDURE k_get_account_tp (IdUser CHAR, TpAccount OUT CHAR) IS
  BEGIN
   SELECT tp_account INTO TpAccount FROM k_users WHERE gu_user=IdUser;
  END k_get_account_tp;
  GO;

CREATE SEQUENCE seq_k_accounts INCREMENT BY 1 START WITH 10000
GO;

 CREATE PROCEDURE k_get_account_days_left (IdAccount CHAR, DaysLeft OUT NUMBER) IS
 BEGIN
   SELECT SYSDATE - dt_cancel INTO DaysLeft FROM k_accounts WHERE id_account=IdAccount;
 END k_get_account_days_left;
 GO;

CREATE PROCEDURE k_get_account_trial (IdAccount CHAR, BoTrial OUT NUMBER) IS
BEGIN
  SELECT bo_trial INTO BoTrial FROM k_accounts WHERE id_account=IdAccount;
END k_get_account_trial;
GO;

CREATE PROCEDURE k_check_account (IdAccount CHAR, BoActive OUT NUMBER) IS
  DtCancel DATE;
BEGIN

  SELECT bo_active,dt_cancel INTO BoActive,DtCancel FROM k_accounts WHERE id_account=IdAccount;

  IF 1=BoActive AND DtCancel IS NOT NULL THEN
    IF SYSDATE - DtCancel < 0 THEN
      UPDATE k_accounts SET bo_active=0 WHERE id_account = IdAccount;
      BoActive := 0;
    END IF;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    BoActive:=0;
END k_check_account;
GO;