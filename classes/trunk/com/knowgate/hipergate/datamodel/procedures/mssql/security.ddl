CREATE PROCEDURE k_get_domain_id @NmDomain VARCHAR(30), @IdDomain INTEGER OUTPUT AS
  SET @IdDomain=0
  SELECT @IdDomain=id_domain FROM k_domains WITH (NOLOCK) WHERE nm_domain=@NmDomain OPTION (FAST 1)
GO;

CREATE PROCEDURE k_get_workarea_id @IdDomain INTEGER, @NmWorkArea VARCHAR(50), @IdWorkArea CHAR(32) OUTPUT AS
  SET @IdWorkArea=NULL
  SELECT @IdWorkArea=gu_workarea FROM k_workareas WITH (NOLOCK) WHERE nm_workarea=@NmWorkArea AND id_domain=@IdDomain AND bo_active<>0 OPTION (FAST 1)
GO;

CREATE PROCEDURE k_is_workarea_anyrole @IdWorkArea CHAR(32), @IdUser CHAR(32), @IsAny INTEGER OUTPUT AS
  DECLARE @IdGroup CHAR(32)

  SET @IdGroup=NULL
  SELECT TOP 1 @IdGroup=x.gu_acl_group FROM k_x_group_user x, k_x_app_workarea w WHERE (x.gu_acl_group=w.gu_admins OR x.gu_acl_group=w.gu_powusers OR x.gu_acl_group=w.gu_users OR x.gu_acl_group=w.gu_guests OR x.gu_acl_group=w.gu_other) AND x.gu_user=@IdUser AND w.gu_workarea=@IdWorkArea
  IF @IdGroup IS NULL
    SET @IsAny=0
  ELSE
    SET @IsAny=1
GO;

CREATE PROCEDURE k_is_workarea_admin @IdWorkArea CHAR(32), @IdUser CHAR(32), @IsAdmin INTEGER OUTPUT AS
  DECLARE @IdGroup CHAR(32)

  SET @IdGroup=NULL
  SELECT TOP 1 @IdGroup=x.gu_acl_group FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_admins AND x.gu_user=@IdUser AND w.gu_workarea=@IdWorkArea
  IF @IdGroup IS NULL
    SET @IsAdmin=0
  ELSE
    SET @IsAdmin=1
GO;

CREATE PROCEDURE k_is_workarea_poweruser @IdWorkArea CHAR(32), @IdPowUser CHAR(32), @IsPowUser INTEGER OUTPUT AS
  DECLARE @IdGroup CHAR(32)

  SET @IdGroup=NULL
  SELECT TOP 1 @IdGroup=x.gu_acl_group FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_powusers AND x.gu_user=@IdPowUser AND w.gu_workarea=@IdWorkArea
  IF @IdGroup IS NULL
    SET @IsPowUser=0
  ELSE
    SET @IsPowUser=1
GO;

CREATE PROCEDURE k_is_workarea_user @IdWorkArea CHAR(32), @IdUser CHAR(32), @IsUser INTEGER OUTPUT AS
  DECLARE @IdGroup CHAR(32)

  SET @IdGroup=NULL
  SELECT TOP 1 @IdGroup=x.gu_acl_group FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_users AND x.gu_user=@IdUser AND w.gu_workarea=@IdWorkArea
  IF @IdGroup IS NULL
    SET @IsUser=0
  ELSE
    SET @IsUser=1
GO;

CREATE PROCEDURE k_is_workarea_guest @IdWorkArea CHAR(32), @IdUser CHAR(32), @IsGuest INTEGER OUTPUT AS
  DECLARE @IdGroup CHAR(32)

  SET @IdGroup=NULL
  SELECT TOP 1 @IdGroup=x.gu_acl_group FROM k_x_group_user x, k_x_app_workarea w WHERE x.gu_acl_group=w.gu_guests AND x.gu_user=@IdUser AND w.gu_workarea=@IdWorkArea
  IF @IdGroup IS NULL
    SET @IsGuest=0
  ELSE
    SET @IsGuest=1
GO;

CREATE PROCEDURE k_get_user_from_email @TxMainEmail VARCHAR(100), @IdUser CHAR(32) OUTPUT AS
  SET @IdUser=NULL
  SELECT @IdUser=gu_user FROM k_users WITH (NOLOCK) WHERE tx_main_email=@TxMainEmail OPTION (FAST 1)
GO;

CREATE PROCEDURE k_get_user_from_nick @IdDomain INTEGER, @TxNick VARCHAR(32), @IdUser CHAR(32) OUTPUT AS
  SET @IdUser=NULL
  SELECT TOP 1 @IdUser=gu_user FROM k_users WITH (NOLOCK) WHERE id_domain=@IdDomain AND tx_nickname=@TxNick OPTION (FAST 1)
GO;

CREATE PROCEDURE k_get_group_id @IdDomain INTEGER, @NmGroup VARCHAR(30), @IdGroup CHAR(32) OUTPUT AS
  SELECT TOP 1 @IdGroup=gu_acl_group FROM k_acl_groups WITH (NOLOCK) WHERE id_domain=@IdDomain AND nm_acl_group=@NmGroup
GO;

CREATE PROCEDURE k_sp_autenticate @IdUser CHAR(32), @PwdText VARCHAR(50), @CoStatus SMALLINT OUTPUT AS
  DECLARE @Password VARCHAR(50)
  DECLARE @Activated SMALLINT
  DECLARE @DtCancel DATETIME
  DECLARE @DtExpire DATETIME

  SET @Activated=NULL
  SET @CoStatus=1

  SELECT @Password=tx_pwd,@Activated=bo_active,@DtCancel=dt_cancel,@DtExpire=dt_pwd_expires FROM k_users WITH (NOLOCK) WHERE gu_user=@IdUser OPTION (FAST 1)

  IF (@Activated IS NULL)
    SET @CoStatus=-1
  ELSE
    BEGIN
      IF (@Password<>@PwdText AND @Password<>'(not set yet, change on next logon)')
        SET @CoStatus=-2
      ELSE
        BEGIN
	        IF @Activated=0
	          SET @CoStatus=-3
	        IF GETDATE()>@DtCancel
	          SET @CoStatus=-8
	        IF GETDATE()>@DtExpire
	          SET @CoStatus=-9
        END
    END
GO;
