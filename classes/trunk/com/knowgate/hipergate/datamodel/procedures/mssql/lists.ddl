ALTER TABLE k_member_address DROP CONSTRAINT f1_member_address
GO;
ALTER TABLE k_member_address ADD CONSTRAINT f1_member_address FOREIGN KEY(gu_address) REFERENCES k_addresses(gu_address) ON DELETE CASCADE
GO;
ALTER TABLE k_member_address DROP CONSTRAINT f3_member_address
GO;
ALTER TABLE k_member_address ADD CONSTRAINT f3_member_address FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company) ON DELETE SET NULL
GO;
ALTER TABLE k_member_address DROP CONSTRAINT f4_member_address
GO;
ALTER TABLE k_member_address ADD CONSTRAINT f4_member_address FOREIGN KEY(gu_contact) REFERENCES k_contacts(gu_contact) ON DELETE SET NULL
GO;

CREATE PROCEDURE k_sp_del_list @ListId CHAR(32) AS   
  DECLARE @tp SMALLINT
  DECLARE @wa CHAR(32)
  DECLARE @bk CHAR(32)
    
  SELECT @tp=tp_list, @wa=gu_workarea FROM k_lists WHERE gu_list=@ListId

  SET @bk = NULL
  SELECT @bk=gu_list FROM k_lists WHERE gu_workarea=@wa AND gu_query=@ListId AND tp_list=4

  IF @bk IS NOT NULL
    BEGIN
      DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=@bk) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@bk)
      DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=@bk) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@bk)
      DELETE k_x_list_members WHERE gu_list=@bk
      DELETE k_x_campaign_lists WHERE gu_list=@bk
      DELETE k_x_adhoc_mailing_list WHERE gu_list=@bk
      DELETE k_x_pageset_list WHERE gu_list=@bk
      DELETE k_lists WHERE gu_list=@bk
    END
    
  DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_x_list_members WHERE gu_list=@ListId

  DELETE k_x_campaign_lists WHERE gu_list=@ListId

  DELETE k_x_adhoc_mailing_list WHERE gu_list=@ListId

  DELETE k_x_pageset_list WHERE gu_list=@ListId
  
  DELETE k_x_cat_objs WHERE gu_object=@ListId
  UPDATE k_activities SET gu_list=NULL WHERE gu_list=@ListId
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=@ListId

  DELETE k_lists WHERE gu_list=@ListId
GO;

CREATE PROCEDURE k_sp_email_blocked @GuList CHAR(32), @TxEmail VARCHAR(100), @BoBlocked SMALLINT OUTPUT AS
  DECLARE @BlackList CHAR(32)

  SET @BoBlocked = 0
  SET @BlackList = NULL
  
  SELECT @BlackList=gu_list FROM k_lists WHERE gu_query=@GuList AND tp_list=4
  
  IF @BlackList IS NOT NULL
    SELECT TOP 1 @BoBlocked=1 FROM k_x_list_members WHERE gu_list=@BlackList AND tx_email=@TxEmail
GO;
  
CREATE PROCEDURE k_sp_contact_blocked @GuList CHAR(32), @GuContact CHAR(32), @BoBlocked SMALLINT OUTPUT AS
  DECLARE @BlackList CHAR(32)

  SET @BoBlocked = 0
  SET @BlackList = NULL
  
  SELECT @BlackList=gu_list FROM k_lists WHERE gu_query=@GuList AND tp_list=4
  
  IF @BlackList IS NOT NULL
    SELECT TOP 1 @BoBlocked=1 FROM k_x_list_members WHERE gu_list=@BlackList AND gu_contact=@GuContact
GO;

CREATE PROCEDURE k_sp_company_blocked @GuList CHAR(32), @GuCompany CHAR(32), @BoBlocked SMALLINT OUTPUT AS
  DECLARE @BlackList CHAR(32)

  SET @BoBlocked = 0
  SET @BlackList = NULL
  
  SELECT @BlackList=gu_list FROM k_lists WHERE gu_query=@GuList AND tp_list=4
  
  IF @BlackList IS NOT NULL
    SELECT @BoBlocked=1 FROM k_x_list_members WHERE gu_list=@BlackList AND gu_company=@GuCompany
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

      UPDATE k_member_address SET k_member_address.ix_address=inserted.ix_address,k_member_address.gu_workarea=inserted.gu_workarea,
             k_member_address.dt_created=inserted.dt_created,k_member_address.dt_modified=inserted.dt_modified,k_member_address.gu_writer=inserted.gu_user,
             k_member_address.nm_legal=CASE LEN(inserted.nm_company) WHEN 0 THEN NULL ELSE inserted.nm_company END,k_member_address.tp_location=inserted.tp_location,
             k_member_address.tp_street=inserted.tp_street,k_member_address.nm_street=inserted.nm_street,k_member_address.nu_street=inserted.nu_street,
             k_member_address.tx_addr1=inserted.tx_addr1,k_member_address.tx_addr2=inserted.tx_addr2,k_member_address.full_addr=ISNULL(inserted.tx_addr1,N'')+NCHAR(10)+ISNULL(inserted.tx_addr2,N''),
             k_member_address.id_country=inserted.id_country,k_member_address.nm_country=inserted.nm_country,k_member_address.id_state=inserted.id_state,k_member_address.nm_state=inserted.nm_state,
             k_member_address.mn_city=inserted.mn_city,k_member_address.zipcode=inserted.zipcode,k_member_address.work_phone=inserted.work_phone,k_member_address.direct_phone=inserted.direct_phone,
             k_member_address.home_phone=inserted.home_phone,k_member_address.mov_phone=inserted.mov_phone,k_member_address.fax_phone=inserted.fax_phone,
             k_member_address.other_phone=inserted.other_phone,k_member_address.po_box=inserted.po_box,k_member_address.tx_email=inserted.tx_email,
             k_member_address.url_addr=inserted.url_addr,k_member_address.contact_person=inserted.contact_person,k_member_address.tx_salutation=inserted.tx_salutation,
             k_member_address.tx_remarks=inserted.tx_remarks
      FROM k_member_address INNER JOIN inserted ON (k_member_address.gu_address = inserted.gu_address)

  ELSE

    DELETE FROM k_member_address WHERE gu_address IN (SELECT gu_address FROM inserted)
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
  
  SELECT @GuCompany=k.gu_company,@NmLegal=k.nm_legal,@IdLegal=k.id_legal,@NmCommercial=k.nm_commercial,@IdSector=k.id_sector,@IdStatus=k.id_status,@IdRef=k.id_ref,@TpCompany=k.tp_company,@NuEmployees=k.nu_employees,@ImRevenue=k.im_revenue,@GuSalesMan=k.gu_sales_man,@TxFranchise=k.tx_franchise,@GuGeoZone=k.gu_geozone,@DeCompany=k.de_company
  FROM k_companies k, inserted i WHERE k.gu_company=i.gu_company

  UPDATE k_member_address SET gu_company=@GuCompany,nm_legal=@NmLegal,id_legal=@IdLegal,nm_commercial=@NmCommercial,id_sector=@IdSector,id_ref=@IdRef,id_status=@IdStatus,tp_company=@TpCompany,nu_employees=@NuEmployees,im_revenue=@ImRevenue,gu_sales_man=@GuSalesMan,tx_franchise=@TxFranchise,gu_geozone=@GuGeoZone,tx_comments=@DeCompany
  WHERE gu_address IN (SELECT gu_address FROM inserted)
GO;

CREATE TRIGGER k_tr_ins_cont_addr ON k_x_contact_addr FOR INSERT AS

  DECLARE @GuCompany     CHAR(32)
  DECLARE @GuContact     CHAR(32)
  DECLARE @GuWorkArea    CHAR(32)
  DECLARE @TxName        NVARCHAR(100)
  DECLARE @TxSurname     NVARCHAR(100)
  DECLARE @DeTitle       NVARCHAR(70)
  DECLARE @TrTitle       NVARCHAR(50)
  DECLARE @DtBirth       DATETIME
  DECLARE @SnPassport    NVARCHAR(16)
  DECLARE @IdGender      CHAR(1)
  DECLARE @NyAge         SMALLINT   
  DECLARE @IdNationality CHAR(3)
  DECLARE @TxDept        NVARCHAR(70)
  DECLARE @TxDivision    NVARCHAR(70)
  DECLARE @TxComments    NVARCHAR(254)
  DECLARE @UrlLinkedIn   VARCHAR(254)
  DECLARE @UrlFacebook   VARCHAR(254)
  DECLARE @UrlTwitter    VARCHAR(254)

  SELECT @GuContact=c.gu_contact,@GuCompany=c.gu_company,@GuWorkArea=c.gu_workarea,
  @TxName=CASE LEN(c.tx_name) WHEN 0 THEN NULL ELSE c.tx_name END,@TxSurname=CASE LEN(c.tx_surname) WHEN 0 THEN NULL ELSE c.tx_surname END,
  @DeTitle=c.de_title,@DtBirth=c.dt_birth,@SnPassport=c.sn_passport,@IdGender=c.id_gender,@NyAge=c.ny_age,@IdNationality=c.id_nationality,
  @TxDept=c.tx_dept,@TxDivision=c.tx_division,@UrlLinkedIn=c.url_linkedin,@UrlFacebook=c.url_facebook,@UrlTwitter=c.url_twitter,
  @TxComments=c.tx_comments
  FROM k_contacts c, inserted i WHERE c.gu_contact=i.gu_contact

  SET @TrTitle = NULL
  
  IF @DeTitle IS NOT NULL
    SELECT @TrTitle=tr_es FROM k_contacts_lookup WHERE gu_owner=@GuWorkArea AND id_section='de_title' AND vl_lookup=@DeTitle

  UPDATE k_member_address SET gu_contact=@GuContact,gu_company=@GuCompany,tx_name=@TxName,tx_surname=@TxSurname,de_title=@DeTitle,tr_title=@TrTitle,
                              dt_birth=@DtBirth,sn_passport=@SnPassport,id_gender=@IdGender,ny_age=@NyAge,id_nationality=@IdNationality,
                              tx_dept=@TxDept,tx_division=@TxDivision,url_linkedin=@UrlLinkedIn,url_facebook=@UrlFacebook,url_twitter=@UrlTwitter,
                              tx_comments=@TxComments
  WHERE gu_address IN (SELECT gu_address FROM inserted)
GO;

CREATE TRIGGER k_tr_upd_comp ON k_companies FOR UPDATE AS

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
  
  SELECT @NmLegal=k.nm_legal,@IdLegal=k.id_legal,@NmCommercial=k.nm_commercial,@IdSector=k.id_sector,@IdStatus=k.id_status,@IdRef=k.id_ref,@TpCompany=k.tp_company,
         @NuEmployees=k.nu_employees,@ImRevenue=k.im_revenue,@GuSalesMan=k.gu_sales_man,@TxFranchise=k.tx_franchise,@GuGeoZone=k.gu_geozone,@DeCompany=k.de_company
  FROM k_companies k, inserted i WHERE k.gu_company=i.gu_company

  UPDATE k_member_address SET nm_legal=@NmLegal,id_legal=@IdLegal,nm_commercial=@NmCommercial,id_sector=@IdSector,id_ref=@IdRef,id_status=@IdStatus,tp_company=@TpCompany,nu_employees=@NuEmployees,im_revenue=@ImRevenue,gu_sales_man=@GuSalesMan,tx_franchise=@TxFranchise,gu_geozone=@GuGeoZone,tx_comments=@DeCompany
  WHERE gu_company IN (SELECT gu_company FROM inserted)
GO;

CREATE TRIGGER k_tr_upd_cont ON k_contacts FOR UPDATE AS

  DECLARE @GuCompany     CHAR(32)
  DECLARE @GuWorkArea    CHAR(32)
  DECLARE @TxName        NVARCHAR(100)
  DECLARE @TxSurname     NVARCHAR(100)
  DECLARE @DeTitle       NVARCHAR(70)
  DECLARE @TrTitle       NVARCHAR(50)
  DECLARE @DtBirth       DATETIME
  DECLARE @SnPassport    NVARCHAR(16)
  DECLARE @IdGender      CHAR(1)
  DECLARE @NyAge         SMALLINT
  DECLARE @IdNationality CHAR(3)
  DECLARE @TxDept        NVARCHAR(70)
  DECLARE @TxDivision    NVARCHAR(70)
  DECLARE @TxComments    NVARCHAR(254)
  DECLARE @UrlLinkedIn   VARCHAR(254)
  DECLARE @UrlFacebook   VARCHAR(254)
  DECLARE @UrlTwitter    VARCHAR(254)

  SELECT @GuCompany=c.gu_company,@GuWorkArea=c.gu_workarea,@TxName=CASE LEN(c.tx_name) WHEN 0 THEN NULL ELSE c.tx_name END,@TxSurname=CASE LEN(c.tx_surname) WHEN 0 THEN NULL ELSE c.tx_surname END,
         @DeTitle=c.de_title,@DtBirth=c.dt_birth,@SnPassport=c.sn_passport,@IdGender=c.id_gender,@NyAge=c.ny_age,@IdNationality=c.id_nationality,@TxDept=c.tx_dept,@TxDivision=c.tx_division,
         @UrlLinkedIn=c.url_linkedin,@UrlFacebook=c.url_facebook,@UrlTwitter=c.url_twitter,@TxComments=c.tx_comments
  FROM k_contacts c, inserted i WHERE c.gu_contact=i.gu_contact

  SET @TrTitle = NULL

  IF @DeTitle IS NOT NULL
    SELECT @TrTitle=tr_es FROM k_contacts_lookup WHERE gu_owner=@GuWorkArea AND id_section='de_title' AND vl_lookup=@DeTitle

  UPDATE k_member_address SET gu_company=@GuCompany,tx_name=@TxName,tx_surname=@TxSurname,de_title=@DeTitle,tr_title=@TrTitle,dt_birth=@DtBirth,sn_passport=@SnPassport,id_gender=@IdGender,
                              ny_age=@NyAge,id_nationality=@IdNationality,tx_dept=@TxDept,tx_division=@TxDivision,tx_comments=@TxComments,url_linkedin=@UrlLinkedIn,url_facebook=@UrlFacebook,url_twitter=@UrlTwitter
  WHERE gu_contact IN (SELECT gu_contact FROM inserted)
GO;

CREATE PROCEDURE k_sp_del_duplicates @GuList CHAR(32), @Deleted INTEGER OUTPUT AS
  
  DECLARE @TxEMail VARCHAR(100)
  DECLARE @TmpMail VARCHAR(100)  
  DECLARE Members CURSOR FOR SELECT tx_email FROM k_x_list_members WHERE gu_list = @GuList

  CREATE TABLE #k_temp_list_emails (tx_email VARCHAR(100) CONSTRAINT pk_temp_list_emails PRIMARY KEY)  
  INSERT INTO k_temp_list_emails SELECT DISTINCT(tx_email) FROM k_x_list_members WHERE gu_list=@GuList
  SET @Deleted = 0
  OPEN Members
  FETCH NEXT FROM Members INTO @TxEMail
  WHILE (@@FETCH_STATUS<>-1)
  BEGIN
    SET @TmpMail = NULL
    DELETE FROM k_temp_list_emails WHERE tx_email=@TxEMail OUTPUT DELETED.tx_email INTO @TmpMail
    IF @TmpMail IS NULL THEN
      BEGIN
        SET @Deleted = @Deleted + 1
        DELETE FROM k_x_list_members WHERE CURRENT OF members
      END
    FETCH NEXT FROM Members INTO @TxEMail
  END
  CLOSE Members  
  DEALLOCATE Members
  DROP TABLE k_temp_list_emails
GO;
