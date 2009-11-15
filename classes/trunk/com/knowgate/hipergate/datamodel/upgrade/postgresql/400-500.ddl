UPDATE k_version SET vs_stamp='5.0.0'
GO;

INSERT INTO k_classes VALUES(14,'PasswordRecord');
GO;

ALTER TABLE k_pageset_pages ADD path_publish VARCHAR(254) NULL
GO;

ALTER TABLE k_oportunities ADD dt_last_call TIMESTAMP NULL
GO;

ALTER TABLE k_newsgroups ADD de_newsgrp VARCHAR(254) NULL
GO;

ALTER TABLE k_newsgroups ADD tx_journal VARCHAR(4000) NULL
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32)     NOT NULL,
gu_newsgrp        CHAR(32)     NOT NULL,
dt_created        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
od_tag            SMALLINT     DEFAULT 1000,
tl_tag            VARCHAR(70)  NOT NULL,
de_tag            VARCHAR(200)     NULL,
nu_msgs           INTEGER     DEFAULT 0,
bo_incoming_ping  SMALLINT    DEFAULT 0,
dt_trackback      TIMESTAMP        NULL,
url_trackback     VARCHAR(2000)    NULL,

CONSTRAINT pk_newsgroup_tags PRIMARY KEY (gu_tag)
)
GO;

CREATE TABLE k_newsmsg_tags
(
gu_msg CHAR(32) NOT NULL,
gu_tag CHAR(32) NOT NULL,

CONSTRAINT pk_newsmsg_tags PRIMARY KEY (gu_msg,gu_tag)
)
GO;

DROP FUNCTION k_sp_del_newsgroup (CHAR)
GO;

CREATE FUNCTION k_sp_del_newsgroup (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_newsmsg_tags WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsgroup_subscriptions WHERE gu_newsgrp=$1;
  DELETE FROM k_newsgroup_tags WHERE gu_newsgrp=$1;
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
  childs REFCURSOR;
BEGIN
  OPEN childs FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=$1;
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_del_newsmsg (IdChild);
    END LOOP;
  CLOSE childs;
  UPDATE k_newsmsgs SET nu_thread_msgs=nu_thread_msgs-1 WHERE gu_thread_msg=$1;  
  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  DELETE FROM k_newsmsg_vote WHERE gu_msg=$1;
  DELETE FROM k_newsmsg_tags WHERE gu_msg=$1;
  DELETE FROM k_newsmsgs WHERE gu_msg=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

ALTER TABLE k_newsmsgs ADD dt_modified TIMESTAMP NULL
GO;

CREATE SEQUENCE seq_k_webbeacons INCREMENT 1 START 1
GO;

CREATE TABLE k_webbeacons (
    id_webbeacon  INTEGER  NOT NULL,
    dt_created    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_last_visit TIMESTAMP NOT NULL,
	nu_pages      INTEGER  NOT NULL,
    gu_user       CHAR(32) NULL,
    gu_contact    CHAR(32) NULL,
    CONSTRAINT pk_webbeacons PRIMARY KEY(id_webbeacon)
)
GO;
    
CREATE TABLE k_webbeacon_pages (
    id_page   INTEGER  NOT NULL,
    nu_hits   INTEGER  NOT NULL,
    gu_object CHAR(32) NULL,
    url_page  VARCHAR(254) NOT NULL,
    CONSTRAINT pk_webbeacon_pages PRIMARY KEY(id_page),
    CONSTRAINT u1_webbeacon_pages UNIQUE (url_page),
    CONSTRAINT c1_webbeacon_pages CHECK (LENGTH(url_page)>0)    
)
GO;

CREATE TABLE k_webbeacon_hit (
    id_webbeacon  INTEGER  NOT NULL,
    id_page       INTEGER  NOT NULL,
    id_referrer   INTEGER      NULL,
    dt_hit        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_addr       INTEGER  NULL
)
GO;

ALTER TABLE k_users ADD mov_phone VARCHAR(16) NULL
GO;

DROP VIEW v_project_company
GO;

CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,COALESCE(d.tx_name,'') || ' ' || COALESCE(d.tx_surname,'') AS full_name, p.id_status, p.id_ref
FROM k_project_expand e, k_contacts d, k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND d.gu_contact=p.gu_contact)
UNION
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NULL AS full_name, p.id_status, p.id_ref
FROM k_project_expand e,
k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND p.gu_contact IS NULL)
GO;

ALTER TABLE k_contacts ADD id_batch VARCHAR(32)
GO;
ALTER TABLE k_companies ADD id_batch VARCHAR(32)
GO;

ALTER TABLE k_academic_courses ADD pr_acourse DECIMAL(14,4) NULL
GO;
ALTER TABLE k_x_course_bookings ADD dt_paid TIMESTAMP NULL
GO;
ALTER TABLE k_x_course_bookings ADD id_transact VARCHAR(32) NULL
GO;
ALTER TABLE k_x_course_bookings ADD tp_billing CHAR(1) NULL
GO;
ALTER TABLE k_academic_courses ADD gu_address CHAR(32) NULL
GO;
ALTER TABLE k_academic_courses DROP CONSTRAINT u1_academic_courses
GO;
INSERT INTO k_classes VALUES(66,'EducationInstitution')
GO;
INSERT INTO k_classes VALUES(67,'EducationDegree')
GO;
CREATE TABLE k_education_institutions (
  gu_institution CHAR(32)    NOT NULL,
  gu_workarea    CHAR(32)    NOT NULL,
  nm_institution VARCHAR(50) NOT NULL,
  id_institution VARCHAR(30) NULL,
  bo_active      SMALLINT    DEFAULT 1,
  CONSTRAINT pk_education_institutions PRIMARY KEY (gu_institution),
  CONSTRAINT u1_education_institutions UNIQUE (gu_workarea,nm_institution)
)
GO;

CREATE TABLE k_education_degree (
  gu_degree   CHAR(32)     NOT NULL,
  gu_workarea CHAR(32)     NOT NULL,
  nm_degree   VARCHAR(50)  NOT NULL,
  tp_degree   VARCHAR(50)  NULL,
  id_degree   VARCHAR(32)  NULL,
  CONSTRAINT pk_education_degree PRIMARY KEY (gu_degree),
  CONSTRAINT u1_education_degree UNIQUE (gu_workarea,nm_degree)
)
GO;

CREATE TABLE k_education_degree_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section VARCHAR(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
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
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_education_degree_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;
CREATE TABLE k_contact_education (
  gu_contact     CHAR(32) NOT NULL,
  gu_degree      CHAR(32) NOT NULL,
  dt_created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  bo_completed   SMALLINT DEFAULT 1,
  gu_institution CHAR(32)     NULL,
  nm_center      VARCHAR(50)  NULL,
  tp_degree      VARCHAR(50)  NULL,
  id_degree      VARCHAR(32)  NULL,
  lv_degree      DECIMAL(3,2) NULL,
  ix_degree      INTEGER      NULL,
  tx_dt_from     VARCHAR(30)  NULL,
  tx_dt_to       VARCHAR(30)  NULL,
  CONSTRAINT pk_contact_education PRIMARY KEY (gu_contact,gu_degree),
  CONSTRAINT f1_contact_education FOREIGN KEY (gu_degree) REFERENCES k_education_degree(gu_degree)
)
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
  DELETE FROM k_contact_education WHERE gu_contact=$1;
  DELETE FROM k_x_duty_resource WHERE nm_resource=$1;
  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=$1);
  DELETE FROM k_welcome_packs WHERE gu_contact=$1;
  DELETE FROM k_x_list_members WHERE gu_contact=$1;
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
CREATE VIEW v_contact_education_degree AS SELECT d.gu_workarea,e.gu_contact,e.gu_degree,d.ix_degree,d.tp_degree,d.nm_degree,e.lv_degree,e.dt_created,e.bo_completed,e.gu_institution,e.nm_center,e.tx_dt_from,e.tx_dt_to FROM k_contact_education e, k_education_degree d WHERE e.gu_degree=d.gu_degree
GO;

CREATE TABLE k_oportunities_changelog (
gu_oportunity    CHAR(32)       NOT NULL,
nm_column        VARCHAR(18)    NOT NULL,
dt_modified      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
gu_writer        CHAR(32)       NULL,
id_former_status VARCHAR(50)    NULL,
id_new_status    VARCHAR(50)    NULL,
tx_value         VARCHAR(1000)  NULL
)
GO;

DROP FUNCTION k_sp_del_contact (CHAR) 
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

  DELETE FROM k_x_duty_resource WHERE nm_resource=$1;
  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=$1);
  DELETE FROM k_welcome_packs WHERE gu_company=$1;
  DELETE FROM k_x_list_members WHERE gu_company=$1;
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
  DELETE FROM k_oportunities_changelog WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=$1);
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

DROP FUNCTION k_sp_del_oportunity (CHAR) 
GO;

CREATE FUNCTION k_sp_del_oportunity (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_oportunities_changelog WHERE gu_oportunity=$1;
  DELETE FROM k_oportunities_attrs WHERE gu_object=$1;
  DELETE FROM k_oportunities WHERE gu_oportunity=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

ALTER TABLE k_mime_msgs ADD gu_job CHAR(32) NULL
GO;

INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SMS','SEND SMS PUSH TEXT MESSAGE','com.knowgate.scheduler.jobs.SmsSender');
GO;

CREATE TABLE k_activities
(
gu_activity    CHAR(32)      NOT NULL,
gu_workarea    CHAR(32)      NOT NULL,
dt_created     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
tl_activity    VARCHAR(100)  NOT NULL,
dt_modified    TIMESTAMP     NULL,
bo_active      SMALLINT DEFAULT 1,
gu_address     CHAR(32)      NULL,
gu_campaign    CHAR(32)      NULL,
gu_list        CHAR(32)      NULL,
gu_writer      CHAR(32)      NULL,
dt_start       TIMESTAMP     NULL,
dt_end         TIMESTAMP     NULL,
nu_capacity    INTEGER       NULL,
pr_sale		   DECIMAL(14,4) NULL,
pr_discount    DECIMAL(14,4) NULL,
id_ref         VARCHAR(50)   NULL,
tx_dept        VARCHAR(70)   NULL,
de_activity    VARCHAR(1000) NULL,
tx_comments    VARCHAR(254)  NULL,

CONSTRAINT pk_activities PRIMARY KEY (gu_activity),
CONSTRAINT u1_activities UNIQUE (gu_workarea,tl_activity),
CONSTRAINT c1_activities CHECK ((dt_start IS NULL AND dt_end IS NULL) OR dt_end IS NULL OR dt_end>=dt_start),
CONSTRAINT c2_activities CHECK (nu_capacity>=0),
CONSTRAINT c3_activities CHECK (pr_sale>=0),
CONSTRAINT c4_activities CHECK (pr_discount>=0)
)
GO;

CREATE TABLE k_x_activity_audience (
gu_activity   CHAR(32)      NOT NULL,
gu_address    CHAR(32)      NULL,
gu_contact    CHAR(32)      NULL,
gu_list       CHAR(32)      NULL,
gu_writer     CHAR(32)      NULL,
dt_created    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
dt_modified   TIMESTAMP     NULL,
id_ref        VARCHAR(50)   NULL,
tp_origin     VARCHAR(50)   NULL,
bo_confirmed  SMALLINT      DEFAULT 0,
dt_confirmed  TIMESTAMP     NULL,
bo_paid       SMALLINT      DEFAULT 0,
dt_paid       TIMESTAMP     NULL,
im_paid       DECIMAL(14,4) NULL,
id_transact   VARCHAR(32)   NULL,
tp_billing    CHAR(1)       NULL,
bo_went       SMALLINT DEFAULT 0,
bo_allows_ads SMALLINT DEFAULT 0,
id_data1      VARCHAR(32)   NULL,
de_data1      VARCHAR(100)  NULL,
tx_data1      VARCHAR(254)  NULL,
id_data2      VARCHAR(32)   NULL,
de_data2      VARCHAR(100)  NULL,
tx_data2      VARCHAR(254)  NULL,
id_data3      VARCHAR(32)   NULL,
de_data3      VARCHAR(100)  NULL,
tx_data3      VARCHAR(254)  NULL,
id_data4      VARCHAR(32)   NULL,
de_data4      VARCHAR(100)  NULL,
tx_data4      VARCHAR(254)  NULL,
id_data5      VARCHAR(32)   NULL,
de_data5      VARCHAR(100)  NULL,
tx_data5      VARCHAR(254)  NULL,
id_data6      VARCHAR(32)   NULL,
de_data6      VARCHAR(100)  NULL,
tx_data6      VARCHAR(254)  NULL,
id_data7      VARCHAR(32)   NULL,
de_data7      VARCHAR(100)  NULL,
tx_data7      VARCHAR(254)  NULL,
id_data8      VARCHAR(32)   NULL,
de_data8      VARCHAR(100)  NULL,
tx_data8      VARCHAR(254)  NULL,
id_data9      VARCHAR(32)   NULL,
de_data9      VARCHAR(100)  NULL,
tx_data9      VARCHAR(254)  NULL,

CONSTRAINT pk_x_activity_audience PRIMARY KEY (gu_activity,gu_contact)
)
GO;

CREATE FUNCTION k_sp_del_activity (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_x_activity_audience WHERE gu_activity=$1;
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_activities WHERE gu_activity=$1);
  DELETE FROM k_activities WHERE gu_activity=$1;
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
  DELETE FROM k_x_activity_audience WHERE gu_contact=$1;
  DELETE FROM k_contact_education WHERE gu_contact=$1;
  DELETE FROM k_x_duty_resource WHERE nm_resource=$1;
  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=$1);
  DELETE FROM k_welcome_packs WHERE gu_contact=$1;
  DELETE FROM k_x_list_members WHERE gu_contact=$1;
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

  DELETE FROM k_oportunities_changelog WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=$1);
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

DROP FUNCTION k_sp_del_list (CHAR)
GO;

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

    DELETE FROM k_lists WHERE gu_list=bk;
  END IF;

  DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=$1) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>$1);

  DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=$1) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>$1);

  DELETE FROM k_x_list_members WHERE gu_list=$1;

  DELETE FROM k_x_campaign_lists WHERE gu_list=$1;

  UPDATE k_activities SET gu_list=NULL WHERE gu_list=$1;
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=$1;

  DELETE FROM k_lists WHERE gu_list=$1;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TABLE k_activity_audience_lookup
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
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_activity_audience_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_activity_audience_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

ALTER TABLE k_invoice_payments ADD bo_active SMALLINT DEFAULT 1
GO;

ALTER TABLE k_invoice_payments ADD id_country CHAR(3) NULL
GO;

ALTER TABLE k_invoice_payments ADD id_authcode VARCHAR(6) NULL
GO;

ALTER TABLE k_invoice_payments ADD dt_paid TIMESTAMP NULL
GO;

ALTER TABLE k_invoice_payments ADD dt_expire TIMESTAMP NULL
GO;

ALTER TABLE k_invoice_payments ADD id_ref VARCHAR(50) NULL
GO;

ALTER TABLE k_invoice_payments ADD id_transact VARCHAR(50) NULL
GO;

ALTER TABLE k_x_course_bookings ADD gu_invoice CHAR(32) NULL
GO;

ALTER TABLE k_x_list_members ADD mov_phone VARCHAR(16) NULL
GO;

CREATE SEQUENCE seq_k_transactions INCREMENT 1 MINVALUE 1 MAXVALUE 999999 START 1
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
CREATE VIEW v_active_contact_address AS
SELECT x.gu_contact,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.tx_remarks FROM k_addresses a, k_x_contact_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
GO;

CREATE VIEW v_contact_company AS
SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,y.gu_company,y.nm_legal,y.id_sector,y.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man, c.gu_geozone, c.gu_sales_man, c.id_batch
FROM k_contacts c, k_companies y WHERE c.gu_company=y.gu_company
GO;

CREATE VIEW v_contact_company_all AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man, c.gu_geozone, c.gu_sales_man, c.id_batch
FROM v_contact_company c)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL AS gu_company,NULL AS nm_legal,NULL AS id_sector,NULL AS tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man, c.gu_geozone, c.gu_sales_man, c.id_batch
FROM k_contacts c WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,COALESCE(tx_addr1,'')||chr(10)||COALESCE(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man, c.gu_geozone, c.gu_sales_man, c.id_batch 
FROM v_contact_company c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,COALESCE(tx_addr1,'')||chr(10)||COALESCE(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man, c.gu_geozone, c.gu_sales_man, c.id_batch 
FROM k_contacts c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address_title AS
SELECT b.*,l.gu_owner,l.id_section,l.pg_lookup,l.vl_lookup,l.tr_es,l.tr_en,tr_fr,tr_de,tr_it,tr_pt,tr_ja,tr_cn,tr_tw,tr_ca,tr_eu FROM v_contact_address b LEFT OUTER JOIN k_contacts_lookup l ON b.de_title=l.vl_lookup
GO;

CREATE VIEW v_contact_list AS
SELECT c.gu_contact,COALESCE(c.tx_surname,'') || ', ' || COALESCE(c.tx_name,'') AS full_name,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner, c.bo_restricted, c.gu_geozone, c.gu_sales_man, c.gu_geozone, c.gu_sales_man, c.id_batch 
FROM k_contacts c LEFT OUTER JOIN k_companies d ON c.gu_company=d.gu_company LEFT OUTER JOIN k_contacts_lookup l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE (l.id_section='de_title' OR l.id_section IS NULL)
GO;

ALTER TABLE k_companies ADD id_bpartner VARCHAR(32) NULL
GO;
ALTER TABLE k_contacts ADD id_bpartner VARCHAR(32) NULL
GO;
ALTER TABLE k_suppliers ADD id_bpartner VARCHAR(32) NULL
GO;
ALTER TABLE k_sales_men ADD id_bpartner VARCHAR(32) NULL
GO;

CREATE TABLE k_bugs_track (
gu_bug       CHAR(32)      NOT NULL,
pg_bug       INTEGER       NOT NULL,
pg_bug_track INTEGER       NOT NULL,
dt_created   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
nm_reporter  VARCHAR(50)       NULL,
tx_rep_mail  VARCHAR(100)      NULL,
gu_writer    CHAR(32)		   NULL,
tx_bug_track VARCHAR(2000)     NULL,
CONSTRAINT pk_bugs_track PRIMARY KEY (gu_bug,pg_bug_track)
)
GO;

ALTER TABLE k_bugs_attach ADD pg_bug_track INTEGER NULL
GO;

CREATE SEQUENCE seq_k_bugs_track INCREMENT 1 START 1
GO;

DROP FUNCTION k_sp_del_bug (CHAR)
GO;

CREATE FUNCTION k_sp_del_bug (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=$1;
  DELETE FROM k_bugs_track WHERE gu_bug=$1;    
  DELETE FROM k_bugs_changelog WHERE gu_bug=$1;
  DELETE FROM k_bugs_attach WHERE gu_bug=$1;
  DELETE FROM k_bugs WHERE gu_bug=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE SEQUENCE seq_k_adhoc_mailings INCREMENT 1 MINVALUE 1 START 1
GO;

CREATE TABLE k_adhoc_mailings (
  gu_mailing     CHAR(32) NOT NULL,
  gu_workarea    CHAR(32) NOT NULL,
  gu_writer      CHAR(32) NOT NULL,
  pg_mailing     INTEGER  NOT NULL,
  dt_created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  
  nm_mailing     VARCHAR(30) NOT NULL,
  bo_html_part   SMALLINT NOT NULL,
  bo_plain_part  SMALLINT NOT NULL,
  bo_attachments SMALLINT NOT NULL,
  id_status      VARCHAR(30) NULL,
  dt_modified    TIMESTAMP NULL,
  dt_execution   TIMESTAMP NULL,
  tx_email_from  VARCHAR(254) NULL,
  tx_email_reply VARCHAR(254) NULL,  
  nm_from        VARCHAR(254)  NULL,
  tx_subject     VARCHAR(254)  NULL,
  tx_allow_regexp VARCHAR(254) NULL,
  tx_deny_regexp VARCHAR(254)  NULL,
  tx_parameters  VARCHAR(2000) NULL,
  CONSTRAINT pk_adhoc_mailings PRIMARY KEY (gu_mailing),
  CONSTRAINT u1_adhoc_mailings UNIQUE (pg_mailing),
  CONSTRAINT u2_adhoc_mailings UNIQUE (nm_mailing)
)
GO;

CREATE TABLE k_adhoc_mailings_lookup
(
gu_owner   CHAR(32)     NOT NULL,
id_section VARCHAR(30)  NOT NULL,
pg_lookup  INTEGER      NOT NULL,
vl_lookup  VARCHAR(255)     NULL,
tr_es      VARCHAR(50)      NULL,
tr_en      VARCHAR(50)      NULL,
tr_de      VARCHAR(50)      NULL,
tr_it      VARCHAR(50)      NULL,
tr_fr      VARCHAR(50)      NULL,
tr_pt      VARCHAR(50)      NULL,
tr_ca      VARCHAR(50)      NULL,
tr_gl      VARCHAR(50)      NULL,
tr_eu      VARCHAR(50)      NULL,
tr_ja      VARCHAR(50)      NULL,
tr_cn      VARCHAR(50)      NULL,
tr_tw      VARCHAR(50)      NULL,
tr_fi      VARCHAR(50)      NULL,
tr_ru      VARCHAR(50)      NULL,
tr_nl      VARCHAR(50)      NULL,
tr_th      VARCHAR(50)      NULL,
tr_cs      VARCHAR(50)      NULL,
tr_uk      VARCHAR(50)      NULL,
tr_no      VARCHAR(50)      NULL,
tr_ko      VARCHAR(50)      NULL,
tr_sk      VARCHAR(50)      NULL,
tr_pl      VARCHAR(50)      NULL,
tr_vn      VARCHAR(50)      NULL,

CONSTRAINT pk_adhoc_mailings_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_adhoc_mailings_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE VIEW v_pagesets_mailings AS
SELECT
p.gu_pageset,p.gu_workarea,p.nm_pageset,p.tx_comments,p.path_data,p.dt_created,m.nm_microsite,p.id_status,p.id_language,m.id_app
FROM k_pagesets p,k_microsites m WHERE p.gu_microsite=m.gu_microsite OR p.gu_microsite IS NULL
UNION
SELECT
a.gu_mailing AS gu_pageset,a.gu_workarea,a.nm_mailing AS nm_pageset,a.tx_parameters AS tx_comments ,'Hipermail' AS path_data,a.dt_created,'AdHoc' AS nm_microsite,a.id_status,'' AS id_language,21 AS id_app
FROM k_adhoc_mailings a
GO;

ALTER TABLE k_jobs DROP CONSTRAINT f7_jobs
GO;

CREATE TABLE k_global_black_list
(
id_domain   INTEGER   NOT NULL,
gu_workarea CHAR(32)  NOT NULL,
tx_email    VARCHAR(100) NOT NULL,
dt_created  TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
tx_name     VARCHAR(100) NULL,
tx_surname  VARCHAR(100) NULL,
gu_contact  CHAR(32) NULL,
gu_address  CHAR(32) NULL,

CONSTRAINT pk_global_black_list PRIMARY KEY (id_domain,gu_workarea,tx_email)
)
GO;