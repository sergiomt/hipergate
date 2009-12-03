CREATE PROCEDURE k_sp_del_activity @ActivtyId CHAR(32) AS
  DELETE k_activity_attachs WHERE gu_activity=@ActivtyId
  DELETE k_x_activity_audience WHERE gu_activity=@ActivtyId
  DELETE k_activities WHERE gu_activity=@ActivtyId
GO;