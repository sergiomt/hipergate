<%@ page import="com.knowgate.dataobjs.DBException,com.knowgate.hequel.HEQUELInterpreter" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalHEQUEL" scope="application" class="com.knowgate.hequel.HEQUELInterpreter"/>
<HTML>
  <HEAD>
    <TITLE>hipergate ::</TITLE>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>  
  </HEAD>
  <BODY  LEFTMARGIN="4" TOPMARGIN="4" MARGINWIDTH="4" MARGINHEIGHT="4">
<%
    GlobalHEQUEL.interpret(request.getParameter("cmdline"));
    out.write("    " + GlobalHEQUEL.getReturnMessage());
%>
  </BODY>
</HTML>