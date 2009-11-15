<%@ page import="com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %><%
  String guid = request.getParameter("gu_mimemsg");
  String msgid = request.getParameter("msgid");
  String action = request.getParameter("action");
  String folder = request.getParameter("folder");
  String contenttype = request.getParameter("contenttype");
  String to = request.getParameter("to");
  String gu_contact = request.getParameter("gu_contact");
  String gu_location = request.getParameter("gu_location");

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Compose new message</TITLE>
  </HEAD>
  <FRAMESET NAME="composemail" ROWS="*,100" FRAMEBORDER="0">
    <FRAME NAME="msgbody" MARGINWIDTH="0" MARGINHEIGHT="0" SCROLLING="no" SRC="msg_new.jsp?<%=(msgid==null ? "void=0" : "msgid="+msgid) + (gu_location==null ? "" : "&gu_location="+gu_location) + (gu_contact==null ? "" : "&gu_contact="+gu_contact) + (action==null ? "" : "&action=" + action) + (folder==null ? "" : "&folder=" + folder) + (guid==null ? "" : "&gu_mimemsg=" + guid) + "&contenttype=" + (contenttype==null ? "html" : "plain") + (to==null ? "" : "&to="+Gadgets.URLEncode(to))%>">
    <FRAME NAME="msgattachments" MARGINWIDTH="0" MARGINHEIGHT="0" SRC="../blank.htm">
  </FRAMESET>
  <NOFRAMES>
      <BODY>
	<P>This page uses frames but your browser does not support them</P>
      </BODY>
  </NOFRAMES>
  </FRAMESET>
</HTML>
