CREATE INDEX i1_companies ON k_companies(gu_workarea);
CREATE INDEX i2_companies ON k_companies(gu_workarea,nm_commercial);
CREATE INDEX i3_companies ON k_companies(gu_workarea,id_legal);
CREATE INDEX i4_companies ON k_companies(gu_workarea,id_sector);
CREATE INDEX i5_companies ON k_companies(gu_workarea,id_ref);
CREATE INDEX i6_companies ON k_companies(gu_workarea,gu_geozone);

CREATE INDEX i1_companies_recent ON k_companies_recent(gu_user);
CREATE INDEX i2_companies_recent ON k_companies_recent(gu_workarea);

CREATE INDEX i1_contacts ON k_contacts(gu_workarea);
CREATE INDEX i2_contacts ON k_contacts(gu_company);
CREATE INDEX i3_contacts ON k_contacts(tx_name);
CREATE INDEX i4_contacts ON k_contacts(tx_surname);
CREATE INDEX i5_contacts ON k_contacts(gu_workarea,dt_birth);
CREATE INDEX i6_contacts ON k_contacts(gu_workarea,ny_age);
CREATE INDEX i7_contacts ON k_contacts(gu_writer);
CREATE INDEX i8_contacts ON k_contacts(sn_passport);

CREATE INDEX i1_x_contact_addr ON k_x_contact_addr(gu_contact);
CREATE INDEX i2_x_contact_addr ON k_x_contact_addr(gu_address);

CREATE INDEX i1_oportunities ON k_oportunities(gu_workarea);
CREATE INDEX i2_oportunities ON k_oportunities(gu_writer);
CREATE INDEX i3_oportunities ON k_oportunities(tl_oportunity);
CREATE INDEX i4_oportunities ON k_oportunities(dt_modified);
CREATE INDEX i5_oportunities ON k_oportunities(dt_next_action);
CREATE INDEX i6_oportunities ON k_oportunities(id_status);
CREATE INDEX i7_oportunities ON k_oportunities(gu_campaign);
CREATE INDEX i8_oportunities ON k_oportunities(gu_contact);

CREATE INDEX i1_oportunities_changelog ON k_oportunities_changelog(gu_oportunity);

CREATE INDEX i1_oportunity_contacts ON k_x_oportunity_contacts (gu_oportunity);

CREATE INDEX i1_contacts_recent ON k_contacts_recent(gu_user);
CREATE INDEX i2_contacts_recent ON k_contacts_recent(gu_workarea);

CREATE INDEX i1_welcome_packs ON k_welcome_packs(gu_workarea);
CREATE INDEX i2_welcome_packs ON k_welcome_packs(gu_contact);

CREATE INDEX i1_sms_audit ON k_sms_audit(gu_workarea);

