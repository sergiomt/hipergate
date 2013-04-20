<%@ page import="java.util.HashSet,java.util.Date,java.io.IOException,java.io.FileNotFoundException,java.io.File,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.misc.Environment,javax.mail.*,javax.mail.internet.MimeMessage,javax.mail.internet.InternetAddress,javax.mail.internet.AddressException,javax.mail.internet.MimeUtility,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.DBStore,com.knowgate.hipermail.DBFolder,com.knowgate.hipermail.SessionHandler,com.knowgate.hipermail.DBMimeMessage,com.knowgate.hipermail.HeadersHelper,com.knowgate.misc.Gadgets,com.knowgate.debug.Chronometer,com.knowgate.debug.DebugFile,com.knowgate.debug.StackTraceUtil" language="java" session="false" contentType="text/xml;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><% 
/*
  Copyright (C) 2008-2012  Know Gate S.L. All rights reserved.

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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // **************************************************************************
  // Initialize variables
  
  Chronometer oTotalMeter = new Chronometer();
  Chronometer oPartialMeter = new Chronometer();
  
  if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp Begin");
      
  final String nm_folder = nullif(request.getParameter("nm_folder"),"inbox");
  final String only_new = nullif(request.getParameter("only_new"),"false"); // Display all or only new messages
  final String bo_update = nullif(request.getParameter("bo_update"),"0");  // Get mail headers update from server
  
  final int iMaxRows = nullif(request.getParameter("maxrows"),100);
  final int iSkip = Math.max(nullif(request.getParameter("skip"), 0),0);
    
  boolean bUpdate = (bo_update.equalsIgnoreCase("yes") || bo_update.equalsIgnoreCase("true") || bo_update.equalsIgnoreCase("1"));
  boolean bOnlyNew = (only_new.equalsIgnoreCase("yes") || only_new.equalsIgnoreCase("true") || only_new.equalsIgnoreCase("1"));

  String sFolderDir = null;
  String sMsgId = null;

  int iServerCount = 0;
  int iCachedCount = 0;  
  int iFetchCount = 0;

  String[] aPopServerMsgsXML = null;
  String[] aLocalDBMSMsgsXML = null;
  
  FileSystem oFs = new FileSystem();
  File oCache = null;
  boolean bExists = false;

  // **************************************************************************
  // Open folder to get messages identifiers set and folder directory path

  oPartialMeter.start();

  SessionHandler oHndl = new SessionHandler(oMacc, sMBoxDir);

  DBStore oRdbms = null;
  DBFolder oFldr = null;
  DBKeySet oKset = null;

  try {
    
    oRdbms = DBStore.open(oHndl.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);
    oFldr = oRdbms.openDBFolder(nm_folder, DBFolder.READ_ONLY);

    if (bOnlyNew) {
      oKset = oFldr.keySet();
      if (oKset.size()==0) bOnlyNew = false;
    }
    
    sFolderDir = oFldr.getDirectoryPath();
    
    // **************************************************************************
    // Check if a cached copy of message headers exists
    // if so then load it at aLocalDBMSMsgsXML

    oCache = new File(sFolderDir+oMacc.getString(DB.gu_account)+"."+nm_folder+".cache");
    bExists = oCache.exists();
    
    if (nm_folder.equals("drafts")) oFldr.expunge();
    aLocalDBMSMsgsXML = oFldr.listMessages();

    oFldr.close(false);
    oFldr=null;
    oRdbms.close();

  } catch (Exception e) {  
    try { if (null!=oFldr) oFldr.close(false); } catch (Exception ignore) {}
    try { if (null!=oRdbms) oRdbms.close(); } catch (Exception ignore) {}
    try { if (null!=oHndl) oHndl.close(); } catch (Exception ignore) {}
    out.write("<folder><error>"+e.getClass().getName()+" DBStore " + e.getMessage()+"</error></folder>");
    return;
  }

  oPartialMeter.stop();

  if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp DBFolder access time "+String.valueOf(oPartialMeter.elapsed())+" ms");

  if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp cache file "+sFolderDir+oMacc.getString(DB.gu_account)+"."+nm_folder+".cache "+(bExists ? "found" : "not found"));

  if (!bUpdate) {
    final long CacheLifetime = 600000l; // Ten minutes
    if (bExists)
      bUpdate = (new Date().getTime()-oCache.lastModified()>CacheLifetime);
  } // fi

  // ***************************************************************************
  // If a cached copy of message headers does not exist or an update from server
  // has been requested then get messages from server and store their headers at
  // the local cache XML file
    
  if (!bExists || bUpdate) {

    if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp refresing headers local cache");

    oPartialMeter.start();
    
    try {
      final String INBOX = "INBOX";      
      aPopServerMsgsXML = oHndl.listFolderMessages(INBOX);
    } catch (Exception e) {  
      oHndl.close();
      if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp " + e.getClass().getName() + " " + e.getMessage() + "\n" + StackTraceUtil.getStackTrace(e));
      out.write("<folder><error>" + e.getClass().getName() + " SessionHandler listFolderMessages() " + e.getMessage() + "</error></folder>");
      return;
    }

    oPartialMeter.stop();

    if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp time retrieving messages from server "+String.valueOf(oPartialMeter.elapsed())+" ms");

    StringBuffer oMsgsXML;
    
    try {
      
      if (null==aPopServerMsgsXML && null==aLocalDBMSMsgsXML) {

        oMsgsXML = new StringBuffer();
			  iFetchCount = iServerCount = iCachedCount = 0;     

      } else if (null==aPopServerMsgsXML && null!=aLocalDBMSMsgsXML) {

				iServerCount = 0;
        iCachedCount = aLocalDBMSMsgsXML.length;
        iFetchCount = iCachedCount>iMaxRows ? iMaxRows : iCachedCount;

        oMsgsXML = new StringBuffer(iCachedCount*200);

        for (int m=iCachedCount-1; m>=0; m--) {
          oMsgsXML.append(aLocalDBMSMsgsXML[m]);
          oMsgsXML.append("\n");
        } // next (m)      

      } else if (null!=aPopServerMsgsXML && null==aLocalDBMSMsgsXML) {

        iCachedCount = 0;
        iServerCount = aPopServerMsgsXML.length;
        iFetchCount = iServerCount>iMaxRows ? iMaxRows : iServerCount;

        oMsgsXML = new StringBuffer(iServerCount*200);

        for (int m=iServerCount-1; m>=0; m--) {
          oMsgsXML.append(aPopServerMsgsXML[m]);
          oMsgsXML.append("\n");
        } // next (m)      
      
      } else {

        if (DebugFile.trace) DebugFile.writeln("<JSP:merging fetched messages with cached messages");

				HashSet<String> oIdMap = new HashSet<String>(iMaxRows*3);
        iCachedCount = aLocalDBMSMsgsXML.length;
        iServerCount = aPopServerMsgsXML.length;
        iFetchCount = (iServerCount+iCachedCount)>iMaxRows ? iMaxRows : (iServerCount+iCachedCount);

        oMsgsXML = new StringBuffer((iServerCount+iCachedCount)*200);

				int iServerIterator = iServerCount-1;
				int iCacheIterator  = iCachedCount-1;
				
				while (iServerIterator>=0 || iCacheIterator>=0) {
				  if (iServerIterator>=0 && iCacheIterator<0) {
				    sMsgId = Gadgets.substrBetween(aPopServerMsgsXML[iServerIterator], "<id><![CDATA[","]]></id>");
				    if (!oIdMap.contains(sMsgId)) {
              oMsgsXML.append(aPopServerMsgsXML[iServerIterator]);
              oMsgsXML.append("\n");
              oIdMap.add(sMsgId);
            }
            iServerIterator--;
				  } else if (iCacheIterator>=0 && iServerIterator<0) {
				    sMsgId = Gadgets.substrBetween(aLocalDBMSMsgsXML[iCacheIterator], "<id><![CDATA[","]]></id>");
				    if (!oIdMap.contains(sMsgId)) {            
              oMsgsXML.append(aLocalDBMSMsgsXML[iCacheIterator]);
              oMsgsXML.append("\n");
              oIdMap.add(sMsgId);
            }
            iCacheIterator--;
				  } else {
				    String sDateCached = Gadgets.substrBetween(aLocalDBMSMsgsXML[iCacheIterator], "<received>","</received>");
				    if (sDateCached.length()==0) sDateCached = Gadgets.substrBetween(aLocalDBMSMsgsXML[iCacheIterator], "<sent>","</sent>");
				    String sDateServer = Gadgets.substrBetween(aPopServerMsgsXML[iServerIterator], "<received>","</received>");
				    if (sDateServer.length()==0) sDateServer = Gadgets.substrBetween(aPopServerMsgsXML[iServerIterator], "<sent>","</sent>");
				    if (sDateCached.compareTo(sDateServer)>0) {
				      sMsgId = Gadgets.substrBetween(aLocalDBMSMsgsXML[iCacheIterator], "<id><![CDATA[","]]></id>");
				      if (!oIdMap.contains(sMsgId)) {
                oMsgsXML.append(aLocalDBMSMsgsXML[iCacheIterator]);
                oMsgsXML.append("\n");
                oIdMap.add(sMsgId);
              }
              iCacheIterator--;				    
				    } else {
				      sMsgId = Gadgets.substrBetween(aPopServerMsgsXML[iServerIterator], "<id><![CDATA[","]]></id>");
				      if (!oIdMap.contains(sMsgId)) {
                oMsgsXML.append(aPopServerMsgsXML[iServerIterator]);
                oMsgsXML.append("\n");
                oIdMap.add(sMsgId);
              }
              iServerIterator--;				    
				    }
				  }
				} // wend
      }

		  // Rewrite message headers xml cache

      if (bExists) oCache.delete();
      oFs.writefilestr(sFolderDir+oMacc.getString(DB.gu_account)+"."+nm_folder+".cache", Gadgets.dechomp(oMsgsXML.toString(),"\n"), "UTF-8");
			if (!new File(sFolderDir+oMacc.getString(DB.gu_account)+"."+nm_folder+".cache").exists())
			  throw new FileNotFoundException("Could not write file "+sFolderDir+oMacc.getString(DB.gu_account)+"."+nm_folder+".cache");

    } catch (FileNotFoundException fnfe) {
      if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp FileNotFoundException " + fnfe.getMessage() + "\n");
      out.write("<folder><error>FileNotFoundException " + fnfe.getMessage()+"</error></folder>");    
    } catch (Exception xcpt) {
      if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp " + xcpt.getClass().getName() + " " + xcpt.getMessage() + "\n" + StackTraceUtil.getStackTrace(xcpt));
      out.write("<folder><error>" + xcpt.getClass().getName() + " HeadersHelper " + xcpt.getMessage()+"</error></folder>");
      if (null!=oHndl) { oHndl.close(); oHndl=null; }
      return;
		}
    
  } // (!bExists || bUpdate)

  oPartialMeter.stop();

  if (null!=oHndl) { oHndl.close(); oHndl=null; }

  // ****************************
  // Read headers from cache file

  String sCache = oFs.readfilestr(sFolderDir+oMacc.getString(DB.gu_account)+"."+nm_folder+".cache", "UTF-8");
  if (sCache.length()>0) {
    aPopServerMsgsXML = Gadgets.split(sCache,'\n');
    iServerCount = aPopServerMsgsXML.length;
    iFetchCount = iServerCount>iMaxRows ? iMaxRows : iServerCount;
  } else {
  	aPopServerMsgsXML = null;
    iFetchCount = iServerCount = 0;
  }
  sCache = null;

  // *************************************************************
  // Finished creating or just reading the messages headers cache
  // Now  take the right subset of messages headers  according to
  // iSkip and iMaxRows parameters and send headers to the client
 
  out.write("<folder account=\""+oMacc.getString(DB.gu_account)+"\" name=\""+nm_folder+"\"><error/><messages total=\""+String.valueOf(iServerCount)+"\" fetched=\""+String.valueOf(iFetchCount)+"\" skip=\""+String.valueOf(iSkip)+"\">");
  
  try {
    int iUpperBound = (iFetchCount+iSkip<iServerCount ? iFetchCount+iSkip : iServerCount); 
    for (int i=iSkip; i<iUpperBound && i<iServerCount; i++) {
      sMsgId = Gadgets.substrBetween(aPopServerMsgsXML[i], "<id><![CDATA[", "]]></id>");
      if (null==sMsgId) {
        out.write("<err>Message "+String.valueOf(i)+" id is null</err>\n");
      } else {
        if (bOnlyNew) {
          if (sMsgId.length()>0 ? !oKset.contains(sMsgId) : false) {
            out.write(aPopServerMsgsXML[i]);
            out.write("<err></err>\n");
          }
        } else {
          out.write(aPopServerMsgsXML[i]);
          out.write("<err></err>\n");
        }
		    if (Gadgets.substrBetween(aPopServerMsgsXML[i], "<spam>", "</spam>").equalsIgnoreCase("YES")) iUpperBound++;
      }
    } // next
    out.write("</messages>");
    out.write("<prev>"+(iSkip>0 ? String.valueOf(iSkip-iMaxRows>0 ? iSkip-iMaxRows : 0) : "" )+"</prev>"); 
    out.write("<next>"+(iFetchCount!=iServerCount ? String.valueOf(iSkip+iFetchCount) : "")+"</next>"); 
    out.write("</folder>"); 
    
  } catch (NumberFormatException xcpt) {
    if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp " + xcpt.getClass().getName() + " " + xcpt.getMessage() + "\n" + StackTraceUtil.getStackTrace(xcpt));
    out.write("<error>" + xcpt.getClass().getName() + " Gadgets.substrBetween " + xcpt.getMessage()+"</error></folder>");
    return;
  }

  if (DebugFile.trace) DebugFile.writeln("<JSP:folder_xmlfeed.jsp End execution time "+String.valueOf(oTotalMeter.stop())+" ms");

%>