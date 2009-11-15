<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.*" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  session.removeAttribute("validated");
  session.removeAttribute("signature");
  response.sendRedirect (response.encodeRedirectUrl ("pwdmanhome.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
%>