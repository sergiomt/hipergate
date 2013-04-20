
DROP FUNCTION k_sp_del_duplicates (CHAR);

DROP FUNCTION k_sp_rebuild_member_address ();

DROP FUNCTION k_sp_company_blocked (CHAR,CHAR);

DROP FUNCTION k_sp_contact_blocked (CHAR,CHAR);

DROP FUNCTION k_sp_email_blocked (CHAR,VARCHAR);

DROP FUNCTION k_sp_del_list (CHAR);

DROP TRIGGER  k_tr_del_company ON k_companies;

DROP FUNCTION k_sp_del_company();

DROP TRIGGER k_tr_del_contact ON k_contacts;

DROP FUNCTION k_sp_del_contact();

DROP TRIGGER k_tr_del_address ON k_addresses;

DROP FUNCTION k_sp_del_address();

DROP TRIGGER k_tr_ins_address ON k_addresses;

DROP FUNCTION k_sp_ins_address();

DROP TRIGGER k_tr_upd_address ON k_addresses;

DROP FUNCTION k_sp_upd_address();

DROP TRIGGER k_tr_ins_comp_addr ON k_x_company_addr;

DROP FUNCTION k_sp_ins_comp_addr();

DROP TRIGGER k_tr_ins_cont_addr ON k_x_contact_addr;

DROP FUNCTION k_sp_ins_cont_addr();

DROP TRIGGER k_tr_upd_comp ON k_companies;

DROP FUNCTION k_sp_upd_comp();

DROP TRIGGER k_tr_upd_cont ON k_contacts;

DROP FUNCTION k_sp_upd_cont();
