/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.

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

package com.knowgate.dataobjs;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Timestamp;

import java.util.Date;

import java.math.BigDecimal;

import com.knowgate.debug.DebugFile;

/**
 * A wrapper for some common SQL command sequences
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public class DBCommand {

  private Statement oStmt;

  // ---------------------------------------------------------------------------

  public DBCommand() {
    oStmt = null;
  }

  // ---------------------------------------------------------------------------

  public void close() throws SQLException {
	if (oStmt!=null) {
	  oStmt.close();
	  oStmt=null;
	}	
  } // close

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query and get a ResultSet
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @throws SQLException
   * @since 4.0
   */
  public ResultSet queryResultSet(Connection oCon, String sSQL) throws SQLException {
  	close();
	oStmt = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	return oStmt.executeQuery(sSQL);
  } // queryResultSet

  // ---------------------------------------------------------------------------

  public static boolean queryExists(Connection oCon, String sTable, String sWhere)
    throws SQLException {
    Statement oStm = null;
    ResultSet oRst = null;
	boolean bExists = false;
	
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryExists("+sTable+","+sWhere+")");
      DebugFile.incIdent();
    }
	
	try {
	  oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
	  oRst = oStm.executeQuery("SELECT NULL FROM "+sTable+" WHERE "+sWhere);
	  bExists = oRst.next();
	  oRst.close();
	  oRst=null;
	  oStm.close();
	  oStm=null;
	} catch (SQLException sqle) {
	  if (oRst!=null) oRst.close();
	  if (oStm!=null) oStm.close();
	  throw new SQLException(sqle.getMessage());
	}

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBCommand.queryExists() : " + String.valueOf(bExists));
    }

	return bExists;
  } // queryExists

  // ---------------------------------------------------------------------------
  
  /**
   * Execute a SQL query and get an Integer value as result
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @return Integer Value of the first column selected by the query or <b>null</b>
   * if no row was found or selected row was <b>null</b>
   * @throws SQLException
   * @throws NumberFormatException
   * @throws ClassCastException
   */
  public static Integer queryInt(Connection oCon, String sSQL)
    throws SQLException,NumberFormatException,ClassCastException {

    Statement oStm = null;
    ResultSet oRst = null;
    Object oObj = null;
    Integer oInt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryInt("+sSQL+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery(sSQL);
      if (oRst.next()) {
        oObj = oRst.getObject(1);
        if (oRst.wasNull()) oObj = null;
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (null==oObj)
      oInt = null;
    else
      oInt = new Integer(oObj.toString());

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oInt)
        DebugFile.writeln("End DBCommand.queryInt() : null");
      else
        DebugFile.writeln("End DBCommand.queryInt() : "+oInt.toString());
    }

    return oInt;
  } // queryInt

  // ---------------------------------------------------------------------------
  
  /**
   * Execute a SQL query and get a Short value as result
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @return Short Value of the first column selected by the query or <b>null</b>
   * if no row was found or selected row was <b>null</b>
   * @throws SQLException
   * @throws NumberFormatException
   * @throws ClassCastException
   * @since 4.0
   */
  public static Short queryShort(Connection oCon, String sSQL)
    throws SQLException,NumberFormatException,ClassCastException {

    Statement oStm = null;
    ResultSet oRst = null;
    Object oObj = null;
    Short oShort;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryShort("+sSQL+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery(sSQL);
      if (oRst.next()) {
        oObj = oRst.getObject(1);
        if (oRst.wasNull()) oObj = null;
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (null==oObj)
      oShort = null;
    else
      oShort = new Short(oObj.toString());

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oShort)
        DebugFile.writeln("End DBCommand.queryShort() : null");
      else
        DebugFile.writeln("End DBCommand.queryShort() : "+oShort.toString());
    }

    return oShort;
  } // queryShort

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query and get a String value as result
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @return String Value of the first column selected by the query or <b>null</b>
   * if no row was found or selected row was <b>null</b>
   * @throws SQLException
   * @throws NumberFormatException
   * @throws ClassCastException
   */

  public static String queryStr(Connection oCon, String sSQL)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    String sStr = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryStr("+sSQL+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery(sSQL);
      if (oRst.next()) {
      	ResultSetMetaData oMDat = oRst.getMetaData();
      	int nCols = oMDat.getColumnCount();
      	if (nCols==1) {
          sStr = oRst.getString(1);
          if (oRst.wasNull()) sStr = null;
      	} else {
      	  sStr = "";
      	  for (int c=1; c<=nCols; c++) {
      	  	String sCol = oRst.getString(c);
            if (!oRst.wasNull()) sStr += sCol;      	  	
      	  } // next 
      	} // fi
      } // fi
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBCommand.queryStr() : "+sStr);
    }

    return sStr;
  } // queryStr

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query and get an Array of Strings as result
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @return Array of Strings or <b>null</b> if no row was found
   * @throws SQLException
   * @throws NumberFormatException
   * @throws ClassCastException
   */

  public static String[] queryStrs(Connection oCon, String sSQL)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    String[] aStr = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryStrs("+sSQL+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery(sSQL);
      if (oRst.next()) {
      	ResultSetMetaData oMDat = oRst.getMetaData();
      	int nCols = oMDat.getColumnCount();
      	aStr = new String[nCols];
      	for (int c=1; c<=nCols; c++) {
      	  String sCol = oRst.getString(c);
          if (oRst.wasNull())
          	aStr[c-1] = null;
          else
          	aStr[c-1] = sCol;      	  	
      	} // next 
      } // fi
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBCommand.queryStrs()");
    }

    return aStr;
  } // queryStrs

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query and get a BigDecimal value as result
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @return String Value of the first column selected by the query or <b>null</b>
   * if no row was found or selected row was <b>null</b>
   * @throws SQLException
   * @throws NumberFormatException
   * @throws ClassCastException
   */

  public static BigDecimal queryBigDecimal(Connection oCon, String sSQL)
    throws SQLException,NumberFormatException,ClassCastException {

    Statement oStm = null;
    ResultSet oRst = null;
    BigDecimal oDec = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryBigDecimal("+sSQL+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery(sSQL);
      if (oRst.next()) {
        oDec = oRst.getBigDecimal(1);
        if (oRst.wasNull()) oDec = null;
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oDec)
        DebugFile.writeln("End DBCommand.queryBigDecimal() : null ");
      else
        DebugFile.writeln("End DBCommand.queryBigDecimal() : "+oDec.toString());
    }
    return oDec;
  } // queryBigDecimal

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query to get the maximum value for a column
   * @param oCon Connection Open JDBC database connection
   * @param sColumn Column Name
   * @param sTable Table Name
   * @param sWhere WHERE clause to restrict maximum search
   * @return The maximum value found for the given restrictions or <b>null</b> if no maximum value was found
   * @throws SQLException
   * @since 4.0
   */
  
  public static Object queryMax(Connection oCon, String sColumn, String sTable, String sWhere)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    Object oMax = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryMax("+sColumn+","+sTable+","+sWhere+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery("SELECT MAX("+sColumn+") FROM "+sTable+(null==sWhere ? "" : " WHERE "+sWhere));
      if (oRst.next()) {
        oMax = oRst.getObject(1);
        if (oRst.wasNull()) oMax = null;
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oMax)
        DebugFile.writeln("End DBCommand.queryMax() : null ");
      else
        DebugFile.writeln("End DBCommand.queryMax() : "+oMax.toString());
    }
    return oMax;
  } // queryMax

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query to get the minimum value for a column
   * @param oCon Connection Open JDBC database connection
   * @param sColumn Column Name
   * @param sTable Table Name
   * @param sWhere WHERE clause to restrict minimum search
   * @return The minimum value found for the given restrictions or <b>null</b> if no minimum value was found
   * @throws SQLException
   * @since 4.0
   */
  
  public static Object queryMin(Connection oCon, String sColumn, String sTable, String sWhere)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    Object oMin = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryMin("+sColumn+","+sTable+","+sWhere+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery("SELECT MIN("+sColumn+") FROM "+sTable+(null==sWhere ? "" : " WHERE "+sWhere));
      if (oRst.next()) {
        oMin = oRst.getObject(1);
        if (oRst.wasNull()) oMin = null;
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oMin)
        DebugFile.writeln("End DBCommand.queryMin() : null ");
      else
        DebugFile.writeln("End DBCommand.queryMin() : "+oMin.toString());
    }
    return oMin;
  } // queryMin

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query to get the maximum date value for a date column
   * @param oCon Connection Open JDBC database connection
   * @param sColumn Column Name
   * @param sTable Table Name
   * @param sWhere WHERE clause to restrict maximum search
   * @return The maximum date found for the given restrictions or <b>null</b> if no maximum date was found
   * @throws SQLException
   * @since 4.0
   */
  
  public static Date queryMaxDate(Connection oCon, String sColumn, String sTable, String sWhere)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    Timestamp oMax = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryMaxDate("+sColumn+","+sTable+","+sWhere+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery("SELECT MAX("+sColumn+") FROM "+sTable+(null==sWhere ? "" : " WHERE "+sWhere));
      if (oRst.next()) {
        oMax = oRst.getTimestamp(1);
        if (oRst.wasNull()) oMax = null;
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oMax)
        DebugFile.writeln("End DBCommand.queryMaxDate() : null ");
      else
        DebugFile.writeln("End DBCommand.queryMaxDate() : "+oMax.toString());
    }
    if (oMax==null)
      return null;
    else
      return new Date(oMax.getTime());
  } // queryMaxDate

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query to get the minimum value for a date column
   * @param oCon Connection Open JDBC database connection
   * @param sColumn Column Name
   * @param sTable Table Name
   * @param sWhere WHERE clause to restrict minimum search
   * @return The minimum date found for the given restrictions or <b>null</b> if no minimum date was found
   * @throws SQLException
   * @since 4.0
   */
  
  public static Date queryMinDate(Connection oCon, String sColumn, String sTable, String sWhere)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    Timestamp oMin = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryMinDate("+sColumn+","+sTable+","+sWhere+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery("SELECT MIN("+sColumn+") FROM "+sTable+(null==sWhere ? "" : " WHERE "+sWhere));
      if (oRst.next()) {
        oMin = oRst.getTimestamp(1);
        if (oRst.wasNull()) oMin = null;
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oMin)
        DebugFile.writeln("End DBCommand.queryMinDate() : null ");
      else
        DebugFile.writeln("End DBCommand.queryMinDate() : "+oMin.toString());
    }
    if (oMin==null)
      return null;
    else
      return new Date(oMin.getTime());
  } // queryMin

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query to get the maximum value for a column of type INTEGER
   * @param oCon Connection Open JDBC database connection
   * @param sColumn Column Name
   * @param sTable Table Name
   * @param sWhere WHERE clause to restrict maximum search
   * @return The maximum value found for the given restrictions or <b>null</b> if no maximum value was found
   * @throws SQLException
   * @throws NumberFormatException
   * @since 4.0
   */

  public static Integer queryMaxInt(Connection oCon, String sColumn, String sTable, String sWhere)
    throws SQLException,NumberFormatException {
	Object oMax = queryMax(oCon, sColumn, sTable, sWhere);
	if (null==oMax)
	  return null;
	else
	  return new Integer(oMax.toString());
  } // queryMaxInt

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query to get the maximum value for a column of type INTEGER
   * @param oCon Connection Open JDBC database connection
   * @param sColumn Column Name
   * @param sTable Table Name
   * @param sWhere WHERE clause to restrict maximum search
   * @return The maximum value found for the given restrictions or <b>null</b> if no maximum value was found
   * @throws SQLException
   * @throws NumberFormatException
   * @since 5.0
   */

  public static Integer queryMinInt(Connection oCon, String sColumn, String sTable, String sWhere)
    throws SQLException,NumberFormatException {
	Object oMin = queryMin(oCon, sColumn, sTable, sWhere);
	if (null==oMin)
	  return null;
	else
	  return new Integer(oMin.toString());
  } // queryoMinInt

  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query to count occurences of rows matching a criteria
   * @param oCon Connection Open JDBC database connection
   * @param sColumn Column Name
   * @param sTable Table Name
   * @param sWhere WHERE clause to restrict counting
   * @return The count of rows matching the WHERE clause
   * @throws SQLException
   * @since 4.0
   */
  public static int queryCount(Connection oCon, String sColumn, String sTable, String sWhere)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    int iCount;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryCount("+sColumn+","+sTable+","+sWhere+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery("SELECT COUNT("+sColumn+") FROM "+sTable+(null==sWhere ? "" : " WHERE "+sWhere));
      oRst.next();
	  iCount = oRst.getInt(1);
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBCommand.queryCount() : "+String.valueOf(iCount));
    }
    return iCount;
  } // queryCount
  
  // ---------------------------------------------------------------------------

  /**
   * Execute a SQL query and get a BigDecimal value as result
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @return String Value of the first column selected by the query or <b>null</b>
   * if no row was found or selected row was <b>null</b>
   * @throws SQLException
   * @throws NumberFormatException
   * @throws ClassCastException
   */

  public static Date queryDateTime(Connection oCon, String sSQL)
    throws SQLException {

    Statement oStm = null;
    ResultSet oRst = null;
    Timestamp oTs = null;;
    Date oDt = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.queryDateTime("+sSQL+")");
      DebugFile.incIdent();
    }

    try {
      oStm = oCon.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRst = oStm.executeQuery(sSQL);
      if (oRst.next()) {
        oTs = oRst.getTimestamp(1);
        if (oRst.wasNull())
          oDt = null;
        else
          oDt = new Date(oTs.getTime());
      }
      oRst.close();
      oRst=null;
      oStm.close();
      oStm=null;
    } catch (Exception xcpt) {
      if (DebugFile.trace) {
        DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      if (oRst!=null) { try {oRst.close(); } catch (Exception ignore) {} }
      if (oStm!=null) { try {oStm.close(); } catch (Exception ignore) {} }
      throw new SQLException(xcpt.getMessage());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oDt)
        DebugFile.writeln("End DBCommand.queryDateTime() : null ");
      else
        DebugFile.writeln("End DBCommand.queryDateTime() : "+oDt.toString());
    }
    return oDt;
  } // queryDateTime

  // ---------------------------------------------------------------------------

  /**
   * Execute an INSERT or UPDATE statement
   * @param oCon Connection Open JDBC database connection
   * @param sSQL String Command to be executed
   * @return int Count of affected rows
   * @throws SQLException
   */
  public static int executeUpdate(Connection oCon, String sSQL) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBCommand.executeUpdate("+sSQL+")");
      DebugFile.incIdent();
    }

    Statement oStm = null;
    int iAffected = 0;
    try {
      oStm = oCon.createStatement();
      iAffected = oStm.executeUpdate(sSQL);
      oStm.close();
      oStm=null;
    } catch (SQLException sqle) {
      if (DebugFile.trace) {
        DebugFile.writeln("SQLException "+sqle.getMessage());
        DebugFile.decIdent();
      }
      if (null!=oStm) { try { oStm.close(); } catch (Exception ignore) {} }
      if (DebugFile.trace) {
      	DebugFile.writeln("SQLException "+sqle.getMessage());
        DebugFile.decIdent();
      }
      throw new SQLException(sSQL+" "+sqle.getMessage(),sqle.getSQLState(),sqle.getErrorCode(), sqle.getCause());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBCommand.executeUpdate() : " + String.valueOf(iAffected));
    }

    return iAffected;
  } // executeUpdate
}
