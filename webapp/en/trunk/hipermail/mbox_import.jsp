<%@ page import="java.util.Vector,javax.mail.Session,javax.mail.Folder,javax.mail.URLName,javax.mail.MessagingException,javax.mail.FolderNotFoundException,javax.mail.AuthenticationFailedException,javax.mail.internet.*,java.io.IOException,java.io.File,java.util.Properties,java.io.InputStream,java.io.UnsupportedEncodingException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.misc.Environment,com.knowgate.hipergate.ProductLocation,com.knowgate.dfs.StreamPipe,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  final String gu_location = request.getParameter("gu_location");
  final String gu_target = request.getParameter("gu_target");
  final String nu_skip = request.getParameter("nu_skip");
  final String nu_count = request.getParameter("nu_count");

  int iSkip = 0;
  if (null!=nu_skip) iSkip = Integer.parseInt(nu_skip);
  
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
  String sMboxFilePath;
   
  String sMBoxDir;
  if (sFileProtocol.equals("file://"))
    sMBoxDir = sFileProtocol + sStorage + sSubPath;
  else
    throw new java.net.ProtocolException(sFileServer);
  
  DBStore oRDBMS = null;
  DBFolder oFolder = null;
  ProductLocation oLoca = new ProductLocation();
  
  try {
    
    Session oMailSession = Session.getInstance(new Properties(), null);
    URLName oURLSession = new URLName("jdbc://", GlobalDBBind.getProfileName(), -1, sMBoxDir, sGuUser, sPwd);

    oRDBMS = new DBStore(oMailSession, oURLSession);
    oRDBMS.connect(GlobalDBBind.getProfileName(), sGuUser, sPwd);

    oLoca.load (oRDBMS.getConnection(), new Object[]{gu_location});
  
    sMboxFilePath = Gadgets.chomp(oLoca.getString(DB.xpath), File.separator)+oLoca.getString(DB.xfile);
    
    oFolder = (DBFolder) oRDBMS.getFolder(gu_target);
    
    oFolder.open(Folder.READ_WRITE);
    
    MimeMessage oMsg;
    InputStream oMsgStrm;

    MboxFile oInputMbox = new MboxFile(sMboxFilePath, MboxFile.READ_ONLY);

   int iMsgCount;

   if (null==nu_count)   
     iMsgCount = oInputMbox.getMessageCount();
   else
     iMsgCount = Integer.parseInt(nu_count);
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Import messages</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    var done = false;
    var skip = 0;
    var halt = false;
    var errr = false;
      
    function reload() {
      if (halt) {
        alert('Importación de mensajes cancelada');
        window.opener.document.reload(true);
        if (!errr) window.close();
      }
      else if (done) {
        alert('Messages import finished');
        window.opener.document.reload(true);
        if (!errr) window.close();
      }
      else {
        window.document.location.href = "mbox_import.jsp?gu_location=<%=gu_location%>&gu_target=<%=gu_target%>&nu_count=<%=iMsgCount%>&nu_skip=" + String(skip);
      }
    }
  //-->
  </SCRIPT>
</HEAD>
<BODY onload="reload()">
  <!-- <%=iMsgCount%> messages left -->
  <CENTER>
  <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1">Import messages</FONT></TD></TR></TABLE>  
  <BR>
  <DIV ALIGN="LEFT" ID="proBar1" STYLE="background-color:white;width:500px;height:14px;padding:2px;font-size:6pt;border-style:solid;border-color:#000000;border-width:1px;">
    <DIV ALIGN="LEFT" ID="proBar2" STYLE="background-color:#8080FF;width:0px;height:10px;font-size:6pt"></DIV>
  </DIV>
  <DIV ALIGN="CENTER" ID="lab1" STYLE="background-color:white;width:500px;height:10px;font-family:Arial,Helvetica,sans-serif;font-size:10pt"></DIV>
  <FORM>
    <INPUT TYPE="button" CLASS="closebutton" VALUE="Stop" onclick="halt=true; alert('El proceso tardara unos minutos en detenerse completamente, por favor pulse Aceptar y espere');">
  </FORM>
  </CENTER>
<%
    long lStart = System.currentTimeMillis();
        
    if (iSkip>0)
      out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">document.all.proBar2.style.width=\"" + String.valueOf((iSkip*500)/iMsgCount) + "\";setInnerHTML(\"lab1\",\"" + String.valueOf(iSkip+1) + "/" + String.valueOf(iMsgCount) + "\");</SCRIPT>\n");

    int m=iSkip;
    for (; m<iMsgCount; m++) {
      oMsgStrm = oInputMbox.getMessageAsStream(m);
            
      oMsg = new MimeMessage(oMailSession, oMsgStrm);
      
      out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">document.all.proBar2.style.width=\"" + String.valueOf((m*500)/iMsgCount) + "\";setInnerHTML(\"lab1\",\"" + String.valueOf(m+1) + "/" + String.valueOf(iMsgCount) + "\"); skip=" + String.valueOf(m+1) + ";</SCRIPT>\n");
      out.flush();
      
      try {
        oFolder.appendMessage(oMsg);
      }
      catch (MessagingException msgxcpt) {
	out.write (msgxcpt.getMessage()+"<BR><BR>");
	
        /*
        StreamPipe oPipe = new StreamPipe();
        oMsgStrm = oInputMbox.getMessageAsStream(m);
        oPipe.between(oMsgStrm, response.getOutputStream());
        */
        
        oInputMbox.close();    
        oFolder.close(false);
        if (1==1) return;
      }
      
      oMsgStrm.close();
    
      long lNow = System.currentTimeMillis();
      if (((lNow-lStart) > 120000l) && (m<iMsgCount-1)) {
        // If have been executing the page for over 2 minutes the realod the page and continue for avoiding a page timeout
	break;
      }
    }

    if (m>=iMsgCount-1)
      out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done = true;</SCRIPT>\n");

    oInputMbox.close();    
    oFolder.close(false);
    oFolder = null;
    oRDBMS.close();
    oRDBMS = null;
  }
  catch (AuthenticationFailedException auth) {
    out.write("AuthenticationFailedException " + auth.getMessage());
    out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done=true; halt=true; errr=true;</SCRIPT>\n");
    out.flush();
  }
  catch (SQLException sqle) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    out.write("SQLException " + sqle.getMessage());
    out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done=true; halt=true; errr=true;</SCRIPT>\n");
    out.flush();
  } 
  catch (FolderNotFoundException fnfe) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    out.write("FolderNotFoundException " + fnfe.getMessage());  
    out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done=true; halt=true; errr=true;</SCRIPT>\n");
    out.flush();
  }
  catch (IOException ioe) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    out.write("IOException " + ioe.getMessage());
    out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done=true; halt=true; errr=true;</SCRIPT>\n");
    out.flush();
  }
  catch (MessagingException me) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    out.write("MessagingException " + me.getMessage());
    out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done=true; halt=true; errr=true;</SCRIPT>\n");
    out.flush();
  }
  catch (ClassCastException cce) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    out.write("ClassCastException " + cce.getMessage());
    out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done=true; halt=true; errr=true;</SCRIPT>\n");
    out.flush();
  }
  catch (NullPointerException npe) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    out.write("NullPointerException " + npe.getMessage());
    out.write("  <SCRIPT LANGUAGE=\"JavaScript\" TYPE=\"text/javascript\">done=true; halt=true; errr=true;</SCRIPT>\n");
    out.flush();
  }  
%>
</BODY>
</HTML>      