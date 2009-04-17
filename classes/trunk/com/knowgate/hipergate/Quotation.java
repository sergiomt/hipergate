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

import java.util.ListIterator;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataxslt.db.PageSetDB;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DBColumn;

public class Quotation extends AbstractOrder {

    private DBSubset oOrders;
    private Address oBillAddr;

	/**
	 * Default Constructor
	 */
	public Quotation() {
      super(DB.k_quotations, DB.k_quotation_lines, DB.gu_quotation, "Quotation");
      oBillAddr=null;
	}

   // ---------------------------------------------------------------------------

   /**
    * Get quotation line by number
    * @param oConn JDCConnection
    * @param iPgLine int Line number [1..n] as as at k_order_lines.pg_line
    * @return OrderLine or <b>null</b> if no line with such number was found
    * @throws SQLException
    */
   public QuotationLine getLine(JDCConnection oConn, int iPgLine) throws SQLException {
     QuotationLine oRetVal = new QuotationLine();
     if (oRetVal.load(oConn, new Object[]{getStringNull(DB.gu_quotation,null),new Integer(iPgLine)}))
       return oRetVal;
     else
       return null;
   } // getLine()

   // ---------------------------------------------------------------------------
	
   /**
    * Get Quotation lines as a DBSubset
    * @param oConn Database Connection
    * @return A DBSubset with the following columns:<br>
    * <table border=1 cellpadding=4>
    * <tr><td><b>gu_quotation</b></td><td><b>pg_line</b></td><td><b>gu_product</b></td><td><b>nm_product</b></td><td><b>pr_sale</b></td><td><b>nu_quantity</b></td><td><b>id_unit</b></td><td><b>pr_total</b></td><td><b>pct_tax_rate</b></td><td><b>is_tax_included</b></td><td><b>tx_promotion</b></td><td><b>tx_options</b></td><td><b>gu_item</b></td><td><b>id_ref</b></td></tr>
    * <tr><td>Quotation GUID</td><td>Line Number</td><td>Product GUID</td><td>Product Name</td><td>Sale Price</td><td>Quantity Ordered</td><td>Unit for quantity</td><td>Total Price</td><td>% of Tax Rate</td><td>1 if tax included</td><td>Promotion Text</td><td>Additional Options</td><td>GUID of ordered item</td></tr>
    * </table>
    * @throws SQLException
    */
	public DBSubset getLines(JDCConnection oConn) throws SQLException {
     oLines = new DBSubset(DB.k_quotation_lines,
                           DB.gu_quotation + "," + DB.pg_line + "," +
                           DB.gu_product + "," + DB.nm_product + "," +
                           DB.pr_sale + "," + DB.nu_quantity + "," +
                           DB.id_unit + "," + DB.pr_total + "," +
                           DB.pct_tax_rate + "," + DB.is_tax_included + "," +
                           DB.tx_promotion + "," + DB.tx_options + "," +
                           DB.gu_item + ", '' AS " + DB.id_ref,
                           DB.gu_quotation + "=? ORDER BY 2", 10);

     oLines.load(oConn, new Object[]{getString(DB.gu_order)});
     
	 DBSubset oProdDetail = new DBSubset (DB.k_products+" p"+","+DB.k_quotation_lines+" l",
	 									  "p."+DB.gu_product+",p."+DB.id_ref,
	 									  "p."+DB.gu_product+"=l."+DB.gu_product+" AND "+
	 									  "p."+DB.gu_owner+"=? AND "+
	 									  "l."+DB.gu_quotation + "=?", 50);
     
     int nProdCount = oProdDetail.load(oConn, new Object[]{getString(DB.gu_workarea),getString(DB.gu_quotation)});
     
     for (int p=0; p<nProdCount; p++) {
       int l = oLines.find(9, oProdDetail.get(0,p));
       if (!oProdDetail.isNull(1,p)) {
         oLines.setElementAt(oProdDetail.get(1,p),13,l);
       }
     } // next
     
     return oLines;
   } // getLines

  // ---------------------------------------------------------------------------

  /**
   * Load Quotation with its associated Address
   * @param oConn JDCConnection
   * @param PKVals Array with a single element Object[1]{(String)gu_quotation}
   * @return boolean <b>true</b> is Quotation was found, <b>false</b> otherwise
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bRetVal = super.load(oConn, PKVals);
    if (bRetVal) {
      oOrders = new DBSubset (DB.k_x_quotations_orders, DB.gu_order, DB.gu_quotation+"=?", 1);
      oOrders.load(oConn, PKVals);
      if (isNull(DB.gu_bill_addr))
        oBillAddr = null;
	  else
        oBillAddr = new Address(oConn, getString(DB.gu_bill_addr));
    } // fi	

    return bRetVal;
  } // load

  // ---------------------------------------------------------------------------

  /**
   * <p>Store Quotation</p>
   * If no value for gu_quotation is specified then a new one is automatically assigned.<br>
   * If no value for pg_quotation is specified then a new one is automatically assigned by looking at k_quotation_next table and updating it afterwards.<br>
   * This method updates dt_modified to current datetime as a side effect iif Quotation did not previously exist at the database.<br>
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Quotation.store([JDCConnection])");
      DebugFile.incIdent();
    }

    if (!AllVals.containsKey(DB.gu_quotation))
      AllVals.put(DB.gu_quotation, Gadgets.generateUUID());
    else
      replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.pg_quotation) && AllVals.containsKey(DB.gu_workarea)) {
      AllVals.put(DB.pg_quotation, new Integer(nextVal(oConn, (String) AllVals.get(DB.gu_workarea))));
    } // fi (gu_workarea AND NOT pg_despatch)

    boolean bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Quotation.store() : " + String.valueOf(bRetVal));
    }
    return bRetVal;
  } // store

   //----------------------------------------------------------------------------

   /**
    * <p>Delete Quotation</p>
    * @param oConn
    * @return
    * @throws SQLException
    */
   public boolean delete (JDCConnection oConn) throws SQLException {
     boolean bRetVal;
     Statement oStmt;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin Quotation.delete([Connection])");
       DebugFile.incIdent();
     }

	 if (!isNull(DB.gu_pageset)) {
	  PageSetDB.delete(oConn, getString(DB.gu_pageset));
	 }
     
     oStmt = oConn.createStatement();

     oStmt.executeUpdate("DELETE FROM " + DB.k_x_quotations_orders + " WHERE " + DB.gu_quotation + "='" + getString(DB.gu_quotation) + "'");

     if (DebugFile.trace)
       DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_quotation_lines + " WHERE " + DB.gu_quotation + "='" + getStringNull(DB.gu_quotation,"") + "')");

     oStmt.executeUpdate("DELETE FROM " + DB.k_quotation_lines + " WHERE " + DB.gu_quotation + "='" + getString(DB.gu_quotation) + "'");

     oStmt.close();

     bRetVal = super.delete(oConn);

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Quotation.delete() : " + String.valueOf(bRetVal));
     }

     return bRetVal;
   } // delete

  //----------------------------------------------------------------------------

  /**
   * Get next value for field pg_quotation in a given WorkArea
   * @param oConn JDCConnection JDBC Connection
   * @param sGuWorkArea String WorkArea GUID
   * @return int Next unused quotation number
   * @throws SQLException
   */
  public static int nextVal(JDCConnection oConn, String sGuWorkArea)
    throws SQLException {
    boolean bNext;
    int iNextQuotation = 1;
    String sSQL = "";
    PreparedStatement oSnxt = null;
    ResultSet oRnxt = null;

    sSQL = "SELECT "+DB.pg_quotation+","+DB.gu_workarea+" FROM "+DB.k_quotations_next+ " WHERE "+DB.gu_workarea+"=? ";
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      sSQL += "FOR UPDATE OF "+DB.k_quotations_next;
    } if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
      sSQL += "FOR UPDATE OF "+DB.pg_quotation;
    }

    try {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE)");
      oSnxt = oConn.prepareStatement(sSQL,ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE);
      oSnxt.setObject(1, sGuWorkArea, Types.CHAR);
      oRnxt = oSnxt.executeQuery();
      bNext = oRnxt.next();
      if (bNext) {
        iNextQuotation = oRnxt.getInt(1);
        oRnxt.updateInt(DB.pg_quotation, ++iNextQuotation);
        oRnxt.updateRow();
      }
      oRnxt.close();
      oRnxt=null;
      oSnxt.close();
      oSnxt=null;
      if (!bNext) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE)");
        sSQL = "INSERT INTO "+DB.k_quotations_next+" ("+DB.gu_workarea+","+DB.pg_quotation+") VALUES (?,?)";
        oSnxt = oConn.prepareStatement(sSQL);
        oSnxt.setObject(1, sGuWorkArea, Types.CHAR);
        oSnxt.setInt(2, iNextQuotation);
        oSnxt.executeUpdate();
        oSnxt.close();
      }
    } catch (SQLException sqle) {
      if (oRnxt!=null) oRnxt.close();
      if (oSnxt!=null) oSnxt.close();
      throw new SQLException (sqle.getMessage()+" "+sSQL,sqle.getSQLState(),sqle.getErrorCode());
    }
    return iNextQuotation;
  } // nextVal

  //----------------------------------------------------------------------------

  /**
   * <p>Create an Order for this Quotation</p>
   * The new Order is given the same GUID as the current Quotation
   * @param oConn JDCConnection
   * @return Order
   * @throws SQLException
   */
  public Order createOrder(JDCConnection oConn) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Quotation.createOrder([Connection])");
      DebugFile.incIdent();
    }
    String sSQL;
    Order oOrder = new Order();
    ListIterator oIter = oOrder.getTable(oConn).getColumns().listIterator();
    while (oIter.hasNext()) {
      String sKey = ((DBColumn) oIter.next()).getName();
      if (!isNull(sKey)) {
        if (DebugFile.trace) DebugFile.writeln("Order.put("+sKey+","+get(sKey)+")");
        oOrder.put(sKey, get(sKey));
      }
    } // wend
    oOrder.replace(DB.gu_order, getString(DB.gu_quotation));
    oOrder.store(oConn);
    Statement oStmt = oConn.createStatement();
    sSQL = "INSERT INTO "+DB.k_order_lines+" ("+DB.gu_order+ ","+
                          DB.pg_line+","+DB.gu_product+","+DB.nm_product+","+
                          DB.pr_sale+","+DB.nu_quantity+","+DB.id_unit+","+
                          DB.pr_total+ ","+DB.pct_tax_rate+","+DB.is_tax_included+","+
                          DB.tx_promotion+","+DB.tx_options+","+DB.gu_item+") SELECT "+
                          DB.gu_quotation+ ","+ DB.pg_line+","+DB.gu_product+","+
                          DB.nm_product+","+ DB.pr_sale+","+DB.nu_quantity+","+
                          DB.id_unit+","+DB.pr_total+ ","+DB.pct_tax_rate+","+
                          DB.is_tax_included+","+ DB.tx_promotion+","+DB.tx_options+","+
                          DB.gu_item+" FROM "+DB.k_quotation_lines+
                          " WHERE "+DB.gu_quotation+"='"+getString(DB.gu_quotation)+"'";
    if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate("+sSQL+")");
    oStmt.executeUpdate(sSQL);
    oStmt.close();
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Quotation.createOrder() : "+oOrder.getString(DB.gu_invoice));
    }
    return oOrder;
  } // createOrder
}
