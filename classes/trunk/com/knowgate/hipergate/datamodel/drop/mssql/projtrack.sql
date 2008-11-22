DELETE FROM k_sequences WHERE nm_table='seq_k_bugs';

DROP PROCEDURE k_sp_prj_expand;
DROP PROCEDURE k_sp_del_bug;
DROP PROCEDURE k_sp_del_duty; 
DROP PROCEDURE k_sp_del_project;
DROP FUNCTION dbo.k_sp_prj_cost;