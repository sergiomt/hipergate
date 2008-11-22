CREATE SEQUENCE seq_k_contact_refs INCREMENT BY 1 START WITH 10000
GO;

CREATE SEQUENCE seq_k_welcme_pak INCREMENT BY 1 START WITH 1
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_contact (ContactId CHAR) IS
  TYPE GUIDS IS TABLE OF k_addresses.gu_address%TYPE;
  TYPE BANKS IS TABLE OF k_bank_accounts.nu_bank_acc%TYPE;

  k_tmp_del_addr GUIDS := GUIDS();
  k_tmp_del_bank BANKS := BANKS();

  GuWorkArea CHAR(32);

BEGIN
  DELETE k_x_duty_resource WHERE nm_resource=ContactId;
  DELETE k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_contact=ContactId);
  DELETE k_welcome_packs WHERE gu_contact=ContactId;
  DELETE k_x_list_members WHERE gu_contact=ContactId;
  DELETE k_member_address WHERE gu_contact=ContactId;
  DELETE k_contacts_recent WHERE gu_contact=ContactId;
  DELETE k_x_group_contact WHERE gu_contact=ContactId;

  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=ContactId;

  FOR addr IN ( SELECT gu_address FROM k_x_contact_addr WHERE gu_contact=ContactId) LOOP
    k_tmp_del_addr.extend;
    k_tmp_del_addr(k_tmp_del_addr.count) := addr.gu_address;
  END LOOP;

  DELETE k_x_contact_addr WHERE gu_contact=ContactId;

  FOR a IN 1..k_tmp_del_addr.COUNT LOOP
    DELETE k_addresses WHERE gu_address=k_tmp_del_addr(a);
  END LOOP;

  /* Borrar las cuentas bancarias del contacto */

  FOR bank IN ( SELECT nu_bank_acc FROM k_x_contact_bank WHERE gu_contact=ContactId) LOOP
    k_tmp_del_bank.extend;
    k_tmp_del_bank(k_tmp_del_bank.count) := bank.nu_bank_acc;
  END LOOP;

  DELETE k_x_contact_bank WHERE gu_contact=ContactId;

  FOR a IN 1..k_tmp_del_bank.COUNT LOOP
    DELETE k_bank_accounts WHERE nu_bank_acc=k_tmp_del_bank(a) AND gu_workarea=GuWorkArea;
  END LOOP;

  /* Los productos que contienen la referencia a los ficheros adjuntos no se borran desde aquí,
     hay que llamar al método Java de borrado de Product para eliminar también los ficheros físicos,
     de este modo la foreign key de la base de datos actua como protección para que no se queden ficheros basura */

  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=ContactId);
  DELETE k_oportunities WHERE gu_contact=ContactId;

  DELETE k_x_cat_objs WHERE gu_object=ContactId AND id_class=90;

  DELETE k_x_contact_prods WHERE gu_contact=ContactId;
  DELETE k_contacts_attrs WHERE gu_object=ContactId;
  DELETE k_contact_notes WHERE gu_contact=ContactId;
  DELETE k_contacts WHERE gu_contact=ContactId;
END k_sp_del_contact;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_company (CompanyId CHAR) IS
  TYPE GUIDS IS TABLE OF k_addresses.gu_address%TYPE;
  TYPE BANKS IS TABLE OF k_bank_accounts.nu_bank_acc%TYPE;

  k_tmp_del_addr GUIDS := GUIDS();
  k_tmp_del_bank BANKS := BANKS();

  GuWorkArea CHAR(32);

BEGIN
  DELETE k_x_duty_resource WHERE nm_resource=CompanyId;
  DELETE k_welcome_packs_changelog WHERE gu_pack IN (SELECT gu_pack FROM k_welcome_packs WHERE gu_company=CompanyId);
  DELETE k_welcome_packs WHERE gu_company=CompanyId;
  DELETE k_x_list_members WHERE gu_company=CompanyId;
  DELETE k_member_address WHERE gu_company=CompanyId;
  DELETE k_companies_recent WHERE gu_company=CompanyId;
  DELETE k_x_group_company WHERE gu_company=CompanyId;
  
  SELECT gu_workarea INTO GuWorkArea FROM k_companies WHERE gu_company=CompanyId;

  /* Borrar las direcciones de la compañia */
  FOR addr IN ( SELECT gu_address FROM k_x_company_addr WHERE gu_company=CompanyId) LOOP
    k_tmp_del_addr.extend;
    k_tmp_del_addr(k_tmp_del_addr.count) := addr.gu_address;
  END LOOP;

  DELETE k_x_company_addr WHERE gu_company=CompanyId;

  FOR a IN 1..k_tmp_del_addr.COUNT LOOP
    DELETE k_addresses WHERE gu_address=k_tmp_del_addr(a);
  END LOOP;

  /* Borrar las cuentas bancarias de la compañia */

  FOR bank IN ( SELECT nu_bank_acc FROM k_x_company_bank WHERE gu_company=CompanyId) LOOP
    k_tmp_del_bank.extend;
    k_tmp_del_bank(k_tmp_del_bank.count) := bank.nu_bank_acc;
  END LOOP;

  DELETE k_x_company_bank WHERE gu_company=CompanyId;

  FOR a IN 1..k_tmp_del_bank.COUNT LOOP
    DELETE k_bank_accounts WHERE nu_bank_acc=k_tmp_del_bank(a);
  END LOOP;

  /* Borrar las oportunidades */
  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE k_oportunities WHERE gu_company=CompanyId;

  /* Borrar las referencias de PageSets */
  
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=CompanyId;
  /* Borrar el enlace con categorías */
  
  DELETE k_x_cat_objs WHERE gu_object=CompanyId AND id_class=91;

  DELETE k_x_company_prods WHERE gu_company=CompanyId;
  DELETE k_companies_attrs WHERE gu_object=CompanyId;
  DELETE k_companies WHERE gu_company=CompanyId;
END k_sp_del_company;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_oportunity (OportunityId CHAR) IS
BEGIN
  DELETE k_oportunities_attrs WHERE gu_object=OportunityId;
  DELETE k_oportunities WHERE gu_oportunity=OportunityId;
END k_sp_del_oportunity;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_sales_man (SalesManId CHAR) IS
BEGIN
  UPDATE k_companies SET gu_sales_man=NULL WHERE gu_sales_man=SalesManId;
  DELETE k_sales_objectives WHERE gu_sales_man=SalesManId;
  DELETE k_sales_men WHERE gu_sales_man=SalesManId;
END k_sp_del_sales_man;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_supplier (SupplierId CHAR) IS
  GuAddress CHAR(32);
BEGIN
  SELECT gu_address INTO GuAddress FROM k_suppliers WHERE gu_supplier=SupplierId;
  DELETE k_x_duty_resource WHERE nm_resource=SupplierId;
  DELETE k_suppliers WHERE gu_supplier=SupplierId;
  DELETE k_addresses WHERE gu_address=GuAddress;
END k_sp_del_supplier;
GO;