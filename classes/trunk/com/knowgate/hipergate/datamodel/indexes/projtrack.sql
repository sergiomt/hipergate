CREATE INDEX ix1_projects ON k_projects(nm_project);
CREATE INDEX ix2_projects ON k_projects(gu_company);
CREATE INDEX ix3_projects ON k_projects(id_ref);
CREATE INDEX ix4_projects ON k_projects(gu_owner);

CREATE INDEX i1_project_expand ON k_project_expand(gu_rootprj);
CREATE INDEX i2_project_expand ON k_project_expand(gu_project);
CREATE INDEX i3_project_expand ON k_project_expand(gu_parent);
CREATE INDEX i4_project_expand ON k_project_expand(od_level);

CREATE INDEX ix1_duties ON k_duties(nm_duty);
CREATE INDEX ix2_duties ON k_duties(gu_project);

CREATE INDEX ix1_duties_dependencies ON k_duties_dependencies(gu_previous);
CREATE INDEX ix2_duties_dependencies ON k_duties_dependencies(gu_next);

CREATE INDEX i1_bugs ON k_bugs(pg_bug);
CREATE INDEX i2_bugs ON k_bugs(tl_bug);
CREATE INDEX i3_bugs ON k_bugs(gu_project);
CREATE INDEX i4_bugs ON k_bugs(tx_rep_mail);
CREATE INDEX i5_bugs ON k_bugs(nm_assigned);
CREATE INDEX i6_bugs ON k_bugs(gu_bug_ref);
CREATE INDEX i7_bugs ON k_bugs(dt_created);
CREATE INDEX i8_bugs ON k_bugs(dt_closed);
CREATE INDEX i9_bugs ON k_bugs(id_ref);
CREATE INDEX i10_bugs ON k_bugs(id_client);
CREATE INDEX i11_bugs ON k_bugs(gu_writer);

CREATE INDEX i1_bugs_changelog ON k_bugs_changelog(gu_bug);

CREATE INDEX i1_project_snapshots ON k_project_snapshots(gu_project);
CREATE INDEX i2_project_snapshots ON k_project_snapshots(dt_created);

CREATE INDEX i1_duties_workreports ON k_duties_workreports(gu_project);
CREATE INDEX i2_duties_workreports ON k_duties_workreports(gu_writer);
CREATE INDEX i3_duties_workreports ON k_duties_workreports(dt_created);
