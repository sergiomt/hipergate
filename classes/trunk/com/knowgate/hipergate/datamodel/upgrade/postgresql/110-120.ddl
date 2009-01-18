UPDATE k_version SET vs_stamp='1.2.0'
GO;

CREATE SEQUENCE seq_thesauri INCREMENT 1 MINVALUE 100000000 MAXVALUE 999999999 START 100000000
GO;

CREATE TABLE k_thesauri_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(255)    NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,

CONSTRAINT pk_thesauri_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_thesauri_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_newsgroup_subscriptions (
  gu_newsgrp  CHAR(32) NOT NULL,
  gu_user     CHAR(32) NOT NULL,
  dt_created  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_status   SMALLINT DEFAULT 0,
  id_msg_type CHAR(5) DEFAULT 'TXT',
  tp_subscrip SMALLINT DEFAULT 1,
  tx_email    VARCHAR(100) NULL,

  CONSTRAINT pk_newsgroup_subscriptions PRIMARY KEY (gu_newsgrp,gu_user)
)
GO;

ALTER TABLE k_newsgroup_subscriptions ADD CONSTRAINT f1_newsgroup_subscriptions FOREIGN KEY (gu_newsgrp)  REFERENCES k_newsgroups(gu_newsgrp)
GO;

ALTER TABLE k_newsgroup_subscriptions ADD CONSTRAINT f2_newsgroup_subscriptions FOREIGN KEY (gu_user)  REFERENCES k_users(gu_user)
GO;

DROP FUNCTION k_sp_del_newsgroup (CHAR)
GO;

CREATE FUNCTION k_sp_del_newsgroup (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_newsmsgs WHERE gu_msg IN (SELECT gu_object FROM k_x_cat_objs WHERE gu_category=$1);
  DELETE FROM k_newsgroup_subscriptions WHERE gu_newsgrp=$1;
  DELETE FROM k_newsgroups WHERE gu_newsgrp=$1;
  DELETE FROM k_x_cat_objs WHERE gu_category=$1;
  PERFORM k_sp_del_category ($1);
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

ALTER TABLE k_sales_men ADD gu_geozone CHAR(32) NULL
GO;

ALTER TABLE k_sales_men ADD id_country CHAR(3) NULL
GO;

ALTER TABLE k_sales_men ADD id_state CHAR(9) NULL
GO;

ALTER TABLE k_sales_men ADD id_sales_group VARCHAR(50) NULL
GO;

ALTER TABLE k_sales_men ADD CONSTRAINT f1_sales_men FOREIGN KEY (gu_sales_man) REFERENCES k_users(gu_user)
GO;

ALTER TABLE k_sales_men ADD CONSTRAINT f2_sales_men FOREIGN KEY (gu_geozone) REFERENCES k_thesauri(gu_term)
GO;

ALTER TABLE k_sales_men ADD CONSTRAINT f3_sales_men FOREIGN KEY (id_state) REFERENCES k_lu_states(id_state)
GO;

CREATE TABLE k_sales_men_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(255)    NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,

CONSTRAINT pk_sales_men_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_sales_men_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

ALTER TABLE k_sales_men_lookup ADD CONSTRAINT f1_sales_men_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea)
GO;

ALTER TABLE k_oportunities ADD im_cost FLOAT NULL
GO;

ALTER TABLE k_bank_accounts ADD tx_addr VARCHAR(100) NULL
GO;

CREATE TABLE k_bank_accounts_lookup
(
gu_owner   CHAR(32)    NOT NULL, /* GUID de la workarea */
id_section CHARACTER VARYING(30) NOT NULL, /* Nombre del campo en la tabla base */
pg_lookup  INTEGER     NOT NULL, /* Progresivo del valor */
vl_lookup  VARCHAR(255) NULL,    /* Valor real del lookup */
tr_es      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (esp) */
tr_en      VARCHAR(50)  NULL,    /* Valor que se visualiza en pantalla (ing) */
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_eu      VARCHAR(50)  NULL,

CONSTRAINT pk_bank_accounts_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

ALTER TABLE k_bank_accounts_lookup ADD CONSTRAINT f1_bank_accounts_lookup FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea)
GO;

CREATE TABLE k_x_company_prods
(
gu_company  CHAR(32) NOT NULL,
gu_category CHAR(32) NOT NULL,

CONSTRAINT pk_x_company_bank PRIMARY KEY(gu_company,gu_category)
)
GO;

ALTER TABLE k_x_company_prods ADD CONSTRAINT f1_companies_prods FOREIGN KEY (gu_company) REFERENCES k_companies(gu_company)
GO;
ALTER TABLE k_x_company_prods ADD CONSTRAINT f2_companies_prods FOREIGN KEY (gu_category) REFERENCES k_categories(gu_category)
GO;

CREATE TABLE k_x_contact_prods
(
gu_contact  CHAR(32) NOT NULL,
gu_category CHAR(32) NOT NULL,

CONSTRAINT pk_x_contact_prods PRIMARY KEY(gu_contact,gu_category)
)
GO;

ALTER TABLE k_x_contact_prods ADD CONSTRAINT f1_contact_prods FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact)
GO;
ALTER TABLE k_x_contact_prods ADD CONSTRAINT f2_contact_prods FOREIGN KEY (gu_category) REFERENCES k_categories(gu_category)
GO;

DROP VIEW v_company_address
GO;

CREATE VIEW v_company_address AS
SELECT c.gu_workarea,c.gu_company,c.nm_legal,c.nm_commercial,c.dt_modified,c.id_legal,c.id_ref,c.id_sector,c.id_status,c.tp_company,c.de_company,b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nu_street,b.nm_street,b.tx_addr1,b.tx_addr2,COALESCE(tx_addr1,'')||chr(10)||COALESCE(tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.id_ref AS id_addrref,b.tx_remarks
FROM k_companies c
LEFT OUTER JOIN v_active_company_address AS b ON c.gu_company=b.gu_company
GO;

DROP VIEW v_member_address
GO;

CREATE VIEW v_member_address AS
(SELECT
k.gu_company,NULL AS gu_contact,k.dt_created,k.dt_modified,k.gu_workarea,CAST(0 AS SMALLINT) AS bo_private,NULL AS gu_writer,NULL AS tx_name,NULL AS tx_surname,k.nm_commercial,k.nm_legal,k.id_sector,NULL AS de_title,NULL AS tr_title,k.id_status,k.id_ref,k.dt_founded AS dt_birth,k.id_legal AS sn_passport,k.de_company AS tx_comments,'C' AS id_gender,k.tp_company,k.nu_employees,k.im_revenue,NULL AS ny_age,NULL AS tx_dept,NULL AS tx_division,
b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nm_street,b.nu_street,b.tx_addr1,b.tx_addr2,COALESCE(b.tx_addr1,'')||chr(10)||COALESCE(b.tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_salutation,b.tx_remarks
FROM k_companies k
LEFT OUTER JOIN v_active_company_address AS b ON k.gu_company=b.gu_company)
UNION
(SELECT
y.gu_company,c.gu_contact,c.dt_created,c.dt_modified,c.gu_workarea,c.bo_private,c.gu_writer,c.tx_name,c.tx_surname,y.nm_commercial,y.nm_legal,y.id_sector,c.de_title ,l.tr_es AS tr_title,c.id_status,c.id_ref,c.dt_birth ,c.sn_passport,c.tx_comments,c.id_gender,y.tp_company,y.nu_employees,y.im_revenue,c.ny_age,c.tx_dept,c.tx_division,
b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nm_street,b.nu_street,b.tx_addr1,b.tx_addr2,COALESCE(b.tx_addr1,'')||chr(10)||COALESCE(b.tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_salutation,b.tx_remarks
FROM k_companies y, k_contacts c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE y.gu_company=c.gu_company)
UNION
(SELECT
NULL AS gu_company,c.gu_contact,c.dt_created,c.dt_modified,c.gu_workarea,c.bo_private,c.gu_writer,c.tx_name,c.tx_surname,NULL AS nm_commercial,NULL AS nm_legal,NULL AS id_sector,c.de_title ,l.tr_es AS tr_title,c.id_status,c.id_ref,c.dt_birth ,c.sn_passport,c.tx_comments,c.id_gender,NULL AS tp_company,0 AS nu_employees,CAST(0 AS FLOAT) AS im_revenue,c.ny_age,c.tx_dept,c.tx_division,
b.gu_address,b.ix_address,b.tp_location,b.tp_street,b.nm_street,b.nu_street,b.tx_addr1,b.tx_addr2,COALESCE(b.tx_addr1,'')||chr(10)||COALESCE(b.tx_addr2,'') AS full_addr, b.id_country,b.nm_country,b.id_state,b.nm_state,b.mn_city,b.zipcode,b.work_phone,b.direct_phone,b.home_phone,b.mov_phone,b.fax_phone,b.other_phone,b.po_box,b.tx_email,b.url_addr,b.contact_person,b.tx_salutation,b.tx_remarks
FROM k_contacts c
LEFT OUTER JOIN v_active_contact_address AS b ON c.gu_contact=b.gu_contact
LEFT OUTER JOIN v_contact_titles AS l ON l.vl_lookup=c.de_title AND l.gu_owner=c.gu_workarea
WHERE c.gu_company IS NULL)
GO;

DROP FUNCTION k_sp_del_contact (CHAR)
GO;

CREATE FUNCTION k_sp_del_contact (CHAR) RETURNS INTEGER AS '
DECLARE
  addr k_x_contact_addr%ROWTYPE;
  addrs text;
  aCount INTEGER := 0;

  bank k_x_contact_bank%ROWTYPE;
  banks text;
  bCount INTEGER := 0;

  GuWorkArea CHAR(32);

BEGIN
  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=$1;

  FOR addr IN SELECT gu_address FROM k_x_contact_addr WHERE gu_contact=$1 LOOP
    aCount := aCount + 1;
    IF 1=aCount THEN
      addrs := quote_literal(addr.gu_address);
    ELSE
      addrs := addrs || chr(44) || quote_literal(addr.gu_address);
    END IF;
  END LOOP;

  DELETE FROM k_x_contact_addr WHERE gu_contact=$1;

  IF char_length(addrs)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_addresses'') || '' WHERE gu_address IN ('' || addrs || '')'';
  END IF;

  FOR bank IN SELECT nu_bank_acc FROM k_x_contact_bank WHERE gu_contact=$1 LOOP
    bCount := bCount + 1;
    IF 1=bCount THEN
      banks := quote_literal(bank.nu_bank_acc);
    ELSE
      banks := banks || chr(44) || quote_literal(bank.nu_bank_acc);
    END IF;
  END LOOP;

  DELETE FROM k_x_contact_bank WHERE gu_contact=$1;

  IF char_length(banks)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_bank_accounts'') || '' WHERE nu_bank_acc IN ('' || banks || '') AND gu_workarea='' || quote_literal(GuWorkArea);
  END IF;

  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_contact=$1);
  DELETE FROM k_oportunities WHERE gu_contact=$1;

  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=90;

  DELETE FROM k_x_contact_prods WHERE gu_contact=$1;
  DELETE FROM k_contacts_attrs WHERE gu_object=$1;
  DELETE FROM k_contact_notes WHERE gu_contact=$1;
  DELETE FROM k_contacts WHERE gu_contact=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_company (CHAR)
GO;

CREATE FUNCTION k_sp_del_company (CHAR) RETURNS INTEGER AS '
DECLARE
  addr k_x_company_addr%ROWTYPE;
  addrs text;
  aCount INTEGER := 0;

  bank k_x_company_bank%ROWTYPE;
  banks text;
  bCount INTEGER := 0;

BEGIN

  FOR addr IN SELECT gu_address FROM k_x_company_addr WHERE gu_company=$1 LOOP
    aCount := aCount + 1;
    IF 1=aCount THEN
      addrs := quote_literal(addr.gu_address);
    ELSE
      addrs := addrs || chr(44) || quote_literal(addr.gu_address);
    END IF;
  END LOOP;

  DELETE FROM k_x_company_addr WHERE gu_company=$1;

  IF char_length(addrs)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_addresses'') || '' WHERE gu_address IN ('' || addrs || '')'';
  END IF;

  FOR bank IN SELECT nu_bank_acc FROM k_x_company_bank WHERE gu_company=$1 LOOP
    bCount := bCount + 1;
    IF 1=bCount THEN
      banks := quote_literal(bank.nu_bank_acc);
    ELSE
      banks := banks || chr(44) || quote_literal(bank.nu_bank_acc);
    END IF;
  END LOOP;

  DELETE FROM k_x_company_bank WHERE gu_company=$1;

  IF char_length(banks)>0 THEN
    EXECUTE ''DELETE FROM '' || quote_ident(''k_bank_accounts'') || '' WHERE nu_bank_acc IN ('' || banks || '') AND gu_workarea='' || quote_literal(GuWorkArea);
  END IF;

  /* Borrar las oportunidades */
  DELETE FROM k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=$1);
  DELETE FROM k_oportunities WHERE gu_company=$1;

  /* Borrar el enlace con categorías */
  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=91;


  DELETE FROM k_x_company_prods WHERE gu_company=$1;
  DELETE FROM k_companies_attrs WHERE gu_object=$1;
  DELETE FROM k_companies WHERE gu_company=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_prj_cost (CHAR) RETURNS FLOAT AS '
DECLARE
  proj k_projects%ROWTYPE;
  fCost FLOAT := 0;
BEGIN
  SELECT COALESCE(SUM(d.pr_cost),0) INTO fCost FROM k_duties d, k_projects p WHERE d.gu_project=p.gu_project AND p.gu_project=$1 AND d.pr_cost IS NOT NULL;

  FOR proj IN SELECT gu_project FROM k_projects WHERE id_parent=$1 LOOP
    fCost = fCost + k_sp_prj_cost (proj.gu_project);
  END LOOP;

  RETURN fCost;
END;
' LANGUAGE 'plpgsql';
GO;