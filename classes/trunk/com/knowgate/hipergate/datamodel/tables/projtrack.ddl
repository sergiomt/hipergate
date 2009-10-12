CREATE TABLE k_projects
(
gu_project   CHAR(32)         NOT NULL,
dt_created   DATETIME         DEFAULT CURRENT_TIMESTAMP,
nm_project   VARCHAR(50)      NOT NULL, /* Project Name */
gu_owner     CHAR(32)         NOT NULL, /* WorkArea */
id_parent    CHAR(32)             NULL, /* Parent Project */
id_dept      VARCHAR(32)          NULL, /* Department */
id_status    VARCHAR(16)          NULL, /* Status */
dt_start     DATETIME             NULL, /* Actual Start Date */
dt_scheduled DATETIME             NULL, /* Date when project start was scheduled */
dt_end       DATETIME             NULL, /* Actual End Date */
pr_cost      FLOAT                NULL, /* Cost */
gu_company   CHAR(32)		      NULL, /* Company */
gu_contact   CHAR(32)		      NULL, /* Contact */
gu_user      CHAR(32)		      NULL, /* User */
id_ref       VARCHAR(50)          NULL, /* External reference identifier */
de_project   VARCHAR(1000)        NULL, /* Description */

CONSTRAINT pk_projects PRIMARY KEY (gu_project),
CONSTRAINT c1_projects CHECK (dt_start IS NULL OR dt_end IS NULL OR dt_end>=dt_start),
CONSTRAINT c2_projects CHECK (id_parent IS NULL OR LENGTH(id_parent)>0),
CONSTRAINT c3_projects CHECK (gu_owner IS NULL OR LENGTH(gu_owner)>0)
)
GO;

CREATE TABLE k_project_costs
(
gu_cost      CHAR(32)         NOT NULL,
gu_project   CHAR(32)         NOT NULL,
dt_created   DATETIME         DEFAULT CURRENT_TIMESTAMP,
dt_modified  DATETIME             NULL,
gu_writer    CHAR(32)         NOT NULL,
gu_user      CHAR(32)         NOT NULL,
tl_cost      VARCHAR(100)     NOT NULL,
pr_cost      FLOAT            NOT NULL,
tp_cost      VARCHAR(30)          NULL,
dt_cost      DATETIME             NULL,
de_cost      VARCHAR(1000)        NULL,
CONSTRAINT pk_project_costs PRIMARY KEY (gu_cost),
CONSTRAINT f1_project_costs FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;


CREATE TABLE k_projects_lookup
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

CONSTRAINT pk_project_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_project_expand
(
gu_rootprj CHAR(32)     NOT NULL,
gu_project CHAR(32)     NOT NULL,
nm_project VARCHAR(50)  NOT NULL,
od_level   INTEGER      NOT NULL,
od_walk    INTEGER      NOT NULL,
gu_parent  CHAR(32)         NULL
)
GO;

CREATE TABLE k_project_snapshots
(
gu_snapshot CHAR(32)     NOT NULL,
gu_project  CHAR(32)     NOT NULL,
gu_writer   CHAR(32)     NOT NULL,
dt_created  DATETIME     DEFAULT CURRENT_TIMESTAMP,
tl_snapshot VARCHAR(100) NOT NULL,
tx_snapshot LONGVARCHAR  NOT NULL,
CONSTRAINT pk_project_snapshots PRIMARY KEY (gu_snapshot),
CONSTRAINT f1_project_snapshots FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;

CREATE TABLE k_duties
(
gu_duty      CHAR(32)    NOT NULL,
nm_duty      VARCHAR(50) NOT NULL,
gu_project   CHAR(32)    NOT NULL,
gu_writer    CHAR(32)        NULL,
dt_created   DATETIME    DEFAULT CURRENT_TIMESTAMP,
dt_modified  DATETIME        NULL,
dt_start     DATETIME        NULL,
dt_scheduled DATETIME        NULL,
dt_end       DATETIME        NULL,
ti_duration  DECIMAL(20,4)   NULL,
od_priority  SMALLINT        NULL,
gu_contact   CHAR(32)        NULL,
tx_status    VARCHAR(50)     NULL,
pct_complete SMALLINT        NULL,
pr_cost      FLOAT           NULL,
tp_duty      VARCHAR(30)     NULL,
de_duty      VARCHAR(2000)   NULL,
tx_comments  VARCHAR(1000)   NULL,

CONSTRAINT pk_duties PRIMARY KEY (gu_duty),
CONSTRAINT f1_duties FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project),
CONSTRAINT f2_duties FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user),
CONSTRAINT c1_duties CHECK (dt_start IS NULL OR dt_end IS NULL OR dt_end>=dt_start),
CONSTRAINT c2_duties CHECK (de_duty IS NULL OR LENGTH(de_duty)>0),
CONSTRAINT c3_duties CHECK (tx_comments IS NULL OR LENGTH(tx_comments)>0)
)
GO;

CREATE TABLE k_duties_dependencies
(
gu_previous CHAR(32)    NOT NULL,
gu_next     CHAR(32)    NOT NULL,
ti_gap      DECIMAL(20,4) DEFAULT 0,
CONSTRAINT  pk_duties_dependencies PRIMARY KEY (gu_previous,gu_next),
CONSTRAINT  f1_duties_dependencies FOREIGN KEY (gu_previous) REFERENCES k_duties(gu_duty),
CONSTRAINT  f2_duties_dependencies FOREIGN KEY (gu_next) REFERENCES k_duties(gu_duty)
)
GO;

CREATE TABLE k_duties_workreports
(
gu_workreport CHAR(32)     NOT NULL,
tl_workreport VARCHAR(200) NOT NULL,
gu_writer     CHAR(32)     NOT NULL,
dt_created    DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_project    CHAR(32)     NULL,
de_workreport VARCHAR(2000) NULL,
tx_workreport LONGVARCHAR   NOT NULL,
CONSTRAINT pk_duties_workreports PRIMARY KEY (gu_workreport),
CONSTRAINT f1_duties_workreports FOREIGN KEY (gu_project) REFERENCES k_projects(gu_project)
)
GO;


CREATE TABLE k_x_duty_resource
(
gu_duty      CHAR(32)    NOT NULL,
nm_resource  VARCHAR(50) NOT NULL,
pct_time     SMALLINT    DEFAULT 100,

CONSTRAINT pk_x_duty_resource PRIMARY KEY (gu_duty,nm_resource)

)
GO;

CREATE TABLE k_duties_lookup
(
gu_owner   CHAR(32)  NOT NULL,
id_section CHARACTER VARYING(30) NOT NULL,
pg_lookup  INTEGER  NOT  NULL,
vl_lookup  VARCHAR(255)  NULL,
tr_es      VARCHAR(200)  NULL,
tr_en      VARCHAR(200)  NULL,
tr_de      VARCHAR(200)  NULL,
tr_it      VARCHAR(200)  NULL,
tr_fr      VARCHAR(200)  NULL,
tr_pt      VARCHAR(200)  NULL,
tr_ca      VARCHAR(200)  NULL,
tr_gl      VARCHAR(200)  NULL,
tr_eu      VARCHAR(200)  NULL,
tr_ja      VARCHAR(200)  NULL,
tr_cn      VARCHAR(200)  NULL,
tr_tw      VARCHAR(200)  NULL,
tr_fi      VARCHAR(200)  NULL,
tr_ru      VARCHAR(200)  NULL,
tr_nl      VARCHAR(200)  NULL,
tr_th      VARCHAR(200)  NULL,
tr_cs      VARCHAR(200)  NULL,
tr_uk      VARCHAR(200)  NULL,
tr_no      VARCHAR(200)  NULL,
tr_sk      VARCHAR(200)  NULL,
tr_pl      VARCHAR(200)  NULL,
tr_vn      VARCHAR(200)  NULL,

CONSTRAINT pk_duties_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_duties_attach
(
gu_duty   CHAR(32)      NOT NULL,
tx_file   VARCHAR(254)  NOT NULL,
len_file  INTEGER       NOT NULL,
bin_file  LONGVARBINARY NOT NULL,
CONSTRAINT pk_duties_attach PRIMARY KEY (gu_duty,tx_file)
)
GO;

CREATE TABLE k_bugs
(
gu_bug       CHAR(32)     NOT NULL,
pg_bug       INTEGER      NOT NULL,
tl_bug       VARCHAR(250) NOT NULL, /* Bug Title */
gu_project   CHAR(32)     NOT NULL, /* Associated Project */
dt_created   DATETIME     DEFAULT CURRENT_TIMESTAMP,
gu_bug_ref   CHAR(32)         NULL, /* The bug is the same as this other one */
dt_modified  DATETIME         NULL, /* Date Modified */
dt_since     DATETIME         NULL, /* Date Since it is happening */
dt_closed    DATETIME         NULL, /* Date Closed */
dt_verified  DATETIME         NULL, /* Date Verified */
vs_found     VARCHAR(16)      NULL, /* Version where was found */
vs_closed    VARCHAR(16)      NULL, /* Version where was corrected */
od_severity  SMALLINT         NULL, /* Severity */
od_priority  SMALLINT         NULL, /* Priority */
tx_status    VARCHAR(50)      NULL, /* Status */
nu_times     INTEGER          NULL, /* How many times has happened */
tp_bug       VARCHAR(50)      NULL, /* Type/Class of Bug */
nm_reporter  VARCHAR(50)      NULL, /* Reported by */
tx_rep_mail  VARCHAR(100)     NULL, /* Reporter e-mail */
nm_assigned  VARCHAR(255)     NULL, /* Assigned to */
nm_inspector VARCHAR(255)     NULL, /* Inspector */
id_ref       VARCHAR(50)      NULL, /* Internal bug reference */
id_client    VARCHAR(50)      NULL, /* Client reference */
gu_writer    CHAR(32)         NULL, /* GUID of User or Contact who reported the bug */
tx_bug_brief VARCHAR(2000)    NULL, /* Briefing */
tx_bug_info  VARCHAR(1000)    NULL, /* More Info on how to reproduce the bug */
tx_comments  VARCHAR(1000)    NULL, /* Comments */

CONSTRAINT pk_bugs PRIMARY KEY (gu_bug),
CONSTRAINT c1_bugs CHECK(dt_closed IS NULL OR dt_closed>=dt_created),
CONSTRAINT c2_bugs CHECK(dt_verified IS NULL OR dt_closed IS NOT NULL),
CONSTRAINT c3_bugs CHECK(dt_verified IS NULL OR dt_verified>=dt_closed)
)
GO;

CREATE TABLE k_bugs_track (
gu_bug       CHAR(32)      NOT NULL,
pg_bug       INTEGER       NOT NULL,
pg_bug_track INTEGER       NOT NULL,
dt_created   DATETIME      DEFAULT CURRENT_TIMESTAMP,
nm_reporter  VARCHAR(50)       NULL,
tx_rep_mail  VARCHAR(100)      NULL,
gu_writer    CHAR(32)		   NULL,
tx_bug_track VARCHAR(2000)     NULL,
CONSTRAINT pk_bugs_track PRIMARY KEY (gu_bug,pg_bug_track)
)
GO;

CREATE TABLE k_bugs_changelog (
gu_bug       CHAR(32)      NOT NULL,
pg_bug       INTEGER       NOT NULL,
nm_column    VARCHAR(18)   NOT NULL,
dt_modified  DATETIME      DEFAULT CURRENT_TIMESTAMP,
gu_writer    CHAR(32)      NULL,
tx_oldvalue  VARCHAR(2000) NULL
)
GO;


CREATE TABLE k_bugs_lookup
(
gu_owner   CHAR(32)     NOT NULL,
id_section CHARACTER VARYING(30)  NOT NULL,
pg_lookup  INTEGER      NOT NULL,
vl_lookup  VARCHAR(255)     NULL,
tr_es      VARCHAR(200)     NULL,
tr_en      VARCHAR(200)     NULL,
tr_de      VARCHAR(200)     NULL,
tr_it      VARCHAR(200)     NULL,
tr_fr      VARCHAR(200)     NULL,
tr_pt      VARCHAR(200)     NULL,
tr_ca      VARCHAR(200)     NULL,
tr_gl      VARCHAR(200)     NULL,
tr_eu      VARCHAR(200)     NULL,
tr_ja      VARCHAR(200)     NULL,
tr_cn      VARCHAR(200)     NULL,
tr_tw      VARCHAR(200)     NULL,
tr_fi      VARCHAR(200)     NULL,
tr_ru      VARCHAR(200)     NULL,
tr_nl      VARCHAR(200)     NULL,
tr_th      VARCHAR(200)     NULL,
tr_cs      VARCHAR(200)     NULL,
tr_uk      VARCHAR(200)     NULL,
tr_no      VARCHAR(200)     NULL,
tr_sk      VARCHAR(200)     NULL,
tr_pl      VARCHAR(200)     NULL,
tr_vn      VARCHAR(200)     NULL,

CONSTRAINT pk_bugs_lookup PRIMARY KEY (gu_owner,id_section,pg_lookup)
)
GO;

CREATE TABLE k_bugs_attach
(
gu_bug   CHAR(32)      NOT NULL,
tx_file  VARCHAR(250)  NOT NULL,
len_file INTEGER       NOT NULL,
pg_bug_track INTEGER       NULL,
bin_file LONGVARBINARY NOT NULL,
CONSTRAINT pk_bugs_attach PRIMARY KEY (gu_bug,tx_file)
)
GO;  