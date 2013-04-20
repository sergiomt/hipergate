<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Company Lookup</TITLE>
  </HEAD>
  <FRAMESET NAME="companieslookp" ROWS="90,*" BORDER="0">
    <FRAME NAME="companiesbrowse" MARGINWIDTH="0" MARGINHEIGHT="0" SRC="company_lookup_top.htm?id_section=<%=nullif(request.getParameter("id_section")%>&nm_assigned=<%=nullif(request.getParameter("nm_assigned")%>&nm_control=<%=nullif(request.getParameter("nm_control")%>&nm_coding=<%=nullif(request.getParameter("nm_coding")%>">
    <FRAME NAME="companieslist" MARGINWIDTH="0" MARGINHEIGHT="0" SRC="../blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
	  <P>This page contains frames, but your browser doesn't support them</P>
    </BODY>
  </NOFRAMES>
</HTML>