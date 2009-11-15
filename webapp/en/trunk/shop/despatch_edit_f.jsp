<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/nullif.jspf" %><%
  String id_domain = nullif(request.getParameter("id_domain"));
  String gu_workarea = nullif(request.getParameter("gu_workarea"));
  String gu_despatch = nullif(request.getParameter("gu_despatch"));
  if (gu_despatch.length()>0) gu_despatch = "&gu_despatch="+gu_despatch;
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<!-- +-------------------------------+ -->
<!-- | Marco de edición de albaranes | -->
<!-- | (c) KnowGate 2005             | -->
<!-- +-------------------------------+ -->  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Despach Advice Edition</TITLE>
  </HEAD>
  <FRAMESET NAME="ordereditframe" ROWS="100%,*">
    <FRAME NAME="orderdata" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" SRC="despatch_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%><%=gu_despatch%>">
    <FRAME NAME="orderexec" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="16" SRC="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>Esta p&aacute;gina usa marcos, pero su explorador no los admite.</P>
    </BODY>
  </NOFRAMES>
</HTML>