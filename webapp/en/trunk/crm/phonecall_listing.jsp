<%@ page import="java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*  
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  

  final String PAGE_NAME = "phonecall_listing";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_contact = request.getParameter("gu_contact");
  String gu_oportunity = request.getParameter("gu_oportunity");

  String id_user = getCookie(request, "userid", "");
    
  JDCConnection oConn = null;
  DBSubset oCalls = new DBSubset (DB.k_phone_calls,
  					    						      DB.gu_phonecall+","+DB.tp_phonecall+","+DB.id_status+","+DB.dt_start+","+DB.dt_end+","+DB.gu_user+","+
  					    						      DB.gu_contact+","+DB.gu_bug+","+DB.tx_phone+","+DB.contact_person+","+DB.tx_comments+","+DB.gu_oportunity,
  					    						      DB.gu_workarea+"=? AND (("+DB.gu_contact+"=? AND "+DB.tp_phonecall+"='R') OR "+DB.gu_oportunity+"=?) "+
 					    						        "ORDER BY "+DB.dt_start+" DESC", 20);
  int nCalls = 0;
  HashMap oUsers = new HashMap(13);
  boolean bIsGuest = true;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

	  nCalls = oCalls.load(oConn, new Object[]{gu_workarea,gu_contact,gu_oportunity});
	  for (int c=0; c<nCalls; c++) {
	    if (!oCalls.isNull(5,c)) {
	      if (!oUsers.containsKey(oCalls.get(5,c))) {
	        oUsers.put(oCalls.get(5,c), new ACLUser(oConn, oCalls.getString(5,c)));
	      } // fi
	    } // fi
	  } // next
	  
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: List of calls for an opportunity</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE SUMMARY="Title" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">List of calls for an opportunity</FONT></TD></TR>
  </TABLE>
  <BR/>
  <% if (!bIsGuest) { %>
    <IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Call">&nbsp;<A CLASS="linkplain" HREF="phonecall_record.jsp?id_domain=<%=id_domain%>&n_domain=<%=Gadgets.URLEncode(n_domain)%>&gu_workarea=<%=gu_workarea%>&gu_user=<%=id_user%>&gu_oportunity=<%=gu_oportunity%>&gu_contact=<%=gu_contact%>">New Call</A>
  <% } %>
  <BR/><BR/>
  <TABLE SUMMARY="Calls List" CELLSPACING="1" CELLPADDING="2">
    <TR>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Number</B></TD>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Date</B></TD>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
      <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Comments</B></TD>
    </TR>
<% for (int i=0; i<nCalls; i++) {
    String sStrip = String.valueOf((i%2)+1); %>
    <TR HEIGHT="16">
      <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="20" ALIGN="center"><IMG SRC="../images/images/addrbook/<% out.write(oCalls.getString(1,i).equals("R") ? "callin.gif" : "callout.gif"); %>" BORDER="0" ALT="<% out.write(oCalls.getString(1,i).equals("R") ? "Received Call" : "Sent Call"); %>"></TD>
      <TD CLASS="strip<% out.write (sStrip); %>"><% out.write(oCalls.getStringNull(8,i,"")); %></TD>
      <TD CLASS="strip<% out.write (sStrip); %>"><% out.write(oCalls.getDateTime(3,i)); %></TD>
      <TD CLASS="strip<% out.write (sStrip); %>"><% if (!oCalls.isNull(5,i)) { ACLUser oUsr = (ACLUser) oUsers.get(oCalls.get(5,i)); out.write(oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")); } %></TD>
      <TD CLASS="strip<% out.write (sStrip); %>"><% out.write(oCalls.getStringNull(9,i,"")); %></TD>
      <TD CLASS="strip<% out.write (sStrip); %>"><% out.write(oCalls.getStringNull(10,i,"")); %></TD>
    </TR>
<% } %>
  </TABLE>
  <BR/><BR/>
  <FORM><INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()"></FORM>
</BODY>
</HTML>