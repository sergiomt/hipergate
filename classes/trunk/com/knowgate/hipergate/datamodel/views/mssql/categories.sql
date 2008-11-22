SET NUMERIC_ROUNDABORT OFF;

SET ANSI_PADDING,ANSI_WARNINGS,CONCAT_NULL_YIELDS_NULL,ARITHABORT,QUOTED_IDENTIFIER,ANSI_NULLS ON;

CREATE VIEW v_cat_tree AS
SELECT p.nm_category AS nm_parent,c.nm_category AS nm_child FROM k_categories p, k_categories c, k_cat_tree t WHERE p.gu_category=t.gu_parent_cat AND c.gu_category=t.gu_child_cat;

CREATE VIEW v_cat_tree_labels WITH SCHEMABINDING AS
SELECT c.gu_category,t.gu_parent_cat,n.id_language,c.nm_category,n.tr_category,c.gu_owner,c.bo_active,c.dt_created,c.dt_modified,c.nm_icon,c.nm_icon2,n.de_category FROM dbo.k_categories c, dbo.k_cat_labels n, dbo.k_cat_tree t WHERE n.gu_category=c.gu_category AND t.gu_child_cat=c.gu_category;

CREATE UNIQUE CLUSTERED INDEX i1_cat_tree_labels ON v_cat_tree_labels(gu_category,gu_parent_cat,id_language);

CREATE INDEX i2_cat_tree_labels ON v_cat_tree_labels (gu_parent_cat,id_language);

CREATE VIEW v_cat_group_acl WITH SCHEMABINDING AS
SELECT c2.gu_category,c2.nm_category,g2.gu_user,g1.gu_acl_group,g1.acl_mask,c2.nm_icon,c2.nm_icon2
FROM dbo.k_categories c2, dbo.k_x_cat_group_acl g1, dbo.k_x_group_user g2
WHERE g1.gu_category=c2.gu_category AND g2.gu_acl_group=g1.gu_acl_group;

CREATE UNIQUE CLUSTERED INDEX i1_cat_group_acl ON v_cat_group_acl(gu_category,gu_user,gu_acl_group,acl_mask);

CREATE INDEX i2_cat_group_acl ON v_cat_group_acl(gu_user);

CREATE VIEW v_cat_user_acl WITH SCHEMABINDING AS
SELECT c1.gu_category,c1.nm_category,u1.gu_user,u1.acl_mask,c1.nm_icon,c1.nm_icon2
FROM dbo.k_categories c1, dbo.k_x_cat_user_acl u1
WHERE u1.gu_category=c1.gu_category;

CREATE UNIQUE CLUSTERED INDEX i1_cat_user_acl ON v_cat_user_acl(gu_category,gu_user);

CREATE INDEX i2_cat_user_acl ON v_cat_user_acl(gu_user);

CREATE VIEW v_cat_acl AS
SELECT u.gu_category,u.nm_category,u.gu_user,NULL AS gu_acl_group,u.acl_mask,u.nm_icon,u.nm_icon2 FROM v_cat_user_acl u
UNION
SELECT g.gu_category,g.nm_category,g.gu_user,g.gu_acl_group,g.acl_mask,g.nm_icon,g.nm_icon2 FROM v_cat_group_acl g;

