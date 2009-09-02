CREATE FUNCTION k_sp_get_cat_id (VARCHAR) RETURNS CHAR AS '
DECLARE
  IdCategory CHAR(32);
BEGIN
  SELECT gu_category INTO IdCategory FROM k_categories WHERE nm_category=$1;

  IF NOT FOUND THEN
    IdCategory := NULL;
  END IF;

  RETURN IdCategory;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_level (CHAR) RETURNS INTEGER AS '
DECLARE
  IdChild  CHAR(32);
  IdParent CHAR(32);
  CatLevel INTEGER;
BEGIN

  IdChild  := $1;
  IdParent := NULL;

  CatLevel := 0;

  LOOP
    EXIT WHEN CatLevel=-1;
    CatLevel := CatLevel + 1;
    SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 1;
    IF NOT FOUND THEN
      EXIT;
    ELSE
      IF IdParent=IdChild THEN
        CatLevel := -1;
      ELSE
        IdChild := IdParent;
      END IF;
    END IF;
  END LOOP;

  RETURN CatLevel;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_category (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_cat_expand WHERE gu_rootcat=$1;
  DELETE FROM k_cat_expand WHERE gu_parent_cat=$1;
  DELETE FROM k_cat_expand WHERE gu_category=$1;
  DELETE FROM k_cat_tree WHERE gu_child_cat=$1;
  DELETE FROM k_cat_root WHERE gu_category=$1;
  DELETE FROM k_cat_labels WHERE gu_category=$1;
  DELETE FROM k_x_cat_user_acl WHERE gu_category=$1;
  DELETE FROM k_x_cat_group_acl WHERE gu_category=$1;
  DELETE FROM k_x_cat_objs WHERE gu_category=$1;
  DELETE FROM k_categories WHERE gu_category=$1;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_category_r (CHAR) RETURNS INTEGER AS '
DECLARE
  childs k_cat_tree%ROWTYPE;
BEGIN
  FOR childs IN SELECT * FROM k_cat_tree WHERE gu_parent_cat=$1 LOOP
    PERFORM k_sp_del_category_r (childs.gu_child_cat);
  END LOOP;

  PERFORM k_sp_del_category ($1);

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_get_cat_path (CHAR) RETURNS VARCHAR AS '
DECLARE
  Neighbour CHAR(32);
  Neighname VARCHAR(100);
  DoNext SMALLINT;
  IdCategory CHAR(32);
  CatPath TEXT;
BEGIN
  CatPath := CHR(32);
  CatPath := trim(trailing from CatPath);
  IdCategory := $1;

  SELECT nm_category INTO CatPath FROM k_categories WHERE gu_category=$1;

  DoNext := 1;
  LOOP
    EXIT WHEN DoNext<>1;
    Neighbour := NULL;
    SELECT gu_parent_cat INTO Neighbour FROM k_cat_tree WHERE gu_child_cat=IdCategory LIMIT 1;
    IF NOT FOUND THEN
      DoNext := 0;
    ELSE
      IF IdCategory=Neighbour THEN
        DoNext := 0;
      ELSE
        SELECT nm_category INTO Neighname FROM k_categories WHERE gu_category=Neighbour;
	    CatPath := Neighname || CHR(47) || CatPath;
        IdCategory := Neighbour;
      END IF;
    END IF;
  END LOOP;

  RETURN CatPath;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_obj_position (CHAR, CHAR) RETURNS VARCHAR AS '
DECLARE
  Position INTEGER;
BEGIN
  SELECT od_position INTO Position FROM k_x_cat_objs WHERE gu_category=$2 AND gu_object=$1;
  IF NOT FOUND THEN
    RETURN NULL;
  ELSE
    RETURN Position;
  END IF;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_expand_node (CHAR, CHAR, INTEGER, INTEGER) RETURNS INTEGER AS '
DECLARE
  childs k_cat_tree%ROWTYPE;
  wlk INTEGER;
BEGIN

  wlk := $4;

  FOR childs IN SELECT * FROM k_cat_tree WHERE gu_parent_cat = $2 LOOP
    INSERT INTO k_cat_expand VALUES ($1, childs.gu_child_cat, $3, wlk, $2);
    wlk := wlk + 1;
    SELECT k_sp_cat_expand_node($1, childs.gu_child_cat, $3+1, wlk) INTO wlk;
  END LOOP;
  RETURN wlk;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_expand (CHAR) RETURNS INTEGER AS '
DECLARE
  childs k_cat_tree%ROWTYPE;
  wlk INTEGER;
BEGIN
  DELETE FROM k_cat_expand WHERE gu_rootcat = $1;

  wlk := 1;

  INSERT INTO k_cat_expand VALUES ($1, $1, 1, wlk, NULL);
  wlk := wlk + 1;

  FOR childs IN SELECT * FROM k_cat_tree WHERE gu_parent_cat = $1 LOOP
    INSERT INTO k_cat_expand VALUES ($1, childs.gu_child_cat, 2, wlk, $1);
    wlk := wlk + 1;
    SELECT k_sp_cat_expand_node($1, childs.gu_child_cat, 2, wlk) INTO wlk;
  END LOOP;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;


CREATE FUNCTION k_sp_del_user (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_x_group_user WHERE gu_user=$1;
  DELETE FROM k_x_cat_user_acl WHERE gu_user=$1;
  DELETE FROM k_users WHERE gu_user=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;


CREATE FUNCTION k_sp_del_group (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=$1;
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=$1;
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=$1;
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=$1;
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=$1;

  DELETE FROM k_working_calendar WHERE gu_acl_group=$1;
  DELETE FROM k_x_group_company WHERE gu_acl_group=$1;
  DELETE FROM k_x_group_contact WHERE gu_acl_group=$1;
  DELETE FROM k_x_group_user WHERE gu_acl_group=$1;
  DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=$1;
  DELETE FROM k_acl_groups WHERE gu_acl_group=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_grp_perm (CHAR, CHAR) RETURNS INTEGER AS '
DECLARE
  ACLMask INTEGER;
  IdParent CHAR(32);
BEGIN
  SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=$2 AND gu_acl_group=$1;
  IF NOT FOUND THEN
    SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=$2 LIMIT 1;
    IF NOT FOUND THEN
      ACLMask:=0;
    ELSIF IdParent=$2 OR IdParent IS NULL THEN
      ACLMask:=0;
    ELSE
      RETURN k_sp_cat_grp_perm($1,IdParent);
    END IF;
  END IF;
  IF ACLMask IS NULL THEN
    RETURN 0;
  ELSE
    RETURN ACLMask;
  END IF;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_usr_perm (CHAR, CHAR) RETURNS INTEGER AS '
  /* Devuelve los permisos que tiene un usuario para una categoría, teniendo en cuenta
     los grupos a los que pertenece y los permisos otorgados a las categorías padre si
     es que no hay asignación explícita de permisos al usuario para la categoría especificada */
DECLARE
  NoDataFound SMALLINT;
  IdParent CHAR(32);
  IdChild CHAR(32);
  IdACLGroup CHAR(32);
  ACLMask INTEGER;
  groups CURSOR (id CHAR(32)) FOR SELECT gu_acl_group FROM k_x_group_user WHERE gu_user=id;

BEGIN

  IdChild:=$2;

  LOOP
    NoDataFound := 0;

    SELECT acl_mask INTO ACLMask FROM k_x_cat_user_acl WHERE gu_category=IdChild AND gu_user=$1;

    IF NOT FOUND THEN
      ACLMask:=NULL;
      IdParent:=IdChild;

      SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 1;

      IF NOT FOUND THEN
          NoDataFound := 0;
      ELSE
        IF IdParent<>IdChild THEN
          IdChild:=IdParent;
          NoDataFound := 1;
        END IF;
      END IF;
    END IF;

    EXIT WHEN NoDataFound<>1;
  END LOOP;

  IF ACLMask IS NULL THEN
    OPEN groups($1);
      LOOP
        FETCH groups INTO IdACLGroup;
        EXIT WHEN NOT FOUND;

  	IdChild:=$2;

	LOOP
    	  NoDataFound := 0;

          SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdChild AND gu_acl_group=IdACLGroup;

    	  IF NOT FOUND THEN
    	    ACLMask:=NULL;
      	    IdParent:=IdChild;

      	    SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 1;

            IF NOT FOUND THEN
              NoDataFound := 0;
            ELSE
      	      IF IdParent<>IdChild THEN
	        IdChild:=IdParent;
	        NoDataFound := 1;
	      END IF;
            END IF;
          END IF;

          EXIT WHEN NoDataFound<>1;
        END LOOP;

      END LOOP;
    CLOSE groups;
  END IF;

  IF ACLMask IS NULL THEN
    RETURN 0;
  ELSE
    RETURN ACLMask;
  END IF;

END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_del_grp (CHAR, CHAR, SMALLINT, SMALLINT) RETURNS INTEGER AS '
DECLARE
  childs k_cat_tree%ROWTYPE;
BEGIN
  DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=$2 AND gu_category=$1;

  IF $3<>0 THEN

    FOR childs IN SELECT * FROM k_cat_tree WHERE gu_parent_cat=$1 LOOP
      PERFORM k_sp_cat_del_grp (childs.gu_child_cat, $2, $3, $4);
    END LOOP;

  END IF;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_del_usr (CHAR, CHAR, SMALLINT, SMALLINT) RETURNS INTEGER AS '
DECLARE
  childs k_cat_tree%ROWTYPE;
BEGIN
  DELETE FROM k_x_cat_user_acl WHERE gu_category=$1 AND gu_user=$2;

  IF $3<>0 THEN

    FOR childs IN SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=$1 LOOP
      PERFORM k_sp_cat_del_usr (childs.gu_child_cat, $2, $3, $4);
    END LOOP;

  END IF;

  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_set_grp (CHAR, CHAR, INTEGER, SMALLINT, SMALLINT) RETURNS INTEGER AS '
DECLARE
  mask INTEGER;
  childs k_cat_tree%ROWTYPE;
BEGIN
  SELECT acl_mask INTO mask FROM k_x_cat_group_acl WHERE gu_category=$1 AND gu_acl_group=$2;

  IF FOUND THEN
    UPDATE k_x_cat_group_acl SET acl_mask=$3 WHERE gu_category=$1 AND gu_acl_group=$2;
  ELSE
    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
      INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ($1, $2, $3);
    END IF;
  END IF;

  IF $4<>0 THEN

    FOR CHILDS IN SELECT * FROM k_cat_tree WHERE gu_parent_cat=$1 LOOP
      PERFORM k_sp_cat_set_grp (childs.gu_child_cat, $2, $3, $4, $5);
    END LOOP;

  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_cat_set_usr (CHAR, CHAR, INTEGER, SMALLINT, SMALLINT) RETURNS INTEGER AS '
DECLARE
  mask INTEGER;
  childs k_cat_tree%ROWTYPE;
BEGIN
  SELECT acl_mask INTO mask FROM k_x_cat_user_acl WHERE gu_category=$1 AND gu_user=$2;

  IF FOUND THEN
    UPDATE k_x_cat_user_acl SET acl_mask=$3 WHERE gu_category=$1 AND gu_user=$2;
  ELSE
    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
      INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ($1, $2, $3);
    END IF;
  END IF;

  IF $4<>0 THEN

    FOR childs IN SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=$1 LOOP
      PERFORM k_sp_cat_set_usr (childs.gu_child_cat, $2, $3, $4, $5);
    END LOOP;

  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_get_user_mailroot (CHAR) RETURNS CHAR AS '
DECLARE
  NmDomain   VARCHAR(30);
  TxNickName VARCHAR(32);
  GuUserHome CHAR(32);
  GuMailRoot CHAR(32);
BEGIN
  SELECT u.gu_category,u.tx_nickname,d.nm_domain INTO GuUserHome,TxNickName,NmDomain FROM k_users u,k_domains d WHERE u.gu_user=$1 AND d.id_domain=u.id_domain;

  IF NOT FOUND THEN
    GuMailRoot := NULL;
  ELSE
    SELECT gu_category INTO GuMailRoot FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category=NmDomain||CHR(95)||TxNickName||''_mail'';
    IF NOT FOUND THEN
      SELECT gu_category INTO GuMailRoot FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category LIKE NmDomain||''_%_mail'' ORDER BY dt_created DESC LIMIT 1;
      IF NOT FOUND THEN
        GuMailRoot := NULL;
      END IF;
    END IF;
  END IF;

  RETURN GuMailRoot;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_get_user_mailfolder (CHAR,VARCHAR) RETURNS CHAR AS '
DECLARE
  NmDomain   VARCHAR(30);
  TxNickName VARCHAR(32);
  GuMailRoot CHAR(32);
  GuMailBox  CHAR(32);
BEGIN
  SELECT u.tx_nickname,d.nm_domain INTO TxNickName,NmDomain FROM k_users u,k_domains d WHERE u.gu_user=$1 AND d.id_domain=u.id_domain;

  SELECT k_sp_get_user_mailroot($1) INTO GuMailRoot;

  SELECT gu_category INTO GuMailBox FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuMailRoot AND (nm_category=NmDomain||CHR(95)||TxNickName||CHR(95)||$2 OR nm_category=$2);
  IF NOT FOUND THEN
    SELECT gu_category INTO GuMailRoot FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuMailRoot AND nm_category LIKE NmDomain||''_%_inbox'' ORDER BY dt_created DESC LIMIT 1;
    IF NOT FOUND THEN
      GuMailBox := NULL;
    END IF;
  END IF;

  RETURN GuMailBox;
END;
' LANGUAGE 'plpgsql';
GO;
