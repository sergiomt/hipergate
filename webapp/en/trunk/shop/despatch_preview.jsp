<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>Despatch Advice</TITLE>
  </HEAD>
  <FRAMESET NAME="despatchframe" ROWS="30,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="despatchctrl" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE src="despatch_print_header.jsp?gu_despatch=<%=request.getParameter("gu_despatch")%>">
    <FRAME NAME="despatchview" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE SRC="despatch_print.jsp?gu_despatch=<%=request.getParameter("gu_despatch")%>">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames, but your web browser does not handle them</P>
    </BODY>
  </NOFRAMES>
</HTML>
