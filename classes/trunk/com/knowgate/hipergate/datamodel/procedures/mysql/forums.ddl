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

CREATE PROCEDURE k_sp_count_thread_msgs (IdNewsThread CHAR(32), OUT MsgCount INT)
BEGIN
  SET MsgCount=0;
  SELECT nu_thread_msgs INTO MsgCount FROM k_newsmsgs WHERE gu_thread_msg=IdNewsThread LIMIT 0,1;
END
GO;

