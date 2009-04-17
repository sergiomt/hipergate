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

package com.knowgate.http;

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

import java.util.Properties;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.acl.ACL;
import com.knowgate.dataobjs.DB;
import com.knowgate.hipergate.*;
import com.knowgate.misc.Environment;

import com.enterprisedt.net.ftp.*;

/**
 * <p>Send Disk Binary File To HttpServletResponse OutputStream</p>
 * @author Sergio Montoro ten
 * @version 2.1
 */
public class HttpBinaryServlet extends HttpServlet {

  private static final long serialVersionUID = 2l;

  public static long pipe(InputStream in, OutputStream out, int chunkSize)
    throws IOException {
    if( chunkSize < 1 ) throw new IOException("Invalid chunk size.");

    byte[] buf = new byte[chunkSize];
    long tot = 0;
    int n;
    while( (n=in.read(buf)) != -1 ) {
      out.write(buf,0,n);
      tot += n;
    }
    out.flush();

    return tot;
  } // pipe()

 // -----------------------------------------------------------

 private boolean isVoid(String sParam) {
   if (null==sParam)
     return true;
   else
     return (sParam.length()==0);
 }

 /**
  * <p>Initialize Servlet Parameters</p>
  * Take Database Driver, Conenction URL and User from /WEB-INF/web.xml.<br>
  * If any parameter is not found then look it up at hipergate.cnf Properties
  * file using Environment singleton.
  * @throws ServletException
  * @throws UnavailableException If jdbcDriverClassName parameter is not found
  * and driver property at hipergate.cnf is not found or if jdbcURL parameter
  * is not found and dburl property at hipergate.cnf is not found.
  * @see com.knowgate.misc.Environment
  */
 public void init() throws ServletException {

   ServletConfig config = getServletConfig();

   jdbcDriverClassName = config.getInitParameter("jdbcDriverClassName");

   jdbcURL = config.getInitParameter("jdbcURL");
   dbUserName = config.getInitParameter("dbUserName");
   dbUserPassword = config.getInitParameter("dbUserPassword");

   if (isVoid(jdbcDriverClassName) || isVoid(jdbcURL) || isVoid(dbUserName) || isVoid(dbUserPassword)) {
     Properties env = Environment.getProfile("hipergate");

     if (isVoid(jdbcDriverClassName))
       jdbcDriverClassName = env.getProperty("driver");

     if (isVoid(jdbcURL))
       jdbcURL = env.getProperty("dburl");

     if (isVoid(dbUserName))
       dbUserName = env.getProperty("dbuser");

     if (isVoid(dbUserPassword))
       dbUserPassword = env.getProperty("dbpassword");
   }

   if (jdbcDriverClassName == null || jdbcURL == null)
     throw new UnavailableException("Init params missing");
 } // init()

 // -----------------------------------------------------------

 /**
  * <p>Send disk binary file held in a Product to HttpServletResponse OutputStream</p>
  * @param id_user Requester User GUID.
  * @param id_product GUID of Requested Product.
  * @param id_location GUID of Requested ProductLocation.
  * @param id_category (Optional) GUID from Category that contains the Product to serve.
  * If a Category is provided then the User permissions over that Category are checked
  * before serving the file.
  * @return Throught response.sendError()<br>
  * <table border=1 cellpadding=4>
  * <tr><td><b>HttpServletResponse Error Code</b></td><td><b>Description</b></td></tr>
  * <tr><td>SC_INTERNAL_SERVER_ERROR</td><td>Database driver not found</td></tr>
  * <tr><td>SC_FORBIDDEN</td><td>User does not have read permissions for requested file</td></tr>
  * <tr><td>SC_NOT_FOUND</td><td>Cannot find file</td></tr>
  * </table>
  * @throws IOException
  * @throws FileNotFoundException
  * @throws ServletException
  * @see com.knowgate.acl.ACLUser
  * @see com.knowgate.hipergate.Product
  * @see com.knowgate.hipergate.Category
  */
 public void doGet(HttpServletRequest request, HttpServletResponse response)
    throws IOException, FileNotFoundException, ServletException
    {
    int iACLMask;
    boolean bFound;
    Class oDriver;
    Connection oConn = null;
    PreparedStatement oStmt;
    ResultSet oRSet;
    File myFile;
    Category oCatg;
    String gu_category;
    String id_location;
    String xprotocol = "file://";
    String xpath = null;
    String xfile = null;
    String xoriginalfile = null;
    String mimetype = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpBinaryServlet.doGet()");
      DebugFile.incIdent();
    }

    try {
      oDriver = Class.forName(jdbcDriverClassName);
    }
    catch (ClassNotFoundException ignore) {
      oDriver = null;
      if (DebugFile.trace) DebugFile.writeln("Class.forName(" + jdbcDriverClassName + ") : " + ignore.getMessage());
      response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database driver not found");
    }

    if (null==oDriver) return;

    try {
      if (DebugFile.trace) DebugFile.writeln("DriverManager.getConnection(" + jdbcURL + "," + dbUserName + ", ...)");

      oConn = DriverManager.getConnection(jdbcURL,dbUserName,dbUserPassword);

      // Si el archivo a recuperar está contenido dentro de una categoría,
      // verificar los permisos del usuario sobre dicha categoría
      gu_category = request.getParameter("id_category");
      if (gu_category!=null)
        if (gu_category.length()>0) {
          oCatg = new Category();
          oCatg.put(DB.gu_category, gu_category);
          iACLMask = oCatg.getUserPermissions(oConn, request.getParameter("id_user"));
          oCatg = null;
        }
        else
          iACLMask = ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_MODIFY|ACL.PERMISSION_SEND;
      else
        iACLMask = ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_MODIFY|ACL.PERMISSION_SEND;

      if ((iACLMask&ACL.PERMISSION_READ)==0) {
        bFound = false;
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "User does not have read permissions for requested file");
      }
      else {
        id_location = request.getParameter("id_location");
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT l." + DB.xprotocol + ", l." + DB.xhost + ", l." + DB.xport + ", l." + DB.xpath + ", l." + DB.xfile + ", l." + DB.xoriginalfile + ", t." + DB.mime_type + ",l." + DB.gu_location + ",l." + DB.dt_uploaded +  " FROM " + DB.k_prod_locats + " l, " + DB.k_lu_prod_types + " t WHERE l." + DB.gu_product + "='" + request.getParameter("id_product") + "' AND l." + DB.id_prod_type + "=t." + DB.id_prod_type + " ORDER BY l." + DB.dt_uploaded + " DESC");

        oStmt = oConn.prepareStatement("SELECT l." + DB.xprotocol + ", l." + DB.xhost + ", l." + DB.xport + ", l." + DB.xpath + ", l." + DB.xfile + ", l." + DB.xoriginalfile + ", t." + DB.mime_type + ",l." + DB.gu_location + ",l." + DB.dt_uploaded + " FROM " + DB.k_prod_locats + " l, " + DB.k_lu_prod_types + " t WHERE l." + DB.gu_product + "=? AND l." + DB.id_prod_type + "=t." + DB.id_prod_type + " ORDER BY l." + DB.dt_uploaded + " DESC", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, request.getParameter("id_product"));
        oRSet = oStmt.executeQuery();
        bFound = oRSet.next();

        if (DebugFile.trace) {
          if (bFound)
            DebugFile.writeln("found product " + request.getParameter("id_product"));
          else
            DebugFile.writeln("product " + request.getParameter("id_product") + " not found");
        }

        if ((null!=id_location) && bFound) {
          bFound = false;
          do {
            if (id_location.equals(oRSet.getString(8))) {
              bFound = true;
              break;
            } // fi (id_location==oRSet.get(gu_location))
          } while (oRSet.next());

          if (DebugFile.trace) {
            if (bFound)
              DebugFile.writeln("found location " + id_location);
            else
              DebugFile.writeln("location " + id_location + " not found");
          }
        } // fi (id_location)

        if (bFound) {
          xprotocol = oRSet.getString(1).toLowerCase();
          xpath = oRSet.getString(4);

          if (xprotocol.equalsIgnoreCase("ftp://")) {
            if (!xpath.endsWith("/")) xpath += "/";
          }
          else {
            if (!xpath.endsWith(java.io.File.separator)) xpath += java.io.File.separator;
          }

          xfile = oRSet.getString(5);
          xoriginalfile = oRSet.getString(6);
          mimetype = oRSet.getString(7);

          if (DebugFile.trace) DebugFile.writeln(xoriginalfile + " " + (mimetype == null ? "" : mimetype));
        } // fi (bFound)

        oRSet.close();
        oRSet = null;
        oStmt.close();
        oStmt = null;

        if (!bFound) {
          response.sendError(HttpServletResponse.SC_NOT_FOUND, "Cannot find requested file");
        }
      }

      oConn.close();
      oConn = null;
    }
    catch (SQLException e) {
      if (DebugFile.trace) DebugFile.writeln(e.getMessage());
      bFound = false;
      response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
    }
    try { if(null!=oConn) if(!oConn.isClosed()) oConn.close(); }
    catch (SQLException e) { if (DebugFile.trace) DebugFile.writeln(e.getMessage()); }

    if (!bFound) {
      if (DebugFile.trace) DebugFile.decIdent();
      return;
    }

    // Do initial test to see if we need to send a 404 error.

    if (DebugFile.trace) DebugFile.writeln("new File(" + xpath+xfile + ")");

    if (xprotocol.equals("ftp://")) {
      if (null!=mimetype) response.setContentType(mimetype);
      response.setHeader("Content-Disposition","attachment; filename=\"" + (xoriginalfile==null ? xfile : xoriginalfile) + "\"");

      boolean bLogged = false;
      FTPClient oFTP = null;

      try {
        oFTP = new FTPClient(Environment.getProfileVar("hipergate", "fileserver", "localhost"));

        oFTP.login(Environment.getProfileVar("hipergate", "fileuser", "anonymous"), Environment.getProfileVar("hipergate", "filepassword", ""));

        bLogged = true;

        oFTP.get(response.getOutputStream(), xpath+xfile);

        oFTP.quit();

        bLogged = false;
      }
      catch (FTPException ftpe) {
        if (oFTP!=null && bLogged) {
          try {oFTP.quit(); } catch (Exception ignore) {}
        }
        response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, ftpe.getMessage());
        if (DebugFile.trace) DebugFile.decIdent();
        return;
      }
    }
    else {
      myFile = new File(xpath+xfile);
      if( !myFile.canRead() ) {
          response.sendError(HttpServletResponse.SC_NOT_FOUND, "Cannot find file " + xfile);
          if (DebugFile.trace) DebugFile.decIdent();
          return;
      } // fi(myFile.canRead)

      // Send some basic http headers to support binary d/l.
      if (DebugFile.trace) DebugFile.writeln("setContentLength(" + myFile.length() + ")");

      response.setContentLength((int)myFile.length());

      if (DebugFile.trace && null!=mimetype) DebugFile.writeln("setContentType(" + mimetype + ")");

      if (null!=mimetype) response.setContentType(mimetype);

      if (DebugFile.trace) DebugFile.writeln("setHeader(Content-Disposition,attachment; filename=" + xoriginalfile);

      response.setHeader("Content-Disposition","attachment; filename=\"" + xoriginalfile + "\"");

      // Copy the file's bytes to the servlet output stream,
      // being absolutely sure NOT to leak file handles even
      // in the face of an exception (thus the try/finally block).
      InputStream in = null;
      try {
        in = new BufferedInputStream(new FileInputStream(myFile));
        pipe(in,response.getOutputStream(),2048);
      }
      finally {
        if( in != null ) try {
            in.close();
        } catch( IOException ignore ) { if (DebugFile.trace) DebugFile.writeln("IOException " + ignore.getMessage()); }
      }
    } // fi (xprotocol)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpBinaryServlet.doGet()");
    }
  } // doGet()

  private String jdbcDriverClassName;
  private String jdbcURL;
  private String dbUserName;
  private String dbUserPassword;
}