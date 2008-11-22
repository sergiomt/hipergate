CREATE VIEW v_jobs AS
SELECT j.gu_job, j.gu_job_group, j.gu_workarea, j.id_command, c.tx_command, j.tx_parameters, j.id_status, s.tr_es, s.tr_en, s.tr_fr, s.tr_de, s.tr_it, j.dt_execution, j.dt_finished, j.dt_created, j.dt_modified, j.tl_job
FROM k_jobs j, k_lu_job_status s, k_lu_job_commands c
WHERE j.id_status = s.id_status AND j.id_command = c.id_command;