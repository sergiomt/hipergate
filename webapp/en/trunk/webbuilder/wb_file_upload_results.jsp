<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%
if (null!=request.getParameter("response"))
  out.write (request.getParameter("response"));
else
	out.write ("<html><body onload='top.close()'></html>");
%>