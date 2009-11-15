<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>Project Snapshot</TITLE>
  </HEAD>
  <FRAMESET NAME="prjsnapshotframe" ROWS="30,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="prjsnapshotctrl" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE src="prj_snapshot_header.jsp?gu_snapshot=<%=request.getParameter("gu_snapshot")%>">
    <FRAME NAME="prjsnapshotview" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE SRC="prj_snapshot_print.jsp?gu_snapshot=<%=request.getParameter("gu_snapshot")%>">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page uses frames but your browser does not allow them</P>
    </BODY>
  </NOFRAMES>
</HTML>
