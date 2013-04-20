CREATE INDEX i1_lists ON k_lists(gu_workarea);

CREATE INDEX i2_lists ON k_lists(gu_query);

CREATE INDEX i1_x_list_members ON k_x_list_members(gu_list);

CREATE INDEX i2_x_list_members ON k_x_list_members(gu_contact);

CREATE INDEX i3_x_list_members ON k_x_list_members(gu_company);

CREATE INDEX i4_x_list_members ON k_x_list_members(gu_list,tx_email);

CREATE INDEX i1_member_address ON k_member_address (gu_workarea);

CREATE INDEX i2_member_address ON k_member_address (gu_company);

CREATE INDEX i3_member_address ON k_member_address (gu_contact);

CREATE INDEX i4_member_address ON k_member_address (tx_email);

CREATE INDEX i5_member_address ON k_member_address (tx_name);

CREATE INDEX i6_member_address ON k_member_address (tx_surname);

CREATE INDEX i7_member_address ON k_member_address (contact_person);
