ALTER TABLE k_courses ADD CONSTRAINT f1_courses FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_courses_lookup ADD CONSTRAINT f1_courses_lookup FOREIGN KEY (gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_academic_courses ADD CONSTRAINT f1_academic_courses FOREIGN KEY (gu_course) REFERENCES k_courses(gu_course);
ALTER TABLE k_academic_courses ADD CONSTRAINT f2_academic_courses FOREIGN KEY (gu_address) REFERENCES k_addresses(gu_address);
ALTER TABLE k_academic_courses ADD CONSTRAINT f3_academic_courses FOREIGN KEY (gu_supplier) REFERENCES k_suppliers(gu_supplier);

ALTER TABLE k_subjects ADD CONSTRAINT f1_subjects FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_subjects ADD CONSTRAINT f2_subjects FOREIGN KEY (gu_course) REFERENCES k_courses(gu_course);

ALTER TABLE k_subjects_lookup ADD CONSTRAINT f1_subjects_lookup FOREIGN KEY (gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_x_course_bookings ADD CONSTRAINT f2_x_course_bookings FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact);

ALTER TABLE k_absentisms ADD CONSTRAINT f3_absentisms FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);

ALTER TABLE k_absentisms_lookup ADD CONSTRAINT f1_absentisms_lookup FOREIGN KEY (gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_education_institutions ADD CONSTRAINT f1_education_institutions FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_education_degree ADD CONSTRAINT f1_education_degree FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_education_degree ADD CONSTRAINT f2_education_degree FOREIGN KEY (id_country) REFERENCES k_lu_countries(id_country);
ALTER TABLE k_education_degree_lookup ADD CONSTRAINT f1_education_degree_lookup FOREIGN KEY (gu_owner) REFERENCES k_workareas(gu_workarea);

