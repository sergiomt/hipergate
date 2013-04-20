CREATE SEQUENCE seq_k_adhoc_mailings INCREMENT BY 1 START WITH 1
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_mime_msg (MimeMsgId CHAR) IS
ParentId CHAR(32);
BEGIN
  SELECT gu_parent_msg INTO ParentId FROM k_mime_msgs WHERE gu_mimemsg=MimeMsgId;

  IF ParentId IS NOT NULL THEN
    k_sp_del_mime_msg (ParentId);
  END IF;
  
  DELETE k_inet_addrs WHERE gu_mimemsg=MimeMsgId;
  DELETE k_mime_parts WHERE gu_mimemsg=MimeMsgId;
  DELETE k_mime_msgs  WHERE gu_mimemsg=MimeMsgId;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  ParentId :=NULL;
  END k_sp_del_mime_msg;
GO;

CREATE OR REPLACE PROCEDURE k_sp_get_mime_msg (MsgId VARCHAR2, MimeMsgId OUT CHAR) IS
BEGIN
  SELECT gu_mimemsg INTO MimeMsgId FROM k_mime_msgs WHERE id_message=MsgId;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    MimeMsgId:=NULL;
END k_sp_get_mime_msg;
GO;

CREATE OR REPLACE PROCEDURE k_sp_write_inet_addr (DomainId NUMBER,WorkAreaId CHAR, MsgGuid CHAR, MimeMsgId VARCHAR2, RecipientTp VARCHAR2, EMailTx VARCHAR2, PersonalTx VARCHAR2) IS
  UserId CHAR(32);
  ContactId CHAR(32);
  CompanyId CHAR(32);
  CURSOR Users (domid NUMBER, email VARCHAR2, email2 VARCHAR2) IS SELECT gu_user FROM k_users u WHERE u.id_domain = domid AND (u.tx_main_email = email OR EXISTS (SELECT a.gu_user FROM k_user_mail a WHERE a.gu_user=u.gu_user AND a.tx_main_email=email2));
  CURSOR Contacts (wrka CHAR, email VARCHAR2) IS SELECT gu_company,gu_contact FROM k_member_address WHERE gu_workarea=wrka AND tx_email = email;
BEGIN
  OPEN Users(DomainId,EMailTx,EMailTx);
    FETCH Users INTO UserId;
    IF Users%NOTFOUND THEN
      UserId:=NULL;
    END IF;
  CLOSE Users;
  OPEN Contacts(WorkAreaId,EMailTx);
    FETCH Contacts INTO CompanyId,ContactId;
    IF Contacts%NOTFOUND THEN
      CompanyId:=NULL;
      ContactId:=NULL;
    END IF;
  CLOSE Contacts;
  INSERT INTO k_inet_addrs (gu_mimemsg,id_message,tx_email,tp_recipient,tx_personal,gu_user,gu_contact,gu_company) VALUES (MsgGuid,MimeMsgId,EMailTx,RecipientTp,PersonalTx,UserId,ContactId,CompanyId);
  END k_sp_write_inet_addr;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_adhoc_mailing (AdHocId CHAR) IS
BEGIN
  UPDATE k_activities SET gu_mailing=NULL WHERE gu_mailing=AdHocId;
  DELETE k_x_adhoc_mailing_list WHERE gu_mailing=AdHocId;
  DELETE k_adhoc_mailings WHERE gu_mailing=AdHocId;
END k_sp_del_adhoc_mailing;
GO;