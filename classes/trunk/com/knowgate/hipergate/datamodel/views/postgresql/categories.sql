
CREATE VIEW v_cat_tree AS
SELECT p.nm_category AS nm_parent,c.nm_category AS nm_child FROM k_categories p, k_categories c, k_cat_tree t WHERE p.gu_category=t.gu_parent_cat AND c.gu_category=t.gu_child_cat;

CREATE VIEW v_cat_tree_labels AS
SELECT c.gu_category,t.gu_parent_cat,n.id_language,c.nm_category,n.tr_category,c.gu_owner,c.bo_active,c.dt_created,c.dt_modified,c.nm_icon,c.nm_icon2,n.de_category
FROM k_cat_tree t, k_categories c LEFT OUTER JOIN k_cat_labels n ON c.gu_category=n.gu_category
WHERE t.gu_child_cat=c.gu_category;

CREATE VIEW v_cat_group_acl AS
SELECT c2.gu_category,c2.nm_category,g2.gu_user,g1.gu_acl_group,g1.acl_mask,c2.nm_icon,c2.nm_icon2
FROM k_categories c2, k_x_cat_group_acl g1, k_x_group_user g2
WHERE g1.gu_category=c2.gu_category AND g2.gu_acl_group=g1.gu_acl_group;

CREATE VIEW v_cat_user_acl AS
SELECT c1.gu_category,c1.nm_category,u1.gu_user,u1.acl_mask,c1.nm_icon,c1.nm_icon2
FROM k_categories c1, k_x_cat_user_acl u1
WHERE u1.gu_category=c1.gu_category;

CREATE VIEW v_cat_acl AS
SELECT u.gu_category,u.nm_category,u.gu_user,NULL AS gu_acl_group,u.acl_mask,u.nm_icon,u.nm_icon2 FROM v_cat_user_acl u
UNION
SELECT g.gu_category,g.nm_category,g.gu_user,g.gu_acl_group,g.acl_mask,g.nm_icon,g.nm_icon2 FROM v_cat_group_acl g;