CREATE PROCEDURE k_sp_del_product (IdProduct CHAR(32))
BEGIN
  DECLARE GuAddress CHAR(32);
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
END
GO;

CREATE PROCEDURE k_sp_get_prod_loca (IdProduct CHAR(32), IdLocation CHAR(32), OUT XProtocol VARCHAR(8), OUT XHost VARCHAR(64), OUT XPort SMALLINT, OUT XPath VARCHAR(254), OUT XFile VARCHAR(128), OUT XAnchor VARCHAR(128))
BEGIN
  IF IdLocation IS NULL THEN
    SELECT xprotocol,xhost,xport,xpath,xfile,xanchor INTO XProtocol,XHost,XPort,XPath,XFile,XAnchor FROM k_prod_locats WHERE gu_product=IdProduct LIMIT 0,1;
  ELSE
    SELECT xprotocol,xhost,xport,xpath,xfile,xanchor INTO XProtocol,XHost,XPort,XPath,XFile,XAnchor FROM k_prod_locats WHERE gu_location=IdLocation;
  END IF;
END
GO;

CREATE PROCEDURE k_sp_get_prod_fare (IdProduct CHAR(32), IdFare VARCHAR(32), OUT PrSale DECIMAL(14,4))
BEGIN
  SET PrSale=NULL;
  SELECT pr_sale INTO PrSale FROM k_prod_fares WHERE gu_product=IdProduct AND id_fare=IdFare;
END
GO;

CREATE PROCEDURE k_sp_get_date_fare (IdProduct CHAR(32), dtWhen TIMESTAMP, OUT PrSale DECIMAL(14,4))
BEGIN
  SET PrSale=NULL;
  SELECT pr_sale INTO PrSale FROM k_prod_fares WHERE gu_product=IdProduct AND dtWhen BETWEEN dt_start AND dt_end;
END
GO;