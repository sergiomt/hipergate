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
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_contact_refs', 10000, 2147483647, 1, 10000)
GO;
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_welcme_pak', 1, 2147483647, 1, 1)
GO;

CREATE TABLE k_lu_unlocode (
  id_country CHAR(3) NOT NULL,
  id_place   CHAR(3) NOT NULL,
  nm_place   NVARCHAR(50) NOT NULL,
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
    dt_created          DATETIME     DEFAULT GETDATE(),
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
    gu_pwd              CHAR(32)       NOT NULL,
    gu_user             CHAR(32)       NOT NULL,
    tl_pwd              NVARCHAR(50)   NOT NULL,
    tp_pwd              NVARCHAR(30)   NOT NULL,
    dt_created          DATETIME       DEFAULT GETDATE(),
    tx_nickname         NVARCHAR(100)  NOT NULL,
    tx_pwd              NVARCHAR(50)   NOT NULL,
    tx_pwd_sign         NVARCHAR(50)   NULL,
    tx_account          NVARCHAR(50)   NULL,
    tx_expire           NVARCHAR(10)   NULL,
    nu_cvv2             NVARCHAR(4)    NULL,
    url_addr            VARCHAR(254)   NULL,
    tx_comments         NVARCHAR(254)  NULL,
    tx_prk              NVARCHAR(2000) NULL,
    tx_pbk              NVARCHAR(2000) NULL,
    bin_key             IMAGE          NULL,

    CONSTRAINT pk_user_pwd PRIMARY KEY (gu_pwd)
)
GO;

CREATE TABLE k_despatch_advices (
  gu_despatch    CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_despatch    INTEGER       NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  dt_created     DATETIME      DEFAULT GETDATE(),
  bo_approved    SMALLINT      DEFAULT 1,
  bo_credit_ok   SMALLINT      DEFAULT 1,
  id_priority    NVARCHAR(16)  NULL,
  gu_warehouse   CHAR(32)      NULL,
  dt_modified    DATETIME      NULL,
  dt_delivered   DATETIME      NULL,
  dt_printed     DATETIME      NULL,
  dt_promised    DATETIME      NULL,
  dt_payment     DATETIME      NULL,
  dt_cancel      DATETIME      NULL,
  de_despatch    NVARCHAR(255)  NULL,
  tx_location    NVARCHAR(100)  NULL,
  gu_company     CHAR(32)      NULL,
  gu_contact     CHAR(32)      NULL,
  nm_client	 NVARCHAR(200)  NULL,
  id_legal       NVARCHAR(16)   NULL,
  gu_ship_addr   CHAR(32)      NULL,
  gu_bill_addr   CHAR(32)      NULL,
  id_ref         NVARCHAR(50)   NULL,
  id_status      NVARCHAR(50)   NULL,
  id_pay_status  NVARCHAR(50)   NULL,
  id_ship_method NVARCHAR(30)   NULL,
  im_subtotal    DECIMAL(14,4) NULL,
  im_taxes       DECIMAL(14,4) NULL,
  im_shipping    DECIMAL(14,4) NULL,
  im_discount    NVARCHAR(10)   NULL,
  im_total       DECIMAL(14,4) NULL,
  tx_ship_notes  NVARCHAR(254)  NULL,
  tx_email_to    NVARCHAR(100)  NULL,
  tx_comments    NVARCHAR(254)  NULL,

  CONSTRAINT pk_despatch_advices PRIMARY KEY(gu_despatch)
)
GO;

CREATE TABLE k_despatch_lines (
  gu_despatch     CHAR(32)      NOT NULL,
  pg_line         INTEGER       NOT NULL,
  pr_sale         DECIMAL(14,4) NULL,
  nu_quantity     FLOAT	        NULL,
  id_unit         NVARCHAR(16)  DEFAULT 'UNIT',
  pr_total        DECIMAL(14,4) NULL,
  pct_tax_rate    FLOAT         NULL,
  is_tax_included SMALLINT      NULL,
  nm_product      NVARCHAR(128) NOT NULL,
  gu_product      CHAR(32)      NULL,
  gu_item         CHAR(32)      NULL,
  id_status       NVARCHAR(50)  NULL,
  tx_promotion    NVARCHAR(100) NULL,
  tx_options      NVARCHAR(254) NULL,

  CONSTRAINT pk_despatch_lines PRIMARY KEY(gu_despatch,pg_line),
  CONSTRAINT c1_despatch_lines CHECK (pg_line>0)
)
GO;

CREATE TABLE k_despatch_advices_lookup
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
tr_sk      NVARCHAR(50)      NULL,

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
  id_legal       NVARCHAR(16)   NOT NULL,
  dt_created     DATETIME      DEFAULT GETDATE(),
  bo_active      SMALLINT      DEFAULT 1,
  bo_approved    SMALLINT      DEFAULT 1,
  dt_modified    DATETIME           NULL,
  dt_returned    DATETIME           NULL,
  dt_printed     DATETIME           NULL,
  de_returned    NVARCHAR(100)       NULL,
  gu_company     CHAR(32)           NULL,
  gu_contact     CHAR(32)           NULL,
  nm_client	 NVARCHAR(200)       NULL,
  gu_bill_addr   CHAR(32)           NULL,
  id_ref         NVARCHAR(50)        NULL,
  id_status      NVARCHAR(30)        NULL,
  id_pay_status  NVARCHAR(30)        NULL,
  id_ship_method NVARCHAR(30)        NULL,
  im_subtotal    DECIMAL(14,4)      NULL,
  im_taxes       DECIMAL(14,4)      NULL,
  im_shipping    DECIMAL(14,4)      NULL,
  im_discount    NVARCHAR(10)        NULL,
  im_total       DECIMAL(14,4)      NULL,
  tp_billing     CHAR(1)            NULL,
  nu_bank   	 CHAR(20)           NULL,
  tx_email_to    NVARCHAR(100)       NULL,
  tx_comments    NVARCHAR(254)       NULL,

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
dt_created   DATETIME         DEFAULT GETDATE(),
dt_modified  DATETIME            NULL,
gu_writer    CHAR(32)         NOT NULL,
gu_user      CHAR(32)         NOT NULL,
tl_cost      NVARCHAR(100)     NOT NULL,
pr_cost      FLOAT            NOT NULL,
tp_cost      NVARCHAR(30)          NULL,
dt_cost      DATETIME             NULL,
de_cost      NVARCHAR(1000)        NULL,
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
nm_column    NVARCHAR(18)   NOT NULL,
dt_modified  DATETIME      DEFAULT GETDATE(),
gu_writer    CHAR(32)      NULL,
tx_oldvalue  NVARCHAR(255)  NULL
)
GO;

CREATE TABLE k_login_audit (
bo_success    CHAR(1)   NOT NULL,
nu_error      INTEGER   NOT NULL,
dt_login      DATETIME  DEFAULT GETDATE(),
gu_user       CHAR(32)  NULL,
tx_email      NVARCHAR(100) NULL,
tx_pwd        NVARCHAR(50) NULL,
gu_workarea   CHAR(32)  NULL,
ip_addr       NVARCHAR(15) NULL
)
GO;

ALTER TABLE k_lu_currencies ADD nu_conversion DECIMAL(20,8) NULL
GO;
ALTER TABLE k_order_lines ADD id_status NVARCHAR(50) NULL
GO;
ALTER TABLE k_prod_attr ADD nu_lines INTEGER NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_pl NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_nl NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_th NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_cs NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_uk NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_languages ADD tr_lang_no NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_pl NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_nl NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_th NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_cs NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_uk NVARCHAR(50) NULL
GO;
ALTER TABLE k_lu_countries ADD tr_country_no NVARCHAR(50) NULL
GO;
ALTER TABLE k_users ADD tx_pwd_sign NVARCHAR(50) NULL
GO;
ALTER TABLE k_sales_men DROP CONSTRAINT f3_sales_men
GO;
ALTER TABLE k_products ADD gu_address CHAR(32) NULL
GO;
ALTER TABLE k_mime_msgs ADD bo_indexed SMALLINT DEFAULT 0
GO;
ALTER TABLE k_job_atoms ADD tp_recipient NVARCHAR(4) NULL
GO;
ALTER TABLE k_job_atoms ADD tx_log NVARCHAR(254) NULL
GO;
ALTER TABLE k_duties ADD ti_duration DECIMAL(20,4) NULL
GO;
ALTER TABLE k_meetings ADD gu_writer CHAR(32) NULL
GO;
ALTER TABLE k_meetings ADD dt_created DATETIME NULL
GO;
ALTER TABLE k_meetings ADD dt_modified DATETIME NULL
GO;
ALTER TABLE k_meetings ADD tx_status NVARCHAR(50) NULL
GO;
ALTER TABLE k_phone_calls ADD gu_bug CHAR(32) NULL
GO;
ALTER TABLE k_invoice_lines DROP CONSTRAINT f1_invoice_lines
GO;
ALTER TABLE k_order_lines ADD id_unit NVARCHAR(16) DEFAULT 'UNIT'
GO;
ALTER TABLE k_invoice_lines ADD id_unit NVARCHAR(16) DEFAULT 'UNIT'
GO;
ALTER TABLE k_shops ADD id_legal NVARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD nm_company NVARCHAR(70) NULL
GO;
ALTER TABLE k_shops ADD tp_street NVARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD nm_street NVARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD nu_street NVARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD tx_addr1 NVARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD tx_addr2 NVARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD id_country CHAR(3) NULL
GO;
ALTER TABLE k_shops ADD nm_country NVARCHAR(50) NULL
GO;
ALTER TABLE k_shops ADD id_state NVARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD nm_state NVARCHAR(30) NULL
GO;
ALTER TABLE k_shops ADD mn_city	NVARCHAR(50) NULL
GO;
ALTER TABLE k_shops ADD zipcode	NVARCHAR(30) NULL
GO;
ALTER TABLE k_shops ADD work_phone NVARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD direct_phone NVARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD fax_phone NVARCHAR(16) NULL
GO;
ALTER TABLE k_shops ADD tx_email NVARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD url_addr NVARCHAR(254) NULL
GO;
ALTER TABLE k_shops ADD contact_person NVARCHAR(100) NULL
GO;
ALTER TABLE k_shops ADD tx_salutation NVARCHAR(16) NULL
GO;
ALTER TABLE k_products ADD pr_discount DECIMAL(14,4) NULL;
GO;
ALTER TABLE k_invoice_lines ADD gu_item CHAR(32) NULL;
GO;
ALTER TABLE k_invoices ADD im_paid DECIMAL(14,4) NULL;
GO;
ALTER TABLE k_contacts ADD sn_drivelic NVARCHAR(16) NULL;
GO;
ALTER TABLE k_contacts ADD dt_drivelic DATETIME NULL;
GO;
ALTER TABLE k_contacts ADD tp_contact NVARCHAR(30) NULL;
GO;

CREATE PROCEDURE k_sp_currval @NMTable CHAR(18), @NextVal INTEGER OUTPUT AS
  SELECT @NextVal=nu_current FROM k_sequences WITH (ROWLOCK) WHERE nm_table=@NMTable
GO;

DROP PROCEDURE k_sp_cat_set_grp
GO;

CREATE PROCEDURE k_sp_cat_set_grp @IdCategory CHAR(32), @IdGroup CHAR(32), @ACLMask INTEGER, @Recurse SMALLINT, @Objects SMALLINT AS
  /* Establece los permisos asignados a un grupo dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdGroup: Identificador unico del grupo
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */
  DECLARE @IdChild CHAR(32)
  DECLARE @PrevMask INTEGER
  DECLARE childs CURSOR LOCAL FAST_FORWARD FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory

  IF @IdCategory IS NOT NULL AND @IdGroup IS NOT NULL
    BEGIN
      SET @PrevMask = NULL

      SELECT @PrevMask=acl_mask FROM k_x_cat_group_acl WHERE gu_category=@IdCategory AND gu_acl_group=@IdGroup

      IF @PrevMask IS NULL
        INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES (@IdCategory, @IdGroup, @ACLMask)
      ELSE
        UPDATE k_x_cat_group_acl SET acl_mask = @ACLMask WHERE gu_category=@IdCategory AND gu_acl_group=@IdGroup
    END

  IF @Recurse<>0
    BEGIN
      OPEN childs
        FETCH NEXT FROM childs INTO @IdChild
        WHILE @@FETCH_STATUS = 0
          BEGIN
            EXECUTE k_sp_cat_set_grp @IdChild, @IdGroup, @ACLMask, @Recurse, @Objects
            FETCH NEXT FROM childs INTO @IdChild
          END
      CLOSE childs
    END
GO;

DROP PROCEDURE k_sp_cat_set_usr
GO;

CREATE PROCEDURE k_sp_cat_set_usr @IdCategory CHAR(32), @IdUser CHAR(32), @ACLMask INTEGER, @Recurse SMALLINT, @Objects SMALLINT AS
  DECLARE @IdChild CHAR(32)
  DECLARE @PrevMask INTEGER
  DECLARE childs CURSOR LOCAL FAST_FORWARD FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory
  IF @IdCategory IS NOT NULL AND @IdUser IS NOT NULL
    BEGIN
      SET @PrevMask = NULL
      SELECT @PrevMask=acl_mask FROM k_x_cat_user_acl WHERE gu_category=@IdCategory AND gu_user=@IdUser
      IF @PrevMask IS NULL
        INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES (@IdCategory, @IdUser, @ACLMask)
      ELSE
        UPDATE k_x_cat_user_acl SET acl_mask=@ACLMask WHERE gu_category=@IdCategory AND gu_user=@IdUser
    END
  IF @Recurse<>0
    BEGIN
      OPEN childs
        FETCH NEXT FROM childs INTO @IdChild
        WHILE @@FETCH_STATUS = 0
          BEGIN
            EXECUTE k_sp_cat_set_usr @IdChild, @IdUser, @ACLMask, @Recurse, @Objects
            FETCH NEXT FROM childs INTO @IdChild
          END
      CLOSE childs
    END
GO;

DROP PROCEDURE k_sp_del_product
GO;

CREATE PROCEDURE k_sp_del_product @IdProduct CHAR(32) AS
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_products WHERE gu_product=@IdProduct)
  DELETE FROM k_images WHERE gu_product=@IdProduct
  DELETE FROM k_x_cat_objs WHERE gu_object=@IdProduct
  DELETE FROM k_prod_keywords WHERE gu_product=@IdProduct
  DELETE FROM k_prod_fares WHERE gu_product=@IdProduct
  DELETE FROM k_prod_attrs WHERE gu_object=@IdProduct
  DELETE FROM k_prod_attr WHERE gu_product=@IdProduct
  DELETE FROM k_prod_locats WHERE gu_product=@IdProduct
  DELETE FROM k_products WHERE gu_product=@IdProduct
GO;

CREATE PROCEDURE k_sp_get_prod_fare @IdProduct CHAR(32), @IdFare NVARCHAR(32), @PrSale DECIMAL(14,4) OUTPUT AS
  SET @PrSale = NULL
  SELECT @PrSale=pr_sale FROM k_prod_fares WHERE gu_product=@IdProduct AND id_fare=@IdFare
GO;

CREATE PROCEDURE k_sp_get_date_fare @IdProduct CHAR(32), @dtWhen DATETIME, @PrSale DECIMAL(14,4) OUTPUT AS
  SET @PrSale = NULL
  SELECT @PrSale=pr_sale FROM k_prod_fares WHERE gu_product=@IdProduct AND @dtWhen BETWEEN dt_start AND dt_end
GO;

CREATE PROCEDURE k_sp_resolve_atom @IdJob CHAR(32), @AtomPg INTEGER, @GuWrkA CHAR(32) AS
  DECLARE @AddrGu        CHAR(32)
  DECLARE @CompGu        CHAR(32)
  DECLARE @ContGu        CHAR(32)
  DECLARE @EMailTx       VARCHAR(100)
  DECLARE @NameTx        NVARCHAR(200)
  DECLARE @SurnTx        NVARCHAR(200)
  DECLARE @SalutTx       NVARCHAR(16)
  DECLARE @CommNm        NVARCHAR(70)
  DECLARE @StreetTp      NVARCHAR(16)
  DECLARE @StreetNm      NVARCHAR(100)
  DECLARE @StreetNu      NVARCHAR(16)
  DECLARE @Addr1Tx       NVARCHAR(100)
  DECLARE @Addr2Tx       NVARCHAR(100)
  DECLARE @CountryNm     NVARCHAR(50)
  DECLARE @StateNm       NVARCHAR(30)
  DECLARE @CityNm	 NVARCHAR(50)
  DECLARE @Zipcode	 NVARCHAR(30)
  DECLARE @WorkPhone     NVARCHAR(16)
  DECLARE @DirectPhone   NVARCHAR(16)
  DECLARE @HomePhone     NVARCHAR(16)
  DECLARE @MobilePhone   NVARCHAR(16)
  DECLARE @FaxPhone      NVARCHAR(16)
  DECLARE @OtherPhone    NVARCHAR(16)
  DECLARE @PoBox         NVARCHAR(50)

  SET @EMailTx=NULL
  SELECT @EMailTx=tx_email FROM k_job_atoms WHERE gu_job=@IdJob AND pg_atom=@AtomPg
  IF @EMailTx IS NOT NULL
    BEGIN
      SET @AddrGu=NULL
      SELECT TOP 1 @AddrGu=gu_address,@CompGu=gu_company,@ContGu=gu_contact,@NameTx=tx_name,@SurnTx=tx_surname,@SalutTx=tx_salutation,@CommNm=nm_commercial,@StreetTp=tp_street,@StreetNm=nm_street,@StreetNu=nu_street,@Addr1Tx=tx_addr1,@Addr2Tx=tx_addr2,@CountryNm=nm_country,@StateNm=nm_state,@CityNm	=mn_city,@Zipcode=zipcode,@WorkPhone=work_phone,@DirectPhone=direct_phone,@HomePhone=home_phone,@MobilePhone=mov_phone,@FaxPhone=fax_phone,@OtherPhone=other_phone,@PoBox=po_box
             FROM k_member_address WHERE gu_workarea=@GuWrkA AND tx_email=@EMailTx
      IF @AddrGu IS NOT NULL
        UPDATE k_job_atoms SET gu_company=@CompGu,gu_contact=@ContGu,tx_name=@NameTx,tx_surname=@SurnTx,tx_salutation=@SalutTx,nm_commercial=@CommNm,tp_street=@StreetTp,nm_street=@StreetNm,nu_street=@StreetNu,tx_addr1=@Addr1Tx,tx_addr2=@Addr2Tx,nm_country=@CountryNm,nm_state=@StateNm,mn_city	=@CityNm,zipcode	=@Zipcode,work_phone=@WorkPhone,direct_phone=@DirectPhone,home_phone=@HomePhone,mov_phone=@MobilePhone,fax_phone=@FaxPhone,other_phone=@OtherPhone,po_box=@PoBox
               WHERE gu_job=@IdJob AND pg_atom=@AtomPg
    END
GO;

CREATE PROCEDURE k_sp_resolve_atoms @IdJob CHAR(32) AS
  DECLARE @WrkAGu CHAR(32)
  DECLARE @AtomPg INTEGER
  DECLARE Atoms CURSOR LOCAL STATIC FOR SELECT pg_atom FROM k_job_atoms WHERE gu_job = @IdJob

  SET @WrkAGu=NULL
  SELECT @WrkAGu=gu_workarea FROM k_jobs WHERE gu_job=@IdJob
  OPEN Atoms
    FETCH NEXT FROM Atoms INTO @AtomPg
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_resolve_atom @IdJob
        FETCH NEXT FROM Atoms INTO @AtomPg
      END
  CLOSE Atoms
  DEALLOCATE Atoms
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

  DELETE FROM k_project_costs WHERE gu_project=@ProjId
  DELETE k_project_expand WHERE gu_project=@ProjId
  DELETE k_projects WHERE gu_project=@ProjId
GO;

DROP FUNCTION dbo.k_sp_prj_cost
GO;

CREATE FUNCTION dbo.k_sp_prj_cost (@ProjectId CHAR(32)) RETURNS FLOAT AS
BEGIN
  DECLARE @fCost FLOAT
  DECLARE @fMore FLOAT
  DECLARE @ChlId CHAR(32)
  DECLARE childs CURSOR LOCAL READ_ONLY FOR SELECT gu_project FROM k_projects WHERE id_parent=@ProjectId

  SELECT @fMore=ISNULL(SUM(pr_cost),0) FROM k_project_costs WHERE gu_project=@ProjectId
  SELECT @fCost=ISNULL(SUM(d.pr_cost),0) FROM k_duties d, k_projects p WITH (NOLOCK) WHERE d.gu_project=p.gu_project AND p.gu_project=@ProjectId AND d.pr_cost IS NOT NULL
  SET @fCost = @fCost + @fMore

  OPEN childs
    FETCH NEXT FROM childs INTO @ChlId
    WHILE @@FETCH_STATUS = 0
      BEGIN
        SET @fCost = @fCost + dbo.k_sp_prj_cost(@ChlId)
        FETCH NEXT FROM childs INTO @ChlId
      END
  CLOSE childs

  RETURN (@fCost)
END
GO;

DROP PROCEDURE k_sp_del_bug
GO;

CREATE PROCEDURE k_sp_del_bug @BugId CHAR(32) AS
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=@BugId
  DELETE FROM k_bugs_changelog WHERE gu_bug=@BugId
  DELETE FROM k_bugs_attach WHERE gu_bug=@BugId
  DELETE FROM k_bugs WHERE gu_bug=@BugId
GO;

DROP PROCEDURE k_sp_del_duty
GO;

CREATE PROCEDURE k_sp_del_duty @DutyId CHAR(32) AS
  DELETE FROM k_duties_dependencies WHERE gu_previous=@DutyId OR gu_next=@DutyId
  DELETE FROM k_x_duty_resource WHERE gu_duty=@DutyId
  DELETE FROM k_duties_attach WHERE gu_duty=@DutyId
  DELETE FROM k_duties WHERE gu_duty=@DutyId
GO;

DROP PROCEDURE k_sp_cat_grp_perm
GO;

CREATE PROCEDURE k_sp_cat_grp_perm @IdGroup CHAR(32), @IdCategory CHAR(32), @ACLMask INTEGER OUTPUT AS
  DECLARE @IdParent CHAR(32)
  SET @ACLMask=NULL
  SELECT @ACLMask=acl_mask FROM k_x_cat_group_acl WITH (NOLOCK) WHERE gu_category=@IdCategory AND gu_acl_group=@IdGroup

  IF (@ACLMask IS NULL)
    BEGIN
      SELECT TOP 1 @IdParent=gu_parent_cat FROM k_cat_tree WHERE gu_child_cat=@IdCategory
      IF (@IdParent=@IdCategory OR @IdParent IS NULL)
        SET @ACLMask=0
      ELSE
        EXECUTE k_sp_cat_grp_perm @IdGroup, @IdParent, @ACLMask OUTPUT
    END
GO;

DROP PROCEDURE k_get_group_id
GO;

CREATE PROCEDURE k_get_group_id @IdDomain INTEGER, @NmGroup VARCHAR(30), @IdGroup CHAR(32) OUTPUT AS
  SELECT TOP 1 @IdGroup=gu_acl_group FROM k_acl_groups WITH (NOLOCK) WHERE id_domain=@IdDomain AND nm_acl_group=@NmGroup
GO;

DROP PROCEDURE k_sp_count_thread_msgs
GO;

CREATE PROCEDURE k_sp_count_thread_msgs @IdNewsThread CHAR(32), @MsgCount INTEGER OUTPUT AS
  SET @MsgCount = 0
  SELECT TOP 1 @MsgCount=nu_thread_msgs FROM k_newsmsgs WHERE gu_thread_msg=@IdNewsThread
GO;

CREATE TRIGGER k_tr_upd_comp ON k_companies FOR UPDATE AS

  DECLARE @NmLegal       NVARCHAR(70)
  DECLARE @NmCommercial  NVARCHAR(70)
  DECLARE @IdLegal       NVARCHAR(16)
  DECLARE @IdSector      NVARCHAR(16)
  DECLARE @IdStatus      NVARCHAR(30)
  DECLARE @IdRef         NVARCHAR(50)
  DECLARE @TpCompany     NVARCHAR(30)
  DECLARE @NuEmployees   INTEGER
  DECLARE @ImRevenue     FLOAT
  DECLARE @GuSalesMan    CHAR(32)
  DECLARE @TxFranchise   NVARCHAR(100)
  DECLARE @GuGeoZone     CHAR(32)
  DECLARE @DeCompany     NVARCHAR(254)

  SELECT @NmLegal=k.nm_legal,@IdLegal=k.id_legal,@NmCommercial=k.nm_commercial,@IdSector=k.id_sector,@IdStatus=k.id_status,@IdRef=k.id_ref,@TpCompany=k.tp_company,@NuEmployees=k.nu_employees,@ImRevenue=k.im_revenue,@GuSalesMan=k.gu_sales_man,@TxFranchise=k.tx_franchise,@GuGeoZone=k.gu_geozone,@DeCompany=k.de_company
  FROM k_companies k, inserted i WHERE k.gu_company=i.gu_company

  UPDATE k_member_address SET nm_legal=@NmLegal,id_legal=@IdLegal,nm_commercial=@NmCommercial,id_sector=@IdSector,id_ref=@IdRef,id_status=@IdStatus,tp_company=@TpCompany,nu_employees=@NuEmployees,im_revenue=@ImRevenue,gu_sales_man=@GuSalesMan,tx_franchise=@TxFranchise,gu_geozone=@GuGeoZone,tx_comments=@DeCompany
  WHERE gu_company IN (SELECT gu_company FROM inserted)
GO;

CREATE TRIGGER k_tr_upd_cont ON k_contacts FOR UPDATE AS

  DECLARE @GuCompany     CHAR(32)
  DECLARE @GuWorkArea    CHAR(32)
  DECLARE @TxName        NVARCHAR(100)
  DECLARE @TxSurname     NVARCHAR(100)
  DECLARE @DeTitle       NVARCHAR(50)
  DECLARE @TrTitle       NVARCHAR(50)
  DECLARE @DtBirth       DATETIME
  DECLARE @SnPassport    NVARCHAR(16)
  DECLARE @IdGender      CHAR(1)
  DECLARE @NyAge         SMALLINT
  DECLARE @TxDept        NVARCHAR(70)
  DECLARE @TxDivision    NVARCHAR(70)
  DECLARE @TxComments    NVARCHAR(254)

  SELECT @GuCompany=c.gu_company,@GuWorkArea=c.gu_workarea,@TxName=CASE LEN(c.tx_name) WHEN 0 THEN NULL ELSE c.tx_name END,@TxSurname=CASE LEN(c.tx_surname) WHEN 0 THEN NULL ELSE c.tx_surname END,@DeTitle=c.de_title,@DtBirth=c.dt_birth,@SnPassport=c.sn_passport,@IdGender=c.id_gender,@NyAge=c.ny_age,@TxDept=c.tx_dept,@TxDivision=c.tx_division,@TxComments=c.tx_comments
  FROM k_contacts c, inserted i WHERE c.gu_contact=i.gu_contact

  SET @TrTitle = NULL

  IF @DeTitle IS NOT NULL
    SELECT @TrTitle=tr_es FROM k_contacts_lookup WHERE gu_owner=@GuWorkArea AND id_section='de_title' AND vl_lookup=@DeTitle

  UPDATE k_member_address SET gu_company=@GuCompany,tx_name=@TxName,tx_surname=@TxSurname,de_title=@DeTitle,tr_title=@TrTitle,dt_birth=@DtBirth,sn_passport=@SnPassport,id_gender=@IdGender,ny_age=@NyAge,tx_dept=@TxDept,tx_division=@TxDivision,tx_comments=@TxComments
  WHERE gu_contact IN (SELECT gu_contact FROM inserted)
GO;
