CREATE INDEX i1_jobs ON k_jobs(gu_workarea);

CREATE INDEX i1_job_atoms ON k_job_atoms(gu_job);

CREATE INDEX ix1_queries ON k_queries(gu_workarea);

CREATE INDEX ix2_queries ON k_queries(nm_queryspec);


