CREATE PROCEDURE k_sp_del_list (ListId CHAR(32))
BEGIN
  DECLARE tp SMALLINT;
  DECLARE wa CHAR(32) DEFAULT NULL;
  DECLARE bk CHAR(32) DEFAULT NULL;

  SELECT tp_list,gu_workarea INTO tp,wa FROM k_lists WHERE gu_list=ListId;

  DELETE FROM k_x_cat_objs WHERE gu_object=ListId;
  UPDATE k_activities SET gu_list=NULL WHERE gu_list=ListId;
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=ListId;

  SELECT gu_list INTO bk FROM k_lists WHERE gu_workarea=wa AND gu_query=ListId AND tp_list=4;
  IF bk IS NULL THEN
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=ListId) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>ListId);
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=ListId) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>ListId);
    DELETE FROM k_x_list_members WHERE gu_list=ListId;
    DELETE FROM k_x_adhoc_mailing_list WHERE gu_list=ListId;
    DELETE FROM k_x_pageset_list WHERE gu_list=ListId;
    DELETE FROM k_lists WHERE gu_list=ListId;
  ELSE  
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);
    DELETE FROM k_x_list_members WHERE gu_list=bk;
    DELETE FROM k_x_campaign_lists WHERE gu_list=bk;
    DELETE FROM k_x_adhoc_mailing_list WHERE gu_list=bk;
    DELETE FROM k_x_pageset_list WHERE gu_list=bk;
    DELETE FROM k_lists WHERE gu_list=bk;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_email_blocked (ListId CHAR(32), TxEmail VARCHAR(100), OUT BoBlocked SMALLINT)
BEGIN
  DECLARE BlackList CHAR(32) DEFAULT NULL;
  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=ListId AND tp_list=4;
  IF BlackList IS NULL THEN
    SET BoBlocked=0;
  ELSE
    SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND tx_email=TxEmail;
  END IF;
  SET BoBlocked = IFNULL(BoBlocked,0);
END
GO;

CREATE PROCEDURE k_sp_contact_blocked (ListId CHAR(32), GuContact CHAR(32), OUT BoBlocked SMALLINT)
BEGIN
  DECLARE BlackList CHAR(32) DEFAULT NULL;
  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=ListId AND tp_list=4;
  IF BlackList IS NULL THEN
    SET BoBlocked=0;
  ELSE
    SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND gu_contact=GuContact;
  END IF;
  SET BoBlocked = IFNULL(BoBlocked,0);
END
GO;

CREATE PROCEDURE k_sp_company_blocked (ListId CHAR(32), GuCompany CHAR(32), OUT BoBlocked SMALLINT)
BEGIN
  DECLARE BlackList CHAR(32) DEFAULT NULL;
  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=ListId AND tp_list=4;
  IF BlackList IS NULL THEN
    SET BoBlocked=0;
  ELSE
    SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND gu_company=GuCompany;
  END IF;
  SET BoBlocked = IFNULL(BoBlocked,0);
END
GO;

CREATE TRIGGER k_tr_del_company BEFORE DELETE ON k_companies FOR EACH ROW
BEGIN
  UPDATE k_member_address SET gu_company=NULL WHERE gu_company=OLD.gu_company;
END
GO;

CREATE TRIGGER k_tr_del_contact BEFORE DELETE ON k_contacts FOR EACH ROW
BEGIN
  UPDATE k_member_address SET gu_contact=NULL WHERE gu_contact=OLD.gu_contact;
END
GO;

CREATE TRIGGER k_tr_del_address BEFORE DELETE ON k_addresses FOR EACH ROW
BEGIN
  DELETE FROM k_member_address WHERE gu_address=OLD.gu_address;
END
GO;

CREATE TRIGGER k_tr_ins_address AFTER INSERT ON k_addresses FOR EACH ROW
BEGIN
  DECLARE AddrId CHAR(32) DEFAULT NULL;
  DECLARE NmLegal VARCHAR(70);
  DECLARE IsExists INTEGER;
  
  IF NEW.bo_active=1 THEN
    SELECT COUNT(gu_address) INTO IsExists FROM k_member_address WHERE gu_address=NEW.gu_address;
    IF IsExists>0 THEN
      SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=NEW.gu_address;
    ELSE
      SET AddrId = NULL;
    END IF;
    IF AddrId IS NULL THEN
      IF LENGTH(NEW.nm_company)=0 THEN
        SET NmLegal = NULL;
      ELSE
        SET NmLegal = NEW.nm_company;
      END IF;
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES
    				   (NEW.gu_address,NEW.ix_address,NEW.gu_workarea,NEW.dt_created,NEW.dt_modified,NEW.gu_user,NmLegal,NEW.tp_location,NEW.tp_street,NEW.nm_street,NEW.nu_street,NEW.tx_addr1,NEW.tx_addr2,CONCAT(COALESCE(NEW.tx_addr1,''),CHAR(10),COALESCE(NEW.tx_addr2,'')),NEW.id_country,NEW.nm_country,NEW.id_state,NEW.nm_state,NEW.mn_city,NEW.zipcode,NEW.work_phone,NEW.direct_phone,NEW.home_phone,NEW.mov_phone,NEW.fax_phone,NEW.other_phone,NEW.po_box,NEW.tx_email,NEW.url_addr,NEW.contact_person,NEW.tx_salutation,NEW.tx_remarks);
    END IF;
  END IF;
END
GO;

CREATE TRIGGER k_tr_upd_address AFTER UPDATE ON k_addresses FOR EACH ROW
BEGIN
  DECLARE AddrId CHAR(32) DEFAULT NULL;
  DECLARE NmLegal VARCHAR(70);
  DECLARE IsExists INTEGER;
  
  IF NEW.bo_active=1 THEN
    SELECT COUNT(gu_address) INTO IsExists FROM k_member_address WHERE gu_address=NEW.gu_address;
    IF IsExists>0 THEN
      SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=NEW.gu_address;
    ELSE
      SET AddrId = NULL;
    END IF;    
    IF AddrId IS NULL THEN
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES (NEW.gu_address,NEW.ix_address,NEW.gu_workarea,NEW.dt_created,NEW.dt_modified,NEW.gu_user,NEW.nm_company,NEW.tp_location,NEW.tp_street,NEW.nm_street,NEW.nu_street,NEW.tx_addr1,NEW.tx_addr2,CONCAT(COALESCE(NEW.tx_addr1,''),CHAR(10),COALESCE(NEW.tx_addr2,'')),NEW.id_country,NEW.nm_country,NEW.id_state,NEW.nm_state,NEW.mn_city,NEW.zipcode,NEW.work_phone,NEW.direct_phone,NEW.home_phone,NEW.mov_phone,NEW.fax_phone,NEW.other_phone,NEW.po_box,NEW.tx_email,NEW.url_addr,NEW.contact_person,NEW.tx_salutation,NEW.tx_remarks);
    ELSE
      IF LENGTH(NEW.nm_company)=0 THEN
        SET NmLegal = NULL;
      ELSE
        SET NmLegal = NEW.nm_company;
      END IF;
      UPDATE k_member_address SET ix_address=NEW.ix_address,gu_workarea=NEW.gu_workarea,dt_created=NEW.dt_created,dt_modified=NEW.dt_modified,gu_writer=NEW.gu_user,tp_location=NEW.tp_location,tp_street=NEW.tp_street,nm_street=NEW.nm_street,nu_street=NEW.nu_street,tx_addr1=NEW.tx_addr1,tx_addr2=NEW.tx_addr2,full_addr=CONCAT(COALESCE(NEW.tx_addr1,''),CHAR(10),COALESCE(NEW.tx_addr2,'')),id_country=NEW.id_country,nm_country=NEW.nm_country,id_state=NEW.id_state,nm_state=NEW.nm_state,mn_city=NEW.mn_city,zipcode=NEW.zipcode,work_phone=NEW.work_phone,direct_phone=NEW.direct_phone,home_phone=NEW.home_phone,mov_phone=NEW.mov_phone,fax_phone=NEW.fax_phone,other_phone=NEW.other_phone,po_box=NEW.po_box,tx_email=NEW.tx_email,url_addr=NEW.url_addr,contact_person=NEW.contact_person,tx_salutation=NEW.tx_salutation,tx_remarks=NEW.tx_remarks
      WHERE gu_address=NEW.gu_address;
    END IF;
  ELSE
    DELETE FROM k_member_address WHERE gu_address=NEW.gu_address;
  END IF;
END
GO;

CREATE TRIGGER k_tr_ins_comp_addr AFTER INSERT ON k_x_company_addr FOR EACH ROW
BEGIN
  DECLARE GuCompany     CHAR(32);
  DECLARE NmLegal       VARCHAR(70);
  DECLARE NmCommercial  VARCHAR(70);
  DECLARE IdLegal       VARCHAR(16);
  DECLARE IdSector      VARCHAR(16);
  DECLARE IdStatus      VARCHAR(30);
  DECLARE IdRef         VARCHAR(50);
  DECLARE TpCompany     VARCHAR(30);
  DECLARE NuEmployees  	INTEGER;
  DECLARE ImRevenue     INTEGER;
  DECLARE GuSalesMan    CHAR(32);
  DECLARE TxFranchise   VARCHAR(100);
  DECLARE GuGeoZone     CHAR(32);
  DECLARE DeCompany	VARCHAR(254);

  SELECT gu_company,nm_legal,id_legal,nm_commercial,id_sector,id_status,id_ref,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,de_company INTO GuCompany,NmLegal,IdLegal,NmCommercial,IdSector,IdStatus,IdRef,TpCompany,NuEmployees,ImRevenue,GuSalesMan,TxFranchise,GuGeoZone,DeCompany FROM k_companies WHERE gu_company=NEW.gu_company;
  UPDATE k_member_address SET gu_company=GuCompany,nm_legal=NmLegal,id_legal=IdLegal,nm_commercial=NmCommercial,id_sector=IdSector,id_ref=IdRef,id_status=IdStatus,tp_company=TpCompany,nu_employees=NuEmployees,im_revenue=ImRevenue,gu_sales_man=GuSalesMan,tx_franchise=TxFranchise,gu_geozone=GuGeoZone,tx_comments=DeCompany WHERE gu_address=NEW.gu_address;
END
GO;

CREATE TRIGGER k_tr_ins_cont_addr AFTER INSERT ON k_x_contact_addr FOR EACH ROW
BEGIN
  DECLARE GuContact     CHAR(32);
  DECLARE GuCompany     CHAR(32);
  DECLARE GuWorkArea    CHAR(32);
  DECLARE TxName        VARCHAR(100);
  DECLARE TxSurname     VARCHAR(100);
  DECLARE DeTitle       VARCHAR(70);
  DECLARE TrTitle       VARCHAR(50);
  DECLARE DtBirth	TIMESTAMP;
  DECLARE SnPassport    VARCHAR(16);
  DECLARE IdGender      CHAR(1);
  DECLARE NyAge         SMALLINT;
  DECLARE IdNationality CHAR(3);
  DECLARE TxDept        VARCHAR(70);
  DECLARE TxDivision    VARCHAR(70);
  DECLARE TxComments	VARCHAR(254);
  DECLARE UrlLinkedIn	VARCHAR(254);
  DECLARE UrlFacebook	VARCHAR(254);
  DECLARE UrlTwitter	VARCHAR(254);

  SELECT gu_contact,gu_company,gu_workarea,tx_name,tx_surname,de_title,dt_birth,sn_passport,id_gender,ny_age,id_nationality,tx_dept,tx_division,tx_comments,url_linkedin,url_facebook,url_twitter
  INTO   GuContact,GuCompany,GuWorkArea,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,IdNationality,TxDept,TxDivision,TxComments,UrlLinkedIn,UrlFacebook,UrlTwitter FROM k_contacts 
  WHERE gu_contact=NEW.gu_contact;

  IF CHAR_LENGTH(TxName)=0 THEN SET TxName=NULL; END IF;
  IF CHAR_LENGTH(TxSurname)=0 THEN SET TxSurname=NULL; END IF;

  IF DeTitle IS NOT NULL THEN
    SET TrTitle='Title record not found';
    SELECT tr_en INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section='de_title' AND vl_lookup=DeTitle;
    IF TrTitle='Title record not found' THEN
      UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,
                                  id_gender=IdGender,ny_age=NyAge,id_nationality=IdNationality,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
                                  WHERE gu_address=NEW.gu_address;
    END IF;
  ELSE
    SET TrTitle = NULL;
  END IF;
  
  UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,id_nationality=IdNationality,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments WHERE gu_address=NEW.gu_address;
END
GO;

CREATE TRIGGER k_tr_upd_comp AFTER UPDATE ON k_companies FOR EACH ROW
BEGIN
  DECLARE NmLegal       VARCHAR(70);
  DECLARE NmCommercial  VARCHAR(70);
  DECLARE IdLegal       VARCHAR(16);
  DECLARE IdSector      VARCHAR(16);
  DECLARE IdStatus      VARCHAR(30);
  DECLARE IdRef         VARCHAR(50);
  DECLARE TpCompany     VARCHAR(30);
  DECLARE NuEmployees  	INTEGER;
  DECLARE ImRevenue     INTEGER;
  DECLARE GuSalesMan    CHAR(32);
  DECLARE TxFranchise   VARCHAR(100);
  DECLARE GuGeoZone     CHAR(32);
  DECLARE DeCompany	VARCHAR(254);

  SELECT nm_legal,id_legal,nm_commercial,id_sector,id_status,id_ref,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,de_company INTO NmLegal,IdLegal,NmCommercial,IdSector,IdStatus,IdRef,TpCompany,NuEmployees,ImRevenue,GuSalesMan,TxFranchise,GuGeoZone,DeCompany FROM k_companies WHERE gu_company=NEW.gu_company;
  UPDATE k_member_address SET nm_legal=NmLegal,id_legal=IdLegal,nm_commercial=NmCommercial,id_sector=IdSector,id_ref=IdRef,id_status=IdStatus,tp_company=TpCompany,nu_employees=NuEmployees,im_revenue=ImRevenue,gu_sales_man=GuSalesMan,tx_franchise=TxFranchise,gu_geozone=GuGeoZone,tx_comments=DeCompany WHERE gu_company=NEW.gu_company;
END
GO;

CREATE TRIGGER k_tr_upd_cont AFTER UPDATE ON k_contacts FOR EACH ROW
BEGIN
  DECLARE GuCompany     CHAR(32);
  DECLARE GuWorkArea    CHAR(32);
  DECLARE TxName        VARCHAR(100);
  DECLARE TxSurname     VARCHAR(100);
  DECLARE DeTitle       VARCHAR(70);
  DECLARE TrTitle       VARCHAR(50);
  DECLARE DtBirth	      TIMESTAMP;
  DECLARE SnPassport    VARCHAR(16);
  DECLARE IdGender      CHAR(1);
  DECLARE NyAge         SMALLINT;
  DECLARE IdNationality CHAR(3);
  DECLARE TxDept        VARCHAR(70);
  DECLARE TxDivision    VARCHAR(70);
  DECLARE TxComments	  VARCHAR(254);
  DECLARE UrlLinkedIn	  VARCHAR(254);
  DECLARE UrlFacebook	  VARCHAR(254);
  DECLARE UrlTwitter	  VARCHAR(254);

  SELECT gu_company,gu_workarea,tx_name,tx_surname,de_title,dt_birth,sn_passport,id_gender,ny_age,id_nationality,tx_dept,tx_division,tx_comments,url_linkedin,url_facebook,url_twitter
  INTO   GuCompany,GuWorkArea,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,IdNationality,TxDept,TxDivision,TxComments,UrlLinkedIn,UrlFacebook,UrlTwitter FROM k_contacts 
  WHERE gu_contact=NEW.gu_contact;

  IF CHAR_LENGTH(TxName)=0 THEN SET TxName=NULL; END IF;
  IF CHAR_LENGTH(TxSurname)=0 THEN SET TxSurname=NULL; END IF;

  IF DeTitle IS NOT NULL THEN
    SET TrTitle='Title record not found';
    SELECT tr_en INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section='de_title' AND vl_lookup=DeTitle;
    IF TrTitle='Title record not found' THEN
      UPDATE k_member_address SET gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,
                                  ny_age=NyAge,id_nationality=IdNationality,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
                                  WHERE gu_contact=NEW.gu_contact;
    END IF;
  ELSE
    SET TrTitle = NULL;
  END IF;
  
  UPDATE k_member_address SET gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,
         ny_age=NyAge,id_nationality=IdNationality,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter WHERE gu_contact=NEW.gu_contact;
END
GO;

CREATE PROCEDURE k_sp_del_duplicates (ListId CHAR(32), OUT Deleted INTEGER)
BEGIN
  DECLARE NuTimes INTEGER;
  DECLARE TxEmail VARCHAR(100);
  DECLARE Members CURSOR FOR SELECT tx_email FROM k_x_list_members WHERE gu_list = ListId;
  CREATE TEMPORARY TABLE k_temp_list_emails (tx_email VARCHAR(100) CONSTRAINT pk_temp_list_emails PRIMARY KEY, nu_times INTEGER) ENGINE = MEMORY;
  INSERT INTO k_temp_list_emails SELECT DISTINCT(tx_email),0 FROM k_x_list_members WHERE gu_list=ListId;
  SET Deleted=0;
  OPEN Members;
  FETCH Members INTO TxEmail;
  WHILE FOUND DO
    UPDATE k_temp_list_emails SET nu_times=nu_times+1 WHERE tx_email = TxEmail;    
    FETCH Members INTO TxEmail;
  END WHILE;
  CLOSE Members;
  DECLARE Dups CURSOR FOR SELECT tx_email,nu_times FROM k_temp_list_emails WHERE nu_times>1;
  OPEN Dups;
  FETCH Dups INTO TxEmail,NuTimes;
  WHILE FOUND DO
    DELETE FROM k_x_list_members WHERE gu_list=ListId AND tx_email=TxEmail LIMIT NuTimes-1;
    FETCH Dups INTO TxEmail,NuTimes;
  END WHILE;
  CLOSE Dups;
  DROP TABLE k_temp_list_emails;
END
GO;
