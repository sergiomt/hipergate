<%@ page import="com.knowgate.misc.Environment,com.knowgate.datacopy.FullTableCopy" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<% 

  String sOrigin = request.getParameter("con_origin");
  String sTarget = request.getParameter("con_target");
  
  FullTableCopy oCopy = new FullTableCopy();
    
  try {
    oCopy.connectOrigin(Environment.getProfileVar(sOrigin, "driver"),Environment.getProfileVar(sOrigin, "dburl"), Environment.getProfileVar(sOrigin, "dbuser"), Environment.getProfileVar(sOrigin, "dbpassword"),Environment.getProfileVar(sOrigin, "schema"));
    oCopy.connectTarget(Environment.getProfileVar(sTarget, "driver"),Environment.getProfileVar(sTarget, "dburl"), Environment.getProfileVar(sTarget, "dbuser"), Environment.getProfileVar(sTarget, "dbpassword"),Environment.getProfileVar(sTarget, "schema"));
    oCopy.setAutoCommit(true);
    oCopy.insert(request.getParameter("tbl_origin"), request.getParameter("tbl_target"), false);
    oCopy.disconnectAll();
  }
  catch (Exception e) {
    try { oCopy.disconnectAll(); } catch (Exception ignore) { }
    oCopy = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }  
  if (null==oCopy) return;    
  oCopy = null;
%>
<HTML>
  <HEAD>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  </HEAD>
  <BODY>
    <BR>
    Command sucessfully executed
  </BODY>
</HTML>