DROP VIEW v_contact_list
GO;

CREATE VIEW v_contact_list AS
(SELECT c.gu_contact,NVL(c.tx_surname,'') || ', ' || NVL(c.tx_name,'') AS full_name,l.tr_es,l.tr_en,l.tr_fr,l.tr_de,l.tr_it,l.tr_pt,l.tr_ja,l.tr_cn,l.tr_tw,l.tr_ca,l.tr_eu,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, l.gu_owner
FROM k_contacts c, k_companies d, k_contacts_lookup l
WHERE c.gu_company=d.gu_company(+) AND c.de_title=l.vl_lookup AND c.gu_workarea=l.gu_owner AND l.id_section='de_title')
UNION
(SELECT c.gu_contact,NVL(c.tx_surname,'') || ', ' || NVL(c.tx_name,'') AS full_name,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,d.gu_company,d.nm_legal,c.nu_notes,c.nu_attachs,c.dt_modified, c.bo_private, c.gu_workarea, c.gu_writer, c.gu_workarea
FROM k_contacts c, k_companies d
WHERE c.gu_company=d.gu_company(+) AND c.de_title IS NULL)
WITH READ ONLY
GO;

UPDATE k_version SET vs_stamp='2.0.2'
GO;
