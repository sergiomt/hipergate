<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.hipermail.MailAccount" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="fldr_combo.jspf" %><%
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

  String sLanguage = getNavigatorLanguage(request);  

  String id_user = getCookie(request,"userid","");
  
  JDCConnection oConn = null;
  DBSubset oAccounts = new DBSubset (DB.k_user_mail,"gu_account,tl_account,tx_main_email,bo_default",DB.gu_user+"=? ORDER BY 1",10);
  int iAccounts = 0;

  String sDefaultIncomingServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "mail.incoming", "");
  String sDefaultOutgoingServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "mail.outgoing", "");

  try {
    oConn = GlobalDBBind.getConnection("account_list");
    iAccounts = oAccounts.load(oConn, new Object[]{id_user});
    if (0==iAccounts) {
      MailAccount oNewAcc = new MailAccount();
      oNewAcc.put(DB.bo_default, (short)1);
      
    }
    oConn.close("account_list");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("account_list");
    oConn = null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" MARGINWIDTH="8" LEFTMARGIN=8">
    <DIV class="cxMnu1" style="width:200px"><DIV class="cxMnu2">
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    </DIV></DIV>
    <FORM METHOD="post" ACTION="account_edit.jsp">

      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="account_edit.jsp" CLASS="linkplain">New</A></TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <BR>

    <TABLE BORDER="0" CELLPADDING="2">
<% for (int a=0; a<iAccounts;a++) { %>
      <TR>
<%      if (oAccounts.getShort(3,a)==(short)1) { %>
        <TD CLASS="strip<%=String.valueOf(a%2+1)%>"><A CLASS="linkplain" HREF="account_edit.jsp?gu_account=<%=oAccounts.getString(0,a)%>"><B><%=oAccounts.getString(1,a)%></B></A></TD>
        <TD CLASS="strip<%=String.valueOf(a%2+1)%>"><I>(<%=oAccounts.getString(2,a)%>)</I></TD>
        <TD CLASS="strip<%=String.valueOf(a%2+1)%>"></TD>
<%      } else { %>
        <TD CLASS="strip<%=String.valueOf(a%2+1)%>"><A CLASS="linkplain" HREF="account_edit.jsp?gu_account=<%=oAccounts.getString(0,a)%>"><%=oAccounts.getString(1,a)%></A></TD>
        <TD CLASS="strip<%=String.valueOf(a%2+1)%>"><I>(<%=oAccounts.getString(2,a)%>)</I></TD>
        <TD CLASS="strip<%=String.valueOf(a%2+1)%>"><A HREF="account_delete.jsp?gu_account=<%=oAccounts.getString(0,a)%>" TITLE="Delete"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete"></A></TD>
<%      } %>
      </TR>
<%  } %>
    </TABLE>
    </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>