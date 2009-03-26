CREATE SEQUENCE seq_k_msg_votes INCREMENT BY 1 START WITH 1
GO;

CREATE PROCEDURE k_sp_del_newsgroup (IdNewsGroup CHAR) IS
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


CREATE PROCEDURE k_sp_count_thread_msgs (IdNewsThread CHAR, MsgCount OUT NUMBER) IS
BEGIN
  SELECT nu_thread_msgs INTO MsgCount FROM k_newsmsgs WHERE gu_thread_msg=IdNewsThread AND ROWNUM=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    MsgCount := 0;
END k_sp_count_thread_msgs;
GO;

