
CREATE TABLE k_lu_job_commands
(
id_command    CHAR(4) NOT NULL,			/* Comando de ejecución */
tx_command    VARCHAR(254) NULL,		/* Descripción de la acción */
nm_class      CHARACTER VARYING(254) NULL,      /* Nombre de la clase Java que ejecuta la accion */

CONSTRAINT pk_lu_job_commands PRIMARY KEY(id_command)
)
GO;

CREATE TABLE k_lu_job_status
(
    id_status SMALLINT NOT NULL,
    tr_en VARCHAR(30)  NULL,
    tr_es VARCHAR(30)  NULL,
    tr_de VARCHAR(30)  NULL,
    tr_it VARCHAR(30)  NULL,
    tr_fr VARCHAR(30)  NULL,
    tr_pt VARCHAR(30)  NULL,
    tr_ca VARCHAR(30)  NULL,
    tr_eu VARCHAR(30)  NULL,
    tr_ja VARCHAR(30)  NULL,
    tr_cn VARCHAR(30)  NULL,
    tr_tw VARCHAR(30)  NULL,
    tr_ru VARCHAR(30)  NULL,
    tr_nl VARCHAR(30)  NULL,
    tr_th VARCHAR(30)  NULL,
    tr_cs VARCHAR(30)  NULL,
    tr_uk VARCHAR(30)  NULL,
    tr_no VARCHAR(30)  NULL,
    tr_sk VARCHAR(30)  NULL,
    tr_pl VARCHAR(30)  NULL,
    tr_vn VARCHAR(30)  NULL,
    tr_u1 VARCHAR(30)  NULL,
    tr_u2 VARCHAR(30)  NULL,
    tr_u3 VARCHAR(30)  NULL,
    tr_u4 VARCHAR(30)  NULL,

    CONSTRAINT pk_lu_job_status PRIMARY KEY (id_status)
)
GO;

CREATE TABLE k_jobs
(
gu_job	      CHAR(32)    NOT NULL,	        /* GUID del proceso */
gu_workarea   CHAR(32)    NOT NULL,		/* GUID de la workarea */
gu_writer     CHAR(32)    NOT NULL,		/* GUID del usuario que creó el job */
id_command    CHAR(4)     NOT NULL,		/* Comando de ejecución */
id_status     SMALLINT    NOT NULL,  		/* Estado, pendiente, suspendido, abortado, terminado. */
dt_created    DATETIME    DEFAULT CURRENT_TIMESTAMP, /* Fecha de creación del registro */
tl_job        VARCHAR(100)    NULL,	        /* Titulo descriptivo del job */
gu_job_group  CHAR(32)        NULL,             /* GUID del lote de proceso */
tx_parameters VARCHAR(2000)   NULL,		/* Parámetros de ejecución (atributo=valor,atributo=valor,...) */
dt_execution  DATETIME        NULL,		/* Fecha programada de ejecución */
dt_finished   DATETIME        NULL,  	        /* Fecha de terminación */
dt_modified   DATETIME        NULL,	        /* Fecha de modificación del registro */

CONSTRAINT pk_jobs PRIMARY KEY(gu_job)
)
GO;

CREATE TABLE k_job_atoms
(
gu_job         CHAR(32)   NOT NULL,
pg_atom        SERIAL,
dt_execution   DATETIME   DEFAULT CURRENT_TIMESTAMP,
id_status      SMALLINT   DEFAULT 1,
id_format      CHARACTER VARYING(4)   DEFAULT 'TXT',
tp_recipient   CHARACTER VARYING(4)   NULL,
gu_company     CHAR(32)     NULL,
gu_contact     CHAR(32)     NULL,
tx_email       CHARACTER VARYING(100) NULL,
tx_name        VARCHAR(200) NULL,
tx_surname     VARCHAR(200) NULL,
tx_salutation  VARCHAR(16)  NULL,
nm_commercial  VARCHAR(70)  NULL,
tp_street      VARCHAR(16)  NULL,
nm_street      VARCHAR(100) NULL,
nu_street      VARCHAR(16)  NULL,
tx_addr1       VARCHAR(100) NULL,
tx_addr2       VARCHAR(100) NULL,
nm_country     VARCHAR(50)  NULL,
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
tx_log         VARCHAR(254) NULL,

CONSTRAINT pk_job_atoms PRIMARY KEY(pg_atom)
)
GO;

CREATE TABLE k_job_atoms_archived
(
gu_job         CHAR(32)   NOT NULL,
pg_atom        INTEGER    NOT NULL,
dt_execution   DATETIME   DEFAULT CURRENT_TIMESTAMP,
id_status      SMALLINT   DEFAULT 1,
id_format      VARCHAR(4) DEFAULT 'TXT',
gu_company     CHAR(32)     NULL,
gu_contact     CHAR(32)     NULL,
tx_email       CHARACTER VARYING(100) NULL,
tx_name        VARCHAR(200) NULL,
tx_surname     VARCHAR(200) NULL,
tx_salutation  VARCHAR(16)  NULL,
nm_commercial  VARCHAR(70)  NULL,
tp_street      VARCHAR(16)  NULL,
nm_street      VARCHAR(100) NULL,
nu_street      VARCHAR(16)  NULL,
tx_addr1       VARCHAR(100) NULL,
tx_addr2       VARCHAR(100) NULL,
nm_country     VARCHAR(50)  NULL,
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
tx_log         VARCHAR(254) NULL,

CONSTRAINT pk_job_atoms_archived PRIMARY KEY(gu_job, pg_atom)
)
GO;

CREATE TABLE k_job_atoms_tracking
(
gu_job         CHAR(32)   NOT NULL,
pg_atom        INTEGER    NOT NULL,
dt_action      DATETIME   DEFAULT CURRENT_TIMESTAMP,
id_status      SMALLINT   DEFAULT 1,
gu_company     CHAR(32)     NULL,
gu_contact     CHAR(32)     NULL,
ip_addr        CHARACTER VARYING(16) NULL,
tx_email       CHARACTER VARYING(100) NULL,
user_agent     VARCHAR(254) NULL
)
GO;

CREATE TABLE k_queries
(
gu_query      CHAR(32)     NOT NULL,
dt_created    DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_workarea   CHAR(32)     NOT NULL,
tl_query      VARCHAR(100) NOT NULL,
nm_queryspec  CHARACTER VARYING(128) NOT NULL,
dt_modified   DATETIME     NULL,
nm_field1     VARCHAR(32)  NULL,
nm_field2     VARCHAR(32)  NULL,
nm_field3     VARCHAR(32)  NULL,
nm_operator1  CHARACTER VARYING(2) NULL,
nm_operator2  CHARACTER VARYING(2) NULL,
nm_operator3  CHARACTER VARYING(2) NULL,
tx_value1     VARCHAR(255) NULL,
tx_value2     VARCHAR(255) NULL,
tx_value3     VARCHAR(255) NULL,
vl_code1      VARCHAR(255) NULL,
vl_code2      VARCHAR(255) NULL,
vl_code3      VARCHAR(255) NULL,
tx_condition1 CHARACTER VARYING(3) NULL,
tx_condition2 CHARACTER VARYING(3) NULL,
tx_orderby    CHARACTER VARYING(255) NULL,
tx_columns    CHARACTER VARYING(4000) NULL,

CONSTRAINT pk_queries PRIMARY KEY (gu_query),
CONSTRAINT u1_queries UNIQUE(gu_workarea,tl_query),
CONSTRAINT c1_queries CHECK (nm_field1 IS NULL OR LENGTH(nm_field1)>0),
CONSTRAINT c2_queries CHECK (nm_field2 IS NULL OR LENGTH(nm_field2)>0),
CONSTRAINT c3_queries CHECK (nm_field3 IS NULL OR LENGTH(nm_field3)>0),
CONSTRAINT c4_queries CHECK (nm_operator1 IS NULL OR LENGTH(nm_operator1)>0),
CONSTRAINT c5_queries CHECK (nm_operator2 IS NULL OR LENGTH(nm_operator2)>0),
CONSTRAINT c6_queries CHECK (nm_operator3 IS NULL OR LENGTH(nm_operator3)>0),
CONSTRAINT c7_queries CHECK (tx_value1 IS NULL OR LENGTH(tx_value1)>0),
CONSTRAINT c8_queries CHECK (tx_value2 IS NULL OR LENGTH(tx_value2)>0),
CONSTRAINT c9_queries CHECK (tx_value3 IS NULL OR LENGTH(tx_value3)>0)
)
GO;

CREATE TABLE k_events (
    id_domain   INTEGER                NOT NULL,
    id_event    CHARACTER VARYING(64)  NOT NULL,
    dt_created  DATETIME DEFAULT CURRENT_TIMESTAMP,
    dt_modified DATETIME               NULL,
    bo_active   SMALLINT               DEFAULT 1,
    gu_writer   CHAR(32)               NOT NULL,
    id_command  CHAR(4)                NOT NULL,
    id_app      INTEGER                NOT NULL,
    gu_workarea CHAR(32)               NULL,
    de_event    CHARACTER VARYING(254) NULL,
    tx_parameters VARCHAR(2000)        NULL,
    
    CONSTRAINT pk_events PRIMARY KEY (id_domain,id_event)
)
GO;
