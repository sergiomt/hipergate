CREATE TABLE k_examples (
gu_example  CHAR(32) NOT NULL,
gu_workarea CHAR(32) NOT NULL,
gu_writer   CHAR(32) NOT NULL,
dt_created  DATETIME DEFAULT CURRENT_TIMESTAMP,
dt_modified DATETIME     NULL,
bo_active   SMALLINT DEFAULT 1,
nm_example  VARCHAR(50)  NULL,
nu_example  INTEGER      NULL,
pr_example  FLOAT        NULL,
dt_example  DATETIME     NULL,
tp_example  VARCHAR(30)  NULL,
de_example  VARCHAR(254) NULL,
CONSTRAINT pk_examples PRIMARY KEY (gu_example),
CONSTRAINT f1_examples FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea),
CONSTRAINT f2_examples FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user),
CONSTRAINT c1_examples CHECK (dt_modified IS NULL OR dt_modified>=dt_created)
)
GO;

CREATE TABLE k_examples_lookup
(
gu_owner   CHAR(32) NOT NULL,	   /* WorkArea GUID */
id_section CHARACTER VARYING(30) NOT NULL, /* Name of column at k_examples table */
pg_lookup  INTEGER  NOT NULL,    /* Value ordinal identifier */
vl_lookup  VARCHAR(255) NULL,    /* Internal value not displayed at screen */
tr_es      VARCHAR(50)  NULL,    /* Spanish value displayed at screen */
tr_en      VARCHAR(50)  NULL,    /* English value displayed at screen  */
tr_de      VARCHAR(50)  NULL,    /* German value displayed at screen  */
tr_it      VARCHAR(50)  NULL,    /* Italian value displayed at screen  */
tr_fr      VARCHAR(50)  NULL,    /* French value displayed at screen  */
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
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_examples_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_examples_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;