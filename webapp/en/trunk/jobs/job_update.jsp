<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String gu_job = request.getParameter("gu_job");
  String dt_execution = request.getParameter("dt_execution");
  String a_execution[];
    
  String sSQL = "";

  out.write("Actualizando " + gu_job + " con dt_execution " + request.getParameter("dt_execution"));

  JDCConnection oConn = null;  
  
  try {
    oConn = GlobalDBBind.getConnection("jobupdate");
    
    oConn.setAutoCommit (false);
    
    sSQL = "UPDATE " + DB.k_jobs + " SET " + DB.dt_execution + "=";
    
    if (dt_execution.equals("Lo antes posible") || dt_execution.equals("As soon as possible"))
      sSQL += "NULL";
    else {
      a_execution = Gadgets.split(dt_execution,"-");
      
      sSQL += DBBind.escape(new java.util.Date (Integer.parseInt(a_execution[0])-1900, Integer.parseInt(a_execution[1])-1, Integer.parseInt(a_execution[2]), 0, 0, 0), "ts");
    }
    
    sSQL += " WHERE " + DB.gu_job + "='" + gu_job + "'";

    PreparedStatement oStmt = oConn.prepareStatement(sSQL);
    oStmt.executeUpdate();   
    oStmt.close();
    oConn.commit();
    oConn.close("jobupdate");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"jobupdate");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&SQLException=" + e.getLocalizedMessage() + "&resume=_close"));
  }

  if (null==oConn) return;
  
  oConn = null;
  
  // [~//Refrescar el padre y cerrar la ventana~]
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>
<%@ include file="../methods/page_epilog.jspf" %>