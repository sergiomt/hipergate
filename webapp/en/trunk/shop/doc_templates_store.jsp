<%@ page import="java.io.File,com.knowgate.misc.Environment,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="templates.jspf" %><%
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sIdDomain = request.getParameter("id_domain");
  String sGuWorkArea = request.getParameter("gu_workarea");
  String sNmFile = request.getParameter("nm_file");
  String sGuShop = request.getParameter("gu_shop");
  String sTxSrc = request.getParameter("source");
  String sSep = java.io.File.separator;

  String sTemplatePath = sStorage+"domains"+sSep+sIdDomain+sSep+"workareas"+sSep+sGuWorkArea+sSep+"apps"+sSep+"Shop"+sSep+sGuShop+sSep+"templates"+sSep+sNmFile;
  
  FileSystem oFS = new FileSystem();
    
  oFS.writefilestr(sTemplatePath,sTxSrc,"UTF-8");
  
  response.sendRedirect (response.encodeRedirectUrl ("doc_templates.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
%>