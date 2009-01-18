ALTER TABLE k_version ADD dt_created   TIMESTAMP    NULL
GO;
ALTER TABLE k_version ADD dt_modified  TIMESTAMP    NULL
GO;
ALTER TABLE k_version ADD bo_register  SMALLINT     NULL
GO;
ALTER TABLE k_version ADD gu_support   CHAR(32)     NULL
GO;
ALTER TABLE k_version ADD gu_contact   CHAR(32)     NULL
GO;
ALTER TABLE k_version ADD tx_name      VARCHAR(100) NULL
GO;
ALTER TABLE k_version ADD tx_surname   VARCHAR(100) NULL
GO;
ALTER TABLE k_version ADD nu_employees INTEGER      NULL
GO;
ALTER TABLE k_version ADD nm_company   VARCHAR(70)  NULL
GO;
ALTER TABLE k_version ADD id_sector    VARCHAR(16)  NULL
GO;
ALTER TABLE k_version ADD id_country   CHAR(3)      NULL
GO;
ALTER TABLE k_version ADD nm_state     VARCHAR(30)  NULL
GO;
ALTER TABLE k_version ADD mn_city	   VARCHAR(50)  NULL
GO;
ALTER TABLE k_version ADD zipcode	   VARCHAR(30)  NULL
GO;
ALTER TABLE k_version ADD work_phone   VARCHAR(16)  NULL
GO;
ALTER TABLE k_version ADD tx_email     VARCHAR(70)  NULL
GO;
UPDATE k_version SET vs_stamp='4.0.0'
GO;

CREATE SEQUENCE seq_k_msg_votes INCREMENT 1 MINVALUE 1 START 1
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

DROP FUNCTION k_sp_del_newsgroup (CHAR)
GO;

CREATE FUNCTION k_sp_del_newsgroup (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsgroup_subscriptions WHERE gu_newsgrp=$1;
  DELETE FROM k_newsgroups WHERE gu_newsgrp=$1;
  DELETE FROM k_x_cat_objs WHERE gu_category=$1;
  PERFORM k_sp_del_category ($1);
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_newsmsg (CHAR)
GO;

CREATE FUNCTION k_sp_del_newsmsg (CHAR) RETURNS INTEGER AS '
DECLARE
  IdChild CHAR(32);
  childs CURSOR (id CHAR(32)) FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=id;
BEGIN
  OPEN childs($1);
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_del_newsmsg (IdChild);
    END LOOP;
  CLOSE childs;
  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  DELETE FROM k_newsmsg_vote WHERE gu_msg=$1;
  DELETE FROM k_newsmsgs WHERE gu_msg=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TABLE k_distances_cache
(
  lo_from   VARCHAR(254) NOT NULL,
  lo_to     VARCHAR(254) NOT NULL,
  nu_km     FLOAT        NOT NULL,
  id_locale CHARACTER VARYING(8) NOT NULL,
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

DROP FUNCTION k_sp_del_group (CHAR)
GO;

CREATE FUNCTION k_sp_del_group (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=$1;
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=$1;
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=$1;
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=$1;
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=$1;

  DELETE FROM k_working_time WHERE gu_acl_group=$1;
  DELETE FROM k_x_group_company WHERE gu_acl_group=$1;
  DELETE FROM k_x_group_contact WHERE gu_acl_group=$1;
  DELETE FROM k_x_group_user WHERE gu_acl_group=$1;
  DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=$1;
  DELETE FROM k_acl_groups WHERE gu_acl_group=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

ALTER TABLE k_meetings ADD gu_address CHAR(32) NULL
GO;

ALTER TABLE k_meetings ADD CONSTRAINT f4_meeting FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address)
GO;

ALTER TABLE k_meetings ADD pr_cost FLOAT NULL
GO;

CREATE FUNCTION k_get_term_from_text (INTEGER, VARCHAR) RETURNS CHAR AS '
DECLARE
  GuTerm CHAR(32);
BEGIN
  GuTerm:=NULL;
  SELECT gu_term INTO GuTerm FROM k_thesauri WHERE id_domain=$1 AND (tx_term=$2 OR tx_term2=$2) LIMIT 1;
  RETURN GuTerm;
END;
' LANGUAGE 'plpgsql';
GO;

DROP TRIGGER k_tr_upd_address ON k_addresses
GO;

DROP FUNCTION k_sp_upd_address()
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
' LANGUAGE 'plpgsql'
GO;

CREATE TRIGGER k_tr_upd_address AFTER UPDATE ON k_addresses FOR EACH ROW EXECUTE PROCEDURE k_sp_upd_address()
GO;

CREATE TABLE k_lu_currencies_history
(
    alpha_code_from CHAR(3)   NOT NULL,
    alpha_code_to   CHAR(3)   NOT NULL,
    nu_conversion   DECIMAL(20,8) NOT NULL,
    dt_stamp        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty, u.tx_nickname AS nm_resource
FROM k_projects p, k_users u, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND x.nm_resource=u.gu_user
UNION
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource
FROM k_projects p, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND NOT EXISTS (SELECT gu_user FROM k_users WHERE gu_user=x.nm_resource)
GO;

CREATE VIEW v_duty_project AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty
FROM k_duties b, k_projects p
WHERE p.gu_project=b.gu_project
GO;

CREATE VIEW v_duty_company AS
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,c.gu_company,c.nm_legal,c.id_legal
FROM k_projects p, k_companies c, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND p.gu_company=c.gu_company)
UNION
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,NULL AS gu_company,NULL AS nm_legal, NULL AS id_legal
FROM k_projects p, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND p.gu_company IS NULL)
GO;

DROP FUNCTION k_sp_autenticate (CHAR, VARCHAR)
GO;

CREATE FUNCTION k_sp_autenticate (CHAR, VARCHAR) RETURNS SMALLINT AS '

DECLARE
    Password  VARCHAR;
    DtCancel  TIMESTAMP;
    DtExpire  TIMESTAMP;
    Activated SMALLINT := NULL;
    CoStatus  SMALLINT := 1;

BEGIN
  SELECT tx_pwd,bo_active,dt_cancel,dt_pwd_expires INTO Password,Activated,DtCancel,DtExpire FROM k_users WHERE gu_user=$1;

  IF Activated IS NULL THEN

    CoStatus := -1;

  ELSE

    IF Password<>$2 AND Password<>''(not set yet, change on next logon)'' THEN

      CoStatus := -2;

    ELSE

      IF Activated=0 THEN
        CoStatus := -3;
      END IF;

      IF age(DtCancel)<0 THEN
        CoStatus := -8;
      END IF;

      IF age(DtExpire)<0 THEN
        CoStatus := -9;
      END IF;

    END IF;

  END IF;

  RETURN CoStatus;
END;
' LANGUAGE 'plpgsql';
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

DROP FUNCTION k_sp_del_company (CHAR) 
GO;

CREATE FUNCTION k_sp_del_company (CHAR) RETURNS INTEGER AS '
DECLARE
  addr RECORD;
  addrs text;
  aCount INTEGER := 0;

  bank RECORD;
  banks text;
  bCount INTEGER := 0;

BEGIN

  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=$1);
  DELETE FROM k_welcome_packs WHERE gu_company=$1;
  DELETE FROM k_member_address WHERE gu_company=$1;
  DELETE FROM k_companies_recent WHERE gu_company=$1;
  DELETE FROM k_x_group_company WHERE gu_company=$1;

  FOR addr IN SELECT * FROM k_x_company_addr WHERE gu_company=$1 LOOP
    aCount := aCount + 1;
    IF 1=aCount THEN
      addrs := quote_literal(addr.gu_address);
    ELSE
      addrs := addrs || chr(44) || quote_literal(addr.gu_address);
    END IF;
  END LOOP;

  DELETE FROM k_x_company_addr WHERE gu_company=$1;

  IF char_length(addrs)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_addresses'') || '' WHERE gu_address IN ('' || addrs || '')'';
  END IF;

  FOR bank IN SELECT * FROM k_x_company_bank WHERE gu_company=$1 LOOP
    bCount := bCount + 1;
    IF 1=bCount THEN
      banks := quote_literal(bank.nu_bank_acc);
    ELSE
      banks := banks || chr(44) || quote_literal(bank.nu_bank_acc);
    END IF;
  END LOOP;

  DELETE FROM k_x_company_bank WHERE gu_company=$1;

  IF char_length(banks)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_bank_accounts'') || '' WHERE nu_bank_acc IN ('' || banks || '') AND gu_workarea='' || quote_literal(GuWorkArea);
  END IF;

  /* Borrar las oportunidades */
  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=$1);
  DELETE FROM k_oportunities WHERE gu_company=$1;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=$1;

  /* Borrar el enlace con categorías */
  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=91;

  DELETE FROM k_x_company_prods WHERE gu_company=$1;
  DELETE FROM k_companies_attrs WHERE gu_object=$1;
  DELETE FROM k_companies WHERE gu_company=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_contact (CHAR)
GO;

CREATE FUNCTION k_sp_del_contact (CHAR) RETURNS INTEGER AS '
DECLARE
  addr RECORD;
  addrs text;
  aCount INTEGER := 0;

  bank RECORD;
  banks text;
  bCount INTEGER := 0;

  GuWorkArea CHAR(32);

BEGIN  

  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=$1);
  DELETE FROM k_welcome_packs WHERE gu_contact=$1;
  DELETE FROM k_member_address WHERE gu_contact=$1;
  DELETE FROM k_contacts_recent WHERE gu_contact=$1;
  DELETE FROM k_x_group_contact WHERE gu_contact=$1;

  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=$1;

  FOR addr IN SELECT * FROM k_x_contact_addr WHERE gu_contact=$1 LOOP
    aCount := aCount + 1;
    IF 1=aCount THEN
      addrs := quote_literal(addr.gu_address);
    ELSE
      addrs := addrs || chr(44) || quote_literal(addr.gu_address);
    END IF;
  END LOOP;

  DELETE FROM k_x_contact_addr WHERE gu_contact=$1;
  
  IF char_length(addrs)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_addresses'') || '' WHERE gu_address IN ('' || addrs || '')'';
  END IF;

  FOR bank IN SELECT * FROM k_x_contact_bank WHERE gu_contact=$1 LOOP
    bCount := bCount + 1;
    IF 1=bCount THEN
      banks := quote_literal(bank.nu_bank_acc);
    ELSE
      banks := banks || chr(44) || quote_literal(bank.nu_bank_acc);
    END IF;
  END LOOP;

  DELETE FROM k_x_contact_bank WHERE gu_contact=$1;

  IF char_length(banks)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_bank_accounts'') || '' WHERE nu_bank_acc IN ('' || banks || '') AND gu_workarea='' || quote_literal(GuWorkArea);
  END IF;

  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=$1);
  DELETE FROM k_oportunities WHERE gu_contact=$1;

  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=90;

  DELETE FROM k_x_contact_prods WHERE gu_contact=$1;
  DELETE FROM k_contacts_attrs WHERE gu_object=$1;
  DELETE FROM k_contact_notes WHERE gu_contact=$1;
  DELETE FROM k_contacts WHERE gu_contact=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
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
SELECT c.gu_workarea,c.gu_company,c.nm_legal,c.nm_commercial,c.dt_modified,c.id_legal,c.id_ref,c.id_sector,c.id_status,c.tp_company,c.de_company,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,COALESCE(tx_addr1,'')||chr(10)||COALESCE(tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.id_ref AS id_addrref,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.tx_franchise
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
SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,y.gu_company,y.nm_legal,y.id_sector,y.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c, k_companies y WHERE c.gu_company=y.gu_company
GO;

CREATE VIEW v_contact_company_all AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL AS gu_company,NULL AS nm_legal,NULL AS id_sector,NULL AS tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,COALESCE(tx_addr1,'')||chr(10)||COALESCE(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,COALESCE(tx_addr1,'')||chr(10)||COALESCE(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address_title AS
SELECT b.*,l.gu_owner,l.id_section,l.pg_lookup,l.vl_lookup,l.tr_es,l.tr_en,tr_fr,tr_de,tr_it,tr_pt,tr_ja,tr_cn,tr_tw,tr_ca,tr_eu FROM v_contact_address b LEFT OUTER JOIN k_contacts_lookup l ON b.de_title=l.vl_lookup
GO;

CREATE VIEW v_contact_list AS
SELECT c.gu_contact,COALESCE(c.tx_surname,'') || ', ' || COALESCE(c.tx_name,'') AS full_name,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner, c.bo_restricted,c.gu_geozone,c.gu_sales_man
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

ALTER TABLE k_duties ADD gu_writer CHAR(32) NULL
GO;

ALTER TABLE k_duties ADD tp_duty VARCHAR(30) NULL
GO;

DROP FUNCTION k_sp_resolve_atom (CHAR,INTEGER,CHAR)
GO;

CREATE FUNCTION k_sp_resolve_atom (CHAR,INTEGER,CHAR) RETURNS INTEGER AS '
DECLARE
  AddrGu        CHAR(32);
  CompGu        CHAR(32);
  ContGu        CHAR(32);
  EMailTx       VARCHAR(100);
  NameTx        VARCHAR(200);
  SurnTx        VARCHAR(200);
  SalutTx       VARCHAR(16) ;
  CommNm        VARCHAR(70) ;
  StreetTp      VARCHAR(16) ;
  StreetNm      VARCHAR(100);
  StreetNu      VARCHAR(16) ;
  Addr1Tx       VARCHAR(100);
  Addr2Tx       VARCHAR(100);
  CountryNm     VARCHAR(50) ;
  StateNm       VARCHAR(30) ;
  CityNm	    VARCHAR(50) ;
  Zipcde	    VARCHAR(30) ;
  WorkPhone     VARCHAR(16) ;
  DirectPhone   VARCHAR(16) ;
  HomePhone     VARCHAR(16) ;
  MobilePhone   VARCHAR(16) ;
  FaxPhone      VARCHAR(16) ;
  OtherPhone    VARCHAR(16) ;
  PoBox         VARCHAR(50) ;
BEGIN
  SELECT tx_email INTO EMailTx FROM k_job_atoms WHERE gu_job=$1 AND pg_atom=$2;
  IF FOUND THEN
    SELECT gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box INTO CompGu,ContGu,EMailTx,NameTx,SurnTx,SalutTx,CommNm,StreetTp,StreetNm,StreetNu,Addr1Tx,Addr2Tx,CountryNm,StateNm,CityNm,Zipcde,WorkPhone,DirectPhone,HomePhone,MobilePhone,FaxPhone,OtherPhone,PoBox FROM k_member_address WHERE gu_workarea=$3 AND tx_email=EMailTx LIMIT 1;
    IF FOUND THEN
      UPDATE k_job_atoms SET gu_company=CompGu,gu_contact=ContGu,tx_name=NameTx,tx_surname=SurnTx,
             tx_salutation=SalutTx,nm_commercial=CommNm,tp_street=StreetTp,nm_street=StreetNm,nu_street=StreetNu,tx_addr1=Addr1Tx,tx_addr2=Addr2Tx,
             nm_country=CountryNm,nm_state=StateNm,mn_city=CityNm,zipcode=Zipcde,work_phone=WorkPhone,direct_phone=DirectPhone,
             home_phone=HomePhone,mov_phone=MobilePhone,fax_phone=FaxPhone,other_phone=OtherPhone,po_box=PoBox WHERE gu_job=$1 AND pg_atom=$2;
    END IF;
  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
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
tx_snapshot TEXT          NOT NULL,
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
tx_workreport TEXT          NOT NULL,
CONSTRAINT pk_duties_workreports PRIMARY KEY (gu_workreport),
CONSTRAINT f1_duties_workreports FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

DROP FUNCTION k_sp_del_project (CHAR)
GO;

CREATE FUNCTION k_sp_del_project (CHAR) RETURNS INTEGER AS '
DECLARE
  chldid CHAR(32);
  childs k_projects%ROWTYPE;
  
BEGIN

  FOR childs IN SELECT * FROM k_projects WHERE id_parent=$1 LOOP
    PERFORM k_sp_del_project (childs.gu_project);    
  END LOOP;
      
  DELETE FROM k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1);
  DELETE FROM k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1);
  DELETE FROM k_duties WHERE gu_project=$1;

  DELETE FROM k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=$1);
  DELETE FROM k_bugs WHERE gu_project=$1;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=$1;
  
  DELETE FROM k_duties_workreports WHERE gu_project=$1;
  DELETE FROM k_project_snapshots WHERE gu_project=$1;
  DELETE FROM k_project_costs WHERE gu_project=$1;
  DELETE FROM k_project_expand WHERE gu_project=$1;
  DELETE FROM k_projects WHERE gu_project=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

ALTER TABLE k_phone_calls ADD gu_oportunity CHAR(32) NULL
GO;

ALTER TABLE k_oportunities ADD lv_interest SMALLINT NULL
GO;
