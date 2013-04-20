ALTER TABLE k_domains ADD CONSTRAINT f1_domains FOREIGN KEY (gu_owner)  REFERENCES k_users      (gu_user);
ALTER TABLE k_domains ADD CONSTRAINT f2_domains FOREIGN KEY (gu_admins) REFERENCES k_acl_groups (gu_acl_group);

ALTER TABLE k_users ADD CONSTRAINT f2_users FOREIGN KEY (id_domain) REFERENCES k_domains (id_domain);

ALTER TABLE k_user_accounts ADD CONSTRAINT f2_user_accounts FOREIGN KEY (id_domain) REFERENCES k_domains (id_domain);

ALTER TABLE k_user_account_alias ADD CONSTRAINT f2_user_account_alias FOREIGN KEY (gu_account) REFERENCES k_user_accounts (gu_account);

ALTER TABLE k_user_mail ADD CONSTRAINT f1_user_mail FOREIGN KEY (gu_user) REFERENCES k_users (gu_user);

ALTER TABLE k_user_pwd ADD CONSTRAINT f1_user_pwd FOREIGN KEY (gu_user) REFERENCES k_users (gu_user);

ALTER TABLE k_acl_groups ADD CONSTRAINT f2_acl_groups FOREIGN KEY (id_domain) REFERENCES k_domains (id_domain);

ALTER TABLE k_x_group_user ADD CONSTRAINT f1_x_group_user FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups (gu_acl_group);
ALTER TABLE k_x_group_user ADD CONSTRAINT f2_x_group_user FOREIGN KEY (gu_user)      REFERENCES k_users (gu_user);

ALTER TABLE k_workareas ADD CONSTRAINT f1_workareas FOREIGN KEY (id_domain) REFERENCES k_domains(id_domain);

ALTER TABLE k_x_app_workarea ADD CONSTRAINT f1_x_app_workarea FOREIGN KEY (id_app)      REFERENCES k_apps      (id_app);
ALTER TABLE k_x_app_workarea ADD CONSTRAINT f2_x_app_workarea FOREIGN KEY (gu_workarea) REFERENCES k_workareas (gu_workarea);
ALTER TABLE k_x_app_workarea ADD CONSTRAINT f3_x_app_workarea FOREIGN KEY (gu_admins)   REFERENCES k_acl_groups(gu_acl_group);
ALTER TABLE k_x_app_workarea ADD CONSTRAINT f4_x_app_workarea FOREIGN KEY (gu_powusers) REFERENCES k_acl_groups(gu_acl_group);
ALTER TABLE k_x_app_workarea ADD CONSTRAINT f5_x_app_workarea FOREIGN KEY (gu_users)    REFERENCES k_acl_groups(gu_acl_group);
ALTER TABLE k_x_app_workarea ADD CONSTRAINT f6_x_app_workarea FOREIGN KEY (gu_guests)   REFERENCES k_acl_groups(gu_acl_group);
ALTER TABLE k_x_app_workarea ADD CONSTRAINT f7_x_app_workarea FOREIGN KEY (gu_other)    REFERENCES k_acl_groups(gu_acl_group);

ALTER TABLE k_x_portlet_user ADD CONSTRAINT f1_x_portlet_user FOREIGN KEY (gu_user) REFERENCES k_users (gu_user);
ALTER TABLE k_x_portlet_user ADD CONSTRAINT f2_x_portlet_user FOREIGN KEY (gu_workarea) REFERENCES k_workareas (gu_workarea);
