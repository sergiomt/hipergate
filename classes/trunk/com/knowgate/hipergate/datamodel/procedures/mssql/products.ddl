CREATE PROCEDURE k_sp_del_product @IdProduct CHAR(32) AS
  DECLARE @GuAddress CHAR(32)
  SELECT @GuAddress=gu_address FROM k_products WHERE gu_product=@IdProduct OPTION (FAST 1)
  DELETE FROM k_images WHERE gu_product=@IdProduct
  DELETE FROM k_x_cat_objs WHERE gu_object=@IdProduct
  DELETE FROM k_prod_keywords WHERE gu_product=@IdProduct
  DELETE FROM k_prod_fares WHERE gu_product=@IdProduct
  DELETE FROM k_prod_attrs WHERE gu_object=@IdProduct
  DELETE FROM k_prod_attr WHERE gu_product=@IdProduct
  DELETE FROM k_prod_locats WHERE gu_product=@IdProduct
  DELETE FROM k_products WHERE gu_product=@IdProduct
  IF @GuAddress IS NOT NULL
    BEGIN
      UPDATE k_academic_courses SET gu_address=NULL WHERE gu_acourse=@IdProduct
      DELETE FROM k_addresses WHERE gu_address=@GuAddress
    END
GO;
  
CREATE PROCEDURE k_sp_get_prod_loca @IdProduct CHAR(32), @IdLocation CHAR(32),
  @XProtocol VARCHAR(8) OUTPUT, @XHost VARCHAR(64) OUTPUT, @XPort SMALLINT OUTPUT, @XPath VARCHAR(254) OUTPUT, @XFile VARCHAR(128) OUTPUT, @XAnchor VARCHAR(128) OUTPUT AS
  IF (@IdLocation IS NULL)
    SELECT TOP 1 @XProtocol=xprotocol,@XHost=xhost,@XPort=xport,@XPath=xpath,@XFile=xfile,@XAnchor=xanchor FROM k_prod_locats WHERE gu_product=@IdProduct
  ELSE
    SELECT @XProtocol=xprotocol,@XHost=xhost,@XPort=xport,@XPath=xpath,@XFile=xfile,@XAnchor=xanchor FROM k_prod_locats WHERE gu_location=@IdLocation OPTION (FAST 1)
GO;

CREATE PROCEDURE k_sp_get_prod_fare @IdProduct CHAR(32), @IdFare NVARCHAR(32), @PrSale DECIMAL(14,4) OUTPUT AS
  SET @PrSale = NULL
  SELECT @PrSale=pr_sale FROM k_prod_fares WHERE gu_product=@IdProduct AND id_fare=@IdFare
GO;

CREATE PROCEDURE k_sp_get_date_fare @IdProduct CHAR(32), @dtWhen DATETIME, @PrSale DECIMAL(14,4) OUTPUT AS
  SET @PrSale = NULL
  SELECT @PrSale=pr_sale FROM k_prod_fares WHERE gu_product=@IdProduct AND @dtWhen BETWEEN dt_start AND dt_end
GO;