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
CREATE SEQUENCE seq_k_contact_refs INCREMENT BY 1 START WITH 10000
GO;
CREATE SEQUENCE seq_k_welcme_pak INCREMENT BY 1 START WITH 1
GO;

CREATE TABLE k_lu_unlocode (
  id_country CHAR(3) NOT NULL,
  id_place   CHAR(3) NOT NULL,
  nm_place   VARCHAR2(50) NOT NULL,
  bo_active  NUMBER(1) NOT NULL,
  bo_port    NUMBER(1) NOT NULL,
  bo_rail    NUMBER(1) NOT NULL,
  bo_road    NUMBER(1) NOT NULL,
  bo_airport NUMBER(1) NOT NULL,
  bo_postal  NUMBER(1) NOT NULL,
  id_status  CHAR(2)   NOT NULL,
  id_iata    CHAR(3)     NULL,
  id_state   CHAR(9)     NULL,
  coord_lat  VARCHAR2(5) NULL,
  coord_long VARCHAR2(6) NULL,
  CONSTRAINT pk_lu_unlocode PRIMARY KEY (id_country, id_place)
)
GO;

CREATE TABLE k_user_mail
(
    gu_account          CHAR(32)      NOT NULL,
    gu_user             CHAR(32)      NOT NULL,
    tl_account          VARCHAR2(50)  NOT NULL,
    dt_created          DATE          DEFAULT SYSDATE,
    bo_default          NUMBER(2)     NOT NULL,
    bo_synchronize      NUMBER(2)     DEFAULT 0,
    tx_main_email       VARCHAR2(100) NOT NULL,
    tx_reply_email      VARCHAR2(100) NULL,
    incoming_protocol   VARCHAR2(6)   DEFAULT 'pop3',
    incoming_account    VARCHAR2(100) NULL,
    incoming_password   VARCHAR2(50)  NULL,
    incoming_server     VARCHAR2(100) NULL,
    incoming_spa	NUMBER(2) DEFAULT 0,
    incoming_ssl	NUMBER(2) DEFAULT 0,
    incoming_port	NUMBER(5) DEFAULT 110,
    outgoing_protocol   VARCHAR2(6)   DEFAULT 'smtp',
    outgoing_account    VARCHAR2(100) NULL,
    outgoing_password   VARCHAR2(50)  NULL,
    outgoing_server     VARCHAR2(100) NULL,
    outgoing_spa	NUMBER(2) DEFAULT 0,
    outgoing_ssl	NUMBER(2) DEFAULT 0,
    outgoing_port	NUMBER(5) DEFAULT 25,
    
    CONSTRAINT pk_user_mail PRIMARY KEY (gu_account),
    CONSTRAINT u1_user_mail UNIQUE (gu_user,tl_account)
)
GO;

CREATE TABLE k_user_pwd
(
    gu_pwd              CHAR(32)      NOT NULL,
    gu_user             CHAR(32)      NOT NULL,
    tl_pwd              VARCHAR2(50)  NOT NULL,
    tp_pwd              VARCHAR2(30)  NOT NULL,
    dt_created          DATE          DEFAULT SYSDATE,
    tx_nickname         VARCHAR2(100) NOT NULL,
    tx_pwd              VARCHAR2(50)  NOT NULL,
    tx_pwd_sign         VARCHAR2(50)  NULL,
    tx_account          VARCHAR2(50)  NULL,
    tx_expire           VARCHAR2(10)  NULL,
    nu_cvv2             VARCHAR2(4)   NULL,
    url_addr            VARCHAR2(254) NULL,
    tx_comments         VARCHAR2(254) NULL,
    tx_prk              VARCHAR2(2000) NULL,
    tx_pbk              VARCHAR2(2000) NULL,
    bin_key             LONG RAW       NULL,

    CONSTRAINT pk_user_pwd PRIMARY KEY (gu_pwd)
)
GO;

CREATE TABLE k_despatch_advices (
  gu_despatch    CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_despatch    NUMBER(11)    NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  dt_created     DATE          DEFAULT SYSDATE,
  bo_approved    NUMBER(2)     DEFAULT 1,
  bo_credit_ok   NUMBER(2)     DEFAULT 1,
  id_priority    VARCHAR2(16)  NULL,
  gu_warehouse   CHAR(32)      NULL,
  dt_modified    DATE          NULL,
  dt_delivered   DATE          NULL,
  dt_printed     DATE          NULL,
  dt_promised    DATE          NULL,
  dt_payment     DATE          NULL,
  dt_cancel      DATE          NULL,
  de_despatch    VARCHAR2(255) NULL,
  tx_location    VARCHAR2(100) NULL,
  gu_company     CHAR(32)      NULL,
  gu_contact     CHAR(32)      NULL,
  nm_client	 VARCHAR2(200) NULL,
  id_legal       VARCHAR2(16)  NULL,
  gu_ship_addr   CHAR(32)      NULL,
  gu_bill_addr   CHAR(32)      NULL,
  id_ref         VARCHAR2(50)  NULL,
  id_status      VARCHAR2(50)  NULL,
  id_pay_status  VARCHAR2(50)  NULL,
  id_ship_method VARCHAR2(30)  NULL,
  im_subtotal    NUMBER(14,4)  NULL,
  im_taxes       NUMBER(14,4)  NULL,
  im_shipping    NUMBER(14,4)  NULL,
  im_discount    VARCHAR2(10)  NULL,
  im_total       NUMBER(14,4)  NULL,
  tx_ship_notes  VARCHAR2(254) NULL,
  tx_email_to    VARCHAR2(100) NULL,
  tx_comments    VARCHAR2(254) NULL,

  CONSTRAINT pk_despatch_advices PRIMARY KEY(gu_despatch)
)
GO;

CREATE TABLE k_despatch_lines (
  gu_despatch     CHAR(32)      NOT NULL,
  pg_line         NUMBER(11)    NOT NULL,
  pr_sale         NUMBER(14,4)      NULL,
  nu_quantity     FLOAT	            NULL,
  id_unit         VARCHAR2(16)  DEFAULT 'UNIT',
  pr_total        NUMBER(14,4)      NULL,
  pct_tax_rate    FLOAT             NULL,
  is_tax_included NUMBER(2)         NULL,
  nm_product      VARCHAR2(128) NOT NULL,
  gu_product      CHAR(32)          NULL,
  gu_item         CHAR(32)          NULL,
  id_status       VARCHAR2(50)      NULL,
  tx_promotion    VARCHAR2(100)     NULL,
  tx_options      VARCHAR2(254)     NULL,

  CONSTRAINT pk_despatch_lines PRIMARY KEY(gu_despatch,pg_line),
  CONSTRAINT c1_despatch_lines CHECK (pg_line>0)
)
GO;

CREATE TABLE k_despatch_advices_lookup
(
gu_owner   CHAR(32)      NOT NULL,
id_section VARCHAR2(30)  NOT NULL,
pg_lookup  NUMBER(11)    NOT NULL,
vl_lookup  VARCHAR2(255)     NULL,
tr_es      VARCHAR2(50)      NULL,
tr_en      VARCHAR2(50)      NULL,
tr_de      VARCHAR2(50)      NULL,
tr_it      VARCHAR2(50)      NULL,
tr_fr      VARCHAR2(50)      NULL,
tr_pt      VARCHAR2(50)      NULL,
tr_ca      VARCHAR2(50)      NULL,
tr_eu      VARCHAR2(50)      NULL,
tr_ja      VARCHAR2(50)      NULL,
tr_cn      VARCHAR2(50)      NULL,
tr_tw      VARCHAR2(50)      NULL,
tr_fi      VARCHAR2(50)      NULL,
tr_ru      VARCHAR2(50)      NULL,
tr_nl      VARCHAR2(50)      NULL,
tr_th      VARCHAR2(50)      NULL,
tr_cs      VARCHAR2(50)      NULL,
tr_uk      VARCHAR2(50)      NULL,
tr_no      VARCHAR2(50)      NULL,
tr_sk      VARCHAR2(50)      NULL,

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
  gu_workarea CHAR(32)   NOT NULL,
  pg_despatch NUMBER(11) NOT NULL,
  CONSTRAINT pk_despatch_next PRIMARY KEY(gu_workarea,pg_despatch)
)
GO;

CREATE TABLE k_returned_invoices (
  gu_returned    CHAR(32)      NOT NULL,
  gu_invoice     CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_returned    NUMBER(11)    NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  id_legal       VARCHAR2(16)  NOT NULL,
  dt_created     DATE          DEFAULT SYSDATE,
  bo_active      NUMBER(5)     DEFAULT 1,
  bo_approved    NUMBER(5)     DEFAULT 1,
  dt_modified    DATE          NULL,
  dt_returned    DATE          NULL,
  dt_printed     DATE          NULL,
  de_returned    VARCHAR2(100) NULL,
  gu_company     CHAR(32)      NULL,
  gu_contact     CHAR(32)      NULL,
  nm_client	 VARCHAR2(200) NULL,
  gu_bill_addr   CHAR(32)      NULL,
  id_ref         VARCHAR2(50)  NULL,
  id_status      VARCHAR2(30)  NULL,
  id_pay_status  VARCHAR2(30)  NULL,
  id_ship_method VARCHAR2(30)  NULL,
  im_subtotal    NUMBER(14,4)  NULL,
  im_taxes       NUMBER(14,4)  NULL,
  im_shipping    NUMBER(14,4)  NULL,
  im_discount    VARCHAR2(10)  NULL,
  im_total       NUMBER(14,4)  NULL,
  tp_billing     CHAR(1)       NULL,
  nu_bank   	 CHAR(20)      NULL,
  tx_email_to    VARCHAR2(100) NULL,
  tx_comments    VARCHAR2(254) NULL,

  CONSTRAINT pk_returned_invoices PRIMARY KEY(gu_returned),
  CONSTRAINT c1_returned_invoices CHECK (dt_printed IS NULL OR dt_printed>=dt_modified),
  CONSTRAINT c2_returned_invoices CHECK (dt_returned IS NULL OR dt_returned>=dt_modified)
)
GO;

CREATE TABLE k_invoices_next
(
  gu_workarea    CHAR(32)     NOT NULL,
  pg_invoice     NUMBER(11)   NOT NULL,
  CONSTRAINT pk_invoices_next PRIMARY KEY(gu_workarea,pg_invoice)
)
GO;

CREATE TABLE k_project_costs
(
gu_cost      CHAR(32)         NOT NULL,
gu_project   CHAR(32)         NOT NULL,
dt_created   DATE             DEFAULT SYSDATE,
dt_modified  DATE                 NULL,
gu_writer    CHAR(32)         NOT NULL,
gu_user      CHAR(32)         NOT NULL,
tl_cost      VARCHAR2(100)    NOT NULL,
pr_cost      FLOAT            NOT NULL,
tp_cost      VARCHAR2(30)         NULL,
dt_cost      DATE                 NULL,
de_cost      VARCHAR2(1000)       NULL,
CONSTRAINT pk_project_costs PRIMARY KEY (gu_cost),
CONSTRAINT f1_project_costs FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

CREATE TABLE k_duties_dependencies
(
gu_previous CHAR(32)    NOT NULL,
gu_next     CHAR(32)    NOT NULL,
ti_gap      NUMBER(20)  DEFAULT 0,
CONSTRAINT  pk_duties_dependencies PRIMARY KEY (gu_previous,gu_next),
CONSTRAINT  f1_duties_dependencies FOREIGN KEY (gu_previous) REFERENCES k_duties(gu_duty),
CONSTRAINT  f2_duties_dependencies FOREIGN KEY (gu_next) REFERENCES k_duties(gu_duty)
)
GO;

CREATE TABLE k_bugs_changelog (
gu_bug       CHAR(32)      NOT NULL,
pg_bug       NUMBER(11)    NOT NULL,
nm_column    VARCHAR2(18)  NOT NULL,
dt_modified  DATE          DEFAULT SYSDATE,
gu_writer    CHAR(32)      NULL,
tx_oldvalue  VARCHAR2(255) NULL
)
GO;

CREATE TABLE k_login_audit (
bo_success    CHAR(1)   NOT NULL,
nu_error      NUMBER(6) NOT NULL,
dt_login      DATE DEFAULT SYSDATE,
gu_user       CHAR(32) NULL,
tx_email      VARCHAR2(100) NULL,
tx_pwd        VARCHAR2(50) NULL,
gu_workarea   CHAR(32) NULL,
ip_addr       VARCHAR2(15) NULL
)
GO;

ALTER TABLE k_lu_currencies ADD nu_conversion NUMBER(20,8) NULL
GO;
ALTER TABLE k_order_lines ADD id_status VARCHAR2(50) NULL
GO;
ALTER TABLE k_prod_attr ADD nu_lines INTEGER NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_pl VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_nl VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_th VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_cs VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_uk VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_no VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_pl VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_nl VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_th VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_cs VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_uk VARCHAR2(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_no VARCHAR2(50) NULL
GO;
ALTER TABLE k_users ADD tx_pwd_sign VARCHAR2(50) NULL
GO;
ALTER TABLE k_sales_men DROP CONSTRAINT f3_sales_men
GO;
ALTER TABLE k_products ADD gu_address CHAR(32) NULL
GO;
ALTER TABLE k_mime_msgs ADD bo_indexed NUMBER(2) DEFAULT 0
GO;
ALTER TABLE k_job_atoms ADD tp_recipient VARCHAR2(4) NULL
GO;
ALTER TABLE k_job_atoms ADD tx_log VARCHAR2(254) NULL
GO;
ALTER TABLE k_duties ADD ti_duration NUMBER(20,4) NULL
GO;
ALTER TABLE k_meetings ADD gu_writer CHAR(32) NULL
GO;
ALTER TABLE k_meetings ADD dt_created DATE NULL
GO;
ALTER TABLE k_meetings ADD dt_modified DATE NULL
GO;
ALTER TABLE k_meetings ADD tx_status VARCHAR2(50) NULL
GO;
ALTER TABLE k_phone_calls ADD gu_bug CHAR(32) NULL
GO;
ALTER TABLE k_invoice_lines DROP CONSTRAINT f1_invoice_lines
GO;
ALTER TABLE k_order_lines ADD id_unit VARCHAR2(16) DEFAULT 'UNIT'
GO;
ALTER TABLE k_invoice_lines ADD id_unit VARCHAR2(16) DEFAULT 'UNIT'
GO;
ALTER TABLE k_shops ADD id_legal VARCHAR2(16) NULL
GO;
ALTER TABLE k_shops ADD nm_company VARCHAR2(70) NULL
GO;
ALTER TABLE k_shops ADD tp_street VARCHAR2(16) NULL
GO;
ALTER TABLE k_shops ADD nm_street VARCHAR2(100) NULL
GO;
ALTER TABLE k_shops ADD nu_street VARCHAR2(16) NULL
GO;
ALTER TABLE k_shops ADD tx_addr1 VARCHAR2(100) NULL
GO;
ALTER TABLE k_shops ADD tx_addr2 VARCHAR2(100) NULL
GO;
ALTER TABLE k_shops ADD id_country CHAR(3) NULL
GO;
ALTER TABLE k_shops ADD nm_country VARCHAR2(50) NULL
GO;
ALTER TABLE k_shops ADD id_state VARCHAR2(16) NULL
GO;
ALTER TABLE k_shops ADD nm_state VARCHAR2(30) NULL
GO;
ALTER TABLE k_shops ADD mn_city	VARCHAR2(50) NULL
GO;
ALTER TABLE k_shops ADD zipcode	VARCHAR2(30) NULL
GO;
ALTER TABLE k_shops ADD work_phone VARCHAR2(16) NULL
GO;
ALTER TABLE k_shops ADD direct_phone VARCHAR2(16) NULL
GO;
ALTER TABLE k_shops ADD fax_phone VARCHAR2(16) NULL
GO;
ALTER TABLE k_shops ADD tx_email VARCHAR2(100) NULL
GO;
ALTER TABLE k_shops ADD url_addr VARCHAR2(254) NULL
GO;
ALTER TABLE k_shops ADD contact_person VARCHAR2(100) NULL
GO;
ALTER TABLE k_shops ADD tx_salutation VARCHAR2(16) NULL
GO;
ALTER TABLE k_products ADD pr_discount NUMBER(14,4) NULL;
GO;
ALTER TABLE k_invoice_lines ADD gu_item CHAR(32) NULL;
GO;
ALTER TABLE k_invoices ADD im_paid NUMBER(14,4) NULL;
GO;
ALTER TABLE k_contacts ADD sn_drivelic VARCHAR2(16) NULL;
GO;
ALTER TABLE k_contacts ADD dt_drivelic DATE NULL;
GO;
ALTER TABLE k_contacts ADD tp_contact VARCHAR2(30) NULL;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_product (IdProduct CHAR) IS
BEGIN
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_products WHERE gu_product=IdProduct);
  DELETE FROM k_images WHERE gu_product=IdProduct;
  DELETE FROM k_x_cat_objs WHERE gu_object=IdProduct;
  DELETE FROM k_prod_keywords WHERE gu_product=IdProduct;
  DELETE FROM k_prod_fares WHERE gu_product=IdProduct;
  DELETE FROM k_prod_attrs WHERE gu_object=IdProduct;
  DELETE FROM k_prod_attr WHERE gu_product=IdProduct;
  DELETE FROM k_prod_locats WHERE gu_product=IdProduct;
  DELETE FROM k_products WHERE gu_product=IdProduct;
END k_sp_del_product;
GO;

CREATE PROCEDURE k_sp_get_prod_fare (IdProduct CHAR, IdFare VARCHAR2, PrSale OUT NUMBER) IS
BEGIN
  SELECT pr_sale INTO PrSale FROM k_prod_fares WHERE gu_product=IdProduct AND id_fare=IdFare;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    PrSale:=NULL;
END k_sp_get_prod_fare;
GO;

CREATE PROCEDURE k_sp_get_date_fare (IdProduct CHAR, dtWhen DATE, PrSale OUT NUMBER) IS
BEGIN
  SELECT pr_sale INTO PrSale FROM k_prod_fares WHERE gu_product=IdProduct AND dtWhen BETWEEN dt_start AND dt_end;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    PrSale:=NULL;
END k_sp_get_date_fare;
GO;

CREATE PROCEDURE k_sp_resolve_atom (IdJob CHAR, AtomPg NUMBER, GuWrkA CHAR) IS
  AddrGu        CHAR(32);
  CompGu        CHAR(32);
  ContGu        CHAR(32);
  EMailTx       VARCHAR2(100);
  NameTx        VARCHAR2(200);
  SurnTx        VARCHAR2(200);
  SalutTx       VARCHAR2(16) ;
  CommNm        VARCHAR2(70) ;
  StreetTp      VARCHAR2(16) ;
  StreetNm      VARCHAR2(100);
  StreetNu      VARCHAR2(16) ;
  Addr1Tx       VARCHAR2(100);
  Addr2Tx       VARCHAR2(100);
  CountryNm     VARCHAR2(50) ;
  StateNm       VARCHAR2(30) ;
  CityNm	VARCHAR2(50) ;
  Zipcode	VARCHAR2(30) ;
  WorkPhone     VARCHAR2(16) ;
  DirectPhone   VARCHAR2(16) ;
  HomePhone     VARCHAR2(16) ;
  MobilePhone   VARCHAR2(16) ;
  FaxPhone      VARCHAR2(16) ;
  OtherPhone    VARCHAR2(16) ;
  PoBox         VARCHAR2(50) ;
BEGIN
  SELECT tx_email INTO EMailTx FROM k_job_atoms WHERE gu_job=IdJob AND pg_atom=AtomPg;
  SELECT gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box
    INTO CompGu,ContGu,EMailTx,NameTx,SurnTx,SalutTx,CommNm,StreetTp,StreetNm,StreetNu,Addr1Tx,Addr2Tx,CountryNm,StateNm,CityNm	,Zipcode,WorkPhone,DirectPhone,HomePhone,MobilePhone,FaxPhone,OtherPhone,PoBox
    FROM k_member_address WHERE gu_workarea=GuWrkA AND tx_email=EMailTx AND ROWNUM=1;
    UPDATE k_job_atoms SET gu_company=CompGu,gu_contact=ContGu,tx_name=NameTx,tx_surname=SurnTx,tx_salutation=SalutTx,nm_commercial=CommNm,tp_street=StreetTp,nm_street=StreetNm,nu_street=StreetNu,tx_addr1=Addr1Tx,tx_addr2=Addr2Tx,nm_country=CountryNm,nm_state=StateNm,mn_city=CityNm,zipcode=Zipcode,work_phone=WorkPhone,direct_phone=DirectPhone,home_phone=HomePhone,mov_phone=MobilePhone,fax_phone=FaxPhone,other_phone=OtherPhone,po_box=PoBox
     WHERE gu_job=IdJob AND pg_atom=AtomPg;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    EMailTx := NULL;
END k_sp_resolve_atom;

CREATE PROCEDURE k_sp_resolve_atoms (IdJob CHAR) IS
  WrkAGu CHAR(32);
  AtomPg NUMBER(11);
  CURSOR Atoms IS SELECT pg_atom FROM k_job_atoms WHERE gu_job=IdJob;
BEGIN
  SELECT gu_workarea INTO WrkAGu FROM k_jobs WHERE gu_job=IdJob;
  OPEN Atoms;
    LOOP
      FETCH Atoms INTO AtomPg;
      EXIT WHEN Atoms%NOTFOUND;
      k_sp_resolve_atom(IdJob,AtomPg,WrkAGu);
    END LOOP;
  CLOSE Atoms;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    WrkAGu := NULL;
END k_sp_resolve_atoms;
GO;

CREATE OR REPLACE FUNCTION k_sp_prj_cost (ProjectId CHAR) RETURN NUMBER IS
  fCost NUMBER := 0;
  fMore NUMBER := 0;
  fDuty NUMBER;
BEGIN

  FOR cProj IN (SELECT gu_project,id_parent FROM k_projects
                START WITH gu_project = ProjectId
                CONNECT BY id_parent = PRIOR gu_project)
  LOOP

    SELECT NVL(SUM(pr_cost),0) INTO fMore FROM k_project_costs WHERE gu_project=cProj.gu_project;

    SELECT NVL(SUM(d.pr_cost),0) INTO fDuty FROM k_duties d, k_projects p WHERE d.gu_project=p.gu_project AND p.gu_project=cProj.gu_project AND d.pr_cost IS NOT NULL;

    fCost := fCost + fDuty + fMore;

  END LOOP;

  RETURN fCost;
END k_sp_prj_cost;
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

  DELETE FROM k_project_costs WHERE gu_project=ProjId;
  DELETE k_project_expand WHERE gu_project=ProjId;
  DELETE k_projects WHERE gu_project=ProjId;
END k_sp_del_project;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_duty (DutyId CHAR) IS
BEGIN
  DELETE FROM k_duties_dependencies WHERE gu_previous=DutyId OR gu_next=DutyId;
  DELETE FROM k_x_duty_resource WHERE gu_duty=DutyId;
  DELETE FROM k_duties_attach WHERE gu_duty=DutyId;
  DELETE FROM k_duties WHERE gu_duty=DutyId;
END k_sp_del_duty;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_bug (BugId CHAR) IS
BEGIN
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=BugId;
  DELETE FROM k_bugs_changelog WHERE gu_bug=BugId;
  DELETE FROM k_bugs_attach WHERE gu_bug=BugId;
  DELETE FROM k_bugs WHERE gu_bug=BugId;
END k_sp_del_bug;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_grp_perm (IdGroup CHAR, IdCategory CHAR, ACLMask OUT NUMBER) IS
  IdParent CHAR(32);
  BEGIN
    ACLMask:=NULL;
    SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdCategory AND gu_acl_group=IdGroup;
    ACLMask := NVL(ACLMask, 0);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdCategory AND ROWNUM=1;
        IF IdParent=IdCategory OR IdParent IS NULL THEN
	  ACLMask := 0;
	ELSE
	  k_sp_cat_grp_perm (IdGroup, IdParent, ACLMask);
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        ACLMask := 0;
      END;
END k_sp_cat_grp_perm;
GO;

CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks
FROM v_contact_company c, v_active_contact_address b, v_contact_titles l
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title=l.vl_lookup AND c.gu_workarea=l.gu_owner)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks
FROM v_contact_company c, v_active_contact_address b, v_contact_titles l
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title IS NULL AND c.gu_workarea=l.gu_owner)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks
FROM k_contacts c, v_active_contact_address b, v_contact_titles l
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title=l.vl_lookup AND c.gu_workarea=l.gu_owner AND c.gu_company IS NULL)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,NULL AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,NVL(tx_addr1,'')||CHR(10)||NVL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks
FROM k_contacts c, v_active_contact_address b
WHERE c.gu_contact=b.gu_contact(+) AND c.de_title IS NULL AND c.gu_company IS NULL)
WITH READ ONLY
GO;

CREATE OR REPLACE PROCEDURE k_sp_prj_expand (StartWith CHAR) IS

  wlk  NUMBER(11) := 1;
  parent CHAR(32) := NULL;
  curname VARCHAR2(50);

BEGIN

  DELETE k_project_expand WHERE gu_rootprj = StartWith;

  SELECT nm_project INTO curname FROM k_projects WHERE gu_project=StartWith;

  INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (StartWith, StartWith, curname, 1, 1, NULL);

  FOR cRec IN ( SELECT gu_project,nm_project,id_parent,level FROM k_projects
  		START WITH id_parent = StartWith
                CONNECT BY id_parent = PRIOR gu_project)
  LOOP

     IF cRec.id_parent IS NULL AND parent IS NULL THEN
       wlk := wlk + 1;
     ELSIF cRec.id_parent=parent THEN
       wlk := wlk + 1;
     ELSE
       parent := cRec.id_parent;
       wlk := wlk + 1;
     END IF;

     INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (StartWith, cRec.gu_project, cRec.nm_project, cRec.level+1, wlk, cRec.id_parent);

  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    curname := NULL;
END k_sp_prj_expand;
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

  DELETE k_project_expand WHERE gu_project=ProjId;
  DELETE k_projects WHERE gu_project=ProjId;
END k_sp_del_project;
GO;

CREATE OR REPLACE PROCEDURE k_get_group_id (IdDomain NUMBER, NmGroup VARCHAR2, IdGroup OUT CHAR) IS
BEGIN
  SELECT gu_acl_group INTO IdGroup FROM k_acl_groups WHERE id_domain=IdDomain AND nm_acl_group=NmGroup;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdGroup:=NULL;
END k_get_group_id;
GO;

CREATE OR REPLACE PROCEDURE k_sp_count_thread_msgs (IdNewsThread CHAR, MsgCount OUT NUMBER) IS
BEGIN
  SELECT nu_thread_msgs INTO MsgCount FROM k_newsmsgs WHERE gu_thread_msg=IdNewsThread AND ROWNUM=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    MsgCount := 0;
END k_sp_count_thread_msgs;
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
  DeTitle       VARCHAR2(50);
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

  UPDATE k_member_address SET gu_company=:new.gu_company,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=TrTitle,dt_birth=:new.dt_birth,sn_passport=:new.sn_passport,id_gender=:new.id_gender,ny_age=:new.ny_age,tx_dept=:new.tx_dept,tx_division=:new.tx_division,tx_comments=:new.tx_comments WHERE gu_contact=:new.gu_contact;
EXCEPTION
  WHEN NO_DATA_FOUND THEN

    UPDATE k_member_address SET gu_company=:new.gu_company,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=NULL,dt_birth=:new.dt_birth,sn_passport=:new.sn_passport,id_gender=:new.id_gender,ny_age=:new.ny_age,tx_dept=:new.tx_dept,tx_division=:new.tx_division,tx_comments=:new.tx_comments WHERE gu_contact=:new.gu_contact;
END k_tr_upd_cont;
GO;
