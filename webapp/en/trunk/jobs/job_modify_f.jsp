<%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<!-- +--------------------------------+ -->
<!-- | Edición de propiedades del Job | -->
<!-- | (c) KnowGate 2003              | -->
<!-- +--------------------------------+ -->  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Edit Task</TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/getparam.js"></SCRIPT>
  </HEAD>
  <FRAMESET NAME="jobmodifyframe" ROWS="*,100px" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="jobmodify" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE SRC="job_modify.jsp?gu_job=<%=request.getParameter("gu_job")%>">
    <FRAME NAME="jobprogress" FRAMEBORDER="no" MARGINWIDTH="16 MARGINHEIGHT="0" NORESIZE SRC="job_progress.jsp?gu_job=<%=request.getParameter("gu_job")%>">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames, but your web browser does not handle them</P>
    </BODY>
  </NOFRAMES>
</HTML>
