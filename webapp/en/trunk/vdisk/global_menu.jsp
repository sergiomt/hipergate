<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<HTML>
<HEAD>
  <TITLE>hipergate :: Menu</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4">
<% try { %>
  <%@ include file="../common/tabmenu.jspf" %>
<% } catch (NumberFormatException nfe) {
     out.write(nfe.getMessage());
   }
%>
</BODY>
</HTML>