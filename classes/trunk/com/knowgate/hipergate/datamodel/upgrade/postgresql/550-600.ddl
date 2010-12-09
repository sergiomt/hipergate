UPDATE k_version SET vs_stamp='6.0.0'
GO;

ALTER TABLE k_x_list_members ADD tx_info VARCHAR(254) NULL
GO;

ALTER TABLE k_pagesets ADD tx_email_from VARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD tx_email_reply VARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD nm_from VARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD tx_subject VARCHAR(254) NULL
GO;
ALTER TABLE k_meetings ADD id_icalendar VARCHAR(255) NULL
GO;
CREATE INDEX i4_meetings ON k_meetings(id_icalendar);
GO;
ALTER TABLE k_jobs ADD nu_sent INTEGER DEFAULT 0
GO;
ALTER TABLE k_jobs ADD nu_opened INTEGER DEFAULT 0
GO;
ALTER TABLE k_jobs ADD nu_unique INTEGER DEFAULT 0
GO;
ALTER TABLE k_jobs ADD nu_clicks INTEGER DEFAULT 0
GO;

ALTER TABLE k_urls ADD nu_clicks INTEGER DEFAULT 0
GO;
ALTER TABLE k_urls ADD dt_last_visit TIMESTAMP NULL
GO;

ALTER TABLE k_contacts ADD url_twitter VARCHAR(254) NULL
GO;

CREATE TABLE k_jobs_atoms_by_day
(
dt_execution  CHAR(10)    NOT NULL,
gu_job        CHAR(32)    NOT NULL,
gu_workarea   CHAR(32)    NOT NULL,
gu_job_group  CHAR(32)        NULL,
nu_msgs       INTEGER    DEFAULT 0,
CONSTRAINT pk_jobs_atoms_by_day PRIMARY KEY(dt_execution,gu_job)
)  
GO;

CREATE TABLE k_jobs_atoms_by_hour
(
dt_hour       SMALLINT    NOT NULL,
gu_job        CHAR(32)    NOT NULL,
gu_workarea   CHAR(32)    NOT NULL,
gu_job_group  CHAR(32)        NULL,
nu_msgs       INTEGER    DEFAULT 0,
CONSTRAINT pk_jobs_atoms_by_hour PRIMARY KEY(dt_hour,gu_job)
)  
GO;

CREATE TABLE k_jobs_atoms_by_agent
(
id_agent      VARCHAR(50) NOT NULL,
gu_job        CHAR(32)    NOT NULL,
gu_workarea   CHAR(32)    NOT NULL,
gu_job_group  CHAR(32)        NULL,
nu_msgs       INTEGER    DEFAULT 0,
CONSTRAINT pk_jobs_atoms_by_agent PRIMARY KEY(id_agent,gu_job)
)  
GO;

DROP FUNCTION k_sp_del_job (CHAR)
GO;

CREATE FUNCTION k_sp_del_job (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_jobs_atoms_by_agent WHERE gu_job=$1;
  DELETE FROM k_jobs_atoms_by_hour WHERE gu_job=$1;
  DELETE FROM k_jobs_atoms_by_day WHERE gu_job=$1;
  DELETE FROM k_job_atoms_clicks WHERE gu_job=$1;
  DELETE FROM k_job_atoms_tracking WHERE gu_job=$1;
  DELETE FROM k_job_atoms_archived WHERE gu_job=$1;
  DELETE FROM k_job_atoms WHERE gu_job=$1;
  DELETE FROM k_jobs WHERE gu_job=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_duplicates (CHAR) RETURNS INTEGER AS '
DECLARE
  deleted INTEGER;
  txemail VARCHAR(100);
  tmpmail VARCHAR(100);
  members NO SCROLL CURSOR (gu CHAR(32)) IS SELECT tx_email FROM k_x_list_members WHERE gu_list = gu;
BEGIN
  CREATE TEMPORARY TABLE k_temp_list_emails (tx_email VARCHAR(100) CONSTRAINT pk_temp_list_emails PRIMARY KEY) ON COMMIT DROP;
  INSERT INTO k_temp_list_emails SELECT DISTINCT(tx_email) FROM k_x_list_members WHERE gu_list=$1;
  deleted:=0;
  OPEN members($1);
  FETCH members INTO txemail;
  WHILE FOUND LOOP
    tmpmail:=NULL;
    DELETE FROM k_temp_list_emails WHERE tx_email=txemail RETURNING tx_email INTO tmpmail;
    IF tmpmail IS NULL THEN
      deleted:=deleted+1;
      DELETE FROM k_x_list_members WHERE CURRENT OF members;
    END IF;
    FETCH members INTO txemail;
  END LOOP;
  CLOSE members;
  DROP TABLE k_temp_list_emails;
  return deleted;
END;
' LANGUAGE 'plpgsql';
GO;

DROP FUNCTION k_sp_del_list (CHAR) 
GO;

CREATE FUNCTION k_sp_del_list (CHAR) RETURNS INTEGER AS '
DECLARE
  tp SMALLINT;
  wa CHAR(32);
  bk CHAR(32);
BEGIN

  SELECT tp_list,gu_workarea INTO tp,wa FROM k_lists WHERE gu_list=$1;

  SELECT gu_list INTO bk FROM k_lists WHERE gu_workarea=wa AND gu_query=$1 AND tp_list=4;

  IF FOUND THEN
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);
    DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=bk) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>bk);

    DELETE FROM k_x_list_members WHERE gu_list=bk;

    DELETE FROM k_x_campaign_lists WHERE gu_list=bk;

    DELETE FROM k_x_adhoc_mailing_list WHERE gu_list=bk;

    DELETE FROM k_lists WHERE gu_list=bk;
  END IF;

  DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=$1) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>$1);

  DELETE FROM k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=$1) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=wa AND x.gu_list<>$1);

  DELETE FROM k_x_list_members WHERE gu_list=$1;

  DELETE FROM k_x_campaign_lists WHERE gu_list=$1;

  DELETE FROM k_x_adhoc_mailing_list WHERE gu_list=$1;

  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  UPDATE k_activities SET gu_list=NULL WHERE gu_list=$1;
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=$1;

  DELETE FROM k_lists WHERE gu_list=$1;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

ALTER TABLE k_bulkloads ADD de_file VARCHAR(254) NULL
GO;
ALTER TABLE k_bulkloads ADD tp_batch VARCHAR(32) NULL
GO;

CREATE TABLE k_x_user_acourse
(
gu_acourse   CHAR(32) NOT NULL,
gu_user      CHAR(32) NOT NULL,
dt_created   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
bo_admin     SMALLINT DEFAULT 0,
bo_user      SMALLINT DEFAULT 1,

CONSTRAINT pk_x_user_acourse PRIMARY KEY (gu_acourse,gu_user),
CONSTRAINT f1_x_user_acourse FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses(gu_acourse),
CONSTRAINT f2_x_user_acourse FOREIGN KEY (gu_user) REFERENCES k_users(gu_user)
)
GO;

DROP FUNCTION k_sp_del_acourse (CHAR) 
GO;

CREATE FUNCTION k_sp_del_acourse (CHAR) RETURNS INTEGER AS '
DECLARE
  GuAddress CHAR(32);
BEGIN
  SELECT gu_address INTO GuAddress FROM k_academic_courses WHERE gu_acourse=$1;
  DELETE FROM k_x_user_acourse WHERE gu_acourse=$1;
  DELETE FROM k_x_course_alumni WHERE gu_acourse=$1;
  DELETE FROM k_x_course_bookings WHERE gu_acourse=$1;
  DELETE FROM k_evaluations WHERE gu_acourse=$1;
  DELETE FROM k_absentisms WHERE gu_acourse=$1;
  DELETE FROM k_academic_courses WHERE gu_acourse=$1;
  IF GuAddress IS NOT NULL THEN
    DELETE FROM k_addresses WHERE gu_address=GuAddress;
  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TABLE k_syndentries
(
id_domain    INTEGER      NOT NULL,
gu_workarea  CHAR(32)      NULL,
uri_entry    VARCHAR(200) NOT NULL,
gu_feed      CHAR(32)      NULL,
id_type      VARCHAR(50)   NULL,
dt_published DATETIME      NULL,
dt_modified  DATETIME      NULL,
tx_query     CHARACTER VARYING(100)  NULL,
gu_contact   CHAR(32)      NULL,
nu_influence INTEGER       NULL,
nm_author    CHARACTER VARYING(100)  NULL,
tl_entry     CHARACTER VARYING(254)  NULL,
de_entry     CHARACTER VARYING(1000) NULL,
url_addr     VARCHAR(254)  NULL,
bin_entry    LONGVARBINARY NULL,
CONSTRAINT pk_syndentries PRIMARY KEY (id_domain,gu_workarea,uri_entry)
)
GO;

