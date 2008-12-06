<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>Invoice</TITLE>
  </HEAD>
  <FRAMESET NAME="invoiceframe" ROWS="30,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="invoicectrl" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE src="invoice_print_header.jsp?gu_invoice=<%=request.getParameter("gu_invoice")%>">
    <FRAME NAME="invoiceview" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE SRC="invoice_print.jsp?gu_invoice=<%=request.getParameter("gu_invoice")%>">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames, but your web browser does not handle them</P>
    </BODY>
  </NOFRAMES>
</HTML>
