<%@ page language="java" contentType="text/plain;charset=UTF-8" %>

<%
  final String sSep = System.getProperty("file.separator");
  String sWWWRoot 	= request.getRealPath(request.getServletPath());
  sWWWRoot = sWWWRoot.substring(0,sWWWRoot.lastIndexOf(sSep)) + sSep + "..";

out.write(sWWWRoot);

%>