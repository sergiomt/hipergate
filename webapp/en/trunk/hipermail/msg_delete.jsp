<%@ page import="javax.mail.*,javax.mail.internet.MimeMessage,java.io.File,java.util.Properties,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.debug.DebugFile,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %>
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

  // **********************************************

  int iMailCount = 0;
  String sLocalIds = request.getParameter("ids");
  String sLocalNums = request.getParameter("nums");
  String sLocalGuids = request.getParameter("guids");
  String sFolder = request.getParameter("folder");
  String sCatId = "";

  String[] aLocalNums = Gadgets.split(sLocalNums,',');
  String[] aLocalIds = Gadgets.split(sLocalIds,',');
  String[] aLocalGuids = Gadgets.split(sLocalGuids,',');
  
  Folder oInbox = null;
  int iInboxCount;
  MimeMessage oMsg;
  PreparedStatement oUpdt = null;
  JDCConnection oConn = null;
  
  SessionHandler oHndl = null;
  
  try {
  
    // Create mail session
    oHndl = new SessionHandler(oMacc,sMBoxDir);
    
    // Get POP3 store          
    oInbox = oHndl.getStore().getFolder("INBOX");
    
    if (DebugFile.trace) DebugFile.writeln("Folder.open(READ_WRITE)"); 

    // Open Inbox folder
    oInbox.open (Folder.READ_WRITE);
    
    // Get message count
    iInboxCount = oInbox.getMessageCount();

    if (iInboxCount>0) {

      // Iterate throught message numbers passed on parameter nums
      for (int i=0; i<aLocalNums.length; i++) {
        if (DebugFile.trace) DebugFile.writeln("POP3Folder.getMessage("+aLocalNums[i]+")"); 

        try {
          // If message does not have a GUID then it is not cached but just stored at a remote folder,
          // so try to fetch it by number first.
          if (aLocalGuids[i].equals("null")) {
	    // Fetch message by number
            oMsg = (MimeMessage) oInbox.getMessage(Integer.parseInt(aLocalNums[i]));          

            // After fetching message check whether or not its Id matches the one passed as parameter
            // As the inbox view uses a diffrent session from the this delete page, the message numbering
            // may have changed between both
            if (aLocalIds[i].equals(HeadersHelper.decodeMessageId(oMsg))) {
              // If retrieved messaged Id. matches the one passed as parameter then delete it
              if (DebugFile.trace) DebugFile.writeln("MimeMessage.setFlags("+aLocalNums[i]+",Flags.Flag.DELETED, true)"); 
              oMsg.setFlag(Flags.Flag.DELETED, true);
            } else {
              // If retrieved messaged Id. does not match the one passed as parameter then
              // scan the inbox looking for the messages that is to be deleted
              for (int m=0; m<iInboxCount; m++) {
                oMsg = (MimeMessage) oInbox.getMessage(m);
                if (aLocalIds[i].equals(HeadersHelper.decodeMessageId(oMsg))) {
                  if (DebugFile.trace) DebugFile.writeln("MimeMessage.setFlags("+aLocalNums[i]+",Flags.Flag.DELETED, true)"); 
                  oMsg.setFlag(Flags.Flag.DELETED, true);
                } // fi        
              } // next m
            } // fi (aLocalIds[i]==getMessageId())
          } else {
            // If message has a GUID then it cached and most probably its number at the database does not match that at
            // the remote folder so ignore number and look-up by directly by Id.
            for (int m=0; m<iInboxCount; m++) {
              oMsg = (MimeMessage) oInbox.getMessage(m);
              if (aLocalIds[i].equals(HeadersHelper.decodeMessageId(oMsg))) {
                if (DebugFile.trace) DebugFile.writeln("MimeMessage.setFlags("+aLocalNums[i]+",Flags.Flag.DELETED, true)"); 
                oMsg.setFlag(Flags.Flag.DELETED, true);
              } // fi        
            } // next m          
          }
        } catch (ArrayIndexOutOfBoundsException ignore) {
          // If message was already deleted from server then ignore the error
          if (DebugFile.trace) DebugFile.writeln("ArrayIndexOutOfBoundsException Folder.getMessage("+aLocalNums[i]+")"); 
        }        
      } // next
    } // fi ()
    if (DebugFile.trace) DebugFile.writeln("Folder.close(true)"); 
    oInbox.close(true);
    oInbox = null;      
  }
  catch (NullPointerException e) {
    if (null!=oInbox) { try {oInbox.close(false);} catch (Exception ignore) {}}
    if (null!=oHndl) { try {oHndl.close();} catch (Exception ignore) {} }
    aLocalIds = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }  
  catch (MessagingException e) {
    if (null!=oInbox) { try {oInbox.close(false);} catch (Exception ignore) {}}
    if (null!=oHndl) { try {oHndl.close();} catch (Exception ignore) {} }
    aLocalIds = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + e.getMessage() + "&resume=_back"));
  }  
  if (null==aLocalIds) return;
  
  // **********************************
  // Delete message also from the cache

  String[] aInboxGuids = new String[aLocalNums.length];  
  DBStore oRDBMS = null;
  Folder oFolder = null;

  try {
      oConn = null;
      try {
        oConn = GlobalDBBind.getConnection("msg_guid");
        
        for (int m=0; m<aLocalNums.length; m++) {
          if (aLocalGuids[m].equals("null"))
            aInboxGuids[m] = DBMimeMessage.getGuidFromId(oConn, aLocalIds[m]);
          else
            aInboxGuids[m] = aLocalGuids[m];
        }
        
        oConn.close("msg_guid");
        oConn = null;
      } catch (SQLException sqle) {
	if (null!=oConn) { try { oConn.close("msg_guid"); } catch (SQLException ignore) {} }
      }

    oRDBMS = DBStore.open(oHndl.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);

    if (null==sFolder)
      oFolder = oRDBMS.getDefaultFolder();      	      
    else
      oFolder = oRDBMS.getFolder(sFolder);      	      

    oFolder.open(Folder.READ_WRITE);

    sCatId = ((DBFolder)oFolder).getCategory().getString(DB.gu_category);

    String sSQL = "UPDATE " + DB.k_mime_msgs + " SET " + DB.bo_deleted + "=1 WHERE " + DB.gu_mimemsg + "=?";

    oRDBMS.getConnection().setAutoCommit(false);
    
    oUpdt = oRDBMS.getConnection().prepareStatement(sSQL);
    
    for (int i=0; i<aLocalNums.length; i++) {
        if (null!=aLocalIds[i]) {
          if (com.knowgate.debug.DebugFile.trace) DebugFile.writeln("Connection.executeUpdate(UPDATE " + DB.k_mime_msgs + " SET " + DB.bo_deleted + "=1 WHERE " + DB.gu_mimemsg + "='"+aInboxGuids[i]+"')");
          oUpdt.setString(1, aInboxGuids[i]);
          oUpdt.executeUpdate();          
        }
    } // next
    oUpdt.close();
    oUpdt = null;

    oRDBMS.getConnection().commit();

    File oCache = new File(((DBFolder)oFolder).getDirectoryPath()+oMacc.getString(DB.gu_account)+".cache");
    if (oCache.exists()) oCache.delete();
    
    oFolder.close(true);
    oFolder = null;
    oRDBMS.close();
    oRDBMS = null;
    oHndl.close();
    oHndl=null;
  }
  catch (Exception me) {
    if (null!=oUpdt) { try {oUpdt.close();} catch (Exception ignore) {}}
    if (null!=oRDBMS) {
      if (null!=oRDBMS.getConnection()) {
        try { oRDBMS.getConnection().rollback(); } catch (Exception ignore) {}
        try { oRDBMS.close(); } catch (Exception ignore) {}
      }
    }
    if (null!=oHndl) { try {oHndl.close();} catch (Exception ignore) {} }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+me.getClass().getName()+"&desc=" + me.getMessage() + "&resume=_back"));
    return;
  }
%><%@ include file="../methods/page_epilog.jspf" %>