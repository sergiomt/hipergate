CREATE TABLE k_lu_permissions
(
bit_mask   INTEGER NOT NULL,
tr_mask_en VARCHAR(32) NULL,
tr_mask_es VARCHAR(32) NULL,
tr_mask_de VARCHAR(32) NULL,
tr_mask_it VARCHAR(32) NULL,
tr_mask_fr VARCHAR(32) NULL,
tr_mask_pt VARCHAR(32) NULL,
tr_mask_ca VARCHAR(32) NULL,
tr_mask_eu VARCHAR(32) NULL,
tr_mask_ja VARCHAR(32) NULL,
tr_mask_cn VARCHAR(32) NULL,
tr_mask_tw VARCHAR(32) NULL,
tr_mask_ru VARCHAR(32) NULL,

CONSTRAINT pk_lu_permissions PRIMARY KEY (bit_mask)
)
GO;

CREATE TABLE k_domains
(
    id_domain	 INTEGER     NOT NULL,  /* Domain Identifier */
    dt_created   DATETIME    DEFAULT CURRENT_TIMESTAMP,
    bo_active    SMALLINT    DEFAULT 1, /* Is domain activated? */
    nm_domain	 VARCHAR(30) NOT NULL,  /* Domain Name */   
    gu_owner	 CHAR(32)        NULL,  /* Domain Owner/Administrator */
    gu_admins	 CHAR(32)        NULL,  /* Domain Administrators Group */    
    dt_expire    DATETIME        NULL,
    
    CONSTRAINT pk_domains PRIMARY KEY (id_domain),
    CONSTRAINT u2_domains UNIQUE (nm_domain)        
)
GO;

CREATE TABLE k_users
(
    /* Basic User data */ 
    gu_user         CHAR(32)    NOT NULL, /* User CHAR(32)  */
    dt_created      DATETIME    DEFAULT CURRENT_TIMESTAMP,
    id_domain	    INTEGER     NOT NULL, /* Domain to witch user belongs */
    tx_nickname     CHARACTER VARYING(32) NOT NULL, /* Nick (for login) */
    tx_pwd          CHARACTER VARYING(50) NOT NULL, /* Password */
    tx_pwd_sign     CHARACTER VARYING(50)     NULL, /* Signature Password */
    bo_change_pwd   SMALLINT    DEFAULT 1, /* May user change its own password? */
    bo_searchable   SMALLINT    DEFAULT 1, /* is user searchable at users directory? */
    bo_active       SMALLINT    DEFAULT 1, /* Is user active? */
    nu_login_attempts INTEGER   DEFAULT 1, /* Number of unsuccessfull login attempts */

    len_quota       DECIMAL(28) DEFAULT 0,
    max_quota       DECIMAL(28) DEFAULT 104857600,

    /* Account Data */
    tp_account       CHAR(1)     NULL,
    id_account       CHAR(10)    NULL,

    dt_last_update  DATETIME 	 NULL, /* Auditing: last register update */
    dt_last_visit   DATETIME	 NULL, /* Auditoria: last visit */
    dt_cancel       DATETIME     NULL, /* Auditoria: date when account was cancelled */

    tx_main_email   CHARACTER VARYING(100) NULL, /* main e-mail  */
    tx_alt_email    CHARACTER VARYING(100) NULL, /* alternative e-mail */
    nm_user         VARCHAR(100) NULL, /* Name */
    tx_surname1	    VARCHAR(100) NULL, /* Surname 1 */
    tx_surname2	    VARCHAR(100) NULL, /* Surname 2 */
    tx_challenge    VARCHAR(100) NULL, /* Question for retrieving forgotten password */
    tx_reply        VARCHAR(100) NULL, /* Answer to question */
    dt_pwd_expires  DATETIME	 NULL, /* Date when password expires */
    gu_category     CHAR(32)     NULL, /* Home Category */
    gu_workarea     CHAR(32)     NULL, /* Default WorkArea */

    /* Corporate data */    
    nm_company	    VARCHAR(70)  NULL, /* Company Name */
    de_title	    VARCHAR(70)  NULL, /* Position */
    id_gender	    CHAR(1)      NULL, /* Gender */

    /* Personal Data */
    dt_birth        DATETIME     NULL, /* Date of Birth */
    ny_age	        SMALLINT     NULL, /* Age */
    marital_status  CHAR(1)      NULL, /* Civil Status */
    tx_education    VARCHAR(100) NULL, /* Formation */

    icq_id	        VARCHAR(50)  NULL,
    sn_passport	    VARCHAR(16)  NULL,
    tp_passport     CHAR(1)      NULL,
    mov_phone       VARCHAR(16)  NULL,

    tx_comments     VARCHAR(254) NULL,

    CONSTRAINT pk_users PRIMARY KEY (gu_user),
    CONSTRAINT u3_users UNIQUE (id_domain,tx_nickname),
    CONSTRAINT u4_users UNIQUE (tx_main_email),
    CONSTRAINT c1_users CHECK  (tx_nickname<>tx_pwd),
    CONSTRAINT c2_users CHECK  (tx_pwd_sign<>tx_pwd)    
)
GO;

CREATE TABLE k_user_mail
(
    gu_account          CHAR(32)    NOT NULL,
    gu_user             CHAR(32)    NOT NULL,
    tl_account          VARCHAR(50) NOT NULL,
    dt_created          DATETIME    DEFAULT CURRENT_TIMESTAMP,
    bo_default          SMALLINT    NOT NULL,
    bo_synchronize      SMALLINT    DEFAULT 0,
    tx_main_email       CHARACTER VARYING(100) NOT NULL,
    tx_reply_email      CHARACTER VARYING(100) NULL,
    incoming_protocol   CHARACTER VARYING(6)   DEFAULT 'pop3',
    incoming_account    CHARACTER VARYING(100) NULL,
    incoming_password   CHARACTER VARYING(50)  NULL,
    incoming_server     CHARACTER VARYING(100) NULL,
    incoming_spa	    SMALLINT DEFAULT 0,
    incoming_ssl	    SMALLINT DEFAULT 0,
    incoming_port	    SMALLINT DEFAULT 110,
    outgoing_protocol   CHARACTER VARYING(6)   DEFAULT 'smtp',
    outgoing_account    CHARACTER VARYING(100) NULL,
    outgoing_password   CHARACTER VARYING(50)  NULL,
    outgoing_server     CHARACTER VARYING(100) NULL,
    outgoing_spa	    SMALLINT DEFAULT 0,
    outgoing_ssl	    SMALLINT DEFAULT 0,
    outgoing_port	    SMALLINT DEFAULT 25,
    
    CONSTRAINT pk_user_mail PRIMARY KEY (gu_account),
    CONSTRAINT u1_user_mail UNIQUE (gu_user,tl_account)
)    
GO;

CREATE TABLE k_user_accounts
(
  gu_account        CHAR(32) NOT NULL,
  id_domain         INTEGER  NOT NULL,
  dt_created        DATETIME DEFAULT CURRENT_TIMESTAMP,
  tx_nickname       VARCHAR(50) NOT NULL,
  tx_pwd            VARCHAR(50) NULL,
  tx_pwd_sign       VARCHAR(50) NULL,
  bo_change_pwd     SMALLINT DEFAULT 1,
  bo_searchable     SMALLINT DEFAULT 1,
  bo_active         SMALLINT DEFAULT 1,
  nu_login_attempts INTEGER NULL,
  len_quota         DECIMAL(28) NULL,
  max_quota         DECIMAL(28) NULL,
  tp_account        CHAR(1) NULL,
  id_account        CHAR(10) NULL,
  dt_last_update    DATETIME NULL,
  dt_last_visit     DATETIME NULL,
  dt_cancel         DATETIME NULL,
  tx_main_email     VARCHAR(100) NULL,
  tx_alt_email      VARCHAR(100) NULL,
  nm_user           VARCHAR(100) NULL,
  tx_surname1       VARCHAR(100) NULL,
  tx_surname2       VARCHAR(100) NULL,
  full_name         VARCHAR(300) NULL,
  nm_ascii          VARCHAR(300) NULL,
  tx_challenge      VARCHAR(100) NULL,
  tx_reply          VARCHAR(100) NULL,
  dt_pwd_expires    DATETIME NULL,
  gu_company        CHAR(32) NULL,
  nm_company        VARCHAR(70) NULL,
  de_title          VARCHAR(70) NULL,
  id_country        CHAR(2) NULL,
  id_gender         CHAR(1) NULL,
  dt_birth          DATETIME NULL,
  ny_age            SMALLINT NULL,
  marital_status    CHAR(1) NULL,
  tx_education      VARCHAR(100) NULL,
  icq_id            VARCHAR(50) NULL,
  sn_passport       VARCHAR(16) NULL,
  tp_passport       CHAR(1) NULL,
  mov_phone         VARCHAR(16) NULL,
  tx_comments       VARCHAR(254) NULL,
  gu_image          CHAR(32),
  jv_recent_searches LONGVARBINARY NULL,
  CONSTRAINT pk_user_accounts PRIMARY KEY (gu_account)
)
GO;

CREATE TABLE k_user_account_alias
(
    id_acalias VARCHAR(150) NOT NULL,
	  gu_account CHAR(32) NULL,
    dt_created DATETIME DEFAULT CURRENT_TIMESTAMP,
    nm_service VARCHAR(50) NOT NULL,
    nm_alias VARCHAR(100) NOT NULL,
    nm_display VARCHAR(100) NULL,
    nm_ascii VARCHAR(100) NULL,
    url_addr VARCHAR(254) NULL,
    CONSTRAINT pk_user_account_alias PRIMARY KEY (id_acalias)
)
GO;

CREATE TABLE k_user_pwd
(
    gu_pwd        CHAR(32)      NOT NULL,
    gu_user       CHAR(32)      NOT NULL,
    tl_pwd        VARCHAR(50)   NOT NULL,
    id_enc_method VARCHAR(30)   DEFAULT 'RC4',
    id_pwd        CHARACTER VARYING(12) NULL,
    dt_created    DATETIME      DEFAULT CURRENT_TIMESTAMP,
    dt_modified   DATETIME      NULL,
    tx_comments   VARCHAR(254)  NULL,
    tx_lines      CHARACTER VARYING(4000) NULL,
    
    CONSTRAINT pk_user_pwd PRIMARY KEY (gu_pwd)
)
GO;

/******************************/
/* Access Control List Groups */
/******************************/

CREATE TABLE k_acl_groups
(
    gu_acl_group CHAR(32)    NOT NULL,
    dt_created   DATETIME    DEFAULT CURRENT_TIMESTAMP,
    id_domain	 INTEGER     NOT NULL,
    bo_active    SMALLINT    NOT NULL, 
    nm_acl_group VARCHAR(30) NOT NULL,
    de_acl_group VARCHAR(254)    NULL,
    
    CONSTRAINT pk_acl_groups PRIMARY KEY (gu_acl_group),
    CONSTRAINT u2_acl_groups UNIQUE (nm_acl_group,id_domain)
)
GO;

/****************************************/
/* Association between Users and Groups */
/****************************************/

CREATE TABLE k_x_group_user
(
    gu_acl_group CHAR(32) NOT NULL,
    gu_user      CHAR(32) NOT NULL,
    dt_created   DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_x_group_user PRIMARY KEY (gu_user,gu_acl_group)
)
GO;

/*************/
/* Workareas */
/*************/

CREATE TABLE k_apps
(
    id_app INTEGER NOT NULL,
    nm_app CHARACTER VARYING(50) NOT NULL,
    
    CONSTRAINT pk_apps PRIMARY KEY (id_app)
)
GO;

CREATE TABLE k_workareas
(
    gu_workarea      CHAR(32)     NOT NULL,
    nm_workarea      VARCHAR(50)  NOT NULL,
    id_domain        INTEGER      NOT NULL,
    gu_owner         CHAR(32)     NOT NULL,
    bo_active        SMALLINT     DEFAULT 1,
    dt_created       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    len_quota        DECIMAL(28)  DEFAULT 0,
    max_quota        DECIMAL(28)  DEFAULT 104857600,
    path_logo	     VARCHAR(254) NULL,
    id_locale        VARCHAR(5)   NULL,
    tx_date_format   VARCHAR(30)  DEFAULT 'yyyy-MM-dd',
    tx_number_format VARCHAR(30)  DEFAULT '#0.00',
    bo_allcaps       SMALLINT     DEFAULT 0,
    bo_dup_id_docs   SMALLINT     DEFAULT 1,
    bo_cnt_autoref   SMALLINT     DEFAULT 0,
    bo_acrs_oprt     SMALLINT     DEFAULT 0,
        
    CONSTRAINT pk_workareas PRIMARY KEY (gu_workarea),
    CONSTRAINT u1_workareas UNIQUE (nm_workarea,id_domain)
)
GO;

CREATE TABLE k_x_app_workarea
(
    id_app      INTEGER  NOT NULL,    /* Id. de la aplicaci�n */
    gu_workarea CHAR(32) NOT NULL,    /* CHAR(32) de la workarea */
    gu_admins   CHAR(32) NULL,        /* CHAR(32) del grupo de administradores de la workarea */
    gu_powusers CHAR(32) NULL,        /* CHAR(32) del grupo de power users de la workarea */
    gu_users    CHAR(32) NULL,        /* CHAR(32) del grupo de usuarios comunes de la workarea */
    gu_guests   CHAR(32) NULL,        /* CHAR(32) del grupo de invitados de la workarea */
    gu_other    CHAR(32) NULL,        /* CHAR(32) del grupo de otros de la workarea */
    path_files  VARCHAR(255) NULL,    /* Ruta a ficheros f�sicos asociados */

    CONSTRAINT pk_x_app_workarea PRIMARY KEY(id_app,gu_workarea)  
)
GO;

CREATE TABLE k_x_portlet_user (
    id_domain   INTEGER                NOT NULL,
    gu_user     CHAR(32)               NOT NULL,
    gu_workarea CHAR(32)               NOT NULL,
    nm_portlet  CHARACTER VARYING(64)  NOT NULL,
    nm_page     CHARACTER VARYING(64)  NOT NULL,
    nm_zone     CHARACTER VARYING(16)  DEFAULT 'none',
    od_position INTEGER                DEFAULT 1,
    id_state    CHARACTER VARYING(16)  DEFAULT 'NORMAL',
    dt_modified DATETIME               DEFAULT CURRENT_TIMESTAMP,
    nm_template CHARACTER VARYING(254) NULL,

    CONSTRAINT pk_x_portlet_user PRIMARY KEY(id_domain,gu_user,gu_workarea,nm_portlet,nm_page,nm_zone)  
)
GO;

CREATE TABLE k_login_audit (
bo_success    CHAR(1) NOT NULL,
nu_error      SMALLINT NOT NULL,
dt_login      DATETIME DEFAULT CURRENT_TIMESTAMP,
gu_user       CHAR(32) NULL,
tx_email      CHARACTER VARYING(100) NULL,
tx_pwd        CHARACTER VARYING(50) NULL,
gu_workarea   CHAR(32) NULL,
ip_addr       VARCHAR(15) NULL
)
GO;

CREATE TABLE k_webbeacons (
    id_webbeacon  INTEGER  NOT NULL,
    dt_created    DATETIME DEFAULT CURRENT_TIMESTAMP,
    dt_last_visit DATETIME NOT NULL,
	nu_pages      INTEGER  NOT NULL,
    gu_user       CHAR(32) NULL,
    gu_contact    CHAR(32) NULL,
    CONSTRAINT pk_webbeacons PRIMARY KEY(id_webbeacon)
)
GO;
    
CREATE TABLE k_webbeacon_pages (
    id_page   INTEGER  NOT NULL,
    nu_hits   INTEGER  NOT NULL,
    gu_object CHAR(32)     NULL,
    url_page  CHARACTER VARYING(254) NOT NULL,
    CONSTRAINT pk_webbeacon_pages PRIMARY KEY(id_page),
    CONSTRAINT u1_webbeacon_pages UNIQUE (url_page),
    CONSTRAINT c1_webbeacon_pages CHECK (LENGTH(url_page)>0)
)
GO;

CREATE TABLE k_webbeacon_hit (
    id_webbeacon  INTEGER  NOT NULL,
    id_page       INTEGER  NOT NULL,
    id_referrer   INTEGER      NULL,
    dt_hit        DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_addr       INTEGER  NULL,
    CONSTRAINT f1_webbeacon_hit FOREIGN KEY (id_webbeacon) REFERENCES k_webbeacons (id_webbeacon),
    CONSTRAINT f2_webbeacon_hit FOREIGN KEY (id_page) REFERENCES k_webbeacon_pages (id_page),
    CONSTRAINT f3_webbeacon_hit FOREIGN KEY (id_referrer) REFERENCES k_webbeacon_pages (id_page)        
)
GO;

