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
    oConn = GlobalDBBind.getConnection("gmail_login");  
  
    oRec.load(oConn,request.getParameter("gu_pwd"));

    oConn.close("gmail_login");

  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("gmail_login");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_close"));
  }
%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="content-type" CONTENT="text/html; charset=UTF-8">
  <META NAME="robots" CONTENT="noindex,nofollow">
  <TITLE>hipergate : GMail Autologin Form</TITLE>
  <SCRIPT TYPE="text/javascript">
    function postGaia() {
    	var frm = document.forms[0];
      frm.Email.value="<%=oRec.getValueOf("user")%>";
      frm.Passwd.value="<%=oRec.getValueOf("pwd")%>";
			frm.submit();
    }
  </SCRIPT>
</HEAD>
<BODY onLoad="postGaia()">
  <FORM ID="gaia_loginform" ACTION="https://www.google.com/accounts/ServiceLoginAuth?service=mail" METHOD="post">
    <INPUT TYPE="hidden" NAME="ltmpl" VALUE="default">
    <INPUT TYPE="hidden" NAME="ltmplcache" VALUE="2">
    <INPUT TYPE="hidden" NAME="continue" id="continue" value="http://mail.google.com/mail/?ui=html&amp;zy=l">
    <INPUT TYPE="hidden" NAME="service" id="service" value="mail">
    <INPUT TYPE="hidden" NAME="rm" id="rm" value="false">
    <INPUT TYPE="hidden" NAME="ltmpl" id="ltmpl" value="default">
    <INPUT TYPE="hidden" NAME="ltmpl" id="ltmpl" value="default">
    <INPUT TYPE="hidden" NAME="scc" id="scc" value="1">
    <INPUT TYPE="hidden" NAME="GALX" value="yFBdDelgcnk">
    <INPUT TYPE="hidden" NAME="Email" id="Email">
    <INPUT TYPE="hidden" NAME="Passwd" id="Passwd">
	  <INPUT TYPE="hidden" NAME='rmShown' value="1">
  </FORM>	
</BODY>
</HTML>