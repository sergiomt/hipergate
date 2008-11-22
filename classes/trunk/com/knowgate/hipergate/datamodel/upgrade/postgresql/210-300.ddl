UPDATE k_version SET VS_STAMP='3.0.0'
GO;
INSERT INTO k_microsites (gu_microsite,tp_microsite,nm_microsite,path_metadata,id_app) VALUES ('SURVEYMICROSITEJIXBXMLDEFINITION',4,'Survey','xslt/templates/Survey/survey-def-jixb.xml',23)
GO;
INSERT INTO k_classes VALUES(4,'ACLPwd')
GO;
INSERT INTO k_classes VALUES(60,'Course')
GO;
INSERT INTO k_classes VALUES(61,'AcademicCourse')
GO;
INSERT INTO k_classes VALUES(62,'Subject')
GO;
INSERT INTO k_classes VALUES(63,'Evaluation')
GO;
INSERT INTO k_classes VALUES(64,'Absentism')
GO;
INSERT INTO k_classes VALUES(99,'WelcomePack');
GO;
CREATE SEQUENCE seq_k_contact_refs INCREMENT 1 START 10000
GO;
CREATE SEQUENCE seq_k_welcme_pak INCREMENT 1 START 1
GO;

CREATE TABLE k_lu_unlocode (
  id_country CHAR(3) NOT NULL,
  id_place   CHAR(3) NOT NULL,
  nm_place   VARCHAR(50) NOT NULL,
  bo_active  SMALLINT NOT NULL,
  bo_port    SMALLINT NOT NULL,
  bo_rail    SMALLINT NOT NULL,
  bo_road    SMALLINT NOT NULL,
  bo_airport SMALLINT NOT NULL,
  bo_postal  SMALLINT NOT NULL,
  id_status  CHAR(2)  NOT NULL,
  id_iata    CHAR(3)  NULL,
  id_state   CHAR(9)  NULL,
  coord_lat  VARCHAR(5) NULL,
  coord_long VARCHAR(6) NULL,
  CONSTRAINT pk_lu_unlocode PRIMARY KEY (id_country, id_place)
)
GO;

CREATE TABLE k_user_mail
(
    gu_account          CHAR(32)     NOT NULL,
    gu_user             CHAR(32)     NOT NULL,
    tl_account          VARCHAR(50)  NOT NULL,
    dt_created          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    bo_default          SMALLINT     NOT NULL,
    bo_synchronize      SMALLINT     DEFAULT 0,
    tx_main_email       VARCHAR(100) NOT NULL,
    tx_reply_email      VARCHAR(100) NULL,
    incoming_protocol   VARCHAR(6)   DEFAULT 'pop3',
    incoming_account    VARCHAR(100) NULL,
    incoming_password   VARCHAR(50)  NULL,
    incoming_server     VARCHAR(100) NULL,
    incoming_spa	SMALLINT DEFAULT 0,
    incoming_ssl	SMALLINT DEFAULT 0,
    incoming_port	SMALLINT DEFAULT 110,
    outgoing_protocol   VARCHAR(6)   DEFAULT 'smtp',
    outgoing_account    VARCHAR(100) NULL,
    outgoing_password   VARCHAR(50)  NULL,
    outgoing_server     VARCHAR(100) NULL,
    outgoing_spa	SMALLINT DEFAULT 0,
    outgoing_ssl	SMALLINT DEFAULT 0,
    outgoing_port	SMALLINT DEFAULT 25,
    
    CONSTRAINT pk_user_mail PRIMARY KEY (gu_account),
    CONSTRAINT u1_user_mail UNIQUE (gu_user,tl_account)
)
GO;

CREATE TABLE k_user_pwd
(
    gu_pwd              CHAR(32)      NOT NULL,
    gu_user             CHAR(32)      NOT NULL,
    tl_pwd              VARCHAR(50)   NOT NULL,
    tp_pwd              VARCHAR(30)   NOT NULL,
    dt_created          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    tx_nickname         VARCHAR(100)  NOT NULL,
    tx_pwd              VARCHAR(50)   NOT NULL,
    tx_pwd_sign         VARCHAR(50)   NULL,
    tx_account          VARCHAR(50)   NULL,
    tx_expire           VARCHAR(10)   NULL,
    nu_cvv2             VARCHAR(4)    NULL,
    url_addr            VARCHAR(254)  NULL,
    tx_comments         VARCHAR(254)  NULL,
    tx_prk              VARCHAR(2000) NULL,
    tx_pbk              VARCHAR(2000) NULL,
    bin_key             BYTEA NULL,

    CONSTRAINT pk_user_pwd PRIMARY KEY (gu_pwd)
)
GO;

CREATE TABLE k_despatch_advices (
  gu_despatch    CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_despatch    INTEGER       NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  dt_created     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  bo_approved    SMALLINT      DEFAULT 1,
  bo_credit_ok   SMALLINT      DEFAULT 1,
  id_priority    VARCHAR(16)   NULL,
  gu_warehouse   CHAR(32)      NULL,
  dt_modified    TIMESTAMP     NULL,
  dt_delivered   TIMESTAMP     NULL,
  dt_printed     TIMESTAMP     NULL,
  dt_promised    TIMESTAMP     NULL,
  dt_payment     TIMESTAMP     NULL,
  dt_cancel      TIMESTAMP     NULL,
  de_despatch    VARCHAR(255)  NULL,
  tx_location    VARCHAR(100)  NULL,
  gu_company     CHAR(32)      NULL,
  gu_contact     CHAR(32)      NULL,
  nm_client	 VARCHAR(200)  NULL,
  id_legal       VARCHAR(16)   NULL,
  gu_ship_addr   CHAR(32)      NULL,
  gu_bill_addr   CHAR(32)      NULL,
  id_ref         VARCHAR(50)   NULL,
  id_status      VARCHAR(50)   NULL,
  id_pay_status  VARCHAR(50)   NULL,
  id_ship_method VARCHAR(30)   NULL,
  im_subtotal    DECIMAL(14,4) NULL,
  im_taxes       DECIMAL(14,4) NULL,
  im_shipping    DECIMAL(14,4) NULL,
  im_discount    VARCHAR(10)   NULL,
  im_total       DECIMAL(14,4) NULL,
  tx_ship_notes  VARCHAR(254)  NULL,
  tx_email_to    VARCHAR(100)  NULL,
  tx_comments    VARCHAR(254)  NULL,

  CONSTRAINT pk_despatch_advices PRIMARY KEY(gu_despatch)
)
GO;

CREATE TABLE k_despatch_lines (
  gu_despatch     CHAR(32)      NOT NULL,
  pg_line         INTEGER       NOT NULL,
  pr_sale         DECIMAL(14,4) NULL,
  nu_quantity     FLOAT	        NULL,
  id_unit         VARCHAR(16)   DEFAULT 'UNIT',
  pr_total        DECIMAL(14,4) NULL,
  pct_tax_rate    FLOAT         NULL,
  is_tax_included SMALLINT      NULL,
  nm_product      VARCHAR(128)  NOT NULL,
  gu_product      CHAR(32)      NULL,
  gu_item         CHAR(32)      NULL,
  id_status       VARCHAR(50)       NULL,
  tx_promotion    VARCHAR(100)  NULL,
  tx_options      VARCHAR(254)  NULL,

  CONSTRAINT pk_despatch_lines PRIMARY KEY(gu_despatch,pg_line),
  CONSTRAINT c1_despatch_lines CHECK (pg_line>0)
)
GO;

CREATE TABLE k_despatch_advices_lookup
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
tr_sk      VARCHAR(50)      NULL,

CONSTRAINT pk_despatch_advices_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_despatch_advices_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_x_orders_despatch
(
  gu_order    CHAR(32) NOT NULL,
  gu_despatch CHAR(32) NOT NULL,

  CONSTRAINT pk_x_orders_despatch PRIMARY KEY(gu_order,gu_despatch)
)
GO;

CREATE TABLE k_despatch_next
(
  gu_workarea CHAR(32) NOT NULL,
  pg_despatch INTEGER  NOT NULL,
  CONSTRAINT pk_despatch_next PRIMARY KEY(gu_workarea,pg_despatch)
)
GO;

CREATE TABLE k_returned_invoices (
  gu_returned    CHAR(32)      NOT NULL,
  gu_invoice     CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_returned    INTEGER       NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  id_legal       VARCHAR(16)   NOT NULL,
  dt_created     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  bo_active      SMALLINT      DEFAULT 1,
  bo_approved    SMALLINT      DEFAULT 1,
  dt_modified    TIMESTAMP          NULL,
  dt_returned    TIMESTAMP          NULL,
  dt_printed     TIMESTAMP          NULL,
  de_returned    VARCHAR(100)       NULL,
  gu_company     CHAR(32)           NULL,
  gu_contact     CHAR(32)           NULL,
  nm_client	 VARCHAR(200)       NULL,
  gu_bill_addr   CHAR(32)           NULL,
  id_ref         VARCHAR(50)        NULL,
  id_status      VARCHAR(30)        NULL,
  id_pay_status  VARCHAR(30)        NULL,
  id_ship_method VARCHAR(30)        NULL,
  im_subtotal    DECIMAL(14,4)      NULL,
  im_taxes       DECIMAL(14,4)      NULL,
  im_shipping    DECIMAL(14,4)      NULL,
  im_discount    VARCHAR(10)        NULL,
  im_total       DECIMAL(14,4)      NULL,
  tp_billing     CHAR(1)            NULL,
  nu_bank   	 CHAR(20)           NULL,
  tx_email_to    VARCHAR(100)       NULL,
  tx_comments    VARCHAR(254)       NULL,

  CONSTRAINT pk_returned_invoices PRIMARY KEY(gu_returned),
  CONSTRAINT c1_returned_invoices CHECK (dt_printed IS NULL OR dt_printed>=dt_modified),
  CONSTRAINT c2_returned_invoices CHECK (dt_returned IS NULL OR dt_returned>=dt_modified)
)
GO;

CREATE TABLE k_invoices_next
(
  gu_workarea    CHAR(32)     NOT NULL,
  pg_invoice     INTEGER      NOT NULL,
  CONSTRAINT pk_invoices_next PRIMARY KEY(gu_workarea,pg_invoice)
)
GO;

CREATE TABLE k_project_costs
(
gu_cost      CHAR(32)         NOT NULL,
gu_project   CHAR(32)         NOT NULL,
dt_created   TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
dt_modified  TIMESTAMP            NULL,
gu_writer    CHAR(32)         NOT NULL,
gu_user      CHAR(32)         NOT NULL,
tl_cost      VARCHAR(100)     NOT NULL,
pr_cost      FLOAT            NOT NULL,
tp_cost      VARCHAR(30)          NULL,
dt_cost      TIMESTAMP            NULL,
de_cost      VARCHAR(1000)        NULL,
CONSTRAINT pk_project_costs PRIMARY KEY (gu_cost),
CONSTRAINT f1_project_costs FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

CREATE TABLE k_duties_dependencies
(
gu_previous CHAR(32)    NOT NULL,
gu_next     CHAR(32)    NOT NULL,
ti_gap      DECIMAL(20,4) DEFAULT 0,
CONSTRAINT  pk_duties_dependencies PRIMARY KEY (gu_previous,gu_next),
CONSTRAINT  f1_duties_dependencies FOREIGN KEY (gu_previous) REFERENCES k_duties(gu_duty),
CONSTRAINT  f2_duties_dependencies FOREIGN KEY (gu_next) REFERENCES k_duties(gu_duty)
)
GO;

CREATE TABLE k_bugs_changelog (
gu_bug       CHAR(32)      NOT NULL,
pg_bug       INTEGER       NOT NULL,
nm_column    VARCHAR(18)   NOT NULL,
dt_modified  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
gu_writer    CHAR(32)      NULL,
tx_oldvalue  VARCHAR(255)  NULL
)
GO;

CREATE TABLE k_login_audit (
bo_success    CHAR(1)   NOT NULL,
nu_error      INTEGER   NOT NULL,
dt_login      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
gu_user       CHAR(32)  NULL,
tx_email      VARCHAR(100) NULL,
tx_pwd        VARCHAR(50) NULL,
gu_workarea   CHAR(32)  NULL,
ip_addr       VARCHAR(15) NULL
)
GO;

ALTER TABLE k_lu_currencies ADD nu_conversion DECIMAL(20,8) NULL
GO;
ALTER TABLE k_order_lines ADD id_status VARCHAR(50) NULL
GO;
ALTER TABLE k_prod_attr ADD nu_lines INTEGER NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_pl VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_nl VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_th VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_cs VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_uk VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_no VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_pl VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_nl VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_th VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_cs VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_uk VARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_no VARCHAR(50) NULL
GO;
ALTER TABLE k_users ADD tx_pwd_sign VARCHAR(50) NULL
GO;
ALTER TABLE k_sales_men DROP CONSTRAINT f3_sales_men
GO;
ALTER TABLE k_products ADD gu_address CHAR(32) NULL
GO;
ALTER TABLE k_mime_msgs ADD bo_indexed SMALLINT
GO;
ALTER TABLE k_job_atoms ADD tp_recipient VARCHAR(4) NULL
GO;
ALTER TABLE k_job_atoms ADD tx_log VARCHAR(254) NULL
GO;
ALTER TABLE k_duties ADD ti_duration DECIMAL(20,4) NULL
GO;
ALTER TABLE k_meetings ADD gu_writer CHAR(32) NULL
GO;
ALTER TABLE k_meetings ADD dt_created TIMESTAMP NULL
GO;
ALTER TABLE k_meetings ADD dt_modified TIMESTAMP NULL
GO;
ALTER TABLE k_meetings ADD tx_status VARCHAR(50) NULL
GO;
ALTER TABLE k_phone_calls ADD gu_bug CHAR(32) NULL
GO;
ALTER TABLE k_invoice_lines DROP CONSTRAINT f1_invoice_lines
GO;
ALTER TABLE k_order_lines ADD id_unit VARCHAR(16)
GO;
ALTER TABLE k_invoice_lines ADD id_unit VARCHAR(16)
GO;
ALTER TABLE k_shops ADD id_legal VARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD nm_company VARCHAR(70) NULL
GO;
ALTER TABLE k_shops ADD tp_street VARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD nm_street VARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD nu_street VARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD tx_addr1 VARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD tx_addr2 VARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD id_country CHAR(3) NULL
GO;
ALTER TABLE k_shops ADD nm_country VARCHAR(50) NULL
GO;
ALTER TABLE k_shops ADD id_state VARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD nm_state VARCHAR(30) NULL
GO;
ALTER TABLE k_shops ADD mn_city	VARCHAR(50) NULL
GO;
ALTER TABLE k_shops ADD zipcode	VARCHAR(30) NULL
GO;
ALTER TABLE k_shops ADD work_phone VARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD direct_phone VARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD fax_phone VARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD tx_email VARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD url_addr VARCHAR(254) NULL
GO;
ALTER TABLE k_shops ADD contact_person VARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD tx_salutation VARCHAR(16) NULL
GO;
ALTER TABLE k_products ADD pr_discount DECIMAL(14,4) NULL;
GO;
ALTER TABLE k_invoice_lines ADD gu_item CHAR(32) NULL;
GO;
ALTER TABLE k_invoices ADD im_paid DECIMAL(14,4) NULL;
GO;
ALTER TABLE k_contacts ADD sn_drivelic VARCHAR(16) NULL;
GO;
ALTER TABLE k_contacts ADD dt_drivelic TIMESTAMP NULL;
GO;
ALTER TABLE k_contacts ADD tp_contact VARCHAR(30) NULL;
GO;

DROP FUNCTION k_sp_del_product (CHAR)
GO;

CREATE FUNCTION k_sp_del_product (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_products WHERE gu_product=$1);
  DELETE FROM k_images WHERE gu_product=$1;
  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  DELETE FROM k_prod_keywords WHERE gu_product=$1;
  DELETE FROM k_prod_fares WHERE gu_product=$1;
  DELETE FROM k_prod_attrs WHERE gu_object=$1;
  DELETE FROM k_prod_attr WHERE gu_product=$1;
  DELETE FROM k_prod_locats WHERE gu_product=$1;
  DELETE FROM k_products WHERE gu_product=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
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
  CityNm	VARCHAR(50) ;
  Zipcode	VARCHAR(30) ;
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
    SELECT gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box
      INTO CompGu,ContGu,EMailTx,NameTx,SurnTx,SalutTx,CommNm,StreetTp,StreetNm,StreetNu,Addr1Tx,Addr2Tx,CountryNm,StateNm,CityNm	,Zipcode,WorkPhone,DirectPhone,HomePhone,MobilePhone,FaxPhone,OtherPhone,PoBox
      FROM k_member_address WHERE gu_workarea=$3 AND tx_email=EMailTx LIMIT 1;
    IF FOUND THEN
      UPDATE k_job_atoms SET gu_company=CompGu,gu_contact=ContGu,tx_name=NameTx,tx_surname=SurnTx,tx_salutation=SalutTx,nm_commercial=CommNm,tp_street=StreetTp,nm_street=StreetNm,nu_street=StreetNu,tx_addr1=Addr1Tx,tx_addr2=Addr2Tx,nm_country=CountryNm,nm_state=StateNm,mn_city=CityNm,zipcode=Zipcode,work_phone=WorkPhone,direct_phone=DirectPhone,home_phone=HomePhone,mov_phone=MobilePhone,fax_phone=FaxPhone,other_phone=OtherPhone,po_box=PoBox
       WHERE gu_job=$1 AND pg_atom=$2;
    END IF;
  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_resolve_atoms (CHAR) RETURNS INTEGER AS '
DECLARE
  WrkAGu CHAR(32);
  AtomPg INTEGER ;
  Atoms CURSOR (id CHAR(32)) FOR SELECT pg_atom FROM k_job_atoms WHERE gu_job=id;
BEGIN
  SELECT gu_workarea INTO WrkAGu FROM k_jobs WHERE gu_job=$1;
  OPEN Atoms($1);
    LOOP
      FETCH Atoms INTO AtomPg;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_resolve_atom ($1,AtomPg,WrkAGu);
    END LOOP;
  CLOSE Atoms;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_prj_cost (CHAR)
GO;

CREATE FUNCTION k_sp_prj_cost (CHAR) RETURNS FLOAT AS '
DECLARE
  proj k_projects%ROWTYPE;
  fCost FLOAT := 0;
  fMore FLOAT := 0;
BEGIN
  SELECT COALESCE(SUM(pr_cost),0) INTO fMore FROM k_project_costs WHERE gu_project=$1;

  SELECT COALESCE(SUM(d.pr_cost),0) INTO fCost FROM k_duties d, k_projects p WHERE d.gu_project=p.gu_project AND p.gu_project=$1 AND d.pr_cost IS NOT NULL;

  FOR proj IN SELECT gu_project FROM k_projects WHERE id_parent=$1 LOOP
    fCost = fCost + k_sp_prj_cost (proj.gu_project);
  END LOOP;

  RETURN fCost+fMore;
END;
' LANGUAGE 'plpgsql';
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

  DELETE FROM k_project_costs WHERE gu_project=$1;
  DELETE FROM k_project_expand WHERE gu_project=$1;
  DELETE FROM k_projects WHERE gu_project=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_bug (CHAR)
GO;

CREATE FUNCTION k_sp_del_bug (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=$1;
  DELETE FROM k_bugs_changelog WHERE gu_bug=$1;
  DELETE FROM k_bugs_attach WHERE gu_bug=$1;
  DELETE FROM k_bugs WHERE gu_bug=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_duty (CHAR)
GO;

CREATE FUNCTION k_sp_del_duty (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_duties_dependencies WHERE gu_previous=$1 OR gu_next=$1;
  DELETE FROM k_x_duty_resource WHERE gu_duty=$1;
  DELETE FROM k_duties_attach WHERE gu_duty=$1;
  DELETE FROM k_duties WHERE gu_duty=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_cat_grp_perm (CHAR, CHAR)
GO;

CREATE FUNCTION k_sp_cat_grp_perm (CHAR, CHAR) RETURNS INTEGER AS '
DECLARE
  ACLMask INTEGER;
  IdParent CHAR(32);
BEGIN
  SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=$2 AND gu_acl_group=$1;
  IF NOT FOUND THEN
    SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=$2 LIMIT 1;
    IF NOT FOUND THEN
      ACLMask:=0;
    ELSIF IdParent=$2 OR IdParent IS NULL THEN
      ACLMask:=0;
    ELSE
      RETURN k_sp_cat_grp_perm($1,IdParent);
    END IF;
  END IF;
  IF ACLMask IS NULL THEN
    RETURN 0;
  ELSE
    RETURN ACLMask;
  END IF;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_count_thread_msgs (CHAR)
GO;

CREATE FUNCTION k_sp_count_thread_msgs (CHAR) RETURNS INTEGER AS '
DECLARE
  MsgCount INTEGER;
BEGIN
  SELECT nu_thread_msgs INTO MsgCount FROM k_newsmsgs WHERE gu_thread_msg=$1 LIMIT 1;
  IF NOT FOUND THEN
    MsgCount := 0;
  END IF;
  RETURN MsgCount;
END;
' LANGUAGE 'plpgsql';
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
  DeCompany	VARCHAR(254);

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
  TxName        VARCHAR(100);
  TxSurname     VARCHAR(100);
  DeTitle       VARCHAR(50);
  TrTitle       VARCHAR(50);
  DtBirth       TIMESTAMP;
  SnPassport    VARCHAR(16);
  IdGender      CHAR(1);
  NyAge         SMALLINT;
  TxDept        VARCHAR(70);
  TxDivision    VARCHAR(70);
  TxComments    VARCHAR(254);

BEGIN
  SELECT gu_company,gu_workarea,
         CASE WHEN char_length(tx_name)=0 THEN NULL ELSE tx_name END,
         CASE WHEN char_length(tx_surname)=0 THEN NULL ELSE tx_surname END,
         de_title,dt_birth,sn_passport,id_gender,ny_age,tx_dept,tx_division,tx_comments
  INTO   GuCompany,GuWorkArea,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,TxDept,TxDivision,TxComments
  FROM k_contacts WHERE gu_contact=NEW.gu_contact;

  IF DeTitle IS NOT NULL THEN
    SELECT tr_en INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section=''de_title'' AND vl_lookup=DeTitle;
    IF NOT FOUND THEN
      UPDATE k_member_address SET gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,
                                  de_title=DeTitle,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,
                                  ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments
      WHERE gu_contact=NEW.gu_contact;
    ELSE
      UPDATE k_member_address SET gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,
                                  tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,
                                  tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments
      WHERE gu_contact=NEW.gu_contact;
    END IF;
  ELSE
      UPDATE k_member_address SET gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,
                                  de_title=NULL,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,
                                  ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments
      WHERE gu_contact=NEW.gu_contact;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql'
GO;

CREATE TRIGGER k_tr_upd_cont AFTER UPDATE ON k_contacts FOR EACH ROW EXECUTE PROCEDURE k_sp_upd_cont()
GO;

DROP FUNCTION k_sp_write_inet_addr (INTEGER,CHAR,CHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR)
GO;

CREATE FUNCTION k_sp_write_inet_addr (INTEGER,CHAR,CHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) RETURNS INTEGER AS '
DECLARE
  UserId CHAR(32);
  ContactId CHAR(32);
  CompanyId CHAR(32);
  FullName VARCHAR(254);
  PersonalTx VARCHAR(254);
  Users CURSOR IS SELECT gu_user,TRIM(COALESCE(nm_user)||'' ''||COALESCE(tx_surname1)||'' ''||COALESCE(tx_surname2)) AS full_name FROM k_users WHERE id_domain=$1 AND tx_main_email=$5;
  Contacts CURSOR IS SELECT gu_company,gu_contact,TRIM(COALESCE(tx_name)||'' ''||COALESCE(tx_surname)) AS full_name FROM k_member_address WHERE gu_workarea=$2 AND tx_email=$5;
BEGIN
  PersonalTx:=$7;
  OPEN Users;
    FETCH Users INTO UserId,FullName;
    IF FOUND THEN
      IF $7 IS NULL THEN
	PersonalTx:=FullName;
      END IF;
    ELSE
      UserId := NULL;
    END IF;    
  CLOSE Users;
  OPEN Contacts;
    FETCH Contacts INTO CompanyId,ContactId,FullName;
    IF FOUND THEN
      IF $7 IS NULL THEN
        PersonalTx:=FullName;
      END IF;
    ELSE
      ContactId := NULL;
      CompanyId := NULL;
    END IF;    
  CLOSE Contacts;

  INSERT INTO k_inet_addrs (gu_mimemsg,id_message,tx_email,tp_recipient,tx_personal,gu_user,gu_contact,gu_company) VALUES ($3,$4,$5,$6,PersonalTx,UserId,ContactId,CompanyId);

  RETURN 0;
END;
' LANGUAGE 'plpgsql'
GO;