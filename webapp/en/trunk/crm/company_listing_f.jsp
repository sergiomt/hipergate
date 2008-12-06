<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
 <HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Company Listing</TITLE>
    <SCRIPT language="JavaScript">
      function setURL() {
        this.frames["companieslist"].document.location = "company_listing.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&screen_width=" + screen.width + "&field=<%=nullif(request.getParameter("field"),"")%>&find=<%=com.knowgate.misc.Gadgets.URLEncode(nullif(request.getParameter("find"),""))%>&where=<%=com.knowgate.misc.Gadgets.URLEncode(nullif(request.getParameter("where"),""))%>&query=<%=com.knowgate.misc.Gadgets.URLEncode(nullif(request.getParameter("gu_query"),""))%>&orderby=<%=com.knowgate.misc.Gadgets.URLEncode(nullif(request.getParameter("orderby"),"0"))%>";
      }
    </SCRIPT>
  </HEAD>
  <FRAMESET NAME="companiesframe" ROWS="*,0" BORDER="0" FRAMEBORDER="0" onLoad="setURL()">
    <FRAME NAME="companieslist" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE SCROLLING="auto" src="../common/blank.htm">
    <FRAME NAME="companiesexec" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE SRC="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames, but your web browser does not handle them</P>
    </BODY>
  </NOFRAMES>
</HTML>
