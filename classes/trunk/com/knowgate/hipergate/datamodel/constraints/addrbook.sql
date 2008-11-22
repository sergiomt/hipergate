ALTER TABLE k_lu_fellow_titles ADD CONSTRAINT f1_lu_fellow_titles FOREIGN KEY(id_boss,gu_workarea) REFERENCES k_lu_fellow_titles(de_title,gu_workarea);

ALTER TABLE k_fellows ADD CONSTRAINT f1_fellows FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_fellows ADD CONSTRAINT f2_fellows FOREIGN KEY(id_domain) REFERENCES k_domains(id_domain);
ALTER TABLE k_fellows ADD CONSTRAINT f3_fellows FOREIGN KEY(de_title,gu_workarea) REFERENCES k_lu_fellow_titles(de_title,gu_workarea);

ALTER TABLE k_fellows_attach ADD CONSTRAINT f1_fellows_attach FOREIGN KEY(gu_fellow) REFERENCES k_fellows(gu_fellow);

ALTER TABLE k_fellows_lookup ADD CONSTRAINT f1_fellows_lookup FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_rooms ADD CONSTRAINT f1_rooms FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_rooms ADD CONSTRAINT f2_rooms FOREIGN KEY(id_domain) REFERENCES k_domains(id_domain);

ALTER TABLE k_rooms_lookup ADD CONSTRAINT f1_rooms_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_meetings ADD CONSTRAINT f1_meeting FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_meetings ADD CONSTRAINT f2_meeting FOREIGN KEY(id_domain) REFERENCES k_domains(id_domain);
ALTER TABLE k_meetings ADD CONSTRAINT f3_meeting FOREIGN KEY(gu_fellow) REFERENCES k_fellows(gu_fellow);
ALTER TABLE k_meetings ADD CONSTRAINT f4_meeting FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address);

ALTER TABLE k_x_meeting_room ADD CONSTRAINT f1_x_meeting_room FOREIGN KEY(gu_meeting) REFERENCES k_meetings(gu_meeting);

ALTER TABLE k_x_meeting_fellow ADD CONSTRAINT f1_x_meeting_fellow FOREIGN KEY(gu_meeting) REFERENCES k_meetings(gu_meeting);

ALTER TABLE k_x_meeting_contact ADD CONSTRAINT f1_x_meeting_contact FOREIGN KEY(gu_meeting) REFERENCES k_meetings(gu_meeting);

ALTER TABLE k_phone_calls ADD CONSTRAINT f1_phone_calls  FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_phone_calls ADD CONSTRAINT f2_phone_calls  FOREIGN KEY(gu_user) REFERENCES k_users(gu_user);
ALTER TABLE k_phone_calls ADD CONSTRAINT f4_phone_calls  FOREIGN KEY(gu_writer) REFERENCES k_users(gu_user);

ALTER TABLE k_to_do ADD CONSTRAINT f1_to_do  FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_to_do ADD CONSTRAINT f2_to_do  FOREIGN KEY(gu_user) REFERENCES k_users(gu_user);


