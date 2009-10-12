INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_bugs', 1, 2147483647, 1, 1)
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_bugs_track', 1, 2147483647, 1, 1)
GO;

CREATE PROCEDURE k_sp_prj_expand (Prj CHAR(32))
BEGIN
  DECLARE Walk  INT;
  DECLARE Level INT;
  DECLARE Depth INT; 
  DECLARE Unwalked INT;
  DECLARE GuPrnt CHAR(32);
  DECLARE GuChld CHAR(32);
  DECLARE NmChld VARCHAR(50);
  DECLARE CurName VARCHAR(50) DEFAULT NULL;
  DECLARE StackBot INTEGER;
  DECLARE StackTop INTEGER;
  DECLARE Done INT DEFAULT 0;
  DECLARE childs CURSOR FOR SELECT gu_prj,nm_prj,od_lvl,od_wlk,gu_par FROM tmp_exp_prj_stack ORDER BY od_wlk;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

  DELETE FROM k_project_expand WHERE gu_rootprj = Prj;

  SELECT nm_project INTO CurName FROM k_projects WHERE gu_project=Prj;

  IF CurName IS NOT NULL THEN

    CREATE TEMPORARY TABLE tmp_exp_prj_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_rot CHAR(32) NOT NULL, gu_prj CHAR(32) NOT NULL, nm_prj VARCHAR(50) NOT NULL, od_lvl INTEGER NOT NULL, gu_par CHAR(32) NULL, od_wlk INTEGER NULL) TYPE MYISAM;
    CREATE TEMPORARY TABLE tmp_exp_prj_slice (gu_prj CHAR(32) NOT NULL, nm_prj VARCHAR(50) NOT NULL, gu_par CHAR(32) NOT NULL) ENGINE = MEMORY;

    INSERT INTO tmp_exp_prj_stack (gu_rot,gu_prj,nm_prj,od_lvl,gu_par,od_wlk) VALUES (Prj, Prj, curname, 1, NULL, 1);
    SET Level = 2;
    SET StackBot = 1;
    SET StackTop = 1;
    
    REPEAT
      INSERT INTO tmp_exp_prj_slice (gu_prj,nm_prj,gu_par) SELECT gu_project,nm_project,id_parent FROM k_projects WHERE gu_project<>id_parent AND id_parent IN (SELECT gu_prj FROM tmp_exp_prj_stack WHERE nu_pos BETWEEN StackBot AND StackTop);
      INSERT INTO tmp_exp_prj_stack (gu_rot,gu_prj,nm_prj,od_lvl,gu_par,od_wlk) SELECT Prj,gu_prj,nm_prj,Level,gu_par,NULL FROM tmp_exp_prj_slice;
      DELETE FROM tmp_exp_prj_slice;
      SET StackBot = StackTop+1;
      SET Level = Level+1;
      SELECT MAX(nu_pos) INTO StackTop FROM tmp_exp_prj_stack;
      UNTIL StackTop<StackBot
    END REPEAT;

    SET Walk = 2;
    SET Level = 2;
    SET GuPrnt = Prj;
    SELECT COUNT(*) INTO Unwalked FROM tmp_exp_prj_stack WHERE od_wlk IS NULL;    
    SELECT MAX(od_lvl) INTO Depth FROM tmp_exp_prj_stack;
    WHILE Unwalked>0 AND Level>1 DO
      SET GuChld=NULL;
      SELECT gu_prj INTO GuChld FROM tmp_exp_prj_stack WHERE od_wlk IS NULL AND gu_par=GuPrnt ORDER BY nu_pos LIMIT 0,1;
      IF GuChld IS NULL THEN      
        SET Level = Level-1;
        SELECT id_parent INTO GuPrnt FROM k_projects WHERE gu_project=GuPrnt;
      ELSE
        UPDATE tmp_exp_prj_stack SET od_wlk=Walk WHERE gu_prj=GuChld;
        SET Walk = Walk+1;
        SET Level = Level+1;
        SET GuPrnt = GuChld;
      END IF;
      SELECT COUNT(*) INTO Unwalked FROM tmp_exp_prj_stack WHERE od_wlk IS NULL;    
    END WHILE;
    
    SET Done=0;
    OPEN childs;
    REPEAT
      FETCH childs INTO GuChld, NmChld,Level,Walk,GuPrnt;
      IF Done=0 THEN
        INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (Prj, GuChld, NmChld, Level, Walk, GuPrnt);
      END IF;
    UNTIL Done=1 END REPEAT;
    CLOSE childs;
  END IF;

  DROP TEMPORARY TABLE tmp_exp_prj_slice;
  DROP TEMPORARY TABLE tmp_exp_prj_stack;  
END
GO;

CREATE PROCEDURE k_sp_del_bug (BugId CHAR(32))
BEGIN
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=BugId;
  DELETE FROM k_bugs_track WHERE gu_bug=BugId;  
  DELETE FROM k_bugs_changelog WHERE gu_bug=BugId;
  DELETE FROM k_bugs_attach WHERE gu_bug=BugId;
  DELETE FROM k_bugs WHERE gu_bug=BugId;
END
GO;

CREATE PROCEDURE k_sp_del_duty (DutyId CHAR(32))
BEGIN
  DELETE FROM k_duties_dependencies WHERE gu_previous=DutyId OR gu_next=DutyId;
  DELETE FROM k_x_duty_resource WHERE gu_duty=DutyId;
  DELETE FROM k_duties_attach WHERE gu_duty=DutyId;
  DELETE FROM k_duties WHERE gu_duty=DutyId;
END
GO;

CREATE PROCEDURE k_sp_del_project (ProjId CHAR(32))
BEGIN
  DECLARE ChldId CHAR(32);
  DECLARE StackBot INTEGER;
  DECLARE StackTop INTEGER;
  DECLARE Done INT DEFAULT 0;
  DECLARE prjs CURSOR FOR SELECT gu_prj FROM tmp_del_prj_stack ORDER BY nu_pos DESC;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  CREATE TEMPORARY TABLE tmp_del_prj_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_prj CHAR(32) NOT NULL) TYPE MYISAM;
  CREATE TEMPORARY TABLE tmp_del_prj_slice (gu_prj CHAR(32) NOT NULL) ENGINE = MEMORY;
    
  SET StackBot = 1;
  SET StackTop = 1;
  INSERT INTO tmp_del_prj_stack (gu_prj) VALUES (ProjId);
  
  REPEAT
    INSERT INTO tmp_del_prj_slice (gu_prj) SELECT gu_project FROM k_projects WHERE id_parent<>gu_project AND id_parent IN (SELECT gu_prj FROM tmp_del_prj_stack WHERE nu_pos BETWEEN StackBot AND StackTop);
    INSERT INTO tmp_del_prj_stack (gu_prj) SELECT gu_prj FROM tmp_del_prj_slice;
    DELETE FROM tmp_del_prj_slice;
    SET StackBot = StackTop+1;
    SELECT MAX(nu_pos) INTO StackTop FROM tmp_del_prj_stack;
    UNTIL StackTop<StackBot
  END REPEAT;

  OPEN prjs;
    REPEAT
      FETCH prjs INTO ChldId;
      IF Done=0 THEN
        DELETE FROM k_duties_dependencies WHERE gu_previous IN (SELECT gu_duty FROM k_duties WHERE gu_project=ChldId) OR gu_next IN (SELECT gu_duty FROM k_duties WHERE gu_project=ChldId);
        DELETE FROM k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ChldId);
        DELETE FROM k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=ChldId);
        DELETE FROM k_duties WHERE gu_project=ChldId;

        DELETE FROM k_bugs_changelog WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ChldId);
        DELETE FROM k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ChldId);
  		UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref IN (SELECT gu_bug FROM k_bugs WHERE gu_project=ChldId);
        DELETE FROM k_bugs WHERE gu_project=ChldId;

        UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=ChldId;

		DELETE FROM k_duties_workreports WHERE gu_project=ChldId;
		DELETE FROM k_project_snapshots WHERE gu_project=ChldId;
        DELETE FROM k_project_costs WHERE gu_project=ChldId;
        DELETE FROM k_project_expand WHERE gu_project=ChldId;
        DELETE FROM k_projects WHERE gu_project=ChldId;
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE prjs;

  DROP TEMPORARY TABLE tmp_del_prj_slice;
  DROP TEMPORARY TABLE tmp_del_prj_stack;
END
GO;

CREATE FUNCTION k_sp_prj_cost (ProjectId CHAR(32)) RETURNS FLOAT
BEGIN
  DECLARE ChldId CHAR(32);
  DECLARE StackBot INTEGER;
  DECLARE StackTop INTEGER;
  DECLARE fCost FLOAT;
  DECLARE fMore FLOAT;
  DECLARE fDuty FLOAT;

  CREATE TEMPORARY TABLE tmp_cost_prj_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_prj CHAR(32) NOT NULL) TYPE MYISAM;
  CREATE TEMPORARY TABLE tmp_cost_prj_slice (gu_prj CHAR(32) NOT NULL) ENGINE = MEMORY;
    
  SET StackBot = 1;
  SET StackTop = 1;
  INSERT INTO tmp_cost_prj_stack (gu_prj) VALUES (ProjectId);
  REPEAT
    INSERT INTO tmp_cost_prj_slice (gu_prj) SELECT gu_project FROM k_projects WHERE id_parent<>gu_project AND id_parent IN (SELECT gu_prj FROM tmp_cost_prj_stack WHERE nu_pos BETWEEN StackBot AND StackTop);
    INSERT INTO tmp_cost_prj_stack (gu_prj) SELECT gu_prj FROM tmp_cost_prj_slice;
    DELETE FROM tmp_cost_prj_slice;
    SET StackBot = StackTop+1;
    SELECT MAX(nu_pos) INTO StackTop FROM tmp_cost_prj_stack;
    UNTIL StackTop<StackBot
  END REPEAT;

  DROP TEMPORARY TABLE tmp_cost_prj_slice;

  SELECT COALESCE(SUM(pr_cost),0) INTO fMore FROM k_project_costs WHERE gu_project IN (SELECT gu_prj FROM tmp_cost_prj_stack);
  SELECT COALESCE(SUM(d.pr_cost),0) INTO fDuty FROM k_duties d, k_projects p WHERE d.gu_project=p.gu_project AND p.gu_project IN (SELECT gu_prj FROM tmp_cost_prj_stack) AND d.pr_cost IS NOT NULL;
  SET fCost = fDuty + fMore;

  DROP TEMPORARY TABLE tmp_cost_prj_stack;
  
  RETURN fCost;
END 
GO;