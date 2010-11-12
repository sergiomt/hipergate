CREATE TABLE k_lu_fellow_titles
(
de_title      VARCHAR(50)  NOT NULL,
gu_workarea   CHAR(32)     NOT NULL,
dt_created    DATETIME     DEFAULT CURRENT_TIMESTAMP,
id_title      VARCHAR(50)  NULL,
tp_title      VARCHAR(50)  NULL,
id_boss       VARCHAR(50)  NULL,
im_salary_max FLOAT        NULL,
im_salary_min FLOAT        NULL,

CONSTRAINT pk_fellow_titles PRIMARY KEY (de_title,gu_workarea)
)
GO;

CREATE TABLE k_fellows (
gu_fellow   CHAR(32)    NOT NULL,	/* CHAR(32) del individuo */
gu_workarea CHAR(32)    NOT NULL,	/* CHAR(32) de la workarea */
id_domain   INTEGER     NOT NULL,
dt_created  DATETIME    DEFAULT CURRENT_TIMESTAMP,
dt_modified DATETIME     NULL,  /* fecha de Modificación del registro */
tx_company  VARCHAR(70)  NULL,  /* Compañía a la que pertenece el individuo */
id_ref      VARCHAR(50)  NULL,  /* Identificador externo de registro (para interfaz con otras applicaciones) */
tx_name     VARCHAR(100) NULL,  /* Nombre de Pila */
tx_surname  VARCHAR(100) NULL,  /* Apellidos */
de_title    VARCHAR(50)  NULL,  /* Empleo/Puesto */
id_gender   CHAR(1)      NULL,  /* Sexo */
sn_passport VARCHAR(16)  NULL,  /* Nº doc identidad legal */
tp_passport CHAR(1)      NULL,  /* Tipo doc identidad legal */
tx_dept     VARCHAR(50)  NULL,  /* Departamento */
tx_division VARCHAR(50)  NULL,  /* División */
tx_location VARCHAR(50)  NULL,  /* Delegación */
tx_email    VARCHAR(100) NULL,
work_phone  VARCHAR(16)  NULL,
home_phone  VARCHAR(16)  NULL,
mov_phone   VARCHAR(16)  NULL,
ext_phone   VARCHAR(16)  NULL,
tx_timezone VARCHAR(16)  NULL,
tx_comments VARCHAR(254) NULL,  /* Comentarios */

CONSTRAINT pk_fellows PRIMARY KEY (gu_fellow),
CONSTRAINT c1_fellows CHECK (tx_name IS NULL OR LENGTH(tx_name)>0),
CONSTRAINT c2_fellows CHECK (tx_surname IS NULL OR LENGTH(tx_surname)>0),
CONSTRAINT c3_fellows CHECK (id_ref IS NULL OR LENGTH(id_ref)>0)
)
GO;

CREATE TABLE k_fellows_attach
(
gu_fellow   CHAR(32)      NOT NULL,
tx_file     VARCHAR(250)  NOT NULL,
len_file    INTEGER       NOT NULL,
bin_file    LONGVARBINARY NOT NULL,
CONSTRAINT pk_fellows_attach PRIMARY KEY (gu_fellow)
)
GO;

CREATE TABLE k_fellows_lookup
(
gu_owner   CHAR(32) NOT NULL,	 /* CHAR(32) de la workarea */
id_section CHARACTER VARYING(30) NOT NULL, /* Nombre del campo en la tabla base */
pg_lookup  INTEGER  NOT NULL,    /* Progresivo del valor */
vl_lookup  VARCHAR(255) NULL,    /* Valor real del lookup */
tr_es      VARCHAR(50)  NULL,
tr_en      VARCHAR(50)  NULL,
tr_de      VARCHAR(50)  NULL,
tr_it      VARCHAR(50)  NULL,
tr_fr      VARCHAR(50)  NULL,
tr_pt      VARCHAR(50)  NULL,
tr_ca      VARCHAR(50)  NULL,
tr_eu      VARCHAR(50)  NULL,
tr_ja      VARCHAR(50)  NULL,
tr_cn      VARCHAR(50)  NULL,
tr_tw      VARCHAR(50)  NULL,
tr_fi      VARCHAR(50)  NULL,
tr_ru      VARCHAR(50)  NULL,
tr_nl      VARCHAR(50)  NULL,
tr_th      VARCHAR(50)  NULL,
tr_cs      VARCHAR(50)  NULL,
tr_uk      VARCHAR(50)  NULL,
tr_no      VARCHAR(50)  NULL,
tr_ko      VARCHAR(50)  NULL,
tr_sk      VARCHAR(50)  NULL,
tr_pl      VARCHAR(50)  NULL,
tr_vn      VARCHAR(50)  NULL,

CONSTRAINT pk_fellows_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_fellows_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_rooms
(
nm_room      VARCHAR(50) NOT NULL,
gu_workarea  CHAR(32)    NOT NULL,
id_domain    INTEGER     NOT NULL,
bo_available SMALLINT    DEFAULT 1,
tp_room      VARCHAR(16)     NULL,
nu_capacity  INTEGER         NULL,
tx_company   VARCHAR(50)     NULL,
tx_location  VARCHAR(50)     NULL,
tx_comments  VARCHAR(255)    NULL,

CONSTRAINT pk_rooms PRIMARY KEY (nm_room,gu_workarea)
)
GO;

CREATE TABLE k_rooms_lookup
(
gu_owner   CHAR(32)    NOT NULL, /* GUID de la workarea */
id_section CHARACTER VARYING(30) NOT NULL, /* Nombre del campo en la tabla base */
pg_lookup  INTEGER     NOT NULL, /* Progresivo del valor */
vl_lookup  VARCHAR(255)    NULL, /* Valor real del lookup */
tr_es      VARCHAR(50)     NULL, /* Valor que se visualiza en pantalla (esp) */
tr_en      VARCHAR(50)     NULL, /* Valor que se visualiza en pantalla (ing) */
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
tr_eu      VARCHAR(50)     NULL,
tr_ja      VARCHAR(50)     NULL,
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_cn      VARCHAR(50)     NULL,
tr_tw      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,

CONSTRAINT pk_rooms_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_rooms_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_meetings (
gu_meeting   CHAR(32) NOT NULL,
gu_workarea  CHAR(32) NOT NULL,
id_domain    INTEGER  NOT NULL,
gu_fellow    CHAR(32) NOT NULL,
bo_private   SMALLINT NOT NULL,
dt_created   DATETIME DEFAULT CURRENT_TIMESTAMP,
dt_start     DATETIME     NULL,
dt_end       DATETIME     NULL,
dt_modified  DATETIME     NULL,
gu_writer    CHAR(32)     NULL,
gu_address   CHAR(32)  	 NULL,
df_before    INTEGER      NULL,
pr_cost      FLOAT        NULL,
tx_status    VARCHAR(50)  NULL,
tp_meeting   VARCHAR(16)  NULL,
tx_meeting   VARCHAR(100) NULL,
de_meeting   VARCHAR(1000) NULL,
id_icalendar VARCHAR(255) NULL,

CONSTRAINT pk_meeting PRIMARY KEY (gu_meeting),
CONSTRAINT c1_meetings CHECK (dt_start<=dt_end)
)
GO;

CREATE TABLE k_meetings_lookup
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
tr_fi      VARCHAR(50)     NULL,
tr_ru      VARCHAR(50)     NULL,
tr_nl      VARCHAR(50)     NULL,
tr_th      VARCHAR(50)     NULL,
tr_cs      VARCHAR(50)     NULL,
tr_uk      VARCHAR(50)     NULL,
tr_no      VARCHAR(50)     NULL,
tr_pl      VARCHAR(50)     NULL,
tr_sk      VARCHAR(50)     NULL,
tr_vn      VARCHAR(50)     NULL,
tr_ko      VARCHAR(50)     NULL,

CONSTRAINT pk_meetings_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_meetings_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_x_meeting_room (
gu_meeting  CHAR(32)    NOT NULL,
nm_room     VARCHAR(50) NOT NULL,
dt_start    DATETIME    NOT NULL,
dt_end      DATETIME    NOT NULL,

CONSTRAINT pk_x_meeting_room PRIMARY KEY (gu_meeting,nm_room),
CONSTRAINT c1_x_meeting_room CHECK (dt_start<=dt_end)
)
GO;

CREATE TABLE k_x_meeting_fellow (
gu_meeting  CHAR(32)     NOT NULL,
gu_fellow   CHAR(32)     NOT NULL,
dt_start    DATETIME     NOT NULL,
dt_end      DATETIME     NOT NULL,

CONSTRAINT pk_x_meeting_fellow PRIMARY KEY (gu_meeting,gu_fellow),
CONSTRAINT c1_x_meeting_fellow CHECK (dt_start<=dt_end)
)
GO;

CREATE TABLE k_x_meeting_contact (
gu_meeting  CHAR(32)     NOT NULL,
gu_contact  CHAR(32)     NOT NULL,
dt_start    DATETIME     NOT NULL,
dt_end      DATETIME     NOT NULL,

CONSTRAINT pk_x_meeting_contact PRIMARY KEY (gu_meeting,gu_contact),
CONSTRAINT c1_x_meeting_contact CHECK (dt_start<=dt_end)
)
GO;

CREATE TABLE k_phone_calls (
gu_phonecall   CHAR(32)     NOT NULL,
tp_phonecall   CHAR(1)      NOT NULL,
gu_workarea    CHAR(32)     NOT NULL,
gu_writer      CHAR(32)     NOT NULL,
id_status      SMALLINT     DEFAULT 0,
dt_start       DATETIME         NULL,
dt_end         DATETIME         NULL,
gu_user        CHAR(32)         NULL,
gu_contact     CHAR(32)         NULL,
gu_oportunity  CHAR(32)         NULL,
gu_bug         CHAR(32)         NULL,
tx_phone       VARCHAR(16)      NULL,
contact_person VARCHAR(200)     NULL,
tx_comments    VARCHAR(254)     NULL,

CONSTRAINT pk_phone_calls PRIMARY KEY (gu_phonecall),
CONSTRAINT c1_phone_calls CHECK (dt_start<=dt_end)
)
GO;

CREATE TABLE k_to_do (
gu_to_do       CHAR(32)     NOT NULL,
gu_workarea    CHAR(32)     NOT NULL,
gu_user        CHAR(32)     NOT NULL,
tl_to_do       VARCHAR(100) NOT NULL,
od_priority    SMALLINT     DEFAULT 0,
dt_created     DATETIME     DEFAULT CURRENT_TIMESTAMP,
dt_end         DATETIME         NULL,
tp_to_do       VARCHAR(16)      NULL,
tx_status      VARCHAR(50)      NULL,
tx_to_do       VARCHAR(2000)    NULL,

CONSTRAINT pk_to_do PRIMARY KEY (gu_to_do),
CONSTRAINT c1_to_do CHECK (dt_created <=dt_end)
)
GO;

CREATE TABLE k_to_do_lookup
(
gu_owner   CHAR(32)    NOT NULL, /* GUID de la workarea */
id_section CHARACTER VARYING(30) NOT NULL, /* Nombre del campo en la tabla base */
pg_lookup  INTEGER     NOT NULL, /* Progresivo del valor */
vl_lookup  VARCHAR(255)    NULL, /* Valor real del lookup */
tr_es      VARCHAR(50)     NULL, /* Valor que se visualiza en pantalla (esp) */
tr_en      VARCHAR(50)     NULL, /* Valor que se visualiza en pantalla (ing) */
tr_de      VARCHAR(50)     NULL,
tr_it      VARCHAR(50)     NULL,
tr_fr      VARCHAR(50)     NULL,
tr_pt      VARCHAR(50)     NULL,
tr_ca      VARCHAR(50)     NULL,
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

CONSTRAINT pk_to_do_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup),
CONSTRAINT u1_to_do_lookup UNIQUE (gu_owner,id_section,vl_lookup)
)
GO;

CREATE TABLE k_working_calendar
(
gu_calendar    CHAR(32)  NOT NULL,
gu_workarea    CHAR(32)  NOT NULL,
id_domain      INTEGER   NOT NULL,
nm_calendar    VARCHAR(100) NOT NULL,
dt_created     DATETIME  DEFAULT CURRENT_TIMESTAMP,
dt_modified    DATETIME  NULL,
dt_from        DATETIME  NOT NULL,
dt_to          DATETIME  NOT NULL,
gu_user        CHAR(32)  NULL,
gu_acl_group   CHAR(32)  NULL,
gu_geozone     CHAR(32)  NULL,
id_country     CHAR(3)   NULL,
id_state       CHAR(9)   NULL,
CONSTRAINT pk_working_calendar PRIMARY KEY (gu_calendar),
CONSTRAINT u1_working_calendar UNIQUE (gu_workarea,id_domain,nm_calendar),
CONSTRAINT c1_working_calendar CHECK (dt_modified IS NULL OR dt_modified>=dt_created),
CONSTRAINT c2_working_calendar CHECK (dt_from<=dt_to)
)
GO;

CREATE TABLE k_working_time
(
dt_day          INTEGER     NOT NULL,
gu_calendar     CHAR(32)    NOT NULL,
bo_working_time SMALLINT    NOT NULL,
hh_start1       SMALLINT    NOT NULL,
mi_start1       SMALLINT    NOT NULL,
hh_end1         SMALLINT    NOT NULL,
mi_end1         SMALLINT    NOT NULL,
hh_start2       SMALLINT    NOT NULL,
mi_start2       SMALLINT    NOT NULL,
hh_end2         SMALLINT    NOT NULL,
mi_end2         SMALLINT    NOT NULL,
de_day          VARCHAR(50) NULL,

CONSTRAINT pk_working_time PRIMARY KEY (dt_day,gu_calendar),
CONSTRAINT cd_working_time CHECK (dt_day BETWEEN 19700101 AND 29991231),
CONSTRAINT cw_working_time CHECK (bo_working_time=0 OR bo_working_time=1),
CONSTRAINT c1_working_time CHECK (hh_start1=-1 OR mi_start1<>-1),
CONSTRAINT c2_working_time CHECK (hh_end1=-1 OR mi_end1<>-1),
CONSTRAINT c3_working_time CHECK (hh_start2=-1 OR mi_start2<>-1),
CONSTRAINT c4_working_time CHECK (hh_end2=-1 OR mi_end2<>-1),
CONSTRAINT c5_working_time CHECK (hh_start1=-1 OR hh_end1=-1 OR hh_end1>=hh_start1),
CONSTRAINT c6_working_time CHECK (hh_start1=-2 OR hh_end2=-1 OR hh_end2>=hh_start2),
CONSTRAINT c7_working_time CHECK (hh_start1 BETWEEN 0 AND 23 OR hh_start1=-1),
CONSTRAINT c8_working_time CHECK (hh_end1 BETWEEN 0 AND 23 OR hh_end1=-1),
CONSTRAINT c9_working_time CHECK (hh_start2 BETWEEN 0 AND 23 OR hh_start2=-1),
CONSTRAINT c10_working_time CHECK (hh_end2 BETWEEN 0 AND 23 OR hh_end2=-1),
CONSTRAINT c11_working_time CHECK (mi_start1 BETWEEN 0 AND 59 OR mi_start1=-1),
CONSTRAINT c12_working_time CHECK (mi_end1 BETWEEN 0 AND 59 OR mi_end1=-1),
CONSTRAINT c13_working_time CHECK (mi_start2 BETWEEN 0 AND 59 OR mi_start2=-1),
CONSTRAINT c14_working_time CHECK (mi_end2 BETWEEN 0 AND 59 OR mi_end2=-1),
CONSTRAINT c15_working_time CHECK (mi_start1=-1 OR hh_end1=-1 OR hh_end1>hh_start1 OR mi_end1>mi_start1),
CONSTRAINT c16_working_time CHECK (mi_start2=-1 OR hh_end2=-1 OR hh_end2>hh_start2 OR mi_end2>mi_start2)
)
GO;