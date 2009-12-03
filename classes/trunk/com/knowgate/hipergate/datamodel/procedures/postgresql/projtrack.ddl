CREATE SEQUENCE seq_k_bugs INCREMENT 1 START 1
GO;

CREATE SEQUENCE seq_k_bugs_track INCREMENT 1 START 1
GO;

CREATE FUNCTION k_sp_prj_expand_node (CHAR, CHAR, INTEGER, INTEGER) RETURNS INTEGER AS '
DECLARE  
  childs k_projects%ROWTYPE;
  wlk INTEGER;
BEGIN

  wlk := $4;
  
  FOR childs IN SELECT * FROM k_projects WHERE id_parent = $2 LOOP
    INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES ($1, childs.gu_project, childs.nm_project, $3, wlk, $2);
    wlk := wlk + 1;
    SELECT k_sp_prj_expand_node ($1, childs.gu_project, $3+1, wlk) INTO wlk;
  END LOOP;
  RETURN wlk;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_prj_expand (CHAR) RETURNS INTEGER AS '
DECLARE  
  childs k_projects%ROWTYPE;
  curname VARCHAR(50);
  wlk INTEGER;
BEGIN
  DELETE FROM k_project_expand WHERE gu_rootprj = $1;

  SELECT nm_project INTO curname FROM k_projects WHERE gu_project=$1;

  IF FOUND THEN
    wlk := 1;

    INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES ($1, $1, curname, 1, wlk, NULL);
    wlk := wlk + 1;
  
    FOR childs IN SELECT * FROM k_projects WHERE id_parent = $1 LOOP
      INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES ($1, childs.gu_project, childs.nm_project, 2, wlk, $1);
      wlk := wlk + 1;
      SELECT k_sp_prj_expand_node ($1, childs.gu_project, 3, wlk) INTO wlk;
    END LOOP;
  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_bug (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=$1;
  DELETE FROM k_bugs_track WHERE gu_bug=$1;    
  DELETE FROM k_bugs_changelog WHERE gu_bug=$1;
  DELETE FROM k_bugs_attach WHERE gu_bug=$1;
  DELETE FROM k_bugs WHERE gu_bug=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_duty (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_duties_dependencies WHERE gu_previous=$1 OR gu_next=$1;
  DELETE FROM k_x_duty_resource WHERE gu_duty=$1;
  DELETE FROM k_duties_attach WHERE gu_duty=$1;
  DELETE FROM k_duties WHERE gu_duty=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_project (CHAR) RETURNS INTEGER AS '
DECLARE
  chldid CHAR(32);
  childs k_projects%ROWTYPE;
  
BEGIN

  FOR childs IN SELECT * FROM k_projects WHERE id_parent=$1 LOOP
    PERFORM k_sp_del_project (childs.gu_project);    
  END LOOP;
  
  DELETE FROM k_duties_dependencies WHERE gu_previous IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1) OR gu_next IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1);
  DELETE FROM k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1);
  DELETE FROM k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=$1);
  DELETE FROM k_duties WHERE gu_project=$1;

  DELETE FROM k_bugs_changelog WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=$1);
  DELETE FROM k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=$1);
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref IN (SELECT gu_bug FROM k_bugs WHERE gu_project=$1);
  DELETE FROM k_bugs WHERE gu_project=$1;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=$1;
  
  DELETE FROM k_duties_workreports WHERE gu_project=$1;
  DELETE FROM k_project_snapshots WHERE gu_project=$1;
  DELETE FROM k_project_costs WHERE gu_project=$1;
  DELETE FROM k_project_expand WHERE gu_project=$1;
  DELETE FROM k_projects WHERE gu_project=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_prj_cost (CHAR) RETURNS FLOAT AS '
DECLARE
  proj k_projects%ROWTYPE;
  fCost FLOAT := 0;
  fMore FLOAT := 0;
BEGIN
  SELECT COALESCE(SUM(pr_cost),0) INTO fMore FROM k_project_costs WHERE gu_project=$1;

  SELECT COALESCE(SUM(d.pr_cost),0) INTO fCost FROM k_duties d, k_projects p WHERE d.gu_project=p.gu_project AND p.gu_project=$1 AND d.pr_cost IS NOT NULL;

  FOR proj IN SELECT gu_project FROM k_projects WHERE id_parent=$1 LOOP
    fCost = fCost + k_sp_prj_cost (proj.gu_project);
  END LOOP;
  
  RETURN fCost+fMore;
END;
' LANGUAGE 'plpgsql';
GO;
