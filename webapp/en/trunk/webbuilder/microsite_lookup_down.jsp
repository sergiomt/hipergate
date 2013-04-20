<%@ page language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<% boolean bIsGuest = isDomainGuest (GlobalDBBind, request, response); %>
<HTML>
  <HEAD>
    <TITLE>hipergate ::</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');                  
      //-->
    </SCRIPT>  
  </HEAD>
  <BODY >
    <FORM>
    <CENTER>
<% if (bIsGuest) { %>
      <INPUT TYPE="button" CLASS="pushbutton" VALUE="Next >>" onClick="alert('Your current priviledges level as Guest does not allow you to perform this action')">
<% } else { %>
      <INPUT TYPE="button" CLASS="pushbutton" VALUE="Next >>" onClick="window.parent.frames[1].choose()">
<% } %>
      &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" onClick="if (window.parent) if (window.parent.opener) window.parent.close(); else document.location = '../common/blank.htm'; else document.location = '../common/blank.htm';">
    </CENTER>
    </FORM>
  </BODY>
</HTML>