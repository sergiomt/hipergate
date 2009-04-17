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

import java.util.ListIterator;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DBColumn;

/**
 * <p>Shopping Order.</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class Order extends AbstractOrder {

  private Address oShipAddr;
  private Address oBillAddr;
  private String sGuDespatchAdvice;
  private String sGuInvoice;

  //----------------------------------------------------------------------------

  /**
   * Create empty Order
   */
  public Order() {
    super(DB.k_orders, DB.k_order_lines, DB.gu_order, "Order");
    oBillAddr=oShipAddr=null;
    sGuDespatchAdvice=sGuInvoice=null;
  }

  /**
   * Create Order and set its GUID
   */
  public Order(String sOrderId) {
    super(DB.k_orders, DB.k_order_lines, DB.gu_order, "Order");
    oBillAddr=oShipAddr=null;
    sGuDespatchAdvice=sGuInvoice=null;
    put(DB.gu_order, sOrderId);
  }

  /**
   * <p>Load Order from database including all its lines</p>
   * @param oConn Database Connection
   * @param sOrderId Order GUID
   * @throws SQLException
   */
  public Order(JDCConnection oConn, String sOrderId) throws SQLException {
    super(DB.k_orders, DB.k_order_lines, DB.gu_order, "Order");
    oBillAddr=oShipAddr=null;
    sGuDespatchAdvice=sGuInvoice=null;
    load(oConn, new Object[]{sOrderId});
  }

  // ---------------------------------------------------------------------------

  /**
   * Load Order with its associated Addresses
   * @param oConn JDCConnection
   * @param PKVals Array with a single element Object[1]{(String)gu_order}
   * @return boolean <b>true</b> is Order was found, <b>false</b> otherwise
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Order.load([Connection], Object[])");
      DebugFile.incIdent();
    }

    boolean bRetVal = super.load(oConn, PKVals);
    if (bRetVal) {
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

      if (DebugFile.trace) DebugFile.writeln("SELECT "+DB.gu_despatch+" FROM "+DB.k_x_orders_despatch+" WHERE "+DB.gu_order+"='"+PKVals[0]+"'");

      oStmt = oConn.prepareStatement("SELECT "+DB.gu_despatch+" FROM "+DB.k_x_orders_despatch+" WHERE "+DB.gu_order+"=?",
      								 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  oStmt.setObject(1, PKVals[0], java.sql.Types.CHAR);
	  oRSet = oStmt.executeQuery();
	  if (oRSet.next())
	  	sGuDespatchAdvice = oRSet.getString(1);
	  oRSet.close();
	  oStmt.close();

      if (DebugFile.trace) DebugFile.writeln("SELECT "+DB.gu_invoice+" FROM "+DB.k_x_orders_invoices+" WHERE "+DB.gu_order+"='"+PKVals[0]+"'");

      oStmt = oConn.prepareStatement("SELECT "+DB.gu_invoice+" FROM "+DB.k_x_orders_invoices+" WHERE "+DB.gu_order+"=?",
      								 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  oStmt.setObject(1, PKVals[0], java.sql.Types.CHAR);
	  oRSet = oStmt.executeQuery();
	  if (oRSet.next())
	  	sGuInvoice = oRSet.getString(1);
	  oRSet.close();
	  oStmt.close();	  
    }	

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Order.load() : "+String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  //----------------------------------------------------------------------------

  /**
   * Load Order with its associated Addresses
   * @param oConn JDCConnection
   * @param sGuOrder Order GUID
   * @return boolean <b>true</b> is Order was found, <b>false</b> otherwise
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, String sGuOrder) throws SQLException {
    return load (oConn, new Object[]{sGuOrder});
  }
  
  //----------------------------------------------------------------------------

  /**
   * Store Order
   * @param oConn Database Connection
   * If gu_order is null then a new GUID is automatically assigned.<br>
   * If pg_order is null then next value for sequence seq_k_orders is automatically assigned.<br>
   * If id_legal is <b>null</b> and gu_contact or gu_company is provided for customer then that one is automatically set.<br>
   * dt_modified field is set to current date.<br>
   * @throws SQLException
   */
   public boolean store(JDCConnection oConn) throws SQLException {
     java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

     if (!AllVals.containsKey(DB.gu_order))
       put(DB.gu_order, Gadgets.generateUUID());
     else
       replace(DB.dt_modified, dtNow);

     if (!AllVals.containsKey(DB.pg_order))
       put(DB.pg_order, DBBind.nextVal(oConn, "seq_" + DB.k_orders));

     if (!AllVals.containsKey(DB.id_legal)) {
       PreparedStatement oStmt;
       ResultSet oRSet;
       String sLegalId = null;
       if (AllVals.containsKey(DB.gu_contact)) {
         oStmt = oConn.prepareStatement("SELECT "+DB.sn_passport+" FROM "+DB.k_contacts+ " WHERE "+DB.gu_contact+"=?",
                                        ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
         oStmt.setString(1, getString(DB.gu_contact));
         oRSet = oStmt.executeQuery();
         if (oRSet.next())
           sLegalId = oRSet.getString(1);
         oRSet.close();
         oStmt.close();
       } // fi (gu_contact!=null)
       if ((sLegalId==null) && AllVals.containsKey(DB.gu_company)) {
         oStmt = oConn.prepareStatement("SELECT "+DB.id_legal+" FROM "+DB.k_companies+ " WHERE "+DB.gu_company+"=?",
                                        ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
         oStmt.setString(1, getString(DB.gu_company));
         oRSet = oStmt.executeQuery();
         if (oRSet.next())
           sLegalId = oRSet.getString(1);
         oRSet.close();
         oStmt.close();
       }
       if (sLegalId!=null) put(DB.id_legal, sLegalId);
     } // fi

     return super.store(oConn);
   } // store

   //----------------------------------------------------------------------------

   /**
    * <p>Delete Order</p>
    * @param oConn
    * @return
    * @throws SQLException
    */
   public boolean delete (JDCConnection oConn) throws SQLException {
     boolean bRetVal;
     Statement oStmt;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin Order.delete([Connection])");
       DebugFile.incIdent();
     }

     oStmt = oConn.createStatement();

     oStmt.executeUpdate("DELETE FROM " + DB.k_x_orders_invoices + " WHERE " + DB.gu_order + "='" + getString(DB.gu_order) + "'");

     oStmt.executeUpdate("DELETE FROM " + DB.k_x_orders_despatch + " WHERE " + DB.gu_order + "='" + getString(DB.gu_order) + "'");

     if (DebugFile.trace)
       DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_order_lines + " WHERE " + DB.gu_order + "='" + getStringNull(DB.gu_order,"") + "')");

     oStmt.executeUpdate("DELETE FROM " + DB.k_order_lines + " WHERE " + DB.gu_order + "='" + getString(DB.gu_order) + "'");

     oStmt.close();

     bRetVal = super.delete(oConn);

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Order.delete() : " + String.valueOf(bRetVal));
     }

     return bRetVal;
   } // delete

   // ---------------------------------------------------------------------------

   /**
    * Get order line by number
    * @param oConn JDCConnection
    * @param iPgLine int Line number [1..n] as as at k_order_lines.pg_line
    * @return OrderLine or <b>null</b> if no line with such number was found
    * @throws SQLException
    */
   public OrderLine getLine(JDCConnection oConn, int iPgLine) throws SQLException {
     OrderLine oRetVal = new OrderLine();
     if (oRetVal.load(oConn, new Object[]{getStringNull(DB.gu_order,null),new Integer(iPgLine)}))
       return oRetVal;
     else
       return null;
   } // getLine()

   //----------------------------------------------------------------------------

   /**
    * Get Order Lines as a DBSubset
    * @param oConn Database Connection
    * @return A DBSubset with the following columns:<br>
    * <table border=1 cellpadding=4>
    * <tr><td><b>gu_order</b></td><td><b>pg_line</b></td><td><b>gu_product</b></td><td><b>nm_product</b></td><td><b>pr_sale</b></td><td><b>nu_quantity</b></td><td><b>id_unit</b></td><td><b>pr_total</b></td><td><b>pct_tax_rate</b></td><td><b>is_tax_included</b></td><td><b>tx_promotion</b></td><td><b>tx_options</b></td><td><b>gu_item</b></td><td><b>id_ref</b></td></tr>
    * <tr><td>Order GUID</td><td>Line Number</td><td>Product GUID</td><td>Product Name</td><td>Sale Price</td><td>Quantity Ordered</td><td>Unit for quantity</td><td>Total Price</td><td>% of Tax Rate</td><td>1 if tax included</td><td>Promotion Text</td><td>Additional Options</td><td>GUID of ordered item</td></tr>
    * </table>
    * @throws SQLException
    */
   public DBSubset getLines(JDCConnection oConn) throws SQLException {
     oLines = new DBSubset(DB.k_order_lines,
                           DB.gu_order + "," + DB.pg_line + "," +
                           DB.gu_product + "," + DB.nm_product + "," +
                           DB.pr_sale + "," + DB.nu_quantity + "," +
                           DB.id_unit + "," + DB.pr_total + "," +
                           DB.pct_tax_rate + "," + DB.is_tax_included + "," +
                           DB.tx_promotion + "," + DB.tx_options + "," +
                           DB.gu_item + ", '' AS " + DB.id_ref,
                           DB.gu_order + "=? ORDER BY 2", 10);

     oLines.load(oConn, new Object[]{getString(DB.gu_order)});
     
	 DBSubset oProdDetail = new DBSubset (DB.k_products+" p"+","+DB.k_order_lines+" l",
	 									  "p."+DB.gu_product+",p."+DB.id_ref,
	 									  "p."+DB.gu_product+"=l."+DB.gu_product+" AND "+
	 									  "p."+DB.gu_owner+"=? AND "+
	 									  "l."+DB.gu_order + "=?", 50);
     
     int nProdCount = oProdDetail.load(oConn, new Object[]{getString(DB.gu_workarea),getString(DB.gu_order)});
     
     for (int p=0; p<nProdCount; p++) {
       int l = oLines.find(9, oProdDetail.get(0,p));
       if (!oProdDetail.isNull(1,p)) {
         oLines.setElementAt(oProdDetail.get(1,p),13,l);
       }
     } // next
     
     return oLines;
   } // getLines()

  //----------------------------------------------------------------------------

  /**
   * Get despatch advice associated to this order
   * @return GUID of associated despatch advice or <b>null</b>
   * if there is no despatch advice associated with this order
   * at k_x_orders_despatch table.
   * @since 4.0
   */
   
  public String getDespatchAdvice() {
    return sGuDespatchAdvice;
  }

  //----------------------------------------------------------------------------

  /**
   * Get invoice associated to this order
   * @return GUID of associated invoice or <b>null</b>
   * if there is no invoice associated with this order
   * at k_x_orders_invoice table.
   * @since 4.0
   */

  public String getInvoice() {
    return sGuInvoice;
  }
  
  //----------------------------------------------------------------------------

  /**
   * <p>Create a Dispatch Note for this Order</p>
   * The new Dispatch Note is given the same GUID as the current order
   * @param oConn JDCConnection
   * @param bIncludePrices boolean whether or not to save prices at the new Dispatch Order
   * @return Invoice
   * @throws SQLException
   */
  public DespatchAdvice createDespatchAdvice(JDCConnection oConn,
                                         boolean bIncludePrices) throws SQLException {
    DespatchAdvice oDispatch = new DespatchAdvice();
    ListIterator oIter = oDispatch.getTable(oConn).getColumns().listIterator();
    if (bIncludePrices) {
      while (oIter.hasNext()) {
        String sKey = ((DBColumn) oIter.next()).getName();
        if (!isNull(sKey)) oDispatch.put(sKey, get(sKey));
      } // wend
    } else {
      while (oIter.hasNext()) {
        String sKey = (String) oIter.next();
        if (!sKey.equalsIgnoreCase(DB.im_subtotal) && !sKey.equalsIgnoreCase(DB.im_taxes) &&
            !sKey.equalsIgnoreCase(DB.im_shipping) && !sKey.equalsIgnoreCase(DB.im_total) &&
            !sKey.equalsIgnoreCase(DB.im_discount)) {
          if (!isNull(sKey)) oDispatch.put(sKey, get(sKey));
        }
      } // wend
    } // fi (bIncludePrices)
    oDispatch.replace(DB.de_despatch, getString(DB.de_order));
    oDispatch.replace(DB.gu_despatch, getString(DB.gu_order));
    oDispatch.store(oConn);
    Statement oStmt = oConn.createStatement();
    if (bIncludePrices) {
      oStmt.executeUpdate("INSERT INTO "+DB.k_despatch_lines+" ("+DB.gu_despatch+ ","+
                          DB.pg_line+","+DB.gu_product+","+DB.nm_product+","+
                          DB.pr_sale+","+DB.nu_quantity+","+DB.id_unit+","+
                          DB.pr_total+ ","+DB.pct_tax_rate+","+DB.is_tax_included+","+
                          DB.tx_promotion+","+DB.tx_options+","+DB.gu_item+") SELECT "+
                          DB.gu_order+ ","+ DB.pg_line+","+DB.gu_product+","+
                          DB.nm_product+","+ DB.pr_sale+","+DB.nu_quantity+","+
                          DB.id_unit+","+DB.pr_total+ ","+DB.pct_tax_rate+","+
                          DB.is_tax_included+","+ DB.tx_promotion+","+DB.tx_options+","+
                          DB.gu_item+" FROM "+DB.k_order_lines+
                          " WHERE "+DB.gu_order+"='"+getString(DB.gu_order)+"'");
    } else {
      oStmt.executeUpdate("INSERT INTO "+DB.k_despatch_lines+" ("+DB.gu_despatch+","+
                          DB.pg_line+","+DB.nu_quantity+","+DB.id_unit+","+
                          DB.nm_product+","+DB.gu_product+","+DB.gu_item+","+
                          DB.tx_promotion+","+DB.tx_options+") SELECT "+DB.gu_order+","+
                          DB.pg_line+","+DB.nu_quantity+","+DB.id_unit+","+
                          DB.nm_product+","+DB.gu_product+","+DB.gu_item+","+
                          DB.tx_promotion+","+DB.tx_options+" FROM "+DB.k_order_lines+
                          " WHERE "+DB.gu_order+"='"+getString(DB.gu_order)+"'");
    } // fi (bIncludePrices)
    oStmt.close();
    return oDispatch;
  } // createDespatchAdvice

  //----------------------------------------------------------------------------

  /**
   * <p>Create an Invoice for this Order</p>
   * The new Invoice is given the same GUID as the current order
   * @param oConn JDCConnection
   * @return Invoice
   * @throws SQLException
   */
  public Invoice createInvoice(JDCConnection oConn) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Order.createInvoice([Connection])");
      DebugFile.incIdent();
    }
    String sSQL;
    Invoice oInvoice = new Invoice();
    ListIterator oIter = oInvoice.getTable(oConn).getColumns().listIterator();
    while (oIter.hasNext()) {
      String sKey = ((DBColumn) oIter.next()).getName();
      if (!isNull(sKey)) {
        if (DebugFile.trace) DebugFile.writeln("Invoice.put("+sKey+","+get(sKey)+")");
        oInvoice.put(sKey, get(sKey));
      }
    } // wend
    oInvoice.replace(DB.gu_invoice, getString(DB.gu_order));
    oInvoice.store(oConn);
    Statement oStmt = oConn.createStatement();
    sSQL = "INSERT INTO "+DB.k_invoice_lines+" ("+DB.gu_invoice+ ","+
                          DB.pg_line+","+DB.gu_product+","+DB.nm_product+","+
                          DB.pr_sale+","+DB.nu_quantity+","+DB.id_unit+","+
                          DB.pr_total+ ","+DB.pct_tax_rate+","+DB.is_tax_included+","+
                          DB.tx_promotion+","+DB.tx_options+","+DB.gu_item+") SELECT "+
                          DB.gu_order+ ","+ DB.pg_line+","+DB.gu_product+","+
                          DB.nm_product+","+ DB.pr_sale+","+DB.nu_quantity+","+
                          DB.id_unit+","+DB.pr_total+ ","+DB.pct_tax_rate+","+
                          DB.is_tax_included+","+ DB.tx_promotion+","+DB.tx_options+","+
                          DB.gu_item+" FROM "+DB.k_order_lines+
                          " WHERE "+DB.gu_order+"='"+getString(DB.gu_order)+"'";
    if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate("+sSQL+")");
    oStmt.executeUpdate(sSQL);
    oStmt.close();
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Order.createInvoice() : "+oInvoice.getString(DB.gu_invoice));
    }
    return oInvoice;
  } // createInvoice

  //----------------------------------------------------------------------------

  /**
   * <p>Activate an Order</p>
   * For a given WorkArea only one order can be active at a time.
   * @param oConn Database Connection
   * @param sOrderId GUID of Order to Activate
   * @throws SQLException
   */
  public void activate(JDCConnection oConn, String sOrderId) throws SQLException {
    PreparedStatement oUpdt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Order.activate([Connection], " + sOrderId + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(UPDATE " + DB.k_orders + " SET " + DB.bo_active + "=0 WHERE " + DB.gu_workarea + "='" + getStringNull(DB.gu_workarea,"null") + "'");

    oUpdt = oConn.prepareStatement("UPDATE " + DB.k_orders + " SET " + DB.bo_active + "=0 WHERE " + DB.gu_workarea + "=?");
    oUpdt.setString(1, getString(DB.gu_workarea));
    oUpdt.executeUpdate();
    oUpdt.close();

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(UPDATE " + DB.k_orders + " SET " + DB.bo_active + "=1 WHERE " + DB.gu_order + "='" + getStringNull(DB.gu_order,"null") + "'");

    oUpdt = oConn.prepareStatement("UPDATE " + DB.k_orders + " SET " + DB.bo_active + "=1 WHERE " + DB.gu_order + "=?");
    oUpdt.setString(1, getString(DB.gu_order));
    oUpdt.executeUpdate();
    oUpdt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Order.activate()");
    }
  } // activate

  // ---------------------------------------------------------------------------

  /**
   * Whether or not this order has an associated despatch advice
   * @since 4.0
   */
  public boolean despatched() {
    return sGuDespatchAdvice!=null;
  }

  // ---------------------------------------------------------------------------

  /**
   * Whether or not this order has an associated invoice
   * @since 4.0
   */
  public boolean invoiced() {
    return sGuInvoice!=null;
  }
  
  // ---------------------------------------------------------------------------

  /**
   * <p>Get order as an XML document</p>
   * Character encoding is set to UTF-8
   * @return An XML String formatted according to OASIS Universal Universal Business Language Specification
   * @throws IllegalStateException if order lines are not loaded or buyer is not set or seller is not set
   * @see <a href="http://docs.oasis-open.org/ubl/cd-UBL-1.0/">OASIS Universal Business Language 1.0</a>
   */

  public String toXML() throws IllegalStateException {
    JDCConnection oConn = null;
    return toXML (oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get order as an XML document</p>
   * Character encoding is set to UTF-8
   * @return An XML String formatted according to OASIS Universal Universal Business Language Specification
   * @throws IllegalStateException if order lines are not loaded or buyer is not set or seller is not set
   * @see <a href="http://docs.oasis-open.org/ubl/cd-UBL-1.0/">OASIS Universal Business Language 1.0</a>
   */

  public String toXML(String sIdent, String sDelim) throws IllegalStateException {
    JDCConnection oConn = null;
    return toXML (oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get order as an XML document</p>
   * Character encoding is set to UTF-8
   * @return An XML String formatted according to OASIS Universal Universal Business Language Specification
   * @throws IllegalStateException if order lines are not loaded or buyer is not set or seller is not set
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
   * &lt;Order&nbsp;xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0"&nbsp;xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.0"&nbsp;xmlns:cur="urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0"&nbsp;xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:BuyersID&gt;&lt;![CDATA[8574922]]&gt;&lt;/cac:BuyersID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:SellerID&gt;&lt;![CDATA[B82568718]]&gt;&lt;/cac:SellerID&gt;<br>
   * &nbsp;&nbsp;&lt;ID&gt;1000000000&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&lt;GUID&gt;7f000001106a7371a7d10000095a8c5e&lt;/GUID&gt;<br>
   * &nbsp;&nbsp;&lt;cbc:IssueDate/&gt;<br>
   * &nbsp;&nbsp;&lt;cbc:Note&gt;&lt;![CDATA[]]&gt;&lt;/cbc:Note&gt;<br>
   * &nbsp;&nbsp;&lt;TransactionCurrencyCode&gt;840&lt;/TransactionCurrencyCode&gt;<br>
   * &nbsp;&nbsp;&lt;cbc:TotalTaxAmount&nbsp;amountCurrencyCodeListVersionID="0.3"&nbsp;amountCurrencyID="840"&gt;&lt;/cbc:TotalTaxAmount&gt;<br>
   * &nbsp;&nbsp;&lt;cbc:LineExtensionTotalAmount&nbsp;amountCurrencyCodeListVersionID="0.3"&nbsp;amountCurrencyID="840"&gt;&lt;/cbc:LineExtensionTotalAmount&gt;<br>
   * &nbsp;&nbsp;&lt;LineItemCountNumeric&gt;2&lt;/LineItemCountNumeric&gt;<br>
   * &nbsp;&nbsp;&lt;DocumentStatusCode&gt;RECEIVED&lt;/DocumentStatusCode&gt;<br>
   * &nbsp;&nbsp;&lt;LineItemCountNumeric&gt;2&lt;/LineItemCountNumeric&gt;<br>
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
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Name&gt;&lt;![CDATA[]]&gt;&lt;/cbc:Name&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Telephone&gt;&lt;![CDATA[]]&gt;&lt;/cbc:Telephone&gt;<br>
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
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;DestinationCountry&gt;us&lt;/DestinationCountry&gt;<br>
   * &nbsp;&nbsp;&lt;cac:OrderLine&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;ID&gt;1&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:DeliveredQuantity&gt;1&lt;/cbc:DeliveredQuantity&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Item&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Description&gt;&lt;![CDATA[Tux&nbsp;Earrings]]&gt;&lt;/cbc:Description&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Item&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:OrderLine&gt;<br>
   * &nbsp;&nbsp;&lt;cac:OrderLine&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;ID&gt;2&lt;/ID&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:DeliveredQuantity&gt;1&lt;/cbc:DeliveredQuantity&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cac:Item&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:Description&gt;&lt;![CDATA[Tux&nbsp;Pendant]]&gt;&lt;/cbc:Description&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;/cac:Item&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:OrderLine&gt;<br>
   * &nbsp;&nbsp;&lt;cac:PaymentMeans&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;PaymentMeansCode&gt;T&lt;/PaymentMeansCode&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;cbc:DuePaymentDate&gt;2005-09-30&lt;/cbc:DuePaymentDate&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;CardAccount&gt;&lt;/CardAccount&gt;<br>
   * &nbsp;&nbsp;&nbsp;&nbsp;&lt;PayerFinancialAccount&gt;00101234990123456789&lt;/PayerFinancialAccount&gt;<br>
   * &nbsp;&nbsp;&lt;/cac:PaymentMeans&gt;<br>
   * &lt;/Order&gt;
   * @throws IllegalStateException if invoice lines are not loaded or buyer is not set or seller is not set
   * @see <a href="http://docs.oasis-open.org/ubl/cd-UBL-1.0/">OASIS Universal Business Language 1.0</a>
   */
  public String toXML(JDCConnection oConn, String sLocale) throws IllegalStateException {

    if (oLines==null) throw new IllegalStateException("Order.toXML() Invoice lines not loaded");
    if (oBuyer==null) throw new IllegalStateException("Order.toXML() Buyer party not set");
    if (oSeller==null) throw new IllegalStateException("Order.toXML() Seller party not set");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Order.toXML([Connection]"+sLocale+")");
      DebugFile.incIdent();
    }

    final int iLineCount = oLines.getRowCount();
    StringBuffer oBfr = new StringBuffer();

    oBfr.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    oBfr.append("<Order xmlns:cbc=\"urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0\" xmlns:cac=\"urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.0\" xmlns:cur=\"urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n");
    // xmlns=\"urn:oasis:names:specification:ubl:schema:xsd:Invoice-1.0\" xsi:schemaLocation=\"urn:oasis:names:specification:ubl:schema:xsd:Invoice-1.0 http://docs.oasis-open.org/ubl/cd-UBL-1.0/xsd/maindoc/UBL-Invoice-1.0.xsd\"
    oBfr.append("    <cac:BuyersID><![CDATA["+getStringNull(DB.id_legal,oBuyer.getStringNull(DB.id_legal,oBuyer.getStringNull(DB.sn_passport,"")))+"]]></cac:BuyersID>\n");
    oBfr.append("    <cac:SellerID><![CDATA["+oSeller.getStringNull(DB.id_legal,oSeller.getStringNull(DB.sn_passport,""))+"]]></cac:SellerID>\n");
    oBfr.append("  <ID>"+String.valueOf(getInt(DB.pg_order))+"</ID>\n");
    oBfr.append("  <GUID>"+getString(DB.gu_order)+"</GUID>\n");
    if (isNull(DB.dt_invoiced))
      oBfr.append("  <cbc:IssueDate/>\n");
    else
      oBfr.append("  <cbc:IssueDate>"+getDateShort(DB.dt_invoiced)+"</cbc:IssueDate>\n");
    oBfr.append("  <cbc:Note><![CDATA["+getStringNull(DB.tx_ship_notes,"")+"]]></cbc:Note>\n");
    oBfr.append("  <TransactionCurrencyCode>"+getString(DB.id_currency)+"</TransactionCurrencyCode>\n");
    oBfr.append("  <cbc:TotalTaxAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">"+getDecimalFormated(DB.im_taxes)+"</cbc:TotalTaxAmount>\n");
    oBfr.append("  <cbc:LineExtensionTotalAmount amountCurrencyCodeListVersionID=\"0.3\" amountCurrencyID=\""+getString(DB.id_currency)+"\">"+getDecimalFormated(DB.im_subtotal)+"</cbc:LineExtensionTotalAmount>\n");
    oBfr.append("  <LineItemCountNumeric>"+String.valueOf(iLineCount)+"</LineItemCountNumeric>\n");

    oBfr.append("  <DocumentStatusCode>"+getStringNull(DB.id_status,"")+"</DocumentStatusCode>\n");
    oBfr.append("  <LineItemCountNumeric>"+String.valueOf(iLineCount)+"</LineItemCountNumeric>\n");

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
    if (oShipAddr!=null) {
      oBfr.append("    <DestinationCountry>"+oShipAddr.getStringNull(DB.id_country,"").trim()+"</DestinationCountry>\n");
    }
    for (int l=0; l<iLineCount; l++) {
      if (DebugFile.trace) DebugFile.writeln("Writting OrderLine "+String.valueOf(l+1)+"...");
      oBfr.append("  <cac:OrderLine>\n");
      oBfr.append("    <ID>"+String.valueOf(l+1)+"</ID>\n");
      float fQuantity = oLines.getFloat(DB.nu_quantity,l);
      if (fQuantity == (long) fQuantity)
        oBfr.append("    <cbc:DeliveredQuantity>"+String.valueOf((long)fQuantity)+"</cbc:DeliveredQuantity>\n");
      else
        oBfr.append("    <cbc:DeliveredQuantity>"+String.valueOf(fQuantity)+"</cbc:DeliveredQuantity>\n");
      oBfr.append("    <cac:Item>\n");
      oBfr.append("      <cbc:Description><![CDATA["+oLines.getString(DB.nm_product,l)+"]]></cbc:Description>\n");
      oBfr.append("      <CatalogueItemIdentification><![CDATA["+oLines.getString(DB.id_ref,l)+"]]></CatalogueItemIdentification>\n");
      oBfr.append("    </cac:Item>\n");
      oBfr.append("  </cac:OrderLine>\n");
    }
    oBfr.append("  <cac:PaymentMeans>\n");
    oBfr.append("    <PaymentMeansCode>"+getStringNull(DB.tp_billing,"")+"</PaymentMeansCode>\n");
    if (isNull(DB.dt_payment))
      oBfr.append("    <cbc:DuePaymentDate/>\n");
    else
      oBfr.append("    <cbc:DuePaymentDate>"+getDateShort(DB.dt_payment)+"</cbc:DuePaymentDate>\n");
    oBfr.append("    <CardAccount>"+getStringNull(DB.nu_card,"")+"</CardAccount>\n");
    oBfr.append("    <PayerFinancialAccount>"+getStringNull(DB.nu_bank,"")+"</PayerFinancialAccount>\n");

    oBfr.append("  </cac:PaymentMeans>\n");
    oBfr.append("  </Order>\n");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Order.toXML()");
    }

    return oBfr.toString();
  } // toXML()


  // **********************************************************
  // Static methods

  /**
   * Delete order
   * @param oConn JDCConnection
   * @param sOrderId String Order GUID
   * @return boolean
   * @throws SQLException
   */
  public static boolean delete (JDCConnection oConn, String sOrderId) throws SQLException {
    return new Order(sOrderId).delete(oConn);
  }

  //----------------------------------------------------------------------------

  /**
   * Get active order for a WorkArea
   * @param oConn JDCConnection
   * @param sWorkAreaId String WorkArea GUID
   * @return Order
   * @throws SQLException
   */
  public static Order getActiveOrder(JDCConnection oConn, String sWorkAreaId) throws SQLException {
    Order oRetObj;
    PreparedStatement oSeek;
    ResultSet oRSet;
    String sOrderId;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Order.getActiveOrder([Connection], " + sWorkAreaId + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_order + " FROM " + DB.k_orders + " WHERE " + DB.gu_workarea + "=? AND " + DB.bo_active + "=1");

    oSeek = oConn.prepareStatement("SELECT " + DB.gu_order + " FROM " + DB.k_orders + " WHERE " + DB.gu_workarea + "=? AND " + DB.bo_active + "=1", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oSeek.setString(1, sWorkAreaId);
    oRSet = oSeek.executeQuery();
    if ( oRSet.next())
      sOrderId = oRSet.getString(1);
    else
      sOrderId = null;
    oRSet.close();
    oSeek.close();

    if (null==sOrderId) {
      oRetObj = new Order();
      oRetObj.put(DB.gu_workarea, sWorkAreaId);
      oRetObj.put(DB.bo_active, (short)1);
      oRetObj.put(DB.id_currency, "999");
      oRetObj.store(oConn);
    }
    else
      oRetObj = new Order(oConn, sOrderId);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Order.getActiveOrder() " + String.valueOf(oRetObj.getInt(DB.pg_order)));
    }

    return oRetObj;
  } // getActiveOrder

  // **********************************************************
  // Public Constants

  public static final short ClassId = 41;
}
