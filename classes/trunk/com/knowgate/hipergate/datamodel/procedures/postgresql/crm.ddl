CREATE SEQUENCE seq_k_contact_refs INCREMENT 1 START 10000
GO;

CREATE SEQUENCE seq_k_welcme_pak INCREMENT 1 START 1
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
  DELETE FROM k_contact_education WHERE gu_contact=$1;
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
