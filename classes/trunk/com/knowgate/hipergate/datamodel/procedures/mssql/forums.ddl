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
  UPDATE k_newsmsgs SET nu_thread_msgs=nu_thread_msgs-1 WHERE gu_thread_msg=@IdNewsMsg
  DELETE k_x_cat_objs WHERE gu_object=@IdNewsMsg
  DELETE k_newsmsg_vote WHERE gu_msg=@IdNewsMsg
  DELETE k_newsmsg_tags WHERE gu_msg=@IdNewsMsg
  DELETE k_newsmsgs WHERE gu_msg=@IdNewsMsg
GO;

CREATE PROCEDURE k_sp_count_thread_msgs @IdNewsThread CHAR(32), @MsgCount INTEGER OUTPUT AS
  SET @MsgCount = 0
  SELECT TOP 1 @MsgCount=nu_thread_msgs FROM k_newsmsgs WHERE gu_thread_msg=@IdNewsThread
GO;