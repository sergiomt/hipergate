<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.hipermail.MailAccount" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

  This library is 7distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);
  
  String id_user = nullif(request.getParameter("id_user"),getCookie(request,"userid",""));
  String gu_account = request.getParameter("gu_account");
  String bo_popup = nullif(request.getParameter("bo_popup"),"false");

  MailAccount oObj = new MailAccount();
  JDCConnection oConn = null;
  DBSubset oTitles = new DBSubset(DB.k_user_mail,DB.tl_account+","+DB.tx_main_email,DB.gu_user+"=?",10);
  int nTitles = 0;
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  String sDefaultIncomingServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "mail.incoming", "");
  String sDefaultOutgoingServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "mail.outgoing", "");
  
  try {
    oConn = GlobalDBBind.getConnection("account_edit");      
    if (gu_account!=null) oObj.load (oConn, new Object[]{gu_account}); 
    nTitles = oTitles.load(oConn, new Object[]{id_user});
    oConn.close("account_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("account_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));  
  }
  if (null==oConn) return;  
  oConn = null;  

  if (!id_user.equals(oObj.getStringNull(DB.gu_user,null)) && !bIsAdmin && gu_account!=null) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Security Exception&desc=It is not allowed to modify this mail account settings&resume=_back"));
    return;
  }  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

			var titles = new Array(<%=(nTitles>0 ? String.valueOf(nTitles) : "")%>);
			var emails = new Array(<%=(nTitles>0 ? String.valueOf(nTitles) : "")%>);
<%    for (int t=0; t<nTitles; t++) {
        out.write("			titles["+String.valueOf(t)+"]=\""+oTitles.getString(0,t).trim()+"\";\n");
        out.write("			emails["+String.valueOf(t)+"]=\""+oTitles.getString(1,t).trim()+"\";\n");
      } // next
%>

      function setDefaults(incprot,incsrvr,incport,incspa,incssl,outprot,outsrvr,outport,outspa,outssl) {
        var frm = document.forms[0];
        frm.incoming_protocol.value = incprot;
        frm.incoming_server.value = incsrvr;
        frm.incoming_port.value = String(incport);
        frm.incoming_spa.checked = incspa;
        frm.incoming_ssl.checked = incssl;
        frm.outgoing_protocol.value = outprot;
        frm.outgoing_server.value = outsrvr;
        frm.outgoing_port.value = String(outport);
        frm.outgoing_spa.checked = outspa;
        frm.outgoing_ssl.checked = outssl;         
      }

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

      	if (frm.tl_account.value.length==0) {
      	  alert ("A name must be given to the mail account");
      	  frm.tl_account.focus();
      	  return false;
      	}
      
      	if (frm.tx_main_email.value.length>0 && !check_email(frm.tx_main_email.value)) {
      	  alert ("Main mail address is not valid");
      	  frm.tx_main_email.focus();
      	  return false;
      	}
      
      	if (frm.tx_reply_email.value.length>0 && !check_email(frm.tx_reply_email.value)) {
      	  alert ("Reply-To mail address is not valid");
      	  frm.tx_reply_email.focus();
      	  return false;
      	}
      	
        if (!isIntValue(frm.incoming_port.value)) {
      	  alert ("In Port is not valid");
      	  frm.incoming_port.focus();
      	  return false;
        }
      
        if (!isIntValue(frm.outgoing_port.value)) {
      	  alert ("Out Port is not valid");
      	  frm.outgoing_port.focus();
      	  return false;
        }

<% if (null==gu_account) { %>
				for (var t=0; t<titles.length; t++) {
					if (ltrim(rtrim(frm.tl_account.value.toLowerCase()))==titles[t].toLowerCase()) {
      	    alert ("Another e-mail account already exists with the same name");
      	    frm.tl_account.focus();
      	    return false;
					}
					if (ltrim(rtrim(frm.tx_main_email.value.toLowerCase()))==emails[t].toLowerCase()) {
      	    alert ("There is already another account associated to the same e-mail "+titles[t]);
      	    frm.tx_main_email.focus();
      	    return false;
					}
				} // next
<% } %>
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  MARGINWIDTH="8">
  <DIV class="cxMnu1" style="width:320px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Mail Account</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="account_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_account" VALUE="<%=nullif(gu_account)%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="bo_test" VALUE="false">
	  <INPUT TYPE="hidden" NAME="bo_popup" VALUE="<%=bo_popup%>">
	  <INPUT TYPE="hidden" NAME="id_user" VALUE="<%=id_user%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <!-- 12. Optional Field -->
          <TR>
            <TD ALIGN="right" WIDTH="128"><FONT CLASS="formplain">Name</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="tl_account" MAXLENGTH="100" SIZE="50" VALUE="<%=oObj.getStringNull(DB.tl_account,"")%>" TITLE="Account descriptive name"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="128"></TD>
            <TD ALIGN="left"><INPUT TYPE="checkbox" NAME="bo_default" VALUE="1" <% if (!oObj.isNull(DB.bo_default)) if (oObj.getShort(DB.bo_default)==(short)1) out.write("CHECKED"); %>><FONT CLASS="formplain">&nbsp;Default Account</FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="128"><FONT CLASS="formplain">e-mail</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_main_email" MAXLENGTH="100" SIZE="50" VALUE="<%=oObj.getStringNull(DB.tx_main_email,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="128"><FONT CLASS="formplain">Reply-To</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_reply_email" MAXLENGTH="100" SIZE="50" VALUE="<%=oObj.getStringNull(DB.tx_reply_email,"")%>"></TD>
          </TR>
<% if (gu_account==null) { %>
          <TR>
            <TD ALIGN="right" WIDTH="128" CLASS="formplain" VALIGN="top">Mail Service</TD>
            <TD ALIGN="left" CLASS="formplain">
              <TABLE>
                <TR>
                  <TD CLASS="formplain"><INPUT TYPE="radio" NAME="mail_service" VALUE="GMail" onclick="setDefaults('pop3','pop.gmail.com',995,true,true,'smtp','smtp.gmail.com',465,true,true)">&nbsp;GMail</TD>
                  <TD CLASS="formplain"><INPUT TYPE="radio" NAME="mail_service" VALUE="Other" onclick="setDefaults('pop3','',110,false,false,'smtp','',25,false,false)" CHECKED="checked">&nbsp;Other</TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
<% } %>          
	  <TR>
	    <TD></TD>
	    <TD>
	      <TABLE CELLPADDING="2">
	        <TR>
	          <TD COLSPAN="2"><FONT CLASS="formstrong">Incoming mail server</FONT></TD>
	        </TR>
	        <TR>
	          <TD>
	            <FONT CLASS="formplain">Protocol:</FONT>
	          </TD>
	          <TD>
	            <INPUT TYPE="text" NAME="incoming_protocol" MAXLENGTH="6" SIZE="6" VALUE="<%=oObj.getStringNull(DB.incoming_protocol,"pop3")%>">
	            &nbsp;&nbsp;&nbsp;&nbsp;
	            <FONT CLASS="formplain">Port:</FONT><INPUT TYPE="text" NAME="incoming_port" MAXLENGTH="5" SIZE="6" VALUE="<% if (oObj.isNull(DB.incoming_port)) out.write("110"); else out.write(String.valueOf(oObj.getShort(DB.incoming_port))); %>">
	          </TD>
	        </TR>
	        <TR>
	          <TD>
	            <FONT CLASS="formplain">Server:</FONT>
	          </TD>
	          <TD>
	            <INPUT TYPE="text" NAME="incoming_server" MAXLENGTH="100" SIZE="36" VALUE="<%=oObj.getStringNull(DB.incoming_server,sDefaultIncomingServer)%>">
	          </TD>
	        </TR>
	        <TR>
	          <TD>
	            <FONT CLASS="formplain">Account:</FONT>
	          </TD>
	          <TD>
	            <INPUT TYPE="text" NAME="incoming_account" MAXLENGTH="100" SIZE="16" VALUE="<%=oObj.getStringNull(DB.incoming_account,oObj.getStringNull(DB.tx_main_email,""))%>">
	            &nbsp;&nbsp;&nbsp;&nbsp;
	            <FONT CLASS="formplain">Password:</FONT><INPUT TYPE="password" NAME="incoming_password" MAXLENGTH="50" SIZE="10" VALUE="<%=oObj.getStringNull(DB.incoming_password,"")%>">
	          </TD>
	        </TR>
	        <TR>
	          <TD COLSPAN="2">
		    <INPUT TYPE="checkbox" NAME="incoming_spa" VALUE="1" <% if (!oObj.isNull(DB.incoming_spa)) if (oObj.getShort(DB.incoming_spa)==(short)1) out.write("CHECKED"); %>>
	            &nbsp;
	            <FONT CLASS="formplain">Use secure authentication (SPA)</FONT>
	          </TD>
	        </TR>
	        <TR>
	          <TD COLSPAN="2">
		    <INPUT TYPE="checkbox" NAME="incoming_ssl" VALUE="1" onclick="document.forms[0].incoming_port.value='995'" <% if (!oObj.isNull(DB.incoming_ssl)) if (oObj.getShort(DB.incoming_ssl)==(short)1) out.write("CHECKED"); %>>
	            &nbsp;
	            <FONT CLASS="formplain">Use secure connection (SSL)</FONT>
	          </TD>
	        </TR>
	      </TABLE>
	    </TD>
	  </TR>
	  <TR>
	    <TD></TD>
	    <TD>
	      <TABLE CELLPADDING="2">
	        <TR>
	          <TD COLSPAN="2"><FONT CLASS="formstrong">Outgoing server</FONT></TD>
	        </TR>
	        <TR>
	          <TD>
	            <FONT CLASS="formplain">Protocol:</FONT>
	          </TD>
	          <TD>
	            <INPUT TYPE="text" NAME="outgoing_protocol" MAXLENGTH="6" SIZE="6" VALUE="<%=oObj.getStringNull(DB.outgoing_protocol,"smtp")%>">
	            &nbsp;&nbsp;&nbsp;&nbsp;
	            <FONT CLASS="formplain">Port:</FONT><INPUT TYPE="text" NAME="outgoing_port" MAXLENGTH="5" SIZE="6" VALUE="<% if (oObj.isNull(DB.outgoing_port)) out.write("25"); else out.write(String.valueOf(oObj.getShort(DB.outgoing_port))); %>">
	          </TD>
	        </TR>
	        <TR>
	          <TD>
	            <FONT CLASS="formplain">Server:</FONT>
	          </TD>
	          <TD>
	            <INPUT TYPE="text" NAME="outgoing_server" MAXLENGTH="100" SIZE="36" VALUE="<%=oObj.getStringNull(DB.outgoing_server,sDefaultOutgoingServer)%>">
	          </TD>
	        </TR>
	        <TR>
	          <TD>
	            <FONT CLASS="formplain">Account:</FONT>
	          </TD>
	          <TD>
	            <INPUT TYPE="text" NAME="outgoing_account" MAXLENGTH="100" SIZE="16" VALUE="<%=oObj.getStringNull(DB.outgoing_account,oObj.getStringNull(DB.tx_main_email,""))%>">
	            &nbsp;&nbsp;&nbsp;&nbsp;
	            <FONT CLASS="formplain">Password:</FONT><INPUT TYPE="password" NAME="outgoing_password" MAXLENGTH="50" SIZE="10" VALUE="<%=oObj.getStringNull(DB.outgoing_password,"")%>">
	          </TD>
	        </TR>
	        <TR>
	          <TD COLSPAN="2">
		    <INPUT TYPE="checkbox" NAME="outgoing_spa" VALUE="1" <% if (!oObj.isNull(DB.outgoing_spa)) if (oObj.getShort(DB.outgoing_spa)==(short)1) out.write("CHECKED"); %>>
	            &nbsp;
	            <FONT CLASS="formplain">Use secure authentication (SPA)</FONT>
	          </TD>
	        </TR>
	        <TR>
	          <TD COLSPAN="2">
		    <INPUT TYPE="checkbox" NAME="outgoing_ssl" VALUE="1" onclick="document.forms[0].outgoing_port.value='465'" <% if (!oObj.isNull(DB.outgoing_ssl)) if (oObj.getShort(DB.outgoing_ssl)==(short)1) out.write("CHECKED"); %>>
	            &nbsp;
	            <FONT CLASS="formplain">Use secure connection (SSL)</FONT>
	          </TD>
	        </TR>
	      </TABLE>
	    </TD>
	  </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">
    	      &nbsp;&nbsp;&nbsp;<INPUT TYPE="submit" ACCESSKEY="t" VALUE="Test" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+t" onclick="document.forms[0].bo_test.value='true';">
    	      &nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="history.back()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
