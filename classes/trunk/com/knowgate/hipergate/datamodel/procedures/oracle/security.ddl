CREATE OR REPLACE PROCEDURE k_get_domain_id (NmDomain VARCHAR2, IdDomain OUT NUMBER) IS
BEGIN
  SELECT id_domain INTO IdDomain FROM k_domains WHERE nm_domain=NmDomain;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdDomain:=0;
END k_get_domain_id;
GO;

CREATE OR REPLACE PROCEDURE k_get_workarea_id (IdDomain NUMBER, NmWorkArea VARCHAR2, IdWorkArea OUT CHAR) IS
BEGIN
  SELECT gu_workarea INTO IdWorkArea FROM k_workareas WHERE nm_workarea=NmWorkArea AND id_domain=IdDomain AND bo_active<>0;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdWorkArea:=NULL;
END k_get_workarea_id;
GO;

CREATE OR REPLACE PROCEDURE k_is_workarea_anyrole (IdWorkArea CHAR, IdUser CHAR, IsAny OUT NUMBER) IS
  IdGroup CHAR(32);
BEGIN
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE (x.gu_acl_group=w.gu_admins OR x.gu_acl_group=w.gu_powusers OR x.gu_acl_group=w.gu_users OR x.gu_acl_group=w.gu_guests OR x.gu_acl_group=w.gu_other) AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea AND ROWNUM=1;
  IsAny:=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IsAny:=0;
END k_is_workarea_anyrole;
GO;

CREATE OR REPLACE PROCEDURE k_is_workarea_admin (IdWorkArea CHAR, IdUser CHAR, IsAdmin OUT NUMBER) IS
  IdGroup CHAR(32);
BEGIN
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_admins AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea AND ROWNUM=1;
  IsAdmin:=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IsAdmin:=0;
END k_is_workarea_admin;
GO;

CREATE PROCEDURE k_is_workarea_poweruser (IdWorkArea CHAR, IdPowUser CHAR, IsPowUser OUT NUMBER) IS
  IdGroup CHAR(32);
BEGIN
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_powusers AND x.gu_user=IdPowUser AND w.gu_workarea=IdWorkArea AND ROWNUM=1;
  IsPowUser:=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IsPowUser:=0;
END k_is_workarea_poweruser;
GO;

CREATE PROCEDURE k_is_workarea_user (IdWorkArea CHAR, IdUser CHAR, IsUser OUT NUMBER) IS
  IdGroup CHAR(32);
BEGIN
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_users AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea AND ROWNUM=1;
  IsUser:=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IsUser:=0;
END k_is_workarea_user;
GO;

CREATE PROCEDURE k_is_workarea_guest (IdWorkArea CHAR, IdUser CHAR, IsGuest OUT NUMBER) IS
  IdGroup CHAR(32);
BEGIN
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_guests AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea AND ROWNUM=1;
  IsGuest:=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IsGuest:=0;
END k_is_workarea_guest;
GO;

CREATE OR REPLACE PROCEDURE k_get_user_from_email (TxMainEmail VARCHAR2, IdUser OUT CHAR) IS
BEGIN
  SELECT gu_user INTO IdUser FROM k_users WHERE tx_main_email=TxMainEmail;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdUser:=NULL;
END k_get_user_from_email;
GO;

CREATE OR REPLACE PROCEDURE k_get_user_from_nick (IdDomain NUMBER, TxNick VARCHAR2, IdUser OUT CHAR) IS
BEGIN
  SELECT gu_user INTO IdUser FROM k_users WHERE id_domain=IdDomain AND tx_nickname=TxNick;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdUser:=NULL;
END k_get_user_from_nick;
GO;

CREATE OR REPLACE PROCEDURE k_get_group_id (IdDomain NUMBER, NmGroup VARCHAR2, IdGroup OUT CHAR) IS
BEGIN
  SELECT gu_acl_group INTO IdGroup FROM k_acl_groups WHERE id_domain=IdDomain AND nm_acl_group=NmGroup;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdGroup:=NULL;
END k_get_group_id;
GO;

CREATE OR REPLACE PROCEDURE k_sp_autenticate (IdUser CHAR, PwdText VARCHAR2, CoStatus OUT NUMBER) IS
  Password VARCHAR2(50);
  Activated NUMBER(6);
  DtCancel DATE;
  DtExpire DATE;
BEGIN

  CoStatus :=1;

  SELECT tx_pwd,bo_active,dt_cancel,dt_pwd_expires INTO Password,Activated,DtCancel,DtExpire FROM k_users WHERE gu_user=IdUser;

    IF Password<>PwdText AND Password<>'(not set yet, change on next logon)' THEN
      CoStatus:=-2;
    ELSE
      IF Activated=0 THEN
        CoStatus:=-3;
      END IF;

      IF SYSDATE>DtCancel THEN
	CoStatus:=-8;
      END IF;

      IF SYSDATE>DtExpire THEN
        CoStatus:=-9;
      END IF;
    END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    CoStatus:=-1;
END k_sp_autenticate;
GO;

CREATE SEQUENCE seq_k_webbeacons INCREMENT BY 1 START WITH 1
GO;
