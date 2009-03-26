DROP SEQUENCE seq_k_webbeacons;

ALTER TABLE k_workareas DROP CONSTRAINT f1_workareas;

ALTER TABLE k_x_group_user DROP CONSTRAINT f1_x_group_user;
ALTER TABLE k_x_group_user DROP CONSTRAINT f2_x_group_user;

ALTER TABLE k_acl_groups DROP CONSTRAINT f2_acl_groups;

ALTER TABLE k_users DROP CONSTRAINT f2_users;

ALTER TABLE k_domains DROP CONSTRAINT f1_domains;
ALTER TABLE k_domains DROP CONSTRAINT f2_domains;

DROP FUNCTION k_sp_autenticate(CHAR, VARCHAR);
