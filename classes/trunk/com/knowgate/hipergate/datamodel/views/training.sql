CREATE VIEW v_active_courses AS
SELECT a.gu_acourse,c.gu_course,c.gu_workarea,a.tx_start,a.tx_end,a.nm_course AS nm_acourse,a.id_course AS id_acourse,a.dt_created,a.dt_modified,a.dt_closed,a.nu_max_alumni,a.nm_tutor,a.tx_tutor_email,a.de_course AS de_acourse,c.nm_course,c.id_course,c.gu_msite_eval,c.gu_msite_abst,c.tx_dept,c.tx_area,c.nu_credits,c.de_course
FROM k_academic_courses a, k_courses c WHERE a.gu_course=c.gu_course AND a.bo_active<>0 AND c.bo_active<>0;

CREATE VIEW v_contact_education_degree AS SELECT d.gu_workarea,e.gu_contact,e.gu_degree,e.ix_degree,e.tp_degree,e.id_degree,d.nm_degree,e.lv_degree,e.dt_created,e.bo_completed,e.gu_institution,e.nm_center,e.tx_dt_from,e.tx_dt_to FROM k_contact_education e, k_education_degree d WHERE e.gu_degree=d.gu_degree;

