CREATE SEQUENCE seq_k_syndsearch_request INCREMENT 1 START 1
GO;

CREATE SEQUENCE seq_k_syndsearch_run INCREMENT 1 START 1
GO;

CREATE SEQUENCE seq_k_syndentries INCREMENT 1 START 1
GO;

CREATE FUNCTION k_sp_del_activity (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_activity_attachs WHERE gu_activity=$1;
  DELETE FROM k_x_activity_audience WHERE gu_activity=$1;
  DELETE FROM k_activities WHERE gu_activity=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;