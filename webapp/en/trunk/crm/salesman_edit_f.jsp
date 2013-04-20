<%@ page import="com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Edit Sales Objectives</TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/getparam.js"></SCRIPT>
  </HEAD>
  <FRAMESET NAME="usrtop" ROWS="80,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="topnavigation" FRAMEBORDER="no" MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="salesman_edit_top.jsp?gu_sales_man=<% out.write (request.getParameter("gu_sales_man")); %>&n_sales_man=<% out.write (Gadgets.URLEncode(request.getParameter("n_sales_man"))); %>">
    <FRAME NAME="yearobjectives" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE>
  </FRAMESET>
    <NOFRAMES>
      <BODY>
	<P>This page contains frames, but you browser does not support them.</P>
      </BODY>
    </NOFRAMES>
</HTML>