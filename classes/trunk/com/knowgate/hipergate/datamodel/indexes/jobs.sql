CREATE INDEX i1_jobs ON k_jobs(gu_workarea);

CREATE INDEX i1_job_atoms ON k_job_atoms(gu_job);

CREATE UNIQUE INDEX i2_job_atoms ON k_job_atoms_archived(gu_job,tx_email);

CREATE INDEX i1_job_atoms_archived ON k_job_atoms_archived(gu_contact);

CREATE UNIQUE INDEX i2_job_atoms_archived ON k_job_atoms_archived(gu_job,tx_email);

CREATE INDEX i1_job_atoms_tracking ON k_job_atoms_tracking(gu_contact);

CREATE INDEX ix1_queries ON k_queries(gu_workarea);

CREATE INDEX ix2_queries ON k_queries(nm_queryspec);


