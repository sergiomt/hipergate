<%@ page import="java.sql.SQLException,com.knowgate.acl.ACLUser,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/cookies.jspf" %>
<%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/
  String sProfile = GlobalDBBind.getProfileName();

  JDCConnection oConn = null;
  ACLUser oMe = new ACLUser();
  
  try {

    oConn = GlobalDBBind.getConnection("mail_login");  
    
    oMe.load (oConn, new Object[]{getCookie (request, "userid", "")});
    
    oConn.close("mail_login");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("mail_login");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_topclose"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;    
%>

<HTML>
<HEAD>
  <META http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <STYLE>
    .boton  { background-color:orange;color:white;font-family:Verdana,Arial,Helvetica,sans-serif;font-size:8pt;height:24px; }
  </STYLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY bgcolor="white">
<P align="center">&nbsp;</P>
<P align="center">&nbsp;</P>
<CENTER>
<FORM NAME="loginForm" METHOD="POST" ACTION="<%=nullif(request.getParameter("resume"),"msg_listing.jsp")%>">
<INPUT TYPE="hidden" NAME="defaultmailhost" VALUE="<%=Environment.getProfileVar(sProfile, "mail.incoming", "")%>">
<TABLE align="center" bgcolor="#000000" cellpadding="1" cellspacing="0" border="0">
  <TR>
  <TD valign="middle" bgcolor="#000000" align="center">
    <TABLE cellpadding="0" cellspacing="0" border="0">
      <TR>
        <TD class="menu2" height="50" colspan="4">&nbsp;</TD>
      </TR>
      <TR>
        <TD class="menu1" height="110" align="center" width="85" rowspan="5"><IMG ALT="Logo KnowGate" SRC="/images/images/hipermail/logobibop.gif"></TD>
        <TD bgcolor="white" height="40" align="center" colspan="2"><IMG SRC="/images/images/hipermail/webmailtitle.gif"></TD>
        <TD bgcolor="white" height="115" width="25" rowspan="5">&nbsp;</TD>
      </TR>
      <TR>
        <TD width="140" bgcolor="white" height="25" align="right" class="textplain">Username&nbsp;&nbsp;</TD>
        <TD class="textplain" width="190" bgcolor="white" height="25"><INPUT class="textsmall" SIZE="20" NAME="mailbox" TYPE="text" VALUE="<%=oMe.getStringNull(DB.tx_nickname,"")%>"></TD>
      </TR>
      <TR>
        <TD width="140" bgcolor="white" height="25" align="right" class="textplain">Password&nbsp;&nbsp;</TD>
        <TD class="textplain" width="190" bgcolor="white" height="25"><INPUT class="textsmall" SIZE="20" NAME="password" TYPE="password" VALUE="<%=oMe.getStringNull(DB.tx_pwd,"")%>"></TD>
      </TR>
      <TR>
        <TD width="140" bgcolor="white" height="25" align="right" class="textplain">Incoming mail server&nbsp;&nbsp;</TD>
        <TD class="textplain" width="190" bgcolor="white" height="25"><INPUT class="textsmall" SIZE="20" NAME="mailincoming" TYPE="text" VALUE="<%=Environment.getProfileVar(sProfile, "mail.incoming", "")%>"></TD>
      </TR>
      <TR>
        <TD width="140" bgcolor="white" height="25" align="right" class="textplain">Outgoing mail server&nbsp;&nbsp;</TD>
        <TD class="textplain" width="190" bgcolor="white" height="25"><INPUT class="textsmall" SIZE="20" NAME="mailoutgoing" TYPE="text" VALUE="<%=Environment.getProfileVar(sProfile, "mail.outgoing", "")%>"></TD>
      </TR>
      <TR>
        <TD height="50" class="menu2" width="85">&nbsp;</TD>
        <TD width="140" height="50" class="menu2">&nbsp;</TD>
        <TD width="190" height="50" class="menu2"><INPUT class="boton" value="Login" TYPE="submit"></TD><TD class="menu2" height="50" width="25">&nbsp;</TD>
      </TR>
      <TR>
      <TD align="center" height="35" bgcolor="silver" class="textsmallinv" width="400" colspan="4"></TD>
      </TR>
    </TABLE>
  </TD>
  </TR>
</TABLE>
</FORM>
</CENTER>
</BODY>
</HTML>

