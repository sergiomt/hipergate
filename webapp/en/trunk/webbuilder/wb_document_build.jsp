<%@ page import="java.util.Vector,dom.DOMDocument,com.knowgate.debug.DebugFile,java.lang.System,java.io.UnsupportedEncodingException,java.io.FileNotFoundException,java.io.IOException,java.io.File,java.util.Properties,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.acl.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*,javax.xml.transform.TransformerException,javax.xml.transform.TransformerConfigurationException" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = nullif(request.getParameter("gu_pageset"));
  String sDocType = request.getParameter("doctype");
  String sPage = nullif(request.getParameter("page"));

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

  Properties UserProperties = new Properties();
  UserProperties.put("domain",   id_domain);
  UserProperties.put("workarea", gu_workarea);
  UserProperties.put("pageset",  gu_pageset);
     
  // Rutas y parámetros
  
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sEnvWorkPut	 = Gadgets.dechomp(Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasput",sDefWrkArPut),java.io.File.separator);
  String sStorageRoot	 = Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");
  String sOutputPathHtml = sEnvWorkPut + File.separator + gu_workarea + File.separator + "apps" + File.separator + sAppDir + File.separator + "html" + File.separator + gu_pageset + File.separator;

  String sFilePageSet = null;
  String sFileTemplate= null;
  String sCompanyGUID = null;
   
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("wb_document_build");
    
    PageSetDB oPageSetDB = new PageSetDB();
    
    if (!oPageSetDB.load(oConn, new Object[]{gu_pageset}))
      throw new SQLException("PageSet " + gu_pageset + " not found at " + DB.k_pagesets); 
  
    sFilePageSet = sStorageRoot + oPageSetDB.getString(DB.path_data);
    sFileTemplate = sStorageRoot + oPageSetDB.getString(DB.path_metadata);

    sCompanyGUID = oPageSetDB.getStringNull(DB.gu_company, null);

    if (sCompanyGUID!=null)
      PageSet.mergeCompanyInfo (oConn, sFilePageSet, sCompanyGUID);
        
    oConn.close("wb_document_build");
    oConn = null;
    
    PageSet oPageSet = new PageSet (sFileTemplate, sFilePageSet);
      
    Vector vPages = oPageSet.buildSite(sStorageRoot, sOutputPathHtml, Environment.getProfile(GlobalDBBind.getProfileName()), UserProperties);
    int iSize = vPages.size();

    oConn = GlobalDBBind.getConnection("wb_document_build");

    for (int p=0; p<iSize; p++) {
      Page oPage = (Page) vPages.get(p);
      oPageSetDB.setPage(oConn, oPage.guid(), p+1, oPage.getTitle(), oPage.filePath());
    }

    oConn.close("wb_document_build");
    oConn = null;
  }
  catch (SQLException sqle) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("wb_document_build");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", sqle.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_none"));       
    return;
  }
  catch (ClassNotFoundException cnfe) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "ClassNotFoundException", cnfe.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=PageSet ClassNotFoundException&desc=" + cnfe.getMessage() + "<BR>" + sFileTemplate + "<BR>" + sFilePageSet + "&resume=_none")); 
    return;
  }
  catch (FileNotFoundException fnfe) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "FileNotFoundException", fnfe.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + fnfe.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathHtml + "&resume=_none")); 
    return;
  }
  catch (UnsupportedEncodingException uee) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "UnsupportedEncodingException", uee.getMessage());
    }
  
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=UnsupportedEncodingException&desc=" + uee.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathHtml + "&resume=_none")); 
    return;
  }
  catch (IOException ioe) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", ioe.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathHtml + "&resume=_none")); 
    return;
  }
  catch (TransformerConfigurationException tcxc) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "TransformerConfigurationException", tcxc.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + tcxc.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathHtml + "&resume=_none")); 
    return;
  }
  catch (TransformerException texc) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "TransformerException", texc.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + texc.getMessage() + "<BR>" + sStorageRoot + "<BR>" + sOutputPathHtml + "&resume=_none")); 
    return;
  }  
%>
<HTML>
<HEAD><TITLE>Wait...</TITLE></HEAD>
<BODY onLoad="document.forms[0].submit()">
  <FORM METHOD="post" ACTION="../jobs/job_confirm.jsp" TARGET="_top">
    <INPUT TYPE="hidden" NAME="target_dir" VALUE="<%=sOutputPathHtml%>">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=nullif(request.getParameter("id_domain"))%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=nullif(request.getParameter("gu_workarea"))%>">
    <INPUT TYPE="hidden" NAME="gu_pageset" VALUE="<%=nullif(request.getParameter("gu_pageset"))%>">    
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=nullif(request.getParameter("id_user"))%>">    
    <INPUT TYPE="hidden" NAME="gu_job" VALUE="<%=nullif(request.getParameter("gu_job"))%>">
    <INPUT TYPE="hidden" NAME="gu_job_group" VALUE="<%=nullif(request.getParameter("gu_job_group"))%>">
    <INPUT TYPE="hidden" NAME="id_command" VALUE="<%=nullif(request.getParameter("id_command"))%>">
    <INPUT TYPE="hidden" NAME="tx_parameters" VALUE="<%=nullif(request.getParameter("tx_parameters"))%>">
    <INPUT TYPE="hidden" NAME="id_status" VALUE="<%=nullif(request.getParameter("id_status"))%>">
    <INPUT TYPE="hidden" NAME="tx_job" VALUE="<%=nullif(request.getParameter("tx_job"))%>">
    <INPUT TYPE="hidden" NAME="tl_job" VALUE="<%=nullif(request.getParameter("tl_job"))%>">
    <INPUT TYPE="hidden" NAME="attachimages" VALUE="<%=nullif(request.getParameter("attachimages"),"0")%>">
    <INPUT TYPE="hidden" NAME="dt_execution" VALUE="<%=nullif(request.getParameter("dt_execution"))%>">
    <INPUT TYPE="hidden" NAME="webbeacon" VALUE="<%=nullif(request.getParameter("webbeacon"),"0")%>">
    <INPUT TYPE="hidden" NAME="clickthrough" VALUE="<%=nullif(request.getParameter("clickthrough"),"0")%>">
  </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>