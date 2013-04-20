/* Indexed view can ONLY be created with the following database parameters */
SET NUMERIC_ROUNDABORT OFF;

SET ANSI_PADDING,ANSI_WARNINGS,CONCAT_NULL_YIELDS_NULL,ARITHABORT,QUOTED_IDENTIFIER,ANSI_NULLS ON;

CREATE VIEW v_active_company_address WITH SCHEMABINDING AS
SELECT x.gu_company,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,
a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,
a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,
a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,
a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks
FROM dbo.k_addresses a, dbo.k_x_company_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
;

CREATE UNIQUE CLUSTERED INDEX i1_active_company_address ON v_active_company_address(gu_company,gu_address);

CREATE INDEX i2_active_company_address ON v_active_company_address(gu_workarea);

CREATE VIEW v_company_address WITH SCHEMABINDING AS
SELECT c.gu_workarea,c.gu_company,c.nm_legal,c.nm_commercial,c.dt_modified,c.id_legal,c.id_ref,
c.id_sector,c.id_status,c.tp_company,c.de_company,b.gu_address,b.ix_address,b.tp_location,
b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,
ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,
b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,
b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,
b.tx_email,b.url_addr,b.contact_person,b.id_ref AS id_addrref,b.tx_remarks,c.bo_restricted,
c.gu_geozone,c.gu_sales_man,c.tx_franchise,c.id_batch
FROM dbo.k_companies c
LEFT OUTER JOIN dbo.v_active_company_address AS b ON c.gu_company=b.gu_company
;

CREATE VIEW v_contact_titles WITH SCHEMABINDING AS
SELECT vl_lookup,gu_owner,tr_es,tr_en FROM dbo.k_contacts_lookup WHERE id_section='de_title'
;

CREATE UNIQUE CLUSTERED INDEX i1_contact_titles ON v_contact_titles(gu_owner,vl_lookup);

CREATE VIEW v_active_contact_address WITH SCHEMABINDING AS
SELECT x.gu_contact,a.gu_address,a.ix_address,a.gu_workarea,a.dt_created,a.bo_active,a.dt_modified,
a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,
a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,
a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.url_addr,a.coord_x,a.coord_y,
a.contact_person,a.tx_salutation,a.tx_remarks
FROM dbo.k_addresses a, dbo.k_x_contact_addr x WHERE a.gu_address=x.gu_address AND a.bo_active<>0
;

CREATE UNIQUE CLUSTERED INDEX i1_active_contact_address ON v_active_contact_address(gu_contact,gu_address);

CREATE VIEW v_contact_company WITH SCHEMABINDING AS
SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,y.gu_company,y.nm_legal,
y.id_sector,y.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,
c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,
c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM dbo.k_contacts c, dbo.k_companies y WHERE c.gu_company=y.gu_company
;

CREATE UNIQUE CLUSTERED INDEX i1_contact_company ON v_contact_company(gu_contact);

CREATE VIEW v_contact_company_all AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM v_contact_company c)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL AS gu_company,NULL AS nm_legal,NULL AS id_sector,NULL AS tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM k_contacts c WHERE c.gu_company IS NULL)
;

CREATE VIEW v_contact_address AS
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,c.gu_company,c.nm_legal,c.id_sector,c.tp_company,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM v_contact_company c
LEFT OUTER JOIN dbo.v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN dbo.v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT c.gu_workarea,c.gu_contact,c.dt_modified,c.bo_private,c.gu_writer,NULL,NULL,NULL,NULL,c.id_status,c.id_ref,c.tx_name,c.tx_surname,c.de_title,l.tr_es AS tr_title,c.id_gender,c.dt_birth,c.ny_age,c.sn_passport,c.tp_passport,c.tx_dept,c.tx_division,c.nu_notes,c.nu_attachs,c.tx_comments,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,ISNULL(tx_addr1,'')+CHAR(10)+ISNULL(tx_addr2,'') AS full_addr,b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_remarks,c.bo_restricted,c.gu_geozone,c.gu_sales_man,c.id_batch
FROM k_contacts c
LEFT OUTER JOIN dbo.v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN dbo.v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE c.gu_company IS NULL)
;

CREATE VIEW v_contact_address_title AS
SELECT b.*,l.gu_owner,l.id_section,l.pg_lookup,l.vl_lookup,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu FROM v_contact_address b LEFT OUTER JOIN k_contacts_lookup l ON b.de_title=l.vl_lookup
;

CREATE VIEW v_contact_list AS
SELECT c.gu_contact,ISNULL(c.tx_surname,'') + ', ' + ISNULL(c.tx_name,'') AS full_name,l.tr_es,l.tr_en,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner, c.bo_restricted, c.gu_geozone, c.gu_sales_man, c.id_batch, c.id_ref
FROM k_contacts c LEFT OUTER JOIN k_companies d ON c.gu_company=d.gu_company LEFT OUTER JOIN k_contacts_lookup l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE (l.id_section='de_title' OR l.id_section IS NULL)
;

CREATE VIEW v_attach_locat AS
SELECT p.gu_product, p.nm_product, p.de_product, c.gu_contact, c.pg_product, c.dt_created, l.dt_modified, l.dt_uploaded, l.gu_location, l.id_cont_type, l.id_prod_type, l.len_file, l.xprotocol, l.xhost, l.xport, l.xpath, l.xfile, l.xoriginalfile, l.xanchor, l.status, l.vs_stamp, l.tx_email, l.tag_prod_locat
FROM k_contact_attachs c, k_products p, k_prod_locats l
WHERE c.gu_product=p.gu_product AND c.gu_product=l.gu_product
;

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
;
    
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
    d.bo_active<>0 AND d.id_domain=w.id_domain AND d.id_domain=u.id_domain AND w.gu_workarea=a.gu_workarea AND w.bo_active<>0 AND (a.tx_email IS NOT NULL);

CREATE VIEW v_supplier_address AS SELECT s.gu_supplier,s.dt_created,s.nm_legal,s.gu_workarea,s.nm_commercial,s.gu_address,s.dt_modified,s.id_legal,s.id_status,s.id_ref,s.tp_supplier,s.gu_geozone,s.de_supplier,a.ix_address,a.bo_active,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city,a.zipcode,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.tx_email_alt,a.url_addr,a.coord_x,a.coord_y,a.contact_person,a.tx_salutation,a.tx_remarks FROM k_suppliers s, k_addresses a WHERE s.gu_address=a.gu_address;
