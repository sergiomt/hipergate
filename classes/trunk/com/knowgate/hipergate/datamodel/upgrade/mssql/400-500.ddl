UPDATE k_version SET vs_stamp='5.0.0'
GO;

INSERT INTO k_classes VALUES(14,'PasswordRecord');
GO;

ALTER TABLE k_pageset_pages ADD path_publish NVARCHAR(254) NULL
GO;

ALTER TABLE k_oportunities ADD dt_last_call DATETIME NULL
GO;

ALTER TABLE k_newsgroups ADD de_newsgrp NVARCHAR(254) NULL
GO;
ALTER TABLE k_newsgroups ADD tx_journal NVARCHAR(4000) NULL
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32) NOT NULL,
gu_newsgrp        CHAR(32) NOT NULL,
dt_created        DATETIME DEFAULT GETDATE(),
od_tag            SMALLINT DEFAULT 1000,
tl_tag            NVARCHAR(70)  NOT NULL,
de_tag            NVARCHAR(200) NULL,
nu_msgs           INTEGER  DEFAULT 0,
bo_incoming_ping  SMALLINT DEFAULT 0,
dt_trackback      DATETIME NULL,
url_trackback     VARCHAR(2000) NULL,

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

DROP PROCEDURE k_sp_del_newsgroup
GO;

CREATE PROCEDURE k_sp_del_newsgroup @IdNewsGroup CHAR(32) AS
  DELETE k_newsmsg_tags WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsgroup_subscriptions WHERE gu_newsgrp=@IdNewsGroup
  DELETE k_newsgroup_tags WHERE gu_newsgrp=@IdNewsGroup
  DELETE k_newsgroups WHERE gu_newsgrp=@IdNewsGroup
  DELETE k_x_cat_objs WHERE gu_category=@IdNewsGroup
  EXECUTE k_sp_del_category @IdNewsGroup
GO;

DROP PROCEDURE k_sp_del_newsmsg
GO;

CREATE PROCEDURE k_sp_del_newsmsg @IdNewsMsg CHAR(32) AS
  DECLARE @IdChild CHAR(32)
  DECLARE childs CURSOR LOCAL STATIC FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=@IdNewsMsg
  OPEN childs
    FETCH NEXT FROM childs INTO @IdChild
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_newsmsg @IdChild
      END
  CLOSE childs
  UPDATE k_newsmsgs SET nu_thread_msgs=nu_thread_msgs-1 WHERE gu_thread_msg=@IdNewsMsg
  DELETE k_x_cat_objs WHERE gu_object=@IdNewsMsg
  DELETE k_newsmsg_vote WHERE gu_msg=@IdNewsMsg
  DELETE k_newsmsg_tags WHERE gu_msg=@IdNewsMsg
  DELETE k_newsmsgs WHERE gu_msg=@IdNewsMsg
GO;

ALTER TABLE k_newsmsgs ADD dt_modified  DATETIME NULL
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_webbeacons', 1, 2147483647, 1, 1)
GO;

CREATE TABLE k_webbeacons (
    id_webbeacon  INTEGER  NOT NULL,
    dt_created    DATETIME DEFAULT GETDATE(),
    dt_last_visit DATETIME NOT NULL,
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
    dt_hit        DATETIME DEFAULT GETDATE(),
    ip_addr       INTEGER  NULL
)
GO;

ALTER TABLE k_users ADD mov_phone VARCHAR(16) NULL
GO;

DROP VIEW v_project_company
GO;

CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,ISNULL(d.tx_name,'')+' '+ISNULL(d.tx_surname,'') AS full_name, p.id_status, p.id_ref
FROM k_project_expand e, k_contacts d, k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND d.gu_contact=p.gu_contact)
UNION
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NULL AS full_name, p.id_status, p.id_ref
FROM k_project_expand e,
k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND p.gu_contact IS NULL)
GO;

ALTER TABLE k_contacts ADD id_batch NVARCHAR(32)
GO;
ALTER TABLE k_companies ADD id_batch NVARCHAR(32)
GO;

ALTER TABLE k_academic_courses ADD pr_acourse DECIMAL(14,4) NULL
GO;
ALTER TABLE k_x_course_bookings ADD dt_paid DATETIME NULL
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
  nm_institution NVARCHAR(50) NOT NULL,
  id_institution NVARCHAR(30) NULL,  
  bo_active      SMALLINT    DEFAULT 1,
  CONSTRAINT pk_education_institutions PRIMARY KEY (gu_institution),
  CONSTRAINT u1_education_institutions UNIQUE (gu_workarea,nm_institution)
)
GO;
CREATE TABLE k_education_degree (
  gu_degree   CHAR(32)     NOT NULL,
  gu_workarea CHAR(32)     NOT NULL,
  nm_degree   NVARCHAR(50) NOT NULL,
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
vl_lookup  NVARCHAR(50)     NULL,
tr_es      NVARCHAR(50)     NULL,
tr_en      NVARCHAR(50)     NULL,
tr_de      NVARCHAR(50)     NULL,
tr_it      NVARCHAR(50)     NULL,
tr_fr      NVARCHAR(50)     NULL,
tr_pt      NVARCHAR(50)     NULL,
tr_ca      NVARCHAR(50)     NULL,
tr_gl      NVARCHAR(50)     NULL,
tr_eu      NVARCHAR(50)     NULL,
tr_ja      NVARCHAR(50)     NULL,
tr_cn      NVARCHAR(50)     NULL,
tr_tw      NVARCHAR(50)     NULL,
tr_fi      NVARCHAR(50)     NULL,
tr_ru      NVARCHAR(50)     NULL,
tr_nl      NVARCHAR(50)     NULL,
tr_th      NVARCHAR(50)     NULL,
tr_cs      NVARCHAR(50)     NULL,
tr_uk      NVARCHAR(50)     NULL,
tr_no      NVARCHAR(50)     NULL,
tr_sk      NVARCHAR(50)     NULL,
tr_pl      NVARCHAR(50)     NULL,
tr_vn      NVARCHAR(50)     NULL,

CONSTRAINT pk_education_degree_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;
CREATE TABLE k_contact_education (
  gu_contact     CHAR(32) NOT NULL,
  gu_degree      CHAR(32) NOT NULL,
  dt_created     DATETIME DEFAULT GETDATE(),
  bo_completed   SMALLINT DEFAULT 1,
  gu_institution CHAR(32)     NULL,
  nm_center      NVARCHAR(50) NULL,
  tp_degree      VARCHAR(50)  NULL,
  id_degree      VARCHAR(32)  NULL,
  lv_degree      DECIMAL(3,2) NULL,
  ix_degree      INTEGER      NULL,
  tx_dt_from     NVARCHAR(30)  NULL,
  tx_dt_to       NVARCHAR(30)  NULL,
  CONSTRAINT pk_contact_education PRIMARY KEY (gu_contact,gu_degree),
  CONSTRAINT f1_contact_education FOREIGN KEY (gu_degree) REFERENCES k_education_degree(gu_degree)
)
GO;
DROP PROCEDURE k_sp_del_contact
GO;
CREATE PROCEDURE k_sp_del_contact @ContactId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  DELETE k_contact_education WHERE gu_contact=@ContactId

  DELETE k_x_duty_resource WHERE nm_resource=@ContactId

  DELETE k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=@ContactId)

  DELETE k_welcome_packs WHERE gu_contact=@ContactId

  DELETE k_x_list_members WHERE gu_contact=@ContactId
  
  DELETE k_member_address WHERE gu_contact=@ContactId
  
  DELETE k_contacts_recent WHERE gu_contact=@ContactId

  SELECT @GuWorkArea=gu_workarea FROM k_contacts WHERE gu_contact=@ContactId

  DELETE k_x_group_contact WHERE gu_contact=@ContactId

  SELECT gu_address INTO #k_tmp_del_addr FROM k_x_contact_addr WHERE gu_contact=@ContactId
  DELETE k_x_contact_addr WHERE gu_contact=@ContactId
  DELETE k_addresses WHERE gu_address IN (SELECT gu_address FROM #k_tmp_del_addr)
  DROP TABLE #k_tmp_del_addr

  SELECT nu_bank_acc INTO #k_tmp_del_bank FROM k_x_contact_bank WHERE gu_contact=@ContactId
  DELETE k_x_contact_bank WHERE gu_contact=@ContactId
  DELETE k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM #k_tmp_del_bank) AND gu_workarea=@GuWorkArea
  DROP TABLE #k_tmp_del_bank

  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=@ContactId)
  DELETE k_oportunities WHERE gu_contact=@ContactId

  DELETE k_x_cat_objs WHERE gu_object=@ContactId AND id_class=90

  DELETE k_x_contact_prods WHERE gu_contact=@ContactId
  DELETE k_contacts_attrs WHERE gu_object=@ContactId
  DELETE k_contact_notes WHERE gu_contact=@ContactId
  DELETE k_contacts WHERE gu_contact=@ContactId
GO;
CREATE VIEW v_contact_education_degree AS SELECT d.gu_workarea,e.gu_contact,e.gu_degree,d.ix_degree,d.tp_degree,d.nm_degree,e.lv_degree,e.dt_created,e.bo_completed,e.gu_institution,e.nm_center,e.tx_dt_from,e.tx_dt_to FROM k_contact_education e, k_education_degree d WHERE e.gu_degree=d.gu_degree
GO;

CREATE TABLE k_oportunities_changelog (
gu_oportunity    CHAR(32)       NOT NULL,
nm_column        VARCHAR(18)    NOT NULL,
dt_modified      DATETIME       DEFAULT GETDATE(),
gu_writer        CHAR(32)       NULL,
id_former_status VARCHAR(50)    NULL,
id_new_status    VARCHAR(50)    NULL,
tx_value         NVARCHAR(1000) NULL
)
GO;

DROP PROCEDURE k_sp_del_company
GO;

CREATE PROCEDURE k_sp_del_company @CompanyId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  DELETE k_x_duty_resource WHERE nm_resource=@CompanyId

  DELETE k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=@CompanyId)

  DELETE k_welcome_packs WHERE gu_company=@CompanyId

  DELETE k_x_list_members WHERE gu_company=@CompanyId

  DELETE k_member_address WHERE gu_company=@CompanyId
  
  DELETE k_companies_recent WHERE gu_company=@CompanyId

  SELECT @GuWorkArea=gu_workarea FROM k_companies WHERE gu_company=@CompanyId

  DELETE k_x_group_company WHERE gu_company=@CompanyId

  /* Borrar las direcciones de la compañia */
  SELECT gu_address INTO #k_tmp_del_addr FROM k_x_company_addr WHERE gu_company=@CompanyId
  DELETE k_x_company_addr WHERE gu_company=@CompanyId
  DELETE k_addresses WHERE gu_address IN (SELECT gu_address FROM #k_tmp_del_addr)
  DROP TABLE #k_tmp_del_addr

  /* Borrar primero las cuentas bancarias asociadas a la compañía */
  SELECT nu_bank_acc INTO #k_tmp_del_bank FROM k_x_company_bank WHERE gu_company=@CompanyId
  DELETE k_x_company_bank WHERE gu_company=@CompanyId
  DELETE k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM #k_tmp_del_bank) AND gu_workarea=@GuWorkArea
  DROP TABLE #k_tmp_del_bank

  /* Borrar las oportunidades */
  DELETE k_oportunities_changelog WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=@CompanyId)
  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=@CompanyId)
  DELETE k_oportunities WHERE gu_company=@CompanyId

  /* Borrar el enlace con categorías */
  DELETE k_x_cat_objs WHERE gu_object=@CompanyId AND id_class=91

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=@CompanyId

  DELETE k_x_company_prods WHERE gu_company=@CompanyId
  DELETE k_companies_attrs WHERE gu_object=@CompanyId
  DELETE k_companies WHERE gu_company=@CompanyId
GO;

DROP PROCEDURE k_sp_del_oportunity
GO;

CREATE PROCEDURE k_sp_del_oportunity @OportunityId CHAR(32) AS
  DELETE k_oportunities_changelog WHERE gu_oportunity=@OportunityId
  DELETE k_oportunities_attrs WHERE gu_object=@OportunityId
  DELETE k_oportunities WHERE gu_oportunity=@OportunityId
GO;

ALTER TABLE k_contacts ADD id_nationality CHAR(3) NULL
GO;

ALTER TABLE k_mime_msgs ADD gu_job CHAR(32) NULL
GO;

INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SMS','SEND SMS PUSH TEXT MESSAGE','com.knowgate.scheduler.jobs.SmsSender');
GO;

CREATE TABLE k_activities
(
gu_activity    CHAR(32)      NOT NULL,
gu_workarea    CHAR(32)      NOT NULL,
dt_created     DATETIME      DEFAULT GETDATE(),
tl_activity    NVARCHAR(100) NOT NULL,
bo_active      SMALLINT DEFAULT 1,
dt_modified    DATETIME      NULL,
gu_address     CHAR(32)      NULL,
gu_campaign    CHAR(32)      NULL,
gu_list        CHAR(32)      NULL,
gu_writer      CHAR(32)      NULL,
dt_start       DATETIME      NULL,
dt_end         DATETIME      NULL,
nu_capacity    INTEGER       NULL,
pr_sale		   DECIMAL(14,4) NULL,
pr_discount    DECIMAL(14,4) NULL,
id_ref         NVARCHAR(50)   NULL,
tx_dept        NVARCHAR(70)   NULL,
de_activity    NVARCHAR(1000) NULL,
tx_comments    NVARCHAR(254)  NULL,

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
dt_created    DATETIME      DEFAULT GETDATE(),
dt_modified   DATETIME      NULL,
id_ref        NVARCHAR(50)   NULL,
tp_origin     NVARCHAR(50)   NULL,
bo_confirmed  SMALLINT      DEFAULT 0,
dt_confirmed  DATETIME      NULL,
bo_paid       SMALLINT      DEFAULT 0,
dt_paid       DATETIME      NULL,
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

CREATE PROCEDURE k_sp_del_activity @ActivtyId CHAR(32) AS
  DELETE k_x_activity_audience WHERE gu_activity=@ActivtyId
  DELETE k_addresses WHERE gu_address IN (SELECT gu_address FROM k_activities WHERE gu_activity=@ActivtyId)
  DELETE k_activities WHERE gu_activity=@ActivtyId
GO;

DROP PROCEDURE k_sp_del_contact (ContactId CHAR(32))
GO;

CREATE PROCEDURE k_sp_del_contact @ContactId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  DELETE k_x_activity_audience WHERE gu_contact=@ContactId

  DELETE k_contact_education WHERE gu_contact=@ContactId

  DELETE k_x_duty_resource WHERE nm_resource=@ContactId

  DELETE k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=@ContactId)

  DELETE k_welcome_packs WHERE gu_contact=@ContactId

  DELETE k_x_list_members WHERE gu_contact=@ContactId
  
  DELETE k_member_address WHERE gu_contact=@ContactId
  
  DELETE k_contacts_recent WHERE gu_contact=@ContactId

  SELECT @GuWorkArea=gu_workarea FROM k_contacts WHERE gu_contact=@ContactId

  DELETE k_x_group_contact WHERE gu_contact=@ContactId

  /* Borrar primero las direcciones asociadas al contacto */
  SELECT gu_address INTO #k_tmp_del_addr FROM k_x_contact_addr WHERE gu_contact=@ContactId
  DELETE k_x_contact_addr WHERE gu_contact=@ContactId
  DELETE k_addresses WHERE gu_address IN (SELECT gu_address FROM #k_tmp_del_addr)
  DROP TABLE #k_tmp_del_addr

  /* Borrar primero las cuentas bancarias asociadas al contacto */
  SELECT nu_bank_acc INTO #k_tmp_del_bank FROM k_x_contact_bank WHERE gu_contact=@ContactId
  DELETE k_x_contact_bank WHERE gu_contact=@ContactId
  DELETE k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM #k_tmp_del_bank) AND gu_workarea=@GuWorkArea
  DROP TABLE #k_tmp_del_bank

  /* Los productos que contienen la referencia a los ficheros adjuntos no se borran desde aquí,
     hay que llamar al método Java de borrado de Product para eliminar también los ficheros físicos,
     de este modo la foreign key de la base de datos actua como protección para que no se queden ficheros basura */

  DELETE k_oportunities_changelog WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=@ContactId)
  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=@ContactId)
  DELETE k_oportunities WHERE gu_contact=@ContactId

  DELETE k_x_cat_objs WHERE gu_object=@ContactId AND id_class=90

  DELETE k_x_contact_prods WHERE gu_contact=@ContactId
  DELETE k_contacts_attrs WHERE gu_object=@ContactId
  DELETE k_contact_notes WHERE gu_contact=@ContactId
  DELETE k_contacts WHERE gu_contact=@ContactId
GO;

DROP PROCEDURE k_sp_del_list @ListId CHAR(32)
GO;

CREATE PROCEDURE k_sp_del_list @ListId CHAR(32) AS   
  DECLARE @tp SMALLINT
  DECLARE @wa CHAR(32)
  DECLARE @bk CHAR(32)
    
  SELECT @tp=tp_list, @wa=gu_workarea FROM k_lists WHERE gu_list=@ListId

  SET @bk = NULL
  SELECT @bk=gu_list FROM k_lists WHERE gu_workarea=@wa AND gu_query=@ListId AND tp_list=4

  IF @bk IS NOT NULL
    BEGIN
      DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=@bk) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@bk)
      DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=@bk) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@bk)
      DELETE k_x_list_members WHERE gu_list=@bk
      DELETE k_x_campaign_lists WHERE gu_list=@bk
      DELETE k_lists WHERE gu_list=@bk
    END
    
  DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_x_list_members WHERE gu_list=@ListId

  DELETE k_x_campaign_lists WHERE gu_list=@ListId

  UPDATE k_activities SET gu_list=NULL WHERE gu_list=@ListId
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=@ListId

  DELETE k_lists WHERE gu_list=@ListId
GO;

CREATE TABLE k_activity_audience_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section VARCHAR(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  NVARCHAR(255)    NULL,
tr_es      NVARCHAR(50)     NULL,
tr_en      NVARCHAR(50)     NULL,
tr_de      NVARCHAR(50)     NULL,
tr_it      NVARCHAR(50)     NULL,
tr_fr      NVARCHAR(50)     NULL,
tr_pt      NVARCHAR(50)     NULL,
tr_ca      NVARCHAR(50)     NULL,
tr_eu      NVARCHAR(50)     NULL,
tr_ja      NVARCHAR(50)     NULL,
tr_cn      NVARCHAR(50)     NULL,
tr_tw      NVARCHAR(50)     NULL,
tr_fi      NVARCHAR(50)     NULL,
tr_ru      NVARCHAR(50)     NULL,
tr_nl      NVARCHAR(50)     NULL,
tr_th      NVARCHAR(50)     NULL,
tr_cs      NVARCHAR(50)     NULL,
tr_uk      NVARCHAR(50)     NULL,
tr_no      NVARCHAR(50)     NULL,
tr_ko      NVARCHAR(50)     NULL,
tr_sk      NVARCHAR(50)     NULL,
tr_pl      NVARCHAR(50)     NULL,
tr_vn      NVARCHAR(50)     NULL,

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

ALTER TABLE k_invoice_payments ADD dt_paid DATETIME NULL
GO;

ALTER TABLE k_invoice_payments ADD dt_expire DATETIME NULL
GO;

ALTER TABLE k_invoice_payments ADD id_ref VARCHAR(50) NULL
GO;

ALTER TABLE k_invoice_payments ADD id_transact VARCHAR(50) NULL
GO;

ALTER TABLE k_x_course_bookings ADD gu_invoice CHAR(32) NULL
GO;

ALTER TABLE k_x_list_members ADD mov_phone VARCHAR(16) NULL
GO;

INSERT INTO k_sequences VALUES ('seq_k_transactions', 1, 999999, 1, 1)
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

CREATE VIEW v_active_company_address WITH SCHEMABINDING AS
SELECT x.gu_company,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,
a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,
a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,
a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,
a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks
FROM dbo.k_addresses a, dbo.k_x_company_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
GO;
CREATE UNIQUE CLUSTERED INDEX i1_active_company_address ON v_active_company_address(gu_company,gu_address)
GO;
CREATE INDEX i2_active_company_address ON v_active_company_address(gu_workarea)
GO;
CREATE VIEW v_company_address WITH SCHEMABINDING AS
SELECT c.gu_workarea,c.gu_company,c.nm_legal,c.nm_commercial,c.dt_modified,c.id_legal,c.id_ref,
c.id_sector,c.id_status,c.tp_company,c.de_company,b.gu_address,b.ix_address,b.tp_location,
b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,
ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,
b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,
b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,
b.tx_email,b.url_addr,b.contact_person,b.id_ref AS id_addrref,b.tx_remarks,c.bo_restricted,
c.gu_geozone,c.gu_sales_man,c.tx_franchise,c.id_batch
FROM dbo.k_companies c
LEFT OUTER JOIN dbo.v_active_company_address AS b ON c.gu_company=b.gu_company
GO;
CREATE VIEW v_contact_titles WITH SCHEMABINDING AS
SELECT vl_lookup,gu_owner,tr_es,tr_en FROM dbo.k_contacts_lookup WHERE id_section='de_title'
GO;
CREATE UNIQUE CLUSTERED INDEX i1_contact_titles ON v_contact_titles(gu_owner,vl_lookup)
GO;
CREATE VIEW v_active_contact_address WITH SCHEMABINDING AS
SELECT x.gu_contact,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,
a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,
a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,
a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,
a.contact_person,a.tx_salutation,a.tx_remarks
FROM dbo.k_addresses a, dbo.k_x_contact_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
GO;
CREATE UNIQUE CLUSTERED INDEX i1_active_contact_address ON v_active_contact_address(gu_contact,gu_address)
GO;
CREATE VIEW v_contact_company WITH SCHEMABINDING AS
SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,y.gu_company,y.nm_legal,
y.id_sector,y.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,
c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,
c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM dbo.k_contacts c, dbo.k_companies y WHERE c.gu_company=y.gu_company
GO;
CREATE UNIQUE CLUSTERED INDEX i1_contact_company ON v_contact_company(gu_contact)
GO;
CREATE VIEW v_contact_company_all AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM v_contact_company c)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL AS gu_company,NULL AS nm_legal,NULL AS id_sector,NULL AS tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM k_contacts c WHERE c.gu_company IS NULL)
GO;
CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM v_contact_company c
LEFT OUTER JOIN dbo.v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN dbo.v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM k_contacts c
LEFT OUTER JOIN dbo.v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN dbo.v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE c.gu_company IS NULL)
GO;
CREATE VIEW v_contact_address_title AS
SELECT b.*,l.gu_owner,l.id_section,l.pg_lookup,l.vl_lookup,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu FROM v_contact_address b LEFT OUTER JOIN k_contacts_lookup l ON b.de_title=l.vl_lookup
GO;
CREATE VIEW v_contact_list AS
SELECT c.gu_contact,ISNULL(c.tx_surname,'') + ', ' + ISNULL(c.tx_name,'') AS full_name,l.tr_es,l.tr_en,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner, c.bo_restricted, c.gu_geozone, c.gu_sales_man, c.id_batch
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
dt_created   DATETIME      DATETIME DEFAULT GETDATE(),
nm_reporter  NVARCHAR(50)      NULL,
tx_rep_mail  VARCHAR(100)      NULL,
gu_writer    CHAR(32)		   NULL,
tx_bug_track NVARCHAR(2000)    NULL,
CONSTRAINT pk_bugs_track PRIMARY KEY (gu_bug,pg_bug_track)
)
GO;

ALTER TABLE k_bugs_attach ADD pg_bug_track INTEGER NULL
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_bugs_track', 1, 2147483647, 1, 1)
GO;

DROP PROCEDURE k_sp_del_bug
GO;

CREATE PROCEDURE k_sp_del_bug @BugId CHAR(32) AS
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=@BugId
  DELETE FROM k_bugs_track WHERE gu_bug=@BugId
  DELETE FROM k_bugs_changelog WHERE gu_bug=@BugId
  DELETE FROM k_bugs_attach WHERE gu_bug=@BugId
  DELETE FROM k_bugs WHERE gu_bug=@BugId
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_adhoc_mailings', 1, 2147483647, 1, 1)
GO;

CREATE TABLE k_adhoc_mailings (
  gu_mailing     CHAR(32) NOT NULL,
  gu_workarea    CHAR(32) NOT NULL,
  gu_writer      CHAR(32) NOT NULL,
  pg_mailing     INTEGER  NOT NULL,
  dt_created     DATETIME DEFAULT GETDATE(),  
  nm_mailing     NVARCHAR(30) NOT NULL,
  bo_html_part   SMALLINT NOT NULL,
  bo_plain_part  SMALLINT NOT NULL,
  bo_attachments SMALLINT NOT NULL,
  id_status      VARCHAR(30) NULL,
  dt_modified    DATETIME NULL,
  dt_execution   DATETIME NULL,
  tx_email_from  VARCHAR(254) NULL,
  tx_email_reply VARCHAR(254) NULL,  
  nm_from        NVARCHAR(254)  NULL,
  tx_subject     NVARCHAR(254)  NULL,
  tx_allow_regexp NVARCHAR(254) NULL,
  tx_deny_regexp NVARCHAR(254)  NULL,
  tx_parameters  NVARCHAR(2000) NULL,
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
vl_lookup  NVARCHAR(255)     NULL,
tr_es      NVARCHAR(50)      NULL,
tr_en      NVARCHAR(50)      NULL,
tr_de      NVARCHAR(50)      NULL,
tr_it      NVARCHAR(50)      NULL,
tr_fr      NVARCHAR(50)      NULL,
tr_pt      NVARCHAR(50)      NULL,
tr_ca      NVARCHAR(50)      NULL,
tr_gl      NVARCHAR(50)      NULL,
tr_eu      NVARCHAR(50)      NULL,
tr_ja      NVARCHAR(50)      NULL,
tr_cn      NVARCHAR(50)      NULL,
tr_tw      NVARCHAR(50)      NULL,
tr_fi      NVARCHAR(50)      NULL,
tr_ru      NVARCHAR(50)      NULL,
tr_nl      NVARCHAR(50)      NULL,
tr_th      NVARCHAR(50)      NULL,
tr_cs      NVARCHAR(50)      NULL,
tr_uk      NVARCHAR(50)      NULL,
tr_no      NVARCHAR(50)      NULL,
tr_ko      NVARCHAR(50)      NULL,
tr_sk      NVARCHAR(50)      NULL,
tr_pl      NVARCHAR(50)      NULL,
tr_vn      NVARCHAR(50)      NULL,

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
dt_created  DATETIME  DEFAULT GETDATE(),
tx_name     NVARCHAR(100) NULL,
tx_surname  NVARCHAR(100) NULL,
gu_contact  CHAR(32) NULL,
gu_address  CHAR(32) NULL,

CONSTRAINT pk_global_black_list PRIMARY KEY (id_domain,gu_workarea,tx_email)
)
GO;
