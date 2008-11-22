ALTER TABLE k_jobs ADD CONSTRAINT f3_jobs FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_jobs ADD CONSTRAINT f4_jobs FOREIGN KEY(id_command) REFERENCES k_lu_job_commands(id_command);
ALTER TABLE k_jobs ADD CONSTRAINT f6_jobs FOREIGN KEY(id_status) REFERENCES k_lu_job_status(id_status);
ALTER TABLE k_jobs ADD CONSTRAINT f7_jobs FOREIGN KEY(gu_writer) REFERENCES k_users(gu_user);

ALTER TABLE k_job_atoms ADD CONSTRAINT f2_job_atoms FOREIGN KEY(gu_job) REFERENCES k_jobs(gu_job);

ALTER TABLE k_queries ADD CONSTRAINT f1_queries FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_events ADD CONSTRAINT f1_events FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_events ADD CONSTRAINT f2_events FOREIGN KEY(id_command) REFERENCES k_lu_job_commands(id_command);
ALTER TABLE k_events ADD CONSTRAINT f3_events FOREIGN KEY(gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_events ADD CONSTRAINT f4_events FOREIGN KEY(id_app) REFERENCES k_apps(id_app);
