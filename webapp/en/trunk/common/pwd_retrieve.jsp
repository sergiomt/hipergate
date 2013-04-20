<%@ page import="java.util.ArrayList,java.util.Date,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACL,com.knowgate.acl.ACLUser,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBAudit,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.hipermail.SendMail" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  String sUserId = request.getParameter("gu_user");
  String sReply = request.getParameter("tx_reply");
  String sNickName = request.getParameter("nickname");
  String sCaptchaText = request.getParameter("captcha_text");
  String sCaptchaTimestamp = getCookie (request, "captcha_timestamp", String.valueOf(new Date().getTime()));
  String sCaptchaKeyMD5 = getCookie (request, "captcha_key", "");

  long lCaptchaTimestamp;
  
  try {
    lCaptchaTimestamp = Long.parseLong(sCaptchaTimestamp);
  } catch (NumberFormatException nfe) {
    lCaptchaTimestamp = new Date().getTime();
  }

  boolean bCheckChallenge = true;   
  JDCConnection oConn = null;
	ACLUser oUser = new ACLUser();
	
  switch (ACL.checkCaptcha(lCaptchaTimestamp, 30000l, sCaptchaText, sCaptchaKeyMD5)) {
    case (short)0:
	    break;
    case ACL.CAPTCHA_TIMEOUT:
      response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=Expired key&desc=The graphic key has expired&resume=pwd_request.jsp"));
		  return;
    case ACL.CAPTCHA_MISMATCH:
      response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=Wrong password&desc=The typed graphic key does not match the one shown on screen&resume=pwd_request.jsp"));
		  return;
		default:	        
      response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=Error at password&desc=An unexpected error occured whilst validating the graphic key&resume=pwd_request.jsp"));
		  return;
  }

  try {
    oConn = GlobalDBBind.getConnection("pwd_retrive");

	  oUser.load(oConn, sUserId);

	  if (!oUser.isNull(DB.tx_challenge) && !oUser.isNull(DB.tx_reply)) {
	    bCheckChallenge = oUser.checkChallengeReply(oConn, sReply);
	  }
  
    DBAudit.log(oConn, ACLUser.ClassId, "RPWD", sUserId, sUserId, null, 0, getClientIP(request), oUser.getStringNull(DB.tx_main_email,""), (bCheckChallenge ? null : "Wrong challenge reply"));
    
    oConn.close("pwd_retrive");
  }
  catch (Exception e) {
    if (oConn!=null) if (!oConn.isClosed())oConn.close("pwd_retrive");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=pwd_request.jsp"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (!bCheckChallenge) {
    response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=Wrong answer&desc=The answer to the verification question is not correct&resume=pwd_challenge.jsp"+Gadgets.URLEncode("?captcha_text="+sCaptchaText+"&nickname="+sNickName)));
		return;
  }
  String aRecipients[];
  if (oUser.isNull(DB.tx_alt_email)) {
    aRecipients = new String[]{oUser.getString(DB.tx_main_email)};
  } else {
    aRecipients = new String[]{oUser.getString(DB.tx_main_email),oUser.getString(DB.tx_alt_email)};
  }

  ArrayList oWarnings = null;

  try {
    oWarnings = SendMail.send(GlobalDBBind.getProperties(), Environment.getTempDir(), null,
  					    						  "Your password is "+oUser.getStringNull(DB.tx_pwd,""),
  					    						  "UTF-8", null, "Your password", "noreply@hipergate.com",
  					    						  "hipergate", null, aRecipients, null, null, null);
  } catch (Exception xcpt) {
    response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=Failure whilst trying to send password&desc=It was not possible to send you your password "+xcpt.getClass().getName()+" "+xcpt.getMessage()+"&resume=pwd_request.jsp"));
    return;
  }
%>
<HTML>
  <HEAD>
    <TITLE>Retrieve Password</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  </HEAD>
	<BODY TOPMARGIN="8" MARGINHEIGHT="8">
    <TABLE WIDTH="100%">
      <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
      <TR><TD CLASS="striptitle"><FONT CLASS="title1">Retrieve Password</FONT></TD></TR>
    </TABLE>  
    <TABLE>
      <TR><TD><BR/><BR/></TD></TR>
      <TR><TD CLASS="textplain">The password has been send to your e-mail</TD></TR>
<% int nWarns = oWarnings.size();
   for (int w=0; w<nWarns; w++) {
      if (!((String)oWarnings.get(w)).startsWith("OK")) out.write("<TR><TD CLASS=\"textplain\">"+oWarnings.get(w)+"</TD></TR>");
   } // next
%>   
      <TR><TD><BR/><BR/></TD></TR>
      <TR><TD align="center"><INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" VALUE="Close" onclick="window.close()"></TD></TR>
	  </TABLE>
  </BODY>
</HTML>