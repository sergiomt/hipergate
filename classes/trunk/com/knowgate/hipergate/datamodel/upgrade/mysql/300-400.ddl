ALTER TABLE k_version ADD dt_created   TIMESTAMP    NULL;
GO;
ALTER TABLE k_version ADD dt_modified  TIMESTAMP    NULL;
GO;
ALTER TABLE k_version ADD bo_register  SMALLINT     NULL;
GO;
ALTER TABLE k_version ADD gu_support   CHAR(32)     NULL;
GO;
ALTER TABLE k_version ADD gu_contact   CHAR(32)     NULL;
GO;
ALTER TABLE k_version ADD tx_name      VARCHAR(100) NULL;
GO;
ALTER TABLE k_version ADD tx_surname   VARCHAR(100) NULL;
GO;
ALTER TABLE k_version ADD nu_employees INTEGER      NULL;
GO;
ALTER TABLE k_version ADD nm_company   VARCHAR(70)  NULL;
GO;
ALTER TABLE k_version ADD id_sector    VARCHAR(16)  NULL;
GO;
ALTER TABLE k_version ADD id_country   CHAR(3)      NULL;
GO;
ALTER TABLE k_version ADD nm_state     VARCHAR(30)  NULL;
GO;
ALTER TABLE k_version ADD mn_city	   VARCHAR(50)  NULL;
GO;
ALTER TABLE k_version ADD zipcode	   VARCHAR(30)  NULL;
GO;
ALTER TABLE k_version ADD work_phone   VARCHAR(16)  NULL;
GO;
ALTER TABLE k_version ADD tx_email     VARCHAR(70)  NULL;
GO;
UPDATE k_version SET vs_stamp='4.0.0'
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_msg_votes', 1, 2147483647, 1, 1)
GO;

ALTER TABLE k_newsmsgs ADD nu_votes INTEGER DEFAULT 0
GO;

CREATE TABLE k_newsmsg_vote (
  gu_msg     CHAR(32)     NOT NULL,
  pg_vote    INTEGER      NOT NULL,
  dt_published TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  od_score   INTEGER      NULL,
  ip_addr    VARCHAR(254) NULL,
  nm_author  VARCHAR(200) NULL,
  gu_writer  CHAR(32)     NULL,
  tx_email   VARCHAR(100) NULL,
  tx_vote    VARCHAR(254) NULL,
  CONSTRAINT pk_newsmsg_vote PRIMARY KEY (gu_msg,pg_vote)
)
GO;

DROP PROCEDURE k_sp_del_newsgroup
GO;

CREATE PROCEDURE k_sp_del_newsgroup (IdNewsGroup CHAR(32))
BEGIN
  DELETE FROM k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE FROM k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE FROM k_newsgroup_subscriptions WHERE gu_newsgrp=IdNewsGroup;
  DELETE FROM k_newsgroups WHERE gu_newsgrp=IdNewsGroup;
  DELETE FROM k_x_cat_objs WHERE gu_category=IdNewsGroup;
  CALL k_sp_del_category (IdNewsGroup);
END
GO;

DROP PROCEDURE k_sp_del_newsmsg
GO;

CREATE PROCEDURE k_sp_del_newsmsg (IdNewsMsg CHAR(32))
BEGIN
  DECLARE IdChild CHAR(32);
  DECLARE Done INT DEFAULT 0;
  DECLARE childs CURSOR FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=IdNewsMsg;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  OPEN childs;
    REPEAT
      FETCH childs INTO IdChild;
      IF Done=0 THEN
        CALL k_sp_del_newsmsg (IdChild);
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE childs;
  DELETE FROM k_x_cat_objs WHERE gu_object=IdNewsMsg;
  DELETE FROM k_newsmsg_vote WHERE gu_msg=IdNewsMsg;
  DELETE FROM k_newsmsgs WHERE gu_msg=IdNewsMsg;
END
GO;

CREATE TABLE k_distances_cache
(
  lo_from   VARCHAR(254) NOT NULL,
  lo_to     VARCHAR(254) NOT NULL,
  nu_km     FLOAT        NOT NULL,
  id_locale VARCHAR(8) NOT NULL,
  coord_x   FLOAT NULL,
  coord_y   FLOAT NULL,  
  CONSTRAINT pk_distances_cache PRIMARY KEY (lo_from,lo_to)  
)
GO;

CREATE TABLE k_working_time
(
gu_calendar    CHAR(32)  NOT NULL,
gu_workarea    CHAR(32)  NOT NULL,
id_domain      INTEGER   NOT NULL,
nm_calendar    VARCHAR(100) NOT NULL,
dt_day         CHAR(8)   NOT NULL,
bo_working_day SMALLINT  NOT NULL,
ti_start1      CHAR(2)   NULL,
ti_end1        CHAR(2)   NULL,
ti_start2      CHAR(2)   NULL,
ti_end2        CHAR(2)   NULL,
gu_user        CHAR(32)  NULL,
gu_acl_group   CHAR(32)  NULL,
gu_geozone     CHAR(32)  NULL,
id_country     CHAR(3)   NULL,
id_state       CHAR(9)   NULL,
de_day         VARCHAR(50) NULL,

CONSTRAINT pk_working_time PRIMARY KEY (gu_calendar)
)
GO;

DROP PROCEDURE k_sp_del_group
GO;

CREATE PROCEDURE k_sp_del_group (IdGroup CHAR(32))
BEGIN
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=IdGroup;
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=IdGroup;
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=IdGroup;
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=IdGroup;
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=IdGroup;

  DELETE FROM k_working_time WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_group_company WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_group_contact WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_group_user WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=IdGroup;
  DELETE FROM k_acl_groups WHERE gu_acl_group=IdGroup;
END
GO;

ALTER TABLE k_meetings ADD gu_address CHAR(32) NULL
GO;

ALTER TABLE k_meetings ADD CONSTRAINT f4_meeting FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address)
GO;

ALTER TABLE k_meetings ADD pr_cost FLOAT NULL
GO;

CREATE PROCEDURE k_get_term_from_text (IdDomain INT, TxTerm VARCHAR(200), OUT GuTerm CHAR(32))
BEGIN
  SET GuTerm=NULL;
  SELECT gu_term INTO GuTerm FROM k_thesauri WHERE id_domain=IdDomain AND (tx_term=TxTerm OR tx_term2=TxTerm) LIMIT 1;
END
GO;

DROP TRIGGER k_tr_upd_address
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

CREATE TABLE k_lu_currencies_history
(
    alpha_code_from CHAR(3)   NOT NULL,
    alpha_code_to   CHAR(3)   NOT NULL,
    nu_conversion   DECIMAL(20,8) NOT NULL,
    dt_stamp        DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_lu_currencies_history PRIMARY KEY (alpha_code_from,alpha_code_to,dt_stamp)
)
GO;

CREATE TABLE k_prod_fares_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section VARCHAR(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(255)    NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,

CONSTRAINT pk_prod_fares_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_prod_fares_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

ALTER TABLE k_companies ADD id_fare VARCHAR(32) NULL
GO;
ALTER TABLE k_contacts ADD id_fare VARCHAR(32) NULL
GO;

DROP VIEW v_duty_resource
GO;
DROP VIEW v_duty_project
GO;
DROP VIEW v_duty_company
GO;

CREATE VIEW v_duty_resource AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty, u.tx_nickname AS nm_resource
FROM k_projects p, k_users u, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND x.nm_resource=u.gu_user
UNION
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource
FROM k_projects p, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND NOT EXISTS (SELECT gu_user FROM k_users WHERE gu_user=x.nm_resource)
GO;

CREATE VIEW v_duty_project AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty
FROM k_duties b, k_projects p
WHERE p.gu_project=b.gu_project
GO;

CREATE VIEW v_duty_company AS
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,c.gu_company,c.nm_legal,c.id_legal
FROM k_projects p, k_companies c, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND p.gu_company=c.gu_company)
UNION
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_scheduled,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,NULL AS gu_company,NULL AS nm_legal, NULL AS id_legal
FROM k_projects p, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND p.gu_company IS NULL)
GO;

DROP PROCEDURE k_sp_autenticate 
GO;

CREATE PROCEDURE k_sp_autenticate (IdUser CHAR(32), PwdText VARCHAR(50), OUT CoStatus SMALLINT)
BEGIN
  DECLARE Password VARCHAR(50);
  DECLARE Activated SMALLINT;
  DECLARE DtCancel TIMESTAMP;
  DECLARE DtExpire TIMESTAMP;

  SET Activated=NULL;
  SET CoStatus=1;

  SELECT tx_pwd,bo_active,dt_cancel,dt_pwd_expires INTO Password,Activated,DtCancel,DtExpire FROM k_users WHERE gu_user=IdUser;

  IF Activated IS NULL THEN
    SET CoStatus=-1;
  ELSE
    SET CoStatus=1;
    IF Password<>PwdText AND Password<>'(not set yet, change on next logon)' THEN
      SET CoStatus=-2;
    ELSE
      IF Activated=0 THEN
        SET CoStatus=-3;
      END IF;
      IF NOW()>DtCancel THEN
	SET CoStatus=-8;
      END IF;
      IF NOW()>DtExpire THEN
        SET CoStatus=-9;
      END IF;
    END IF;
  END IF;
END
GO;

INSERT INTO k_apps (id_app,nm_app) VALUES (23,'Wiki')
GO;

INSERT INTO k_apps (id_app,nm_app) VALUES (24,'Passwords Manager')
GO;

ALTER TABLE k_companies ADD bo_restricted SMALLINT DEFAULT 0
GO;

ALTER TABLE k_contacts ADD bo_restricted SMALLINT DEFAULT 0
GO;

ALTER TABLE k_contacts ADD gu_sales_man CHAR(32) NULL
GO;

CREATE TABLE k_x_group_company
(
gu_acl_group CHAR(32) NOT NULL,
gu_company   CHAR(32) NOT NULL,
dt_created   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT pk_x_group_company PRIMARY KEY (gu_acl_group,gu_company),
CONSTRAINT f1_x_group_company FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups(gu_acl_group),
CONSTRAINT f2_x_group_company FOREIGN KEY (gu_company) REFERENCES k_companies(gu_company)
)
GO;

CREATE TABLE k_x_group_contact
(
gu_acl_group CHAR(32) NOT NULL,
gu_contact   CHAR(32) NOT NULL,
dt_created   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT pk_x_group_contact PRIMARY KEY (gu_acl_group,gu_contact),
CONSTRAINT f1_x_group_contact FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups(gu_acl_group),
CONSTRAINT f2_x_group_contact FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact)
)
GO;

DROP PROCEDURE k_sp_del_company
GO;

CREATE PROCEDURE k_sp_del_company (CompanyId CHAR(32))
BEGIN
  DECLARE GuWorkArea CHAR(32);

  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=CompanyId);

  DELETE FROM k_welcome_packs WHERE gu_company=CompanyId;

  DELETE FROM k_member_address WHERE gu_company=CompanyId;

  DELETE FROM k_companies_recent WHERE gu_company=CompanyId;

  SELECT gu_workarea INTO GuWorkArea FROM k_companies WHERE gu_company=CompanyId;

  DELETE FROM k_x_group_company WHERE gu_company=CompanyId;

  CREATE TEMPORARY TABLE k_tmp_del_addr (gu_address CHAR(32)) SELECT gu_address FROM k_x_company_addr WHERE gu_company=CompanyId;
  DELETE FROM k_x_company_addr WHERE gu_company=CompanyId;
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_tmp_del_addr);
  DROP TEMPORARY TABLE k_tmp_del_addr;

  CREATE TEMPORARY TABLE k_tmp_del_bank (nu_bank_acc CHAR(20)) SELECT nu_bank_acc FROM k_x_company_bank WHERE gu_company=CompanyId;
  DELETE FROM k_x_company_bank WHERE gu_company=CompanyId;
  DELETE FROM k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM k_tmp_del_bank) AND gu_workarea=GuWorkArea;
  DROP TEMPORARY TABLE k_tmp_del_bank;

  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE FROM k_oportunities WHERE gu_company=CompanyId;

  DELETE FROM k_x_cat_objs WHERE gu_object=CompanyId AND id_class=91;

  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=CompanyId;

  DELETE FROM k_x_company_prods WHERE gu_company=CompanyId;
  DELETE FROM k_companies_attrs WHERE gu_object=CompanyId;
  DELETE FROM k_companies WHERE gu_company=CompanyId;
END
GO;

DROP PROCEDURE k_sp_del_contact
GO;

CREATE PROCEDURE k_sp_del_contact (ContactId CHAR(32))
BEGIN
  DECLARE GuWorkArea CHAR(32);

  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=ContactId);

  DELETE FROM k_welcome_packs WHERE gu_contact=ContactId;

  DELETE FROM k_member_address WHERE gu_contact=ContactId;
  
  DELETE FROM k_contacts_recent WHERE gu_contact=ContactId;

  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=ContactId;

  DELETE FROM k_x_group_contact WHERE gu_contact=ContactId;

  CREATE TEMPORARY TABLE k_tmp_del_addr (gu_address CHAR(32)) SELECT gu_address FROM k_x_contact_addr WHERE gu_contact=ContactId;  
  DELETE FROM k_x_contact_addr WHERE gu_contact=ContactId;
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_tmp_del_addr);
  DROP TEMPORARY TABLE k_tmp_del_addr;

  CREATE TEMPORARY TABLE k_tmp_del_bank (nu_bank_acc CHAR(20)) SELECT nu_bank_acc FROM k_x_contact_bank WHERE gu_contact=ContactId;
  DELETE FROM k_x_contact_bank WHERE gu_contact=ContactId;
  DELETE FROM k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM k_tmp_del_bank) AND gu_workarea=GuWorkArea;
  DROP TEMPORARY TABLE k_tmp_del_bank;

  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=ContactId);
  DELETE FROM k_oportunities WHERE gu_contact=ContactId;

  DELETE FROM k_x_cat_objs WHERE gu_object=ContactId AND id_class=90;

  DELETE FROM k_x_contact_prods WHERE gu_contact=ContactId;
  DELETE FROM k_contacts_attrs WHERE gu_object=ContactId;
  DELETE FROM k_contact_notes WHERE gu_contact=ContactId;
  DELETE FROM k_contacts WHERE gu_contact=ContactId;
END
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
GO;

CREATE VIEW v_company_address AS
SELECT c.gu_workarea,c.gu_company,c.nm_legal,c.nm_commercial,c.dt_modified,c.id_legal,c.id_ref,c.id_sector,c.id_status,c.tp_company,c.de_company,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,CONCAT(COALESCE(tx_addr1,''),CHAR(10),COALESCE(tx_addr2,'')) AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.id_ref AS id_addrref,b.tx_remarks, c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.tx_franchise
FROM k_companies c
LEFT OUTER JOIN v_active_company_address AS b ON c.gu_company=b.gu_company
GO;

CREATE VIEW v_contact_titles AS
SELECT vl_lookup,gu_owner,tr_es,tr_en,tr_fr,tr_de,tr_it,tr_pt,tr_ja,tr_cn,tr_tw,tr_ca,tr_eu FROM k_contacts_lookup WHERE id_section='de_title'
GO;

CREATE VIEW v_active_contact_address AS
SELECT x.gu_contact,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.tx_remarks FROM k_addresses a, k_x_contact_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
GO;

CREATE VIEW v_contact_company AS
SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,y.gu_company,y.nm_legal,y.id_sector,y.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c, k_companies y WHERE c.gu_company=y.gu_company
GO;

CREATE VIEW v_contact_company_all AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL AS gu_company,NULL AS nm_legal,NULL AS id_sector,NULL AS tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,CONCAT(COALESCE(tx_addr1,''),CHAR(10),COALESCE(tx_addr2,'')) AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,CONCAT(COALESCE(tx_addr1,''),CHAR(10),COALESCE(tx_addr2,'')) AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address_title AS
SELECT b.*,l.gu_owner,l.id_section,l.pg_lookup,l.vl_lookup,l.tr_es,l.tr_en,tr_fr,tr_de,tr_it,tr_pt,tr_ja,tr_cn,tr_tw,tr_ca,tr_eu FROM v_contact_address b LEFT OUTER JOIN k_contacts_lookup l ON b.de_title=l.vl_lookup
GO;

CREATE VIEW v_contact_list AS
SELECT c.gu_contact,CONCAT(COALESCE(c.tx_surname,''),', ',COALESCE(c.tx_name,'')) AS full_name,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner, c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c LEFT OUTER JOIN k_companies d ON c.gu_company=d.gu_company LEFT OUTER JOIN k_contacts_lookup l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE (l.id_section='de_title' OR l.id_section IS NULL)
GO;

CREATE VIEW v_attach_locat AS
SELECT p.gu_product, p.nm_product, p.de_product, c.gu_contact, c.pg_product, c.dt_created, l.dt_modified, l.dt_uploaded, l.gu_location, l.id_cont_type, l.id_prod_type, l.len_file, l.xprotocol, l.xhost, l.xport, l.xpath, l.xfile, l.xoriginalfile, l.xanchor, l.status, l.vs_stamp, l.tx_email, l.tag_prod_locat
FROM k_contact_attachs c, k_products p, k_prod_locats l
WHERE c.gu_product=p.gu_product AND c.gu_product=l.gu_product
GO;

CREATE VIEW v_supplier_address AS SELECT s.gu_supplier,s.dt_created,s.nm_legal,s.gu_workarea,s.nm_commercial,s.gu_address,s.dt_modified,s.id_legal,s.id_status,s.id_ref,s.tp_supplier,s.gu_geozone,s.de_supplier,a.ix_address,a.bo_active,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.tx_email_alt,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.tx_remarks FROM k_suppliers s, k_addresses a WHERE s.gu_address=a.gu_address
GO;

CREATE TABLE k_events (
    id_domain   INTEGER NOT NULL,
    id_event    VARCHAR(64) NOT NULL,
    dt_created  TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
    dt_modified TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
    bo_active   SMALLINT DEFAULT 1,
    gu_writer   CHAR(32) NOT NULL,
    id_command  CHAR(4)  NOT NULL,
    id_app      INTEGER  NOT NULL,
    gu_workarea CHAR(32) NULL,
    de_event    VARCHAR(254) NULL,
    tx_parameters VARCHAR(2000) NULL,
    
    CONSTRAINT pk_events PRIMARY KEY (id_domain,id_event)
)
GO;

CREATE PROCEDURE k_is_workarea_anyrole (IdWorkArea CHAR(32), IdUser CHAR(32), OUT IsAny INT)
BEGIN
  DECLARE IdGroup CHAR(32);
  SET IdGroup=NULL;
  SELECT x.gu_acl_group INTO IdGroup FROM k_x_group_user x, k_x_app_workarea w WHERE (x.gu_acl_group=w.gu_admins OR x.gu_acl_group=w.gu_powusers OR x.gu_acl_group=w.gu_users OR x.gu_acl_group=w.gu_guests OR x.gu_acl_group=w.gu_other) AND x.gu_user=IdUser AND w.gu_workarea=IdWorkArea LIMIT 0, 1;
  IF IdGroup IS NULL THEN
    SET IsAny=0;
  ELSE
    SET IsAny=1;
  END IF;
END
GO;

ALTER TABLE k_duties ADD gu_writer CHAR(32) NULL
GO;

ALTER TABLE k_duties ADD tp_duty VARCHAR(30) NULL
GO;

ALTER TABLE k_workareas ADD id_locale VARCHAR(5) NULL
GO;

ALTER TABLE k_workareas ADD tx_date_format VARCHAR(30) DEFAULT 'yyyy-MM-dd'
GO;

ALTER TABLE k_workareas ADD tx_number_format VARCHAR(30) DEFAULT '#0.00'
GO;

ALTER TABLE k_workareas ADD bo_dup_id_docs SMALLINT DEFAULT 1
GO;

ALTER TABLE k_workareas ADD bo_cnt_autoref SMALLINT DEFAULT 0
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
  dt_payment     TIMESTAMP     NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  im_paid        DECIMAL(14,4) NOT NULL,
  tp_billing     CHAR(1)       NULL,
  nm_client	     VARCHAR(200)  NULL,
  tx_comments    VARCHAR(254)  NULL,

  CONSTRAINT pk_invoice_payments PRIMARY KEY(gu_invoice,pg_payment)
)
GO;

CREATE TABLE k_project_snapshots
(
gu_snapshot CHAR(32)      NOT NULL,
gu_project  CHAR(32)      NOT NULL,
gu_writer   CHAR(32)      NOT NULL,
dt_created  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
tl_snapshot VARCHAR(100)  NOT NULL,
tx_snapshot MEDIUMTEXT    NOT NULL,
CONSTRAINT pk_project_snapshots PRIMARY KEY (gu_snapshot),
CONSTRAINT f1_project_snapshots FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

CREATE TABLE k_duties_workreports
(
gu_workreport CHAR(32)      NOT NULL,
tl_workreport VARCHAR(200)  NOT NULL,
gu_writer     CHAR(32)      NOT NULL,
dt_created    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
gu_project    CHAR(32)      NULL,
de_workreport VARCHAR(2000) NULL,
tx_workreport MEDIUMTEXT    NOT NULL,
CONSTRAINT pk_duties_workreports PRIMARY KEY (gu_workreport),
CONSTRAINT f1_duties_workreports FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

DROP PROCEDURE k_sp_del_project
GO;

CREATE PROCEDURE k_sp_del_project (ProjId CHAR(32))
BEGIN
  DECLARE ChldId CHAR(32);
  DECLARE StackBot INTEGER;
  DECLARE StackTop INTEGER;
  DECLARE Done INT DEFAULT 0;
  DECLARE prjs CURSOR FOR SELECT gu_prj FROM tmp_del_prj_stack ORDER BY nu_pos DESC;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  CREATE TEMPORARY TABLE tmp_del_prj_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_prj CHAR(32) NOT NULL) TYPE MYISAM;
  CREATE TEMPORARY TABLE tmp_del_prj_slice (gu_prj CHAR(32) NOT NULL) ENGINE = MEMORY;
    
  SET StackBot = 1;
  SET StackTop = 1;
  INSERT INTO tmp_del_prj_stack (gu_prj) VALUES (ProjId);
  
  REPEAT
    INSERT INTO tmp_del_prj_slice (gu_prj) SELECT gu_project FROM k_projects WHERE id_parent<>gu_project AND id_parent IN (SELECT gu_prj FROM tmp_del_prj_stack WHERE nu_pos BETWEEN StackBot AND StackTop);
    INSERT INTO tmp_del_prj_stack (gu_prj) SELECT gu_prj FROM tmp_del_prj_slice;
    DELETE FROM tmp_del_prj_slice;
    SET StackBot = StackTop+1;
    SELECT MAX(nu_pos) INTO StackTop FROM tmp_del_prj_stack;
    UNTIL StackTop<StackBot
  END REPEAT;

  OPEN prjs;
    REPEAT
      FETCH prjs INTO ChldId;
      IF Done=0 THEN
        DELETE FROM k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ChldId);
        DELETE FROM k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ChldId);
        DELETE FROM k_duties WHERE gu_project=ChldId;

        DELETE FROM k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ChldId);
        DELETE FROM k_bugs WHERE gu_project=ChldId;

        UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=ChldId;

		DELETE FROM k_duties_workreports WHERE gu_project=ChldId;
		DELETE FROM k_project_snapshots WHERE gu_project=ChldId;
        DELETE FROM k_project_costs WHERE gu_project=ChldId;
        DELETE FROM k_project_expand WHERE gu_project=ChldId;
        DELETE FROM k_projects WHERE gu_project=ChldId;
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE prjs;

  DROP TEMPORARY TABLE tmp_del_prj_slice;
  DROP TEMPORARY TABLE tmp_del_prj_stack;
END
GO;

ALTER TABLE k_phone_calls ADD gu_oportunity CHAR(32) NULL
GO;

ALTER TABLE k_oportunities ADD lv_interest SMALLINT NULL
GO;

