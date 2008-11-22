CREATE TABLE k_campaigns
(
gu_campaign    CHAR(32)    NOT NULL,
gu_workarea    CHAR(32)    NOT NULL,
nm_campaign    VARCHAR(70) NOT NULL,
dt_created     DATETIME    DEFAULT CURRENT_TIMESTAMP,
bo_active      SMALLINT    DEFAULT 1,
CONSTRAINT pk_campaigns PRIMARY KEY (gu_campaign),
CONSTRAINT u1_campaigns UNIQUE (gu_workarea,nm_campaign)
)
GO;

CREATE TABLE k_x_campaign_lists
(
gu_campaign    CHAR(32)    NOT NULL,
gu_list        CHAR(32)    NOT NULL,
bo_active      SMALLINT    DEFAULT 1,
dt_created     DATETIME    DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT pk_x_campaign_lists PRIMARY KEY (gu_campaign,gu_list)
)
GO;

CREATE TABLE k_campaign_targets
(
gu_campaign_target CHAR(32) NOT NULL,
gu_campaign    CHAR(32)     NOT NULL,
gu_geozone     CHAR(32)     NOT NULL,
gu_product     CHAR(32)     NOT NULL,
dt_created     DATETIME     DEFAULT CURRENT_TIMESTAMP,
dt_start       DATETIME     NOT NULL,
dt_end         DATETIME     NOT NULL,
dt_modified    DATETIME     NOT NULL,
nu_planned     FLOAT	    NOT NULL,
nu_achieved    FLOAT	    NOT NULL,
CONSTRAINT pk_campaign_targets PRIMARY KEY (gu_campaign_target),
CONSTRAINT c1_campaign_targets CHECK (dt_end>=dt_start),
CONSTRAINT c2_campaign_targets CHECK (dt_modified>=dt_created)
)
GO;

CREATE VIEW v_campaign_contacts AS 
SELECT l.gu_list,l.tp_list,l.gu_query,l.de_list,m.gu_contact,m.gu_company,m.bo_active,m.dt_created,m.dt_modified,m.tx_salutation,m.tx_email,m.tx_name,m.tx_surname,m.id_format
FROM k_campaigns g, k_x_campaign_lists x, k_lists l, k_x_list_members m, k_contacts c
WHERE g.gu_campaign=x.gu_campaign AND x.gu_list=l.gu_list AND l.gu_list=m.gu_list AND m.gu_contact=c.gu_contact
GO;