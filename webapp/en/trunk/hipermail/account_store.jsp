<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,javax.mail.Session,javax.mail.Store,javax.mail.Transport,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.SessionHandler,com.knowgate.debug.StackTraceUtil,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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
      
  String id_user = request.getParameter("id_user");
  
  MailAccount oObj = new MailAccount();

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("account_store"); 
  
    loadRequest(oConn, request, oObj);

    oConn.setAutoCommit (false);
    
    oObj.store(oConn);
    
    oConn.commit();
    oConn.close("account_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"account_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"account_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;
  
  GlobalCacheClient.expire("["+oObj.getString(DB.gu_account)+"]");
  GlobalCacheClient.expire("["+id_user+",defaultaccount]");
  
  if (request.getParameter("bo_test").equals("true")) {
		SessionHandler oHndlr = null;
		try {
      oHndlr = new SessionHandler (oObj);
      if (request.getParameter("incoming_server").length()>0) {
        Session oSssn = oHndlr.getSession();
        Store oStor = oHndlr.getStore();
      }
      if (request.getParameter("outgoing_server").length()>0) {
        Transport oTrprt = oHndlr.getTransport();
      }
      oHndlr.close();
      out.write("<HTML><BODY><FONT CLASS=\"textplain\">TEST OK</FONT></BODY></HTML>");
    } catch (Exception xcpt) {
      out.write ("<HTML><BODY><FONT CLASS=\"textplain\">");
      if (oHndlr!=null) out.write (oHndlr.getProperties().toString());
      out.write (xcpt.getClass().getName()+" "+xcpt.getMessage()+"<BR/><BR/>");
      if (xcpt.getCause()!=null) out.write ("Cause: "+xcpt.getCause().getClass().getName()+" "+xcpt.getCause().getMessage()+"<BR/><BR/>");
      out.write (Gadgets.replace(StackTraceUtil.getStackTrace(xcpt),"\n","<BR/>"));
      out.write ("</FONT></BODY></HTML>");
    }
  } else if (request.getParameter("bo_popup").equals("true")) {
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>if (window.opener) if (!window.opener.closed) window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

  } else {
    response.sendRedirect (response.encodeRedirectUrl ("account_list.jsp"));
  }
%>