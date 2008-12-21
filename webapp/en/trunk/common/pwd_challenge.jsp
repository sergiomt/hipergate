<%@ page import="java.util.Date,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.acl.ACL" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %>
<% 

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

  String sUserId = null;
  String sChallenge = null;
  String sReply = null;
  boolean bFound = false;
  boolean bHasChallenge = false;
  boolean bHasReply = false;
  
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;

  switch (ACL.checkCaptcha(lCaptchaTimestamp, 30000l, sCaptchaText, sCaptchaKeyMD5)) {
    case (short)0:
	    break;
    case ACL.CAPTCHA_TIMEOUT:
      response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=[~Clave expirada~]&desc=[~La validez de la clave grafica ha expirado~]&resume=pwd_request.jsp"));
		  return;
    case ACL.CAPTCHA_MISMATCH:
      response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=[~Clave erronea~]&desc=[~La la clave grafica introducida no coincide con la mostrada en pantalla~]&resume=pwd_request.jsp"));
		  return;
		default:	        
      response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=[~Error en la clave~]&desc=[~Se produjo un error indeterminado validando la clave grafica~]&resume=pwd_request.jsp"));
		  return;
  }

  try {
    oConn = GlobalDBBind.getConnection("pwd_challenge");
    
		if (sNickName.indexOf('@')>=0) {
		  oStmt = oConn.prepareStatement("SELECT " + DB.gu_user + "," + DB.tx_challenge + "," + DB.tx_reply +
		  														   " FROM " + DB.k_users + " WHERE " + DB.tx_main_email + "=? OR " + DB.tx_alt_email + "=?",
		  														   ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
	    oStmt.setString(1, sNickName);
	    oStmt.setString(2, sNickName);	    
		} else {
		  oStmt = oConn.prepareStatement("SELECT " + DB.gu_user + "," + DB.tx_challenge + "," + DB.tx_reply +
		  															 " FROM " + DB.k_users + " WHERE " + DB.tx_nickname + "=?",
		  														   ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
	    oStmt.setString(1, sNickName);
		}
	  oRSet = oStmt.executeQuery();
	  bFound = oRSet.next();
	  if (bFound) {
      sUserId = oRSet.getString(1);
      sChallenge = oRSet.getString(2);
      bHasChallenge = !oRSet.wasNull();
      if (null!=sChallenge) if (sChallenge.length()==0) bHasChallenge = false;
      sReply = oRSet.getString(3);
      bHasReply = !oRSet.wasNull();
      if (null!=sReply) if (sReply.length()==0) bHasReply = false;
	  }
	  oRSet.close();
	  oRSet=null;
	  oStmt.close();
    oStmt=null;
    oConn.close("pwd_challenge");
  }
  catch (Exception e) {
    if (oRSet!=null) oRSet.close();
    if (oStmt!=null) oStmt.close();
    if (oConn!=null) if (!oConn.isClosed())oConn.close("pwd_challenge");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=pwd_request.jsp"));
  }
  
  if (null==oConn) return;    
  oConn = null;
  
  if (!bFound) {
    response.sendRedirect (response.encodeRedirectUrl ("pwd_errmsg.jsp?title=[~Usuario no encontrado~]&desc=[~El usuario especificado no se encuentra en la base de datos~]&resume=pwd_request.jsp"));
		return;
  }
%>
<HTML>
  <HEAD>
    <TITLE>[~Frase de verificaci&oacute;n~]</TITLE>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  </HEAD>
	<BODY TOPMARGIN="8" MARGINHEIGHT="8" onload="<% if (!bHasChallenge || !bHasReply) out.write("document.forms[0].submit()"); else out.write("document.getElementById('chform').style.visibility='visible'"); %>">
		<DIV ID="chform" STYLE="visibility:hidden">
    <TABLE WIDTH="100%">
      <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
      <TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Frase de verificaci&oacute;n~]</FONT></TD></TR>
    </TABLE>  
	  <FORM METHOD="post" ACTION="pwd_retrieve.jsp">
		  <INPUT TYPE="hidden" name="nickname" VALUE="<%=sNickName%>">
		  <INPUT TYPE="hidden" name="captcha_text" VALUE="<%=sCaptchaText%>">
		  <INPUT TYPE="hidden" name="gu_user" VALUE="<%=sUserId%>">
      <TABLE>
        <TR><TD CLASS="textplain"><%=sChallenge%></TD></TR>
        <TR><TD><INPUT TYPE="text" NAME="tx_reply" MAXLENGTH="100" SIZE="30"></TD></TR>
        <TR>
          <TD>
			      <INPUT TYPE="submit" CLASS="pushbutton" ACCESSKEY="r" TITLE="ALT+r" VALUE="[~Recuperar~]">
			      &nbsp;&nbsp;&nbsp;&nbsp;
			      <INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" VALUE="[~Cancelar~]" onclick="window.close()">
          </TD>
        </TR>
	    </TABLE>
    </FORM>
  </DIV>
  </BODY>
</HTML>