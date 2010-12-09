UPDATE k_version SET vs_stamp='6.0.0'
GO;

DROP PROCEDURE k_sp_read_pageset 
GO;
CREATE PROCEDURE k_sp_read_pageset @IdPageSet CHAR(32), @IdMicrosite CHAR(32) OUTPUT, @NmMicrosite VARCHAR(100) OUTPUT, @IdWorkArea CHAR(32) OUTPUT, @NmPageSet NVARCHAR(100) OUTPUT, @VsStamp VARCHAR(16) OUTPUT, @IdLanguage CHAR(2) OUTPUT, @DtModified DATETIME OUTPUT, @PathData VARCHAR(254) OUTPUT, @IdStatus VARCHAR(30) OUTPUT, @PathMetaData VARCHAR(254) OUTPUT, @TxComments NVARCHAR(255) OUTPUT, @GuCompany CHAR(32) OUTPUT, @GuProject CHAR(32) OUTPUT,@TxEmailFrom VARCHAR(254) OUTPUT, @TxEmailReply VARCHAR(254) OUTPUT, @NmFrom NVARCHAR(254) OUTPUT, @TxSubject NVARCHAR(254) OUTPUT AS
  SELECT @NmMicrosite=m.nm_microsite, @IdMicrosite=m.gu_microsite, @IdWorkArea=p.gu_workarea, @NmPageSet=p.nm_pageset, @VsStamp=p.vs_stamp, @IdLanguage=p.id_language, @DtModified=p.dt_modified, @PathData=p.path_data, @IdStatus=p.id_status, @PathMetaData=m.path_metadata, @TxComments=p.tx_comments,@GuCompany=p.gu_company,@GuProject=p.gu_project @TxEmailFrom=p.tx_email_from, @TxEmailReply=p.tx_email_reply, @NmFrom=p.nm_from, @TxSubject=p.tx_subject FROM k_pagesets p LEFT OUTER JOIN k_microsites m ON p.gu_microsite=m.gu_microsite WHERE p.gu_pageset=@IdPageSet
GO;
ALTER TABLE k_x_list_members ADD tx_info NVARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD tx_email_from VARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD tx_email_reply VARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD nm_from NVARCHAR(254) NULL
GO;
ALTER TABLE k_pagesets ADD tx_subject NVARCHAR(254) NULL
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
ALTER TABLE k_urls ADD dt_last_visit DATETIME NULL
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

DROP PROCEDURE k_sp_del_job
GO;

CREATE PROCEDURE k_sp_del_job @IdJob CHAR(32) AS
  DELETE FROM k_jobs_atoms_by_agent WHERE gu_job=@IdJob
  DELETE FROM k_jobs_atoms_by_hour WHERE gu_job=@IdJob
  DELETE FROM k_jobs_atoms_by_day WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_clicks WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_tracking WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_archived WHERE gu_job=@IdJob
  DELETE k_job_atoms WHERE gu_job=@IdJob
  DELETE k_jobs WHERE gu_job=@IdJob
GO;

CREATE PROCEDURE k_sp_del_duplicates @GuList CHAR(32), @Deleted INTEGER OUTPUT AS
  
  DECLARE @TxEMail VARCHAR(100)
  DECLARE @TmpMail VARCHAR(100)  
  DECLARE Members CURSOR FOR SELECT tx_email FROM k_x_list_members WHERE gu_list = @GuList

  CREATE TABLE #k_temp_list_emails (tx_email VARCHAR(100) CONSTRAINT pk_temp_list_emails PRIMARY KEY)  
  INSERT INTO k_temp_list_emails SELECT DISTINCT(tx_email) FROM k_x_list_members WHERE gu_list=@GuList
  SET @Deleted = 0
  OPEN Members
  FETCH NEXT FROM Members INTO @TxEMail
  WHILE (@@FETCH_STATUS<>-1)
  BEGIN
    SET @TmpMail = NULL
    DELETE FROM k_temp_list_emails WHERE tx_email=@TxEMail OUTPUT DELETED.tx_email INTO @TmpMail
    IF @TmpMail IS NULL THEN
      BEGIN
        SET @Deleted = @Deleted + 1
        DELETE FROM k_x_list_members WHERE CURRENT OF members
      END
    FETCH NEXT FROM Members INTO @TxEMail
  END
  CLOSE Members  
  DEALLOCATE Members
  DROP TABLE k_temp_list_emails
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
      DELETE k_x_adhoc_mailing_list WHERE gu_list=@bk
      DELETE k_lists WHERE gu_list=@bk
    END
    
  DELETE k_list_members WHERE gu_member IN (SELECT gu_contact FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_contact FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_list_members WHERE gu_member IN (SELECT gu_company FROM k_x_list_members WHERE gu_list=@ListId) AND gu_member NOT IN (SELECT x.gu_company FROM k_x_list_members x, k_lists l WHERE x.gu_list=l.gu_list AND l.gu_workarea=@wa AND x.gu_list<>@ListId)
  
  DELETE k_x_list_members WHERE gu_list=@ListId

  DELETE k_x_campaign_lists WHERE gu_list=@ListId

  DELETE k_x_adhoc_mailing_list WHERE gu_list=@ListId

  DELETE k_x_cat_objs WHERE gu_object=@ListId
  UPDATE k_activities SET gu_list=NULL WHERE gu_list=@ListId
  UPDATE k_x_activity_audience SET gu_list=NULL WHERE gu_list=@ListId

  DELETE k_lists WHERE gu_list=@ListId
GO;

ALTER TABLE k_bulkloads ADD de_file NVARCHAR(254) NULL
GO;
ALTER TABLE k_bulkloads ADD tp_batch VARCHAR(32) NULL
GO;

CREATE TABLE k_x_user_acourse
(
gu_acourse   CHAR(32) NOT NULL,
gu_user      CHAR(32) NOT NULL,
dt_created   DATETIME DEFAULT GETDATE(),
bo_admin     SMALLINT DEFAULT 0,
bo_user      SMALLINT DEFAULT 1,

CONSTRAINT pk_x_user_acourse PRIMARY KEY (gu_acourse,gu_user),
CONSTRAINT f1_x_user_acourse FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses(gu_acourse),
CONSTRAINT f2_x_user_acourse FOREIGN KEY (gu_user) REFERENCES k_users(gu_user)
)
GO;

DROP PROCEDURE k_sp_del_acourse
GO;

CREATE PROCEDURE k_sp_del_acourse @CourseId CHAR(32) AS
  DECLARE @GuAddress CHAR(32)
  SELECT @GuAddress=gu_address gu_address FROM k_academic_courses WHERE gu_acourse=@CourseId
  DELETE k_x_user_acourse WHERE gu_acourse=@CourseId
  DELETE k_x_course_alumni WHERE gu_acourse=@CourseId
  DELETE k_x_course_bookings WHERE gu_acourse=@CourseId
  DELETE k_evaluations WHERE gu_acourse=@CourseId
  DELETE k_absentisms WHERE gu_acourse=@CourseId
  DELETE k_academic_courses WHERE gu_acourse=@CourseId
  IF @GuAddress IS NOT NULL
    DELETE FROM k_addresses WHERE gu_address=@GuAddress
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
tx_query     NVARCHAR(100) NULL,
gu_contact   CHAR(32)      NULL,
nu_influence INTEGER       NULL,
nm_author    NVARCHAR(100) NULL,
tl_entry     NVARCHAR(254) NULL,
de_entry     NVARCHAR(1000) NULL,
url_addr     VARCHAR(254)  NULL,
bin_entry    IMAGE         NULL,
CONSTRAINT pk_syndentries PRIMARY KEY (id_domain,gu_workarea,uri_entry)
)
GO;

