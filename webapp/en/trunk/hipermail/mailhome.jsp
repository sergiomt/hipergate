<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.hipergate.Category,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  String sSkin = getCookie(request, "skin", "xp");

  String id_user = getCookie(request,"userid","");
  String id_domain = getCookie(request,"domainid","0");
  String gu_workarea = getCookie(request,"workarea",""); 
  
  String sLuceneIndex = Environment.getProfileVar(GlobalDBBind.getProfileName(), "luceneindex", "");
  
  String screen_width = request.getParameter("screen_width");

  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  ACLUser oMe = new ACLUser();
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  StringBuffer oFoldersBuffer = new StringBuffer();
  boolean bHasAccounts = false;

  try {
    oConn = GlobalDBBind.getConnection("mailhome");

    oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_user_mail+" WHERE "+DB.gu_user+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, id_user);
    oRSet = oStmt.executeQuery();
    bHasAccounts = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (oMe.load(oConn, new Object[]{id_user}) && bHasAccounts) {    
      paintFolders (oConn, oMe.getMailRoot(oConn), sLanguage, "", oFoldersBuffer);
    }

    oConn.close("mailhome");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("mailhome");
    oConn = null;    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
    
      function setCombos() {
        var frm = window.document.forms[0];

	      sortCombo(frm.sel_folder);
      
	      frm.screen_width.value = screen.width;
	
      } // setCombos()
	
      function validate() {
        var frm = window.document.forms[0];

      	if (!isDate(frm.dt_before.value, "d") && frm.dt_before.value.length>0) {
      	  alert ("Start date is not valid");
      	  return false;	  
      	}
      
      	if (!isDate(frm.dt_after.value, "d") && frm.dt_after.value.length>0) {
      	  alert ("End date is not valid");
      	  return false;	  
      	}
      		
      	frm.gu_folder.value = getCombo(frm.sel_folder);
      	
      	if ((frm.gu_folder.value.length==0) && (frm.from.value.length==0) && (frm.to.value.length==0) && (frm.subject.value.length==0) &&
      	    (frm.dt_before.value.length==0) && (frm.dt_after.value.length==0)) {
      	  alert ("You must set at least one search criteria");
      	  return false;	  	  
      	}
        
        return true;
      } // validate;	
    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" MARGINWIDTH="8" LEFTMARGIN=8" onLoad="setCombos()">
    <FORM METHOD="post" ACTION="msg_search.jsp" onsubmit="return validate()">
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="screen_width">

      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bHasAccounts) { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Compose New Message"></TD>
        <TD VALIGN="middle"><A HREF="msg_new_f.jsp?folder=drafts" TARGET="_blank" CLASS="linkplain">Compose New Message</A></TD>
<% } else { %>
        <TD COLSPAN="2"></TD>
<% } %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/hipermail/accounts.gif" WIDTH="20" HEIGHT="17" BORDER="0" ALT="Manage Accounts"></TD>
        <TD VALIGN="middle"><A HREF="account_list.jsp" CLASS="linkplain">Manage Accounts</A></TD>
        <TD VALIGN="bottom"></TD>
        <TD VALIGN="middle"></TD>
        <TD VALIGN="bottom"></TD>
        <TD VALIGN="bottom"></TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top Menu -->
      <BR>
<% if (bHasAccounts) { %>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR><TD></TD><TD><FONT CLASS="formstrong">Find messages</FONT></TD></TR>
          <TR><TD><FONT CLASS="formplain">Carpeta:</FONT></TD><TD><INPUT TYPE="hidden" NAME="gu_folder"><SELECT NAME="sel_folder"><OPTION VALUE=""></OPTION><% out.write(oFoldersBuffer.toString()); %></SELECT></TD></TR>
          <!--<TR><TD></TD><TD><INPUT TYPE="checkbox" NAME="chk_subfolders"><FONT CLASS="formplain">Include subfolders</FONT></TD></TR>-->
	  <TR><TD><FONT CLASS="formplain">De:</FONT></TD><TD><INPUT TYPE="text" NAME="from" SIZE="40"></TD></TR>
	  <TR><TD><FONT CLASS="formplain">To:</FONT></TD><TD><INPUT TYPE="text" NAME="to" SIZE="40"></TD></TR>
	  <TR><TD><FONT CLASS="formplain">Asunto:</FONT></TD><TD><INPUT TYPE="text" NAME="subject" SIZE="40"></TD></TR>
	  <!--<TR><TD><FONT CLASS="formplain">Texto:</FONT></TD><TD><INPUT TYPE="text" NAME="body" SIZE="40"></TD></TR>-->
	  <TR><TD><FONT CLASS="formplain">Entre:</FONT></TD>
	      <TD>
	        <INPUT TYPE="text" NAME="dt_before" MAXLENGTH="10" SIZE="10">
                <A HREF="javascript:showCalendar('dt_before')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View calendar"></A>
		&nbsp;&nbsp;<FONT CLASS="formplain">y</FONT>&nbsp;&nbsp;
	        <INPUT TYPE="text" NAME="dt_after" MAXLENGTH="10" SIZE="10">
                <A HREF="javascript:showCalendar('dt_after')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View calendar"></A>
	      </TD>
	  </TR>
<% if (sLuceneIndex.length()>0) { %>
	  <TR><TD><FONT CLASS="formplain">Texto:</FONT></TD><TD><INPUT TYPE="text" NAME="body" SIZE="40"></TD></TR>
<% } %>  
	  <TR><TD></TD><TD ALIGN="center"><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Find"></TD></TR>
	</TABLE>
      </TD></TR>
    </TABLE>
<% } // fi (bHasAccounts) %>
    </FORM>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>