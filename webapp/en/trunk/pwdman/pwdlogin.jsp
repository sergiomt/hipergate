<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.*" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_user = getCookie(request, "userid", "");

  JDCConnection oConn = null;  
  boolean bLogin = false;
  
  try {
    oConn = GlobalDBBind.getConnection("pwdlogin");
    
	  bLogin = ACLUser.checkSignature(oConn, gu_user, request.getParameter("pwd1"));

    oConn.close("pwdlogin");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("pwdlogin");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=pwdmanhome.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (bLogin) {
		session.setAttribute("validated", new Boolean(true));
    response.sendRedirect (response.encodeRedirectUrl ("pwdmanhome.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  } else {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=[~Clave invalida~]&desc=[~La clave de firma introducida no es correcta~]&resume=pwdmanhome.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  }
%>