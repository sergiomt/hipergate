CREATE SEQUENCE seq_k_syndsearch_request INCREMENT BY 1 START WITH 1
GO;

CREATE SEQUENCE seq_k_syndsearch_run INCREMENT BY 1 START WITH 1
GO;

CREATE SEQUENCE seq_k_syndentries INCREMENT BY 1 START WITH 1
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_activity (ActivtyId CHAR) IS
BEGIN
  DELETE k_activity_attachs WHERE gu_activity=ActivtyId;
  DELETE k_x_activity_audience WHERE gu_activity=ActivtyId;
  DELETE k_activities WHERE gu_activity=ActivtyId;
END k_sp_del_job;
GO;