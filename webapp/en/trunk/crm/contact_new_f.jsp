<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">
<!-- +-------------------------------------------------------------------+ -->
<!-- | Marco de edición combinada de contactos, compañías y direcciones  | -->
<!-- | (c) KnowGate 2003                                                 | -->
<!-- +-------------------------------------------------------------------+ -->
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Edit Contact</TITLE>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT LANGUAGE="javascript" SRC="../javascript/trim.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--                
      function setURL() {
        contacttext.location = "contact_new.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea");
      }
    //-->
    </SCRIPT>
  </HEAD>
  <FRAMESET NAME="contacttop" ROWS="100%,*" BORDER="0" FRAMEBORDER="0" onLoad="setURL()">
    <FRAME NAME="contacttext" FRAMEBORDER="no" MARGINWIDTH="8" MARGINHEIGHT="0" NORESIZE src="../common/blank.htm">
    <FRAME NAME="contactexec" FRAMEBORDER="no" MARGINWIDTH="8 marginheight=" NORESIZE src="../common/blank.htm">
  </FRAMESET>
  <NOFRAMES>
      <BODY>
	<P>This page uses frames, but your browser does not handle them.</P>
      </BODY>
  </NOFRAMES>
</HTML>
