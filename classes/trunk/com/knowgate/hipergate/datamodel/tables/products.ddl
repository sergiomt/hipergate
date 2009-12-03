
CREATE TABLE k_products
(
gu_product  	 CHAR(32)     NOT NULL,
dt_created       DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_owner	     CHAR(32)     NOT NULL,
nm_product 	     VARCHAR(128) NOT NULL,
id_status	     SMALLINT     DEFAULT 1,
is_compound	     SMALLINT     DEFAULT 0,
gu_blockedby     CHAR(32)         NULL,
dt_modified      DATETIME 	      NULL,
dt_uploaded      DATETIME 	      NULL,
id_language      CHAR(2)     	  NULL,
de_product       VARCHAR(254)     NULL,
pr_list          DECIMAL(14,4)	  NULL,
pr_sale		     DECIMAL(14,4)    NULL,
pr_discount      DECIMAL(14,4)    NULL,
pr_purchase	     DECIMAL(14,4)    NULL,
id_currency      VARCHAR(16)      NULL,
pct_tax_rate 	 FLOAT            NULL,
is_tax_included  SMALLINT         NULL,
dt_start         DATETIME 	      NULL,
dt_end           DATETIME 	      NULL,
tag_product	     VARCHAR(254)     NULL,
id_ref	         VARCHAR(50)      NULL,
gu_address       CHAR(32)         NULL,

CONSTRAINT pk_products PRIMARY KEY (gu_product)
)
GO;

CREATE TABLE k_prod_fares
(
gu_product  	 CHAR(32)      NOT NULL,
id_fare          VARCHAR(32)   NOT NULL,
pr_sale		     DECIMAL(14,4) NOT NULL,
tp_fare          VARCHAR(32)       NULL,
id_currency      VARCHAR(16)       NULL,
pct_tax_rate 	 FLOAT             NULL,
is_tax_included  SMALLINT          NULL,
dt_start         DATETIME 	   NULL,
dt_end           DATETIME 	   NULL,

CONSTRAINT pk_prod_fares PRIMARY KEY (gu_product,id_fare)
)
GO;

CREATE TABLE k_prod_fares_lookup
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

CONSTRAINT pk_prod_fares_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_prod_fares_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;


CREATE TABLE k_prod_locats
(
gu_location	  CHAR(32)     NOT NULL,
gu_product  	  CHAR(32)     NOT NULL,
dt_created	  DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_owner          CHAR(32)     NOT NULL,
pg_prod_locat	  INTEGER      NOT NULL,
id_cont_type      INTEGER      NOT NULL,
id_prod_type      VARCHAR(5)   NOT NULL,
len_file	  INTEGER      NOT NULL,
xprotocol         CHARACTER VARYING(8)   DEFAULT 'file://',
xhost 		  CHARACTER VARYING(64)  DEFAULT 'localhost',
xport 		  SMALLINT     NULL,
xpath 		  CHARACTER VARYING(254) NULL,
xfile 		  CHARACTER VARYING(128) NULL,
xanchor 	  CHARACTER VARYING(128) NULL,
xoriginalfile     CHARACTER VARYING(128) NULL,
dt_modified       DATETIME     NULL,
dt_uploaded	  DATETIME     NULL,
de_prod_locat     VARCHAR(100) NULL,
status		  INTEGER      NULL,
nu_current_stock  FLOAT	       NULL,
nu_reserved_stock FLOAT	       NULL,
nu_min_stock	  FLOAT	       NULL,
vs_stamp 	  VARCHAR(16)  NULL,
tx_email	  CHARACTER VARYING(100) NULL,
tag_prod_locat	  VARCHAR(254) NULL,

CONSTRAINT pk_prod_locats PRIMARY KEY (gu_location)
)
GO;

CREATE TABLE k_prod_attr
(
gu_product     CHAR(32) NOT NULL,
adult_rated    SMALLINT     NULL,
alturl 	       VARCHAR(254) NULL,
author 	       VARCHAR(50)  NULL,
availability   VARCHAR(50)  NULL,
brand  	       VARCHAR(50)  NULL,
client         VARCHAR(50)  NULL,
color 	       VARCHAR(50)  NULL,
contact_person VARCHAR(50)  NULL,
country_code   CHAR(3)      NULL,
country        VARCHAR(50)  NULL,
cover 	       VARCHAR(50)  NULL,
days_to_deliver SMALLINT    NULL,
department     VARCHAR(50)  NULL,
disk_space     VARCHAR(50)  NULL,
display        VARCHAR(50)  NULL,
doc_no         VARCHAR(50)  NULL,
dt_acknowledge DATETIME     NULL,
dt_expire      DATETIME     NULL,
dt_out         DATETIME     NULL,
email          VARCHAR(100) NULL,
fax            VARCHAR(16)  NULL,
format         VARCHAR(50)  NULL,
forward_to     VARCHAR(50)  NULL,
icq_id         VARCHAR(32)  NULL,
ip_addr        CHARACTER VARYING(20)  NULL,
isbn           VARCHAR(16)  NULL,
nu_lines       INTEGER      NULL,
memory         VARCHAR(50)  NULL,
mobilephone    VARCHAR(16)  NULL,
office         VARCHAR(50)  NULL,
ordinal        INTEGER      NULL,
organization   VARCHAR(50)  NULL,
pages          INTEGER      NULL,
paragraphs     INTEGER      NULL,
phone1         VARCHAR(16)  NULL,
phone2         VARCHAR(16)  NULL,
power 	       VARCHAR(32)  NULL,
project        VARCHAR(50)  NULL,
product_group  VARCHAR(32)  NULL,
rank           FLOAT        NULL,
reference_id   VARCHAR(100) NULL,
revised_by     VARCHAR(50)  NULL,
rooms          SMALLINT     NULL,
scope  	       VARCHAR(100) NULL,
signature      VARCHAR(128) NULL,
size_x 	       VARCHAR(50)  NULL,
size_y 	       VARCHAR(50)  NULL,
size_z 	       VARCHAR(50)  NULL,
speed 	       VARCHAR(32)  NULL,
state_code     CHAR(9)      NULL,
state	       VARCHAR(50)  NULL,
subject        VARCHAR(100) NULL,
target 	       VARCHAR(50)  NULL,
template       VARCHAR(100) NULL,
typeof         VARCHAR(50)  NULL,
upload_by      VARCHAR(100) NULL,
weight         VARCHAR(16)  NULL,
words          INTEGER      NULL,
zip_code       VARCHAR(16)  NULL,

CONSTRAINT pk_prod_attr PRIMARY KEY (gu_product)
)
GO;

CREATE TABLE k_prod_attrs
(
gu_object  CHAR(32)     NOT NULL,
nm_attr    VARCHAR(30)  NOT NULL,
vl_attr    VARCHAR(255)     NULL,

CONSTRAINT pk_products_attrs PRIMARY KEY (gu_object,nm_attr)
)
GO;

CREATE TABLE k_prod_keywords
(
gu_product  CHAR(32)      NOT NULL,
dt_modified DATETIME 	  DEFAULT CURRENT_TIMESTAMP,
tx_keywords VARCHAR(2000) NULL,

CONSTRAINT pk_prod_keywords PRIMARY KEY (gu_product)
)
GO;
