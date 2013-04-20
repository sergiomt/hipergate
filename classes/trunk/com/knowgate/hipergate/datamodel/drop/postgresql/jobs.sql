DROP SEQUENCE seq_k_job_atoms;

DROP FUNCTION k_sp_del_test_jobs (); 

DROP FUNCTION k_sp_resolve_atoms (CHAR);

DROP FUNCTION k_sp_resolve_atom (CHAR,INTEGER,CHAR);

DROP FUNCTION k_sp_del_job(CHAR);

DROP TRIGGER k_tr_ins_atom ON k_job_atoms;

DROP FUNCTION k_sp_ins_atom();
