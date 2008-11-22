CREATE TABLE k_x_portlet_user (
    id_domain   INTEGER       NOT NULL,
    gu_user     CHAR(32)      NOT NULL,
    gu_workarea CHAR(32)      NOT NULL,
    nm_portlet  VARCHAR2(128) NOT NULL,
    nm_page     VARCHAR2(128) NOT NULL,
    nm_zone     VARCHAR2(16)  DEFAULT 'none',
    od_position INTEGER       DEFAULT 1,
    id_state    VARCHAR2(16)  DEFAULT 'NORMAL',
    dt_modified DATE          DEFAULT SYSDATE,
    nm_template VARCHAR2(254) NULL,  

    CONSTRAINT pk_x_portlet_user PRIMARY KEY(id_domain,gu_user,gu_workarea,nm_portlet,nm_page,nm_zone)  
)
GO;
UPDATE k_categories SET nm_category='MODEL_superuser' WHERE nm_category='MODEL_poweruser'
GO;
INSERT INTO k_apps (id_app,nm_app) VALUES (21,'Hipermail')
GO;
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SEND','SEND MIME MESSAGES BY SMTP','com.knowgate.scheduler.jobs.MimeSender')
GO;
CREATE SEQUENCE seq_mime_msgs INCREMENT BY 1 START WITH 1 MAXVALUE 2147483647 MINVALUE 1
GO;
ALTER TABLE k_categories ADD len_size NUMBER(28) NULL
GO;
ALTER TABLE k_projects ADD dt_scheduled DATE NULL
GO;
ALTER TABLE k_duties ADD dt_scheduled DATE NULL
GO;
ALTER TABLE k_duties ADD gu_contact CHAR(32) NULL
GO;
ALTER TABLE k_bugs ADD gu_writer CHAR(32) NULL
GO;
ALTER TABLE k_bugs ADD tp_bug VARCHAR2(50) NULL
GO;
ALTER TABLE k_bugs ADD dt_since DATE NULL
GO;
ALTER TABLE k_bugs ADD tx_bug_info VARCHAR2(1000) NULL
GO;
ALTER TABLE k_bugs ADD nu_times NUMBER(10) NULL
GO;
ALTER TABLE k_products ADD pr_purchase NUMBER(14,4) NULL
GO;
ALTER TABLE k_cat_labels ADD de_category VARCHAR2(254) NULL
GO;
ALTER TABLE k_pagesets ADD gu_company CHAR(32) NULL
GO;
ALTER TABLE k_pagesets ADD gu_project CHAR(32) NULL
GO;
ALTER TABLE k_lu_job_status ADD tr_ru VARCHAR2(30)  NULL
GO;
ALTER TABLE k_fellows ADD tx_timezone VARCHAR2(16) NULL
GO;
ALTER TABLE k_contacts ADD tx_nickname VARCHAR2(100) NULL
GO;
ALTER TABLE k_contacts ADD tx_pwd VARCHAR2(50) NULL
GO;
ALTER TABLE k_contacts ADD tx_challenge VARCHAR2(100) NULL
GO;
ALTER TABLE k_contacts ADD tx_reply VARCHAR2(100) NULL
GO;
ALTER TABLE k_contacts ADD dt_pwd_expires DATE NULL
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

CREATE OR REPLACE PROCEDURE k_sp_read_pageset (IdPageSet CHAR, IdMicrosite OUT CHAR, NmMicrosite OUT VARCHAR2, IdWorkArea OUT CHAR, NmPageSet OUT VARCHAR2, VsStamp OUT VARCHAR2, IdLanguage OUT CHAR, DtModified OUT DATE, PathData OUT VARCHAR2, IdStatus OUT VARCHAR2, PathMetaData OUT VARCHAR2, TxComments OUT VARCHAR2, GuCompany OUT CHAR, GuProject OUT CHAR) IS
BEGIN
  SELECT m.nm_microsite,m.gu_microsite,p.gu_workarea,p.nm_pageset,p.vs_stamp,p.id_language,p.dt_modified,p.path_data,p.id_status,m.path_metadata,p.tx_comments,p.gu_company,p.gu_project INTO NmMicrosite,IdMicrosite,IdWorkArea,NmPageSet,VsStamp,IdLanguage,DtModified,PathData,IdStatus,PathMetaData,TxComments,GuCompany,GuProject FROM k_pagesets p, k_microsites m WHERE p.gu_pageset=IdPageSet AND p.gu_microsite(+)=m.gu_microsite;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NmMicrosite:=NULL;
    IdMicrosite:=NULL;
    IdWorkArea :=NULL;
    NmPageSet  :=NULL;
    DtModified :=NULL;
    GuCompany  :=NULL;
    GuProject  :=NULL;
END k_sp_read_pageset;
GO;

DROP VIEW v_cat_tree_labels
GO;

CREATE VIEW v_cat_tree_labels AS
SELECT c.gu_category,t.gu_parent_cat,n.id_language,c.nm_category,n.tr_category,c.gu_owner,c.bo_active,c.dt_created,c.dt_modified,c.nm_icon,c.nm_icon2,n.de_category
FROM k_categories c, k_cat_labels n, k_cat_tree t
WHERE c.gu_category=n.gu_category(+) AND t.gu_child_cat=c.gu_category
WITH READ ONLY
GO;

DROP VIEW v_project_company
GO;

CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NVL(d.tx_name,'') || ' ' || NVL(d.tx_surname,'') AS full_name, p.id_status
FROM k_project_expand e, k_contacts d, k_projects p, k_companies c
WHERE p.gu_company=c.gu_company(+) AND e.gu_project=p.gu_project AND d.gu_contact=p.gu_contact)
UNION
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NULL AS full_name, p.id_status
FROM k_project_expand e,
k_projects p, k_companies c
WHERE p.gu_company=c.gu_company(+) AND e.gu_project=p.gu_project AND p.gu_contact IS NULL)
GO;

DROP VIEW v_duty_resource
GO;

CREATE VIEW v_duty_resource AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty, u.tx_nickname AS nm_resource
FROM k_projects p, k_duties b, k_x_duty_resource x, k_users u
WHERE b.gu_duty=x.gu_duty(+) AND p.gu_project=b.gu_project AND x.nm_resource=u.gu_user
UNION
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource
FROM k_projects p, k_duties b, k_x_duty_resource x
WHERE b.gu_duty=x.gu_duty(+) AND p.gu_project=b.gu_project AND NOT EXISTS (SELECT gu_user FROM k_users WHERE gu_user=x.nm_resource)
WITH READ ONLY
GO;

CREATE VIEW v_ldap_users AS
  SELECT
    d.id_domain   AS control_domain_guid,
    d.nm_domain   AS control_domain_name,
    w.nm_workarea AS control_workarea_name,
    w.gu_workarea AS control_workarea_guid,
    u.tx_main_email AS cn,
    u.gu_user     AS "uid",
    u.nm_user     AS givenName,
    u.tx_pwd      AS userPassword,
    RTRIM(NVL (u.tx_surname1,u.tx_nickname)||' '||NVL (u.tx_surname2,'')) AS sn,
    RTRIM(LTRIM(NVL (u.nm_user,'')||' '||NVL (u.tx_surname1,u.tx_nickname)||' '||NVL (u.tx_surname2,''))) AS displayName,
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
    NVL (f.tx_email,u.tx_main_email) AS cn,
    f.gu_fellow   AS "uid",
    f.tx_name     AS givenName,
    u.tx_pwd      AS userPassword,
    NVL (f.tx_surname,u.tx_nickname) AS sn,
    LTRIM(RTRIM(NVL (u.nm_user,'')||' '||NVL (u.tx_surname1,u.tx_surname1)||' '||NVL (u.tx_surname2,''))) AS displayName,
    NVL (f.tx_email,u.tx_main_email) AS mail,
    u.nm_company  AS o,
    f.work_phone  AS telephonenumber,
    f.home_phone  AS homePhone,
    f.mov_phone   AS mobile,
    NVL (f.tx_dept,'')||'|'||NVL(f.tx_division,'')||'|'||NVL(f.tx_location,'') AS postalAddress
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
    f.gu_fellow   AS "uid",
    f.tx_name     AS givenName,
    NULL          AS userPassword,
    NVL (f.tx_surname,'(unknown)') AS sn,
    NVL (f.tx_surname,f.tx_email) AS displayName,
    f.tx_email    AS mail,
    f.tx_company  AS o,
    f.work_phone  AS telephonenumber,
    f.home_phone  AS homePhone,
    f.mov_phone   AS mobile,
    NVL (f.tx_dept,'')||'|'||NVL(f.tx_division,'')||'|'||NVL(f.tx_location,'') AS postalAddress
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
    a.gu_address    AS "uid",
    a.tx_name       AS givenName,
    NVL (a.tx_surname,a.tx_email) AS sn,
    a.tx_email      AS mail,
    a.nm_legal      AS o,
    a.work_phone    AS telephonenumber,
    a.fax_phone     AS facsimileTelephoneNumber,
    a.home_phone    AS homePhone,
    a.mov_phone     AS mobile,
    LTRIM(NVL(a.tp_street,'')||' '||NVL(a.nm_street,'')||' '||NVL(a.nu_street,'')||'|'||NVL(a.tx_addr1,'')||'|'||NVL(a.tx_addr2,'')) AS postalAddress,
    a.mn_city       AS l,
    NVL(a.nm_state,a.id_state) AS st,
    a.zipcode       AS postalCode
  FROM
    k_domains d, k_workareas w, k_users u, k_member_address a
  WHERE
    a.gu_writer(+)=u.gu_user AND d.bo_active<>0 AND d.id_domain=w.id_domain AND d.id_domain=u.id_domain AND w.gu_workarea=a.gu_workarea AND w.bo_active<>0 AND a.tx_email IS NOT NULL
GO;

CREATE OR REPLACE PROCEDURE k_sp_prj_expand (StartWith CHAR) IS

  wlk  NUMBER(11) := 1;
  parent CHAR(32) := NULL;
  curname VARCHAR2(50);

BEGIN

  DELETE k_project_expand WHERE gu_rootprj = StartWith;

  SELECT nm_project INTO curname FROM k_projects WHERE gu_project=StartWith;

  INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (StartWith, StartWith, curname, 1, 1, NULL);

  FOR cRec IN ( SELECT gu_project,nm_project,id_parent,level FROM k_projects
  		START WITH id_parent = StartWith
                CONNECT BY id_parent = PRIOR gu_project)
  LOOP

     IF cRec.id_parent IS NULL AND parent IS NULL THEN
       wlk := wlk + 1;
     ELSIF cRec.id_parent=parent THEN
       wlk := wlk + 1;
     ELSE
       parent := cRec.id_parent;
       wlk := 1;
     END IF;

     INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (StartWith, cRec.gu_project, cRec.nm_project, cRec.level+1, wlk, cRec.id_parent);

  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    curname := NULL;
END k_sp_prj_expand;
GO;

CREATE OR REPLACE TRIGGER k_tr_ins_comp_addr AFTER INSERT ON k_x_company_addr FOR EACH ROW
DECLARE

  GuCompany     CHAR(32);
  NmLegal       VARCHAR2(70);
  NmCommercial  VARCHAR2(70);
  IdLegal       VARCHAR2(16);
  IdSector      VARCHAR2(16);
  IdStatus      VARCHAR2(30);
  IdRef         VARCHAR2(50);
  TpCompany     VARCHAR2(30);
  NuEmployees  	NUMBER;
  ImRevenue     NUMBER;
  GuSalesMan    CHAR(32);
  TxFranchise   VARCHAR2(100);
  GuGeoZone     CHAR(32);
  DeCompany	VARCHAR2(254);

BEGIN
  SELECT gu_company,nm_legal,id_legal,nm_commercial,id_sector,id_status,id_ref,tp_company,nu_employees,im_revenue,gu_sales_man,tx_franchise,gu_geozone,de_company INTO GuCompany,NmLegal,IdLegal,NmCommercial,IdSector,IdStatus,IdRef,TpCompany,NuEmployees,ImRevenue,GuSalesMan,TxFranchise,GuGeoZone,DeCompany FROM k_companies WHERE gu_company=:new.gu_company;

  UPDATE k_member_address SET gu_company=GuCompany,nm_legal=NmLegal,id_legal=IdLegal,nm_commercial=NmCommercial,id_sector=IdSector,id_ref=IdRef,id_status=IdStatus,tp_company=TpCompany,nu_employees=NuEmployees,im_revenue=ImRevenue,gu_sales_man=GuSalesMan,tx_franchise=TxFranchise,gu_geozone=GuGeoZone,tx_comments=DeCompany WHERE gu_address=:new.gu_address;

END k_tr_ins_comp_addr;
GO;

CREATE OR REPLACE TRIGGER k_tr_ins_cont_addr AFTER INSERT ON k_x_contact_addr FOR EACH ROW
DECLARE
  GuContact     CHAR(32);
  GuCompany     CHAR(32);
  GuWorkArea    CHAR(32);
  TxName        VARCHAR2(100);
  TxSurname     VARCHAR2(100);
  DeTitle       VARCHAR2(50);
  TrTitle       VARCHAR2(50);
  DtBirth	DATE;
  SnPassport    VARCHAR2(16);
  IdGender      CHAR(1);
  NyAge         NUMBER;
  TxDept        VARCHAR2(70);
  TxDivision    VARCHAR2(70);
  TxComments	VARCHAR2(254);

BEGIN
  SELECT gu_contact,gu_company,gu_workarea,tx_name,tx_surname,de_title,dt_birth,sn_passport,id_gender,ny_age,tx_dept,tx_division,tx_comments INTO GuContact,GuCompany,GuWorkArea,TxName,TxSurname,DeTitle,DtBirth,SnPassport,IdGender,NyAge,TxDept,TxDivision,TxComments FROM k_contacts WHERE gu_contact=:new.gu_contact;

  IF DeTitle IS NOT NULL THEN
    SELECT tr_es INTO TrTitle FROM k_contacts_lookup WHERE gu_owner=GuWorkArea AND id_section='de_title' AND vl_lookup=DeTitle;
  ELSE
    TrTitle := NULL;
  END IF;

  IF LENGTH(TxName)=0 THEN TxName:=NULL; END IF;
  IF LENGTH(TxSurname)=0 THEN TxSurname:=NULL; END IF;

  UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=TrTitle,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments WHERE gu_address=:new.gu_address;
EXCEPTION
  WHEN NO_DATA_FOUND THEN

    UPDATE k_member_address SET gu_contact=GuContact,gu_company=GuCompany,tx_name=TxName,tx_surname=TxSurname,de_title=DeTitle,tr_title=NULL,dt_birth=DtBirth,sn_passport=SnPassport,id_gender=IdGender,ny_age=NyAge,tx_dept=TxDept,tx_division=TxDivision,tx_comments=TxComments WHERE gu_address=:new.gu_address;
END k_tr_ins_cont_addr;
GO;

CREATE OR REPLACE TRIGGER k_tr_ins_address AFTER INSERT ON k_addresses FOR EACH ROW
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR2(70);

BEGIN
  IF :new.bo_active=1 THEN
    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=:new.gu_address;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    IF LENGTH(:new.nm_company)=0 THEN
      NmLegal := NULL;
    ELSE
      NmLegal := :new.nm_company;
    END IF;

    INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES
    				 (:new.gu_address,:new.ix_address,:new.gu_workarea,:new.dt_created,:new.dt_modified,:new.gu_user,NmLegal,:new.tp_location,:new.tp_street,:new.nm_street,:new.nu_street,:new.tx_addr1,:new.tx_addr2,NVL(:new.tx_addr1,'')||CHR(10)||NVL(:new.tx_addr2,''),:new.id_country,:new.nm_country,:new.id_state,:new.nm_state,:new.mn_city,:new.zipcode,:new.work_phone,:new.direct_phone,:new.home_phone,:new.mov_phone,:new.fax_phone,:new.other_phone,:new.po_box,:new.tx_email,:new.url_addr,:new.contact_person,:new.tx_salutation,:new.tx_remarks);
END k_tr_ins_address;
GO;

CREATE OR REPLACE TRIGGER k_tr_upd_address AFTER UPDATE ON k_addresses FOR EACH ROW
DECLARE
  AddrId CHAR(32);
  NmLegal VARCHAR2(70);

BEGIN
  IF :new.bo_active=1 THEN
    SELECT gu_address INTO AddrId FROM k_member_address WHERE gu_address=:new.gu_address;

    IF LENGTH(:new.nm_company)=0 THEN
      NmLegal := NULL;
    ELSE
      NmLegal := :new.nm_company;
    END IF;

    UPDATE k_member_address SET ix_address=:new.ix_address,gu_workarea=:new.gu_workarea,dt_created=:new.dt_created,dt_modified=:new.dt_modified,gu_writer=:new.gu_user,nm_legal=NmLegal,tp_location=:new.tp_location,tp_street=:new.tp_street,nm_street=:new.nm_street,nu_street=:new.nu_street,tx_addr1=:new.tx_addr1,tx_addr2=:new.tx_addr2,full_addr=NVL(:new.tx_addr1,'')||CHR(10)||NVL(:new.tx_addr2,''),id_country=:new.id_country,nm_country=:new.nm_country,id_state=:new.id_state,nm_state=:new.nm_state,mn_city=:new.mn_city,zipcode=:new.zipcode,work_phone=:new.work_phone,direct_phone=:new.direct_phone,home_phone=:new.home_phone,mov_phone=:new.mov_phone,fax_phone=:new.fax_phone,other_phone=:new.other_phone,po_box=:new.po_box,tx_email=:new.tx_email,url_addr=:new.url_addr,contact_person=:new.contact_person,tx_salutation=:new.tx_salutation,tx_remarks=:new.tx_remarks
    WHERE gu_address=:new.gu_address;
  ELSE
    DELETE FROM k_member_address WHERE gu_address=:new.gu_address;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    INSERT INTO k_member_address (gu_address,ix_address,gu_workarea,dt_created,dt_modified,gu_writer,nm_legal,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,full_addr,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,url_addr,contact_person,tx_salutation,tx_remarks) VALUES (:new.gu_address,:new.ix_address,:new.gu_workarea,:new.dt_created,:new.dt_modified,:new.gu_user,:new.nm_company,:new.tp_location,:new.tp_street,:new.nm_street,:new.nu_street,:new.tx_addr1,:new.tx_addr2,NVL(:new.tx_addr1,'')||CHR(10)||NVL(:new.tx_addr2,''),:new.id_country,:new.nm_country,:new.id_state,:new.nm_state,:new.mn_city,:new.zipcode,:new.work_phone,:new.direct_phone,:new.home_phone,:new.mov_phone,:new.fax_phone,:new.other_phone,:new.po_box,:new.tx_email,:new.url_addr,:new.contact_person,:new.tx_salutation,:new.tx_remarks);
END k_tr_upd_address;
GO;

CREATE OR REPLACE PROCEDURE k_sp_autenticate (IdUser CHAR, PwdText VARCHAR2, CoStatus OUT NUMBER) IS
  Password VARCHAR2(50);
  Activated NUMBER(6);
  DtCancel DATE;
  DtExpire DATE;
BEGIN

  CoStatus :=1;

  SELECT tx_pwd,bo_active,dt_cancel,dt_pwd_expires INTO Password,Activated,DtCancel,DtExpire FROM k_users WHERE gu_user=IdUser;

    IF Password<>PwdText THEN
      CoStatus:=-2;
    ELSE
      IF Activated=0 THEN
        CoStatus:=-3;
      END IF;

      IF SYSDATE>DtCancel THEN
	CoStatus:=-8;
      END IF;

      IF SYSDATE>DtExpire THEN
        CoStatus:=-9;
      END IF;
    END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    CoStatus:=-1;
END k_sp_autenticate;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_project (ProjId CHAR) IS
  chldid CHAR(32);
  CURSOR childs(id CHAR) IS SELECT gu_project FROM k_projects START WITH id_parent=id CONNECT BY id_parent = PRIOR gu_project;

BEGIN
  /* Borrar primero los proyectos hijos */
  OPEN childs(ProjId);
    LOOP
      FETCH childs INTO chldid;
      EXIT WHEN childs%NOTFOUND;
    END LOOP;
  CLOSE childs;

  DELETE k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId);
  DELETE k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId);
  DELETE k_duties WHERE gu_project=ProjId;

  DELETE k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ProjId);
  DELETE k_bugs WHERE gu_project=ProjId;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=ProjId;

  DELETE k_project_expand WHERE gu_project=ProjId;
  DELETE k_projects WHERE gu_project=ProjId;
END k_sp_del_project;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_company (CompanyId CHAR) IS
  TYPE GUIDS IS TABLE OF k_addresses.gu_address%TYPE;
  TYPE BANKS IS TABLE OF k_bank_accounts.nu_bank_acc%TYPE;

  k_tmp_del_addr GUIDS := GUIDS();
  k_tmp_del_bank BANKS := BANKS();

  GuWorkArea CHAR(32);

BEGIN
  DELETE k_companies_recent WHERE gu_company=CompanyId;

  SELECT gu_workarea INTO GuWorkArea FROM k_companies WHERE gu_company=CompanyId;

  /* Borrar las direcciones de la compañia */
  FOR addr IN ( SELECT gu_address FROM k_x_company_addr WHERE gu_company=CompanyId) LOOP
    k_tmp_del_addr.extend;
    k_tmp_del_addr(k_tmp_del_addr.count) := addr.gu_address;
  END LOOP;

  DELETE k_x_company_addr WHERE gu_company=CompanyId;

  FOR a IN 1..k_tmp_del_addr.COUNT LOOP
    DELETE k_addresses WHERE gu_address=k_tmp_del_addr(a);
  END LOOP;

  /* Borrar las cuentas bancarias de la compañia */

  FOR bank IN ( SELECT nu_bank_acc FROM k_x_company_bank WHERE gu_company=CompanyId) LOOP
    k_tmp_del_bank.extend;
    k_tmp_del_bank(k_tmp_del_bank.count) := bank.nu_bank_acc;
  END LOOP;

  DELETE k_x_company_bank WHERE gu_company=CompanyId;

  FOR a IN 1..k_tmp_del_bank.COUNT LOOP
    DELETE k_bank_accounts WHERE nu_bank_acc=k_tmp_del_bank(a);
  END LOOP;

  /* Borrar las oportunidades */
  DELETE k_oportunities_attrs WHERE gu_object IN (SELECT gu_oportunity FROM k_oportunities WHERE gu_company=CompanyId);
  DELETE k_oportunities WHERE gu_company=CompanyId;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_company=NULL WHERE gu_company=CompanyId;

  /* Borrar el enlace con categorías */
  DELETE k_x_cat_objs WHERE gu_object=CompanyId AND id_class=91;

  DELETE k_x_company_prods WHERE gu_company=CompanyId;
  DELETE k_companies_attrs WHERE gu_object=CompanyId;
  DELETE k_companies WHERE gu_company=CompanyId;
END k_sp_del_company;
GO;

TRUNCATE TABLE k_member_address
GO;
INSERT INTO K_MEMBER_ADDRESS SELECT GU_ADDRESS,IX_ADDRESS,GU_WORKAREA,GU_COMPANY,GU_CONTACT,DT_CREATED,DT_MODIFIED,BO_PRIVATE,GU_WRITER,TX_NAME,TX_SURNAME,NM_COMMERCIAL,NM_LEGAL,ID_LEGAL,ID_SECTOR,DE_TITLE,TR_TITLE,ID_STATUS,ID_REF,DT_BIRTH,SN_PASSPORT,TX_COMMENTS,ID_GENDER,TP_COMPANY,NU_EMPLOYEES,IM_REVENUE,GU_SALES_MAN,TX_FRANCHISE,GU_GEOZONE,NY_AGE,TX_DEPT,TX_DIVISION,TP_LOCATION,TP_STREET,NM_STREET,NU_STREET,TX_ADDR1,TX_ADDR2,FULL_ADDR,ID_COUNTRY,NM_COUNTRY,ID_STATE,NM_STATE,MN_CITY,ZIPCODE,WORK_PHONE,DIRECT_PHONE,HOME_PHONE,MOV_PHONE,FAX_PHONE,OTHER_PHONE,PO_BOX,TX_EMAIL,URL_ADDR,CONTACT_PERSON,TX_SALUTATION,TX_REMARKS FROM V_MEMBER_ADDRESS
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_usr_perm (IdUser CHAR, IdCategory CHAR, ACLMask OUT NUMBER) IS
  NoDataFound NUMBER(1);
  IdParent CHAR(32);
  IdChild CHAR(32);
  IdACLGroup CHAR(32);
  CURSOR groups (id CHAR) IS SELECT gu_acl_group FROM k_x_group_user WHERE gu_user=id;

BEGIN
  ACLMask:=NULL;
  IdChild:=IdCategory;

  LOOP
    NoDataFound := 0;
    BEGIN
      SELECT acl_mask INTO ACLMask FROM k_x_cat_user_acl WHERE gu_category=IdChild AND gu_user=IdUser;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        IdParent:=IdChild;
        BEGIN
          SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild AND ROWNUM=1;

          IF IdParent<>IdChild THEN
            IdChild:=IdParent;
            NoDataFound := 1;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NoDataFound := 0;
        END;
    END;
    EXIT WHEN NoDataFound<>1;
  END LOOP;

  IF ACLMask IS NULL THEN
    OPEN groups(IdUser);
      LOOP
        FETCH groups INTO IdACLGroup;
        EXIT WHEN groups%NOTFOUND;
        IdChild:=IdCategory;
        LOOP
          NoDataFound := 0;
          BEGIN
            SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdChild AND gu_acl_group=IdACLGroup;

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
              IdParent:=IdChild;
              BEGIN
                SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild AND ROWNUM=1;
                IF IdParent<>IdChild THEN
                  IdChild:=IdParent;
                  NoDataFound := 1;
                END IF;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              NoDataFound := 0;
            END;
          END;

          EXIT WHEN NoDataFound<>1;
        END LOOP;

      END LOOP;
    CLOSE groups;
  END IF;

  ACLMask := NVL(ACLMask, 0);

END k_sp_cat_usr_perm;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_fellow (FellowId CHAR) IS
  MeetingId CHAR(32);
  CURSOR meetings(id CHAR) IS SELECT gu_meeting FROM k_x_meeting_fellow WHERE gu_fellow=id;
BEGIN
  OPEN meetings(FellowId);
    LOOP
      FETCH meetings INTO MeetingId;
      EXIT WHEN meetings%NOTFOUND;
      k_sp_del_meeting (MeetingId);
    END LOOP;
  CLOSE meetings;

  DELETE k_fellows_attach WHERE gu_fellow=FellowId;
  DELETE k_fellows WHERE gu_fellow=FellowId;
END k_sp_del_fellow;
GO;

CREATE OR REPLACE PROCEDURE k_sp_get_user_mailroot (GuUser CHAR, GuCategory OUT CHAR) IS
  NmDomain   VARCHAR2(30);
  GuUserHome CHAR(32);
  TxNickName VARCHAR2(32);
  NmCategory VARCHAR2(100);
BEGIN

  SELECT u.gu_category,u.tx_nickname,d.nm_domain INTO GuUserHome,TxNickName,NmDomain FROM k_users u,k_domains d WHERE u.gu_user=GuUser AND d.id_domain=u.id_domain;

  BEGIN
    SELECT gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category=NmDomain||'_'||TxNickName||'_mail';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      SELECT gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category LIKE NmDomain||'_%_mail' AND ROWNUM=1 ORDER BY dt_created DESC;
  END;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    GuCategory:=NULL;
END k_sp_get_user_mailroot;
GO;

CREATE OR REPLACE PROCEDURE k_sp_get_user_mailfolder (GuUser CHAR, NmFolder VARCHAR2, GuCategory OUT CHAR) IS
  NmDomain   VARCHAR2(30);
  NickName   VARCHAR2(32);
  NmCategory VARCHAR2(100);
  GuMailRoot CHAR(32);
BEGIN

  SELECT u.tx_nickname,nm_domain INTO NickName,NmDomain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=GuUser;

  k_sp_get_user_mailroot (GuUser,GuMailRoot);

  IF GuMailRoot IS NULL THEN
    GuCategory:=NULL;
  ELSE
    SELECT c.gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuMailRoot AND (c.nm_category=NmDomain || '_' || NickName || '_' || NmFolder OR c.nm_category=NmFolder);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    GuCategory:=NULL;
END k_sp_get_user_mailfolder;
GO;