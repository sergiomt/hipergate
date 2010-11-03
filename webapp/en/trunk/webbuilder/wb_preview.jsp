<%@ page import="com.knowgate.debug.DebugFile,java.lang.System,java.util.Vector,java.io.IOException,java.io.File,java.util.Properties,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Environment,com.knowgate.acl.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*,javax.xml.transform.TransformerException,javax.xml.transform.TransformerConfigurationException" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String sSep = System.getProperty("file.separator");
  
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = nullif(request.getParameter("gu_pageset"));
  String sDocType = request.getParameter("doctype");
  String sPage = nullif(request.getParameter("page"));

  String sAppDir, sIntegrador;
  
  if (sDocType.equals("newsletter")) {
    sAppDir = "Mailwire";
  }
  else {
    sAppDir = "WebBuilder";
  } 
  
  Properties UserProperties = new Properties();      
  UserProperties.put("domain",   id_domain);
  UserProperties.put("workarea", gu_workarea);
  UserProperties.put("pageset",  gu_pageset);
  
  // Rutas y parámetros
  String sWWWRoot 	= request.getRealPath(request.getServletPath());
  sWWWRoot = sWWWRoot.substring(0,sWWWRoot.lastIndexOf(sSep)) + sSep + "..";
  
  String sDefURLRoot = request.getRequestURI();
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));

  String sURLRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver", sDefURLRoot);
  
  if (sURLRoot.endsWith("/") && sURLRoot.length()>0) sURLRoot = sURLRoot.substring(0, sURLRoot.length()-1);
  
  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sStorageRoot 	= Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");
  String sEnvWorkGet	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasget", sDefWrkArGet);
  String sEnvWorkPut	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasput", sDefWrkArPut);
 
  String sMenuPath = sURLRoot + "/webbuilder/wb_mnuintegrador.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_pageset=" + gu_pageset + "&doctype=" + sDocType + "&page=" + sPage;
  String sOutputPathEdit = sEnvWorkPut + sSep + gu_workarea + sSep + "apps" + sSep + sAppDir + sSep + "html" + sSep + gu_pageset + sSep;
  String sURLEdit = sEnvWorkGet + "/" + gu_workarea + "/apps/" + sAppDir + "/html/" + gu_pageset + "/";

  // Declaración de instancias
  String sFilePageSet=null, sFileTemplate=null, sCompanyGUID=null;
   
  JDCConnection oConn = GlobalDBBind.getConnection("wb_preview");

  try {

    PageSetDB oPageSetDB = new PageSetDB(oConn, gu_pageset);

    sFilePageSet = sStorageRoot + oPageSetDB.getString(DB.path_data);
    sFileTemplate = sStorageRoot + oPageSetDB.getString(DB.path_metadata);

    sCompanyGUID = oPageSetDB.getStringNull(DB.gu_company, null);

    if (sCompanyGUID!=null)
      PageSet.mergeCompanyInfo (oConn, sFilePageSet, sCompanyGUID);
      
    oPageSetDB = null;
  
    oConn.close("wb_preview");

  }
  catch (SQLException sqle) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("wb_preview");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", sqle.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_close"));       
  }

  if (null==oConn) return;
  
  oConn = null;  
  
  File oFileDir;
  
  if (DebugFile.trace) DebugFile.writeln("<JSP: new File (" + sOutputPathEdit + ");>");
  
  oFileDir = new File (sOutputPathEdit);
  if (!oFileDir.exists()) oFileDir.mkdirs();

  oFileDir = null;
  
  PageSet oPageSet = null;
  
  try {
    if (DebugFile.trace) DebugFile.writeln("<JSP: new PageSet (" + sFileTemplate + "," + sFilePageSet + ",...);>");
    
    oPageSet = new PageSet (sFileTemplate, sFilePageSet, true);
  }
  catch (ClassNotFoundException cnfe) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=PageSet ClassNotFoundException&desc=" + cnfe.getMessage() + "<BR>" + sFileTemplate + "<BR>" + sFilePageSet + "&resume=_close")); 
  }

  if (null==oPageSet) return;

  if (DebugFile.trace) DebugFile.writeln("<JSP: Vector vPages = oPageSet.pages();>");

  Vector vPages = oPageSet.pages();
  
  try {
    if (DebugFile.trace) DebugFile.writeln("<JSP: PageSet.buildSite(" + sStorageRoot + "," + sOutputPathEdit + ", ...);>" );
    oPageSet.buildSite(sStorageRoot, sOutputPathEdit, Environment.getProfile(GlobalDBBind.getProfileName()), UserProperties);
  }
  catch (IOException ioe) {
    oPageSet = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", ioe.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close")); 
  }
  catch (TransformerConfigurationException tcxc) {
    oPageSet = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "TransformerConfigurationException", tcxc.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=TransformerConfigurationException&desc=" + tcxc.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close")); 
  }
  catch (TransformerException texc) {
    oPageSet = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "TransformerException", texc.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=TransformerException&desc=" + texc.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathEdit + "&resume=_close")); 
  }

  if (null==oPageSet) return;
  
  oPageSet = null;
  
  Page oPage = (Page) vPages.firstElement();
    
  // Redirección a la página renderizada
  if (sPage.length()==0) {
    if (DebugFile.trace) DebugFile.writeln("<JSP: response.encodeRedirectUrl (" + sURLEdit + oPage.getTitle().replace(' ', '_') + ".html);>");
    
    response.sendRedirect (response.encodeRedirectUrl (sURLEdit + oPage.getTitle().replace(' ', '_') + ".html"));  
  }
  else {
    if (DebugFile.trace) DebugFile.writeln("<JSP: response.encodeRedirectUrl (" + sURLEdit + sPage + ".html);>");

    response.sendRedirect (response.encodeRedirectUrl (sURLEdit + sPage + ".html"));
  }
%>
<%@ include file="../methods/page_epilog.jspf" %>
