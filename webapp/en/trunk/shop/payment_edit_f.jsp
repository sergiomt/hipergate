<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: <%= request.getParameter("gu_invoice")==null ? "Create Payment" : "Edit Payment"%></TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" DEFER="true">
    <!--
      function goURL() {
        this.frames['msgslist'].document.location = "payment_edit.jsp?id_domain=<%=request.getParameter("id_domain")%>&gu_workarea=<%=request.getParameter("gu_workarea")%><%=request.getParameter("gu_invoice")==null ? "" : "&gu_invoice="+request.getParameter("gu_invoice")%><%=request.getParameter("pg_payment")==null ? "" : "&pg_payment="+request.getParameter("pg_payment")%>";
      }
    //-->
    </SCRIPT>    
  </HEAD>
  <FRAMESET NAME="msgsframe" ROWS="*,1" onLoad="goURL()">
    <FRAME NAME="msgslist" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" >
    <FRAME NAME="msgsexec" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="2" SRC="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames but your browser does nit support them</P>
    </BODY>
  </NOFRAMES>
</HTML>
