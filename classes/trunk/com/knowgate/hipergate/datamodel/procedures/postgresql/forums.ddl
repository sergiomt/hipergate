CREATE SEQUENCE seq_k_msg_votes INCREMENT 1 MINVALUE 1 START 1;
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

CREATE FUNCTION k_sp_count_thread_msgs (CHAR) RETURNS INTEGER AS '
DECLARE
  MsgCount INTEGER;
BEGIN
  SELECT nu_thread_msgs INTO MsgCount FROM k_newsmsgs WHERE gu_thread_msg=$1 LIMIT 1;
  IF NOT FOUND THEN
    MsgCount := 0;
  END IF;
  RETURN MsgCount;
END;
' LANGUAGE 'plpgsql';
GO;