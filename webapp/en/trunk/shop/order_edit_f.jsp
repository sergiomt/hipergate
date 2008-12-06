<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %><%
  String id_domain = nullif(request.getParameter("id_domain"));
  String gu_workarea = nullif(request.getParameter("gu_workarea"));
  String gu_order = nullif(request.getParameter("gu_order"));
  if (gu_order.length()>0) gu_order = "&gu_order="+gu_order;
  String gu_contact = nullif(request.getParameter("gu_contact"));
  if (gu_contact.length()>0) gu_contact = "&gu_contact="+gu_contact;
  String gu_company = nullif(request.getParameter("gu_company"));
  if (gu_company.length()>0) gu_company = "&gu_company="+gu_company;
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<!-- +-------------------------------+ -->
<!-- | Marco de edición de pedidos   | -->
<!-- | (c) KnowGate 2003             | -->
<!-- +-------------------------------+ -->  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Edit Order</TITLE>
  </HEAD>
  <FRAMESET NAME="ordereditframe" ROWS="100%,*">
    <FRAME NAME="orderdata" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" SRC="order_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%><%=gu_order%><%=gu_company%><%=gu_contact%>">
    <FRAME NAME="orderexec" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="16" SRC="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>Esta p&aacute;gina usa marcos, pero su explorador no los admite.</P>
    </BODY>
  </NOFRAMES>
</HTML>
