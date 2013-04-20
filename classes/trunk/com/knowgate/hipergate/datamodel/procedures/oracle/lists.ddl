CREATE OR REPLACE PROCEDURE k_sp_del_list (ListId CHAR) IS
  tp NUMBER(6);
  wa CHAR(32);
  bk CHAR(32);

BEGIN

  SELECT tp_list,gu_workarea INTO tp,wa FROM k_lists WHERE gu_list=ListId;

  SELECT gu_list INTO bk FROM k_lists WHERE gu_workarea=wa AND gu_query=ListId AND tp_list=4;

  DELETE k_x_cat_objs WHERE gu_object=ListId;
  UPDATE k_activities SET gu_list=NULL WHERE gu_list=ListId;
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=ListId;

  DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);
  DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);

  DELETE k_x_list_members WHERE gu_list=bk;
  
  DELETE k_x_campaign_lists WHERE gu_list=bk;

  DELETE k_x_adhoc_mailing_list WHERE gu_list=bk;

  DELETE k_x_pageset_list WHERE gu_list=bk;
  
  DELETE k_lists WHERE gu_list=bk;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    bk:=NULL;

    DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=ListId) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>ListId);

    DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=ListId) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>ListId);

    DELETE k_x_list_members WHERE gu_list=ListId;

    DELETE k_x_campaign_lists WHERE gu_list=ListId;

    DELETE k_x_adhoc_mailing_list WHERE gu_list=ListId;

    DELETE k_x_pageset_list WHERE gu_list=ListId;

    DELETE k_lists WHERE gu_list=ListId;
END k_sp_del_list;
GO;

CREATE OR REPLACE PROCEDURE k_sp_email_blocked (ListId CHAR, TxEmail VARCHAR2, BoBlocked OUT NUMBER) IS
  BlackList CHAR(32);
BEGIN

  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=ListId AND tp_list=4;

  SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND tx_email=TxEmail;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    BoBlocked := 0;

END k_sp_email_blocked;
GO;

CREATE OR REPLACE PROCEDURE k_sp_contact_blocked (ListId CHAR, GuContact CHAR, BoBlocked OUT NUMBER) IS
  BlackList CHAR(32);
BEGIN

  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=ListId AND tp_list=4;

  SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND gu_contact=GuContact;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    BoBlocked := 0;

END k_sp_contact_blocked;
GO;

CREATE OR REPLACE PROCEDURE k_sp_company_blocked (ListId CHAR, GuCompany CHAR, BoBlocked OUT NUMBER) IS
  BlackList CHAR(32);
BEGIN

  SELECT gu_list INTO BlackList FROM k_lists WHERE gu_query=ListId AND tp_list=4;

  SELECT 1 INTO BoBlocked FROM k_x_list_members WHERE gu_list=BlackList AND gu_company=GuCompany;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    BoBlocked := 0;

END k_sp_company_blocked;
GO;

CREATE OR REPLACE TRIGGER k_tr_del_company BEFORE DELETE ON k_companies FOR EACH ROW
BEGIN
  UPDATE k_member_address SET gu_company=NULL WHERE gu_company=:old.gu_company;
END k_tr_del_company;
GO;

CREATE OR REPLACE TRIGGER k_tr_del_contact BEFORE DELETE ON k_contacts FOR EACH ROW
BEGIN
  UPDATE k_member_address SET gu_contact=NULL WHERE gu_contact=:old.gu_contact;
END k_tr_del_contact;
GO;

CREATE OR REPLACE TRIGGER k_tr_del_address BEFORE DELETE ON k_addresses FOR EACH ROW
BEGIN
  DELETE FROM k_member_address WHERE gu_address=:old.gu_address;
END k_tr_del_address;
GO;

CREATE OR REPLACE TRIGGER k_tr_ins_address AFTER INSERT ON k_addresses FOR EACH ROW
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR2(70);

BEGIN
  IF :new.bo_active=1 THEN
    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=:new.gu_address;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    IF LENGTH(:new.nm_company)=0 THEN
      NmLegal := NULL;
    ELSE
      NmLegal := :new.nm_company;
    END IF;
    
    INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES
    				 (:new.gu_address,:new.ix_address,:new.gu_workarea,:new.dt_created,:new.dt_modified,:new.gu_user,NmLegal,:new.tp_location,:new.tp_street,:new.nm_street,:new.nu_street,:new.tx_addr1,:new.tx_addr2,NVL(:new.tx_addr1,'')||CHR(10)||NVL(:new.tx_addr2,''),:new.id_country,:new.nm_country,:new.id_state,:new.nm_state,:new.mn_city,:new.zipcode,:new.work_phone,:new.direct_phone,:new.home_phone,:new.mov_phone,:new.fax_phone,:new.other_phone,:new.po_box,:new.tx_email,:new.url_addr,:new.contact_person,:new.tx_salutation,:new.tx_remarks);
END k_tr_ins_address;
GO;

CREATE OR REPLACE TRIGGER k_tr_upd_address AFTER UPDATE ON k_addresses FOR EACH ROW
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR2(70);
  
BEGIN
  IF :new.bo_active=1 THEN
    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=:new.gu_address;

    IF LENGTH(:new.nm_company)=0 THEN
      NmLegal := NULL;
    ELSE
      NmLegal := :new.nm_company;
    END IF;

    UPDATE k_member_address SET ix_address=:new.ix_address,gu_workarea=:new.gu_workarea,dt_created=:new.dt_created,dt_modified=:new.dt_modified,gu_writer=:new.gu_user,tp_location=:new.tp_location,tp_street=:new.tp_street,nm_street=:new.nm_street,nu_street=:new.nu_street,tx_addr1=:new.tx_addr1,tx_addr2=:new.tx_addr2,full_addr=NVL(:new.tx_addr1,'')||CHR(10)||NVL(:new.tx_addr2,''),id_country=:new.id_country,nm_country=:new.nm_country,id_state=:new.id_state,nm_state=:new.nm_state,mn_city=:new.mn_city,zipcode=:new.zipcode,work_phone=:new.work_phone,direct_phone=:new.direct_phone,home_phone=:new.home_phone,mov_phone=:new.mov_phone,fax_phone=:new.fax_phone,other_phone=:new.other_phone,po_box=:new.po_box,tx_email=:new.tx_email,url_addr=:new.url_addr,contact_person=:new.contact_person,tx_salutation=:new.tx_salutation,tx_remarks=:new.tx_remarks
    WHERE gu_address=:new.gu_address;
  ELSE
    DELETE FROM k_member_address WHERE gu_address=:new.gu_address;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES (:new.gu_address,:new.ix_address,:new.gu_workarea,:new.dt_created,:new.dt_modified,:new.gu_user,:new.nm_company,:new.tp_location,:new.tp_street,:new.nm_street,:new.nu_street,:new.tx_addr1,:new.tx_addr2,NVL(:new.tx_addr1,'')||CHR(10)||NVL(:new.tx_addr2,''),:new.id_country,:new.nm_country,:new.id_state,:new.nm_state,:new.mn_city,:new.zipcode,:new.work_phone,:new.direct_phone,:new.home_phone,:new.mov_phone,:new.fax_phone,:new.other_phone,:new.po_box,:new.tx_email,:new.url_addr,:new.contact_person,:new.tx_salutation,:new.tx_remarks);
END k_tr_upd_address;
GO;

CREATE OR REPLACE TRIGGER k_tr_ins_comp_addr AFTER INSERT ON k_x_company_addr FOR EACH ROW
DECLARE

  GuCompany     CHAR(32);
  NmLegal       VARCHAR2(70);
  NmCommercial  VARCHAR2(70);
  IdLegal       VARCHAR2(16);
  IdSector      VARCHAR2(16);
  IdStatus      VARCHAR2(30);
  IdRef         VARCHAR2(50);
  TpCompany     VARCHAR2(30);
  NuEmployees  	NUMBER;
  ImRevenue     NUMBER;
  GuSalesMan    CHAR(32);
  TxFranchise   VARCHAR2(100);
  GuGeoZone     CHAR(32);
  DeCompany	    VARCHAR2(254);

BEGIN
  SELECT gu_company,nm_legal,id_legal,nm_commercial,id_sector,id_status,id_ref,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,de_company INTO GuCompany,NmLegal,IdLegal,NmCommercial,IdSector,IdStatus,IdRef,TpCompany,NuEmployees,ImRevenue,GuSalesMan,TxFranchise,GuGeoZone,DeCompany FROM k_companies WHERE gu_company=:new.gu_company;

  UPDATE k_member_address SET gu_company=GuCompany,nm_legal=NmLegal,id_legal=IdLegal,nm_commercial=NmCommercial,id_sector=IdSector,id_ref=IdRef,id_status=IdStatus,tp_company=TpCompany,nu_employees=NuEmployees,im_revenue=ImRevenue,gu_sales_man=GuSalesMan,tx_franchise=TxFranchise,gu_geozone=GuGeoZone,tx_comments=DeCompany WHERE gu_address=:new.gu_address;

END k_tr_ins_comp_addr;
GO;

CREATE OR REPLACE TRIGGER k_tr_ins_cont_addr AFTER INSERT ON k_x_contact_addr FOR EACH ROW
DECLARE
  GuContact     CHAR(32);
  GuCompany     CHAR(32);
  GuWorkArea    CHAR(32);
  TxName        VARCHAR2(100);
  TxSurname     VARCHAR2(100);
  DeTitle       VARCHAR2(70);
  TrTitle       VARCHAR2(50);
  DtBirth	DATE;
  SnPassport    VARCHAR2(16);
  IdGender      CHAR(1);
  NyAge         NUMBER;
  IdNationality CHAR(3);
  TxDept        VARCHAR2(70);
  TxDivision    VARCHAR2(70);
  TxComments	VARCHAR2(254);
  UrlLinkedIn	VARCHAR2(254);
  UrlFacebook	VARCHAR2(254);
  UrlTwitter    VARCHAR2(254);
  
BEGIN
  SELECT gu_contact,gu_company,gu_workarea,tx_name,tx_surname,de_title,dt_birth,sn_passport,id_gender,ny_age,id_nationality,tx_dept,tx_division,tx_comments,url_linkedin,url_facebook,url_twitter
  INTO   GuContact,GuCompany,GuWorkArea,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,IdNationality,TxDept,TxDivision,TxComments,UrlLinkedIn,UrlFacebook,UrlTwitter FROM k_contacts 
  WHERE gu_contact=:new.gu_contact;

  IF LENGTH(TxName)=0 THEN TxName:=NULL; END IF;
  IF LENGTH(TxSurname)=0 THEN TxSurname:=NULL; END IF;

  IF DeTitle IS NOT NULL THEN
    SELECT tr_es INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section='de_title' AND vl_lookup=DeTitle;
  ELSE
    TrTitle := NULL;
  END IF;
  
  UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,
                              id_gender=IdGender,ny_age=NyAge,id_nationality=IdNationality,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
                              WHERE gu_address=:new.gu_address;
EXCEPTION
  WHEN NO_DATA_FOUND THEN

    UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,
                                id_gender=IdGender,ny_age=NyAge,id_nationality=IdNationality,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments,url_linkedin=UrlLinkedIn,url_facebook=UrlFacebook,url_twitter=UrlTwitter
                                WHERE gu_address=:new.gu_address;
END k_tr_ins_cont_addr;
GO;

CREATE OR REPLACE TRIGGER k_tr_upd_comp AFTER UPDATE ON k_companies FOR EACH ROW
BEGIN
  UPDATE k_member_address SET nm_legal=:new.nm_legal,id_legal=:new.id_legal,nm_commercial=:new.nm_commercial,id_sector=:new.id_sector,id_ref=:new.id_ref,id_status=:new.id_status,tp_company=:new.tp_company,nu_employees=:new.nu_employees,im_revenue=:new.im_revenue,gu_sales_man=:new.gu_sales_man,tx_franchise=:new.tx_franchise,gu_geozone=:new.gu_geozone WHERE gu_company=:new.gu_company;
END k_tr_upd_comp;
GO;

CREATE OR REPLACE TRIGGER k_tr_upd_cont AFTER UPDATE ON k_contacts FOR EACH ROW
DECLARE
  TxName        VARCHAR2(100);
  TxSurname     VARCHAR2(100);
  DeTitle       VARCHAR2(70);
  TrTitle       VARCHAR2(50);
BEGIN

  IF LENGTH(:new.tx_name)=0 THEN TxName:=NULL; ELSE TxName:=:new.tx_name; END IF;
  IF LENGTH(:new.tx_surname)=0 THEN TxSurname:=NULL; ELSE TxSurname:=:new.tx_surname; END IF;
  DeTitle:=:new.de_title;

  IF DeTitle IS NOT NULL THEN
    SELECT tr_es INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=:new.gu_workarea AND id_section='de_title' AND vl_lookup=DeTitle;
  ELSE
    TrTitle := NULL;
  END IF;
  
  UPDATE k_member_address SET gu_company=:new.gu_company,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=TrTitle,dt_birth=:new.dt_birth,sn_passport=:new.sn_passport,
                              id_gender=:new.id_gender,ny_age=:new.ny_age,id_nationality=:new.id_nationality,tx_dept=:new.tx_dept,tx_division=:new.tx_division,tx_comments=:new.tx_comments,
                              url_linkedin=:new.url_linkedin,url_facebook=:new.url_facebook,url_twitter=:new.url_twitter WHERE gu_contact=:new.gu_contact;
EXCEPTION
  WHEN NO_DATA_FOUND THEN

    UPDATE k_member_address SET gu_company=:new.gu_company,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=NULL,dt_birth=:new.dt_birth,sn_passport=:new.sn_passport,
                                id_gender=:new.id_gender,ny_age=:new.ny_age,id_nationality=:new.id_nationality,tx_dept=:new.tx_dept,tx_division=:new.tx_division,tx_comments=:new.tx_comments,
                                url_linkedin=:new.url_linkedin,url_facebook=:new.url_facebook,url_twitter=:new.url_twitter WHERE gu_contact=:new.gu_contact;
END k_tr_upd_cont;
GO;