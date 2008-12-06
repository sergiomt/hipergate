<%@ page import="com.knowgate.misc.Environment,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="templates.jspf" %><%
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sIdDomain = getCookie(request,"domainid","");
  String sGuWorkArea = getCookie(request,"workarea","");
  String sNmFile = request.getParameter("nm_file");
  String sGuShop = request.getParameter("gu_shop");
  
  String sTemplatePath = getXSLTemplatePath(sStorage, sIdDomain, sGuWorkArea,sGuShop, sNmFile);
  
  FileSystem oFS = new FileSystem();
  
  if (null==sTemplatePath)
    out.write(sStorage + " " + sIdDomain + " " + sGuWorkArea + " file not found");
  else
    out.write(oFS.readfilestr(sTemplatePath,"UTF-8"));
%>