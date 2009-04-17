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

package com.knowgate.dataxslt.db;

import java.util.Date;

import java.io.File;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;

/**
 *
 * <p>PageSet database index</p>
 * @author Sergio Montoro Ten
 * @version 1.1
 */

public class PageSetDB extends DBPersist {

  public PageSetDB() {
    super(DB.k_pagesets, "PageSetDB");
  }

  public PageSetDB(JDCConnection oConn,String sPageSetGUID) throws SQLException {
    super(DB.k_pagesets, "PageSetDB");
    Object aPageSet[] = {sPageSetGUID};
    if (!load(oConn,aPageSet))
      throw new SQLException ("Could not find PageSet " + sPageSetGUID + " at " + DB.k_pagesets);
  }

  // ----------------------------------------------------------

  public boolean load(JDCConnection oConn, Object aPK[]) throws SQLException {
    // Rutina especial de carga con procedimiento almacenado para maxima velocidad en el rendering

    ResultSet oRSet;
    PreparedStatement oStmt;
    CallableStatement oCall;
    String sNmPageSet;
    Object sField;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin PageSetDB.load([Connection], {" + aPK[0] + "}");
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE ||
        oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL ||
        oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL ) {

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareCall({ call k_sp_read_pageset ('" + aPK[0] + "',?,?,?,?,?,?,?,?,?,?,?,?,?) }");

      oCall = oConn.prepareCall("{ call k_sp_read_pageset (?,?,?,?,?,?,?,?,?,?,?,?,?,?) }");

      clear();

      oCall.setObject(1, aPK[0], Types.CHAR);       // gu_pageset
      oCall.registerOutParameter(2, Types.CHAR);    // gu_microsite
      oCall.registerOutParameter(3, Types.VARCHAR); // nm_microsite
      oCall.registerOutParameter(4, Types.CHAR);    // gu_workarea
      oCall.registerOutParameter(5, Types.VARCHAR); // nm_pageset
      oCall.registerOutParameter(6, Types.VARCHAR); // vs_stamp
      oCall.registerOutParameter(7, Types.CHAR); // id_language
      oCall.registerOutParameter(8, Types.TIMESTAMP); // dt_modified
      oCall.registerOutParameter(9, Types.VARCHAR); // path_data
      oCall.registerOutParameter(10, Types.VARCHAR); // id_status
      oCall.registerOutParameter(11, Types.VARCHAR); // path_metadata
      oCall.registerOutParameter(12, Types.VARCHAR); // tx_comments
      oCall.registerOutParameter(13, Types.CHAR);    // gu_company
      oCall.registerOutParameter(14, Types.CHAR);    // gu_project

      if (DebugFile.trace) DebugFile.writeln("CallableStatement.execute()");

      oCall.execute();

      sNmPageSet = oCall.getString(5);
      bRetVal = (null!=sNmPageSet);

      put (DB.gu_pageset, aPK[0]);

      if (bRetVal) {
        put (DB.gu_microsite, oCall.getString(2).trim());
        put (DB.nm_microsite, oCall.getString(3));
        put (DB.gu_workarea, oCall.getString(4).trim());
        put (DB.nm_pageset, oCall.getString(5));

        sField = oCall.getObject(6);
        if (!oCall.wasNull()) put(DB.vs_stamp, (String) sField);

        sField = oCall.getObject(7);
        if (!oCall.wasNull()) put(DB.id_language, ((String) sField).trim());

        sField = oCall.getObject(8);
        if (!oCall.wasNull()) put(DB.dt_modified, oCall.getDate(8));

        sField = oCall.getObject(9);
        if (!oCall.wasNull()) put(DB.path_data, (String) sField);

        sField = oCall.getObject(10);
        if (!oCall.wasNull()) put(DB.id_status, (String) sField);

        sField = oCall.getObject(11);
        if (!oCall.wasNull()) put(DB.path_metadata, (String) sField);

        sField = oCall.getObject(12);
        if (!oCall.wasNull()) put(DB.tx_comments, (String) sField);

        sField = oCall.getObject(13);
        if (!oCall.wasNull()) put(DB.gu_company, sField.toString().trim());

        sField = oCall.getObject(14);
        if (!oCall.wasNull()) put(DB.gu_project, sField.toString().trim());
      } // fi (bRetVal)

      oCall.close();
    }
    else {

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT m." + DB.gu_microsite + ",m." + DB.nm_microsite +
                                     ",p." + DB.gu_workarea + ",p." + DB.nm_pageset + ",p." + DB.vs_stamp +
                                     ",p." + DB.id_language + ",p." + DB.dt_modified + ",p." + DB.path_data +
                                     ",p." + DB.id_status + ",m." + DB.path_metadata + ",p." + DB.tx_comments +
                                     ",p." + DB.gu_company + ",p." + DB.gu_project +
                                     " FROM " + DB.k_pagesets + " p LEFT OUTER JOIN " + DB.k_microsites +
                                     " m ON p." + DB.gu_microsite + "=m." + DB.gu_microsite + " WHERE p." + DB.gu_pageset + "=" + aPK[0] + ")");

      oStmt = oConn.prepareStatement("SELECT m." + DB.gu_microsite + ",m." + DB.nm_microsite +
                                     ",p." + DB.gu_workarea + ",p." + DB.nm_pageset + ",p." + DB.vs_stamp +
                                     ",p." + DB.id_language + ",p." + DB.dt_modified + ",p." + DB.path_data +
                                     ",p." + DB.id_status + ",m." + DB.path_metadata + ",p." + DB.tx_comments +
                                     ",p." + DB.gu_company + ",p." + DB.gu_project +
                                     " FROM " + DB.k_pagesets+ " p LEFT OUTER JOIN " + DB.k_microsites +
                                     " m ON p." + DB.gu_microsite + "=m." + DB.gu_microsite + " WHERE p." + DB.gu_pageset + "=?",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      oStmt.setObject(1, aPK[0], Types.CHAR);
      oRSet = oStmt.executeQuery();

      bRetVal = oRSet.next();

      put (DB.gu_pageset, aPK[0]);

      if (bRetVal) {
        put (DB.gu_microsite, oRSet.getString(1));
        put (DB.nm_microsite, oRSet.getString(2));
        put (DB.gu_workarea, oRSet.getString(3));
        put (DB.nm_pageset, oRSet.getString(4));

        sField = oRSet.getObject(5);
        if (!oRSet.wasNull()) put(DB.vs_stamp, (String) sField);

        sField = oRSet.getObject(6);
        if (!oRSet.wasNull()) put(DB.id_language, (String) sField);

        sField = oRSet.getObject(7);
        if (!oRSet.wasNull()) put(DB.dt_modified, oRSet.getTimestamp(7));

        sField = oRSet.getObject(8);
        if (!oRSet.wasNull()) put(DB.path_data, (String) sField);

        sField = oRSet.getObject(9);
        if (!oRSet.wasNull()) put(DB.id_status, (String) sField);

        sField = oRSet.getObject(10);
        if (!oRSet.wasNull()) put(DB.path_metadata, (String) sField);

        sField = oRSet.getObject(11);
        if (!oRSet.wasNull()) put(DB.tx_comments, (String) sField);

        sField = oRSet.getObject(12);
        if (!oRSet.wasNull()) put(DB.gu_company, (String) sField);

        sField = oRSet.getObject(13);
        if (!oRSet.wasNull()) put(DB.gu_project, (String) sField);
      }
      oRSet.close();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSetDB.load() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  // ----------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_pageset))
      put(DB.gu_pageset, Gadgets.generateUUID());

    // Forzar la fecha de modificación del registro
    replace(DB.dt_modified, dtNow);

    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {
    boolean bRetVal;
    File oXFil;
    Statement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin PageSetDB.delete([Connection])");
      DebugFile.incIdent();
    }

    if (exists(oConn)) {
      if (DebugFile.trace) DebugFile.writeln("PageSet " + getString(DB.gu_pageset) + " exists");

      if (!isNull(DB.path_data)) {
          oXFil = new File(getString(DB.path_data));
          if (oXFil.exists()) {
            if (DebugFile.trace) DebugFile.writeln("File.delete(" + getString(DB.path_data) + ")");
            oXFil.delete();
          }
          oXFil = null;
      } // fi (path_data)

      if (DBBind.exists(oConn, DB.k_list_jobs, "U")) {
        oStmt = oConn.createStatement();
        if (DebugFile.trace) DebugFile.writeln("Connection.execute(" + "DELETE FROM " + DB.k_list_jobs + " WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'" + ")");
        oStmt.execute("DELETE FROM " + DB.k_list_jobs + " WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'");
        oStmt.close();
      }

      if (DBBind.exists(oConn, DB.k_pageset_answers, "U")) {
        oStmt = oConn.createStatement();
        oStmt.execute("DELETE FROM " + DB.k_pageset_answers + " WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'");
        oStmt.execute("DELETE FROM " + DB.k_pageset_datasheets + " WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'");
        oStmt.execute("DELETE FROM " + DB.k_datasheets_lookup + " WHERE " + DB.gu_owner + "='" + getString(DB.gu_pageset) + "'");
        oStmt.close();
      }

      oStmt = oConn.createStatement();
      oStmt.execute("DELETE FROM " + DB.k_pageset_pages + " WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'");
      oStmt.close();

      bRetVal = super.delete(oConn);
    }
    else
      bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSetDB.delete()" + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  public boolean existsFile() {
    if (!isNull(DB.path_data))
      return new File(getString(DB.path_data)).exists();
    else
      return false;
  } // existsFile

  // ----------------------------------------------------------

  public void setPage(JDCConnection oConn, String sIdPage, int iPgPage, String sTlPage, String sPathPage) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sGuPage;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin PageSetDB.setPage([Connection], " + sIdPage + "," + String.valueOf(iPgPage) + "," + sTlPage + "," + sPathPage + ")");
      DebugFile.incIdent();
    }

    sSQL = "SELECT " + DB.gu_page + " FROM " + DB.k_pageset_pages + " WHERE " + DB.gu_pageset + "=? AND " + DB.pg_page + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    oStmt = oConn.prepareStatement(sSQL);
    oStmt.setString(1, getString(DB.gu_pageset));
    oStmt.setInt(2, iPgPage);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sGuPage = oRSet.getString(1);
    else
      sGuPage = null;
    oRSet.close();
    oStmt.close();

    if (null==sGuPage) {

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + "INSERT INTO " + DB.k_pageset_pages + " (" + DB.gu_page + "," + DB.pg_page + "," + DB.gu_pageset + "," + DB.dt_modified + "," + DB.tl_page + "," + DB.path_page + ") VALUES ('" + sIdPage + "'," + String.valueOf(iPgPage) + ",'" + getString(DB.gu_pageset) + "'," + DBBind.escape(new Date(), "ts") + ",'" + sTlPage + "','" + sPathPage + "')" + ")");

      sSQL = "INSERT INTO " + DB.k_pageset_pages + " (" + DB.gu_page + "," + DB.pg_page + "," + DB.gu_pageset + "," + DB.dt_modified + "," + DB.tl_page + "," + DB.path_page + ") VALUES (?,?,?," + DBBind.escape(new Date(), "ts") + ",?,?)";

      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1, sIdPage);
      oStmt.setInt(2, iPgPage);
      oStmt.setString(3, getString(DB.gu_pageset));
      oStmt.setString(4, sTlPage);
      oStmt.setString(5, sPathPage);
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.execute()");
      oStmt.execute();
      oStmt.close();
    }
    else {
      sSQL = "UPDATE " + DB.k_pageset_pages + " SET " + DB.dt_modified + "=" + DBBind.escape(new Date(), "ts") + "," + DB.tl_page + "=?," + DB.path_page + "=? WHERE " + DB.gu_page + "=?";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement)" + sSQL + ")");

      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1, sTlPage);
      oStmt.setString(2, sPathPage);
      oStmt.setString(3, sGuPage);
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");
      oStmt.executeUpdate();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSetDB.setPage()");
    }
  } // setPage

  // **********************************************************
  // Metodos Estáticos

  /**
   * <p>Get relative path to XML data file</p>
   * Relative path is readed from field path_data of table k_pagesets.<br>
   * For example: domains/2049/workareas/c0a801ccf90ee54e40100000ffd3af4f/apps/Mailwire/data/Basic (Dec 8 2003 11.00.01 PM).xml<br>
   * @param oConn Database Connection
   * @param sPageSetGUID GUID of PageSet witch data file relative path is to be retrieved
   * @return Relative path to XML metadata file or <b>null</b> if no Microsite with such GUID was found at k_microsites table.
   * @throws SQLException
   */
  public static String filePath(JDCConnection oConn, String sPageSetGUID) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin PageSetDB.filePath([Connection], " + sPageSetGUID + ")");
      DebugFile.incIdent();
    }
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sFilePath;

    oStmt = oConn.prepareStatement("SELECT " + DB.path_data + " FROM " + DB.k_pagesets + " WHERE " + DB.gu_pageset + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sPageSetGUID);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sFilePath = oRSet.getString(1);
    else
      sFilePath = null;
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSetDB.filePath() : " + (sFilePath!=null ? sFilePath : "null"));
    }
    return sFilePath;
  } // filePath

  // ----------------------------------------------------------

  /**
   * First Page of this PageSet
   * @param oConn Database Connection
   * @return PageDB object or <b>null</b> if this PageSet has no pages at k_pageset_pages table
   * @throws SQLException
   */
  public PageDB getFirstPage(JDCConnection oConn) throws SQLException {
    PageDB oPage = new PageDB();
    DBSubset oPages = new DBSubset (DB.k_pageset_pages,oPage.getTable(oConn).getColumnsStr(),
    								DB.gu_pageset+"=? ORDER BY "+DB.pg_page, 1);
    oPages.setMaxRows(1);			
    int nPages = oPages.load(oConn, new Object[]{getString(DB.gu_pageset)});
    if (0==nPages) {
      oPage = null;
    } else {
      oPage.putAll(oPages.getRowAsMap(0));
    }
    return oPage;
  } // getFirstPage

  // ----------------------------------------------------------

  /**
   * Pages of this PageSet
   * @param oConn Database Connection
   * @return Array of PageDB objects or <b>null</b> if this PageSet has no pages at k_pageset_pages table
   * @throws SQLException
   */
  public PageDB[] getPages(JDCConnection oConn) throws SQLException {
    PageDB[] aPages;
    PageDB oPage = new PageDB();
    DBSubset oPages = new DBSubset (DB.k_pageset_pages,oPage.getTable(oConn).getColumnsStr(),
    								DB.gu_pageset+"=? ORDER BY "+DB.pg_page, 10);
    int nPages = oPages.load(oConn, new Object[]{getString(DB.gu_pageset)});
    if (0==nPages) {
      aPages = null;
    } else {
      aPages = new PageDB[nPages];
      for (int p=0; p<nPages; p++) {
		aPages[p] = new PageDB();
		aPages[p].putAll(oPages.getRowAsMap(p));
      } // next
    }
    return aPages;
  } // getPages

  // ----------------------------------------------------------
  
  public static boolean delete(JDCConnection oConn, String sPageSetGUID) throws SQLException {
    PageSetDB oPGDB = new PageSetDB(oConn, sPageSetGUID);
    return oPGDB.delete(oConn);
  } // delete

  // **********************************************************
  // * Variables estáticas

  public static final short ClassId = 71;
}
