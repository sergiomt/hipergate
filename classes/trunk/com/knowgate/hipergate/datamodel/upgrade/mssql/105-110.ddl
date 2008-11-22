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

CREATE PROCEDURE k_sp_del_category @IdCategory CHAR(32) AS
  /* Borrar una categoria  */

  DELETE FROM k_cat_expand WHERE gu_rootcat=@IdCategory
  DELETE FROM k_cat_expand WHERE gu_parent_cat=@IdCategory
  DELETE FROM k_cat_expand WHERE gu_category=@IdCategory
  DELETE FROM k_cat_tree WHERE gu_child_cat=@IdCategory
  DELETE FROM k_cat_root WHERE gu_category=@IdCategory
  DELETE FROM k_cat_labels WHERE gu_category=@IdCategory
  DELETE FROM k_x_cat_user_acl WHERE gu_category=@IdCategory
  DELETE FROM k_x_cat_group_acl WHERE gu_category=@IdCategory
  DELETE FROM k_x_cat_objs WHERE gu_category=@IdCategory  
  DELETE FROM k_categories WHERE gu_category=@IdCategory
GO;

CREATE PROCEDURE k_sp_del_category_r @IdCategory CHAR(32) AS
  /* Borrar en cascada una categoria y todos sus registros asociados.
     Este procedimiento borra una categoria y todas sus hijas */
  DECLARE @IdChild CHAR(32)
  DECLARE childs CURSOR LOCAL STATIC FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory
  OPEN childs
    FETCH NEXT FROM childs INTO @IdChild
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_category_r @IdChild
        FETCH NEXT FROM childs INTO @IdChild
      END
  CLOSE childs
  DEALLOCATE childs
  EXECUTE k_sp_del_category @IdCategory
GO;

DROP PROCEDURE k_sp_del_contact
GO;

CREATE PROCEDURE k_sp_del_contact @ContactId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  SELECT @GuWorkArea=gu_workarea FROM k_contacts WHERE gu_contact=@ContactId

  /* Borrar primero las direcciones asociadas al contacto */
  SELECT gu_address INTO #k_tmp_del_addr FROM k_x_contact_addr WHERE gu_contact=@ContactId
  DELETE k_x_contact_addr WHERE gu_contact=@ContactId
  DELETE k_addresses WHERE gu_address IN (SELECT gu_address FROM #k_tmp_del_addr)
  DROP TABLE #k_tmp_del_addr

  /* Borrar primero las cuentas bancarias asociadas al contacto */
  SELECT nu_bank_acc INTO #k_tmp_del_bank FROM k_x_contact_bank WHERE gu_contact=@ContactId
  DELETE k_x_contact_bank WHERE gu_contact=@ContactId
  DELETE k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM #k_tmp_del_bank) AND gu_workarea=@GuWorkArea
  DROP TABLE #k_tmp_del_bank

  /* Los productos que contienen la referencia a los ficheros adjuntos no se borran desde aquí,
     hay que llamar al método Java de borrado de Product para eliminar también los ficheros físicos,
     de este modo la foreign key de la base de datos actua como protección para que no se queden ficheros basura */

  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=@ContactId)
  DELETE k_oportunities WHERE gu_contact=@ContactId

  DELETE k_x_cat_objs WHERE gu_object=@ContactId AND id_class=90

  DELETE k_contacts_attrs WHERE gu_object=@ContactId
  DELETE k_contact_notes WHERE gu_contact=@ContactId
  DELETE k_contacts WHERE gu_contact=@ContactId
GO;

DROP PROCEDURE k_sp_del_company
GO;

CREATE PROCEDURE k_sp_del_company @CompanyId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  SELECT @GuWorkArea=gu_workarea FROM k_companies WHERE gu_company=@CompanyId

  /* Borrar las direcciones de la compañia */
  SELECT gu_address INTO #k_tmp_del_addr FROM k_x_company_addr WHERE gu_company=@CompanyId
  DELETE k_x_company_addr WHERE gu_company=@CompanyId
  DELETE k_addresses WHERE gu_address IN (SELECT gu_address FROM #k_tmp_del_addr)
  DROP TABLE #k_tmp_del_addr

  /* Borrar primero las cuentas bancarias asociadas a la compañía */
  SELECT nu_bank_acc INTO #k_tmp_del_bank FROM k_x_company_bank WHERE gu_company=@CompanyId
  DELETE k_x_company_bank WHERE gu_company=@CompanyId
  DELETE k_bank_accounts WHERE nu_bank_acc IN (SELECT nu_bank_acc FROM #k_tmp_del_bank) AND gu_workarea=@GuWorkArea
  DROP TABLE #k_tmp_del_bank

  /* Borrar las oportunidades */
  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=@CompanyId)
  DELETE k_oportunities WHERE gu_company=@CompanyId

  /* Borrar el enlace con categorías */
  DELETE k_x_cat_objs WHERE gu_object=@CompanyId AND id_class=91

  /* Borrar los atributos extendidos */
  DELETE k_companies_attrs WHERE gu_object=@CompanyId
  DELETE k_companies WHERE gu_company=@CompanyId
GO;

DROP PROCEDURE k_sp_read_pageset 
GO;

CREATE PROCEDURE k_sp_read_pageset @IdPageSet CHAR(32), @IdMicrosite CHAR(32) OUTPUT, @NmMicrosite VARCHAR(100) OUTPUT, @IdWorkArea CHAR(32) OUTPUT, @NmPageSet VARCHAR(100) OUTPUT, @VsStamp VARCHAR(16) OUTPUT, @IdLanguage CHAR(2) OUTPUT, @DtModified DATETIME OUTPUT, @PathData VARCHAR(254) OUTPUT, @IdStatus VARCHAR(30) OUTPUT, @PathMetaData VARCHAR(254) OUTPUT, @TxComments VARCHAR(255) OUTPUT AS
  SELECT @NmMicrosite=m.nm_microsite, @IdMicrosite=m.gu_microsite, @IdWorkArea=p.gu_workarea, @NmPageSet=p.nm_pageset, @VsStamp=p.vs_stamp, @IdLanguage=p.id_language, @DtModified=p.dt_modified, @PathData=p.path_data, @IdStatus=p.id_status, @PathMetaData=m.path_metadata, @TxComments=p.tx_comments FROM k_pagesets p LEFT OUTER JOIN k_microsites m ON p.gu_microsite=m.gu_microsite WHERE p.gu_pageset=@IdPageSet
GO;