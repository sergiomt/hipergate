<%@ page import="java.util.Enumeration,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.acl.PasswordRecord,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="pwdtemplates.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "pwd_store";

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
	boolean bSession = (session.getAttribute("validated")!=null);

	if (!bSession) {
	  response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Session Expired&desc=Session has expired. Please log in again&resume=_close"));
    return;
  } else if (!((Boolean) session.getAttribute("validated")).booleanValue() || session.getAttribute("signature")==null) {
	  response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Session Expired&desc=Session has expired. Please log in again&resume=_close"));
    return;
  }

  String sSignature = (String) session.getAttribute("signature");
	if (null==sSignature) {
	  response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Invalid Session&desc=Session is invalid. Please log in again&resume=_close"));
    return;
  }   

  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_category = request.getParameter("gu_category");
  String nm_template = request.getParameter("nm_template");
  String id_user = getCookie (request, "userid", null);
  
  String gu_pwd = request.getParameter("gu_pwd");

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  String sOpCode = gu_pwd.length()>0 ? "NPWD" : "MPWD";

  PasswordRecordTemplate oRec = new PasswordRecordTemplate();
  oRec.load(Gadgets.chomp(getTemplatesPath(sStorage, id_domain, gu_workarea, id_user),File.separator)+nm_template);
      
  PasswordRecord oPwd = new PasswordRecord(sSignature);

  JDCConnection oConn = null;

  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

    loadRequest(oConn, request, oPwd);
			
    oConn.setAutoCommit (false);

		Enumeration en = request.getParameterNames();
  
    while (en.hasMoreElements()) {            
      String paramName = (String) en.nextElement();
      if (!paramName.startsWith("lbl_") && 
          !paramName.equals("gu_pwd") && !paramName.equals("tl_pwd") && !paramName.equals("id_domain") &&
          !paramName.equals("gu_workarea") && !paramName.equals("gu_category") && !paramName.equals("nm_template")
          && !paramName.equals("gu_writer") && !paramName.equals("gu_user") && !paramName.equals("id_enc_method")) {
        char cTp = oRec.getTypeOf(paramName);
        String sLabel = request.getParameter("lbl_"+paramName);
        String sValue = nullif(request.getParameter(paramName));
        if (sValue.equalsIgnoreCase("null")) sValue = "";
        oPwd.addLine(paramName, cTp==(char)0 ? '$' : cTp, sLabel, sValue);
      } // fi
    } // wend

    oPwd.put(DB.gu_user, request.getParameter("gu_writer"));

    oPwd.store(oConn, gu_category);

		GlobalCacheClient.expire(request.getParameter("gu_writer")+"["+oPwd.getStringNull(DB.id_pwd,"")+"]");

    DBAudit.log(oConn, PasswordRecord.ClassId, sOpCode, id_user, gu_pwd, null, 0, 0, null, null);

    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.refreshPasswordList(); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>