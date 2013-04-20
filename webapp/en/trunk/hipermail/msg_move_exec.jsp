<%@ page import="javax.mail.*,javax.mail.internet.*,java.util.Enumeration,java.util.Date,java.util.Properties,java.io.File,java.io.IOException,java.io.UnsupportedEncodingException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,com.sun.mail.dsn.MultipartReport,com.knowgate.debug.DebugFile,com.knowgate.debug.StackTraceUtil,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.dfs.FileSystem,com.knowgate.misc.Gadgets,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><%
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

  // --------------------------------------------------------------------------
  
  response.addHeader ("cache-control", "private");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sErrMsg = "";
  String sFolder = request.getParameter("folder");
  String sTarget = request.getParameter("destination");
  String sAction = request.getParameter("perform");
  String sMsgIds = request.getParameter("ids");
  String sMsgNums = request.getParameter("nums");

  if (DebugFile.trace)
    DebugFile.writeln("<JSP:msg_move.exec.jsp?folder="+sFolder+"&destination="+sTarget+"&perform="+sAction+"&nums="+sMsgNums);

  String[] aMsgIds = null;
  String[] aMsgNums = null;

  if (null!=sMsgIds) aMsgIds = Gadgets.split(sMsgIds,',');
  if (null!=sMsgNums) aMsgNums = Gadgets.split(sMsgNums,',');
  
  DBMimeMessage oMimeMsg = null;
	MimeMessage oPop3Msg = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;

  DBStore oRDBMS = null;
  Folder oInbox;
  Properties oHeaders;

  String sReloadUrl = null;

  DBFolder oLocalFldr = null;
  DBFolder oTargetFldr = null;

  JDCConnection oConn = null;

  SessionHandler oHndlr = new SessionHandler(oMacc);
  
  try {
    if (null==aMsgIds) throw new NullPointerException("The list of messages to move or copy is empty");

    oRDBMS = DBStore.open(oHndlr.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);
    
    oLocalFldr = oRDBMS.openDBFolder(sFolder, Folder.READ_WRITE|DBFolder.MODE_MBOX);

    oTargetFldr = oRDBMS.openDBFolder(sTarget, Folder.READ_WRITE|DBFolder.MODE_MBOX);
    
    if (sFolder.equals("inbox")) {
      
      if (DebugFile.trace) DebugFile.writeln("Store.getFolder(INBOX)");
      
      Folder oPop3Fldr = oHndlr.getStore().getFolder("INBOX");
      
      if (null==oPop3Fldr) {
        try { oTargetFldr.close(false); } catch (Exception ignore) {}
        try { oLocalFldr.close(false); } catch (Exception ignore) {}
        try { oRDBMS.close(); } catch (Exception ignore) {}
        
        response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=Inbox could not be opened&resume=_close"));
        return;
      } // fi (oPop3Fldr)
      
      try {
        oPop3Fldr.open(Folder.READ_WRITE);
        int iPop3Count = oPop3Fldr.getMessageCount();
        
        if (DebugFile.trace)
          DebugFile.writeln("<JSP:Connection.prepareStatement(SELECT " + DB.gu_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.id_message + "=? AND " + DB.gu_category + "='"+((DBFolder)oLocalFldr).getCategory().getString(DB.gu_category)+"')");
    
        out.write("<HTML>\n<HEAD><SCRIPT LANGUAGE=\"JavaScript\" SRC=\"../javascript/cookies.js\"></SCRIPT><SCRIPT LANGUAGE=\"JavaScript\" SRC=\"../javascript/setskin.js\"></SCRIPT><SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">function setLabHTML(txt) { var doc=window.parent.frames[0].document; if ((navigator.appCodeName==\"Mozilla\") && (navigator.appName!=\"Microsoft Internet Explorer\")) doc.getElementById(\"lab1\").innerHTML = txt; else if (doc.layers) doc[\"lab1\"].innerHTML = txt; else doc.all[\"lab1\"].innerHTML=txt; }</SCRIPT>\n");

	      if (DebugFile.trace) DebugFile.writeln("<JSP:message count="+aMsgNums.length);
          
	      for (int m=0; m<aMsgNums.length; m++) {
  
	      try {
	        if (DebugFile.trace) DebugFile.writeln("<JSP:Folder.getMessage("+aMsgNums[m]+")");
	        oPop3Msg = (MimeMessage) oPop3Fldr.getMessage(Integer.parseInt(aMsgNums[m]));
	      } catch (ArrayIndexOutOfBoundsException aiob) {
      	  if (DebugFile.trace) DebugFile.writeln("<JSP:Message not found by number at POP3 folder");
	        oPop3Msg = null;
	      }

	      String sMsgGuid;
	  
	      if (null!=oPop3Msg) {
	        if (!aMsgIds[m].equals(oPop3Msg.getMessageID())) {
	          for (int c=1; c<=iPop3Count; c++) {
	            oPop3Msg = (MimeMessage) oPop3Fldr.getMessage(c);
	            if (aMsgIds[m].equals(oPop3Msg.getMessageID()))
	              break;
	            else
	              oPop3Msg = null;
	          } // next
	        } // fi aMsgIds[m] == oPop3Msg.getMessageID()

	      } else { // null==oPop3Msg

	        for (int c=1; c<=iPop3Count; c++) {
	          oPop3Msg = (MimeMessage) oPop3Fldr.getMessage(c);
	          if (aMsgIds[m].equals(oPop3Msg.getMessageID()))
	            break;
	          else
	            oPop3Msg = null;
	        } // next
	      } // fi (oPop3Msg)
	  
	      if (null!=oPop3Msg) {
	        if (DebugFile.trace) DebugFile.writeln("<JSP:searching message " + oPop3Msg.getMessageID());
          
       	  oConn = GlobalDBBind.getConnection("k_mime_msgs_id_message",true);
       
          oStmt = oConn.prepareStatement("SELECT " + DB.gu_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.id_message + "=? AND " + DB.gu_category + "='"+((DBFolder)oLocalFldr).getCategory().getString(DB.gu_category)+"'",
        					                       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	        oStmt.setString(1, oPop3Msg.getMessageID());

	        oRSet = oStmt.executeQuery();
	    
	        if (oRSet.next()) {
	          sMsgGuid = oRSet.getString(1);
	          if (DebugFile.trace) DebugFile.writeln("<JSP:message guid for " + oPop3Msg.getMessageID() + " is "+ sMsgGuid);
	        } else {
	          sMsgGuid = null;
	          if (DebugFile.trace) DebugFile.writeln("<JSP:message guid for " + oPop3Msg.getMessageID() + " not found");
	        }
	    
	    		oStmt.close();
	    		oStmt=null;
	        oRSet.close();
	        oRSet = null;
	  	    oConn.close("k_mime_msgs_id_message");
	  	    oConn=null;

	        if (sMsgGuid==null) {
	          if (DebugFile.trace) DebugFile.writeln("source message not cached, reading from remote folder");
	    
	          oTargetFldr.appendMessages(new Message[]{oPop3Msg});

	        } else { // sMsgGuid!=null

	          if (DebugFile.trace) DebugFile.writeln("source message cached " + sMsgGuid);
	    
	          oMimeMsg = oLocalFldr.getMessageByGuid(sMsgGuid);
	        }
	    
	        if (sAction.equals("move")) oPop3Msg.setFlag(Flags.Flag.DELETED, true);

        } else { // null==oPop3Msg
          oMimeMsg = oLocalFldr.getMessageByID(aMsgIds[m]);
        } // fi (oPop3Msg)

        if (null!=oMimeMsg) {
	        if (sAction.equals("move"))
	           oTargetFldr.moveMessage(oMimeMsg);
	        else
	          oTargetFldr.copyMessage(oMimeMsg);
          } // fi (oMimeMsg)
	      } // next (m)

	      oPop3Fldr.close(sAction.equals("move"));
      }
      catch (NumberFormatException e) {
        if (DebugFile.trace) {
          DebugFile.writeln("<JSP:NumberFormatException "+ e.getMessage());
          DebugFile.writeln(StackTraceUtil.getStackTrace(e));
          DebugFile.writeln(":JSP>");
        }
        if (oRSet!=null) oRSet.close();
        if (oStmt!=null) oStmt.close();
        oPop3Fldr.close(sAction.equals("move"));
	      sErrMsg += "NumberFormatException "+ e.getMessage() + " ";
      }
      catch (SQLException e) {
        if (DebugFile.trace) {
          DebugFile.writeln("<JSP:SQLException "+ e.getMessage());
          DebugFile.writeln(StackTraceUtil.getStackTrace(e));
          DebugFile.writeln(":JSP>");
        }
        if (oRSet!=null) oRSet.close();
        if (oStmt!=null) oStmt.close();
        oPop3Fldr.close(sAction.equals("move"));
	      sErrMsg += "SQLException "+ e.getMessage() + " ";
      }
      
      // ****************************************
      // Remove deleted messages from inbox cache

	    FileSystem oFs = new FileSystem();        
      File oCache = new File(oLocalFldr.getDirectoryPath()+oMacc.getString(DB.gu_account)+".inbox.cache");

	    if (oCache.exists()) {
        String sCache = oFs.readfilestr(oLocalFldr.getDirectoryPath()+oMacc.getString(DB.gu_account)+".inbox.cache", "UTF-8");
        oCache.delete();
        if (sCache.length()>0) {
          StringBuffer oMsgsXML = new StringBuffer(sCache.length());
          String[] aPopServerMsgsXML = Gadgets.split(sCache,'\n');
          int nPopServerMsgsXML = aPopServerMsgsXML.length;
          int nMsgIds = aMsgIds.length;
          boolean bFirstLine = true;
          int nRemoved = 0;
          for (int l=0; l<nPopServerMsgsXML; l++) {
            boolean bMatch = false;
            for (int m=0; m<nMsgIds && !bMatch; m++) {
              bMatch = (aPopServerMsgsXML[l].indexOf("<id><![CDATA["+aMsgIds[m].replace('\n',' ')+"]]></id>")>=0);
            } // next
            if (!bMatch) {
              if (!bFirstLine) oMsgsXML.append("\n");
              oMsgsXML.append(aPopServerMsgsXML[l]);
              bFirstLine=false;
              nRemoved++;
            } // fi
          } //next
          oFs.writefilestr(oLocalFldr.getDirectoryPath()+oMacc.getString(DB.gu_account)+".inbox.cache", oMsgsXML.toString(), "UTF-8");
          if (DebugFile.trace) DebugFile.writeln(String.valueOf(nRemoved)+" messages removed. Cache file after update is\n"+oMsgsXML.toString());
        }
      } // fi

      // ********************************************************************
      // If message is a confirmation receipt then update confirmed addresses
			if (sTarget.equals("receipts")) {	
				Object oCnt = (oPop3Msg==null ? oMimeMsg : oPop3Msg).getContent();
        if (oCnt.getClass().getName().equals("com.sun.mail.dsn.MultipartReport")) {
  				oConn = GlobalDBBind.getConnection("inet_addrs_notification");
			    oConn.setAutoCommit(true);
					RecipientsHelper.acknowledgeNotification(oConn, (MultipartReport) oCnt);
					oConn.close("inet_addrs_notification");
			  } // fi MultipartReport
			} // fi (sTarget=="receipts")

    } else { // sFolder!="inbox"

      sReloadUrl = "folder_listing_local.jsp?gu_folder="+oLocalFldr.getCategory().getString(DB.gu_category);

      for (int m=0; m<aMsgNums.length; m++) {
	      out.write("<SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">window.parent.frames[0].document.all.proBar2.style.width = \"" + String.valueOf((100*m)/aMsgNums.length) + "px\";setLabHTML(\""+m+"/"+aMsgNums.length+"\")</SCRIPT>\n");
        out.flush();
        oMimeMsg = (DBMimeMessage) oLocalFldr.getMessage(Integer.parseInt(aMsgNums[m]));
        if (sAction.equals("move")) {
          oTargetFldr.moveMessage(oMimeMsg);
        } else {
          oTargetFldr.copyMessage(oMimeMsg);
        }
      } // next
    } // fi (inbox)

    oTargetFldr.close(false);
    oTargetFldr=null;
    oLocalFldr.close(true);
    oLocalFldr=null;
    oRDBMS.close();
    oRDBMS=null;
    oHndlr.close();
    oHndlr=null;
  }
  catch (Exception e) {
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:msg_move_exec.jsp "+ e.getClass().getName() + " " + e.getMessage());
      DebugFile.writeln(StackTraceUtil.getStackTrace(e));
      DebugFile.writeln(":JSP>");
    }
    try { if (null!=oTargetFldr) oTargetFldr.close(false); } catch (Exception ignore) {}
    try { if (null!=oLocalFldr) oLocalFldr.close(false);  } catch (Exception ignore) {}
    try { if (null!=oRDBMS) oRDBMS.close(); } catch (Exception ignore) {}
    try { if (null!=oHndlr) oHndlr.close(); } catch (Exception ignore) {}
    sErrMsg += e.getClass().getName() + " "+ e.getMessage() + " ";
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:"+sErrMsg);
      DebugFile.writeln(StackTraceUtil.getStackTrace(e));
      DebugFile.writeln(":JSP>");
    }
  }

  if (DebugFile.trace) DebugFile.writeln("<JSP:msg_move.exec.jsp Done!");

%></HEAD>
<BODY BGCOLOR="linen" onload="<% if (sErrMsg.length()>0) { %> alert ('<%=Gadgets.escapeChars(sErrMsg.replace('\n',' ').replace((char)39,(char)32),"\\",'\\')%>'); <% } %>">
<!--
<% if (sReloadUrl!=null) { %>window.parent.parent.frames[3].document.location.href='<%=sReloadUrl%>' + '&screen_width=' + String(screen.width); window.parent.document.location.href='../common/blank.htm';<% } %>
-->
</BODY>
</HTML><%@ include file="../methods/page_epilog.jspf" %>