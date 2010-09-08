CREATE SEQUENCE seq_k_contact_refs INCREMENT 1 START 10000
GO;

CREATE SEQUENCE seq_k_welcme_pak INCREMENT 1 START 1
GO;

CREATE SEQUENCE seq_k_bulkloads INCREMENT 1 START 1
GO;

CREATE FUNCTION k_sp_del_contact (CHAR) RETURNS INTEGER AS '
DECLARE
  addr RECORD;
  addrs text;
  aCount INTEGER := 0;

  bank RECORD;
  banks text;
  bCount INTEGER := 0;

  GuWorkArea CHAR(32);

BEGIN
  UPDATE k_sms_audit SET gu_contact=NULL WHERE gu_contact=$1;
  DELETE FROM k_x_activity_audience WHERE gu_contact=$1;
  DELETE FROM k_contact_education WHERE gu_contact=$1;
  DELETE FROM k_contact_languages WHERE gu_contact=$1;
  DELETE FROM k_contact_computer_science WHERE gu_contact=$1;
  DELETE FROM k_contact_experience WHERE gu_contact=$1;
  DELETE FROM k_x_duty_resource WHERE nm_resource=$1;
  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=$1);
  DELETE FROM k_welcome_packs WHERE gu_contact=$1;
  DELETE FROM k_x_list_members WHERE gu_contact=$1;
  DELETE FROM k_member_address WHERE gu_contact=$1;
  DELETE FROM k_contacts_recent WHERE gu_contact=$1;
  DELETE FROM k_x_group_contact WHERE gu_contact=$1;

  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=$1;

  FOR addr IN SELECT * FROM k_x_contact_addr WHERE gu_contact=$1 LOOP
    aCount := aCount + 1;
    IF 1=aCount THEN
      addrs := quote_literal(addr.gu_address);
    ELSE
      addrs := addrs || chr(44) || quote_literal(addr.gu_address);
    END IF;
  END LOOP;

  DELETE FROM k_x_contact_addr WHERE gu_contact=$1;
  
  IF char_length(addrs)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_addresses'') || '' WHERE gu_address IN ('' || addrs || '')'';
  END IF;

  FOR bank IN SELECT * FROM k_x_contact_bank WHERE gu_contact=$1 LOOP
    bCount := bCount + 1;
    IF 1=bCount THEN
      banks := quote_literal(bank.nu_bank_acc);
    ELSE
      banks := banks || chr(44) || quote_literal(bank.nu_bank_acc);
    END IF;
  END LOOP;

  DELETE FROM k_x_contact_bank WHERE gu_contact=$1;

  IF char_length(banks)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_bank_accounts'') || '' WHERE nu_bank_acc IN ('' || banks || '') AND gu_workarea='' || quote_literal(GuWorkArea);
  END IF;

  DELETE FROM k_oportunities_attachs WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=$1);
  DELETE FROM k_oportunities_changelog WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=$1);
  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=$1);
  DELETE FROM k_oportunities WHERE gu_contact=$1;

  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=90;

  DELETE FROM k_x_contact_prods WHERE gu_contact=$1;
  DELETE FROM k_contacts_attrs WHERE gu_object=$1;
  DELETE FROM k_contact_notes WHERE gu_contact=$1;
  DELETE FROM k_contacts WHERE gu_contact=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_company (CHAR) RETURNS INTEGER AS '
DECLARE
  addr RECORD;
  addrs text;
  aCount INTEGER := 0;

  bank RECORD;
  banks text;
  bCount INTEGER := 0;

BEGIN

  DELETE FROM k_x_duty_resource WHERE nm_resource=$1;
  DELETE FROM k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=$1);
  DELETE FROM k_welcome_packs WHERE gu_company=$1;
  DELETE FROM k_x_list_members WHERE gu_company=$1;
  DELETE FROM k_member_address WHERE gu_company=$1;
  DELETE FROM k_companies_recent WHERE gu_company=$1;
  DELETE FROM k_x_group_company WHERE gu_company=$1;

  FOR addr IN SELECT * FROM k_x_company_addr WHERE gu_company=$1 LOOP
    aCount := aCount + 1;
    IF 1=aCount THEN
      addrs := quote_literal(addr.gu_address);
    ELSE
      addrs := addrs || chr(44) || quote_literal(addr.gu_address);
    END IF;
  END LOOP;

  DELETE FROM k_x_company_addr WHERE gu_company=$1;

  IF char_length(addrs)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_addresses'') || '' WHERE gu_address IN ('' || addrs || '')'';
  END IF;

  FOR bank IN SELECT * FROM k_x_company_bank WHERE gu_company=$1 LOOP
    bCount := bCount + 1;
    IF 1=bCount THEN
      banks := quote_literal(bank.nu_bank_acc);
    ELSE
      banks := banks || chr(44) || quote_literal(bank.nu_bank_acc);
    END IF;
  END LOOP;

  DELETE FROM k_x_company_bank WHERE gu_company=$1;

  IF char_length(banks)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_bank_accounts'') || '' WHERE nu_bank_acc IN ('' || banks || '') AND gu_workarea='' || quote_literal(GuWorkArea);
  END IF;

  /* Borrar las oportunidades */
  DELETE FROM k_oportunities_attachs WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=$1);
  DELETE FROM k_oportunities_changelog WHERE gu_oportunity IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=$1);
  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=$1);
  DELETE FROM k_oportunities WHERE gu_company=$1;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=$1;

  /* Borrar el enlace con categorías */
  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=91;

  DELETE FROM k_x_company_prods WHERE gu_company=$1;
  DELETE FROM k_companies_attrs WHERE gu_object=$1;
  DELETE FROM k_companies WHERE gu_company=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_oportunity (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_oportunities_attachs WHERE gu_oportunity=$1;
  DELETE FROM k_oportunities_changelog WHERE gu_oportunity=$1;
  DELETE FROM k_oportunities_attrs WHERE gu_object=$1;
  DELETE FROM k_oportunities WHERE gu_oportunity=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_sales_man (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_companies SET gu_sales_man=NULL WHERE gu_sales_man=$1;
  DELETE FROM k_sales_objectives WHERE gu_sales_man=$1;
  DELETE FROM k_sales_men WHERE gu_sales_man=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_supplier (CHAR) RETURNS INTEGER AS '
DECLARE
  GuAddress CHAR(32);
BEGIN
  SELECT gu_address INTO GuAddress FROM k_suppliers WHERE gu_supplier=$1;
  DELETE FROM k_x_duty_resource WHERE nm_resource=$1;
  DELETE FROM k_suppliers WHERE gu_supplier=$1;
  DELETE FROM k_addresses WHERE gu_address=GuAddress;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_dedup_email_contacts () RETURNS INTEGER AS '
DECLARE
  addr RECORD;
  addrs text;
  aCount INTEGER := 0;
  TxPreve VARCHAR(100);
  TxEmail VARCHAR(100);
  GuWorkArea CHAR(32);
  GuContact CHAR(32);
  Dups NO SCROLL CURSOR FOR SELECT a.tx_email,a.gu_workarea FROM k_member_address a, k_member_address b WHERE a.tx_email=b.tx_email AND a.gu_contact<>b.gu_contact AND a.gu_contact IS NOT NULL and b.gu_contact IS NOT NULL AND a.gu_workarea=b.gu_workarea ORDER BY 1;
BEGIN
  CREATE TEMPORARY TABLE k_discard_contacts (gu_contact CHAR(32));
  CREATE TEMPORARY TABLE k_newer_contacts (gu_contact CHAR(32));
  
  TxPreve := '''';
  OPEN Dups;
  LOOP

    FETCH Dups INTO TxEmail,GuWorkArea;
    EXIT WHEN NOT FOUND;  
	IF TxEmail<>TxPreve THEN
      TxEmail:=TxPreve;
      SELECT gu_contact INTO GuContact FROM k_member_address WHERE gu_contact IS NOT NULL AND tx_email=TxEmail AND gu_workarea=GuWorkArea ORDER BY dt_created LIMIT 1;
      INSERT INTO k_newer_contacts (SELECT gu_contact FROM k_member_address WHERE gu_contact IS NOT NULL AND tx_email=TxEmail AND gu_workarea=GuWorkArea AND gu_contact<>GuContact);
	  INSERT INTO k_discard_contacts (SELECT gu_contact FROM k_newer_contacts);
		
      UPDATE k_sms_audit SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
  	  UPDATE k_x_activity_audience SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_contact_education SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_contact_languages SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_contact_computer_science SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_contact_experience SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_x_duty_resource SET nm_resource=GuContact WHERE nm_resource IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_welcome_packs SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_x_list_members SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_oportunities SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_x_cat_objs SET gu_object=GuContact WHERE gu_object IN (SELECT gu_contact FROM k_newer_contacts) AND id_class=90;
      UPDATE k_x_contact_prods SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_contacts_attrs SET gu_object=GuContact WHERE gu_object IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_contact_notes SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_contact_attachs SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_phone_calls SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_x_meeting_contact SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_inet_addrs SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_projects SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_orders SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_x_course_bookings SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_job_atoms_archived SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_job_atoms_tracking SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      UPDATE k_job_atoms_clicks SET gu_contact=GuContact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      
      DELETE FROM k_contacts_recent WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
      DELETE FROM k_x_group_contact WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);

      FOR addr IN SELECT * FROM k_x_contact_addr WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts) LOOP
        aCount := aCount + 1;
        IF 1=aCount THEN
          addrs := quote_literal(addr.gu_address);
        ELSE
          addrs := addrs || chr(44) || quote_literal(addr.gu_address);
        END IF;
      END LOOP;

      DELETE FROM k_x_contact_addr WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);
  
      IF char_length(addrs)>0 THEN
        EXECUTE ''DELETE FROM '' || quote_ident(''k_addresses'') || '' WHERE gu_address IN ('' || addrs || '')'';
      END IF;

      DELETE FROM k_member_address WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts);

      INSERT INTO k_contacts_deduplicated (SELECT current_timestamp AS dt_dedup,GuContact AS gu_dup,* FROM k_contacts WHERE gu_contact IN (SELECT gu_contact FROM k_newer_contacts));
    
      DELETE FROM k_newer_contacts;
    END IF;
  END LOOP;
  CLOSE Dups;
  

	SELECT SUM(k_sp_del_contact(gu_contact)) INTO aCount FROM k_discard_contacts;
	
	SELECT COUNT(*) INTO aCount FROM k_discard_contacts;
	
	DROP TABLE k_discard_contacts;
	DROP TABLE k_newer_contacts;
	
	RETURN aCount;
END;
' LANGUAGE 'plpgsql';
GO;
