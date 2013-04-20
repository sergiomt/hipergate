/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

import java.math.BigDecimal;
import java.util.HashMap;

import java.sql.Date;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.debug.DebugFile;

import com.knowgate.acl.ACL;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.misc.Gadgets;

/**
 * Read and write products from k_products table
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class Product extends DBPersist {

  /**
   * Create empty Product
   */
  public Product() {
    super(DB.k_products, "Product");
  }

  /**
   * Create empty Product and set gu_product
   * @param sIdProduct GUID for Product
   */
  public Product(String sIdProduct) {
    super(DB.k_products, "Product");

    put (DB.gu_product, sIdProduct);
  }

  /**
   * Load Product from database
   * @param oConn Database Connection
   * @param sIdProduct GUID of Product to be loaded
   * @throws SQLException
   */
  public Product(JDCConnection oConn, String sIdProduct) throws SQLException  {
    super(DB.k_products, "Product");

    Object aProd[] = { sIdProduct };

    load(oConn, aProd);
  } // Product

  // ----------------------------------------------------------

  /**
   * Get product GUID given its Name (nm_product) and WorkArea (gu_owner)
   * @param oConn Connection
   * @param sProductNm String Product Name (k_products.nm_product column)
   * @param sWorkAreaId String WorkArea GUID 
   * @return String GUID of product or <b>null</b> if no product with such name
   * was found at given WorkArea
   * @throws SQLException
   * @since 3.0
   */
  public static String getIdFromName(Connection oConn, String sProductNm, String sWorkAreaId)
    throws SQLException {

    String sRetVal = null;

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_product+","+DB.gu_owner+" FROM "+DB.k_products+" WHERE "+DB.nm_product+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sProductNm);
    ResultSet oRSet = oStmt.executeQuery();
    while (oRSet.next() && (null==sRetVal)) {
      Product oProd = new Product();
      oProd.put(DB.gu_product, oRSet.getString(1));
      oProd.put(DB.gu_owner, oRSet.getString(2));
      Shop oShop = oProd.getShop(new JDCConnection(oConn,null));
      if (null!=oShop) {
        if (oShop.getString(DB.gu_workarea).equals(sWorkAreaId))
          sRetVal = oProd.getString(DB.gu_product);
      }
    } // wend
    oRSet.close();
    oStmt.close();

    return sRetVal;
  } // getIdFromName

  // ----------------------------------------------------------

  /**
   * Get product GUID given its Name (nm_product) and WorkArea (gu_owner)
   * @param oConn JDCConnection
   * @param sProductNm String Product Name (k_products.nm_product column)
   * @param sWorkAreaId String WorkArea GUID 
   * @return String GUID of product or <b>null</b> if no product with such name
   * was found at given WorkArea
   * @throws SQLException
   * @since 3.0
   */
  public static String getIdFromName(JDCConnection oConn, String sProductNm, String sWorkAreaId)
    throws SQLException {

    String sRetVal = null;

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_product+","+DB.gu_owner+" FROM "+DB.k_products+" WHERE "+DB.nm_product+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sProductNm);
    ResultSet oRSet = oStmt.executeQuery();
    while (oRSet.next() && (null==sRetVal)) {
      Product oProd = new Product();
      oProd.put(DB.gu_product, oRSet.getString(1));
      oProd.put(DB.gu_owner, oRSet.getString(2));
      Shop oShop = oProd.getShop(oConn);
      if (null!=oShop) {
        if (oShop.getString(DB.gu_workarea).equals(sWorkAreaId))
          sRetVal = oProd.getString(DB.gu_product);
      }
    } // wend
    oRSet.close();
    oStmt.close();

    return sRetVal;
  } // getIdFromName

  // ----------------------------------------------------------

  /**
   * Get product GUID given its Reference (id_ref) and WorkArea (gu_owner)
   * @param oConn Connection
   * @param sProductId String Product Reference (k_products.id_ref column)
   * @param sWorkAreaId String WorkArea GUID (k_products.gu_owner column)
   * @return String GUID of product or <b>null</b> if no product with such reference
   * was found at given WorkArea
   * @throws SQLException
   * @since 3.0
   */
  public static String getIdFromReference(Connection oConn, String sProductId, String sWorkAreaId)
    throws SQLException {

    String sProdGuid;

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_product+" FROM "+DB.k_products+" WHERE "+DB.id_ref+"=? AND "+DB.gu_owner+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sProductId);
    oStmt.setString(2, sWorkAreaId);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sProdGuid = oRSet.getString(1);
    else
      sProdGuid = null;
    oRSet.close();
    oStmt.close();

    return sProdGuid;
  }

  // ----------------------------------------------------------

  /**
   * <p>Add or replace a Product Fare</p>
   * This method modifies both k_prod_fares and k_prod_fares_lookup tables
   * @param oConn JDCConnection
   * @param sIdFare Fare Identifier
   * @param sTpFare Fare Type
   * @param sWorkAreaId GUID of WorkArea
   * @param dPrice Fare Price
   * @param sIdCurrency 3 digits numeric currency code
   * @param fTaxRate Tax Rate (10% == 0.10f)
   * @param bIsTaxIncluded <b>true</b> if taxes are included at pr_sale
   * @return Previous sale price value for fare, or <b>null</b>
   * @since 4.0
   */
  public BigDecimal addOrReplaceFare(JDCConnection oConn, String sIdFare, String sTpFare,
  						             String sWorkAreaId, BigDecimal dPrice, String sIdCurrency,
  						             float fTaxRate, boolean bIsTaxIncluded,
  						             Date dtStart, Date dtEnd)
  	throws SQLException, NullPointerException, IllegalStateException {

    HashMap oMap;
    String sTr;
    BigDecimal oPreviousFare;
    ProductFare oFare = new ProductFare();

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Product.addOrReplaceFare([JDCConnection],"+sIdFare+","+
       					 sTpFare+","+sWorkAreaId+","+dPrice+","+sIdCurrency+","+
       					 String.valueOf(fTaxRate)+","+String.valueOf(bIsTaxIncluded)+","+
       					 dtStart+","+dtEnd+")");
       DebugFile.incIdent();
    }

    if (isNull(DB.gu_product)) {
      DebugFile.decIdent();
      throw new IllegalStateException ("Product.addOrReplaceFare product not loaded");
    }
    	
    if (null==dPrice) {
      DebugFile.decIdent();
      throw new NullPointerException ("Product.addOrReplaceFare fare for product "+getString(DB.gu_product)+" cannot be null");
    }
    
    if (oFare.load(oConn, new Object[]{get(DB.gu_product),sIdFare})) {
      oPreviousFare = oFare.getDecimal(DB.pr_sale);
      oFare.replace(DB.tp_fare, sTpFare);
      oFare.replace(DB.pr_sale, dPrice);
      oFare.replace(DB.id_currency, sIdCurrency);
      oFare.replace(DB.pct_tax_rate, fTaxRate);
      oFare.replace(DB.is_tax_included, (short) (bIsTaxIncluded ? 1 : 0));
      if (null!=dtStart)
        oFare.replace(DB.dt_start, new Timestamp(dtStart.getTime()));
      else
      	oFare.remove(DB.dt_end);
      if (null!=dtEnd)
        oFare.replace(DB.dt_end, new Timestamp(dtEnd.getTime()));
      else
      	oFare.remove(DB.dt_end);
    } else {
      oPreviousFare = null;
      oFare.put(DB.gu_product, getString(DB.gu_product));
      oFare.put(DB.id_fare, sIdFare);
      oFare.put(DB.tp_fare, sTpFare);
      oFare.put(DB.pr_sale, dPrice);
      oFare.put(DB.id_currency, sIdCurrency);
      oFare.put(DB.pct_tax_rate, fTaxRate);
      oFare.put(DB.is_tax_included, (short) (bIsTaxIncluded ? 1 : 0));
      if (null!=dtStart)
        oFare.put(DB.dt_start, new Timestamp(dtStart.getTime()));
      if (null!=dtStart)
        oFare.replace(DB.dt_end, new Timestamp(dtEnd.getTime()));    
    }
    oFare.store(oConn);

    final int nLangs = DBLanguages.SupportedLanguages.length;

    sTr = DBLanguages.getLookUpTranslation((Connection) oConn, DB.k_prod_fares_lookup, sWorkAreaId,
    								  	   DB.tp_fare, "en", sTpFare);
    if (null==sTr) {
      oMap = new HashMap(2*nLangs);
      for (int l=0; l<nLangs; l++)
      	oMap.put(DBLanguages.SupportedLanguages[l],sTpFare);
      DBLanguages.addLookup((Connection) oConn, DB.k_prod_fares_lookup, sWorkAreaId,
                            DB.tp_fare, sTpFare, oMap);
    }

    sTr = DBLanguages.getLookUpTranslation((Connection) oConn, DB.k_prod_fares_lookup, sWorkAreaId,
    								  	   DB.id_fare, "en", sIdFare);
    if (null==sTr) {
      oMap = new HashMap(2*nLangs);
      for (int l=0; l<nLangs; l++)
      	oMap.put(DBLanguages.SupportedLanguages[l],sIdFare);
      DBLanguages.addLookup((Connection) oConn, DB.k_prod_fares_lookup, sWorkAreaId,
      						DB.id_fare, sIdFare, oMap);
    }

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Product.addOrReplaceFare() : "+oPreviousFare);
    }

    return oPreviousFare;
  } // addOrReplaceFare
  
  /**
   * Get first fare found valid for a given date
   * @param oConn JDCConnection
   * @param dtWhen Date
   * @return BigDecimal
   * @throws SQLException
   */
  public BigDecimal getFareForDate(JDCConnection oConn, Date dtWhen) throws SQLException {
    BigDecimal oFare = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.getFare([Connection],"+dtWhen.toString()+")" );
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) {
        DebugFile.writeln("Connection.prepareStatement(SELECT "+DB.pr_sale+" FROM "+DB.k_prod_fares+" WHERE "+DB.gu_product+"='"+getStringNull(DB.gu_product,null)+"' AND "+DB.dt_start+"<=? AND "+DB.dt_end+">=?)");
      }
      PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.pr_sale+" FROM "+DB.k_prod_fares+" WHERE "+DB.gu_product+"=? AND "+DB.dt_start+"<=? AND "+DB.dt_end+">=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, getStringNull(DB.gu_product,null));
      oStmt.setDate(2, dtWhen);
      oStmt.setDate(3, dtWhen);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next())
        oFare = oRSet.getBigDecimal(1);
      oRSet.close();
      oStmt.close();
    } else {
      if (DebugFile.trace) {
        DebugFile.writeln("Connection.prepareCall({ call k_sp_get_date_fare('"+getStringNull(DB.gu_product,null)+"','"+dtWhen.toString()+"',?) }");
      }
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_get_date_fare(?,?,?) }");
      oCall.setString(1, getStringNull(DB.gu_product,null));
      oCall.setDate(2, dtWhen);
      oCall.registerOutParameter(3, java.sql.Types.DECIMAL);
      oCall.execute();
      oFare = oCall.getBigDecimal(3);
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oFare)
        DebugFile.writeln("End Product.getFare() : null");
      else
        DebugFile.writeln("End Product.getFare() : "+oFare.toString());
    }
    return oFare;
  }

  // ----------------------------------------------------------

  /**
   * Get a given fare price for a product
   * @param oConn JDCConnection
   * @param sIdFare String Identifier of fare to wich price is going to be retrived
   * @return BigDecimal Product price for the fare or <b>null</b> if fare does not exist.
   * @throws SQLException
   * @since v2.2
   */
  public BigDecimal getFare(JDCConnection oConn, String sIdFare) throws SQLException {
    BigDecimal oFare = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.getFare([Connection],"+sIdFare+")" );
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) {
        DebugFile.writeln("Connection.prepareStatement(SELECT "+DB.pr_sale+" FROM "+DB.k_prod_fares+" WHERE "+DB.gu_product+"='"+getStringNull(DB.gu_product,null)+"' AND "+DB.id_fare+"='"+sIdFare+"')");
      }
      PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.pr_sale+" FROM "+DB.k_prod_fares+" WHERE "+DB.gu_product+"=? AND "+DB.id_fare+"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, getStringNull(DB.gu_product,null));
      oStmt.setString(2, sIdFare);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next())
        oFare = oRSet.getBigDecimal(1);
      oRSet.close();
      oStmt.close();
    } else {
      if (DebugFile.trace) {
        DebugFile.writeln("Connection.prepareCall({ call k_sp_get_prod_fare('"+getStringNull(DB.gu_product,null)+"','"+sIdFare+"',?) }");
      }
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_get_prod_fare(?,?,?) }");
      oCall.setString(1, getStringNull(DB.gu_product,null));
      oCall.setString(2, sIdFare);
      oCall.registerOutParameter(3, java.sql.Types.DECIMAL);
      oCall.execute();
      oFare = oCall.getBigDecimal(3);
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oFare)
        DebugFile.writeln("End Product.getFare() : null");
      else
        DebugFile.writeln("End Product.getFare() : "+oFare.toString());
    }

    return oFare;
  }

  // ----------------------------------------------------------

  /**
   * Get product fares
   * @param oConn JDCConnection
   * @return DBSubset with the following columns<br>
   * <table><tr><td>id_fare</td><td>pr_sale</td><td>id_currency</td>pct_tax_rate</td><td>is_tax_included</td><td>dt_start</td><td>dt_end</td><td>tp_fare</td></tr></table>
   * @throws SQLException
   */
  public DBSubset getFares(JDCConnection oConn) throws SQLException {
    DBSubset oFares = new DBSubset(DB.k_prod_fares,DB.id_fare+","+DB.pr_sale+","+
                                   DB.id_currency+","+DB.pct_tax_rate+","+
                                   DB.is_tax_included+","+DB.dt_start+","+DB.dt_end+","+
                                   DB.tp_fare,DB.gu_product+"=?", 10);
    oFares.load(oConn, new Object[]{getStringNull(DB.gu_product,null)});

    return oFares;
  }

  // ----------------------------------------------------------

  /**
   * Get product fares of a given type
   * @param oConn JDCConnection
   * @return DBSubset with the following columns<br>
   * <table><tr><td>id_fare</td><td>pr_sale</td><td>id_currency</td>pct_tax_rate</td><td>is_tax_included</td><td>dt_start</td><td>dt_end</td><td>tp_fare</td></tr></table>
   * @throws SQLException
   */
  public DBSubset getFaresOfType(JDCConnection oConn, String sType) throws SQLException {
    DBSubset oFares = new DBSubset(DB.k_prod_fares,DB.id_fare+","+DB.pr_sale+","+
                                   DB.id_currency+","+DB.pct_tax_rate+","+
                                   DB.is_tax_included+","+DB.dt_start+","+DB.dt_end+","+
                                   DB.tp_fare,DB.gu_product+"=? AND "+DB.tp_fare+"=?", 10);
    oFares.load(oConn, new Object[]{getStringNull(DB.gu_product,null),sType});
    return oFares;
  }

  // ----------------------------------------------------------

  /**
   * Get product fares of a given type valid for the specified date
   * @param oConn JDCConnection
   * @return DBSubset with the following columns<br>
   * <table><tr><td>id_fare</td><td>pr_sale</td><td>id_currency</td>pct_tax_rate</td><td>is_tax_included</td><td>dt_start</td><td>dt_end</td><td>tp_fare</td></tr></table>
   * @throws SQLException
   */
  public DBSubset getFaresOfType(JDCConnection oConn, String sType, Date dtWhen) throws SQLException {
    DBSubset oFares = new DBSubset(DB.k_prod_fares,DB.id_fare+","+DB.pr_sale+","+
                                   DB.id_currency+","+DB.pct_tax_rate+","+
                                   DB.is_tax_included+","+DB.dt_start+","+DB.dt_end+","+
                                   DB.tp_fare,DB.gu_product+"=? AND "+DB.tp_fare+"=? AND "+
                                   "("+DB.dt_start+" IS NULL OR "+DB.dt_start+"<=?) AND "+
                                   "("+DB.dt_end+" IS NULL OR "+DB.dt_end+">=?)", 10);
    oFares.load(oConn, new Object[]{getStringNull(DB.gu_product,null),sType,dtWhen,dtWhen});
    return oFares;
  }

  // ----------------------------------------------------------

  /**
   * Get Images associated to this Product
   * @param oConn Database Connection
   * @return A DBSubset with all columns from k_images table for images with
   * gu_product field is equal to this Product GUID.
   * @throws SQLException
   * @see com.knowgate.hipergate.Image
   */
  public DBSubset getImages(JDCConnection oConn) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.getImages([Connection])" );
      DebugFile.incIdent();
    }

    int iLoca;
    Image oImg = new Image();
    Object aProd[] = { get(DB.gu_product) };

    oLocations = new DBSubset (DB.k_images, oImg.getTable(oConn).getColumnsStr(), DB.gu_product + "=?", 10);
    iLoca = oLocations.load (oConn, aProd);

    oImg = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.getImages()");
    }

    return oLocations;
  } // getImages

  // ----------------------------------------------------------

  /**
   * <p>Get Product Locations</p>
   * Location semantics depend upon what Product is used for.<br>
   * <ul>
   * <li>For Downloadable Products, ProductLocations represent mirror download URLs.
   * <li>For Versioned Products, ProductLocations represent different versions of the same File.
   * <li>For Compound Products, ProductLocations represent parts of the Product each one being a File.
   * <li>For Physical Products, ProductLocations represent stock of Product at different warehouses.
   * </ul>
   * @param oConn Database Connection
   * @return A DBSubset with all columns from k_prod_locats for ProductLocations
   * with gu_product is equal to this Product GUID.
   * @throws SQLException
   * @throws NullPointerException if gu_product property is not set for this object
   */
  public DBSubset getLocations(JDCConnection oConn)
  	throws SQLException, NullPointerException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.getLocations([Connection])" );
      DebugFile.incIdent();
    }

	if (isNull(DB.gu_product)) {
      DebugFile.decIdent();
	  throw new NullPointerException("Product.getLocations() gu_product property not set");
	}
    
    int iLoca;
    ProductLocation oLoca = new ProductLocation();
    Object aProd[] = { get(DB.gu_product) };

    oLocations = new DBSubset (DB.k_prod_locats, oLoca.getTable(oConn).getColumnsStr(), DB.gu_product + "=?", 10);
    iLoca = oLocations.load (oConn, aProd);

    oLoca = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.getLocations() : " + String.valueOf(iLoca));
    }

    return oLocations;
  } // getLocations

  // ----------------------------------------------------------

  /**
   * <p>Get First ProductLocation for this Product.</p>
   * First ProductLocation is that one find in the first place when querying
   * to the database. Thus there is no particular criteria for what is a first
   * ProductLocation. This method is particularly usefull when retrieving
   * the ProductLocation for products that always have a single Productlocation.
   * @param oConn Database Connection
   * @return ProductLocation or <b>null</b> if no ProductLocation is found at
   * k_prod_locats with gu_product equal to this Product GUID.
   * @throws SQLException
   */
  public ProductLocation getFirstLocation(JDCConnection oConn) throws SQLException {
    ResultSet oRSet;
    ResultSetMetaData oMeta;
    PreparedStatement oStmt;
    ProductLocation oLoca;
    Object oVal;
    int iColCount;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.getFirstLocation()" );
      DebugFile.incIdent();
    }

    oStmt = oConn.prepareStatement("SELECT l.* FROM " + DB.k_prod_locats + " l, " + DB.k_products + " p WHERE l." + DB.gu_product + "=p." + DB.gu_product + " AND p." + DB.gu_product + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setString(1,getString(DB.gu_product));
    oRSet = oStmt.executeQuery();

    if (oRSet.next()) {
      oLoca = new ProductLocation();
      oMeta = oRSet.getMetaData();
      iColCount = oMeta.getColumnCount();

      for (int iCol=1; iCol<=iColCount; iCol++) {
        oVal = oRSet.getObject(iCol);
        if (null!=oVal) oLoca.put(oMeta.getColumnName(iCol).toLowerCase(), oVal);
      }
    }
    else
      oLoca = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.getFirstLocation()");
    }

    return oLoca;
  } // getFirstLocation

  // ----------------------------------------------------------

  /**
   * <p>Store Product</p>
   * If no gu_product is provided, this method will automatically add a new row to k_prod_attr table for the newly created product
   * If gu_product is null then a new GUID is automatically assigned.<br>
   * If dt_modified is null then it is assigned to current system date.<br>
   * If dt_uploaded is null then it is assigned to current system date.<br>
   * If is_compound is null then it is assigned to 0.<br>
   * If id_status is null then it is assigned to 1.<br>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtSQL = new java.sql.Timestamp(new java.util.Date().
        getTime());

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.store()");
      DebugFile.incIdent();
    }

    boolean bNew = !AllVals.containsKey(DB.gu_product);

    if (bNew)

      put(DB.gu_product, Gadgets.generateUUID());

    else if (!AllVals.containsKey(DB.dt_modified) && exists(oConn))

      put (DB.dt_modified, dtSQL);

    if (!AllVals.containsKey(DB.dt_uploaded))
      put (DB.dt_uploaded, dtSQL);

    if (!AllVals.containsKey(DB.is_compound))
      put (DB.is_compound, new Short((short)0));

    if (!AllVals.containsKey(DB.id_status))
      put (DB.id_status, new Short((short)1));

    boolean bRetVal = super.store(oConn);

    if (bNew) {
      if (DebugFile.trace) DebugFile.writeln("new ProductAttribute("+getStringNull(DB.gu_product,"null")+")");
      new ProductAttribute(getString(DB.gu_product)).store(oConn);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.store() : " + getString(DB.gu_product) );
    }

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Delete Product</p>
   * Images and Productlocations are deleted first, including disk files.
   * Then k_sp_del_product storedprocedure is called.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    CallableStatement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.delete(Connection)" );
      DebugFile.incIdent();
    }

    try {
      eraseImages(oConn);
    } catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.writeln("SQLException: Product.eraseImages() " + sqle.getMessage());
      throw new SQLException(sqle.getMessage());
    }

    // Begin SQLException
      eraseLocations(oConn);

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({call k_sp_del_product ('" + getStringNull(DB.gu_product,"null") + "')}");

      oStmt = oConn.prepareCall("{call k_sp_del_product ('" + getString(DB.gu_product) + "')}");
      oStmt.execute();
      oStmt.close();
    // End SQLException

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.delete() : " + getString(DB.gu_product) );
    }

    return true;
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Delete Associated images</p>
   * @param oConn Database Connection
   * @throws SQLException
   * @throws NullPointerException if gu_product property is not set for this object
   * @see com.knowgate.hipergate.Image#delete(JDCConnection)
   */
  private void eraseImages(JDCConnection oConn)
  	throws SQLException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.eraseImages(Connection)" );
      DebugFile.incIdent();
    }

	if (isNull(DB.gu_product)) {
      DebugFile.decIdent();
	  throw new NullPointerException("Product.eraseImages() gu_product property not set");
	}
	
    DBSubset oImages = new DBSubset(DB.k_images, DB.gu_image + "," + DB.path_image, DB.gu_product + "=?", 10);
    int iImgCount = oImages.load(oConn, new Object[]{get(DB.gu_product)});
    Image oImg = new Image();

    for (int i=0; i<iImgCount; i++) {
      oImg.replace(DB.gu_image, oImages.get(0,i));
      oImg.replace(DB.path_image, oImages.get(1,i));
      oImg.delete(oConn);
    } // next

    oImg = null;
    oImages = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.eraseImages()");
    }
  } // eraseImages

  // ----------------------------------------------------------

  /**
   * <p>Delete ProductLocations including disk files.</p>
   * @param oConn Database Connection
   * @throws SQLException
   * @throws NullPointerException if gu_product property is not set for this object
   * @see com.knowgate.hipergate.ProductLocation#delete(JDCConnection)
   */
  public int eraseLocations(JDCConnection oConn) throws SQLException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.eraseLocations(Connection)" );
      DebugFile.incIdent();
    }

    DBSubset oLocs = getLocations(oConn);
    int iLocs = oLocs.getRowCount();
    ProductLocation oLoca = new ProductLocation();

    for (int f=0; f<iLocs; f++) {
      oLoca = new ProductLocation(oConn, oLocs.getString(0,f));
      oLoca.delete(oConn);
    } // next (f)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.eraseLocations() : " + oLocs.getRowCount() );
    }

    return oLocs.getRowCount();
  } //  eraseLocations()

  // ----------------------------------------------------------

  /**
   * <p>Add Product to Category</p>
   * Insert Product GUID into table k_x_cat_objs.<br>
   * If Product already belongs to Category no error is raised.
   * @param oConn Database Connection
   * @param idCategory GUID of Category
   * @param iOdPosition Position of Product into Category.
   * Positions of products inside categories do not need to be unique,
   * this value is only used for ordering product when displaying them.
   * @throws SQLException if there was another Product with the same name (k_products.nm_product) already present at idCategory
   */
  public int addToCategory(JDCConnection oConn, String idCategory, int iOdPosition) throws SQLException {

    boolean bDuplicatedName;
    boolean bAlreadyExists;
    int iRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin Product.addToCategory([JDCConnection], " + idCategory + "," + String.valueOf(iOdPosition) + ")" );
       DebugFile.incIdent();
     }

    oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "=? AND " + DB.gu_object + "=?");
    oStmt.setString(1, idCategory);
    oStmt.setString(2, getString(DB.gu_product));
    oRSet = oStmt.executeQuery();
    bAlreadyExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (!bAlreadyExists) {
      if (isNull(DB.nm_product)) load(oConn, getString(DB.gu_product));
      
      oStmt = oConn.prepareStatement("SELECT " + DB.gu_object + " FROM " +
      	                             DB.k_x_cat_objs + " x, " + DB.k_products + " p WHERE " +
    	                             "x." + DB.gu_object + "=p." + DB.gu_product + " AND " + 
    	                             "x." + DB.gu_category + "=? AND x." + DB.gu_object + "<>? AND " +
    	                             "p." + DB.nm_product + "=?");
      oStmt.setString(1, idCategory);
      oStmt.setString(2, getString(DB.gu_product));
      oStmt.setString(3, getString(DB.nm_product));
      oRSet = oStmt.executeQuery();
      bDuplicatedName = oRSet.next();
      oRSet.close();
      oStmt.close();
    
      if (bDuplicatedName) {
      	throw new SQLException ("Product.addToCategory() Integrity constraint violation: there is already another product with the same name at given category", "23000", 23);
      }

      oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_cat_objs + " (" + DB.gu_category + "," + DB.gu_object + "," + DB.id_class + "," + DB.od_position + ") VALUES (?,?,?,?)");
      oStmt.setString(1, idCategory);
      oStmt.setString(2, getString(DB.gu_product));
      oStmt.setInt (3, ClassId);
      oStmt.setInt (4, iOdPosition);
      iRetVal = oStmt.executeUpdate();
      oStmt.close();
    }
    else {
      iRetVal = 0;
    }

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Product.addToCategory() : " + String.valueOf(iRetVal));
     }

    return iRetVal;
  } // addToCategory

  // ----------------------------------------------------------

  /**
   * Remove product from Category
   * @param oConn Database Conenction
   * @param idCategory Category GUID
   * @throws SQLException
   */
  public int removeFromCategory(JDCConnection oConn, String idCategory) throws SQLException {
    int iDeleted = 0;
    PreparedStatement oStmt;

    oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "=? AND " + DB.gu_object + "=?");
    oStmt.setString(1, idCategory);
    oStmt.setString(2, getString(DB.gu_product));
    iDeleted = oStmt.executeUpdate();
    oStmt.close();

    return iDeleted;
  } // removeFromCategory

  // ----------------------------------------------------------

  /**
   * get position of Product inside a Category.
   * @param oConn Database Conenction
   * @param sCategoryId Category GUID
   * @return Product Position or <b>null</b> if this Product was not found inside
   * specified Category.
   * @throws SQLException
   */
  public Integer getPosition(JDCConnection oConn, String sCategoryId) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    Object oPos;
    Integer iPos;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.getPosition([Connection], " + sCategoryId + ")" );
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT k_sp_cat_obj_position('" + getStringNull(DB.gu_product, "null") + "','" + sCategoryId + "'))");

      oRSet = oStmt.executeQuery("SELECT k_sp_cat_obj_position ('" + getString(DB.gu_product) + "','" + sCategoryId + "')");
      oRSet.next();
      oPos = new Integer(oRSet.getInt(1));
      oRSet.close();
      oStmt.close();
    }
    else {
      // Patched for MySQL at v 3.0.13
      oCall = oConn.prepareCall("{ call k_sp_cat_obj_position(?,?,?)}");
      oCall.setString(1, getString(DB.gu_product));
      oCall.setString(2, sCategoryId);
      oCall.registerOutParameter(3, Types.INTEGER);
      oCall.execute();
      oPos = oCall.getObject(3);
      oCall.close();
      oCall = null;
    }

    if (null==oPos)
      iPos = null;
    else
      iPos = new Integer(oPos.toString());

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.getPosition()");
    }

    return iPos;
  } // getPosition

  // ----------------------------------------------------------

  /**
   * Get all categories to which this Products belongs
   * @param JDCConnection
   * @return A DBSubset with a single column gu_category
   * @throws SQLException
   * @since 4.0
   */
  public DBSubset getCategories(JDCConnection oConn) throws SQLException {
    DBSubset oCats = new DBSubset(DB.k_x_cat_objs,DB.gu_category,
    					 DB.gu_object+"=?",4);
	oCats.load(oConn, new Object[]{get(DB.gu_product)});
    return oCats;
  }

  /**
   * Get GUID of the first Category to which this Products belongs
   * @param JDCConnection
   * @return Category GUID
   * @throws SQLException
   * @since 4.0
   */
  public String getCategoryId(JDCConnection oConn) throws SQLException {
    DBSubset oCats = new DBSubset(DB.k_x_cat_objs,DB.gu_category,
    							  DB.gu_object+"=?",4);
	oCats.load(oConn, new Object[]{get(DB.gu_product)});
    if (oCats.getRowCount()>0)
      return oCats.getString(0,0);
    else
      return null;
  } // getCategoryId
    
  // ----------------------------------------------------------

  /**
   * Get the GUID of the Shop to which this product belongs
   * @param Connection
   * @return GUID of Shop or <b>null</b> if no Shop is found for this Product
   * @throws SQLException
   * @throws IllegalStateException
   * @since 4.0
   */
  public String getShopId (JDCConnection oConn) throws SQLException,IllegalStateException {
    String sGuShop = null;
    DBSubset oCats = getCategories(oConn);
    String sIdDomain = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.getShopId([JDCConnection])");
      DebugFile.incIdent();
    }
    
    if (oCats.getRowCount()!=0) {

	  if (isNull(DB.gu_owner))
	  	throw new IllegalStateException("Product must be fully loaded before calling getShopId()");
	  		
      PreparedStatement oQury = oConn.prepareStatement("SELECT "+DB.id_domain+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"=?",
                                                       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT "+DB.id_domain+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+getStringNull(DB.gu_owner,"null")+"'");
      oQury.setString(1, getString(DB.gu_owner));
      ResultSet oRSet = oQury.executeQuery();
      if (oRSet.next())
        sIdDomain = String.valueOf(oRSet.getInt(1));
      oRSet.close();
      oQury.close();
      
      if (null==sIdDomain) throw new SQLException("User "+getString(DB.gu_owner)+" not found at "+DB.k_users+" table");
      
      oQury = oConn.prepareStatement("SELECT "+DB.gu_shop+" FROM "+DB.k_shops+" WHERE "+DB.id_domain+"="+sIdDomain+" AND "+DB.gu_root_cat+"=?",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      for (int c=0; c<oCats.getRowCount() && sGuShop==null; c++) {
        for (Category oPrnt : new Category (oConn, oCats.getString(0,c)).browse(oConn, Category.BROWSE_UP, Category.BROWSE_TOPDOWN)) {
		  if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT "+DB.gu_shop+" FROM "+DB.k_shops+" WHERE "+DB.id_domain+"="+sIdDomain+" AND "+DB.gu_root_cat+"='"+oPrnt.getStringNull(DB.gu_category,"null")+"'");
		  oQury.setString(1, oPrnt.getString(DB.gu_category));
		  oRSet = oQury.executeQuery();
		  if (oRSet.next()) sGuShop = oRSet.getString(1);
		  oRSet.close();
		  if (sGuShop!=null) break;
        } // next
      } // next
      oQury.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.getShopIp() : "+sGuShop);
    }

    return sGuShop;
  } // getShopId

  // ----------------------------------------------------------

  /**
   * Get the Shop to which this product belongs
   * @param JDCConnection
   * @return Shop object or <b>null</b> if no Shop is found for this Product
   * @throws SQLException
   * @since 4.0
   */

  public Shop getShop (JDCConnection oConn) throws SQLException {
    Shop oShop;
    String sShopId = getShopId(oConn);
    if (null==sShopId)
      oShop = null;
    else
      oShop = new Shop (oConn, sShopId);
    return oShop;
  } // getShop

  // ----------------------------------------------------------

  /**
   * <p>Get Sale Price for a given date.</p>
   * This method takes into account pr_sale, pr_list, dt_start and dt_end fields.<br>
   * There are two possible prices, <i>list price</i> or <i>sale</i> (bargain) <i>price</i>.<br>
   * Sale price is returned if it exists at database and given date is between dt_start and dt_end.<br>
   * Otherwise List price is returned.<br>
   * This method does not take into account any information from k_prod_fares table.<br>
   * Product Price is taken from k_products table following these rules:<br>
   * <ul>
   * <li>if dt_start AND dt_end are NULL then pr_list price is assigned.
   * <li>if dt_start is NULL AND dt_end is NOT NULL AND pr_sale is NULL then pr_list is assigned.
   * <li>if dt_start is NULL AND dt_end is NOT NULL AND pr_sale is NOT NULL AND dtForDate is less than or equal to dt_end then pr_sale is assigned.
   * <li>if dt_start is NULL AND dt_end is NOT NULL AND pr_sale is NOT NULL AND dtForDate is greater than dt_end then pr_list is assigned.
   * <li>if dt_start is NOT NULL AND dt_end is NULL AND pr_sale is NULL then pr_list is assigned.
   * <li>if dt_start is NOT NULL AND dt_end is NULL AND pr_sale is NOT NULL AND dtForDate is greater than or equal to dt_start then pr_sale is assigned.
   * <li>if dt_start is NOT NULL AND dt_end is NULL AND pr_sale is NOT NULL AND dtForDate is less than dt_start then pr_list is assigned.
   * <li>if dt_start AND dt_end are NOT NULL AND pr_sale IS NULL then pr_list price is assigned.
   * <li>if dt_start AND dt_end are NOT NULL AND pr_sale IS NOT NULL AND dtForDate is greater than or equal to dt_start AND dtForDate is less than or equal to dt_end then pr_sale is assigned.
   * <li>if dt_start AND dt_end are NOT NULL AND pr_sale IS NOT NULL AND dtForDate is less than dt_start OR dtForDate is greater than dt_end then pr_sale is assigned.
   * </ul>
   * @param dtForDate Date for testing List or Sale Price.
   * @return Price for selling the Product at a given Date.
   */
  public BigDecimal salePrice(java.util.Date dtForDate) {
    java.util.Date dtForDateStart;
    java.util.Date dtForDateEnd;
    BigDecimal dRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.salePrice(" + dtForDate + ")" );
      DebugFile.incIdent();
    }

    if (isNull(DB.pr_list) && isNull(DB.pr_sale))
      dRetVal = null;
    else {
      if ((isNull(DB.dt_start) && isNull(DB.dt_end)) || null==dtForDate) {
        if (isNull(DB.pr_list))
          dRetVal = null;
        else
          dRetVal = getDecimal(DB.pr_list);
      }
      else {
        dtForDateStart = new java.util.Date(dtForDate.getTime());
        dtForDateStart.setHours(0); dtForDateStart.setMinutes(1); dtForDateStart.setSeconds(1);
        dtForDateEnd = new java.util.Date(dtForDate.getTime());
        dtForDateEnd.setHours(0); dtForDateEnd.setMinutes(1); dtForDateEnd.setSeconds(1);

        if (!isNull(DB.dt_start)) {
          if (isNull(DB.dt_end))
            if (dtForDateStart.compareTo(getDate(DB.dt_start))>0)
              dRetVal = getDecimal(DB.pr_sale);
            else
              dRetVal = getDecimal(DB.pr_list);
          else
            if (dtForDateStart.compareTo(getDate(DB.dt_start))>0 && dtForDateEnd.compareTo(getDate(DB.dt_end))<0)
              dRetVal = getDecimal(DB.pr_sale);
            else
              dRetVal = getDecimal(DB.pr_list);
        }
        else {
          if (dtForDateEnd.compareTo(getDate(DB.dt_end))<0)
            dRetVal = getDecimal(DB.pr_list);
          else
            dRetVal = getDecimal(DB.pr_sale);
        }
      } // fi ((isNull(DB.dt_start) && isNull(DB.dt_end)) || null==dtForDate)
    } // fi (isNull(DB.pr_list) && isNull(DB.pr_sale))

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.salePrice() : " + dRetVal);
    }

    return dRetVal;
  } // salePrice

  // ----------------------------------------------------------

  /**
   * Check user permissions and set gu_blockedby column of k_products to <b>null</b>
   * @param JDCConnection
   * @param sUserId GUID of user requesting check-out
   * @throws SecurityException if user does not have modify permission over any category containing this product
   * @throws IllegalStateException if product is already checked out by another user
   * @throws SQLException
   * @since 4.0
   */

  public void checkIn(JDCConnection oConn, String sUserId)
  	throws SQLException, IllegalStateException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.checkIn([JDCConnection]," + sUserId + ")" );
      DebugFile.incIdent();
    }

    Category oCatg = new Category();
    DBSubset oCats = getCategories(oConn);
    int nCats = oCats.getRowCount();
	int iAppMask = 0;
	if (!getStringNull(DB.gu_blockedby,"").equals(sUserId)) {
	  throw new IllegalStateException("Product.checkIn() The requested document is not checked out by "+sUserId);
	}
	for (int c=0; c<nCats && ((iAppMask&ACL.PERMISSION_MODIFY)==0); c++) {
	  oCatg.replace(DB.gu_category, oCats.getString(0,c));
	  iAppMask = oCatg.getUserPermissions((oConn), sUserId);
	} // next
	int iAffected = DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_products+" SET "+DB.gu_blockedby+"=NULL WHERE "+DB.gu_product+"='"+getStringNull(DB.gu_product,"")+"'");
    if (0==iAffected)
      throw new SQLException("Product.checkIn() Document "+getStringNull(DB.gu_product,"")+" not found","02000",200);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.checkIn()");
    }

  } // checkIn

  // ----------------------------------------------------------
  
  /**
   * Check user permissions and set the given user GUID at gu_blockedby column of k_products
   * @param JDCConnection
   * @param sUserId GUID of user requesting check-out
   * @throws SecurityException if user does not have modify permission over any category containing this product
   * @throws IllegalStateException if product is already checked out by another user
   * @throws SQLException
   * @since 4.0
   */
  public void checkOut(JDCConnection oConn, String sUserId)
  	throws SecurityException, SQLException, IllegalStateException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Product.checkOut([JDCConnection]," + sUserId + ")" );
      DebugFile.incIdent();
    }

    Category oCatg = new Category();
    DBSubset oCats = getCategories(oConn);
    int nCats = oCats.getRowCount();
	int iAppMask = 0;
	if (!getStringNull(DB.gu_blockedby,sUserId).equals(sUserId)) {
	  String sBlockersNick = DBCommand.queryStr(oConn, "SELECT "+DB.tx_nickname+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+getStringNull(DB.gu_blockedby,"")+"'");
	  throw new IllegalStateException("Product.checkOut() The requested document is already checked out by "+sBlockersNick);
	}
	for (int c=0; c<nCats && ((iAppMask&ACL.PERMISSION_MODIFY)==0); c++) {
	  oCatg.replace(DB.gu_category, oCats.getString(0,c));
	  iAppMask = oCatg.getUserPermissions((oConn), sUserId);
	} // next
	if ((iAppMask&ACL.PERMISSION_MODIFY)==0)
	  throw new SecurityException("Product.checkOut() User does not have enought permissions to check-out the requested document");
	int iAffected = DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_products+" SET "+DB.gu_blockedby+"='"+sUserId+"' WHERE "+DB.gu_product+"='"+getStringNull(DB.gu_product,"")+"'");
    if (0==iAffected)
      throw new SQLException("Product.checkOut() Document "+getStringNull(DB.gu_product,"")+" not found","02000",200);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.checkOut()");
    }

  } // checkOut

  // ----------------------------------------------------------

  private DBSubset oLocations;

  public static final short ClassId = 15;
  
  public static final short STATUS_RETIRED = -2;
  public static final short STATUS_CORRUPTED = -1;
  public static final short STATUS_PENDING = 0;
  public static final short STATUS_ACTIVE = 1;
  public static final short STATUS_BLOCKED = 2;
  
} // Product
