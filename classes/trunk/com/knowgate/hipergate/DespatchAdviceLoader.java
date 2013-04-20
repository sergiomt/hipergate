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

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.UnsupportedEncodingException;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import java.math.BigDecimal;

import java.util.Arrays;
import java.util.Collections;
import java.util.Date;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ImportExportException;
import com.knowgate.hipergate.datamodel.ImportLoader;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DBCommand;

import com.knowgate.dfs.FileSystem;

import com.knowgate.misc.CSVParser;
import com.knowgate.misc.Gadgets;

import com.enterprisedt.net.ftp.FTPException;

public class DespatchAdviceLoader extends CSVParser implements ImportLoader {

  // --------------------------------------------------------------------------
  // Private variables
  
  private SimpleDateFormat oDateFrmt;  
  private String sCharacterSet;
  private String sColumnDelimiter;
  private ColumnList ColumnsPresentAtInputFile;
  private String[] ColumnNames = { "","bo_approved","bo_credit_ok","de_despatch","dt_cancel","dt_created","dt_delivered","dt_modified","dt_payment","dt_printed","dt_promised","gu_bill_addr","gu_company","gu_contact","gu_despatch","gu_item","gu_order","gu_product","gu_ship_addr","gu_shop","gu_warehouse","gu_workarea","id_currency","id_legal","id_order_ref","id_pay_status","id_priority","id_product_ref","id_ref","id_ship_method","id_status","id_status","id_unit","im_discount","im_shipping","im_subtotal","im_taxes","im_total","is_tax_included","nm_client","nm_product","nm_shop","nm_warehouse","nu_quantity","pct_tax_rate","pg_despatch","pg_line","pr_sale","pr_total","tx_comments","tx_email_to","tx_location","tx_options","tx_promotion","tx_ship_notes" };
  private Object[] Values;
  private PreparedStatement oInsertDespatch, oInsertLine, oInsertRelationWithOrder;
  private PreparedStatement oFindProductGUID;
  private DBCommand oLoadOrder;

  // Data kept from one despatch line to another of the same despatch advice
  private String sLastDespatchAdviceIdentifier;  
  private String sLastDespatchAdviceGUID;
  private int iLastDespatchAdviceNumber;
  private int iLastDespatchLineNumber;
  private String sLastOrderGUID;
  private String sLastShopGUID;
  private String sLastLegalId;
  private String sLastCurrency;
  private String sLastWarehouse;
  private String sLastCompany;
  private String sLastContact;
  private String sLastClient;
  private String sLastShipAddr;
  private String sLastBillAddr;

  // --------------------------------------------------------------------------
  // Constructors
    
  /**
   * <p>Default constructor</p>
   * Input file is assumed to be in ISO-8859-1 character set encoding and default delimiter is TAB
   */
  public DespatchAdviceLoader() {
    oDateFrmt = new SimpleDateFormat("dd/MM/yyyy");
    sLastDespatchAdviceIdentifier = "";
    sCharacterSet = "ISO8859_1";
    sColumnDelimiter = "\t";
	Arrays.sort(ColumnNames, String.CASE_INSENSITIVE_ORDER);
    Values = new Object[ColumnNames.length];
    oFindProductGUID = oInsertDespatch = oInsertLine = oInsertRelationWithOrder = null;
  }

  // --------------------------------------------------------------------------
  // Constructors

  /**
   * Constructor
   * @param String sCharSet Character set of input file
   * @param String Column delimiter
   */

  public DespatchAdviceLoader(String sCharSet, String sColDelimiter) {
    sLastDespatchAdviceIdentifier = "";
    sCharacterSet = sCharSet;
    sColumnDelimiter = sColDelimiter;
	Arrays.sort(ColumnNames, String.CASE_INSENSITIVE_ORDER);
    Values = new Object[ColumnNames.length];
    oFindProductGUID = oInsertDespatch = oInsertLine = oInsertRelationWithOrder = null;
  }
  
  // --------------------------------------------------------------------------

  /**
   * Import despatch advices from a delimited file into the database
   * @param Connection Opened JDBC database connection
   * @param String sWorkArea GUID of WorkArea where despatch advices are to be loaded
   * @param int iFlags Additional flags for data loading { MODE_APPEND, MODE_UPDATE, MODE_APPENDUPDATE, WRITE_LOOKUPS }
   * @param String sFilePath Full path of file to be imported, including protocol.
   * @param String sColumnList Comma delimited list of columns present at the input file: "id_ref,nm_product,pr_total,..."
   * Like "file:///tmp/myfile.txt" or "file://C:\\Temp\\MyFile.txt" or "ftp://myhost:21/dir/myfile.txt"
   * @throws ImportExportException
   * @since 4.0
   */  
  public void importFile(Connection oConn, String sWorkArea, int iFlags, String sFilePath, String sColumnList)
  	throws ImportExportException {
	try {
	  
	  ColumnList oColsList = new ColumnList();
	  Collections.addAll(oColsList, (Object[]) Gadgets.split(sColumnList,','));

	  // Prepare SQL statements
	  prepare(oConn, oColsList);
	  
	  // Load desired file into memory
	  char[] aFileData = FileSystem.readfile(sFilePath,sCharacterSet);
	  parseData(aFileData, ColumnsPresentAtInputFile.toString(sColumnDelimiter));

	  // Get lines and columns counts
	  final int nLineCount = getLineCount();
	  final int nColsCount = getColumnCount();
	  
	  // For each line, put it into a Map and write it into the database
	  for (int l=0; l<nLineCount; l++) {
	    for (int c=0; c<nColsCount; c++) {
	      String sFieldValue = getField(c, l);
	      put(c, sFieldValue);
	    } // next (c)
	    store(oConn, sWorkArea, iFlags);
	  } // next (l)

	} catch (ArrayIndexOutOfBoundsException xcpt) { throw new ImportExportException(xcpt.getMessage(), xcpt); }  
	  catch (NullPointerException xcpt)           { throw new ImportExportException(xcpt.getMessage(), xcpt); }  
	  catch (IllegalArgumentException xcpt)       { throw new ImportExportException(xcpt.getMessage(), xcpt); }  
	  catch (RuntimeException xcpt)               { throw new ImportExportException(xcpt.getMessage(), xcpt); }
	  catch (SQLException xcpt)                   { throw new ImportExportException(xcpt.getMessage(), xcpt); }
	  catch (FileNotFoundException xcpt)          { throw new ImportExportException(xcpt.getMessage(), xcpt); }
	  catch (UnsupportedEncodingException xcpt)   { throw new ImportExportException(xcpt.getMessage(), xcpt); }
	  catch (IOException xcpt)                    { throw new ImportExportException(xcpt.getMessage(), xcpt); }
	  catch (FTPException xcpt)                   { throw new ImportExportException(xcpt.getMessage(), xcpt); }
    finally {
  	  try { close(); } catch (SQLException sqle) { throw new ImportExportException(sqle.getMessage(), sqle); } 
  	}
  } // importFile

  /**
   * Gt columns count
   * @return int
   */
  public int columnCount() {
    return ColumnNames.length;
  }

  /**
   * Get array of column names
   * @return String[]
   */
  public String[] columnNames() throws IllegalStateException {
    return ColumnNames;
  }

  /**
   * Get current value for a column given its index
   * @param iColumnIndex int [0..columnCount()-1]
   * @return Object
   * @throws ArrayIndexOutOfBoundsException
   */
  public Object get(int iColumnIndex) throws ArrayIndexOutOfBoundsException {
    return Values[iColumnIndex];
  }

  /**
   * Get current value for a column given its name
   * @param sColumnName Case insensitive String
   * @return Object
   * @throws ArrayIndexOutOfBoundsException if no column with such name was found
   */
  public Object get(String sColumnName) throws ArrayIndexOutOfBoundsException {
    return Values[getColumnIndex(sColumnName)];
  }

  /**
   * Get column index from its name
   * @param sColumnName String
   * @return int [0..columnCount()-1] or -1 if column was not found
   */
  public int getColumnIndex(String sColumnName) {
    int iIndex = Arrays.binarySearch(ColumnNames, sColumnName, String.CASE_INSENSITIVE_ORDER);
    if (iIndex<0) iIndex=-1;
    return iIndex;    
  }

  /**
   * Put current value for a column
   * @param iColumnIndex int [0..columnCount()-1]
   * @param oValue Object
   * @throws ArrayIndexOutOfBoundsException
   */
  public void put(int iColumnIndex, Object oValue) throws ArrayIndexOutOfBoundsException {
	Values[iColumnIndex] = oValue;
  }
  
  /**
   * Put current value for a column
   * @param sColumnName String Column name
   * @param oValue Object
   * @throws ArrayIndexOutOfBoundsException
   */
  public void put(String sColumnName, Object oValue) throws ArrayIndexOutOfBoundsException {
	Values[getColumnIndex(sColumnName)] = oValue;
  }

  /**
   * Set all current values to null
   */
  public void setAllColumnsToNull() {
  	for (int c=0; c<ColumnNames.length; c++) {
  	  Values[c] = null;
  	}
  } // setAllColumnsToNull
  
  /**
   * Prepare DespacthAdviceLoader for repeated execution
   * @param oConn Connection
   * @param oCols ColumnList List of columns that will be inserted or updated at the database
   * @throws SQLException
   */
  public void prepare(Connection oConn, ColumnList oCols) throws SQLException {
    ColumnsPresentAtInputFile = oCols;
    
    oInsertDespatch = oConn.prepareStatement("INSERT INTO k_despatch_advices (gu_despatch,gu_workarea,pg_despatch,gu_shop,id_currency,bo_approved,bo_credit_ok,id_priority,gu_warehouse,dt_modified,dt_delivered,dt_printed,dt_promised,dt_payment,dt_cancel,de_despatch,tx_location,gu_company,gu_contact,nm_client	,id_legal,gu_ship_addr,gu_bill_addr,id_ref,id_status,id_pay_status,id_ship_method,im_subtotal,im_taxes,im_shipping,im_discount,im_total,tx_ship_notes,tx_email_to,tx_comments) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	oInsertLine = oConn.prepareStatement("INSERT INTO k_despatch_lines (gu_despatch,pg_line,pr_sale,nu_quantity,id_unit,pr_total,pct_tax_rate,is_tax_included,nm_product,gu_product,gu_item,id_status,tx_promotion,tx_options) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	oInsertRelationWithOrder = oConn.prepareStatement("INSERT INTO k_x_orders_despatch (gu_order,gu_despatch) VALUES (?,?)");
    oFindProductGUID = oConn.prepareStatement("SELECT gu_product FROM k_products WHERE nm_product=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oLoadOrder = new DBCommand();
  }

  /**
   * <p>Close DespacthAdviceLoader</p>
   * Must be always called before DespacthAdviceLoader is destroyed
   * @throws SQLException
   */
  public void close() throws SQLException {
    if (oLoadOrder!=null) { oLoadOrder.close(); oLoadOrder=null; }
    if (oFindProductGUID!=null) { oFindProductGUID.close(); oFindProductGUID=null; }
    if (oInsertRelationWithOrder!=null) { oInsertRelationWithOrder.close(); oInsertRelationWithOrder=null; }
    if (oInsertLine!=null) { oInsertLine.close(); oInsertLine=null; }
    if (oInsertDespatch!=null) { oInsertDespatch.close(); oInsertDespatch=null; }
  } // close

  /**
   * Store a single despatch advice line
   * @param oConn Connection
   * @param sWorkArea String
   * @param iFlags int
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws NullPointerException
   */
  public void store(Connection oConn, String sWorkArea, int iFlags)
  	throws SQLException,IllegalArgumentException,NullPointerException {
  	
  	Timestamp tsNow = new Timestamp(new Date().getTime());
  	
  	// Check whether this is the first line of a new despatch or
  	// any next line for the previous despatch by comparing id_ref
  	// column value with the one previously processed
	boolean bIsNewDespacth = !sLastDespatchAdviceIdentifier.equals(get("id_ref"));

    // For each first line of a despatch, get data from order and insert row into k_despatch_advices and k_x_orders_despatch

	if (bIsNewDespacth) {
	  sLastDespatchAdviceIdentifier = (String) get("id_ref");
	  sLastDespatchAdviceGUID = Gadgets.generateUUID();
	  iLastDespatchAdviceNumber = DespatchAdvice.nextVal(new JDCConnection(oConn, null), sWorkArea);
	  iLastDespatchLineNumber = 1;

	  // Get data for the previous order corresponding to this despatch advice
	  ResultSet rOrderData = oLoadOrder.queryResultSet(oConn, "SELECT gu_order,gu_shop,id_legal,id_currency,gu_warehouse,gu_company,gu_contact,nm_client,gu_ship_addr,gu_bill_addr FROM k_orders WHERE gu_workarea='"+sWorkArea+"' AND id_ref='"+sLastDespatchAdviceIdentifier+"'");
	  if (rOrderData.next()) {
	  	sLastOrderGUID = rOrderData.getString(1);
	  	sLastShopGUID = rOrderData.getString(2);
	  	sLastLegalId = rOrderData.getString(3);
	  	sLastCurrency = rOrderData.getString(4);
	  	sLastWarehouse = rOrderData.getString(5);
	  	sLastCompany = rOrderData.getString(6);
	  	sLastContact = rOrderData.getString(7);
	  	sLastClient = rOrderData.getString(8);
	  	sLastShipAddr = rOrderData.getString(9);
	  	sLastBillAddr = rOrderData.getString(10);	  	
	    rOrderData.close();  
	  } else {
	  	rOrderData.close();
	    throw new SQLException ("Could not find any previous order corresponding to despatch advice "+sLastDespatchAdviceIdentifier);
	  }
	  try {
        oInsertDespatch.setString (1, sLastDespatchAdviceGUID);
        oInsertDespatch.setString (2, sWorkArea);
        oInsertDespatch.setInt    (3, iLastDespatchAdviceNumber);
        oInsertDespatch.setString (4, sLastShopGUID);
        oInsertDespatch.setString (5, sLastCurrency);
        oInsertDespatch.setShort  (6, (short) 1);
        oInsertDespatch.setShort  (7, (short) 1);
        oInsertDespatch.setNull   (8, java.sql.Types.VARCHAR);
        oInsertDespatch.setString (9, sLastWarehouse);
        oInsertDespatch.setTimestamp(10, tsNow);
        if (null==get("dt_delivered"))
          oInsertDespatch.setNull (11, java.sql.Types.TIMESTAMP);
        else
	      oInsertDespatch.setTimestamp(11, new Timestamp(oDateFrmt.parse((String) get("dt_delivered")).getTime()));
        if (null==get("dt_printed"))
          oInsertDespatch.setNull (12, java.sql.Types.TIMESTAMP);
        else
	      oInsertDespatch.setTimestamp(12, new Timestamp(oDateFrmt.parse((String) get("dt_printed")).getTime()));
        if (null==get("dt_promised"))
          oInsertDespatch.setNull (13, java.sql.Types.TIMESTAMP);
        else
	      oInsertDespatch.setTimestamp(13, new Timestamp(oDateFrmt.parse((String) get("dt_promised")).getTime()));
        if (null==get("dt_payment"))
          oInsertDespatch.setNull (14, java.sql.Types.TIMESTAMP);
        else
	      oInsertDespatch.setTimestamp(14, new Timestamp(oDateFrmt.parse((String) get("dt_payment")).getTime()));
        if (null==get("dt_cancel"))
          oInsertDespatch.setNull (15, java.sql.Types.TIMESTAMP);
        else
	      oInsertDespatch.setTimestamp(15, new Timestamp(oDateFrmt.parse((String) get("dt_cancel")).getTime()));
        oInsertDespatch.setObject (16, get("de_despatch"), java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (16, get("tx_location"), java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (18, sLastCompany, java.sql.Types.CHAR);
        oInsertDespatch.setObject (19, sLastContact, java.sql.Types.CHAR);
        oInsertDespatch.setObject (20, sLastClient, java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (21, sLastLegalId, java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (22, sLastShipAddr, java.sql.Types.CHAR);
        oInsertDespatch.setObject (23, sLastBillAddr, java.sql.Types.CHAR);
        oInsertDespatch.setObject (24, get("id_ref"), java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (25, get("id_status"), java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (26, get("id_pay_status"), java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (27, get("id_ship_method"), java.sql.Types.VARCHAR);
	    oInsertDespatch.setBigDecimal(28, new BigDecimal(0d));
	    oInsertDespatch.setBigDecimal(29, new BigDecimal(0d));
	    oInsertDespatch.setBigDecimal(30, new BigDecimal(0d));
	    oInsertDespatch.setBigDecimal(31, new BigDecimal(0d));
	    oInsertDespatch.setBigDecimal(32, new BigDecimal(0d));
        oInsertDespatch.setObject (33, get("tx_ship_notes"), java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (34, get("tx_email_to"), java.sql.Types.VARCHAR);
        oInsertDespatch.setObject (35, get("tx_comments"), java.sql.Types.VARCHAR);
        oInsertDespatch.executeUpdate();
      
        oInsertRelationWithOrder.setString(1, sLastOrderGUID);
        oInsertRelationWithOrder.setString(1, sLastDespatchAdviceGUID);
        oInsertRelationWithOrder.executeUpdate();
	  } catch (ParseException xcpt) {
	  	throw new IllegalArgumentException("Bad date: "+xcpt.getMessage());
	  }
	} // fi (bIsNewDespacth)

	// Finished inserting data for new despatch advices,
	// now insert despatch line
	
	oInsertLine.setString(1, sLastDespatchAdviceGUID);
	oInsertLine.setInt(2, iLastDespatchLineNumber++);
	if (null==get("pr_sale"))
	  oInsertLine.setNull(3, java.sql.Types.DECIMAL);
	else
	  oInsertLine.setBigDecimal(3, new BigDecimal((String) get("pr_sale")));	
	if (null==get("nu_quantity"))
	  oInsertLine.setFloat(4, 1f);
	else
	  oInsertLine.setFloat(4, Float.parseFloat((String) get("nu_quantity")));
	if (null==get("id_unit"))
	  oInsertLine.setString(5, "UNIT");
	else
	  oInsertLine.setObject(5, get("id_unit"), java.sql.Types.VARCHAR);
	if (null==get("pr_total"))
	  oInsertLine.setNull(6, java.sql.Types.DECIMAL);
	else
	  oInsertLine.setBigDecimal(6, new BigDecimal((String) get("pr_total")));	
	if (null==get("pct_tax_rate"))
	  oInsertLine.setNull(7, java.sql.Types.FLOAT);
	else
	  oInsertLine.setFloat(7, Float.parseFloat((String) get("pct_tax_rate")));
	if (null==get("is_tax_included"))
	  oInsertLine.setNull(8, java.sql.Types.SMALLINT);
	else
	  oInsertLine.setShort(8, Short.parseShort((String) get("is_tax_included")));
	if (null==get("nm_product"))
	  oInsertLine.setNull(9, java.sql.Types.VARCHAR);
	else
	  oInsertLine.setObject(9, get("nm_product"), java.sql.Types.VARCHAR);
	if (null==get("gu_product")) {
	  if (null==get("nm_product")) {
	    oInsertLine.setNull(10, java.sql.Types.CHAR);	  
	  } else {
	    oFindProductGUID.setObject(1, get("nm_product"), java.sql.Types.VARCHAR);
	    ResultSet rFoundProduct = oFindProductGUID.executeQuery();
	    if (rFoundProduct.next()) {
	      String sNmProduct = rFoundProduct.getString(1);
	      rFoundProduct.close();
	      oInsertLine.setString(10, sNmProduct);	  
	    } else {
	      oInsertLine.setNull(10, java.sql.Types.CHAR);	  	    	
	    }
	  }	  	
	} else {
	  oInsertLine.setObject(10, get("gu_product"), java.sql.Types.CHAR);
	} // fi (gu_product)
	if (null==get("gu_item"))
	  oInsertLine.setNull(11, java.sql.Types.CHAR);
	else
	  oInsertLine.setObject(11, get("gu_item"), java.sql.Types.CHAR);
	if (null==get("id_status"))
	  oInsertLine.setNull(12, java.sql.Types.VARCHAR);
	else
	  oInsertLine.setObject(12, get("id_status"), java.sql.Types.VARCHAR);
	if (null==get("tx_promotion"))
	  oInsertLine.setNull(13, java.sql.Types.VARCHAR);
	else
	  oInsertLine.setObject(13, get("id_status"), java.sql.Types.VARCHAR);
	if (null==get("tx_options"))
	  oInsertLine.setNull(14, java.sql.Types.VARCHAR);
	else
	  oInsertLine.setObject(14, get("tx_options"), java.sql.Types.VARCHAR);
	oInsertLine.executeUpdate();  		
  } // store
    
}
