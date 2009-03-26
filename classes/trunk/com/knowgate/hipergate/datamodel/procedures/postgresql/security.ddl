CREATE FUNCTION k_sp_autenticate (CHAR, VARCHAR) RETURNS SMALLINT AS '

DECLARE
    Password  VARCHAR;
    DtCancel  TIMESTAMP;
    DtExpire  TIMESTAMP;
    Activated SMALLINT := NULL;
    CoStatus  SMALLINT := 1;

BEGIN
  SELECT tx_pwd,bo_active,dt_cancel,dt_pwd_expires INTO Password,Activated,DtCancel,DtExpire FROM k_users WHERE gu_user=$1;

  IF Activated IS NULL THEN

    CoStatus := -1;

  ELSE

    IF Password<>$2 AND Password<>''(not set yet, change on next logon)'' THEN

      CoStatus := -2;

    ELSE

      IF Activated=0 THEN
        CoStatus := -3;
      END IF;

      IF age(DtCancel)<INTERVAL ''0 secs'' THEN
        CoStatus := -8;
      END IF;

      IF age(DtExpire)<INTERVAL ''0 secs'' THEN
        CoStatus := -9;
      END IF;

    END IF;

  END IF;

  RETURN CoStatus;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE SEQUENCE seq_k_webbeacons INCREMENT 1 START 1
GO;

