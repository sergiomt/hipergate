<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.acl.PasswordRecordTemplate,com.knowgate.acl.PasswordRecordLine" language="java" session="true" contentType="text/html;charset=UTF-8" %>
<%@ include file="../../methods/dbbind.jsp" %><%@ include file="../../methods/cookies.jspf" %><%@ include file="../../methods/authusrs.jspf" %><%

	if (session.getAttribute("validated")==null) {
	  response.sendRedirect (response.encodeRedirectUrl ("../../common/errmsg.jsp?title=[~Session Expired~]&desc=[~Session has expired. Please log in again~]&resume=_close"));
    return;	
	} else if (!((Boolean) session.getAttribute("validated")).booleanValue()) {
	  response.sendRedirect (response.encodeRedirectUrl ("../../common/errmsg.jsp?title=[~Session Expired~]&desc=[~Session has expired. Please log in again~]&resume=_close"));
    return;	
	}

  short iStatus = autenticateCookie(GlobalDBBind, request, response);
    
  if (iStatus>=0) iStatus = verifyUserAccessRights(GlobalDBBind, request, response);

  if (iStatus<(short)0) {
	  response.sendRedirect (response.encodeRedirectUrl ("../../common/errmsg.jsp?title=SecurityException&desc="+ACL.getErrorMessage(iStatus)+"&resume=_close"));
    return;
  }

  PasswordRecord oRec = new PasswordRecord((String) session.getAttribute("signature"));

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("hotmail_login");  
  
    oRec.load(oConn,request.getParameter("gu_pwd"));

    oConn.close("hotmail_login");

  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("hotmail_login");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_close"));
  }

  response.sendRedirect (response.encodeRedirectUrl ("http://www.hotmail.com"));
%>
