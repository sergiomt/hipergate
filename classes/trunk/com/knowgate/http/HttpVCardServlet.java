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

package com.knowgate.http;

import javax.servlet.*;
import javax.servlet.http.*;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Connection;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Environment;
import com.knowgate.addrbook.Fellow;

/**
 * <p>Get RFC 2426 vCard from Fellow or Contact</p>
 * @author Sergio Montoro ten
 * @version 2.1
 */

public class HttpVCardServlet extends HttpServlet {

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
     java.util.Properties env = Environment.getProfile("hipergate");

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
  * <p>Send Fellow vCard to HttpServletResponse OutputStream</p>
  * @throws IOException
  * @throws ServletException
  */
 public void doGet(HttpServletRequest request, HttpServletResponse response)
    throws java.io.IOException, ServletException
    {
    boolean bFound;
    Class oDriver;
    Connection oConn = null;
    Fellow oFlw = new Fellow();
    String sPKFld, sPKVal, vCard, sNick = null;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin HttpVCardServlet.doGet");
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

    try {
      if (DebugFile.trace) DebugFile.writeln("DriverManager.getConnection(" + jdbcURL + ",...)");

      oConn = DriverManager.getConnection(jdbcURL,dbUserName,dbUserPassword);

      sPKFld = (request.getParameter("pk_field")!=null ? request.getParameter("pk_field") : "null");
      sPKVal = (request.getParameter("pk_value")!=null ? request.getParameter("pk_value") : "null");

      if (DebugFile.trace) DebugFile.writeln("pk_field = " + sPKFld);

      if (sPKFld.equalsIgnoreCase("gu_fellow")) {
        bFound = oFlw.load(oConn, new Object[]{sPKVal});

        if (!oFlw.isNull("tx_nickname"))
          sNick = oFlw.getString("tx_nickname");
        else
          sNick = sPKVal;
      }
      else
        bFound = false;

      if (bFound) {

        if (DebugFile.trace) {
          DebugFile.writeln("response.setContentType(\"application/directory\")");
          DebugFile.writeln("response.setHeader(\"Content-Disposition\", \"attachment; filename=\"" + sNick + ".vcf\"");
        }

        // Send some basic http headers to support binary d/l.
        response.setContentType("application/directory");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + sNick + ".vcf\"");

        oOut.print(oFlw.vCard(oConn));

        oOut.flush();
      } // fi (bFound)

      if (!bFound) {
        if (DebugFile.trace) DebugFile.writeln("SQLException: Cannot find requested document");

        response.sendError(HttpServletResponse.SC_NOT_FOUND, "Cannot find requested document");
      }

      oConn.close();
      oConn = null;
    }
    catch (SQLException e) {
      bFound = false;

      if (DebugFile.trace) DebugFile.writeln("SQLException: " + e.getMessage());

      response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
    }
    try { if(null!=oConn) if(!oConn.isClosed()) oConn.close(); } catch (SQLException e) { }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpVCardServlet().doGet()");
    }
  } // doGet()

  // **********************************************************
  // * Variables privadas

  private String jdbcDriverClassName;
  private String jdbcURL;
  private String dbUserName;
  private String dbUserPassword;
}
