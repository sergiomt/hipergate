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

package com.knowgate.dataobjs;

import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.ParameterMetaData;
import java.sql.Statement;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;
import java.sql.Types;

import java.math.BigDecimal;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;

import java.util.StringTokenizer;
import java.util.Vector;
import java.util.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Calendar;
import com.knowgate.misc.CSVParser;
import com.knowgate.math.Money;

/**
 *
 * <p>A bidimensional array representing data readed from a database table.</p>
 * The DBSubset object is used for reading a collection of registers from the database
 * and kept them in memory for inmediate access.
 * As hipergate reuses database connections by recycling them at the {@link JDCConnectionPool},
 * it is a good programming practice to read just the needed number of registers in a single
 * step operation and then free the connection as soon as possible for being used by another processs.
 * Another reason for this "read fast and leave" tactic is that some JDBC drivers have problems
 * managing multiple open resultsets with pending results in a single connection.
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public final class DBSubset extends Vector<Vector<Object>> {

  private static final long serialVersionUID = 70000l;
	
  /**
   * </p>Contructs a DBSubset.</p>
   * @param sTableName Base table or tables, ie. "k_products" or "k_products p, k_x_cat_objs x"
   * @param sColumnList Column list to be retirved from base tables i.e "p.gu_product,p.nm_product"
   * @param sFilterClause SQL filter clause or <b>null</b> if there is no filter clause to be applied.
   * @param iFetchSize Space for number of rows initailly allocated. Is DBSubset later loads more rows
   * the buffer is automatically expanded. This parameter may also have a great effect on reducing
   * network round trips as the ResultSet.setFetchSize(iFetchSize) method is called prior to fetching
   * rows. Fetching rows in batches is much faster than doing so one by one. When iFetchSize is set,
   * the JDBC driver may optimize accesses to fetched rows by reading bursts and
   * caching rows at client side.
   */

  public DBSubset (String sTableName, String sColumnList, String sFilterClause, int iFetchSize) {
    if (DebugFile.trace)
      DebugFile.writeln ("new DBSubset(" + sTableName + "," + sColumnList + "," + sFilterClause + "," + String.valueOf(iFetchSize)+")");

    sTable = sTableName;
    sColList = sColumnList;

    if (null!=sFilterClause) {
     sFilter = sFilterClause;

     if (sFilter.length()>0)
        sSelect = "SELECT " +  sColList + " FROM " + sTable + " WHERE " + sFilter;
      else
        sSelect = "SELECT " +  sColList + " FROM " + sTable;
    }
    else {
      sFilter = "";
      sSelect = "SELECT " +  sColList + " FROM " + sTable;
    }

    if (DebugFile.trace) DebugFile.writeln (sSelect);

    iFetch = iFetchSize;
    iColCount = 0;
    iMaxRows = -1;
    iTimeOut = 60;
    bEOF = true;
    sColDelim = "`";
    sRowDelim = "¨";
    sTxtQualifier = "\"";
    oShortDate = null;
  }

  // ----------------------------------------------------------

  /**
   * Delete rows from base table
   * @param oConn Connection
   * @param aFilterValues Object[] Parameters for sFilter parameter specified at constructor
   * @return int Number of rows deleted
   * @throws SQLException
   */
  public int clear(Connection oConn, Object[] aFilterValues) throws SQLException
  {
    int iAffected=0;
    PreparedStatement oStmt;

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBSubset.clear([Connection], Object[])");
      DebugFile.incIdent();
      }

    // Begin SQLException

      if (sFilter.length()>0)
        oStmt = oConn.prepareStatement("DELETE FROM " + sTable + " WHERE " + sFilter);
      else
        oStmt = oConn.prepareStatement("DELETE FROM " + sTable);

      for (int c=0; c<aFilterValues.length; c++)
        oStmt.setObject(c+1, aFilterValues[c]);

      iAffected = oStmt.executeUpdate();
      oStmt.close();

    // End SQLException
    
    oSubRecords = null;

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.clear()");
      }

    return iAffected;
  } // clear

  // ----------------------------------------------------------

  /**
   * @return <b>true</b> if call() or load() methods readed all available rows,
   * <b>false</b> if more rows where pending of reading when getMaxRows() was
   * reached.<br>
   * Also, after calling store(), eof() is <b>true</b> if all rows were stored
   * successfully or <b>false</b> if any row failed to be inserted or updated.
   */
  public boolean eof() {
    return bEOF;
  }

  // ----------------------------------------------------------

  /**
   * @return Maximum number of rows to be readed from database
   */
  public int getMaxRows() {
    return iMaxRows;
  }

  // ----------------------------------------------------------

  /**
   * <p>Maximum number of rows to be readed from database</p>
   * <p>The exact behavior of this property depends on the RDBMS used.</p>
   * <p>For <b>PostgreSQL</b> [LIMIT n] clause is appended to DBSubset query and all returned rows are readed.</p>
   * <p>For <b>Microsoft SQL Server</b> [OPTION FAST(n)] clause is appended to DBSubset query
   * and then the number of readed rows is limited at client side fetching.</p>
   * <p>For <b>Oracle</b> there is no standard way of limiting the resultset size.
   * The number of readed rows is just limited at client side fetching.</p>
   */

  public void setMaxRows(int iMax) {
    iMaxRows = iMax;    
  }

  // ----------------------------------------------------------

  /**
   * @return Maximum amount of time in seconds that a query may run before being cancelled.
   */

  public int getQueryTimeout() {
    return iTimeOut;
  }

  // ----------------------------------------------------------

  /**
   * Maximum number of seconds that a query can be executing before raising a timeout exception
   * @param iMaxSeconds
   */
  public void setQueryTimeout(int iMaxSeconds) {
    iTimeOut = iMaxSeconds;
  }

  // ----------------------------------------------------------

  private void setFetchSize(JDCConnection oConn, ResultSet oRSet)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.setFetchSize()");
      DebugFile.incIdent();
      }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL)
      // PostgreSQL does not support setFetchSize()
      iFetch = 1;

    else {

      try {
        if (0!=iFetch)
          oRSet.setFetchSize (iFetch);
        else
          iFetch = oRSet.getFetchSize();
      }
      catch (SQLException e) {
        if (DebugFile.trace) DebugFile.writeln(e.getMessage());
        iFetch = 1;
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.setFetchSize() : " + iFetch);
      }
    } // setFetchSize

  // ----------------------------------------------------------

  private int fetchResultSet (ResultSet oRSet, int iSkip)
    throws SQLException, ArrayIndexOutOfBoundsException
    {
    Vector oRow;
    int iCol;
    int iRetVal = 0;
    int iMaxRow = iMaxRows<0 ? 2147483647 : iMaxRows;
    long lFetchTime = 0;
    Object oFieldValue;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.fetchResultSet([ResultSet], " + String.valueOf(iSkip) + ")");
      DebugFile.incIdent();
      DebugFile.writeln("column count = " + String.valueOf(iColCount));
      DebugFile.writeln("max. rows = " + String.valueOf(iMaxRows));
      DebugFile.writeln("new Vector(" + String.valueOf(iFetch) + "," + String.valueOf(iFetch) + ")");
      lFetchTime = System.currentTimeMillis();
    }

    if (0!=iSkip) {
      oRSet.next();

      if (DebugFile.trace) DebugFile.writeln("ResultSet.relative(" + String.valueOf(iSkip-1) + ")");

      oRSet.relative (iSkip-1);
    } // fi(iSkip)

    boolean bHasNext = oRSet.next();

    while (bHasNext && iRetVal<iMaxRow) {

      iRetVal++;
      oRow = new Vector(iColCount);

      for (iCol=1; iCol<=iColCount; iCol++) {
        oFieldValue = oRSet.getObject(iCol);
        if (oRSet.wasNull())
          oRow.add (null);
        else
          oRow.add (oFieldValue);
      } // next

      super.add(oRow);

      bHasNext = oRSet.next();
    } // wend

    if (0==iRetVal || iRetVal<iMaxRow) {
      bEOF = true;
      if (DebugFile.trace) DebugFile.writeln("readed " + String.valueOf(iRetVal) + " rows eof() = true");
    }
    else {
      bEOF = !bHasNext;

      if (DebugFile.trace) DebugFile.writeln("readed max " + String.valueOf(iMaxRow) + " rows eof() = " + String.valueOf(bEOF));
    }

    if (DebugFile.trace) {
      DebugFile.writeln("fetching done in " + String.valueOf(System.currentTimeMillis()-lFetchTime) + " ms");
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.fetchResultSet() : " + String.valueOf(iRetVal));
    }

    return iRetVal;
    } // fetchResultSet

  // ----------------------------------------------------------

  /**
   * <p>Execute a stored procedure returning a ResultSet</p>
   * @param oConn Database Connection
   * @return Number of rows retrieved
   * @throws SQLException
   */

  public int call (JDCConnection oConn) throws SQLException {
    return call(oConn,0);
  }

  // ----------------------------------------------------------

  /**
   * <p>Execute a stored procedure returning a ResultSet</p>
   * @param oConn Database Connection
   * @param iSkip Number of rows to be skipped before reading
   * @return Number of rows retrieved
   * @throws SQLException
   * @throws IllegalArgumentException if iSkip<0
   * @throws ArrayIndexOutOfBoundsException
   */

  public int call (JDCConnection oConn, int iSkip)
      throws SQLException, IllegalArgumentException, ArrayIndexOutOfBoundsException
  {
    CallableStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    int iRows = 0;
    int iType = (iSkip==0 ? ResultSet.TYPE_FORWARD_ONLY : ResultSet.TYPE_SCROLL_INSENSITIVE);

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBSubset.call([Connection]," + iSkip + ")");
      DebugFile.incIdent();
      }

    // Begin SQLException

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({call " + sTable + "()}");
      oStmt = oConn.prepareCall("{call " + sTable + "()}", iType, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(" + sTable + ")");

      oRSet = oStmt.executeQuery();

      oMDat = oRSet.getMetaData();
      iColCount = oMDat.getColumnCount();
      ColNames = new String[iColCount];

      for (int c=1; c<=iColCount; c++) {
        ColNames[c-1] = oMDat.getColumnName(c).toLowerCase();
      }
      oMDat = null;

      setFetchSize(oConn, oRSet);

      iRows = fetchResultSet(oRSet,iSkip);

      oRSet.close();
      oRSet = null;

      oStmt.close();
      oStmt = null;

    // End SQLException

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.call()");
      }

    return iRows;
  } // call()

  // ----------------------------------------------------------

  /**
   * <p>Execute a stored procedure returning a ResultSet</p>
   * @param oConn Database Connection
   * @param aFilterValues Values to be binded and JDBC PreparedStatement query paramenters.
   * @return Number of rows retrieved
   * @throws SQLException
   */

  public int call (JDCConnection oConn, Object[] aFilterValues) throws SQLException {
    return call(oConn, aFilterValues, 0);
  }

  // ----------------------------------------------------------

  /**
   * <p>Execute a stored procedure returning a ResultSet</p>
   * @param oConn Database Connection
   * @param aFilterValues Values to be binded and JDBC PreparedStatement query paramenters.
   * @param iSkip Number of rows to be skipped before reading
   * @return Number of rows retrieved,
   * the maximum number of rows to be retrieved is determined by calling method
   * setMaxRows(), if setMaxRows() is not called before call() then all rows existing are retrieved.
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws ArrayIndexOutOfBoundsException
   */

  public int call (JDCConnection oConn, Object[] aFilterValues, int iSkip)
    throws SQLException, IllegalArgumentException, ArrayIndexOutOfBoundsException
    {
    CallableStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;

    int iRows = 0;
    int iType = (iSkip==0 ? ResultSet.TYPE_FORWARD_ONLY : ResultSet.TYPE_SCROLL_INSENSITIVE);

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBSubset.call([Connection:"+oConn.pid()+"], Object[]," + iSkip + ")");
      DebugFile.incIdent();
      }

    // Begin SQLException
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({call " + sTable + "()}");
      oStmt = oConn.prepareCall("{call " + sTable + "()}", iType, ResultSet.CONCUR_READ_ONLY);

      for (int p=0; p<aFilterValues.length; p++)
        oStmt.setObject(p+1, aFilterValues[p]);

      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery()");

      oRSet = oStmt.executeQuery();

      oMDat = oRSet.getMetaData();
      iColCount = oMDat.getColumnCount();
      ColNames = new String[iColCount];

      for (int c=1; c<=iColCount; c++) {
        ColNames[c-1] = oMDat.getColumnName(c).toLowerCase();
      }
      oMDat = null;

      setFetchSize(oConn, oRSet);

      iRows = fetchResultSet(oRSet, iSkip);

      oRSet.close();
      oRSet = null;

      oStmt.close();
      oStmt = null;

    // End SQLException

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.call()");
      }

    return iRows;
  } // call

  // ----------------------------------------------------------

  /**
   * <p>Execute a JDBC Statement and load query ResultSet in an internal bidimensional matrix</p>
   * @param oConn Database Connection
   * @return Number of rows retrieved
   * the maximum number of rows to be retrieved is determined by calling method
   * setMaxRows(), if setMaxRows() is not called before call() then all rows existing are retrieved.
   * @throws SQLException
   */

  public int load (JDCConnection oConn)
    throws SQLException, ArrayIndexOutOfBoundsException, NullPointerException {
    return load(oConn, 0);
  }

  // ----------------------------------------------------------

  /**
   * <p>Execute a JDBC Statement and load query ResultSet in an internal bidimensional matrix</p>
   * @param oConn Database Connection
   * @param iSkip Number of rows to be skipped before reading. On database systems that support an
   * OFFSET clause (such as PostgreSQL) the native offset feature of the DBMS is used, in case that
   * the DBMS does not provide offset capabilities, the data is fetched and discarded at client side
   * before returning the DBSubset. Care must be taken when skipping a large number of rows in client
   * side mode as it may cause heavy network traffic and round trips to the database.
   * @return Number of rows retrieved
   * the maximum number of rows to be retrieved is determined by calling method
   * setMaxRows(), if setMaxRows() is not called before call() then all rows existing are retrieved.
   * @throws SQLException
   * @throws IllegalArgumentException if iSkip<0
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   */

  public int load (JDCConnection oConn, int iSkip)
    throws SQLException, IllegalArgumentException,
    ArrayIndexOutOfBoundsException, NullPointerException {

    Statement oStmt = null;
    ResultSet oRSet = null;
    ResultSetMetaData oMDat;
    int iRows = 0;
    int iType = (iSkip==0 ? ResultSet.TYPE_FORWARD_ONLY : ResultSet.TYPE_SCROLL_INSENSITIVE);
    long lQueryTime = 0;

    if (DebugFile.trace)
      {
      DebugFile.writeln("Begin DBSubset.load([Connection]," + iSkip + ")");
      lQueryTime = System.currentTimeMillis();
      }

    if (iSkip<0)
      throw new IllegalArgumentException("row offset must be equal to or greater than zero");

    if (null==oConn)
      throw new NullPointerException("DBSubset.load() JDCConnection parameter is null");

    if (DebugFile.trace)
      DebugFile.incIdent();

    try {

      oStmt = oConn.createStatement (iType, ResultSet.CONCUR_READ_ONLY);

      if (iMaxRows>0) {

        switch (oConn.getDataBaseProduct()) {

          case JDCConnection.DBMS_MSSQL:
            if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + " OPTION (FAST " + String.valueOf(iMaxRows) + ")" + ")");
            oRSet = oStmt.executeQuery(sSelect + " OPTION (FAST " + String.valueOf(iMaxRows) + ")");
            break;

          case JDCConnection.DBMS_MYSQL:
            if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + " LIMIT " + String.valueOf(iSkip) + "," + String.valueOf(iMaxRows+2) + ")");
            oRSet = oStmt.executeQuery(sSelect + " LIMIT " + String.valueOf(iSkip) + "," + String.valueOf(iMaxRows+2));
            iSkip = 0; // Use MySQL native OFFSET parameter, so do not skip any rows before client side fetching
            break;

          case JDCConnection.DBMS_POSTGRESQL:
            if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + " LIMIT " + String.valueOf(iMaxRows+2) + " OFFSET " + String.valueOf(iSkip) + ")");
            oRSet = oStmt.executeQuery(sSelect + " LIMIT " + String.valueOf(iMaxRows+2) + " OFFSET " + String.valueOf(iSkip));
            iSkip = 0; // Use PostgreSQL native OFFSET clause, so do not skip any rows before client side fetching
            break;

          default:
            if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + ")");
            oRSet = oStmt.executeQuery(sSelect);
        } // end switch
      }
      else {
        switch (oConn.getDataBaseProduct()) {

          case JDCConnection.DBMS_MYSQL:
            if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + " LIMIT " + String.valueOf(iSkip) + ",2147483647)");
            oRSet = oStmt.executeQuery(sSelect + " LIMIT " + String.valueOf(iSkip) + ",2147483647" );
            iSkip = 0; // Use MySQL native LIMIT clause, so do not skip any rows before client side fetching
            break;

          case JDCConnection.DBMS_POSTGRESQL:
            if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + " OFFSET " + String.valueOf(iSkip) + ")");
            oRSet = oStmt.executeQuery(sSelect + " OFFSET " + String.valueOf(iSkip));
            iSkip = 0; // Use PostgreSQL native OFFSET clause, so do not skip any rows before client side fetching
            break;

          default:
            if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + ")");
            oRSet = oStmt.executeQuery(sSelect);
        } // end switch
      }

      if (DebugFile.trace) {
        DebugFile.writeln("query executed in " + String.valueOf(System.currentTimeMillis()-lQueryTime) + " ms");
        DebugFile.writeln("ResultSet.getMetaData()");
      }

      oMDat = oRSet.getMetaData();
      iColCount = oMDat.getColumnCount();
      ColNames = new String[iColCount];

      for (int c=1; c<=iColCount; c++) {
        ColNames[c-1] = oMDat.getColumnName(c).toLowerCase();
      }

      oMDat = null;

      setFetchSize(oConn, oRSet);

      iRows = fetchResultSet(oRSet,iSkip);

      if (DebugFile.trace) DebugFile.writeln("ResultSet.close()");

      oRSet.close();
      oRSet = null;

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.close()");

      oStmt.close();
      oStmt = null;

    }
    catch (SQLException sqle) {
      try { if (null!=oRSet) oRSet.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      try { if (null!=oStmt) oStmt.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      throw new SQLException(sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
    }
    catch (ArrayIndexOutOfBoundsException aiob) {
      try { if (null!=oRSet) oRSet.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      try { if (null!=oStmt) oStmt.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      throw new ArrayIndexOutOfBoundsException("DBSubset.load() " + aiob.getMessage());
    }
    catch (NullPointerException npe) {
      try { if (null!=oRSet) oRSet.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      try { if (null!=oStmt) oStmt.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      throw new NullPointerException("DBSubset.load()");
    }

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.load() : "+String.valueOf(iRows));
      }

    return iRows;
  } // load()

  // ----------------------------------------------------------

  /**
   * <p>Execute a JDBC Statement and load query ResultSet in an internal bidimensional matrix</p>
   * @param oConn Database Connection
   * @param aFilterValues Values to be binded and JDBC PreparedStatement query paramenters.
   * @return Number of rows retrieved
   * the maximum number of rows to be retrieved is determined by calling method
   * setMaxRows(), if setMaxRows() is not called before call() then all rows existing are retrieved.
   * @throws SQLException
   */

  public int load (JDCConnection oConn, Object[] aFilterValues)
    throws SQLException, ArrayIndexOutOfBoundsException, NullPointerException {

    return load(oConn, aFilterValues, 0);
  }

  /**
   * <p>Execute a JDBC Statement and load query ResultSet in an internal bidimensional matrix</p>
   * @param oConn Database Connection
   * @param aFilterValues Values to be binded and JDBC PreparedStatement query paramenters.
   * @param iSkip Number of rows to be skipped before reading. On database systems that support an
   * OFFSET clause (such as PostgreSQL) the native offset feature of the DBMS is used, in case that
   * the DBMS does not provide offset capabilities, the data is fetched and discarded at client side
   * before returning the DBSubset. Care must be taken when skipping a large number of rows in client
   * side mode as it may cause heavy network traffic and round trips to the database.
   * @return Number of rows retrieved
   * the maximum number of rows to be retrieved is determined by calling method
   * setMaxRows(), if setMaxRows() is not called before call() then all rows existing are retrieved.
   * @throws SQLException
   * @throws IllegalArgumentException if iSkip<0
   */

  // ----------------------------------------------------------

  public int load (JDCConnection oConn, Object[] aFilterValues, int iSkip)
    throws SQLException, IllegalArgumentException,
    ArrayIndexOutOfBoundsException, NullPointerException {

    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    ResultSetMetaData oMDat;

    int iRows = 0;
    int iType = (iSkip==0 ? ResultSet.TYPE_FORWARD_ONLY : ResultSet.TYPE_SCROLL_INSENSITIVE);
    long lQueryTime = 0;

    if (DebugFile.trace)
      DebugFile.writeln("Begin DBSubset.load([Connection], Object[]," + iSkip + ")");

    if (iSkip<0)
      throw new IllegalArgumentException("row offset must be equal to or greater than zero");

    if (null==oConn)
      throw new NullPointerException("DBSubset.load() JDCConnection parameter is null");

    if (DebugFile.trace)
      DebugFile.incIdent();

    try {

      if (iMaxRows>0) {

        switch (oConn.getDataBaseProduct()) {

          case JDCConnection.DBMS_MSSQL:
            if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSelect + " OPTION (FAST " + String.valueOf(iMaxRows) + ")" + ")");
            oStmt = oConn.prepareStatement(sSelect + " OPTION (FAST " + String.valueOf(iMaxRows) + ")", iType, ResultSet.CONCUR_READ_ONLY);
            break;

          case JDCConnection.DBMS_POSTGRESQL:
          case JDCConnection.DBMS_MYSQL:
            if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSelect + " LIMIT " + String.valueOf(iMaxRows+2) + " OFFSET " + String.valueOf(iSkip) + ")");
            oStmt = oConn.prepareStatement(sSelect + " LIMIT " + String.valueOf(iMaxRows+2) + " OFFSET " + String.valueOf(iSkip), ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
            iSkip = 0; // Use PostgreSQL native OFFSET clause, so do not skip any rows before client side fetching
            break;

          default:
            if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSelect + ")");
            oStmt = oConn.prepareStatement(sSelect, iType, ResultSet.CONCUR_READ_ONLY);
        } // end switch
      }

      else {
        switch (oConn.getDataBaseProduct()) {

          case JDCConnection.DBMS_POSTGRESQL:
            if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSelect + " OFFSET " + String.valueOf(iSkip) + ")");
            oStmt = oConn.prepareStatement(sSelect + " OFFSET " + String.valueOf(iSkip), ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
            iSkip = 0; // Use PostgreSQL native OFFSET clause, so do not skip any rows before client side fetching
            break;

          default:
            if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSelect + ")");
            oStmt = oConn.prepareStatement(sSelect, iType, ResultSet.CONCUR_READ_ONLY);
        } // end switch

      } // fi (iMaxRows)

      try { if (oConn.getDataBaseProduct()!=JDCConnection.DBMS_POSTGRESQL) oStmt.setQueryTimeout(iTimeOut); } catch (SQLException sqle) { if (DebugFile.trace) DebugFile.writeln("Error at PreparedStatement.setQueryTimeout(" + String.valueOf(iTimeOut) + ")" + sqle.getMessage()); }

      for (int p=0; p<aFilterValues.length; p++) {
        Object oParam = aFilterValues[p];
        if (null==oParam) {
          ParameterMetaData oParMDat = oStmt.getParameterMetaData();
          int pType;
          try {
          	pType = oParMDat.getParameterType(p+1);
          } catch (SQLException parameternotavailable) {
            if (DebugFile.trace) {
              DebugFile.writeln("DBSubset.load() : SQLException "+parameternotavailable.getMessage()+" at ParameterMetaData.getParameterType("+String.valueOf(p+1)+")");
      		}
      		pType = Types.NULL;
          }
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setNull("+String.valueOf(p+1)+","+String.valueOf(pType)+")");
          oStmt.setNull(p+1, pType);
        } else {
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setObject("+String.valueOf(p+1)+","+oParam.toString()+")");
          oStmt.setObject(p+1, oParam);
        } // fi
      } // next

      if (DebugFile.trace) {
        DebugFile.writeln("PreparedStatement.executeQuery()");
        lQueryTime = System.currentTimeMillis();
      }

      oRSet = oStmt.executeQuery();

      if (DebugFile.trace) {
        DebugFile.writeln("query executed in " + String.valueOf(System.currentTimeMillis()-lQueryTime) + " ms");
        DebugFile.writeln("ResultSet.getMetaData()");
      }

      oMDat = oRSet.getMetaData();
      iColCount = oMDat.getColumnCount();
      ColNames = new String[iColCount];

      for (int c=1; c<=iColCount; c++) {
        ColNames[c-1] = oMDat.getColumnName(c).toLowerCase();
      }
      oMDat = null;

      setFetchSize(oConn, oRSet);

      iRows = fetchResultSet(oRSet, iSkip);

      if (DebugFile.trace) DebugFile.writeln("ResultSet.close()");

      oRSet.close();
      oRSet = null;

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.close()");

      oStmt.close();
      oStmt = null;
    }
    catch (SQLException sqle) {
      try { 
      	if (DebugFile.trace) DebugFile.writeln("SQLException "+sqle.getMessage()+"\n"+StackTraceUtil.getStackTrace(sqle));
      } catch (java.io.IOException ignore) {}
      try { if (null!=oRSet) oRSet.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      try { if (null!=oStmt) oStmt.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      if (aFilterValues==null)  
        throw new SQLException(sqle.getMessage()+" "+sSelect+" with no parameters set", sqle.getSQLState(), sqle.getErrorCode());
      else if (aFilterValues.length==0)
        throw new SQLException(sqle.getMessage()+" "+sSelect+" with zero parameters set", sqle.getSQLState(), sqle.getErrorCode());
	  else {
	  	String sParams = "";
	  	for (int v=0; v<aFilterValues.length; v++)
	  	  sParams += (v==0 ? "" : ",") + aFilterValues[v];
        throw new SQLException(sqle.getMessage()+" "+sSelect+" with parameters "+sParams, sqle.getSQLState(), sqle.getErrorCode());	  
	  }
    }
    catch (ArrayIndexOutOfBoundsException aiob) {
      try { if (null!=oRSet) oRSet.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      try { if (null!=oStmt) oStmt.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      throw new ArrayIndexOutOfBoundsException("DBSubset.load() " + aiob.getMessage());
    }
    catch (NullPointerException npe) {
      try { if (null!=oRSet) oRSet.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      try { if (null!=oStmt) oStmt.close();
      } catch (Exception logit) { if (DebugFile.trace) DebugFile.writeln(logit.getClass().getName()+" "+logit.getMessage()); }
      throw new NullPointerException("DBSubset.load()");
    }

    if (DebugFile.trace)
      {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.load() : "+String.valueOf(iRows));
      }

    return iRows;
  } // load()

  // ----------------------------------------------------------

  /**
   * <p>Get list of distinct values for a column<p>
   * If column contains null values, those are never included at the output list
   * @param iCol Column to be searched [0..getColumnCount()-1]
   * @return ArrayList with distinct values.
   * @since 4.0
   */

  public ArrayList distinct (int iCol) throws ArrayIndexOutOfBoundsException {
  	final int nCount = getRowCount();
  	ArrayList oDistinct = new ArrayList(nCount);
  	HashMap oMap = new HashMap(nCount+10);
  	for (int iRow=0; iRow<nCount; iRow++) {
  	  Object oObj = get(iCol,iRow);
  	  if (null!=oObj) {
  	    if (!oMap.containsKey(oObj)) {
  	      oMap.put(oObj,oObj);
  	      oDistinct.add(oObj);
  	    } // fi
  	  } // fi  	  
  	} // next
  	return oDistinct;
	
  } // distinct

  // ----------------------------------------------------------

  /**
   * <p>Get maximum value for a column<p>
   * @param iCol Column index [0..getColumnCount()-1]
   * @return Maximum value for column
   * @since 7.0
   */

  public Comparable max (int iCol) throws ArrayIndexOutOfBoundsException {
  	final int nCount = getRowCount();
  	Comparable oMax = null;
  	for (int iRow=0; iRow<nCount; iRow++) {
  	  Comparable oObj = (Comparable) get(iCol,iRow);
  	  if (null!=oObj) {
  	  	if (null==oMax)
  	  	  oMax = oObj;
  	  	else if (oObj.compareTo(oMax)>0)
  	  	  oMax = oObj;
  	  } // fi
  	} // next
  	return oMax;	
  } // max

  // ----------------------------------------------------------

  /**
   * <p>Get minimum value for a column<p>
   * @param iCol Column index [0..getColumnCount()-1]
   * @return Minimum value for column
   * @since 7.0
   */

  public Comparable min (int iCol) throws ArrayIndexOutOfBoundsException {
  	final int nCount = getRowCount();
  	Comparable oMin = null;
  	for (int iRow=0; iRow<nCount; iRow++) {
  	  Comparable oObj = (Comparable) get(iCol,iRow);
  	  if (null!=oObj) {
  	  	if (null==oMin)
  	  	  oMin = oObj;
  	  	else if (oObj.compareTo(oMin)<0)
  	  	  oMin = oObj;
  	  } // fi
  	} // next
  	return oMin;	
  } // min

  // ----------------------------------------------------------

  /**
   * <p>Find first match of a value in a given column<p>
   * Value is searched by brute force from the begining to the end of the column.<br>
   * Trying to find a <b>null</b> value is allowed.<br>
   * For strings, find is case sensitive.
   * @param iCol Column to be searched [0..getColumnCount()-1]
   * @param oVal Value searched
   * @return Row where seached value was found or -1 is value was not found.
   */

  public int find (int iCol, Object oVal) throws ArrayIndexOutOfBoundsException {
    int iFound = -1;
    int iRowCount;
    Object objCol;

    if (DebugFile.trace) {
      if (null==oVal)
        DebugFile.writeln("Begin DBSubset.find(" + String.valueOf(iCol)+ ", null)");
      else
        DebugFile.writeln("Begin DBSubset.find(" + String.valueOf(iCol)+ ", " + oVal.toString() + ")");

      DebugFile.incIdent();
    }

    if (super.isEmpty())
      iRowCount = -1;
    else
      iRowCount = super.size();

    if (DebugFile.trace)
      DebugFile.writeln("row count is " + String.valueOf(iRowCount));

    for (int iRow=0; iRow<iRowCount; iRow++) {

      objCol = get(iCol,iRow);

      if (null!=objCol) {
        if (null!=oVal) {
            if (objCol.equals(oVal)) {
              iFound = iRow;
              break;
            }
        }
      }
      else if (null==oVal) {
        iFound = iRow;
        break;
      } // fi()

    } // next (iRow)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.find() : " + String.valueOf(iFound));
    }

    return iFound;
  } // find

  // ----------------------------------------------------------

  /**
   * <p>Find a String in a given column using case insensitive search<p>
   * Value is searched by brute force from the begining to the end of the column.<br>
   * Trying to find a <b>null</b> value is allowed.<br>
   * Find is case insensitive.
   * @param iCol Column to be searched [0..getColumnCount()-1]
   * @param sVal Value searched
   * @return Row where seached value was found or -1 is value was not found.
   * @since 4.0
   */

  public int findi (int iCol, String sVal) throws ArrayIndexOutOfBoundsException {
    int iFound = -1;
    int iRowCount;
    String strCol;

    if (DebugFile.trace) {
      if (null==sVal)
        DebugFile.writeln("Begin DBSubset.findi(" + String.valueOf(iCol)+ ", null)");
      else
        DebugFile.writeln("Begin DBSubset.findi(" + String.valueOf(iCol)+ ", " + sVal + ")");

      DebugFile.incIdent();
    }

    if (super.isEmpty())
      iRowCount = -1;
    else
      iRowCount = super.size();

    if (DebugFile.trace)
      DebugFile.writeln("row count is " + String.valueOf(iRowCount));

    for (int iRow=0; iRow<iRowCount; iRow++) {

      strCol = getStringNull(iCol,iRow,null);

      if (null!=strCol) {
        if (null!=sVal) {
            if (strCol.equalsIgnoreCase(sVal)) {
              iFound = iRow;
              break;
            }
        }
      }
      else if (null==sVal) {
        iFound = iRow;
        break;
      } // fi()

    } // next (iRow)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.findi() : " + String.valueOf(iFound));
    }

    return iFound;
  } // findi

  // ----------------------------------------------------------

  /**
   * </p>Find columns lexicographically close to a given one</p>
   * This method uses Levenshtein distance to compare a given value
   * with all not null values of a DBSubset column.
   * @param iCol int Position of column being searched [0..getRowCount()]
   * @param iRowGuidCol int Position of column holding the DBSubset primary key,
   * if it is -1 then a new GUID is automatically assigned to each new match.
   * @param sSought String being sought
   * @param nMaxResults int Maximum number of results to return
   * @param bAccents boolean If this parameter is <b>true</b> then search will be
   * case sensitive and accents will be taken into account, if it is <b>false</b>
   * then search will be case insensitive and accents will not be taken into account.
   * @param fThreshold float [0..100] The minimum match grade percentage that a result must reach in order to be included at the matches set
   * @throws IllegalArgumentException if fThreshold is not between 0 and 100
   * @throws ArrayIndexOutOfBoundsException
   * @return DBMatchSet
   * @since 4.0
   */
  public DBMatchSet findClose(int iCol, int iRowGuidCol,
  							  String sSought, int nMaxResults,
  							  boolean bAccents, float fThreshold)
    throws IllegalArgumentException,ArrayIndexOutOfBoundsException {

    final int iRowCount = getRowCount();
    
    if (fThreshold<0f || fThreshold>100f) throw new IllegalArgumentException("DBSubset.findClose() Match threshold must be between 0 and 100");

	if (nMaxResults<0) nMaxResults = iRowCount;

    DBMatchSet oMSet = new DBMatchSet(nMaxResults);
    
    if (sSought!=null) {
	  if (!bAccents) sSought = Gadgets.ASCIIEncode(sSought).toUpperCase();
      final int iLenSght = sSought.length();
	  for (int iRow=0; iRow<iRowCount; iRow++) {
	    if (!isNull(iCol, iRow)) {
	  	  String sSearched = getString(iCol,iRow);
	  	  if (!bAccents) sSearched = Gadgets.ASCIIEncode(sSearched).toUpperCase();
		  int iLenSrch = sSearched.length();
		  float fMaxLen = (float) (iLenSrch>iLenSght ? iLenSrch : iLenSght);
		  float fLevDis = (float) Gadgets.getLevenshteinDistance(sSearched, sSought);
		  float fMatchGrade =  100f*(1f-(fLevDis/fMaxLen));
		  if (fMatchGrade>=fThreshold) {
		  	if (-1==iRowGuidCol)
		  	  oMSet.put(Gadgets.generateUUID(), getString(iCol,iRow), iRow, fMatchGrade);
			else
		  	  oMSet.put(get(iRowGuidCol,iRow).toString(), getString(iCol,iRow), iRow, fMatchGrade);
		  } // fi (fMatchGrade>fThreshold)
	    } // fi
	  } // next
    } // fi (sSought)
    return oMSet;
  } // findClose

  // ----------------------------------------------------------

  /**
   * <p>Find a Comparable object using binary search<p>
   * The searched column must have been previously sorted in ascending order.<br>
   * Trying to find <b>null</b> always return -1 even thought the column contains indeed a <b>null</b> value.<br>
   * @param iCol Column to be searched [0..getColumnCount()-1]
   * @param oVal Value searched
   * @return Row where seached value was found or -1 if value was not found.
   * @throws ClassCastException if column iCol is not Comparable
   * @since 4.0
   */

  public int binaryFind(int iCol, Comparable oVal)
  	throws ClassCastException {
    int iFound = -1;
	int iLow = 0;
	int iHigh = getRowCount()-1;

    if (DebugFile.trace) {
      if (null==oVal)
        DebugFile.writeln("Begin DBSubset.binaryFind(" + String.valueOf(iCol)+ ", null)");
      else
        DebugFile.writeln("Begin DBSubset.binaryFind(" + String.valueOf(iCol)+ ", " + oVal.toString() + ")");
      DebugFile.incIdent();
    }
	
	if (oVal!=null) {
	  while (iLow<=iHigh) {
	  	Comparable oCmp;
	  	int iComparison;
	  	    
 		if (iLow==iHigh) {
	      oCmp = (Comparable) get(iCol, iLow);
	  	  iComparison = oCmp.compareTo(oVal);
		  if (0==iComparison) iFound = iLow;
	  	  break;	  	
 		} else if (iLow==iHigh-1) {
	      oCmp = (Comparable) get(iCol, iLow);
	  	  iComparison = oCmp.compareTo(oVal);
		  if (0==iComparison) iFound = iLow;
	      oCmp = (Comparable) get(iCol, iHigh);
	  	  iComparison = oCmp.compareTo(oVal);
		  if (0==iComparison) iFound = iHigh;
	  	  break;	  	  
	  	} else {
          int iMid = (iLow + iHigh) / 2;
	      oCmp = (Comparable) get(iCol, iMid);
	      iComparison = oCmp.compareTo(oVal);
		  if (0==iComparison) {
		    iFound = iMid;
		    break;
		  } else if (iComparison>0) {
		    iHigh = iMid - 1;
		  } else {
            iLow = iMid + 1;
		  }
	  	} // fi
	  } // wend
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.binaryFind() : " + String.valueOf(iFound));
    }

	return iFound;
  } // binaryFind

  // ----------------------------------------------------------

  /**
   * @return Column delimiter for print() and toString() methods.
   */
  public String getColumnDelimiter() {
    return sColDelim;
  }

  // ----------------------------------------------------------

  /**
   * @param sDelim Column delimiter for print() and toString() methods.
   * The default delimiter is '&grave;' character
   */
  public void setColumnDelimiter(String sDelim) {
    sColDelim=sDelim;
  }

  // ----------------------------------------------------------

  /**
   * @return Row delimiter for print() and toString() methods.
   */
  public String getRowDelimiter() {
    return sRowDelim;
  }

  // ----------------------------------------------------------

  /**
   * @param sDelim Row delimiter for print() and toString() methods.
   * The default delimiter is '&uml;' character
   */

  public void setRowDelimiter(String sDelim) {
    sRowDelim=sDelim;
  }

  // ----------------------------------------------------------

  /**
   * @return Text qualifier for quoting fields in print() and toString() methods.
   */
  public String getTextQualifier() {
    return sTxtQualifier;
  }

  // ----------------------------------------------------------

  /**
   * @param sQualifier Text qualifier for quoting fields in print() and toString() methods.
   */
  public void setTextQualifier(String sQualifier) {
    sTxtQualifier=sQualifier;
  }

  // ----------------------------------------------------------

  /**
   * @return Number of columns retrieved.
   */
  public int getColumnCount() {
    return iColCount;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get column names</p>
   * @return String[] An array with names of columns from the most recently SQL SELECT sentence.
   * @since 3.0
   */
  public String[] getColumnNames() {
    return ColNames;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get name for column given its index</p>
   * @param iColumnPosition [0..getColumnCount()-1]
   * @return String Column Name
   * @since 5.0
   */
  public String getColumnName(int iColumnPosition) throws ArrayIndexOutOfBoundsException {
    return ColNames[iColumnPosition];
  }

  // ----------------------------------------------------------

  /**
   * @param sColumnName Name of column witch position is to be returned. Column names are case insensitive.
   * @return Column position or -1 if no column with such name exists.
   */
  public int getColumnPosition(String sColumnName) {
    int iColPos = -1;

    for (int iCol=0; iCol<iColCount; iCol++) {
      if (sColumnName.equalsIgnoreCase(ColNames[iCol])) {
        iColPos = iCol;
        break;
      }
    } // endfor

    return iColPos;
  } // getColumnPosition

  // ----------------------------------------------------------

  /**
   * @return number of rows retrieved by last call() or load() method invocation.
   */
  public int getRowCount() {
    int iRows;

    if (super.isEmpty())
      iRows = 0;
    else
      iRows = super.size();

    return iRows;

  } // getRowCount

  // ----------------------------------------------------------

  /**
   * Get DBSubset column as a List interface
   * @param iCol int Column position [0..getColumnCount()-1]
   * @return List
   * @throws ArrayIndexOutOfBoundsException
   * @throws IllegalStateException if DBSubset has not been loaded
   */
  public List getColumnAsList (int iCol)
    throws ArrayIndexOutOfBoundsException,IllegalStateException {
    Vector oRow, oCol;
    int iRowCount;
    if (super.isEmpty())
      throw new IllegalStateException("DBSubset.getColumnAsList("+String.valueOf(iCol)+") DBSubset not loaded");
    else
      iRowCount = super.size();
    if (0==iRowCount) {
      oCol = new Vector();
    } else {
      oCol = new Vector(iRowCount);
      for (int iRow=0; iRow<iRowCount; iRow++) {
        oRow = (Vector) super.get(iRow);
        oCol.add(oRow.get(iCol));
      } // next
    }
    return oCol;
  } // getColumnAsList

  // ----------------------------------------------------------

  /**
   * Get DBSubset row as a List interface
   * @param iRow int Row position [0..getRowCount()-1]
   * @return List
   * @throws ArrayIndexOutOfBoundsException
   * @throws IllegalStateException if DBSubset has not been loaded
   */
  public List getRowAsList (int iRow)
    throws ArrayIndexOutOfBoundsException,IllegalStateException {
    if (super.isEmpty())
      throw new IllegalStateException("DBSubset.getRowAsList("+String.valueOf(iRow)+") DBSubset not loaded");
    else
      return (List) super.get(iRow);
  } // getRowAsList

  // ----------------------------------------------------------

  /**
   * Get DBSubset row as a Map interface
   * @param iRow int Row position [0..getRowCount()-1]
   * @return HashMap<String,Object>
   * @throws ArrayIndexOutOfBoundsException
   * @throws IllegalStateException if DBSubset has not been loaded
   */
  public HashMap<String,Object> getRowAsMap (int iRow)
    throws ArrayIndexOutOfBoundsException,IllegalStateException {
    if (super.isEmpty())
      throw new IllegalStateException("DBSubset.getRowAsMap("+String.valueOf(iRow)+") DBSubset not loaded");

    Vector oRow = (Vector) super.get(iRow);
    HashMap<String,Object> oRetVal = new HashMap(iColCount*2);

    for (int iCol=0; iCol<iColCount; iCol++) {
      oRetVal.put(ColNames[iCol], oRow.get(iCol));
    } // endfor

    return oRetVal;
  } // getRowMap

  // ----------------------------------------------------------

  /**
   * Get DBSubset row as a Vector
   * @param iRow int Row position [0..getRowCount()-1]
   * @return Vector
   * @throws ArrayIndexOutOfBoundsException
   * @throws IllegalStateException if DBSubset has not been loaded
   * @since 3.0
   */
  public Vector getRowAsVector (int iRow)
    throws ArrayIndexOutOfBoundsException,IllegalStateException {
    if (super.isEmpty())
      throw new IllegalStateException("DBSubset.getRowAsList("+String.valueOf(iRow)+") DBSubset not loaded");
    else
      return (Vector) super.get(iRow);
  } // getRowAsVector

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded field</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ArrayIndexOutOfBoundsException
   */
  public Object get (int iCol, int iRow) throws ArrayIndexOutOfBoundsException {
    return ((Vector) super.get(iRow)).get(iCol);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded field by name</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ArrayIndexOutOfBoundsException If no column with such name was found
   */
  public Object get (String sCol, int iRow)
    throws ArrayIndexOutOfBoundsException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return ((Vector) super.get(iRow)).get(iCol);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Boolean field</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return <b>boolean</b> value for field.
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   */
  public boolean getBoolean (int iCol, int iRow)
    throws ClassCastException,ArrayIndexOutOfBoundsException,NullPointerException {

    boolean bRetVal;
    Object oObj = get(iCol, iRow);

    if (oObj.getClass().equals(Integer.TYPE))

      bRetVal = (((Integer)oObj).intValue()!=0 ? true : false);

    else if (oObj.getClass().equals(Short.TYPE))
      bRetVal = (((Short)oObj).shortValue()!=(short)0 ? true : false);

    else
      bRetVal = ((Boolean) get(iCol, iRow)).booleanValue();

    return bRetVal;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @version 3.1
   */

  public java.util.Date getDate(int iCol, int iRow)
    throws ClassCastException,ArrayIndexOutOfBoundsException {
    Object oDt = ((Vector) super.get(iRow)).get(iCol);

    if (null!=oDt) {
      if (oDt.getClass().equals(ClassUtilDate))
        return (java.util.Date) oDt;
      else if (oDt.getClass().equals(ClassTimestamp))
        return new java.util.Date(((java.sql.Timestamp) oDt).getTime());
      else if (oDt.getClass().equals(ClassSQLDate))
        return new java.util.Date(((java.sql.Date) oDt).getYear(), ((java.sql.Date) oDt).getMonth(), ((java.sql.Date) oDt).getDate());
      else if (oDt.getClass().equals(ClassLangString)) {
        if (null==oDateTime24) oDateTime24 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        try {
          return oDateTime24.parse((String) oDt);
        } catch (java.text.ParseException pe) {
        	throw new ClassCastException("Cannot parse Date " + oDt);
        }
      }
      else
        throw new ClassCastException("Cannot cast " + oDt.getClass().getName() + " to Date");
    }
    else
      return null;

  } // getDate()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return java.sql.Date
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @since 3.0
   */

  public java.sql.Date getSQLDate(int iCol, int iRow)
    throws ClassCastException,ArrayIndexOutOfBoundsException {
    Object oDt = ((Vector) super.get(iRow)).get(iCol);

    if (null!=oDt) {
      if (oDt.getClass().equals(ClassSQLDate))
        return (java.sql.Date) oDt;
      else if (oDt.getClass().equals(ClassTimestamp))
        return new java.sql.Date(((java.sql.Timestamp) oDt).getTime());
      else if (oDt.getClass().equals(ClassUtilDate))
        return new java.sql.Date(((java.util.Date) oDt).getTime());
      else
        throw new ClassCastException("Cannot cast " + oDt.getClass().getName() + " to Date");
    }
    else
      return null;
  } // getSQLDate()

  /**
   * <p>Get pre-loaded value for a Date field</p>
   * @param sCol String Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @return java.sql.Date
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @since 3.0
   */
  public java.sql.Date getSQLDate (String sCol, int iRow) throws ArrayIndexOutOfBoundsException {
    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException("Column " + sCol + " not found");

    return getSQLDate(iCol, iRow);
  } // getSQLDate()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Time field</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @since 3.0
   */

  public java.sql.Time getSQLTime(int iCol, int iRow)
    throws ClassCastException,ArrayIndexOutOfBoundsException {
    Object oDt = ((Vector) super.get(iRow)).get(iCol);

    if (null!=oDt) {
      if (oDt.getClass().equals(ClassSQLTime))
        return (java.sql.Time) oDt;
      else if (oDt.getClass().equals(ClassTimestamp))
        return new java.sql.Time(((java.sql.Timestamp) oDt).getTime());
      else if (oDt.getClass().equals(ClassUtilDate))
        return new java.sql.Time(((java.util.Date) oDt).getTime());
      else
        throw new ClassCastException("Cannot cast " + oDt.getClass().getName() + " to Time");
    }
    else
      return null;
  } // getTime()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Time field</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @return Time
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @since 3.0
   */
  public java.sql.Time getSQLTime (String sCol, int iRow)
    throws ClassCastException, ArrayIndexOutOfBoundsException {
    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException("Column " + sCol + " not found");

    return getSQLTime(iCol, iRow);
  } // getSQLTime()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException if column is not found
   */

  public java.util.Date getDate (String sCol, int iRow) throws ArrayIndexOutOfBoundsException {
    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException("Column " + sCol + " not found");

    return getDate(iCol, iRow);
  } // getDate()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field formated as a short Date "yyyy-MM-dd"</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return String with format "yyyy-MM-dd" or <b>null</b>.
   * @throws ClassCastException
   */
  public String getDateShort(int iCol, int iRow) {
    java.util.Date oDt = getDate(iCol, iRow);

    if (null==oShortDate) oShortDate = new SimpleDateFormat("yyyy-MM-dd");

    if (null!=oDt)
      return oShortDate.format(oDt);
    else
      return null;

  } // getDateShort()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field formated as a DateTime "yyyy-MM-dd HH:mm:ss"</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return String with format "yyyy-MM-dd HH:mm:ss" or <b>null</b>.
   * @throws ClassCastException
   * @since 2.1
   */

  public String getDateTime24(int iCol, int iRow) {
    java.util.Date oDt = getDate(iCol, iRow);

    if (null==oDateTime24) oDateTime24 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    if (null!=oDt)
      return oDateTime24.format(oDt);
    else
      return null;

  } // getDateTime24()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field formated as a DateTime "yyyy-MM-dd hh:mm:ss"</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @return String with format "yyyy-MM-dd hh:mm:ss" or <b>null</b>.
   */

  public String getDateTime(int iCol, int iRow)
    throws ClassCastException, ArrayIndexOutOfBoundsException {

    java.util.Date oDt = getDate(iCol, iRow);

    if (null==oDateTime) oDateTime = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");

    if (null!=oDt)
      return oDateTime.format(oDt);
    else
      return null;
  } // getDateTime()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field formated with a used defind formar</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @param sFormat Date Format (like "yyyy-MM-dd HH:mm:ss")
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @return Date value formated as String.
   * @see java.text.SimpleDateFormat
   */

  public String getDateFormated(int iCol, int iRow, String sFormat)
    throws ArrayIndexOutOfBoundsException, ClassCastException {

    java.util.Date oDt = getDate(iCol, iRow);
    SimpleDateFormat oSimpleDate;

    if (null!=oDt) {
      oSimpleDate = new SimpleDateFormat(sFormat);
      return oSimpleDate.format(oDt);
    }
    else
      return null;
  } // getDateFormated()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value for a Date field formated with a used defind formar</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @param oFmt Date Format
   * @throws ClassCastException
   * @throws ArrayIndexOutOfBoundsException
   * @return Date value formated as String.
   * @since 4.0
   */

  public String getDateFormated(int iCol, int iRow, SimpleDateFormat oFmt)
    throws ArrayIndexOutOfBoundsException, ClassCastException {

    java.util.Date oDt = getDate(iCol, iRow);

    if (null!=oDt)
      return oFmt.format(oDt);
    else
      return null;

  } // getDateFormated()

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a Short</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws NullPointerException If field value is <b>null</b>
   * @throws ArrayIndexOutOfBoundsException
   */

  public short getShort (int iCol, int iRow)
    throws NullPointerException,ArrayIndexOutOfBoundsException {

    Object oVal = (((Vector) super.get(iRow)).get(iCol));
    Class oCls;
    short iRetVal;

    oCls = oVal.getClass();

    try {
      if (oCls.equals(Short.TYPE))
        iRetVal = ((Short) oVal).shortValue();
      else if (oCls.equals(Integer.TYPE))
        iRetVal = (short) ((Integer) oVal).intValue();
      else if (oCls.equals(Class.forName("java.math.BigDecimal")))
        iRetVal = (short) ((java.math.BigDecimal) oVal).intValue();
      else if (oCls.equals(Float.TYPE))
        iRetVal = (short) ((Float) oVal).intValue();
      else if (oCls.equals(Double.TYPE))
        iRetVal = (short) ((Double) oVal).intValue();
      else
        iRetVal = new Short(oVal.toString()).shortValue();
    } catch (ClassNotFoundException cnfe) { /* never thrown */ iRetVal = (short)0; }

    return iRetVal;
  } // getShort

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a Short</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @throws NullPointerException If field value is <b>null</b>
   * @throws ArrayIndexOutOfBoundsException
   * @since 4.0
   */
  public short getShort (String sCol, int iRow)
    throws NullPointerException,ArrayIndexOutOfBoundsException {
  
    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

	return getShort(iCol, iRow);
  } // getShort
    
  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a int</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws NullPointerException If field value is <b>null</b>
   * @throws ArrayIndexOutOfBoundsException
   */

  public int getInt (int iCol, int iRow)
    throws NullPointerException,ArrayIndexOutOfBoundsException {

    Object oVal = (((Vector) super.get(iRow)).get(iCol));

    if (oVal.getClass().equals(Integer.TYPE))
      return ((Integer)oVal).intValue();
    else
      return getInteger(iCol, iRow).intValue();
  }

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a Short</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ArrayIndexOutOfBoundsException if column is not found
   * @throws NullPointerException If field value is <b>null</b>
   */

  public int getInt (String sCol, int iRow)
    throws ArrayIndexOutOfBoundsException, NullPointerException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException("Column " + sCol + " not found");

    Object oVal = (((Vector) super.get(iRow)).get(iCol));

    if (oVal.getClass().equals(Integer.TYPE))

      return ((Integer)oVal).intValue();

    else

      return getInteger(iCol, iRow).intValue();

  } // getInt

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a double</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws NullPointerException If field value is <b>null</b>
   * @throws ArrayIndexOutOfBoundsException
   */

  public double getDouble (int iCol, int iRow)
    throws NullPointerException,ArrayIndexOutOfBoundsException {

    Object oVal = (((Vector) super.get(iRow)).get(iCol));
    Class oCls;
    double dRetVal;

    oCls = oVal.getClass();

    try {
      if (oCls.equals(Short.TYPE))
        dRetVal = (double) ((Short) oVal).shortValue();
      else if (oCls.equals(Integer.TYPE))
        dRetVal = (double) ((Integer) oVal).intValue();
      else if (oCls.equals(Class.forName("java.math.BigDecimal")))
        dRetVal = ((java.math.BigDecimal) oVal).doubleValue();
      else if (oCls.equals(Float.TYPE))
        dRetVal = ((Float) oVal).doubleValue();
      else if (oCls.equals(Double.TYPE))
        dRetVal = ((Double) oVal).doubleValue();
      else
        dRetVal = new Double(Gadgets.removeChar(oVal.toString(),',')).doubleValue();
    } catch (ClassNotFoundException cnfe) { /* never thrown */ dRetVal = 0d; }

    return dRetVal;
  } // getDouble

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a float</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @throws NullPointerException If field value is <b>null</b>
   * @throws ArrayIndexOutOfBoundsException
   */

  public float getFloat (int iCol, int iRow)
    throws NullPointerException,ArrayIndexOutOfBoundsException {

    Object oVal = (((Vector) super.get(iRow)).get(iCol));
    Class oCls;
    float fRetVal;

    oCls = oVal.getClass();

    try {
      if (oCls.equals(Short.TYPE))
        fRetVal = (float) ((Short) oVal).shortValue();
      else if (oCls.equals(Integer.TYPE))
        fRetVal = (float) ((Integer) oVal).intValue();
      else if (oCls.equals(Class.forName("java.math.BigDecimal")))
        fRetVal = ((java.math.BigDecimal) oVal).floatValue();
      else if (oCls.equals(Float.TYPE))
        fRetVal = ((Float) oVal).floatValue();
      else if (oCls.equals(Double.TYPE))
        fRetVal = ((Double) oVal).floatValue();
      else
        fRetVal = new Float(Gadgets.removeChar(oVal.toString(),',')).floatValue();
    } catch (ClassNotFoundException cnfe) { /* never thrown */ fRetVal = 0f; }

    return fRetVal;
  } // getFloat

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a Short</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @throws ArrayIndexOutOfBoundsException if column is not found
   * @throws NullPointerException If field value is <b>null</b>
   */

  public float getFloat (String sCol, int iRow)
    throws NullPointerException,ArrayIndexOutOfBoundsException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getFloat(iCol, iRow);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a float</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @param iDecimals Decimal places for float value
   * @throws ArrayIndexOutOfBoundsException if column is not found
   * @throws NullPointerException If field value is <b>null</b>
   */

  public float getFloat (int iCol, int iRow, int iDecimals)
    throws NullPointerException,ArrayIndexOutOfBoundsException {

    float p, f = getFloat (iCol, iRow);
    int i;

    if (0==iDecimals)

      return (float) ((int) f);

    else {

      p = 10f;
      for (int d=0; d<iDecimals; d++) p*=10;
      i = (int) (f * p);

      return  ((float)i) / p;
    }
  } // getFloat

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a float</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @param iDecimals Decimal places for float value
   * @throws ArrayIndexOutOfBoundsException if column is not found
   * @throws NullPointerException If field value is <b>null</b>
   */

  public float getFloat (String sCol, int iRow, int iDecimals)
    throws ArrayIndexOutOfBoundsException, NullPointerException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getFloat(iCol, iRow, iDecimals);
  } // getFloat

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into an Integer</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return Field value converted to Integer or <b>null</b> if field was NULL.
   */

  public Integer getInteger (int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException {

    Object oVal = (((Vector) super.get(iRow)).get(iCol));
    Class oCls;
    Integer iRetVal;

    if (null==oVal) return null;

    oCls = oVal.getClass();

    try {
      if (oCls.equals(Short.TYPE))
        iRetVal = new Integer(((Short) oVal).intValue());
      else if (oCls.equals(Integer.TYPE))
        iRetVal = (Integer) oVal;
      else if (oCls.equals(Class.forName("java.math.BigDecimal")))
        iRetVal = new Integer(((java.math.BigDecimal) oVal).intValue());
      else if (oCls.equals(Float.TYPE))
        iRetVal = new Integer(((Float) oVal).intValue());
      else if (oCls.equals(Double.TYPE))
        iRetVal = new Integer(((Double) oVal).intValue());
      else
        iRetVal = new Integer(oVal.toString());
    } catch (ClassNotFoundException cnfe) { /* never thrown */ iRetVal = null; }

    return iRetVal;

  } // getInteger

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a Long</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return Field value converted to Integer or <b>null</b> if field was NULL.
   * @since 5.0
   */

  public Long getLong (int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException {

    Object oVal = (((Vector) super.get(iRow)).get(iCol));
    Class oCls;
    Long iRetVal;

    if (null==oVal) return null;

    oCls = oVal.getClass();

    try {
      if (oCls.equals(Short.TYPE))
        iRetVal = new Long(((Short) oVal).shortValue());
      else if (oCls.equals(Integer.TYPE))
        iRetVal = new Long(((Integer) oVal).intValue());
      else if (oCls.equals(Long.TYPE))
        iRetVal = (Long) oVal;
      else if (oCls.equals(Class.forName("java.math.BigDecimal")))
        iRetVal = new Long(((java.math.BigDecimal) oVal).longValue());
      else if (oCls.equals(Float.TYPE))
        iRetVal = new Long(((Float) oVal).longValue());
      else if (oCls.equals(Double.TYPE))
        iRetVal = new Long(((Double) oVal).longValue());
      else
        iRetVal = new Long(oVal.toString());
    } catch (ClassNotFoundException cnfe) { /* never thrown */ iRetVal = null; }

    return iRetVal;

  } // getLong

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into an Integer</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @return Field value converted to Integer or <b>null</b> if field was NULL.
   * @throws ArrayIndexOutOfBoundsException if column is not found
   */

  public Integer getInteger (String sCol, int iRow)
    throws ArrayIndexOutOfBoundsException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getInteger(iCol, iRow);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a BigDecimal</p>
   * If column is NULL then <b>null</b> value is returned.<BR>
   * If base columnn is of type String then thsi function will try to parse the
   * value into a BigDecimal. A single dot '.' is used as decimal delimiter no
   * matter which is the current locale. All comma characters ',' are removed
   * before parsing String into BigDecimal.
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return Field value converted to BigDecimal or <b>null</b> if field was NULL.
   * @throws java.lang.ClassCastException
   * @throws java.lang.NumberFormatException
   */

  public BigDecimal getDecimal (int iCol, int iRow)
    throws java.lang.ClassCastException, java.lang.NumberFormatException {
    Object oVal = (((Vector) super.get(iRow)).get(iCol));
    Class oCls;
    BigDecimal oDecVal;

    if (oVal==null) return null;

    oCls = oVal.getClass();

      if (oCls.equals(Short.TYPE))
        oDecVal = new BigDecimal(((Short) oVal).doubleValue());
      else if (oCls.equals(Integer.TYPE))
        oDecVal = new BigDecimal(((Integer) oVal).doubleValue());
      else if (oCls.equals(Float.TYPE))
        oDecVal = new BigDecimal(((Float) oVal).doubleValue());
      else if (oCls.equals(Double.TYPE))
        oDecVal = new BigDecimal(((Double) oVal).doubleValue());
      else if (oCls.getName().equalsIgnoreCase("java.lang.String"))
        oDecVal = new BigDecimal(Gadgets.removeChar((String) oVal, ','));
      else {
        try {
          oDecVal = (BigDecimal) oVal;
        } catch (ClassCastException cce) {
          throw new ClassCastException("Cannot cast column of type " + oVal.getClass().getName() + " to BigDecimal");
        }
      }

    return oDecVal;
  } // getDecimal

  // ----------------------------------------------------------

  /**
   * <p>Get pre-loaded value and tries to convert it into a BigDecimal</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @return Field value converted to BigDecimal or <b>null</b> if field was NULL.
   * @throws ArrayIndexOutOfBoundsException if column is not found
   */
  public BigDecimal getDecimal (String sCol, int iRow)
    throws ArrayIndexOutOfBoundsException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getDecimal(iCol, iRow);
  } // getDecimal

  // ----------------------------------------------------------

  /**
   * <p>Get decimal formated as a String using the given pattern and the symbols for the default locale</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @param sPattern A non-localized pattern string, for example: "#0.00"
   * @return String decimal value formated according to sPatern or <b>null</b>
   * @throws ClassCastException
   * @throws NumberFormatException
   * @throws NullPointerException if sPattern is <b>null</b>
   * @throws IllegalArgumentException if sPattern is invalid
   */
  public String getDecimalFormated (int iCol, int iRow, String sPattern)
    throws java.lang.ClassCastException, java.lang.NumberFormatException,
    java.lang.NullPointerException, java.lang.IllegalArgumentException {
    BigDecimal oDecVal = getDecimal(iCol, iRow);

    if (null==oDecVal) {
      return null;
    } else {
      if (oDecFmt==null) {
        oDecFmt = new DecimalFormat(sPattern);
        return oDecFmt.format(oDecVal.doubleValue());
      } else {
        if (oDecFmt.toPattern().equals(sPattern)) {
          return oDecFmt.format(oDecVal.doubleValue());
        } else {
          oDecFmt = new DecimalFormat(sPattern);
          return oDecFmt.format(oDecVal.doubleValue());
        }
      }
    }
  } // getDecimalFormated

  // ----------------------------------------------------------

  /**
   * <p>Get decimal formated as a String using the given pattern and the symbols for the default locale</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @param sPattern A non-localized pattern string, for example: "#0.00"
   * @return String decimal value formated according to sPatern or <b>null</b>
   * @throws ClassCastException
   * @throws NumberFormatException
   * @throws NullPointerException if sPattern is <b>null</b>
   * @throws IllegalArgumentException if sPattern is invalid
   * @throws ArrayIndexOutOfBoundsException if column is not found
   */
  public String getDecimalFormated (String sCol, int iRow, String sPattern)
    throws java.lang.ClassCastException, java.lang.NumberFormatException,
           java.lang.NullPointerException, java.lang.IllegalArgumentException,
           java.lang.ArrayIndexOutOfBoundsException {

    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getDecimalFormated(iCol, iRow, sPattern);
  } // getDecimalFormated

  // ----------------------------------------------------------

  /**
   * <p>Get value of a VARCHAR field that holds a money+currency amount<p>
   * Money values are stored with its currency sign embedded inside,
   * like "26.32 USD" or "$48.3" or "35.44 €"
   * @param iCol int Column position [0..getColumnCount()-1]
   * @param iRow int Row position [0..getRowCount()-1]
   * @return com.knowgate.math.Money
   * @throws ArrayIndexOutOfBoundsException
   * @throws NumberFormatException
   * @since 3.0
   */
  public Money getMoney(int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException,NumberFormatException {
    Object obj = (((Vector) super.get(iRow)).get(iCol));

    if (null!=obj)
      if (obj.toString().length()>0)
        return Money.parse(obj.toString());
      else
        return null;
    else
      return null;
  } // getMoney

  // ----------------------------------------------------------

  /**
   * <p>Get value of a VARCHAR field that holds a money+currency amount<p>
   * Money values are stored with its currency sign embedded inside,
   * like "26.32 USD" or "$48.3" or "35.44 €"
   * @param iCol int Column position [0..getColumnCount()-1]
   * @param iRow int Row position [0..getRowCount()-1]
   * @return com.knowgate.math.Money
   * @throws ArrayIndexOutOfBoundsException if column is not found
   * @throws NumberFormatException
   * @since 3.0
   */
  public Money getMoney(String sCol, int iRow)
    throws ArrayIndexOutOfBoundsException,NumberFormatException {
    int iCol = getColumnPosition(sCol);

    if (iCol==-1) throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    return getMoney(iCol, iRow);
  } // getMoney

  // ----------------------------------------------------------

  /**
   * <p>Get toString() form of pre-loaded value</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return Field value converted to String or <b>null</b> if field was NULL.
   * @throws ArrayIndexOutOfBoundsException
   */

  public String getString (int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException {

    Object obj = (((Vector) super.get(iRow)).get(iCol));

    if (null!=obj)
      return obj.toString();
    else
      return null;

  } // getString

  // ----------------------------------------------------------

  /**
   * <p>Get toString() form of pre-loaded value</p>
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @param sDef Default value
   * @return Field value converted to String default value sDef if field was NULL.
   */

  public String getStringNull (int iCol, int iRow, String sDef)
    throws ArrayIndexOutOfBoundsException{
    String str = getString(iCol,iRow);

    return (null!=str ? str : sDef);

  } // getStringNull

  // ----------------------------------------------------------

  /**
   * <p>Get toString() form of pre-loaded value</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @return Field value converted to String or <b>null</b> if field was NULL.
   * @throws ArrayIndexOutOfBoundsException if column is not found
   */

  public String getString (String sCol, int iRow)
    throws ArrayIndexOutOfBoundsException {
    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    Object obj = (((Vector) super.get(iRow)).get(iCol));

    if (null!=obj)
      return obj.toString();
    else
      return null;
  } // getString

  // ----------------------------------------------------------

  /**
   * <p>Get toString() form of pre-loaded value</p>
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @param sDef Default value
   * @return Field value converted to String default value sDef if field was NULL.
   * @throws ArrayIndexOutOfBoundsException if column is not found
   */

  public String getStringNull (String sCol, int iRow, String sDef)
    throws ArrayIndexOutOfBoundsException {
    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    String str = getString(iCol,iRow);

    return (null!=str ? str : sDef);
  } // getStringNull

  // ----------------------------------------------------------

  /**
   * <p>Get value for a CHAR, VARCHAR or LONGVARCHAR field replacing <b>null</b>
   * with a default value and replacing non-ASCII and quote values with &#<i>code</i>;<p>
   * @param iCol Column index
   * @param iRow Row position [0..getRowCount()-1]
   * @param sDef Default value
   * @return Field value or default value encoded as HTML numeric entities.
   * @since 5.5
   */

  public String getStringHtml(int iCol, int iRow, String sDef)
    throws ArrayIndexOutOfBoundsException {
    String sStr = getString(iCol,iRow);
    if (null==sStr) sStr = sDef;
	try {
    if (null!=sStr)
      sStr = Gadgets.replace(Gadgets.replace(Gadgets.replace(Gadgets.replace(Gadgets.XHTMLEncode(sStr),"\"", "&#34;"),"'", "&#39;"),"<","&lt;"),">","&gt;");
	} catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }
	return sStr;
  } // getStringHtml

  // ----------------------------------------------------------

  /**
   * Get Time column
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return java.sql.Time
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   * @since 3.0
   */
  public Time getTimeOfDay (int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException, ClassCastException {

    Object obj = (((Vector) super.get(iRow)).get(iCol));

    if (null!=obj)
      return (Time) obj;
    else
      return null;
  } // getTimeOfDay

  // ----------------------------------------------------------

  /**
   * Get Timestamp columnn
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return java.sql.Timestamp
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   * @since 2.2
   */
  public Timestamp getTimestamp(int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException,ClassCastException {
    Object obj = (((Vector) super.get(iRow)).get(iCol));

    if (null!=obj) {
      if (obj instanceof Timestamp)
        return (Timestamp) obj;
      else if (obj instanceof Date)
        return new Timestamp(((Date)obj).getTime());
      else
        throw new ClassCastException("Cannot cast "+obj.getClass().getName()+" to Timestamp");
    }
    else
      return null;
  }

  // ----------------------------------------------------------

  /**
   * Returns the number of milliseconds since January 1, 1970, 00:00:00 GMT
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return long Miliseconds or zero if column is <b>null</b>
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   * @since 2.2
   */
  public long getTimeMilis(int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException,ClassCastException {
    Object obj = (((Vector) super.get(iRow)).get(iCol));

    if (null!=obj) {
      if (obj instanceof Timestamp)
        return ((Timestamp) obj).getTime();
      else if (obj instanceof Date)
        return ((Date) obj).getTime();
      else
        throw new ClassCastException("Cannot cast "+obj.getClass().getName()+" to Timestamp");
    }
    else
      return 0;
  }

  // ----------------------------------------------------------

  /**
   * <p>Return interval value in miliseconds</p>
   * This method is only for PostgreSQL 8.0 or later
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return long Interval in miliseconds. If interval is null then zero is returned.<br>
   * For Postgres 7.4 and earlier versions this method always return zero
   * even if the interval column is not null.
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   * @since v2.2
   */
  public long getIntervalMilis (int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException,ClassCastException {
    Object obj = (((Vector) super.get(iRow)).get(iCol));
    // 	0 years 0 mons 0 days 0 hours 0 mins 0.00 secs
    String s;
   
    if (null==obj)
      return 0l;
    else if (obj.getClass().getName().equals("org.postgresql.util.PGInterval")) {
      final float SecMilis = 1000f;
      final long MinMilis = 60000l, HourMilis=3600000l, DayMilis=86400000l;
      long lInterval = 0;
      String[] aParts = obj.toString().trim().split("\\s");
	  for (int p=0; p<aParts.length-1; p+=2) {
	  	Float fPart = new Float(aParts[p]);
	  	if (fPart.floatValue()!=0f) {
	  	  if (aParts[p+1].startsWith("year"))
	  	  	lInterval += fPart.longValue()*DayMilis*365l;
	  	  else if (aParts[p+1].startsWith("mon"))
	  	  	lInterval += fPart.longValue()*DayMilis*30l;
	  	  else if (aParts[p+1].startsWith("day"))
	  	  	lInterval += fPart.longValue()*DayMilis;
	  	  else if (aParts[p+1].startsWith("hour"))
	  	  	lInterval += fPart.longValue()*HourMilis;
	  	  else if (aParts[p+1].startsWith("min"))
	  	  	lInterval += fPart.longValue()*MinMilis;
	  	  else if (aParts[p+1].startsWith("sec"))
	  	  	lInterval += new Float(fPart.floatValue()*SecMilis).longValue();	  	  	
	  	}
	  }
      return lInterval;
    }
    else
      throw new ClassCastException("Cannot cast "+obj.getClass().getName()+" to Timestamp");
  } // getIntervalMilis

  // ----------------------------------------------------------

  /**
   * Pre-allocate a given number of empty rows and columns
   * @param nCols Number of columns per row
   * @param nRows Number of rows to allocate
   * @since 2.2
   */
  public void ensureCapacity(int nCols, int nRows) {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.ensureCapacity("+String.valueOf(nCols)+","+String.valueOf(nRows)+")");
      DebugFile.incIdent();
    }

    for (int r=0;r<nRows; r++) {
      Vector<Object> oNewRow = new Vector<Object>(nCols);
      for (int c=0; c<nCols; c++) {
        oNewRow.add(null);
      }
      super.add(oNewRow);
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.ensureCapacity()");
    }
  } // ensureCapacity

  // ----------------------------------------------------------

  /**
   * Set an element for a loaded DBSubset
   * @param oObj Object Reference
   * @param iCol Column Index [0..getColumnCount()-1]
   * @param iRow Row Index [0..getRowCount()-1]
   * @throws ArrayIndexOutOfBoundsException
   */
  public void setElementAt (Object oObj, int iCol, int iRow) throws ArrayIndexOutOfBoundsException {

    if (DebugFile.trace) {
      if (oObj==null)
        DebugFile.writeln("DBSubset.setElementAt(null,"+String.valueOf(iCol)+","+String.valueOf(iRow)+")");
      else
        DebugFile.writeln("DBSubset.setElementAt("+oObj.toString()+","+String.valueOf(iCol)+","+String.valueOf(iRow)+")");
      DebugFile.incIdent();
    }

    Vector oRow;
    Object oRaw = super.get(iRow);

    if (null==oRaw) {
      if (DebugFile.trace) DebugFile.writeln("new Vector("+String.valueOf(iCol)+",1)");
      oRow = new Vector(iCol, 1);
      super.add(iRow, oRow);
    }
    else {
      oRow = (Vector) oRaw;
    }

    oRow.setElementAt (oObj, iCol);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.setElementAt()");
    }
  } // setElementAt

  // ----------------------------------------------------------

  /**
   * Set an element for a loaded DBSubset
   * @param oObj Object Reference
   * @param sCol Column Name
   * @param iRow Row Index [0..getColumnCount()-1]
   * @throws ArrayIndexOutOfBoundsException
   */
  public void setElementAt (Object oObj, String sCol, int iRow)
    throws ArrayIndexOutOfBoundsException {
    int iCol = getColumnPosition(sCol);
    if (-1==iCol)
      throw new ArrayIndexOutOfBoundsException("DBSubset.setElementAt() column "+sCol+" not found");
    else
      setElementAt (oObj, iCol, iRow);
  } // setElementAt

  // ----------------------------------------------------------

  /**
   * @param iCol Column position [0..getColumnCount()-1]
   * @param iRow Row position [0..getRowCount()-1]
   * @return <b>true</b> if pre-load field is <b>null</b>, <b>false</b> otherwise.
   * @throws ArrayIndexOutOfBoundsException
   */
  public boolean isNull (int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException {
    Object obj = (((Vector) super.get(iRow)).get(iCol));

    return (null==obj);

  } // isNull()


  // ----------------------------------------------------------

  /**
   * @param sCol Column name
   * @param iRow Row position [0..getRowCount()-1]
   * @return <b>true</b> if pre-load field is <b>null</b>, <b>false</b> otherwise.
   * @throws ArrayIndexOutOfBoundsException if column is not found
   */

  public boolean isNull (String sCol, int iRow) throws ArrayIndexOutOfBoundsException {
    int iCol = getColumnPosition(sCol);

    if (iCol==-1)
      throw new ArrayIndexOutOfBoundsException ("Column " + sCol + " not found");

    Object obj = (((Vector) super.get(iRow)).get(iCol));

    return (null==obj);
  } // isNull()

  // ----------------------------------------------------------

  /**
   * <p>Write DBSubset to a delimited text string using the column and row delimiters
   * stablished at setColumnDelimiter() and setRowDelimiter() properties.</p>
   * @return String dump of the whole DBSubset pre-loaded data.
   */

  public String toString() {
    Vector vRow;
    int iCol;
    int iRowCount;
    StringBuffer strBuff;

    if (super.isEmpty()) return "";

    iRowCount = super.size();

    if (iRowCount==0) return "";

    strBuff = new StringBuffer(64*iRowCount);

    for (int iRow=0; iRow<iRowCount; iRow++)
      {
      vRow = (Vector) super.get(iRow);
      iCol = 0;
      while (iCol<iColCount)
        {
        strBuff.append(vRow.get(iCol));
        if (++iCol<iColCount) strBuff.append(sColDelim);
        }
      strBuff.append(sRowDelim);
      }

  return strBuff.toString();
  } // toString()

  // ----------------------------------------------------------

  /**
   * <p>Write DBSubset to an XML string</p>
   * @param sIdent Initial space identations on the left for fields
   * @param sNode Name of top parent node. If <b>null</b> then main table name
   * for this DBSubset is used.
   * @param sDateFormat Output format for date values
   * @param sDecimalFormat Output format for decimal and floating point values
   * @return XML string dump of the whole DBSubset pre-loaded data.
   */

  public String toXML(String sIdent, String sNode,
                      String sDateFormat, String sDecimalFormat) {
    Vector vRow;
    int iAs;
    int iCol;
    int iDot;
    int iRowCount;
    int iTokCount;
    StringBuffer strBuff;
    StringTokenizer strTok;
    String sLabel;
    String sNodeName;
    Object oColValue;
    Class oColClass, ClassString = null, ClassDateTime = null, ClassTimeStamp = null,
                     ClassBigDecimal = null, ClassDouble = null, ClassFloat = null;
    SimpleDateFormat oXMLDate;
    DecimalFormat oDecFmt = null;

    if (sDateFormat==null)
      oXMLDate = new SimpleDateFormat("yyyy-MM-dd'T'hh:mm:ss");
    else if (sDateFormat.length()==0)
      oXMLDate = new SimpleDateFormat("yyyy-MM-dd'T'hh:mm:ss");
    else
      oXMLDate = new SimpleDateFormat(sDateFormat);

    if (null!=sDecimalFormat) {
      if (sDecimalFormat.length()>0)
        oDecFmt = new DecimalFormat(sDecimalFormat);
    } // fi

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.toXML(" + sNode + ")");
      DebugFile.incIdent();
    }

    try {
      ClassString = Class.forName("java.lang.String");
      ClassDateTime = Class.forName("java.util.Date");
      ClassTimeStamp = Class.forName("java.sql.Timestamp");
      ClassBigDecimal = Class.forName("java.math.BigDecimal");
      ClassDouble = Class.forName("java.lang.Double");
      ClassFloat = Class.forName("java.lang.Float");
    } catch (ClassNotFoundException ignore) { }

    if (!super.isEmpty()) {

      sNodeName = (null!=sNode ? sNode : sTable);

      iRowCount = super.size();
      strBuff = new StringBuffer(256*iRowCount);

      strTok = new StringTokenizer(sColList,",");
      iTokCount = strTok.countTokens();
      String[] Labels = new String[iTokCount];

      for (int iTok=0; iTok<iTokCount; iTok++) {
        sLabel = strTok.nextToken();
        iAs = sLabel.toUpperCase().indexOf(" AS ");
        if (-1!=iAs) sLabel = sLabel.substring(iAs+4);
        iDot = sLabel.indexOf('.');
        if (-1!=iDot) sLabel = sLabel.substring(++iDot);
        Labels[iTok] = sLabel.trim();
      } // next

      for (int iRow=0; iRow<iRowCount; iRow++)
        {
        vRow = (Vector) super.get(iRow);
        iCol = 0;
        strBuff.append(sIdent + "<" + sNodeName + ">\n");
        while (iCol<iColCount)
          {
          strBuff.append(sIdent + "  <" + Labels[iCol] + ">");
          oColValue = vRow.get(iCol);
          if (null!=oColValue) {
            oColClass = oColValue.getClass();

            if (oColClass.equals(ClassString) && !Labels[iCol].startsWith("gu_"))
              strBuff.append("<![CDATA[" + oColValue + "]]>");

            else if (oColClass.equals(ClassDateTime))
              strBuff.append (oXMLDate.format((java.util.Date) oColValue));

            else if (oColClass.equals(ClassTimeStamp))
              strBuff.append (oXMLDate.format(new Date (((java.sql.Timestamp) oColValue).getTime())));

            else if (oColClass.equals(ClassBigDecimal) && (oDecFmt!=null))
              strBuff.append (oDecFmt.format((java.math.BigDecimal) oColValue));

            else if (oColClass.equals(ClassDouble) && (oDecFmt!=null))
              strBuff.append (oDecFmt.format(((java.lang.Double) oColValue).doubleValue()));

            else if (oColClass.equals(ClassFloat) && (oDecFmt!=null))
              strBuff.append (oDecFmt.format((double)((java.lang.Float) oColValue).floatValue()));

            else if (oColClass.equals(getClass()))
              strBuff.append ("<"+getColumnName(iCol)+"s>\n"+((DBSubset)oColValue).toXML(sIdent+"  ", getColumnName(iCol), sDateFormat, sDecimalFormat)+"\n</"+getColumnName(iCol)+"s>\n");

            else
              strBuff.append(oColValue);
          }
          strBuff.append("</" + Labels[iCol] + ">\n");
          iCol++;
          }
        strBuff.append(sIdent + "</" + sNodeName + ">\n");
        } // wend
    }
    else
      strBuff = new StringBuffer();

    if (DebugFile.trace) {
      DebugFile.writeln("End DBSubset.toXML() : " + String.valueOf(strBuff.length()));
      DebugFile.decIdent();
    }

    return strBuff.toString();

  } // toXML()

  /**
   * <p>Write DBSubset to an XML string</p>
   * Use default output format for date values: yyyy-MM-dd'T'hh:mm:ss
   * @param sIdent Initial space identations on the left for fields
   * @param sNode Name of top parent node. If <b>null</b> then main table name
   * for this DBSubset is used.
   * @return XML string dump of the whole DBSubset pre-loaded data.
   */

  public String toXML(String sIdent, String sNode) {
    return toXML(sIdent, sNode, null, null);
  }

  // ----------------------------------------------------------

  /**
   * <p>Print DBSubset to an output stream<p>
   * This method is quite different in behavior from toString() and toXML().
   * In toString() and toXML() methods data is first pre-loaded by invoking
   * call() or load() methods and then written to a string buffer.
   * For toString() and toXML() memory consumption depends on how many rows
   * are pre-loaded in memory.
   * print() method directly writes readed data to the output stream without creating
   * the bidimimensional internal array for holding readed data.
   * This way data is directly piped from database to output stream.
   * @param oConn Database Connection
   * @param oOutStrm Output Stream
   * @throws SQLException
   */

  public void print(Connection oConn, OutputStream oOutStrm) throws SQLException {
    String sCol;
    int iRows;
    int iCol;
    short jCol;
    float fCol;
    double dCol;
    Date dtCol;
    BigDecimal bdCol;
    Object oCol;
    boolean bQualify = sTxtQualifier.length()>0;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.print([Connection], [Object])");
      DebugFile.incIdent();
      }

    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSelect + ")");

    ResultSet oRSet = oStmt.executeQuery(sSelect);

    if (DebugFile.trace) DebugFile.writeln("ResultSet.getMetaData()");

    ResultSetMetaData oMDat = oRSet.getMetaData();
    int iCols = oMDat.getColumnCount();

    if (DebugFile.trace) DebugFile.writeln("column count = " + String.valueOf(iCols));

    PrintWriter oWriter = new PrintWriter(oOutStrm);

    iRows = 0;
    while (oRSet.next()) {
      for (int c=1; c<=iCols; c++) {
        switch (oMDat.getColumnType(c)) {
          case Types.VARCHAR:
          case Types.CHAR:
            sCol = oRSet.getString(c);
            if (!oRSet.wasNull()) {
              sCol = sCol.replace('\n',' ');
              if (bQualify)
                oWriter.print(sTxtQualifier + sCol + sTxtQualifier);
              else
                oWriter.print(sCol);
            }
            break;
          case Types.DATE:
            dtCol = oRSet.getDate(c);
            if (!oRSet.wasNull()) oWriter.write(dtCol.toString());
            break;
          case Types.INTEGER:
            iCol = oRSet.getInt(c);
            if (!oRSet.wasNull()) oWriter.print(iCol);
            break;
          case Types.SMALLINT:
            jCol = oRSet.getShort(c);
            if (!oRSet.wasNull()) oWriter.print(jCol);
            break;
          case Types.FLOAT:
            fCol = oRSet.getFloat(c);
            if (!oRSet.wasNull()) oWriter.print(fCol);
            break;
          case Types.REAL:
            dCol =  oRSet.getDouble(c);
            if (!oRSet.wasNull()) oWriter.print(dCol);
            break;
          case Types.DECIMAL:
            bdCol = oRSet.getBigDecimal(c);
            if (!oRSet.wasNull()) oWriter.print(bdCol.toString());
            break;
          default:
            oCol = oRSet.getObject(c);
            if (!oRSet.wasNull()) oWriter.print(oCol.toString());
            break;
        } // end switch()
        if (c<iCols) oWriter.print(getColumnDelimiter());
      } // next (c)
      oWriter.print(getRowDelimiter());
      iRows++;
    } // wend()

    oWriter.flush();
    oWriter.close();
    oWriter = null;

    oRSet.close();
    oRSet = null;
    oStmt.close();
    oStmt = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.print() : " + String.valueOf(iRows));
    }

  } // print()

  // ----------------------------------------------------------

  private static String rpl(String s) {
  	return s.replace('"','`').replace('\n',' ').replace('\t',' ');
  }

  public String json(String sName, String sIdentifier, String sLabel) throws ArrayIndexOutOfBoundsException {
    boolean c = false;
    StringBuffer oBuff = new StringBuffer(200*(getRowCount()+1));
    oBuff.append("{\"identifier\":\""+sIdentifier+"\",\"label\":\""+sLabel+"\",\"items\":[\n");

    for (int r=0; r<getRowCount(); r++) {
      if (c) oBuff.append(',');
      oBuff.append("{\"name\":\""+rpl(getStringNull(sName,r,""))+"\",");
      oBuff.append("\""+sIdentifier+"\":\""+rpl(getStringNull(sIdentifier,r,""))+"\",");
      oBuff.append("\""+sLabel+"\":\""+rpl(getStringNull(sLabel,r,""))+"\"}\n");
      c = true;
    } // next

    oBuff.append("]}");  	
    return oBuff.toString();
  	
  }

  // ----------------------------------------------------------

  private static String removeQuotes (String sStr) {
    final int iLen = sStr.length();
    StringBuffer oStr = new StringBuffer(iLen);
    char c;

    for (int i=0; i<iLen; i++) {
      c = sStr.charAt(i);
      if (c!='"' && c!=' ' && c!='\n' && c!='\t' && c!='\r')
        oStr.append(c);
    } // next (c)

    return oStr.toString();
  } // removeQuotes

  // ----------------------------------------------------------

  /**
   * <p>Store full contents of this DBSubset at base table</p>
   * <p>This method takes all the dat contained in memory for this DBSubsets and
   * stores it at the database. For each row, if it does not exist then it is
   * inserted, if it exists then it is updated.
   * @param oConn JDBC Database Connection
   * @param oDBPersistSubclass DBPersist subclass for rows. DBSubset will call the
   * proper DBPersist.store() derived method for each row, executing specific code
   * for the subclass such as automatic GUID at modification date generation.
   * @param bStopOnError <b>true</b> if process should stop if any SQLException is
   * thrown, <b>false</b> if process must continue upon an SQLException and leave
   * return addional information throught SQLException[] array.
   * @return An array with a SQLException object per stored row, if no SQLException
   * was trown for a row then the entry at the array for that row is <b>null</b>.<br>
   * eof() property is set to <b>true</b> if all rows were inserted successfully,
   * and, thus, all entries of the returned SQLException array are null; if any row
   * failed to be inserted or updated then eof() is set to <b>false</b>
   * @throws SQLException Only if bStopOnError is <b>true</b>
   * @trhows ArrayIndexOutOfBoundsException If a table column is not found by its name
   * @throws IllegalAccessException
   * @throws InstantiationException
   */
  public SQLException[] store (JDCConnection oConn, Class oDBPersistSubclass, boolean bStopOnError)
    throws SQLException, IllegalAccessException, InstantiationException, ArrayIndexOutOfBoundsException {

    DBPersist oDBP;
    DBTable oTbl;
    Object oFld;
    String sClssName;
    Statement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    SQLException[] aExceptions;
    int iExceptions = 0;
    int iType = Types.NULL;

    if (DebugFile.trace) {
      if (null==oDBPersistSubclass)
        DebugFile.writeln("Begin DBSubset.store([Connection],null");
      else
        DebugFile.writeln("Begin DBSubset.store([Connection],[" + oDBPersistSubclass.getName() + "]");
      DebugFile.incIdent();
    }

    String[] aCols = Gadgets.split(removeQuotes(sColList), ',');

    iColCount = aCols.length ;

    if (oDBPersistSubclass!=null) {
      oDBP =  (DBPersist) oDBPersistSubclass.newInstance();
      oTbl = oDBP.getTable();

      sColList = "";
      for (int c=0; c<iColCount; c++)
        if (null!=oTbl.getColumnByName(aCols[c]))
          sColList += (c==0 ? "" : "," ) + aCols[c];
        else
          sColList += (c==0 ? "" : "," ) + "'void' AS " + aCols[c];
    }

    final int iRowCount = getRowCount();

    if (bStopOnError)
      aExceptions = null;
    else
      aExceptions = new SQLException[iRowCount];

    oStmt = oConn.createStatement();

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT " + sColList + " FROM " + sTable + " WHERE 1=0)");

    oRSet = oStmt.executeQuery("SELECT " + sColList + " FROM " + sTable + " WHERE 1=0");
    oMDat = oRSet.getMetaData();

    int[] aTypes = new int[oMDat.getColumnCount()];

    ColNames = new String[oMDat.getColumnCount()];

    for (int t=1; t<=iColCount; t++) {
      ColNames[t-1] = oMDat.getColumnName(t).toLowerCase();
      aTypes  [t-1] = oMDat.getColumnType(t);
    }

    oMDat = null;
    oRSet.close();
    oStmt.close();

    if (oDBPersistSubclass!=null)
      oDBP = (DBPersist) oDBPersistSubclass.newInstance();
    else
      oDBP = new DBPersist(sTable, sTable);

    for (int r=0; r<iRowCount; r++) {

      if (DebugFile.trace) DebugFile.writeln("processing row " + String.valueOf(r));

      for (int c=0; c<iColCount; c++) {

        oFld = get(c, r);

        if (null!=oFld) {
          iType = aTypes[c];
          if (iType==Types.BLOB) iType = Types.LONGVARBINARY;
          if (iType==Types.CLOB) iType = Types.LONGVARCHAR;
          try {
            if (oFld.toString().length()>0 && !oDBP.AllVals.containsKey(aCols[c])) {
              sClssName = oFld.getClass().getName();
              if (sClssName.equals("java.util.Date"))
                oDBP.put(aCols[c], (java.util.Date) oFld);
              else if (sClssName.equals("java.sql.Timestamp"))
                oDBP.put(aCols[c], new java.util.Date(((java.sql.Timestamp) oFld).getTime()));
              else
                oDBP.put(aCols[c], oFld.toString(), iType);
            }
          } catch (FileNotFoundException e) { /* never thrown */ }
        } // fi (null!=oFld)
      } // next (c)

      if (bStopOnError) {

        oDBP.store(oConn);
      }
      else {

        try {

          oDBP.store(oConn);
          aExceptions[r] = null;

        } catch (SQLException sqle) {
          iExceptions++;
          aExceptions[r] = sqle;
        }
      } // fi (bStopOnError)

      oDBP.clear();
    } // next (r)

    ColNames = null;

    aTypes = null;

    bEOF = (0==iExceptions);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.store() : " + String.valueOf(iExceptions));
    }

    return aExceptions;
  } // store

  // ----------------------------------------------------------

  /**
   * <p>For each DBSubset row, load another DBSubset with related records from another table<p>
   * For example for loading the categories of a user and then the Products inside them do:<BR>
   * DBSubset oCats = new DBSubset(DB.k_categories, DB.gu_category+","+DB.nm_category, DB.gu_owner+"=?", 10);<BR>
   * int nCats = oCats.load (oJdbcConnection, new Object[]{"guid_of_user_owner_of_categories"});<BR>
   * int nProds = oCats.loadSubrecords(oJdbcConnection, DB.v_prod_cat, DB.gu_category, 0);<BR>
   * if (nProds!=0) {<BR>
   *   for (int c=0; c&lt;nCats; c++) {<BR>
   *     for (int p=0; p&lt;oCats.getSubrecords(c).getRowCount(); p++) {<BR>
   *	   System.out.writeln(oCats.getSubrecords(c).getString(DB.nm_product,p));<BR>
   *	 }<BR>
   *   }<BR>
   * }
   * @param oConn JDCConnection
   * @param sSubrecordsTable String Name of table where subrecords are to be taken from
   * @param sForeignKey String name of a column at subrecords table
   * @param iPrimaryKey int Position of column from this DBSubset which must be binded into foreign key for filtering child subrecords
   * @return int Total count of subrecords found for all rows of this DBSubset
   * @throws SQLException
   * @since 4.0
   */
  public int loadSubrecords(JDCConnection oConn, String sSubrecordsTable,
  							String sForeignKey, int iPrimaryKey) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.loadSubrecords([JDCConnection], "+sSubrecordsTable+
      				    ", "+sForeignKey+", "+String.valueOf(iPrimaryKey)+")");
      DebugFile.incIdent();
    }

	DBSubset oSubRecs;
	int nCount = 0;
	int nSubRecs = 0;
	
	Statement oStmt = oConn.createStatement();
	ResultSet oRSet = oStmt.executeQuery("SELECT * FROM "+sSubrecordsTable+" WHERE 1=1");
	ResultSetMetaData oMDat = oRSet.getMetaData();
	int nColCount = oMDat.getColumnCount();
	StringBuffer oColsList = new StringBuffer(50*nColCount);
	oColsList.append(oMDat.getColumnName(1));
	for (int c=2; c<=nColCount; c++) {
	  oColsList.append(",");
	  oColsList.append(oMDat.getColumnName(c));	  
	} // next
	oRSet.close();
	oStmt.close();

	final int nRowCount = getRowCount();

	if (nRowCount>0) {
      oSubRecords = new Vector<DBSubset>(nRowCount);
	  for (int r=0; r<nRowCount; r++) {
	    if (isNull(iPrimaryKey,r)) {
	      oSubRecs = new DBSubset(sSubrecordsTable,oColsList.toString(),sForeignKey+" IS NULL",10);
	      nSubRecs = oSubRecs.load(oConn);
	    } else {
	      oSubRecs = new DBSubset(sSubrecordsTable,oColsList.toString(),sForeignKey+"=?",10);
	      nSubRecs = oSubRecs.load(oConn, new Object[]{get(iPrimaryKey,r)});
	    }
	    oSubRecords.add(oSubRecs);
	    nCount += nSubRecs;
	  } // next	  
	} else {
	  oSubRecords = null;
	}// fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.loadSubrecords() : " + String.valueOf(nCount));
    }

    return nCount;
  } // loadSubrecords

  // ----------------------------------------------------------

  /**
   * <p>Get subrecords of a given row of this DBSubset</p>
   * Subrecords must have been prevoiously loaded by calling loadSubrecords()
   * @return DBSubset or <b>null</b> if there are no subrecords for any row of this DBSubset
   * @throws ArrayIndexOutOfBoundsException
   * @since 4.0
   */
  public DBSubset getSubrecords(int nRow) throws ArrayIndexOutOfBoundsException {
    if (null==oSubRecords)
      return null;
    else 
      return oSubRecords.get(nRow);
  } // getSubrecords
  
  // ----------------------------------------------------------

  private boolean swapRows(int iRow1, int iRow2)
    throws ArrayIndexOutOfBoundsException {
    Vector<Object> oRow1 = super.get(iRow1);
    Vector<Object> oRow2 = super.get(iRow2);
    super.setElementAt(oRow2, iRow1);
    super.setElementAt(oRow1, iRow2);
    return true;
  }

  /**
   * <p>Sort in memory an already loaded ResultSet by a given column</p>
   * A modified bubble sort algorithm is used. Resulting in a O(n&sup2;) worst case
   * and O(n) best case if the ResultSet was already sorted by the given column.
   * @param iCol int Column Index [0..getColumnCount()-1]
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   * @since 3.0
   */
  public void sortBy(int iCol)
    throws ArrayIndexOutOfBoundsException, ClassCastException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.sortBy("+String.valueOf(iCol)+")");
      DebugFile.incIdent();
    }

    final int iRows = getRowCount();
    final int iRows1 = iRows-1;
    boolean bSwapFlag = true;

    for (int q=0; q<iRows && bSwapFlag; q++) {
      bSwapFlag = false;
      for (int r=0; r<iRows1; r++) {
        if (!isNull(iCol,r) || !isNull(iCol,r+1)) {
          if (!isNull(iCol,r) && isNull(iCol,r+1))
            bSwapFlag = swapRows(r,r+1);
          else if (isNull(iCol,r) && !isNull(iCol,r+1))
            bSwapFlag = true;
          else if (((Comparable) get(iCol, r)).compareTo(get(iCol, r+1))>0)
            bSwapFlag = swapRows(r,r+1);
        } // fi
      } // next (r)
    } // next (q)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.sortBy("+String.valueOf(iCol)+")");
    }
  } // sortBy

  /**
   * <p>Sort in memory an already loaded ResultSet by a given column</p>
   * A modified bubble sort algorithm is used. Resulting in a O(n&sup2;) worst case
   * and O(n) best case if the ResultSet was already sorted by the given column.
   * @param iCol int Column Index [0..getColumnCount()-1]
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   * @since 5.0
   */
  public void sortByDesc(int iCol)
    throws ArrayIndexOutOfBoundsException, ClassCastException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.sortByDesc("+String.valueOf(iCol)+")");
      DebugFile.incIdent();
    }

    final int iRows = getRowCount();
    final int iRows1 = iRows-1;
    boolean bSwapFlag = true;

    for (int q=0; q<iRows && bSwapFlag; q++) {
      bSwapFlag = false;
      for (int r=0; r<iRows1; r++) {
        if (!isNull(iCol,r) || !isNull(iCol,r+1)) {
          if (isNull(iCol,r) && !isNull(iCol,r+1))
            bSwapFlag = swapRows(r,r+1);
          else if (!isNull(iCol,r) && isNull(iCol,r+1))
            bSwapFlag = true;
          else if (((Comparable) get(iCol, r)).compareTo(get(iCol, r+1))<0)
            bSwapFlag = swapRows(r,r+1);
        } // fi
      } // next (r)
    } // next (q)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.sortByDesc("+String.valueOf(iCol)+")");
    }
  } // sortByDesc

  // ----------------------------------------------------------

  /**
   * <p>Sort in memory an already loaded ResultSet by a given column</p>
   * A modified bubble sort algorithm is used. Resulting in a O(n&sup2;) worst case
   * and O(n) best case if the ResultSet was already sorted by the given column.
   * @param sCol String Column Name
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   * @since 7.0
   */
  public void sort(String sCol) throws ArrayIndexOutOfBoundsException {
    sortBy(getColumnPosition(sCol));
  }

  // ----------------------------------------------------------

  private BigDecimal sumDecimal(int iCol)
    throws NumberFormatException, ArrayIndexOutOfBoundsException {
    BigDecimal oRetVal = new BigDecimal(0);
    final int iRows = getRowCount();

    for (int r=0; r<iRows; r++)
      if (!isNull(iCol, r))
        oRetVal.add(getDecimal(iCol, r));

    return oRetVal;
  }

  private Long sumLong(int iCol) {
    long iRetVal = 0l;
    final int iRows = getRowCount();

    for (int r=0; r<iRows; r++)
      if (!isNull(iCol, r))
        iRetVal += getLong(iCol, r);

    return new Long(iRetVal);
  }

  private Integer sumInteger(int iCol) {
    int iRetVal = 0;
    final int iRows = getRowCount();

    for (int r=0; r<iRows; r++)
      if (!isNull(iCol, r))
        iRetVal += getInt(iCol, r);

    return new Integer(iRetVal);
  }

  private Short sumShort(int iCol) {
    short iRetVal = 0;
    final int iRows = getRowCount();

    for (int r=0; r<iRows; r++)
      if (!isNull(iCol, r))
        iRetVal += getShort(iCol, r);

    return new Short(iRetVal);
  }

  private Float sumFloat(int iCol) {
    float fRetVal = 0;
    final int iRows = getRowCount();

    for (int r=0; r<iRows; r++)
      if (!isNull(iCol, r))
        fRetVal += getFloat(iCol, r);

    return new Float(fRetVal);
  }

  private Double sumDouble(int iCol) {
    double dRetVal = 0;
    final int iRows = getRowCount();

    for (int r=0; r<iRows; r++)
      if (!isNull(iCol, r))
        dRetVal += getDouble(iCol, r);

    return new Double(dRetVal);
  }

  public Object sum(int iCol)
    throws NumberFormatException, ArrayIndexOutOfBoundsException {
    final int iRows = getRowCount();

    if (0==iRows) return null;

    Object oFirst = null;
    int r = 0;
    do
      oFirst = get(iCol, 0);
    while ((null==oFirst) && (r<iRows));

    if (null==oFirst) return new BigDecimal(0);

    if (oFirst.getClass().getName().equals("java.math.BigDecimal"))
      return sumDecimal(iCol);
    else if (oFirst.getClass().getName().equals("java.lang.Long"))
      return sumLong(iCol);
    else if (oFirst.getClass().getName().equals("java.lang.Integer"))
      return sumInteger(iCol);
    else if (oFirst.getClass().getName().equals("java.lang.Short"))
      return sumShort(iCol);
    else if (oFirst.getClass().getName().equals("java.lang.Float"))
      return sumFloat(iCol);
    else if (oFirst.getClass().getName().equals("java.lang.Double"))
      return sumDouble(iCol);
    else
      throw new NumberFormatException("Column " + String.valueOf(iCol) + " of type " + oFirst.getClass().getName() + " is not a suitable type for sum()");
  }

  // ----------------------------------------------------------

  /**
   * <p>Append rows from given DBSubset to this DBSubset</p>
   * @param oDbs DBSubset An already loaded DBSubset
   * @throws ArrayIndexOutOfBoundsException If both DBSubsets do not have the same number of columns
   * @throws NullPointerException If oDbs is <b>null</b>
   * @since 3.0
   */
  public void union(DBSubset oDbs)
    throws ArrayIndexOutOfBoundsException,NullPointerException {
    if (this.getColumnCount()!=oDbs.getColumnCount()) {
      throw new ArrayIndexOutOfBoundsException("DBSubset.union() subsets to be unified must have the same number of columns");
    }
    final int iDbsRows = oDbs.getRowCount();
    if (iDbsRows>0) {
      super.ensureCapacity(getRowCount()+iDbsRows);
      for (int r=0; r<iDbsRows; r++) {
        super.add(oDbs.get(r));
      } // next
    } // fi
  } // union

  // ----------------------------------------------------------

  public class DBSubsetDateGroup extends ArrayList<Integer> {

	private static final long serialVersionUID = 70000l;

	private Date dtFrom;
    private Date dtTo;
    
	public DBSubsetDateGroup(Date dtStart, Date dtEnd) {
	  dtFrom = dtStart;
	  dtTo = dtEnd;
	}
	public Date getDateFrom() {
		return dtFrom;
	}
	public Date getDateTo() {
	  return dtTo;
	}	
	public int compareTo(Date dt) {
	  boolean bAfterFrom = (dt.compareTo(dtFrom)>=0);
	  boolean bBeforeTo = dt.compareTo(dtTo)<=0;
	  return bAfterFrom && bBeforeTo ? 0 : !bBeforeTo ? -1 : 1;
	}
  }
  
  /**
   * <p>Group subsets of rows by date intervals</p>
   * @param iDateColumnPosition int Date Column Index [0..getColumnCount()-1]
   * @param lInterval long May be 3600000 for grouping by hour, 86400000 for grouping by day,
   * 604800000 for grouping by week, 2592000000 for grouping by month
   * or any other arbitrary interval value.
   * @param iFirstDayOfWeek int SUNDAY=0, MONDAY=1
   * @return ArrayList<DBSubsetGroup> with one DBSubsetGroup for each interval
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   * @throws ClassCastException
   * @since 7.0
   */
  private ArrayList<DBSubsetDateGroup> groupByInterval(int iDateColumnPosition, long lInterval, int iFirstDayOfWeek)
    throws ArrayIndexOutOfBoundsException,NullPointerException,ClassCastException {
    
    ArrayList<DBSubsetDateGroup> aRetVal = new ArrayList<DBSubsetDateGroup>();
    DBSubsetDateGroup oNulls = new DBSubsetDateGroup(null,null);
    Date dtMin = (Date) min(iDateColumnPosition);
    Date dtMax = (Date) max(iDateColumnPosition);
    Date dtFirst, dtLast;
    
    if (dtMin==null || dtMax==null)
      throw new NullPointerException("Could not find minimum and maximum date values");

	if (dtMax.getTime()-dtMin.getTime()>1000l*lInterval) {
	  throw new ArrayIndexOutOfBoundsException("Date values may not span for more than 1000 intervals");
	}

	if (lInterval==3600000l) {

      // Group by hours
      dtFirst = new Date(dtMin.getYear(), dtMin.getMonth(), dtMin.getDate(),dtMin.getHours(),0,0);
      dtLast = new Date(dtMax.getYear(), dtMax.getMonth(), dtMax.getDate(),dtMin.getHours(),59,59);
	  Date dtHour = dtFirst;	
	  aRetVal.add(new DBSubsetDateGroup(dtHour, new Date(dtHour.getTime()+lInterval-1l)));
	  while (dtHour.compareTo(dtLast)<0) {
	    dtHour = new Date(dtHour.getTime()+lInterval);
	    aRetVal.add(new DBSubsetDateGroup(dtHour, new Date(dtHour.getTime()+lInterval-1l)));
	  } // wend

	} else if (lInterval==86400000l) {

      // Group by days
      dtFirst = new Date(dtMin.getYear(), dtMin.getMonth(), dtMin.getDate(),0,0,0);
      dtLast = new Date(dtMax.getYear(), dtMax.getMonth(), dtMax.getDate(),23,59,59);
	  Date dtDay = dtFirst;	
	  aRetVal.add(new DBSubsetDateGroup(dtDay, new Date(dtDay.getTime()+lInterval-1l)));
	  while (dtDay.compareTo(dtLast)<0) {
	    dtDay = new Date(dtDay.getTime()+lInterval);
	    aRetVal.add(new DBSubsetDateGroup(dtDay, new Date(dtDay.getTime()+lInterval-1l)));
	  } // wend

	} else if (lInterval==7l*86400000l) {

      // Group by weeks
      dtFirst = new Date(dtMin.getYear(), dtMin.getMonth(), dtMin.getDate(),0,0,0);
      while (dtFirst.getDay()!=iFirstDayOfWeek)
      	dtFirst = new Date(dtFirst.getTime()-86400000l);
      dtLast = new Date(dtMax.getYear(), dtMax.getMonth(), dtMax.getDate(),23,59,59);
      while (dtLast.getDay()!=(iFirstDayOfWeek==0 ? 6 : 0))
      	dtLast = new Date(dtLast.getTime()+86400000l);
	  Date dtWeek = dtFirst;	
	  aRetVal.add(new DBSubsetDateGroup(dtWeek, new Date(dtWeek.getTime()+lInterval-1l)));
	  while (dtWeek.compareTo(dtLast)<0) {
	    dtWeek = new Date(dtWeek.getTime()+lInterval);
	    aRetVal.add(new DBSubsetDateGroup(dtWeek, new Date(dtWeek.getTime()+lInterval-1l)));
	  } // wend

	} else if (lInterval==30l*86400000l) {

      // Group by months
      dtFirst = new Date(dtMin.getYear(), dtMin.getMonth(), dtMin.getDate(),0,0,0);
      while (dtFirst.getDate()!=1)
      	dtFirst = new Date(dtFirst.getTime()-86400000l);
      dtLast = new Date(dtMax.getYear(), dtMax.getMonth(), dtMax.getDate(),23,59,59);
      while (dtLast.getDate()!=Calendar.LastDay(dtLast.getMonth(),dtLast.getYear()+1900))
      	dtLast = new Date(dtLast.getTime()+86400000l);
	  Date dtMonth = dtFirst;	
	  aRetVal.add(new DBSubsetDateGroup(dtMonth, new Date(dtMonth.getTime()+(Calendar.LastDay(dtMonth.getMonth(),dtMonth.getYear()+1900)*86400000l)-1l)));
	  while (dtMonth.compareTo(dtLast)<0) {
	    dtMonth = new Date(dtMonth.getTime()+(Calendar.LastDay(dtMonth.getMonth(),dtMonth.getYear()+1900)*86400000l));
	    aRetVal.add(new DBSubsetDateGroup(dtMonth, new Date(dtMonth.getTime()+(Calendar.LastDay(dtMonth.getMonth(),dtMonth.getYear()+1900)*86400000l)-1l)));
	  } // wend

	} else if (lInterval==365l*86400000l) {

      // Group by years
      dtFirst = new Date(dtMin.getYear(), 0, 1,0,0,0);
      dtLast = new Date(dtMax.getYear(), 11, 31,23,59,59);
	  Date dtYear = dtFirst;	
	  aRetVal.add(new DBSubsetDateGroup(dtYear, new Date(dtYear.getTime()+((Calendar.LastDay(1,dtYear.getYear()+1900)==29 ? 366l : 365l)*86400000l)-1l)));
	  while (dtYear.compareTo(dtLast)<0) {
	    dtYear = new Date(dtYear.getTime()+((Calendar.LastDay(1,dtYear.getYear()+1900)==29 ? 366l : 365l)*86400000l));
	    aRetVal.add(new DBSubsetDateGroup(dtYear, new Date(dtYear.getTime()+((Calendar.LastDay(1,dtYear.getYear()+1900)==29 ? 366l : 365l)*86400000l)-1l)));
	  } // wend

	} else {

      // Group by arbitrary intervals
      dtFirst = dtMin;
      dtLast = dtMax;
	  Date dtInterval = dtFirst;	
	  aRetVal.add(new DBSubsetDateGroup(dtInterval, new Date(dtInterval.getTime()+lInterval-1l)));
	  while (dtInterval.compareTo(dtLast)<0) {
	    dtInterval = new Date(dtInterval.getTime()+lInterval);
	    aRetVal.add(new DBSubsetDateGroup(dtInterval, new Date(dtInterval.getTime()+lInterval-1l)));
	  } // wend
	}

    final int nRows = getRowCount();
    
	for (int r=0; r<nRows; r++) {
	  if (isNull(iDateColumnPosition,r)) {
	  	oNulls.add(new Integer(r));
	  } else {
	    Date dtRow = getDate(iDateColumnPosition,r);
	    int iFound = -1;
		int iLow = 0;
		int iHigh = aRetVal.size()-1;
	    while (iLow<=iHigh) {
	  	  int iComparison;	  	    
 		  DBSubsetDateGroup oGrp;
 		  if (iLow==iHigh) {
 		  	oGrp = aRetVal.get(iLow);
 		  	if (0==oGrp.compareTo(dtRow)) iFound = iLow;
	  	    break;	  	
 		  } else if (iLow==iHigh-1) {	      
 		  	oGrp = aRetVal.get(iLow);
	   	    iComparison = oGrp.compareTo(dtRow);
		    if (0==iComparison) iFound = iLow;
	        oGrp = aRetVal.get(iHigh);
	  	    iComparison = oGrp.compareTo(dtRow);
		    if (0==iComparison) iFound = iHigh;
	  	    break;	  	  
	  	  } else {
            int iMid = (iLow + iHigh) / 2;
 		  	oGrp = aRetVal.get(iMid);
	        iComparison = oGrp.compareTo(dtRow);
		    if (0==iComparison) {
		      iFound = iMid;
		      break;
		    } else if (iComparison>0) {
		      iHigh = iMid - 1;
		    } else {
              iLow = iMid + 1;
		    }
	  	  } // fi
	    } // wend
	    if (-1==iFound)
	      throw new ArrayIndexOutOfBoundsException("Date "+dtRow+" not found at any interval");
	    else
	      aRetVal.get(iFound).add(new Integer(r));
	  } // fi
	} // next
	return aRetVal;
  } // groupByInterval

  /**
   * <p>Group rows by hour intervals</p>
   * @param iDateColumnPosition int Date Column Index [0..getColumnCount()-1]
   * @return ArrayList<DBSubsetGroup> with one DBSubsetGroup for each hour
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   * @throws ClassCastException
   * @since 7.0
   */

  public ArrayList<DBSubsetDateGroup> groupByHour(int iDateColumnPosition) {
  	return groupByInterval(iDateColumnPosition, 3600000l, 0);
  }

  /**
   * <p>Group rows by day intervals</p>
   * @param iDateColumnPosition int Date Column Index [0..getColumnCount()-1]
   * @return ArrayList<DBSubsetGroup> with one DBSubsetGroup for each day
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   * @throws ClassCastException
   * @since 7.0
   */

  public ArrayList<DBSubsetDateGroup> groupByDay(int iDateColumnPosition) {
  	return groupByInterval(iDateColumnPosition, 86400000l, 0);
  }

  /**
   * <p>Group rows by week intervals</p>
   * @param iDateColumnPosition int Date Column Index [0..getColumnCount()-1]
   * @param iFirstDayOfWeek int First day of the week, SUNDAY=0, MONDAY=1
   * @return ArrayList<DBSubsetGroup> with one DBSubsetGroup for each week
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   * @throws ClassCastException
   * @since 7.0
   */

  public ArrayList<DBSubsetDateGroup> groupByWeek(int iDateColumnPosition, int iFirstDayOfWeek) {
  	return groupByInterval(iDateColumnPosition, 604800000l, iFirstDayOfWeek);
  }

  /**
   * <p>Group rows by month intervals</p>
   * @param iDateColumnPosition int Date Column Index [0..getColumnCount()-1]
   * @return ArrayList<DBSubsetGroup> with one DBSubsetGroup for each month
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   * @throws ClassCastException
   * @since 7.0
   */
  public ArrayList<DBSubsetDateGroup> groupByMonth(int iDateColumnPosition) {
  	return groupByInterval(iDateColumnPosition, 2592000000l, 0);
  }

  /**
   * <p>Group rows by year intervals</p>
   * @param iDateColumnPosition int Date Column Index [0..getColumnCount()-1]
   * @return ArrayList<DBSubsetGroup> with one DBSubsetGroup for each month
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   * @throws ClassCastException
   * @since 7.0
   */
  public ArrayList<DBSubsetDateGroup> groupByYear(int iDateColumnPosition) {
  	return groupByInterval(iDateColumnPosition, 31536000000l, 0);
  }
    
  // ----------------------------------------------------------

  /**
   * <p>Parse a delimited text file into DBSubset bi-dimensional array</p>
   * The parsed file must have the same column structure as the column list set when the DBSubset constructor was called.
   * @param sFilePath File Path
   * @param sCharSet Character set encoding for file
   * @throws IOException
   * @throws FileNotFoundException
   * @throws ArrayIndexOutOfBoundsException Delimited values for a file is greater
   * than columns specified at descriptor.
   * @throws RuntimeException If delimiter is not one of { ',' ';' or '\t' }
   * @throws NullPointerException if sFileDescriptor is <b>null</b>
   * @throws IllegalArgumentException if sFileDescriptor is ""
   */

  public void parseCSV (String sFilePath, String sCharSet)
    throws ArrayIndexOutOfBoundsException,IOException,FileNotFoundException,
           RuntimeException,NullPointerException,IllegalArgumentException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.parseCSV(" + sFilePath + ")");
      DebugFile.incIdent();
    }

    Vector oRow;

    String[] aCols = Gadgets.split (removeQuotes(sColList), ',');

    iColCount = aCols.length;

    CSVParser oParser = new CSVParser (sCharSet);

    oParser.parseFile (sFilePath, sColList.replace(',',sColDelim.charAt(0)));

    final int iRowCount = oParser.getLineCount();

    for (int r=0; r<iRowCount; r++) {
      oRow = new Vector<Object> (iColCount);

      for (int c=0; c<iColCount; c++)
        oRow.add (oParser.getField(c,r));

      super.add (oRow);
    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.parseCSV()");
    }
  } // parseCSV()

  // ----------------------------------------------------------

  /**
   * <p>Parse a delimited text file into DBSubset bi-dimensional array</p>
   * The parsed file must have the same column structure as the column list set when the DBSubset constructor was called.
   * @param sFilePath File Path
   */

  public void parseCSV (String sFilePath)
    throws ArrayIndexOutOfBoundsException,IOException,FileNotFoundException,
           RuntimeException,NullPointerException,IllegalArgumentException {

    parseCSV (sFilePath, null);

  } // parseCSV()

  // ----------------------------------------------------------

  /**
   * <p>Parse character data into DBSubset bi-dimensional array</p>
   * The parsed file must have the same column structure as the column list set when the DBSubset constructor was called.
   * @param sFilePath Character Data to be parsed
   * @param sCharSet Character set encoding for file
   */

  public void parseCSV (char[] aData, String sCharSet)
    throws ArrayIndexOutOfBoundsException, RuntimeException, NullPointerException,
           IllegalArgumentException, UnsupportedEncodingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBSubset.parseCSV(char[], " + sCharSet + ")");
      DebugFile.incIdent();
    }

    Vector oRow;

    String[] aCols = Gadgets.split (removeQuotes(sColList), ',');

    CSVParser oParser = new CSVParser (sCharSet);

    oParser.parseData (aData, sColList.replace(',',sColDelim.charAt(0)));

    final int iRowCount = oParser.getLineCount();
    iColCount = aCols.length;

    for (int r=0; r<iRowCount; r++) {
      oRow = new Vector<Object> (iColCount);

      for (int c=0; c<iColCount; c++)
        oRow.add (oParser.getField(c,r));

      super.add (oRow);
    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBSubset.parseCSV()");
    }
  } // parseCSV()

  // ----------------------------------------------------------

  /**
   * <p>Parse character data into DBSubset bi-dimensional array</p>
   * The parsed file must have the same column structure as the column list set when the DBSubset constructor was called.
   * @param sFilePath Character Data to be parsed
   */

  public void parseCSV (char[] aData)
    throws ArrayIndexOutOfBoundsException, RuntimeException, NullPointerException,
           IllegalArgumentException, UnsupportedEncodingException {

    parseCSV(aData, null);
  }

  
  // **********************************************************
  // Private Variables

  private static Class getClassForName(String sClassName) {
    Class oRetVal;
    try {
      oRetVal = Class.forName(sClassName);
    }
    catch (ClassNotFoundException cnfe) { oRetVal = null; }

    return oRetVal;
  }

  // ----------------------------------------------------------

  private static Class ClassLangString  = getClassForName("java.lang.String");
  private static Class ClassUtilDate  = getClassForName("java.util.Date");
  private static Class ClassSQLDate  = getClassForName("java.sql.Date");
  private static Class ClassSQLTime = getClassForName("java.sql.Time");
  private static Class ClassTimestamp = getClassForName("java.sql.Timestamp");

  private int iFetch;
  private int iTimeOut;
  private int iColCount;
  private int iMaxRows;
  private boolean bEOF;
  private String sTable;
  private String sColList;
  private String sFilter;
  private String sSelect;
  private String sColDelim;
  private String sRowDelim;
  private String sTxtQualifier;
  private Vector<DBSubset> oSubRecords;
  private String ColNames[];
  private SimpleDateFormat oShortDate;
  private SimpleDateFormat oDateTime;
  private SimpleDateFormat oDateTime24;
  private DecimalFormat oDecFmt;

} // DBSubset
