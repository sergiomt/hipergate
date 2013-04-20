<%@ page import="java.net.URL,javax.activation.DataHandler,javax.activation.DataSource,javax.activation.FileDataSource,javax.activation.URLDataSource,javax.mail.*,javax.mail.internet.*,java.util.Enumeration,java.util.Properties,java.io.File,java.io.IOException,java.io.UnsupportedEncodingException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.lucene.Indexer,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="mail_env.jspf" %><%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return; %>
<HTML>
  <HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
<%
  String sMsgId = request.getParameter("id_msg");
  int iMsgNum = Integer.parseInt(request.getParameter("nu_msg"));
  String sFolder = request.getParameter("nm_folder");

  int iIdDomain = Integer.parseInt(id_domain);
 
  String sTxSubject = null;

  DBMimeMessage oMimeMsg = null;
  Multipart oParts = null;
  DBInetAddr oAdrDb;
  
  InternetAddress   oFrom = null;
  InternetAddress[] oToDb = null;
  InternetAddress[] oCcDb = null;
  InternetAddress[] oBccDb= null;
  
  JDCConnection oCon = null;
  DBStore oRDBMS = null;
  DBFolder oInbox = null;
  Properties oHeaders;

  SessionHandler oHndl = new SessionHandler(oMacc);
  oHndl.setMBoxDirectory(sMBoxDir);

  try {
    oRDBMS = new DBStore(oHndl.getSession(), new URLName("jdbc://", GlobalDBBind.getProfileName(), -1, sMBoxDir, id_user, tx_pwd));

    oRDBMS.connect();
    
    oInbox = (DBFolder) oRDBMS.getFolder(sFolder);

    oInbox.open(Folder.READ_ONLY);
    
    oHeaders = oInbox.getMessageHeaders (sMsgId);
    
    if (null==oHeaders) {
      oMimeMsg = oRDBMS.preFetchMessage(oHndl.getFolder("INBOX"), iMsgNum);
    } else {
      oMimeMsg = new DBMimeMessage(oInbox, oHeaders.getProperty(DB.gu_mimemsg));      
    } // fi (oHeaders)

    oParts = oMimeMsg.getParts();
    sTxSubject = oMimeMsg.getSubject();      
    oFrom  = (InternetAddress) ((DBMimeMessage)oMimeMsg).getFromRecipient();
    oToDb  = (InternetAddress[]) oMimeMsg.getRecipients(MimeMessage.RecipientType.TO);
    oCcDb  = (InternetAddress[]) oMimeMsg.getRecipients(MimeMessage.RecipientType.CC);
    oBccDb = (InternetAddress[]) oMimeMsg.getRecipients(MimeMessage.RecipientType.BCC);      
    
    oInbox.close(false);
    oInbox=null;
    oRDBMS.close();
    oRDBMS=null;
  }
  catch (ArrayIndexOutOfBoundsException msgnotfound) {
    oHeaders = null;
    try { if (null!=oInbox) oInbox.close(false); } catch (Exception ignore) {}        
    try { if (null!=oRDBMS) oRDBMS.close(); } catch (Exception ignore) {}    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=Message no longer available at server&resume=_close"));    
    return;
  }
  catch (AuthenticationFailedException e) {
    oHeaders = null;    
    try { if (null!=oInbox) oInbox.close(false); } catch (Exception ignore) {}        
    try { if (null!=oRDBMS) oRDBMS.close(); } catch (Exception ignore) {}    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=AuthenticationFailedException&desc=" + oMacc.getString(DB.gu_user) + " " +e.getMessage() + "&resume=_close"));  
    return;
  }
  catch (MessagingException e) {  
    oHeaders = null;
    try { if (null!=oInbox) oInbox.close(false); } catch (Exception ignore) {}        
    try { if (null!=oRDBMS) oRDBMS.close(); } catch (Exception ignore) {}    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + e.getMessage() + "&resume=_close"));  
    return;
  }
  
  oHndl.close();
%>
  <TITLE><%=sTxSubject%></TITLE>
  </HEAD>
  <BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <TABLE HEIGHT="100%" WIDTH="100%" BORDER="0" CELLPADDING="2" CELLSPACING="0">
    <TR><TD WIDTH="100%" ALIGN="LEFT" VALIGN="TOP">
    <TABLE WIDTH="98%">
      <TR>
        <TD COLSPAN="2" BGCOLOR="silver"><FONT CLASS="formstrong"><%=sTxSubject%></FONT></TD>
      </TR>
      <TR>
        <TD BGCOLOR="linen" WIDTH="100"><FONT CLASS="formstrong">From:</FONT></TD>
        <TD BGCOLOR="#EAE5E1"><FONT CLASS="formplain">
        <% 
           if (null!=oFrom) out.write(nullif(oFrom.getPersonal(), oFrom.getAddress()));
        %>
        </FONT></TD>        
      </TR>
<%   if (oToDb!=null) if (oToDb.length>0) { %>
      <TR>
        <TD BGCOLOR="linen" WIDTH="100"><FONT CLASS="formstrong">To:</FONT></TD>
        <TD BGCOLOR="#EAE5E1"><FONT CLASS="textsmall">
<%
	for (int a=0; a<oToDb.length; a++)
	  out.write ((a==0 ? "" : "; ") + nullif(oToDb[a].getPersonal(), oToDb[a].getAddress()));	  
%>        
        </FONT></TD>
      </TR>
<%   } %>
<%   if (oCcDb!=null) if (oCcDb.length>0) { %>
      <TR>
        <TD BGCOLOR="linen" WIDTH="100"><FONT CLASS="formstrong">CC:</FONT></TD>
        <TD BGCOLOR="#EAE5E1"><FONT CLASS="textsmall">
<%
	for (int a=0; a<oCcDb.length; a++)
	  out.write ((a==0 ? "" : "; ") + nullif(oCcDb[a].getPersonal(), oCcDb[a].getAddress()));	  
%>        
        </FONT></TD>
      </TR>
<%   } %>
<%   if (oBccDb!=null) if (oBccDb.length>0) { %>
      <TR>
        <TD BGCOLOR="linen" WIDTH="100"><FONT CLASS="formstrong">BCC:</FONT></TD>
        <TD BGCOLOR="#EAE5E1"><FONT CLASS="textsmall">
<%
	for (int a=0; a<oBccDb.length; a++)
	  out.write ((a==0 ? "" : "; ") + nullif(oBccDb[a].getPersonal(), oBccDb[a].getAddress()));	  
%>        
        </FONT></TD>
      </TR>
<%   } %>
      <TR>
        <TD BGCOLOR="linen" COLSPAN="2">
          <TABLE BORDER="0">
            <TR>
              <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/reply.gif" BORDER="0"></TD>
              <TD VALIGN="middle"><A HREF="msg_new_f.jsp?action=reply<%=(sFolder==null ? "" : "&folder="+sFolder)%>&gu_mimemsg=<%=oMimeMsg.getMessageGuid()%>&msgid=<%=sMsgId%>" TARGET="_top" CLASS="linkplain"><B>Reply</B></A></TD>
              <TD><IMG SRC="../images/images/spacer.gif" WIDTH="16" HEIGHT="1" BORDER="0"></TD>
              <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/replyall.gif" BORDER="0"></TD>
              <TD VALIGN="middle"><A HREF="msg_new_f.jsp?action=replyall<%=(sFolder==null ? "" : "&folder="+sFolder)%>&gu_mimemsg=<%=oMimeMsg.getMessageGuid()%>&msgid=<%=sMsgId%>" TARGET="_top" CLASS="linkplain"><B>Reply All</B></A></TD>
              <TD><IMG SRC="../images/images/spacer.gif" WIDTH="16" HEIGHT="1" BORDER="0"></TD>
              <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/forward.gif" BORDER="0"></TD>
              <TD VALIGN="middle"><A HREF="msg_new_f.jsp?action=forward<%=(sFolder==null ? "" : "&folder="+sFolder)%>&gu_mimemsg=<%=oMimeMsg.getMessageGuid()%>&msgid=<%=sMsgId%>" TARGET="_top" CLASS="linkplain"><B>Forward</B></A></TD>
            </TR>
          </TABLE>
        </TD>
      </TR>
    </TABLE>
<%!
  public static String getFileExtension(DBBind oDBB, String sContentId) {
    String sExt = "";
    
    JDCConnection oCon = null;
    PreparedStatement oStm = null;
    ResultSet oRst;
    
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.debug.DebugFile.writeln("<JSP:Begin getFileExtension([DBBind], "+sContentId+")");
      com.knowgate.debug.DebugFile.incIdent();
    }
    
    String sMimeType = sContentId.toLowerCase();
    
    int iSemiColon = sMimeType.indexOf(';');
    if (iSemiColon>0) sMimeType = sMimeType.substring(0, iSemiColon);
    sMimeType = sMimeType.trim();
    
    // Do not lookup typical mime types at the database but return them directly
    if (sMimeType.equals("text/plain"))
      return ".txt";
    else if (sMimeType.equals("text/html"))
      return ".htm";
    else if (sMimeType.equals("image/gif"))
      return ".gif";
    else if (sMimeType.equals("image/jpeg"))
      return ".jpg";
    
    try {
      oCon = oDBB.getConnection("msg_ext");
      
      if (com.knowgate.debug.DebugFile.trace)
        com.knowgate.debug.DebugFile.writeln("<JSP:Connection.prepareStatement(SELECT " + DB.id_prod_type + " FROM " + DB.k_lu_prod_types + " WHERE "+DB.mime_type+"=?)");
      
      oStm = oCon.prepareStatement("SELECT " + DB.id_prod_type + " FROM " + DB.k_lu_prod_types + " WHERE "+DB.mime_type+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStm.setString (1, sMimeType);
      oRst = oStm.executeQuery();
      if (oRst.next())
        sExt = "."+oRst.getString(1).toLowerCase();
      oRst.close();
      oStm.close();
      
      oCon.close("msg_ext");
      oCon = null;
    }
    catch (SQLException e) {  
      if (oStm!=null) { try {oStm.close();} catch (Exception ignore) {}}
      if (oCon!=null) {
        try {
          if (!oCon.isClosed()) {
            oCon.close("msg_ext");
          }
        } catch (SQLException ignore) {}
      }
    }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.debug.DebugFile.decIdent();
      com.knowgate.debug.DebugFile.writeln("<JSP:End getFileExtension() : " + sExt);
    }

    return sExt;
  }
%>
<%
  int iAttachments = 0;

  if (null!=oParts) {

    final int iParts = oParts.getCount();
    if (DebugFile.trace) DebugFile.writeln("message has " + String.valueOf(iParts) + " parts");

    for (int p=0; p<iParts; p++) {
       BodyPart oPart = oParts.getBodyPart(p);
       String sContentId = nullif(oPart.getContentType()).toUpperCase();
       String sDisposition = nullif(oPart.getDisposition(),"inline");
        
       if (DebugFile.trace) DebugFile.writeln("Part " + String.valueOf(p) + " " + sDisposition + " Content-Type: " + sContentId.replace('\r',' ').replace('\n',' '));
			
       if (!sDisposition.equalsIgnoreCase("inline") ||
          (!sContentId.startsWith("TEXT/PLAIN") && !sContentId.startsWith("TEXT/HTML") && !sContentId.startsWith("MULTIPART/ALTERNATIVE"))) {
         
         if (sContentId.startsWith("MESSAGE/DELIVERY-STATUS"))
           out.write("<A HREF=\"msg_part.jsp?folder="+sFolder+"&msgid="+Gadgets.URLEncode(sMsgId)+"&part="+String.valueOf(p+1)+"\">"+nullif(oPart.getDescription(),"Delivery error report")+"</A>&nbsp;");
         else if (sContentId.startsWith("TEXT/RFC822-HEADERS"))
           out.write("<A HREF=\"msg_part.jsp?folder="+sFolder+"&msgid="+Gadgets.URLEncode(sMsgId)+"&part="+String.valueOf(p+1)+"\">"+nullif(oPart.getDescription(),"Undelivered-message headers")+"</A>&nbsp;");
         else {
           String sFile = oPart.getFileName();
           if (null==sFile)
             sFile = "attachment"+String.valueOf(iAttachments+1)+getFileExtension(GlobalDBBind, sContentId);
           
           out.write("<A CLASS=\"linkplain\" HREF=\"msg_part.jsp?part="+String.valueOf(p+1)+"&folder="+sFolder+"&msgid="+Gadgets.URLEncode(sMsgId)+"\">" + sFile + "</A>&nbsp;");
         }
         if (oPart.getSize()<1024)
           out.write("<FONT CLASS=\"textplain\">(" + String.valueOf(oPart.getSize()) +" bytes)</FONT>");   
         else if (oPart.getSize()<1048576)
           out.write("<FONT CLASS=\"textplain\">(" + String.valueOf(oPart.getSize()/1024) +" Kb)</FONT>");   
         else
           out.write("<FONT CLASS=\"textplain\">(" + String.valueOf(oPart.getSize()/1048576) +" Mb)</FONT>");            
         if (p<iParts-1) out.write("&nbsp;&nbsp;&nbsp;&nbsp;");
         iAttachments++;
       }
    } // next
  } else {
    if (DebugFile.trace) DebugFile.writeln("message is not multipart");
  }
  if (iAttachments>0) out.write("  <BR>");
  
%>         
  </TD></TR>
  <TR HEIGHT="100%"><TD WIDTH="100%" BGCOLOR="white">
    <IFRAME NAME="msgbody" ID="msgbody" SRC="msg_frame.jsp?gu_account=<%=oMacc.getString(DB.gu_account)%>&id_msg=<%=Gadgets.URLEncode(sMsgId)%>&nu_msg=<%=request.getParameter("nu_msg")%><%=(sFolder==null ? "" : "&folder="+sFolder)%>&resume=<%=Gadgets.URLEncode("id_msg="+sMsgId+"&nu_msg="+request.getParameter("nu_msg"))%>" WIDTH="100%" HEIGHT="100%" FRAMEBORDER="0"></IFRAME>
  </TD></TR></TABLE>
  </BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>