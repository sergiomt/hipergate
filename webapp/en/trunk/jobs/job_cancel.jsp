<%@ page import="com.knowgate.misc.Gadgets,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.scheduler.Job" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
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
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String id_status = request.getParameter("id_status");
  String sSQL = new String("");
  
  JDCConnection oConn = GlobalDBBind.getConnection("jobcancel");  
  
  String aItems[] = Gadgets.split(request.getParameter("checkeditems"),",");
  for (int i=1; i<aItems.length; i++) {
   String gu_job = aItems[i];
   try {
    oConn.setAutoCommit (false);
    sSQL = "UPDATE k_jobs SET id_status=" + String.valueOf(Job.STATUS_ABORTED) + " WHERE gu_job='" + gu_job + "'";
    PreparedStatement stmt = oConn.prepareStatement(sSQL);
    stmt.executeUpdate();   
    oConn.commit();
    oConn.close("jobcancel");
   }
   catch (SQLException e) {  
    disposeConnection(oConn,"jobcancel");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
   }
  }
  oConn = null;
  
  // [~//Volver a la lista de tareas~]
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>history.back();<" + "/SCRIPT" +"></HEAD></HTML>");
%>