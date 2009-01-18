ALTER TABLE k_version ADD dt_created DATE NULL
GO;
ALTER TABLE k_version ADD dt_modified DATE NULL
GO;
ALTER TABLE k_version ADD bo_register NUMBER(5) NULL
GO;
ALTER TABLE k_version ADD gu_support CHAR(32) NULL
GO;
ALTER TABLE k_version ADD gu_contact CHAR(32) NULL
GO;
ALTER TABLE k_version ADD tx_name VARCHAR2(100) NULL
GO;
ALTER TABLE k_version ADD tx_surname VARCHAR2(100) NULL
GO;
ALTER TABLE k_version ADD nu_employees NUMBER(28) NULL
GO;
ALTER TABLE k_version ADD nm_company VARCHAR2(70) NULL
GO;
ALTER TABLE k_version ADD id_sector VARCHAR2(16) NULL
GO;
ALTER TABLE k_version ADD id_country CHAR(3) NULL
GO;
ALTER TABLE k_version ADD nm_state VARCHAR2(30) NULL
GO;
ALTER TABLE k_version ADD mn_city VARCHAR2(50) NULL
GO;
ALTER TABLE k_version ADD zipcode VARCHAR2(30) NULL
GO;
ALTER TABLE k_version ADD work_phone VARCHAR2(16) NULL
GO;
ALTER TABLE k_version ADD tx_email VARCHAR2(70) NULL
GO;
UPDATE k_version SET vs_stamp='4.0.0'
GO;

CREATE SEQUENCE seq_k_msg_votes INCREMENT BY 1 START WITH 1
GO;

ALTER TABLE k_newsmsgs ADD nu_votes NUMBER(11) DEFAULT 0
GO;

CREATE TABLE k_newsmsg_vote (
  gu_msg     CHAR(32)      NOT NULL,
  pg_vote    NUMBER(11)    NOT NULL,
  dt_published DATE        DEFAULT SYSDATE,
  od_score   NUMBER(11)    NULL,
  ip_addr    VARCHAR2(254) NULL,
  nm_author  VARCHAR2(200) NULL,
  gu_writer  CHAR(32)      NULL,
  tx_email   VARCHAR2(100) NULL,
  tx_vote    VARCHAR2(254) NULL,
  CONSTRAINT pk_newsmsg_vote PRIMARY KEY (gu_msg,pg_vote)
)
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_newsgroup (IdNewsGroup CHAR) IS
BEGIN
  DELETE k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE k_newsgroup_subscriptions WHERE gu_newsgrp=IdNewsGroup;
  DELETE k_newsgroups WHERE gu_newsgrp=IdNewsGroup;
  DELETE k_x_cat_objs WHERE gu_category=IdNewsGroup;
  k_sp_del_category (IdNewsGroup);
END k_sp_del_newsgroup;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_newsmsg (IdNewsMsg CHAR) IS
  IdChild CHAR(32);
  CURSOR childs(id CHAR) IS SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=id;
BEGIN
  OPEN childs(IdNewsMsg);
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN childs%NOTFOUND;
      k_sp_del_newsmsg (IdChild);
    END LOOP;
  CLOSE childs;
  DELETE k_x_cat_objs WHERE gu_object=IdNewsMsg;
  DELETE k_newsmsg_vote WHERE gu_msg=IdNewsMsg;
  DELETE k_newsmsgs WHERE gu_msg=IdNewsMsg;
END k_sp_del_newsmsg;
GO;

CREATE TABLE k_distances_cache
(
  lo_from   VARCHAR2(254) NOT NULL,
  lo_to     VARCHAR2(254) NOT NULL,
  nu_km     FLOAT         NOT NULL,
  id_locale VARCHAR2(8)   NOT NULL,
  coord_x   FLOAT NULL,
  coord_y   FLOAT NULL,  
  CONSTRAINT pk_distances_cache PRIMARY KEY (lo_from,lo_to)  
)
GO;

CREATE TABLE k_working_time
(
gu_calendar    CHAR(32)   NOT NULL,
gu_workarea    CHAR(32)   NOT NULL,
id_domain      NUMBER(11) NOT NULL,
nm_calendar    VARCHAR2(100) NOT NULL,
dt_day         CHAR(8)      NOT NULL,
bo_working_day NUMBER(1)    NOT NULL,
ti_start1      CHAR(2)      NULL,
ti_end1        CHAR(2)      NULL,
ti_start2      CHAR(2)      NULL,
ti_end2        CHAR(2)      NULL,
gu_user        CHAR(32)     NULL,
gu_acl_group   CHAR(32)     NULL,
gu_geozone     CHAR(32)     NULL,
id_country     CHAR(3)      NULL,
id_state       CHAR(9)      NULL,
de_day         VARCHAR2(50) NULL,

CONSTRAINT pk_working_time PRIMARY KEY (gu_calendar)
)
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_group (IdGroup CHAR) IS
BEGIN
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=IdGroup;
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=IdGroup;
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=IdGroup;
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=IdGroup;
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=IdGroup;

  DELETE k_working_time WHERE gu_acl_group=IdGroup;
  DELETE k_x_group_company WHERE gu_acl_group=IdGroup;
  DELETE k_x_group_contact WHERE gu_acl_group=IdGroup;
  DELETE k_x_group_user WHERE gu_acl_group=IdGroup;
  DELETE k_x_cat_group_acl WHERE gu_acl_group=IdGroup;
  DELETE k_acl_groups WHERE gu_acl_group=IdGroup;
END k_sp_del_group;
GO;

ALTER TABLE k_meetings ADD gu_address CHAR(32) NULL
GO;

ALTER TABLE k_meetings ADD CONSTRAINT f4_meeting FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address)
GO;

ALTER TABLE k_meetings ADD pr_cost FLOAT NULL
GO;

BEGIN
  SELECT gu_term INTO GuTerm FROM _thesauri WHERE id_domain=IdDomain AND (tx_term=TxTerm OR tx_term2=TxTerm) AND ROWNUM=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    GuTerm:=NULL;
END k_get_term_from_text;
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

CREATE TABLE k_lu_currencies_history
(
    alpha_code_from CHAR(3)   NOT NULL,
    alpha_code_to   CHAR(3)   NOT NULL,
    nu_conversion   NUMBER(20,8) NOT NULL,
    dt_stamp        DATE DEFAULT SYSDATE,
    CONSTRAINT pk_lu_currencies_history PRIMARY KEY (alpha_code_from,alpha_code_to,dt_stamp)
)
GO;

CREATE TABLE k_prod_fares_lookup
(
gu_owner   CHAR(32)     NOT NULL,
id_section VARCHAR2(30) NOT NULL,
pg_lookup  NUMBER(11)   NOT NULL,
vl_lookup  VARCHAR2(255)    NULL,
tr_es      VARCHAR2(50)     NULL,
tr_en      VARCHAR2(50)     NULL,
tr_de      VARCHAR2(50)     NULL,
tr_it      VARCHAR2(50)     NULL,
tr_fr      VARCHAR2(50)     NULL,
tr_pt      VARCHAR2(50)     NULL,
tr_ca      VARCHAR2(50)     NULL,
tr_eu      VARCHAR2(50)     NULL,
tr_ja      VARCHAR2(50)     NULL,
tr_cn      VARCHAR2(50)     NULL,
tr_tw      VARCHAR2(50)     NULL,
tr_fi      VARCHAR2(50)     NULL,
tr_ru      VARCHAR2(50)     NULL,
tr_nl      VARCHAR2(50)     NULL,
tr_th      VARCHAR2(50)     NULL,
tr_cs      VARCHAR2(50)     NULL,
tr_uk      VARCHAR2(50)     NULL,
tr_no      VARCHAR2(50)     NULL,
tr_sk      VARCHAR2(50)     NULL,
tr_pl      VARCHAR2(50)     NULL,

CONSTRAINT pk_prod_fares_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_prod_fares_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

ALTER TABLE k_companies ADD id_fare VARCHAR2(32) NULL
GO;
ALTER TABLE k_contacts ADD id_fare VARCHAR2(32) NULL
GO;

DROP VIEW v_duty_resource
GO;
DROP VIEW v_duty_project
GO;
DROP VIEW v_duty_company
GO;

CREATE VIEW v_duty_resource AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty, u.tx_nickname AS nm_resource
FROM k_projects p, k_duties b, k_x_duty_resource x, k_users u
WHERE b.gu_duty=x.gu_duty(+) AND p.gu_project=b.gu_project AND x.nm_resource=u.gu_user
UNION
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource
FROM k_projects p, k_duties b, k_x_duty_resource x
WHERE b.gu_duty=x.gu_duty(+) AND p.gu_project=b.gu_project AND NOT EXISTS (SELECT gu_user FROM k_users WHERE gu_user=x.nm_resource)
WITH READ ONLY
GO;

CREATE VIEW v_duty_project AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty
FROM k_duties b, k_projects p
WHERE p.gu_project=b.gu_project
WITH READ ONLY
GO;

CREATE VIEW v_duty_company AS
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,c.gu_company,c.nm_legal,c.id_legal
FROM k_projects p, k_companies c, k_duties b, k_x_duty_resource x
WHERE b.gu_duty=x.gu_duty(+) AND p.gu_project=b.gu_project AND p.gu_company=c.gu_company)
UNION
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,NULL AS gu_company,NULL AS nm_legal, NULL AS id_legal
FROM k_projects p, k_duties b, k_x_duty_resource x
WHERE b.gu_duty=x.gu_duty(+) AND p.gu_project=b.gu_project AND p.gu_company IS NULL)
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

INSERT INTO k_apps (id_app,nm_app) VALUES (23,'Wiki')
GO;

INSERT INTO k_apps (id_app,nm_app) VALUES (24,'Passwords Manager')
GO;

ALTER TABLE k_companies ADD bo_restricted NUMBER(5) DEFAULT 0
GO;

ALTER TABLE k_contacts ADD bo_restricted NUMBER(5) DEFAULT 0
GO;

ALTER TABLE k_contacts ADD gu_sales_man CHAR(32) NULL
GO;

CREATE TABLE k_x_group_company
(
gu_acl_group CHAR(32) NOT NULL,
gu_company   CHAR(32) NOT NULL,
dt_created   DATE DEFAULT SYSDATE,

CONSTRAINT pk_x_group_company PRIMARY KEY (gu_acl_group,gu_company),
CONSTRAINT f1_x_group_company FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups(gu_acl_group),
CONSTRAINT f2_x_group_company FOREIGN KEY (gu_company) REFERENCES k_companies(gu_company)
)
GO;

CREATE TABLE k_x_group_contact
(
gu_acl_group CHAR(32) NOT NULL,
gu_contact   CHAR(32) NOT NULL,
dt_created   DATE DEFAULT SYSDATE,

CONSTRAINT pk_x_group_contact PRIMARY KEY (gu_acl_group,gu_contact),
CONSTRAINT f1_x_group_contact FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups(gu_acl_group),
CONSTRAINT f2_x_group_contact FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact)
)
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_company (CompanyId CHAR) IS
  TYPE GUIDS IS TABLE OF k_addresses.gu_address%TYPE;
  TYPE BANKS IS TABLE OF k_bank_accounts.nu_bank_acc%TYPE;

  k_tmp_del_addr GUIDS := GUIDS();
  k_tmp_del_bank BANKS := BANKS();

  GuWorkArea CHAR(32);

BEGIN
  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=CompanyId);
  DELETE k_welcome_packs WHERE gu_company=CompanyId;
  DELETE k_member_address WHERE gu_company=CompanyId;
  DELETE k_companies_recent WHERE gu_company=CompanyId;
  DELETE k_x_group_company WHERE gu_company=CompanyId;
  
  SELECT gu_workarea INTO GuWorkArea FROM k_companies WHERE gu_company=CompanyId;

  /* Borrar las direcciones de la compañia */
  FOR addr IN ( SELECT gu_address FROM k_x_company_addr WHERE gu_company=CompanyId) LOOP
    k_tmp_del_addr.extend;
    k_tmp_del_addr(k_tmp_del_addr.count) := addr.gu_address;
  END LOOP;

  DELETE k_x_company_addr WHERE gu_company=CompanyId;

  FOR a IN 1..k_tmp_del_addr.COUNT LOOP
    DELETE k_addresses WHERE gu_address=k_tmp_del_addr(a);
  END LOOP;

  /* Borrar las cuentas bancarias de la compañia */

  FOR bank IN ( SELECT nu_bank_acc FROM k_x_company_bank WHERE gu_company=CompanyId) LOOP
    k_tmp_del_bank.extend;
    k_tmp_del_bank(k_tmp_del_bank.count) := bank.nu_bank_acc;
  END LOOP;

  DELETE k_x_company_bank WHERE gu_company=CompanyId;

  FOR a IN 1..k_tmp_del_bank.COUNT LOOP
    DELETE k_bank_accounts WHERE nu_bank_acc=k_tmp_del_bank(a);
  END LOOP;

  /* Borrar las oportunidades */
  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE k_oportunities WHERE gu_company=CompanyId;

  /* Borrar las referencias de PageSets */
  
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=CompanyId;
  /* Borrar el enlace con categorías */
  
  DELETE k_x_cat_objs WHERE gu_object=CompanyId AND id_class=91;

  DELETE k_x_company_prods WHERE gu_company=CompanyId;
  DELETE k_companies_attrs WHERE gu_object=CompanyId;
  DELETE k_companies WHERE gu_company=CompanyId;
END k_sp_del_company;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_contact (ContactId CHAR) IS
  TYPE GUIDS IS TABLE OF k_addresses.gu_address%TYPE;
  TYPE BANKS IS TABLE OF k_bank_accounts.nu_bank_acc%TYPE;

  k_tmp_del_addr GUIDS := GUIDS();
  k_tmp_del_bank BANKS := BANKS();

  GuWorkArea CHAR(32);

BEGIN
  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=ContactId);
  DELETE k_welcome_packs WHERE gu_contact=ContactId;
  DELETE k_member_address WHERE gu_contact=ContactId;
  DELETE k_contacts_recent WHERE gu_contact=ContactId;
  DELETE k_x_group_contact WHERE gu_contact=ContactId;

  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=ContactId;

  FOR addr IN ( SELECT gu_address FROM k_x_contact_addr WHERE gu_contact=ContactId) LOOP
    k_tmp_del_addr.extend;
    k_tmp_del_addr(k_tmp_del_addr.count) := addr.gu_address;
  END LOOP;

  DELETE k_x_contact_addr WHERE gu_contact=ContactId;

  FOR a IN 1..k_tmp_del_addr.COUNT LOOP
    DELETE k_addresses WHERE gu_address=k_tmp_del_addr(a);
  END LOOP;

  /* Borrar las cuentas bancarias del contacto */

  FOR bank IN ( SELECT nu_bank_acc FROM k_x_contact_bank WHERE gu_contact=ContactId) LOOP
    k_tmp_del_bank.extend;
    k_tmp_del_bank(k_tmp_del_bank.count) := bank.nu_bank_acc;
  END LOOP;

  DELETE k_x_contact_bank WHERE gu_contact=ContactId;

  FOR a IN 1..k_tmp_del_bank.COUNT LOOP
    DELETE k_bank_accounts WHERE nu_bank_acc=k_tmp_del_bank(a) AND gu_workarea=GuWorkArea;
  END LOOP;

  /* Los productos que contienen la referencia a los ficheros adjuntos no se borran desde aquí,
     hay que llamar al método Java de borrado de Product para eliminar también los ficheros físicos,
     de este modo la foreign key de la base de datos actua como protección para que no se queden ficheros basura */

  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=ContactId);
  DELETE k_oportunities WHERE gu_contact=ContactId;

  DELETE k_x_cat_objs WHERE gu_object=ContactId AND id_class=90;

  DELETE k_x_contact_prods WHERE gu_contact=ContactId;
  DELETE k_contacts_attrs WHERE gu_object=ContactId;
  DELETE k_contact_notes WHERE gu_contact=ContactId;
  DELETE k_contacts WHERE gu_contact=ContactId;
END k_sp_del_contact;
GO;

DROP VIEW v_attach_locat
GO;

DROP VIEW v_contact_list
GO;

DROP VIEW v_contact_address_title
GO;

DROP VIEW v_contact_address
GO;

DROP VIEW v_contact_company_all
GO;

DROP VIEW v_contact_company
GO;

DROP VIEW v_active_contact_address
GO;

DROP VIEW v_contact_titles
GO;

DROP VIEW v_company_address
GO;

DROP VIEW v_active_company_address
GO;

CREATE VIEW v_active_company_address AS
SELECT x.gu_company,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks FROM k_addresses a, k_x_company_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
WITH READ ONLY
GO;

CREATE VIEW v_company_address AS
SELECT c.gu_workarea,c.gu_company,c.nm_legal,c.nm_commercial,c.dt_modified,c.id_legal,c.id_ref,c.id_sector,c.id_status,c.tp_company,c.de_company,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.id_ref AS id_addrref,b.tx_remarks, c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.tx_franchise
FROM k_companies c, v_active_company_address b WHERE c.gu_company=b.gu_company(+)
WITH READ ONLY
GO;

CREATE VIEW v_contact_titles AS
SELECT vl_lookup,gu_owner,tr_es,tr_en,tr_fr,tr_de,tr_it,tr_pt,tr_ja,tr_cn,tr_tw,tr_ca,tr_eu FROM k_contacts_lookup WHERE id_section='de_title'
WITH READ ONLY
GO;

CREATE VIEW v_active_contact_address AS
SELECT x.gu_contact,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.tx_remarks FROM k_addresses a, k_x_contact_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
WITH READ ONLY
GO;

CREATE VIEW v_contact_company AS
SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,y.gu_company,y.nm_legal,y.id_sector,y.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c, k_companies y WHERE c.gu_company=y.gu_company
WITH READ ONLY
GO;

CREATE VIEW v_contact_company_all AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL AS gu_company,NULL AS nm_legal,NULL AS id_sector,NULL AS tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c WHERE c.gu_company IS NULL)
WITH READ ONLY
GO;

CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c, v_active_contact_address b, v_contact_titles l
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title=l.vl_lookup AND c.gu_workarea=l.gu_owner)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c, v_active_contact_address b, v_contact_titles l
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title IS NULL AND c.gu_workarea=l.gu_owner)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c, v_active_contact_address b, v_contact_titles l
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title=l.vl_lookup AND c.gu_workarea=l.gu_owner AND c.gu_company IS NULL)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,NULL AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c, v_active_contact_address b
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title IS NULL AND c.gu_company IS NULL)
WITH READ ONLY
GO;

CREATE VIEW v_contact_address_title AS
SELECT b.*,l.gu_owner,l.id_section,l.pg_lookup,l.vl_lookup,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu FROM v_contact_address b, k_contacts_lookup l WHERE b.de_title=l.vl_lookup(+)
WITH READ ONLY
GO;

CREATE VIEW v_contact_list AS
(SELECT c.gu_contact,NVL(c.tx_surname,'') || ', ' || NVL(c.tx_name,'') AS full_name,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c, k_companies d, k_contacts_lookup l
WHERE c.gu_company=d.gu_company(+) AND c.de_title=l.vl_lookup AND c.gu_workarea=l.gu_owner AND l.id_section='de_title')
UNION
(SELECT c.gu_contact,NVL(c.tx_surname,'') || ', ' || NVL(c.tx_name,'') AS full_name,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, c.gu_workarea, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c, k_companies d
WHERE c.gu_company=d.gu_company(+) AND c.de_title IS NULL)
WITH READ ONLY
GO;

CREATE VIEW v_attach_locat AS
SELECT p.gu_product, p.nm_product, p.de_product, c.gu_contact, c.pg_product, c.dt_created, l.dt_modified, l.dt_uploaded, l.gu_location, l.id_cont_type, l.id_prod_type, l.len_file, l.xprotocol, l.xhost, l.xport, l.xpath, l.xfile, l.xoriginalfile, l.xanchor, l.status, l.vs_stamp, l.tx_email, l.tag_prod_locat
FROM k_contact_attachs c, k_products p, k_prod_locats l
WHERE c.gu_product=p.gu_product AND c.gu_product=l.gu_product
WITH READ ONLY
GO;

CREATE VIEW v_supplier_address AS SELECT s.gu_supplier,s.dt_created,s.nm_legal,s.gu_workarea,s.nm_commercial,s.gu_address,s.dt_modified,s.id_legal,s.id_status,s.id_ref,s.tp_supplier,s.gu_geozone,s.de_supplier,a.ix_address,a.bo_active,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.tx_email_alt,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.tx_remarks FROM k_suppliers s, k_addresses a WHERE s.gu_address=a.gu_address
GO;

CREATE TABLE k_events (
    id_domain   NUMBER(11) NOT NULL,
    id_event    VARCHAR2(64) NOT NULL,
    dt_created  DATE DEFAULT SYSDATE,
    dt_modified DATE DEFAULT SYSDATE,
    bo_active   NUMBER(2) DEFAULT 1,
    gu_writer   CHAR(32) NOT NULL,
    id_command  CHAR(4)  NOT NULL,
    id_app      NUMBER(11)  NOT NULL,
    gu_workarea CHAR(32) NULL,
    de_event    VARCHAR2(254) NULL,
    tx_parameters VARCHAR2(2000) NULL,
    
    CONSTRAINT pk_events PRIMARY KEY (id_domain,id_event)
)
GO;

CREATE OR REPLACE PROCEDURE k_is_workarea_anyrole (IdWorkArea CHAR, IdUser CHAR, IsAny OUT NUMBER) IS
  IdGroup CHAR(32);
BEGIN
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE (x.gu_acl_group=w.gu_admins OR x.gu_acl_group=w.gu_powusers OR x.gu_acl_group=w.gu_users OR x.gu_acl_group=w.gu_guests OR x.gu_acl_group=w.gu_other) AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea AND ROWNUM=1;
  IsAny:=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IsAny:=0;
END k_is_workarea_admin;
GO;

ALTER TABLE k_duties ADD gu_writer CHAR(32) NULL
GO;

ALTER TABLE k_duties ADD tp_duty VARCHAR2(30) NULL
GO;

ALTER TABLE k_workareas ADD id_locale VARCHAR2(5) NULL
GO;

ALTER TABLE k_workareas ADD tx_date_format VARCHAR2(30) DEFAULT 'yyyy-MM-dd'
GO;

ALTER TABLE k_workareas ADD tx_number_format VARCHAR2(30)  DEFAULT '#0.00'
GO;

ALTER TABLE k_workareas ADD bo_dup_id_docs NUMBER(5) DEFAULT 1
GO;

ALTER TABLE k_workareas ADD bo_cnt_autoref NUMBER(5) DEFAULT 0
GO;

ALTER TABLE k_warehouses ADD gu_address CHAR(32) NULL
GO;

ALTER TABLE k_sale_points ADD gu_address CHAR(32) NULL
GO;

CREATE VIEW v_sale_points AS
SELECT
s.gu_sale_point,s.gu_workarea,s.nm_sale_point,s.dt_created,s.bo_active,a.gu_address,a.ix_address,a.dt_modified,a.gu_user,a.tp_location,a.nm_company	,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city	,a.zipcode	,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.tx_email_alt,a.url_addr,a.coord_x	,a.coord_y,a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks
FROM k_sale_points s, k_addresses a
WHERE s.gu_address=a.gu_address
GO;

CREATE VIEW v_warehouses AS
SELECT
s.gu_warehouse,s.gu_workarea,s.nm_warehouse,s.dt_created,s.bo_active,a.gu_address,a.ix_address,a.dt_modified,a.gu_user,a.tp_location,a.nm_company	,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city	,a.zipcode	,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.tx_email_alt,a.url_addr,a.coord_x	,a.coord_y,a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks
FROM k_warehouses s, k_addresses a
WHERE s.gu_address=a.gu_address
GO;

ALTER TABLE k_oportunities ADD gu_campaign CHAR(32) NULL
GO;

CREATE TABLE k_invoice_payments (
  gu_invoice     CHAR(32)      NOT NULL,
  pg_payment     INTEGER       NOT NULL,
  dt_payment     DATE          NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  im_paid        NUMBER(14,4)  NOT NULL,
  tp_billing     CHAR(1)       NULL,
  nm_client	     VARCHAR2(200) NULL,
  tx_comments    VARCHAR2(254) NULL,

  CONSTRAINT pk_invoice_payments PRIMARY KEY(gu_invoice,pg_payment)
)
GO;

CREATE TABLE k_project_snapshots
(
gu_snapshot CHAR(32)      NOT NULL,
gu_project  CHAR(32)      NOT NULL,
gu_writer   CHAR(32)      NOT NULL,
dt_created  DATE          DEFAULT SYSDATE,
tl_snapshot VARCHAR2(100) NOT NULL,
tx_snapshot LONG          NOT NULL,
CONSTRAINT pk_project_snapshots PRIMARY KEY (gu_snapshot),
CONSTRAINT f1_project_snapshots FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

CREATE TABLE k_duties_workreports
(
gu_workreport CHAR(32)      NOT NULL,
tl_workreport VARCHAR2(200) NOT NULL,
gu_writer     CHAR(32)      NOT NULL,
dt_created    DATE          DEFAULT SYSDATE,
gu_project    CHAR(32)      NULL,
de_workreport VARCHAR2(2000) NULL,
tx_workreport LONG          NOT NULL,
CONSTRAINT pk_duties_workreports PRIMARY KEY (gu_workreport),
CONSTRAINT f1_duties_workreports FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_project (ProjId CHAR) IS
  chldid CHAR(32);
  CURSOR childs IS SELECT gu_project FROM k_projects WHERE id_parent=ProjId AND id_parent<>gu_project;

BEGIN
  /* Borrar primero los proyectos hijos */
  FOR chld IN childs LOOP
    k_sp_del_project(chld.gu_project);
  END LOOP;

  DELETE k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId);
  DELETE k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId);
  DELETE k_duties WHERE gu_project=ProjId;

  DELETE k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ProjId);
  DELETE k_bugs WHERE gu_project=ProjId;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=ProjId;

  DELETE k_duties_workreports WHERE gu_project=ProjId;
  DELETE k_project_snapshots WHERE gu_project=ProjId;
  DELETE k_project_costs WHERE gu_project=ProjId;
  DELETE k_project_expand WHERE gu_project=ProjId;
  DELETE k_projects WHERE gu_project=ProjId;
END k_sp_del_project;
GO;

ALTER TABLE k_phone_calls ADD gu_oportunity CHAR(32) NULL
GO;

ALTER TABLE k_oportunities ADD lv_interest NUMBER(5) NULL
GO;

