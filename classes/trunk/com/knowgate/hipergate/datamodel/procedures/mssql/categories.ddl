CREATE PROCEDURE k_sp_get_cat_id @NmCategory NVARCHAR(30), @IdCategory CHAR(32) OUTPUT AS
  SET @IdCategory=NULL
  SELECT @IdCategory=gu_category FROM k_categories WITH (NOLOCK) WHERE nm_category=@NmCategory OPTION (FAST 1)
GO;


CREATE PROCEDURE k_sp_cat_descendant @IdCategory CHAR(32), @IdAncestor CHAR(32), @BoChild SMALLINT OUTPUT AS
  /* Devuelve @BoChild=1 si @IdCategory es descendiente a algun nivel de la Categoría @IdAncestor
     Si @IdAncestor no es padre ni abuelo de @IdCategory devuelve @BoChild=0
  */
  DECLARE @IdNextParent CHAR(32)
  
  CREATE TABLE #k_tmp_parents (gu_category CHAR(32) NOT NULL, bo_explored SMALLINT)

  INSERT INTO #k_tmp_parents SELECT gu_parent_cat,0 FROM k_cat_tree WHERE gu_child_cat=@IdCategory OPTION (FAST 1)
  
  DECLARE parents CURSOR LOCAL DYNAMIC FOR SELECT gu_category FROM #k_tmp_parents WHERE bo_explored=0 FOR UPDATE OF bo_explored
    
  OPEN parents  
    FETCH NEXT FROM parents INTO @IdNextParent
    WHILE @@FETCH_STATUS = 0
      BEGIN
        UPDATE #k_tmp_parents SET bo_explored=1 FROM #k_tmp_parents WHERE CURRENT OF parents
        INSERT INTO #k_tmp_parents SELECT gu_parent_cat,0 FROM k_cat_tree WHERE gu_child_cat=@IdNextParent OPTION (FAST 1)
        FETCH NEXT FROM parents INTO @IdNextParent
      END
  CLOSE parents
  DEALLOCATE parents
  
  SET @IdNextParent = NULL
  SELECT @IdNextParent=gu_category FROM #k_tmp_parents WHERE gu_category = @IdAncestor

  DROP TABLE #k_tmp_parents

  IF (@IdNextParent IS NULL)
    SET @BoChild = 0
  ELSE	  
    SET @BoChild = 1

GO;


CREATE PROCEDURE k_sp_cat_level @IdCategory CHAR(32), @Level INTEGER OUTPUT AS
  DECLARE @boFound  SMALLINT,
  	  @IdChild  CHAR(32),
  	  @IdParent CHAR(32)
  
  SET @Level = 0
  SET @boFound = 1
  SET @IdChild = @IdCategory
  
  WHILE @boFound<>0 AND @Level<>-1
    BEGIN
      SET @Level = @Level + 1
      SET @IdParent = NULL
      SELECT TOP 1 @IdParent=gu_parent_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_child_cat=@IdChild
      IF @IdParent IS NULL
        SET @boFound=0
      ELSE
        BEGIN
          IF @IdParent=@IdChild
            SET @Level = -1
          ELSE
            SET @IdChild = @IdParent
        END
    END
GO;


CREATE PROCEDURE k_sp_del_category @IdCategory CHAR(32) AS
  /* Borrar una categoria  */

  DELETE FROM k_cat_expand WHERE gu_rootcat=@IdCategory
  DELETE FROM k_cat_expand WHERE gu_parent_cat=@IdCategory
  DELETE FROM k_cat_expand WHERE gu_category=@IdCategory
  DELETE FROM k_cat_tree WHERE gu_child_cat=@IdCategory
  DELETE FROM k_cat_root WHERE gu_category=@IdCategory
  DELETE FROM k_cat_labels WHERE gu_category=@IdCategory
  DELETE FROM k_x_cat_user_acl WHERE gu_category=@IdCategory
  DELETE FROM k_x_cat_group_acl WHERE gu_category=@IdCategory
  DELETE FROM k_x_cat_objs WHERE gu_category=@IdCategory  
  DELETE FROM k_categories WHERE gu_category=@IdCategory
GO;


CREATE PROCEDURE k_sp_del_category_r @IdCategory CHAR(32) AS
  /* Borrar en cascada una categoria y todos sus registros asociados.
     Este procedimiento borra una categoria y todas sus hijas */
  DECLARE @IdChild CHAR(32)
  DECLARE childs CURSOR LOCAL STATIC FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory
  OPEN childs
    FETCH NEXT FROM childs INTO @IdChild
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_category_r @IdChild
        FETCH NEXT FROM childs INTO @IdChild
      END
  CLOSE childs
  DEALLOCATE childs
  EXECUTE k_sp_del_category @IdCategory
GO;

CREATE PROCEDURE k_sp_get_cat_path @IdCategory CHAR(32), @CatPath NVARCHAR(4000) OUTPUT AS
  DECLARE @Neighbour CHAR(32),
  	  @Neighname NVARCHAR(30),
  	  @DoNext    SMALLINT
  	  
  SELECT @CatPath=nm_category FROM k_categories WHERE gu_category=@IdCategory
  SET @DoNext = 1
  WHILE @DoNext = 1
    BEGIN
      SET @Neighbour = NULL
      SELECT TOP 1 @Neighbour = gu_parent_cat FROM k_cat_tree WHERE gu_child_cat=@IdCategory
      IF @Neighbour IS NULL
	SET @DoNext = 0
      IF @DoNext = 1
        BEGIN
          IF @IdCategory=@Neighbour
            SET @DoNext = 0
          ELSE
            BEGIN
              SELECT @Neighname = nm_category FROM k_categories WHERE gu_category=@Neighbour
	      SET @CatPath = @Neighname + '/' + @CatPath          
            END
          SET @IdCategory = @Neighbour
        END
    END
GO;

CREATE PROCEDURE k_sp_cat_obj_position @IdObj CHAR(32), @IdCategory CHAR(32), @Position INTEGER OUTPUT AS 
  SET @Position=NULL
  SELECT @Position=od_position FROM k_x_cat_objs WHERE gu_category=@IdCategory AND gu_object=@IdObj OPTION (FAST 1)
GO;

CREATE PROCEDURE k_sp_cat_expand @StartWith CHAR(32) AS

DECLARE @lvl AS INTEGER,
        @wlk    INTEGER,
	@current AS CHAR(32),
	@parent  AS CHAR(32)	

SET NOCOUNT ON

BEGIN
   
  DELETE k_cat_expand WHERE gu_rootcat = @StartWith
  
  CREATE TABLE #tmp_stack (item CHAR(32), lvl INTEGER, prnt CHAR(32))

  INSERT INTO #tmp_stack VALUES (@StartWith, 1, NULL)
  
  SET @wlk = 1
  SET @lvl = 1

  WHILE @lvl > 0

  BEGIN

    IF EXISTS (SELECT item FROM #tmp_stack WHERE lvl = @lvl)

        BEGIN

            SELECT @current=item, @parent=prnt FROM #tmp_stack WHERE lvl = @lvl

	    INSERT INTO k_cat_expand VALUES(@StartWith, @current, @lvl, @wlk, @parent)

            SET @wlk = @wlk + 1
	    	    
            DELETE FROM #tmp_stack WHERE lvl = @lvl AND item = @current

            INSERT #tmp_stack SELECT p.gu_child_cat, @lvl + 1, p.gu_parent_cat FROM k_cat_tree p WHERE p.gu_parent_cat = @current AND NOT EXISTS (SELECT e.gu_category FROM k_cat_expand e WHERE e.gu_category=p.gu_child_cat AND e.gu_rootcat=@StartWith)

            IF @@ROWCOUNT > 0
              SET @lvl = @lvl + 1
        END

    ELSE

        SET @lvl = @lvl - 1

  END -- WHILE
  
END
GO;

CREATE PROCEDURE k_sp_del_user @IdUser CHAR(32) AS
  DELETE k_x_group_user WHERE gu_user=@IdUser
  DELETE k_x_cat_user_acl WHERE gu_user=@IdUser
  DELETE k_users WHERE gu_user=@IdUser
GO;

CREATE PROCEDURE k_sp_del_group @IdGroup CHAR(32) AS
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=@IdGroup
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=@IdGroup
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=@IdGroup
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=@IdGroup
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=@IdGroup
  
  DELETE k_working_calendar WHERE gu_acl_group=@IdGroup
  DELETE k_x_group_company WHERE gu_acl_group=@IdGroup
  DELETE k_x_group_contact WHERE gu_acl_group=@IdGroup
  DELETE k_x_group_user WHERE gu_acl_group=@IdGroup
  DELETE k_x_cat_group_acl WHERE gu_acl_group=@IdGroup
  DELETE k_acl_groups WHERE gu_acl_group=@IdGroup
GO;

CREATE PROCEDURE k_sp_cat_grp_perm @IdGroup CHAR(32), @IdCategory CHAR(32), @ACLMask INTEGER OUTPUT AS
  DECLARE @IdParent CHAR(32)
  SET @ACLMask=NULL
  SELECT @ACLMask=acl_mask FROM k_x_cat_group_acl WITH (NOLOCK) WHERE gu_category=@IdCategory AND gu_acl_group=@IdGroup

  IF (@ACLMask IS NULL)
    BEGIN
      SELECT TOP 1 @IdParent=gu_parent_cat FROM k_cat_tree WHERE gu_child_cat=@IdCategory
      IF (@IdParent=@IdCategory OR @IdParent IS NULL)
        SET @ACLMask=0
      ELSE
        EXECUTE k_sp_cat_grp_perm @IdGroup, @IdParent, @ACLMask OUTPUT   
    END
GO;
    
CREATE PROCEDURE k_sp_cat_usr_perm @IdUser CHAR(32), @IdCategory CHAR(32), @ACLMask INTEGER OUTPUT AS
  /* Devuelve los permisos que tiene un usuario para una categoría, teniendo en cuenta
     los grupos a los que pertenece y los permisos otorgados a las categorías padre si
     es que no hay asignación explícita de permisos al usuario para la categoría especificada */
  DECLARE @IdParent CHAR(32)
  DECLARE @IdChild  CHAR(32)
  DECLARE @IdACLGroup CHAR(32)
  DECLARE groups CURSOR LOCAL FAST_FORWARD FOR SELECT gu_acl_group FROM k_x_group_user WITH (NOLOCK) WHERE gu_user=@IdUser
  
  SET @ACLMask=NULL
  SET @IdChild=@IdCategory
  
  user_loop:
  SELECT @ACLMask=acl_mask FROM k_x_cat_user_acl WITH (NOLOCK) WHERE gu_category=@IdChild AND gu_user=@IdUser

  IF (@ACLMask IS NULL)
    BEGIN
      SET @IdParent=@IdChild
      SELECT TOP 1 @IdParent=gu_parent_cat FROM k_cat_tree WHERE gu_child_cat=@IdChild
      IF @IdParent<>@IdChild
	BEGIN
	  SET @IdChild=@IdParent 
	  GOTO user_loop
	END
    END

  IF (@ACLMask IS NULL)
    BEGIN
      OPEN groups
      
      FETCH NEXT FROM groups INTO @IdACLGroup
      WHILE @@FETCH_STATUS = 0
        BEGIN
  	  SET @IdChild=@IdCategory
	  
	  group_loop:
          
          SELECT @ACLMask=acl_mask FROM k_x_cat_group_acl WITH (NOLOCK) WHERE gu_category=@IdChild AND gu_acl_group=@IdACLGroup
  	  IF (@ACLMask IS NULL)
    	    BEGIN
      	    SET @IdParent=@IdChild
      	    SELECT TOP 1 @IdParent=gu_parent_cat FROM k_cat_tree WHERE gu_child_cat=@IdChild
      	    IF @IdParent<>@IdChild
	      BEGIN
	        SET @IdChild=@IdParent 
	  	GOTO group_loop
	      END
            END
          FETCH NEXT FROM groups INTO @IdACLGroup
	END
      CLOSE groups
    END
  IF (@ACLMask IS NULL) SET @ACLMask=0
GO;

CREATE PROCEDURE k_sp_cat_del_grp @IdCategory CHAR(32), @IdGroup CHAR(32), @Recurse SMALLINT, @Objects SMALLINT AS
  /* Borrar los permisos asignados a un grupo dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdGroup: Identificador unico del grupo
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */
  DECLARE @IdChild CHAR(32)
  DECLARE chldcat CURSOR LOCAL FAST_FORWARD FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory
  DELETE FROM k_x_cat_group_acl WHERE gu_category=@IdCategory AND gu_acl_group=@IdGroup
  IF @Recurse<>0
    BEGIN
      OPEN chldcat
        FETCH NEXT FROM chldcat INTO @IdChild
        WHILE @@FETCH_STATUS = 0
          BEGIN
            EXECUTE k_sp_cat_del_grp @IdChild, @IdGroup, @Recurse, @Objects 
            FETCH NEXT FROM chldcat INTO @IdChild
	  END
      CLOSE chldcat
    END     
GO;

CREATE PROCEDURE k_sp_cat_del_usr @IdCategory CHAR(32), @IdUser CHAR(32), @Recurse SMALLINT, @Objects SMALLINT AS
  /* Borrar los permisos asignados a un usuario dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdUser: Identificador unico del usuario k_users.gu_user
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */
  DECLARE @IdChild CHAR(32)
  DECLARE chldcat CURSOR LOCAL FAST_FORWARD FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory
  DELETE FROM k_x_cat_user_acl WHERE gu_category=@IdCategory AND gu_user=@IdUser
  IF @Recurse<>0
    BEGIN
      OPEN chldcat
        FETCH NEXT FROM chldcat INTO @IdChild
        WHILE @@FETCH_STATUS = 0
          BEGIN
            EXECUTE k_sp_cat_del_usr @IdChild, @IdUser, @Recurse, @Objects 
            FETCH NEXT FROM chldcat INTO @IdChild
	  END
      CLOSE chldcat
    END    
GO;

CREATE PROCEDURE k_sp_cat_set_grp @IdCategory CHAR(32), @IdGroup CHAR(32), @ACLMask INTEGER, @Recurse SMALLINT, @Objects SMALLINT AS
  /* Establece los permisos asignados a un grupo dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdGroup: Identificador unico del grupo
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */
  DECLARE @IdChild CHAR(32)
  DECLARE @PrevMask INTEGER
  DECLARE childs CURSOR LOCAL FAST_FORWARD FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory

  IF @IdCategory IS NOT NULL AND @IdGroup IS NOT NULL
    BEGIN
      SET @PrevMask = NULL
  
      SELECT @PrevMask=acl_mask FROM k_x_cat_group_acl WHERE gu_category=@IdCategory AND gu_acl_group=@IdGroup
  
      IF @PrevMask IS NULL
        INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES (@IdCategory, @IdGroup, @ACLMask)
      ELSE
        UPDATE k_x_cat_group_acl SET acl_mask = @ACLMask WHERE gu_category=@IdCategory AND gu_acl_group=@IdGroup
    END
    
  IF @Recurse<>0
    BEGIN
      OPEN childs
        FETCH NEXT FROM childs INTO @IdChild
        WHILE @@FETCH_STATUS = 0
          BEGIN
            EXECUTE k_sp_cat_set_grp @IdChild, @IdGroup, @ACLMask, @Recurse, @Objects 
            FETCH NEXT FROM childs INTO @IdChild
          END
      CLOSE childs
    END    
GO;

CREATE PROCEDURE k_sp_cat_set_usr @IdCategory CHAR(32), @IdUser CHAR(32), @ACLMask INTEGER, @Recurse SMALLINT, @Objects SMALLINT AS
  /* Establece los permisos asignados a un usuario dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdUser: Identificador unico del usuario k_users.gu_user
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */
  DECLARE @IdChild CHAR(32)
  DECLARE @PrevMask INTEGER
  DECLARE childs CURSOR LOCAL FAST_FORWARD FOR SELECT gu_child_cat FROM k_cat_tree WITH (NOLOCK) WHERE gu_parent_cat=@IdCategory

  IF @IdCategory IS NOT NULL AND @IdUser IS NOT NULL
    BEGIN
      SET @PrevMask = NULL
  
      SELECT @PrevMask=acl_mask FROM k_x_cat_user_acl WHERE gu_category=@IdCategory AND gu_user=@IdUser

      IF @PrevMask IS NULL
        INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES (@IdCategory, @IdUser, @ACLMask)
      ELSE
        UPDATE k_x_cat_user_acl SET acl_mask=@ACLMask WHERE gu_category=@IdCategory AND gu_user=@IdUser
    END
    
  IF @Recurse<>0
    BEGIN
      OPEN childs
        FETCH NEXT FROM childs INTO @IdChild
        WHILE @@FETCH_STATUS = 0
          BEGIN
            EXECUTE k_sp_cat_set_usr @IdChild, @IdUser, @ACLMask, @Recurse, @Objects 
            FETCH NEXT FROM childs INTO @IdChild
	  END
      CLOSE childs
    END  
GO;

CREATE PROCEDURE k_sp_get_user_mailroot @GuUser CHAR(32), @GuCategory CHAR(32) OUTPUT AS
  DECLARE @NickName   VARCHAR(32)
  DECLARE @NmDomain   NVARCHAR(30)
  DECLARE @NmCategory NVARCHAR(100)

  SET @NickName = NULL
  SET @GuCategory = NULL
  
  SELECT @NickName=u.tx_nickname, @NmDomain=nm_domain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=@GuUser

  IF @NickName IS NOT NULL
    SELECT @GuCategory=gu_category FROM k_categories WHERE nm_category=@NmDomain + N'_' + @NickName + N'_mail'
GO;

CREATE PROCEDURE k_sp_get_user_mailfolder @GuUser CHAR(32), @NmFolder NVARCHAR(100), @GuCategory CHAR(32) OUTPUT AS
  DECLARE @NickName   VARCHAR(32)
  DECLARE @NmDomain   NVARCHAR(30)
  DECLARE @NmCategory NVARCHAR(100)
  DECLARE @GuMailRoot CHAR(32)

  SET @NickName = NULL
  SET @GuCategory = NULL
  
  SELECT @NickName=u.tx_nickname, @NmDomain=nm_domain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=@GuUser

  IF @NickName IS NOT NULL
    BEGIN
      EXECUTE k_sp_get_user_mailroot @GuUser, @GuMailRoot OUTPUT
      IF @GuMailRoot IS NOT NULL
        SELECT @GuCategory=c.gu_category FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=@GuMailRoot AND (c.nm_category=@NmDomain + N'_' + @NickName + N'_' + @NmFolder OR c.nm_category=@NmFolder)
    END
GO;