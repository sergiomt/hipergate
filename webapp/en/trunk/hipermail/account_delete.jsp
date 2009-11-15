<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.hipermail.MailAccount" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 

  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_account = request.getParameter("gu_account");
  String id_user = getCookie (request, "userid", null);

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("account_delete");
    
    oConn.setAutoCommit(false);
    
    new MailAccount(oConn, gu_account).delete(oConn);

    oConn.commit();
      
    oConn.close("account_delete");
  }
  catch (Exception e) {  
    disposeConnection(oConn,"account_delete");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("account_list.jsp"));
%>