<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.*" language="java" session="true" %><%@ include file="inc/dbbind.jsp" %><% 

  String tx_pwd_sign = request.getParameter("tx_pwd_sign");

  boolean bLogin = false;
  
  try {
    oConn = GlobalDBBind.getConnection("pwdlogin");
    
	  bLogin = ACLUser.checkSignature(oConn, oUser.getString(DB.gu_user), tx_pwd_sign);

    oConn.close("pwdlogin");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("pwdlogin");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=home.jsp"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (bLogin) {
		session.setAttribute("validated", new Boolean(true));
		session.setAttribute("signature", tx_pwd_sign);
    response.sendRedirect (response.encodeRedirectUrl ("passwords.jsp"));
  } else {
		session.removeAttribute("validated");
		session.removeAttribute("signature");
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+Labels.getString("lbl_invalid_password")+"&desc="+Labels.getString("lbl_invalid_password")+"&resume=passwords.jsp"));
  }
%>