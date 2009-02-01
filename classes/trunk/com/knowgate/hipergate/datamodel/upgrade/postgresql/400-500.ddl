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
dt_created        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
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
  childs CURSOR (id CHAR(32)) FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=id;
BEGIN
  OPEN childs($1);
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_del_newsmsg (IdChild);
    END LOOP;
  CLOSE childs;
  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  DELETE FROM k_newsmsg_vote WHERE gu_msg=$1;
  DELETE FROM k_newsmsg_tags WHERE gu_msg=$1;
  DELETE FROM k_newsmsgs WHERE gu_msg=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;