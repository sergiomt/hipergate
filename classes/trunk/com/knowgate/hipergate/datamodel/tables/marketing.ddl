CREATE TABLE k_campaigns
(
gu_campaign    CHAR(32)    NOT NULL,
gu_workarea    CHAR(32)    NOT NULL,
nm_campaign    VARCHAR(70) NOT NULL,
dt_created     DATETIME    DEFAULT CURRENT_TIMESTAMP,
bo_active      SMALLINT    DEFAULT 1,
CONSTRAINT pk_campaigns PRIMARY KEY (gu_campaign),
CONSTRAINT u1_campaigns UNIQUE (gu_workarea,nm_campaign)
)
GO;

CREATE TABLE k_x_campaign_lists
(
gu_campaign    CHAR(32)    NOT NULL,
gu_list        CHAR(32)    NOT NULL,
bo_active      SMALLINT    DEFAULT 1,
dt_created     DATETIME    DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT pk_x_campaign_lists PRIMARY KEY (gu_campaign,gu_list)
)
GO;

CREATE TABLE k_campaign_targets
(
gu_campaign_target CHAR(32) NOT NULL,
gu_campaign    CHAR(32)     NOT NULL,
gu_geozone     CHAR(32)     NOT NULL,
gu_product     CHAR(32)     NOT NULL,
dt_created     DATETIME     DEFAULT CURRENT_TIMESTAMP,
dt_start       DATETIME     NOT NULL,
dt_end         DATETIME     NOT NULL,
dt_modified    DATETIME     NOT NULL,
nu_planned     FLOAT	    NOT NULL,
nu_achieved    FLOAT	    NOT NULL,
CONSTRAINT pk_campaign_targets PRIMARY KEY (gu_campaign_target),
CONSTRAINT c1_campaign_targets CHECK (dt_end>=dt_start),
CONSTRAINT c2_campaign_targets CHECK (dt_modified>=dt_created)
)
GO;

CREATE VIEW v_campaign_contacts AS 
SELECT l.gu_list,l.tp_list,l.gu_query,l.de_list,m.gu_contact,m.gu_company,m.bo_active,m.dt_created,m.dt_modified,m.tx_salutation,m.tx_email,m.tx_name,m.tx_surname,m.id_format
FROM k_campaigns g, k_x_campaign_lists x, k_lists l, k_x_list_members m, k_contacts c
WHERE g.gu_campaign=x.gu_campaign AND x.gu_list=l.gu_list AND l.gu_list=m.gu_list AND m.gu_contact=c.gu_contact
GO;

CREATE TABLE k_activities
(
gu_activity    CHAR(32)      NOT NULL,
gu_workarea    CHAR(32)      NOT NULL,
dt_created     DATETIME      DEFAULT CURRENT_TIMESTAMP,
tl_activity    VARCHAR(100)  NOT NULL,
pg_activity    INTEGER       NULL,
bo_active      SMALLINT DEFAULT 1,
dt_modified    DATETIME      NULL,
dt_start       DATETIME      NULL,
dt_end         DATETIME      NULL,
gu_address     CHAR(32)      NULL,
gu_campaign    CHAR(32)      NULL,
gu_list        CHAR(32)      NULL,
gu_writer      CHAR(32)      NULL,
gu_meeting     CHAR(32)      NULL,
gu_pageset     CHAR(32)      NULL,
gu_mailing     CHAR(32)      NULL,
dt_mailing     DATETIME      NULL,
tx_subject     VARCHAR(254)  NULL,
tx_email_from  CHARACTER VARYING(254) NULL,
nm_from        CHARACTER VARYING(254) NULL,
url_activity   CHARACTER VARYING(254) NULL,
nm_author      VARCHAR(200)  NULL,
nu_capacity    INTEGER       NULL,
pr_sale		   DECIMAL(14,4) NULL,
pr_discount    DECIMAL(14,4) NULL,
id_language    CHAR(2)       NULL,
id_ref         VARCHAR(50)   NULL,
tx_dept        VARCHAR(70)   NULL,
de_activity    VARCHAR(1000) NULL,
tx_comments    VARCHAR(254)  NULL,

CONSTRAINT pk_activities PRIMARY KEY (gu_activity),
CONSTRAINT u1_activities UNIQUE (gu_workarea,tl_activity),
CONSTRAINT c1_activities CHECK ((dt_start IS NULL AND dt_end IS NULL) OR dt_end IS NULL OR dt_end>=dt_start),
CONSTRAINT c2_activities CHECK (nu_capacity>=0),
CONSTRAINT c3_activities CHECK (pr_sale>=0),
CONSTRAINT c4_activities CHECK (pr_discount>=0)
)
GO;

CREATE TABLE k_activity_attachs
(
gu_activity  CHAR(32)     NOT NULL,
pg_product   INTEGER      NOT NULL,
gu_product   CHAR(32)     NOT NULL,
dt_created   DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_writer    CHAR(32)     NOT NULL,

CONSTRAINT pk_activity_attachs PRIMARY KEY (gu_activity,pg_product)
)
GO;

CREATE TABLE k_activity_tags
(
gu_activity  CHAR(32)     NOT NULL,
tp_tag       SMALLINT     NOT NULL,
nm_tag       VARCHAR(30)  NOT NULL,

CONSTRAINT pk_activity_tags PRIMARY KEY (gu_activity,nm_tag)
)
GO;

CREATE TABLE k_x_activity_audience (
gu_activity   CHAR(32)      NOT NULL,
gu_contact    CHAR(32)      NOT NULL,
gu_address    CHAR(32)      NULL,
gu_list       CHAR(32)      NULL,
gu_writer     CHAR(32)      NULL,
dt_created    DATETIME      DEFAULT CURRENT_TIMESTAMP,
dt_modified   DATETIME      NULL,
id_ref        VARCHAR(50)   NULL,
tp_origin     VARCHAR(50)   NULL,
bo_confirmed  SMALLINT      DEFAULT 0,
dt_confirmed  DATETIME      NULL,
bo_paid       SMALLINT      DEFAULT 0,
dt_paid       DATETIME      NULL,
im_paid       DECIMAL(14,4) NULL,
id_transact   VARCHAR(32)   NULL,
tp_billing    CHAR(1)       NULL,
bo_went       SMALLINT DEFAULT 0,
bo_allows_ads SMALLINT DEFAULT 0,
gu_sales_man  CHAR(32)      NULL,
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

CREATE TABLE k_activity_audience_lookup
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

CONSTRAINT pk_activity_audience_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_activity_audience_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_syndsearches
(
tx_sought VARCHAR(254) NOT NULL,
dt_created   DATETIME      DEFAULT CURRENT_TIMESTAMP,
dt_last_run  DATETIME      NULL,
dt_next_run  DATETIME      NULL,
dt_last_request DATETIME   NULL,
nu_rerun_after_secs INTEGER DEFAULT 1200,
nu_runs      INTEGER       NULL,
nu_requests  INTEGER       NULL,
nu_results   INTEGER       NULL,
xml_recent   LONGVARCHAR   NULL,
CONSTRAINT pk_syndsearches PRIMARY KEY (tx_sought)
)
GO;

CREATE TABLE k_syndsearch_request
(
id_request INTEGER      NOT NULL,
tx_sought  VARCHAR(254) NOT NULL,
dt_request DATETIME         NULL,
nu_milis   INTEGER          NULL,
gu_user    CHAR(32)         NULL,
gu_account CHAR(32)         NULL,
CONSTRAINT pk_syndsearch_request PRIMARY KEY (id_request)
)
GO;

CREATE TABLE k_syndsearch_run
(
id_run       INTEGER      NOT NULL,
tx_sought    VARCHAR(254) NOT NULL,
dt_run       DATETIME         NULL,
nu_milis     INTEGER          NULL,
nu_entries   INTEGER          NULL,
CONSTRAINT pk_syndsearch_run PRIMARY KEY (id_run)
)
GO;

CREATE TABLE k_syndreferers
(
id_syndref VARCHAR(480) NOT NULL,
dt_created DATETIME DEFAULT CURRENT_TIMESTAMP,
tx_sought  VARCHAR(254) NOT NULL,
url_domain VARCHAR(100) NOT NULL,
nu_entries   INTEGER        NULL,
CONSTRAINT pk_syndreferers PRIMARY KEY (id_syndref)
)
GO;

CREATE TABLE k_syndentries
(
id_domain    INTEGER       NOT NULL,
id_syndentry INTEGER       NOT NULL,
gu_workarea  CHAR(32)      NULL,
uri_entry    VARCHAR(200)  NOT NULL,
gu_feed      CHAR(32)      NULL,
id_type      VARCHAR(50)   NULL,
id_acalias   VARCHAR(150)  NULL,
id_country   CHAR(2)       NULL,
id_language  CHAR(2)       NULL,
dt_created   DATETIME      DEFAULT CURRENT_TIMESTAMP,
dt_published DATETIME      NULL,
dt_modified  DATETIME      NULL,
dt_run       DATETIME      NULL,
tx_sought    CHARACTER VARYING(254)  NULL,
tx_sought_by_date CHARACTER VARYING(276)  NULL,
gu_account   CHAR(32)      NULL,
nu_influence INTEGER       NULL,
nu_relevance INTEGER       NULL,
url_author   CHARACTER VARYING(254)  NULL,
tl_entry     CHARACTER VARYING(254)  NULL,
de_entry     CHARACTER VARYING(1000) NULL,
url_addr     VARCHAR(254)  NULL,
url_domain   VARCHAR(254)  NULL,
bin_entry    LONGVARBINARY NULL,
CONSTRAINT pk_syndentries PRIMARY KEY (id_syndentry)
)
GO;

CREATE TABLE k_syndfeeds_info_cache
(
url   VARCHAR(254) NOT NULL,
bin_info LONGVARBINARY NULL,
CONSTRAINT pk_syndfeeds_info_cache PRIMARY KEY (url)
)
GO;
