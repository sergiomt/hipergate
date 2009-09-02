CREATE PROCEDURE k_sp_del_activity (ActivtyId CHAR(32))
BEGIN
  DELETE FROM k_x_activity_audience WHERE gu_activity=ActivtyId;
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_activities WHERE gu_activity=ActivtyId);
  DELETE FROM k_activities WHERE gu_activity=ActivtyId;
END
GO;