<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Add Attendant</TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/getparam.js"></SCRIPT>
  </HEAD>
  <FRAMESET NAME="msgsframe" ROWS="*,1">
    <FRAME NAME="msgslist" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" SRC="audience_new.jsp?id_domain=<%=request.getParameter("id_domain")%>&gu_workarea=<%=request.getParameter("gu_workarea")%>&gu_activity=<%=request.getParameter("gu_activity")%>">
    <FRAME NAME="msgsexec" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="2" SRC="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page uses frames but your browser does not support them</P>
    </BODY>
  </NOFRAMES>
</HTML>
