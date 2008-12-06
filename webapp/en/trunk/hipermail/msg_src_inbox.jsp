<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,javax.mail.*,javax.mail.internet.MimeMessage,javax.mail.internet.InternetAddress,javax.mail.internet.AddressException,javax.mail.internet.MimeUtility,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.DBStore,com.knowgate.hipermail.DBFolder,com.knowgate.hipermail.SessionHandler" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  response.addHeader ("cache-control", "no-cache");

  String gu_account = request.getParameter("gu_account");
  int nu_msg = Integer.parseInt(request.getParameter("nu_msg"));
  String id_user = getCookie(request,"userid","");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;      
  
  String sFsp = System.getProperty("file.separator");
  String sStorDir = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sFileProt = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileSrvr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  String sWrkAPath = "domains" + sFsp + getCookie(request, "domainid", "") + sFsp + "workareas" + sFsp + getCookie(request,"workarea","");
   
  if (!sFileProt.equals("file://")) {
    out.write("ProtocolException " + sFileProt);
    return;  
  }

  JDCConnection oConn = null;  
  MailAccount oMacc = new MailAccount();

  try {
    oConn = GlobalDBBind.getConnection("folder_xmlfeed");
    oMacc.load(oConn, new Object[]{gu_account});
    oConn.close("folder_xmlfeed");  
  } catch (SQLException e) {  
    if (oConn!=null) if (!oConn.isClosed()) oConn.close("folder_xmlfeed");
    out.write("SQLException " + e.getMessage());
    return;
  }
  
  SessionHandler oHndl = new SessionHandler(oMacc);
  oHndl.setMBoxDirectory(sFileProt + sStorDir + sWrkAPath);
    
  Folder oInbox = null;
  
  try {
    oInbox = oHndl.getStore().getFolder("INBOX");
    oInbox.open (Folder.READ_ONLY);
    MimeMessage oMimeMsg = (MimeMessage) oInbox.getMessage(nu_msg);
    oMimeMsg.writeTo(response.getOutputStream());
    oInbox.close(false);
    oInbox = null;
    oHndl.close();
    oHndl = null;
  } catch (ArrayIndexOutOfBoundsException aiob) {
    out.write("Unable to recover message from Inbox");
    if (null!=oInbox) oInbox.close(false);
    if (null!=oHndl) oHndl.close();
    return;
  } catch (NullPointerException xcpt) {
    out.write(xcpt.getClass().getName() + " " + xcpt.getMessage());
    if (null!=oInbox) oInbox.close(false);
    if (null!=oHndl) oHndl.close();
    return;
  }
%>