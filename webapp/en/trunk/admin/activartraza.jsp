<%@ page import="com.knowgate.debug.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<HTML>
<HEAD>
<TITLE>hipergate :: Enable Trace</TITLE>
</HEAD>
<BODY>
<%
  DebugFile.trace = true;
  out.write("Trace mode activated");
%>
</BODY>
</HTML>