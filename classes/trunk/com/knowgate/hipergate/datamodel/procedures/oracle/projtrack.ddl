CREATE SEQUENCE seq_k_bugs INCREMENT BY 1 START WITH 1
GO;

CREATE SEQUENCE seq_k_bugs_track INCREMENT BY 1 START WITH 1
GO;

CREATE OR REPLACE PROCEDURE k_sp_prj_expand (StartWith CHAR) IS

  wlk  NUMBER(11) := 1;
  parent CHAR(32) := NULL;
  curname VARCHAR2(50);

BEGIN

  DELETE k_project_expand WHERE gu_rootprj = StartWith;

  SELECT nm_project INTO curname FROM k_projects WHERE gu_project=StartWith;

  INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (StartWith, StartWith, curname, 1, 1, NULL);

  FOR cRec IN ( SELECT gu_project,nm_project,id_parent,level FROM k_projects
  		START WITH id_parent = StartWith
                CONNECT BY id_parent = PRIOR gu_project)
  LOOP

     IF cRec.id_parent IS NULL AND parent IS NULL THEN
       wlk := wlk + 1;
     ELSIF cRec.id_parent=parent THEN
       wlk := wlk + 1;
     ELSE
       parent := cRec.id_parent;
       wlk := wlk + 1;
     END IF;

     INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (StartWith, cRec.gu_project, cRec.nm_project, cRec.level+1, wlk, cRec.id_parent);

  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    curname := NULL;
END k_sp_prj_expand;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_bug (BugId CHAR) IS
BEGIN
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=BugId;
  DELETE FROM k_bugs_track WHERE gu_bug=BugId;  
  DELETE FROM k_bugs_changelog WHERE gu_bug=BugId;
  DELETE FROM k_bugs_attach WHERE gu_bug=BugId;
  DELETE FROM k_bugs WHERE gu_bug=BugId;
END k_sp_del_bug;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_duty (DutyId CHAR) IS
BEGIN
  DELETE FROM k_duties_dependencies WHERE gu_previous=DutyId OR gu_next=DutyId;
  DELETE FROM k_x_duty_resource WHERE gu_duty=DutyId;
  DELETE FROM k_duties_attach WHERE gu_duty=DutyId;
  DELETE FROM k_duties WHERE gu_duty=DutyId;
END k_sp_del_duty;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_project (ProjId CHAR) IS
  chldid CHAR(32);
  CURSOR childs IS SELECT gu_project FROM k_projects WHERE id_parent=ProjId AND id_parent<>gu_project;

BEGIN
  /* Borrar primero los proyectos hijos */
  FOR chld IN childs LOOP
    k_sp_del_project(chld.gu_project);
  END LOOP;

  DELETE k_duties_dependencies WHERE gu_previous IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId) OR gu_next IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId);
  DELETE k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId);
  DELETE k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ProjId);
  DELETE k_duties WHERE gu_project=ProjId;

  DELETE k_bugs_changelog WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ProjId);
  DELETE k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ProjId);
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ProjId);
  DELETE k_bugs WHERE gu_project=ProjId;

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=ProjId;

  DELETE k_duties_workreports WHERE gu_project=ProjId;
  DELETE k_project_snapshots WHERE gu_project=ProjId;
  DELETE k_project_costs WHERE gu_project=ProjId;
  DELETE k_project_expand WHERE gu_project=ProjId;
  DELETE k_projects WHERE gu_project=ProjId;
END k_sp_del_project;
GO;

CREATE FUNCTION k_sp_prj_cost (ProjectId CHAR) RETURN NUMBER IS
  fCost NUMBER := 0;
  fMore NUMBER := 0;
  fDuty NUMBER;
BEGIN

  FOR cProj IN (SELECT gu_project,id_parent FROM k_projects
                START WITH gu_project = ProjectId
                CONNECT BY id_parent = PRIOR gu_project)
  LOOP

    SELECT NVL(SUM(pr_cost),0) INTO fMore FROM k_project_costs WHERE gu_project=cProj.gu_project;

    SELECT NVL(SUM(d.pr_cost),0) INTO fDuty FROM k_duties d, k_projects p WHERE d.gu_project=p.gu_project AND p.gu_project=cProj.gu_project AND d.pr_cost IS NOT NULL;

    fCost := fCost + fDuty + fMore;

  END LOOP;

  RETURN fCost;
END k_sp_prj_cost;
GO;