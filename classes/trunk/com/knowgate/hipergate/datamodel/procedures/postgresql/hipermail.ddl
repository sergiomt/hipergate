CREATE SEQUENCE seq_k_adhoc_mailings INCREMENT 1 MINVALUE 1 START 1
GO;

CREATE FUNCTION k_sp_del_mime_msg (CHAR) RETURNS INTEGER AS '
DECLARE
  ParentId CHAR(32);
BEGIN
  SELECT gu_parent_msg INTO ParentId FROM k_mime_msgs WHERE gu_mimemsg=$1;
  IF FOUND THEN  
    IF ParentId IS NOT NULL THEN
      PERFORM k_sp_del_mime_msg (ParentId);
    END IF;
    DELETE FROM k_inet_addrs WHERE gu_mimemsg=$1;
    DELETE FROM k_mime_parts WHERE gu_mimemsg=$1;
    DELETE FROM k_mime_msgs  WHERE gu_mimemsg=$1;
  END IF;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_get_mime_msg (VARCHAR) RETURNS CHAR AS '
DECLARE
  MimeMsgId CHAR(32);
BEGIN
  SELECT gu_mimemsg INTO MimeMsgId FROM k_mime_msgs WHERE id_message=$1;

  IF NOT FOUND THEN
    MimeMsgId := NULL;
  END IF;
  
  RETURN MimeMsgId;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_write_inet_addr (INTEGER,CHAR,CHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) RETURNS INTEGER AS '
DECLARE
  FoundCount INTEGER;
  UserId CHAR(32);
  ContactId CHAR(32);
  CompanyId CHAR(32);
  FullName VARCHAR(254);
  PersonalTx VARCHAR(254);
  Users CURSOR IS SELECT gu_user,TRIM(COALESCE(nm_user)||'' ''||COALESCE(tx_surname1)||'' ''||COALESCE(tx_surname2)) AS full_name FROM k_users u WHERE u.id_domain=$1 AND (u.tx_main_email=$5 OR EXISTS (SELECT a.gu_user FROM k_user_mail a WHERE a.gu_user=u.gu_user AND a.tx_main_email=$5));
  Contacts CURSOR IS SELECT gu_company,gu_contact,TRIM(COALESCE(tx_name)||'' ''||COALESCE(tx_surname)) AS full_name FROM k_member_address WHERE gu_workarea=$2 AND tx_email=$5;
BEGIN
  PersonalTx:=$7;
  OPEN Users;
    FETCH Users INTO UserId,FullName;
    IF FOUND THEN
      FoundCount:=1;
      IF $7 IS NULL THEN
	    PersonalTx:=FullName;
      END IF;
    ELSE
      FoundCount:=0;
      UserId := NULL;
    END IF;    
  CLOSE Users;
  OPEN Contacts;
    FETCH Contacts INTO CompanyId,ContactId,FullName;
    IF FOUND THEN
      FoundCount:=1;
      IF $7 IS NULL THEN
        PersonalTx:=FullName;
      END IF;
    ELSE
      FoundCount:=0;
      ContactId := NULL;
      CompanyId := NULL;
    END IF;    
  CLOSE Contacts;

  INSERT INTO k_inet_addrs (gu_mimemsg,id_message,tx_email,tp_recipient,tx_personal,gu_user,gu_contact,gu_company) VALUES ($3,$4,$5,$6,PersonalTx,UserId,ContactId,CompanyId);

  RETURN FoundCount;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_adhoc_mailing (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_activities SET gu_mailing=NULL WHERE gu_mailing=$1;
  DELETE FROM k_x_adhoc_mailing_list WHERE gu_mailing=$1;
  DELETE FROM k_adhoc_mailings WHERE gu_mailing=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;
