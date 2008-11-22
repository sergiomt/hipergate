CREATE TABLE k_version
(
vs_stamp VARCHAR(16) NOT NULL,

CONSTRAINT pk_version PRIMARY KEY (vs_stamp)
)
GO;

INSERT INTO k_version VALUES ('1.1.0')
GO;

DROP FUNCTION k_sp_del_category_r (CHAR)
GO;

DROP FUNCTION k_sp_del_category (CHAR)
GO;

CREATE FUNCTION k_sp_del_category (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_cat_expand WHERE gu_rootcat=$1;
  DELETE FROM k_cat_expand WHERE gu_parent_cat=$1;
  DELETE FROM k_cat_expand WHERE gu_category=$1;
  DELETE FROM k_cat_tree WHERE gu_child_cat=$1;
  DELETE FROM k_cat_root WHERE gu_category=$1;
  DELETE FROM k_cat_labels WHERE gu_category=$1;
  DELETE FROM k_x_cat_user_acl WHERE gu_category=$1;
  DELETE FROM k_x_cat_group_acl WHERE gu_category=$1;
  DELETE FROM k_x_cat_objs WHERE gu_category=$1;
  DELETE FROM k_categories WHERE gu_category=$1;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_category_r (CHAR) RETURNS INTEGER AS '
DECLARE
  childs k_cat_tree%ROWTYPE;
BEGIN  
  FOR childs IN SELECT * FROM k_cat_tree WHERE gu_parent_cat=$1 LOOP
    PERFORM k_sp_del_category_r (childs.gu_child_cat);
  END LOOP;

  PERFORM k_sp_del_category ($1);

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_contact (CHAR)
GO;

CREATE FUNCTION k_sp_del_contact (CHAR) RETURNS INTEGER AS '
DECLARE
  addr k_x_contact_addr%ROWTYPE;
  addrs text;
  aCount INTEGER := 0;

  bank k_x_contact_bank%ROWTYPE;
  banks text;
  bCount INTEGER := 0;

  GuWorkArea CHAR(32);

BEGIN
  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=$1;

  FOR addr IN SELECT gu_address FROM k_x_contact_addr WHERE gu_contact=$1 LOOP
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

  FOR bank IN SELECT nu_bank_acc FROM k_x_contact_bank WHERE gu_contact=$1 LOOP
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

  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=$1);
  DELETE FROM k_oportunities WHERE gu_contact=$1;

  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=90;

  DELETE FROM k_contacts_attrs WHERE gu_object=$1;
  DELETE FROM k_contact_notes WHERE gu_contact=$1;
  DELETE FROM k_contacts WHERE gu_contact=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_company (CHAR)
GO;

CREATE FUNCTION k_sp_del_company (CHAR) RETURNS INTEGER AS '
DECLARE
  addr k_x_company_addr%ROWTYPE;
  addrs text;
  aCount INTEGER := 0;

  bank k_x_company_bank%ROWTYPE;
  banks text;
  bCount INTEGER := 0;

BEGIN

  FOR addr IN SELECT gu_address FROM k_x_company_addr WHERE gu_company=$1 LOOP
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

  FOR bank IN SELECT nu_bank_acc FROM k_x_company_bank WHERE gu_company=$1 LOOP
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
  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=$1);
  DELETE FROM k_oportunities WHERE gu_company=$1;

  /* Borrar el enlace con categorías */
  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=91;

  /* Borrar los atributos extendidos */
  DELETE FROM k_companies_attrs WHERE gu_object=$1;
  DELETE FROM k_companies WHERE gu_company=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_fellow (CHAR)
GO;

CREATE FUNCTION k_sp_del_fellow (CHAR) RETURNS INTEGER AS '
DECLARE
  MeetingId CHAR(32);
  meetings CURSOR (id CHAR(32)) FOR SELECT gu_meeting FROM k_x_meeting_fellow WHERE gu_fellow=id;
BEGIN
  OPEN meetings($1);
    LOOP
      FETCH meetings INTO MeetingId;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_del_meeting (MeetingId);
    END LOOP;
  CLOSE meetings;

  DELETE FROM k_fellows_attach WHERE gu_fellow=$1;
  DELETE FROM k_fellows WHERE gu_fellow=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;
