CREATE FUNCTION k_sp_del_activity (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_activity_attachs WHERE gu_activity=$1;
  DELETE FROM k_x_activity_audience WHERE gu_activity=$1;
  DELETE FROM k_activities WHERE gu_activity=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;