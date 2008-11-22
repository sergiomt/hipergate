CREATE TABLE k_version
(
vs_stamp VARCHAR(16) NOT NULL,

CONSTRAINT pk_version PRIMARY KEY (vs_stamp)
)
GO;

INSERT INTO k_version VALUES ('1.1.0')
GO;

DROP PROCEDURE k_sp_del_category_r
GO;

DROP PROCEDURE k_sp_del_category
GO;

CREATE PROCEDURE k_sp_del_category (IdCategory CHAR) IS
  /* Borrar una categoria  */
BEGIN

  DELETE FROM k_cat_expand WHERE gu_rootcat=IdCategory;
  DELETE FROM k_cat_expand WHERE gu_parent_cat=IdCategory;
  DELETE FROM k_cat_expand WHERE gu_category=IdCategory;
  DELETE FROM k_cat_tree WHERE gu_child_cat=IdCategory;
  DELETE FROM k_cat_root WHERE gu_category=IdCategory;
  DELETE FROM k_cat_labels WHERE gu_category=IdCategory;
  DELETE FROM k_x_cat_user_acl WHERE gu_category=IdCategory;
  DELETE FROM k_x_cat_group_acl WHERE gu_category=IdCategory;
  DELETE FROM k_x_cat_objs WHERE gu_category=IdCategory;
  DELETE FROM k_categories WHERE gu_category=IdCategory;

END k_sp_del_category ;
GO;

CREATE PROCEDURE k_sp_del_category_r (IdCategory CHAR) IS
  /* Borrar en cascada una categoria y todos sus registros asociados.
     Este procedimiento borra una categoria y todas sus hijas */
  IdChild CHAR(32);
  CURSOR childs(id CHAR) IS SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=id;
BEGIN
  OPEN childs(IdCategory);
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN childs%NOTFOUND;
      k_sp_del_category_r (IdChild);
    END LOOP;
  CLOSE childs;

  k_sp_del_category (IdCategory);

END k_sp_del_category_r;
GO;

DROP PROCEDURE k_sp_del_contact
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_contact (ContactId CHAR) IS
  TYPE GUIDS IS TABLE OF k_addresses.gu_address%TYPE;
  TYPE BANKS IS TABLE OF k_bank_accounts.nu_bank_acc%TYPE;

  k_tmp_del_addr GUIDS := GUIDS();
  k_tmp_del_bank BANKS := BANKS();

  GuWorkArea CHAR(32);

BEGIN

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

  /* Borrar el enlace con categorías */
  DELETE k_x_cat_objs WHERE gu_object=CompanyId AND id_class=91;

  /* Borrar los atributos extendidos */
  DELETE k_companies_attrs WHERE gu_object=CompanyId;
  DELETE k_companies WHERE gu_company=CompanyId;
END k_sp_del_company;
GO;

CREATE OR REPLACE PROCEDURE k_sp_read_pageset (IdPageSet CHAR, IdMicrosite OUT CHAR, NmMicrosite OUT VARCHAR2, IdWorkArea OUT CHAR, NmPageSet OUT VARCHAR2, VsStamp OUT VARCHAR2, IdLanguage OUT CHAR, DtModified OUT DATE, PathData OUT VARCHAR2, IdStatus OUT VARCHAR2, PathMetaData OUT VARCHAR2, TxComments OUT VARCHAR2) IS
BEGIN
  SELECT m.nm_microsite,m.gu_microsite,p.gu_workarea,p.nm_pageset,p.vs_stamp,p.id_language,p.dt_modified,p.path_data,p.id_status,m.path_metadata,p.tx_comments INTO NmMicrosite,IdMicrosite,IdWorkArea,NmPageSet,VsStamp,IdLanguage,DtModified,PathData,IdStatus,PathMetaData,TxComments FROM k_pagesets p, k_microsites m WHERE p.gu_pageset=IdPageSet AND p.gu_microsite(+)=m.gu_microsite;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NmMicrosite:=NULL;
    IdMicrosite:=NULL;
    IdWorkArea :=NULL;
    NmPageSet  :=NULL;
    DtModified :=NULL;
END k_sp_read_pageset;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_fellow (FellowId CHAR) IS
  MeetingId CHAR(32);
  CURSOR meetings(id CHAR) IS SELECT gu_meeting FROM k_x_meeting_fellow WHERE gu_fellow=id;
BEGIN
  OPEN meetings(FellowId);
    LOOP
      FETCH meetings INTO MeetingId;
      EXIT WHEN meetings%NOTFOUND;
      k_sp_del_meeting (MeetingId);
    END LOOP;
  CLOSE meetings;

  DELETE k_fellows_attach WHERE gu_fellow=FellowId;
  DELETE k_fellows WHERE gu_fellow=FellowId;
END k_sp_del_fellow;
GO;
