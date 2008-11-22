CREATE PROCEDURE k_get_domain_id (NmDomain VARCHAR(30), OUT IdDomain INT)
BEGIN
  SET IdDomain=0;
  SELECT id_domain INTO IdDomain FROM k_domains WHERE nm_domain=NmDomain;
END
GO;

CREATE PROCEDURE k_get_workarea_id (IdDomain INT, NmWorkArea VARCHAR(50), OUT IdWorkArea CHAR(32))
BEGIN
  SET IdWorkArea=NULL;
  SELECT gu_workarea INTO IdWorkArea FROM k_workareas WHERE nm_workarea=NmWorkArea AND id_domain=IdDomain AND bo_active<>0;
END
GO;

CREATE PROCEDURE k_is_workarea_anyrole (IdWorkArea CHAR(32), IdUser CHAR(32), OUT IsAny INT)
BEGIN
  DECLARE IdGroup CHAR(32);
  SET IdGroup=NULL;
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE (x.gu_acl_group=w.gu_admins OR x.gu_acl_group=w.gu_powusers OR x.gu_acl_group=w.gu_users OR x.gu_acl_group=w.gu_guests OR x.gu_acl_group=w.gu_other) AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea LIMIT 0, 1;
  IF IdGroup IS NULL THEN
    SET IsAny=0;
  ELSE
    SET IsAny=1;
  END IF;
END
GO;

CREATE PROCEDURE k_is_workarea_admin (IdWorkArea CHAR(32), IdUser CHAR(32), OUT IsAdmin INT)
BEGIN
  DECLARE IdGroup CHAR(32);
  SET IdGroup=NULL;
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_admins AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea LIMIT 0, 1;
  IF IdGroup IS NULL THEN
    SET IsAdmin=0;
  ELSE
    SET IsAdmin=1;
  END IF;
END
GO;

CREATE PROCEDURE k_is_workarea_poweruser (IdWorkArea CHAR(32), IdPowUser CHAR(32), OUT IsPowUser INT)
BEGIN
  DECLARE IdGroup CHAR(32);
  SET IdGroup=NULL;
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_powusers AND x.gu_user=IdPowUser AND w.gu_workarea=IdWorkArea LIMIT 0, 1;
  IF IdGroup IS NULL THEN
    SET IsPowUser=0;
  ELSE
    SET IsPowUser=1;
  END IF;
END
GO;

CREATE PROCEDURE k_is_workarea_user (IdWorkArea CHAR(32), IdUser CHAR(32), OUT IsUser INT)
BEGIN
  DECLARE IdGroup CHAR(32);
  SET IdGroup=NULL;
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_users AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea LIMIT 0, 1;
  IF IdGroup IS NULL THEN
    SET IsUser=0;
  ELSE
    SET IsUser=1;
  END IF;
END
GO;

CREATE PROCEDURE k_is_workarea_guest (IdWorkArea CHAR(32), IdUser CHAR(32), OUT IsGuest INT)
BEGIN
  DECLARE IdGroup CHAR(32);
  SET IdGroup=NULL;
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_guests AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea LIMIT 0, 1;
  IF IdGroup IS NULL THEN
    SET IsGuest=0;
  ELSE
    SET IsGuest=1;
  END IF;
END
GO;

CREATE PROCEDURE k_get_user_from_email (TxMainEmail VARCHAR(100), OUT IdUser CHAR(32))
BEGIN
  SET IdUser=NULL;
  SELECT gu_user INTO IdUser FROM k_users WHERE tx_main_email=TxMainEmail LIMIT 1;
END
GO;

CREATE PROCEDURE k_get_user_from_nick (IdDomain INT, TxNick VARCHAR(32), OUT IdUser CHAR(32))
BEGIN
  SET IdUser=NULL;
  SELECT gu_user INTO IdUser FROM k_users WHERE id_domain=IdDomain AND tx_nickname=TxNick LIMIT 1;
END
GO;

CREATE PROCEDURE k_get_group_id (IdDomain INT, NmGroup VARCHAR(32), OUT IdGroup CHAR(32))
BEGIN
  SET IdGroup=NULL;
  SELECT gu_acl_group INTO IdGroup FROM k_acl_groups WHERE id_domain=IdDomain AND nm_acl_group=NmGroup LIMIT 1;
END
GO;

CREATE PROCEDURE k_sp_autenticate (IdUser CHAR(32), PwdText VARCHAR(50), OUT CoStatus SMALLINT)
BEGIN
  DECLARE Password VARCHAR(50);
  DECLARE Activated SMALLINT;
  DECLARE DtCancel TIMESTAMP;
  DECLARE DtExpire TIMESTAMP;

  SET Activated=NULL;
  SET CoStatus=1;

  SELECT tx_pwd,bo_active,dt_cancel,dt_pwd_expires INTO Password,Activated,DtCancel,DtExpire FROM k_users WHERE gu_user=IdUser;

  IF Activated IS NULL THEN
    SET CoStatus=-1;
  ELSE
    SET CoStatus=1;
    IF Password<>PwdText AND Password<>'(not set yet, change on next logon)' THEN
      SET CoStatus=-2;
    ELSE
      IF Activated=0 THEN
        SET CoStatus=-3;
      END IF;
      IF NOW()>DtCancel THEN
	SET CoStatus=-8;
      END IF;
      IF NOW()>DtExpire THEN
        SET CoStatus=-9;
      END IF;
    END IF;
  END IF;
END
GO;
