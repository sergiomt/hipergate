CREATE OR REPLACE PROCEDURE k_sp_del_product (IdProduct CHAR) IS
  GuAddress CHAR(32);
BEGIN
  SELECT gu_address INTO GuAddress FROM k_products WHERE gu_product=IdProduct;
  DELETE FROM k_images WHERE gu_product=IdProduct;
  DELETE FROM k_x_cat_objs WHERE gu_object=IdProduct;
  DELETE FROM k_prod_keywords WHERE gu_product=IdProduct;
  DELETE FROM k_prod_fares WHERE gu_product=IdProduct;
  DELETE FROM k_prod_attrs WHERE gu_object=IdProduct;
  DELETE FROM k_prod_attr WHERE gu_product=IdProduct;
  DELETE FROM k_prod_locats WHERE gu_product=IdProduct;
  DELETE FROM k_products WHERE gu_product=IdProduct;
  IF GuAddress IS NOT NULL THEN
    UPDATE k_academic_courses SET gu_address=NULL WHERE gu_acourse=IdProduct;
    DELETE FROM k_addresses WHERE gu_address=GuAddress;
  END IF;
END k_sp_del_product;
GO;

CREATE PROCEDURE k_sp_get_prod_loca (IdProduct CHAR, IdLocation CHAR, XProtocol OUT VARCHAR2, XHost OUT VARCHAR2, XPort OUT NUMBER, XPath OUT VARCHAR2, XFile OUT VARCHAR2, XAnchor OUT VARCHAR2) IS
BEGIN
  IF IdLocation IS NULL THEN
    SELECT xprotocol,xhost,xport,xpath,xfile,xanchor INTO XProtocol,XHost,XPort,XPath,XFile,XAnchor FROM k_prod_locats WHERE gu_product=IdProduct AND ROWNUM=1;
  ELSE
    SELECT xprotocol,xhost,xport,xpath,xfile,xanchor INTO XProtocol,XHost,XPort,XPath,XFile,XAnchor FROM k_prod_locats WHERE gu_location=IdLocation;
  END IF;
END k_sp_get_prod_loca;
GO;

CREATE PROCEDURE k_sp_get_prod_fare (IdProduct CHAR, IdFare VARCHAR2, PrSale OUT NUMBER) IS
BEGIN
  SELECT pr_sale INTO PrSale FROM k_prod_fares WHERE gu_product=IdProduct AND id_fare=IdFare;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    PrSale:=NULL;  
END k_sp_get_prod_fare;
GO;

CREATE PROCEDURE k_sp_get_date_fare (IdProduct CHAR, dtWhen DATE, PrSale OUT NUMBER) IS
BEGIN
  SELECT pr_sale INTO PrSale FROM k_prod_fares WHERE gu_product=IdProduct AND dtWhen BETWEEN dt_start AND dt_end;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    PrSale:=NULL;  
END k_sp_get_date_fare;
GO;
