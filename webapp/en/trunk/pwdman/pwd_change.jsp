<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACL,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_user = getCookie (request, "userid", "anonymous");

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("pwd_change");
    
    String sCurrentPwd = DBCommand.queryStr(oConn, "SELECT "+DB.tx_pwd+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+id_user+"'");

		if (!sCurrentPwd.equals(request.getParameter("tx_pwd_old"))) {
		  throw new SecurityException("The new password does not match the previous one");
		}

    oConn.setAutoCommit(true);
    
    ACLUser.resetPassword(oConn, id_user, request.getParameter("tx_pwd_new1"));
          
    oConn.close("pwd_change");

    GlobalCacheClient.expire ("["+id_user+",authstr]");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("pwd_change");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

%>
<HTML>
  <HEAD>
    <TITLE>Wait...</TITLE>
    <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
    <META HTTP-EQUIV="Pragma" CONTENT="no-cache"> 
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
    <!--
      function redirect() {
        setCookie ("authstr","<%=ACL.encript(request.getParameter("tx_pwd_new1"),ENCRYPT_ALGORITHM)%>");
        document.location = "pwdmanhome.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>";
      }      
    // -->
    </SCRIPT>
  </HEAD>
  <BODY onLoad="redirect()"></BODY>
</HTML>