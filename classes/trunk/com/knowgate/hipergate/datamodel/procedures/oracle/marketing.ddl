CREATE OR REPLACE PROCEDURE k_sp_del_activity (ActivtyId CHAR) IS
BEGIN
  DELETE k_x_activity_audience WHERE gu_activity=ActivtyId;
  DELETE k_addresses WHERE gu_address IN (SELECT gu_address FROM k_activities WHERE gu_activity=ActivtyId);
  DELETE k_activities WHERE gu_activity=ActivtyId;
END k_sp_del_job;
GO;