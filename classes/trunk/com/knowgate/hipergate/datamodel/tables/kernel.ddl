CREATE TABLE k_classes
(
id_class INTEGER     NOT NULL,
nm_class CHARACTER VARYING(30) NOT NULL,

CONSTRAINT pk_classes PRIMARY KEY (id_class),
CONSTRAINT u1_classes UNIQUE (nm_class)
)
GO;

CREATE TABLE k_auditing
(
id_entity   SMALLINT NOT NULL,
co_op       CHAR(4)  NOT NULL,
gu_user     CHAR(32) NOT NULL,
dt_op       DATETIME NOT NULL,
gu_entity1  CHAR(32) NOT NULL,
gu_entity2  CHAR(32) NULL,
id_transact INTEGER  NULL,
ip_addr     INTEGER  NULL,
tx_params1  CHARACTER VARYING(100) NULL,
tx_params2  CHARACTER VARYING(100) NULL
)
GO;


CREATE TABLE k_connection_stats
(
nm_cn  VARCHAR(30) NOT NULL,
dt_op  DATETIME    DEFAULT CURRENT_TIMESTAMP,
tp_op  CHAR(1)     NOT NULL,
tx_pa  CHARACTER VARYING(100)    NULL
)
GO;

CREATE TABLE k_version
(
vs_stamp     VARCHAR(16)  NOT NULL,
dt_created   DATETIME     DEFAULT CURRENT_TIMESTAMP,
dt_modified  DATETIME     NULL,
bo_register  SMALLINT     DEFAULT 0,
bo_allow_stats SMALLINT   DEFAULT 0,
gu_support   CHAR(32)     NULL,
gu_contact   CHAR(32)     NULL,
tx_name      VARCHAR(100) NULL,
tx_surname   VARCHAR(100) NULL,
nu_employees INTEGER      NULL,
nm_company   VARCHAR(70)  NULL,
id_sector    VARCHAR(16)  NULL,
id_country   CHAR(3)      NULL,
nm_state     VARCHAR(30)  NULL,
mn_city	     VARCHAR(50)  NULL,
zipcode	     VARCHAR(30)  NULL,
work_phone   VARCHAR(16)  NULL,
tx_email     VARCHAR(70)  NULL,

CONSTRAINT pk_version PRIMARY KEY (vs_stamp)
)
GO;

GO;