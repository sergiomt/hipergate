<%@ page language="java" import="com.knowgate.misc.Gadgets" session="false" contentType="text/html;charset=UTF-8" %>
<%
  String sQueryStr = "";
  
  if (request.getParameter("id_class")!=null)
    sQueryStr += "&id_class=" + request.getParameter("id_class");
        
  if (request.getParameter("gu_sale_point")!=null)
    sQueryStr += "&gu_sale_point=" + request.getParameter("gu_sale_point");

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <TITLE>hipergate :: Edit Address</TITLE>
  </HEAD>
  <FRAMESET NAME="editsalepointf" ROWS="100%,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="editsalepoint" FRAMEBORDER="no" MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="salepoint_edit.jsp?void=0<%=sQueryStr%>">
    <FRAME NAME="liststates" FRAMEBORDER="no" MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="blank.htm">
    </FRAMESET>
    <NOFRAMES>
      <BODY>
	      <P>This page has frames but your browser does not support them</P>
      </BODY>
    </NOFRAMES>
  </FRAMESET>
</HTML>
