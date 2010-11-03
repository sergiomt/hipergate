<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Preview</TITLE>
  </HEAD>
  <FRAMESET ROWS="28,*" BORDER="0">
    <FRAME MARGINWIDTH="0" MARGINHEIGHT="0" SRC="adhoc_mailing_nav.htm">
    <FRAME MARGINWIDTH="0" MARGINHEIGHT="0" SRC="adhoc_mailing_preview.jsp?gu_workarea=<%=request.getParameter("gu_workarea")%>&gu_mailing=<%=request.getParameter("gu_mailing")%>">
    </FRAMESET>
    <NOFRAMES>
      <BODY>
	      <P>This page use frames but your browser does nit support them</P>
      </BODY>
    </NOFRAMES>
  </FRAMESET>
</HTML>