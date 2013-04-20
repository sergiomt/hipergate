CREATE PROCEDURE k_sp_del_mime_msg (MimeMsgId CHAR(32))
BEGIN
  DECLARE ParentId CHAR(32) DEFAULT NULL;
  SELECT gu_parent_msg INTO ParentId FROM k_mime_msgs WHERE gu_mimemsg=MimeMsgId;
  IF ParentId IS NOT NULL THEN
    CALL k_sp_del_mime_msg (ParentId);
  END IF;
  DELETE FROM k_inet_addrs WHERE gu_mimemsg=MimeMsgId;
  DELETE FROM k_mime_parts WHERE gu_mimemsg=MimeMsgId;
  DELETE FROM k_mime_msgs  WHERE gu_mimemsg=MimeMsgId;
END
GO;

CREATE PROCEDURE k_sp_get_mime_msg (MsgId VARCHAR(254), OUT MimeMsgId CHAR(32))
BEGIN
  SET MimeMsgId=NULL;
  SELECT gu_mimemsg INTO MimeMsgId FROM k_mime_msgs WHERE id_message=MsgId;
END
GO;

CREATE PROCEDURE k_sp_write_inet_addr (DomainId INTEGER, WorkAreaId CHAR(32), MsgGuid CHAR(32), MimeMsgId VARCHAR(254), RecipientTp VARCHAR(4), EMailTx VARCHAR(254), PersonalTx VARCHAR(254))
BEGIN
  DECLARE UserId CHAR(32);
  DECLARE ContactId CHAR(32);
  DECLARE CompanyId CHAR(32);
  DECLARE Done INT DEFAULT 0;
  DECLARE Users CURSOR FOR SELECT gu_user FROM k_users u WHERE u.id_domain = DomainId AND (u.tx_main_email = EMailTx OR EXISTS (SELECT a.gu_user FROM k_user_mail a WHERE a.gu_user=u.gu_user AND a.tx_main_email=EMailTx));
  DECLARE Contacts CURSOR FOR SELECT gu_company,gu_contact FROM k_member_address WHERE gu_workarea = WorkAreaId AND tx_email = EMailTx;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  OPEN Users;
    FETCH Users INTO UserId;
    IF Done=1 THEN
      SET UserId=NULL;
    END IF;
  CLOSE Users;
  SET Done=0;
  OPEN Contacts;
    FETCH Contacts INTO CompanyId,ContactId;
    IF Done=1 THEN
      SET CompanyId=NULL;
      SET ContactId=NULL;
    END IF;
  CLOSE Contacts;
  INSERT INTO k_inet_addrs (gu_mimemsg,id_message,tx_email,tp_recipient,tx_personal,gu_user,gu_contact,gu_company) VALUES (MsgGuid,MimeMsgId,EMailTx,RecipientTp,PersonalTx,UserId,ContactId,CompanyId);
END
GO;

CREATE PROCEDURE k_sp_del_adhoc_mailing (AdHocId CHAR(32))
BEGIN
  UPDATE k_activities SET gu_mailing=NULL WHERE gu_mailing=AdHocId;
  DELETE FROM k_x_adhoc_mailing_list WHERE gu_mailing=AdHocId;
  DELETE FROM k_adhoc_mailings WHERE gu_mailing=AdHocId;
END
GO;
