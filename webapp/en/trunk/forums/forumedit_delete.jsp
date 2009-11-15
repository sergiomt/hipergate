<%@ page import="com.knowgate.forums.NewsGroup,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
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

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ",");
    
  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("forum_delete");
    oCon.setAutoCommit (false);

    for (int i=0;i<a_items.length;i++) {
      NewsGroup.delete(oCon, a_items[i]);
      DBAudit.log(oCon, NewsGroup.ClassId, "DNGR", id_user, a_items[i], null, 0, 0, null, null);
    } // next ()
    oCon.commit();

    oCon.setAutoCommit (true);

    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon, id_user, "com.knowgate.http.portlets.RecentPostsTab", getCookie(request,"workarea",""));
    
    oCon.close("forum_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"forum_delete");
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>top.document.location.reload();window.location='../blank.htm';<" + "/SCRIPT" +"></HEAD></HTML>"); 
%>