CREATE FUNCTION k_sp_del_list (CHAR) RETURNS INTEGER AS '
DECLARE
  tp SMALLINT;
  wa CHAR(32);
  bk CHAR(32);
BEGIN

  SELECT tp_list,gu_workarea INTO tp,wa FROM k_lists WHERE gu_list=$1;

  SELECT gu_list INTO bk FROM k_lists WHERE gu_workarea=wa AND gu_query=$1 AND tp_list=4;

  IF FOUND THEN
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);

    DELETE FROM k_x_list_members WHERE gu_list=bk;

    DELETE FROM k_x_campaign_lists WHERE gu_list=bk;

    DELETE FROM k_x_adhoc_mailing_list WHERE gu_list=bk;

    DELETE FROM k_x_pageset_list WHERE gu_list=bk;

    DELETE FROM k_lists WHERE gu_list=bk;
  END IF;

  DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=$1) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>$1);

  DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=$1) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>$1);

  DELETE FROM k_x_list_members WHERE gu_list=$1;

  DELETE FROM k_x_campaign_lists WHERE gu_list=$1;

  DELETE FROM k_x_adhoc_mailing_list WHERE gu_list=$1;

  DELETE FROM k_x_pageset_list WHERE gu_list=$1;

  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  UPDATE k_activities SET gu_list=NULL WHERE gu_list=$1;
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=$1;

  DELETE FROM k_lists WHERE gu_list=$1;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_email_blocked (CHAR,VARCHAR) RETURNS SMALLINT AS '
DECLARE
  BlackList CHAR(32);
  BoBlocked SMALLINT;

BEGIN
  BoBlocked := 0;

  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=$1 AND tp_list=4;

  IF FOUND THEN
    SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND tx_email=$2;
  END IF;

  RETURN BoBlocked;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_contact_blocked (CHAR,CHAR) RETURNS SMALLINT AS '
DECLARE
  BlackList CHAR(32);
  BoBlocked SMALLINT;

BEGIN
  BoBlocked := 0;

  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=$1 AND tp_list=4;

  IF FOUND THEN
    SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND gu_contact=$2 LIMIT 1;
  END IF;

  RETURN BoBlocked;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_company_blocked (CHAR,CHAR) RETURNS SMALLINT AS '
DECLARE
  BlackList CHAR(32);
  BoBlocked SMALLINT;

BEGIN
  BoBlocked := 0;

  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=$1 AND tp_list=4;

  IF FOUND THEN
    SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND gu_company=$2 LIMIT 1;
  END IF;

  RETURN BoBlocked;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_company() RETURNS OPAQUE AS '
BEGIN
  UPDATE k_member_address SET gu_company=NULL WHERE gu_company=OLD.gu_company;
  RETURN OLD;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_del_company BEFORE DELETE ON k_companies FOR EACH ROW EXECUTE PROCEDURE k_sp_del_company();
GO;

CREATE FUNCTION k_sp_del_contact() RETURNS OPAQUE AS '
BEGIN
  UPDATE k_member_address SET gu_contact=NULL WHERE gu_contact=OLD.gu_contact;
  RETURN OLD;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_del_contact BEFORE DELETE ON k_contacts FOR EACH ROW EXECUTE PROCEDURE k_sp_del_contact();
GO;

CREATE FUNCTION k_sp_del_address() RETURNS OPAQUE AS '
BEGIN
  DELETE FROM k_member_address WHERE gu_address=OLD.gu_address;
  RETURN OLD;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_del_address BEFORE DELETE ON k_addresses FOR EACH ROW EXECUTE PROCEDURE k_sp_del_address();
GO;

CREATE FUNCTION k_sp_ins_address() RETURNS OPAQUE AS '
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR(70);

BEGIN
  IF NEW.bo_active=1 THEN
  
    NmLegal := NEW.nm_company;
    IF NmLegal IS NOT NULL AND char_length(NmLegal)=0 THEN
      NmLegal := NULL;
    END IF;
    
    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=NEW.gu_address;

    IF NOT FOUND THEN
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,
                                    tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,
                                    nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,
                                    mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES
                                   (NEW.gu_address,NEW.ix_address,NEW.gu_workarea,NEW.dt_created,NEW.dt_modified,NEW.gu_user,NmLegal,
                                    NEW.tp_location,NEW.tp_street,NEW.nm_street,NEW.nu_street,NEW.tx_addr1,
                                    NEW.tx_addr2,COALESCE(NEW.tx_addr1,'''')||CHR(10)||COALESCE(NEW.tx_addr2,''''),
                                    NEW.id_country,NEW.nm_country,NEW.id_state,NEW.nm_state,NEW.mn_city,NEW.zipcode,
                                    NEW.work_phone,NEW.direct_phone,NEW.home_phone,NEW.mov_phone,NEW.fax_phone,NEW.other_phone,
                                    NEW.po_box,NEW.tx_email,NEW.url_addr,NEW.contact_person,NEW.tx_salutation,NEW.tx_remarks);
    END IF;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_ins_address AFTER INSERT ON k_addresses FOR EACH ROW EXECUTE PROCEDURE k_sp_ins_address();
GO;

CREATE FUNCTION k_sp_upd_address() RETURNS OPAQUE AS '
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR(70);
  
BEGIN
  IF NEW.bo_active=1 THEN
    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=NEW.gu_address;

    NmLegal := NEW.nm_company;
    IF NmLegal IS NOT NULL AND char_length(NmLegal)=0 THEN
      NmLegal := NULL;
    END IF;

    IF NOT FOUND THEN
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES
    				   (NEW.gu_address,NEW.ix_address,NEW.gu_workarea,NEW.dt_created,NEW.dt_modified,NEW.gu_user,NmLegal,NEW.tp_location,NEW.tp_street,NEW.nm_street,NEW.nu_street,NEW.tx_addr1,NEW.tx_addr2,COALESCE(NEW.tx_addr1,'''')||CHR(10)||COALESCE(NEW.tx_addr2,''''),NEW.id_country,NEW.nm_country,NEW.id_state,NEW.nm_state,NEW.mn_city,NEW.zipcode,NEW.work_phone,NEW.direct_phone,NEW.home_phone,NEW.mov_phone,NEW.fax_phone,NEW.other_phone,NEW.po_box,NEW.tx_email,NEW.url_addr,NEW.contact_person,NEW.tx_salutation,NEW.tx_remarks);
    ELSE
      UPDATE k_member_address SET ix_address=NEW.ix_address,gu_workarea=NEW.gu_workarea,dt_created=NEW.dt_created,dt_modified=NEW.dt_modified,gu_writer=NEW.gu_user,tp_location=NEW.tp_location,tp_street=NEW.tp_street,nm_street=NEW.nm_street,nu_street=NEW.nu_street,tx_addr1=NEW.tx_addr1,tx_addr2=NEW.tx_addr2,full_addr=COALESCE(NEW.tx_addr1,'''')||CHR(10)||COALESCE(NEW.tx_addr2,''''),id_country=NEW.id_country,nm_country=NEW.nm_country,id_state=NEW.id_state,nm_state=NEW.nm_state,mn_city=NEW.mn_city,zipcode=NEW.zipcode,work_phone=NEW.work_phone,direct_phone=NEW.direct_phone,home_phone=NEW.home_phone,mov_phone=NEW.mov_phone,fax_phone=NEW.fax_phone,other_phone=NEW.other_phone,po_box=NEW.po_box,tx_email=NEW.tx_email,url_addr=NEW.url_addr,contact_person=NEW.contact_person,tx_salutation=NEW.tx_salutation,tx_remarks=NEW.tx_remarks
      WHERE gu_address=NEW.gu_address;
    END IF;
  ELSE
    DELETE FROM k_member_address WHERE gu_address=NEW.gu_address;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_upd_address AFTER UPDATE ON k_addresses FOR EACH ROW EXECUTE PROCEDURE k_sp_upd_address();
GO;

CREATE FUNCTION k_sp_ins_comp_addr() RETURNS OPAQUE AS '
DECLARE

  GuCompany     CHAR(32);
  NmLegal       VARCHAR(70);
  NmCommercial  VARCHAR(70);
  IdLegal       VARCHAR(16);
  IdSector      VARCHAR(16);
  IdStatus      VARCHAR(30);
  IdRef         VARCHAR(50);
  TpCompany     VARCHAR(30);
  NuEmployees  	INTEGER;
  ImRevenue     FLOAT;
  GuSalesMan    CHAR(32);
  TxFranchise   VARCHAR(100);
  GuGeoZone     CHAR(32);
  DeCompany	VARCHAR(254);

BEGIN
  SELECT gu_company,nm_legal,id_legal,nm_commercial,id_sector,id_status,id_ref,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,de_company
  INTO GuCompany,NmLegal,IdLegal,NmCommercial,IdSector,IdStatus,IdRef,TpCompany,NuEmployees,ImRevenue,GuSalesMan,TxFranchise,GuGeoZone,DeCompany
  FROM k_companies WHERE gu_company=NEW.gu_company;

  UPDATE k_member_address SET gu_company=GuCompany,nm_legal=NmLegal,id_legal=IdLegal,nm_commercial=NmCommercial,id_sector=IdSector,id_ref=IdRef,id_status=IdStatus,tp_company=TpCompany,nu_employees=NuEmployees,im_revenue=ImRevenue,gu_sales_man=GuSalesMan,tx_franchise=TxFranchise,gu_geozone=GuGeoZone,tx_comments=DeCompany
  WHERE gu_address=NEW.gu_address;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_ins_comp_addr AFTER INSERT ON k_x_company_addr FOR EACH ROW EXECUTE PROCEDURE k_sp_ins_comp_addr()
GO;

CREATE FUNCTION k_sp_ins_cont_addr() RETURNS OPAQUE AS '
DECLARE
  GuCompany     CHAR(32);
  GuContact     CHAR(32);
  GuWorkArea    CHAR(32);
  GuGeoZone     CHAR(32);
  TxName        VARCHAR(100);
  TxSurname     VARCHAR(100);
  DeTitle       VARCHAR(70);
  TrTitle       VARCHAR(50);
  DtBirth       TIMESTAMP;
  SnPassport    VARCHAR(16);
  IdGender      CHAR(1);
  NyAge         SMALLINT;
  IdNationality CHAR(3);
  TxDept        VARCHAR(70);
  TxDivision    VARCHAR(70);
  NmLegal       VARCHAR(70);
  NmCommercial  VARCHAR(70);
  IdLegal       VARCHAR(16);
  IdSector      VARCHAR(16);
  TxComments    VARCHAR(254);
  UrlLinkedIn	VARCHAR(254);
  UrlFacebook	VARCHAR(254);
  UrlTwitter	VARCHAR(254);

BEGIN
  SELECT gu_contact,gu_company,gu_workarea,gu_geozone,
         CASE WHEN char_length(tx_name)=0 THEN NULL ELSE tx_name END,
         CASE WHEN char_length(tx_surname)=0 THEN NULL ELSE tx_surname END,
         de_title,dt_birth,sn_passport,id_gender,ny_age,id_nationality,tx_dept,tx_division,tx_comments,url_linkedin,url_facebook,url_twitter
  INTO   GuContact,GuCompany,GuWorkArea,GuGeoZone,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,IdNationality,TxDept,TxDivision,TxComments,UrlLinkedIn,UrlFacebook,UrlTwitter
  FROM k_contacts WHERE gu_contact=NEW.gu_contact;
  
  IF GuCompany IS NOT NULL THEN
    SELECT nm_commercial,nm_legal,id_legal,id_sector INTO NmCommercial,NmLegal,IdLegal,IdSector FROM k_companies WHERE gu_company=GuCompany;
  ELSE
    NmLegal := NULL;
    NmCommercial := NULL;
    IdLegal := NULL;
    IdSector := NULL;
  END IF;

  IF DeTitle IS NOT NULL THEN
    SELECT tr_en INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section=''de_title'' AND vl_lookup=DeTitle;
    IF NOT FOUND THEN
      UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,gu_geozone=GuGeoZone,tx_name=TxName,tx_surname=TxSurname,
                                  nm_legal=NmLegal,nm_commercial=NmCommercial,id_legal=IdLegal,id_sector=IdSector,
                                  de_title=DeTitle,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,id_nationality=IdNationality,
                                  ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
      WHERE gu_address=NEW.gu_address;
    ELSE
      UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,gu_geozone=GuGeoZone,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,
                                  nm_legal=NmLegal,nm_commercial=NmCommercial,id_legal=IdLegal,id_sector=IdSector,
                                  tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,id_nationality=IdNationality,
                                  tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
      WHERE gu_address=NEW.gu_address;
    END IF;
  ELSE
      UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,gu_geozone=GuGeoZone,tx_name=TxName,tx_surname=TxSurname,
                                  nm_legal=NmLegal,nm_commercial=NmCommercial,id_legal=IdLegal,id_sector=IdSector,
                                  de_title=NULL,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,
																	id_nationality=IdNationality,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,
																	url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
      WHERE gu_address=NEW.gu_address;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_ins_cont_addr AFTER INSERT ON k_x_contact_addr FOR EACH ROW EXECUTE PROCEDURE k_sp_ins_cont_addr()
GO;

CREATE FUNCTION k_sp_upd_comp() RETURNS OPAQUE AS '
DECLARE

  NmLegal       VARCHAR(70);
  NmCommercial  VARCHAR(70);
  IdLegal       VARCHAR(16);
  IdSector      VARCHAR(16);
  IdStatus      VARCHAR(30);
  IdRef         VARCHAR(50);
  TpCompany     VARCHAR(30);
  NuEmployees  	INTEGER;
  ImRevenue     FLOAT;
  GuSalesMan    CHAR(32);
  TxFranchise   VARCHAR(100);
  GuGeoZone     CHAR(32);
  DeCompany	    VARCHAR(254);

BEGIN
  SELECT nm_legal,id_legal,nm_commercial,id_sector,id_status,id_ref,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,de_company
  INTO NmLegal,IdLegal,NmCommercial,IdSector,IdStatus,IdRef,TpCompany,NuEmployees,ImRevenue,GuSalesMan,TxFranchise,GuGeoZone,DeCompany
  FROM k_companies WHERE gu_company=NEW.gu_company;

  UPDATE k_member_address SET nm_legal=NmLegal,id_legal=IdLegal,nm_commercial=NmCommercial,id_sector=IdSector,id_ref=IdRef,id_status=IdStatus,tp_company=TpCompany,nu_employees=NuEmployees,im_revenue=ImRevenue,gu_sales_man=GuSalesMan,tx_franchise=TxFranchise,gu_geozone=GuGeoZone,tx_comments=DeCompany
  WHERE gu_company=NEW.gu_company;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_upd_comp AFTER UPDATE ON k_companies FOR EACH ROW EXECUTE PROCEDURE k_sp_upd_comp()
GO;

CREATE FUNCTION k_sp_upd_cont() RETURNS OPAQUE AS '
DECLARE
  GuCompany     CHAR(32);
  GuWorkArea    CHAR(32);
  GuGeoZone     CHAR(32);
  TxName        VARCHAR(100);
  TxSurname     VARCHAR(100);
  DeTitle       VARCHAR(70);
  TrTitle       VARCHAR(50);
  DtBirth       TIMESTAMP;
  SnPassport    VARCHAR(16);
  IdGender      CHAR(1);
  IdNationality CHAR(3);
  NyAge         SMALLINT;
  TxDept        VARCHAR(70);
  TxDivision    VARCHAR(70);
  NmLegal       VARCHAR(70);
  NmCommercial  VARCHAR(70);
  IdLegal       VARCHAR(16);
  IdSector      VARCHAR(16);
  TxComments    VARCHAR(254);
  UrlLinkedIn	VARCHAR(254);
  UrlFacebook	VARCHAR(254);
  UrlTwitter	VARCHAR(254);

BEGIN
  SELECT gu_company,gu_workarea,gu_geozone,
         CASE WHEN char_length(tx_name)=0 THEN NULL ELSE tx_name END,
         CASE WHEN char_length(tx_surname)=0 THEN NULL ELSE tx_surname END,
         de_title,dt_birth,sn_passport,id_gender,ny_age,id_nationality,tx_dept,tx_division,tx_comments,url_linkedin,url_facebook,url_twitter
  INTO   GuCompany,GuWorkArea,GuGeoZone,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,IdNationality,TxDept,TxDivision,TxComments,UrlLinkedIn,UrlFacebook,UrlTwitter
  FROM k_contacts WHERE gu_contact=NEW.gu_contact;

  IF GuCompany IS NOT NULL THEN
    SELECT nm_commercial,nm_legal,id_legal,id_sector INTO NmCommercial,NmLegal,IdLegal,IdSector FROM k_companies WHERE gu_company=GuCompany;
  ELSE
    NmLegal := NULL;
    NmCommercial := NULL;
    IdLegal := NULL;
    IdSector := NULL;
  END IF;
  
  IF DeTitle IS NOT NULL THEN
    SELECT tr_en INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section=''de_title'' AND vl_lookup=DeTitle;
    IF NOT FOUND THEN
      UPDATE k_member_address SET gu_company=GuCompany,gu_geozone=GuGeoZone,tx_name=TxName,tx_surname=TxSurname,
                                  nm_legal=NmLegal,nm_commercial=NmCommercial,id_legal=IdLegal,id_sector=IdSector,
                                  de_title=substring(DeTitle,1,50),tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,id_nationality=IdNationality,
                                  ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
      WHERE gu_contact=NEW.gu_contact;
    ELSE
      UPDATE k_member_address SET gu_company=GuCompany,gu_geozone=GuGeoZone,tx_name=TxName,tx_surname=TxSurname,de_title=substring(DeTitle,1,50),
                                  nm_legal=NmLegal,nm_commercial=NmCommercial,id_legal=IdLegal,id_sector=IdSector,
                                  tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,id_nationality=IdNationality,
                                  tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
      WHERE gu_contact=NEW.gu_contact;
    END IF;
  ELSE
      UPDATE k_member_address SET gu_company=GuCompany,gu_geozone=GuGeoZone,tx_name=TxName,tx_surname=TxSurname,
                                  nm_legal=NmLegal,nm_commercial=NmCommercial,id_legal=IdLegal,id_sector=IdSector,
                                  de_title=NULL,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,id_nationality=IdNationality,
                                  ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
      WHERE gu_contact=NEW.gu_contact;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_upd_cont AFTER UPDATE ON k_contacts FOR EACH ROW EXECUTE PROCEDURE k_sp_upd_cont()
GO;

CREATE FUNCTION k_sp_del_duplicates (CHAR) RETURNS INTEGER AS '
DECLARE
  deleted INTEGER;
  txemail VARCHAR(100);
  tmpmail VARCHAR(100);
  members NO SCROLL CURSOR (gu CHAR(32)) IS SELECT tx_email FROM k_x_list_members WHERE gu_list = gu;
BEGIN
  CREATE TEMPORARY TABLE k_temp_list_emails (tx_email VARCHAR(100) CONSTRAINT pk_temp_list_emails PRIMARY KEY) ON COMMIT DROP;
  INSERT INTO k_temp_list_emails SELECT DISTINCT(tx_email) FROM k_x_list_members WHERE gu_list=$1;
  deleted:=0;
  OPEN members($1);
  FETCH members INTO txemail;
  WHILE FOUND LOOP
    tmpmail:=NULL;
    DELETE FROM k_temp_list_emails WHERE tx_email=txemail RETURNING tx_email INTO tmpmail;
    IF tmpmail IS NULL THEN
      deleted:=deleted+1;
      DELETE FROM k_x_list_members WHERE CURRENT OF members;
    END IF;
    FETCH members INTO txemail;
  END LOOP;
  CLOSE members;
  DROP TABLE k_temp_list_emails;
  return deleted;
END;
' LANGUAGE 'plpgsql';
GO;


CREATE FUNCTION k_sp_rebuild_member_address () RETURNS INTEGER AS '
DECLARE
  m RECORD;
  nRowCount INTEGER;
  IdLegal VARCHAR(16);
  NmLegal VARCHAR(70);
  NmCommercial VARCHAR(70);
  IdSector VARCHAR(16);  
  TpCompany VARCHAR(30);
  NuEmployees INTEGER;
  ImRevenue FLOAT;
  TxFranchise VARCHAR(100);
  TrTitle VARCHAR(50);
BEGIN
  nRowCount:=0;

  DELETE FROM k_member_address;

  FOR m IN SELECT a.gu_address,a.ix_address,c.gu_workarea,c.gu_company,a.dt_created,a.dt_modified,a.gu_user,c.nm_commercial,c.nm_legal,
                  c.id_legal,c.id_sector,c.id_status,c.id_ref,c.de_company,c.tp_company,c.nu_employees,c.im_revenue,c.gu_sales_man,
                  c.tx_franchise,c.gu_geozone,a.tp_location,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,
                  COALESCE(a.tx_addr1,'''')||CHR(10)||COALESCE(a.tx_addr2,'''') AS full_addr,a.id_country,a.nm_country,a.id_state,
                  a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,
                  a.po_box,a.tx_email,a.url_addr,a.contact_person,a.tx_salutation,a.tx_remarks
                  FROM k_companies c, k_x_company_addr x, k_addresses a
                  WHERE c.gu_company=x.gu_company AND x.gu_address=a.gu_address LOOP
    BEGIN
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,gu_company,dt_created,dt_modified,gu_writer,nm_commercial,nm_legal,id_legal,id_sector,id_status,id_ref,tx_comments,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks)
      VALUES (m.gu_address,m.ix_address,m.gu_workarea,m.gu_company,m.dt_created,m.dt_modified,m.gu_user,m.nm_commercial,m.nm_legal,m.id_legal,m.id_sector,m.id_status,m.id_ref,m.de_company,m.tp_company,m.nu_employees,m.im_revenue,m.gu_sales_man,m.tx_franchise,m.gu_geozone,m.tp_location,m.tp_street,m.nm_street,m.nu_street,m.tx_addr1,m.tx_addr2,m.full_addr,m.id_country,m.nm_country,m.id_state,m.nm_state,m.mn_city,m.zipcode,m.work_phone,m.direct_phone,m.home_phone,m.mov_phone,m.fax_phone,m.other_phone,m.po_box,m.tx_email,m.url_addr,m.contact_person,m.tx_salutation,m.tx_remarks);
      nRowCount:=nRowCount+1;
    EXCEPTION
      WHEN INTEGRITY_CONSTRAINT_VIOLATION OR UNIQUE_VIOLATION THEN
    END;
  END LOOP;

  FOR m IN SELECT a.gu_address,a.ix_address,c.gu_workarea,c.gu_company,c.gu_contact,a.dt_created,a.dt_modified,a.gu_user,
  				  c.id_status,c.id_ref,c.de_title,c.tx_comments,c.gu_sales_man,c.gu_geozone,c.bo_private,c.dt_birth,c.tx_dept,
  				  c.tx_division,c.sn_passport,c.ny_age,c.id_gender,c.tx_name,c.tx_surname,a.tp_location,a.tp_street,a.nm_street,
  				  a.nu_street,a.tx_addr1,a.tx_addr2,COALESCE(a.tx_addr1,'''')||CHR(10)||COALESCE(a.tx_addr2,'''') AS full_addr,
                  a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,
                  a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.contact_person,
                  a.tx_salutation,a.tx_remarks
                  FROM k_contacts c, k_x_contact_addr x, k_addresses a
                  WHERE c.gu_contact=x.gu_contact AND x.gu_address=a.gu_address LOOP
    IF m.gu_company IS NOT NULL THEN
      SELECT id_legal,nm_legal,nm_commercial,id_sector,tp_company,nu_employees,im_revenue,tx_franchise INTO IdLegal,NmLegal,NmCommercial,IdSector,TpCompany,NuEmployees,ImRevenue,TxFranchise FROM k_companies WHERE gu_company=m.gu_company;
    ELSE
      IdLegal:=NULL;
      NmLegal:=NULL;
      NmCommercial:=NULL;
      IdSector:=NULL;
      TpCompany:=NULL;
      NuEmployees:=NULL;
      ImRevenue:=NULL;
      TxFranchise:=NULL;
    END IF;
    IF m.de_title IS NOT NULL THEN
      SELECT tr_es INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=m.gu_workarea AND id_section=''de_title'' AND vl_lookup=m.de_title;
    END IF;
    BEGIN
      INSERT INTO k_member_address (  gu_address,  ix_address,  gu_workarea,  gu_company,  gu_contact,  dt_created,  dt_modified,  bo_private,gu_writer,nm_commercial,nm_legal,id_legal,id_sector,  id_status,  tx_name,  tx_surname,de_title               ,tr_title,  id_ref,  dt_birth,  id_gender,  sn_passport,  tx_comments,tp_company,nu_employees,im_revenue,  gu_sales_man,tx_franchise,  gu_geozone,  ny_age,  tx_dept,  tx_division,  tp_location,  tp_street,  nm_street,  nu_street,  tx_addr1,  tx_addr2,full_addr  ,  id_country,  nm_country,  id_state,  nm_state,  mn_city,  zipcode,  work_phone,  direct_phone,  home_phone,  mov_phone,  fax_phone,  other_phone,  po_box,  tx_email,  url_addr,  contact_person,  tx_salutation,  tx_remarks)
      VALUES                       (m.gu_address,m.ix_address,m.gu_workarea,m.gu_company,m.gu_contact,m.dt_created,m.dt_modified,m.bo_private,m.gu_user,NmCommercial ,NmLegal ,IdLegal ,IdSector ,m.id_status,m.tx_name,m.tx_surname,substr(m.de_title,1,50),TrTitle ,m.id_ref,m.dt_birth,m.id_gender,m.sn_passport,m.tx_comments,TpCompany ,NuEmployees ,ImRevenue ,m.gu_sales_man,TxFranchise ,m.gu_geozone,m.ny_age,m.tx_dept,m.tx_division,m.tp_location,m.tp_street,m.nm_street,m.nu_street,m.tx_addr1,m.tx_addr2,m.full_addr,m.id_country,m.nm_country,m.id_state,m.nm_state,m.mn_city,m.zipcode,m.work_phone,m.direct_phone,m.home_phone,m.mov_phone,m.fax_phone,m.other_phone,m.po_box,m.tx_email,m.url_addr,m.contact_person,m.tx_salutation,m.tx_remarks);
      nRowCount:=nRowCount+1;
    EXCEPTION
      WHEN INTEGRITY_CONSTRAINT_VIOLATION OR UNIQUE_VIOLATION THEN
    END;
  END LOOP;

  RETURN nRowCount;
END;
' LANGUAGE 'plpgsql';
GO;
