<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sSkin = getCookie(request, "skin", "xp");

  String gu_bug = request.getParameter("gu_bug");
  String tl_bug = request.getParameter("tl_bug");

  ACLUser oAcl = new ACLUser();
  HashMap oUsr = new HashMap();
  JDCConnection oConn = null;  
  DBSubset oLog = new DBSubset (DB.k_bugs_changelog, DB.nm_column+","+DB.dt_modified+","+DB.tx_oldvalue+","+DB.gu_writer, DB.gu_bug+"=? ORDER BY 2 DESC",10);
  int iLog = 0;

  try {
    oConn = GlobalDBBind.getConnection("bug_changelog");

    iLog = oLog.load(oConn, new Object[]{gu_bug});

    for (int u=0; u<iLog; u++) {
      if (!oLog.isNull(3,u)) {
        if (!oAcl.containsKey(oLog.getString(3,u))) {
          if (oAcl.load(oConn, new Object[]{oLog.getString(3,u)})) {
	    oUsr.put(oLog.getString(3,u), oAcl.getStringNull(DB.tx_nickname,"unknown user"));
          }
        }
      }
    } // next

    oConn.close("bug_changelog");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("bug_changelog");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }  
  if (null==oConn) return;    
  oConn = null;
%>

<HTML>
<HEAD>
  <TITLE>hipergate :: Incident History</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
<HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=tl_bug%></FONT></TD></TR>
  </TABLE>  
  <TABLE BORDER="0" CELLSPACING="1" CELLPADDING="4">
    <TR CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><TD><B>Column</B></TD><TD><B>Date</B></TD><TD><B>Previous Value</B></TD><TD><B>User</B></TD></TR>
<% for (int i=0; i<iLog; i++) { %>
    <TR CLASS="strip<%=String.valueOf(i%2+1)%>">
      <TD CLASS="textplain"><%=oLog.getString(0,i)%></TD>
      <TD CLASS="textplain"><%=oLog.getDateTime(1,i)%></TD>
      <TD CLASS="textplain"><%=oLog.getStringNull(2,i,"null")%></TD>
<%   if (oLog.isNull(3,i)) { %>
      <TD CLASS="textplain"><I>anonymous</I></TD>
<% } else { %>
      <TD CLASS="textplain"><%=oUsr.get(oLog.getString(3,i))%></TD>
<% } %>  
    </TR>
<% } %>    
  </TABLE>
</HTML>