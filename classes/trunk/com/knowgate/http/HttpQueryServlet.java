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

import java.io.IOException;
import java.io.FileNotFoundException;

import java.util.Properties;

import javax.servlet.*;
import javax.servlet.http.*;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Connection;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Environment;
import com.knowgate.hipergate.QueryByForm;

/**
 * <p>Get Query By Form results</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 * @see com.knowgate.hipergate.QueryByForm
 */

public class HttpQueryServlet extends HttpServlet {

  // -----------------------------------------------------------

  private boolean isVoid(String sParam) {
    if (null==sParam)
      return true;
    else
      return (sParam.length()==0);
  }

  private boolean hasSqlSignature(String s) {
    boolean bRetVal = false;
    try {
      bRetVal = Gadgets.matches(s, "(\\%27)|(\\')|(\\-\\-)|(\\%23)|(#)") ||
                Gadgets.matches(s, "((\\%3D)|(=))[^\\n]*((\\%27)|(\\')|(\\-\\-)|(\\%3B)|(;))") ||
                Gadgets.matches(s, "\\w*((\\%27)|(\\'))((\\%6F)|o|(\\%4F))((\\%72)|r|(\\%52))") ||
                Gadgets.matches(s, "((\\%27)|(\\'))union");
    } catch (org.apache.oro.text.regex.MalformedPatternException ignore) {
      // never thrown
    }
    return bRetVal;
  } // hasSqlSignature

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
   * <p>Get Query By Form results throught response output stream.</p>
   * @param queryspec Name of XML file containing the Query Specification
   * @param columnlist List of comma separated column names to retrieve
   * @param where SQL WHERE clause to apply
   * @param order by SQL ORDER BY clause to apply
   * @param showas Output format. One of { "CSV" <i>(comma separated)</i>, "TSV" <i>(tabbed separated)</i>, "XLS" <i>(Excel)</i> }
   * @throws IOException
   * @throws FileNotFoundException
   * @throws ServletException
   */
  public void doGet(HttpServletRequest request, HttpServletResponse response)
     throws IOException, FileNotFoundException, ServletException
     {
     Class oDriver;
     Connection oConn = null;
     ServletOutputStream oOut = response.getOutputStream();
     QueryByForm oQBF;
     String sQuerySpec;
     String sColumnList;
     String sWhere;
     String sOrderBy;
     String sShowAs;
     String sStorage;

     if (DebugFile.trace) {
       DebugFile.writeln("Begin HttpQueryServlet.doGet(...)");
       DebugFile.incIdent();
     }

     sStorage = Environment.getProfileVar("hipergate", "storage");

     if (DebugFile.trace) DebugFile.writeln("storage=" + sStorage);

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

       sQuerySpec = request.getParameter("queryspec");
       sColumnList = request.getParameter("columnlist");
       if (null==sColumnList) sColumnList = "*";
       sWhere = request.getParameter("where");
       if (null==sWhere) sWhere = "1=1";
       sOrderBy = request.getParameter("orderby");
       if (null==sOrderBy) sOrderBy = "";
       sShowAs = request.getParameter("showas");
       if (null==sShowAs) sShowAs = "CSV";

       if (DebugFile.trace) DebugFile.writeln("queryspec=" + sQuerySpec!=null ? sQuerySpec : "null");
       if (DebugFile.trace) DebugFile.writeln("where=" + sWhere);
       if (DebugFile.trace) DebugFile.writeln("orderby=" + sOrderBy);

	   if (hasSqlSignature(sColumnList)) {
         response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid Column List Syntax");
		 return;
	   }

       oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + sQuerySpec + ".xml");

       if (DebugFile.trace) DebugFile.writeln("DriverManager.getConnection(" + jdbcURL + ",...)");
       oConn = DriverManager.getConnection(jdbcURL,dbUserName,dbUserPassword);

       // Send some basic http headers to support binary d/l.
       if (sShowAs.equalsIgnoreCase("XLS")) {
         response.setContentType("application/x-msexcel");
         response.setHeader("Content-Disposition", "inline; filename=\"" + oQBF.getTitle(request.getLocale().getLanguage())+ " 1.csv\"");
       }
       else if (sShowAs.equalsIgnoreCase("CSV")) {
         response.setContentType("text/plain");
         response.setHeader("Content-Disposition","attachment; filename=\"" + oQBF.getTitle(request.getLocale().getLanguage())+ " 1.csv\"");
       }
       else if (sShowAs.equalsIgnoreCase("TSV")) {
         response.setContentType("text/tab-separated-values");
         response.setHeader("Content-Disposition","attachment; filename=\"" + oQBF.getTitle(request.getLocale().getLanguage())+ " 1.tsv\"");
       }
       else {
         response.setContentType("text/plain");
         response.setHeader("Content-Disposition", "inline; filename=\"" + oQBF.getTitle(request.getLocale().getLanguage())+ " 1.txt\"");
       }

       if (0==sOrderBy.length())
         oQBF.queryToStream(oConn, sColumnList, oQBF.getBaseFilter(request) + " " + sWhere, oOut, sShowAs);
       else
         oQBF.queryToStream(oConn, sColumnList, oQBF.getBaseFilter(request) + " " + sWhere + " ORDER BY " + sOrderBy, oOut, sShowAs);

       oConn.close();
       oConn = null;

       oOut.flush();
     }
     catch (SQLException e) {
       if (DebugFile.trace) DebugFile.writeln("SQLException " + e.getMessage());
       response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
     }
     catch (ClassNotFoundException e) {
       if (DebugFile.trace) DebugFile.writeln("ClassNotFoundException " + e.getMessage());
       response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
     }
     catch (IllegalAccessException e) {
       if (DebugFile.trace) DebugFile.writeln("IllegalAccessException " + e.getMessage());
       response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
     }
     catch (Exception e) {
       if (DebugFile.trace) DebugFile.writeln("Exception " + e.getMessage());
       response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
     }
     finally {
       try { if(null!=oConn) if(!oConn.isClosed()) oConn.close(); }
       catch (SQLException e) { if (DebugFile.trace) DebugFile.writeln("SQLException " + e.getMessage()); }
     }

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End HttpQueryServlet.doGet()");
     }
   } // doGet()

  // **********************************************************
  // * Private Variables

  private String jdbcDriverClassName;
  private String jdbcURL;
  private String dbUserName;
  private String dbUserPassword;

}