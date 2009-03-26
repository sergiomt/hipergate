
CREATE TABLE k_newsgroups
(
gu_newsgrp     CHAR(32)      NOT NULL,
id_domain      INTEGER       NOT NULL,
gu_workarea    CHAR(32)      NOT NULL,
dt_created     DATETIME      DEFAULT CURRENT_TIMESTAMP,
bo_binaries    SMALLINT      DEFAULT 0,
dt_last_update DATETIME 	 NULL,
dt_expire      INTEGER       NULL,
de_newsgrp     VARCHAR(254)  NULL,
tx_journal     VARCHAR(4000) NULL,

CONSTRAINT pk_newsgroups PRIMARY KEY (gu_newsgrp),
CONSTRAINT c1_newsgroups CHECK (LENGTH(tx_journal)>0 OR tx_journal IS NULL)
)
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32)     NOT NULL,
gu_newsgrp        CHAR(32)     NOT NULL,
dt_created        DATETIME     DEFAULT CURRENT_TIMESTAMP,
od_tag            SMALLINT     DEFAULT 1000,
tl_tag            VARCHAR(70)  NOT NULL,
de_tag            VARCHAR(200)     NULL,
nu_msgs           INTEGER     DEFAULT 0,
bo_incoming_ping  SMALLINT    DEFAULT 0,
dt_trackback      DATETIME         NULL,
url_trackback     VARCHAR(2000)    NULL,

CONSTRAINT pk_newsgroup_tags PRIMARY KEY (gu_tag),
CONSTRAINT u1_newsgroup_tags UNIQUE (gu_newsgrp,tl_tag)

)
GO;

CREATE TABLE k_newsmsgs
(
gu_msg           CHAR(32)         NOT NULL,
nm_author        VARCHAR(200)     NOT NULL,
gu_writer        CHAR(32)         NOT NULL,
dt_modified      DATETIME             NULL,
dt_published     DATETIME         DEFAULT CURRENT_TIMESTAMP,
dt_start         DATETIME             NULL,
id_language      CHAR(2)          DEFAULT 'xx',
id_status        SMALLINT 	      DEFAULT 1,
id_msg_type      CHAR(5)          DEFAULT 'TXT',
nu_thread_msgs   INTEGER          DEFAULT 1,
gu_thread_msg    CHAR(32)         NOT NULL,
gu_parent_msg    CHAR(32)             NULL,
nu_votes         INTEGER          DEFAULT 0,
tx_email         CHARACTER VARYING(100) NULL,
tx_subject       VARCHAR(254) 	      NULL,
dt_expire        DATETIME             NULL,
dt_validated     DATETIME             NULL,
gu_validator     CHAR(32)             NULL,
gu_product       CHAR(32)             NULL,
tx_msg           LONGVARCHAR	      NULL,

CONSTRAINT pk_newsmsgs PRIMARY KEY (gu_msg),
CONSTRAINT c1_newsmsgs CHECK (dt_expire>=dt_published OR dt_expire IS NULL),
CONSTRAINT c2_newsmsgs CHECK (dt_expire>=dt_start OR dt_expire IS NULL),
CONSTRAINT c3_newsmsgs CHECK (dt_validated>=dt_published OR dt_validated IS NULL)
)
GO;

CREATE TABLE k_newsgroup_subscriptions (
  gu_newsgrp  CHAR(32) NOT NULL,
  gu_user     CHAR(32) NOT NULL,
  dt_created  DATETIME DEFAULT CURRENT_TIMESTAMP,
  id_status   SMALLINT DEFAULT 1,
  id_msg_type CHAR(5) DEFAULT 'TXT',
  tp_subscrip SMALLINT DEFAULT 1,
  tx_email    CHARACTER VARYING(100) NULL,

  CONSTRAINT pk_newsgroup_subscriptions PRIMARY KEY (gu_newsgrp,gu_user)
)
GO;

CREATE TABLE k_newsmsg_vote (
  gu_msg     CHAR(32)               NOT NULL,
  pg_vote    INTEGER                NOT NULL,
  dt_published DATETIME             DEFAULT CURRENT_TIMESTAMP,
  od_score   INTEGER         	    NULL,
  ip_addr    VARCHAR(254) 	    NULL,
  nm_author  VARCHAR(200)           NULL,
  gu_writer  CHAR(32)               NULL,
  tx_email   CHARACTER VARYING(100) NULL,
  tx_vote    VARCHAR(254)           NULL,
  CONSTRAINT pk_newsmsg_vote PRIMARY KEY (gu_msg,pg_vote)
)
GO;

CREATE TABLE k_newsmsg_tags
(
gu_msg CHAR(32) NOT NULL,
gu_tag CHAR(32) NOT NULL,

CONSTRAINT pk_newsmsg_tags PRIMARY KEY (gu_msg,gu_tag)
)
GO;
