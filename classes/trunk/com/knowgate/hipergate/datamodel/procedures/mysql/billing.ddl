CREATE PROCEDURE k_get_account_tp (IdUser CHAR(32), OUT TpAccount CHAR(1))
BEGIN
  SELECT tp_account INTO TpAccount FROM k_users WHERE gu_user=IdUser;
END
GO;

INSERT INTO k_sequences VALUES ('seq_k_accounts', 10000, 1073741823, 1, 1)
GO;

CREATE PROCEDURE k_get_account_days_left (IdAccount CHAR(32), OUT DaysLeft INT)
BEGIN
  SELECT DATEDIFF(NOW(),dt_cancel) INTO DaysLeft FROM k_accounts WHERE id_account=IdAccount;
END
GO;

CREATE PROCEDURE k_get_account_trial (IdAccount CHAR(32), OUT BoTrial SMALLINT)
BEGIN
  SELECT bo_trial INTO BoTrial FROM k_accounts WHERE id_account=IdAccount;
END
GO;

CREATE PROCEDURE k_check_account (IdAccount CHAR(32), OUT BoActive SMALLINT)
BEGIN
  DECLARE DtCancel TIMESTAMP;

  SELECT bo_active,dt_cancel INTO BoActive,DtCancel FROM k_accounts WHERE id_account=IdAccount;
  IF BoActive IS NULL THEN
    SET BoActive = 0;
  ELSE 
    IF 1=BoActive AND DtCancel IS NOT NULL THEN
      IF DATEDIFF(NOW(),DtCancel) < 0 THEN
        UPDATE k_accounts SET bo_active=0 WHERE id_account = IdAccount;
        SET BoActive = 0;
      END IF;
    END IF;
  END IF;
END
GO;