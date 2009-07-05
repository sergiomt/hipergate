UPDATE k_version SET vs_stamp='5.0.0'
GO;

INSERT INTO k_classes VALUES(14,'PasswordRecord');
GO;

ALTER TABLE k_pageset_pages ADD path_publish VARCHAR2(254) NULL
GO;

ALTER TABLE k_oportunities ADD dt_last_call DATE NULL
GO;

ALTER TABLE k_newsgroups ADD de_newsgrp VARCHAR2(254) NULL
GO;

ALTER TABLE k_newsgroups ADD tx_journal VARCHAR2(4000) NULL
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32)       NOT NULL,
gu_newsgrp        CHAR(32)       NOT NULL,
dt_created        DATE           DEFAULT SYSDATE,
od_tag            NUMBER(5)      DEFAULT 1000,
tl_tag            VARCHAR2(70)   NOT NULL,
de_tag            VARCHAR2(200)  NULL,
nu_msgs           NUMBER(11)     DEFAULT 0,
bo_incoming_ping  NUMBER(5)      DEFAULT 0,
dt_trackback      DATE           NULL,
url_trackback     VARCHAR2(2000) NULL,

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

CREATE OR REPLACE PROCEDURE k_sp_del_newsgroup (IdNewsGroup CHAR) IS
BEGIN
  DELETE k_newsmsg_tags WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=IdNewsGroup);
  DELETE k_newsgroup_subscriptions WHERE gu_newsgrp=IdNewsGroup;
  DELETE k_newsgroup_tags WHERE gu_newsgrp=IdNewsGroup;
  DELETE k_newsgroups WHERE gu_newsgrp=IdNewsGroup;
  DELETE k_x_cat_objs WHERE gu_category=IdNewsGroup;
  k_sp_del_category (IdNewsGroup);
END k_sp_del_newsgroup;
GO;


CREATE PROCEDURE k_sp_del_newsmsg (IdNewsMsg CHAR) IS
  IdChild CHAR(32);
  CURSOR childs(id CHAR) IS SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=id;
BEGIN
  OPEN childs(IdNewsMsg);
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN childs%NOTFOUND;
      k_sp_del_newsmsg (IdChild);
    END LOOP;
  CLOSE childs;
  UPDATE k_newsmsgs SET nu_thread_msgs=nu_thread_msgs-1 WHERE gu_thread_msg=IdNewsMsg;  
  DELETE k_x_cat_objs WHERE gu_object=IdNewsMsg;
  DELETE k_newsmsg_vote WHERE gu_msg=IdNewsMsg;
  DELETE k_newsmsg_tags WHERE gu_msg=IdNewsMsg;
  DELETE k_newsmsgs WHERE gu_msg=IdNewsMsg;
END k_sp_del_newsmsg;
GO;

ALTER TABLE k_newsmsgs ADD dt_modified DATE NULL
GO;

CREATE SEQUENCE seq_k_webbeacons INCREMENT BY 1 START WITH 1
GO;

CREATE TABLE k_webbeacons (
    id_webbeacon  NUMBER(11)  NOT NULL,
    dt_created    DATE DEFAULT SYSDATE,
    dt_last_visit DATE NOT NULL,
	nu_pages      NUMBER(11) NOT NULL,
    gu_user       CHAR(32) NULL,
    gu_contact    CHAR(32) NULL,
    CONSTRAINT pk_webbeacons PRIMARY KEY(id_webbeacon)
)
GO;
    
CREATE TABLE k_webbeacon_pages (
    id_page   NUMBER(11) NOT NULL,
    nu_hits   NUMBER(11) NOT NULL,
    gu_object CHAR(32) NULL,
    url_page  VARCHAR2(254) NOT NULL,
    CONSTRAINT pk_webbeacon_pages PRIMARY KEY(id_page),
    CONSTRAINT u1_webbeacon_pages UNIQUE (url_page),
    CONSTRAINT c1_webbeacon_pages CHECK (LENGTH(url_page)>0)    
)
GO;

CREATE TABLE k_webbeacon_hit (
    id_webbeacon  NUMBER(11) NOT NULL,
    id_page       NUMBER(11) NOT NULL,
    id_referrer   NUMBER(11)     NULL,
    dt_hit        DATE DEFAULT SYSDATE,
    ip_addr       NUMBER(11) NULL
)
GO;

ALTER TABLE k_users ADD mov_phone VARCHAR2(16) NULL
GO;

DROP VIEW v_project_company
GO;

CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NVL(d.tx_name,'') || ' ' || NVL(d.tx_surname,'') AS full_name, p.id_status, p.id_ref
FROM k_project_expand e, k_contacts d, k_projects p, k_companies c
WHERE p.gu_company=c.gu_company(+) AND e.gu_project=p.gu_project AND d.gu_contact=p.gu_contact)
UNION
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NULL AS full_name, p.id_status, p.id_ref
FROM k_project_expand e,
k_projects p, k_companies c
WHERE p.gu_company=c.gu_company(+) AND e.gu_project=p.gu_project AND p.gu_contact IS NULL)
GO;

ALTER TABLE k_contacts ADD id_batch VARCHAR2(32)
GO;
ALTER TABLE k_companies ADD id_batch VARCHAR2(32)
GO;

ALTER TABLE k_academic_courses ADD pr_acourse NUMBER(14,4) NULL
GO;
ALTER TABLE k_x_course_bookings ADD dt_paid DATE NULL
GO;
ALTER TABLE k_x_course_bookings ADD id_transact VARCHAR2(32) NULL
GO;
ALTER TABLE k_x_course_bookings ADD tp_billing CHAR(1) NULL
GO;
ALTER TABLE k_academic_courses ADD gu_address CHAR(32) NULL
GO;
