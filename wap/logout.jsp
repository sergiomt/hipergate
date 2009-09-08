<%@ page language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%

session.removeAttribute("user");

response.sendRedirect (response.encodeRedirectUrl ("index.jsp"));

%>