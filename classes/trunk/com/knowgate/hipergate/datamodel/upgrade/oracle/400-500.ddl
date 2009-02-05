UPDATE k_version SET vs_stamp='5.0.0'
GO;

ALTER TABLE k_pageset_pages ADD path_publish VARCHAR2(254) NULL
GO;

ALTER TABLE k_oportunities ADD dt_last_call DATE NULL
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32)       NOT NULL,
gu_newsgrp        CHAR(32)       NOT NULL,
dt_created        DATE           DEFAULT SYSDATE,
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


CREATE OR REPLACE PROCEDURE k_sp_del_newsmsg (IdNewsMsg CHAR) IS
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
  DELETE k_x_cat_objs WHERE gu_object=IdNewsMsg;
  DELETE k_newsmsg_vote WHERE gu_msg=IdNewsMsg;
  DELETE k_newsmsg_tags WHERE gu_msg=IdNewsMsg;
  DELETE k_newsmsgs WHERE gu_msg=IdNewsMsg;
END k_sp_del_newsmsg;
GO;

ALTER TABLE k_newsmsgs ADD dt_modified DATE NULL
GO;
