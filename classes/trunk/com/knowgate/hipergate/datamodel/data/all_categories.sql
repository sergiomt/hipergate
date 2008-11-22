/* When adding translations to this file, also update vdisk/usernew_store.jsp */

/* ROOT */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,nm_icon2,id_doc_status) VALUES ('0cd535569eae4fb4b2a3487c1454edc4','bab84ab397564299b068693187464b4f','ROOT'   ,1,'root_16x16.gif'   ,'root_16x16.gif'   ,1);

INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','es','Raiz');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) 
VALUES('0cd535569eae4fb4b2a3487c1454edc4','en','Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','fr','Racine');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','de','Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','it','Radice');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','pt','#pt#Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','ca','#ca#Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','eu','#eu#Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','ja','#ja#Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','cn','#zh#Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','tw','#zh#Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','fi','#fi#Root');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('0cd535569eae4fb4b2a3487c1454edc4','ru','Корень');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('0cd535569eae4fb4b2a3487c1454edc4', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('0cd535569eae4fb4b2a3487c1454edc4', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_root (gu_category) VALUES ('0cd535569eae4fb4b2a3487c1454edc4');

/* --------------------------------------------------------------------------- */

/* DOMAINS */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,nm_icon2,id_doc_status) VALUES ('c0a801c9eee719f272100000ebc9b3ff','bab84ab397564299b068693187464b4f','DOMAINS',1,'domains_16x16.gif','domains_16x16.gif',1);

INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','es','Dominios');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','en','Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','fr','Domaine');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','de','Domaene');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','it','Domini');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','pt','#pt#Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','ca','#ca#Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','eu','#eu#Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','ja','#ja#Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','cn','#zh#Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','tw','#zh#Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','fi','#fi#Domains');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee719f272100000ebc9b3ff','ru','Домены');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES('c0a801c9eee719f272100000ebc9b3ff', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a801c9eee719f272100000ebc9b3ff', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('0cd535569eae4fb4b2a3487c1454edc4', 'c0a801c9eee719f272100000ebc9b3ff');

/* --------------------------------------------------------------------------- */

/* SYSTEM DOMAIN */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a801c9eee72a4eec1000008dd849e5','bab84ab397564299b068693187464b4f','SYSTEM',1,'domain_16x16.gif',1,'domain_16x16.gif');

INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','es','System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','en','System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','de','System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','fr','Système');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','it','Sistema');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','pt','#pt#System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','ca','#ca#System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','eu','#eu#System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','ja','#ja#System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','cn','#zh#System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','tw','#zh#System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','fi','#fi#System');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a801c9eee72a4eec1000008dd849e5','ru','Система');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a801c9eee72a4eec1000008dd849e5', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a801c9eee72a4eec1000008dd849e5', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('c0a801c9eee719f272100000ebc9b3ff', 'c0a801c9eee72a4eec1000008dd849e5');

/* SYSTEM USERS */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('09d97bbb943c407c9ba8549bc8e4ec47','bab84ab397564299b068693187464b4f','SYSTEM_USERS',1,NULL,'folderusers_16x16.gif',1,'folderusers_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','es','Usuarios del Sistema');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','en','System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','fr','Utilisateur Système');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','de','Systembenutzer');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','it','Utenti del Sistema');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','pt','#pt#System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','ca','#ca#System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','eu','#eu#System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','ja','#ja#System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','cn','#zh#System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','tw','#zh#System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','fi','#fi#System Users');
INSERT INTO k_cat_labels (gu_category,id_language,tr_category) VALUES('09d97bbb943c407c9ba8549bc8e4ec47','ru','Системные Пользователи');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('09d97bbb943c407c9ba8549bc8e4ec47', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('09d97bbb943c407c9ba8549bc8e4ec47', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('c0a801c9eee72a4eec1000008dd849e5', '09d97bbb943c407c9ba8549bc8e4ec47');

/* SYSTEM USERS (Administrator) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('dd8263f0b83448658e84779e09bf7701','bab84ab397564299b068693187464b4f','SYSTEM_administrator',1,'mydesktopc_16x16.gif',1,'mydesktopc_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','en','Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','es','Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','fr','Administrateur',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','de','Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','it','Amministratore',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','pt','#pt#Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','ca','#ca#Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','eu','#eu#Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','ja','#ja#Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','cn','#zh#Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','tw','#zh#Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','fi','#fi#Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dd8263f0b83448658e84779e09bf7701','ru','Администратор',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('dd8263f0b83448658e84779e09bf7701','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('dd8263f0b83448658e84779e09bf7701','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('09d97bbb943c407c9ba8549bc8e4ec47', 'dd8263f0b83448658e84779e09bf7701');

/* SYSTEM USERS (Administrator Directories) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146e5967c8b45100000d9ba0790','bab84ab397564299b068693187464b4f','SYSTEM_administrator_temp',1,NULL,'foldertempc_16x16.gif',1,'foldertempo_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','en','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','es','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','fr','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','de','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','it','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','pt','#pt#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','ca','#ca#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','eu','#eu#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','ja','#ja#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','cn','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','tw','#tw#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','fi','#fi#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5967c8b45100000d9ba0790','ru','Временный',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146e5967c8b45100000d9ba0790','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146e5967c8b45100000d9ba0790','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dd8263f0b83448658e84779e09bf7701','c0a80146e5967c8b45100000d9ba0790');

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146e5968b1d58100002b448cad3','bab84ab397564299b068693187464b4f','SYSTEM_administrator_favs',1,NULL,'folderfavsc_16x16.gif',1,'folderfavso_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','en','Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','es','Favoritos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','fr','Favoris',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','de','Favoriten',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','it','Preferiti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','pt','#pt#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','ca','#ca#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','eu','#eu#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','ja','#ja#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','cn','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','tw','#tw#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','fi','#fi#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146e5968b1d58100002b448cad3','ru','Избранное',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146e5968b1d58100002b448cad3','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146e5968b1d58100002b448cad3','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dd8263f0b83448658e84779e09bf7701','c0a80146e5968b1d58100002b448cad3');

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('d4396a450fcf42db8be489efdff2047c','bab84ab397564299b068693187464b4f','SYSTEM_administrator_mail',1,NULL,'myemailc_16x16.gif',1,'myemailo_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','en','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','es','Correo',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','fr','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','de','E-Mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','it','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','pt','#pt#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','ca','#ca#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','eu','#eu#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','ja','#ja#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','cn','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','tw','#tw#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','fi','#fi#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d4396a450fcf42db8be489efdff2047c','ru','Электронная Почта',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d4396a450fcf42db8be489efdff2047c','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('d4396a450fcf42db8be489efdff2047c','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dd8263f0b83448658e84779e09bf7701','d4396a450fcf42db8be489efdff2047c');

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('e5406a450fcf42cc8be489efdff2048d','bab84ab397564299b068693187464b4f','SYSTEM_administrator_inbox',1,NULL,'mailbox_16x16.gif',1,'mailbox_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','en','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','es','Bandeja de Entrada',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','fr','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','de','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','it','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','pt','#pt#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','ca','#ca#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','eu','#eu#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','ja','#ja#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','cn','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','tw','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','fi','#fi#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e5406a450fcf42cc8be489efdff2048d','ru','#ru#Inbox',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e5406a450fcf42cc8be489efdff2048d','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e5406a450fcf42cc8be489efdff2048d','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('d4396a450fcf42db8be489efdff2047c','e5406a450fcf42cc8be489efdff2048d');

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','bab84ab397564299b068693187464b4f','SYSTEM_administrator_recycled',1,NULL,'recycledfull_16x16.gif',1,'recycledfull_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','en','Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','es','Eliminados',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','fr','Effacé',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','de','Geloescht',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','it','Cancellati',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','pt','#pt#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','ca','#ca#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','eu','#eu#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','ja','#ja#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','cn','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','tw','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','fi','#fi#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','ru','Удалённый',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e70af064f9144ab89d30a2afcd2bb15f','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dd8263f0b83448658e84779e09bf7701','e70af064f9144ab89d30a2afcd2bb15f');


/* SYSTEM WORKAREAS */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c1a81146f4b6e7ba95135002e03557ab','bab84ab397564299b068693187464b4f','SYSTEM_WORKAREAS',1,'filecab_16x16.gif',1,'filecab_16x16.gif');

INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','es','Areas de Trabajo');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','en','WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','fr','Espace de Travail');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','de','Arbeitsflaeche');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','it','Aree di Lavoro');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','pt','#pt#WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','ca','#ca#WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','eu','#eu#WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','ja','#ja#WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','cn','#zh#WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','tw','#zh#WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','fi','#fi#WorkAreas');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c1a81146f4b6e7ba95135002e03557ab','ru','РабочиеЗоны');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c1a81146f4b6e7ba95135002e03557ab', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c1a81146f4b6e7ba95135002e03557ab', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('c0a801c9eee72a4eec1000008dd849e5', 'c1a81146f4b6e7ba95135002e03557ab');


INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c2a91146f4b6e7ba95136003e03557ac','bab84ab397564299b068693187464b4f','SYSTEM_WORKAREAS_default',1,'folderclosed_16x16.gif.gif',1,'folderopen_16x16.gif.gif');

INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','es','Predeterminada');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','en','Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','fr','Defaut');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','de','Standardeinstellung');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','it','Predefinita');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','pt','#pt#Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','ca','#ca#Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','eu','#eu#Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','ja','#ja#Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','cn','#zh#Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','tw','#zh#Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','fi','#fi#Default');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c2a91146f4b6e7ba95136003e03557ac','ru','Установка');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c2a91146f4b6e7ba95136003e03557ac', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c2a91146f4b6e7ba95136003e03557ac', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('c1a81146f4b6e7ba95135002e03557ab', 'c2a91146f4b6e7ba95136003e03557ac');


/* SYSTEM APPS */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4b6e7ba95100001e03446fd','bab84ab397564299b068693187464b4f','SYSTEM_APPS',1,NULL,'appsclosed_16x16.gif',1,'appsopen_16x16.gif');

INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','es','Aplicaciones del Sistema');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','en','System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','fr','Applications Systèmes');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','de','Systemanwendungen');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','it','Applicazioni del Sistema');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','pt','#pt#System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','ca','#ca#System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','eu','#eu#System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','ja','#ja#System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','cn','#zh#System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','tw','#zh#System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','fi','#fi#System Applications');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('c0a80146f4b6e7ba95100001e03446fd','ru','Применения Системы');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4b6e7ba95100001e03446fd', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4b6e7ba95100001e03446fd', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('c0a801c9eee72a4eec1000008dd849e5', 'c0a80146f4b6e7ba95100001e03446fd');

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4b6edd276100004c4f32fc9','bab84ab397564299b068693187464b4f','SYSTEM_apps_sales',1,'rolodex16x16.gif',1,'rolodex16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c1b814c9eae71a4eec1001118dd849d4','bab84ab397564299b068693187464b4f','SYSTEM_apps_forums',1,'forums_16x16.gif',1,'forums_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c2b814c9eae71a4eec1001118dd849d5','bab84ab397564299b068693187464b4f','SYSTEM_apps_shop',1,'shop16x20.gif',1,'shop16x20.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c3b814c9eae71a4eec1001118dd849d6','bab84ab397564299b068693187464b4f','SYSTEM_apps_webbuilder',1,'folderpagesets_16x16.gif',1,'folderpagesets_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','en','CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','es','Gestion de Contactos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','fr','CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','de','CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','it','Gestione dei Contatti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','pt','#pt#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','ca','#ca#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','eu','#eu#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','ja','#ja#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','cn','#zh#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','tw','#zh#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','fi','#fi#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6edd276100004c4f32fc9','ru','Система Контактов',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','en','Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','es','Foros',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','fr','Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','de','Forum',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','it','Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','pt','#pt#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','ca','#ca#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','eu','#eu#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','ja','#ja#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','cn','#zh#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','tw','#zh#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','fi','#fi#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c1b814c9eae71a4eec1001118dd849d4','ru','Форумы',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','en','Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','es','Tienda',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','fr','Magasin',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','de','Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','it','Negozio',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','pt','#pt#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','ca','#ca#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','eu','#eu#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','ja','#ja#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','cn','#zh#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','tw','#zh#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','fi','#fi#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c2b814c9eae71a4eec1001118dd849d5','ru','Купить',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','en','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','es','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','fr','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','de','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','it','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','pt','#pt#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','ca','#ca#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','eu','#eu#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','ja','#ja#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','cn','#zh#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','tw','#zh#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','fi','#fi#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c3b814c9eae71a4eec1001118dd849d6','ru','WebСоздатель',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4b6edd276100004c4f32fc9','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c1b814c9eae71a4eec1001118dd849d4','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c2b814c9eae71a4eec1001118dd849d5','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c3b814c9eae71a4eec1001118dd849d6','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4b6edd276100004c4f32fc9','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c1b814c9eae71a4eec1001118dd849d4','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c2b814c9eae71a4eec1001118dd849d5','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c3b814c9eae71a4eec1001118dd849d6','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6e7ba95100001e03446fd','c0a80146f4b6edd276100004c4f32fc9');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6e7ba95100001e03446fd','c1b814c9eae71a4eec1001118dd849d4');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6e7ba95100001e03446fd','c2b814c9eae71a4eec1001118dd849d5');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6e7ba95100001e03446fd','c3b814c9eae71a4eec1001118dd849d6');

/* --------------------------------------------------------------------------- */

/* MODEL DOMAIN */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('ecd80abbb4b24668aa75d45a58c830a6','c1f4f56ffa344a5498c15a021203cf81','MODEL',1,'domain_16x16.gif',1,'domain_16x16.gif');

INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','es','Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','en','Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','fr','Modèle');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','de','Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','it','Modello');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','pt','#pt#Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','ca','#ca#Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','eu','#eu#Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','ja','#ja#Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','cn','#zh#Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','tw','#zh#Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','fi','#fi#Model');
INSERT INTO k_cat_labels(gu_category,id_language,tr_category) VALUES('ecd80abbb4b24668aa75d45a58c830a6','ru','Модель');

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('ecd80abbb4b24668aa75d45a58c830a6', '0fb03429fa3447a6be92142479fc6d52', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('ecd80abbb4b24668aa75d45a58c830a6', 'c1f4f56ffa344a5498c15a021203cf81', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('c0a801c9eee719f272100000ebc9b3ff', 'ecd80abbb4b24668aa75d45a58c830a6');


/* MODEL USERS */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','c1f4f56ffa344a5498c15a021203cf81','MODEL_USERS',1,'mydesktopc_16x16.gif',1,'mydesktopc_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','en','Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','es','Usuarios del Dominio',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','fr','Utilisateurs du Domaine',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','de','Domaenebenutzer',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','it','Utenti del Dominio',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','pt','#pt#Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','ca','#ca#Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','eu','#eu#Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','ja','#ja#Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','cn','#zh#Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','tw','#zh#Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','fi','#fi#Domain Users',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','ru','Пользователи Домена',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', '0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'c0a80146f4cc507f0e10021acf4aad60', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'c0a80146f4cc55e5d710021bc3e3ed97', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'c0a80146f4cc57e3cb10021c8d0629bc', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('ecd80abbb4b24668aa75d45a58c830a6', '1b5eed47658d4c959ab40c2cd9ecde80');

/* MODEL APPS */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','c1f4f56ffa344a5498c15a021203cf81','MODEL_APPS',1,'appsclosed_16x16.gif',1,'appsopen_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','en','Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','es','Aplicaciones',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','fr','Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','de','Anwendungen',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','it','Applicazioni',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','pt','#pt#Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','ca','#ca#Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','eu','#eu#Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','ja','#ja#Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','cn','#zh#Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','tw','#zh#Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','fi','#fi#Applications',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','ru','Применения',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4b6ea4fdd100002b805aa76', '0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4b6ea4fdd100002b805aa76', 'c0a80146f4cc507f0e10021acf4aad60', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4b6ea4fdd100002b805aa76', 'c0a80146f4cc55e5d710021bc3e3ed97', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4b6ea4fdd100002b805aa76', 'c0a80146f4cc57e3cb10021c8d0629bc', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4b6ea4fdd100002b805aa76', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4b6ea4fdd100002b805aa76', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('ecd80abbb4b24668aa75d45a58c830a6', 'c0a80146f4b6ea4fdd100002b805aa76');


INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c1f4f56ffa344a5498c15a021203cf81','MODEL_apps_sales',1,'rolodex16x16.gif',1,'rolodex16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c1f4f56ffa344a5498c15a021203cf81','MODEL_apps_forums',1,'forums_16x16.gif',1,'forums_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c1f4f56ffa344a5498c15a021203cf81','MODEL_apps_shop',1,'shop16x20.gif',1,'shop16x20.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c1f4f56ffa344a5498c15a021203cf81','MODEL_apps_webbuilder',1,'folderpagesets_16x16.gif',1,'folderpagesets_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','en','CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','es','Gestion de Contactos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','fr','CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','de','CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','it','Gestione dei Contatti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','pt','#pt#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','ca','#ca#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','eu','#eu#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','ja','#ja#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','cn','#zh#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','tw','#zh#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','fi','#fi#CRM',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e0a80146f4b6edd276101004c4f32fe3','ru','Система Контактов',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','en','Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','es','Foros',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','fr','Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','de','Forum',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','it','Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','pt','#pt#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','ca','#ca#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','eu','#eu#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','ja','#ja#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','cn','#zh#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','tw','#zh#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','fi','#fi#Forums',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e1b814c9eae71a4eec1011118dd849e4','ru','Форумы',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','en','Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','es','Tienda',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','fr','Magasin',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','de','Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','it','Negozio',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','pt','#pt#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','ca','#ca#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','eu','#eu#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','ja','#ja#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','cn','#zh#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','tw','#zh#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','fi','#fi#Shop',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b814c9eae71a4eec1011118dd849e5','ru','Купить',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','en','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','es','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','fr','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','de','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','it','WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','pt','#pt#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','ca','#ca#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','eu','#eu#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','ja','#ja#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','cn','#zh#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','tw','#zh#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','fi','#fi#WebBuilder',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e3b814c9eae71a4eec1011118dd849e6','ru','WebСоздатель',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','0fb03429fa3447a6be92142479fc6d52',2147483647);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c0a80146f4cc507f0e10021acf4aad60',127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c0a80146f4cc507f0e10021acf4aad60',127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c0a80146f4cc507f0e10021acf4aad60',127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c0a80146f4cc507f0e10021acf4aad60',127);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c0a80146f4cc55e5d710021bc3e3ed97',127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c0a80146f4cc55e5d710021bc3e3ed97',127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c0a80146f4cc55e5d710021bc3e3ed97',127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c0a80146f4cc55e5d710021bc3e3ed97',127);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c0a80146f4cc57e3cb10021c8d0629bc',3);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c0a80146f4cc57e3cb10021c8d0629bc',3);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c0a80146f4cc57e3cb10021c8d0629bc',3);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c0a80146f4cc57e3cb10021c8d0629bc',3);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c1f4f56ffa344a5498c15a021203cf81',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c0a80146f4cc6cb87410021ecc4e5dc2',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c0a80146f4cc6cb87410021ecc4e5dc2',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c0a80146f4cc6cb87410021ecc4e5dc2',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c0a80146f4cc6cb87410021ecc4e5dc2',127);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c0a80146f4cc58e96f10021dab7e4dfe',31);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c0a80146f4cc58e96f10021dab7e4dfe',31);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c0a80146f4cc58e96f10021dab7e4dfe',31);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c0a80146f4cc58e96f10021dab7e4dfe',31);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e0a80146f4b6edd276101004c4f32fe3','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e1b814c9eae71a4eec1011118dd849e4','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e2b814c9eae71a4eec1011118dd849e5','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('e3b814c9eae71a4eec1011118dd849e6','c0a80146f4cc6ed36a10021fff922e78',3);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','e0a80146f4b6edd276101004c4f32fe3');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','e1b814c9eae71a4eec1011118dd849e4');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','e2b814c9eae71a4eec1011118dd849e5');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4b6ea4fdd100002b805aa76','e3b814c9eae71a4eec1011118dd849e6');

/* MODEL SHARED DIRECTORIES */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('a3a90146f4b6ea4fed234565b805ab45','c1f4f56ffa344a5498c15a021203cf81','MODEL_SHARED',1,'shared_16x16.gif',1,'shared_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','en','Domain Shared Files',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','es','Archivos Compartidos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','fr','Dossiers Partagés',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','de','Max 30 zeichen benutzen',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','it','Files condivisi',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','pt','#pt#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','ca','#ca#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','eu','#eu#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','ja','#ja#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','cn','#zh#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','tw','#zh#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','fi','#fi#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('a3a90146f4b6ea4fed234565b805ab45','ru','Общие Файлы',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', '0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'c0a80146f4cc507f0e10021acf4aad60', 127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'c0a80146f4cc55e5d710021bc3e3ed97', 127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'c0a80146f4cc57e3cb10021c8d0629bc', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'bab84ab397564299b068693187464b4f', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'c0a80146f4cc58e96f10021dab7e4dfe', 127);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'c0a80146f4cc6cb87410021ecc4e5dc2', 127);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('a3a90146f4b6ea4fed234565b805ab45', 'c0a80146f4cc6ed36a10021fff922e78', 1);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('ecd80abbb4b24668aa75d45a58c830a6', 'a3a90146f4b6ea4fed234565b805ab45');


/* MODEL WORKAREAS */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('d1b90146f4b6ea4fed200005b805bc54','c1f4f56ffa344a5498c15a021203cf81','MODEL_WORKAREAS',1,'filecab_16x16.gif',1,'filecab_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','en','Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','es','Areas de Trabajo',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','fr','Espace de travail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','de','Arbeitsflaeche',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','it','Aree di Lavoro',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','pt','#pt#Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','ca','#ca#Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','eu','#eu#Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','ja','#ja#Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','cn','#zh#Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','tw','#zh#Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','fi','#fi#Workareas',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d1b90146f4b6ea4fed200005b805bc54','ru','РабочиеЗоны',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', '0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'c0a80146f4cc507f0e10021acf4aad60', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'c0a80146f4cc55e5d710021bc3e3ed97', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'c0a80146f4cc57e3cb10021c8d0629bc', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'bab84ab397564299b068693187464b4f', 2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54',  'c1f4f56ffa344a5498c15a021203cf81', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'c0a80146f4cc58e96f10021dab7e4dfe', 1);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'c0a80146f4cc6cb87410021ecc4e5dc2', 1);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'c0a80146f4cc6ed36a10021fff922e78', 1);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('ecd80abbb4b24668aa75d45a58c830a6', 'd1b90146f4b6ea4fed200005b805bc54');

/* MODEL DEFAULT WORKAREA */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('d2b80146f4b6ea4fed234565b805da67','c1f4f56ffa344a5498c15a021203cf81','MODEL_WORKAREAS_default',1,'filecab_16x16.gif',1,'filecab_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','en','Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','es','Predeterminada',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','fr','Défaut',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','de','Standardeinstellung',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','it','Predefinita',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','pt','#pt#Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','ca','#ca#Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','eu','#eu#Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','ja','#ja#Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','cn','#zh#Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','tw','#zh#Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','fi','#fi#Default',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('d2b80146f4b6ea4fed234565b805da67','ru','Установка',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', '0fb03429fa3447a6be92142479fc6d52', 2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'c0a80146f4cc507f0e10021acf4aad60', 127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'c0a80146f4cc55e5d710021bc3e3ed97', 31);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'c0a80146f4cc57e3cb10021c8d0629bc', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'bab84ab397564299b068693187464b4f', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'c1f4f56ffa344a5498c15a021203cf81', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'c0a80146f4cc58e96f10021dab7e4dfe', 1);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'c0a80146f4cc6cb87410021ecc4e5dc2', 1);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'c0a80146f4cc6ed36a10021fff922e78', 1);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('d1b90146f4b6ea4fed200005b805bc54', 'd2b80146f4b6ea4fed234565b805da67');

/* MODEL SHARED DIRECTORIES FOR DEFAULT WORKAREA */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('e2b80146f4b6ea4fed234565b805da68','c1f4f56ffa344a5498c15a021203cf81','MODEL_default_SHARED',1,'shared_16x16.gif',1,'shared_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','en','WorkArea Shared Files',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','es','Archivos Area de Trabajo',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','fr','Dossiers Partagés',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','de','Max 30 Zeichen benutzen',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','it','Files condivisi Area di Lavoro',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','pt','#pt#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','ca','#ca#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','eu','#eu#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','ja','#ja#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','cn','#zh#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','tw','#zh#Shared max 30 chars',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('e2b80146f4b6ea4fed234565b805da68','ru','Общие Файлы РабочейЗоны',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', '0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'c0a80146f4cc507f0e10021acf4aad60', 127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'c0a80146f4cc55e5d710021bc3e3ed97', 127);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'c0a80146f4cc57e3cb10021c8d0629bc', 1);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'bab84ab397564299b068693187464b4f', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'c0a80146f4cc58e96f10021dab7e4dfe', 127);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'c0a80146f4cc6cb87410021ecc4e5dc2', 127);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('e2b80146f4b6ea4fed234565b805da68', 'c0a80146f4cc6ed36a10021fff922e78', 1);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('d2b80146f4b6ea4fed234565b805da67', 'e2b80146f4b6ea4fed234565b805da68');


/* MODEL USERS (Administrator) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('dc66215648de4df1a65c5298dfc13d9b','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator',1,'mydesktopc_16x16.gif',1,'mydesktopc_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','en','Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','es','Administrador',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','fr','Administrateur',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','de','Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','it','Amministratore',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','pt','#pt#Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','ca','#ca#Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','eu','#eu#Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','ja','#ja#Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','cn','#zh#Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','tw','#zh#Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','fi','#fi#Administrator',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dc66215648de4df1a65c5298dfc13d9b','ru','Администратор',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('dc66215648de4df1a65c5298dfc13d9b', '0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('dc66215648de4df1a65c5298dfc13d9b', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('dc66215648de4df1a65c5298dfc13d9b', 'c1f4f56ffa344a5498c15a021203cf81', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('dc66215648de4df1a65c5298dfc13d9b', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'dc66215648de4df1a65c5298dfc13d9b');

/* MODEL USERS (Power User) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d1901d891000008fa9d0b6','c0a80146f4cc6cb87410021ecc4e5dc2','MODEL_superuser',1,'mydesktopc_16x16.gif',1,'mydesktopc_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','en','Power UsUser',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','es','Usuario Avanzado',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','fr','Super Utilisateur',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','de','Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','it','Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','pt','#pt#Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','ca','#ca#Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','eu','#eu#Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','ja','#ja#Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','cn','#zh#Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','tw','#zh#Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','fi','#fi#Power User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901d891000008fa9d0b6','ru','Супер Пользователь',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901d891000008fa9d0b6', '0fb03429fa3447a6be92142479fc6d52', 2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901d891000008fa9d0b6', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901d891000008fa9d0b6', 'c0a80146f4cc6cb87410021ecc4e5dc2', 127);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901d891000008fa9d0b6', 'c1f4f56ffa344a5498c15a021203cf81', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901d891000008fa9d0b6', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'c0a80146f4d1901d891000008fa9d0b6');

/* MODEL USERS (User) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d190406010000697b6ef3e','c0a80146f4cc58e96f10021dab7e4dfe','MODEL_user',1,'mydesktopc_16x16.gif',1,'mydesktopc_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','en','User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','es','Usuario',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','fr','Utilisateur',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','de','Benutzer',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','it','Utente',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','pt','#pt#User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','ca','#ca#User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','eu','#eu#User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','ja','#ja#User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','cn','#zh#User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','tw','#zh#User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','fi','#fi#User',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190406010000697b6ef3e','ru','Пользователь',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d190406010000697b6ef3e', '0fb03429fa3447a6be92142479fc6d52', 2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d190406010000697b6ef3e', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d190406010000697b6ef3e', 'c0a80146f4cc58e96f10021dab7e4dfe', 127);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d190406010000697b6ef3e', 'c1f4f56ffa344a5498c15a021203cf81', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d190406010000697b6ef3e', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'c0a80146f4d190406010000697b6ef3e');

/* MODEL USERS (Guest) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','c0a80146f4cc6ed36a10021fff922e78','MODEL_guest',1,'mydesktopc_16x16.gif',1,'mydesktopc_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','en','Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','es','Invitado',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','fr','Invité',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','de','Gast',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','it','Ospite',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','pt','#pt#Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','ca','#ca#Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','eu','#eu#Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','ja','#ja#Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','cn','#zh#Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','tw','#zh#Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','fi','#fi#Guest',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','ru','Гость',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6', '0fb03429fa3447a6be92142479fc6d52', 2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6', 'ce75c69a786f49cfa3beead8a961942c', 2147483647);

INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6', 'c0a80146f4cc6ed36a10021fff922e78', 3);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6', 'c1f4f56ffa344a5498c15a021203cf81', 2147483647);
INSERT INTO k_x_cat_user_acl  (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6', 'bab84ab397564299b068693187464b4f', 2147483647);

INSERT INTO k_cat_tree (gu_parent_cat, gu_child_cat) VALUES ('1b5eed47658d4c959ab40c2cd9ecde80', 'c0a80146f4d18c0e2f100007ba7df5c6');


/* MODEL USERS (Administrator Categories) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('5c241036f27f4554871823a0df6a29f7','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator_temp',1,NULL,'foldertempc_16x16.gif',1,'foldertempo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('dcd77f6401f54578b2dbd852e36dec32','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator_favs',1,NULL,'folderfavsc_16x16.gif',1,'folderfavso_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('345c9aae32ae4c4bab6dead531540bf7','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator_mail',1,NULL,'myemailc_16x16.gif',1,'myemailo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('456c9dae32bb4c4b676dead531541ca8','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator_inbox',1,NULL,'mailbox_16x16.gif',1,'mailbox_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('579c9da732b74c4b676d6ad531531ddd','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator_spam',1,NULL,'docsclosed_16x16.gif',1,'docsclosed_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4cc91630b100220825aecad','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator_doc',1,NULL,'docsclosed_16x16.gif',1,'docsclosed_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('1939d4c250594e2681a03a6cc8105c72','c1f4f56ffa344a5498c15a021203cf81','MODEL_administrator_recycled',1,NULL,'recycledfull_16x16.gif',1,'recycledfull_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','en','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','es','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','fr','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','de','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','it','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','pt','#pt#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','ca','#ca#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','eu','#eu#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','ja','#ja#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','cn','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','tw','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','fi','#fi#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('5c241036f27f4554871823a0df6a29f7','ru','Временный',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','en','Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','es','Favoritos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','fr','Favoris',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','de','Favoriten',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','it','Preferiti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','pt','#pt#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','ca','#ca#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','eu','#eu#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','ja','#ja#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','cn','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','tw','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','fi','#fi#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('dcd77f6401f54578b2dbd852e36dec32','ru','Избранное',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','en','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','es','Correo',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','fr','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','de','E-Mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','it','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','pt','#pt#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','ca','#ca#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','eu','#eu#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','ja','#ja#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','cn','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','tw','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','fi','#fi#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('345c9aae32ae4c4bab6dead531540bf7','ru','Электронная Почта',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','en','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','es','Bandeja de Entrada',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','fr','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','de','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','it','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','pt','#pt#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','ca','#ca#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','eu','#eu#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','ja','#ja#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','cn','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','tw','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','fi','#fi#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('456c9dae32bb4c4b676dead531541ca8','ru','#ru#Inbox',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','en','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','es','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','fr','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','de','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','it','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','pt','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','ca','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','eu','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','ja','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','cn','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','tw','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','fi','Spam',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('579c9da732b74c4b676d6ad531531ddd','ru','Spam',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','en','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','es','Documentos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','fr','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','de','Dokumente',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','it','Documenti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','pt','#pt#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','ca','#ca#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','eu','#eu#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','ja','#ja#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','cn','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','tw','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','fi','#fi#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc91630b100220825aecad','ru','Документы',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','en','Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','es','Eliminados',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','fr','Effacé',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','de','Geloescht',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','it','Eliminato',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','pt','#pa#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','ca','#ca#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','eu','#eu#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','ja','#ja#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','cn','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','tw','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','fi','#fi#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('1939d4c250594e2681a03a6cc8105c72','ru','Удалённый',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('5c241036f27f4554871823a0df6a29f7','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('dcd77f6401f54578b2dbd852e36dec32','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('345c9aae32ae4c4bab6dead531540bf7','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('456c9dae32bb4c4b676dead531541ca8','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4cc91630b100220825aecad','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('579c9da732b74c4b676d6ad531531ddd','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('1939d4c250594e2681a03a6cc8105c72','0fb03429fa3447a6be92142479fc6d52',2147483647);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('5c241036f27f4554871823a0df6a29f7','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('dcd77f6401f54578b2dbd852e36dec32','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('345c9aae32ae4c4bab6dead531540bf7','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('456c9dae32bb4c4b676dead531541ca8','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4cc91630b100220825aecad','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('579c9da732b74c4b676d6ad531531ddd','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('1939d4c250594e2681a03a6cc8105c72','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('5c241036f27f4554871823a0df6a29f7','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('dcd77f6401f54578b2dbd852e36dec32','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('345c9aae32ae4c4bab6dead531540bf7','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('456c9dae32bb4c4b676dead531541ca8','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc91630b100220825aecad','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('579c9da732b74c4b676d6ad531531ddd','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('1939d4c250594e2681a03a6cc8105c72','c1f4f56ffa344a5498c15a021203cf81',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('5c241036f27f4554871823a0df6a29f7','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('dcd77f6401f54578b2dbd852e36dec32','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('345c9aae32ae4c4bab6dead531540bf7','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('456c9dae32bb4c4b676dead531541ca8','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc91630b100220825aecad','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('579c9da732b74c4b676d6ad531531ddd','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('1939d4c250594e2681a03a6cc8105c72','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dc66215648de4df1a65c5298dfc13d9b','5c241036f27f4554871823a0df6a29f7');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dc66215648de4df1a65c5298dfc13d9b','dcd77f6401f54578b2dbd852e36dec32');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dc66215648de4df1a65c5298dfc13d9b','345c9aae32ae4c4bab6dead531540bf7');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('345c9aae32ae4c4bab6dead531540bf7','456c9dae32bb4c4b676dead531541ca8');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('345c9aae32ae4c4bab6dead531540bf7','579c9da732b74c4b676d6ad531531ddd');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dc66215648de4df1a65c5298dfc13d9b','c0a80146f4cc91630b100220825aecad');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('dc66215648de4df1a65c5298dfc13d9b','1939d4c250594e2681a03a6cc8105c72');

/* MODEL USERS (Power User Categories) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d1901ef6100003839f878b','c0a80146f4cc6cb87410021ecc4e5dc2','MODEL_superuser_temp',1,NULL,'foldertempc_16x16.gif',1,'foldertempo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d1901e8610000281c9dd83','c0a80146f4cc6cb87410021ecc4e5dc2','MODEL_superuser_favs',1,NULL,'folderfavsc_16x16.gif',1,'folderfavso_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d1901f53100004801d694b','c0a80146f4cc6cb87410021ecc4e5dc2','MODEL_superuser_mail',1,NULL,'myemailc_16x16.gif',1,'myemailo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d1901f53100014802e705c','c0a80146f4cc6cb87410021ecc4e5dc2','MODEL_superuser_inbox',1,NULL,'mailbox_16x16.gif',1,'mailbox_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d1901e1f10000184903b7c','c0a80146f4cc6cb87410021ecc4e5dc2','MODEL_superuser_docs',1,NULL,'docsclosed_16x16.gif',1,'docsclosed_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d1901fc010000582a91203','c0a80146f4cc6cb87410021ecc4e5dc2','MODEL_superuser_recycled',1,NULL,'recycledfull_16x16.gif',1,'recycledfull_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','en','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','es','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','fr','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','de','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','it','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','pt','#pt#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','ca','#ca#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','eu','#eu#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','ja','#ja#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','cn','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','tw','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','fi','#fi#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901ef6100003839f878b','ru','Временный',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','en','Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','es','Favoritos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','fr','Favoris',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','de','Favoriten',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','it','Preferiti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','pt','#pt#Favourites',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','ca','#ca#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','eu','#eu#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','ja','#ja#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','cn','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','tw','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','fi','#fi#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e8610000281c9dd83','ru','Избранное',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','en','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','es','Correo',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','fr','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','de','E-Mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','it','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','pt','#pt#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','ca','#ca#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','eu','#eu#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','ja','#ja#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','cn','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','tw','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','fi','#fi#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100004801d694b','ru','Электронная Почта',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','en','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','es','Bandeja de Entrada',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','fr','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','de','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','it','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','pt','#pt#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','ca','#ca#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','eu','#eu#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','ja','#ja#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','cn','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','tw','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','fi','#fi#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901f53100014802e705c','ru','#ru#Inbox',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','en','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','es','Documentos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','fr','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','de','Dokumente',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','it','Documenti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','pt','#pt#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','ca','#ca#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','eu','#eu#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','ja','#ja#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','cn','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','tw','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','fi','#fi#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901e1f10000184903b7c','ru','Документы',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','en','Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','es','Eliminados',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','fr','Effacé',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','de','Geloescht',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','it','Eliminati',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','pt','#pt#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','ca','#ca#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','eu','#eu#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','ja','#ja#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','cn','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','tw','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','fi','#fi#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d1901fc010000582a91203','ru','Удалённый',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901ef6100003839f878b','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901e8610000281c9dd83','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901f53100004801d694b','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901f53100014802e705c','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901e1f10000184903b7c','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901fc010000582a91203','0fb03429fa3447a6be92142479fc6d52',2147483647);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901ef6100003839f878b','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901e8610000281c9dd83','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901f53100004801d694b','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901f53100014802e705c','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901e1f10000184903b7c','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d1901fc010000582a91203','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901ef6100003839f878b','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901e8610000281c9dd83','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901f53100004801d694b','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901f53100014802e705c','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901e1f10000184903b7c','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901fc010000582a91203','c1f4f56ffa344a5498c15a021203cf81',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901ef6100003839f878b','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901e8610000281c9dd83','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901f53100004801d694b','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901f53100014802e705c','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901e1f10000184903b7c','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901fc010000582a91203','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901ef6100003839f878b','c0a80146f4cc6cb87410021ecc4e5dc2',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901e8610000281c9dd83','c0a80146f4cc6cb87410021ecc4e5dc2',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901f53100004801d694b','c0a80146f4cc6cb87410021ecc4e5dc2',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901f53100014802e705c','c0a80146f4cc6cb87410021ecc4e5dc2',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901e1f10000184903b7c','c0a80146f4cc6cb87410021ecc4e5dc2',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d1901fc010000582a91203','c0a80146f4cc6cb87410021ecc4e5dc2',2147483647);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d1901d891000008fa9d0b6','c0a80146f4d1901ef6100003839f878b');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d1901d891000008fa9d0b6','c0a80146f4d1901e8610000281c9dd83');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d1901d891000008fa9d0b6','c0a80146f4d1901f53100004801d694b');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d1901f53100004801d694b','c0a80146f4d1901f53100014802e705c');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d1901d891000008fa9d0b6','c0a80146f4d1901e1f10000184903b7c');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d1901d891000008fa9d0b6','c0a80146f4d1901fc010000582a91203');

/* MODEL USERS (User Categories) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d19041a5100009a1dfb331','c0a80146f4cc58e96f10021dab7e4dfe','MODEL_user_temp',1,NULL,'foldertempc_16x16.gif',1,'foldertempo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d19041481000089e22c25a','c0a80146f4cc58e96f10021dab7e4dfe','MODEL_user_favs',1,NULL,'folderfavsc_16x16.gif',1,'folderfavso_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d190421110000a8e84be29','c0a80146f4cc58e96f10021dab7e4dfe','MODEL_user_mail',1,NULL,'myemailc_16x16.gif',1,'myemailo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','c0a80146f4cc58e96f10021dab7e4dfe','MODEL_user_inbox',1,NULL,'mailbox_16x16.gif',1,'mailbox_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d19040c91000079b2d6cfa','c0a80146f4cc58e96f10021dab7e4dfe','MODEL_user_docs',1,NULL,'docsclosed_16x16.gif',1,'docsclosed_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d19042a210000b906c04f8','c0a80146f4cc58e96f10021dab7e4dfe','MODEL_user_recycled',1,NULL,'recycledfull_16x16.gif',1,'recycledfull_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','en','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','es','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','fr','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','de','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','it','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','pt','#pt#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','ca','#ca#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','eu','#eu#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','ja','#ja#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','cn','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','tw','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','fi','#fi#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041a5100009a1dfb331','ru','Временный',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','en','Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','es','Favoritos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','fr','Favoris',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','de','Favoriten',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','it','Preferiti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','pt','#pt#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','ca','#ca#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','eu','#eu#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','ja','#ja#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','cn','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','tw','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','fi','#fi#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19041481000089e22c25a','ru','Избранное',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','en','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','es','Correo',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','fr','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','de','E-Mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','it','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','pt','#pt#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','ca','#ca#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','eu','#eu#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','ja','#ja#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','cn','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','tw','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','fi','#fi#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d190421110000a8e84be29','ru','Электронная Почта',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','en','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','es','Bandeja de Entrada',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','fr','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','de','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','it','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','pt','#pt#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','ca','#ca#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','eu','#eu#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','ja','#ja#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','cn','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','tw','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','fi','#fi#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','ru','#ru#Inbox',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','en','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','es','Documentos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','fr','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','de','Dokumente',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','it','Documenti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','pt','#pt#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','ca','#ca#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','eu','#eu#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','ja','#ja#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','cn','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','tw','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','fi','#fi#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19040c91000079b2d6cfa','ru','Документы',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','en','Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','es','Eliminados',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','fr','Effacé',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','de','geloescht',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','it','Eliminati',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','pt','#pt#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','ca','#ca#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','eu','#eu#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','ja','#ja#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','cn','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','tw','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','fi','#fi#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d19042a210000b906c04f8','ru','Удалённый',NULL);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19041a5100009a1dfb331','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19041481000089e22c25a','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d190421110000a8e84be29','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19040c91000079b2d6cfa','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19042a210000b906c04f8','0fb03429fa3447a6be92142479fc6d52',2147483647);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19041a5100009a1dfb331','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19041481000089e22c25a','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d190421110000a8e84be29','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19040c91000079b2d6cfa','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d19042a210000b906c04f8','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19041a5100009a1dfb331','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19041481000089e22c25a','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d190421110000a8e84be29','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19040c91000079b2d6cfa','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19042a210000b906c04f8','c1f4f56ffa344a5498c15a021203cf81',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19041a5100009a1dfb331','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19041481000089e22c25a','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d190421110000a8e84be29','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19040c91000079b2d6cfa','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19042a210000b906c04f8','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19041a5100009a1dfb331','c0a80146f4cc58e96f10021dab7e4dfe',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19041481000089e22c25a','c0a80146f4cc58e96f10021dab7e4dfe',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d190421110000a8e84be29','c0a80146f4cc58e96f10021dab7e4dfe',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc6cb97410021ecc8e5e30','c0a80146f4cc58e96f10021dab7e4dfe',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19040c91000079b2d6cfa','c0a80146f4cc58e96f10021dab7e4dfe',127);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d19042a210000b906c04f8','c0a80146f4cc58e96f10021dab7e4dfe',127);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d190406010000697b6ef3e','c0a80146f4d19041a5100009a1dfb331');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d190406010000697b6ef3e','c0a80146f4d19041481000089e22c25a');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d190406010000697b6ef3e','c0a80146f4d190421110000a8e84be29');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d190421110000a8e84be29','c0a80146f4cc6cb97410021ecc8e5e30');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d190406010000697b6ef3e','c0a80146f4d19040c91000079b2d6cfa');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d190406010000697b6ef3e','c0a80146f4d19042a210000b906c04f8');


/* MODEL USERS (Guest Categories) */

INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d18c0fe210000ac220efed','c0a80146f4cc6ed36a10021fff922e78','MODEL_guest_temp',1,NULL,'foldertempc_16x16.gif',1,'foldertempo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d18c0f80100009c448caea','c0a80146f4cc6ed36a10021fff922e78','MODEL_guest_favs',1,NULL,'folderfavsc_16x16.gif',1,'folderfavso_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d18c103610000bf2be507e','c0a80146f4cc6ed36a10021fff922e78','MODEL_guest_mail',1,NULL,'myemailc_16x16.gif',1,'myemailo_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4cc6cb97410031edc8e618f','c0a80146f4cc6ed36a10021fff922e78','MODEL_guest_inbox',1,NULL,'mailbox_16x16.gif',1,'mailbox_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d18c0e7f100008b964295a','c0a80146f4cc6ed36a10021fff922e78','MODEL_guest_docs',1,NULL,'docsclosed_16x16.gif',1,'docsclosed_16x16.gif');
INSERT INTO k_categories (gu_category,gu_owner,nm_category,bo_active,dt_modified,nm_icon,id_doc_status,nm_icon2) VALUES ('c0a80146f4d18c109a10000cef2a7821','c0a80146f4cc6ed36a10021fff922e78','MODEL_guest_recycled',1,NULL,'recycledfull_16x16.gif',1,'recycledfull_16x16.gif');

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','en','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','es','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','fr','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','de','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','it','Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','pt','#pt#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','ca','#ca#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','eu','#eu#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','ja','#ja#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','cn','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','tw','#zh#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','fi','#fi#Temp',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0fe210000ac220efed','ru','Временный',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','en','Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','es','Favoritos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','fr','Favoris',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','de','Favoriten',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','it','Preferiti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','pt','#pt#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','ca','#ca#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','eu','#eu#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','ja','#ja#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','cn','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','tw','#zh#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','fi','#fi#Favourites',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0f80100009c448caea','ru','Избранное',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','en','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','es','Correo',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','fr','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','de','E-Mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','it','e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','pt','#pt#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','ca','#ca#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','eu','#eu#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','ja','#ja#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','cn','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','tw','#zh#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','fi','#fi#e-mail',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c103610000bf2be507e','ru','Электронная Почта',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','en','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','es','Bandeja de Entrada',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','fr','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','de','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','it','Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','pt','#pt#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','ca','#ca#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','eu','#eu#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','ja','#ja#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','cn','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','tw','#zh#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','fi','#fi#Inbox',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4cc6cb97410031edc8e618f','ru','#ru#Inbox',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','en','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','es','Documentos',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','fr','Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','de','Dokumente',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','it','Documenti',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','pt','#pt#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','ca','#ca#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','eu','#eu#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','ja','#ja#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','cn','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','tw','#zh#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','fi','#fi#Documents',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c0e7f100008b964295a','ru','Документы',NULL);

INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','en','Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','es','Eliminados',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','fr','Effacé',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','de','Geloescht',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','it','Eliminati',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','pt','#pt#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','ca','#ca#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','eu','#eu#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','ja','#ja#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','cn','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','tw','#zh#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','fi','#fi#Deleted',NULL);
INSERT INTO k_cat_labels (gu_category,id_language,tr_category,url_category) VALUES ('c0a80146f4d18c109a10000cef2a7821','ru','Удалённый',NULL);


INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0fe210000ac220efed','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0f80100009c448caea','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c103610000bf2be507e','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4cc6cb97410031edc8e618f','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0e7f100008b964295a','0fb03429fa3447a6be92142479fc6d52',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c109a10000cef2a7821','0fb03429fa3447a6be92142479fc6d52',2147483647);

INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0fe210000ac220efed','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0f80100009c448caea','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c103610000bf2be507e','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4cc6cb97410031edc8e618f','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c0e7f100008b964295a','ce75c69a786f49cfa3beead8a961942c',2147483647);
INSERT INTO k_x_cat_group_acl (gu_category,gu_acl_group,acl_mask) VALUES ('c0a80146f4d18c109a10000cef2a7821','ce75c69a786f49cfa3beead8a961942c',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0fe210000ac220efed','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0f80100009c448caea','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c103610000bf2be507e','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc6cb97410031edc8e618f','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0e7f100008b964295a','c1f4f56ffa344a5498c15a021203cf81',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c109a10000cef2a7821','c1f4f56ffa344a5498c15a021203cf81',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0fe210000ac220efed','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0f80100009c448caea','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c103610000bf2be507e','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc6cb97410031edc8e618f','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0e7f100008b964295a','bab84ab397564299b068693187464b4f',2147483647);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c109a10000cef2a7821','bab84ab397564299b068693187464b4f',2147483647);

INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0fe210000ac220efed','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0f80100009c448caea','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c103610000bf2be507e','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4cc6cb97410031edc8e618f','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c0e7f100008b964295a','c0a80146f4cc6ed36a10021fff922e78',3);
INSERT INTO k_x_cat_user_acl (gu_category,gu_user,acl_mask) VALUES ('c0a80146f4d18c109a10000cef2a7821','c0a80146f4cc6ed36a10021fff922e78',3);

INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','c0a80146f4d18c0fe210000ac220efed');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','c0a80146f4d18c0f80100009c448caea');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','c0a80146f4d18c103610000bf2be507e');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d18c103610000bf2be507e','c0a80146f4cc6cb97410031edc8e618f');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','c0a80146f4d18c0e7f100008b964295a');
INSERT INTO k_cat_tree (gu_parent_cat,gu_child_cat) VALUES ('c0a80146f4d18c0e2f100007ba7df5c6','c0a80146f4d18c109a10000cef2a7821');

UPDATE k_categories SET len_size=0;

/* --------------------------------------------------------------------------- */

