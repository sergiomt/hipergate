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

ALTER TABLE k_phone_calls ADD gu_bug CHAR(32) NULL
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

CREATE TABLE k_returned_invoices (
  gu_returned    CHAR(32)      NOT NULL,
  gu_invoice     CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_returned    INTEGER       NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  id_legal       VARCHAR2(16)  NOT NULL,
  dt_created     DATE          DEFAULT CURRENT_TIMESTAMP,
  bo_active      SMALLINT      DEFAULT 1,
  bo_approved    SMALLINT      DEFAULT 1,
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

CREATE TABLE k_invoices_next
(
  gu_workarea    CHAR(32)     NOT NULL,
  pg_invoice     INTEGER      NOT NULL,
  CONSTRAINT pk_invoices_next PRIMARY KEY(gu_workarea,pg_invoice)
)
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


UPDATE k_version SET VS_STAMP='2.2.0'
GO;
INSERT INTO k_apps VALUES(23,'Surveys')
GO;
INSERT INTO k_microsites (gu_microsite,tp_microsite,nm_microsite,path_metadata,id_app) VALUES ('SURVEYMICROSITEJIXBXMLDEFINITION',4,'Survey','xslt/templates/Survey/survey-def-jixb.xml',23)
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