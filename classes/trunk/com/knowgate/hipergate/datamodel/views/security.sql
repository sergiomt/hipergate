CREATE VIEW v_app_workarea AS
SELECT a.nm_app,w.nm_workarea,d.nm_domain,g1.nm_acl_group AS nm_admins,g2.nm_acl_group AS nm_powusers,g3.nm_acl_group AS nm_users,g4.nm_acl_group AS nm_guests FROM
k_apps a,k_workareas w, k_x_app_workarea x,k_domains d,k_acl_groups g1,k_acl_groups g2,k_acl_groups g3,k_acl_groups g4 WHERE
a.id_app=x.id_app AND x.gu_workarea=w.gu_workarea AND d.id_domain=w.id_domain AND
(g1.gu_acl_group=x.gu_admins OR x.gu_admins IS NULL) AND
(g2.gu_acl_group=x.gu_powusers OR x.gu_powusers IS NULL) AND
(g3.gu_acl_group=x.gu_users OR x.gu_users IS NULL) AND
(g4.gu_acl_group=x.gu_guests OR x.gu_guests IS NULL)
;
