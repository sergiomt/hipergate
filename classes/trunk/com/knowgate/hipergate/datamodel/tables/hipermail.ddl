CREATE TABLE k_mime_msgs (
  gu_mimemsg     CHAR(32) NOT NULL,
  gu_workarea    CHAR(32) NOT NULL,
  pg_message     DECIMAL(20) NOT NULL,
  gu_category    CHAR(32) NULL,
  gu_parent_msg  CHAR(32) NULL,
  gu_job         CHAR(32) NULL,
  nu_position    DECIMAL(20) NULL,
  id_type        CHARACTER VARYING(254) NULL,
  id_content     CHARACTER VARYING(254) NULL,
  id_message     CHARACTER VARYING(254) NULL,  
  id_disposition CHARACTER VARYING(100) NULL,
  len_mimemsg    INTEGER NULL,
  tx_md5         CHAR(32) NULL,
  de_mimemsg     VARCHAR(254) NULL,
  file_name      VARCHAR(254) NULL,
  tx_encoding    CHARACTER VARYING(16) NULL,
  tx_subject     VARCHAR(254) NULL,
  dt_sent        DATETIME NULL,
  dt_received    DATETIME NULL,
  dt_readed      DATETIME NULL,
  bo_indexed     SMALLINT DEFAULT 0,
  bo_answered    SMALLINT NULL,
  bo_deleted     SMALLINT NULL,
  bo_draft       SMALLINT NULL,
  bo_flagged     SMALLINT NULL,
  bo_recent      SMALLINT NULL,
  bo_seen        SMALLINT NULL,
  bo_spam        SMALLINT NULL,  
  id_compression SMALLINT NULL,
  id_priority    CHARACTER VARYING(10)  NULL,
  tx_email_from  CHARACTER VARYING(254) NULL,
  tx_email_reply CHARACTER VARYING(254) NULL,  
  nm_from        CHARACTER VARYING(254) NULL,
  nm_to          CHARACTER VARYING(254) NULL,  
  by_content     LONGVARBINARY NULL,

  CONSTRAINT pk_mime_msgs PRIMARY KEY (gu_mimemsg),
  CONSTRAINT u1_mime_msgs UNIQUE (gu_category,pg_message),
  CONSTRAINT c1_mime_msgs CHECK (pg_message IS NULL OR pg_message>=0),
  CONSTRAINT c2_mime_msgs CHECK (nu_position IS NULL OR nu_position>=0),
  CONSTRAINT c3_mime_msgs CHECK (len_mimemsg IS NULL OR len_mimemsg>=0),
  CONSTRAINT c4_mime_msgs CHECK (dt_received IS NULL OR dt_readed IS NULL OR dt_received<=dt_readed)  
)
GO;

CREATE TABLE k_inet_addrs (
  gu_mimemsg     CHAR(32) NOT NULL,
  id_message     CHARACTER VARYING(254) NULL,
  pg_message     DECIMAL(20) NULL,
  tx_email       CHARACTER VARYING(254) NOT NULL,
  tp_recipient   CHARACTER VARYING(4)   NOT NULL,
  tx_personal    VARCHAR(254) NULL,
  gu_user        CHAR(32) NULL,
  gu_contact     CHAR(32) NULL,
  gu_company     CHAR(32) NULL,
  dt_displayed   DATETIME NULL,
  user_agent     VARCHAR(254) NULL,
  
  CONSTRAINT c1_inet_addrs CHECK (tp_recipient='from' OR tp_recipient='to' OR tp_recipient='cc' OR tp_recipient='bcc')  
)
GO;

CREATE TABLE k_mime_parts (
  gu_mimemsg     CHAR(32) NOT NULL,
  id_message     CHARACTER VARYING(254) NOT NULL,
  pg_message     DECIMAL(20) NULL,
  nu_offset      DECIMAL(20) NULL,
  id_part        INTEGER NOT NULL,
  id_content     CHARACTER VARYING(254) NULL,
  id_type        CHARACTER VARYING(254) NULL,
  id_disposition CHARACTER VARYING(100) NULL,
  id_encoding    CHARACTER VARYING(100) NULL,
  len_part       INTEGER NULL,
  de_part        VARCHAR(254) NULL,
  tx_md5         CHAR(32) NULL,
  file_name      VARCHAR(254) NULL,
  id_compression SMALLINT NULL,
  by_content     LONGVARBINARY NULL,
  
  CONSTRAINT pk_mime_parts PRIMARY KEY (gu_mimemsg,id_part),
  CONSTRAINT c1_mime_parts CHECK (id_disposition<>'pointer' OR (nu_offset>=0 AND len_part>=0)),
  CONSTRAINT c2_mime_parts CHECK (id_disposition<>'pointer' OR file_name IS NOT NULL),
  CONSTRAINT c3_mime_parts CHECK (id_disposition<>'reference' OR file_name IS NOT NULL)
)
GO;

CREATE TABLE k_adhoc_mailings (
  gu_mailing     CHAR(32) NOT NULL,
  gu_workarea    CHAR(32) NOT NULL,
  gu_writer      CHAR(32) NOT NULL,
  pg_mailing     INTEGER  NOT NULL,
  dt_created     DATETIME DEFAULT CURRENT_TIMESTAMP,  
  nm_mailing     VARCHAR(30) NOT NULL,
  bo_urgent      SMALLINT DEFAULT 0,
  bo_reminder    SMALLINT DEFAULT 0,
  bo_html_part   SMALLINT NOT NULL,
  bo_plain_part  SMALLINT NOT NULL,
  bo_attachments SMALLINT NOT NULL,
  id_status      CHARACTER VARYING(30) NULL,
  dt_modified    DATETIME NULL,
  dt_execution   DATETIME NULL,
  tx_email_from  CHARACTER VARYING(254) NULL,
  tx_email_reply CHARACTER VARYING(254) NULL,  
  nm_from        VARCHAR(254)  NULL,
  tx_subject     VARCHAR(254)  NULL,
  tx_allow_regexp VARCHAR(254) NULL,
  tx_deny_regexp VARCHAR(254)  NULL,
  tx_parameters  VARCHAR(2000) NULL,
  CONSTRAINT pk_adhoc_mailings PRIMARY KEY (gu_mailing),
  CONSTRAINT u1_adhoc_mailings UNIQUE (pg_mailing),
  CONSTRAINT u2_adhoc_mailings UNIQUE (nm_mailing)
)
GO;

CREATE TABLE k_x_adhoc_mailing_list (
  gu_list CHAR(32)    NOT NULL,
  gu_mailing CHAR(32) NOT NULL,
  CONSTRAINT pk_x_adhoc_mailing_list PRIMARY KEY (gu_list,gu_mailing)
)
GO;

CREATE TABLE k_adhoc_mailings_lookup
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

CONSTRAINT pk_adhoc_mailings_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_adhoc_mailings_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;
  