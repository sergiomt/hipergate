ALTER TABLE k_products ADD CONSTRAINT f4_product FOREIGN KEY (id_status) REFERENCES k_lu_status (id_status);
ALTER TABLE k_products ADD CONSTRAINT f6_product FOREIGN KEY (id_language) REFERENCES k_lu_languages (id_language);
ALTER TABLE k_products ADD CONSTRAINT f7_product FOREIGN KEY (gu_owner) REFERENCES k_users (gu_user);

ALTER TABLE k_prod_locats ADD CONSTRAINT f1_prod_locats FOREIGN KEY (gu_product) REFERENCES k_products (gu_product);
ALTER TABLE k_prod_locats ADD CONSTRAINT f6_prod_locats FOREIGN KEY (id_cont_type) REFERENCES k_lu_cont_types (id_container_type);
ALTER TABLE k_prod_locats ADD CONSTRAINT f7_prod_locats FOREIGN KEY (id_prod_type) REFERENCES k_lu_prod_types(id_prod_type);
ALTER TABLE k_prod_locats ADD CONSTRAINT u1_prod_locats UNIQUE (gu_product,pg_prod_locat);

ALTER TABLE k_prod_attr ADD CONSTRAINT f1_prod_attr FOREIGN KEY (gu_product) REFERENCES k_products (gu_product);

ALTER TABLE k_prod_attrs ADD CONSTRAINT f1_products_attrs FOREIGN KEY (gu_object) REFERENCES k_products(gu_product);

ALTER TABLE k_prod_keywords ADD CONSTRAINT f1_prod_keywords FOREIGN KEY (gu_product) REFERENCES k_products(gu_product);
ALTER TABLE k_prod_keywords ADD CONSTRAINT c1_prod_keywords CHECK (tx_keywords IS NULL OR LENGTH(tx_keywords)>0);

ALTER TABLE k_images ADD CONSTRAINT f5_images FOREIGN KEY (gu_product) REFERENCES k_products(gu_product);
    