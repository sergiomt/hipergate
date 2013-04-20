<%@ page language="java" import="com.knowgate.misc.Gadgets" session="false" contentType="text/html;charset=UTF-8" %>
<%
  String sQueryStr = "?id_domain=" + request.getParameter("id_domain") + "&gu_workarea=" + request.getParameter("gu_workarea") + "&id_scope=" + request.getParameter("id_scope");

  if (null!=request.getParameter("id_language"))
    sQueryStr += "&id_language=" + request.getParameter("id_language");

  if (null!=request.getParameter("gu_term"))
    sQueryStr += "&gu_term=" + request.getParameter("gu_term");

  if (null!=request.getParameter("id_term"))
    sQueryStr += "&id_term=" + request.getParameter("id_term");

  if (null!=request.getParameter("id_level"))
    sQueryStr += "&id_level=" + request.getParameter("id_level");

  if (null!=request.getParameter("bo_mainterm"))
    sQueryStr += "&bo_mainterm=" + request.getParameter("bo_mainterm");

  if (null!=request.getParameter("nm_control"))
    sQueryStr += "&nm_control=" + request.getParameter("nm_control");

  if (null!=request.getParameter("nm_coding"))
    sQueryStr += "&nm_coding=" + request.getParameter("nm_coding");

  if (null!=request.getParameter("skip"))
    sQueryStr += "&skip=" + request.getParameter("skip");
  else
    sQueryStr += "&skip=0";    
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <TITLE>hipergate :: Edit Thesaurus</TITLE>
  </HEAD>
  <FRAMESET NAME="thesaurif" ROWS="70%,*">
    <FRAME NAME="thesaurilist"  MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="thesauri_listing.jsp<%=sQueryStr%>">
    <FRAME NAME="thesauriedit"  MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="term_edit.jsp<%=sQueryStr%>">
    </FRAMESET>
    <NOFRAMES>
      <BODY>
	<P>This page use frames, but your web browser does not handle them</P>
      </BODY>
    </NOFRAMES>
</HTML>
