<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.projtrack.Bug" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sLuceneIndex = Environment.getProfileVar("luceneindex","");  
  String[] aBugs = Gadgets.split(request.getParameter("checkeditems"),',');      
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  String sSet = " "+DB.dt_modified+"="+DBBind.Functions.GETDATE; 
  String sAttr;
  
  sAttr = request.getParameter("sel_new_status");
  if (sAttr.length()>0) {
    sSet += ","+DB.tx_status+"='"+sAttr+"'";
    if (sAttr.equals("CORREGIDO"))
      sSet += ","+DB.dt_closed+"="+DBBind.Functions.GETDATE;
  }
  sAttr = request.getParameter("sel_new_priority");
  if (sAttr.length()>0) {
    sSet += ","+DB.od_priority+"="+sAttr;
  }
  sAttr = request.getParameter("sel_new_severity");
  if (sAttr.length()>0) {
    sSet += ","+DB.od_severity+"="+sAttr;
  }
  sAttr = request.getParameter("nm_assigned");
  if (sAttr.length()>0) {
    sSet += ","+DB.nm_assigned+"='"+sAttr.replace((char)39,(char)32)+"'";
  }
    
  try {
    oConn = GlobalDBBind.getConnection("bugedit_update"); 
  
    oStmt = oConn.prepareStatement("UPDATE "+DB.k_bugs+" SET "+sSet+" WHERE "+DB.gu_bug+"=?");

    oConn.setAutoCommit (false);

    for (int b=aBugs.length-1; b>=0; b--) {
      oStmt.setString(1, aBugs[b]);
      oStmt.executeUpdate();
      if (null!=sLuceneIndex) {
        if (sLuceneIndex.length()>0) {
          new Bug(oConn, aBugs[b]).reIndex(oConn, GlobalDBBind.getProperties());
        } // fi
      }
    } // next
    
    oStmt.close();
    
    com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, getCookie (request, "userid", null), "com.knowgate.http.portlets.MyIncidencesTab", getCookie(request,"workarea",""));
    
    oConn.commit();
    
    oConn.close("bugedit_update");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"bugedit_update");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;  
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("bug_list.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));

%>