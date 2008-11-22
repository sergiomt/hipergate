ALTER TABLE k_thesauri_root ADD CONSTRAINT f1_thesauri_root FOREIGN KEY (id_domain) REFERENCES k_domains (id_domain);
ALTER TABLE k_thesauri_root ADD CONSTRAINT f2_thesauri_root FOREIGN KEY (gu_workarea) REFERENCES k_workareas (gu_workarea);

ALTER TABLE k_thesauri ADD CONSTRAINT f1_thesauri FOREIGN KEY (gu_rootterm) REFERENCES k_thesauri_root (gu_rootterm);
ALTER TABLE k_thesauri ADD CONSTRAINT f2_thesauri FOREIGN KEY (id_language) REFERENCES k_lu_languages (id_language);
ALTER TABLE k_thesauri ADD CONSTRAINT f3_thesauri FOREIGN KEY (id_domain)   REFERENCES k_domains (id_domain);
ALTER TABLE k_thesauri ADD CONSTRAINT f4_thesauri FOREIGN KEY (gu_synonym)  REFERENCES k_thesauri (gu_term);

ALTER TABLE k_images ADD CONSTRAINT f1_images FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_images ADD CONSTRAINT f2_images FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_addresses ADD CONSTRAINT f1_addresses FOREIGN KEY(id_country) REFERENCES k_lu_countries(id_country);
ALTER TABLE k_addresses ADD CONSTRAINT f2_addresses FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_addresses_lookup ADD CONSTRAINT f1_addresses_lookup FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_bank_accounts ADD CONSTRAINT f1_bank_accounts FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_bank_accounts_lookup ADD CONSTRAINT f1_bank_accounts_lookup FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);


