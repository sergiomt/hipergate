
CREATE FUNCTION k_sp_del_product (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_addresses WHERE gu_address IN (SELECT gu_address FROM k_products WHERE gu_product=$1);
  DELETE FROM k_images WHERE gu_product=$1;
  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  DELETE FROM k_prod_keywords WHERE gu_product=$1;
  DELETE FROM k_prod_fares WHERE gu_product=$1;
  DELETE FROM k_prod_attrs WHERE gu_object=$1;
  DELETE FROM k_prod_attr WHERE gu_product=$1;
  DELETE FROM k_prod_locats WHERE gu_product=$1;
  DELETE FROM k_products WHERE gu_product=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;
