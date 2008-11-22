ALTER TABLE k_categories      ADD CONSTRAINT f1_categories      FOREIGN KEY (gu_owner) REFERENCES k_users (gu_user);

ALTER TABLE k_cat_labels      ADD CONSTRAINT f1_cat_labels      FOREIGN KEY (gu_category) REFERENCES k_categories (gu_category);
ALTER TABLE k_cat_labels      ADD CONSTRAINT f2_cat_labels      FOREIGN KEY (id_language) REFERENCES k_lu_languages (id_language);

ALTER TABLE k_cat_root        ADD CONSTRAINT f1_cat_root        FOREIGN KEY (gu_category) REFERENCES k_categories (gu_category);

ALTER TABLE k_cat_tree        ADD CONSTRAINT f1_cat_tree        FOREIGN KEY (gu_parent_cat) REFERENCES k_categories (gu_category);
ALTER TABLE k_cat_tree        ADD CONSTRAINT f2_cat_tree        FOREIGN KEY (gu_child_cat)  REFERENCES k_categories (gu_category);

ALTER TABLE k_x_cat_objs      ADD CONSTRAINT f1_x_cat_objs      FOREIGN KEY(gu_category) REFERENCES k_categories(gu_category);
ALTER TABLE k_x_cat_objs      ADD CONSTRAINT f2_x_cat_objs      FOREIGN KEY(id_class) REFERENCES k_classes(id_class);

ALTER TABLE k_cat_expand      ADD CONSTRAINT f1_cat_expand      FOREIGN KEY(gu_rootcat) REFERENCES k_categories(gu_category);
ALTER TABLE k_cat_expand      ADD CONSTRAINT f2_cat_expand      FOREIGN KEY(gu_category) REFERENCES k_categories(gu_category);
ALTER TABLE k_cat_expand      ADD CONSTRAINT f3_cat_expand      FOREIGN KEY(gu_parent_cat) REFERENCES k_categories(gu_category);

ALTER TABLE k_x_cat_user_acl  ADD CONSTRAINT f1_x_cat_user_acl  FOREIGN KEY (gu_category) REFERENCES k_categories (gu_category);
ALTER TABLE k_x_cat_user_acl  ADD CONSTRAINT f2_x_cat_user_acl  FOREIGN KEY (gu_user) REFERENCES k_users (gu_user);

ALTER TABLE k_x_cat_group_acl ADD CONSTRAINT f1_x_cat_group_acl FOREIGN KEY (gu_category) REFERENCES k_categories (gu_category);
ALTER TABLE k_x_cat_group_acl ADD CONSTRAINT f2_x_cat_group_acl FOREIGN KEY (gu_acl_group) REFERENCES k_acl_groups (gu_acl_group);
