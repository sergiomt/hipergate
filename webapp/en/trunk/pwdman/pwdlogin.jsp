<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.*" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_user = getCookie(request, "userid", "");
  String tx_pwd_sign = request.getParameter("pwd1");

  JDCConnection oConn = null;  
  boolean bLogin = false;
  
  try {
    oConn = GlobalDBBind.getConnection("pwdlogin");
    
	  bLogin = ACLUser.checkSignature(oConn, gu_user, tx_pwd_sign);

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
		session.setAttribute("signature", tx_pwd_sign);
    response.sendRedirect (response.encodeRedirectUrl ("pwdmanhome.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  } else {
		session.removeAttribute("validated");
		session.removeAttribute("signature");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Invalid password&desc=Signature password is incorrect&resume=pwdmanhome.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")));
  }
%>