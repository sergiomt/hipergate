<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,java.io.File,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_workarea = request.getParameter("gu_workarea");
  String nm_file = request.getParameter("nm_file");
  String id_status = request.getParameter("id_status");

  File oTxt = new File(Gadgets.chomp(Environment.getProfileVar(GlobalDBBind.getProfileName(),"temp",Environment.getTempDir()),File.separator)+gu_workarea+File.separator+nm_file);
  if (oTxt.exists()) oTxt.delete();

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>hipergate :: Import process results</TITLE>
  </HEAD>
  <FRAMESET NAME="textload" ROWS="60,200,*">
    <FRAME NAME="msg" MARGINWIDTH="0" MARGINHEIGHT="0" SRC="userloader4m.jsp?id_status=<%=id_status%>">
    <FRAME NAME="bad" MARGINWIDTH="0" MARGINHEIGHT="0" SRC="userloader4e.jsp?gu_workarea=<%=gu_workarea%>&nm_file=<%=Gadgets.URLEncode(nm_file)%>&id_status=<%=id_status%>&tp_file=bad">
    <FRAME NAME="dis" MARGINWIDTH="0" MARGINHEIGHT="0" SRC="userloader4e.jsp?gu_workarea=<%=gu_workarea%>&nm_file=<%=Gadgets.URLEncode(nm_file)%>&id_status=<%=id_status%>&tp_file=dis">
    <NOFRAMES>
      <BODY>
	<P>This page has frames, but your browser does not support them</P>
      </BODY>
    </NOFRAMES>
  </FRAMESET>
</HTML>
