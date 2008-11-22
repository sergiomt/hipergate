CREATE VIEW v_prod_cat AS
SELECT
c.gu_category,c.id_class,c.bi_attribs,c.od_position,p.gu_product,p.dt_created,p.gu_owner,p.nm_product,p.id_status,p.is_compound,p.gu_blockedby,p.dt_modified,p.dt_uploaded,p.id_language,p.de_product,p.pr_list,p.pr_sale,p.pr_discount,p.pr_purchase,p.id_currency,p.pct_tax_rate,p.is_tax_included,p.dt_start,p.dt_end,p.tag_product,p.id_ref,p.gu_address
FROM k_x_cat_objs c, k_products p WHERE c.gu_object=p.gu_product;

CREATE VIEW v_prods_with_attrs AS
SELECT p.gu_product,p.dt_created,p.gu_owner,p.nm_product,p.id_status,p.is_compound,p.dt_modified,p.dt_uploaded,p.id_language,p.de_product,p.pr_list,p.pr_sale,p.id_currency,p.pct_tax_rate,p.is_tax_included,p.dt_start,p.dt_end,p.tag_product,
l.gu_location,l.pg_prod_locat,l.id_cont_type,l.id_prod_type,l.len_file,l.xprotocol,l.xhost,l.xport,l.xpath,l.xfile,l.xanchor,l.xoriginalfile,l.de_prod_locat,l.status,l.nu_current_stock,l.nu_min_stock,l.vs_stamp,l.tx_email,l.tag_prod_locat,
a.adult_rated,a.alturl,a.author,a.availability,a.brand,a.client,a.color,a.contact_person,a.country_code,a.country,a.cover,a.days_to_deliver,a.department,a.disk_space,a.display,a.doc_no,a.dt_acknowledge,a.dt_expire,a.dt_out,a.email,a.fax,a.forward_to,a.icq_id,a.ip_addr,a.isbn,a.nu_lines,a.memory,a.mobilephone,a.office,a.ordinal,a.organization,a.pages,a.paragraphs,a.phone1,a.phone2,a.power,a.project,a.product_group,a.rank,a.reference_id,a.revised_by,a.rooms,a.scope,a.size_x,a.size_y,a.size_z,a.speed,a.state_code,a.state,a.subject,a.target,a.template,a.typeof,a.upload_by,a.weight,a.words,a.zip_code
FROM k_products p, k_prod_locats l, k_prod_attr a WHERE p.gu_product=l.gu_product(+) AND p.gu_product=a.gu_product
WITH READ ONLY;
