
CREATE VIEW v_member_address AS
(SELECT
k.gu_company,'' AS gu_contact,k.dt_created,k.dt_modified,k.gu_workarea,0 AS bo_private,'' AS gu_writer,'' AS tx_name,'' AS tx_surname,k.nm_commercial,k.nm_legal,k.id_legal,k.id_sector,'' AS de_title,'' AS tr_title,k.id_status,k.id_ref,k.dt_founded AS dt_birth,k.id_legal AS sn_passport,k.de_company AS tx_comments,'C' AS id_gender,k.tp_company,k.nu_employees,k.im_revenue,k.gu_sales_man,k.tx_franchise,k.gu_geozone,0 AS ny_age,'' AS tx_dept,'' AS tx_division,
b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nm_street,b.nu_street,b.tx_addr1,b.tx_addr2,NVL(b.tx_addr1,'')||CHR(10)||NVL(b.tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_salutation,b.tx_remarks
FROM k_companies k, v_active_company_address b WHERE k.gu_company=b.gu_company)
UNION
(SELECT
y.gu_company,c.gu_contact,c.dt_created,c.dt_modified,c.gu_workarea,c.bo_private,c.gu_writer,c.tx_name,c.tx_surname,y.nm_commercial,y.nm_legal,y.id_legal,y.id_sector,c.de_title ,l.tr_es AS tr_title,c.id_status,c.id_ref,c.dt_birth ,c.sn_passport,c.tx_comments,c.id_gender,y.tp_company,y.nu_employees,y.im_revenue,y.gu_sales_man,y.tx_franchise,NVL(c.gu_geozone,y.gu_geozone) AS gu_geozone,c.ny_age,c.tx_dept,c.tx_division,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nm_street,b.nu_street,b.tx_addr1,b.tx_addr2,NVL(b.tx_addr1,'')||CHR(10)||NVL(b.tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_salutation,b.tx_remarks
FROM k_contacts c, v_contact_titles l, k_companies y, v_active_contact_address b WHERE c.gu_contact=b.gu_contact
AND y.gu_company=c.gu_company AND l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT
'' AS gu_company,c.gu_contact,c.dt_created,c.dt_modified,c.gu_workarea,c.bo_private,c.gu_writer,c.tx_name,c.tx_surname,'' AS nm_commercial,'' AS nm_legal,'' AS id_legal,'' AS id_sector,c.de_title ,l.tr_es AS tr_title,c.id_status,c.id_ref,c.dt_birth ,c.sn_passport,c.tx_comments,c.id_gender,'' AS tp_company,0 AS nu_employees,0 AS im_revenue,'' AS gu_sales_man,'' AS tx_franchise,c.gu_geozone,c.ny_age,c.tx_dept,c.tx_division,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nm_street,b.nu_street,b.tx_addr1,b.tx_addr2,NVL(b.tx_addr1,'')||CHR(10)||NVL(b.tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_salutation,b.tx_remarks
FROM k_contacts c, v_contact_titles l, v_active_contact_address b WHERE c.gu_contact=b.gu_contact(+)
AND c.gu_company IS NULL AND l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea)
UNION
(SELECT
y.gu_company,c.gu_contact,c.dt_created,c.dt_modified,c.gu_workarea,c.bo_private,c.gu_writer,c.tx_name,c.tx_surname,y.nm_commercial,y.nm_legal,y.id_legal,y.id_sector,c.de_title ,'' AS tr_title,c.id_status,c.id_ref,c.dt_birth ,c.sn_passport,c.tx_comments,c.id_gender,y.tp_company,y.nu_employees,y.im_revenue,y.gu_sales_man,y.tx_franchise,NVL(c.gu_geozone,y.gu_geozone) AS gu_geozone,c.ny_age,c.tx_dept,c.tx_division,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nm_street,b.nu_street,b.tx_addr1,b.tx_addr2,NVL(b.tx_addr1,'')||CHR(10)||NVL(b.tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_salutation,b.tx_remarks
FROM k_contacts c, k_companies y, v_active_contact_address b WHERE c.gu_contact=b.gu_contact
AND y.gu_company=c.gu_company AND c.de_title IS NULL);
