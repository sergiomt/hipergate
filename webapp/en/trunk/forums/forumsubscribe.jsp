<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.forums.NewsGroup,com.knowgate.forums.Subscription" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String id_user = request.getParameter("id_user");
  String gu_newsgrp = request.getParameter("gu_newsgrp");
  String tp_subscrip = String.valueOf(Subscription.GROUP_NONE);

  ACLUser oUser = new ACLUser();
  NewsGroup oNGrp = new NewsGroup();
  Subscription oSubs = new Subscription();
  String sLGrp = "";
  boolean bSubscribed = false;
  
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection("forumsubscribe");  

	  oUser.load(oConn, new Object[]{id_user});
	  
	  oNGrp.load(oConn, new Object[]{gu_newsgrp});
	  
	  sLGrp = oNGrp.getLabel(oConn, sLanguage);

	  bSubscribed = oSubs.load(oConn, new Object[]{gu_newsgrp, id_user});

	  if (bSubscribed) {
	    if (!oSubs.isNull(DB.tp_subscrip))
	    	tp_subscrip = String.valueOf(oSubs.getShort(DB.tp_subscrip));
	  }
			  
	  if (oSubs.isNull(DB.id_status)) {
	    bSubscribed = false;
	    oSubs.replace(DB.id_status, (short)0);
	  } else {
      bSubscribed = (oSubs.getShort(DB.id_status)!=(short)0);
    }
    
    oConn.close("forumsubscribe");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("forumsubscribe");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Example Form</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      
      function validate() {
        var frm = window.document.forms[0];

				frm.tx_email.value = frm.tx_email.value.toLowerCase();
				if (!check_email(frm.tx_email.value)) {
				  alert ("e-mail address is not valid");
				  frm.tx_email.focus();
				  return false;
				}
        
        return true;
      } // validate

      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.id_msg_type,"<% out.write(oSubs.getStringNull(DB.id_msg_type,"TXT")); %>");

        return true;
      } // setCombos

    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE SUMMARY="Form Title" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit subscription</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="forumsubscribe_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_newsgrp" VALUE="<%=gu_newsgrp%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="tp_subscrip" VALUE="<%=tp_subscrip%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" CLASS="formstrong">Forum</TD>
            <TD ALIGN="left" CLASS="formplain"><%=sLGrp%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">e-mail</TD>
            <TD ALIGN="left" CLASS="formplain"><INPUT TYPE="text" NAME="tx_email" MAXLENGTH="100" SIZE="40" TABINDEX="-1" onfocus="document.forms[0].id_msg_type.focus()" STYLE="text-transform:lowercase" VALUE="<%=oSubs.getStringNull(DB.tx_email,oUser.getString(DB.tx_main_email))%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Format</TD>
            <TD ALIGN="left" CLASS="formplain"><SELECT NAME="id_msg_type"><OPTION VALUE="TXT" SELECTED>Text</OPTION><OPTION VALUE="HTM" SELECTED>HTML</OPTION></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><INPUT TYPE="radio" NAME="id_status" VALUE="0" <%=oSubs.getShort(DB.id_status)==(short)0 ? "CHECKED" : ""%>></TD>
            <TD ALIGN="left" CLASS="formplain">Do not receive any e-mail</TD>
          </TR>
          <TR>
            <TD ALIGN="right"><INPUT TYPE="radio" NAME="id_status" VALUE="1" <%=oSubs.getShort(DB.id_status)==(short)1 ? "CHECKED" : ""%>></TD>
            <TD ALIGN="left" CLASS="formplain">Receive all messages by e-mail</TD>
          </TR>
          <TR>
            <TD ALIGN="right"><INPUT TYPE="radio" NAME="id_status" VALUE="2" <%=oSubs.getShort(DB.id_status)==(short)2 ? "CHECKED" : ""%>></TD>
            <TD ALIGN="left" CLASS="formplain">Receive only messages from my threads</TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
