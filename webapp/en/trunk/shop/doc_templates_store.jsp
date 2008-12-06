<%@ page import="com.knowgate.misc.Environment,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="templates.jspf" %><%
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sIdDomain = request.getParameter("id_domain");
  String sGuWorkArea = request.getParameter("gu_worakrea");
  String sNmFile = request.getParameter("nm_file");
  String sGuShop = request.getParameter("gu_shop");
  String sTxSrc = request.getParameter("source");
  
  String sTemplatePath = getXSLTemplatePath(sStorage, sIdDomain, sGuWorkArea, sGuShop, sNmFile);
  
  FileSystem oFS = new FileSystem();
  
  if (null==sTemplatePath) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFound&desc=" + sStorage + " " + sIdDomain + " " + sGuWorkArea + " file not found" + "&resume=_close"));  
  } else{
    oFS.writefilestr(sTemplatePath,sTxSrc,"UTF-8");  
    response.sendRedirect (response.encodeRedirectUrl ("doc_templates.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  }
%>