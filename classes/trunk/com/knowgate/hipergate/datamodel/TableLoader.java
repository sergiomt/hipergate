/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate.datamodel;

import java.math.BigDecimal;

import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.util.ListIterator;
import java.util.HashMap;

import java.sql.Types;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dataobjs.DBTable;
import com.knowgate.misc.Gadgets;

/**
 * Generic text to table loader
 * @author Sergio Montoro Ten
 * @version 2.0
 */
public class TableLoader extends DBTable implements ImportLoader {

  private JDCConnection jConn;
  private short[] aColTypes;
  private String[] aColNames;
  private Object[] aValues;
  private SimpleDateFormat oDtFmt = new SimpleDateFormat("yyyy-MM-dd");
  private SimpleDateFormat oTsFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  HashMap oInsrColPos;
  HashMap oUpdtColPos;
  private PreparedStatement oInsr;
  private PreparedStatement oUpdt;

  // ---------------------------------------------------------------------------

  public TableLoader(String sTableName) {
    super(sTableName);
    aColNames = null;
    aColTypes = null;
    jConn = null;
  }

  // ---------------------------------------------------------------------------

  public String[] columnNames() throws IllegalStateException {
    if (null==aColNames)
      throw new IllegalStateException("TableLoader: must call prepare() before columnNames()");
    return aColNames;
  }

  // ---------------------------------------------------------------------------

  public short[] columnTypes() throws IllegalStateException {
    if (null==aColTypes)
      throw new IllegalStateException("TableLoader: must call prepare() before columnTypes()");
    return aColTypes;
  }

  // ---------------------------------------------------------------------------

  public void prepare(Connection oConn, ColumnList oColList)
    throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin TableLoader.prepare([Connection], [ColumnList])");
      DebugFile.incIdent();
    }
    readColumns(oConn, oConn.getMetaData());
    if (columnCount()==0) {
      DebugFile.decIdent();
      throw new SQLException("No columns found for table "+getName());
    }
    aColNames = Gadgets.split(","+getColumnsStr(),',');
    aColTypes = new short[aColNames.length];
    ListIterator<DBColumn> oColIter = getColumns().listIterator();
    int t=-1;
    while (oColIter.hasNext()) {
      aColTypes[++t] = oColIter.next().getSqlType();
    } // wend
    aValues = new Object[columnCount()+1];
    String sSQL;
    String sCol;
    oInsrColPos = new HashMap(1+oColList.size()*2);
    oUpdtColPos = new HashMap(1+oColList.size()*2);

    // ************************************
    // Compose and prepare insert statement
    sSQL = "INSERT INTO "+getName()+" ("+oColList.toString(",")+") VALUES (";
    for (int c=0; c<oColList.size(); c++) {
      oInsrColPos.put(oColList.getColumnName(c).toLowerCase(),new Integer(c+1));
      sSQL += (c == 0 ? "" : ",") + "?";
    }
    sSQL += ")";

    if (DebugFile.trace) {
      DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    }

    oInsr = oConn.prepareStatement(sSQL);

    // ************************************
    // Compose and prepare update statement

    sSQL = oColList.toString("=?,");
    ListIterator oIter = getPrimaryKey().listIterator();
    while (oIter.hasNext()) {
      sCol = (String) oIter.next();
      try {
        sSQL = Gadgets.replace(sSQL, sCol + "=?,", "");
        sSQL = Gadgets.replace(sSQL, sCol + "=?", "");
      } catch (Exception neverthrown) {}
    }
    String[] aUpdtCols = Gadgets.split(sSQL, ",");
    for (int c=0; c<aUpdtCols.length; c++) {
      oUpdtColPos.put(Gadgets.dechomp(aUpdtCols[c],"=?").toLowerCase(),new Integer(c+1));
    }
    sSQL = "UPDATE "+getName()+" SET "+sSQL+ " WHERE ";
    oIter = getPrimaryKey().listIterator();
    int iPK=1;
    while (oIter.hasNext()) {
      sCol = (String) oIter.next();
      oUpdtColPos.put(sCol.toLowerCase(),new Integer(aUpdtCols.length+iPK));
      if (iPK>1) sSQL += " AND ";
      sSQL += sCol+"=?";
      iPK++;
    }

    if (DebugFile.trace) {
      DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    }

    oUpdt = oConn.prepareStatement(sSQL);

    jConn = new JDCConnection(oConn, null);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End TableLoader.prepare()");
    }
  } // prepare

  // ---------------------------------------------------------------------------

  public Object get(int iColumnIndex) throws ArrayIndexOutOfBoundsException {
    return aValues[iColumnIndex];
  }

  // ---------------------------------------------------------------------------

  public Object get(String sColumnName) throws ArrayIndexOutOfBoundsException {
    return aValues[getColumnIndex(sColumnName)-1];
  }

  // ---------------------------------------------------------------------------

  public void put(int iColumnIndex, String sValue)
  	throws NumberFormatException,ArrayIndexOutOfBoundsException,ParseException {
    switch (aColTypes[iColumnIndex]) {
      case Types.TINYINT:
    	aValues[iColumnIndex]=new Byte(sValue);
        break;
      case Types.SMALLINT:
    	aValues[iColumnIndex]=new Short(sValue);
        break;
      case Types.INTEGER:
    	aValues[iColumnIndex]=new Integer(sValue);
        break;
      case Types.BIGINT:
    	aValues[iColumnIndex]=new Long(sValue);
        break;
      case Types.FLOAT:
    	aValues[iColumnIndex]=new Float(sValue);
        break;
      case Types.DOUBLE:
      case Types.REAL:
    	aValues[iColumnIndex]=new Double(sValue);
        break;
      case Types.DECIMAL:
      case Types.NUMERIC:
    	aValues[iColumnIndex]=new BigDecimal(sValue);
        break;
      case Types.DATE:
      	if (sValue.length()==10)
    	  aValues[iColumnIndex]=oDtFmt.parse(sValue);
      	else    	
    	  aValues[iColumnIndex]=oTsFmt.parse(sValue);
        break;        
      case Types.TIMESTAMP:    	
    	aValues[iColumnIndex]=oTsFmt.parse(sValue);
        break;        
      default:
    	aValues[iColumnIndex]=sValue;      	
    }
  }

  // ---------------------------------------------------------------------------

  public void put(int iColumnIndex, Object oValue) throws ArrayIndexOutOfBoundsException {
    aValues[iColumnIndex]=oValue;
  }

  // ---------------------------------------------------------------------------

  public void put(String sColumnName, Object oValue) throws ArrayIndexOutOfBoundsException {
    aValues[getColumnIndex(sColumnName)-1]=oValue;
  }

  // ---------------------------------------------------------------------------

  public void setAllColumnsToNull() {
    for (int c=columnCount()-1; c>=0; c--) aValues[c]=null;
  }

  // ---------------------------------------------------------------------------

  public void close() throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin TableLoader.close()");
      DebugFile.incIdent();
    }

    try { if (oUpdt!=null) oUpdt.close(); } catch (Exception ignore) {}
    try { if (oInsr!=null) oUpdt.close(); } catch (Exception ignore) {}

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End TableLoader.close()");
    }
  } // close

  // ---------------------------------------------------------------------------

  private static boolean test(int iInputValue, int iBitMask) {
    return (iInputValue&iBitMask)!=0;
  } // test

  // ---------------------------------------------------------------------------

  public void store(Connection oConn, String sWorkArea, int iFlags)
      throws SQLException,IllegalArgumentException,NullPointerException {

    int iAffected;
    if (oUpdt==null || oInsr==null)
      throw new SQLException("Invalid command sequece. Must call ContactLoader.prepare() before TableLoader.store()");

    if (!test(iFlags,MODE_APPEND) && !test(iFlags,MODE_UPDATE))
      throw new IllegalArgumentException("TableLoader.store() Flags bitmask must contain either MODE_APPEND, MODE_UPDATE or both");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin TableLoader.store([Connection], "+sWorkArea+","+String.valueOf(iFlags)+")");
      DebugFile.incIdent();
    }

    if (test(iFlags,MODE_UPDATE)) {
      ListIterator oIter = getColumns().listIterator();
      int iPos = 0;
      while (oIter.hasNext()) {
        DBColumn oCol = (DBColumn) oIter.next();
        Integer iUpdtPos = (Integer) oUpdtColPos.get(oCol.getName());
        if (null!=iUpdtPos) {
          jConn.bindParameter(oUpdt, iUpdtPos.intValue(), aValues[iPos], oCol.getSqlType());
        }
        iPos++;
      } // wend
      iAffected = oUpdt.executeUpdate();
    } // fi (MODE_UPDATE)

    if (test(iFlags,MODE_APPEND)) {
      ListIterator oIter = getColumns().listIterator();
      int iPos = 0;
      while (oIter.hasNext()) {
        DBColumn oCol = (DBColumn) oIter.next();
        Integer iInsrPos = (Integer) oInsrColPos.get(oCol.getName());
        if (null!=iInsrPos) {
          jConn.bindParameter(oInsr, iInsrPos.intValue(), aValues[iPos], oCol.getSqlType());
        }
        iPos++;
      } // wend
      iAffected = oInsr.executeUpdate();
    } // fi (MODE_UPDATE)
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End TableLoader.store()");
    }
  } // store

  // ---------------------------------------------------------------------------
}
