<%@ page language="java" import="com.knowgate.misc.Gadgets" session="false" contentType="text/html;charset=UTF-8" %>
<%
  String sQueryStr = "";
  
  if (request.getParameter("linktable")!=null)
    sQueryStr += "&linktable=" + request.getParameter("linktable");

  if (request.getParameter("linkfield")!=null)
    sQueryStr += "&linkfield=" + request.getParameter("linkfield");

  if (request.getParameter("linkvalue")!=null)
    sQueryStr += "&linkvalue=" + request.getParameter("linkvalue");
        
  if (request.getParameter("gu_address")!=null)
    sQueryStr += "&gu_address=" + request.getParameter("gu_address");

  if (request.getParameter("nm_company")!=null)
    sQueryStr += "&nm_company=" + Gadgets.URLEncode(request.getParameter("nm_company"));    

  if (request.getParameter("noreload")!=null)
    sQueryStr += "&noreload=" + request.getParameter("noreload");
  else
    sQueryStr += "&noreload=0";

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <TITLE>hipergate :: [~Editar Direcci&oacute;n~]</TITLE>
  </HEAD>
  <FRAMESET NAME="editaddrf" ROWS="100%,*" BORDER="0" FRAMEBORDER="0">
    <FRAME NAME="editaddr" FRAMEBORDER="no" MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="addr_edit.jsp?void=0<%=sQueryStr%>">
    <FRAME NAME="liststates" FRAMEBORDER="no" MARGINWIDTH="0" MARGINHEIGHT="0" NORESIZE SRC="blank.htm">
    </FRAMESET>
    <NOFRAMES>
      <BODY>
	<P>[~Esta p&aacute;gina usa marcos, pero su explorador no los admite.~]</P>
      </BODY>
    </NOFRAMES>
  </FRAMESET>
</HTML>
