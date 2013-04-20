<%@ page import="com.sun.mail.smtp.SMTPMessage,javax.mail.*,javax.mail.Message.RecipientType,javax.mail.internet.*,java.util.Properties,java.util.HashMap,java.util.Iterator,java.io.File,java.io.FileNotFoundException,java.io.InputStream,java.io.ByteArrayOutputStream,java.io.IOException,java.net.URL,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,java.sql.ResultSet,java.sql.Types,com.knowgate.jdc.JDCConnection,com.knowgate.debug.DebugFile,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Job,com.knowgate.scheduler.jobs.MimeSender,com.knowgate.dfs.*,com.knowgate.hipermail.*,com.knowgate.crm.Attachment,com.knowgate.crm.Contact" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="msg_txt_util.jspf" %><%@ include file="../methods/page_prolog.jspf" %><%!
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


  // -------------------------------------------------------------  
  
  public int safeLength(InternetAddress[] a) {
    if (a==null) return 0; else return a.length;
  }
    
  // -------------------------------------------------------------  
%><%
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // ***********************
  // Autenticate user cookie

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_mimemsg = request.getParameter("GUID");
  String nm_folder = request.getParameter("FOLDER");
  String tp_content = request.getParameter("CONTENTTYPE");
  if (tp_content.equals("text")) tp_content="plain";
  String gu_from = request.getParameter("SEL_FROM");
  String tx_subject = request.getParameter("SUBJECT");
  String gu_contact = nullif(request.getParameter("CONTACT"));
  String id_mimemsg = nullif(request.getParameter("ID"));
  if (id_mimemsg.length()==0 || id_mimemsg.equals("null")) id_mimemsg=null; 

  String id_domain = getCookie(request, "domainid", "");  
  String gu_workarea = getCookie (request, "workarea", null);
  String id_user = getCookie (request, "userid", null);
  String gu_account = nullif(request.getParameter("gu_account"),getCookie(request,"mail_account","").trim());
  boolean bo_webbeacon = nullif(request.getParameter("chk_webbeacon"),"0").equals("1");
  boolean bo_notification = nullif(request.getParameter("chk_notification"),"0").equals("1");

  String tx_pwd = (String) GlobalCacheClient.get("[" + id_user + ",mailpwd]");
  if (null==tx_pwd) {
    tx_pwd = ACL.encript(getCookie (request, "authstr", ""), ENCRYPT_ALGORITHM);
    GlobalCacheClient.put ("[" + id_user + ",mailpwd]", tx_pwd);
  }

  String sWebSrvr = Gadgets.chomp(GlobalDBBind.getProperty("webserver"),'/');
  String sProfile = GlobalDBBind.getProfileName();
  String sMBoxDir = DBStore.MBoxDirectory(sProfile,Integer.parseInt(id_domain),gu_workarea);
  String sGuJob;

  MailAccount oMacc = null;  
  DBStore oRDBMS = null;
  DBFolder oDrafts = null;
  DBFolder oSent = null;
  DBMimeMessage oDraft;
  SessionHandler oHndlr = null;
  JDCConnection oConn = null;
  RecipientsHelper oRecp = new RecipientsHelper(gu_workarea);
  PreparedStatement oAtom = null;

  String sBody;
  
  if (tp_content.equals("html")) {
    sBody = "<HTML>\n<HEAD><TITLE>" + tx_subject + "</TITLE></HEAD>\n<BODY>\n" + request.getParameter("MSGBODY");
    if (bo_webbeacon) {
      sBody += "<!--WEBBEACON SRC=\""+sWebSrvr+"hipermail/web_beacon.jsp?gu_job={#Job.Guid}&pg_atom={#Job.Atom}&gu_company={#Data.Company_Guid}&gu_contact={#Data.Contact_Guid}&tx_email={#Address.EMail}\"-->";
    }
    sBody += "\n</BODY>\n</HTML>";
  } else {
    sBody = request.getParameter("MSGBODY");
  }
  
  // If body contains "{#" substring then it is assumed to have personalization tags
  boolean bIsPersonalizedMail = (sBody.indexOf("{#")>=0);  

  if (DebugFile.trace) DebugFile.writeln("<JSP:is "+(bIsPersonalizedMail ? "" : "not ")+"personalized mail");

  boolean bXcpt = false;

  try {
    oConn = GlobalDBBind.getConnection("msg_send");

    // **********************************
    // Get mail account object for sender

    oMacc = new MailAccount(oConn, gu_from);

    // ***************************************************************************************
    // Get message recipients extracting members from lists and placing them on Bcc as needed.

    oRecp.parseRecipientsList(oConn, request.getParameter("TO"),Message.RecipientType.TO);
    oRecp.parseRecipientsList(oConn, request.getParameter("CC"), Message.RecipientType.CC);
    oRecp.parseRecipientsList(oConn, request.getParameter("BCC"), Message.RecipientType.BCC);

		if (DebugFile.trace) DebugFile.writeln("<JSP:has "+(oRecp.hasLists() ? "" : "not ")+"lists");

    oConn.close("msg_send");
    oConn=null;

    // **********************
    // Connect to local store 
      
    oHndlr = new SessionHandler(oMacc);
    oRDBMS = DBStore.open(oHndlr.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);
        
    // ****************************************
    // Get From mail address and displayed name
    
    InternetAddress[] aAdrFrom = new InternetAddress[1];
    if (DebugFile.trace) DebugFile.writeln("<JSP:msg_send.jsp new InternetAddress("+oMacc.getString(DB.tx_main_email)+","+oMacc.getString(DB.tl_account)+",UTF-8)");
    aAdrFrom[0] = new InternetAddress(oMacc.getString(DB.tx_main_email), oMacc.getString(DB.tl_account), "UTF-8");

    // ****************************************
    // Open drafts folder and get draft message
    
    oDrafts = (DBFolder) oRDBMS.getFolder(nm_folder);    
    oDrafts.open (Folder.READ_WRITE);
    String sFolderName = ((DBFolder)oDrafts).getCategory().getString(DB.nm_category);

    oDraft = ((DBFolder)oDrafts).getMessageByGuid(gu_mimemsg);
    oDraft.setSubject(tx_subject);

    // *******************************************************************
    // Temporaly store the message body at k_mime_msgs LONGVARBINARY field

    DraftsHelper.draftUpdate(oRDBMS.getConnection(), Integer.parseInt(id_domain), gu_workarea,
                             gu_mimemsg, id_mimemsg,
                             oMacc.getString(DB.tx_main_email),oMacc.getStringNull(DB.tx_reply_email,oMacc.getString(DB.tx_main_email)),
                             oMacc.getStringNull(DB.tl_account,oMacc.getString(DB.tx_main_email)),
                             tx_subject, tp_content+"; charset=utf-8", sBody, 
                             oRecp.getAddresses(Message.RecipientType.TO),
                             oRecp.getAddresses(Message.RecipientType.CC),
                             oRecp.getAddresses(Message.RecipientType.BCC));

    if (bIsPersonalizedMail || oRecp.hasLists()) {
      MimeSender oJob = MimeSender.newInstance(oRDBMS.getConnection(), sProfile, gu_workarea,
                                    	       gu_mimemsg, id_mimemsg,
                                    	       id_user, oMacc.getString(DB.gu_account),
                                    	       bIsPersonalizedMail, tx_subject, bo_notification);
      oJob.store(oRDBMS.getConnection());      
      sGuJob = oJob.getString(DB.gu_job);
    
      // *****************************
      // Move message to outbox folder
      ((DBFolder) oRDBMS.getFolder("outbox")).moveMessage(oDraft);

      // Prepare a statement for inserting atoms fast
      oAtom = oRDBMS.getConnection().prepareStatement("INSERT INTO "+DB.k_job_atoms+" ("+DB.gu_job+","+DB.id_status+","+DB.id_format+","+DB.tp_recipient+","+DB.tx_email+") VALUES ('"+sGuJob+"',"+String.valueOf(Job.STATUS_PENDING)+",'"+(tp_content.equals("plain") ? "TXT" : "HTML")+"',?,?)");

      // ************************************
      // Write one atom for each mail address

      int nRecps;
      InternetAddress[] aRecps;
      aRecps = (InternetAddress[]) oRecp.getRecipients(Message.RecipientType.TO);
      if (null!=aRecps) {
        nRecps = aRecps.length;
	      for (int r=0; r<nRecps; r++) {
          oAtom.setString(1,"to");
          oAtom.setString(2,aRecps[r].getAddress());
          oAtom.executeUpdate();
	      } // next
      } // fi
      aRecps = (InternetAddress[]) oRecp.getRecipients(Message.RecipientType.CC);
      if (null!=aRecps) {
        nRecps = aRecps.length;
	      for (int r=0; r<nRecps; r++) {
            oAtom.setString(1,"cc");
            oAtom.setString(2,aRecps[r].getAddress());
            oAtom.executeUpdate();
	      } // next
      } // fi
      aRecps = (InternetAddress[]) oRecp.getRecipients(Message.RecipientType.BCC);
      if (null!=aRecps) {
        nRecps = aRecps.length;
	      for (int r=0; r<nRecps; r++) {
          oAtom.setString(1,"bcc");
          oAtom.setString(2,aRecps[r].getAddress());
          oAtom.executeUpdate();
	      } // next
      } // fi
      
      oAtom.close();
      if (!oRDBMS.getConnection().getAutoCommit()) oRDBMS.getConnection().commit();
      oAtom=null;
            
    } else { // !bIsPersonalizedMail && !oRecp.hasLists()

      // ************************
      // Send message inmediately

      SMTPMessage oSentMsg = oDraft.composeFinalMessage(oHndlr.getSmtpSession(), tx_subject, sBody, id_mimemsg, tp_content);
      if (bo_notification) oSentMsg.addHeader("Disposition-Notification-To", oMacc.getString(DB.tx_main_email));

      oHndlr.sendMessage(oSentMsg,aAdrFrom,aAdrFrom,oRecp.getRecipients(Message.RecipientType.TO),
      			 oRecp.getRecipients(Message.RecipientType.CC), oRecp.getRecipients(Message.RecipientType.BCC));

      // ***************************************
      // Store message copy at sent items folder

      oSent = (DBFolder) oRDBMS.getFolder("sent");      
      oSent.open(Folder.READ_WRITE);  
      oSent.appendMessages(new Message[]{oSentMsg});  
      oSent.close(false);

      // ***********************
      // Attach files to contact
      
      if (gu_contact.length()>0) {				
			  DBSubset oAttachments = new DBSubset(DB.k_mime_parts, DB.file_name+","+DB.de_part, DB.gu_mimemsg+"=? AND "+DB.id_disposition+"='reference'", 10);
			  int nAttachments = oAttachments.load(oRDBMS.getConnection(), new Object[]{oDraft.getMessageGuid()});
			  if (nAttachments>0) {
			    Contact oCont = new Contact (oRDBMS.getConnection(), gu_contact);
			    for (int a=0; a<nAttachments; a++) {
			      int iSlash = oAttachments.getString(0,a).lastIndexOf(File.separator);
			      String sDirPath = oAttachments.getString(0,a).substring(0, iSlash);
			      String sFileNm = oAttachments.getString(0,a).substring(iSlash+1);
			      File oAttchedFile = new File(oAttachments.getString(0,a));
			      oAttchedFile.renameTo(new File(sDirPath+File.separator+Gadgets.left(oAttachments.getString(1,a),128)));
			      oCont.addAttachment(oRDBMS.getConnection(), id_user, sDirPath, Gadgets.left(oAttachments.getString(1,a),128), tx_subject, false);
			      oAttchedFile.renameTo(new File(oAttachments.getString(0,a)));
			    } // next
          if (!oRDBMS.getConnection().getAutoCommit()) oRDBMS.getConnection().commit();			  
			  } // fi
      } // fi

      // ******************************************
      // Delete original message from drafts folder

      if (DebugFile.trace) DebugFile.writeln("folder="+sFolderName);  
      if (sFolderName.equals("drafts") || sFolderName.endsWith("_drafts")) {
        oDraft.setFlag(Flags.Flag.DELETED, true);
      }

      oSent = null;
    
    } // fi (bIsPersonalizedMail || oRecp.hasLists())
    
    oDrafts.close(sFolderName.equals("drafts") || sFolderName.endsWith("_drafts"));
    oDrafts = null;
    oRDBMS.close();
    oRDBMS = null;
    oHndlr.close();
    oHndlr=null;
  }
  catch (SQLException q) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + q.getMessage() + "&resume=_back"));
  }
  catch (IndexOutOfBoundsException i) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IndexOutOfBoundsException&desc=" + i.getMessage() + "&resume=_back"));
  } catch (NullPointerException n) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + n.getMessage() + "&resume=_back"));
  } catch (ParseException f) {
    bXcpt = true;
    String sParseXcptMsg = f.getMessage();
    if (sParseXcptMsg==null && f.getNextException()!=null) sParseXcptMsg = f.getNextException().getMessage();
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ParseException&desc=" + sParseXcptMsg + "&resume=_back"));
  } catch (IOException i) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + i.getMessage() + "&resume=_back"));
  } catch (AuthenticationFailedException a) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=AuthenticationFailedException&desc=" + a.getMessage() + "&resume=_back"));
  } catch (FolderNotFoundException f) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FolderNotFoundException&desc=" + f.getMessage() + "&resume=_back"));
  } catch (SendFailedException s) {
    bXcpt = true;
    if (s.getCause()!=null)
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SendFailedException&desc=" + nullif(s.getMessage()).replace('#','~') + " " + s.getCause().getClass().getName()+ " " + s.getCause().getMessage() + "&resume=_back"));
    else
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SendFailedException&desc=" + nullif(s.getMessage()).replace('#','~') + "&resume=_back"));
  } catch (MessagingException me) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + me.getMessage() + "&resume=_back"));
  } catch (NumberFormatException me) {
    bXcpt = true;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + me.getMessage() + "&resume=_back"));
  }
  finally {
    if (null!=oAtom)   { try {oAtom.close();} catch (Exception ignore){} }
    if (null!=oConn)   { try { if (!oConn.isClosed()) oConn.close();} catch (Exception ignore){} }
    if (null!=oRDBMS)  { try {oRDBMS.close();} catch (Exception ignore) {} }
    if (null!=oDrafts) { try {oDrafts.close(false);} catch (Exception ignore){} }
    if (null!=oHndlr)  { try {oHndlr.close();} catch (Exception ignore){} }
  }
  if (bXcpt) return;
%>
<HTML>
	<HEAD>
		<SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
		<SCRIPT TYPE="text/javascript">
			<!--
		    function startSchedulerIfNecessary() {
<%     if (bIsPersonalizedMail || oRecp.hasLists()) { %>		    	
    		  var cac = createXMLHttpRequest();
    			if (cac) {
            cac.open("GET", "../servlet/HttpSchedulerServlet?action=info", false);
      			cac.send(null);
	      		var sch = cac.responseXML.getElementsByTagName("scheduler");
						var sts = getElementText(sch[0],"status");
						if (sts=="stop" || sts=="stopped") {
              cac.open("GET", "../servlet/HttpSchedulerServlet?action=start", false);
              cac.send(null);						  
						} // fi
          } // fi
<% } %>
		      top.close()
		    }
		  // -->
		</SCRIPT>
  </HEAD>
	<BODY onload="startSchedulerIfNecessary()"></BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>