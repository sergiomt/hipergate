ALTER TABLE k_projects ADD CONSTRAINT f1_projects FOREIGN KEY (gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_projects ADD CONSTRAINT f2_projects FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_projects ADD CONSTRAINT f3_projects FOREIGN KEY (gu_owner) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_projects ADD CONSTRAINT f4_projects FOREIGN KEY (gu_user) REFERENCES k_users(gu_user);

ALTER TABLE k_project_expand ADD CONSTRAINT f1_project_expand FOREIGN KEY (gu_rootprj) REFERENCES k_projects(gu_project);
ALTER TABLE k_project_expand ADD CONSTRAINT f2_project_expand FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project);

ALTER TABLE k_x_duty_resource ADD CONSTRAINT f1_x_duty_resource FOREIGN KEY (gu_duty) REFERENCES k_duties(gu_duty);

ALTER TABLE k_duties_attach ADD CONSTRAINT f1_duties_attach FOREIGN KEY (gu_duty) REFERENCES k_duties(gu_duty);

ALTER TABLE k_bugs ADD CONSTRAINT f1_bugs FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project);

ALTER TABLE k_bugs_attach ADD CONSTRAINT f1_bugs_attach FOREIGN KEY (gu_bug) REFERENCES k_bugs(gu_bug);

ALTER TABLE k_bugs_changelog ADD CONSTRAINT f1_bugs_changelog FOREIGN KEY (gu_bug) REFERENCES k_bugs(gu_bug);
ALTER TABLE k_bugs_changelog ADD CONSTRAINT f2_bugs_changelog FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);
 