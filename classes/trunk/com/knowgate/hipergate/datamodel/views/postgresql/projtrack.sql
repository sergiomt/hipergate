CREATE VIEW v_project_company AS
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,COALESCE(d.tx_name,'') || ' ' || COALESCE(d.tx_surname,'') AS full_name, p.id_status, p.id_ref
FROM k_project_expand e, k_contacts d, k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND d.gu_contact=p.gu_contact)
UNION
(SELECT p.gu_project,p.dt_created,p.nm_project,p.id_parent,p.id_dept,p.dt_start,p.dt_end,p.pr_cost,p.gu_owner,p.de_project,p.gu_company,p.gu_contact,e.od_level,e.od_walk,c.nm_legal,NULL AS full_name, p.id_status, p.id_ref
FROM k_project_expand e,
k_projects p LEFT OUTER JOIN k_companies c ON c.gu_company=p.gu_company
WHERE e.gu_project=p.gu_project AND p.gu_contact IS NULL);

CREATE VIEW v_duty_resource AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.dt_scheduled,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty, u.tx_nickname AS nm_resource
FROM k_projects p, k_users u, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND x.nm_resource=u.gu_user
UNION
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.dt_scheduled,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource
FROM k_projects p, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND NOT EXISTS (SELECT gu_user FROM k_users WHERE gu_user=x.nm_resource)
;

CREATE VIEW v_duty_project AS
SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.dt_scheduled,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty
FROM k_duties b, k_projects p
WHERE p.gu_project=b.gu_project;

CREATE VIEW v_duty_company AS
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.dt_scheduled,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,c.gu_company,c.nm_legal,c.id_legal
FROM k_projects p, k_companies c, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND p.gu_company=c.gu_company)
UNION
(SELECT p.gu_owner,p.gu_project,p.nm_project,b.od_priority,b.gu_duty,b.nm_duty,b.dt_start,b.dt_end,b.dt_scheduled,b.tx_status,b.pct_complete,b.pr_cost,b.de_duty,x.nm_resource,NULL AS gu_company,NULL AS nm_legal, NULL AS id_legal
FROM k_projects p, k_duties b LEFT OUTER JOIN k_x_duty_resource x ON x.gu_duty=b.gu_duty 
WHERE p.gu_project=b.gu_project AND p.gu_company IS NULL);
