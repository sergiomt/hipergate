<%@ page import="java.util.*,java.math.*,java.io.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*,com.knowgate.misc.*,com.knowgate.workareas.FileSystemWorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<%
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
 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
 
  final String sSep = System.getProperty("file.separator");
  
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_microsite = request.getParameter("gu_microsite");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String gu_pageset = request.getParameter("gu_pageset");
  String sDocType = request.getParameter("doctype");
  String sTitle = request.getParameter("title");
  String sDataFile = request.getParameter("path_data");
  String sMetaFile = request.getParameter("path_metadata");
  String sDataTemplateFile;
  String sTemplateData;

  String sAppDir;
  
  if (sDocType.equals("newsletter")) {
    sAppDir = "Mailwire";
  } else if (sDocType.equals("website")) {
    sAppDir = "WebBuilder";
  } else if (sDocType.equals("survey")) {
    sAppDir = "Surveys";  
  } else {
    sAppDir = "Other";
  }

  if (DebugFile.trace) {
    DebugFile.writeln("<JSP: storage=" + sStorage);
    DebugFile.writeln("<JSP: path_data=" + sDataFile);
    DebugFile.writeln("<JSP: path_metadata=" + sMetaFile);
  }

  FileSystemWorkArea oFS = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));

  String sUrl = "pageset_listing.jsp?selected=5&subselected=0&doctype=" + sDocType;  

  PageSetDB oPgSt = new PageSetDB();
   
  JDCConnection oConn = null;  
  
  try {

    oConn = GlobalDBBind.getConnection("pageset_edit_store");  

    if (gu_pageset.length()>0) oPgSt.put("gu_pageset", gu_pageset);

    loadRequest(oConn, request, oPgSt);

    oConn.setAutoCommit (false);

    oPgSt.store(oConn);

    // Guardar XML preparado
  
    oFS.mkstorpath (Integer.parseInt(id_domain), gu_workarea, "apps" + sSep + sAppDir + sSep + "data");
    
    // Almacenar Home/Index
      
    Microsite msite = MicrositeFactory.getInstance(sMetaFile);
  
    Container oContainer = msite.container(0);

    if (oContainer==null)
     throw new NullPointerException("Cannot find container(0) on microsite metadata");
     
    if (sDocType.equals("newsletter"))
      sDataTemplateFile = Gadgets.replace(sMetaFile,".xml", ".datatemplate.xml");
    else
      sDataTemplateFile = Gadgets.replace(sMetaFile,".xml", "_" + oContainer.name() + ".datatemplate.xml");
  
    if (!oFS.exists("file://"+sDataTemplateFile))
      throw new FileNotFoundException ("Required file not found "+sDataTemplateFile);
      
    sTemplateData = oFS.readfilestr(sDataTemplateFile, "UTF-8");
  
    sTemplateData = Gadgets.replace (sTemplateData, ":gu_pageset", oPgSt.getString(DB.gu_pageset));
    sTemplateData = Gadgets.replace (sTemplateData, ":gu_microsite", gu_microsite);
    sTemplateData = Gadgets.replace (sTemplateData, ":gu_pagex", Gadgets.generateUUID());
    sTemplateData = Gadgets.replace (sTemplateData, ":page_title", sDocType.equals("newsletter") ? request.getParameter("nm_pageset") : "Index");
    sTemplateData = Gadgets.replace (sTemplateData, ":gu_container", oContainer.guid());
  
    if (sDocType.equals("website"))
      sTemplateData = Gadgets.replace (sTemplateData, ":gu_pageres", Gadgets.generateUUID());
      
    oFS.writefilestr (sStorage + sDataFile, sTemplateData, "UTF-8");
    
    File oDataFile = new File(sStorage + sDataFile);
    if (!oDataFile.exists()) {
      throw new IOException("File Creation Failed "+sStorage + sDataFile+"Check the valueof workareasput at hipergate.cnf and to permissions on the directory to which it points");
    }
    
    oConn.commit();
    oConn.close("pageset_edit_store");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("pageset_edit_store");      
      }
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
        
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (FileNotFoundException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("pageset_edit_store");      
      }
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "FileNotFoundException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (IOException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("pageset_edit_store");      
      }
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (NullPointerException e) {  
   if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("pageset_edit_store");      
      }
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (ClassNotFoundException e) {  
   if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("pageset_edit_store");      
      }
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ClassNotFoundException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (IllegalAccessException e) {  
   if (oConn!=null)
      if (!oConn.isClosed()) {
        if (oConn.getAutoCommit()) oConn.rollback();
        oConn.close("pageset_edit_store");      
      }
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IllegalAccessException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassNotFoundException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  oConn = null;
  
  //Refrescar el padre y cerrar la ventana
%>
<html>
<head>
  <TITLE>[~Espere~]...</TITLE>
  <script>
    <!--
      window.top.opener.location = "<%=sUrl%>";
      window.top.location="wb_file_upload.jsp?caller=newdocument&gu_pageset=<%=oPgSt.getString(DB.gu_pageset)%>&doctype=<%=sDocType%>&title=" + escape("<%=sTitle%>") + "&dir=";
    //-->
  </script>
</head>
</html>
<%@ include file="../methods/page_epilog.jspf" %>