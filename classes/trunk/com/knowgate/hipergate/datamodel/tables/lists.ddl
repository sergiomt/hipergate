CREATE TABLE k_lists
(
gu_list     CHAR(32) NOT NULL,
dt_created  DATETIME DEFAULT CURRENT_TIMESTAMP,
gu_workarea CHAR(32) NOT NULL,
tp_list     SMALLINT NOT NULL, /* 1=Lista Estática, 2=Lista Dinámica, 3=Lista Directa, 4=Negra */
gu_query    CHAR(32)     NULL,
de_list     VARCHAR(50)  NULL,
tx_sender   VARCHAR(100) NULL,
tx_from     CHARACTER VARYING(100) NULL,
tx_reply    CHARACTER VARYING(100) NULL,
tx_subject  VARCHAR(100) NULL,

CONSTRAINT pk_lists PRIMARY KEY (gu_list),
CONSTRAINT f1_lists FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea),
CONSTRAINT c2_lists CHECK (tx_sender IS NULL OR LENGTH(tx_sender)>0),
CONSTRAINT c3_lists CHECK (tx_from IS NULL OR LENGTH(tx_from)>0),
CONSTRAINT c4_lists CHECK (tx_reply IS NULL OR LENGTH(tx_reply)>0),
CONSTRAINT c5_lists CHECK (tx_subject IS NULL OR LENGTH(tx_subject)>0)
)
GO;

CREATE TABLE k_list_members (
	gu_member     CHAR(32)      NOT NULL,
	dt_created    DATETIME      DEFAULT CURRENT_TIMESTAMP,
	tx_email      CHARACTER VARYING(100) NOT NULL,
	tx_name       VARCHAR (100)     NULL,
	tx_surname    VARCHAR (100)     NULL,
	tx_salutation VARCHAR (16)      NULL,
	dt_modified   DATETIME          NULL,
CONSTRAINT pk_list_members PRIMARY KEY (gu_member)
)
GO;

CREATE TABLE k_x_list_members
(
gu_list        CHAR(32)     NOT NULL,
tx_email       CHARACTER VARYING(100) NOT NULL,
tx_name        VARCHAR(100) NULL,
tx_surname     VARCHAR(100) NULL,
mov_phone      VARCHAR(16)  NULL,
tx_salutation  VARCHAR(16)  NULL,
bo_active      SMALLINT     DEFAULT 1,
dt_created     DATETIME     DEFAULT CURRENT_TIMESTAMP,
tp_member      SMALLINT     DEFAULT 90,
gu_company     CHAR(32)     NULL,
gu_contact     CHAR(32)     NULL,
id_format      VARCHAR(4)   DEFAULT 'TXT',
dt_modified    DATETIME     NULL,
tx_info        VARCHAR(254) NULL,

CONSTRAINT f1_x_list_members FOREIGN KEY (gu_list) REFERENCES k_lists(gu_list)
)
GO;

CREATE TABLE k_global_black_list
(
id_domain   INTEGER   NOT NULL,
gu_workarea CHAR(32)  NOT NULL,
tx_email    CHARACTER VARYING(100) NOT NULL,
dt_created  DATETIME  DEFAULT CURRENT_TIMESTAMP,
tx_name     VARCHAR(100) NULL,
tx_surname  VARCHAR(100) NULL,
gu_contact  CHAR(32) NULL,
gu_address  CHAR(32) NULL,

CONSTRAINT pk_global_black_list PRIMARY KEY (id_domain,gu_workarea,tx_email)
)
GO;

