<%@ page import="com.knowgate.forums.NewsMessage,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
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
  
  String id_user = getCookie (request, "userid", null);
  String id_status = request.getParameter("id_status");
  
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = GlobalDBBind.getConnection("msg_aproval");
  PreparedStatement oStmt;
    
  try {
    oStmt = oCon.prepareStatement("UPDATE " + DB.k_newsmsgs + " SET " + DB.id_status + "=" + id_status + " WHERE " + DB.gu_msg + "=?");
    
    oCon.setAutoCommit (false);
    
    for (int i=0;i<a_items.length;i++) {
      oStmt.setString(1, a_items[i]);
      oStmt.executeUpdate();
      
      DBAudit.log(oCon, NewsMessage.ClassId, "CMSG", id_user, a_items[i], null, 0, 0, "id_status=" + id_status, null);
    } // next ()
    
    oStmt.close();
    
    oCon.commit();

    oCon.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon, id_user, "com.knowgate.http.portlets.RecentPostsTab", getCookie(request,"workarea",""));

    oCon.close("msg_aproval");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"msg_aproval");
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.msgslist.document.location.reload(true);<" + "/SCRIPT" +"></HEAD></HTML>"); 
%>
