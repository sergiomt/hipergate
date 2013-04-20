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
    oConn = GlobalDBBind.getConnection("yahoo_login");  
  
    oRec.load(oConn,request.getParameter("gu_pwd"));

    oConn.close("yahoo_login");

  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("yahoo_login");
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
  <SCRIPT TYPE="text/javascript" SRC="https://s.yimg.com/lq/i/reg/js/login_md5_1.1.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    function postYahoo() {
    	var frm = document.forms[0];
      frm.login.value="<%=oRec.getValueOf("yahooid")%>";
      frm.passwd.value="<%=oRec.getValueOf("pwd")%>";
      hash2(frm);
			frm.submit();
    }
  </SCRIPT>
</HEAD>
<BODY onLoad="postYahoo()">
  <FORM METHOD="post" ACTION="https://login.yahoo.com/config/login?" AUTOCOMPLETE="off" NAME="login_form">
				<input type="hidden" name=".tries" value="1">
				<input type="hidden" name=".src" value="ym">
				<input type="hidden" name=".md5" value="">
				<input type="hidden" name=".hash" value="">
				<input type="hidden" name=".js" value="">
				<input type="hidden" name=".last" value="">
				<input type="hidden" name="promo" value="">
				<input type="hidden" name=".intl" value="us">
				<input type="hidden" name=".bypass" value="">
				<input type="hidden" name=".partner" value="">
				<input type="hidden" name=".u" value="16ads7559i88d">
				<input type="hidden" name=".v" value="0">
				<input type="hidden" name=".challenge" value="LAnUBuKovRq7yizBW447jMgkL3bC">
				<input type="hidden" name=".yplus" value="">
				<input type="hidden" name=".emailCode" value="">
				<input type="hidden" name="pkg" value="">
				<input type="hidden" name="stepid" value="">
				<input type="hidden" name=".ev" value="">
				<input type="hidden" name="hasMsgr" value="0">
				<input type="hidden" name=".chkP" value="Y">
				<input type="hidden" name=".done" value="http://mail.yahoo.com">
				<input type="hidden" name=".pd" value="ym_ver=0&c=&ivt=&sg=">
				<input name="login" id="username" type="hidden" >
				<input name="passwd" id="passwd" type="hidden">
		</FORM>
</BODY>
</HTML>