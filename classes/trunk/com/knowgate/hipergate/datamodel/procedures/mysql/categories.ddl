CREATE PROCEDURE k_sp_get_cat_id (NmCategory VARCHAR(100), OUT IdCategory CHAR(32))
BEGIN
  SET IdCategory=NULL;
  SELECT gu_category INTO IdCategory FROM k_categories WHERE nm_category=NmCategory;
END
GO;

CREATE PROCEDURE k_sp_cat_level (IdCategory CHAR(32), OUT CatLevel INT)
BEGIN
  DECLARE IdParent CHAR(32) DEFAULT NULL;
  DECLARE IdChild  CHAR(32);

  SET IdChild=IdCategory;
  SET CatLevel=0;

  WalkChilds: WHILE CatLevel<>-1 DO
    SET CatLevel=CatLevel+1;
    SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 0,1;
    IF IdParent IS NULL THEN
      LEAVE WalkChilds;
    ELSE
      IF IdParent=IdChild THEN
        SET CatLevel=-1;
      ELSE
        SET IdChild=IdParent;
      END IF;
    END IF;
  END WHILE WalkChilds;
END
GO;

CREATE PROCEDURE k_sp_del_category (IdCategory CHAR(32))
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
END
GO;

CREATE PROCEDURE k_sp_list_all_cat_childs (IdCategory CHAR(32))
BEGIN
  DECLARE StackBot INTEGER;
  DECLARE StackTop INTEGER;

  CREATE TEMPORARY TABLE tmp_del_cat_slice (gu_cat CHAR(32) NOT NULL) ENGINE = MEMORY;

  SET StackBot = 1;
  SET StackTop = 1;
  INSERT INTO tmp_del_cat_stack (gu_cat) VALUES (IdCategory);

  REPEAT
    INSERT INTO tmp_del_cat_slice (gu_cat) SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat IN (SELECT gu_cat FROM tmp_del_cat_stack WHERE nu_pos BETWEEN StackBot AND StackTop);
    INSERT INTO tmp_del_cat_stack (gu_cat) SELECT gu_cat FROM tmp_del_cat_slice;
    DELETE FROM tmp_del_cat_slice;
    SET StackBot = StackTop+1;
    SELECT MAX(nu_pos) INTO StackTop FROM tmp_del_cat_stack;
    UNTIL StackTop<StackBot
  END REPEAT;

  DROP TEMPORARY TABLE tmp_del_cat_slice;
END
GO;

CREATE PROCEDURE k_sp_del_category_r (IdCategory CHAR(32))
BEGIN
  DECLARE ChldId CHAR(32);
  DECLARE Done INT;
  DECLARE childs CURSOR FOR SELECT gu_cat FROM tmp_del_cat_stack ORDER BY nu_pos DESC;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

  CREATE TEMPORARY TABLE tmp_del_cat_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_cat CHAR(32) NOT NULL) TYPE MYISAM;

  CALL k_sp_list_all_cat_childs (IdCategory);

  SET Done = 0;
  OPEN childs;
    REPEAT
      FETCH childs INTO ChldId;
      IF Done=0 THEN
        CALL k_sp_del_category (ChldId);
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE childs;

  DROP TEMPORARY TABLE tmp_del_cat_stack;
END
GO;

CREATE PROCEDURE k_sp_get_cat_path (CatId CHAR(32), OUT CatPath  VARCHAR(2000))
BEGIN
  DECLARE Neighbour CHAR(32);
  DECLARE Neighname VARCHAR(30);
  DECLARE IdCategory CHAR(32);
  DECLARE DoNext SMALLINT DEFAULT 0;

  SET IdCategory=CatId;

  SELECT nm_category INTO CatPath FROM k_categories WHERE gu_category=IdCategory;

  WalkChilds: WHILE DoNext=1 DO
    SET Neighbour=NULL;
    SELECT gu_parent_cat INTO Neighbour FROM k_cat_tree WHERE gu_child_cat=IdCategory;
    IF Neighbour IS NULL THEN
      LEAVE WalkChilds;
    ELSE
      IF DoNext = 1 THEN
        IF IdCategory=Neighbour THEN
          SET DoNext=0;
        ELSE
          SELECT nm_category INTO Neighname FROM k_categories WHERE gu_category=Neighbour;
	  SET CatPath = CONCAT(Neighname,'/',CatPath);
          SET IdCategory=Neighbour;
        END IF;
      END IF;
    END IF;
  END WHILE WalkChilds;
END
GO;

CREATE PROCEDURE k_sp_cat_obj_position (IdObj CHAR(32), IdCategory CHAR(32), OUT Position INT)
BEGIN
  SET Position=NULL;
  SELECT od_position INTO Position FROM k_x_cat_objs WHERE gu_category=IdCategory AND gu_object=IdObj;
END
GO;

CREATE PROCEDURE k_sp_cat_expand (Cat CHAR(32))
BEGIN
  DECLARE Walk  INT;
  DECLARE Level INT;
  DECLARE Depth INT;
  DECLARE Unwalked INT;
  DECLARE GuPrnt CHAR(32);
  DECLARE GuChld CHAR(32);
  DECLARE NmChld VARCHAR(50);
  DECLARE CurName VARCHAR(254) DEFAULT NULL;
  DECLARE StackBot INTEGER;
  DECLARE StackTop INTEGER;
  DECLARE Done INT DEFAULT 0;
  DECLARE childs CURSOR FOR SELECT gu_cat,od_lvl,od_wlk,gu_par FROM tmp_exp_cat_stack ORDER BY od_wlk;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

  DELETE FROM k_cat_expand WHERE gu_rootcat = Cat;

  SELECT nm_category INTO CurName FROM k_categories WHERE gu_category=Cat;

  IF CurName IS NOT NULL THEN

    CREATE TEMPORARY TABLE tmp_exp_cat_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_rot CHAR(32) NOT NULL, gu_cat CHAR(32) NOT NULL, od_lvl INTEGER NOT NULL, gu_par CHAR(32) NULL, od_wlk INTEGER NULL) TYPE MYISAM;
    CREATE TEMPORARY TABLE tmp_exp_cat_slice (gu_cat CHAR(32) NOT NULL, gu_par CHAR(32) NOT NULL) ENGINE = MEMORY;

    INSERT INTO tmp_exp_cat_stack (gu_rot,gu_cat,od_lvl,gu_par,od_wlk) VALUES (Cat, Cat, 1, NULL, 1);
    SET Level = 2;
    SET StackBot = 1;
    SET StackTop = 1;

    REPEAT
      INSERT INTO tmp_exp_cat_slice (gu_cat,gu_par) SELECT gu_child_cat,gu_parent_cat FROM k_cat_tree WHERE gu_parent_cat IN (SELECT gu_cat FROM tmp_exp_cat_stack WHERE nu_pos BETWEEN StackBot AND StackTop);
      INSERT INTO tmp_exp_cat_stack (gu_rot,gu_cat,od_lvl,gu_par,od_wlk) SELECT Cat,gu_cat,Level,gu_par,NULL FROM tmp_exp_cat_slice;
      DELETE FROM tmp_exp_cat_slice;
      SET StackBot = StackTop+1;
      SET Level = Level+1;
      SELECT MAX(nu_pos) INTO StackTop FROM tmp_exp_cat_stack;
    UNTIL StackTop<StackBot END REPEAT;

    SET Walk = 2;
    SET Level = 2;
    SET GuPrnt = Cat;
    SELECT COUNT(*) INTO Unwalked FROM tmp_exp_cat_stack WHERE od_wlk IS NULL;
    SELECT MAX(od_lvl) INTO Depth FROM tmp_exp_cat_stack;
    WHILE Unwalked>0 AND Level>1 DO
      SET GuChld=NULL;
      SELECT gu_cat INTO GuChld FROM tmp_exp_cat_stack WHERE od_wlk IS NULL AND gu_par=GuPrnt ORDER BY nu_pos LIMIT 0,1;
      IF GuChld IS NULL THEN
        SET Level = Level-1;
        SELECT gu_parent_cat INTO GuPrnt FROM k_cat_tree WHERE gu_child_cat=GuPrnt;
      ELSE
        UPDATE tmp_exp_cat_stack SET od_wlk=Walk WHERE gu_cat=GuChld;
        SET Walk = Walk+1;
        SET Level = Level+1;
        SET GuPrnt = GuChld;
      END IF;
      SELECT COUNT(*) INTO Unwalked FROM tmp_exp_cat_stack WHERE od_wlk IS NULL;
    END WHILE;

    SET Done=0;
    OPEN childs;
    REPEAT
      FETCH childs INTO GuChld,Level,Walk,GuPrnt;
      IF Done=0 THEN
        INSERT INTO k_cat_expand (gu_rootcat,gu_category,od_level,od_walk,gu_parent_cat) VALUES (Cat, GuChld, Level, Walk, GuPrnt);
      END IF;
    UNTIL Done=1 END REPEAT;
    CLOSE childs;
  END IF;

  DROP TEMPORARY TABLE tmp_exp_cat_slice;
  DROP TEMPORARY TABLE tmp_exp_cat_stack;
END
GO;

CREATE PROCEDURE k_sp_del_user (IdUser CHAR(32))
BEGIN
  DELETE FROM k_x_group_user WHERE gu_user=IdUser;
  DELETE FROM k_x_cat_user_acl WHERE gu_user=IdUser;
  DELETE FROM k_users WHERE gu_user=IdUser;
END
GO;

CREATE PROCEDURE k_sp_del_group (IdGroup CHAR(32))
BEGIN
  UPDATE k_x_app_workarea SET gu_admins=NULL WHERE gu_admins=IdGroup;
  UPDATE k_x_app_workarea SET gu_powusers=NULL WHERE gu_powusers=IdGroup;
  UPDATE k_x_app_workarea SET gu_users=NULL WHERE gu_users=IdGroup;
  UPDATE k_x_app_workarea SET gu_guests=NULL WHERE gu_guests=IdGroup;
  UPDATE k_x_app_workarea SET gu_other=NULL WHERE gu_other=IdGroup;

  DELETE FROM k_working_calendar WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_group_company WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_group_contact WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_group_user WHERE gu_acl_group=IdGroup;
  DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=IdGroup;
  DELETE FROM k_acl_groups WHERE gu_acl_group=IdGroup;
END
GO;

CREATE PROCEDURE k_sp_cat_grp_perm (IdGroup CHAR(32), IdCategory CHAR(32), OUT ACLMask INT)
BEGIN
  DECLARE IdParent CHAR(32) DEFAULT NULL;
  SET ACLMask=NULL;
bottom_up: LOOP
    SELECT IFNULL(acl_mask,0) INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdCategory AND gu_acl_group=IdGroup;
    IF ACLMask IS NULL THEN
      SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdCategory LIMIT 0,1;
      IF IdParent=IdCategory OR IdParent IS NULL THEN
        SET ACLMask=0;
        LEAVE bottom_up;
      ELSE
        SET IdCategory=IdParent;
      END IF;
    ELSE
      LEAVE bottom_up;
    END IF;
  END LOOP bottom_up;
END
GO;

CREATE PROCEDURE k_sp_cat_usr_perm (IdUser CHAR(32), IdCategory CHAR(32), OUT ACLMask INT)
BEGIN
  DECLARE NoDataFound SMALLINT;
  DECLARE IdParent CHAR(32);
  DECLARE IdChild CHAR(32);
  DECLARE IdACLGroup CHAR(32);
  DECLARE Done INT DEFAULT 0;
  DECLARE groups CURSOR FOR SELECT gu_acl_group FROM k_x_group_user WHERE gu_user=IdUser;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

  SET IdChild=IdCategory;

  REPEAT
    SET NoDataFound=0;
    SET ACLMask=NULL;
    SELECT acl_mask INTO ACLMask FROM k_x_cat_user_acl WHERE gu_category=IdChild AND gu_user=IdUser;

    IF ACLMask IS NULL THEN
      SET IdParent=IdChild;
      SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 0,1;
      IF IdParent=IdChild OR IdParent IS NULL THEN
        SET NoDataFound=0;
      ELSE
        IF IdParent<>IdChild THEN
          SET IdChild=IdParent;
          SET NoDataFound=1;
        END IF;
      END IF;
    END IF;
  UNTIL NoDataFound<>1 END REPEAT;

  IF ACLMask IS NULL THEN
    SET Done=0;
    OPEN groups;
      REPEAT
        FETCH groups INTO IdACLGroup;
        IF Done = 0 THEN
          SET IdChild=IdCategory;
          REPEAT
            SET NoDataFound=0;
            SELECT acl_mask INTO ACLMask FROM k_x_cat_group_acl WHERE gu_category=IdChild AND gu_acl_group=IdACLGroup;
            IF ACLMask IS NULL THEN
              SET ACLMask=NULL;
              SET IdParent=IdChild;
              SELECT gu_parent_cat INTO IdParent FROM k_cat_tree WHERE gu_child_cat=IdChild LIMIT 0,1;
              IF IdParent=IdChild OR IdParent IS NULL THEN
                SET NoDataFound=0;
              ELSE
      	        IF IdParent<>IdChild THEN
	          SET IdChild=IdParent;
	          SET NoDataFound=1;
	        END IF;
              END IF;
            END IF;
	  UNTIL NoDataFound<>1 END REPEAT;
        END IF;
      UNTIL Done=1 END REPEAT;
    CLOSE groups;
  END IF;

  IF ACLMask IS NULL THEN
    SET ACLMask=0;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_cat_del_grp (IdCategory CHAR(32), IdGroup CHAR(32), Recurse SMALLINT, Objects SMALLINT)
BEGIN
  DECLARE IdChld CHAR(32);
  DECLARE Done INT;
  DECLARE childs CURSOR FOR SELECT gu_cat FROM tmp_del_cat_stack ORDER BY nu_pos DESC;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

  IF Recurse=0 THEN
    DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=IdGroup AND gu_category=IdCategory;
  ELSE
    CREATE TEMPORARY TABLE tmp_del_cat_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_cat CHAR(32) NOT NULL) TYPE MYISAM;

    CALL k_sp_list_all_cat_childs (IdCategory);

    SET Done = 0;
    OPEN childs;
      REPEAT
        FETCH childs INTO IdChld;
        IF Done=0 THEN
          DELETE FROM k_x_cat_group_acl WHERE gu_acl_group=IdGroup AND gu_category=IdChld;
        END IF;
      UNTIL Done=1 END REPEAT;
    CLOSE childs;

    DROP TEMPORARY TABLE tmp_del_cat_stack;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_cat_del_usr (IdCategory CHAR(32), IdUser CHAR(32), Recurse SMALLINT, Objects SMALLINT)
BEGIN
  DECLARE IdChld CHAR(32);
  DECLARE Done INT;
  DECLARE childs CURSOR FOR SELECT gu_cat FROM tmp_del_cat_stack ORDER BY nu_pos DESC;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

  IF Recurse=0 THEN
    DELETE FROM k_x_cat_user_acl WHERE gu_category=IdCategory AND gu_user=IdUser;
  ELSE
    CREATE TEMPORARY TABLE tmp_del_cat_stack (nu_pos INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, gu_cat CHAR(32) NOT NULL) TYPE MYISAM;
    CALL k_sp_list_all_cat_childs (IdCategory);
    SET Done = 0;
    OPEN childs;
      REPEAT
        FETCH childs INTO IdChld;
        IF Done=0 THEN
    	  DELETE FROM k_x_cat_user_acl WHERE gu_category=IdChld AND gu_user=IdUser;
        END IF;
      UNTIL Done=1 END REPEAT;
    CLOSE childs;
    DROP TEMPORARY TABLE tmp_del_cat_stack;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_cat_set_grp (IdCategory CHAR(32), IdGroup CHAR(32), ACLMask INT, Recurse SMALLINT, Objects SMALLINT)
BEGIN
  DECLARE PrevMask INT DEFAULT NULL;
  DECLARE IdChild CHAR(32);
  DECLARE Done INT DEFAULT 0;
  DECLARE childs CURSOR FOR SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=IdCategory;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  SELECT acl_mask INTO PrevMask FROM k_x_cat_group_acl WHERE gu_category=IdCategory AND gu_acl_group=IdGroup;

  IF PrevMask IS NULL THEN
    IF IdCategory IS NOT NULL AND IdGroup IS NOT NULL THEN
      INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES (IdCategory, IdGroup, ACLMask);
    END IF;
  ELSE
    UPDATE k_x_cat_group_acl SET acl_mask = ACLMask WHERE gu_category=IdCategory AND gu_acl_group=IdGroup;
  END IF;

  IF Recurse<>0 THEN
    OPEN childs;
      REPEAT
        FETCH childs INTO IdChild;
        IF Done=0 THEN
          CALL k_sp_cat_set_grp (IdChild, IdGroup, ACLMask, Recurse, Objects);
        END IF;
      UNTIL Done=1 END REPEAT;
    CLOSE childs;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_cat_set_usr (IdCategory CHAR(32), IdUser CHAR(32), ACLMask INT, Recurse SMALLINT, Objects SMALLINT)
BEGIN
  DECLARE PrevMask INT DEFAULT NULL;
  DECLARE IdChild CHAR(32);
  DECLARE Done INT DEFAULT 0;
  DECLARE childs CURSOR FOR SELECT gu_child_cat FROM k_cat_tree WHERE gu_parent_cat=IdCategory;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  SELECT acl_mask INTO PrevMask FROM k_x_cat_user_acl WHERE gu_category=IdCategory AND gu_user=IdUser;
  IF PrevMask IS NULL THEN
    IF IdCategory IS NOT NULL AND IdUser IS NOT NULL THEN
      INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES (IdCategory, IdUser, ACLMask);
    END IF;
  ELSE
    UPDATE k_x_cat_user_acl SET acl_mask = ACLMask WHERE gu_category=IdCategory AND gu_user=IdUser;
  END IF;

  IF Recurse<>0 THEN
    OPEN childs;
      REPEAT
        FETCH childs INTO IdChild;
        IF Done=0 THEN
          CALL k_sp_cat_set_usr (IdChild, IdUser, ACLMask, Recurse, Objects);
        END IF;
      UNTIL Done=1 END REPEAT;
    CLOSE childs;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_get_user_mailroot (GuUser CHAR(32), OUT GuCategory CHAR(32))
BEGIN
  DECLARE NmDomain VARCHAR(30);
  DECLARE GuUserHome CHAR(32);
  DECLARE TxNickName VARCHAR(32);
  DECLARE NmCategory VARCHAR(100);

  SELECT u.gu_category,u.tx_nickname,d.nm_domain INTO GuUserHome,TxNickName,NmDomain FROM k_users u,k_domains d WHERE u.gu_user=GuUser AND d.id_domain=u.id_domain;

  SET GuCategory=NULL;
  SELECT gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category=CONCAT(NmDomain,'_',TxNickName,'_mail');
  IF GuCategory IS NULL THEN
    SELECT gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuUserHome AND nm_category LIKE CONCAT(NmDomain,'_%_mail') ORDER BY dt_created DESC LIMIT 0,1;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_get_user_mailfolder (GuUser CHAR(32), NmFolder VARCHAR(100), OUT GuCategory CHAR(32))
BEGIN
  DECLARE NmDomain   VARCHAR(30) DEFAULT NULL;
  DECLARE NickName   VARCHAR(32) DEFAULT NULL;
  DECLARE NmCategory VARCHAR(100);
  DECLARE GuMailRoot CHAR(32);

  SET GuCategory=NULL;
  SELECT u.tx_nickname,nm_domain INTO NickName,NmDomain FROM k_domains d, k_users u WHERE d.id_domain=u.id_domain AND u.gu_user=GuUser;

  IF NmDomain IS NOT NULL THEN
    CALL k_sp_get_user_mailroot (GuUser,GuMailRoot);
    IF GuMailRoot IS NULL THEN
      SET GuCategory=NULL;
    ELSE
      SELECT c.gu_category INTO GuCategory FROM k_categories c, k_cat_tree t WHERE c.gu_category=t.gu_child_cat AND t.gu_parent_cat=GuMailRoot AND (c.nm_category=CONCAT(NmDomain,'_',NickName,'_',NmFolder) OR c.nm_category=NmFolder);
    END IF;
  END IF;
END
GO;
