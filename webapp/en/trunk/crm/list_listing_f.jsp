<%@ include file="../methods/nullif.jspf" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<!-- +----------------------------+ -->
<!-- | Marco principal de listas  | -->
<!-- | (c) KnowGate 2003-2010     | -->
<!-- +----------------------------+ -->  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Distribution Lists</TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function setURL() {
        listslist.location = "list_listing.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + screen.width + "&where=" + escape("<%=nullif(request.getParameter("where"))%>");
      }
    //-->
    </SCRIPT>    
  </HEAD>
  <FRAMESET NAME="listsframe" ROWS="*,0" BORDER="0" FRAMEBORDER="0" onLoad="setURL()">
    <FRAME NAME="listslist" FRAMEBORDER="no" MARGINWIDTH="16" MARGINHEIGHT="0" NORESIZE SRC="../common/blank.htm">
    <FRAME NAME="listsexec" FRAMEBORDER="no" MARGINWIDTH="0 marginheight=" NORESIZE SRC="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
    <BODY>
      <P>This page use frames, but your web browser does not handle them</P>
    </BODY>
  </NOFRAMES>
</HTML>
