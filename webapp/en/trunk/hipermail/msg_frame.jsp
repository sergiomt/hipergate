<%@ page import="javax.mail.*,javax.mail.internet.*,java.util.HashMap,java.util.Properties,java.io.IOException,java.io.UnsupportedEncodingException,java.net.URLDecoder,java.net.MalformedURLException,java.sql.Statement,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dataxslt.FastStreamReplacer,com.knowgate.hipermail.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%!
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
                      C/Oña 107 1º2 28050 Madrid (Spain)

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


  // --------------------------------------------------------------------------

%><%

  response.addHeader ("cache-control", "private");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  if (DebugFile.trace) DebugFile.writeln("<JSP:Begin msg_frame.jsp");

  String sGuAccount = request.getParameter("gu_account");
  String sGuUser = getCookie(request, "userid", "");

  String sPwd = (String) GlobalCacheClient.get("[" + sGuUser + ",mailpwd]");
  if (null==sPwd) {
    sPwd = ACL.encript(getCookie (request, "authstr", ""), ENCRYPT_ALGORITHM);
    GlobalCacheClient.put ("[" + sGuUser + ",mailpwd]", sPwd);
  }
  
  String sMsgId = request.getParameter("id_msg");  
  int iMsgNum = Integer.parseInt(request.getParameter("nu_msg"));
  String sFolder = request.getParameter("folder");  

  String sIdDomain = getCookie(request, "domainid", "");
  String sIdWrkA = getCookie(request,"workarea","");
  
  DBMimeMessage oMsg = null;
  Multipart oParts = null;
  String sText = "";

  String sMBoxDir = DBStore.MBoxDirectory(GlobalDBBind.getProfileName(),Integer.parseInt(sIdDomain),sIdWrkA);

  JDCConnection oCon = null;
  MailAccount oMacc = new MailAccount();
  try {
    oCon = GlobalDBBind.getConnection("msg_frame");
    oMacc.load(oCon, new Object[]{sGuAccount});
    oCon.close("msg_frame");  
  } catch (Exception e) {  
    if (oCon!=null) if (!oCon.isClosed()) oCon.close("msg_frame");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + sGuUser + " " + e.getMessage() + "&resume=_close"));  
    return;
  }
    
  Session oMailSession = Session.getInstance(oMacc.getProperties(), null);

  DBStore oRDBMS = null;
  DBFolder oFolder;

  try {
    URLName oURLSession = new URLName("jdbc://", GlobalDBBind.getProfileName(), -1, sMBoxDir, sGuUser, sPwd);

    oRDBMS = new DBStore(oMailSession, oURLSession);
    oRDBMS.connect(GlobalDBBind.getProfileName(), sGuUser, sPwd);
    
    if (null==sFolder)
      oFolder = (DBFolder) oRDBMS.getDefaultFolder();
    else
      oFolder = (DBFolder) oRDBMS.getFolder(sFolder);    
    
    oFolder.open(Folder.READ_ONLY);
    
    oMsg = (DBMimeMessage) oFolder.getMessage(iMsgNum);
    if (null==oMsg)
      oMsg = oFolder.getMessageByID (sMsgId);
    else if (!sMsgId.equals(oMsg.getMessageID()))
      oMsg = oFolder.getMessageByID (sMsgId);
    
    if (oMsg!=null) {

      sText = oMsg.getText();
      
      String sContentId = nullif(oMsg.getMessageContentType());
      
      if (DebugFile.trace) DebugFile.writeln("<JSP:content/type="+sContentId);
      
      if (sContentId.toUpperCase().startsWith("TEXT/PLAIN"))
        sText = Gadgets.replace(sText,"\n","<BR>");

      out.write (sText);

      oParts = oMsg.getParts();

      boolean bFooter = false;

      if (null!=oParts) {
        if (DebugFile.trace && oParts.getCount()==0) DebugFile.writeln("<JSP:zero parts found for message "+sMsgId);
        for (int p=0; p<oParts.getCount(); p++) {
          if (DebugFile.trace) DebugFile.writeln("<JSP:Multipart.getBodyPart("+String.valueOf(p)+")");
          
          BodyPart oPart =  oParts.getBodyPart(p);

          sContentId = nullif(((MimePart)oPart).getContentID()).toUpperCase();

          if (DebugFile.trace) DebugFile.writeln("<JSP:ContentID="+sContentId);

					String sDisposition = nullif(oPart.getDisposition());

          if (DebugFile.trace) DebugFile.writeln("<JSP:Disposition="+sDisposition);
					
          if (sDisposition.equalsIgnoreCase("inline") && (sContentId.startsWith("TEXT/PLAIN") || sContentId.startsWith("TEXT/HTML"))) {
            if (!bFooter) {
              out.write("<BR><HR><BR>");
              bFooter = true;    
            }
            try {             
          		if (DebugFile.trace) DebugFile.writeln("<JSP:DBMimePartgetText()");
             sText = ((DBMimePart)oPart).getText();
    	       out.write (sText);
    	      }
    	      catch (SQLException sqle) {
              if (DebugFile.trace) DebugFile.writeln("SQLException"+sqle.getMessage());
    	      }    	   
          } // fi
        } // next
      } else {
        if (DebugFile.trace) DebugFile.writeln("<JSP:no parts found for message "+sMsgId);      	
      }// fi (oParts)
    } else {
      out.write("<FONT FACE=\"Arial,Helvetica,sans.serif\">Message number "+String.valueOf(iMsgNum)+" with unique identifier "+Gadgets.HTMLEncode(sMsgId)+" was not found at mail folder "+oFolder.getName()+"<FONT>");
    }

    oFolder.close(false);
    oRDBMS.close();
  }
  catch (MessagingException e) {  
    try { if (oRDBMS!=null) oRDBMS.close(); } catch (Exception ignore) {}      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + e.getMessage() + "&resume=../blank.htm"));
    return;
  }
  catch (UnsupportedEncodingException uee) {
    try { if (oRDBMS!=null) oRDBMS.close(); } catch (Exception ignore) {}      
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=UnsupportedEncodingException&desc=This message cannot be displayed because it uses an unsupported charset&resume=../blank.htm"));
    return;
  }    

  out.flush();

  if (DebugFile.trace) DebugFile.writeln("<JSP:End msg_frame.jsp");

%><%@ include file="../methods/page_epilog.jspf" %>