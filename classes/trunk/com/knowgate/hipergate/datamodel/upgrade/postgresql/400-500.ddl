UPDATE k_version SET vs_stamp='5.0.0'
GO;

INSERT INTO k_classes VALUES(14,'PasswordRecord');
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

DROP FUNCTION k_sp_del_newsgroup (CHAR)
GO;

CREATE FUNCTION k_sp_del_newsgroup (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_newsmsg_tags WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsgroup_subscriptions WHERE gu_newsgrp=$1;
  DELETE FROM k_newsgroup_tags WHERE gu_newsgrp=$1;
  DELETE FROM k_newsgroups WHERE gu_newsgrp=$1;
  DELETE FROM k_x_cat_objs WHERE gu_category=$1;
  PERFORM k_sp_del_category ($1);
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_newsmsg (CHAR)
GO;

CREATE FUNCTION k_sp_del_newsmsg (CHAR) RETURNS INTEGER AS '
DECLARE
  IdChild CHAR(32);
  childs REFCURSOR;
BEGIN
  OPEN childs FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=$1;
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_del_newsmsg (IdChild);
    END LOOP;
  CLOSE childs;
  UPDATE k_newsmsgs SET nu_thread_msgs=nu_thread_msgs-1 WHERE gu_thread_msg=$1;  
  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  DELETE FROM k_newsmsg_vote WHERE gu_msg=$1;
  DELETE FROM k_newsmsg_tags WHERE gu_msg=$1;
  DELETE FROM k_newsmsgs WHERE gu_msg=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

ALTER TABLE k_newsmsgs ADD dt_modified TIMESTAMP NULL
GO;

CREATE SEQUENCE seq_k_webbeacons INCREMENT 1 START 1
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
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,COALESCE(d.tx_name,'') || ' ' || COALESCE(d.tx_surname,'') AS full_name, p.id_status, p.id_ref
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

ALTER TABLE k_academic_courses ADD pr_acourse DECIMAL(14,4) NULL
GO;
ALTER TABLE k_x_course_bookings ADD dt_paid TIMESTAMP NULL
GO;
ALTER TABLE k_x_course_bookings ADD id_transact VARCHAR(32) NULL
GO;
ALTER TABLE k_x_course_bookings ADD tp_billing CHAR(1) NULL
GO;
ALTER TABLE k_academic_courses ADD gu_address CHAR(32) NULL
GO;
