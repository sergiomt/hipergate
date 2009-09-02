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
  nu_max_alumni  INTEGER       NULL,
  gu_address     CHAR(32)      NULL,
  nm_tutor       VARCHAR(200)  NULL,
  tx_tutor_email CHARACTER VARYING(100) NULL,
  de_course     VARCHAR(2000)  NULL,
  CONSTRAINT pk_academic_courses PRIMARY KEY (gu_acourse)
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
  nm_degree   VARCHAR(100)  NOT NULL,
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
  CONSTRAINT pk_contact_education PRIMARY KEY (gu_contact,gu_degree),
  CONSTRAINT f1_contact_education FOREIGN KEY (gu_degree) REFERENCES k_education_degree(gu_degree)  
)
GO;

