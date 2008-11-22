
CREATE TABLE k_categories
(
    /* List of all available categories */

    gu_category   CHAR(32)     NOT NULL, /* Category unique identifier */
    gu_owner      CHAR(32)     NOT NULL, /* User who is owner of this category */
    nm_category   VARCHAR(100) NOT NULL, /* Alternative identifier for ordering */
    bo_active     SMALLINT     NOT NULL, /* Whether or not this category is activated and thus must be visible */
    dt_created    DATETIME     DEFAULT CURRENT_TIMESTAMP, /* Date when category was created */
    dt_modified   DATETIME	   NULL, /* Date when category was last modified */
    nm_icon       VARCHAR(254)     NULL, /* Graphical icon of the category */
    nm_icon2      VARCHAR(254)     NULL, /* Other Graphical icon of the category */
    id_doc_status SMALLINT         NULL, /* Initial doc status */
    len_size      DECIMAL(28)      NULL, 

    CONSTRAINT  pk_categories PRIMARY KEY (gu_category),
    CONSTRAINT  u2_categories UNIQUE (nm_category)
)
GO;

CREATE TABLE k_cat_labels
(
    gu_category  CHAR(32)    NOT NULL, /* Category unique identifier */
    id_language  CHAR(2)     NOT NULL, /* Language code */
    tr_category  VARCHAR(30) NOT NULL, /* Translated Name */
    url_category VARCHAR(254)    NULL, /* Default HTML page URL for selected language*/
    de_category  VARCHAR(254)    NULL,

    CONSTRAINT pk_cat_names PRIMARY KEY (gu_category, id_language)    
)
GO;


CREATE TABLE k_cat_root
(
    /* List of root categories */

    gu_category CHAR(32) NOT NULL,

    CONSTRAINT pk_cat_root PRIMARY KEY (gu_category)    
)
GO;


CREATE TABLE k_cat_tree
(
    gu_parent_cat CHAR(32) NOT NULL,
    gu_child_cat  CHAR(32) NOT NULL,

    CONSTRAINT pk_cat_tree PRIMARY KEY (gu_parent_cat, gu_child_cat),
    CONSTRAINT c1_cat_tree CHECK (gu_parent_cat<>gu_child_cat)
)
GO;

CREATE TABLE k_x_cat_objs
(
    gu_category  CHAR(32) NOT NULL, /* Category unique identifier */
    gu_object    CHAR(32) NOT NULL, /* Contained Object unique identifier */
    id_class     INTEGER  NOT NULL,
    bi_attribs   INTEGER  DEFAULT 0,
    od_position  INTEGER      NULL ,
    
    CONSTRAINT pk_x_cat_objs PRIMARY KEY(gu_category,gu_object)

)    
GO;

CREATE TABLE k_cat_expand
(
gu_rootcat    CHAR(32) NOT NULL,
gu_category   CHAR(32) NOT NULL,
od_level      INTEGER  NOT NULL,
od_walk       INTEGER  NOT NULL,
gu_parent_cat CHAR(32)     NULL
)
GO;

CREATE TABLE k_x_cat_user_acl
(
    gu_category CHAR(32) NOT NULL,
    gu_user     CHAR(32) NOT NULL,
    acl_mask    INTEGER  NOT NULL,

    CONSTRAINT pk_x_cat_user_acl PRIMARY KEY (gu_category,gu_user)
)
GO;

CREATE TABLE k_x_cat_group_acl
(
    gu_category  CHAR(32) NOT NULL,
    gu_acl_group CHAR(32) NOT NULL,
    acl_mask     INTEGER  NOT NULL,

    CONSTRAINT pk_x_cat_group_acl PRIMARY KEY (gu_category,gu_acl_group)
)
GO;