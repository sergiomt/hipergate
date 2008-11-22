DROP VIEW v_jobs;

ALTER TABLE k_jobs DROP CONSTRAINT f3_jobs;
ALTER TABLE k_jobs DROP CONSTRAINT f4_jobs;
ALTER TABLE k_jobs DROP CONSTRAINT f6_jobs;
ALTER TABLE k_jobs DROP CONSTRAINT f7_jobs;

ALTER TABLE k_job_atoms DROP CONSTRAINT f2_job_atoms;

DROP TABLE k_job_atoms_archived;

DROP TABLE k_job_atoms;

DROP TABLE k_jobs;

DROP TABLE k_lu_job_status;

DROP TABLE k_lu_job_commands;

DROP TABLE k_queries;

DROP TABLE k_events;
