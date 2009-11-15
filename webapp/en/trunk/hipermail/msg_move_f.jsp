<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/nullif.jspf" %><%
  String sFolder = nullif(request.getParameter("folder"));
  String sTarget = nullif(request.getParameter("destination"));
  String sAction = nullif(request.getParameter("perform"));
  String sItems  = nullif(request.getParameter("checkeditems"));
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 FRAMESET//EN" "http://www.w3.org/TR/REC-html40/FRAMESET.dtd">  
<HTML>
  <HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  </HEAD>
  <FRAMESET ROWS="48,*">
    <FRAME NAME="movebar" MARGINWIDTH="0" MARGINHEIGHT="0" FRAMEBORDER="0" SCROLLING="NO" SRC="msg_move_bar.htm">
    <FRAME NAME="moveexec" MARGINWIDTH="0" MARGINHEIGHT="0" FRAMEBORDER="0" SCROLLING="NO" SRC="msg_move_exec.jsp?folder=<%=sFolder%>&destination=<%=sTarget%>&perform=<%=sAction%>&checkeditems=<%=sItems%>">
  </FRAMESET>
  <NOFRAMES>
      <BODY>
	<P>Esta p&aacute;gina usa marcos, pero su explorador no los admite.</P>
      </BODY>
  </NOFRAMES>
  </FRAMESET>
</HTML>
