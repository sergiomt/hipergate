<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %><%
  String sLocation = "../blank.htm";
  
  if (null!=request.getParameter("gu_phonecall") && null!=request.getParameter("gu_workarea")) {
    sLocation = "phonecall_edit.jsp?gu_workarea=" + request.getParameter("gu_workarea") + "&gu_phonecall=" + request.getParameter("gu_phonecall");  
  } else if (null==request.getParameter("gu_contact") && null==request.getParameter("gu_fellow")) {
    sLocation = "phonecall_edit.jsp?gu_workarea=" + request.getParameter("gu_workarea") + "&gu_bug=" + nullif(request.getParameter("gu_bug"));  
  } else if (null!=request.getParameter("gu_contact")) {
    sLocation = "phonecall_edit.jsp?gu_workarea=" + request.getParameter("gu_workarea") + "&gu_contact=" + request.getParameter("gu_contact") + "&gu_bug=" + nullif(request.getParameter("gu_bug"));        
  } else if (null!=request.getParameter("gu_fellow")) {
    sLocation = "phonecall_edit.jsp?gu_workarea=" + request.getParameter("gu_workarea") + "&gu_fellow=" + request.getParameter("gu_fellow") + "&gu_bug=" + nullif(request.getParameter("gu_bug"));          
  }
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<!-- +----------------------------------------------------+ -->
<!-- | Marco principal de edición de llamadas telefónicas | -->
<!-- | (c) KnowGate 2004                                  | -->
<!-- +----------------------------------------------------+ -->
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: New Phone Call</TITLE>
  </HEAD>
  <FRAMESET NAME="phonecalltop" ROWS="100%,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="phonecalltext" FRAMEBORDER="no" MARGINWIDTH="8" MARGINHEIGHT="0" SRC="<%=sLocation%>" NORESIZE>
    <FRAME NAME="phonecallexec" FRAMEBORDER="no" MARGINWIDTH="8 marginheight=" NORESIZE>
  </FRAMESET>
  <NOFRAMES>
      <BODY>
	<P>This page use frames, but your web browser does not handle them</P>
      </BODY>
  </NOFRAMES>
</HTML>
