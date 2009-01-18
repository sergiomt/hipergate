CREATE TABLE k_x_portlet_user (
    id_domain   INTEGER      NOT NULL,
    gu_user     CHAR(32)     NOT NULL,
    gu_workarea CHAR(32)     NOT NULL,
    nm_portlet  VARCHAR(128) NOT NULL,
    nm_page     VARCHAR(128) NOT NULL,
    nm_zone     VARCHAR(16)  DEFAULT 'none',
    od_position INTEGER      DEFAULT 1,
    id_state    VARCHAR(16)  DEFAULT 'NORMAL',
    dt_modified TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    nm_template VARCHAR(254) NULL,  

    CONSTRAINT pk_x_portlet_user PRIMARY KEY(id_domain,gu_user,gu_workarea,nm_portlet,nm_page,nm_zone)  
)
GO;
UPDATE k_categories SET nm_category='MODEL_superuser' WHERE nm_category='MODEL_poweruser'
GO;
INSERT INTO k_apps (id_app,nm_app) VALUES (21,'Hipermail');
GO;
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SEND','SEND MIME MESSAGES BY SMTP','com.knowgate.scheduler.jobs.MimeSender')
GO;
CREATE SEQUENCE seq_mime_msgs INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 START 1
GO;
ALTER TABLE k_categories ADD len_size DECIMAL(28) NULL
GO;
ALTER TABLE k_projects ADD dt_scheduled TIMESTAMP NULL
GO;
ALTER TABLE k_duties ADD dt_scheduled TIMESTAMP NULL
GO;
ALTER TABLE k_duties ADD gu_contact CHAR(32) NULL
GO;
ALTER TABLE k_bugs ADD gu_writer CHAR(32) NULL
GO;
ALTER TABLE k_bugs ADD tp_bug VARCHAR(50) NULL
GO;
ALTER TABLE k_bugs ADD dt_since TIMESTAMP NULL
GO;
ALTER TABLE k_bugs ADD tx_bug_info VARCHAR(1000) NULL
GO;
ALTER TABLE k_bugs ADD nu_times INTEGER NULL
GO;
ALTER TABLE k_products ADD pr_purchase DECIMAL(14,4) NULL
GO;
ALTER TABLE k_cat_labels ADD de_category VARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD gu_company CHAR(32) NULL
GO;
ALTER TABLE k_pagesets ADD gu_project CHAR(32) NULL
GO;
ALTER TABLE k_lu_job_status ADD tr_ru VARCHAR(30)  NULL
GO;
ALTER TABLE k_fellows ADD tx_timezone VARCHAR(16) NULL
GO;
ALTER TABLE k_lu_permissions ADD tr_mask_ru VARCHAR(32) NULL
GO;
ALTER TABLE k_contacts ADD tx_nickname VARCHAR(100) NULL
GO;
ALTER TABLE k_contacts ADD tx_pwd VARCHAR(50) NULL
GO;
ALTER TABLE k_contacts ADD tx_challenge VARCHAR(100) NULL
GO;
ALTER TABLE k_contacts ADD tx_reply VARCHAR(100) NULL
GO;
ALTER TABLE k_contacts ADD dt_pwd_expires TIMESTAMP NULL
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

DROP VIEW v_cat_tree_labels
GO;

CREATE VIEW v_cat_tree_labels AS
SELECT c.gu_category,t.gu_parent_cat,n.id_language,c.nm_category,n.tr_category,c.gu_owner,c.bo_active,c.dt_created,c.dt_modified,c.nm_icon,c.nm_icon2,n.de_category
FROM k_cat_tree t, k_categories c LEFT OUTER JOIN k_cat_labels n ON c.gu_category=n.gu_category
WHERE t.gu_child_cat=c.gu_category
GO;

DROP VIEW v_project_company
GO;

CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,COALESCE(d.tx_name,'') || ' ' || COALESCE(d.tx_surname,'') AS full_name,p.id_status
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
WHERE p.gu_project=b.gu_project AND NOT EXISTS (SELECT gu_user FROM k_users WHERE gu_user=x.nm_resource)
GO;

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
    TRIM(trailing FROM COALESCE (u.tx_surname1,u.tx_nickname)||' '||COALESCE (u.tx_surname2,'')) AS sn,
    TRIM(both FROM COALESCE (u.nm_user,'')||' '||COALESCE (u.tx_surname1,u.tx_nickname)||' '||COALESCE (u.tx_surname2,'')) AS displayName,
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
    COALESCE (f.tx_email,u.tx_main_email) AS cn,
    f.gu_fellow   AS uid,
    f.tx_name     AS givenName,
    u.tx_pwd      AS userPassword,
    COALESCE (f.tx_surname,u.tx_nickname) AS sn,
    TRIM(both FROM COALESCE (u.nm_user,'')||' '||COALESCE (u.tx_surname1,u.tx_surname1)||' '||COALESCE (u.tx_surname2,'')) AS displayName,
    COALESCE (f.tx_email,u.tx_main_email) AS mail,
    u.nm_company  AS o,
    f.work_phone  AS telephonenumber,
    f.home_phone  AS homePhone,
    f.mov_phone   AS mobile,
    COALESCE (f.tx_dept,'')||'|'||COALESCE(f.tx_division,'')||'|'||COALESCE(f.tx_location,'') AS postalAddress
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
    COALESCE (f.tx_surname,'(unknown)') AS sn,
    COALESCE (f.tx_surname,f.tx_email) AS displayName,
    f.tx_email    AS mail,
    f.tx_company  AS o,
    f.work_phone  AS telephonenumber,
    f.home_phone  AS homePhone,
    f.mov_phone   AS mobile,
    COALESCE (f.tx_dept,'')||'|'||COALESCE(f.tx_division,'')||'|'||COALESCE(f.tx_location,'') AS postalAddress
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
    COALESCE (a.tx_surname,a.tx_email) AS sn,
    a.tx_email      AS mail,
    a.nm_legal      AS o,
    a.work_phone    AS telephonenumber,
    a.fax_phone     AS facsimileTelephoneNumber,
    a.home_phone    AS homePhone,
    a.mov_phone     AS mobile,
    TRIM(leading FROM COALESCE(a.tp_street,'')||' '||COALESCE(a.nm_street,'')||' '||COALESCE(a.nu_street,'')||'|'||COALESCE(a.tx_addr1,'')||'|'||COALESCE(a.tx_addr2,'')) AS postalAddress,
    a.mn_city       AS l,
    COALESCE(a.nm_state,a.id_state) AS st,
    a.zipcode       AS postalCode
  FROM
    k_domains d, k_workareas w,
    k_member_address a LEFT OUTER JOIN k_users u ON u.gu_user=a.gu_writer
  WHERE
    d.bo_active<>0 AND d.id_domain=w.id_domain AND d.id_domain=u.id_domain AND w.gu_workarea=a.gu_workarea AND w.bo_active<>0 AND a.tx_email IS NOT NULL
GO;

DELETE FROM k_member_address
GO;

INSERT INTO k_member_address SELECT gu_address,ix_address,gu_workarea,gu_company,gu_contact,dt_created,dt_modified,bo_private,gu_writer,tx_name,tx_surname,nm_commercial,nm_legal,id_legal,id_sector,de_title,tr_title,id_status,id_ref,dt_birth,sn_passport,tx_comments,id_gender,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,ny_age,tx_dept,tx_division,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks FROM v_member_address
GO;

DROP TRIGGER k_tr_ins_comp_addr ON k_x_company_addr
GO;

DROP FUNCTION k_sp_ins_comp_addr()
GO;

CREATE FUNCTION k_sp_ins_comp_addr() RETURNS OPAQUE AS '
DECLARE

  GuCompany     CHAR(32);
  NmLegal       VARCHAR(70);
  NmCommercial  VARCHAR(70);
  IdLegal       VARCHAR(16);
  IdSector      VARCHAR(16);
  IdStatus      VARCHAR(30);
  IdRef         VARCHAR(50);
  TpCompany     VARCHAR(30);
  NuEmployees  	INTEGER;
  ImRevenue     FLOAT;
  GuSalesMan    CHAR(32);
  TxFranchise   VARCHAR(100);
  GuGeoZone     CHAR(32);
  DeCompany	VARCHAR(254);

BEGIN
  SELECT gu_company,nm_legal,id_legal,nm_commercial,id_sector,id_status,id_ref,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,de_company
  INTO GuCompany,NmLegal,IdLegal,NmCommercial,IdSector,IdStatus,IdRef,TpCompany,NuEmployees,ImRevenue,GuSalesMan,TxFranchise,GuGeoZone,DeCompany
  FROM k_companies WHERE gu_company=NEW.gu_company;

  UPDATE k_member_address SET gu_company=GuCompany,nm_legal=NmLegal,id_legal=IdLegal,nm_commercial=NmCommercial,id_sector=IdSector,id_ref=IdRef,id_status=IdStatus,tp_company=TpCompany,nu_employees=NuEmployees,im_revenue=ImRevenue,gu_sales_man=GuSalesMan,tx_franchise=TxFranchise,gu_geozone=GuGeoZone,tx_comments=DeCompany
  WHERE gu_address=NEW.gu_address;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql'
GO;

CREATE TRIGGER k_tr_ins_comp_addr AFTER INSERT ON k_x_company_addr FOR EACH ROW EXECUTE PROCEDURE k_sp_ins_comp_addr()
GO;

DROP TRIGGER k_tr_ins_cont_addr ON k_x_contact_addr
GO;
DROP FUNCTION k_sp_ins_cont_addr();
GO;

CREATE FUNCTION k_sp_ins_cont_addr() RETURNS OPAQUE AS '
DECLARE
  GuCompany     CHAR(32);
  GuContact     CHAR(32);
  GuWorkArea    CHAR(32);
  TxName        VARCHAR(100);
  TxSurname     VARCHAR(100);
  DeTitle       VARCHAR(50);
  TrTitle       VARCHAR(50);
  DtBirth       TIMESTAMP;
  SnPassport    VARCHAR(16);
  IdGender      CHAR(1);
  NyAge         SMALLINT;
  TxDept        VARCHAR(70);
  TxDivision    VARCHAR(70);
  TxComments    VARCHAR(254);

BEGIN
  SELECT gu_contact,gu_company,gu_workarea,
         CASE WHEN char_length(tx_name)=0 THEN NULL ELSE tx_name END,
         CASE WHEN char_length(tx_surname)=0 THEN NULL ELSE tx_surname END,
         de_title,dt_birth,sn_passport,id_gender,ny_age,tx_dept,tx_division,tx_comments
  INTO   GuContact,GuCompany,GuWorkArea,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,TxDept,TxDivision,TxComments
  FROM k_contacts WHERE gu_contact=NEW.gu_contact;

  IF DeTitle IS NOT NULL THEN
    SELECT tr_es INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section=''de_title'' AND vl_lookup=DeTitle;
    IF NOT FOUND THEN
      UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,
                                  de_title=DeTitle,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,
                                  ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments
      WHERE gu_address=NEW.gu_address;
    ELSE
      UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,
                                  tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,
                                  tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments
      WHERE gu_address=NEW.gu_address;
    END IF;
  ELSE
      UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,
                                  de_title=NULL,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,
                                  ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments
      WHERE gu_address=NEW.gu_address;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql'
GO;

CREATE TRIGGER k_tr_ins_cont_addr AFTER INSERT ON k_x_contact_addr FOR EACH ROW EXECUTE PROCEDURE k_sp_ins_cont_addr()
GO;


DROP TRIGGER k_tr_ins_address ON k_addresses
GO;
DROP FUNCTION k_sp_ins_address()
GO;

CREATE FUNCTION k_sp_ins_address() RETURNS OPAQUE AS '
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR(70);

BEGIN
  IF NEW.bo_active=1 THEN

    NmLegal := NEW.nm_company;
    IF NmLegal IS NOT NULL AND char_length(NmLegal)=0 THEN
      NmLegal := NULL;
    END IF;

    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=NEW.gu_address;

    IF NOT FOUND THEN
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES
    				   (NEW.gu_address,NEW.ix_address,NEW.gu_workarea,NEW.dt_created,NEW.dt_modified,NEW.gu_user,NmLegal,NEW.tp_location,NEW.tp_street,NEW.nm_street,NEW.nu_street,NEW.tx_addr1,NEW.tx_addr2,COALESCE(NEW.tx_addr1,'''')||CHR(10)||COALESCE(NEW.tx_addr2,''''),NEW.id_country,NEW.nm_country,NEW.id_state,NEW.nm_state,NEW.mn_city,NEW.zipcode,NEW.work_phone,NEW.direct_phone,NEW.home_phone,NEW.mov_phone,NEW.fax_phone,NEW.other_phone,NEW.po_box,NEW.tx_email,NEW.url_addr,NEW.contact_person,NEW.tx_salutation,NEW.tx_remarks);
    END IF;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql'
GO;

CREATE TRIGGER k_tr_ins_address AFTER INSERT ON k_addresses FOR EACH ROW EXECUTE PROCEDURE k_sp_ins_address()
GO;

DROP TRIGGER k_tr_upd_address ON k_addresses
GO;
DROP FUNCTION k_sp_upd_address()
GO;

CREATE FUNCTION k_sp_upd_address() RETURNS OPAQUE AS '
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR(70);

BEGIN
  IF NEW.bo_active=1 THEN
    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=NEW.gu_address;

    NmLegal := NEW.nm_company;
    IF NmLegal IS NOT NULL AND char_length(NmLegal)=0 THEN
      NmLegal := NULL;
    END IF;

    IF NOT FOUND THEN
      INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES
    				   (NEW.gu_address,NEW.ix_address,NEW.gu_workarea,NEW.dt_created,NEW.dt_modified,NEW.gu_user,NmLegal,NEW.tp_location,NEW.tp_street,NEW.nm_street,NEW.nu_street,NEW.tx_addr1,NEW.tx_addr2,COALESCE(NEW.tx_addr1,'''')||CHR(10)||COALESCE(NEW.tx_addr2,''''),NEW.id_country,NEW.nm_country,NEW.id_state,NEW.nm_state,NEW.mn_city,NEW.zipcode,NEW.work_phone,NEW.direct_phone,NEW.home_phone,NEW.mov_phone,NEW.fax_phone,NEW.other_phone,NEW.po_box,NEW.tx_email,NEW.url_addr,NEW.contact_person,NEW.tx_salutation,NEW.tx_remarks);
    ELSE
      UPDATE k_member_address SET ix_address=NEW.ix_address,gu_workarea=NEW.gu_workarea,dt_created=NEW.dt_created,dt_modified=NEW.dt_modified,gu_writer=NEW.gu_user,nm_legal=NmLegal,tp_location=NEW.tp_location,tp_street=NEW.tp_street,nm_street=NEW.nm_street,nu_street=NEW.nu_street,tx_addr1=NEW.tx_addr1,tx_addr2=NEW.tx_addr2,full_addr=COALESCE(NEW.tx_addr1,'''')||CHR(10)||COALESCE(NEW.tx_addr2,''''),id_country=NEW.id_country,nm_country=NEW.nm_country,id_state=NEW.id_state,nm_state=NEW.nm_state,mn_city=NEW.mn_city,zipcode=NEW.zipcode,work_phone=NEW.work_phone,direct_phone=NEW.direct_phone,home_phone=NEW.home_phone,mov_phone=NEW.mov_phone,fax_phone=NEW.fax_phone,other_phone=NEW.other_phone,po_box=NEW.po_box,tx_email=NEW.tx_email,url_addr=NEW.url_addr,contact_person=NEW.contact_person,tx_salutation=NEW.tx_salutation,tx_remarks=NEW.tx_remarks
      WHERE gu_address=NEW.gu_address;
    END IF;
  ELSE
    DELETE FROM k_member_address WHERE gu_address=NEW.gu_address;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql'
GO;

CREATE TRIGGER k_tr_upd_address AFTER UPDATE ON k_addresses FOR EACH ROW EXECUTE PROCEDURE k_sp_upd_address()
GO;


DROP FUNCTION k_sp_del_project (CHAR)
GO;

CREATE FUNCTION k_sp_del_project (CHAR) RETURNS INTEGER AS '
DECLARE
  chldid CHAR(32);
  childs k_projects%ROWTYPE;

BEGIN

  FOR childs IN SELECT * FROM k_projects WHERE id_parent=$1 LOOP
    PERFORM k_sp_del_project (childs.gu_project);
  END LOOP;

  DELETE FROM k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1);
  DELETE FROM k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1);
  DELETE FROM k_duties WHERE gu_project=$1;

  DELETE FROM k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=$1);
  DELETE FROM k_bugs WHERE gu_project=$1;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=$1;

  DELETE FROM k_project_expand WHERE gu_project=$1;
  DELETE FROM k_projects WHERE gu_project=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_contact (CHAR)
GO;

CREATE FUNCTION k_sp_del_contact (CHAR) RETURNS INTEGER AS '
DECLARE
  addr RECORD;
  addrs text;
  aCount INTEGER := 0;

  bank RECORD;
  banks text;
  bCount INTEGER := 0;

  GuWorkArea CHAR(32);

BEGIN

  DELETE FROM k_contacts_recent WHERE gu_contact=$1;

  SELECT gu_workarea INTO GuWorkArea FROM k_contacts WHERE gu_contact=$1;

  FOR addr IN SELECT * FROM k_x_contact_addr WHERE gu_contact=$1 LOOP
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

  FOR bank IN SELECT * FROM k_x_contact_bank WHERE gu_contact=$1 LOOP
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
  addr RECORD;
  addrs text;
  aCount INTEGER := 0;

  bank RECORD;
  banks text;
  bCount INTEGER := 0;

BEGIN

  DELETE FROM k_companies_recent WHERE gu_company=$1;

  FOR addr IN SELECT * FROM k_x_company_addr WHERE gu_company=$1 LOOP
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

  FOR bank IN SELECT * FROM k_x_company_bank WHERE gu_company=$1 LOOP
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

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=$1;

  /* Borrar el enlace con categorías */
  DELETE FROM k_x_cat_objs WHERE gu_object=$1 AND id_class=91;

  DELETE FROM k_x_company_prods WHERE gu_company=$1;
  DELETE FROM k_companies_attrs WHERE gu_object=$1;
  DELETE FROM k_companies WHERE gu_company=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

TRUNCATE TABLE k_member_address
GO;
INSERT INTO k_member_address SELECT gu_address,ix_address,gu_workarea,gu_company,gu_contact,dt_created,dt_modified,bo_private,gu_writer,tx_name,tx_surname,nm_commercial,nm_legal,id_legal,id_sector,de_title,tr_title,id_status,id_ref,dt_birth,sn_passport,tx_comments,id_gender,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,ny_age,tx_dept,tx_division,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks FROM v_member_address
GO;

DROP FUNCTION k_sp_cat_usr_perm (CHAR, CHAR)
GO;

CREATE FUNCTION k_sp_cat_usr_perm (CHAR, CHAR) RETURNS INTEGER AS '
DECLARE
  NoDataFound SMALLINT;
  IdParent CHAR(32);
  IdChild CHAR(32);
  IdACLGroup CHAR(32);
  ACLMask INTEGER;
  groups CURSOR (id CHAR(32)) FOR SELECT gu_acl_group FROM k_x_group_user WHERE gu_user=id;

BEGIN

  IdChild:=$2;

  LOOP
    NoDataFound := 0;

    SELECT acl_mask INTO ACLMask FROM k_x_cat_user_acl WHERE gu_category=IdChild AND gu_user=$1;

    IF NOT FOUND THEN
      ACLMask:=NULL;
      IdParent:=IdChild;

      SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 1;

      IF NOT FOUND THEN
          NoDataFound := 0;
      ELSE
        IF IdParent<>IdChild THEN
          IdChild:=IdParent;
          NoDataFound := 1;
        END IF;
      END IF;
    END IF;

    EXIT WHEN NoDataFound<>1;
  END LOOP;

  IF ACLMask IS NULL THEN
    OPEN groups($1);
      LOOP
        FETCH groups INTO IdACLGroup;
        EXIT WHEN NOT FOUND;

  	IdChild:=$2;

	LOOP
    	  NoDataFound := 0;

          SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdChild AND gu_acl_group=IdACLGroup;

    	  IF NOT FOUND THEN
    	    ACLMask:=NULL;
      	    IdParent:=IdChild;

      	    SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 1;

            IF NOT FOUND THEN
              NoDataFound := 0;
            ELSE
      	      IF IdParent<>IdChild THEN
	        IdChild:=IdParent;
	        NoDataFound := 1;
	      END IF;
            END IF;
          END IF;

          EXIT WHEN NoDataFound<>1;
        END LOOP;

      END LOOP;
    CLOSE groups;
  END IF;

  IF ACLMask IS NULL THEN
    RETURN 0;
  ELSE
    RETURN ACLMask;
  END IF;

END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_get_user_mailroot (CHAR) RETURNS CHAR AS '
DECLARE
  NmDomain   VARCHAR(30);
  TxNickName VARCHAR(32);
  GuUserHome CHAR(32);
  GuMailRoot CHAR(32);
BEGIN
  SELECT u.gu_category,u.tx_nickname,d.nm_domain INTO GuUserHome,TxNickName,NmDomain FROM k_users u,k_domains d WHERE u.gu_user=$1 AND d.id_domain=u.id_domain;

  IF NOT FOUND THEN
    GuMailRoot := NULL;
  ELSE
    SELECT gu_category INTO GuMailRoot FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category=NmDomain||''_''||TxNickName||''_mail'';
    IF NOT FOUND THEN
      SELECT gu_category INTO GuMailRoot FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category LIKE NmDomain||''_%_mail'' ORDER BY dt_created DESC LIMIT 1;
      IF NOT FOUND THEN
        GuMailRoot := NULL;
      END IF;
    END IF;
  END IF;

  RETURN GuMailRoot;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_get_user_mailfolder (CHAR,VARCHAR) RETURNS CHAR AS '
DECLARE
  NmDomain   VARCHAR(30);
  TxNickName VARCHAR(32);
  GuMailRoot CHAR(32);
  GuMailBox  CHAR(32);
BEGIN
  SELECT u.tx_nickname,d.nm_domain INTO TxNickName,NmDomain FROM k_users u,k_domains d WHERE u.gu_user=$1 AND d.id_domain=u.id_domain;

  SELECT k_sp_get_user_mailroot($1) INTO GuMailRoot;

  SELECT gu_category INTO GuMailBox FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuMailRoot AND (nm_category=NmDomain||''_''||TxNickName||''_''||$2 OR nm_category=$2);
  IF NOT FOUND THEN
    SELECT gu_category INTO GuMailRoot FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuMailRoot AND nm_category LIKE NmDomain||''_%_inbox'' ORDER BY dt_created DESC LIMIT 1;
    IF NOT FOUND THEN
      GuMailBox := NULL;
    END IF;
  END IF;

  RETURN GuMailBox;
END;
' LANGUAGE 'plpgsql';
GO;
