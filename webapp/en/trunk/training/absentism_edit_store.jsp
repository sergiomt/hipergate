<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.training.Absentism" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/reqload.jspf" %><%
/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
        
  Absentism oAbsm = new Absentism();

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("absent_edit_store"); 
    loadRequest(oConn, request, oAbsm);
    oAbsm.put(DB.gu_writer, getCookie (request, "userid", null));
    oAbsm.put(DB.dt_from, new Date (Integer.parseInt(request.getParameter("sel_year_from"))-1900, Integer.parseInt(request.getParameter("sel_month_from")), Integer.parseInt(request.getParameter("sel_day_from")), Integer.parseInt(request.getParameter("sel_hour_from")), Integer.parseInt(request.getParameter("sel_min_from")), 0)); 
    oAbsm.put(DB.dt_to, new Date (Integer.parseInt(request.getParameter("sel_year_to"))-1900, Integer.parseInt(request.getParameter("sel_month_to")), Integer.parseInt(request.getParameter("sel_day_to")), Integer.parseInt(request.getParameter("sel_hour_to")), Integer.parseInt(request.getParameter("sel_min_to")), 0));
    oConn.setAutoCommit (false);
    oAbsm.store(oConn);
    oConn.commit();
    oConn.close("absent_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"absent_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"absent_new_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); window.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>