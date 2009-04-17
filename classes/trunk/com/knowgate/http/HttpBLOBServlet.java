/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

import java.io.InputStream;
import java.io.IOException;
import java.io.FileNotFoundException;
import javax.servlet.*;
import javax.servlet.http.*;

import java.util.StringTokenizer;
import java.util.Properties;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Environment;

/**
 * <p>Send LONGVARBINARY database field to HttpServletResponse OutputStream</p>
 * @author Sergio Montoro ten
 * @version 5.0
 */

public class HttpBLOBServlet extends HttpServlet {

 private static final long serialVersionUID = 5l;

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

   if (jdbcDriverClassName == null || jdbcURL == null) {
     throw new UnavailableException("Init params missing");
   }
 } // init()

 // -----------------------------------------------------------

 /**
  * <p>Send LONGVARBINARY database field to HttpServletResponse OutputStream</p>
  * @param nm_table Name of table holding longvarbinary field.
  *
  * @param response
  * @throws IOException
  * @throws FileNotFoundException
  * @throws ServletException
  */
 public void doGet(HttpServletRequest request, HttpServletResponse response)
    throws IOException, FileNotFoundException, ServletException
    {
    boolean bFound;
    String sSQL;
    String sExt;
    String sContentType;
    Class oDriver;
    Connection oConn = null;
    Connection oCon2 = null;
    PreparedStatement oStmt;
    PreparedStatement oStm2;
    ResultSet oRSet;
    ResultSet oRSe2;
    InputStream oBlob = null;
    int iOffset;
    int iReaded;
    int iPar;
    int iDot;
    StringTokenizer oStrTok;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin HttpBLOBServlet().doGet");
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

    ServletOutputStream oOut = response.getOutputStream();

    byte oBuffer[] = new byte[4004];

    try {
      if (DebugFile.trace) DebugFile.writeln("DriverManager.getConnection(" + jdbcURL + ",...)");

      oConn = DriverManager.getConnection(jdbcURL,dbUserName,dbUserPassword);

      if (DebugFile.trace) DebugFile.writeln("pk_field = " + (request.getParameter("pk_field")!=null ? request.getParameter("pk_field") : "null"));

      oStrTok = new StringTokenizer(request.getParameter("pk_field"), ",");

      sSQL = "";
      while (oStrTok.hasMoreTokens()) {
        sSQL += (sSQL.length()==0 ? " WHERE " : " AND ");
        sSQL += oStrTok.nextToken() + "=?";
      } // wend
      sSQL = "SELECT " + request.getParameter("nm_field") + "," + request.getParameter("bin_field") + " FROM " + request.getParameter("nm_table") + sSQL;

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

      oStmt = oConn.prepareStatement (sSQL);
      iPar = 0;
      oStrTok = new StringTokenizer(request.getParameter("pk_value"), ",");
      while (oStrTok.hasMoreTokens()) {
        oStmt.setString(++iPar, oStrTok.nextToken());
      }

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");

      oRSet = oStmt.executeQuery();
      bFound = oRSet.next();

      String sFileName = null;

      if (bFound) {

        sFileName = oRSet.getString(1);
		sContentType = "application/octet-stream";
		iDot = sFileName.indexOf('.');
		
		// New for v5.0, set mime type at header
		
		if (iDot>=0 && iDot<sFileName.length()-1) {
		  sExt = sFileName.substring(iDot+1).toUpperCase();
		  oCon2 = DriverManager.getConnection(jdbcURL,dbUserName,dbUserPassword);
		  oStm2 = oCon2.prepareStatement("SELECT mime_type FROM k_lu_prod_types WHERE id_prod_type=? AND mime_type IS NOT NULL",
		  								 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		  oStm2.setString(1, sExt);
		  oRSe2 = oStm2.executeQuery();
		  if (oRSe2.next()) sContentType = oRSe2.getString(1);
		  oRSe2.close();
		  oStm2.close();
		} // fi
		// *** end new for v5.0

        if (DebugFile.trace) {
          DebugFile.writeln("response.setContentType(\""+sContentType+"\")");
          DebugFile.writeln("response.setHeader(\"Content-Disposition\", \"inline; filename=\"" + sFileName + "\"");
        }

        // Send some basic http headers to support binary d/l.
        response.setContentType(sContentType);
        response.setHeader("Content-Disposition", "inline; filename=\"" + sFileName + "\"");

        if (DebugFile.trace)
          DebugFile.writeln("ResultSet.getBinaryStream(2)");

        oBlob = oRSet.getBinaryStream(2);
        iOffset = 0;
        do {
          iReaded = oBlob.read(oBuffer, 0, 4000);
          if (iReaded>0)
            oOut.write(oBuffer, 0, iReaded);
          iOffset += iReaded;
        } while (4000==iReaded);

        if (DebugFile.trace)
          DebugFile.writeln("response.getOutputStream().flush()");

        oOut.flush();
        oBlob.close();
        oBlob = null;
      } // fi (bFound)

      oRSet.close();

      if (!bFound) {
        if (DebugFile.trace) DebugFile.writeln("FileNotFoundException: Cannot find requested document");

        response.sendError(HttpServletResponse.SC_NOT_FOUND, "Cannot find requested document");
      }

      oConn.close();
      oConn = null;
    }
    catch (SQLException e) {
      bFound = false;
      if (oBlob!=null) oBlob.close();

      if (DebugFile.trace) DebugFile.writeln("SQLException: " + e.getMessage());

      response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
    }
    try { if(null!=oConn) if(!oConn.isClosed()) oConn.close(); } catch (SQLException e) { }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpBLOBServlet().doGet()");
    }
  } // doGet()

  // **********************************************************
  // * Variables privadas

  private String jdbcDriverClassName;
  private String jdbcURL;
  private String dbUserName;
  private String dbUserPassword;
}