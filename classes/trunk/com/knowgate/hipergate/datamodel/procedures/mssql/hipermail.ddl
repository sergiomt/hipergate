CREATE PROCEDURE k_sp_del_mime_msg @MimeMsgId CHAR(32) AS
  DECLARE @ParentId CHAR(32)

  SET @ParentId=NULL
  
  SELECT @ParentId=gu_parent_msg FROM k_mime_msgs WHERE gu_mimemsg=@MimeMsgId
  
  IF @ParentId IS NOT NULL EXECUTE k_sp_del_mime_msg @ParentId
    
  DELETE k_inet_addrs WHERE gu_mimemsg=@MimeMsgId
  DELETE k_mime_parts WHERE gu_mimemsg=@MimeMsgId
  DELETE k_mime_msgs  WHERE gu_mimemsg=@MimeMsgId
GO;

CREATE PROCEDURE k_sp_get_mime_msg @MsgId VARCHAR(254), @MimeMsgId CHAR(32) OUTPUT AS
  SET @MimeMsgId = NULL
  SELECT @MimeMsgId=gu_mimemsg FROM k_mime_msgs WHERE id_message=@MsgId
GO;

CREATE PROCEDURE k_sp_write_inet_addr @DomainId INTEGER, @WorkAreaId CHAR(32), @MsgGuid CHAR(32), @MimeMsgId VARCHAR(254), @RecipientTp VARCHAR(4), @EMailTx VARCHAR(100), @PersonalTx NVARCHAR(254) AS
  DECLARE @UserId CHAR(32)
  DECLARE @ContactId CHAR(32)
  DECLARE @CompanyId CHAR(32)
  DECLARE Users CURSOR LOCAL STATIC FOR SELECT gu_user FROM k_users WHERE id_domain = @DomainId AND (tx_main_email = @EMailTx OR EXISTS (SELECT a.gu_user FROM k_user_mail a WHERE a.gu_user=u.gu_user AND a.tx_main_email=@EMailTx))
  DECLARE Contacts CURSOR LOCAL STATIC FOR  SELECT gu_company,gu_contact FROM k_member_address WHERE gu_workarea = @WorkAreaId AND tx_email = @EMailTx

  OPEN Users
    FETCH NEXT FROM Users INTO @UserId
    IF @@FETCH_STATUS <> 0 SET @UserId=NULL    
  CLOSE Users
  DEALLOCATE Users

  OPEN Contacts 
    FETCH NEXT FROM Contacts INTO @CompanyId,@ContactId
    IF @@FETCH_STATUS <> 0
      BEGIN
        SET @ContactId=NULL    
        SET @CompanyId=NULL    
      END
  CLOSE Contacts
  DEALLOCATE Contacts

  INSERT INTO k_inet_addrs (gu_mimemsg,id_message,tx_email,tp_recipient,tx_personal,gu_user,gu_contact,gu_company)
                    VALUES (@MsgGuid,  @MimeMsgId,@EMailTx,@RecipientTp,@PersonalTx,@UserId,@ContactId,@CompanyId)
GO;

CREATE PROCEDURE k_sp_del_adhoc_mailing @AdHocId CHAR(32) AS
  UPDATE k_activities SET gu_mailing=NULL WHERE gu_mailing=@AdHocId
  DELETE k_x_adhoc_mailing_list WHERE gu_mailing=@AdHocId
  DELETE k_adhoc_mailings WHERE gu_mailing=@AdHocId
GO;
