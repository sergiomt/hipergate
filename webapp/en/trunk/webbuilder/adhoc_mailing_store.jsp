<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipermail.AdHocMailing,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
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

  final String PAGE_NAME = "adhoc_mailing_store";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_mailing = request.getParameter("gu_mailing");

  String sOpCode = gu_mailing.length()>0 ? "NAHM" : "MAHM";
      
  AdHocMailing oObj = new AdHocMailing();
  
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 
		 
    loadRequest(oConn, request, oObj);

		if (oObj.isNull(DB.bo_plain_part)) oObj.put(DB.bo_plain_part, (short) 0);
		if (oObj.isNull(DB.bo_html_part)) oObj.put(DB.bo_html_part, (short) 0);
		
    oConn.setAutoCommit (false);
    
    oObj.store(oConn);

    DBAudit.log(oConn, oObj.ClassId, sOpCode, id_user, gu_mailing, null, 0, 0, oObj.getStringNull(DB.nm_mailing,""), null);
		    
    oConn.commit();

    oConn.close(PAGE_NAME);

  }
  catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>