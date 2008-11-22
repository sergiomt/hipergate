CREATE SEQUENCE seq_k_accounts INCREMENT 1 START 10000
GO;

CREATE FUNCTION k_get_account_tp (CHAR) RETURNS CHAR AS '
DECLARE
  TpAccount CHAR(1);
BEGIN
  SELECT tp_account INTO TpAccount FROM k_users WHERE gu_user=$1;
  RETURN TpAccount;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_get_account_days_left (CHAR) RETURNS INTERVAL AS '
DECLARE
  DaysLeft INTERVAL;
BEGIN
  SELECT extract(DAY FROM age(dt_cancel)) INTO DaysLeft FROM k_accounts WHERE id_account=$1;
  RETURN DaysLeft;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_get_account_trial (CHAR) RETURNS SMALLINT AS '
DECLARE
  BoTrial SMALLINT;
BEGIN
  SELECT bo_trial INTO BoTrial FROM k_accounts WHERE id_account=$1;
  RETURN BoTrial;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_check_account (CHAR) RETURNS SMALLINT AS '
DECLARE
  DtCancel TIMESTAMP;
  BoActive SMALLINT;
BEGIN  
  BoActive:=0;
  
  SELECT bo_active,dt_cancel INTO BoActive,DtCancel FROM k_accounts WHERE id_account=$1;
	   
  IF FOUND AND DtCancel IS NOT NULL THEN
    IF age(DtCancel) < 0 THEN
      UPDATE k_accounts SET bo_active=0 WHERE id_account = $1;
      BoActive := 0;
    END IF;
  END IF;
  
  RETURN BoActive;
END;
' LANGUAGE 'plpgsql';
GO;
