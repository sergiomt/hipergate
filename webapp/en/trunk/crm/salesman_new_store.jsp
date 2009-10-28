 <%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
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
      
  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("salesman_new_store");
    
    Statement oStmt = oConn.createStatement();
    
    oStmt.executeUpdate("INSERT INTO " + DB.k_sales_men + "(" + DB.gu_sales_man + "," + DB.gu_workarea + ") VALUES ('" + request.getParameter("gu_sales_man") + "','" + request.getParameter("gu_workarea") + "')");
    
    oConn.close("salesman_new_store");
    
    GlobalCacheClient.expire("k_sales_men["+request.getParameter("gu_workarea")+"]");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"salesman_new_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

  GlobalCacheClient.expire ("k_sales_men[" + request.getParameter("gu_workarea") + "]");
%>
<HTML>
  <BODY onload="window.opener.location.reload();self.close()"></BODY>
</HTML>
