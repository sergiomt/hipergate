CREATE TABLE k_lu_business_states
(
gu_status   CHAR(32)    NOT NULL,
gu_workarea CHAR(32)    NOT NULL,
id_class    INTEGER     NOT NULL,
id_status   VARCHAR(50) NOT NULL,

CONSTRAINT pk_lu_business_states PRIMARY KEY(gu_status),
CONSTRAINT u1_lu_business_states UNIQUE(gu_workarea,id_class,id_status)
)
GO;

CREATE TABLE k_business_states
(
gu_object   CHAR(32) NOT NULL,
gu_status   CHAR(32) NOT NULL,
gu_workarea CHAR(32) NOT NULL,
id_class    INTEGER  NOT NULL,
dt_start    DATETIME     NULL,
dt_end      DATETIME     NULL,
id_cause    VARCHAR(50)  NULL,
gu_writer   CHAR(32)     NULL,
tx_comments VARCHAR(254) NULL,
CONSTRAINT pk_business_states PRIMARY KEY(gu_workarea,id_class,gu_status)
)
GO;


CREATE TABLE k_shops
(
gu_shop        CHAR(32)     NOT NULL,
nm_shop        VARCHAR(100) NOT NULL,
gu_workarea    CHAR(32)     NOT NULL,
id_domain      INTEGER      NOT NULL,
gu_root_cat    CHAR(32)     NOT NULL,
gu_bundles_cat CHAR(32)     NOT NULL,
dt_created     DATETIME     DEFAULT CURRENT_TIMESTAMP,
bo_active      SMALLINT     DEFAULT 1,
id_business    VARCHAR(100) NULL, /* PayPal, FirstGate or Authorize.net merchant Id. */
id_legal       VARCHAR(16)  NULL,
nm_company     VARCHAR(70)  NULL,
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
fax_phone      VARCHAR(16)  NULL,
tx_email       CHARACTER VARYING(100) NULL,
url_addr       CHARACTER VARYING(254) NULL,
contact_person VARCHAR(100) NULL,
tx_salutation  VARCHAR(16)  NULL,
nm_bank        VARCHAR(50)  NULL,
nu_bank_acc    CHAR(28)     NULL,

CONSTRAINT pk_shops PRIMARY KEY(gu_shop),
CONSTRAINT u1_shops UNIQUE (nm_shop,gu_workarea)
)
GO;

CREATE TABLE k_sale_points
(
gu_sale_point CHAR(32)     NOT NULL,
gu_workarea   CHAR(32)     NOT NULL,
nm_sale_point VARCHAR(100) NOT NULL,
dt_created    DATETIME     DEFAULT CURRENT_TIMESTAMP,
bo_active     SMALLINT     DEFAULT 1,
gu_address    CHAR(32)     NULL,

CONSTRAINT pk_sale_points PRIMARY KEY(gu_sale_point),
CONSTRAINT u1_sale_points UNIQUE (nm_sale_point,gu_workarea)
)
GO;

CREATE TABLE k_warehouses
(
gu_warehouse  CHAR(32)     NOT NULL,
gu_workarea   CHAR(32)     NOT NULL,
nm_warehouse  VARCHAR(64)  NOT NULL,
dt_created    DATETIME     DEFAULT CURRENT_TIMESTAMP,
bo_active     SMALLINT     DEFAULT 1,
gu_address    CHAR(32)     NULL,

CONSTRAINT pk_warehouses PRIMARY KEY(gu_warehouse),
CONSTRAINT u1_warehouses UNIQUE (nm_warehouse,gu_workarea)
)
GO;

CREATE TABLE k_orders (
  gu_order       CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_order       INTEGER       NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  dt_created     DATETIME      DEFAULT CURRENT_TIMESTAMP,
  bo_active      SMALLINT      DEFAULT 1,
  bo_approved    SMALLINT      DEFAULT 1,
  bo_credit_ok   SMALLINT      DEFAULT 1,
  id_priority    VARCHAR(16)   NULL,
  gu_sales_man   CHAR(32)      NULL,
  gu_sale_point  CHAR(32)      NULL,
  gu_warehouse   CHAR(32)      NULL,
  dt_modified    DATETIME      NULL,
  dt_invoiced    DATETIME      NULL,
  dt_delivered   DATETIME      NULL,
  dt_printed     DATETIME      NULL,
  dt_promised    DATETIME      NULL,
  dt_payment     DATETIME      NULL,
  dt_cancel      DATETIME      NULL,
  de_order       VARCHAR(100)  NULL,
  tx_location    VARCHAR(100)  NULL,
  gu_company     CHAR(32)      NULL,
  gu_contact     CHAR(32)      NULL,
  nm_client	     VARCHAR(200)  NULL,
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
  tp_billing     CHAR(1)       NULL,    			/* Tipo de opción de cobro ( T=Tarjeta, B=Banco, ... ) */
  nu_bank   	 CHAR(28)      NULL,				/* Nº de cuenta bancaria */
  nm_cardholder	 VARCHAR(100)  NULL,				/* Titular de la cuenta o la tarjeta */
  nu_card        CHAR(16)      NULL,				/* Nº de la tarjeta */
  tp_card        VARCHAR(30)   NULL,				/* Tipo de la tarjeta ( MASTERCARD,VISA,AMEX,...) */
  tx_expire      VARCHAR(10)   NULL,				/* Fecha Expiración de la Tarjeta */
  nu_pin         VARCHAR(7)    NULL,				/* Pin de la Tarjeta */
  nu_cvv2        VARCHAR(4)    NULL,
  tx_ship_notes  VARCHAR(254)  NULL,
  tx_email_to    CHARACTER VARYING(100) NULL,
  tx_comments    VARCHAR(254)  NULL,

  CONSTRAINT pk_orders PRIMARY KEY(gu_order),
  CONSTRAINT u1_orders UNIQUE(gu_workarea,pg_order)  
)
GO;

CREATE TABLE k_orders_lookup
(
gu_owner   CHAR(32)     NOT NULL,
id_section CHARACTER VARYING(30)  NOT NULL,
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

CONSTRAINT pk_orders_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_orders_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_order_lines (
  gu_order        CHAR(32)      NOT NULL,
  pg_line         INTEGER       NOT NULL,
  pr_sale         DECIMAL(14,4) NOT NULL,
  nu_quantity     FLOAT	        NOT NULL,
  id_unit         VARCHAR(16)   DEFAULT 'UNIT',
  pr_total        DECIMAL(14,4) NOT NULL,
  pct_tax_rate    FLOAT         NOT NULL,
  is_tax_included SMALLINT      NOT NULL,
  nm_product      VARCHAR(128)  NOT NULL,
  id_status       VARCHAR(50)       NULL,
  gu_product      CHAR(32)          NULL,
  gu_item         CHAR(32)          NULL,
  tx_promotion    VARCHAR(100)      NULL,
  tx_options      VARCHAR(254)      NULL,

  CONSTRAINT pk_order_line PRIMARY KEY(gu_order,pg_line),
  CONSTRAINT c1_order_lines CHECK (pg_line>0)
)
GO;

CREATE TABLE k_despatch_advices (
  gu_despatch    CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_despatch    INTEGER       NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  dt_created     DATETIME      DEFAULT CURRENT_TIMESTAMP,
  bo_approved    SMALLINT      DEFAULT 1,
  bo_credit_ok   SMALLINT      DEFAULT 1,
  id_priority    VARCHAR(16)   NULL,
  gu_warehouse   CHAR(32)      NULL,
  dt_modified    DATETIME      NULL,
  dt_delivered   DATETIME      NULL,
  dt_printed     DATETIME      NULL,
  dt_promised    DATETIME      NULL,
  dt_payment     DATETIME      NULL,
  dt_cancel      DATETIME      NULL,
  de_despatch    VARCHAR(255)  NULL,
  tx_location    VARCHAR(100)  NULL,
  gu_company     CHAR(32)      NULL,
  gu_contact     CHAR(32)      NULL,
  nm_client	     VARCHAR(200)  NULL,
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
  tx_email_to    CHARACTER VARYING(100) NULL,
  tx_comments    VARCHAR(254)  NULL,

  CONSTRAINT pk_despatch_advices PRIMARY KEY(gu_despatch),
  CONSTRAINT u1_despatch_advices UNIQUE(gu_workarea,pg_despatch)  
)
GO;

CREATE TABLE k_despatch_lines (
  gu_despatch     CHAR(32)      NOT NULL,
  pg_line         INTEGER       NOT NULL,
  pr_sale         DECIMAL(14,4)     NULL,
  nu_quantity     FLOAT	            NULL,
  id_unit         VARCHAR(16)   DEFAULT 'UNIT',
  pr_total        DECIMAL(14,4)     NULL,
  pct_tax_rate    FLOAT             NULL,
  is_tax_included SMALLINT          NULL,
  nm_product      VARCHAR(128)  NOT NULL,
  gu_product      CHAR(32)          NULL,
  gu_item         CHAR(32)          NULL,
  id_status       VARCHAR(50)       NULL,
  tx_promotion    VARCHAR(100)      NULL,
  tx_options      VARCHAR(254)      NULL,

  CONSTRAINT pk_despatch_lines PRIMARY KEY(gu_despatch,pg_line),
  CONSTRAINT c1_despatch_lines CHECK (pg_line>0)
)
GO;

CREATE TABLE k_x_orders_despatch
(
  gu_order    CHAR(32) NOT NULL,
  gu_despatch CHAR(32) NOT NULL,

  CONSTRAINT pk_x_orders_despatch PRIMARY KEY(gu_order,gu_despatch)
)
GO;

CREATE TABLE k_despatch_advices_lookup
(
gu_owner   CHAR(32)     NOT NULL,
id_section CHARACTER VARYING(30)  NOT NULL,
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
tr_sk      VARCHAR(50)      NULL,
tr_pl      VARCHAR(50)      NULL,
tr_vn      VARCHAR(50)      NULL,

CONSTRAINT pk_despatch_advices_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_despatch_advices_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_despatch_next
(
  gu_workarea CHAR(32) NOT NULL,
  pg_despatch INTEGER  NOT NULL,
  CONSTRAINT pk_despatch_next PRIMARY KEY(gu_workarea,pg_despatch)
)
GO;

CREATE TABLE k_invoice_schedules
(
  gu_schedule     CHAR(32)     NOT NULL,
  gu_workarea     CHAR(32)     NOT NULL,
  gu_template     CHAR(32)     NOT NULL,
  dt_created      DATETIME     DEFAULT CURRENT_TIMESTAMP,
  bo_active       SMALLINT     DEFAULT 1,
  nu_max_rebills  INTEGER      DEFAULT 99,
  gu_company      CHAR(32)     NULL,
  gu_contact      CHAR(32)     NULL,
  dt_1st_invoice  DATETIME     NULL,
  nd_next_invoice SMALLINT     NULL,

  CONSTRAINT pk_invoice_schedules PRIMARY KEY(gu_schedule)
)
GO;

CREATE TABLE k_invoices (
  gu_invoice     CHAR(32)     NOT NULL,
  gu_workarea    CHAR(32)     NOT NULL,
  pg_invoice     INTEGER      NOT NULL,
  gu_shop        CHAR(32)     NOT NULL,
  id_currency    CHAR(3)      NOT NULL,
  id_legal       VARCHAR(16)  NOT NULL,
  dt_created     DATETIME     DEFAULT CURRENT_TIMESTAMP,
  bo_active      SMALLINT     DEFAULT 1,
  bo_approved    SMALLINT     DEFAULT 1,
  bo_template    SMALLINT     DEFAULT 0,
  gu_schedule    CHAR(32)     NULL,
  gu_sales_man   CHAR(32)     NULL,
  gu_sale_point  CHAR(32)     NULL,
  gu_warehouse   CHAR(32)     NULL,
  dt_modified    DATETIME     NULL,
  dt_invoiced    DATETIME     NULL,
  dt_printed     DATETIME     NULL,
  dt_payment     DATETIME     NULL,
  dt_paid        DATETIME     NULL,
  dt_cancel      DATETIME     NULL,
  de_order       VARCHAR(100) NULL,
  tx_location    VARCHAR(100) NULL,
  gu_company     CHAR(32)     NULL,
  gu_contact     CHAR(32)     NULL,
  nm_client	     VARCHAR(200) NULL,
  gu_ship_addr   CHAR(32)     NULL,
  gu_bill_addr   CHAR(32)     NULL,
  id_ref         VARCHAR(50)  NULL,
  id_status      VARCHAR(30)  NULL,
  id_pay_status  VARCHAR(30)  NULL,
  id_ship_method VARCHAR(30)  NULL,
  im_subtotal    DECIMAL(14,4) NULL,
  im_taxes       DECIMAL(14,4) NULL,
  im_shipping    DECIMAL(14,4) NULL,
  im_discount    VARCHAR(10)  NULL,
  im_total       DECIMAL(14,4) NULL,
  im_paid        DECIMAL(14,4) NULL,
  tp_billing     CHAR(1)      NULL,    				/* Tipo de opción de cobro (T=Tarjeta, B=Banco, ... ) */
  nu_bank   	 CHAR(28)     NULL,				/* Nº de cuenta bancaria */
  nm_cardholder	 VARCHAR(100) NULL,				/* Titular de la cuenta o la tarjeta */
  nu_card        CHAR(16)     NULL,				/* Nº de la tarjeta */
  tp_card        VARCHAR(30)  NULL,				/* Tipo de la tarjeta ( MASTERCARD,VISA,AMEX,...) */
  tx_expire      VARCHAR(10)  NULL,				/* Fecha Expiración de la Tarjeta */
  nu_pin         VARCHAR(7)   NULL,				/* Pin de la Tarjeta */
  nu_cvv2        VARCHAR(4)   NULL,
  tx_ship_notes  VARCHAR(254) NULL,
  tx_email_to    CHARACTER VARYING(100) NULL,
  tx_comments    VARCHAR(254) NULL,

  CONSTRAINT pk_invoices PRIMARY KEY(gu_invoice),
  CONSTRAINT u1_invoices UNIQUE(gu_workarea,pg_invoice),
  CONSTRAINT c1_invoices CHECK (dt_printed IS NULL OR dt_printed>=dt_modified)
)
GO;

CREATE TABLE k_returned_invoices (
  gu_returned    CHAR(32)     NOT NULL,
  gu_invoice     CHAR(32)     NOT NULL,
  gu_workarea    CHAR(32)     NOT NULL,
  pg_returned    INTEGER      NOT NULL,
  gu_shop        CHAR(32)     NOT NULL,
  id_currency    CHAR(3)      NOT NULL,
  id_legal       VARCHAR(16)  NOT NULL,
  dt_created     DATETIME     DEFAULT CURRENT_TIMESTAMP,
  bo_active      SMALLINT     DEFAULT 1,
  bo_approved    SMALLINT     DEFAULT 1,
  dt_modified    DATETIME     NULL,
  dt_returned    DATETIME     NULL,
  dt_printed     DATETIME     NULL,
  de_returned    VARCHAR(100) NULL,
  gu_company     CHAR(32)     NULL,
  gu_contact     CHAR(32)     NULL,
  nm_client	     VARCHAR(200) NULL,
  gu_bill_addr   CHAR(32)     NULL,
  id_ref         VARCHAR(50)  NULL,
  id_status      VARCHAR(30)  NULL,
  id_pay_status  VARCHAR(30)  NULL,
  im_subtotal    DECIMAL(14,4) NULL,
  im_taxes       DECIMAL(14,4) NULL,
  im_shipping    DECIMAL(14,4) NULL,
  im_discount    VARCHAR(10)  NULL,
  im_total       DECIMAL(14,4) NULL,
  tp_billing     CHAR(1)      NULL,
  nu_bank   	 CHAR(28)     NULL,
  tx_email_to    CHARACTER VARYING(100) NULL,
  tx_comments    VARCHAR(254) NULL,

  CONSTRAINT pk_returned_invoices PRIMARY KEY(gu_returned),
  CONSTRAINT c1_returned_invoices CHECK (dt_printed IS NULL OR dt_printed>=dt_modified),
  CONSTRAINT c2_returned_invoices CHECK (dt_returned IS NULL OR dt_returned>=dt_modified)
)
GO;

CREATE TABLE k_invoice_payments (
  gu_invoice     CHAR(32)      NOT NULL,
  pg_payment     INTEGER       NOT NULL,
  bo_active      SMALLINT      DEFAULT 1,
  dt_payment     DATETIME      NOT NULL,
  dt_paid        DATETIME          NULL,
  dt_expire      DATETIME          NULL,
  id_currency    CHAR(3)       NOT NULL,
  im_paid        DECIMAL(14,4) NOT NULL,
  tp_billing     CHAR(1)       NULL,
  id_ref         VARCHAR(50)   NULL,
  id_transact    VARCHAR(32)   NULL,
  id_country     CHAR(3)       NULL,
  id_authcode    VARCHAR(6)    NULL,  
  nm_client	     VARCHAR(200)  NULL,
  tx_comments    VARCHAR(254)  NULL,

  CONSTRAINT pk_invoice_payments PRIMARY KEY(gu_invoice,pg_payment)
)
GO;

CREATE TABLE k_x_orders_invoices
(
  gu_order   CHAR(32) NOT NULL,
  gu_invoice CHAR(32) NOT NULL,

  CONSTRAINT pk_x_orders_invoices PRIMARY KEY(gu_order,gu_invoice)
)
GO;

CREATE TABLE k_invoices_next
(
  gu_workarea    CHAR(32)     NOT NULL,
  pg_invoice     INTEGER      NOT NULL,
  CONSTRAINT pk_invoices_next PRIMARY KEY(gu_workarea,pg_invoice)
)
GO;


CREATE TABLE k_invoices_lookup
(
gu_owner   CHAR(32)     NOT NULL,
id_section CHARACTER VARYING(30)  NOT NULL,
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
tr_sk      VARCHAR(50)      NULL,
tr_pl      VARCHAR(50)      NULL,
tr_vn      VARCHAR(50)      NULL,

CONSTRAINT pk_invoices_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_invoices_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_invoice_lines (
  gu_invoice      CHAR(32)      NOT NULL,
  pg_line         INTEGER       NOT NULL,
  pr_sale         DECIMAL(14,4) NOT NULL,
  nu_quantity     FLOAT         NOT NULL,
  id_unit         VARCHAR(16)   DEFAULT 'UNIT',  
  pr_total        DECIMAL(14,4) NOT NULL,
  pct_tax_rate    FLOAT         NOT NULL,
  is_tax_included SMALLINT      NOT NULL,
  nm_product      VARCHAR(128)  NOT NULL,
  gu_product      CHAR(32)          NULL,
  gu_item         CHAR(32)          NULL,
  tx_promotion    VARCHAR(100)      NULL,
  tx_options      VARCHAR(254)      NULL,

  CONSTRAINT pk_invoice_line PRIMARY KEY(gu_invoice,pg_line),
  CONSTRAINT c1_invoice_lines CHECK (pg_line>0)
)
GO;

CREATE TABLE k_quotations (
  gu_quotation   CHAR(32)      NOT NULL,
  gu_workarea    CHAR(32)      NOT NULL,
  pg_quotation   INTEGER       NOT NULL,
  gu_shop        CHAR(32)      NOT NULL,
  id_currency    CHAR(3)       NOT NULL,
  dt_created     DATETIME      DEFAULT CURRENT_TIMESTAMP,
  dt_modified    DATETIME      NULL,
  dt_sent        DATETIME      NULL,
  dt_promised    DATETIME      NULL,
  dt_delivered   DATETIME      NULL,
  de_quotation   VARCHAR(100)  NULL,
  gu_pageset     CHAR(32)      NULL,
  gu_sales_man   CHAR(32)      NULL,
  gu_company     CHAR(32)      NULL,
  gu_contact     CHAR(32)      NULL,
  gu_supplier    CHAR(32)      NULL,
  gu_base_quotation CHAR(32)   NULL,
  nm_client	     VARCHAR(200)  NULL,
  gu_bill_addr   CHAR(32)      NULL,
  id_ref         VARCHAR(50)   NULL,
  im_subtotal    DECIMAL(14,4) NULL,
  im_taxes       DECIMAL(14,4) NULL,
  im_shipping    DECIMAL(14,4) NULL,
  im_discount    VARCHAR(10)   NULL,
  im_total       DECIMAL(14,4) NULL,
  tp_billing     CHAR(1)       NULL,
  tx_email_to    CHARACTER VARYING(100) NULL,
  tx_comments    VARCHAR(254)  NULL,

  CONSTRAINT pk_quotations PRIMARY KEY(gu_quotation),
  CONSTRAINT u1_quotations UNIQUE(gu_workarea,pg_quotation)
  
)
GO;

CREATE TABLE k_quotation_lines (
  gu_quotation    CHAR(32)      NOT NULL,
  pg_line         INTEGER       NOT NULL,
  pr_sale         DECIMAL(14,4) NOT NULL,
  nu_quantity     FLOAT	        NOT NULL,
  id_unit         VARCHAR(16)   DEFAULT 'UNIT',
  pr_total        DECIMAL(14,4) NOT NULL,
  pct_tax_rate    FLOAT         NOT NULL,
  is_tax_included SMALLINT      DEFAULT 1,
  nm_product      VARCHAR(128)  NOT NULL,
  gu_product      CHAR(32)          NULL,
  gu_item         CHAR(32)          NULL,
  tx_promotion    VARCHAR(100)      NULL,
  tx_options      VARCHAR(254)      NULL,

  CONSTRAINT pk_quotation_line PRIMARY KEY(gu_quotation,pg_line),
  CONSTRAINT c1_quotation_lines CHECK (pg_line>0)
)
GO;

CREATE TABLE k_x_quotations_orders
(
  gu_order     CHAR(32) NOT NULL,
  gu_quotation CHAR(32) NOT NULL,

  CONSTRAINT pk_x_quotations_orders PRIMARY KEY(gu_order,gu_quotation)
)
GO;

CREATE TABLE k_quotations_next
(
  gu_workarea  CHAR(32) NOT NULL,
  pg_quotation INTEGER  NOT NULL,
  CONSTRAINT pk_quotations_next PRIMARY KEY(gu_workarea,pg_quotation)
)
GO;
