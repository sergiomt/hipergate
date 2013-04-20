<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<!-- +-------------------------------------------+ -->
<!-- | Marco principal de listado de alumnos     | -->
<!-- | (c) KnowGate 2006                         | -->
<!-- +-------------------------------------------+ -->  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Students Listing</TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function setURL() {
      if (getURLParam("field")!=null && getURLParam("find")!=null)
        contactslist.location = "../crm/contact_listing.jsp?face=edu&private=<%=nullif(request.getParameter("private"),"0")%>&field=<%=request.getParameter("field")%>&find=<%=request.getParameter("find")%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&screen_width=" + screen.width + "&where=" + escape("<%=nullif(request.getParameter("where"))%>") + "&query=<%=nullif(request.getParameter("gu_query"))%>&orderby=<%=nullif(request.getParameter("orderby"),"0")%>";
      else
        this.frames['contactslist'].document.location = "../crm/contact_listing.jsp?face=edu&private=<%=nullif(request.getParameter("private"),"0")%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&screen_width=" + screen.width + "&where=" + escape("<%=nullif(request.getParameter("where"))%>") + "&query=<%=nullif(request.getParameter("gu_query"))%>&orderby=<%=nullif(request.getParameter("orderby"),"0")%>";
      }
    //-->
    </SCRIPT>    
  </HEAD>
  <FRAMESET NAME="contactsframe" ROWS="*,0" BORDER="0" FRAMEBORDER="0" onLoad="setURL()">
    <FRAME NAME="contactslist" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE src="../common/blank.htm">
    <FRAME NAME="contactsexec" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE SRC="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames, but your web browser does not handle them</P>
    </BODY>
  </NOFRAMES>
</HTML>
