<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.WelcomePack" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  WelcomePack oPak = new WelcomePack();

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("welcomepack_store"); 
  
    loadRequest(oConn, request, oPak);

    oConn.setAutoCommit (false);
    
    oPak.store(oConn);
    
    oConn.commit();
    oConn.close("welcomepack_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"welcomepack_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"welcomepack_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;
  
  response.sendRedirect (response.encodeRedirectUrl ("welcomepack_edit.jsp?gu_pack="+oPak.getString(DB.gu_pack)+"&gu_workarea="+request.getParameter("gu_workarea")+(request.getParameter("gu_company").length()>0 ? "&gu_company="+request.getParameter("gu_company") : "")+(request.getParameter("gu_contact").length()>0 ? "&gu_contact="+request.getParameter("gu_contact") : "")+"&linktable="+request.getParameter("linktable")+"&linkfield="+request.getParameter("linkfield")+"&linkvalue="+request.getParameter("linkvalue")));
%>