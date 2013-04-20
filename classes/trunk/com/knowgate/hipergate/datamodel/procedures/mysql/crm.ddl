INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_contact_refs', 10000, 2147483647, 1, 10000)
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_welcme_pak', 1, 2147483647, 1, 1)
GO;

CREATE PROCEDURE k_sp_del_contact (ContactId CHAR(32))
BEGIN
  DECLARE GuWorkArea CHAR(32);

  UPDATE k_sms_audit SET gu_contact=NULL WHERE gu_contact=ContactId;

  DELETE FROM k_phone_calls WHERE gu_contact=ContactId;
  DELETE FROM k_x_meeting_contact WHERE gu_contact=ContactId;

  DELETE FROM k_x_activity_audience WHERE gu_contact=ContactId;

  DELETE FROM k_x_course_bookings WHERE gu_contact=ContactId;
  DELETE FROM k_x_course_alumni WHERE gu_alumni=ContactId;  

  DELETE FROM k_contact_education WHERE gu_contact=ContactId;
  DELETE FROM k_contact_languages WHERE gu_contact=ContactId;
  DELETE FROM k_contact_computer_science WHERE gu_contact=ContactId;
  DELETE FROM k_contact_experience WHERE gu_contact=ContactId;
 
  DELETE FROM k_admission WHERE gu_contact=ContactId;

  DELETE FROM k_x_duty_resource WHERE nm_resource=ContactId;

  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=ContactId);

  DELETE FROM k_welcome_packs WHERE gu_contact=ContactId;

  DELETE FROM k_x_list_members WHERE gu_contact=ContactId;

  DELETE FROM k_member_address WHERE gu_contact=ContactId;
  
  DELETE FROM k_contacts_recent WHERE gu_contact=ContactId;

  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=ContactId;

  DELETE FROM k_x_group_contact WHERE gu_contact=ContactId;

  CREATE TEMPORARY TABLE k_tmp_del_addr (gu_address CHAR(32)) SELECT gu_address FROM k_x_contact_addr WHERE gu_contact=ContactId;  
  DELETE FROM k_x_contact_addr WHERE gu_contact=ContactId;
  UPDATE k_x_activity_audience SET gu_address=NULL WHERE gu_address IN (SELECT gu_address FROM k_tmp_del_addr);
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_tmp_del_addr);
  DROP TEMPORARY TABLE k_tmp_del_addr;

  CREATE TEMPORARY TABLE k_tmp_del_bank (nu_bank_acc CHAR(20)) SELECT nu_bank_acc FROM k_x_contact_bank WHERE gu_contact=ContactId;
  DELETE FROM k_x_contact_bank WHERE gu_contact=ContactId;
  DELETE FROM k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM k_tmp_del_bank) AND gu_workarea=GuWorkArea;
  DROP TEMPORARY TABLE k_tmp_del_bank;

  DELETE FROM k_x_oportunity_contacts WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=ContactId);
  DELETE FROM k_oportunities_attachs WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=ContactId);
  DELETE FROM k_oportunities_changelog WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=ContactId);
  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=ContactId);
  DELETE FROM k_oportunities WHERE gu_contact=ContactId;

  DELETE FROM k_x_cat_objs WHERE gu_object=ContactId AND id_class=90;

  DELETE FROM k_x_contact_prods WHERE gu_contact=ContactId;
  DELETE FROM k_contacts_attrs WHERE gu_object=ContactId;
  DELETE FROM k_contact_notes WHERE gu_contact=ContactId;
  DELETE FROM k_contacts WHERE gu_contact=ContactId;
END
GO;

CREATE PROCEDURE k_sp_del_company (CompanyId CHAR(32))
BEGIN
  DECLARE GuWorkArea CHAR(32);

  DELETE FROM k_x_duty_resource WHERE nm_resource=CompanyId;

  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=CompanyId);

  DELETE FROM k_welcome_packs WHERE gu_company=CompanyId;

  DELETE FROM k_x_list_members WHERE gu_company=CompanyId;

  DELETE FROM k_member_address WHERE gu_company=CompanyId;

  DELETE FROM k_companies_recent WHERE gu_company=CompanyId;

  SELECT gu_workarea INTO GuWorkArea FROM k_companies WHERE gu_company=CompanyId;

  DELETE FROM k_x_group_company WHERE gu_company=CompanyId;

  CREATE TEMPORARY TABLE k_tmp_del_addr (gu_address CHAR(32)) SELECT gu_address FROM k_x_company_addr WHERE gu_company=CompanyId;
  DELETE FROM k_x_company_addr WHERE gu_company=CompanyId;
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_tmp_del_addr);
  DROP TEMPORARY TABLE k_tmp_del_addr;

  CREATE TEMPORARY TABLE k_tmp_del_bank (nu_bank_acc CHAR(20)) SELECT nu_bank_acc FROM k_x_company_bank WHERE gu_company=CompanyId;
  DELETE FROM k_x_company_bank WHERE gu_company=CompanyId;
  DELETE FROM k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM k_tmp_del_bank) AND gu_workarea=GuWorkArea;
  DROP TEMPORARY TABLE k_tmp_del_bank;

  DELETE FROM k_x_oportunity_contacts WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE FROM k_oportunities_attachs WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE FROM k_oportunities_changelog WHERE gu_oportunityt IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE FROM k_oportunities WHERE gu_company=CompanyId;

  DELETE FROM k_x_cat_objs WHERE gu_object=CompanyId AND id_class=91;

  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=CompanyId;

  DELETE FROM k_x_company_prods WHERE gu_company=CompanyId;
  DELETE FROM k_companies_attrs WHERE gu_object=CompanyId;
  DELETE FROM k_companies WHERE gu_company=CompanyId;
END
GO;

CREATE PROCEDURE k_sp_del_oportunity (OportunityId CHAR(32))
BEGIN
  DECLARE GuContact CHAR(32);
  DECLARE NuCount INTEGER;
  SELECT gu_contact INTO GuContact FROM k_oportunities WHERE gu_oportunity=OportunityId;
  UPDATE k_phone_calls SET gu_oportunity=NULL WHERE gu_oportunity=OportunityId;
  DELETE FROM k_x_oportunity_contacts WHERE gu_oportunity=OportunityId;
  DELETE FROM k_oportunities_attachs WHERE gu_oportunity=OportunityId;
  DELETE FROM k_oportunities_changelog WHERE gu_oportunity=OportunityId;
  DELETE FROM k_oportunities_attrs WHERE gu_object=OportunityId;
  DELETE FROM k_oportunities WHERE gu_oportunity=OportunityId;
  IF GuContact IS NOT NULL THEN
    SELECT COUNT(*) INTO NuCount FROM k_oportunities WHERE gu_contact=GuContact;
    UPDATE k_oportunities SET nu_oportunities=NuCount WHERE gu_contact=GuContact;    
  END IF;
END
GO;

CREATE PROCEDURE k_sp_del_sales_man (SalesManId CHAR(32))
BEGIN
  UPDATE k_companies SET gu_sales_man=NULL WHERE gu_sales_man=SalesManId;
  DELETE FROM k_sales_objectives WHERE gu_sales_man=SalesManId;
  DELETE FROM k_sales_men WHERE gu_sales_man=SalesManId;
END
GO;

CREATE PROCEDURE k_sp_del_supplier (SupplierId CHAR(32))
BEGIN
  DECLARE GuAddress CHAR(32);
  SELECT gu_address INTO GuAddress FROM k_suppliers WHERE gu_supplier=SupplierId;
  DELETE FROM k_x_duty_resource WHERE nm_resource=SupplierId;
  UPDATE k_academic_courses SET gu_supplier=NULL WHERE gu_supplier=SupplierId;
  DELETE FROM k_suppliers WHERE gu_supplier=SupplierId;
  DELETE FROM k_addresses WHERE gu_address=GuAddress;
END
GO;