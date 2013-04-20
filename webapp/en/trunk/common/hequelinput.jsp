<%@ page import="java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<HTML>
  <HEAD>
    <TITLE>hipergate ::</TITLE>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>  
  </HEAD>
  <BODY  LEFTMARGIN="8" TOPMARGIN="8">
    <FORM name="hequelform" METHOD="POST" ACTION="hequelexec.jsp" TARGET="hequelresults">
      <TEXTAREA name="cmdline" ROWS="16" COLS="80"></TEXTAREA>
      <BR>
      <INPUT TYPE="submit" VALUE="Execute">
    </FORM>
  </BODY>
</HTML>