
CREATE FUNCTION k_sp_del_product (CHAR) RETURNS INTEGER AS '
DECLARE
  GuAddress CHAR(32);
BEGIN
  SELECT gu_address INTO GuAddress FROM k_products WHERE gu_product=$1;
  DELETE FROM k_images WHERE gu_product=$1;
  DELETE FROM k_x_cat_objs WHERE gu_object=$1;
  DELETE FROM k_prod_keywords WHERE gu_product=$1;
  DELETE FROM k_prod_fares WHERE gu_product=$1;
  DELETE FROM k_prod_attrs WHERE gu_object=$1;
  DELETE FROM k_prod_attr WHERE gu_product=$1;
  DELETE FROM k_prod_locats WHERE gu_product=$1;
  DELETE FROM k_products WHERE gu_product=$1;
  IF GuAddress IS NOT NULL THEN
    UPDATE k_academic_courses SET gu_address=NULL WHERE gu_acourse=$1;
    DELETE FROM k_addresses WHERE gu_address=GuAddress;
  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;
