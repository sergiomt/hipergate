<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
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
      
  String gu_workarea = getCookie(request, "workarea", null);
  String id_user = getCookie (request, "userid", null);
  
  String gu_query = request.getParameter("gu_query");

  String sCaller = nullif(request.getParameter("caller"),"");
    
  JDCConnection oConn = GlobalDBBind.getConnection("qbf_store");  
  PreparedStatement oStmt;
  
  try {
    oConn.setAutoCommit (false);
    if (gu_query.length()>0) {
      oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_queries + " WHERE " + DB.gu_query + "=?");
      oStmt.setString(1,gu_query);
      oStmt.execute();
      oStmt.close();
    }

    if (gu_query.length()==0)
      gu_query = Gadgets.generateUUID();
      
    oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_queries + "(" + DB.gu_query + "," + DB.gu_workarea + "," + DB.tl_query + "," + DB.nm_queryspec + "," + DB.dt_modified + ",nm_field1,nm_field2,nm_field3,nm_operator1,nm_operator2,nm_operator3,tx_value1,tx_value2,tx_value3,vl_code1,vl_code2,vl_code3,tx_condition1,tx_condition2) VALUES (?,?,?,?," + DBBind.Functions.GETDATE + ",?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oStmt.setString( 1, gu_query);
    oStmt.setString( 2, gu_workarea);
    oStmt.setString( 3, request.getParameter("tl_query"));
    oStmt.setString( 4, request.getParameter("queryspec"));
    oStmt.setString( 5, nullif(request.getParameter("field1")).length()==0 ? null : request.getParameter("field1"));
    oStmt.setString( 6, nullif(request.getParameter("field2")).length()==0 ? null : request.getParameter("field2"));
    oStmt.setString( 7, nullif(request.getParameter("field3")).length()==0 ? null : request.getParameter("field3"));
    oStmt.setString( 8, nullif(request.getParameter("operator1")).length()==0 ? null : request.getParameter("operator1"));
    oStmt.setString( 9, nullif(request.getParameter("operator2")).length()==0 ? null : request.getParameter("operator2"));
    oStmt.setString(10, nullif(request.getParameter("operator3")).length()==0 ? null : request.getParameter("operator3"));
    oStmt.setString(11, nullif(request.getParameter("value1")).length()==0 ? null : request.getParameter("value1"));
    oStmt.setString(12, nullif(request.getParameter("value2")).length()==0 ? null : request.getParameter("value2"));
    oStmt.setString(13, nullif(request.getParameter("value3")).length()==0 ? null : request.getParameter("value3"));
    oStmt.setString(14, nullif(request.getParameter("code1")).length()==0 ? null : request.getParameter("code1"));
    oStmt.setString(15, nullif(request.getParameter("code2")).length()==0 ? null : request.getParameter("code2"));
    oStmt.setString(16, nullif(request.getParameter("code3")).length()==0 ? null : request.getParameter("code3"));
    oStmt.setString(17, nullif(request.getParameter("condition1")).length()==0 ? null : request.getParameter("condition1"));
    oStmt.setString(18, nullif(request.getParameter("condition2")).length()==0 ? null : request.getParameter("condition2"));
    oStmt.execute();
    oStmt.close();
    
    DBAudit.log(oConn, (short)12, "MQBF", id_user, gu_query, gu_workarea, 0, 0, request.getParameter("tl_query"), request.getParameter("queryspec"));
    
    oConn.commit();
    oConn.close("qbf_store");
    
    GlobalCacheClient.expire("k_queries.contacts"  + "[" + gu_workarea + "]");
    GlobalCacheClient.expire("k_queries.companies" + "[" + gu_workarea + "]");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"qbf_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;
  
  // Refrescar el padre y cerrar la ventana
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.location='qbf.jsp?queryspec=" + request.getParameter("queryspec") + "&queryid=" + gu_query + "';");
  if (sCaller.equals("list_wizard_02.jsp"))
   out.write ("window.opener.location.reload();self.close();");
  out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");

%>