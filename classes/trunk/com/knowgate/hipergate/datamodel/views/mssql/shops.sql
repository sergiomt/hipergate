SET NUMERIC_ROUNDABORT OFF;

SET ANSI_PADDING,ANSI_WARNINGS,CONCAT_NULL_YIELDS_NULL,ARITHABORT,QUOTED_IDENTIFIER,ANSI_NULLS ON;

CREATE VIEW v_orders WITH SCHEMABINDING AS
SELECT o.gu_order,o.gu_workarea,o.pg_order,o.gu_shop,s.nm_shop,s.gu_root_cat,o.id_currency,o.dt_created,o.bo_active,o.bo_approved,o.bo_credit_ok,o.id_priority,o.gu_sales_man,o.gu_sale_point,p.nm_sale_point,o.gu_warehouse,w.nm_warehouse,o.dt_modified,o.dt_invoiced,o.dt_delivered,o.dt_printed,o.dt_promised,o.dt_payment,o.dt_cancel,o.de_order,o.tx_location,o.gu_contact,o.nm_client,o.id_legal,o.id_ref,o.id_status,o.id_pay_status,o.id_ship_method,o.im_subtotal,o.im_taxes,o.im_shipping,o.im_discount,o.im_total,o.tp_billing,o.nu_bank,o.nm_cardholder,o.nu_card,o.tp_card,o.tx_expire,o.nu_pin,o.nu_cvv2,o.tx_ship_notes,o.tx_email_to,o.tx_comments,
o.gu_company,c.nm_legal,c.nm_commercial,c.id_sector,c.tp_company,c.gu_geozone,
o.gu_ship_addr,a.ix_address AS ship_ix_address,a.tp_location AS ship_tp_location,a.nm_company AS ship_nm_company,a.tp_street AS ship_tp_street,a.nm_street AS ship_nm_street,a.nu_street AS ship_nu_street,a.tx_addr1 AS ship_tx_addr1,a.tx_addr2 AS ship_tx_addr2,a.id_country AS ship_id_country,a.nm_country AS ship_nm_country,a.id_state AS ship_id_state,a.nm_state AS ship_nm_state,a.mn_city AS ship_mn_city,a.zipcode AS ship_zipcode,a.work_phone AS ship_work_phone,a.direct_phone AS ship_direct_phone,a.home_phone AS ship_home_phone,a.mov_phone AS ship_mov_phone,a.fax_phone AS ship_fax_phone,a.other_phone AS ship_other_phone,a.po_box AS ship_po_box,a.tx_email AS ship_tx_email,a.url_addr AS ship_url_addr,a.coord_x AS ship_coord_x,a.coord_y AS ship_coord_y,a.contact_person AS ship_contact_person,a.tx_salutation AS ship_tx_salutation,a.id_ref AS ship_id_ref,
o.gu_bill_addr,b.ix_address AS bill_ix_address,b.tp_location AS bill_tp_location,b.nm_company AS bill_nm_company,b.tp_street AS bill_tp_street,b.nm_street AS bill_nm_street,b.nu_street AS bill_nu_street,b.tx_addr1 AS bill_tx_addr1,b.tx_addr2 AS bill_tx_addr2,b.id_country AS bill_id_country,b.nm_country AS bill_nm_country,b.id_state AS bill_id_state,b.nm_state AS bill_nm_state,b.mn_city AS bill_mn_city,b.zipcode AS bill_zipcode,b.work_phone AS bill_work_phone,b.direct_phone AS bill_direct_phone,b.home_phone AS bill_home_phone,b.mov_phone AS bill_mov_phone,b.fax_phone AS bill_fax_phone,b.other_phone AS bill_other_phone,b.po_box AS bill_po_box,b.tx_email AS bill_tx_email,b.url_addr AS bill_url_addr,b.coord_x AS bill_coord_x,b.coord_y AS bill_coord_y,b.contact_person AS bill_contact_person,b.tx_salutation AS bill_tx_salutation,b.id_ref AS bill_id_ref
FROM dbo.k_shops s, dbo.k_orders o
LEFT OUTER JOIN dbo.k_sale_points AS p ON o.gu_sale_point=p.gu_sale_point
LEFT OUTER JOIN dbo.k_warehouses AS w ON o.gu_warehouse=w.gu_warehouse
LEFT OUTER JOIN dbo.k_addresses AS a ON o.gu_ship_addr=a.gu_address
LEFT OUTER JOIN dbo.k_addresses AS b ON o.gu_bill_addr=b.gu_address
LEFT OUTER JOIN dbo.k_companies AS c ON o.gu_company=c.gu_company
WHERE s.gu_shop=o.gu_shop;

CREATE VIEW v_despatch_advices WITH SCHEMABINDING AS
SELECT d.gu_despatch,d.gu_workarea,d.pg_despatch,d.gu_shop,s.nm_shop,s.gu_root_cat,d.id_currency,d.dt_created,s.bo_active,d.bo_approved,d.bo_credit_ok,d.id_priority,d.gu_warehouse,d.dt_modified,d.dt_delivered,d.dt_printed,d.dt_promised,d.dt_payment,d.dt_cancel,d.tx_location,d.gu_contact,d.nm_client,d.id_legal,d.id_ref,d.id_status,d.id_pay_status,d.id_ship_method,d.im_subtotal,d.im_taxes,d.im_shipping,d.im_discount,d.im_total,d.tx_ship_notes,d.tx_email_to,d.tx_comments,
d.gu_company,c.nm_legal,c.nm_commercial,c.id_sector,c.tp_company,c.gu_geozone,
d.gu_ship_addr,a.ix_address AS ship_ix_address,a.tp_location AS ship_tp_location,a.nm_company AS ship_nm_company,a.tp_street AS ship_tp_street,a.nm_street AS ship_nm_street,a.nu_street AS ship_nu_street,a.tx_addr1 AS ship_tx_addr1,a.tx_addr2 AS ship_tx_addr2,a.id_country AS ship_id_country,a.nm_country AS ship_nm_country,a.id_state AS ship_id_state,a.nm_state AS ship_nm_state,a.mn_city AS ship_mn_city,a.zipcode AS ship_zipcode,a.work_phone AS ship_work_phone,a.direct_phone AS ship_direct_phone,a.home_phone AS ship_home_phone,a.mov_phone AS ship_mov_phone,a.fax_phone AS ship_fax_phone,a.other_phone AS ship_other_phone,a.po_box AS ship_po_box,a.tx_email AS ship_tx_email,a.url_addr AS ship_url_addr,a.coord_x AS ship_coord_x,a.coord_y AS ship_coord_y,a.contact_person AS ship_contact_person,a.tx_salutation AS ship_tx_salutation,a.id_ref AS ship_id_ref,
d.gu_bill_addr,b.ix_address AS bill_ix_address,b.tp_location AS bill_tp_location,b.nm_company AS bill_nm_company,b.tp_street AS bill_tp_street,b.nm_street AS bill_nm_street,b.nu_street AS bill_nu_street,b.tx_addr1 AS bill_tx_addr1,b.tx_addr2 AS bill_tx_addr2,b.id_country AS bill_id_country,b.nm_country AS bill_nm_country,b.id_state AS bill_id_state,b.nm_state AS bill_nm_state,b.mn_city AS bill_mn_city,b.zipcode AS bill_zipcode,b.work_phone AS bill_work_phone,b.direct_phone AS bill_direct_phone,b.home_phone AS bill_home_phone,b.mov_phone AS bill_mov_phone,b.fax_phone AS bill_fax_phone,b.other_phone AS bill_other_phone,b.po_box AS bill_po_box,b.tx_email AS bill_tx_email,b.url_addr AS bill_url_addr,b.coord_x AS bill_coord_x,b.coord_y AS bill_coord_y,b.contact_person AS bill_contact_person,b.tx_salutation AS bill_tx_salutation,b.id_ref AS bill_id_ref
FROM dbo.k_shops s, dbo.k_despatch_advices d
LEFT OUTER JOIN dbo.k_addresses AS a ON d.gu_ship_addr=a.gu_address
LEFT OUTER JOIN dbo.k_addresses AS b ON d.gu_bill_addr=b.gu_address
LEFT OUTER JOIN dbo.k_companies AS c ON d.gu_company=c.gu_company
WHERE s.gu_shop=d.gu_shop;

CREATE VIEW v_invoices WITH SCHEMABINDING AS
SELECT i.gu_invoice,o.gu_order,i.gu_workarea,i.pg_invoice,i.gu_shop,s.nm_shop,
i.id_currency,i.id_legal,i.dt_created,i.bo_active,i.bo_approved,i.bo_template,
i.gu_schedule,i.gu_sales_man,i.gu_sale_point,i.gu_warehouse,i.dt_modified,
i.dt_invoiced,i.dt_printed,i.dt_payment,i.dt_paid,i.dt_cancel,i.de_order,
i.tx_location,i.gu_contact,i.nm_client,i.id_ref,i.id_status,i.id_pay_status,
i.id_ship_method,i.im_subtotal,i.im_taxes,i.im_shipping,i.im_discount,i.im_total,
i.tp_billing,i.nu_bank,i.nm_cardholder,i.nu_card,i.tp_card,i.tx_expire,i.nu_pin,
i.nu_cvv2,i.tx_ship_notes,i.tx_email_to,i.tx_comments,i.gu_company,
c.nm_legal,c.nm_commercial,c.id_sector,c.tp_company,c.gu_geozone,
i.gu_ship_addr,i.gu_bill_addr,b.ix_address AS bill_ix_address,
b.tp_location AS bill_tp_location,b.nm_company AS bill_nm_company,
b.tp_street AS bill_tp_street,b.nm_street AS bill_nm_street,
b.nu_street AS bill_nu_street,b.tx_addr1 AS bill_tx_addr1,b.tx_addr2 AS bill_tx_addr2,
b.id_country AS bill_id_country,b.nm_country AS bill_nm_country,
b.id_state AS bill_id_state,b.nm_state AS bill_nm_state,b.mn_city AS bill_mn_city,
b.zipcode AS bill_zipcode,b.work_phone AS bill_work_phone,
b.direct_phone AS bill_direct_phone,b.home_phone AS bill_home_phone,
b.mov_phone AS bill_mov_phone,b.fax_phone AS bill_fax_phone,
b.other_phone AS bill_other_phone,b.po_box AS bill_po_box,b.tx_email AS bill_tx_email,
b.url_addr AS bill_url_addr,b.coord_x AS bill_coord_x,b.coord_y AS bill_coord_y,
b.contact_person AS bill_contact_person,b.tx_salutation AS bill_tx_salutation,
b.id_ref AS bill_id_ref
FROM dbo.k_shops s, dbo.k_invoices i
LEFT OUTER JOIN dbo.k_x_orders_invoices AS o ON i.gu_invoice=o.gu_invoice
LEFT OUTER JOIN dbo.k_addresses AS b ON i.gu_bill_addr=b.gu_address
LEFT OUTER JOIN dbo.k_companies AS c ON i.gu_company=c.gu_company
WHERE s.gu_shop=i.gu_shop;

CREATE VIEW v_sale_points AS
SELECT
s.gu_sale_point,s.gu_workarea,s.nm_sale_point,s.dt_created,s.bo_active,a.gu_address,a.ix_address,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city	,a.zipcode	,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.tx_email_alt,a.url_addr,a.coord_x	,a.coord_y,a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks
FROM k_sale_points s, k_addresses a
WHERE s.gu_address=a.gu_address;

CREATE VIEW v_warehouses AS
SELECT
s.gu_warehouse,s.gu_workarea,s.nm_warehouse,s.dt_created,s.bo_active,a.gu_address,a.ix_address,a.dt_modified,a.gu_user,a.tp_location,a.nm_company,a.tp_street,a.nm_street,a.nu_street,a.tx_addr1,a.tx_addr2,a.id_country,a.nm_country,a.id_state,a.nm_state,a.mn_city	,a.zipcode	,a.work_phone,a.direct_phone,a.home_phone,a.mov_phone,a.fax_phone,a.other_phone,a.po_box,a.tx_email,a.tx_email_alt,a.url_addr,a.coord_x	,a.coord_y,a.contact_person,a.tx_salutation,a.id_ref,a.tx_remarks
FROM k_warehouses s, k_addresses a
WHERE s.gu_address=a.gu_address;
