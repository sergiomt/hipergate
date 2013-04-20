<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<!-- +--------------------------------+ -->
<!-- | Edición de propiedades del Job | -->
<!-- | (c) KnowGate 2003-2009         | -->
<!-- +--------------------------------+ -->  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Edit Task</TITLE>
  </HEAD>
  <FRAMESET NAME="jobmodifyframe" ROWS="280px,70px">
    <FRAME NAME="jobmodify" SRC="job_modify.jsp?gu_job=<%=request.getParameter("gu_job")%>">
    <FRAME NAME="jobprogress" SRC="job_progress.jsp?gu_job=<%=request.getParameter("gu_job")%>">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames, but your web browser does not handle them</P>
    </BODY>
  </NOFRAMES>
</HTML>
