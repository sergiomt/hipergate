CREATE INDEX i1_products ON k_products (nm_product);
CREATE INDEX i2_products ON k_products (gu_owner);

CREATE INDEX i1_prod_locats ON k_prod_locats (gu_product);
CREATE INDEX i5_prod_locats ON k_prod_locats (xhost);
