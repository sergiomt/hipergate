CREATE OR REPLACE PROCEDURE k_sp_get_cat_id (NmCategory VARCHAR2, IdCategory OUT CHAR) IS
BEGIN
  SELECT gu_category INTO IdCategory FROM k_categories WHERE nm_category=NmCategory;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdCategory:=NULL;
END k_sp_get_cat_id;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_descendant (IdCategory CHAR, IdAncestor CHAR, BoChild OUT NUMBER) IS
  /* Devuelve BoChild=1 si IdCategory es descendiente a algun nivel de la Categoría IdAncestor
     Si IdAncestor no es padre ni abuelo de IdCategory devuelve BoChild=0
  */

  IdFound CHAR(32);
  CURSOR childs(id CHAR) IS SELECT gu_child_cat FROM k_cat_tree START WITH gu_parent_cat=id CONNECT BY gu_parent_cat=PRIOR gu_child_cat;
BEGIN
  BoChild := 0;

  OPEN childs(IdAncestor);
    WHILE BoChild=0 LOOP
      FETCH childs INTO IdFound;
      EXIT WHEN childs%NOTFOUND;
      IF IdFound=IdCategory THEN
        BoChild := 1;
      END IF;
    END LOOP;
  CLOSE childs;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    BoChild:=0;
END k_sp_cat_descendant;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_level (IdCategory CHAR, CatLevel OUT NUMBER) IS
  IdChild  CHAR(32) := IdCategory;
  IdParent CHAR(32) := NULL;

BEGIN

  CatLevel := 0;

  LOOP
    EXIT WHEN CatLevel=-1;
    CatLevel := CatLevel + 1;
    SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild AND ROWNUM=1;
    IF IdParent=IdChild THEN
      CatLevel := -1;
    ELSE
      IdChild := IdParent;
    END IF;
  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    CatLevel := CatLevel;

END k_sp_cat_level;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_category (IdCategory CHAR) IS
  /* Borrar una categoria  */
BEGIN

  DELETE FROM k_cat_expand WHERE gu_rootcat=IdCategory;
  DELETE FROM k_cat_expand WHERE gu_parent_cat=IdCategory;
  DELETE FROM k_cat_expand WHERE gu_category=IdCategory;
  DELETE FROM k_cat_tree WHERE gu_child_cat=IdCategory;
  DELETE FROM k_cat_root WHERE gu_category=IdCategory;
  DELETE FROM k_cat_labels WHERE gu_category=IdCategory;
  DELETE FROM k_x_cat_user_acl WHERE gu_category=IdCategory;
  DELETE FROM k_x_cat_group_acl WHERE gu_category=IdCategory;
  DELETE FROM k_x_cat_objs WHERE gu_category=IdCategory;
  DELETE FROM k_categories WHERE gu_category=IdCategory;

END k_sp_del_category ;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_category_r (IdCategory CHAR) IS
  /* Borrar en cascada una categoria y todos sus registros asociados.
     Este procedimiento borra una categoria y todas sus hijas */
  IdChild CHAR(32);
  CURSOR childs(id CHAR) IS SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=id;
BEGIN
  OPEN childs(IdCategory);
    LOOP
      FETCH childs INTO IdChild;
      EXIT WHEN childs%NOTFOUND;
      k_sp_del_category_r (IdChild);
    END LOOP;
  CLOSE childs;

  k_sp_del_category (IdCategory);

END k_sp_del_category_r;
GO;

CREATE OR REPLACE PROCEDURE k_sp_get_cat_path (CatId CHAR, CatPath OUT VARCHAR2) IS
  Neighbour CHAR(32);
  Neighname VARCHAR2(30);
  DoNext NUMBER(6);
  IdCategory CHAR(32);
BEGIN
  IdCategory := CatId;

  SELECT nm_category INTO CatPath FROM k_categories WHERE gu_category=IdCategory;

  DoNext := 1;
  LOOP
    EXIT WHEN DoNext<>1;
    Neighbour := NULL;
    SELECT gu_parent_cat INTO Neighbour FROM k_cat_tree WHERE gu_child_cat=IdCategory AND ROWNUM=1;

    IF DoNext = 1 THEN
      IF IdCategory=Neighbour THEN
        DoNext := 0;
      ELSE
        SELECT nm_category INTO Neighname FROM k_categories WHERE gu_category=Neighbour;
	CatPath := Neighname || '/' || CatPath;
        IdCategory := Neighbour;
      END IF;
    END IF;
  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DoNext := DoNext;
END k_sp_get_cat_path;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_obj_position (IdObj CHAR, IdCategory CHAR, Position OUT NUMBER) IS
BEGIN
  SELECT od_position INTO Position FROM k_x_cat_objs WHERE gu_category=IdCategory AND gu_object=IdObj;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    Position:=NULL;
END k_sp_cat_obj_position;
GO;


CREATE OR REPLACE PROCEDURE k_sp_cat_expand (StartWith CHAR) IS

  lvl NUMBER(11) := 1;
  wlk NUMBER(11) := 1;
  parent  CHAR(32) := NULL;

BEGIN

  DELETE k_cat_expand WHERE gu_rootcat = StartWith;

  INSERT INTO k_cat_expand VALUES (StartWith, StartWith, 1, 1, NULL);

  FOR cRec IN ( SELECT gu_child_cat,gu_parent_cat FROM k_cat_tree
  		START WITH gu_parent_cat = StartWith
                CONNECT BY gu_parent_cat = PRIOR gu_child_cat)
  LOOP

     IF cRec.gu_parent_cat IS NULL AND parent IS NULL THEN
       wlk := wlk + 1;

     ELSIF cRec.gu_parent_cat=parent THEN
       wlk := wlk + 1;
     ELSE
       lvl := lvl +1;
       parent := cRec.gu_parent_cat;
       wlk := 1;
     END IF;

     INSERT INTO k_cat_expand VALUES(StartWith, cRec.gu_child_cat, lvl, wlk, parent);

  END LOOP;

END k_sp_cat_expand;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_user (IdUser CHAR) IS
BEGIN
  DELETE k_x_group_user WHERE gu_user=IdUser;
  DELETE k_x_cat_user_acl WHERE gu_user=IdUser;
  DELETE k_users WHERE gu_user=IdUser;
END k_sp_del_user;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_group (IdGroup CHAR) IS
BEGIN
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=IdGroup;
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=IdGroup;
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=IdGroup;
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=IdGroup;
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=IdGroup;

  DELETE k_working_calendar WHERE gu_acl_group=IdGroup;
  DELETE k_x_group_company WHERE gu_acl_group=IdGroup;
  DELETE k_x_group_contact WHERE gu_acl_group=IdGroup;
  DELETE k_x_group_user WHERE gu_acl_group=IdGroup;
  DELETE k_x_cat_group_acl WHERE gu_acl_group=IdGroup;
  DELETE k_acl_groups WHERE gu_acl_group=IdGroup;
END k_sp_del_group;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_grp_perm (IdGroup CHAR, IdCategory CHAR, ACLMask OUT NUMBER) IS
  IdParent CHAR(32);
  BEGIN
    ACLMask:=NULL;
    SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdCategory AND gu_acl_group=IdGroup;
    ACLMask := NVL(ACLMask, 0);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdCategory AND ROWNUM=1;
        IF IdParent=IdCategory OR IdParent IS NULL THEN
	  ACLMask := 0;
	ELSE
	  k_sp_cat_grp_perm (IdGroup, IdParent, ACLMask);
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        ACLMask := 0;
      END;
END k_sp_cat_grp_perm;
GO;


CREATE OR REPLACE PROCEDURE k_sp_cat_usr_perm (IdUser CHAR, IdCategory CHAR, ACLMask OUT NUMBER) IS
  /* Devuelve los permisos que tiene un usuario para una categoría, teniendo en cuenta
     los grupos a los que pertenece y los permisos otorgados a las categorías padre si
     es que no hay asignación explícita de permisos al usuario para la categoría especificada */

  NoDataFound NUMBER(1);
  IdParent CHAR(32);
  IdChild CHAR(32);
  IdACLGroup CHAR(32);
  CURSOR groups (id CHAR) IS SELECT gu_acl_group FROM k_x_group_user WHERE gu_user=id;

BEGIN
  ACLMask:=NULL;
  IdChild:=IdCategory;

  LOOP
    NoDataFound := 0;
    BEGIN
      SELECT acl_mask INTO ACLMask FROM k_x_cat_user_acl WHERE gu_category=IdChild AND gu_user=IdUser;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        IdParent:=IdChild;
        BEGIN
          SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild AND ROWNUM=1;

          IF IdParent<>IdChild THEN
            IdChild:=IdParent;
            NoDataFound := 1;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NoDataFound := 0;
        END;
    END;
    EXIT WHEN NoDataFound<>1;
  END LOOP;

  IF ACLMask IS NULL THEN
    OPEN groups(IdUser);
      LOOP
        FETCH groups INTO IdACLGroup;
        EXIT WHEN groups%NOTFOUND;
        IdChild:=IdCategory;
        LOOP
          NoDataFound := 0;
          BEGIN
            SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdChild AND gu_acl_group=IdACLGroup;

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
              IdParent:=IdChild;
              BEGIN
                SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild AND ROWNUM=1;
                IF IdParent<>IdChild THEN
                  IdChild:=IdParent;
                  NoDataFound := 1;
                END IF;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              NoDataFound := 0;
            END;
          END;

          EXIT WHEN NoDataFound<>1;
        END LOOP;

      END LOOP;
    CLOSE groups;
  END IF;

  ACLMask := NVL(ACLMask, 0);

END k_sp_cat_usr_perm;
GO;


CREATE OR REPLACE PROCEDURE k_sp_cat_del_grp (IdCategory CHAR, IdGroup CHAR, Recurse NUMBER, Objects NUMBER) IS
  /* Borrar los permisos asignados a un grupo dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdGroup: Identificador unico del grupo
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */
BEGIN
  DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=IdGroup AND gu_category=IdCategory;
  IF Recurse<>0 THEN
    DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=IdGroup AND gu_category IN (SELECT gu_child_cat FROM k_cat_tree START WITH gu_parent_cat=IdCategory CONNECT BY gu_parent_cat=PRIOR gu_child_cat);
  END IF;
END k_sp_cat_del_grp;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_del_usr (IdCategory CHAR, IdUser CHAR, Recurse NUMBER, Objects NUMBER) IS
  /* Borrar los permisos asignados a un usuario dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdUser: Identificador unico del usuario k_users.gu_user
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */
BEGIN
  DELETE FROM k_x_cat_user_acl WHERE gu_category=IdCategory AND gu_user=IdUser;
  IF Recurse<>0 THEN
    DELETE FROM k_x_cat_user_acl WHERE gu_user=IdUser AND gu_category IN (SELECT gu_child_cat FROM k_cat_tree START WITH gu_parent_cat=IdCategory CONNECT BY gu_parent_cat=PRIOR gu_child_cat);
  END IF;
END  k_sp_cat_del_usr;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_set_grp (IdCategory CHAR, IdGroup CHAR, ACLMask NUMBER, Recurse NUMBER, Objects NUMBER) IS
  /* Establece los permisos asignados a un grupo dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdGroup: Identificador unico del grupo
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */

  PrevMask NUMBER(11,0);
  IdChild CHAR(32);

  CURSOR childs(id CHAR) IS SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=id;

BEGIN
  BEGIN
    SELECT acl_mask INTO PrevMask FROM k_x_cat_group_acl WHERE gu_category=IdCategory AND gu_acl_group=IdGroup;

    UPDATE k_x_cat_group_acl SET acl_mask = ACLMask WHERE gu_category=IdCategory AND gu_acl_group=IdGroup;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      IF IdCategory IS NOT NULL AND IdGroup IS NOT NULL THEN
        INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES (IdCategory, IdGroup, ACLMask);
      END IF;
  END;

  IF Recurse<>0 THEN
    OPEN childs(IdCategory);
      LOOP
        FETCH childs INTO IdChild;
        EXIT WHEN childs%NOTFOUND;
        k_sp_cat_set_grp (IdChild, IdGroup, ACLMask, Recurse, Objects);
      END LOOP;
    CLOSE childs;
  END IF;
END k_sp_cat_set_grp;
GO;

CREATE OR REPLACE PROCEDURE k_sp_cat_set_usr (IdCategory CHAR, IdUser CHAR, ACLMask NUMBER, Recurse NUMBER, Objects NUMBER) IS
  /* Establece los permisos asignados a un usuario dentro de una categoria
     Parametros:
     	IdCategory: Identificador numerico de la categoria k_categories.gu_category
     	IdUser: Identificador unico del usuario k_users.gu_user
     	Recurse: Indica si el cambio de permisos se debe propagar a las categorias hijas
     	Objects: Indica si el cambio de permisos se debe progagar a los objetos contenidos en la categoria
     		 este parametro no se usa actualmente
  */

  PrevMask NUMBER(11,0);
  IdChild CHAR(32);

  CURSOR childs(id CHAR) IS SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=id;

BEGIN
  BEGIN
    SELECT acl_mask INTO PrevMask FROM k_x_cat_user_acl WHERE gu_category=IdCategory AND gu_user=IdUser;

    UPDATE k_x_cat_user_acl SET acl_mask = ACLMask WHERE gu_category=IdCategory AND gu_user=IdUser;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      IF IdCategory IS NOT NULL AND IdUser IS NOT NULL THEN
        INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES (IdCategory, IdUser, ACLMask);
      END IF;
  END;

  IF Recurse<>0 THEN
    OPEN childs(IdCategory);
      LOOP
        FETCH childs INTO IdChild;
        EXIT WHEN childs%NOTFOUND;
        k_sp_cat_set_usr (IdChild, IdUser, ACLMask, Recurse, Objects);
      END LOOP;
    CLOSE childs;
  END IF;
END k_sp_cat_set_usr;
GO;

CREATE OR REPLACE PROCEDURE k_sp_get_user_mailroot (GuUser CHAR, GuCategory OUT CHAR) IS
  NmDomain   VARCHAR2(30);
  GuUserHome CHAR(32);
  TxNickName VARCHAR2(32);
  NmCategory VARCHAR2(100);
BEGIN

  SELECT u.gu_category,u.tx_nickname,d.nm_domain INTO GuUserHome,TxNickName,NmDomain FROM k_users u,k_domains d WHERE u.gu_user=GuUser AND d.id_domain=u.id_domain;

  BEGIN
    SELECT gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category=NmDomain||'_'||TxNickName||'_mail';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      SELECT gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category LIKE NmDomain||'_%_mail' AND ROWNUM=1 ORDER BY dt_created DESC;
  END;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    GuCategory:=NULL;
END k_sp_get_user_mailroot;
GO;

CREATE OR REPLACE PROCEDURE k_sp_get_user_mailfolder (GuUser CHAR, NmFolder VARCHAR2, GuCategory OUT CHAR) IS
  NmDomain   VARCHAR2(30);
  NickName   VARCHAR2(32);
  NmCategory VARCHAR2(100);
  GuMailRoot CHAR(32);
BEGIN

  SELECT u.tx_nickname,nm_domain INTO NickName,NmDomain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=GuUser;

  k_sp_get_user_mailroot (GuUser,GuMailRoot);

  IF GuMailRoot IS NULL THEN
    GuCategory:=NULL;
  ELSE
    SELECT c.gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuMailRoot AND (c.nm_category=NmDomain || '_' || NickName || '_' || NmFolder OR c.nm_category=NmFolder);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    GuCategory:=NULL;
END k_sp_get_user_mailfolder;
GO;