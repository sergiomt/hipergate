ALTER TABLE k_accounts ADD CONSTRAINT f1_accounts FOREIGN KEY (id_domain) REFERENCES k_domains(id_domain);
ALTER TABLE k_accounts ADD CONSTRAINT f2_accounts FOREIGN KEY (gu_billing_addr) REFERENCES k_addresses(gu_address);
ALTER TABLE k_accounts ADD CONSTRAINT f3_accounts FOREIGN KEY (gu_contact_addr) REFERENCES k_addresses(gu_address);
ALTER TABLE k_accounts ADD CONSTRAINT f4_accounts FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);
