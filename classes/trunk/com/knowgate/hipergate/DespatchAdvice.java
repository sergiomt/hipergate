/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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
import java.sql.Types;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.math.BigDecimal;

import com.knowgate.dataobjs.DB;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DBBind;
import java.sql.Statement;

/**
 * Despatch Advice
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class DespatchAdvice extends AbstractOrder {

  private DBSubset oOrders;
  private Address oShipAddr;
  private Address oBillAddr;

  // ---------------------------------------------------------------------------

  public DespatchAdvice() {
    super(DB.k_despatch_advices,DB.k_despatch_lines,DB.gu_despatch,"DespatchAdvice");
    oBillAddr=oShipAddr=null;
  }

  // ---------------------------------------------------------------------------

  public DespatchAdvice(String sDespacthAdviceId) {
    super(DB.k_despatch_advices,DB.k_despatch_lines,DB.gu_despatch,"DespatchAdvice");
    put(DB.gu_despatch, sDespacthAdviceId);
    oBillAddr=oShipAddr=null;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get a DBSubset with all lines of this Dispatch Note</p>
   * The Despatch Advice must have been previously loaded or a NullPointerException will be thrown
   * @param oConn JDCConnection
   * @return DBSubset with columns gu_dispacth,pg_line,pr_sale,nu_quantity,id_unit,pr_total,pct_tax_rate,is_tax_included,nm_product,gu_product,gu_item,tx_promotion,tx_options,id_ref
   * @throws SQLException
   * @throws NullPointerException
   */
   public DBSubset getLines(JDCConnection oConn) throws SQLException,NullPointerException {

     oLines = new DBSubset(DB.k_despatch_lines,
                           DB.gu_despatch+","+DB.pg_line+","+DB.pr_sale+","+
                           DB.nu_quantity+","+DB.id_unit+","+DB.pr_total+","+
                           DB.pct_tax_rate+","+DB.is_tax_included+","+
                           DB.nm_product+","+ DB.gu_product+","+
                           DB.gu_item+","+DB.tx_promotion+","+DB.tx_options+","+
                           "'' AS "+DB.id_ref,
                           DB.gu_despatch + "=? ORDER BY 2", 50);

     oLines.load(oConn, new Object[]{getString(DB.gu_despatch)});

	 DBSubset oProdDetail = new DBSubset (DB.k_products+" p"+","+DB.k_despatch_lines+" l",
	 									  "p."+DB.gu_product+",p."+DB.id_ref,
	 									  "p."+DB.gu_product+"=l."+DB.gu_product+" AND "+
	 									  "p."+DB.gu_owner+"=? AND "+
	 									  "l."+DB.gu_despatch + "=?", 50);
     
     int nProdCount = oProdDetail.load(oConn, new Object[]{getString(DB.gu_workarea),getString(DB.gu_despatch)});
     
     for (int p=0; p<nProdCount; p++) {
       int l = oLines.find(9, oProdDetail.get(0,p));
       if (!oProdDetail.isNull(1,p)) {
         oLines.setElementAt(oProdDetail.get(1,p),13,l);
       }
     } // next
     
     return oLines;
  } // getLines()

  // ---------------------------------------------------------------------------

  /**
   * <p>Get Orders for this Invoice</p>
   * Orders can only be get if Invoice has been previously loaded,
   * else this method will return <b>null</b>
   * @return String[]
   */
  public String[] getOrders() {
    if (oOrders==null)
      return null;
    else {
      String [] aRetVal = new String[oOrders.getRowCount()];
      for (int o=0; o<oOrders.getRowCount(); o++)
        aRetVal[o] = oOrders.getString(0,o);
      return aRetVal;
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * Load Despatch Advice with its associated Addresses
   * @param oConn JDCConnection
   * @param PKVals Array with a single element Object[1]{(String)gu_despacth}
   * @return boolean <b>true</b> is Despacth Advice was found, <b>false</b> otherwise
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bRetVal = super.load(oConn, PKVals);
    if (bRetVal) {
      oOrders = new DBSubset (DB.k_x_orders_despatch, DB.gu_order, DB.gu_despatch+"=?", 1);
      oOrders.load(oConn, PKVals);
      if (!isNull(DB.gu_ship_addr))
        oShipAddr = new Address(oConn, getString(DB.gu_ship_addr));
      if (!isNull(DB.gu_bill_addr))
        oShipAddr = new Address(oConn, getString(DB.gu_bill_addr));
      else
        oShipAddr = null;
      if (!isNull(DB.gu_bill_addr))
        oBillAddr = new Address(oConn, getString(DB.gu_bill_addr));
      if (!isNull(DB.gu_ship_addr))
        oShipAddr = new Address(oConn, getString(DB.gu_ship_addr));
      else
        oBillAddr = null;
    } // fi	

    return bRetVal;
  } // load

  // ---------------------------------------------------------------------------

  /**
   * Load Despatch Advice with its associated Addresses
   * @param oConn JDCConnection
   * @param sGuDespatchAdvice Despatch Advice GUID
   * @return boolean <b>true</b> is Despacth Advice was found, <b>false</b> otherwise
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, String sGuDespatchAdvice) throws SQLException {
    return load(oConn, new Object[]{sGuDespatchAdvice});
  }
  
  // ---------------------------------------------------------------------------

  /**
   * <p>Store despatch note</p>
   * If no value for gu_despatch is specified then a new one is automatically assigned.<br>
   * If no value for pg_despatch is specified then a new one is automatically assigned by looking at k_despatch_next table and updating it afterwards.<br>
   * This method updates dt_modified to current datetime as a side effect iif Dispatch Note did not previously exist at the database.<br>
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DespatchAdvice.store([JDCConnection])");
      DebugFile.incIdent();
    }

    if (!AllVals.containsKey(DB.gu_despatch))
      AllVals.put(DB.gu_despatch,Gadgets.generateUUID());
    else
      replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.pg_despatch) && AllVals.containsKey(DB.gu_workarea)) {
      AllVals.put(DB.pg_despatch, new Integer(nextVal(oConn, (String) AllVals.get(DB.gu_workarea))));
    } // fi (gu_workarea AND NOT pg_despatch)

    boolean bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DespatchAdvice.store() : " + String.valueOf(bRetVal));
    }
    return bRetVal;
  } // store

  //----------------------------------------------------------------------------

  /**
   * <p>Delete Dispatch Note</p>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete (JDCConnection oConn) throws SQLException {
    boolean bRetVal;
    Statement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DespatchAdvice.delete([Connection])");
      DebugFile.incIdent();
    }

    oStmt = oConn.createStatement();
    oStmt.executeUpdate("DELETE FROM " + DB.k_despatch_lines + " WHERE " + DB.gu_despatch + "='" + getString(DB.gu_despatch) + "'");
    oStmt.executeUpdate("DELETE FROM " + DB.k_x_orders_despatch + " WHERE " + DB.gu_despatch + "='" + getString(DB.gu_despatch) + "'");
    oStmt.close();

    bRetVal = super.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DespatchAdvice.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // ---------------------------------------------------------------------------

  /**
   * <p>Get despatch advice as an XML document</p>
   * Character encoding is set to UTF-8
   * @return An XML String formatted according to OASIS Universal Universal Business Language Specification
   * @throws IllegalStateException if despatch advice lines are not loaded or buyer is not set or seller is not set
   * @see <a href="http://docs.oasis-open.org/ubl/cd-UBL-1.0/">OASIS Universal Business Language 1.0</a>
   */

  public String toXML() throws IllegalStateException {
    JDCConnection oConn = null;
    return toXML (oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get despatch advice as an XML document</p>
   * Character encoding is set to UTF-8
   * @return An XML String formatted according to OASIS Universal Universal Business Language Specification
   * @throws IllegalStateException if despatch advice lines are not loaded or buyer is not set or seller is not set
   * @see <a href="http://docs.oasis-open.org/ubl/cd-UBL-1.0/">OASIS Universal Business Language 1.0</a>
   */

  public String toXML(String sIdent, String sDelim) throws IllegalStateException {
    JDCConnection oConn = null;
    return toXML (oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get despatch advice as an XML document</p>
   * Character encoding is set to UTF-8
   * @return An XML String formatted according to OASIS Universal Universal Business Language Specification
   * @throws IllegalStateException if despatch advice lines are not loaded or buyer is not set or seller is not set
   * @see <a href="http://docs.oasis-open.org/ubl/cd-UBL-1.0/">OASIS Universal Business Language 1.0</a>
   */

  public String toXML(String sIdent) throws IllegalStateException {
    JDCConnection oConn = null;
    return toXML (oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get despatch advice as an XML document</p>
   * Character encoding is set to UTF-8
   * @param oConn JDCConnection Openend JDBC database connection
   * @param sLocale String Locale for output formatting
   * @return An XML String formatted according to OASIS Universal Universal Business Language Specification<br>
   * <b>Sample output</b>
   * &lt;?xml&nbsp;version="1.0"&nbsp;encoding="UTF-8"?&gt;<br>
   * &lt;DespatchAdvice&nbsp;xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0"&nbsp;xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.0"&nbsp;xmlns:cur="urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0"&nbsp;xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"&gt;<br>
   * &nbsp;&nbsp;&lt;ID&gt;2&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&lt;GUID&gt;7f000001106a7669d5a100001e7bc8ca&lt;/GUID&gt;<br>
   * &nbsp;&nbsp;&lt;cbc:IssueDate/&gt;<br>
   * &nbsp;&nbsp;&lt;DocumentStatusCode&gt;SHIPPED&lt;/DocumentStatusCode&gt;<br>
   * &nbsp;&nbsp;&lt;cbc:Note&gt;&lt;![CDATA[Deliver&nbsp;before&nbsp;6&nbsp;P.M.]]&gt;&lt;/cbc:Note&gt;<br>
   * &nbsp;&nbsp;&lt;LineItemCountNumeric&gt;2&lt;/LineItemCountNumeric&gt;<br>
   * &nbsp;&nbsp;&lt;cac:OrderReference&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:BuyersID&gt;&lt;![CDATA[51409272]]&gt;&lt;/cac:BuyersID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:SellerID&gt;&lt;![CDATA[B82568718]]&gt;&lt;/cac:SellerID&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:OrderReference&gt;<br>
   * &nbsp;&nbsp;&lt;cac:BuyerParty&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Party&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:PartyName&gt;&lt;cbc:Name&gt;&lt;![CDATA[Paul&nbsp;Klein]]&gt;&lt;/cbc:Name&gt;&lt;/cac:PartyName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Address&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;ID&gt;7f000001106709e1bda10000ec419d26&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:PostBox&gt;&lt;/cbc:PostBox&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:StreetName&gt;&lt;![CDATA[Bulbury]]&gt;&lt;/cbc:StreetName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:AdditionalStreetName&gt;&lt;![CDATA[ST]]&gt;&lt;/cbc:AdditionalStreetName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:BuildingName&gt;&lt;![CDATA[]]&gt;&lt;/cbc:BuildingName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:BuildingNumber&gt;&lt;![CDATA[80]]&gt;&lt;/cbc:BuildingNumber&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CityName&gt;&lt;![CDATA[]]&gt;&lt;/cbc:CityName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:PostalZone&gt;&lt;/cbc:PostalZone&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CountrySubentity&gt;&lt;![CDATA[]]&gt;&lt;/cbc:CountrySubentity&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CountrySubentityCode&gt;&lt;/cbc:CountrySubentityCode&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:AddressLine&gt;&lt;![CDATA[]]&gt;&lt;/cbc:AddressLine&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;Country&gt;&lt;![CDATA[]]&gt;&lt;/Country&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Address&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Party&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:AccountsContact&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Name&gt;&lt;![CDATA[]]&gt;&lt;/cbc:Name&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Telephone&gt;&lt;![CDATA[]]&gt;&lt;/cbc:Telephone&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:AccountsContact&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:BuyerParty&gt;<br>
   * &nbsp;&nbsp;&lt;cac:SellerParty&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Party&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:PartyName&gt;&lt;cbc:Name&gt;&lt;![CDATA[Know&nbsp;Gate&nbsp;Ltd.]]&gt;&lt;/cbc:Name&gt;&lt;/cac:PartyName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Address&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;ID&gt;7f0000011067057c4ef100008c688128&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:StreetName&gt;&lt;![CDATA[Wesleyan]]&gt;&lt;/cbc:StreetName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:AdditionalStreetName&gt;&lt;![CDATA[ST]]&gt;&lt;/cbc:AdditionalStreetName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:BuildingName&gt;&lt;![CDATA[]]&gt;&lt;/cbc:BuildingName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:BuildingNumber&gt;&lt;![CDATA[107]]&gt;&lt;/cbc:BuildingNumber&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CityName&gt;&lt;![CDATA[Boston]]&gt;&lt;/cbc:CityName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:PostalZone&gt;&lt;/cbc:PostalZone&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CountrySubentity&gt;&lt;![CDATA[MA]]&gt;&lt;/cbc:CountrySubentity&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CountrySubentityCode&gt;&lt;/cbc:CountrySubentityCode&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:AddressLine&gt;&lt;![CDATA[]]&gt;&lt;/cbc:AddressLine&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;Country&gt;&lt;![CDATA[United&nbsp;States]]&gt;&lt;/Country&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Address&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Party&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:AccountsContact&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Name&gt;&lt;![CDATA[Charles&nbsp;Robertson]]&gt;&lt;/cbc:Name&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Telephone&gt;&lt;![CDATA[1-800callcharles]]&gt;&lt;/cbc:Telephone&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:AccountsContact&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:SellerParty&gt;<br>
   * &nbsp;&nbsp;&lt;cac:Delivery&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:DeliveryAddress&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;ID&gt;7f00000110670211e12100002a4874df&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:StreetName&gt;&lt;![CDATA[Yokohama]]&gt;&lt;/cbc:StreetName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:AdditionalStreetName&gt;&lt;![CDATA[ST]]&gt;&lt;/cbc:AdditionalStreetName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:BuildingName&gt;&lt;![CDATA[]]&gt;&lt;/cbc:BuildingName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:BuildingNumber&gt;&lt;![CDATA[1310]]&gt;&lt;/cbc:BuildingNumber&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CityName&gt;&lt;![CDATA[]]&gt;&lt;/cbc:CityName&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:PostalZone&gt;&lt;/cbc:PostalZone&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CountrySubentity&gt;&lt;![CDATA[]]&gt;&lt;/cbc:CountrySubentity&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:CountrySubentityCode&gt;&lt;/cbc:CountrySubentityCode&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:AddressLine&gt;&lt;![CDATA[]]&gt;&lt;/cbc:AddressLine&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;Country&gt;&lt;![CDATA[us]]&gt;&lt;/Country&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:DeliveryAddress&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:Delivery&gt;<br>
   * &nbsp;&nbsp;&lt;cac:DespatchLine&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;ID&gt;1&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:DeliveredQuantity&gt;1&lt;/cbc:DeliveredQuantity&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Item&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Description&gt;&lt;![CDATA[Tux&nbsp;Earrings]]&gt;&lt;/cbc:Description&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Item&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:DespatchLine&gt;<br>
   * &nbsp;&nbsp;&lt;cac:DespatchLine&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;ID&gt;2&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:DeliveredQuantity&gt;1&lt;/cbc:DeliveredQuantity&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:LineExtensionAmount amountCurrencyCodeListVersionID="0.3" amountCurrencyID="978"&gt;999.99&lt;/cbc:LineExtensionAmount&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:TaxTotalAmount amountCurrencyCodeListVersionID="0.3" amountCurrencyID="978"&gt;0.16&lt;/cbc:TaxTotalAmount&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Item&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Description&gt;&lt;![CDATA[Tux&nbsp;Pendant]]&gt;&lt;/cbc:Description&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Item&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;BasePrice amountCurrencyCodeListVersionID="0.3" amountCurrencyID="978"&gt;999.99&lt;/BasePrice&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:DespatchLine&gt;<br>
   * &lt;/DespatchAdvice&gt;
   * @throws IllegalStateException if invoice lines are not loaded or buyer is not set or seller is not set
   * @see <a href="http://docs.oasis-open.org/ubl/cd-UBL-1.0/">OASIS Universal Business Language 1.0</a>
   */
  public String toXML(JDCConnection oConn, String sLocale) throws IllegalStateException {

    if (oLines==null) throw new IllegalStateException("DespacthAdvice.toXML() Invoice lines not loaded");
    if (oBuyer==null) throw new IllegalStateException("DespacthAdvice.toXML() Buyer party not set");
    if (oSeller==null) throw new IllegalStateException("DespacthAdvice.toXML() Seller party not set");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DespatchAdvice.toXML()");
      DebugFile.incIdent();
    }

    final int iLineCount = oLines.getRowCount();
    StringBuffer oBfr = new StringBuffer();

    oBfr.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    oBfr.append("<DespatchAdvice xmlns:cbc=\"urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0\" xmlns:cac=\"urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.0\" xmlns:cur=\"urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n");
    // xmlns=\"urn:oasis:names:specification:ubl:schema:xsd:Invoice-1.0\" xsi:schemaLocation=\"urn:oasis:names:specification:ubl:schema:xsd:Invoice-1.0 http://docs.oasis-open.org/ubl/cd-UBL-1.0/xsd/maindoc/UBL-Invoice-1.0.xsd\"
    oBfr.append("  <ID>"+String.valueOf(getInt(DB.pg_despatch))+"</ID>\n");
    oBfr.append("  <GUID>"+getString(DB.gu_despatch)+"</GUID>\n");
    if (isNull(DB.dt_delivered))
      oBfr.append("  <cbc:IssueDate/>\n");
    else
      oBfr.append("  <cbc:IssueDate>"+getDateShort(DB.dt_delivered)+"</cbc:IssueDate>\n");
    oBfr.append("  <DocumentStatusCode>"+getStringNull(DB.id_status,"")+"</DocumentStatusCode>\n");
    oBfr.append("  <cbc:Note><![CDATA["+getStringNull(DB.tx_ship_notes,"")+"]]></cbc:Note>\n");
    oBfr.append("  <LineItemCountNumeric>"+String.valueOf(iLineCount)+"</LineItemCountNumeric>\n");

    oBfr.append("  <cac:OrderReference>\n");
    oBfr.append("    <cac:BuyersID><![CDATA["+getStringNull(DB.id_legal,oBuyer.getStringNull(DB.id_legal,oBuyer.getStringNull(DB.sn_passport,"")))+"]]></cac:BuyersID>\n");
    oBfr.append("    <cac:SellerID><![CDATA["+oSeller.getStringNull(DB.id_legal,oSeller.getStringNull(DB.sn_passport,""))+"]]></cac:SellerID>\n");
    String[] aOrders = getOrders();
    Order oOrdr;
    if (aOrders!=null) {
      try {
        oOrdr = new Order(oConn, aOrders[0]);
        if (oOrdr.isNull(DB.dt_invoiced))
          oBfr.append("    <cbc:IssueDate/>\n");
        else
          oBfr.append("    <cbc:IssueDate>"+oOrdr.getDateShort(DB.dt_invoiced)+"</cbc:IssueDate>\n");
        oBfr.append("    <GUID>"+oOrdr.getString(DB.gu_order)+"</GUID>\n");
      } catch (Exception ignore) {}
    } // fi
    oBfr.append("  </cac:OrderReference>\n");
    if (DebugFile.trace) DebugFile.writeln("Writting BuyerParty...");
    oBfr.append("  <cac:BuyerParty>\n");
    oBfr.append("    <cac:Party>\n");
    if (oBuyer.isNull(DB.gu_contact))
      oBfr.append("      <cac:PartyName><cbc:Name><![CDATA["+oBuyer.getString(DB.nm_legal)+"]]></cbc:Name></cac:PartyName>\n");
    else
      oBfr.append("      <cac:PartyName><cbc:Name><![CDATA["+oBuyer.getStringNull(DB.tx_name,"")+" "+oBuyer.getStringNull(DB.tx_surname,"")+"]]></cbc:Name></cac:PartyName>\n");
    oBfr.append("      <cac:Address>\n");
    if (oBillAddr==null) {
      oBfr.append("        <ID/>\n");
      oBfr.append("        <cbc:PostBox/>\n");
      oBfr.append("        <cbc:StreetName/>\n");
      oBfr.append("        <cbc:AdditionalStreetName/>\n");
      oBfr.append("        <cbc:BuildingName/>\n");
      oBfr.append("        <cbc:BuildingNumber/>\n");
      oBfr.append("        <cbc:CityName/>\n");
      oBfr.append("        <cbc:PostalZone/>\n");
      oBfr.append("        <cbc:CountrySubentity/>\n");
      oBfr.append("        <cbc:CountrySubentityCode/>\n");
      oBfr.append("        <cbc:AddressLine/>\n");
      oBfr.append("        <Country/>\n");
    } else {
      oBfr.append("        <ID>"+oBillAddr.getString(DB.gu_address)+"</ID>\n");
      oBfr.append("        <cbc:PostBox>"+oBillAddr.getStringNull(DB.po_box,"")+"</cbc:PostBox>\n");
      oBfr.append("        <cbc:StreetName><![CDATA["+oBillAddr.getStringNull(DB.nm_street,"")+"]]></cbc:StreetName>\n");
      oBfr.append("        <cbc:AdditionalStreetName><![CDATA["+oBillAddr.getStringNull(DB.tp_street,"")+"]]></cbc:AdditionalStreetName>\n");
      oBfr.append("        <cbc:BuildingName><![CDATA["+oBillAddr.getStringNull(DB.tx_addr2,"")+"]]></cbc:BuildingName>\n");
      oBfr.append("        <cbc:BuildingNumber><![CDATA["+oBillAddr.getStringNull(DB.nu_street,"")+"]]></cbc:BuildingNumber>\n");
      oBfr.append("        <cbc:CityName><![CDATA["+oBillAddr.getStringNull(DB.mn_city,"")+"]]></cbc:CityName>\n");
      oBfr.append("        <cbc:PostalZone>"+oBillAddr.getStringNull(DB.zipcode,"")+"</cbc:PostalZone>\n");
      oBfr.append("        <cbc:CountrySubentity><![CDATA["+oBillAddr.getStringNull(DB.nm_state,"")+"]]></cbc:CountrySubentity>\n");
      oBfr.append("        <cbc:CountrySubentityCode>"+oBillAddr.getStringNull(DB.id_state,"")+"</cbc:CountrySubentityCode>\n");
      oBfr.append("        <cbc:AddressLine><![CDATA["+oBillAddr.getStringNull(DB.tx_addr1,"")+"]]></cbc:AddressLine>\n");
      oBfr.append("        <Country><![CDATA["+oBillAddr.getStringNull(DB.nm_country,"").trim()+"]]></Country>\n");
    }
    oBfr.append("      </cac:Address>\n");
    oBfr.append("    </cac:Party>\n");
    oBfr.append("    <cac:AccountsContact>\n");
    if (oBillAddr==null) {
      oBfr.append("      <cbc:Name/>\n");
      oBfr.append("      <cbc:Telephone/>\n");
    } else {
      oBfr.append("      <cbc:Name><![CDATA["+oBuyer.getStringNull(DB.contact_person,"")+"]]></cbc:Name>\n");
      oBfr.append("      <cbc:Telephone><![CDATA["+oBuyer.getStringNull(DB.direct_phone,oBuyer.getStringNull(DB.work_phone,""))+"]]></cbc:Telephone>\n");
    }
    oBfr.append("    </cac:AccountsContact>\n");
    oBfr.append("  </cac:BuyerParty>\n");
    if (DebugFile.trace) DebugFile.writeln("Writting SellerParty...");
    oBfr.append("  <cac:SellerParty>\n");
    oBfr.append("    <cac:Party>\n");
    oBfr.append("      <cac:PartyName><cbc:Name><![CDATA["+oSeller.getStringNull(DB.nm_company,oSeller.getStringNull(DB.nm_shop,""))+"]]></cbc:Name></cac:PartyName>\n");
    oBfr.append("      <cac:Address>\n");
    if (oBillAddr==null) {
      oBfr.append("        <ID/>\n");
      oBfr.append("        <cbc:PostBox/>\n");
      oBfr.append("        <cbc:StreetName/>\n");
      oBfr.append("        <cbc:AdditionalStreetName/>\n");
      oBfr.append("        <cbc:BuildingName/>\n");
      oBfr.append("        <cbc:BuildingNumber/>\n");
      oBfr.append("        <cbc:CityName/>\n");
      oBfr.append("        <cbc:PostalZone/>\n");
      oBfr.append("        <cbc:CountrySubentity/>\n");
      oBfr.append("        <cbc:CountrySubentityCode/>\n");
      oBfr.append("        <cbc:AddressLine/>\n");
      oBfr.append("        <Country/>\n");
    } else {
      oBfr.append("        <ID>"+oSeller.getStringNull(DB.gu_shop, oSeller.getStringNull(DB.gu_address, ""))+"</ID>\n");
      oBfr.append("        <cbc:StreetName><![CDATA["+oSeller.getStringNull(DB.nm_street,"")+"]]></cbc:StreetName>\n");
      oBfr.append("        <cbc:AdditionalStreetName><![CDATA["+oSeller.getStringNull(DB.tp_street,"")+"]]></cbc:AdditionalStreetName>\n");
      oBfr.append("        <cbc:BuildingName><![CDATA["+oSeller.getStringNull(DB.tx_addr2,"")+"]]></cbc:BuildingName>\n");
      oBfr.append("        <cbc:BuildingNumber><![CDATA["+oSeller.getStringNull(DB.nu_street,"")+"]]></cbc:BuildingNumber>\n");
      oBfr.append("        <cbc:CityName><![CDATA["+oSeller.getStringNull(DB.mn_city,"")+"]]></cbc:CityName>\n");
      oBfr.append("        <cbc:PostalZone>"+oSeller.getStringNull(DB.zipcode,"")+"</cbc:PostalZone>\n");
      oBfr.append("        <cbc:CountrySubentity><![CDATA["+oSeller.getStringNull(DB.nm_state,"")+"]]></cbc:CountrySubentity>\n");
      oBfr.append("        <cbc:CountrySubentityCode>"+oSeller.getStringNull(DB.id_state,"")+"</cbc:CountrySubentityCode>\n");
      oBfr.append("        <cbc:AddressLine><![CDATA["+oSeller.getStringNull(DB.tx_addr1,"")+"]]></cbc:AddressLine>\n");
      oBfr.append("        <Country><![CDATA["+oSeller.getStringNull(DB.nm_country,"").trim()+"]]></Country>\n");
    }
    oBfr.append("      </cac:Address>\n");
    oBfr.append("    </cac:Party>\n");
    oBfr.append("    <cac:AccountsContact>\n");
    oBfr.append("      <cbc:Name><![CDATA["+oSeller.getStringNull(DB.contact_person,"")+"]]></cbc:Name>\n");
    oBfr.append("      <cbc:Telephone><![CDATA["+oSeller.getStringNull(DB.direct_phone,oSeller.getStringNull(DB.work_phone,""))+"]]></cbc:Telephone>\n");
    oBfr.append("    </cac:AccountsContact>\n");
    oBfr.append("  </cac:SellerParty>\n");
    if (DebugFile.trace) DebugFile.writeln("Writting Delivery...");
    oBfr.append("  <cac:Delivery>\n");
    if (!isNull(DB.dt_promised))
      oBfr.append("    <cbc:RequestedDeliveryDateTime>"+getDateShort(DB.dt_promised)+"T"+getTime(DB.dt_promised)+"</cbc:RequestedDeliveryDateTime>\n");
    if (oShipAddr!=null) {
      oBfr.append("    <cac:DeliveryAddress>\n");
      oBfr.append("        <ID>"+oShipAddr.getString(DB.gu_address)+"</ID>\n");
      oBfr.append("        <cbc:StreetName><![CDATA["+oShipAddr.getStringNull(DB.nm_street,"")+"]]></cbc:StreetName>\n");
      oBfr.append("        <cbc:AdditionalStreetName><![CDATA["+oShipAddr.getStringNull(DB.tp_street,"")+"]]></cbc:AdditionalStreetName>\n");
      oBfr.append("        <cbc:BuildingName><![CDATA["+oShipAddr.getStringNull(DB.tx_addr2,"")+"]]></cbc:BuildingName>\n");
      oBfr.append("        <cbc:BuildingNumber><![CDATA["+oShipAddr.getStringNull(DB.nu_street,"")+"]]></cbc:BuildingNumber>\n");
      oBfr.append("        <cbc:CityName><![CDATA["+oShipAddr.getStringNull(DB.mn_city,"")+"]]></cbc:CityName>\n");
      oBfr.append("        <cbc:PostalZone>"+oShipAddr.getStringNull(DB.zipcode,"")+"</cbc:PostalZone>\n");
      oBfr.append("        <cbc:CountrySubentity><![CDATA["+oShipAddr.getStringNull(DB.nm_state,"")+"]]></cbc:CountrySubentity>\n");
      oBfr.append("        <cbc:CountrySubentityCode>"+oShipAddr.getStringNull(DB.id_state,"")+"</cbc:CountrySubentityCode>\n");
      oBfr.append("        <cbc:AddressLine><![CDATA["+oShipAddr.getStringNull(DB.tx_addr1,"")+"]]></cbc:AddressLine>\n");
      oBfr.append("        <Country><![CDATA["+oShipAddr.getStringNull(DB.id_country,"").trim()+"]]></Country>\n");
      oBfr.append("    </cac:DeliveryAddress>\n");
    }
    oBfr.append("  </cac:Delivery>\n");

    if (DebugFile.trace) DebugFile.writeln("Writting TaxTotal...");
    oBfr.append("  <cac:TaxTotal>\n");
    oBfr.append("    <cbc:TotalTaxAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">");
    oBfr.append(getDecimalFormated(DB.im_taxes));
    oBfr.append("</cbc:TotalTaxAmount>\n");
    oBfr.append("  </cac:TaxTotal>\n");
    if (DebugFile.trace) DebugFile.writeln("Writting LegalTotal...");
    oBfr.append("  <cac:LegalTotal>\n");
    oBfr.append("    <cbc:LineExtensionTotalAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">");
    oBfr.append(getDecimalFormated(DB.im_subtotal));
    oBfr.append("    </cbc:LineExtensionTotalAmount>\n");
    oBfr.append("    <cbc:TaxInclusiveTotalAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">");
    oBfr.append(getDecimalFormated(DB.im_total));
    oBfr.append("</cbc:TaxInclusiveTotalAmount>\n");
    oBfr.append("  </cac:LegalTotal>\n");
    
    for (int l=0; l<iLineCount; l++) {
      if (DebugFile.trace) DebugFile.writeln("Writting DespatchLine "+String.valueOf(l+1)+"...");
      oBfr.append("  <cac:DespatchLine>\n");
      oBfr.append("    <ID>"+String.valueOf(l+1)+"</ID>\n");
      float fQuantity = oLines.getFloat(DB.nu_quantity,l);
      if (fQuantity == (long) fQuantity)
        oBfr.append("    <cbc:DeliveredQuantity>"+String.valueOf((long)fQuantity)+"</cbc:DeliveredQuantity>\n");
      else
        oBfr.append("    <cbc:DeliveredQuantity>"+String.valueOf(fQuantity)+"</cbc:DeliveredQuantity>\n");
      oBfr.append("    <cbc:LineExtensionAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">"+oLines.getDecimalFormated(DB.pr_total,l,getCurrencyFormat())+"</cbc:LineExtensionAmount>\n");
	  if (!oLines.isNull(DB.pct_tax_rate,l)) {
        float fTaxRate = oLines.getFloat(DB.pct_tax_rate,l);
        if (0f==fTaxRate) {
          oBfr.append("    <cbc:TaxTotalAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">"+formatCurrency(BigDecimal.ZERO)+"</cbc:TaxTotalAmount>\n");
        } else if (oLines.isNull(DB.is_tax_included,l)) {          
          oBfr.append("    <cbc:TaxTotalAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">"+formatCurrency(oLines.getDecimal(DB.pr_total,l).multiply(new BigDecimal(fTaxRate)))+"</cbc:TaxTotalAmount>\n");
        } else if (oLines.getShort(DB.is_tax_included,l)==(short)0) {
          oBfr.append("    <cbc:TaxTotalAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">"+formatCurrency(oLines.getDecimal(DB.pr_total,l).multiply(new BigDecimal(fTaxRate)))+"</cbc:TaxTotalAmount>\n"); 
        } else {		  
          oBfr.append("    <cbc:TaxTotalAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">"+formatCurrency(oLines.getDecimal(DB.pr_total,l).multiply(new BigDecimal(1f-(1f/(1f+fTaxRate)))))+"</cbc:TaxTotalAmount>\n"); 
        }
	  } // fi (pct_tax_rate)
      oBfr.append("    <cac:Item>\n");
      oBfr.append("      <cbc:Description><![CDATA["+oLines.getString(DB.nm_product,l)+"]]></cbc:Description>\n");
      oBfr.append("      <CatalogueItemIdentification><![CDATA["+oLines.getString(DB.id_ref,l)+"]]></CatalogueItemIdentification>\n");
	  if (!oLines.isNull(DB.pct_tax_rate,l)) {
        oBfr.append("      <TaxCategory><ID>void</ID><Percent>"+formatPercentage(oLines.getFloat(DB.pct_tax_rate,l))+"</Percent><TaxScheme></TaxScheme></TaxCategory>\n");
	  }
      oBfr.append("    </cac:Item>\n");
      if (oLines.isNull(DB.pr_sale,l))
        oBfr.append("    <BasePrice/>\n");
      else
        oBfr.append("    <BasePrice>"+oLines.getDecimalFormated(DB.pr_sale,l,getCurrencyFormat())+"</BasePrice>\n");
      oBfr.append("  </cac:DespatchLine>\n");
    }
    oBfr.append("  </DespatchAdvice>\n");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DespatchAdvice.toXML()");
    }

    return oBfr.toString();
  } // toXML()

  //----------------------------------------------------------------------------

  /**
   * Get next value for field pg_despatch in a given WorkArea
   * @param oConn JDCConnection JDBC Connection
   * @param sGuWorkArea String WorkArea GUID
   * @return int Next unused despatch note number
   * @throws SQLException
   */
  public static int nextVal(JDCConnection oConn, String sGuWorkArea)
    throws SQLException {
    boolean bNext;
    int iNextDispatch = 1;
    String sSQL = "";
    PreparedStatement oSnxt = null;
    ResultSet oRnxt = null;

    sSQL = "SELECT "+DB.pg_despatch+","+DB.gu_workarea+" FROM "+DB.k_despatch_next+ " WHERE "+DB.gu_workarea+"=? ";
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      sSQL += "FOR UPDATE OF "+DB.k_despatch_next;
    } if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
      sSQL += "FOR UPDATE OF "+DB.pg_despatch;
    }

    try {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE)");
      oSnxt = oConn.prepareStatement(sSQL,ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE);
      oSnxt.setObject(1, sGuWorkArea, Types.CHAR);
      oRnxt = oSnxt.executeQuery();
      bNext = oRnxt.next();
      if (bNext) {
        iNextDispatch = oRnxt.getInt(1);
        oRnxt.updateInt(DB.pg_despatch, ++iNextDispatch);
        oRnxt.updateRow();
      }
      oRnxt.close();
      oRnxt=null;
      oSnxt.close();
      oSnxt=null;
      if (!bNext) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE)");
        sSQL = "INSERT INTO "+DB.k_despatch_next+" ("+DB.gu_workarea+","+DB.pg_despatch+") VALUES (?,?)";
        oSnxt = oConn.prepareStatement(sSQL);
        oSnxt.setObject(1, sGuWorkArea, Types.CHAR);
        oSnxt.setInt(2, iNextDispatch);
        oSnxt.executeUpdate();
        oSnxt.close();
      }
    } catch (SQLException sqle) {
      if (oRnxt!=null) oRnxt.close();
      if (oSnxt!=null) oSnxt.close();
      throw new SQLException (sqle.getMessage()+" "+sSQL,sqle.getSQLState(),sqle.getErrorCode());
    }
    return iNextDispatch;
  } // nextVal

  // **********************************************************
  // Public Constants

  public static final short ClassId = 42;

}
