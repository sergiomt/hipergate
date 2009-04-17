/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.hipergate;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;

 /**
  * <p>Manage Product Bundles</p>
  * Product Bundles are sets of products that must be sold all together at a discount price.
  * The bundle itself is stored as a Product at k_products table.
  * Actual products contained into the bundle are also stored at k_products
  * and the relationship between the bundle and its composing products is stablished throught
  * k_prod_locats table, being one bundle location for each of its products.
  * 
  */
public class ProductBundle extends Product {

  /**
   * <p>Check if this bundle contains a given Product</p>
   * @param oConn JDCConnection
   * @param sGuProduct GUID of Product sought
   * @return <b>true</b> if xfile column from any ProductLocation of this ProductBundle is equal to sGuProduct
   * @throws SQLException
   */
  public boolean containsProduct(JDCConnection oConn, String sGuProduct) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM"+DB.k_prod_locats+" WHERE "+DB.gu_product+"=? AND "+DB.xfile+"=?");
    oStmt.setString(1, getString(DB.gu_product));
    oStmt.setString(2, sGuProduct);
	ResultSet oRSet = oStmt.executeQuery();
	boolean bContainsProduct = oRSet.next();
	oRSet.close();
	oStmt.close();
	return bContainsProduct;
  } // containsProduct

  public void addProduct(JDCConnection oConn, String sGuProduct) throws SQLException {
  		
  	if (containsProduct(oConn, sGuProduct))
  	  throw new SQLException("ProductBundle.addProduct() Product already exists at bundle");
  	  
  	ProductLocation oLoca = new ProductLocation();
  	oLoca.replace(DB.gu_product,getString(DB.gu_product));
  	oLoca.replace(DB.xprotocol,"ware://");
  	oLoca.replace(DB.id_prod_type,"LNK");
  	oLoca.replace(DB.id_cont_type,100);
  	oLoca.replace(DB.xfile,sGuProduct);
  	oLoca.store(oConn);
  	
  } // addProduct
	
  public void addProduct(JDCConnection oConn, String sGuProduct, int iPgProduct) throws SQLException {
  		
  	if (containsProduct(oConn, sGuProduct))
  	  throw new SQLException("ProductBundle.addProduct() Product already exists at bundle");
  	  
  	ProductLocation oLoca = new ProductLocation();
  	oLoca.replace(DB.gu_product,getString(DB.gu_product));
  	oLoca.replace(DB.pg_prod_locat,iPgProduct);
  	oLoca.replace(DB.xprotocol,"ware://");
  	oLoca.replace(DB.id_prod_type,"LNK");
  	oLoca.replace(DB.id_cont_type,100);
  	oLoca.replace(DB.xfile,sGuProduct);
  	oLoca.store(oConn);
  	
  } // addProduct

  public boolean removeProduct(JDCConnection oConn, String sGuProduct) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_prod_locats+" WHERE "+DB.gu_product+"=? AND "+DB.xfile+"=?");
    oStmt.setString(1, getString(DB.gu_product));
    oStmt.setString(2, sGuProduct);
    int nAffected = oStmt.executeUpdate();
    oStmt.close();
    return nAffected>0 ? true : false;
  } // removeProduct
  
  public Product[] getProducts (JDCConnection oConn) throws SQLException {
    Product[] aProds;
    DBSubset oProds = new DBSubset(DB.k_products,"*","gu_product=? ORDER BY "+DB.pg_prod_locat,10);
    int nProds = oProds.load(oConn, new Object[]{getString(DB.gu_product)});
    if (0==nProds) {
      aProds = null;
    } else {
      aProds = new Product[nProds];
      for (int p=0; p<nProds; p++) {
        aProds[p] = new Product();
        aProds[p].putAll(oProds.getRowAsMap(p));
      } // next
    } // fi
    return aProds;
  } // getProducts
}
