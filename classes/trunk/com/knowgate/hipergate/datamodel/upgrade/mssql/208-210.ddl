CREATE TABLE k_x_portlet_user (
    id_domain   INTEGER       NOT NULL,
    gu_user     CHAR(32)      NOT NULL,
    gu_workarea CHAR(32)      NOT NULL,
    nm_portlet  NVARCHAR(128) NOT NULL,
    nm_page     NVARCHAR(128) NOT NULL,
    nm_zone     NVARCHAR(16)  DEFAULT 'none',
    od_position INTEGER       DEFAULT 1,
    id_state    NVARCHAR(16)  DEFAULT 'NORMAL',
    dt_modified DATETIME      DEFAULT GETDATE(),
    nm_template NVARCHAR(254) NULL,  

    CONSTRAINT pk_x_portlet_user PRIMARY KEY(id_domain,gu_user,gu_workarea,nm_portlet,nm_page,nm_zone)  
)
GO;
UPDATE k_categories SET nm_category='MODEL_superuser' WHERE nm_category='MODEL_poweruser'
GO;
INSERT INTO k_apps (id_app,nm_app) VALUES (21,'Hipermail');
GO;
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SEND','SEND MIME MESSAGES BY SMTP','com.knowgate.scheduler.jobs.MimeSender')
GO;
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_mime_msgs', 1, 2147483647, 1, 1)
GO;
ALTER TABLE k_categories ADD len_size DECIMAL(28) NULL
GO;
ALTER TABLE k_projects ADD dt_scheduled DATETIME NULL
GO;
ALTER TABLE k_duties ADD dt_scheduled DATETIME NULL
GO;
ALTER TABLE k_duties ADD gu_contact CHAR(32) NULL
GO;
ALTER TABLE k_bugs ADD gu_writer CHAR(32) NULL
GO;
ALTER TABLE k_bugs ADD tp_bug VARCHAR(50) NULL
GO;
ALTER TABLE k_bugs ADD dt_since DATETIME NULL
GO;
ALTER TABLE k_bugs ADD tx_bug_info NVARCHAR(1000) NULL
GO;
ALTER TABLE k_bugs ADD nu_times INTEGER NULL
GO;
ALTER TABLE k_products ADD pr_purchase DECIMAL(14,4) NULL
GO;
ALTER TABLE k_cat_labels ADD de_category NVARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD gu_company CHAR(32) NULL
GO;
ALTER TABLE k_pagesets ADD gu_project CHAR(32) NULL
GO;
ALTER TABLE k_lu_job_status ADD tr_ru NVARCHAR(30)  NULL
GO;
ALTER TABLE k_fellows ADD tx_timezone NVARCHAR(16) NULL
GO;
ALTER TABLE k_contacts ADD tx_nickname NVARCHAR(100) NULL
GO;
ALTER TABLE k_contacts ADD tx_pwd NVARCHAR(50) NULL
GO;
ALTER TABLE k_contacts ADD tx_challenge NVARCHAR(100) NULL
GO;
ALTER TABLE k_contacts ADD tx_reply NVARCHAR(100) NULL
GO;
ALTER TABLE k_contacts ADD dt_pwd_expires DATETIME NULL
GO;

CREATE INDEX i1_oportunities ON k_oportunities(gu_workarea)
GO;
CREATE INDEX i2_oportunities ON k_oportunities(gu_writer)
GO;
CREATE INDEX i3_oportunities ON k_oportunities(tl_oportunity)
GO;
CREATE INDEX i4_oportunities ON k_oportunities(dt_modified)
GO;
CREATE INDEX i5_oportunities ON k_oportunities(dt_next_action)
GO;
CREATE INDEX i6_oportunities ON k_oportunities(id_status)
GO;

CREATE PROCEDURE k_sp_get_user_mailroot @GuUser CHAR(32), @GuCategory CHAR(32) OUTPUT AS
  DECLARE @NmDomain VARCHAR(30)
  DECLARE @NickName VARCHAR(32)
  DECLARE @NmCategory VARCHAR(100)

  SET @NickName = NULL
  SET @GuCategory = NULL
  
  SELECT @NickName=u.tx_nickname, @NmDomain=nm_domain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=@GuUser

  IF @NickName IS NOT NULL
    SELECT @GuCategory=gu_category FROM k_categories WHERE nm_category=@NmDomain + '_' + @NickName + '_email'
GO;

CREATE PROCEDURE k_sp_get_user_inbox @GuUser CHAR(32), @GuCategory CHAR(32) OUTPUT AS
  DECLARE @NmDomain VARCHAR(30)
  DECLARE @NickName VARCHAR(32)
  DECLARE @NmCategory VARCHAR(100)

  SET @NickName = NULL
  SET @GuCategory = NULL
  
  SELECT @NickName=u.tx_nickname, @NmDomain=nm_domain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=@GuUser

  IF @NickName IS NOT NULL
    SELECT @GuCategory=gu_category FROM k_categories WHERE nm_category=@NmDomain + '_' + @NickName + '_inbox'
GO;

DROP PROCEDURE k_sp_read_pageset
GO;

CREATE PROCEDURE k_sp_read_pageset @IdPageSet CHAR(32), @IdMicrosite CHAR(32) OUTPUT, @NmMicrosite VARCHAR(100) OUTPUT, @IdWorkArea CHAR(32) OUTPUT, @NmPageSet VARCHAR(100) OUTPUT, @VsStamp VARCHAR(16) OUTPUT, @IdLanguage CHAR(2) OUTPUT, @DtModified DATETIME OUTPUT, @PathData VARCHAR(254) OUTPUT, @IdStatus VARCHAR(30) OUTPUT, @PathMetaData VARCHAR(254) OUTPUT, @TxComments VARCHAR(255) OUTPUT, @GuCompany CHAR(32) OUTPUT, @GuProject CHAR(32) OUTPUT AS
  SELECT @NmMicrosite=m.nm_microsite, @IdMicrosite=m.gu_microsite, @IdWorkArea=p.gu_workarea, @NmPageSet=p.nm_pageset, @VsStamp=p.vs_stamp, @IdLanguage=p.id_language, @DtModified=p.dt_modified, @PathData=p.path_data, @IdStatus=p.id_status, @PathMetaData=m.path_metadata, @TxComments=p.tx_comments,@GuCompany=p.gu_company,@GuProject=p.gu_project FROM k_pagesets p LEFT OUTER JOIN k_microsites m ON p.gu_microsite=m.gu_microsite WHERE p.gu_pageset=@IdPageSet
GO;

DROP VIEW v_cat_tree_labels
GO;

CREATE VIEW v_cat_tree_labels WITH SCHEMABINDING AS
SELECT c.gu_category,t.gu_parent_cat,n.id_language,c.nm_category,n.tr_category,c.gu_owner,c.bo_active,c.dt_created,c.dt_modified,c.nm_icon,c.nm_icon2,n.de_category FROM dbo.k_categories c, dbo.k_cat_labels n, dbo.k_cat_tree t WHERE n.gu_category=c.gu_category AND t.gu_child_cat=c.gu_category
GO;

DROP VIEW v_project_company
GO;

CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,ISNULL(d.tx_name,'')+' '+ISNULL(d.tx_surname,'') AS full_name, p.id_status
FROM k_project_expand e, k_contacts d, k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND d.gu_contact=p.gu_contact)
UNION
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NULL AS full_name, p.id_status
FROM k_project_expand e,
k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND p.gu_contact IS NULL)
GO;

DROP VIEW v_duty_resource
GO;

CREATE VIEW v_duty_resource AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty, u.tx_nickname AS nm_resource
FROM k_projects p, k_users u, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND x.nm_resource=u.gu_user
UNION
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource
FROM k_projects p, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND NOT EXISTS (SELECT gu_user FROM k_users WHERE gu_user=x.nm_resource);

CREATE VIEW v_ldap_users AS
  SELECT
    d.id_domain   AS control_domain_guid,
    d.nm_domain   AS control_domain_name,
    w.nm_workarea AS control_workarea_name,
    w.gu_workarea AS control_workarea_guid,
    u.tx_main_email AS cn,
    u.gu_user     AS uid,
    u.nm_user     AS givenName,
    u.tx_pwd      AS userPassword,
    RTRIM(ISNULL (u.tx_surname1,u.tx_nickname)+N' '+ISNULL (u.tx_surname2,N'')) AS sn,
    RTRIM(LTRIM(ISNULL (u.nm_user,N'')+N' '+ISNULL (u.tx_surname1,u.tx_nickname)+N' '+ISNULL (u.tx_surname2,N''))) AS displayName,
    u.tx_main_email AS mail,
    u.nm_company  AS o,
    NULL AS telephonenumber,
    NULL AS homePhone,
    NULL AS mobile,
    NULL AS postalAddress
  FROM
    k_domains d,
    k_workareas w,
    k_users u
  WHERE
    u.tx_main_email IS NOT NULL  AND
    d.bo_active<>0 AND d.id_domain=w.id_domain AND
    w.bo_active<>0 AND w.gu_workarea=u.gu_workarea AND
    NOT EXISTS (SELECT f.gu_fellow FROM k_fellows f WHERE u.gu_user=f.gu_fellow)
UNION
  SELECT
    d.id_domain   AS control_domain_guid,
    d.nm_domain   AS control_domain_name,
    w.nm_workarea AS control_workarea_name,
    w.gu_workarea AS control_workarea_guid,
    ISNULL (f.tx_email,u.tx_main_email) AS cn,
    f.gu_fellow   AS uid,
    f.tx_name     AS givenName,
    u.tx_pwd      AS userPassword,
    ISNULL (f.tx_surname,u.tx_nickname) AS sn,
    RTRIM(LTRIM(ISNULL (u.nm_user,N'')+N' '+ISNULL (u.tx_surname1,u.tx_surname1)+N' '+ISNULL (u.tx_surname2,N''))) AS displayName,
    ISNULL (f.tx_email,u.tx_main_email) AS mail,
    u.nm_company  AS o,
    f.work_phone  AS telephonenumber,
    f.home_phone  AS homePhone,
    f.mov_phone   AS mobile,
    ISNULL (f.tx_dept,N'')+'|'+ISNULL(f.tx_division,N'')+N'|'+ISNULL(f.tx_location,N'') AS postalAddress
  FROM
    k_domains d,
    k_workareas w,
    k_fellows f,
    k_users u
  WHERE
    (f.tx_email IS NOT NULL OR u.tx_main_email IS NOT NULL) AND
    d.bo_active<>0 AND d.id_domain=w.id_domain AND
    w.bo_active<>0 AND w.gu_workarea=f.gu_workarea AND
    f.gu_fellow=u.gu_user
UNION
  SELECT
    d.id_domain   AS control_domain_guid,
    d.nm_domain   AS control_domain_name,
    w.nm_workarea AS control_workarea_name,
    w.gu_workarea AS control_workarea_guid,
    f.tx_email    AS cn,
    f.gu_fellow   AS uid,
    f.tx_name     AS givenName,
    NULL          AS userPassword,
    ISNULL (f.tx_surname,'(unknown)') AS sn,
    ISNULL (f.tx_surname,f.tx_email) AS displayName,
    f.tx_email    AS mail,
    f.tx_company  AS o,
    f.work_phone  AS telephonenumber,
    f.home_phone  AS homePhone,
    f.mov_phone   AS mobile,
    ISNULL (f.tx_dept,N'')+N'|'+ISNULL(f.tx_division,N'')+N'|'+ISNULL(f.tx_location,N'') AS postalAddress
  FROM
    k_domains d,
    k_workareas w,
    k_fellows f
  WHERE
    f.tx_email IS NOT NULL AND
    d.bo_active<>0 AND d.id_domain=w.id_domain AND
    w.bo_active<>0 AND w.gu_workarea=f.gu_workarea AND
    NOT EXISTS (SELECT u.gu_user FROM k_users u WHERE u.gu_user=f.gu_fellow)
GO;

CREATE VIEW v_ldap_contacts AS
  SELECT
    a.bo_private    AS control_priv,
    d.id_domain     AS control_domain_guid,
    d.nm_domain     AS control_domain_name,
    w.gu_workarea   AS control_workarea_guid,
    w.nm_workarea   AS control_workarea_name,
    u.tx_main_email AS control_owner,
    a.gu_contact    AS control_contact,
    a.tx_email      AS cn,
    a.gu_address    AS uid,
    a.tx_name       AS givenName,
    ISNULL (a.tx_surname,a.tx_email) AS sn,
    a.tx_email      AS mail,
    a.nm_legal      AS o,
    a.work_phone    AS telephonenumber,
    a.fax_phone     AS facsimileTelephoneNumber,
    a.home_phone    AS homePhone,
    a.mov_phone     AS mobile,
    LTRIM(ISNULL(a.tp_street,N'')+N' '+ISNULL(a.nm_street,N'')+N' '+ISNULL(a.nu_street,N'')+N'|'+ISNULL(a.tx_addr1,N'')+N'|'+ISNULL(a.tx_addr2,N'')) AS postalAddress,
    a.mn_city       AS l,
    ISNULL(a.nm_state,a.id_state) AS st,
    a.zipcode       AS postalCode
  FROM
    k_domains d, k_workareas w,
    k_member_address a LEFT OUTER JOIN k_users u ON u.gu_user=a.gu_writer
  WHERE
    d.bo_active<>0 AND d.id_domain=w.id_domain AND d.id_domain=u.id_domain AND w.gu_workarea=a.gu_workarea AND w.bo_active<>0 AND a.tx_email IS NOT NULL
GO;

DROP TRIGGER k_tr_ins_comp_addr
GO;

CREATE TRIGGER k_tr_ins_comp_addr ON k_x_company_addr FOR INSERT AS

  DECLARE @GuCompany     CHAR(32)
  DECLARE @NmLegal       NVARCHAR(70)
  DECLARE @NmCommercial  NVARCHAR(70)
  DECLARE @IdLegal       NVARCHAR(16)
  DECLARE @IdSector      NVARCHAR(16)
  DECLARE @IdStatus      NVARCHAR(30)
  DECLARE @IdRef         NVARCHAR(50)
  DECLARE @TpCompany     NVARCHAR(30)
  DECLARE @NuEmployees   INTEGER
  DECLARE @ImRevenue     FLOAT
  DECLARE @GuSalesMan    CHAR(32)
  DECLARE @TxFranchise   NVARCHAR(100)
  DECLARE @GuGeoZone     CHAR(32)
  DECLARE @DeCompany     NVARCHAR(254)
  
  SELECT @GuCompany=gu_company,@NmLegal=nm_legal,@IdLegal=id_legal,@NmCommercial=nm_commercial,@IdSector=id_sector,@IdStatus=id_status,@IdRef=id_ref,@TpCompany=tp_company,@NuEmployees=nu_employees,@ImRevenue=im_revenue,@GuSalesMan=gu_sales_man,@TxFranchise=tx_franchise,@GuGeoZone=gu_geozone,@DeCompany=de_company
  FROM k_companies k, inserted i WHERE k.gu_company=i.gu_company

  UPDATE k_member_address SET gu_company=@GuCompany,nm_legal=@NmLegal,id_legal=@IdLegal,nm_commercial=@NmCommercial,id_sector=@IdSector,id_ref=@IdRef,id_status=@IdStatus,tp_company=@TpCompany,nu_employees=@NuEmployees,im_revenue=@ImRevenue,gu_sales_man=@GuSalesMan,tx_franchise=@TxFranchise,gu_geozone=@GuGeoZone,tx_comments=@DeCompany
  WHERE gu_address IN (SELECT gu_address FROM inserted)
GO;

DROP TRIGGER k_tr_ins_address
GO;

CREATE TRIGGER k_tr_ins_address ON k_addresses FOR INSERT AS
  DECLARE @AddrId CHAR(32)
  DECLARE @BoActive SMALLINT

  SET @AddrId = NULL

  SELECT @BoActive=bo_active FROM inserted

  IF (@BoActive=1)
    SELECT @AddrId=gu_address FROM k_member_address WHERE gu_address IN (SELECT gu_address FROM inserted)

  IF @AddrId IS NULL
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks)
      SELECT gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_user,CASE LEN(nm_company) WHEN 0 THEN NULL ELSE nm_company END,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,ISNULL(tx_addr1,N'')+NCHAR(10)+ISNULL(tx_addr2,N''),id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks
      FROM inserted
GO;

DROP TRIGGER k_tr_upd_address
GO;

CREATE TRIGGER k_tr_upd_address ON k_addresses FOR UPDATE AS
  DECLARE @AddrId CHAR(32)
  DECLARE @BoActive SMALLINT

  SET @AddrId = NULL

  SELECT @BoActive=bo_active FROM inserted

  SELECT @AddrId=gu_address FROM k_member_address WHERE gu_address IN (SELECT gu_address FROM inserted)

  IF (@BoActive=1)

    IF @AddrId IS NULL

      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks)
                        SELECT  gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_user,CASE LEN(nm_company) WHEN 0 THEN NULL ELSE nm_company END,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,ISNULL(tx_addr1,N'')+NCHAR(10)+ISNULL(tx_addr2,''),id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks
                        FROM inserted
    ELSE

      UPDATE k_member_address SET k_member_address.ix_address=inserted.ix_address,k_member_address.gu_workarea=inserted.gu_workarea,k_member_address.dt_created=inserted.dt_created,k_member_address.dt_modified=inserted.dt_modified,k_member_address.gu_writer=inserted.gu_user,k_member_address.nm_legal=CASE LEN(inserted.nm_company) WHEN 0 THEN NULL ELSE inserted.nm_company END,k_member_address.tp_location=inserted.tp_location,k_member_address.tp_street=inserted.tp_street,k_member_address.nm_street=inserted.nm_street,k_member_address.nu_street=inserted.nu_street,k_member_address.tx_addr1=inserted.tx_addr1,k_member_address.tx_addr2=inserted.tx_addr2,k_member_address.full_addr=ISNULL(inserted.tx_addr1,N'')+NCHAR(10)+ISNULL(inserted.tx_addr2,N''),k_member_address.id_country=inserted.id_country,k_member_address.nm_country=inserted.nm_country,k_member_address.id_state=inserted.id_state,k_member_address.nm_state=inserted.nm_state,k_member_address.mn_city=inserted.mn_city,k_member_address.zipcode=inserted.zipcode,k_member_address.work_phone=inserted.work_phone,k_member_address.direct_phone=inserted.direct_phone,k_member_address.home_phone=inserted.home_phone,k_member_address.mov_phone=inserted.mov_phone,k_member_address.fax_phone=inserted.fax_phone,k_member_address.other_phone=inserted.other_phone,k_member_address.po_box=inserted.po_box,k_member_address.tx_email=inserted.tx_email,k_member_address.url_addr=inserted.url_addr,k_member_address.contact_person=inserted.contact_person,k_member_address.tx_salutation=inserted.tx_salutation,k_member_address.tx_remarks=inserted.tx_remarks
      FROM k_member_address INNER JOIN inserted ON (k_member_address.gu_address = inserted.gu_address)

  ELSE

    DELETE FROM k_member_address WHERE gu_address IN (SELECT gu_address FROM inserted)
GO;


DROP TRIGGER k_tr_ins_cont_addr
GO;

REATE TRIGGER k_tr_ins_cont_addr ON k_x_contact_addr FOR INSERT AS

  DECLARE @GuCompany     CHAR(32)
  DECLARE @GuContact     CHAR(32)
  DECLARE @GuWorkArea    CHAR(32)
  DECLARE @TxName        NVARCHAR(100)
  DECLARE @TxSurname     NVARCHAR(100)
  DECLARE @DeTitle       NVARCHAR(50)
  DECLARE @TrTitle       NVARCHAR(50)
  DECLARE @DtBirth       DATETIME
  DECLARE @SnPassport    NVARCHAR(16)
  DECLARE @IdGender      CHAR(1)
  DECLARE @NyAge         SMALLINT   
  DECLARE @TxDept        NVARCHAR(70)
  DECLARE @TxDivision    NVARCHAR(70)
  DECLARE @TxComments    NVARCHAR(254)

  SELECT @GuContact=c.gu_contact,@GuCompany=c.gu_company,@GuWorkArea=c.gu_workarea,@TxName=CASE LEN(c.tx_name) WHEN 0 THEN NULL ELSE c.tx_name END,@TxSurname=CASE LEN(c.tx_surname) WHEN 0 THEN NULL ELSE c.tx_surname END,@DeTitle=c.de_title,@DtBirth=c.dt_birth,@SnPassport=c.sn_passport,@IdGender=c.id_gender,@NyAge=c.ny_age,@TxDept=c.tx_dept,@TxDivision=c.tx_division,@TxComments=c.tx_comments
  FROM k_contacts c, inserted i WHERE c.gu_contact=i.gu_contact

  SET @TrTitle = NULL
  
  IF @DeTitle IS NOT NULL
    SELECT @TrTitle=tr_es FROM k_contacts_lookup WHERE gu_owner=@GuWorkArea AND id_section='de_title' AND vl_lookup=@DeTitle

  UPDATE k_member_address SET gu_contact=@GuContact,gu_company=@GuCompany,tx_name=@TxName,tx_surname=@TxSurname,de_title=@DeTitle,tr_title=@TrTitle,dt_birth=@DtBirth,sn_passport=@SnPassport,id_gender=@IdGender,ny_age=@NyAge,tx_dept=@TxDept,tx_division=@TxDivision,tx_comments=@TxComments
  WHERE gu_address IN (SELECT gu_address FROM inserted)
GO;



DROP PROCEDURE k_sp_del_project
GO;

CREATE PROCEDURE k_sp_del_project @ProjId CHAR(32) AS
  DECLARE @chldid CHAR(32)
  DECLARE childs CURSOR LOCAL FAST_FORWARD FOR SELECT gu_project FROM k_projects WHERE id_parent=@ProjId
  
  /* Borrar primero recursivamente los proyectos hijos */
  OPEN childs
    FETCH NEXT FROM childs INTO @chldid
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_project @chldid
        FETCH NEXT FROM childs INTO @chldid
      END
  CLOSE childs
  
  DELETE k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId)
  DELETE k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId)
  DELETE k_duties WHERE gu_project=@ProjId

  DELETE k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=@ProjId)
  DELETE k_bugs WHERE gu_project=@ProjId

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=@ProjId
  
  DELETE k_project_expand WHERE gu_project=@ProjId
  DELETE k_projects WHERE gu_project=@ProjId
GO;

DROP PROCEDURE k_sp_del_company
GO;

CREATE PROCEDURE k_sp_del_company @CompanyId CHAR(32) AS

  DECLARE @GuWorkArea CHAR(32)

  DELETE k_companies_recent WHERE gu_company=@CompanyId

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

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=@CompanyId

  DELETE k_x_company_prods WHERE gu_company=@CompanyId
  DELETE k_companies_attrs WHERE gu_object=@CompanyId
  DELETE k_companies WHERE gu_company=@CompanyId
GO;

TRUNCATE TABLE k_member_address
GO;
INSERT INTO k_member_address SELECT gu_address,ix_address,gu_workarea,gu_company,gu_contact,dt_created,dt_modified,bo_private,gu_writer,tx_name,tx_surname,nm_commercial,nm_legal,id_legal,id_sector,de_title,tr_title,id_status,id_ref,dt_birth,sn_passport,tx_comments,id_gender,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,ny_age,tx_dept,tx_division,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks FROM v_member_address
GO;

CREATE PROCEDURE k_sp_get_user_mailroot @GuUser CHAR(32), @GuCategory CHAR(32) OUTPUT AS
  DECLARE @NmDomain VARCHAR(30)
  DECLARE @NickName VARCHAR(32)
  DECLARE @NmCategory VARCHAR(100)

  SET @NickName = NULL
  SET @GuCategory = NULL
  
  SELECT @NickName=u.tx_nickname, @NmDomain=nm_domain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=@GuUser

  IF @NickName IS NOT NULL
    SELECT @GuCategory=gu_category FROM k_categories WHERE nm_category=@NmDomain + '_' + @NickName + '_email'
GO;

CREATE PROCEDURE k_sp_get_user_mailfolder @GuUser CHAR(32), @NmFolder VARCHAR(100), @GuCategory CHAR(32) OUTPUT AS
  DECLARE @NmDomain VARCHAR(30)
  DECLARE @NickName VARCHAR(32)
  DECLARE @NmCategory VARCHAR(100)
  DECLARE @GuMailRoot CHAR(32)

  SET @NickName = NULL
  SET @GuCategory = NULL
  
  SELECT @NickName=u.tx_nickname, @NmDomain=nm_domain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=@GuUser

  IF @NickName IS NOT NULL
    BEGIN
      EXECUTE k_sp_get_user_mailroot @GuUser, @GuMailRoot
      IF @GuMailRoot IS NOT NULL
        SELECT @GuCategory=c.gu_category FROM k_categories WHERE c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=@GuMailRoot AND (c.nm_category=@NmDomain + '_' + @NickName + '_' + @NmFolder OR c.nm_category=@NmFolder)
    END
GO;
