ALTER TABLE k_workareas DROP CONSTRAINT f1_workareas;

ALTER TABLE k_x_group_user DROP CONSTRAINT f1_x_group_user;
ALTER TABLE k_x_group_user DROP CONSTRAINT f2_x_group_user;

ALTER TABLE k_acl_groups DROP CONSTRAINT f2_acl_groups;

ALTER TABLE k_users DROP CONSTRAINT f2_users;

ALTER TABLE k_domains DROP CONSTRAINT f1_domains;
ALTER TABLE k_domains DROP CONSTRAINT f2_domains;

DROP PROCEDURE k_get_domain_id;

DROP PROCEDURE k_get_workarea_id;

DROP PROCEDURE k_is_workarea_admin;

DROP PROCEDURE k_is_workarea_poweruser;

DROP PROCEDURE k_is_workarea_user;

DROP PROCEDURE k_is_workarea_guest;

DROP PROCEDURE k_is_workarea_anyrole;

DROP PROCEDURE k_get_user_from_email;

DROP PROCEDURE k_get_user_from_nick;

DROP PROCEDURE k_get_group_id;

DROP PROCEDURE k_sp_autenticate;