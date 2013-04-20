INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_syndsearch_request', 1, 2147483647, 1, 1)
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_syndsearch_run', 1, 2147483647, 1, 1)
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_syndentries', 1, 2147483647, 1, 1)
GO;

CREATE PROCEDURE k_sp_del_activity (ActivtyId CHAR(32))
BEGIN
  DELETE FROM k_activity_attachs WHERE gu_activity=ActivtyId;
  DELETE FROM k_x_activity_audience WHERE gu_activity=ActivtyId;
  DELETE FROM k_activities WHERE gu_activity=ActivtyId;
END
GO;