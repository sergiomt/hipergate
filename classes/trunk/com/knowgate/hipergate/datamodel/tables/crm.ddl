CREATE TABLE k_sales_men
(
gu_sales_man   CHAR(32) NOT NULL,
gu_workarea    CHAR(32) NOT NULL,
gu_geozone     CHAR(32)     NULL,
id_country     CHAR(3)      NULL,
id_state       CHAR(9)      NULL,
id_sales_group VARCHAR(50)  NULL,
id_bpartner    VARCHAR(32)  NULL,

CONSTRAINT pk_sales_men PRIMARY KEY (gu_sales_man)
)
GO;

CREATE TABLE k_sales_men_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
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

CONSTRAINT pk_sales_men_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_sales_men_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_sales_objectives
(
gu_sales_man    CHAR(32)    NOT NULL,
tx_year         VARCHAR(10) NOT NULL,
im_jan_planed   DECIMAL(14,4)   NULL,
im_feb_planed   DECIMAL(14,4)   NULL,
im_mar_planed   DECIMAL(14,4)   NULL,
im_apr_planed   DECIMAL(14,4)   NULL,
im_may_planed   DECIMAL(14,4)   NULL,
im_jun_planed   DECIMAL(14,4)   NULL,
im_jul_planed   DECIMAL(14,4)   NULL,
im_aug_planed   DECIMAL(14,4)   NULL,
im_sep_planed   DECIMAL(14,4)   NULL,
im_oct_planed   DECIMAL(14,4)   NULL,
im_nov_planed   DECIMAL(14,4)   NULL,
im_dec_planed   DECIMAL(14,4)   NULL,
im_tot_planed   DECIMAL(14,4)   NULL,
im_jan_achieved DECIMAL(14,4)   NULL,
im_feb_achieved DECIMAL(14,4)   NULL,
im_mar_achieved DECIMAL(14,4)   NULL,
im_apr_achieved DECIMAL(14,4)   NULL,
im_may_achieved DECIMAL(14,4)   NULL,
im_jun_achieved DECIMAL(14,4)   NULL,
im_jul_achieved DECIMAL(14,4)   NULL,
im_aug_achieved DECIMAL(14,4)   NULL,
im_sep_achieved DECIMAL(14,4)   NULL,
im_oct_achieved DECIMAL(14,4)   NULL,
im_nov_achieved DECIMAL(14,4)   NULL,
im_dec_achieved DECIMAL(14,4)   NULL,
im_tot_achieved DECIMAL(14,4)   NULL,

CONSTRAINT pk_sales_objectives PRIMARY KEY (gu_sales_man,tx_year)
)
GO;

CREATE TABLE k_companies
(
gu_company     CHAR(32)    NOT NULL,
dt_created     DATETIME    DEFAULT CURRENT_TIMESTAMP,
nm_legal       VARCHAR(70) NOT NULL,
gu_workarea    CHAR(32)    NOT NULL,
bo_restricted  SMALLINT    DEFAULT 0,
nm_commercial  VARCHAR(70)     NULL,
dt_modified    DATETIME        NULL,
dt_founded     DATETIME        NULL,
id_batch       VARCHAR(32)     NULL,
id_legal       VARCHAR(16)     NULL,
id_sector      VARCHAR(16)     NULL,
id_status      VARCHAR(30)     NULL,
id_ref         VARCHAR(50)     NULL,
id_fare        VARCHAR(32)     NULL,
id_bpartner    VARCHAR(32)     NULL,
tp_company     VARCHAR(30)     NULL,
gu_geozone     CHAR(32)        NULL,
nu_employees   INTEGER         NULL,
im_revenue     FLOAT           NULL,
gu_sales_man   CHAR(32)        NULL,
tx_franchise   VARCHAR(100)    NULL,
de_company     VARCHAR(254)    NULL,

CONSTRAINT pk_companies PRIMARY KEY(gu_company),
CONSTRAINT u1_companies UNIQUE(gu_workarea,nm_legal),
CONSTRAINT c1_companies CHECK (nm_legal IS NULL OR LENGTH(nm_legal)>0),
CONSTRAINT c2_companies CHECK (id_legal IS NULL OR LENGTH(id_legal)>0),
CONSTRAINT c3_companies CHECK (id_ref IS NULL OR LENGTH(id_ref)>0),
CONSTRAINT c4_companies CHECK (id_sector IS NULL OR LENGTH(id_sector)>0),
CONSTRAINT c5_companies CHECK (tx_franchise IS NULL OR LENGTH(tx_franchise)>0)
)
GO;

CREATE TABLE k_x_group_company
(
gu_acl_group CHAR(32) NOT NULL,
gu_company   CHAR(32) NOT NULL,
dt_created   DATETIME DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT pk_x_group_company PRIMARY KEY (gu_acl_group,gu_company)
)
GO;


CREATE TABLE k_x_company_addr
(
gu_company  CHAR(32) NOT NULL,
gu_address  CHAR(32) NOT NULL,

CONSTRAINT pk_x_company_addr PRIMARY KEY(gu_company,gu_address)
)
GO;

CREATE TABLE k_x_company_bank
(
gu_company  CHAR(32) NOT NULL,
nu_bank_acc CHAR(28) NOT NULL,
gu_workarea CHAR(32) NOT NULL,

CONSTRAINT pk_x_company_bank PRIMARY KEY(gu_company,nu_bank_acc)
)
GO;

CREATE TABLE k_x_company_prods
(
gu_company  CHAR(32) NOT NULL,
gu_category CHAR(32) NOT NULL,

CONSTRAINT pk_x_company_prods PRIMARY KEY(gu_company,gu_category)
)
GO;

CREATE TABLE k_companies_lookup
(
gu_owner   CHAR(32) NOT NULL,	 /* GUID de la workarea */
id_section CHARACTER VARYING(30) NOT NULL, /* Nombre del campo en la tabla base */
pg_lookup  INTEGER  NOT NULL,    /* Progresivo del valor */
vl_lookup  VARCHAR(255) NULL,    /* Valor real del lookup */
tr_es      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (esp) */
tr_en      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (ing) */
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_eu      VARCHAR(50)  NULL,
tr_ja      VARCHAR(50)  NULL,
tr_cn      VARCHAR(50)  NULL,
tr_tw      VARCHAR(50)  NULL,
tr_fi      VARCHAR(50)  NULL,
tr_ru      VARCHAR(50)  NULL,
tr_nl      VARCHAR(50)  NULL,
tr_th      VARCHAR(50)  NULL,
tr_cs      VARCHAR(50)  NULL,
tr_uk      VARCHAR(50)  NULL,
tr_no      VARCHAR(50)  NULL,
tr_ko      VARCHAR(50)  NULL,
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_companies_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_companies_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_companies_attrs
(
gu_object  CHAR(32)        NOT NULL,
nm_attr    VARCHAR(30) NOT NULL,
vl_attr    VARCHAR(255)    NULL,

CONSTRAINT pk_companies_attrs PRIMARY KEY (gu_object,nm_attr)
)
GO;

CREATE TABLE k_companies_recent
(
gu_company     CHAR(32)    NOT NULL,
gu_user        CHAR(32)    NOT NULL,
dt_last_visit  DATETIME    NOT NULL,
gu_workarea    CHAR(32)    NOT NULL,
nm_company     VARCHAR(70) NOT NULL,
work_phone     VARCHAR(16)     NULL,
tx_email       CHARACTER VARYING(100) NULL,

CONSTRAINT pk_companies_recent PRIMARY KEY (gu_company,gu_user)
)
GO;

CREATE TABLE k_contacts
(
gu_contact     CHAR(32) NOT NULL,   /* GUID del individuo */
gu_workarea    CHAR(32) NOT NULL,   /* GUID de la workarea */
dt_created     DATETIME DEFAULT CURRENT_TIMESTAMP,
bo_restricted  SMALLINT DEFAULT 0, /* Si tiene restricciones de acceso por grupo o no */
bo_private     SMALLINT DEFAULT 0, /* Contacto privado del usuario que lo cre� */
nu_notes       INTEGER  DEFAULT 0, /* Cuenta de notas asociadas */
nu_attachs     INTEGER  DEFAULT 0, /* Cuenta de archivos adjuntos */
bo_change_pwd  SMALLINT DEFAULT 1, /* May user change its own password? */
tx_nickname    VARCHAR(100) NULL,  /* New for v2.1 */
tx_pwd         VARCHAR(50)  NULL,  /* New for v2.1 */
tx_challenge   VARCHAR(100) NULL,  /* New for v2.1 */
tx_reply       VARCHAR(100) NULL,  /* New for v2.1 */
dt_pwd_expires DATETIME	    NULL,  /* New for v2.1 */
dt_modified    DATETIME     NULL,  /* Fecha de Modificaci�n del registro */
gu_writer      CHAR(32)     NULL,  /* GUID del usuario propietario del registro */
gu_company     CHAR(32)     NULL,  /* GUID de la compa��a a la que pertenece el individuo */
id_batch       VARCHAR(32)  NULL,  /* Lote de trabajo del cual provenia la carga del registro */
id_status      VARCHAR(30)  NULL,  /* Estado, activo, cambio de trabajo, etc. */
id_ref         VARCHAR(50)  NULL,  /* Identificador externo de registro (para interfaz con otras applicaciones) */
id_fare        VARCHAR(32)  NULL,  /* Tarifa aplicable al contacto */
id_bpartner    VARCHAR(32)  NULL,  /* Identificador de el contacto en Openbravo */
tx_name        VARCHAR(100) NULL,  /* Nombre de Pila */
tx_surname     VARCHAR(100) NULL,  /* Apellidos */
de_title       VARCHAR(70)  NULL,  /* Empleo/Puesto */
id_gender      CHAR(1)      NULL,  /* Sexo */
dt_birth       DATETIME     NULL,  /* Fecha Nacimiento */
ny_age	       SMALLINT     NULL,  /* Edad */
id_nationality CHAR(3)      NULL,  /* Country of nationality */
sn_passport    VARCHAR(16)  NULL,  /* N� doc identidad legal */
tp_passport    CHAR(1)      NULL,  /* Tipo doc identidad legal */
sn_drivelic    VARCHAR(16)  NULL,  /* Permiso de conducir */
dt_drivelic    DATETIME     NULL,  /* Fecha expedicion permiso de conducir */
tx_dept        VARCHAR(70)  NULL,  /* Departamento */
tx_division    VARCHAR(70)  NULL,  /* Divisi�n */
gu_geozone     CHAR(32)     NULL,  /* Zona Geogr�fica */
gu_sales_man   CHAR(32)     NULL,  /* Vendedor */
tx_comments    VARCHAR(254) NULL,  /* Comentarios */
url_linkedin   CHARACTER VARYING(254) NULL,
url_facebook   CHARACTER VARYING(254) NULL,
url_twitter    CHARACTER VARYING(254) NULL,

CONSTRAINT pk_contacts PRIMARY KEY (gu_contact),
CONSTRAINT c1_contacts CHECK (tx_name IS NULL OR LENGTH(tx_name)>0),
CONSTRAINT c2_contacts CHECK (tx_surname IS NULL OR LENGTH(tx_surname)>0),
CONSTRAINT c3_contacts CHECK (id_ref IS NULL OR LENGTH(id_ref)>0),
CONSTRAINT c4_contacts CHECK (de_title IS NULL OR LENGTH(de_title)>0)
)
GO;

CREATE TABLE k_contacts_recent
(
gu_contact     CHAR(32)    NOT NULL,
gu_user        CHAR(32)    NOT NULL,
dt_last_visit  DATETIME    NOT NULL,
gu_workarea    CHAR(32)    NOT NULL,
full_name      VARCHAR(100)    NULL,
nm_company     VARCHAR(70)     NULL,
work_phone     VARCHAR(16)     NULL,
tx_email       CHARACTER VARYING(100) NULL,

CONSTRAINT pk_contacts_recent PRIMARY KEY (gu_contact,gu_user)
)
GO;

CREATE TABLE k_contact_notes
(
gu_contact    CHAR(32)      NOT NULL,
pg_note       INTEGER       NOT NULL,
dt_created    DATETIME      DEFAULT CURRENT_TIMESTAMP,
gu_writer     CHAR(32)      NOT NULL,
tl_note       VARCHAR(128)  NULL,
dt_modified   DATETIME 	    NULL,
tx_fullname   VARCHAR(200)  NULL,
tx_main_email CHARACTER VARYING(100)  NULL,
tx_note       VARCHAR(2000) NULL,

CONSTRAINT pk_contacts_notes PRIMARY KEY (gu_contact,pg_note)
)
GO;

CREATE TABLE k_contact_attachs
(
gu_contact   CHAR(32)     NOT NULL,
pg_product   INTEGER      NOT NULL,
gu_product   CHAR(32)     NOT NULL,
dt_created   DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_writer    CHAR(32)     NOT NULL,

CONSTRAINT pk_contacts_attachs PRIMARY KEY (gu_contact,pg_product)
)
GO;

CREATE TABLE k_x_group_contact
(
gu_acl_group CHAR(32) NOT NULL,
gu_contact   CHAR(32) NOT NULL,
dt_created   DATETIME DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT pk_x_group_contact PRIMARY KEY (gu_acl_group,gu_contact)
)
GO;

CREATE TABLE k_x_contact_addr
(
gu_contact  CHAR(32) NOT NULL,
gu_address  CHAR(32) NOT NULL,

CONSTRAINT pk_x_contact_addr PRIMARY KEY(gu_contact,gu_address)
)
GO;

CREATE TABLE k_x_contact_bank
(
gu_contact  CHAR(32) NOT NULL,
nu_bank_acc CHAR(28) NOT NULL,
gu_workarea CHAR(32) NOT NULL,

CONSTRAINT pk_x_contact_bank PRIMARY KEY(gu_contact,nu_bank_acc)
)
GO;

CREATE TABLE k_x_contact_prods
(
gu_contact  CHAR(32) NOT NULL,
gu_category CHAR(32) NOT NULL,

CONSTRAINT pk_x_contact_prods PRIMARY KEY(gu_contact,gu_category)
)
GO;

CREATE TABLE k_contacts_lookup
(
gu_owner   CHAR(32) NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER  NOT NULL,
vl_lookup  VARCHAR(255) NULL,
tr_es      VARCHAR(50)  NULL,
tr_en      VARCHAR(50)  NULL,
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_eu      VARCHAR(50)  NULL,
tr_ja      VARCHAR(50)  NULL,
tr_cn      VARCHAR(50)  NULL,
tr_tw      VARCHAR(50)  NULL,
tr_fi      VARCHAR(50)  NULL,
tr_ru      VARCHAR(50)  NULL,
tr_nl      VARCHAR(50)  NULL,
tr_th      VARCHAR(50)  NULL,
tr_cs      VARCHAR(50)  NULL,
tr_uk      VARCHAR(50)  NULL,
tr_no      VARCHAR(50)  NULL,
tr_ko      VARCHAR(50)  NULL,
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_contacts_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT f1_contacts_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea),
CONSTRAINT u1_contacts_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_contacts_attrs
(
gu_object  CHAR(32)      NOT NULL,
nm_attr    VARCHAR(30)   NOT NULL,
vl_attr    VARCHAR(255)      NULL,

CONSTRAINT pk_contacts_attrs PRIMARY KEY (gu_object,nm_attr)
)
GO;

CREATE TABLE k_oportunities
(
gu_oportunity   CHAR(32)      NOT NULL,
gu_writer       CHAR(32)          NULL,
gu_workarea     CHAR(32)      NOT NULL,
bo_private      SMALLINT      NOT NULL,
dt_created      DATETIME      DEFAULT CURRENT_TIMESTAMP,
dt_modified     DATETIME          NULL,
dt_next_action  DATETIME          NULL,
dt_last_call    DATETIME          NULL,
lv_interest     SMALLINT          NULL,
nu_oportunities INTEGER       DEFAULT 1,
gu_campaign     CHAR(32)          NULL,
gu_company      CHAR(32)          NULL,
gu_contact      CHAR(32)          NULL,
tx_company      VARCHAR(70)       NULL,
tx_contact      VARCHAR(200)      NULL,
tl_oportunity   VARCHAR(128)      NULL,
tp_oportunity   VARCHAR(50)       NULL,
tp_origin       VARCHAR(50)       NULL,
im_revenue      FLOAT             NULL,
im_cost         FLOAT             NULL,
id_status       VARCHAR(50)       NULL,
id_objetive     VARCHAR(50)       NULL,
id_message      CHARACTER VARYING(254) NULL,
tx_cause        VARCHAR(250)      NULL,
tx_note         VARCHAR(1000)     NULL,

CONSTRAINT pk_oportunities PRIMARY KEY (gu_oportunity),
CONSTRAINT c3_oportunities CHECK (gu_company IS NOT NULL OR gu_contact IS NOT NULL),
CONSTRAINT c4_oportunities CHECK (tx_company IS NULL OR LENGTH(tx_company)>0),
CONSTRAINT c5_oportunities CHECK (tx_contact IS NULL OR LENGTH(tx_contact)>0),
CONSTRAINT c6_oportunities CHECK (tl_oportunity IS NULL OR LENGTH(tl_oportunity)>0),
CONSTRAINT c7_oportunities CHECK (tx_note IS NULL OR LENGTH(tx_note)>0)
)
GO;

CREATE TABLE k_oportunities_lookup
(
gu_owner   CHAR(32) NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER  NOT NULL,
vl_lookup  VARCHAR(255) NULL,
tp_lookup  VARCHAR(50)  NULL,
bo_active  SMALLINT     NULL,
tx_comments VARCHAR(255) NULL,
tr_es      VARCHAR(50)  NULL,
tr_en      VARCHAR(50)  NULL,
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_eu      VARCHAR(50)  NULL,
tr_ja      VARCHAR(50)  NULL,
tr_cn      VARCHAR(50)  NULL,
tr_tw      VARCHAR(50)  NULL,
tr_fi      VARCHAR(50)  NULL,
tr_ru      VARCHAR(50)  NULL,
tr_nl      VARCHAR(50)  NULL,
tr_th      VARCHAR(50)  NULL,
tr_cs      VARCHAR(50)  NULL,
tr_uk      VARCHAR(50)  NULL,
tr_no      VARCHAR(50)  NULL,
tr_ko      VARCHAR(50)  NULL,
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_oportunities_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_oportunities_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_oportunities_attrs
(
gu_object  CHAR(32) NOT NULL,
nm_attr    VARCHAR(30) NOT NULL,
vl_attr    VARCHAR(255) NULL,

CONSTRAINT pk_oportunities_attrs PRIMARY KEY (gu_object,nm_attr)
)
GO;

CREATE TABLE k_oportunities_changelog (
gu_oportunity    CHAR(32)      NOT NULL,
nm_column        VARCHAR(18)   NOT NULL,
dt_modified      DATETIME      DEFAULT CURRENT_TIMESTAMP,
gu_writer        CHAR(32)      NULL,
id_former_status VARCHAR(50)   NULL,
id_new_status    VARCHAR(50)   NULL,
tx_value         VARCHAR(1000) NULL
)
GO;

CREATE TABLE k_oportunities_attachs
(
gu_oportunity CHAR(32)     NOT NULL,
pg_product    INTEGER      NOT NULL,
gu_product    CHAR(32)     NOT NULL,
dt_created    DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_writer     CHAR(32)     NOT NULL,

CONSTRAINT pk_oportunities_attachs PRIMARY KEY (gu_oportunity,pg_product)
)
GO;

CREATE TABLE k_x_oportunity_contacts
(
gu_contact    CHAR(32) NOT NULL,
gu_oportunity CHAR(32) NOT NULL,
dt_created    DATETIME DEFAULT CURRENT_TIMESTAMP,
tp_relation   VARCHAR(30)  NULL,

CONSTRAINT pk_x_oportunity_contacts PRIMARY KEY(gu_contact,gu_oportunity)
)
GO;

CREATE TABLE k_member_address
(
gu_address      CHAR(32) NOT NULL,
ix_address      INTEGER  NOT NULL,
gu_workarea     CHAR(32) NOT NULL,
gu_company      CHAR(32) NULL,
gu_contact      CHAR(32) NULL,
dt_created      DATETIME NULL,
dt_modified     DATETIME NULL,
bo_private      SMALLINT DEFAULT 0,
gu_writer       CHAR(32) NULL,
tx_name         VARCHAR(100) NULL,
tx_surname      VARCHAR(100) NULL,
nm_commercial   VARCHAR(70)  NULL,
nm_legal        VARCHAR(70)  NULL,
id_legal        VARCHAR(16)  NULL,
id_sector       VARCHAR(16)  NULL,
de_title        VARCHAR(70)  NULL,
tr_title        VARCHAR(50)  NULL,
id_status       VARCHAR(30)  NULL,
id_ref          VARCHAR(50)  NULL,
dt_birth        DATETIME NULL,
sn_passport     VARCHAR(16) NULL,
tx_comments     VARCHAR(254) NULL,
id_gender       CHAR(1) NULL,
tp_company      VARCHAR(30) NULL,
nu_employees    INTEGER NULL,
im_revenue      FLOAT NULL,
gu_sales_man    CHAR(32) NULL,
tx_franchise    VARCHAR(100) NULL,
gu_geozone      CHAR(32) NULL,
ny_age          SMALLINT NULL,
id_nationality  CHAR(3)      NULL,
tx_dept         VARCHAR(70)  NULL,
tx_division     VARCHAR(70)  NULL,
tp_location     VARCHAR(16)  NULL,
tp_street       VARCHAR(16)  NULL,
nm_street       VARCHAR(100) NULL,
nu_street       VARCHAR(16)  NULL,
tx_addr1        VARCHAR(100) NULL,
tx_addr2        VARCHAR(100) NULL,
full_addr       VARCHAR(200) NULL,
id_country      CHAR(3) NULL,
nm_country      VARCHAR(50) NULL,
id_state        VARCHAR(16) NULL,
nm_state        VARCHAR(30) NULL,
mn_city         VARCHAR(50) NULL,
zipcode         VARCHAR(30) NULL,
work_phone      VARCHAR(16) NULL,
direct_phone    VARCHAR(16) NULL,
home_phone      VARCHAR(16) NULL,
mov_phone       VARCHAR(16) NULL,
fax_phone       VARCHAR(16) NULL,
other_phone     VARCHAR(16) NULL,
po_box          VARCHAR(50) NULL,
tx_email        CHARACTER VARYING(100) NULL,
url_addr        CHARACTER VARYING(254) NULL,
url_linkedin    CHARACTER VARYING(254) NULL,
url_facebook    CHARACTER VARYING(254) NULL,
url_twitter     CHARACTER VARYING(254) NULL,
contact_person  VARCHAR(100) NULL,
tx_salutation   VARCHAR(16)  NULL,
tx_remarks      VARCHAR(254) NULL,

CONSTRAINT pk_member_address PRIMARY KEY (gu_address),
CONSTRAINT c2_member_address CHECK (tx_name IS NULL OR LENGTH(tx_name)>0),
CONSTRAINT c3_member_address CHECK (tx_surname IS NULL OR LENGTH(tx_surname)>0),
CONSTRAINT c4_member_address CHECK (id_ref IS NULL OR LENGTH(id_ref)>0),
CONSTRAINT c5_member_address CHECK (nm_legal IS NULL OR LENGTH(nm_legal)>0),
CONSTRAINT c6_member_address CHECK (id_legal IS NULL OR LENGTH(id_legal)>0),
CONSTRAINT c7_member_address CHECK (id_sector IS NULL OR LENGTH(id_sector)>0),
CONSTRAINT c8_member_address CHECK (tx_franchise IS NULL OR LENGTH(tx_franchise)>0)
)
GO;

CREATE TABLE k_welcome_packs
(
gu_pack         CHAR(32)     NOT NULL,
ix_pack         INTEGER      NOT NULL,
gu_workarea     CHAR(32)     NOT NULL,
gu_writer	CHAR(32)     NOT NULL,
dt_created      DATETIME     DEFAULT CURRENT_TIMESTAMP,
dt_modified     DATETIME     NULL,
dt_next_action  DATETIME     NULL,
dt_promised     DATETIME     NULL,
dt_cancel       DATETIME     NULL,
dt_sent         DATETIME     NULL,
dt_delivered    DATETIME     NULL,
dt_returned     DATETIME     NULL,
tp_pack         VARCHAR(30)  NULL,
gu_contact      CHAR(32)     NULL,
gu_company      CHAR(32)     NULL,
gu_address      CHAR(32)     NULL,
id_status       VARCHAR(30)  NULL,
id_courier      VARCHAR(30)  NULL,
id_ref          VARCHAR(50)  NULL,
tx_remarks      VARCHAR(254) NULL,
CONSTRAINT pk_welcome_packs PRIMARY KEY(gu_pack),
CONSTRAINT u1_welcome_packs UNIQUE(ix_pack,gu_workarea),
CONSTRAINT c1_welcome_packs CHECK (id_ref IS NULL OR LENGTH(id_ref)>0),
CONSTRAINT c2_welcome_packs CHECK (id_ref IS NULL OR LENGTH(id_ref)>0),
CONSTRAINT c3_welcome_packs CHECK (tx_remarks IS NULL OR LENGTH(tx_remarks)>0)
)
GO;

CREATE TABLE k_welcome_packs_changelog (
gu_pack        CHAR(32)     NOT NULL,
dt_last_update DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_writer      CHAR(32)     NOT NULL,
id_old_status  VARCHAR(30)  NULL,
id_new_status  VARCHAR(30)  NULL,
CONSTRAINT pk_welcome_packs_changelog PRIMARY KEY(gu_pack,dt_last_update)
)
GO;

CREATE TABLE k_welcome_packs_lookup
(
gu_owner   CHAR(32) NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER  NOT NULL,
vl_lookup  VARCHAR(255) NULL,
tr_es      VARCHAR(50)  NULL,
tr_en      VARCHAR(50)  NULL,
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_eu      VARCHAR(50)  NULL,
tr_ja      VARCHAR(50)  NULL,
tr_cn      VARCHAR(50)  NULL,
tr_tw      VARCHAR(50)  NULL,
tr_fi      VARCHAR(50)  NULL,
tr_ru      VARCHAR(50)  NULL,
tr_nl      VARCHAR(50)  NULL,
tr_th      VARCHAR(50)  NULL,
tr_cs      VARCHAR(50)  NULL,
tr_uk      VARCHAR(50)  NULL,
tr_no      VARCHAR(50)  NULL,
tr_ko      VARCHAR(50)  NULL,
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_welcome_packs_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_welcome_packs_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_suppliers
(
gu_supplier    CHAR(32)    NOT NULL,
dt_created     DATETIME    DEFAULT CURRENT_TIMESTAMP,
nm_legal       VARCHAR(70) NOT NULL,
gu_workarea    CHAR(32)    NOT NULL,
nm_commercial  VARCHAR(70)     NULL,
gu_address     CHAR(32)        NULL,
dt_modified    DATETIME        NULL,
id_legal       VARCHAR(16)     NULL,
id_sector      VARCHAR(16)     NULL,
id_status      VARCHAR(30)     NULL,
id_ref         VARCHAR(50)     NULL,
id_bpartner    VARCHAR(32)     NULL,
tp_supplier    VARCHAR(30)     NULL,
nu_employees   INTEGER         NULL,
gu_geozone     CHAR(32)        NULL,
de_supplier    VARCHAR(254)    NULL,

CONSTRAINT pk_suppliers PRIMARY KEY(gu_supplier),
CONSTRAINT u1_suppliers UNIQUE(gu_workarea,nm_legal),
CONSTRAINT c1_suppliers CHECK (nm_legal IS NULL OR LENGTH(nm_legal)>0),
CONSTRAINT c2_suppliers CHECK (id_legal IS NULL OR LENGTH(id_legal)>0),
CONSTRAINT c3_suppliers CHECK (id_ref IS NULL OR LENGTH(id_ref)>0)
)
GO;

CREATE TABLE k_suppliers_lookup
(
gu_owner   CHAR(32) NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER  NOT NULL,
vl_lookup  VARCHAR(255) NULL,
tr_es      VARCHAR(50)  NULL,
tr_en      VARCHAR(50)  NULL,
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_eu      VARCHAR(50)  NULL,
tr_ja      VARCHAR(50)  NULL,
tr_cn      VARCHAR(50)  NULL,
tr_tw      VARCHAR(50)  NULL,
tr_fi      VARCHAR(50)  NULL,
tr_ru      VARCHAR(50)  NULL,
tr_nl      VARCHAR(50)  NULL,
tr_th      VARCHAR(50)  NULL,
tr_cs      VARCHAR(50)  NULL,
tr_uk      VARCHAR(50)  NULL,
tr_no      VARCHAR(50)  NULL,
tr_ko      VARCHAR(50)  NULL,
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_suppliers_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_suppliers_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_prod_suppliers
(
gu_product  CHAR(32) NOT NULL,
gu_supplier CHAR(32) NOT NULL,
CONSTRAINT pk_prod_suppliers PRIMARY KEY(gu_product,gu_supplier)
)
GO;

CREATE TABLE k_sms_msisdn
(
gu_workarea  CHAR(32)    NOT NULL,
nu_msisdn    VARCHAR(16) NOT NULL,
bo_validated SMALLINT    DEFAULT 1,
nu_pin       VARCHAR(6)  NULL,

CONSTRAINT pk_sms_msisdn PRIMARY KEY (gu_workarea,nu_msisdn)
)
GO;

CREATE TABLE k_sms_audit (
id_sms		  VARCHAR(50)  NOT NULL,
gu_workarea   CHAR(32)     NOT NULL,
pg_part       SMALLINT     DEFAULT 1,
nu_msisdn     VARCHAR(16)  NOT NULL,
id_msg        VARCHAR(50)  NULL,
gu_batch      CHAR(32)     NULL,
bo_success    SMALLINT     NOT NULL,
nu_error      INTEGER      DEFAULT 0,
id_status     INTEGER      DEFAULT 0,
dt_sent       DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_writer     CHAR(32)     NULL,
gu_address    CHAR(32)     NULL,
gu_contact    CHAR(32)     NULL,
gu_company    CHAR(32)     NULL,
tx_msg        VARCHAR(160) NOT NULL,
tx_err        VARCHAR(254) NULL,
CONSTRAINT pk_sms_audit PRIMARY KEY(id_sms)
)
GO;

CREATE TABLE k_bulkloads (
pg_bulkload   INTEGER  NOT NULL,
dt_uploaded   DATETIME NOT NULL,
gu_workarea   CHAR(32) NOT NULL,
nm_file       VARCHAR(254) NOT NULL,
id_batch      VARCHAR(32)  NULL,
tp_batch      VARCHAR(32)  NULL,
id_status     VARCHAR(30)  NULL,
dt_processed  DATETIME NOT NULL,
nu_lines      INTEGER DEFAULT 0,
nu_successful INTEGER DEFAULT 0,
nu_errors     INTEGER DEFAULT 0,
de_file       VARCHAR(254) NULL,
CONSTRAINT pk_bulkloads PRIMARY KEY(pg_bulkload),
CONSTRAINT u1_bulkloads UNIQUE(dt_uploaded,gu_workarea,nm_file)
)
GO;