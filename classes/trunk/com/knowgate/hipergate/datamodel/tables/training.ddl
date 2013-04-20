CREATE TABLE k_courses (
  gu_course      CHAR(32)     NOT NULL,
  gu_workarea    CHAR(32)     NOT NULL,
  nm_course      VARCHAR(100) NOT NULL,
  id_course      VARCHAR(50)      NULL,
  bo_active      SMALLINT DEFAULT 1,
  dt_created     DATETIME DEFAULT CURRENT_TIMESTAMP,
  dt_modified    DATETIME         NULL,
  nu_max_pending INTEGER  DEFAULT -1,
  gu_msite_eval  CHAR(32)         NULL,
  gu_msite_abst  CHAR(32)         NULL,
  tx_dept        VARCHAR(50)      NULL,
  tx_area        VARCHAR(50)      NULL,
  nu_credits     FLOAT            NULL,
  de_course      VARCHAR(2000)    NULL,
  CONSTRAINT pk_courses PRIMARY KEY (gu_course)
)
GO;

CREATE TABLE k_courses_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_courses_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_academic_courses (
  gu_acourse     CHAR(32)     NOT NULL,
  gu_course      CHAR(32)     NOT NULL,
  tx_start       VARCHAR(30)  NOT NULL,
  tx_end         VARCHAR(30)  NOT NULL,
  nm_course      VARCHAR(100) NOT NULL,
  id_course      VARCHAR(50)      NULL,
  bo_active      SMALLINT DEFAULT 1,
  dt_created     DATETIME DEFAULT CURRENT_TIMESTAMP,
  dt_modified    DATETIME	   NULL,
  dt_closed      DATETIME	   NULL,
  pr_acourse     DECIMAL(14,4) NULL,
  pr_booking     DECIMAL(14,4) NULL,
  pr_payment     DECIMAL(14,4) NULL,
  nu_payments    INTEGER       NULL,
  nu_max_alumni  INTEGER       NULL,
  nu_booked      INTEGER       NULL,
  nu_confirmed   INTEGER       NULL,
  nu_alumni      INTEGER       NULL,
  gu_address     CHAR(32)      NULL,
  gu_supplier    CHAR(32)      NULL,
  nm_tutor       VARCHAR(200)  NULL,
  tx_tutor_email CHARACTER VARYING(100) NULL,
  de_course     VARCHAR(2000)  NULL,
  CONSTRAINT pk_academic_courses PRIMARY KEY (gu_acourse)
)
GO;

CREATE TABLE k_x_user_acourse
(
gu_acourse   CHAR(32) NOT NULL,
gu_user      CHAR(32) NOT NULL,
dt_created   DATETIME DEFAULT CURRENT_TIMESTAMP,
bo_admin     SMALLINT DEFAULT 0,
bo_user      SMALLINT DEFAULT 1,

CONSTRAINT pk_x_user_acourse PRIMARY KEY (gu_acourse,gu_user),
CONSTRAINT f1_x_user_acourse FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses(gu_acourse),
CONSTRAINT f2_x_user_acourse FOREIGN KEY (gu_user) REFERENCES k_users(gu_user)
)
GO;

CREATE TABLE k_subjects (
  gu_subject     CHAR(32)     NOT NULL,
  gu_workarea    CHAR(32)     NOT NULL,
  nm_subject     VARCHAR(200) NOT NULL,
  gu_course      CHAR(32)         NULL,
  nm_short       VARCHAR(100)     NULL,
  id_subject     VARCHAR(50)      NULL,
  bo_active      SMALLINT DEFAULT 1,
  bo_optative    SMALLINT DEFAULT 0,
  dt_created     DATETIME DEFAULT CURRENT_TIMESTAMP,
  dt_modified    DATETIME	      NULL,
  tm_start       CHAR(5)          NULL,
  tm_end         CHAR(5)          NULL,
  nu_credits     FLOAT            NULL,
  tx_area        VARCHAR(50)      NULL,
  nm_tutor       VARCHAR(200)     NULL,
  tx_tutor_email CHARACTER VARYING(100) NULL,
  de_subject     VARCHAR(2000) NULL,
  CONSTRAINT pk_subjects PRIMARY KEY (gu_subject),
  CONSTRAINT c1_subjects CHECK (tm_start IS NULL OR tm_end IS NULL OR tm_start<=tm_end)
)
GO;

CREATE TABLE k_subjects_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_subjects_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_x_course_alumni (
  gu_acourse   CHAR(32)  NOT NULL,
  gu_alumni    CHAR(32)  NOT NULL,
  tp_register  VARCHAR(30)   NULL,
  id_classroom VARCHAR(30)   NULL,
  dt_created   DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT pk_x_course_alumni PRIMARY KEY (gu_acourse,gu_alumni),
  CONSTRAINT f1_x_course_alumni FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses(gu_acourse)
)
GO;

CREATE TABLE k_x_course_bookings (
  gu_acourse   CHAR(32)  NOT NULL,
  gu_contact   CHAR(32)  NOT NULL,
  bo_confirmed SMALLINT  DEFAULT 0,
  bo_paid      SMALLINT  DEFAULT 0,
  bo_canceled  SMALLINT  DEFAULT 0,
  bo_waiting   SMALLINT  DEFAULT 0,
  tp_register  VARCHAR(30)   NULL,
  id_classroom VARCHAR(30)   NULL,
  dt_created   DATETIME DEFAULT CURRENT_TIMESTAMP,
  dt_confirmed DATETIME      NULL,
  dt_cancel    DATETIME      NULL,
  dt_waiting   DATETIME      NULL,
  im_paid      DECIMAL(14,4) NULL,
  dt_paid      DATETIME      NULL,
  id_transact  VARCHAR(32)   NULL,
  tp_billing   CHAR(1)       NULL,
  gu_invoice   CHAR(32)      NULL,

  CONSTRAINT pk_x_course_bookings PRIMARY KEY (gu_acourse,gu_contact),
  CONSTRAINT f1_x_course_bookings FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses(gu_acourse),
  CONSTRAINT c1_x_course_bookings CHECK (dt_confirmed IS NULL OR dt_confirmed>=dt_created),
  CONSTRAINT c2_x_course_bookings CHECK (dt_paid IS NULL OR dt_paid>=dt_created),
  CONSTRAINT c3_x_course_bookings CHECK (dt_cancel IS NULL OR dt_cancel>=dt_created),
  CONSTRAINT c4_x_course_bookings CHECK (dt_confirmed IS NULL OR bo_confirmed=1),
  CONSTRAINT c5_x_course_bookings CHECK (dt_paid IS NULL OR bo_paid=1),
  CONSTRAINT c6_x_course_bookings CHECK (dt_cancel IS NULL OR bo_canceled=1),
  CONSTRAINT c7_x_course_bookings CHECK (bo_waiting=0 OR bo_canceled=0)  
)
GO;

CREATE TABLE k_x_course_subject (
  gu_course   CHAR(32)  NOT NULL,
  gu_subject  CHAR(32)  NOT NULL,
  od_position INTEGER       NULL,
  tx_start    VARCHAR(30)   NULL,
  tx_end      VARCHAR(30)   NULL,
  CONSTRAINT pk_x_course_subject PRIMARY KEY (gu_course,gu_subject),
  CONSTRAINT f1_x_course_subject FOREIGN KEY (gu_course) REFERENCES k_courses(gu_course),
  CONSTRAINT f2_x_course_subject FOREIGN KEY (gu_subject) REFERENCES k_subjects(gu_subject)
)
GO;

CREATE TABLE k_evaluations (
  gu_subject   CHAR(32)    NOT NULL,
  gu_alumni    CHAR(32)    NOT NULL,
  gu_acourse   CHAR(32)    NOT NULL,
  tx_date      VARCHAR(30) NOT NULL,
  gu_writer    CHAR(32)    NOT NULL,
  dt_created   DATETIME    DEFAULT CURRENT_TIMESTAMP,
  dt_modified  DATETIME        NULL,
  bo_approved  SMALLINT        NULL,
  bo_open      SMALLINT    DEFAULT 1,
  tx_knowledge VARCHAR(30)     NULL,
  tx_attitude  VARCHAR(30)     NULL,
  nu_absent1   INTEGER         NULL,
  nu_absent2   INTEGER         NULL,
  tx_comments VARCHAR(1000)    NULL,
  CONSTRAINT pk_evaluations PRIMARY KEY (gu_subject,gu_alumni,gu_acourse,tx_date),
  CONSTRAINT f1_evaluations FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses(gu_acourse),
  CONSTRAINT f2_evaluations FOREIGN KEY (gu_subject) REFERENCES k_subjects(gu_subject)
)
GO;

CREATE TABLE k_absentisms (
  gu_absentism CHAR(32)  NOT NULL,
  gu_alumni    CHAR(32)  NOT NULL,
  gu_writer    CHAR(32)  NOT NULL,
  dt_created   DATETIME  DEFAULT CURRENT_TIMESTAMP,
  bo_wholeday  SMALLINT  DEFAULT 0,
  dt_from      DATETIME  NOT NULL,
  dt_to        DATETIME  NOT NULL,
  gu_acourse   CHAR(32)      NULL,
  gu_subject   CHAR(32)      NULL,
  tp_absentism VARCHAR(30)   NULL,
  tx_comments  VARCHAR(1000) NULL,
  CONSTRAINT pk_absentisms PRIMARY KEY (gu_absentism),
  CONSTRAINT f1_absentisms FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses(gu_acourse),
  CONSTRAINT f2_absentisms FOREIGN KEY (gu_subject) REFERENCES k_subjects(gu_subject),
  CONSTRAINT c1_absentisms CHECK (dt_from<=dt_to)
)
GO;

CREATE TABLE k_absentisms_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_absentisms_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_education_institutions (
  gu_institution CHAR(32)    NOT NULL,
  gu_workarea    CHAR(32)    NOT NULL,
  nm_institution VARCHAR(100) NOT NULL,
  id_institution VARCHAR(30) NULL,
  bo_active      SMALLINT    DEFAULT 1,
  CONSTRAINT pk_education_institutions PRIMARY KEY (gu_institution),
  CONSTRAINT u1_education_institutions UNIQUE (gu_workarea,nm_institution)
)
GO;

CREATE TABLE k_education_degree (
  gu_degree   CHAR(32)     NOT NULL,
  gu_workarea CHAR(32)     NOT NULL,
  id_country  CHAR(3)      NOT NULL,
  nm_degree   VARCHAR(100) NOT NULL,
  tp_degree   VARCHAR(50)  NULL,
  id_degree   VARCHAR(32)  NULL,
  CONSTRAINT pk_education_degree PRIMARY KEY (gu_degree),
  CONSTRAINT u1_education_degree UNIQUE (gu_workarea,tp_degree,nm_degree)
)
GO;

CREATE TABLE k_education_degree_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_education_degree_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_contact_education (
  gu_contact     CHAR(32) NOT NULL,
  gu_degree      CHAR(32) NOT NULL,
  dt_created     DATETIME DEFAULT CURRENT_TIMESTAMP,
  bo_completed   SMALLINT DEFAULT 1,
  gu_institution CHAR(32)     NULL,
  nm_center      VARCHAR(50)  NULL,
  tp_degree      VARCHAR(50)  NULL,
  id_degree      VARCHAR(32)  NULL,
  lv_degree      DECIMAL(3,2) NULL,
  ix_degree      INTEGER      NULL,
  tx_dt_from     VARCHAR(30)  NULL,
  tx_dt_to       VARCHAR(30)  NULL,
  pg_product     INTEGER      NULL,
  gu_product     CHAR(32)     NULL,
  
  CONSTRAINT pk_contact_education PRIMARY KEY (gu_contact,gu_degree),
  CONSTRAINT f1_contact_education FOREIGN KEY (gu_degree) REFERENCES k_education_degree(gu_degree),
  CONSTRAINT f2_contact_education FOREIGN KEY (gu_contact) REFERENCES k_contacts(gu_contact),
  CONSTRAINT f3_contact_education FOREIGN KEY (gu_institution) REFERENCES k_education_institutions(gu_institution)
)
GO;

CREATE TABLE k_contact_short_courses (
  gu_contact     CHAR(32) NOT NULL,
  gu_scourse     CHAR(32) NOT NULL,
  nm_scourse     VARCHAR(100) NOT NULL,
  dt_created     DATETIME DEFAULT CURRENT_TIMESTAMP,
  nm_center      VARCHAR(50)  NULL,
  lv_scourse     DECIMAL(3,2) NULL,
  ix_scourse     INTEGER      NULL,
  tx_dt_from     VARCHAR(30)  NULL,
  tx_dt_to       VARCHAR(30)  NULL,
  nu_credits     INTEGER      NULL,
  CONSTRAINT pk_contact_short_courses PRIMARY KEY (gu_contact,gu_scourse),
  CONSTRAINT u1_contact_short_courses UNIQUE (gu_contact,nm_scourse)
)
GO;

CREATE TABLE k_contact_languages (
  gu_contact   CHAR(32) NOT NULL,
  id_language  CHAR(2) NOT NULL,
  lv_language_degree  VARCHAR(16) NULL,
  lv_language_spoken  SMALLINT NULL,
  lv_language_written SMALLINT NULL,
  CONSTRAINT pk_contact_languages PRIMARY KEY (gu_contact,id_language),
  CONSTRAINT f1_contact_languages FOREIGN KEY (id_language) REFERENCES k_lu_languages(id_language)  
)
GO;

CREATE TABLE k_contact_languages_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_contact_languages_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_contact_computer_science (
  gu_ccsskill CHAR(32) NOT NULL,
  gu_contact  CHAR(32) NOT NULL,
  nm_skill    VARCHAR(100) NOT NULL,
  lv_skill    VARCHAR(16)  NULL,
  CONSTRAINT pk_contact_computer_science PRIMARY KEY (gu_ccsskill),
  CONSTRAINT u1_contact_computer_science UNIQUE (gu_contact,nm_skill)
)
GO;

CREATE TABLE k_contact_computer_science_lookup
(
gu_owner   CHAR(32)    NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_contact_computer_science_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_contact_experience
(
  gu_experience  CHAR(32)    NOT NULL,
  gu_contact     CHAR(32)    NOT NULL,
  nm_company     VARCHAR(70) NOT NULL,
  bo_current_job SMALLINT    NOT NULL,
  id_sector      VARCHAR(16)     NULL, /* Reuse k_companies_lookup for this column */
  de_title       VARCHAR(70)     NULL, /* Reuse k_contacts_lookup for this column */
  tx_dt_from     VARCHAR(30)     NULL,
  tx_dt_to       VARCHAR(30)     NULL,
  contact_person VARCHAR(100)    NULL,
  tx_comments    VARCHAR(254)    NULL,
    
CONSTRAINT pk_contact_experience PRIMARY KEY (gu_experience)
)
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
  dt_created     	DATETIME 		DEFAULT CURRENT_TIMESTAMP,/*admission application date*/
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
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER     NOT NULL,
vl_lookup  VARCHAR(50)     NULL,
tr_es      VARCHAR(50)     NULL,
tr_en      VARCHAR(50)     NULL,
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_gl      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_admission_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_registrations
(
  gu_contact CHAR(32) NOT NULL,
  gu_oportunity CHAR(32) NOT NULL,
  gu_acourse CHAR(32) NULL,
  id_institution VARCHAR(200) NULL,
  dt_reserve DATETIME NULL,
  dt_registration DATETIME NULL,
  dt_drop DATETIME NULL,
  id_drop_cause SMALLINT NULL,
  CONSTRAINT pk_registrations PRIMARY KEY (gu_contact, gu_oportunity),
  CONSTRAINT f1_registrations FOREIGN KEY (gu_oportunity) REFERENCES k_oportunities (gu_oportunity),
  CONSTRAINT f2_registrations FOREIGN KEY (gu_acourse) REFERENCES k_academic_courses (gu_acourse)
)
GO;

CREATE TABLE k_registrations_lookup
(
  gu_owner CHAR(32) NOT NULL,
  id_section CHARACTER VARYING(30) NOT NULL,
  pg_lookup INTEGER NOT NULL,
  vl_lookup VARCHAR(50) NULL,
  tr_es VARCHAR(50) NULL,
  tr_en VARCHAR(50) NULL,
  tr_de VARCHAR(50) NULL,
  tr_it VARCHAR(50) NULL,
  tr_fr VARCHAR(50) NULL,
  tr_pt VARCHAR(50) NULL,
  tr_ca VARCHAR(50) NULL,
  tr_gl VARCHAR(50) NULL,
  tr_eu VARCHAR(50) NULL,
  tr_ja VARCHAR(50) NULL,
  tr_cn VARCHAR(50) NULL,
  tr_tw VARCHAR(50) NULL,
  tr_fi VARCHAR(50) NULL,
  tr_ru VARCHAR(50) NULL,
  tr_nl VARCHAR(50) NULL,
  tr_th VARCHAR(50) NULL,
  tr_cs VARCHAR(50) NULL,
  tr_uk VARCHAR(50) NULL,
  tr_no VARCHAR(50) NULL,
  tr_ko VARCHAR(50) NULL,
  tr_sk VARCHAR(50) NULL,
  tr_pl VARCHAR(50) NULL,
  tr_vn VARCHAR(50) NULL,
  CONSTRAINT pk_registrations_lookup PRIMARY KEY (gu_owner, id_section, pg_lookup)
)
GO;