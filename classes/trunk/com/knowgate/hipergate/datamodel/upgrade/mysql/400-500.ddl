UPDATE k_version SET vs_stamp='5.0.0'
GO;

ALTER TABLE k_pageset_pages ADD path_publish VARCHAR(254) NULL
GO;

ALTER TABLE k_oportunities ADD dt_last_call TIMESTAMP NULL
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32)     NOT NULL,
gu_newsgrp        CHAR(32)     NOT NULL,
dt_created        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
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
  DELETE FROM k_x_cat_objs WHERE gu_object=IdNewsMsg;
  DELETE FROM k_newsmsg_vote WHERE gu_msg=IdNewsMsg;
  DELETE FROM k_newsmsg_tags WHERE gu_msg=IdNewsMsg;
  DELETE FROM k_newsmsgs WHERE gu_msg=IdNewsMsg;
END
GO;