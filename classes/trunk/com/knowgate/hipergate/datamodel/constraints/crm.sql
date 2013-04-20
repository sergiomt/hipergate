ALTER TABLE k_job_atoms ADD CONSTRAINT f1_job_atoms FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);

ALTER TABLE k_companies ADD CONSTRAINT f1_companies FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_companies ADD CONSTRAINT f2_companies FOREIGN KEY(gu_geozone) REFERENCES k_thesauri(gu_term);

ALTER TABLE k_companies_attrs ADD CONSTRAINT f1_companies_attrs FOREIGN KEY (gu_object) REFERENCES k_companies(gu_company);

ALTER TABLE k_x_company_bank ADD CONSTRAINT f1_x_company_bank FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);

ALTER TABLE k_x_company_prods ADD CONSTRAINT f1_companies_prods FOREIGN KEY (gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_x_company_prods ADD CONSTRAINT f2_companies_prods FOREIGN KEY (gu_category) REFERENCES k_categories(gu_category);

ALTER TABLE k_x_group_company ADD CONSTRAINT f1_x_group_company FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_x_group_company ADD CONSTRAINT f2_x_group_company FOREIGN KEY(gu_acl_group) REFERENCES k_acl_groups(gu_acl_group);

ALTER TABLE k_x_company_addr ADD CONSTRAINT f1_x_company_addr FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_x_company_addr ADD CONSTRAINT f2_x_company_addr FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address);

ALTER TABLE k_companies_recent ADD CONSTRAINT f1_companies_recent FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_companies_recent ADD CONSTRAINT f2_companies_recent FOREIGN KEY(gu_user) REFERENCES k_users(gu_user);
ALTER TABLE k_companies_recent ADD CONSTRAINT f3_companies_recent FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_companies_lookup ADD CONSTRAINT f1_companies_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_contacts ADD CONSTRAINT f1_contacts FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_contacts ADD CONSTRAINT f2_contacts FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_contacts ADD CONSTRAINT f3_contacts FOREIGN KEY(gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_contacts ADD CONSTRAINT f4_contacts FOREIGN KEY(gu_geozone) REFERENCES k_thesauri(gu_term);
ALTER TABLE k_contacts ADD CONSTRAINT f5_contacts FOREIGN KEY(id_nationality) REFERENCES k_lu_countries(id_country);

ALTER TABLE k_contact_notes ADD CONSTRAINT f1_contact_notes FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);

ALTER TABLE k_contact_attachs ADD CONSTRAINT f1_contact_attachs FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_contact_attachs ADD CONSTRAINT f2_contact_attachs FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);

ALTER TABLE k_contacts_recent ADD CONSTRAINT f1_contacts_recent FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_contacts_recent ADD CONSTRAINT f2_contacts_recent FOREIGN KEY(gu_user) REFERENCES k_users(gu_user);
ALTER TABLE k_contacts_recent ADD CONSTRAINT f3_contacts_recent FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_x_contact_bank ADD CONSTRAINT f1_x_contact_bank FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact);

ALTER TABLE k_x_contact_prods ADD CONSTRAINT f1_contact_prods FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_x_contact_prods ADD CONSTRAINT f2_contact_prods FOREIGN KEY (gu_category) REFERENCES k_categories(gu_category);

ALTER TABLE k_x_group_contact ADD CONSTRAINT f1_x_group_contact FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_x_group_contact ADD CONSTRAINT f2_x_group_contact FOREIGN KEY(gu_acl_group) REFERENCES k_acl_groups(gu_acl_group);

ALTER TABLE k_x_contact_addr ADD CONSTRAINT f1_x_contact_addr FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_x_contact_addr ADD CONSTRAINT f2_x_contact_addr FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address);

ALTER TABLE k_contacts_attrs ADD CONSTRAINT f1_contacts_attrs FOREIGN KEY (gu_object) REFERENCES k_contacts(gu_contact);

ALTER TABLE k_oportunities ADD CONSTRAINT f1_oportunities FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_oportunities ADD CONSTRAINT f2_oportunities FOREIGN KEY (gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_oportunities ADD CONSTRAINT f3_oportunities FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact);

ALTER TABLE k_oportunities_lookup ADD CONSTRAINT f1_oportunities_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_oportunities_attrs ADD CONSTRAINT f1_oportunities_attrs FOREIGN KEY (gu_object) REFERENCES k_oportunities(gu_oportunity);

ALTER TABLE k_oportunities_changelog ADD CONSTRAINT f1_oportunities_changelog FOREIGN KEY (gu_oportunity) REFERENCES k_oportunities(gu_oportunity);

ALTER TABLE k_oportunities_attachs ADD CONSTRAINT f1_oportunities_attachs FOREIGN KEY (gu_oportunity) REFERENCES k_oportunities(gu_oportunity);
ALTER TABLE k_oportunities_attachs ADD CONSTRAINT f2_oportunities_attachs FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);

ALTER TABLE k_x_oportunity_contacts ADD CONSTRAINT f1_x_oportunity_contacts FOREIGN KEY (gu_oportunity) REFERENCES k_oportunities(gu_oportunity);
ALTER TABLE k_x_oportunity_contacts ADD CONSTRAINT f2_x_oportunity_contacts FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact);

ALTER TABLE k_sales_men ADD CONSTRAINT f1_sales_men FOREIGN KEY (gu_sales_man) REFERENCES k_users(gu_user);
ALTER TABLE k_sales_men ADD CONSTRAINT f2_sales_men FOREIGN KEY (gu_geozone) REFERENCES k_thesauri(gu_term);

ALTER TABLE k_sales_men_lookup ADD CONSTRAINT f1_sales_men_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_member_address ADD CONSTRAINT f1_member_address FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address);
ALTER TABLE k_member_address ADD CONSTRAINT f2_member_address FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_member_address ADD CONSTRAINT f3_member_address FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_member_address ADD CONSTRAINT f4_member_address FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_member_address ADD CONSTRAINT f5_member_address FOREIGN KEY(gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_member_address ADD CONSTRAINT f6_member_address FOREIGN KEY(gu_sales_man) REFERENCES k_users(gu_user);
ALTER TABLE k_member_address ADD CONSTRAINT f7_member_address FOREIGN KEY(gu_geozone) REFERENCES k_thesauri(gu_term);
ALTER TABLE k_member_address ADD CONSTRAINT f8_member_address FOREIGN KEY(id_country) REFERENCES k_lu_countries(id_country);

ALTER TABLE k_welcome_packs ADD CONSTRAINT f1_welcome_packs FOREIGN KEY(gu_company)  REFERENCES k_companies(gu_company);
ALTER TABLE k_welcome_packs ADD CONSTRAINT f2_welcome_packs FOREIGN KEY(gu_contact)  REFERENCES k_contacts (gu_contact);
ALTER TABLE k_welcome_packs ADD CONSTRAINT f3_welcome_packs FOREIGN KEY(gu_address)  REFERENCES k_addresses(gu_address);
ALTER TABLE k_welcome_packs ADD CONSTRAINT f4_welcome_packs FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_welcome_packs_lookup ADD CONSTRAINT f1_welcome_packs_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_suppliers ADD CONSTRAINT f1_suppliers FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_suppliers ADD CONSTRAINT f2_suppliers FOREIGN KEY(gu_geozone) REFERENCES k_thesauri(gu_term);
ALTER TABLE k_suppliers ADD CONSTRAINT f3_suppliers FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address);

ALTER TABLE k_prod_suppliers ADD CONSTRAINT f1_prod_suppliers FOREIGN KEY(gu_product) REFERENCES k_products(gu_product);
ALTER TABLE k_prod_suppliers ADD CONSTRAINT f2_prod_suppliers FOREIGN KEY(gu_supplier) REFERENCES k_suppliers(gu_supplier);

ALTER TABLE k_sms_audit ADD CONSTRAINT f1_sms_audit FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_sms_audit ADD CONSTRAINT f2_sms_audit FOREIGN KEY(gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_sms_audit ADD CONSTRAINT f3_sms_audit FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address);
ALTER TABLE k_sms_audit ADD CONSTRAINT f4_sms_audit FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact);
ALTER TABLE k_sms_audit ADD CONSTRAINT f5_sms_audit FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);

