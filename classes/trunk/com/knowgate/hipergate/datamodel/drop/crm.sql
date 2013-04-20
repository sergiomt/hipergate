DROP VIEW v_oportunity_contact_address;
DROP VIEW v_ldap_contacts;
DROP VIEW v_ldap_users;

DROP VIEW v_supplier_address;
DROP VIEW v_attach_locat;
DROP VIEW v_contact_list;
DROP VIEW v_contact_address_title;
DROP VIEW v_contact_address;
DROP VIEW v_contact_company_all;
DROP VIEW v_contact_company;
DROP VIEW v_active_contact_address;
DROP VIEW v_contact_titles;
DROP VIEW v_company_address;
DROP VIEW v_active_company_address;

DROP TABLE k_bulkloads;

DROP TABLE k_sms_audit;
DROP TABLE k_sms_msisdn;

DROP TABLE k_welcome_packs_changelog;
DROP TABLE k_welcome_packs;
DROP TABLE k_welcome_packs_lookup;

DROP TABLE k_member_address;

ALTER TABLE k_job_atoms DROP CONSTRAINT f1_job_atoms;

ALTER TABLE k_companies DROP CONSTRAINT f1_companies;
ALTER TABLE k_companies DROP CONSTRAINT f2_companies;

ALTER TABLE k_x_company_prods DROP CONSTRAINT f1_companies_prods;
ALTER TABLE k_x_company_prods DROP CONSTRAINT f2_companies_prods;

ALTER TABLE k_companies_attrs DROP CONSTRAINT f1_companies_attrs;

ALTER TABLE k_companies_recent DROP CONSTRAINT f1_companies_recent;
ALTER TABLE k_companies_recent DROP CONSTRAINT f2_companies_recent;
ALTER TABLE k_companies_recent DROP CONSTRAINT f3_companies_recent;

ALTER TABLE k_x_company_bank DROP CONSTRAINT f1_x_company_bank;

ALTER TABLE k_x_company_addr DROP CONSTRAINT f1_x_company_addr;
ALTER TABLE k_x_company_addr DROP CONSTRAINT f2_x_company_addr;

ALTER TABLE k_companies_lookup DROP CONSTRAINT f1_companies_lookup;

ALTER TABLE k_contacts DROP CONSTRAINT f1_contacts;
ALTER TABLE k_contacts DROP CONSTRAINT f2_contacts;
ALTER TABLE k_contacts DROP CONSTRAINT f3_contacts;
ALTER TABLE k_contacts DROP CONSTRAINT f4_contacts;

ALTER TABLE k_contacts_recent DROP CONSTRAINT f1_contacts_recent;
ALTER TABLE k_contacts_recent DROP CONSTRAINT f2_contacts_recent;
ALTER TABLE k_contacts_recent DROP CONSTRAINT f3_contacts_recent;

ALTER TABLE k_contact_notes DROP CONSTRAINT f1_contact_notes;

ALTER TABLE k_contact_attachs DROP CONSTRAINT f1_contact_attachs;
ALTER TABLE k_contact_attachs DROP CONSTRAINT f2_contact_attachs;

ALTER TABLE k_x_contact_bank DROP CONSTRAINT f1_x_contact_bank;

ALTER TABLE k_x_contact_addr DROP CONSTRAINT f1_x_contact_addr;
ALTER TABLE k_x_contact_addr DROP CONSTRAINT f2_x_contact_addr;

ALTER TABLE k_x_contact_prods DROP CONSTRAINT f1_contact_prods;
ALTER TABLE k_x_contact_prods DROP CONSTRAINT f2_contact_prods;

ALTER TABLE k_contacts_attrs DROP CONSTRAINT f1_contacts_attrs;

ALTER TABLE k_oportunities_attachs DROP CONSTRAINT f1_oportunities_attachs;
ALTER TABLE k_oportunities_attachs DROP CONSTRAINT f2_oportunities_attachs;

ALTER TABLE k_oportunities DROP CONSTRAINT f1_oportunities;
ALTER TABLE k_oportunities DROP CONSTRAINT f2_oportunities;
ALTER TABLE k_oportunities DROP CONSTRAINT f3_oportunities;

ALTER TABLE k_oportunities_lookup DROP CONSTRAINT f1_oportunities_lookup;

ALTER TABLE k_oportunities_attrs DROP CONSTRAINT f1_oportunities_attrs;

ALTER TABLE k_oportunities_changelog DROP CONSTRAINT f1_oportunities_changelog;

ALTER TABLE k_x_oportunity_contacts DROP CONSTRAINT f1_x_oportunity_contacts;

ALTER TABLE k_x_oportunity_contacts DROP CONSTRAINT f2_x_oportunity_contacts;

ALTER TABLE k_sales_men DROP CONSTRAINT f1_sales_men;
ALTER TABLE k_sales_men DROP CONSTRAINT f2_sales_men;

ALTER TABLE k_sales_men_lookup DROP CONSTRAINT f1_sales_men_lookup;

DROP TABLE k_sales_objectives;
DROP TABLE k_sales_men_lookup;
DROP TABLE k_sales_men;
DROP TABLE k_x_oportunity_contacts;
DROP TABLE k_oportunities_attachs;
DROP TABLE k_oportunities_changelog;
DROP TABLE k_oportunities_attrs;
DROP TABLE k_oportunities_lookup;
DROP TABLE k_oportunities;
DROP TABLE k_contacts_attrs;
DROP TABLE k_contacts_lookup;
DROP TABLE k_x_group_contact;
DROP TABLE k_x_contact_prods;
DROP TABLE k_x_contact_bank;
DROP TABLE k_x_contact_addr;
DROP TABLE k_contact_attachs;
DROP TABLE k_contact_notes;
DROP TABLE k_contacts_recent;
DROP TABLE k_contacts;
DROP TABLE k_companies_attrs;
DROP TABLE k_companies_lookup;
DROP TABLE k_x_group_company;
DROP TABLE k_x_company_prods;
DROP TABLE k_x_company_bank;
DROP TABLE k_x_company_addr;
DROP TABLE k_companies_recent;
DROP TABLE k_companies;
DROP TABLE k_prod_suppliers;
DROP TABLE k_suppliers_lookup;
DROP TABLE k_suppliers;
