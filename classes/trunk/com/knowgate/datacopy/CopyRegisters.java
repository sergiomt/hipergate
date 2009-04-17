/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

package com.knowgate.datacopy;

import com.knowgate.debug.DebugFile;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import com.knowgate.misc.Gadgets;

/**
 * @author Sergio Montoro Ten
 * @version 2.0
 */

public class CopyRegisters {

  public static int FETCH_SIZE = 100;

  private String sSchema;

  private String sCatalog;

  // ---------------------------------------------------------------------------

  private class ExtendedStatement {
    public PreparedStatement sqlstatement;
    public String[] columns;

    ExtendedStatement (PreparedStatement oStmt, String sCols) {
      sqlstatement = oStmt;
      columns = Gadgets.split(sCols, ',');
    }
  }

  // ---------------------------------------------------------------------------

  public CopyRegisters() {
    sSchema = null;
    sCatalog = null;
  }

  public CopyRegisters(String schema, String catalog) {
    sSchema = schema;
    sCatalog = catalog;
  }

  // ---------------------------------------------------------------------------

  private PreparedStatement prepareReadStatement (Connection oOriginConn, Connection oTargetConn, DataTblDef oOriginDef, DataTblDef oTargetDef, String sWhere)
    throws SQLException {
    PreparedStatement oReadStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CopyRegisters.prepareReadStatement(...)");
      DebugFile.incIdent();
    }

    int iColPos;
    String sColList = "";

    for (int c=0; c<oTargetDef.ColCount; c++) {
      iColPos = oOriginDef.findColumnPosition(oTargetDef.ColNames[c]);

      if (-1==iColPos)
        sColList += "NULL AS " + oTargetDef.ColNames[c] + ",";
      else
        sColList += oTargetDef.ColNames[c] + ",";
    }

    if (DebugFile.trace)
      DebugFile.writeln ("SELECT " + sColList.substring(0, sColList.length()-1) + " FROM " + oOriginDef.BaseTable + " " + (sWhere!=null ? sWhere : ""));

    oReadStmt = oOriginConn.prepareStatement("SELECT " + sColList.substring(0, sColList.length()-1) + " FROM " + oOriginDef.BaseTable + " " + (sWhere!=null ? sWhere : ""));

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CopyRegisters.prepareReadStatement() : [PreparedStatement]");
    }

    return oReadStmt;
  }

  // ---------------------------------------------------------------------------

  private ExtendedStatement prepareInsertStatement (Connection oTargetConn, DataTblDef oTargetDef)
    throws SQLException {
    PreparedStatement oInsrtStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CopyRegisters.prepareInsertStatement(...)");
      DebugFile.incIdent();
    }

    String sColList = "";
    String sValues = "(";

    for (int c=0; c<oTargetDef.ColCount; c++) {
      if (c!=oTargetDef.ColCount-1) {
        sColList += oTargetDef.ColNames[c] + ",";
        sValues += "?,";
      }
      else {
        sColList += oTargetDef.ColNames[c];
        sValues += "?)";
      }
    }

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(INSERT INTO " + oTargetDef.BaseTable + " (" + sColList + ") VALUES " + sValues + ")");

    oInsrtStmt = oTargetConn.prepareStatement("INSERT INTO " + oTargetDef.BaseTable + " (" + sColList + ") VALUES " + sValues);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CopyRegisters.prepareInsertStatement() : [ExtendedStatement]");
    }

    return new ExtendedStatement (oInsrtStmt, sColList);
  }

  // ---------------------------------------------------------------------------

  private ExtendedStatement prepareUpdateStatement (Connection oTargetConn, DataTblDef oTargetDef)
    throws SQLException {
    PreparedStatement oUpdtStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CopyRegisters.prepareUpdateStatement(...)");
      DebugFile.incIdent();
    }

    String sSQL = "UPDATE " + oTargetDef.BaseTable + " SET ";
    String sColList = "", sColumns = "";

    for (int c=0; c<oTargetDef.ColCount; c++) {
      if (!oTargetDef.isPrimaryKey(c)) {
        if (sColList.length()==0)
          sColList = oTargetDef.ColNames[c] + "=?";
        else
          sColList += "," + oTargetDef.ColNames[c] + "=?";

      sColumns += (sColumns.length()==0 ? oTargetDef.ColNames[c] : "," + oTargetDef.ColNames[c]);
      } // fi (!oTargetDef.isPrimaryKey(c))
    } // next

    if (sColList.length()==0) {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End CopyRegisters.prepareUpdateStatement() : null");
      }
      return null;
    }

    sSQL += sColList + " WHERE ";
    sColList = "";

    for (int c=0; c<oTargetDef.ColCount; c++) {
      if (oTargetDef.isPrimaryKey(c)) {
        if (sColList.length()==0)
          sColList = oTargetDef.ColNames[c] + "=?";
        else
          sColList += " AND " + oTargetDef.ColNames[c] + "=?";

      sColumns += (sColumns.length()==0 ? oTargetDef.ColNames[c] : "," + oTargetDef.ColNames[c]);
      } // fi (oTargetDef.isPrimaryKey(c))
    } // next

    if (sColList.length()==0)
      throw new SQLException("Could not find primary key for table " + oTargetDef.BaseTable, "42S12");

    sSQL += sColList;

    if (DebugFile.trace) DebugFile.writeln ("Connection.prepareStatement(" + sSQL + ")");

    oUpdtStmt = oTargetConn.prepareStatement(sSQL);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CopyRegisters.prepareUpdateStatement() : [PreparedStatement]");
    }

    return new ExtendedStatement (oUpdtStmt, sColumns);
  }

  // ---------------------------------------------------------------------------

  public Object cast (Object oOrigin, int iOriginType, int iTargetType) {
    return oOrigin;
  }

  // ---------------------------------------------------------------------------

  private boolean existsRow (Connection oConn, String sTable, String sPKCols, ResultSet oRow)
    throws SQLException {
    String[] aCols = Gadgets.split(sPKCols, ',');
    String sSQL = "SELECT NULL FROM " + sTable + " WHERE ";

    for (int c=0; c<aCols.length; c++) {
      if (c>0) sSQL += " AND ";
      sSQL += aCols[c] + "=?";
    } // next

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    PreparedStatement oStmt = oConn.prepareStatement(sSQL);
    for (int c=0; c<aCols.length; c++)
      oStmt.setObject(c+1, oRow.getObject(aCols[c]));
    ResultSet oRSet = oStmt.executeQuery();
    boolean bExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      for (int c=0; c<aCols.length; c++) {
        if (c>0) DebugFile.write(",");
        DebugFile.write(aCols[c] + "=" + oRow.getObject(aCols[c]));
      }
      DebugFile.writeln(bExists ? " exists" : " does not exist");
    }

    return bExists;
  } // existsRow

  // ---------------------------------------------------------------------------

  /**
   * <p>Insert registers from origin table to target table.</p>
   * @param oOrigin JDBC Origin Connection
   * @param oTarget JDBC Target Connection
   * @param sOriginTable Origin Table Name
   * @param sTargetTable Target Table Name
   * @param sWhere SQL filter clause to be applied at origin fron retrieving only a register subset
   * @return Number of inserted rows
   * @throws SQLException A duplicated primary key exception is thrown if any inserted register already exists at target table
   */
  public int insert (Connection oOrigin, Connection oTarget, String sOriginTable, String sTargetTable, String sWhere)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CopyRegisters.insert(" + sOriginTable + "," + sTargetTable + "," + sWhere + ")");
      DebugFile.incIdent();
    }

    int iInserted = 0;
    ResultSet oReadRSet = null;
    ExtendedStatement oInsrtStmt= null;
    PreparedStatement oReadStmt = null;

    DataTblDef oOriginDef = new DataTblDef();
    DataTblDef oTargetDef = new DataTblDef();

    oOriginDef.readMetaData(oOrigin,  sOriginTable, null);
    oTargetDef.readMetaData(oTarget, sTargetTable, null);

    try {
      oInsrtStmt = prepareInsertStatement(oTarget, oTargetDef);

      oReadStmt = prepareReadStatement (oOrigin, oTarget, oOriginDef, oTargetDef, sWhere);

      try { oReadStmt.setFetchSize(FETCH_SIZE); } catch (SQLException ignore) { }

      oReadRSet = oReadStmt.executeQuery();

      final int iCols = oTargetDef.ColCount;

      while (oReadRSet.next()) {

        for (int c=1; c<=iCols; c++) {
          oInsrtStmt.sqlstatement.setObject (c, cast(oReadRSet.getObject(c), oOriginDef.ColTypes[c-1], oTargetDef.ColTypes[c-1]), oTargetDef.ColTypes[c-1]);
        }
        iInserted += oInsrtStmt.sqlstatement.executeUpdate();
      } // wend
    }
    catch (SQLException sqle) {
      throw new SQLException (sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
    }
    finally {
      if (null!=oReadRSet) oReadRSet.close();

      if (null!=oReadStmt) oReadStmt.close();

      if (null!=oInsrtStmt) oInsrtStmt.sqlstatement.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CopyRegisters.insert() : " + String.valueOf(iInserted));
    }

    return iInserted;
  } // insert

  // ---------------------------------------------------------------------------

  /**
   * <p>Replace registers from origin table to target table.</p>
   * <p>Registers not already present at target table will not be inserted from origin table</p>
   * @param oOrigin JDBC Origin Connection
   * @param oTarget JDBC Target Connection
   * @param sOriginTable Origin Table Name
   * @param sTargetTable Target Table Name
   * @param sWhere SQL filter clause to be applied at origin fron retrieving only a register subset
   * @return Number of replaced rows
   * @throws SQLException
   */
  public int replace (Connection oOrigin, Connection oTarget, String sOriginTable, String sTargetTable, String sWhere)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CopyRegisters.replace(" + sOriginTable + "," + sTargetTable + "," + sWhere + ")");
      DebugFile.incIdent();
    }

    int iReplaced = 0;
    ResultSet oReadRSet = null;
    ResultSetMetaData oReadMDat = null;
    PreparedStatement oReadStmt = null;
    ExtendedStatement oUpdtStmt = null;

    DataTblDef oOriginDef = new DataTblDef();
    DataTblDef oTargetDef = new DataTblDef();

    String sTargetPK = oTargetDef.getPrimaryKeys(oOrigin, sSchema, sCatalog, sTargetTable);

    oOriginDef.readMetaData(oOrigin,  sOriginTable, null);
    oTargetDef.readMetaData(oTarget, sTargetTable, sTargetPK);

    try {
      oUpdtStmt = prepareUpdateStatement(oTarget, oTargetDef);

      oReadStmt = prepareReadStatement (oOrigin, oTarget, oOriginDef, oTargetDef, sWhere);

      try { oReadStmt.setFetchSize(FETCH_SIZE); } catch (SQLException ignore) { }

      oReadRSet = oReadStmt.executeQuery();
      oReadMDat = oReadRSet.getMetaData();

      int iCols, iColPos, iOriginType, iTargetType;

      if (oUpdtStmt!=null)
        iCols = oUpdtStmt.columns.length;
      else
        iCols = 0;

      while (oReadRSet.next()) {

        for (int c=1; c<=iCols; c++) {
          iColPos = oReadRSet.findColumn(oUpdtStmt.columns[c-1]);
          iOriginType = oReadMDat.getColumnType(iColPos);
          iTargetType = oTargetDef.ColTypes[oTargetDef.findColumnPosition(oUpdtStmt.columns[c-1])];

          oUpdtStmt.sqlstatement.setObject (c, cast(oReadRSet.getObject(iColPos), iOriginType, iTargetType), iTargetType);
        }
        if (oUpdtStmt!=null)
          iReplaced += oUpdtStmt.sqlstatement.executeUpdate();
        else
          iReplaced = (existsRow(oTarget, sTargetTable, sTargetPK, oReadRSet) ? 1 : 0);
      } // wend
    }
    catch (SQLException sqle) {
      throw new SQLException (sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
    }
    finally {
      if (null!=oReadRSet) oReadRSet.close();

      if (null!=oReadStmt) oReadStmt.close();

      if (null!=oUpdtStmt) oUpdtStmt.sqlstatement.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CopyRegisters.replace() : " + String.valueOf(iReplaced));
    }
    return iReplaced;
  } // replace

  // ---------------------------------------------------------------------------

  /**
   * <p>Append registers from origin table to target table.</p>
   * <p>Registers not present at target table will be inserted from origin table and those present will be updated</p>
   * @param oOrigin JDBC Origin Connection
   * @param oTarget JDBC Target Connection
   * @param sOriginTable Origin Table Name
   * @param sTargetTable Target Table Name
   * @param sWhere SQL filter clause to be applied at origin fron retrieving only a register subset
   * @return Number of replaced rows
   * @throws SQLException
   */
  public int append (Connection oOrigin, Connection oTarget, String sOriginTable, String sTargetTable, String sWhere)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CopyRegisters.append(" + sOriginTable + "," + sTargetTable + "," + sWhere + ")");
      DebugFile.incIdent();
    }

    int iAppended = 0;
    ResultSet oReadRSet = null;
    ResultSetMetaData oReadMDat = null;
    PreparedStatement oReadStmt = null;
    ExtendedStatement oUpdtStmt = null;
    ExtendedStatement oInsrtStmt = null;

    DataTblDef oOriginDef = new DataTblDef();
    DataTblDef oTargetDef = new DataTblDef();

    String sTargetPK = oTargetDef.getPrimaryKeys(oOrigin, sSchema, sCatalog, sTargetTable);

    oOriginDef.readMetaData(oOrigin,  sOriginTable, null);
    oTargetDef.readMetaData(oTarget, sTargetTable, sTargetPK);

    final int iInsrtCols = oTargetDef.ColCount;

    try {
      oInsrtStmt = prepareInsertStatement(oTarget, oTargetDef);

      oUpdtStmt = prepareUpdateStatement(oTarget, oTargetDef);

      oReadStmt = prepareReadStatement (oOrigin, oTarget, oOriginDef, oTargetDef, sWhere);

      try { oReadStmt.setFetchSize(FETCH_SIZE); } catch (SQLException ignore) { }

      oReadRSet = oReadStmt.executeQuery();
      oReadMDat = oReadRSet.getMetaData();


      int iUpdated, iUpdtCols, iColPos, iOriginType, iTargetType;

      if (oUpdtStmt!=null)
        iUpdtCols = oUpdtStmt.columns.length;
      else
        iUpdtCols = 0;

      while (oReadRSet.next()) {

        for (int c=1; c<=iUpdtCols; c++) {
          iColPos = oReadRSet.findColumn(oUpdtStmt.columns[c-1]);
          iOriginType = oReadMDat.getColumnType(iColPos);
          iTargetType = oTargetDef.ColTypes[oTargetDef.findColumnPosition(oUpdtStmt.columns[c-1])];

          //if (DebugFile.trace) DebugFile.writeln("UpdateStatement.setObject (" + String.valueOf(c) + "," + cast(oReadRSet.getObject(iColPos), iOriginType, iTargetType) + "," + iTargetType + ")");

          oUpdtStmt.sqlstatement.setObject (c, cast(oReadRSet.getObject(iColPos), iOriginType, iTargetType), iTargetType);
        }

        if (DebugFile.trace) DebugFile.writeln("ExtendedStatement.executeUpdate(" + sTargetTable + ")");

        if (iUpdtCols>0)
          iUpdated = oUpdtStmt.sqlstatement.executeUpdate();
        else {
          iUpdated = (existsRow (oTarget, sTargetTable, sTargetPK, oReadRSet) ? 1 : 0);
        }

        if (0==iUpdated) {
          for (int c=1; c<=iInsrtCols; c++) {

            iColPos = oReadRSet.findColumn(oInsrtStmt.columns[c-1]);
            iOriginType = oReadMDat.getColumnType(iColPos);
            iTargetType = oTargetDef.ColTypes[oTargetDef.findColumnPosition(oInsrtStmt.columns[c-1])];

            //if (DebugFile.trace) DebugFile.writeln("InsertStatement.setObject (" + String.valueOf(c) + "," + cast(oReadRSet.getObject(iColPos), iOriginType, iTargetType) + "," + iTargetType + ")");

            oInsrtStmt.sqlstatement.setObject (c, cast(oReadRSet.getObject(iColPos), iOriginType, iTargetType), iTargetType);
          }

          if (DebugFile.trace) DebugFile.writeln("ExtendedStatement.executeInsert(" + sTargetTable + ")");

          iUpdated += oInsrtStmt.sqlstatement.executeUpdate();
        } // fi (0==iUpdated)

        iAppended += iUpdated;
      } // wend
    }
    catch (SQLException sqle) {

      if (null!=oReadRSet) oReadRSet.close();
      if (null!=oReadStmt) oReadStmt.close();
      if (null!=oUpdtStmt) if (null!=oUpdtStmt.sqlstatement) oUpdtStmt.sqlstatement.close();

      throw new SQLException (sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
    }
    if (null!=oReadRSet) oReadRSet.close();
    if (null!=oReadStmt) oReadStmt.close();
    if (null!=oUpdtStmt) if (null!=oUpdtStmt.sqlstatement) oUpdtStmt.sqlstatement.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CopyRegisters.append() : " + String.valueOf(iAppended));
    }
    return iAppended;
  } // append

}