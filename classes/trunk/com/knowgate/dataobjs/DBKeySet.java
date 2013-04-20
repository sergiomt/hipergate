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

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;

import java.util.TreeSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;

/**
 * Load a primary keys set from the database into a java.util.TreeSet
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class DBKeySet extends TreeSet {

  private static final long serialVersionUID = 1l;

  private String sTable;
  private String sColumn;
  private String sWhere;
  private int iMaxRows;

  /**
   * @param sTableName Table Name
   * @param sColumnName Column Name
   * @param sWhereClause SQL WHERE clause
   * @param iLimit Absolute maximum number of primary key to be loaded or -1 if there is no limit
   */
  public DBKeySet(String sTableName, String sColumnName, String sWhereClause, int iLimit) {
    sTable = sTableName;
    sColumn = sColumnName;
    sWhere = sWhereClause;
    iMaxRows = (iLimit>0 ? iLimit : 2147483647);
  }

  // ---------------------------------------------------------------------------

  private String composeSQL(int iDbms, int iMaxRows) {
    String sSQL;
    if (iMaxRows<2147483647) {
      switch (iDbms) {
        case JDCConnection.DBMS_MSSQL:
          sSQL = "SELECT " + sColumn + " FROM " + sTable + " WHERE " + sWhere + " OPTION FAST (" + String.valueOf(iMaxRows) + ")";
          break;
        case JDCConnection.DBMS_MYSQL:
          sSQL = "SELECT " + sColumn + " FROM " + sTable + " WHERE " + sWhere + " LIMIT 0," + String.valueOf(iMaxRows);
          break;
        case JDCConnection.DBMS_POSTGRESQL:
          sSQL = "SELECT " + sColumn + " FROM " + sTable + " WHERE " + sWhere + " LIMIT " + String.valueOf(iMaxRows);
          break;
        case JDCConnection.DBMS_ORACLE:
          sSQL = "SELECT " + sColumn + " FROM " + sTable + " WHERE ROWNUM<=" + String.valueOf(iMaxRows) + " AND " + sWhere;
          break;
        default:
          sSQL = "SELECT " + sColumn + " FROM " + sTable + " WHERE " + sWhere;
      }
    }
    else {
      sSQL = "SELECT " + sColumn + " FROM " + sTable + " WHERE " + sWhere;
    }
    return sSQL;
  }

  // ---------------------------------------------------------------------------

  /**
   * Load primary keys from the database to this TreeSet
   * @param oConn JDBC Database Connection
   * @return Number of keys actually readed
   * @throws SQLException
   */
  public int load (JDCConnection oConn) throws SQLException {
    String sSQL = composeSQL(oConn.getDataBaseProduct(), iMaxRows);
    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery("+sSQL+")");
    ResultSet oRSet = oStmt.executeQuery(sSQL);
    try { if (iMaxRows<2147483647) oRSet.setFetchSize(iMaxRows); else oRSet.setFetchSize(1000); } catch (SQLException ignore) {}
    clear();
    int iReaded = 0;
    while (oRSet.next()) {
      add(oRSet.getObject(1));
      iReaded++;
    }
    oRSet.close();
    oStmt.close();
    return iReaded;
  }

  // ---------------------------------------------------------------------------

  /**
   * Load primary keys from the database to this TreeSet
   * @param oConn JDBC Database Connection
   * @param aParams Parameters to be binded to prepared SQL
   * @return Number of keys actually readed
   * @throws SQLException
   */
  public int load (JDCConnection oConn, Object[] aParams) throws SQLException {
    String sSQL = composeSQL(oConn.getDataBaseProduct(), iMaxRows);
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    PreparedStatement oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    for (int p=0;p<aParams.length; p++)
      oStmt.setObject(p+1, aParams[p]);
    ResultSet oRSet = oStmt.executeQuery();
    try { if (iMaxRows<2147483647) oRSet.setFetchSize(iMaxRows); else oRSet.setFetchSize(1000); } catch (SQLException ignore) {}
    clear();
    int iReaded = 0;
    while (oRSet.next()) {
      add(oRSet.getObject(1));
      iReaded++;
    }
    oRSet.close();
    oStmt.close();
    return iReaded;
  }

  // ---------------------------------------------------------------------------

  public int count(JDCConnection oConn) throws SQLException {
    Statement oStmt = oConn.createStatement();
    ResultSet oRSet = oStmt.executeQuery("SELECT COUNT("+sColumn+") FROM "+sTable+" WHERE "+sWhere);
    int iRetVal = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();
    return iRetVal;
  }

  // ---------------------------------------------------------------------------
}
