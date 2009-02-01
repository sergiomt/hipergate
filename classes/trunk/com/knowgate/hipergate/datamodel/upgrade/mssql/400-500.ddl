UPDATE k_version SET vs_stamp='5.0.0'
GO;

ALTER TABLE k_pageset_pages ADD path_publish NVARCHAR(254) NULL
GO;

ALTER TABLE k_oportunities ADD dt_last_call DATETIME NULL
GO;

CREATE TABLE k_newsgroup_tags
(
gu_tag            CHAR(32) NOT NULL,
gu_newsgrp        CHAR(32) NOT NULL,
dt_created        DATETIME DEFAULT GETDATE(),
tl_tag            NVARCHAR(70)  NOT NULL,
de_tag            NVARCHAR(200) NULL,
nu_msgs           INTEGER  DEFAULT 0,
bo_incoming_ping  SMALLINT DEFAULT 0,
dt_trackback      DATETIME NULL,
url_trackback     VARCHAR(2000) NULL,

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

CREATE PROCEDURE k_sp_del_newsgroup @IdNewsGroup CHAR(32) AS
  DELETE k_newsmsg_tags WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsmsg_vote WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=@IdNewsGroup)
  DELETE k_newsgroup_subscriptions WHERE gu_newsgrp=@IdNewsGroup
  DELETE k_newsgroup_tags WHERE gu_newsgrp=@IdNewsGroup
  DELETE k_newsgroups WHERE gu_newsgrp=@IdNewsGroup
  DELETE k_x_cat_objs WHERE gu_category=@IdNewsGroup
  EXECUTE k_sp_del_category @IdNewsGroup
GO;

DROP PROCEDURE k_sp_del_newsmsg
GO;

CREATE PROCEDURE k_sp_del_newsmsg @IdNewsMsg CHAR(32) AS
  DECLARE @IdChild CHAR(32)
  DECLARE childs CURSOR LOCAL STATIC FOR SELECT gu_msg FROM k_newsmsgs WHERE gu_parent_msg=@IdNewsMsg
  OPEN childs
    FETCH NEXT FROM childs INTO @IdChild
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_newsmsg @IdChild
      END
  CLOSE childs
  DELETE k_x_cat_objs WHERE gu_object=@IdNewsMsg
  DELETE k_newsmsg_vote WHERE gu_msg=@IdNewsMsg
  DELETE k_newsmsg_tags WHERE gu_msg=@IdNewsMsg
  DELETE k_newsmsgs WHERE gu_msg=@IdNewsMsg
GO;
