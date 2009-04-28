/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Types;

import java.util.Date;
import java.util.Locale;

import java.text.NumberFormat;
import java.text.DecimalFormat;
import java.text.FieldPosition;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DBBind;

/**
 * An abstract super class for Quotation, Order and Invoice classes
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public abstract class AbstractOrder extends DBPersist {

  private Locale oLocale;
  private String sCurrencyFormat;
  private DecimalFormat oCurrencyFormat = null;
  private FieldPosition oCurrencyFieldP = null;
  private StringBuffer oCurrencyBuffer;

  protected DBSubset oLines;
  protected DBPersist oBuyer;
  protected DBPersist oSeller;
  protected String sLinesTable, sPrimaryKey;

  // ---------------------------------------------------------------------------

  protected AbstractOrder(String sTableName, String sLinesName,
                          String sKeyName, String sAuditClass) {
    super(sTableName, sAuditClass);
    sLinesTable = sLinesName;
    sPrimaryKey = sKeyName;
    oLines = null;
    oBuyer = null;
    oSeller = null;
    oLocale = null;
    setCurrencyFormat("#0.00");
  }


  // ---------------------------------------------------------------------------

  public String getCurrencyFormat() {
    return sCurrencyFormat;
  }

  // ---------------------------------------------------------------------------

  public void setCurrencyFormat(String sFormat) throws NullPointerException {
    sCurrencyFormat = sFormat;
    oCurrencyFormat = new DecimalFormat(sFormat);
    oCurrencyFieldP = new FieldPosition(NumberFormat.FRACTION_FIELD);
    oCurrencyBuffer = new StringBuffer();
  }

  // ---------------------------------------------------------------------------

  protected String formatCurrency(BigDecimal oDec)  {
    oCurrencyBuffer.setLength(0);
    oCurrencyFormat.format(oDec.doubleValue(), oCurrencyBuffer, oCurrencyFieldP);
    return oCurrencyBuffer.toString();
  }

  // ---------------------------------------------------------------------------

  protected String formatPercentage(float fPct)  {
    oCurrencyBuffer.setLength(0);
    oCurrencyFormat.format(fPct, oCurrencyBuffer, oCurrencyFieldP);
    return oCurrencyBuffer.toString();
  }
  
  // ---------------------------------------------------------------------------

  protected StringBuffer getDecimalFormated(String sColumnName)  {
    oCurrencyBuffer.setLength(0);
    if (!isNull(sColumnName))
      oCurrencyFormat.format(getDecimal(sColumnName).doubleValue(), oCurrencyBuffer, oCurrencyFieldP);
    return oCurrencyBuffer;
  }

  // ---------------------------------------------------------------------------

  protected StringBuffer getFloatFormated(String sColumnName)  {
    oCurrencyBuffer.setLength(0);
    if (!isNull(sColumnName))
      oCurrencyFormat.format(getFloat(sColumnName), oCurrencyBuffer, oCurrencyFieldP);
    return oCurrencyBuffer;
  }

  // ---------------------------------------------------------------------------

  public void setLocale(Locale oLoc) {
    oLocale = oLoc;
  }

  // ---------------------------------------------------------------------------

  public void setLocale(String sLanguage, String sCountry) {
    oLocale = new Locale(sLanguage, sCountry);
  }

  // ---------------------------------------------------------------------------

  public void setLocale(String sLanguage) {
    oLocale = new Locale(sLanguage);
  }

  // ---------------------------------------------------------------------------

  public Locale getLocale() {
    return oLocale==null ? Locale.getDefault() : oLocale;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get billing address for this order</p>
   * Address is loaded from value of gu_bill_addr column. If gu_bill_addr is null
   * then this function returns null.
   * @param oConn JDCConnection
   * @return Address object instance or <b>null</b> if gu_bill_addr is <b>null</b>
   * @throws SQLException
   */
  public Address getBillAddress(JDCConnection oConn) throws SQLException {
    Address oBillAddr;
    if (isNull(DB.gu_bill_addr)) {
      oBillAddr = null;
    } else {
      oBillAddr = new Address(oConn, getString(DB.gu_bill_addr));
    }
    return oBillAddr;
  } // getBillAddress

  // ---------------------------------------------------------------------------

  /**
   * Get order lines as a DBSubset
   * @return DBSubset The columns returned depend on the implementation of
   * getLines(JDCConnection) at derived clases
   * @throws IllegalStateException If this method is called without having
   * loaded the order lines first.
   */
  public DBSubset getLines() throws IllegalStateException {
    if (oLines==null)
      throw new IllegalStateException("AbstractOrder.getLines() Order lines not loaded");
    else
      return oLines;
  }

  // ---------------------------------------------------------------------------

  public abstract DBSubset getLines(JDCConnection oConn) throws SQLException;

  // ---------------------------------------------------------------------------

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;

    boolean bLoad = super.load(oConn, PKVals);

    oLines = null;
    oBuyer = null;
    oSeller= null;

    if (bLoad) {
      oLines = getLines(oConn);

      if (!isNull(DB.gu_contact)) {
        oStmt = oConn.prepareStatement("SELECT "+DB.gu_address+ " FROM "+DB.k_x_contact_addr+" WHERE "+DB.gu_contact+"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, getString(DB.gu_contact));
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          oBuyer = new DBPersist(DB.k_member_address, "Buyer");
          oBuyer.load(oConn, new Object[]{oRSet.getString(1)});
        }
        oRSet.close();
        oStmt.close();
      } else if (!isNull(DB.gu_company)) {
        oStmt = oConn.prepareStatement("SELECT "+DB.gu_address+ " FROM "+DB.k_x_company_addr+" WHERE "+DB.gu_company+"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, getString(DB.gu_company));
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          oBuyer = new DBPersist(DB.k_member_address, "Buyer");
          oBuyer.load(oConn, new Object[]{oRSet.getString(1)});
        }
        oRSet.close();
        oStmt.close();
      }
      if (!isNull(DB.gu_shop))
        oSeller = new Shop(oConn, getString(DB.gu_shop));
    } // fi (bLoad)

    return bLoad;
  }

  //----------------------------------------------------------------------------

  private void insertLine(JDCConnection oConn, int iLine,
                          String sProductId, String sProductNm,
                          BigDecimal dSalePr, float fQuantity,
                          BigDecimal dTotalPr, float fTax,
                          short iTaxIncluded, String sPromotion,
                          String sOptions) throws SQLException {
    PreparedStatement oStmt;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin AbstractOrder.insertLine([Connection], " + String.valueOf(iLine) + "," + (sProductId!=null ? sProductId : "null") + "," + (sProductNm!=null ? sProductNm : "null") + "," + dSalePr.toString() + "," + String.valueOf(fQuantity) + "," + dTotalPr.toString() + "," + String.valueOf(iTaxIncluded) + "," + (sPromotion!=null ? sPromotion : "") + "," + (sOptions!=null ? sOptions : ""));
      DebugFile.incIdent();
    }

    sSQL = "INSERT INTO " + sLinesTable + " (" + sPrimaryKey + "," + DB.pg_line + "," + DB.gu_product + "," + DB.nm_product + "," + DB.pr_sale + "," + DB.nu_quantity + "," + DB.pr_total + "," + DB.pct_tax_rate + "," + DB.is_tax_included + "," + DB.tx_promotion + "," + DB.tx_options + ") VALUES (?,?,?,?,?,?,?,?,?,?,?)";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    oStmt = oConn.prepareStatement(sSQL);

    oStmt.setString(1,getString(sPrimaryKey));
    oStmt.setInt   (2,iLine);
    oStmt.setString(3, sProductId);
    oStmt.setString(4, sProductNm);
    oStmt.setBigDecimal (5, dSalePr);
    oStmt.setFloat (6, fQuantity);
    oStmt.setBigDecimal (7, dTotalPr);
    oStmt.setFloat (8, fTax);
    oStmt.setShort (9, iTaxIncluded);
    oStmt.setString(10, sPromotion);
    oStmt.setString(11, sOptions);

    if (DebugFile.trace) DebugFile.writeln("Connection.execute()");

    oStmt.execute();
    oStmt.close();

    oStmt = oConn.prepareStatement("UPDATE "+getTableName()+" SET "+DB.dt_modified+"="+DBBind.Functions.GETDATE+" WHERE "+sPrimaryKey+"=?");
    oStmt.setObject(1, get(sPrimaryKey), Types.CHAR);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AbstractOrder.insertLine()");
    }
  } // insertLine

  //----------------------------------------------------------------------------

  private boolean updateLine(JDCConnection oConn, int iLine,
                             String sProductId, String sProductNm,
                             BigDecimal dSalePr, float fQuantity,
                             BigDecimal dTotalPr, float fTax,
                             short iTaxIncluded, String sPromotion,
                             String sOptions) throws SQLException {
    boolean bUpdated;
    PreparedStatement oStmt;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin AbstractOrder.updateLine([Connection], " + String.valueOf(iLine) + "," + (sProductId!=null ? sProductId : "null") + "," + (sProductNm!=null ? sProductNm : "null") + "," + dSalePr.toString() + "," + String.valueOf(fQuantity) + "," + dTotalPr.toString() + "," + String.valueOf(iTaxIncluded) + "," + (sPromotion!=null ? sPromotion : "") + "," + (sOptions!=null ? sOptions : ""));
      DebugFile.incIdent();
    }

    sSQL = "UPDATE " + sLinesTable + " SET " + DB.gu_product + "=?," + DB.nm_product + "=?," + DB.pr_sale + "=?," + DB.nu_quantity + "=?," + DB.pr_total + "=?," + DB.pct_tax_rate + "=?," + DB.is_tax_included + "=?," + DB.tx_promotion + "=?," + DB.tx_options + "=? WHERE " + sPrimaryKey + "=? AND " + DB.pg_line + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    oStmt = oConn.prepareStatement(sSQL);

    oStmt.setString(1, sProductId);
    oStmt.setString(2, sProductNm);
    oStmt.setBigDecimal (3, dSalePr);
    oStmt.setFloat (4, fQuantity);
    oStmt.setBigDecimal (5, dTotalPr);
    oStmt.setFloat (6, fTax);
    oStmt.setShort (7, iTaxIncluded);
    oStmt.setString(8, sPromotion);
    oStmt.setString(9, sOptions);
    oStmt.setString(10,getString(sPrimaryKey));
    oStmt.setInt   (11,iLine);

    if (DebugFile.trace) DebugFile.writeln("Connection.executeUpdate()");

    bUpdated = (oStmt.executeUpdate()>0);
    oStmt.close();

    oStmt = oConn.prepareStatement("UPDATE "+getTableName()+" SET "+DB.dt_modified+"="+DBBind.Functions.GETDATE+" WHERE "+sPrimaryKey+"=?");
    oStmt.setObject(1, get(sPrimaryKey), Types.CHAR);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AbstractOrder.updateLine() : " + String.valueOf(bUpdated));
    }

    return bUpdated;
  } // updateLine

  //----------------------------------------------------------------------------

  /**
   * <p>Add Product to Order or Invoice line</p>
   * This method may be used to add order lines for products not present at
   * k_products table.
   * @param oConn Database Connection
   * @param sProductId Product GUID (optional, if not set a new one will be
   * automatically assigned).
   * @param sProductNm Product Name
   * @param dSalePr Product Unitary Sale Price
   * @param fQuantity Quantity ordered
   * @param dTotalPr Total Price for Quantity including taxes
   * @param fTax Percentage of tax rate applicable
   * @param iTaxIncluded 1 if tax is included in unitary price, 0 if tax is not included.
   * @param sPromotion Promotional Text
   * @param sOptions Additional Options
   * @return Line Number Added
   * @throws SQLException
   * @throws IllegalArgumentException If sProductId does not exist
   * @throws NullPointerException
   */
  public int addProduct(JDCConnection oConn, String sProductId, String sProductNm,
                        BigDecimal dSalePr, float fQuantity, BigDecimal dTotalPr,
                        float fTax, short iTaxIncluded, String sPromotion,
                        String sOptions)
    throws SQLException,IllegalArgumentException,NullPointerException {
    int iPgLine;
    Object oPgLine;
    ResultSet oLine;
    PreparedStatement oSeek;

    if (isNull(sPrimaryKey)) throw new NullPointerException("AbstractOrder.addProduct() "+sPrimaryKey+" cannot be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin AbstractOrder.addProduct([Connection], " + (sProductId!=null ? sProductId : "null") + "," + (sProductNm!=null ? sProductNm : "null") + "," + dSalePr.toString() + "," + String.valueOf(fQuantity) + "," + dTotalPr.toString() + "," + String.valueOf(iTaxIncluded) + "," + (sPromotion!=null ? sPromotion : "") + "," + (sOptions!=null ? sOptions : ""));
      DebugFile.incIdent();
    }

    if (null==sProductId) {
      sProductId = "null_"+Gadgets.leftPad(Gadgets.left(sProductNm==null ? "" : Gadgets.ASCIIEncode(sProductNm), 27),'*',27).toUpperCase();
      iPgLine = -1;
    }
    else {
      if (sProductNm==null) sProductNm = DBCommand.queryStr(oConn, "SELECT "+DB.nm_product+" FROM "+DB.k_products+" WHERE "+DB.gu_product+"='"+sProductId+"'");

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + "SELECT " + DB.pg_line + " FROM " + sLinesTable + " WHERE " + sPrimaryKey + "=? AND " + DB.gu_product + "=?" + ")");

      oSeek = oConn.prepareStatement("SELECT " + DB.pg_line + " FROM " + sLinesTable + " WHERE " + sPrimaryKey + "=? AND " + DB.gu_product + "=?",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oSeek.setString(1, getString(sPrimaryKey));
      oSeek.setString(2, sProductId);
      oLine = oSeek.executeQuery();
      if (oLine.next())
        iPgLine = oLine.getInt(1);
      else
        iPgLine = -1;
      oLine.close();
      oSeek.close();
    }

    if (-1==iPgLine) {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + "SELECT MAX(" + DB.pg_line + ") FROM " + sLinesTable + " WHERE " + sPrimaryKey + "=?" + ")");

      oSeek = oConn.prepareStatement("SELECT MAX(" + DB.pg_line + ") FROM " + sLinesTable + " WHERE " + sPrimaryKey + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oSeek.setString(1, getString(sPrimaryKey));
      oLine = oSeek.executeQuery();
      if (oLine.next())
        oPgLine = oLine.getObject(1);
      else
        oPgLine = null;
      oLine.close();
      oSeek.close();

      if (null==oPgLine)
        iPgLine = 1;
      else
        iPgLine = new Integer(oPgLine.toString()).intValue() + 1;

      insertLine (oConn, iPgLine, sProductId, sProductNm, dSalePr, fQuantity, dTotalPr, fTax, iTaxIncluded, sPromotion, sOptions);
    }
    else
      updateLine (oConn, iPgLine, sProductId, sProductNm, dSalePr, fQuantity, dTotalPr, fTax, iTaxIncluded, sPromotion, sOptions);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AbstractOrder.addProduct() : " + String.valueOf(iPgLine));
    }

    return iPgLine;
  } // addProduct

  //----------------------------------------------------------------------------

  /**
   * <p>Add a Product from a Catalog to an Order or Invoice line</p>
   * This method takes into account pr_sale, pr_list, dt_start and dt_end fields.<br>
   * There are two possible prices, <i>list price</i> or <i>sale</i> (bargain) <i>price</i>.<br>
   * Sale price is returned if it exists at database and given date is between dt_start and dt_end.<br>
   * Otherwise List price is returned.<br>
   * Product Price is taken from k_products table following these rules:<br>
   * <ul>
   * <li>if dt_start AND dt_end are NULL then pr_list price is assigned.
   * <li>if dt_start is NULL AND dt_end is NOT NULL AND pr_sale is NULL then pr_list is assigned.
   * <li>if dt_start is NULL AND dt_end is NOT NULL AND pr_sale is NOT NULL AND current date is less than or equal to dt_end then pr_sale is assigned.
   * <li>if dt_start is NULL AND dt_end is NOT NULL AND pr_sale is NOT NULL AND current date is greater than dt_end then pr_list is assigned.
   * <li>if dt_start is NOT NULL AND dt_end is NULL AND pr_sale is NULL then pr_list is assigned.
   * <li>if dt_start is NOT NULL AND dt_end is NULL AND pr_sale is NOT NULL AND current date is greater than or equal to dt_start then pr_sale is assigned.
   * <li>if dt_start is NOT NULL AND dt_end is NULL AND pr_sale is NOT NULL AND current date is less than dt_start then pr_list is assigned.
   * <li>if dt_start AND dt_end are NOT NULL AND pr_sale IS NULL then pr_list price is assigned.
   * <li>if dt_start AND dt_end are NOT NULL AND pr_sale IS NOT NULL AND current date is greater than or equal to dt_start AND current_date is less than or equal to dt_end then pr_sale is assigned.
   * <li>if dt_start AND dt_end are NOT NULL AND pr_sale IS NOT NULL AND current date is less than dt_start OR current_date is greater than dt_end then pr_sale is assigned.
   * </ul>
   * @param oConn Database Conenction
   * @param sProductId Product GUID (required)
   * @param sProductNm Product Name
   * @param fQuantity Quantity ordered.
   * @param sPromotion Promotional Text
   * @param sOptions Additional Options
   * @return Line Number Added
   * @throws SQLException
   * @throws IllegalArgumentException If sProductId does not exist
   * @throws NullPointerException
   */

  public int addProduct(JDCConnection oConn, String sProductId, String sProductNm,
                        float fQuantity, String sPromotion, String sOptions)
      throws SQLException,IllegalArgumentException,NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin AbstractOrder.addProduct([Connection], " + (sProductId!=null ? sProductId : "null") + "," + (sProductNm!=null ? sProductNm : "null") + "," + String.valueOf(fQuantity) + "," + (sPromotion!=null ? sPromotion : "") + "," + (sOptions!=null ? sOptions : ""));
      DebugFile.incIdent();
    }

    Product oProd = new Product();
    boolean bFound;
    if (sProductId==null)
      bFound = false;
    else {
      bFound = oProd.load(oConn, new Object[]{sProductId});

      if (!bFound) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new SQLException("AbstractOrder.addProduct() Product "+sProductId+" not found","02000", 200);
      }
    } // fi (sProductId)

    float fTaxRate;
    BigDecimal dListPr;
    BigDecimal dSalePr;
    short iTaxIncluded;
    boolean bDtStart = oProd.isNull(DB.dt_start);
    boolean bDtEnd = oProd.isNull(DB.dt_end);

    if (null==sProductNm) sProductNm = oProd.getString(DB.nm_product);
    if (oProd.isNull(DB.pr_list)) dListPr = new BigDecimal(0); else dListPr = oProd.getDecimal(DB.pr_list);
    if (oProd.isNull(DB.is_tax_included)) iTaxIncluded = (short)0f; else iTaxIncluded = oProd.getShort(DB.is_tax_included);
    if (oProd.isNull(DB.pct_tax_rate)) fTaxRate = 0f; else fTaxRate = oProd.getFloat(DB.pct_tax_rate);

    Date dNow = new Date();
    dSalePr = oProd.salePrice (dNow);

    if (null==dSalePr)
      throw new NullPointerException("Could not find Sale Price for Product " + oProd.getStringNull(DB.gu_product,"") + " on date " + dNow.toString());

    int iPg = addProduct(oConn, sProductId, sProductNm, dSalePr, fQuantity,
                         new BigDecimal(dSalePr.doubleValue() * (double)fQuantity),
                         fTaxRate, iTaxIncluded, sPromotion, sOptions);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End AbstractOrder.addProduct() : " + String.valueOf(iPg));
    }

    return iPg;
 } // addProduct

  // ---------------------------------------------------------------------------

  /**
   * <p>Add Product from Catalog to an Order or Invoice line</p>
   * @param oConn Database Connection
   * @param sProductId Product GUID
   * @param fQuantity Quantity
   * @return Line Number Added
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws NullPointerException
   */
  public int addProduct(JDCConnection oConn, String sProductId, float fQuantity)
    throws SQLException,IllegalArgumentException,NullPointerException {

    return addProduct (oConn, sProductId, null, fQuantity, null, null);
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Remove Product from Order given its GUID</p>
   * @param oConn Database Connection
   * @param sProductId GUID of product to be removed.
   * @throws SQLException
   */
  public void removeProduct(JDCConnection oConn, String sProductId) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Order.removeProduct([Connection], " + (sProductId!=null ? sProductId : "null") + ")");
      DebugFile.incIdent();
    }

    Statement oDlte = oConn.createStatement();

    if (DebugFile.trace)
      DebugFile.writeln("Statement.execute(DELETE FROM " + sLinesTable + " WHERE " + sPrimaryKey + "='" + getStringNull(sPrimaryKey,"null") + "' AND " + DB.gu_product + "='" + (sProductId!=null ? sProductId : "null") + "'");

    oDlte.execute("DELETE FROM " + sLinesTable + " WHERE " + sPrimaryKey + "='" + getString(sPrimaryKey) + "' AND " + DB.gu_product + "='" + sProductId + "'");
    oDlte.close();

    PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+getTableName()+" SET "+DB.dt_modified+"="+DBBind.Functions.GETDATE+" WHERE "+sPrimaryKey+"=?");
    oStmt.setObject(1, get(sPrimaryKey), Types.CHAR);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Order.removeProduct()");
    }
  } // removeProduct

  //----------------------------------------------------------------------------

  /**
   * <p>Remove all products from invoice or order (empty basket)</p>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public void removeAllProducts(JDCConnection oConn) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Order.removeAllProducts([Connection])");
      DebugFile.incIdent();
    }

    Statement oDlte = oConn.createStatement();

    if (DebugFile.trace)
      DebugFile.writeln("Statement.execute(DELETE FROM " + sLinesTable + " WHERE " + sPrimaryKey + "='" + getStringNull(sPrimaryKey,"") + "'");

    oDlte.execute("DELETE FROM " + sLinesTable + " WHERE " + sPrimaryKey + "='" + getString(sPrimaryKey) + "'");
    oDlte.close();

    PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+getTableName()+" SET "+DB.dt_modified+"="+DBBind.Functions.GETDATE+" WHERE "+sPrimaryKey+"=?");
    oStmt.setObject(1, get(sPrimaryKey), Types.CHAR);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Order.removeAllProducts()");
    }
  } // removeAllProducts

  //----------------------------------------------------------------------------

  /**
   * <p>Sum over pr_total price of order lines taking quantities into account</p>
   * This method will compute the sum of order line prices without taxes or other charges
   * @return BigDecimal
   * @throws IllegalStateException if order lines have not been previously loaded
   */
  public BigDecimal computeSubtotal()
    throws IllegalStateException {

    if (null==oLines)
      throw new IllegalStateException("AbstractOrder.computeSubtotal() Lines must be loaded before computing subtotal");

    BigDecimal dSubTotal = new BigDecimal(0d);

    final int iLines = oLines.getRowCount();

    if (iLines>0) {
      final int iPrSale = oLines.getColumnPosition(DB.pr_total);
      final int iNuQuan = oLines.getColumnPosition(DB.nu_quantity);
      final BigDecimal dOne = new BigDecimal(1d);
      BigDecimal dQuantity;

      for (int l = 0; l < iLines; l++) {
        if (!oLines.isNull(iPrSale, l)) {
          if (oLines.isNull(iNuQuan, l))
            dQuantity = dOne;
          else
            dQuantity = new BigDecimal(oLines.getFloat(iNuQuan, l));
          dSubTotal = dSubTotal.add(oLines.getDecimal(iPrSale,l).multiply(dQuantity));
        } // fi (pr_sale is not null)
      } // next
    }
    return dSubTotal;
  } // computeSubtotal

  //----------------------------------------------------------------------------

  /**
   * <p>Get total price for all lines without taxes</p>
   * @param oConn JDCConnection
   * @return BigDecimal Sum over pr_sale price taking quantities into account
   * @throws SQLException
   */

  public BigDecimal computeSubtotal(JDCConnection oConn) throws SQLException {
    if (null==oLines) getLines(oConn);
    return computeSubtotal();
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Get total tax amount for all lines</p>
   * @return BigDecimal SUM(pr_total*nu_quantity*pct_tax_rate)
   * @throws IllegalStateException
   */
  public BigDecimal computeTaxes()
    throws IllegalStateException {

    if (null == oLines)
      throw new IllegalStateException("AbstractOrder.computeTaxes() Lines must be loaded before computing subtotal");

    BigDecimal dTaxes = new BigDecimal(0d);
    float fTax;
    boolean bTaxIncluded;
    final int iLines = oLines.getRowCount();

    if (iLines > 0) {
      final int iPrSale = oLines.getColumnPosition(DB.pr_total);
      final int iNuQuan = oLines.getColumnPosition(DB.nu_quantity);
      final int iPctTax = oLines.getColumnPosition(DB.pct_tax_rate);
      final int iTaxInc = oLines.getColumnPosition(DB.is_tax_included);
      final BigDecimal dOne = new BigDecimal(1d);
      BigDecimal dQuantity, dTax;

      for (int l = 0; l < iLines; l++) {
        if (!oLines.isNull(iPctTax,l) && !oLines.isNull(iPrSale,l)) {

          if (oLines.isNull(iNuQuan, l))
            dQuantity = dOne;
          else
            dQuantity = new BigDecimal(oLines.getFloat(iNuQuan, l));

          fTax = oLines.getFloat(iPctTax,l);          
          if (fTax>1f)
            dTax = new BigDecimal(fTax/100f);
          else
            dTax = new BigDecimal(fTax);

          if (oLines.isNull(iTaxInc,l))
            bTaxIncluded = false;
          else if (oLines.getShort(iTaxInc,l)==(short)0)
            bTaxIncluded = false;
          else
            bTaxIncluded = true;

          if (!bTaxIncluded)
            dTaxes = dTaxes.add(oLines.getDecimal(iPrSale,l).multiply(dQuantity).multiply(dTax));
        }
      } // next
    } // fi (iLines>0)
    return dTaxes;
  } // computeTaxes

  //----------------------------------------------------------------------------

  public BigDecimal computeTaxes(JDCConnection oConn) throws SQLException {
    if (null==oLines) getLines(oConn);
    return computeTaxes();
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Compute Order total</p>
   * Sum of all line subtotals including taxes.
   * @return BigDecimal computeSubtotal()+computeTaxes()
   * @throws IllegalStateException if order lines have not been previously loaded
   */
  public BigDecimal computeTotal() throws IllegalStateException {
    return computeSubtotal().add(computeTaxes());
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Compute Order total</p>
   * Sum of all line subtotals including taxes.
   * @return BigDecimal computeSubtotal()+computeTaxes()
   * @throws SQLException
   * @throws IllegalStateException if order lines have not been previously loaded
   */
  public BigDecimal computeTotal(JDCConnection oConn) throws SQLException, IllegalStateException {
    return computeSubtotal(oConn).add(computeTaxes(oConn));
  }

}
