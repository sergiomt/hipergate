INSERT INTO k_sequences VALUES ('seq_k_accounts', 10000, 1073741823, 1, 1)
GO;

CREATE PROCEDURE k_get_account_tp @IdUser CHAR(32), @TpAccount CHAR(1) OUTPUT AS
  SELECT @TpAccount=tp_account FROM k_users WHERE gu_user=@IdUser
GO;

CREATE PROCEDURE k_get_account_days_left @IdAccount CHAR(10), @DaysLeft INTEGER OUTPUT AS
  SELECT @DaysLeft=datediff(day,getdate(),dt_cancel) FROM k_accounts WHERE id_account=@IdAccount
GO;

CREATE PROCEDURE k_get_account_trial @IdAccount CHAR(10), @BoTrial SMALLINT OUTPUT AS
  SELECT @BoTrial=bo_trial FROM k_accounts WHERE id_account=@IdAccount
GO;

CREATE PROCEDURE k_check_account @IdAccount CHAR(10), @bo_active SMALLINT OUTPUT AS
  DECLARE @DtCancel DATETIME
  
  SET @bo_active=0
  
  SELECT @bo_active=bo_active,@DtCancel=dt_cancel FROM k_accounts WHERE id_account=@IdAccount
	   
  IF (1=@bo_active AND @DtCancel IS NOT NULL)
    BEGIN
      IF (DATEDIFF(day,GETDATE(),@DtCancel) < 0)
        BEGIN 
	  UPDATE k_accounts SET bo_active=0 WHERE id_account = @IdAccount
	  SET @bo_active = 0	  
	END
      END
GO;