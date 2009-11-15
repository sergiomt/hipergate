<%@ page import="java.util.Map,java.util.Iterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.ContactLoader" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<%
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
      
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  Map oParamMap = request.getParameterMap();
  JDCConnection oConn = null;
  ContactLoader oLoad = null;
  
  try {
    oConn = GlobalDBBind.getConnection("visit_edit3"); 
  
    oConn.setAutoCommit (false);

    oLoad = new ContactLoader(oConn);
    oLoad.putAll(oParamMap);
    oLoad.store(oConn, gu_workarea, ContactLoader.MODE_APPENDUPDATE|ContactLoader.WRITE_COMPANIES|ContactLoader.WRITE_CONTACTS|ContactLoader.WRITE_ADDRESSES);
    oLoad.close();
    oLoad=null;
    
    oConn.commit();
    oConn.close("visit_edit3");
  }
  catch (NullPointerException e) {
    if (oLoad!=null) { try { oLoad.close(); } catch (Exception ignore) {} }
    disposeConnection(oConn,"visit_edit3");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;  
  oConn = null;
%>
<HTML>
  <BODY onload="document.forms[0].submit()">
    <FORM METHOD="post" ACTION="meeting_edit_store.jsp">
<%  Iterator oIter = oParamMap.keySet().iterator();
    Object oParamName;
    while (oIter.hasNext()) {
      oParamName = oIter.next();
      out.write("    <INPUT TYPE=\"hidden\" NAME=\""+oParamName+"\" VALUE=\""+request.getParameter((String)oParamName)+"\">\n");
    }
%>
    </FORM>
  </BODY>
</HTML>