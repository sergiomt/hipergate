CREATE TABLE k_thesauri_root
(
gu_rootterm  CHAR(32)     NOT NULL,
tx_term      VARCHAR(100) NOT NULL,
id_scope     VARCHAR(50)  DEFAULT 'all',
id_domain    INTEGER          NULL,
gu_workarea  CHAR(32)         NULL,

CONSTRAINT pk_thesauri_root PRIMARY KEY (gu_rootterm)
)
GO;

CREATE TABLE k_thesauri
(
gu_rootterm  CHAR(32)     NOT NULL,
gu_term      CHAR(32)     NOT NULL,
dt_created   DATETIME     DEFAULT CURRENT_TIMESTAMP,
id_language  CHAR(2)      NOT NULL,
bo_mainterm  SMALLINT     DEFAULT 1,
tx_term      VARCHAR(100) NOT NULL,
id_scope     VARCHAR(50)  DEFAULT 'all',
id_domain    INTEGER      NOT NULL,
gu_synonym   CHAR(32)     NULL,
de_term      VARCHAR(200) NULL,
tx_term2     VARCHAR(100) NULL,
id_term0     INTEGER      NULL,
id_term1     INTEGER      NULL,
id_term2     INTEGER      NULL,
id_term3     INTEGER      NULL,
id_term4     INTEGER      NULL,
id_term5     INTEGER      NULL,
id_term6     INTEGER      NULL,
id_term7     INTEGER      NULL,
id_term8     INTEGER      NULL,
id_term9     INTEGER      NULL,

CONSTRAINT pk_thesauri PRIMARY KEY (gu_term)
)
GO;

CREATE TABLE k_thesauri_lookup
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
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_thesauri_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_thesauri_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_images
(
    gu_image    CHAR(32)     NOT NULL,
    path_image  VARCHAR(254) NOT NULL,
    dt_created  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    gu_writer   CHAR(32)     NULL,
    gu_workarea CHAR(32)     NULL,
    dt_modified DATETIME     NULL,
    nm_image    VARCHAR(30)  NULL,
    tl_image    VARCHAR(100) NULL,
    tp_image    VARCHAR(16)  NULL,
    dm_width    INTEGER      NULL,
    dm_height   INTEGER      NULL,
    id_img_type VARCHAR(5)   NULL,
    len_file    INTEGER      NULL,
    gu_pageset  CHAR(32)     NULL,
    gu_block    CHAR(32)     NULL,
    gu_product  CHAR(32)     NULL,
    url_addr    CHARACTER VARYING(254) NULL,

    CONSTRAINT pk_images PRIMARY KEY (gu_image)
)
GO;

CREATE TABLE k_addresses
(
    gu_address     CHAR(32)  	NOT NULL,
    ix_address     INTEGER 	NOT NULL,
    gu_workarea    CHAR(32)     NOT NULL,
    dt_created     DATETIME 	DEFAULT CURRENT_TIMESTAMP,
    bo_active      SMALLINT     DEFAULT 1,
    dt_modified    DATETIME 	NULL,
    gu_user        CHAR(32)     NULL,
    tp_location    VARCHAR(16)  NULL,
    nm_company	   VARCHAR(70)  NULL,
    tp_street      VARCHAR(16)  NULL,
    nm_street      VARCHAR(100) NULL,
    nu_street      VARCHAR(16)  NULL,
    tx_addr1       VARCHAR(100) NULL,
    tx_addr2       VARCHAR(100) NULL,
    id_country     CHAR(3)      NULL,
    nm_country     VARCHAR(50)  NULL,
    id_state       VARCHAR(16)  NULL,
    nm_state       VARCHAR(30)  NULL,
    mn_city	       VARCHAR(50)  NULL,
    zipcode	       VARCHAR(30)  NULL,
    work_phone     VARCHAR(16)  NULL,
    direct_phone   VARCHAR(16)  NULL,
    home_phone     VARCHAR(16)  NULL,
    mov_phone      VARCHAR(16)  NULL,
    fax_phone      VARCHAR(16)  NULL,
    other_phone    VARCHAR(16)  NULL,
    po_box         VARCHAR(50)  NULL,
    tx_email       CHARACTER VARYING(100) NULL,
    tx_email_alt   CHARACTER VARYING(100) NULL,
    url_addr       CHARACTER VARYING(254) NULL,
    coord_x	       FLOAT        NULL,
    coord_y        FLOAT        NULL,
    contact_person VARCHAR(100) NULL,
    tx_salutation  VARCHAR(16)  NULL,
    tx_dept        VARCHAR(70)  NULL,
    id_ref         VARCHAR(50)  NULL,
    tx_remarks     VARCHAR(254) NULL,

    CONSTRAINT pk_address PRIMARY KEY (gu_address),
    CONSTRAINT c1_address CHECK ((id_country<>'es' AND id_country<>'fr' AND id_country<>'de') OR (LENGTH(zipcode)=5 OR LENGTH(zipcode)=0 OR zipcode IS NULL)),
    CONSTRAINT c2_address CHECK (id_country<>'us' OR (LENGTH(zipcode) BETWEEN 5 AND 10 OR zipcode IS NULL)),
    CONSTRAINT c3_address CHECK (id_country<>'cn' OR (LENGTH(zipcode)=6 OR zipcode IS NULL)),
    CONSTRAINT c4_address CHECK (nm_street IS NULL OR LENGTH(nm_street)>0)
)
GO;

CREATE TABLE k_addresses_lookup
(
gu_owner   CHAR(32)    NOT NULL, /* GUID de la workarea */
id_section CHARACTER VARYING(30) NOT NULL, /* Nombre del campo en la tabla base */
pg_lookup  INTEGER     NOT NULL, /* Progresivo del valor */
vl_lookup  VARCHAR(255) NULL,    /* Valor real del lookup */
tr_es      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (esp) */
tr_en      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (ing) */
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_gl      VARCHAR(50)  NULL,
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
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_addresses_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_bank_accounts
(
  nu_bank_acc     CHAR(28)      NOT NULL,
  gu_workarea     CHAR(32)      NOT NULL,
  dt_created      DATETIME      DEFAULT CURRENT_TIMESTAMP,
  bo_active       SMALLINT      DEFAULT 1,
  tp_account      SMALLINT      DEFAULT 1,
  nm_bank         VARCHAR(50)   NULL,
  tx_addr         VARCHAR(100)  NULL,
  nm_cardholder	  VARCHAR(100)  NULL,				/* Titular de la cuenta o la tarjeta */
  nu_card         CHAR(16)      NULL,				/* N� de la tarjeta */
  tp_card         VARCHAR(30)   NULL,				/* Tipo de la tarjeta  (MASTERCARD,VISA,AMEX,...) */
  tx_expire       VARCHAR(10)   NULL,				/* Fecha Expiraci�n de la Tarjeta */
  nu_pin          VARCHAR(7)    NULL,				/* Pin de la Tarjeta */
  nu_cvv2         VARCHAR(4)    NULL,
  im_credit_limit DECIMAL(14,4) NULL,
  de_bank_acc     VARCHAR(254)  NULL,

  CONSTRAINT pk_bank_accounts PRIMARY KEY (nu_bank_acc,gu_workarea)
)
GO;

CREATE TABLE k_bank_accounts_lookup
(
gu_owner   CHAR(32)    NOT NULL, /* GUID de la workarea */
id_section CHARACTER VARYING(30) NOT NULL, /* Nombre del campo en la tabla base */
pg_lookup  INTEGER     NOT NULL, /* Progresivo del valor */
vl_lookup  VARCHAR(255) NULL,    /* Valor real del lookup */
tr_es      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (esp) */
tr_en      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (ing) */
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_gl      VARCHAR(50)  NULL,
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
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_bank_accounts_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
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

CREATE TABLE k_urls
(
gu_url CHAR(32) NOT NULL,
gu_workarea CHAR(32) NOT NULL,
url_addr VARCHAR(2000) NOT NULL,
nu_clicks INTEGER NULL,
dt_last_visit DATETIME NULL,
tx_title VARCHAR(2000) NULL,
de_url VARCHAR(2000) NULL,
CONSTRAINT pk_urls PRIMARY KEY(gu_url,gu_workarea),
CONSTRAINT u1_urls UNIQUE(gu_workarea,url_addr)
)
GO;
