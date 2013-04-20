<%@ page import="javax.mail.Session,javax.mail.Folder,javax.mail.Multipart,javax.mail.BodyPart,javax.mail.URLName,javax.mail.MessagingException,javax.mail.FolderNotFoundException,javax.mail.AuthenticationFailedException,javax.mail.internet.*,java.io.IOException,java.io.FileInputStream,java.util.Properties,java.io.ByteArrayInputStream,java.io.InputStream,java.io.ByteArrayOutputStream,java.io.OutputStream,java.io.UnsupportedEncodingException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.StreamPipe,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Image,com.knowgate.hipermail.*" language="java" session="false" contentType="application/octec-stream" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  response.addHeader ("cache-control", "private");
  
  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  final String sMsgId = request.getParameter("msgid");
  final String sPartId = request.getParameter("cid");
  final String sPartNum = request.getParameter("part");
  String sFolder = request.getParameter("folder");
  
  int iPart;

  if (null!=sPartNum)
    iPart = Integer.parseInt(sPartNum);
  else
    iPart = -1;

  String sGuUser = getCookie(request, "userid", "");
  String sIdDomain = getCookie(request, "domainid", "");
  String sIdWrkA = getCookie(request,"workarea","");

  String sPwd = (String) GlobalCacheClient.get("[" + sGuUser + ",mailpwd]");
  if (null==sPwd) {
    sPwd = ACL.encript(getCookie (request, "authstr", ""), ENCRYPT_ALGORITHM);
    GlobalCacheClient.put ("[" + sGuUser + ",mailpwd]", sPwd);
  }

  String sSep = System.getProperty("file.separator");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  String sSubPath = "domains" + sSep + sIdDomain + sSep + "workareas" + sSep + sIdWrkA;
   
  String sMBoxDir;
  if (sFileProtocol.equals("file://"))
    sMBoxDir = sFileProtocol + sStorage + sSubPath;
  else
    throw new java.net.ProtocolException(sFileServer);
  
  OutputStream oOut;
  Object oContent = null;
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;

  DBStore oRDBMS = null;
  DBFolder oFolder = null;

  try {
    oConn = GlobalDBBind.getConnection("msg_guid");
    String sMsgGuid = DBMimeMessage.getGuidFromId(oConn, sMsgId);
    oConn.close("msg_guid");
    oConn = null;
    
    if (null==sMsgGuid)
      throw new SQLException("Message " + sMsgId + "not found", "02000", 2000);
      
    Session oMailSession = Session.getInstance(new Properties(), null);
    URLName oURLSession = new URLName("jdbc://", GlobalDBBind.getProfileName(), -1, sMBoxDir, sGuUser, sPwd);

    oRDBMS = new DBStore(oMailSession, oURLSession);
    oRDBMS.connect(GlobalDBBind.getProfileName(), sGuUser, sPwd);
        
    if (null==sFolder) {      
      oFolder = (DBFolder) oRDBMS.getDefaultFolder();      	      
      sFolder = oFolder.getName();
    } else {
      oFolder = (DBFolder) oRDBMS.getFolder(sFolder);      	      
    }

    oFolder.open(Folder.READ_ONLY);

    DBMimeMessage oMimeMsg = new DBMimeMessage(oFolder, sMsgGuid);
    
    DBMimeMultipart oParts = (DBMimeMultipart) oMimeMsg.getParts();

    BodyPart oBody;

    if (null!=sPartNum)    
      oBody = oParts.getBodyPart(iPart-1);
    else
      oBody = oParts.getBodyPart("<"+sPartId+">");
    
    oContent = oBody.getContent();

    String sContentType = oBody.getContentType();

    if (sContentType!=null)
        if (sContentType.indexOf(";")>0) sContentType = (Gadgets.split(sContentType,';')[0]).trim();
          
    String sFileName = oBody.getFileName();
    String sDisposition = nullif(oBody.getDisposition(), "inline");    
    int nBytes = oBody.getSize();
    
    if (DebugFile.trace) DebugFile.writeln("file "+sFileName+" disposition "+sDisposition+" size "+String.valueOf(nBytes));

    oFolder.close(false);
    oFolder = null;
    oRDBMS.close();
    oRDBMS = null;
    
      if (oContent!=null) {
          String sClassName = oContent.getClass().getName();
          
  	  if (sClassName.equals("java.lang.String")) {
  	    if (DebugFile.trace) {
  	      DebugFile.writeln("Content-Type=" + nullif(sContentType,"text/html"));
  	      DebugFile.writeln("Content-Disposition=inline; filename=\"" + nullif(sFileName) + "\"");
  	    }
  
            response.setContentType(nullif(sContentType,"text/html"));
            response.setHeader("Content-Disposition","inline; filename=\"" + nullif(sFileName) + "\"");
  	    out.write((String) oContent);
  
  	} else if (sClassName.equals("java.io.ByteArrayInputStream") || sClassName.equals("java.io.FileInputStream") ||
  	         sClassName.equals("com.sun.mail.util.BASE64DecoderStream")) {
  	    if (nBytes!=0) response.setContentLength(nBytes);
  
  	    if (nullif(sContentType).toLowerCase().startsWith("message/delivery-status")) {
        	response.setContentType(nullif(sContentType,"text/plain"));
                response.setHeader("Content-Disposition","inline; filename=\"" + nullif(sFileName,"delivery-status.txt") + "\"");	          	      
  	    }
  	    else if (nullif(sContentType).toLowerCase().startsWith("text/rfc822-headers")) {
        	response.setContentType(nullif(sContentType,"text/plain"));
                response.setHeader("Content-Disposition","inline; filename=\"" + nullif(sFileName,"undelivered-message-headers.txt") + "\"");	    
  	    }
  	    else {
  	      if (DebugFile.trace) {
  	        DebugFile.writeln("Content-Type=" + nullif(sContentType,"aplication/octec-stream"));
  	        DebugFile.writeln("Content-Disposition=" + sDisposition+"; filename=\"" + nullif(sFileName) + "\"");
  	      }
  
  	      if (nullif(sContentType).length()>0) response.setContentType(sContentType);
                response.setHeader("Content-Disposition",sDisposition+"; filename=\"" + nullif(sFileName) + "\"");
              }
              
  	    oOut = response.getOutputStream();
  	    
  	    StreamPipe oPipe = new StreamPipe(true);
  	    
  	    oPipe.between((InputStream)oContent,oOut,8000);
  	    oOut.flush();

  	    if (sClassName.equals("java.io.ByteArrayInputStream"))
  	      ((ByteArrayInputStream)oContent).close();
	    else if (sClassName.equals("java.io.FileInputStream"))
  	      ((FileInputStream)oContent).close();

  	} else if (sClassName.equals("sun.awt.motif.X11Image") ||
  	         sClassName.equals("sun.awt.win32.Win32Image") ||
  	         sClassName.equals("sun.awt.windows.WImage") ||
  	         sClassName.equals("sun.awt.macos.MacImage") ) {
  	  
  	    if (nullif(sContentType).length()>0) response.setContentType(sContentType);
              response.setHeader("Content-Disposition",sDisposition+"; filename=\"" + nullif(sFileName) + "\"");
  
  	    oOut = response.getOutputStream();
  	    
  	    StreamPipe oPipe = new StreamPipe(true);
  	    
  	    oPipe.between(oBody.getInputStream(),oOut,8000);
  	    oOut.flush();
  	} else if (sClassName.equals("javax.mail.internet.MimeMessage")) {
  
  	    oConn = GlobalDBBind.getConnection("msg_attachment");
  	    oConn.setAutoCommit(false);
  
  	    String sAttachmentId = "<"+sMsgId+"."+String.valueOf(iPart)+">";
            oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_mimemsg + "=? OR " + DB.id_message + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
            oStmt.setString(1, sAttachmentId);
            oStmt.setString(2, sAttachmentId);
  	    ResultSet oRSet = oStmt.executeQuery();	    
  	    boolean bCached = oRSet.next();
  	    oRSet.close();
  	    oStmt.close();
  	    
  	    oConn.commit();
  	    oConn.close("msg_attachment");
  	    oConn = null;
  	      	    
  	    if (!bCached) {

    	      oRDBMS = new DBStore(oMailSession, oURLSession);
    	      oRDBMS.connect(GlobalDBBind.getProfileName(), sGuUser, sPwd);
    
      	      oFolder = (DBFolder) oRDBMS.getFolder(request.getParameter("folder"));      	      

  	      ((MimeMessage) oContent).setHeader("Message-ID",sAttachmentId);
  	      
  	      oFolder.open(DBFolder.READ_WRITE);
  	      oFolder.appendMessage((MimeMessage) oContent);  	      
  	      oFolder.close(false);

  	      oRDBMS.close();
 
  	      oConn = GlobalDBBind.getConnection("msg_attachment");
  	      oConn.setAutoCommit(false);
  	      
  	      PreparedStatement oUpdt = oConn.prepareStatement("UPDATE " + DB.k_mime_msgs + " SET " + DB.gu_parent_msg + "=? WHERE gu_mimemsg=?");
  	      oUpdt.setString(1, DBMimeMessage.getGuidFromId(oConn, sMsgId)); 
  	      oUpdt.setString(2, DBMimeMessage.getGuidFromId(oConn, sAttachmentId)); 
  	      oUpdt.executeUpdate();
  	      oUpdt.close();
  	      oUpdt = null;

  	      oConn.commit();
  	      oConn.close("msg_attachment");
  	      oConn = null;  	      
  	    }
%>
  	    <jsp:forward page="msg_view.jsp">
  	      <jsp:param name="id_msg" value="<%=sAttachmentId%>" />
  	      <jsp:param name="nu_msg" value="-1" />
  	      <jsp:param name="nm_folder" value="<%=oFolder.getName()%>" />
  	    </jsp:forward>    
<%        return;
  	} else {
          response.setContentType("text/plain");
          response.setHeader("Content-Disposition","inline");
  	  out.write(sClassName);
          }
        } else {
	  if (DebugFile.trace) DebugFile.writeln("BodyPart.getContent() was null");        
        }
  }
  catch (SQLException sqle) {
    if (oStmt!=null) { try {oStmt.close();} catch (Exception ignore) {}}
    try { if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close();
      } } catch (Exception ignore) {}

    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("SQLException " + sqle.getMessage());
  } 
  catch (AuthenticationFailedException auth) {
    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("AuthenticationFailedException " + auth.getMessage());
  }
  catch (FolderNotFoundException fnfe) {
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}

    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("FolderNotFoundException " + fnfe.getMessage());  
  }
  catch (IOException ioe) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("IOException " + ioe.getMessage());
  }
  catch (MessagingException me) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("MessagingException " + me.getMessage());
  }

  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"

%><%@ include file="../methods/page_epilog.jspf" %>