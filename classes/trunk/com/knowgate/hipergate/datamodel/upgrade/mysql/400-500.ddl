UPDATE k_version SET vs_stamp='5.0.0'
GO;

ALTER TABLE k_pageset_pages ADD path_publish VARCHAR(254) NULL
GO;

ALTER TABLE k_oportunities ADD dt_last_call TIMESTAMP NULL
GO;

ALTER TABLE k_newsgroups ADD de_newsgrp VARCHAR(254) NULL
GO;
ALTER TABLE k_newsgroups ADD tx_journal VARCHAR(4000) NULL
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32)     NOT NULL,
gu_newsgrp        CHAR(32)     NOT NULL,
dt_created        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
od_tag            SMALLINT     DEFAULT 1000,
tl_tag            VARCHAR(70)  NOT NULL,
de_tag            VARCHAR(200)     NULL,
nu_msgs           INTEGER     DEFAULT 0,
bo_incoming_ping  SMALLINT    DEFAULT 0,
dt_trackback      TIMESTAMP        NULL,
url_trackback     VARCHAR(2000)    NULL,

CONSTRAINT pk_newsgroup_tags PRIMARY KEY (gu_tag)
)
GO;

CREATE TABLE k_newsmsg_tags
(
gu_msg CHAR(32) NOT NULL,
gu_tag CHAR(32) NOT NULL,

CONSTRAINT pk_newsmsg_tags PRIMARY KEY (gu_msg,gu_tag)
)
GO;

DROP PROCEDURE k_sp_del_newsgroup
GO;

CREATE PROCEDURE k_sp_del_newsgroup (IdNewsGroup CHAR(32))
BEGIN
  DELETE FROM k_newsmsg_tags WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE FROM k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE FROM k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE FROM k_newsgroup_subscriptions WHERE gu_newsgrp=IdNewsGroup;
  DELETE FROM k_newsgroup_tags WHERE gu_newsgrp=IdNewsGroup;
  DELETE FROM k_newsgroups WHERE gu_newsgrp=IdNewsGroup;
  DELETE FROM k_x_cat_objs WHERE gu_category=IdNewsGroup;
  CALL k_sp_del_category (IdNewsGroup);
END
GO;

DROP PROCEDURE k_sp_del_newsmsg
GO;

CREATE PROCEDURE k_sp_del_newsmsg (IdNewsMsg CHAR(32))
BEGIN
  DECLARE IdChild CHAR(32);
  DECLARE Done INT DEFAULT 0;
  DECLARE childs CURSOR FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=IdNewsMsg;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  OPEN childs;
    REPEAT
      FETCH childs INTO IdChild;
      IF Done=0 THEN
        CALL k_sp_del_newsmsg (IdChild);
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE childs;
  UPDATE k_newsmsgs SET nu_thread_msgs=nu_thread_msgs-1 WHERE gu_thread_msg=IdNewsMsg;
  DELETE FROM k_x_cat_objs WHERE gu_object=IdNewsMsg;
  DELETE FROM k_newsmsg_vote WHERE gu_msg=IdNewsMsg;
  DELETE FROM k_newsmsg_tags WHERE gu_msg=IdNewsMsg;
  DELETE FROM k_newsmsgs WHERE gu_msg=IdNewsMsg;
END
GO;

ALTER TABLE k_newsmsgs ADD dt_modified TIMESTAMP NULL
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_webbeacons', 1, 2147483647, 1, 1)
GO;

CREATE TABLE k_webbeacons (
    id_webbeacon  INTEGER  NOT NULL,
    dt_created    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_last_visit TIMESTAMP NOT NULL,
	nu_pages      INTEGER  NOT NULL,
    gu_user       CHAR(32) NULL,
    gu_contact    CHAR(32) NULL,
    CONSTRAINT pk_webbeacons PRIMARY KEY(id_webbeacon)
)
GO;
    
CREATE TABLE k_webbeacon_pages (
    id_page   INTEGER  NOT NULL,
    nu_hits   INTEGER  NOT NULL,
    gu_object CHAR(32) NULL,
    url_page  VARCHAR(254) NOT NULL,
    CONSTRAINT pk_webbeacon_pages PRIMARY KEY(id_page),
    CONSTRAINT u1_webbeacon_pages UNIQUE (url_page),
    CONSTRAINT c1_webbeacon_pages CHECK (LENGTH(url_page)>0)    
)
GO;

CREATE TABLE k_webbeacon_hit (
    id_webbeacon  INTEGER  NOT NULL,
    id_page       INTEGER  NOT NULL,
    id_referrer   INTEGER      NULL,
    dt_hit        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_addr       INTEGER  NULL
)
GO;

ALTER TABLE k_users ADD mov_phone VARCHAR(16) NULL
GO;

DROP VIEW v_project_company
GO;

CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,CONCAT(COALESCE(d.tx_name,''),' ',COALESCE(d.tx_surname,'')) AS full_name, p.id_status, p.id_ref
FROM k_project_expand e, k_contacts d, k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND d.gu_contact=p.gu_contact)
UNION
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NULL AS full_name, p.id_status, p.id_ref
FROM k_project_expand e,
k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND p.gu_contact IS NULL)
GO;

ALTER TABLE k_contacts ADD id_batch VARCHAR(32)
GO;
ALTER TABLE k_companies ADD id_batch VARCHAR(32)
GO;
