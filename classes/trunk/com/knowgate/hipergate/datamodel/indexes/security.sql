CREATE INDEX i3_users ON k_users (id_domain);
CREATE INDEX i4_users ON k_users (tx_nickname);
CREATE INDEX i5_users ON k_users (nm_user);
CREATE INDEX i6_users ON k_users (tx_surname1);
CREATE INDEX i8_users ON k_users (tx_main_email);
CREATE INDEX i9_users ON k_users (gu_workarea);

CREATE INDEX i1_user_mail ON k_user_mail (gu_user);

CREATE INDEX i1_user_pwd ON k_user_pwd (gu_user);

CREATE INDEX i1_user_accounts ON k_user_accounts (tx_main_email);

CREATE INDEX i1_webbeacons ON k_webbeacons (gu_user);
CREATE INDEX i1_webbeacon_pages ON k_webbeacon_pages (gu_object);
