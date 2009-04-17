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

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

import java.io.File;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

/**
 *
 * <p>Microsite database index</p>
 * @author Sergio Montoro Ten
 * @version 2.0
 */
public class MicrositeDB extends DBPersist {

  public MicrositeDB() {
    super(DB.k_microsites, "MicrositesDB");
  }

  public MicrositeDB(JDCConnection oConn, String sMicrositeGUID) throws SQLException {
    super(DB.k_microsites, "MicrositesDB");
    Object aPK[] = {sMicrositeGUID};
    load (oConn, aPK);
  }

  // ----------------------------------------------------------

  public boolean load(JDCConnection oConn, Object aPK[]) throws SQLException {
    CallableStatement oStmt;
    String sNmMicrosite;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MicrositeDB.load([Connection], {" + aPK[0] + "}");
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE ||
        oConn.getDataBaseProduct()==JDCConnection.DBMS_MSSQL  ||
        oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL) {

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareCall({ call k_sp_read_microsite ('" + aPK[0] + "',?,?,?,?) }");

      oStmt = oConn.prepareCall("{ call k_sp_read_microsite (?,?,?,?,?) }");

      clear();

      oStmt.setObject(1, aPK[0], Types.CHAR);       // gu_microsite
      oStmt.registerOutParameter(2, Types.INTEGER); // id_app
      oStmt.registerOutParameter(3, Types.VARCHAR); // nm_microsite
      oStmt.registerOutParameter(4, Types.VARCHAR); // path_metadata
      oStmt.registerOutParameter(5, Types.CHAR);    // gu_workarea

      if (DebugFile.trace) DebugFile.writeln("CallableStatement.execute()");

      oStmt.execute();

      sNmMicrosite = oStmt.getString(3);

      bRetVal = (null!=sNmMicrosite);

      put (DB.gu_microsite, aPK[0]);

      if (bRetVal) {
        put(DB.id_app, oStmt.getInt(2));
        put(DB.nm_microsite, oStmt.getString(3));
        put(DB.path_metadata, oStmt.getString(4));

        if (oStmt.getObject(5)!=null) put(DB.gu_workarea, oStmt.getString(5).trim());
      }

    oStmt.close();
    }
    else
      bRetVal = super.load(oConn, aPK);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MicrositeDB.load() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  // ----------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_microsite))
      put(DB.gu_microsite, Gadgets.generateUUID());

    return super.store(oConn);
  }

  // ----------------------------------------------------------

  public boolean existsFile() {
    if (!isNull(DB.path_metadata))
      return new File(getString(DB.path_metadata)).exists();
    else
      return false;
  } // existsFile

  // **********************************************************
  // Metodos Estáticos

  /**
   * <p>Get relative path to XML metadata file</p>
   * Relative path is readed from field path_metadata of table k_microsites.<br>
   * For example: xslt/templates/Basic.xml<br>
   * Slashes or backsclashes are used as file separators depending on the value of
   * System.getProperty("file.separator") and independently of what separator is
   * used at path_metadata field.
   * @param oConn Database Connection
   * @param sMicrositeGUID GUID of Microsite witch metadata file relative path is to be retrieved
   * @return Relative path to XML metadata file or <b>null</b> if no Microsite with such GUID was found at k_microsites table.
   * @throws SQLException
   */
  public static String filePath(JDCConnection oConn, String sMicrositeGUID) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MicrositeDB.filePath([Connection], " + sMicrositeGUID + ")");
      DebugFile.incIdent();
    }
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sFilePath;

    oStmt = oConn.prepareStatement("SELECT " + DB.path_metadata + " FROM " + DB.k_microsites + " WHERE " + DB.gu_microsite + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sMicrositeGUID);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sFilePath = oRSet.getString(1);
    else
      sFilePath = null;
    oRSet.close();
    oStmt.close();

    if (System.getProperty("file.separator").equals("\\") && (null!=sFilePath))
      sFilePath = sFilePath.replace('/','\\');

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MicrositeDB.filePath() : " + (sFilePath!=null ? sFilePath : "null"));
    }
    return sFilePath;
  } // filePath

  // **********************************************************
  // * Variables estáticas

  public static final short ClassId = 70;

  public static final short TYPE_XSL = 1;
  public static final short TYPE_HTML = 2;
  public static final short TYPE_SURVEY = 4;
}
