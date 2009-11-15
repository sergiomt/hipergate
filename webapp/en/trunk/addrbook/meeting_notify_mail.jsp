<%@ page import="java.util.StringTokenizer,javax.mail.Message,javax.mail.internet.InternetAddress,javax.mail.SendFailedException,javax.mail.MessagingException,javax.mail.internet.ParseException,javax.mail.internet.MimeUtility,com.sun.mail.smtp.SMTPMessage,java.util.Properties,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.SessionHandler" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Copyright (C) 2004-2005  Know Gate S.L. All rights reserved.
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
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);
  
  StringTokenizer oRecips = new StringTokenizer(request.getParameter("recipients"), ",;");
  int iRecCount = oRecips.countTokens();
  String[] recipients = new String[iRecCount];  
  for (int t=0; t<iRecCount; t++) recipients[t] = oRecips.nextToken();  
  
  MailAccount oMacc = null;
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("meeting_notify_mail");
    oMacc = MailAccount.forUser(oConn,id_user,Environment.getProfile(GlobalDBBind.getProfileName()));
    oConn.close("meeting_notify_mail");  
  } catch (SQLException e) {
    if (oConn!=null) {
      if (!oConn.isClosed()) oConn.close();
    }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close"));
    return;
  }
  
  SessionHandler oHndlr = null;
  
  try {
    oHndlr = new SessionHandler(oMacc);
    SMTPMessage oMsg = new SMTPMessage(oHndlr.getSession());
    oMsg.setHeader("Content-Transfert-Encoding", "8Bit");
    oMsg.setFrom(new InternetAddress(request.getParameter("from")));
    oMsg.setSubject(MimeUtility.encodeText(request.getParameter("subject")));
    oMsg.setText(request.getParameter("de_meeting"), "utf-8");

    for (int r=0; r<recipients.length; r++) {
      oMsg.addRecipient(Message.RecipientType.TO, new InternetAddress(recipients[r].trim()));
    }

    oHndlr.sendMessage(oMsg, oMsg.getRecipients(Message.RecipientType.TO));

    oHndlr.close();
    oHndlr=null;
  }
  catch (SendFailedException e) {
    if (null!=oHndlr) { try { oHndlr.close(); } catch (Exception ignore) {} }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SendFailedException&desc=" + e.getMessage() + "&resume=_close"));
    return;
  }
  catch (ParseException e) {  
    if (null!=oHndlr) { try { oHndlr.close(); } catch (Exception ignore) {} }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ParseException&desc=" + e.getMessage() + "&resume=_close"));
    return;
  }
  catch (MessagingException e) {  
    if (null!=oHndlr) { try { oHndlr.close(); } catch (Exception ignore) {} }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + e.getMessage() + "&resume=_close"));
    return;
  }
  
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.opener.location.reload(true); parent.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>