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
import java.io.IOException;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import java.text.SimpleDateFormat;

import java.util.Vector;
import java.util.Arrays;
import java.util.ArrayList;

import org.apache.oro.text.regex.MalformedPatternException;

import org.w3c.dom.Node;
import org.w3c.dom.Element;

import dom.DOMSubDocument;

import com.knowgate.debug.DebugFile;
import com.knowgate.dfs.FileSystem;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;

import com.knowgate.dataxslt.PageSet;

/**
 *
 * <p>PageSet database index</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class PageSetDB extends DBPersist {

  private String[] aRecipients;
  private String[] aBlackList;

  public PageSetDB() {
    super(DB.k_pagesets, "PageSetDB");
  	aBlackList = null;
  	aRecipients = null;
  }

  public PageSetDB(JDCConnection oConn,String sPageSetGUID) throws SQLException {
    super(DB.k_pagesets, "PageSetDB");
  	aBlackList = null;
  	aRecipients = null;
    Object aPageSet[] = {sPageSetGUID};
    if (!load(oConn,aPageSet))
      throw new SQLException ("Could not find PageSet " + sPageSetGUID + " at " + DB.k_pagesets);
  }

  // ----------------------------------------------------------

  public PageSet getPageSet(JDCConnection oConn, String sBasePath)
  	throws SQLException,ClassNotFoundException,Exception {
  	MicrositeDB oMst = new MicrositeDB(oConn, getString(DB.gu_microsite));
    return new PageSet(Gadgets.chomp(sBasePath,File.separator)+oMst.getString(DB.path_metadata),
    				   Gadgets.chomp(sBasePath,File.separator)+getString(DB.path_data));
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

      oCall = oConn.prepareCall("{ call k_sp_read_pageset (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) }");

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
      oCall.registerOutParameter(15, Types.VARCHAR); // tx_email_from
      oCall.registerOutParameter(16, Types.VARCHAR); // tx_email_reply
      oCall.registerOutParameter(17, Types.VARCHAR); // nm_from
      oCall.registerOutParameter(18, Types.VARCHAR); // tx_subject

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

        sField = oCall.getObject(15);
        if (!oCall.wasNull()) put(DB.tx_email_from, sField.toString().trim());

        sField = oCall.getObject(16);
        if (!oCall.wasNull()) put(DB.tx_email_reply, sField.toString().trim());

        sField = oCall.getObject(17);
        if (!oCall.wasNull()) put(DB.nm_from, sField.toString().trim());

        sField = oCall.getObject(18);
        if (!oCall.wasNull()) put(DB.tx_subject, sField.toString().trim());
      } // fi (bRetVal)

      oCall.close();
    }
    else {

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT m." + DB.gu_microsite + ",m." + DB.nm_microsite +
                                     ",p." + DB.gu_workarea + ",p." + DB.nm_pageset + ",p." + DB.vs_stamp +
                                     ",p." + DB.id_language + ",p." + DB.dt_modified + ",p." + DB.path_data +
                                     ",p." + DB.id_status + ",m." + DB.path_metadata + ",p." + DB.tx_comments +
                                     ",p." + DB.gu_company + ",p." + DB.gu_project + ",p." + DB.tx_email_from +
                                     ",p." + DB.tx_email_reply + ",p." + DB.nm_from + ",p." + DB.tx_subject +
                                     " FROM " + DB.k_pagesets + " p LEFT OUTER JOIN " + DB.k_microsites +
                                     " m ON p." + DB.gu_microsite + "=m." + DB.gu_microsite + " WHERE p." + DB.gu_pageset + "=" + aPK[0] + ")");

      oStmt = oConn.prepareStatement("SELECT m." + DB.gu_microsite + ",m." + DB.nm_microsite +
                                     ",p." + DB.gu_workarea + ",p." + DB.nm_pageset + ",p." + DB.vs_stamp +
                                     ",p." + DB.id_language + ",p." + DB.dt_modified + ",p." + DB.path_data +
                                     ",p." + DB.id_status + ",m." + DB.path_metadata + ",p." + DB.tx_comments +
                                     ",p." + DB.gu_company + ",p." + DB.gu_project + ",p." + DB.tx_email_from +
                                     ",p." + DB.tx_email_reply + ",p." + DB.nm_from + ",p." + DB.tx_subject +
                                     " FROM " + DB.k_pagesets+ " p LEFT OUTER JOIN " + DB.k_microsites +
                                     " m ON p." + DB.gu_microsite + "=m." + DB.gu_microsite + " WHERE p." + DB.gu_pageset + "=?",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      oStmt.setObject(1, aPK[0], Types.CHAR);
      oRSet = oStmt.executeQuery();

      bRetVal = oRSet.next();

      put (DB.gu_pageset, (String) aPK[0]);

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

        sField = oRSet.getObject(14);
        if (!oRSet.wasNull()) put(DB.tx_email_from, (String) sField);

        sField = oRSet.getObject(15);
        if (!oRSet.wasNull()) put(DB.tx_email_reply, (String) sField);

        sField = oRSet.getObject(16);
        if (!oRSet.wasNull()) put(DB.nm_from, (String) sField);

        sField = oRSet.getObject(17);
        if (!oRSet.wasNull()) put(DB.tx_subject, (String) sField);
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
      
      /* New for v7.0 */
      if (DBBind.exists(oConn, DB.k_x_pageset_list, "U")) {
        oStmt = oConn.createStatement();
        if (DebugFile.trace) DebugFile.writeln("Connection.execute(" + "DELETE FROM " + DB.k_x_pageset_list + " WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'" + ")");
        oStmt.execute("DELETE FROM " + DB.k_x_pageset_list + " WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'");
        oStmt.close();
      }
      /****************/
      
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

      /* New for v7.0 */
      oStmt = oConn.createStatement();
      oStmt.execute("UPDATE " + DB.k_activities + " SET " + DB.gu_pageset + "=NULL WHERE " + DB.gu_pageset + "='" + getString(DB.gu_pageset) + "'");
      oStmt.close();
      /****************/
      
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

      sSQL = "INSERT INTO " + DB.k_pageset_pages + " (" + DB.gu_page + "," + DB.pg_page + "," + DB.gu_pageset + "," + DB.dt_modified + "," + DB.tl_page + "," + DB.path_page + ") VALUES (?,?,?,?,?,?)";

      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1, sIdPage);
      oStmt.setInt(2, iPgPage);
      oStmt.setString(3, getString(DB.gu_pageset));
      oStmt.setTimestamp(4, new Timestamp(new Date().getTime()));      
      oStmt.setString(5, sTlPage);
      oStmt.setString(6, sPathPage);
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.execute()");
      oStmt.execute();
      oStmt.close();
    }
    else {
      sSQL = "UPDATE " + DB.k_pageset_pages + " SET " + DB.dt_modified + "=?," + DB.tl_page + "=?," + DB.path_page + "=? WHERE " + DB.gu_page + "=?";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement)" + sSQL + ")");

      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setTimestamp(1, new Timestamp(new Date().getTime()));
      oStmt.setString(2, sTlPage);
      oStmt.setString(3, sPathPage);
      oStmt.setString(4, sGuPage);
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

  /**
   * <p>Clone another page set including all its pages into current object instance</p>
   * Both database registers and XML and HTML files are cloned.
   * @param oConn JDCConnection
   * @param sProtocol File transfer protocol (usually "file://") if <b>null</b> then file:// is the default
   * @param sStorage String Absolute path to storage directory (from storage property of hipergate.cnf file)
   * @param oSource Source PageSetDB object instance to be cloned
   * @throws IOException
   * @throws SQLException
   * @since 5.0
   */
  public void clone(JDCConnection oConn, String sProtocol, String sStorage, PageSetDB oSource)
  	throws IOException, SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin PageSetDB.clone([Connection], [PageSetDB])");
      DebugFile.incIdent();
    }

	FileSystem oFS = new FileSystem();
	if (sProtocol==null) sProtocol = "file://";
	
	sStorage = Gadgets.chomp(sStorage, File.separator);

	SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH.mm.ss");
	int iLastSlash, iParenthesis;

	String sPathMetadata = DBCommand.queryStr(oConn, "SELECT "+DB.path_metadata+" FROM "+DB.k_microsites+" WHERE "+DB.gu_microsite+"='"+oSource.getString(DB.gu_microsite)+"'");

	super.clone(oSource);
	
	replace(DB.gu_pageset, Gadgets.generateUUID());
	remove(DB.dt_modified);
	remove(DB.id_status);

	if (getStringNull(DB.id_language,"").equals("es"))
	  replace(DB.nm_pageset, Gadgets.left("Copia de "+oSource.getString(DB.nm_pageset),100));
	else  
	  replace(DB.nm_pageset, Gadgets.left("Copy of "+oSource.getString(DB.nm_pageset),100));

	String sPathData = getString(DB.path_data);
	iLastSlash = sPathData.lastIndexOf('/');
	if (-1==iLastSlash) iLastSlash = sPathData.lastIndexOf('\\');
	sPathData = sPathData.substring(0, iLastSlash+1);
	Date dtCreated = new Date();
	String sXmlFileName = oSource.getString(DB.nm_pageset);
	iParenthesis = sXmlFileName.indexOf('(');
	if (iParenthesis>0) sXmlFileName = sXmlFileName.substring(0, iParenthesis);	
	sXmlFileName = Gadgets.ASCIIEncode(sXmlFileName).toLowerCase();

    if (DebugFile.trace) DebugFile.writeln("path_data="+sPathData+sXmlFileName+" ("+oFmt.format(dtCreated)+").xml");

	replace(DB.path_data, sPathData+sXmlFileName+" ("+oFmt.format(dtCreated)+").xml");

	store(oConn);
	setCreationDate(oConn, dtCreated);

	PageSet oPSet = null;
	
	try {
	  oPSet = new PageSet(sStorage+sPathMetadata, sStorage+oSource.getString(DB.path_data), false);
	} catch (Exception xcpt) {
	  throw new IOException(xcpt.getMessage(), xcpt);
	}

	Node oRoot = oPSet.getRootNode();	  
	Node oPgst = oPSet.seekChildByName(oRoot, "pageset");
	if (DebugFile.trace) DebugFile.writeln("PageSet.setAttribute("+oPgst+",\"guid\",\""+getString(DB.gu_pageset)+"\")");
    oPSet.setAttribute(oPgst, "guid", getString(DB.gu_pageset));	    

	PageDB[] aPags = oSource.getPages(oConn);

	if (aPags!=null) {
	  if (DebugFile.trace) DebugFile.writeln("PageSet.seekChildByName("+oPgst+",\"pages\")");
	  Node oPags = oPSet.seekChildByName(oPgst,"pages");
	  if (DebugFile.trace) DebugFile.writeln("PageSet.filterChildsByName("+oPags+",\"page\")");
	  Vector<DOMSubDocument> vPags = oPSet.filterChildsByName((Element) oPags, "page");

	  for (int p=0; p<aPags.length; p++) {
	  	PageDB oPage = aPags[p];
	  	oPage.replace(DB.gu_page, Gadgets.generateUUID());
	  	oPage.replace(DB.gu_pageset, getString(DB.gu_pageset));
		oPage.remove(DB.dt_modified);
	  	String sTlPage = oPage.getString(DB.tl_page);
		iParenthesis = sTlPage.indexOf('(');
		if (iParenthesis>0) sTlPage = sTlPage.substring(0, iParenthesis)+" ("+oFmt.format(dtCreated)+").html";
		if (DebugFile.trace) DebugFile.writeln("PageDB.replace(DB.tl_page, \""+sTlPage+"\")");
		oPage.replace(DB.tl_page, sTlPage);
		
		final String sSrcPathPage = oPage.getString(DB.path_page);
	  	String sPathPage = sSrcPathPage;
	    iLastSlash = sPathPage.indexOf("/"+oSource.getString(DB.gu_pageset)+"/");
	    if (-1==iLastSlash) iLastSlash = sPathPage.indexOf("\\"+oSource.getString(DB.gu_pageset)+"\\");
	  	char cSep = sPathPage.charAt(iLastSlash);
	  	String sPathPages = sPathPage.substring(0, ++iLastSlash)+getString(DB.gu_pageset);
	  	sPathPage = sPathPages+cSep+sTlPage.replace(' ','_');	  	
	  	if (DebugFile.trace) DebugFile.writeln("Page.replace(DB.path_page, \""+sPathPages+cSep+sTlPage.replace(' ','_')+"\")");
	  	oPage.replace(DB.path_page, sPathPages+cSep+sTlPage.replace(' ','_'));
	  		
	  	oPage.store(oConn);
		oPage.setCreationDate(oConn, dtCreated);

        oPSet.setAttribute(vPags.get(p).getNode(), "guid", oPage.getString(DB.gu_page));

        try {
          oFS.mkdirs(sProtocol+sPathPages);
          if (oFS.exists(sProtocol+sSrcPathPage)) 
            oFS.copy(sProtocol+sSrcPathPage, sProtocol+sPathPage);	      
        } catch (Exception xcpt) {
          throw new IOException(xcpt.getMessage(), xcpt);
        }
	  } // next
	} // fi (aPags)

	oPSet.save(sStorage+getString(DB.path_data));

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End PageSetDB.clone()");
    }

  } // clone

  // ----------------------------------------------------------

  private String[] concatArrays(String[] a1, String a2[]) {
	final int l1 = a1.length;
	final int l2 = a2.length;
	final int ll = l1+l2;
	String[] aRetVal = Arrays.copyOf(a1, ll);
    for (int e=0; e<l2; e++) aRetVal[e+l1] = a2[e];
    return aRetVal;
  } // concatArrays

  // ----------------------------------------------------------

  public String[] getBlackList() {
    return aBlackList;
  }

  // ----------------------------------------------------------

  public void addBlackList(String[] aEMails)
  	throws MalformedPatternException {
    if (aEMails!=null) {
      if (aEMails.length>0) {
      	if (aBlackList==null) {
      	  aBlackList = aEMails;
      	} else {
      	  aBlackList = concatArrays(aBlackList, aEMails);
      	} // fi (aRecipients!=null)
      	final int nBlackList = aBlackList.length;
      	Arrays.sort(aBlackList, String.CASE_INSENSITIVE_ORDER);
      }
    }
  } // addBlackList

  // ----------------------------------------------------------

  public void clearRecipients() {
    aRecipients = null;
  }

  // ----------------------------------------------------------

  public String[] getRecipients() {
    return aRecipients;
  }

  // ----------------------------------------------------------

  public String getAllowPattern() {
  	return getStringNull(DB.tx_allow_regexp, "");
  }

  // ----------------------------------------------------------

  public void setAllowPattern(String sAllowPattern) {
  	replace(DB.tx_allow_regexp, sAllowPattern);
  }

  // ----------------------------------------------------------

  public String getDenyPattern() {
  	return getStringNull(DB.tx_deny_regexp, "");
  }

  // ----------------------------------------------------------

  public void setDenyPattern(String sDenyPattern) {
  	replace(DB.tx_deny_regexp, sDenyPattern);
  }

  // ----------------------------------------------------------

  public void addRecipients(String[] aEMails)
  	throws ArrayIndexOutOfBoundsException,MalformedPatternException {
	String sAllowPattern, sDenyPattern;
    ArrayList<String> oRecipientsWithoutDuplicates;
    boolean bAllowed;

    if (aEMails!=null) {
      if (aEMails.length>0) {
      	if (aRecipients==null) {
      	  aRecipients = aEMails;
      	} else {
      	  aRecipients = concatArrays(aRecipients, aEMails);
      	} // fi (aRecipients!=null)
      	final int nRecipients = aRecipients.length;
      	Arrays.sort(aRecipients, String.CASE_INSENSITIVE_ORDER);
		
		oRecipientsWithoutDuplicates = new ArrayList<String>(nRecipients);

	  	sAllowPattern = getAllowPattern();
	  	sDenyPattern = getDenyPattern();
	  	  	  
	    for (int r=0; r<nRecipients-1; r++) {
		  bAllowed = true;
		  try {
		    if (sAllowPattern.length()>0) bAllowed &= Gadgets.matches(aRecipients[r], sAllowPattern);
		  } catch (ArrayIndexOutOfBoundsException aiob) {
		  	throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[r]+","+sAllowPattern+")");
		  }
		  try {
		  if (sDenyPattern.length()>0) bAllowed &= !Gadgets.matches(aRecipients[r], sDenyPattern);
		  } catch (ArrayIndexOutOfBoundsException aiob) {
		  	throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[r]+","+sDenyPattern+")");
		  }
		  if (bAllowed) {
	  	    if (!aRecipients[r].equalsIgnoreCase(aRecipients[r+1])) {
	  	      if (aBlackList==null) {
	  	        if (aRecipients[r].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[r].trim());
	  	      } else if (Arrays.binarySearch(aBlackList, aRecipients[r].toLowerCase(), String.CASE_INSENSITIVE_ORDER)<0) {
	  	        if (aRecipients[r].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[r].trim());
	  	      } // fi
	  	    } // fi
	  	  } // fi bAllowed
	    } // next      

	    bAllowed=true;
		try {
	      if (sAllowPattern.length()>0) bAllowed &= Gadgets.matches(aRecipients[nRecipients-1], sAllowPattern);
		} catch (ArrayIndexOutOfBoundsException aiob) {
		  throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[nRecipients-1]+","+sAllowPattern+")");
		}
		try {
	      if (sDenyPattern.length()>0) bAllowed &= !Gadgets.matches(aRecipients[nRecipients-1], sDenyPattern);
		} catch (ArrayIndexOutOfBoundsException aiob) {
		  throw new ArrayIndexOutOfBoundsException("Gadgets.matches("+aRecipients[nRecipients-1]+","+sDenyPattern+")");
		}
	    if (bAllowed) {
	      if (aBlackList==null) {
	        if (aRecipients[nRecipients-1].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[nRecipients-1].trim());
	      } else if (Arrays.binarySearch(aBlackList, aRecipients[nRecipients-1].toLowerCase(), String.CASE_INSENSITIVE_ORDER)<0) {
	  	    if (aRecipients[nRecipients-1].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[nRecipients-1].trim());
	      }
	    } // fi (bAllowed)

	    aRecipients = oRecipientsWithoutDuplicates.toArray(new String[oRecipientsWithoutDuplicates.size()]);
	    	  
      } // fi (aEMails != {})
    } // fi (aEMails != null)

  } // addRecipients

  // ----------------------------------------------------------
  
  public static boolean delete(JDCConnection oConn, String sPageSetGUID) throws SQLException {
    PageSetDB oPGDB = new PageSetDB(oConn, sPageSetGUID);
    return oPGDB.delete(oConn);
  } // delete

  // **********************************************************
  // * Variables estáticas

  public static final short ClassId = 71;
}
