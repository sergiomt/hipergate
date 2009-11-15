<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.ToDo,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/reqload.jspf" %>
<%
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_user = request.getParameter("gu_user");
  
  String gu_to_do = request.getParameter("gu_object");

  JDCConnection oConn = null;

  ToDo oTodo = new ToDo();
  
  try {
    oConn = GlobalDBBind.getConnection("todo_edit_store"); 
  
    loadRequest(oConn, request, oTodo);

    String dt_end = request.getParameter("dt_end");
    if (dt_end.length()>0) {
      String[] aDt = Gadgets.split(dt_end.substring(0,10),'-');
      oTodo.replace("dt_end", new java.util.Date(Integer.parseInt(aDt[0])-1900,Integer.parseInt(aDt[1])-1,Integer.parseInt(aDt[2]), 23, 59, 59));
    }
    
    oConn.setAutoCommit (false);
    
    oTodo.store(oConn);
    
    oConn.commit();

    oConn.setAutoCommit (true);
    
    com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, gu_user, "com.knowgate.http.portlets.CalendarTab", gu_workarea);
    
    oConn.close("todo_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"todo_edit_store");
    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?resume=_back&title=SQLException&desc=" + e.getMessage()));
    return; 
  }

  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); window.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>
<%@ include file="../methods/page_epilog.jspf" %>
