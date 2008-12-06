<%@ page import="javax.mail.Session,javax.mail.Folder,javax.mail.Multipart,javax.mail.BodyPart,javax.mail.URLName,javax.mail.MessagingException,javax.mail.FolderNotFoundException,javax.mail.AuthenticationFailedException,javax.mail.internet.*,java.util.Properties,java.io.IOException,com.knowgate.hipermail.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_mimemsg = request.getParameter("gu_mimemsg");
  String nm_folder = request.getParameter("folder");
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  String sGuUser = getCookie(request, "userid", "");
  String sIdDomain = getCookie(request, "domainid", "");
  String sIdWrkA = getCookie(request,"workarea","");

  String sPwd = (String) GlobalCacheClient.get("[" + sGuUser + ",mailpwd]");
  if (null==sPwd) {
    sPwd = ACL.encript(getCookie (request, "authstr", ""), ENCRYPT_ALGORITHM);
    GlobalCacheClient.put ("[" + sGuUser + ",mailpwd]", sPwd);
  }

  DBStore oRDBMS = null;
  Folder oFolder = null;
  
  try {    
    Session oMailSession = Session.getInstance(new Properties(), null);
    URLName oURLSession = new URLName("jdbc://", GlobalDBBind.getProfileName(), -1, null, sGuUser, sPwd);

    oRDBMS = new DBStore(oMailSession, oURLSession);
    oRDBMS.connect(GlobalDBBind.getProfileName(), sGuUser, sPwd);

    oFolder = oRDBMS.getFolder(nm_folder);

    oFolder.open(Folder.READ_WRITE|DBFolder.MODE_BLOB);

    DBMimeMessage oMsg = new DBMimeMessage(oFolder, gu_mimemsg);
    DBMimeMultipart oParts = (DBMimeMultipart) oMsg.getParts();
    
    for (int p=0; p<a_items.length; p++) {
      if (com.knowgate.debug.DebugFile.trace) com.knowgate.debug.DebugFile.writeln("DBMimeMultipart.removeBodyPart("+a_items[p]+")");

      oParts.removeBodyPart(Integer.parseInt(a_items[p]));
    }
    
    oFolder.close(false);
    oFolder = null;
    oRDBMS.close();
    oRDBMS = null;
  }
  catch (AuthenticationFailedException auth) {
    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("AuthenticationFailedException " + auth.getMessage());
    return;
  }
  catch (FolderNotFoundException fnfe) {
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}

    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("FolderNotFoundException " + fnfe.getMessage());  
    return;
  }
  catch (IOException ioe) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("IOException " + ioe.getMessage());
    return;
  }
  catch (ArrayIndexOutOfBoundsException aiob) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("ArrayIndexOutOfBoundsException " + aiob.getMessage());
    return;
  }
  catch (MessagingException me) {
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) { try {oRDBMS.close();} catch (Exception ignore) {}}
    response.setContentType("text/plain");
    response.setHeader("Content-Disposition","inline; filename=\"error.txt\"");
    out.write("MessagingException " + me.getMessage());
    return;
  }
    
  response.sendRedirect (response.encodeRedirectUrl ("msg_attachs.jsp?gu_mimemsg="+gu_mimemsg+"&folder="+nm_folder));
%><%@ include file="../methods/page_epilog.jspf" %>