 <%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.forums.Subscription" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/nullif.jspf" %>
<% 
/*
  Subscribe User to a News Group

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

  String gu_newsgrp = request.getParameter("gu_newsgrp");
  String gu_user = request.getParameter("gu_user");
  String tx_email = request.getParameter("tx_email");
  
  String id_msg_type = nullif(request.getParameter("gu_user"), "TXT");
  short tp_subscrip = Short.parseShort(nullif(request.getParameter("gu_user"), "1"));

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("forum_subscribe_user");
      
    if (null==gu_user && null!=tx_email)
      gu_user = ACLUser.getIdFromEmail(oConn, tx_email);
      
    Subscription.subscribe (oConn, gu_newsgrp, gu_user, id_msg_type, tp_subscrip);
     
    oConn.close("forum_subscribe_user");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"forum_subscribe_user");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("...");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

  /* TO DO: Write HTML or redirect to another page */
%>
