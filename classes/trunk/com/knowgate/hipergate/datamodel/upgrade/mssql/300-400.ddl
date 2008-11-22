ALTER TABLE k_version ADD dt_created DATETIME NULL;
GO;
ALTER TABLE k_version ADD dt_modified DATETIME NULL;
GO;
ALTER TABLE k_version ADD bo_register SMALLINT NULL;
GO;
ALTER TABLE k_version ADD gu_support CHAR(32) NULL;
GO;
ALTER TABLE k_version ADD gu_contact CHAR(32)NULL;
GO;
ALTER TABLE k_version ADD tx_name NVARCHAR(100) NULL;
GO;
ALTER TABLE k_version ADD tx_surname NVARCHAR(100) NULL;
GO;
ALTER TABLE k_version ADD nu_employees INTEGER NULL;
GO;
ALTER TABLE k_version ADD nm_company NVARCHAR(70) NULL;
GO;
ALTER TABLE k_version ADD id_sector NVARCHAR(16) NULL;
GO;
ALTER TABLE k_version ADD id_country CHAR(3) NULL;
GO;
ALTER TABLE k_version ADD nm_state NVARCHAR(30) NULL;
GO;
ALTER TABLE k_version ADD mn_city NVARCHAR(50) NULL;
GO;
ALTER TABLE k_version ADD zipcode NVARCHAR(30) NULL;
GO;
ALTER TABLE k_version ADD work_phone VARCHAR(16) NULL;
GO;
ALTER TABLE k_version ADD tx_email VARCHAR(70) NULL;
GO;
UPDATE k_version SET vs_stamp='4.0.0'
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_msg_votes', 1, 2147483647, 1, 1)
GO;

ALTER TABLE k_newsmsgs ADD nu_votes INTEGER DEFAULT 0
GO;

CREATE TABLE k_newsmsg_vote (
  gu_msg     CHAR(32)               NOT NULL,
  pg_vote    INTEGER                NOT NULL,
  dt_published DATETIME             DEFAULT GETDATE(),
  od_score   INTEGER         	    NULL,
  ip_addr    VARCHAR(254) 	    NULL,
  nm_author  NVARCHAR(200)           NULL,
  gu_writer  CHAR(32)               NULL,
  tx_email   VARCHAR(100) 	    NULL,
  tx_vote    NVARCHAR(254)          NULL,
  CONSTRAINT pk_newsmsg_vote PRIMARY KEY (gu_msg,pg_vote)
)
GO;

DROP PROCEDURE k_sp_del_newsgroup
GO;

CREATE PROCEDURE k_sp_del_newsgroup @IdNewsGroup CHAR(32) AS
  DELETE k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsgroup_subscriptions WHERE gu_newsgrp=@IdNewsGroup
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
  DELETE k_x_cat_objs WHERE gu_object=@IdNewsMsg
  DELETE k_newsmsg_vote WHERE gu_msg=@IdNewsMsg
  DELETE k_newsmsgs WHERE gu_msg=@IdNewsMsg
GO;

CREATE TABLE k_distances_cache
(
  lo_from   NVARCHAR(254) NOT NULL,
  lo_to     NVARCHAR(254) NOT NULL,
  nu_km     FLOAT        NOT NULL,
  id_locale VARCHAR(8)   NOT NULL,
  coord_x   FLOAT NULL,
  coord_y   FLOAT NULL,  
  CONSTRAINT pk_distances_cache PRIMARY KEY (lo_from,lo_to)  
)
GO;

ALTER TABLE k_meetings ADD gu_address CHAR(32) NULL
GO;

ALTER TABLE k_meetings ADD CONSTRAINT f4_meeting FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address)
GO;

ALTER TABLE k_meetings ADD pr_cost FLOAT NULL
GO;

CREATE PROCEDURE k_get_term_from_text @IdDomain INTEGER, @TxTerm VARCHAR(200), @GuTerm CHAR(32) OUTPUT AS
  SET @GuTerm=NULL
  SELECT TOP 1 @GuTerm=gu_term FROM k_thesauri WITH (NOLOCK) WHERE id_domain=@IdDomain AND (tx_term=@TxTerm OR tx_term2=@TxTerm)
GO;

CREATE TABLE k_lu_currencies_history
(
    alpha_code_from CHAR(3)   NOT NULL,
    alpha_code_to   CHAR(3)   NOT NULL,
    nu_conversion   DECIMAL(20,8) NOT NULL,
    dt_stamp        DATETIME  DEFAULT GETDATE(),
    CONSTRAINT pk_lu_currencies_history PRIMARY KEY (alpha_code_from,alpha_code_to,dt_stamp)
)
GO;

CREATE TABLE k_prod_fares_lookup
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
tr_sk      NVARCHAR(50)     NULL,
tr_pl      NVARCHAR(50)     NULL,

CONSTRAINT pk_prod_fares_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_prod_fares_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

ALTER TABLE k_companies ADD id_fare NVARCHAR(32) NULL
GO;
ALTER TABLE k_contacts ADD id_fare NVARCHAR(32) NULL
GO;

DROP TRIGGER k_tr_del_company
GO;
DROP TRIGGER k_tr_del_contact
GO;
DROP TRIGGER k_tr_del_address
GO;
ALTER TABLE k_member_address DROP CONSTRAINT f1_member_address
GO;
ALTER TABLE k_member_address ADD CONSTRAINT f1_member_address FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address) ON DELETE CASCADE
GO;
ALTER TABLE k_member_address DROP CONSTRAINT f3_member_address
GO;
ALTER TABLE k_member_address ADD CONSTRAINT f3_member_address FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company) ON DELETE SET NULL
GO;
ALTER TABLE k_member_address DROP CONSTRAINT f4_member_address
GO;
ALTER TABLE k_member_address ADD CONSTRAINT f4_member_address FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact) ON DELETE SET NULL
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

CREATE PROCEDURE k_sp_autenticate @IdUser CHAR(32), @PwdText VARCHAR(50), @CoStatus SMALLINT OUTPUT AS
  DECLARE @Password VARCHAR(50)
  DECLARE @Activated SMALLINT
  DECLARE @DtCancel DATETIME
  DECLARE @DtExpire DATETIME

  SET @Activated=NULL
  SET @CoStatus=1

  SELECT @Password=tx_pwd,@Activated=bo_active,@DtCancel=dt_cancel,@DtExpire=dt_pwd_expires FROM k_users WITH (NOLOCK) WHERE gu_user=@IdUser OPTION (FAST 1)

  IF (@Activated IS NULL)
    SET @CoStatus=-1
  ELSE
    BEGIN
      IF (@Password<>@PwdText AND @Password<>'(not set yet, change on next logon)')
        SET @CoStatus=-2
      ELSE
        BEGIN
	        IF @Activated=0
	          SET @CoStatus=-3
	        IF GETDATE()>@DtCancel
	          SET @CoStatus=-8
	        IF GETDATE()>@DtExpire
	          SET @CoStatus=-9
        END
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
dt_created   DATETIME DEFAULT GETDATE(),

CONSTRAINT pk_x_group_company PRIMARY KEY (gu_acl_group,gu_company),
CONSTRAINT f1_x_group_company FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups(gu_acl_group),
CONSTRAINT f2_x_group_company FOREIGN KEY (gu_company) REFERENCES k_companies(gu_company)
)
GO;

CREATE TABLE k_x_group_contact
(
gu_acl_group CHAR(32) NOT NULL,
gu_contact   CHAR(32) NOT NULL,
dt_created   DATETIME DEFAULT GETDATE(),

CONSTRAINT pk_x_group_contact PRIMARY KEY (gu_acl_group,gu_contact),
CONSTRAINT f1_x_group_contact FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups(gu_acl_group),
CONSTRAINT f2_x_group_contact FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact)
)
GO;

DROP PROCEDURE k_sp_del_group
GO;

CREATE PROCEDURE k_sp_del_group @IdGroup CHAR(32) AS
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=@IdGroup
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=@IdGroup
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=@IdGroup
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=@IdGroup
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=@IdGroup
  
  DELETE k_working_time WHERE gu_acl_group=@IdGroup
  DELETE k_x_group_company WHERE gu_acl_group=@IdGroup
  DELETE k_x_group_contact WHERE gu_acl_group=@IdGroup
  DELETE k_x_group_user WHERE gu_acl_group=@IdGroup
  DELETE k_x_cat_group_acl WHERE gu_acl_group=@IdGroup
  DELETE k_acl_groups WHERE gu_acl_group=@IdGroup
GO;

CREATE PROCEDURE k_sp_del_company
GO;

CREATE PROCEDURE k_sp_del_company @CompanyId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  DELETE k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=@CompanyId)

  DELETE k_welcome_packs WHERE gu_company=@CompanyId

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

CREATE PROCEDURE k_sp_del_contact
GO;

CREATE PROCEDURE k_sp_del_contact @ContactId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  DELETE k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=@ContactId)

  DELETE k_welcome_packs WHERE gu_contact=@ContactId

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

  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=@ContactId)
  DELETE k_oportunities WHERE gu_contact=@ContactId

  DELETE k_x_cat_objs WHERE gu_object=@ContactId AND id_class=90

  DELETE k_x_contact_prods WHERE gu_contact=@ContactId
  DELETE k_contacts_attrs WHERE gu_object=@ContactId
  DELETE k_contact_notes WHERE gu_contact=@ContactId
  DELETE k_contacts WHERE gu_contact=@ContactId
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

SET NUMERIC_ROUNDABORT OFF
GO;

SET ANSI_PADDING,ANSI_WARNINGS,CONCAT_NULL_YIELDS_NULL,ARITHABORT,QUOTED_IDENTIFIER,ANSI_NULLS ON
GO;

CREATE VIEW v_active_company_address WITH SCHEMABINDING AS
SELECT x.gu_company,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks FROM dbo.k_addresses a, dbo.k_x_company_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
GO;

CREATE UNIQUE CLUSTERED INDEX i1_active_company_address ON v_active_company_address(gu_company,gu_address)
GO;

CREATE INDEX i2_active_company_address ON v_active_company_address(gu_workarea)
GO;

CREATE VIEW v_company_address WITH SCHEMABINDING AS
SELECT c.gu_workarea,c.gu_company,c.nm_legal,c.nm_commercial,c.dt_modified,c.id_legal,c.id_ref,c.id_sector,c.id_status,c.tp_company,c.de_company,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.id_ref AS id_addrref,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.tx_franchise
FROM dbo.k_companies c
LEFT OUTER JOIN dbo.v_active_company_address AS b ON c.gu_company=b.gu_company
GO;

CREATE VIEW v_contact_titles WITH SCHEMABINDING AS
SELECT vl_lookup,gu_owner,tr_es,tr_en FROM dbo.k_contacts_lookup WHERE id_section='de_title'
GO;

CREATE UNIQUE CLUSTERED INDEX i1_contact_titles ON v_contact_titles(gu_owner,vl_lookup)
GO;

CREATE VIEW v_active_contact_address WITH SCHEMABINDING AS
SELECT x.gu_contact,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.tx_remarks FROM dbo.k_addresses a, dbo.k_x_contact_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
GO;

CREATE UNIQUE CLUSTERED INDEX i1_active_contact_address ON v_active_contact_address(gu_contact,gu_address)
GO;

CREATE VIEW v_contact_company WITH SCHEMABINDING AS
SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,y.gu_company,y.nm_legal,y.id_sector,y.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM dbo.k_contacts c, dbo.k_companies y WHERE c.gu_company=y.gu_company
GO;

CREATE UNIQUE CLUSTERED INDEX i1_contact_company ON v_contact_company(gu_contact)
GO;

CREATE VIEW v_contact_company_all AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL AS gu_company,NULL AS nm_legal,NULL AS id_sector,NULL AS tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM v_contact_company c
LEFT OUTER JOIN dbo.v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN dbo.v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man
FROM k_contacts c
LEFT OUTER JOIN dbo.v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN dbo.v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE c.gu_company IS NULL)
GO;

CREATE VIEW v_contact_address_title AS
SELECT b.*,l.gu_owner,l.id_section,l.pg_lookup,l.vl_lookup,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu FROM v_contact_address b LEFT OUTER JOIN k_contacts_lookup l ON b.de_title=l.vl_lookup
GO;

CREATE VIEW v_contact_list AS
SELECT c.gu_contact,ISNULL(c.tx_surname,'') + ', ' + ISNULL(c.tx_name,'') AS full_name,l.tr_es,l.tr_en,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner, c.bo_restricted,c.gu_geozone,c.gu_sales_man
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
    id_event    NVARCHAR(64) NOT NULL,
    dt_created  DATETIME DEFAULT GETDATE(),
    dt_modified DATETIME DEFAULT GETDATE(),
    bo_active   SMALLINT DEFAULT 1,
    gu_writer   CHAR(32) NOT NULL,
    id_command  CHAR(4)  NOT NULL,
    id_app      INTEGER  NOT NULL,
    gu_workarea CHAR(32) NULL,
    de_event    NVARCHAR(254) NULL,
    tx_parameters NVARCHAR(2000) NULL,
    
    CONSTRAINT pk_events PRIMARY KEY (id_domain,id_event)
)
GO;

CREATE PROCEDURE k_is_workarea_anyrole @IdWorkArea CHAR(32), @IdUser CHAR(32), @IsAny INTEGER OUTPUT AS
  DECLARE @IdGroup CHAR(32)

  SET @IdGroup=NULL
  SELECT TOP 1 @IdGroup=x.gu_acl_group FROM k_x_group_user x, k_x_app_workarea w WHERE (x.gu_acl_group=w.gu_admins OR x.gu_acl_group=w.gu_powusers OR x.gu_acl_group=w.gu_users OR x.gu_acl_group=w.gu_guests OR x.gu_acl_group=w.gu_other) AND x.gu_user=@IdUser AND w.gu_workarea=@IdWorkArea
  IF @IdGroup IS NULL
    SET @IsAny=0
  ELSE
    SET @IsAny=1
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
  dt_payment     DATETIME      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  im_paid        DECIMAL(14,4) NOT NULL,
  tp_billing     CHAR(1)       NULL,
  nm_client	     NVARCHAR(200)  NULL,
  tx_comments    NVARCHAR(254)  NULL,

  CONSTRAINT pk_invoice_payments PRIMARY KEY(gu_invoice,pg_payment)
)
GO;

CREATE TABLE k_project_snapshots
(
gu_snapshot CHAR(32)      NOT NULL,
gu_project  CHAR(32)      NOT NULL,
gu_writer   CHAR(32)      NOT NULL,
dt_created  DATETIME      DEFAULT GETDATE(),
tl_snapshot NVARCHAR(100) NOT NULL,
tx_snapshot NTEXT         NOT NULL,
CONSTRAINT pk_project_snapshots PRIMARY KEY (gu_snapshot),
CONSTRAINT f1_project_snapshots FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

CREATE TABLE k_duties_workreports
(
gu_workreport CHAR(32)      NOT NULL,
tl_workreport NVARCHAR(200) NOT NULL,
gu_writer     CHAR(32)      NOT NULL,
dt_created    DATETIME      DEFAULT GETDATE(),
gu_project    CHAR(32)      NULL,
de_workreport NVARCHAR(2000) NULL,
tx_workreport NTEXT         NOT NULL,
CONSTRAINT pk_duties_workreports PRIMARY KEY (gu_workreport),
CONSTRAINT f1_duties_workreports FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

DROP PROCEDURE k_sp_del_project
GO;

CREATE PROCEDURE k_sp_del_project @ProjId CHAR(32) AS
  DECLARE @chldid CHAR(32)
  DECLARE childs CURSOR LOCAL FAST_FORWARD FOR SELECT gu_project FROM k_projects WHERE id_parent=@ProjId
  
  /* Borrar primero recursivamente los proyectos hijos */
  OPEN childs
    FETCH NEXT FROM childs INTO @chldid
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_project @chldid
        FETCH NEXT FROM childs INTO @chldid
      END
  CLOSE childs
  
  DELETE k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId)
  DELETE k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId)
  DELETE k_duties WHERE gu_project=@ProjId

  DELETE k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=@ProjId)
  DELETE k_bugs WHERE gu_project=@ProjId

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=@ProjId

  DELETE FROM k_duties_workreports WHERE gu_project=@ProjId
  DELETE FROM k_project_snapshots WHERE gu_project=@ProjId
  DELETE FROM k_project_costs WHERE gu_project=@ProjId    
  DELETE k_project_expand WHERE gu_project=@ProjId
  DELETE k_projects WHERE gu_project=@ProjId
GO;

ALTER TABLE k_phone_calls ADD gu_oportunity CHAR(32) NULL
GO;

ALTER TABLE k_oportunities ADD lv_interest SMALLINT NULL
GO;

