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

package com.knowgate.hipergate;

import java.lang.System;
import java.io.IOException;
import java.io.File;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.HashMap;
import java.util.LinkedList;

import java.net.URL;
import java.net.MalformedURLException;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.Gadgets;
import com.knowgate.storage.Column;
import com.knowgate.storage.Engine;
import com.knowgate.storage.Factory;
import com.knowgate.storage.Record;
import com.knowgate.storage.Table;
import com.knowgate.storage.StorageException;

/**
 * <p>Product Location</p>
 * Location semantics depend upon what Product is used for.<br>
 * <ul>
 * <li>For Downloadable Products, ProductLocations represent mirror download URLs.
 * <li>For Versioned Products, ProductLocations represent different versions of the same File.
 * <li>For Compound Products, ProductLocations represent parts of the Product each one being a File.
 * <li>For Physical Products, ProductLocations represent stock of Product at different warehouses.
 * </ul>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class ProductLocation extends DBPersist {

  public ProductLocation() {
    super(DB.k_prod_locats, "ProductLocation");
  }

  /**
   * Load ProductLocation from database
   * @param oConn Database Conenction
   * @param iIdLocation GUID of ProductLocation to be loaded
   * @throws SQLException
   */
  public ProductLocation(JDCConnection oConn, String iIdLocation) throws SQLException  {
    super(DB.k_prod_locats, "ProductLocation");

    Object aProd[] = { iIdLocation };

    load(oConn, aProd);
  }

  // ----------------------------------------------------------

  /**
   * <p>Get Path to URL or file</p>
   * @return xprotocol [xhost] [:xport] / xpath<br>
   * Example 1: file:///opt/knowgate/storage/userdata/<br>
   * Example 2: http://www.hipergate.org/es/<br>
   * Example 3: http://localhost:8080/
   */
  public String getPath() {
    String sPath;
    String sXProtocol = getString(DB.xprotocol);
    String sXPath = getStringNull(DB.xpath, "");
    String sFileSep = sXProtocol.startsWith("file") ? System.getProperty("file.separator") : "/";

    if (!sXProtocol.endsWith("://")) sXProtocol += "://";

    sPath = sXProtocol;

    if (!sXProtocol.startsWith("file")) sPath += getString("xhost");

    if (!isNull(DB.xport)) sPath += ":" + getShort(DB.xport);

    if (!sPath.endsWith(sFileSep) && !sXPath.startsWith(sFileSep)) sPath += sFileSep;

    sPath += sXPath;
		
    return sPath;
  } // getPath()

  // ----------------------------------------------------------

  /**
   * Get URL for ProductLocation
   * @return getPath() [xfile] [#xanchor]
   */

  public String getURL() {
    String sURL;
    String sXProtocol = getString(DB.xprotocol);
    String sFileSep = sXProtocol.startsWith("file") ? System.getProperty("file.separator") : "/";

    sURL = getPath();

    if (null!=sURL) {
      sURL = sURL.trim();

      if (!sURL.endsWith(sFileSep) && !isNull(DB.xfile)) sURL += sFileSep;

      if (!isNull(DB.xfile)) sURL += getString(DB.xfile);
      if (!isNull(DB.xanchor)) sURL += "#" + getString(DB.xanchor);
    }

  return sURL;
  } // getURL()

  // ----------------------------------------------------------

  /**
   * <p>Get numeric identifier for container type.</p>
   * Usually, container type is computed from protocol.<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>Protocol</b></td><td><b>Container Type</b></td></tr>
   * <tr><td align=middle>file://</td><td align=middle>CONTAINER_FILE</td></tr>
   * <tr><td align=middle>http://</td><td align=middle>CONTAINER_HTTP</td></tr>
   * <tr><td align=middle>https://</td><td align=middle>CONTAINER_HTTPS</td></tr>
   * <tr><td align=middle>ftp://</td><td align=middle>CONTAINER_FTP</td></tr>
   * <tr><td align=middle>odbc://</td><td align=middle>CONTAINER_ODBC</td></tr>
   * <tr><td align=middle>lotus://</td><td align=middle>CONTAINER_LOTUS</td></tr>
   * <tr><td align=middle>jdbc://</td><td align=middle>CONTAINER_JDBC</td></tr>
   * <tr><td align=middle>ware://</td><td align=middle>CONTAINER_WARE</td></tr>
   * </table>
   * @return Container Type. One of { CONTAINER_FILE, CONTAINER_HTTP, CONTAINER_HTTPS, CONTAINER_FTP, CONTAINER_ODBC, CONTAINER_JDBC, CONTAINER_LOTUS, CONTAINER_WARE }
   */
  public int getContainerType() {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLocation.getContainerType()");
      DebugFile.incIdent();
      DebugFile.writeln("protocol="+getStringNull(DB.xprotocol,"null").toLowerCase());
    }

    String sProtocol = getString(DB.xprotocol).toLowerCase();
    int iProdType = 0;

    if (sProtocol.startsWith("file:"))
      iProdType = 1;
    else if (sProtocol.startsWith("http:"))
      iProdType = 2;
    else if (sProtocol.startsWith("https:"))
      iProdType = 3;
    else if (sProtocol.startsWith("ftp:"))
      iProdType = 4;
    else if (sProtocol.startsWith("odbc:"))
      iProdType = 5;
    else if (sProtocol.startsWith("lotus:"))
      iProdType = 6;
    else if (sProtocol.startsWith("jdbc:"))
      iProdType = 7;
    else if (sProtocol.startsWith("ware:"))
      iProdType = 100;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLocation.getContainerType() : " + String.valueOf(iProdType));
    }

    return iProdType;
  } // getContainerType()

  // ----------------------------------------------------------

  /**
   * <p>Remove querystring from a file name</p>
   * Used for separating a file extension from the query string in a URL.<br>
   * The tactic used is finding the first character of a the set {'?', '#', '/', '&' }
   * and cut file extension at that point.
   * @param sType File Name and query string
   * @return File Name without query string
   */
  private String removeQueryString(String sType) {
    int iLastQuery, iNextQuery;

    // If 4 characters or less, then return as is.
    if (sType.length()<=4) return sType;

    iLastQuery = iNextQuery = sType.indexOf("?");

    iNextQuery = sType.indexOf("#");
    if (iNextQuery>0 && (iNextQuery<iLastQuery || iLastQuery==-1))
      iLastQuery = iNextQuery;

    iNextQuery = sType.indexOf(",");
    if (iNextQuery>0 && (iNextQuery<iLastQuery || iLastQuery==-1))
      iLastQuery = iNextQuery;

    iNextQuery = sType.indexOf("/");
    if (iNextQuery>0 && (iNextQuery<iLastQuery || iLastQuery==-1))
      iLastQuery = iNextQuery;

    iNextQuery = sType.indexOf("&");
    if (iNextQuery>0 && (iNextQuery<iLastQuery || iLastQuery==-1))
      iLastQuery = iNextQuery;

    if (iLastQuery<0) iLastQuery=4;

    return sType.substring(0, iLastQuery);
  } // removeQueryString()

  // ----------------------------------------------------------

  /**
   * <p>Get product type from file path.</p>
   * @return Product Type as listed in k_lu_prod_types table computed following these rules:<br>
   * If xfile is <b>null</b> and xpath is <b>null</b> and id_cont_type is not CONTAINER_HTTP or CONTAINER_HTTPS then "?" is returned.<br>
   * If xfile is <b>null</b> and xpath is <b>null</b> and id_cont_type is CONTAINER_HTTP or CONTAINER_HTTPS then "HTML" is returned.<br>
   * If xfile is not <b>null</b> and file name has at least one dot ('.') then last dot is considered the extension delimiter.<br>
   * <b>Example 1</b>:<br>
   * ProductLocation oLoca = new ProductLocation();<br>
   * oLoca.setURL("http://www.hipergate.org/index.jsp?lang=en");<br>
   * String sProdType = oLoca.getProductType();<br>
   * // sProdType == "JSP"<br><br>
   * <b>Example 2</b>:<br>
   * ProductLocation oLoca = new ProductLocation();<br>
   * oLoca.put(DB.id_cont_type, ProductLocation.CONTAINER_HTTP);<br>
   * oLoca.setURL("http://www.hipergate.org/");<br>
   * // sProdType == "HTML"
   */

  public String getProductType() {
    String sFile;
    String sType;
    int iLast;

    sFile = isNull(DB.xfile) ? getStringNull(DB.xpath,"") : getStringNull(DB.xfile,"");

    if (sFile.length()==0) {
      if (isNull(DB.id_cont_type))
        return "?";
      else
        switch (getInt(DB.id_cont_type)) {
          case CONTAINER_HTTP :
          case CONTAINER_HTTPS:
            return "HTML";
          default:
            return "?";
        }
    }
    else {
      iLast = sFile.lastIndexOf(".");
      if (iLast > 0) {
        sType = removeQueryString(sFile.substring(++iLast).toUpperCase());

        return sType;
      }
      else {
        if (isNull(DB.id_cont_type))
          return "?";
        else
          switch (getInt(DB.id_cont_type)) {
            case CONTAINER_HTTP:
            case CONTAINER_HTTPS:
              return "HTML";
            default:
              return "?";
          }
      }
    }
  } // getProductType()

  // ----------------------------------------------------------

  /**
   * <p>Set URL for ProductLocation</p>
   * @throws MalformedURLException
   */

  public void setURL (String sURL) throws MalformedURLException {
    String sURI = sURL.toLowerCase();
    URL oURL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLocation.setURL(" + sURL + ")" );
      DebugFile.incIdent();
    }

    if (!sURI.startsWith("http://") && !sURI.startsWith("https://") && !sURI.startsWith("ftp://") &&
        !sURI.startsWith("file://") && !sURI.startsWith("odbc:") && !sURI.startsWith("jdbc:") &&
        !sURI.startsWith("lotus://") && !sURI.startsWith("ware://"))
      sURI = "http://" + sURI;

    if (sURI.startsWith("https://"))
      oURL = new URL("http" + sURI.substring(5));
    else
      oURL = new URL(sURI);

    replace(DB.xprotocol, sURI.substring(0, sURI.indexOf("://")+3));

    replace(DB.xhost, oURL.getHost());

    if (-1!=oURL.getPort())
      replace(DB.xport, oURL.getPort());
    else
      remove(DB.xport);

    String sPath = oURL.getPath();
    if (null!=sPath) {
      if (sPath.equals("/"))
        remove(DB.xpath);
      else
        replace(DB.xpath, sPath);
    }
    else
      remove(DB.xpath);

    String sFile = oURL.getFile();
    if (null!=sFile) {
      if (sPath.equals("/")) {
        remove(DB.xfile);
        remove(DB.xoriginalfile);
      }
      else {
        replace(DB.xfile, sFile);
        replace(DB.xoriginalfile, sFile);
      }
    }
    else {
      remove(DB.xfile);
      remove(DB.xoriginalfile);
    }

    if (null!=oURL.getRef())
      replace(DB.xanchor, oURL.getRef());
    else
      remove(DB.xanchor);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLocation.setURL() : " + oURL.toExternalForm());
    }

    } // setURL()

    // ----------------------------------------------------------

    /**
     * <p>Set file length in bytes</p>
     * Max file length is 2147483647 bytes
     * @param lLen Length of file pointed by ProductLocation URL
     * @throws IllegalArgumentException If lLen > 2147483647
     */
    public void setLength (long lLen) throws IllegalArgumentException {

      if (lLen>(long)2147483647)
        throw new IllegalArgumentException("Maximum allowed file length is 2Gb");

      replace (DB.len_file, new Long(lLen).intValue());
    }

    // ----------------------------------------------------------

    /**
     * <p>Set file length in bytes</p>
     * @param lLen Length of file pointed by ProductLocation URL
     */
    public void setLength (int iLen) {
      replace (DB.len_file, iLen);
    }

    // ----------------------------------------------------------

    /**
     * <p>Set File Path</p>
     * @param sProtocol Protocol. One of { "file://", "http://", "https://", "ftp://", "odbc://", "jdbc://", "ware://" }
     * @param sHost Host Name for electronic Products or WareHouse Name for physical Products. Example: "www.hipergate.org"
     * @param sPath Absolute Access Path. Example: "/opt/knowgate/users/"
     * @param sFile Uploaded File Name
     * @param sOriginalFile Original File Name before uploading.
     * In some cases, files may be renamed upon upload and then renamed again to their original names when downloaded.
     */
    public void setPath (String sProtocol, String sHost, String sPath, String sFile, String sOriginalFile) {
      if (DebugFile.trace) {
        DebugFile.writeln("Begin ProductLocation.setPath(" + sProtocol + "," + sHost + "," + sPath + "," + sFile + "," + sOriginalFile + ")");
        DebugFile.incIdent();
      }

      replace(DB.xprotocol,sProtocol);
      replace(DB.xhost,sHost);
      replace(DB.xpath,sPath);
      replace(DB.xfile,sFile);
      replace(DB.xoriginalfile,sOriginalFile);

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ProductLocation.setPath()");
      }
    } // setPath

    // ----------------------------------------------------------

    /**
     * <p>Set File Path</p>
     * @param sProtocol Protocol. One of { "file://", "http://", "https://", "ftp://", "odbc://", "jdbc://", "ware://" }
     * @param sHost Host Name for electronic Products or WareHouse Name for physical Products. Example: "www.hipergate.org"
     * @param sPath Absolute Access Path. Example: "/opt/knowgate/users/"
     * @param sFile Uploaded File Name
     * @param sOriginalFile Original File Name before uploading.
     * In some cases, files may be renamed upon upload and then renamed again to their original names when downloaded.
     * @param sAnchor Anchor
     */
    public void setPath (String sProtocol, String sHost, String sPath, String sFile, String sOriginalFile, String sAnchor) {
      if (DebugFile.trace) {
        DebugFile.writeln("Begin ProductLocation.setPath(" + sProtocol + "," + sHost + "," + sPath + "," + sFile + "," + sOriginalFile + "," + sAnchor + ")");
        DebugFile.incIdent();
      }

      replace(DB.xprotocol,sProtocol);
      replace(DB.xhost,sHost);
      replace(DB.xpath,sPath);
      replace(DB.xfile,sFile);
      replace(DB.xoriginalfile,sOriginalFile);
      replace(DB.xanchor,sAnchor);

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ProductLocation.setPath()");
      }
    } // setPath

  // ----------------------------------------------------------

  /**
   * <p>Set Local Path for ProductLocation</p>
   * File Separator is taken from System.getProperty("file.separator") method.
   * @param sHost Host Name
   * @param sLocalPath Full Local Path and File Name.<br>
   * Example 1: "file:///opt/knowgate/userfiles/logo.gif"<br>
   * Example 2: "file://C:\\TEMP\\UserGuide.doc"<br>
   */

  public void setPath (String sHost, String sLocalPath) {
    final String sFileSep = System.getProperty("file.separator");
    String sPath = sLocalPath;
    int iLast;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLocation.setPath(" + sHost + "," + sLocalPath + ")");
      DebugFile.incIdent();
    }

    if (!sPath.startsWith("file://")) sPath = "file://" + sPath;

    iLast = sPath.lastIndexOf(sFileSep);

    replace(DB.xprotocol, "file");
    replace(DB.xhost, sHost);

    if (DebugFile.trace) DebugFile.writeln(DB.xpath + "=" + sPath.substring(7, iLast));

    replace(DB.xpath, sPath.substring(7, iLast));

    if (iLast<sPath.length()-1) {
      if (DebugFile.trace) DebugFile.writeln(DB.xfile + "=" + sPath.substring(iLast+1));

      replace(DB.xfile, sPath.substring(iLast+1));

      if (DebugFile.trace) DebugFile.writeln(DB.xoriginalfile + "=" + sPath.substring(iLast+1));

      replace(DB.xoriginalfile, sPath.substring(iLast+1));
    }
    else {
      remove(DB.xfile);
      remove(DB.xoriginalfile);
    }

    remove(DB.xport);
    remove(DB.xanchor);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLocation.setPath()");
    }
  } // setPath()

  // ----------------------------------------------------------

  /**
   * <p>Store ProductLocation</p>
   * Properties gu_location, dt_uploaded, dt_modified, id_cont_type,
   * id_prod_type, pg_prod_locat and status are automatically set if not present
   * at internal properties colelction when calling store().
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    boolean iRetVal;
    String sProtocol;
    String sProdType;
    PreparedStatement oStmt;
    ResultSet oRSet;
    Object oNextLoca;
    final String EmptyStr = "";
    java.util.Date dtNow = new java.util.Date();
    java.sql.Timestamp dtSQL = new java.sql.Timestamp(dtNow.getTime());

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLocation.store([Connection])" );
      DebugFile.incIdent();
    }

    if (!AllVals.containsKey(DB.gu_location))
      put(DB.gu_location, Gadgets.generateUUID());

    if (!AllVals.containsKey(DB.dt_uploaded))
      put (DB.dt_uploaded, dtSQL);

    if (!AllVals.containsKey(DB.dt_modified))
      put (DB.dt_modified, dtSQL);

    if (!AllVals.containsKey(DB.id_cont_type)) {
      if (DebugFile.trace) DebugFile.writeln(DB.id_cont_type + "=" + String.valueOf(getContainerType()));

      put (DB.id_cont_type, new Integer(getContainerType()));
    }

    if (!AllVals.containsKey(DB.id_prod_type)) {
      sProdType = getProductType();

      if (DebugFile.trace) DebugFile.writeln(DB.id_prod_type + "=" + sProdType);

      put(DB.id_prod_type, sProdType.length()>0 ? sProdType : "?");
    }
    else {
      sProdType = (String) AllVals.get(DB.id_prod_type);
    }

    if (!AllVals.containsKey(DB.xhost))
      put (DB.xhost, "localhost");
    else if (EmptyStr.equals(AllVals.get(DB.xhost)))
      put (DB.xhost, "localhost");

    PreparedStatement oStTp = oConn.prepareStatement("SELECT NULL FROM "+DB.k_lu_prod_types+" WHERE "+DB.id_prod_type+"=?",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStTp.setString(1, sProdType.length()>0 ? sProdType : "?");
    ResultSet oRsTp = oStTp.executeQuery();
    boolean bRegistredType = oRsTp.next();
    oRsTp.close();
    oStTp.close();
    if (!bRegistredType) {
      oStTp = oConn.prepareStatement("INSERT INTO "+DB.k_lu_prod_types+" ("+DB.id_prod_type+","+DB.de_prod_type+","+DB.nm_icon+") VALUES (?,'"+sProdType+" file',NULL)");
      oStTp.setString(1, sProdType);
      oStTp.executeUpdate();
      oStTp.close();
    }

    if (AllVals.containsKey(DB.xprotocol))
      replace(DB.xprotocol, getString(DB.xprotocol).toLowerCase());

    if (!AllVals.containsKey(DB.pg_prod_locat)) {
      if (DebugFile.trace)
         DebugFile.writeln("Connection.prepareStatement(SELECT MAX(" + DB.pg_prod_locat + ")+1 FROM " + DB.k_prod_locats + " WHERE " + DB.gu_product + "='" + getStringNull(DB.gu_product, "") + "')");

      oStmt = oConn.prepareStatement("SELECT MAX(" + DB.pg_prod_locat + ")+1 FROM " + DB.k_prod_locats + " WHERE " + DB.gu_product + "=?");
      oStmt.setString(1, getString(DB.gu_product));

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");

      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oNextLoca = oRSet.getObject(1);
        if (oRSet.wasNull()) {
          if (DebugFile.trace) DebugFile.writeln("Next pg_prod_locat was null, setting it to 1");
          put(DB.pg_prod_locat, new Integer(1));
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("Next pg_prod_locat is 1"+oNextLoca.toString());
          put(DB.pg_prod_locat, new Integer(oNextLoca.toString()));
        }
      }
      else {
        put(DB.pg_prod_locat, new Integer(1));
      }

      oRSet.close();
      oStmt.close();
      oStmt = null;

      if (DebugFile.trace)
        DebugFile.writeln(DB.pg_prod_locat + "=" + String.valueOf(getInt(DB.pg_prod_locat)));
    }

    if (!AllVals.containsKey(DB.status)) put(DB.status, 1);

    iRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLocation.store() : " + String.valueOf(iRetVal));
    }

    return iRetVal;
  } // store()

  // ----------------------------------------------------------

  /**
   * <p>Rename a Product Location</p>
   * This method updates the xfile value from table k_prod_locats and changes the physical file name accordingly
   * @param oConn Database connection
   * @param oFileSys FileSystem Object for accessing physical file
   * @param sNewFile New file name
   * @return <b>true</b> if file was successfully renamed
   * @since 2.1
   * @throws Exception
   * @throws IOException
   * @throws SQLException
   * @throws SecurityException
   */
  public boolean rename(JDCConnection oConn, FileSystem oFileSys, String sNewFile)
    throws Exception,IOException,SQLException,SecurityException {
    String sPath;
    String sOldFile;
    java.util.Date dtNow = new java.util.Date();
    java.sql.Timestamp dtSQL = new java.sql.Timestamp(dtNow.getTime());

    sOldFile = getString(DB.xfile);

    if (getString(DB.xprotocol).equalsIgnoreCase("file://")) {
      sPath = Gadgets.chomp (getString(DB.xprotocol)+getString(DB.xpath), File.separator);
    }
    else {
      if (isNull(DB.xport))
        sPath = Gadgets.chomp (getString(DB.xprotocol)+getString(DB.xhost)+"/"+getString(DB.xpath), '/');
      else
        sPath = Gadgets.chomp (getString(DB.xprotocol)+getString(DB.xhost)+":"+String.valueOf(getInt(DB.xport))+"/"+getString(DB.xpath), '/');
    }

    replace(DB.xfile, sNewFile);
    replace(DB.id_prod_type, getProductType());
    replace(DB.dt_modified, dtSQL);

    store(oConn);

    return oFileSys.rename(sPath+sOldFile, sPath+sNewFile);
  } // rename

  // ----------------------------------------------------------

  /**
   * Move a File from a temporary directory up to the final location referenced
   * by ProductLocation URL.
   * @param oConn DataSource Connection
   * @param oFileSys FileSystem object used for moving the file.<br>
   * If FileSystem requires additional parameters (such as user authentication for FTP)
   * it will be taken from hipergate.cnf file by using Environment singleton.
   * @param sSourcePath Source Directory. For example: "file:///tmp/archives/"
   * @param sSourceFile Original File Name. For example: "notes.pdf"
   * @param sTargetPath Target Directory. For example: "ftp://saturno/opt/storage/"
   * @param sTargetFile Final File Name. For Example: "notes-13-05-03.pdf"
   * @throws Exception
   * @throws IOException
   * @throws StorageException
   * @see com.knowgate.misc.Environment
   */
  public void upload(Table oConn, FileSystem oFileSys, String sSourcePath, String sSourceFile, String sTargetPath, String sTargetFile) throws Exception,IOException,StorageException {
    String sFileSep = System.getProperty("file.separator");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLocation.upload([Connection], [FileSystem], " + sSourcePath + "," + sSourceFile + sTargetPath + "," + sTargetFile + ")" );
      DebugFile.incIdent();
    }

    if (sSourcePath.startsWith("file://") || sSourcePath.startsWith("ftp://")) {
      if (!sSourcePath.endsWith(sFileSep)) sSourcePath += sFileSep;
      if (sTargetPath.startsWith("file://") || sTargetPath.startsWith("ftp://")) {
        if (!sTargetPath.endsWith(sFileSep)) sTargetPath += sFileSep;
        oFileSys.move(sSourcePath+sSourceFile, sTargetPath+sTargetFile);
      } else if (sTargetPath.startsWith("bdb://")) {
    	LinkedList<Column> oColumnsList;
    	if (!oColsMap.containsKey(sTargetPath)) {
    	  oColumnsList = new LinkedList<Column>();
    	  oColumnsList.add(new Column(sTargetPath, DB.gu_location, Types.CHAR, 32, 0, false, true, null, null, true, 0));
    	  oColumnsList.add(new Column(sTargetPath, DB.bin_file, Types.BLOB, 2147483647, 0, false, false, null, null, false, 1));
    	  oColsMap.put(sTargetPath, oColumnsList);
    	} else {
    	  oColumnsList = oColsMap.get(sTargetPath);
    	}
    	Record oRec = Factory.createRecord(Engine.BERKELYDB, sTargetPath, oColumnsList);
    	oRec.setPrimaryKey(getString(DB.gu_location));
    	oRec.put("bin_file", oFileSys.readfilebin(sSourcePath+sSourceFile));
    	oRec.store(oConn);
      }
    } else {
      
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLocation.upload()");
    }
  } // upload()

  // ----------------------------------------------------------

  /**
   * <p>Delete Productocation</p>
   * If ProductLocation URL point to a file that does not exist then an SQLException will be raised.<br>
   * Disk files are only deleted for CONTAINER_FILE and CONTAINER_FTP container types. Files pointed by
   * other protocols (such as CONTAINER_HTTP) will not be deleted with by this method.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    boolean bRetVal;
    FileSystem oFS = new FileSystem();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLocation.delete(" + getString(DB.gu_location) + ")" );
      DebugFile.incIdent();
    }

    try {
      if (getInt(DB.id_cont_type)==ProductLocation.CONTAINER_FILE || getInt(DB.id_cont_type)==ProductLocation.CONTAINER_FTP) {

        oFS.delete(getURL());
      } // fi(CONTAINER_*)
    }
    catch (IOException ioe) {
      if (ioe.getMessage().indexOf("No such file or directory")<0)
        throw new SQLException(ioe.getMessage());
    }

    oFS = null;

    bRetVal =  super.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Product.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  private static HashMap<String,LinkedList<Column>> oColsMap = new HashMap<String,LinkedList<Column>>();
  
  public static final short ClassId = 16;

  public static final int CONTAINER_FILE = 1;
  public static final int CONTAINER_HTTP = 2;
  public static final int CONTAINER_HTTPS = 3;
  public static final int CONTAINER_FTP = 4;
  public static final int CONTAINER_ODBC = 5;
  public static final int CONTAINER_LOTUS = 6;
  public static final int CONTAINER_JDBC = 7;
  public static final int CONTAINER_WARE = 100;

}
