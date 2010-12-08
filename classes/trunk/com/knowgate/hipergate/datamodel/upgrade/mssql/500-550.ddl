UPDATE k_version SET vs_stamp='5.5.0';

ALTER TABLE k_version ADD bo_allow_stats SMALLINT DEFAULT 0;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_adhoc_mail', 1, 2147483647, 1, 1);

ALTER TABLE k_meetings_lookup ADD tr_ko VARCHAR(50) NULL;

ALTER TABLE k_activities ADD gu_address CHAR(32) NULL;
ALTER TABLE k_activities ADD gu_campaign CHAR(32) NULL;
ALTER TABLE k_activities ADD gu_list CHAR(32) NULL;
ALTER TABLE k_activities ADD gu_writer CHAR(32) NULL;
ALTER TABLE k_activities ADD gu_meeting CHAR(32) NULL;
ALTER TABLE k_activities ADD gu_pageset CHAR(32) NULL;
ALTER TABLE k_activities ADD gu_mailing CHAR(32) NULL;
ALTER TABLE k_activities ADD dt_mailing DATETIME NULL;
ALTER TABLE k_activities ADD tx_subject NVARCHAR(254) NULL;
ALTER TABLE k_activities ADD tx_email_from VARCHAR(254) NULL;
ALTER TABLE k_activities ADD nm_from NVARCHAR(254) NULL;
ALTER TABLE k_activities ADD url_activity VARCHAR(254) NULL;
ALTER TABLE k_activities ADD nm_author NVARCHAR(200) NULL;
ALTER TABLE k_activities ADD pg_activity INTEGER NULL;
ALTER TABLE k_activities ADD id_language CHAR(2) NULL;

ALTER TABLE k_adhoc_mailings ADD bo_urgent SMALLINT DEFAULT 0;
ALTER TABLE k_adhoc_mailings ADD bo_reminder SMALLINT DEFAULT 0;

ALTER TABLE k_pagesets ADD bo_urgent SMALLINT DEFAULT 0;

ALTER TABLE k_contacts ADD url_linkedin VARCHAR(254) NULL;
ALTER TABLE k_contacts ADD url_facebook VARCHAR(254) NULL;

INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('NOPO','NEW OPORTUNITY','com.knowgate.scheduler.events.DoNothing');

INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('MOPO','MODIFY OPORTUNITY','com.knowgate.scheduler.events.DoNothing');

ALTER TABLE k_prod_attr ADD format VARCHAR(50) NULL;

ALTER TABLE k_education_degree ADD id_country CHAR(3) NULL;
ALTER TABLE k_contact_education ADD pg_product INTEGER NULL;
ALTER TABLE k_contact_education ADD gu_product CHAR(32);

CREATE TABLE k_oportunities_attachs
(
gu_oportunity CHAR(32)     NOT NULL,
pg_product    INTEGER      NOT NULL,
gu_product    CHAR(32)     NOT NULL,
dt_created    DATETIME     DEFAULT GETDATE(),
gu_writer     CHAR(32)     NOT NULL,

CONSTRAINT pk_oportunities_attachs PRIMARY KEY (gu_oportunity,pg_product)
)
GO;

CREATE TABLE k_x_adhoc_mailing_list (
  gu_list    CHAR(32) NOT NULL,
  gu_mailing CHAR(32) NOT NULL,
  CONSTRAINT pk_x_adhoc_mailing_list PRIMARY KEY (gu_list,gu_mailing)
)
GO;

DROP PROCEDURE k_sp_del_list
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
      DELETE k_lists WHERE gu_list=@bk
    END
    
  DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_x_list_members WHERE gu_list=@ListId

  DELETE k_x_campaign_lists WHERE gu_list=@ListId

  DELETE k_x_adhoc_mailing_list WHERE gu_list=@ListId

  UPDATE k_activities SET gu_list=NULL WHERE gu_list=@ListId
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=@ListId

  DELETE k_lists WHERE gu_list=@ListId
GO;

CREATE PROCEDURE k_sp_del_adhoc_mailing @AdHocId CHAR(32) AS
  DELETE k_x_adhoc_mailing_list WHERE gu_mailing=@AdHocId;
  DELETE k_adhoc_mailings WHERE gu_mailing=@AdHocId;
GO;

CREATE TABLE k_activity_attachs
(
gu_activity  CHAR(32)     NOT NULL,
pg_product   INTEGER      NOT NULL,
gu_product   CHAR(32)     NOT NULL,
dt_created   DATETIME     DEFAULT GETDATE(),
gu_writer    CHAR(32)     NOT NULL,

CONSTRAINT pk_activity_attachs PRIMARY KEY (gu_activity,pg_product)
)
GO;

DROP PROCEDURE k_sp_del_activity
GO;

CREATE PROCEDURE k_sp_del_activity @ActivtyId CHAR(32) AS
  DELETE k_activity_attachs WHERE gu_activity=@ActivtyId
  DELETE k_x_activity_audience WHERE gu_activity=@ActivtyId
  DELETE k_activities WHERE gu_activity=@ActivtyId
GO;

CREATE VIEW v_activity_locat AS
SELECT p.gu_product, p.nm_product, p.de_product, c.gu_activity, c.pg_product, c.dt_created, l.dt_modified, l.dt_uploaded, l.gu_location, l.id_cont_type, l.id_prod_type, l.len_file, l.xprotocol, l.xhost, l.xport, l.xpath, l.xfile, l.xoriginalfile, l.xanchor, l.status, l.vs_stamp, l.tx_email, l.tag_prod_locat
FROM k_activity_attachs c, k_products p, k_prod_locats l
WHERE c.gu_product=p.gu_product AND c.gu_product=l.gu_product
GO;

DROP PROCEDURE k_sp_del_product
GO;

CREATE PROCEDURE k_sp_del_product @IdProduct CHAR(32) AS
  DECLARE @GuAddress CHAR(32)
  SELECT @GuAddress=gu_address FROM k_products WHERE gu_product=@IdProduct OPTION (FAST 1)
  DELETE FROM k_images WHERE gu_product=@IdProduct
  DELETE FROM k_x_cat_objs WHERE gu_object=@IdProduct
  DELETE FROM k_prod_keywords WHERE gu_product=@IdProduct
  DELETE FROM k_prod_fares WHERE gu_product=@IdProduct
  DELETE FROM k_prod_attrs WHERE gu_object=@IdProduct
  DELETE FROM k_prod_attr WHERE gu_product=@IdProduct
  DELETE FROM k_prod_locats WHERE gu_product=@IdProduct
  DELETE FROM k_products WHERE gu_product=@IdProduct
  IF @GuAddress IS NOT NULL
    BEGIN
      UPDATE k_academic_courses SET gu_address=NULL WHERE gu_acourse=@IdProduct
      DELETE FROM k_addresses WHERE gu_address=@GuAddress
    END
GO;

DROP PROCEDURE k_sp_del_acourse
GO;

CREATE PROCEDURE k_sp_del_acourse @CourseId CHAR(32) AS
  DECLARE @GuAddress CHAR(32)
  SELECT @GuAddress=gu_address gu_address FROM k_academic_courses WHERE gu_acourse=@CourseId
  DELETE k_x_course_alumni WHERE gu_acourse=@CourseId
  DELETE k_x_course_bookings WHERE gu_acourse=@CourseId
  DELETE k_evaluations WHERE gu_acourse=@CourseId
  DELETE k_absentisms WHERE gu_acourse=@CourseId
  DELETE k_academic_courses WHERE gu_acourse=@CourseId
  IF @GuAddress IS NOT NULL
    DELETE FROM k_addresses WHERE gu_address=@GuAddress
GO;

CREATE TABLE k_admission (
  gu_admission		CHAR(32)    	NOT NULL,
  gu_contact		CHAR(32)    	NOT NULL,
  gu_oportunity		CHAR(32)    	NOT NULL,
  gu_workarea    	CHAR(32)		NOT NULL,
  gu_acourse    	CHAR(32)		NOT NULL,
  id_objetive_1		VARCHAR(50)		NULL, /*Program in which admission sought 1*/
  id_objetive_2		VARCHAR(50) 	NULL, /*Program in which admission sought 2*/
  id_objetive_3		VARCHAR(50) 	NULL, /*Program in which admission sought 3*/
  dt_created     	DATETIME 		DEFAULT GETDATE(),/*admission application date*/
  dt_target      	DATETIME 		NULL, /*Target date for the admission test*/
  is_call			SMALLINT		NULL, /*Call Meeting (Yes) or Special (No) admission test*/
  id_place    		VARCHAR(50) 	NULL, /*Place of entrance examinations*/
  id_interviewer   	VARCHAR(50) 	NULL, /*Name of interviewer*/
  dt_interview     	DATETIME 		NULL, /*Date of completion of the interview*/
  dt_admision_test 	DATETIME 		NULL, /*Actual date for the admission test*/
  is_grant			SMALLINT		NULL, /*Grant Request (Yes / No)*/
  nu_grant        	DECIMAL(4,2)	NULL, /*The amount or percentage of scholarship*/
  nu_interview     	INTEGER         NULL, /*points interview */
  nu_vips   	  	INTEGER         NULL, /*points vips */
  nu_nips	     	INTEGER         NULL, /*points nips */
  nu_elp	     	INTEGER         NULL, /*points elp */
  nu_total	     	INTEGER         NULL, /*points total */
  id_test_result 	VARCHAR(50)		NULL, /*Test result (Admitted, admitted conditionally, not supported)*/
  CONSTRAINT pk_admission PRIMARY KEY (gu_admission),
  CONSTRAINT u_admission UNIQUE (gu_contact,gu_oportunity)
)
GO;

CREATE TABLE k_admission_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section VARCHAR(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  NVARCHAR(50)     NULL,
tr_es      NVARCHAR(50)     NULL,
tr_en      NVARCHAR(50)     NULL,
tr_de      NVARCHAR(50)     NULL,
tr_it      NVARCHAR(50)     NULL,
tr_fr      NVARCHAR(50)     NULL,
tr_pt      NVARCHAR(50)     NULL,
tr_ca      NVARCHAR(50)     NULL,
tr_gl      NVARCHAR(50)     NULL,
tr_eu      NVARCHAR(50)     NULL,
tr_ja      NVARCHAR(50)     NULL,
tr_cn      NVARCHAR(50)     NULL,
tr_tw      NVARCHAR(50)     NULL,
tr_fi      NVARCHAR(50)     NULL,
tr_ru      NVARCHAR(50)     NULL,
tr_nl      NVARCHAR(50)     NULL,
tr_th      NVARCHAR(50)     NULL,
tr_cs      NVARCHAR(50)     NULL,
tr_uk      NVARCHAR(50)     NULL,
tr_no      NVARCHAR(50)     NULL,
tr_sk      NVARCHAR(50)     NULL,
tr_pl      NVARCHAR(50)     NULL,
tr_vn      NVARCHAR(50)     NULL,

CONSTRAINT pk_admission_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

DROP VIEW v_pagesets_mailings
GO;

CREATE VIEW v_pagesets_mailings AS
(SELECT
p.gu_pageset,p.gu_workarea,p.nm_pageset,p.tx_comments,p.path_data,p.dt_created,m.nm_microsite,p.id_status,p.id_language,m.id_app,p.bo_urgent,NULL AS dt_execution
FROM k_pagesets p,k_microsites m WHERE p.gu_microsite=m.gu_microsite OR p.gu_microsite IS NULL)
UNION
(SELECT
a.gu_mailing AS gu_pageset,a.gu_workarea,a.nm_mailing AS nm_pageset,a.tx_subject AS tx_comments ,'Hipermail' AS path_data,a.dt_created,'AdHoc' AS nm_microsite,a.id_status,'' AS id_language,21 AS id_app,a.bo_urgent,a.dt_execution
FROM k_adhoc_mailings a)
GO;

DELETE FROM k_lu_job_commands WHERE id_command='SMS'
GO;
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SMS','SEND SMS PUSH TEXT MESSAGE','com.knowgate.scheduler.jobs.SMSSender')
GO;

CREATE TABLE k_urls
(
gu_url CHAR(32) NOT NULL,
gu_workarea CHAR(32) NOT NULL,
url_addr VARCHAR(2000) NOT NULL,
tx_title NVARCHAR(2000) NULL,
de_url NVARCHAR(2000) NULL,
CONSTRAINT pk_urls PRIMARY KEY(gu_url,gu_workarea)
)
GO;

CREATE TABLE k_job_atoms_clicks
(
gu_job         CHAR(32)   NOT NULL,
pg_atom        INTEGER    NOT NULL,
gu_url         CHAR(32)   NOT NULL,
dt_action      DATETIME   DEFAULT CURRENT_TIMESTAMP,
id_status      SMALLINT   DEFAULT 1,
gu_company     CHAR(32)     NULL,
gu_contact     CHAR(32)     NULL,
ip_addr        VARCHAR(16) NULL,
tx_email       VARCHAR(100) NULL
)
GO;

DROP PROCEDURE k_sp_del_job
GO;

CREATE PROCEDURE k_sp_del_job @IdJob CHAR(32) AS
  DELETE FROM k_job_atoms_clicks WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_tracking WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_archived WHERE gu_job=@IdJob
  DELETE k_job_atoms WHERE gu_job=@IdJob
  DELETE k_jobs WHERE gu_job=@IdJob
GO;

CREATE TABLE k_bulkloads (
pg_bulkload   INTEGER  NOT NULL,
dt_uploaded   DATETIME NOT NULL,
gu_workarea   CHAR(32) NOT NULL,
nm_file       VARCHAR(254) NOT NULL,
id_batch      VARCHAR(32)  NULL,
id_status     VARCHAR(30)  NULL,
dt_processed  DATETIME NOT NULL,
nu_lines      INTEGER DEFAULT 0,
nu_successful INTEGER DEFAULT 0,
nu_errors     INTEGER DEFAULT 0,
CONSTRAINT pk_bulkloads PRIMARY KEY(pg_bulkload),
CONSTRAINT u1_bulkloads UNIQUE(dt_uploaded,gu_workarea,nm_file)
)
GO;