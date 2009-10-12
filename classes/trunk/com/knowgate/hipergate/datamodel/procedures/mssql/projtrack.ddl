INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_bugs', 1, 2147483647, 1, 1)
GO;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_bugs_track', 1, 2147483647, 1, 1)
GO;

CREATE PROCEDURE k_sp_prj_expand @StartWith CHAR(32) AS

DECLARE @lvl AS INTEGER,
        @wlk    INTEGER,
	@curname NVARCHAR(50),
	@current AS CHAR(32),
	@parent  AS CHAR(32)	

SET NOCOUNT ON

BEGIN
   
  DELETE k_project_expand WHERE gu_rootprj = @StartWith
  
  CREATE TABLE #tmp_stack (item CHAR(32), lvl INTEGER, iname NVARCHAR(50), prnt CHAR(32))

  SET @curname=NULL
  
  SELECT @curname=nm_project FROM k_projects WHERE gu_project=@StartWith

  IF @curname IS NOT NULL
    BEGIN
      INSERT INTO #tmp_stack VALUES (@StartWith, 1, @curname, NULL)
  
      SET @wlk = 1
      SET @lvl = 1
    
      WHILE @lvl > 0
    
      BEGIN
    
        IF EXISTS (SELECT item FROM #tmp_stack WHERE lvl = @lvl)
    
            BEGIN
    
                SELECT @current=item, @curname=iname, @parent=prnt FROM #tmp_stack WHERE lvl = @lvl
    
    	        INSERT INTO k_project_expand (gu_rootprj,gu_project,nm_project,od_level,od_walk,gu_parent) VALUES (@StartWith, @current, @curname, @lvl, @wlk, @parent)
    		
                SET @wlk = @wlk + 1
    	    	    
                DELETE FROM #tmp_stack WHERE lvl = @lvl AND item = @current
    
                INSERT #tmp_stack SELECT p.gu_project, @lvl + 1, p.nm_project, p.id_parent FROM k_projects p WHERE p.id_parent = @current AND NOT EXISTS (SELECT e.gu_project FROM k_project_expand e WHERE e.gu_project=p.gu_project AND e.gu_rootprj=@StartWith)
    
                IF @@ROWCOUNT > 0
                  SET @lvl = @lvl + 1
            END
    
        ELSE
    
            SET @lvl = @lvl - 1
    
      END -- WHILE
    END -- IF @curname IS NOT NULL
END
GO;

CREATE PROCEDURE k_sp_del_bug @BugId CHAR(32) AS
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref=@BugId
  DELETE FROM k_bugs_track WHERE gu_bug=@BugId
  DELETE FROM k_bugs_changelog WHERE gu_bug=@BugId
  DELETE FROM k_bugs_attach WHERE gu_bug=@BugId
  DELETE FROM k_bugs WHERE gu_bug=@BugId
GO;

CREATE PROCEDURE k_sp_del_duty @DutyId CHAR(32) AS
  DELETE FROM k_duties_dependencies WHERE gu_previous=@DutyId OR gu_next=@DutyId
  DELETE FROM k_x_duty_resource WHERE gu_duty=@DutyId
  DELETE FROM k_duties_attach WHERE gu_duty=@DutyId
  DELETE FROM k_duties WHERE gu_duty=@DutyId
GO;

CREATE PROCEDURE k_sp_del_project @ProjId CHAR(32) AS
  DECLARE @chldid CHAR(32)
  DECLARE childs CURSOR LOCAL FAST_FORWARD FOR SELECT gu_project FROM k_projects WHERE id_parent=@ProjId
  
  /* Borrar primero recursivamente los proyectos hijos */
  OPEN childs
    FETCH NEXT FROM childs INTO @chldid
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_project @chldid
        FETCH NEXT FROM childs INTO @chldid
      END
  CLOSE childs
  
  DELETE k_duties_dependencies WHERE gu_previous IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId) OR gu_next IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId)
  DELETE k_x_duty_resource WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId)
  DELETE k_duties_attach WHERE gu_duty IN (SELECT gu_duty FROM k_duties WHERE gu_project=@ProjId)
  DELETE k_duties WHERE gu_project=@ProjId

  DELETE k_bugs_changelog WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=@ProjId)
  DELETE k_bugs_attach WHERE gu_bug IN (SELECT gu_bug FROM k_bugs WHERE gu_project=@ProjId)
  UPDATE k_bugs SET gu_bug_ref=NULL WHERE gu_bug_ref IN (SELECT gu_bug FROM k_bugs WHERE gu_project=@ProjId)
  DELETE k_bugs WHERE gu_project=@ProjId

  /* Borrar las referencias de PageSets */
  UPDATE k_pagesets SET gu_project=NULL WHERE gu_project=@ProjId

  DELETE FROM k_duties_workreports WHERE gu_project=@ProjId
  DELETE FROM k_project_snapshots WHERE gu_project=@ProjId
  DELETE FROM k_project_costs WHERE gu_project=@ProjId    
  DELETE k_project_expand WHERE gu_project=@ProjId
  DELETE k_projects WHERE gu_project=@ProjId
GO;

CREATE FUNCTION db_accessadmin.k_sp_prj_cost (@ProjectId CHAR(32)) RETURNS FLOAT AS
BEGIN
  DECLARE @fCost FLOAT
  DECLARE @fMore FLOAT
  DECLARE @ChlId CHAR(32)
  DECLARE childs CURSOR LOCAL READ_ONLY FOR SELECT gu_project FROM k_projects WHERE id_parent=@ProjectId

  SELECT @fMore=ISNULL(SUM(pr_cost),0) FROM k_project_costs WHERE gu_project=@ProjectId   
  SELECT @fCost=ISNULL(SUM(d.pr_cost),0) FROM k_duties d, k_projects p WITH (NOLOCK) WHERE d.gu_project=p.gu_project AND p.gu_project=@ProjectId AND d.pr_cost IS NOT NULL
  SET @fCost = @fCost + @fMore
  
  OPEN childs
    FETCH NEXT FROM childs INTO @ChlId
    WHILE @@FETCH_STATUS = 0
      BEGIN
        SET @fCost = @fCost + dbo.k_sp_prj_cost(@ChlId)
        FETCH NEXT FROM childs INTO @ChlId
      END
  CLOSE childs

  RETURN (@fCost)
END
GO;

CREATE FUNCTION dbo.k_sp_prj_cost (@ProjectId CHAR(32)) RETURNS FLOAT AS
BEGIN
  DECLARE @fCost FLOAT
  DECLARE @fMore FLOAT
  DECLARE @ChlId CHAR(32)
  DECLARE childs CURSOR LOCAL READ_ONLY FOR SELECT gu_project FROM k_projects WHERE id_parent=@ProjectId

  SELECT @fMore=ISNULL(SUM(pr_cost),0) FROM k_project_costs WHERE gu_project=@ProjectId   
  SELECT @fCost=ISNULL(SUM(d.pr_cost),0) FROM k_duties d, k_projects p WITH (NOLOCK) WHERE d.gu_project=p.gu_project AND p.gu_project=@ProjectId AND d.pr_cost IS NOT NULL
  SET @fCost = @fCost + @fMore
  
  OPEN childs
    FETCH NEXT FROM childs INTO @ChlId
    WHILE @@FETCH_STATUS = 0
      BEGIN
        SET @fCost = @fCost + dbo.k_sp_prj_cost(@ChlId)
        FETCH NEXT FROM childs INTO @ChlId
      END
  CLOSE childs

  RETURN (@fCost)
END
GO;