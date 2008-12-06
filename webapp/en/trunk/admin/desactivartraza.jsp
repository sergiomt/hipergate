<%@ page import="com.knowgate.debug.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<HTML>
<HEAD>
<TITLE>hipergate :: Disable Trace</TITLE>
</HEAD>
<BODY>
<%
  DebugFile.trace = false;
  out.write("Trace mode deactivated");
%>
</BODY>
</HTML>