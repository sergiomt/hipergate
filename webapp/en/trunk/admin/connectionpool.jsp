<%@ page import="java.util.Date,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.misc.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  String sSkin = "xp";
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Connection Pool Inspector</TITLE>
  <META HTTP-EQUIV="Refresh" CONTENT="10; URL=connectionpool.jsp"> 
  <LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css">
</HEAD>

<BODY >
<%@ include file="../common/header.jspf" %>
  <FORM>
    <INPUT CLASS="pushbutton" TYPE="button" onClick="window.location='connectionpool.jsp?closeall';" VALUE="Free All Connections">
  </FORM>
  <FONT FACE="Arial,Helvetica,sans-serif">
  <%
    boolean bCloseAll = (request.getParameter("closeall")!=null);    
    out.write("<B>Connection Pool Inspector</B><BR>");
    out.write(new Date().toString()+"<BR><BR>");
    JDCConnectionPool oConnPool = GlobalDBBind.connectionPool();
    
    if (null==oConnPool)
      out.write("GlobalDBBind.connectionPool() NullPointerException<BR>");
    else {       
      if (bCloseAll)
        oConnPool.closeConnections();
    
      out.write(Gadgets.replace(oConnPool.dumpStatistics(), "\n", "<BR>"));
    }
  %>
  </FONT>
</BODY>
</HTML>
