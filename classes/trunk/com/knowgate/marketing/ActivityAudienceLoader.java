/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

package com.knowgate.marketing;

import java.util.Date;
import java.util.HashMap;
import java.util.Arrays;

import java.math.BigDecimal;

import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.debug.StackTraceUtil;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.crm.ContactLoader;
import com.knowgate.crm.DistributionList;
import com.knowgate.dataobjs.DB;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ImportLoader;

public final class ActivityAudienceLoader implements ImportLoader {

    // ---------------------------------------------------------------------------
	
	private DistributionList oDstLst;
	private ContactLoader oCntLdr;
  	private Object[] aValues;
  	private HashMap oOriginsMap;
  	private PreparedStatement oAcAuInsr;
  	private PreparedStatement oAcAuUpdt;
  	private PreparedStatement oAcAuLook;

    // ---------------------------------------------------------------------------

    private final static String SQLAcAuInsr = "INSERT INTO k_x_activity_audience (gu_contact,gu_address,gu_list,gu_writer,dt_created,dt_modified,id_ref,tp_origin,bo_confirmed,dt_confirmed,bo_paid,dt_paid,im_paid,id_transact,tp_billing,bo_went,bo_allows_ads,id_data1,de_data1,tx_data1,id_data2,de_data2,tx_data2,id_data3,de_data3,tx_data3,id_data4,de_data4,tx_data4,id_data5,de_data5,tx_data5,id_data6,de_data6,tx_data6,id_data7,de_data7,tx_data7,id_data8,de_data8,tx_data8,id_data9,de_data9,tx_data9,gu_activity) VALUES (?,?,?,?,?,NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
    private final static String SQLAcAuUpdt = "UPDATE k_x_activity_audience SET gu_address=?,gu_list=?,gu_writer=?,dt_modified=?,id_ref=?,tp_origin=?,bo_confirmed=?,dt_confirmed=?,bo_paid=?,dt_paid=?,im_paid=?,id_transact=?,tp_billing=?,bo_went=?,bo_allows_ads=?,id_data1=?,de_data1=?,tx_data1=?,id_data2=?,de_data2=?,tx_data2=?,id_data3=?,de_data3=?,tx_data3=?,id_data4=?,de_data4=?,tx_data4=?,id_data5=?,de_data5=?,tx_data5=?,id_data6=?,de_data6=?,tx_data6=?,id_data7=?,de_data7=?,tx_data7=?,id_data8=?,de_data8=?,tx_data8=?,id_data9=?,de_data9=?,tx_data9=? WHERE gu_activity=? AND gu_contact=?";

    // ---------------------------------------------------------------------------

	public ActivityAudienceLoader() {
		aValues = new Object[ColumnNames.length];
		Arrays.fill(aValues, null);
		oDstLst = new DistributionList();
		oDstLst.put (DB.tp_list, DistributionList.TYPE_STATIC);		
		oCntLdr = new ContactLoader();
		oAcAuUpdt = oAcAuInsr = oAcAuLook = null;
		oOriginsMap = new HashMap();
	}

    // ---------------------------------------------------------------------------

	public int columnCount() {
		return aValues.length;
	}

    // ---------------------------------------------------------------------------

	public String[] columnNames() throws IllegalStateException {
		return ColumnNames;
	}	// columnNames()

    // ---------------------------------------------------------------------------

	public Object get(int iColumnIndex) throws ArrayIndexOutOfBoundsException {
		return aValues[iColumnIndex];
	}

    // ---------------------------------------------------------------------------

	public Object get(String sColumnName) throws ArrayIndexOutOfBoundsException {
		int iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
    	if (iColumnIndex>=0)
    	  return aValues[iColumnIndex];
    	else {
    	  iColumnIndex = oCntLdr.getColumnIndex(sColumnName.toLowerCase());
    	  if (iColumnIndex>=0)
    		return oCntLdr.get(iColumnIndex);
    	  else
    	  	throw new ArrayIndexOutOfBoundsException("Cannot find column named "+sColumnName);
    	}
	}	// get

	// ---------------------------------------------------------------------------

	private String getColNull (int iColIndex)
    	throws ArrayIndexOutOfBoundsException,ClassCastException {
    	if (DebugFile.trace) {
      		if (iColIndex<0 || iColIndex>=aValues.length)
        		throw new ArrayIndexOutOfBoundsException("ContactLoader.getColNull() column index "+String.valueOf(iColIndex)+" must be in the range between 0 and "+String.valueOf(aValues.length));
      		DebugFile.writeln("ContactLoader.getColNull("+String.valueOf(iColIndex)+") : "+aValues[iColIndex]);
    	}
    	String sRetVal;
    	if (null==aValues[iColIndex])
      		sRetVal = null;
    	else {
      		try {
        		sRetVal = aValues[iColIndex].toString();
      		} catch (ClassCastException cce) {
        	if (aValues[iColIndex]==null)
          		throw new ClassCastException("ContactLoader.getColNull("+String.valueOf(iColIndex)+") could not cast null to String");
        	else
          		throw new ClassCastException("ContactLoader.getColNull("+String.valueOf(iColIndex)+") could not cast "+aValues[iColIndex].getClass().getName()+" "+aValues[iColIndex]+" to String");
      		}
      	if (sRetVal.length()==0 || sRetVal.equalsIgnoreCase("null"))
        	sRetVal = null;
    	}
    	return sRetVal;
	}	// getColNull

    // ---------------------------------------------------------------------------

	public int getColumnIndex(String sColumnName) {
    	int iIndex = Arrays.binarySearch(ColumnNames, sColumnName, String.CASE_INSENSITIVE_ORDER);
    	if (iIndex<0) iIndex=-1;
    	return iIndex;
	}	// getColumnIndex

    // ---------------------------------------------------------------------------

	public void put(int iColumnIndex, Object oValue) throws ArrayIndexOutOfBoundsException {
		aValues[iColumnIndex] = oValue;
	}	// put

    // ---------------------------------------------------------------------------

	public void put(String sColumnName, Object oValue) throws ArrayIndexOutOfBoundsException {
		int iActivityIndex = getColumnIndex(sColumnName.toLowerCase());
		int iContactIndex = oCntLdr.getColumnIndex(sColumnName.toLowerCase());
    	if (iActivityIndex==-1 && iContactIndex==-1)
    		throw new ArrayIndexOutOfBoundsException("Cannot find column named "+sColumnName);
    	if (iActivityIndex>=0)
    		aValues[iActivityIndex] = oValue;
    	if (iContactIndex>=0)
    		oCntLdr.put(iContactIndex, oValue);
	}	// put

    // ---------------------------------------------------------------------------

	public void setAllColumnsToNull() {
		if (DebugFile.trace) {
			DebugFile.writeln("Begin ActivityAudienceLoader.setAllColumnsToNull()");
      		DebugFile.incIdent();
    	}

		Arrays.fill(aValues, null);
		
		oCntLdr.setAllColumnsToNull();

    	if (DebugFile.trace) {
      		DebugFile.decIdent();
      		DebugFile.writeln("End ActivityAudienceLoader.setAllColumnsToNull()");
    	}
	} // setAllColumnsToNull

    // ---------------------------------------------------------------------------

	public void prepare(Connection oConn, ColumnList oCols) throws SQLException {
		if (DebugFile.trace) {
      		DebugFile.writeln("Begin ActivityAudienceLoader.prepare()");
      		DebugFile.incIdent();
    	}

    	if (oAcAuInsr!=null || oAcAuLook!=null) {
      		if (DebugFile.trace) DebugFile.decIdent();
      		throw new SQLException("Either ActivityAudienceLoader.prepare() has already been called or statements were not properly closed","HY010");
    	}

		oAcAuInsr = oConn.prepareStatement(SQLAcAuInsr);
		oAcAuUpdt = oConn.prepareStatement(SQLAcAuUpdt);
    	oAcAuLook = oConn.prepareStatement("SELECT NULL FROM k_activity_audience_lookup WHERE gu_owner=? AND id_section=? AND vl_lookup=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);

		oCntLdr.prepare(oConn, oCols);

		if (DebugFile.trace) {
			DebugFile.decIdent();
      		DebugFile.writeln("End ActivityAudienceLoader.prepare()");
		}
	}	// prepare

    // ---------------------------------------------------------------------------

	public void close() throws SQLException {
		if (oAcAuLook!=null) oAcAuLook.close();
		oAcAuLook=null;
		if (oAcAuUpdt!=null) oAcAuUpdt.close();
		oAcAuUpdt=null;
		if (oAcAuInsr!=null) oAcAuInsr.close();
		oAcAuInsr=null;
		oCntLdr.close();
	}	// close

    // ---------------------------------------------------------------------------

	private static boolean test(int iInputValue, int iBitMask) {
		return (iInputValue&iBitMask)!=0;
  	} // test

  // ---------------------------------------------------------------------------

  	/**
   	 * Add a lookup value to a table
     * @param sSection String Section. Usually the name of the column at the base table
     * @param sWorkArea Work Area GUID
     * @param sValue String Internal hidden value of the lookup
     * @param oConn Connection
     * @param oSelStmt PreparedStatement
     * @param oCacheMap HashMap
     * @throws SQLException
     */
  	private void addLookUp(String sTable, String sSection, String sWorkArea, String sValue, Connection oConn,
                         PreparedStatement oSelStmt, HashMap<String,String> oCacheMap) throws SQLException {
    	String sTr;
    	char[] aTr;
    	final String EmptyStr = "";
    	boolean bExistsLookup;

    	if (DebugFile.trace) {
      		DebugFile.writeln("Begin ActivityAudienceLoader.addLookUp("+sTable+","+sSection+","+sValue+","+
                              "[Connection],[PreparedStatement],[PreparedStatement],[HashMap]");
      		DebugFile.incIdent();
    	}

    	if (null==sValue) sValue = EmptyStr;
    	if (!EmptyStr.equals(sValue)) {
      		if (!oCacheMap.containsKey(sValue)) {
        		oSelStmt.setString(1, sWorkArea);
        		oSelStmt.setString(2, sSection);
        		oSelStmt.setString(3, sValue);
        		ResultSet oRSet = oSelStmt.executeQuery();
        		bExistsLookup = oRSet.next();
        		oRSet.close();
        		if (!bExistsLookup) {
          			aTr = sValue.toLowerCase().toCharArray();
          			aTr[0] = Character.toUpperCase(aTr[0]);
          			sTr = new String(aTr);
		  			HashMap<String,String> oTranslatMap = new HashMap<String,String>(DBLanguages.SupportedLanguages.length*2);
		  			for (int l=0; l<DBLanguages.SupportedLanguages.length; l++) oTranslatMap.put(DBLanguages.SupportedLanguages[l], sTr);
 		  			DBLanguages.addLookup (oConn, sTable, sWorkArea, sSection, sValue, oTranslatMap);
                                   
        		} // fi (!bExistsLookup)
        		oCacheMap.put(sValue, sValue);
      		} // fi (!oCacheMap.containsKey(sValue))
    	}

    	if (DebugFile.trace) {
      		DebugFile.decIdent();
      		DebugFile.writeln("End ActivityAudienceLoader.addLookUp()");
    	}
	} // addLookUp

    // ---------------------------------------------------------------------------

    /**
     * Store properties currently held in RAM into the database
     * @param oConn Opened JDBC connection
     * @param sWorkArea String GUID of WorkArea to which inserted data will belong
     * @param iFlags int A boolean combination of {MODE_APPEND|MODE_APPENDUPDATE|WRITE_COMPANIES|WRITE_CONTACTS+WRITE_ADDRESSES|WRITE_LOOKUPS|NO_DUPLICATED_MAILS}
     * @throws SQLException
     * @throws IllegalArgumentException
     * @throws NullPointerException
     * @throws ClassCastException
     */

	public void store(Connection oConn, String sWorkArea, int iFlags)
		throws SQLException, IllegalArgumentException, NullPointerException {

    	Timestamp tsNow = new Timestamp(new Date().getTime());

		if (test(iFlags,WRITE_ADDRESSES) && !test(iFlags,WRITE_CONTACTS)) {
			throw new IllegalArgumentException("ActivityAudienceLoader.store() WRITE_CONTACTS is required if WRITE_ADDRESSES is set");
		}

		if (test(iFlags,WRITE_COMPANIES) && !test(iFlags,WRITE_CONTACTS)) {
			throw new IllegalArgumentException("ActivityAudienceLoader.store() WRITE_CONTACTS is required if WRITE_COMPANIES is set");
		}

		if (oAcAuInsr==null || oAcAuLook==null)
      		throw new SQLException("Invalid command sequece. Must call ActivityAudienceLoader.prepare() before ActivityAudienceLoader.store()");

    	if (null==sWorkArea)
      		throw new NullPointerException("ActivityAudienceLoader.store() Default WorkArea cannot be null");

		if (DebugFile.trace)	{
      		DebugFile.writeln("Begin ActivityAudienceLoader.store([Connection],"+sWorkArea+","+String.valueOf(iFlags)+")");
      		DebugFile.incIdent();
      		StringBuffer oRow = new StringBuffer();
      		oRow.append('{');
      		oRow.append(ColumnNames[0]+"=");
      		oRow.append(aValues[0]==null ? "null" : aValues[0]);
      		for (int d=1; d<aValues.length; d++)	{
        		oRow.append(","+ColumnNames[d]+"=");
        		oRow.append(aValues[d]==null ? "null" : aValues[d]);
      		} // next
      		oRow.append('}');
      		DebugFile.writeln(oRow.toString());
    	}
    	
    	if (test(iFlags,ImportLoader.MODE_UPDATE) && !test(iFlags,ImportLoader.MODE_APPENDUPDATE)) {
    		oAcAuUpdt.setObject(1, getColNull(gu_address), Types.CHAR);
    		if (aValues[gu_list]==null)
    	      oAcAuUpdt.setNull(2, Types.CHAR);
      		else
      		  oAcAuUpdt.setObject(2, aValues[gu_list], Types.CHAR);
    		oAcAuUpdt.setObject(3, getColNull(gu_writer), Types.CHAR);
    		oAcAuUpdt.setTimestamp(4, tsNow);
    		oAcAuUpdt.setObject(5, getColNull(id_ref), Types.VARCHAR);
    		oAcAuUpdt.setObject(6, getColNull(tp_origin), Types.VARCHAR);
    		if (aValues[bo_confirmed]==null)
    			oAcAuUpdt.setNull(7, Types.SMALLINT);
    		else
    			oAcAuUpdt.setObject(7, aValues[bo_confirmed], Types.SMALLINT);
    		if (aValues[dt_confirmed]==null)
    			oAcAuUpdt.setNull(8, Types.TIMESTAMP);
    		else
    			oAcAuUpdt.setObject(8, aValues[dt_confirmed], Types.TIMESTAMP);
    		if (aValues[bo_paid]==null)
    			oAcAuUpdt.setNull(9, Types.SMALLINT);
    		else
    			oAcAuUpdt.setObject(9, aValues[bo_paid], Types.SMALLINT);
    		if (aValues[dt_paid]==null)
    			oAcAuUpdt.setNull(10, Types.TIMESTAMP);
    		else
    			oAcAuUpdt.setObject(10, aValues[dt_paid], Types.TIMESTAMP);
    		if (aValues[im_paid]==null)
    			oAcAuUpdt.setNull(11, Types.DECIMAL);
    		else
    			oAcAuUpdt.setObject(11, aValues[im_paid], Types.DECIMAL);
    		oAcAuUpdt.setObject(12, getColNull(id_transact), Types.VARCHAR);
    		oAcAuUpdt.setObject(13, getColNull(tp_billing), Types.VARCHAR);
    		if (aValues[bo_went]==null)
    			oAcAuUpdt.setNull(14, Types.SMALLINT);
    		else
    			oAcAuUpdt.setObject(14, aValues[bo_went], Types.SMALLINT);
    		if (aValues[bo_allows_ads]==null)
    			oAcAuUpdt.setNull(15, Types.SMALLINT);
    		else
    			oAcAuUpdt.setObject(15, aValues[bo_allows_ads], Types.SMALLINT);
    		oAcAuUpdt.setObject(16, getColNull(id_data1), Types.VARCHAR);
    		oAcAuUpdt.setObject(17, getColNull(de_data1), Types.VARCHAR);
    		oAcAuUpdt.setObject(18, getColNull(tx_data1), Types.VARCHAR);
    		oAcAuUpdt.setObject(19, getColNull(id_data2), Types.VARCHAR);
    		oAcAuUpdt.setObject(20, getColNull(de_data2), Types.VARCHAR);
    		oAcAuUpdt.setObject(21, getColNull(tx_data2), Types.VARCHAR);
    		oAcAuUpdt.setObject(22, getColNull(id_data3), Types.VARCHAR);
    		oAcAuUpdt.setObject(23, getColNull(de_data3), Types.VARCHAR);
    		oAcAuUpdt.setObject(24, getColNull(tx_data3), Types.VARCHAR);
    		oAcAuUpdt.setObject(25, getColNull(id_data4), Types.VARCHAR);
    		oAcAuUpdt.setObject(26, getColNull(de_data4), Types.VARCHAR);
    		oAcAuUpdt.setObject(27, getColNull(tx_data4), Types.VARCHAR);
    		oAcAuUpdt.setObject(28, getColNull(id_data5), Types.VARCHAR);
    		oAcAuUpdt.setObject(29, getColNull(de_data5), Types.VARCHAR);
    		oAcAuUpdt.setObject(30, getColNull(tx_data5), Types.VARCHAR);
    		oAcAuUpdt.setObject(31, getColNull(id_data6), Types.VARCHAR);
    		oAcAuUpdt.setObject(32, getColNull(de_data6), Types.VARCHAR);
    		oAcAuUpdt.setObject(33, getColNull(tx_data6), Types.VARCHAR);
    		oAcAuUpdt.setObject(34, getColNull(id_data7), Types.VARCHAR);
    		oAcAuUpdt.setObject(35, getColNull(de_data7), Types.VARCHAR);
    		oAcAuUpdt.setObject(36, getColNull(tx_data7), Types.VARCHAR);
    		oAcAuUpdt.setObject(37, getColNull(id_data8), Types.VARCHAR);
    		oAcAuUpdt.setObject(38, getColNull(de_data8), Types.VARCHAR);
    		oAcAuUpdt.setObject(39, getColNull(tx_data8), Types.VARCHAR);
    		oAcAuUpdt.setObject(40, getColNull(id_data9), Types.VARCHAR);
    		oAcAuUpdt.setObject(41, getColNull(de_data9), Types.VARCHAR);
    		oAcAuUpdt.setObject(42, getColNull(tx_data9), Types.VARCHAR);
    		oAcAuUpdt.setObject(43, getColNull(gu_activity), Types.CHAR);
    		oAcAuUpdt.setObject(44, getColNull(gu_contact), Types.CHAR);

    		try {
    		  oAcAuUpdt.executeUpdate();
      		} catch (SQLException sqle) {
      		  if (DebugFile.trace) {
      		  	DebugFile.writeln("SQLException "+sqle.getMessage());
      			try { DebugFile.writeln(StackTraceUtil.getStackTrace(sqle)); } catch (java.io.IOException ignore) {}
          	  }
      		  oAcAuUpdt.close();
      		  oAcAuUpdt = oConn.prepareStatement(SQLAcAuUpdt);
      		  throw new SQLException("ActivityAudienceLoader UPDATE k_x_activity_audience gu_contact="+getColNull(gu_contact)+", gu_activity="+getColNull(gu_activity)+
      		  	                     ", gu_address="+getColNull(gu_address)+" "+
      		  	                     sqle.getMessage(),sqle.getSQLState(), sqle.getErrorCode(), sqle.getCause());
      		}    		
    		
    	} else {
    		if (!test(iFlags,MODE_APPEND)) iFlags |= MODE_APPEND;
    		
    		if (test(iFlags,WRITE_CONTACTS)) {	
    			oCntLdr.store(oConn, sWorkArea, iFlags);
    			oAcAuInsr.setObject(1, oCntLdr.get(ContactLoader.gu_contact), Types.CHAR);
    			if (test(iFlags,WRITE_ADDRESSES))
    			  oAcAuInsr.setObject(2, oCntLdr.get(ContactLoader.gu_address), Types.CHAR);
    			else
    			  oAcAuInsr.setNull(2, Types.CHAR);
    		} else {
    			oAcAuInsr.setObject(1, get(gu_contact), Types.CHAR);
    			if (test(iFlags,WRITE_ADDRESSES))
    			  oAcAuInsr.setObject(2, get(gu_address), Types.CHAR);
    			else
    			  oAcAuInsr.setNull(2, Types.CHAR);			
    		}
    		if (aValues[gu_list]==null)
      		  oAcAuInsr.setNull(3, Types.CHAR);
    		else
    		  oAcAuInsr.setObject(3, aValues[gu_list], Types.CHAR);
    		oAcAuInsr.setObject(4, getColNull(gu_writer), Types.CHAR);
    		oAcAuInsr.setTimestamp(5, tsNow);
    		oAcAuInsr.setObject(6, getColNull(id_ref), Types.VARCHAR);
    		oAcAuInsr.setObject(7, getColNull(tp_origin), Types.VARCHAR);
    		if (aValues[bo_confirmed]==null)
    			oAcAuInsr.setNull(8, Types.SMALLINT);
    		else
    			oAcAuInsr.setObject(8, aValues[bo_confirmed], Types.SMALLINT);
    		if (aValues[dt_confirmed]==null)
    			oAcAuInsr.setNull(9, Types.TIMESTAMP);
    		else
    			oAcAuInsr.setObject(9, aValues[dt_confirmed], Types.TIMESTAMP);
    		if (aValues[bo_paid]==null)
    			oAcAuInsr.setNull(10, Types.SMALLINT);
    		else
    			oAcAuInsr.setObject(10, aValues[bo_paid], Types.SMALLINT);
    		if (aValues[dt_paid]==null)
    			oAcAuInsr.setNull(11, Types.TIMESTAMP);
    		else
    			oAcAuInsr.setObject(11, aValues[dt_paid], Types.TIMESTAMP);
    		if (aValues[im_paid]==null)
    			oAcAuInsr.setNull(12, Types.DECIMAL);
    		else
    			oAcAuInsr.setObject(12, aValues[im_paid], Types.DECIMAL);
    		oAcAuInsr.setObject(13, getColNull(id_transact), Types.VARCHAR);
    		oAcAuInsr.setObject(14, getColNull(tp_billing), Types.VARCHAR);
    		if (aValues[bo_went]==null)
    			oAcAuInsr.setNull(15, Types.SMALLINT);
    		else
    			oAcAuInsr.setObject(15, aValues[bo_went], Types.SMALLINT);
    		if (aValues[bo_allows_ads]==null)
    			oAcAuInsr.setNull(16, Types.SMALLINT);
    		else
    			oAcAuInsr.setObject(16, aValues[bo_allows_ads], Types.SMALLINT);
    		oAcAuInsr.setObject(17, getColNull(id_data1), Types.VARCHAR);
    		oAcAuInsr.setObject(18, getColNull(de_data1), Types.VARCHAR);
    		oAcAuInsr.setObject(19, getColNull(tx_data1), Types.VARCHAR);
    		oAcAuInsr.setObject(20, getColNull(id_data2), Types.VARCHAR);
    		oAcAuInsr.setObject(21, getColNull(de_data2), Types.VARCHAR);
    		oAcAuInsr.setObject(22, getColNull(tx_data2), Types.VARCHAR);
    		oAcAuInsr.setObject(23, getColNull(id_data3), Types.VARCHAR);
    		oAcAuInsr.setObject(24, getColNull(de_data3), Types.VARCHAR);
    		oAcAuInsr.setObject(25, getColNull(tx_data3), Types.VARCHAR);
    		oAcAuInsr.setObject(26, getColNull(id_data4), Types.VARCHAR);
    		oAcAuInsr.setObject(27, getColNull(de_data4), Types.VARCHAR);
    		oAcAuInsr.setObject(28, getColNull(tx_data4), Types.VARCHAR);
    		oAcAuInsr.setObject(29, getColNull(id_data5), Types.VARCHAR);
    		oAcAuInsr.setObject(30, getColNull(de_data5), Types.VARCHAR);
    		oAcAuInsr.setObject(31, getColNull(tx_data5), Types.VARCHAR);
    		oAcAuInsr.setObject(32, getColNull(id_data6), Types.VARCHAR);
    		oAcAuInsr.setObject(33, getColNull(de_data6), Types.VARCHAR);
    		oAcAuInsr.setObject(34, getColNull(tx_data6), Types.VARCHAR);
    		oAcAuInsr.setObject(35, getColNull(id_data7), Types.VARCHAR);
    		oAcAuInsr.setObject(36, getColNull(de_data7), Types.VARCHAR);
    		oAcAuInsr.setObject(37, getColNull(tx_data7), Types.VARCHAR);
    		oAcAuInsr.setObject(38, getColNull(id_data8), Types.VARCHAR);
    		oAcAuInsr.setObject(39, getColNull(de_data8), Types.VARCHAR);
    		oAcAuInsr.setObject(40, getColNull(tx_data8), Types.VARCHAR);
    		oAcAuInsr.setObject(41, getColNull(id_data9), Types.VARCHAR);
    		oAcAuInsr.setObject(42, getColNull(de_data9), Types.VARCHAR);
    		oAcAuInsr.setObject(43, getColNull(tx_data9), Types.VARCHAR);
    		oAcAuInsr.setObject(44, getColNull(gu_activity), Types.CHAR);
    		try {
    		  oAcAuInsr.executeUpdate();
    		} catch (SQLException sqle) {
    		  if (DebugFile.trace) {
    		  	DebugFile.writeln("SQLException "+sqle.getMessage());
    			try { DebugFile.writeln(StackTraceUtil.getStackTrace(sqle)); } catch (java.io.IOException ignore) {}
        	  }
    		  oAcAuInsr.close();
    		  oAcAuInsr = oConn.prepareStatement(SQLAcAuInsr);
    		  throw new SQLException("ActivityAudienceLoader INSERT INTO k_x_activity_audience gu_contact="+oCntLdr.get(ContactLoader.gu_contact)+", gu_activity="+getColNull(gu_activity)+
    		  	                     ", gu_address="+oCntLdr.get(ContactLoader.gu_address)+" "+
    		  	                     sqle.getMessage(),sqle.getSQLState(), sqle.getErrorCode(), sqle.getCause());
    		}    		
    	}

		if (aValues[gu_list]!=null && aValues[gu_contact]!=null) {
          oDstLst.replace (DB.gu_workarea, sWorkArea);
		  oDstLst.addContact(oConn, getColNull(gu_contact));
		}

		if (test(iFlags,WRITE_LOOKUPS)) {
      		addLookUp("k_activity_audience_lookup", "tp_origin", sWorkArea, getColNull(tp_origin), oConn, oAcAuLook, oOriginsMap);
    	} // if (test(WRITE_LOOKUPS))

		if (DebugFile.trace) {
			DebugFile.decIdent();
			DebugFile.writeln("End ActivityAudienceLoader.store()");
    	}
	}	// store

    // ---------------------------------------------------------------------------

	public void storeLine(Connection oConn, String sWorkArea, int iFlags,
						  String sColNames, char cColSep, String sColValues)
		throws SQLException, IllegalArgumentException, NullPointerException,
		       ParseException, NumberFormatException {

		if (DebugFile.trace) {
			DebugFile.writeln("Begin ActivityAudienceLoader.storeLine([Connection], "+sWorkArea+","+
							  sColNames+",'"+cColSep+"',"+sColValues+")");
			DebugFile.incIdent();
    	}
	
		final SimpleDateFormat oShortDate = new SimpleDateFormat ("yyyy-MM-dd");
		final SimpleDateFormat oDateTime = new SimpleDateFormat ("yyyy-MM-dd HH:mm:ss");
		
		final String[] aColNames = Gadgets.split(sColNames, cColSep);
		final String[] aColValues= Gadgets.split(sColValues, cColSep);
		
		if (aColNames.length!=aColValues.length) {
			throw new IllegalArgumentException("Column names count "+String.valueOf(aColNames.length)+
											   " does not match column values count "+String.valueOf(aColValues.length));
		}
		
		final int nCols = aColNames.length;

		for (int c=0; c<nCols; c++) {
			String sColValue = aColValues[c].trim();
			if (sColValue.length()>0) {
				Object oColValue;
				String sColName = aColNames[c];
				if (sColName.startsWith("bo_") || sColName.startsWith("ny_"))
					oColValue = new Short(sColValue);
				else if (sColName.startsWith("nu_") && !sColName.equals("nu_street"))
					oColValue = new Integer(sColValue);
				else if (sColName.startsWith("im_"))
					oColValue = new Float(sColValue);
				else if (sColName.startsWith("pr_"))
					oColValue = new BigDecimal(sColValue);
				else if (sColName.startsWith("dt_"))
					if (sColName.length()==10)
						oColValue = oShortDate.parse(sColValue);
					else
						oColValue = oDateTime.parse (sColValue);
				else
					oColValue = sColValue;

				int iColIndex = getColumnIndex(sColName);
				if (iColIndex>=0) aValues[iColIndex] = oColValue;

				int iCntIndex = oCntLdr.getColumnIndex(sColName);
				if (iCntIndex>=0) oCntLdr.put(iCntIndex, oColValue);				
			} // fi (sColValue!="")
		}	// next

		store(oConn, sWorkArea, iFlags);

		if (DebugFile.trace) {
			DebugFile.decIdent();
			DebugFile.writeln("End ActivityAudienceLoader.storeLine()");
    	}

	}	// storeLine

    // ---------------------------------------------------------------------------

    // Keep this list sorted
    private static final String[] ColumnNames = { "", "bo_allows_ads","bo_confirmed","bo_paid","bo_went","de_data1","de_data2","de_data3","de_data4","de_data5","de_data6","de_data7","de_data8","de_data9","dt_confirmed","dt_created","dt_modified","dt_paid","gu_activity","gu_address","gu_contact","gu_list","gu_writer","id_data1","id_data2","id_data3","id_data4","id_data5","id_data6","id_data7","id_data8","id_data9","id_ref","id_transact","im_paid","tp_billing","tp_origin","tx_data1","tx_data2","tx_data3","tx_data4","tx_data5","tx_data6","tx_data7","tx_data8","tx_data9" };
  	
    // ----------------------------------------------------------------------

    public static int bo_allows_ads	= 1;
    public static int bo_confirmed	= 2;
    public static int bo_paid	= 3;
    public static int bo_went	= 4;
    public static int de_data1	= 5;
    public static int de_data2	= 6;
    public static int de_data3	= 7;
    public static int de_data4	= 8;
    public static int de_data5	= 9;
    public static int de_data6	= 10;
    public static int de_data7	= 11;
    public static int de_data8	= 12;
    public static int de_data9	= 13;
    public static int dt_confirmed	= 14;
    public static int dt_created	= 15;
    // public static int dt_modified	= 16;
    public static int dt_paid	= 17;
    public static int gu_activity	= 18;
    public static int gu_address	= 19;
    public static int gu_contact	= 20;
    public static int gu_list	= 21;
    public static int gu_writer	= 22;
    public static int id_data1	= 23;
    public static int id_data2	= 24;
    public static int id_data3	= 25;
    public static int id_data4	= 26;
    public static int id_data5	= 27;
    public static int id_data6	= 28;
    public static int id_data7	= 29;
    public static int id_data8	= 30;
    public static int id_data9	= 31;
    public static int id_ref	= 32;
    public static int id_transact	= 33;
    public static int im_paid	= 34;
    public static int tp_billing	= 35;
    public static int tp_origin	= 36;
    public static int tx_data1	= 37;
    public static int tx_data2	= 38;
    public static int tx_data3	= 39;
    public static int tx_data4	= 40;
    public static int tx_data5	= 41;
    public static int tx_data6	= 42;
    public static int tx_data7	= 43;
    public static int tx_data8	= 44;
    public static int tx_data9	= 45;

    // ----------------------------------------------------------------------

    public static final int MODE_UPDATE = ImportLoader.MODE_UPDATE;
    public static final int MODE_APPEND = ImportLoader.MODE_APPEND;
    public static final int MODE_APPENDUPDATE = ImportLoader.MODE_APPENDUPDATE;
    public static final int WRITE_LOOKUPS = ImportLoader.WRITE_LOOKUPS;

    public static final int WRITE_COMPANIES = ContactLoader.WRITE_COMPANIES;
    public static final int WRITE_CONTACTS = ContactLoader.WRITE_CONTACTS;
    public static final int WRITE_ADDRESSES = ContactLoader.WRITE_ADDRESSES;
    public static final int NO_DUPLICATED_MAILS = ContactLoader.NO_DUPLICATED_MAILS;

}
