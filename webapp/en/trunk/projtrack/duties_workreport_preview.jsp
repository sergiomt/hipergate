<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>Work Report</TITLE>
  </HEAD>
  <FRAMESET NAME="workreportframe" ROWS="30,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="workreportctrl" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE src="duties_workreport_header.jsp?gu_workreport=<%=request.getParameter("gu_workreport")%>">
    <FRAME NAME="workreportview" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE SRC="duties_workreport_print.jsp?gu_workreport=<%=request.getParameter("gu_workreport")%>">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page uses frames but your browser does not allow them</P>
    </BODY>
  </NOFRAMES>
</HTML>
