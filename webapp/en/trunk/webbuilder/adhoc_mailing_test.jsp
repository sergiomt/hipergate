<%@ page import="java.util.Properties,java.util.Vector,java.io.File,java.io.IOException,java.net.URL,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.hipermail.AdHocMailing,com.knowgate.dataxslt.Page,com.knowgate.dataxslt.PageSet,com.knowgate.dataxslt.db.PageSetDB,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "adhoc_mailing_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  String id_user = getCookie (request, "userid", null);  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_mailing = request.getParameter("gu_mailing");
  String pg_mailing = request.getParameter("pg_mailing");

  URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas" + File.separator;
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;

  String sStorageRoot	 = Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");

  String sOutputPathHtml = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Mailwire" + File.separator + "html" + File.separator + gu_mailing + File.separator;
	
  String sBasePath = null;
	String sBaseHref = null;
	String sHtmlFile = null;
  String[] aFiles = null;
  
  ACLUser oMe = new ACLUser();
  AdHocMailing oAdm = new AdHocMailing();
  PageSetDB oPgs = new PageSetDB();
        
  JDCConnection oConn = null;
  DBSubset oAccs = new DBSubset (DB.k_user_mail, DB.gu_account+","+DB.tl_account+","+DB.tx_main_email+","+DB.bo_default,
  															 DB.gu_user+"=? ORDER BY 3 DESC", 10);
  int iAccs = 0;
  int iDocType = 0;

  Properties UserProperties = new Properties();
  UserProperties.put("domain",   id_domain);
  UserProperties.put("workarea", gu_workarea);
  UserProperties.put("pageset",  gu_mailing);
  
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

    iAccs = oAccs.load(oConn, new Object[]{id_user});
    
    if (oAdm.load(oConn, new Object[]{gu_mailing})) {
			iDocType = 21;
			
      sBasePath = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Hipermail" + File.separator + "html" + File.separator + Gadgets.leftPad(String.valueOf(oAdm.getInt(DB.pg_mailing)), '0', 5);
      sBaseHref = oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()))+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+gu_workarea+"/apps/Hipermail/html/"+Gadgets.leftPad(String.valueOf(oAdm.getInt(DB.pg_mailing)),'0',5);

    } else if (oPgs.load(oConn, new Object[]{gu_mailing})) {
			iDocType = 13;
			
      sBasePath = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Mailwire" + File.separator + "html" + File.separator + gu_mailing;
      sBaseHref = oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()))+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+gu_workarea+"/apps/Mailwire/html/"+gu_mailing;

      PageSet oPageSet = new PageSet (sStorageRoot + oPgs.getString(DB.path_metadata), sStorageRoot + oPgs.getString(DB.path_data));
      Vector vPages = oPageSet.buildSite(sStorageRoot, sOutputPathHtml, Environment.getProfile(GlobalDBBind.getProfileName()), UserProperties);
      int iSize = vPages.size();
      for (int p=0; p<iSize; p++) {
        Page oPage = (Page) vPages.get(p);
        oPgs.setPage(oConn, oPage.guid(), p+1, oPage.getTitle(), oPage.filePath());
      } // next

			oPgs.put(DB.tx_subject,"Test "+oPgs.getString(DB.nm_pageset));

			if (iAccs>0) {
				oPgs.put(DB.tx_email_from,oAccs.getString(2,0));
				oPgs.put(DB.tx_email_reply,oAccs.getString(2,0));
				oPgs.put(DB.nm_from,oAccs.getString(1,0));
			} else {
			  oMe.load(oConn, new Object[]{id_user});
				oPgs.put(DB.tx_email_from,oMe.getString(DB.tx_main_email));
				oPgs.put(DB.tx_email_reply,oMe.getString(DB.tx_main_email));
				oPgs.put(DB.nm_from,oMe.getString(DB.nm_user)+" "+oMe.getString(DB.tx_surname1));
			}    
  } else {
    throw new SQLException("No pageset nor adhoc mailing found with GUID "+gu_mailing);
  }
    	
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  oConn = null;
  
  DBPersist oObj = (21==iDocType ? oAdm : oPgs);
 
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Test of ad-hoc e-mailing</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      function validate() {
        var frm = window.document.forms[0];

	      if (frm.tx_recipient1.value.length>0) {
	        if (check_email(frm.tx_recipient1.value)) {
	          frm.recipients.value = frm.tx_recipient1.value;
	        } else {
	        	alert ("Recipient's e-mail is not valid");
	        	frm.tx_recipient1.focus();
	          return false;
	        }
	      }

	      if (frm.tx_recipient2.value.length>0) {
	        if (check_email(frm.tx_recipient2.value)) {
	          frm.recipients.value += (frm.recipients.value.length>0 ? "," : "") + frm.tx_recipient2.value;
	        } else {
	        	alert ("Recipient's e-mail is not valid");
	        	frm.tx_recipient2.focus();
	          return false;
	        }
	      }

	      if (frm.tx_recipient3.value.length>0) {
	        if (check_email(frm.tx_recipient3.value)) {
	          frm.recipients.value += (frm.recipients.value.length>0 ? "," : "") + frm.tx_recipient3.value;
	        } else {
	        	alert ("Recipient's e-mail is not valid");
	        	frm.tx_recipient3.focus();
	          return false;
	        }
	      }

	      if (frm.tx_recipient4.value.length>0) {
	        if (check_email(frm.tx_recipient4.value)) {
	          frm.recipients.value += (frm.recipients.value.length>0 ? "," : "") + frm.tx_recipient4.value;
	        } else {
	        	alert ("Recipient's e-mail is not valid");
	        	frm.tx_recipient4.focus();
	          return false;
	        }
	      }

	      if (frm.tx_recipient5.value.length>0) {
	        if (check_email(frm.tx_recipient5.value)) {
	          frm.recipients.value += (frm.recipients.value.length>0 ? "," : "") + frm.tx_recipient5.value;
	        } else {
	        	alert ("Recipient's e-mail is not valid");
	        	frm.tx_recipient5.focus();
	          return false;
	        }
	      }

				if (frm.recipients.value.length==0) {
	        alert ("At least one recipient is required for the test");
				  return false;				
				}
				
				if (frm.gu_account.selectedIndex<=0) {
	        alert ("An origin account must be selected");
				  frm.gu_account.focus();
				  return false;								
				}
        return true;
      } // validate;

    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Test of ad-hoc e-mailing</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="adhoc_mailing_send.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_mailing" VALUE="<%=gu_mailing%>">
    <INPUT TYPE="hidden" NAME="doc_type" VALUE="<%=String.valueOf(iDocType)%>">
    <INPUT TYPE="hidden" NAME="base_path" VALUE="<%=sBasePath%>">
    <INPUT TYPE="hidden" NAME="base_href" VALUE="<%=sBaseHref%>">
    <INPUT TYPE="hidden" NAME="html_file" VALUE="<%=request.getParameter("nm_html")%>">
    <INPUT TYPE="hidden" NAME="plain_file" VALUE="<%=request.getParameter("nm_plain")%>">
    <INPUT TYPE="hidden" NAME="nm_mailing" VALUE="<%=oObj.getStringNull(DB.nm_mailing,"")%>">
    <INPUT TYPE="hidden" NAME="tx_subject" VALUE="<%=oObj.getStringNull(DB.tx_subject,"")%>">
    <INPUT TYPE="hidden" NAME="tx_email_from" VALUE="<%=oObj.getStringNull(DB.tx_email_from,"")%>">
    <INPUT TYPE="hidden" NAME="tx_email_reply" VALUE="<%=oObj.getStringNull(DB.tx_email_reply,oObj.getStringNull(DB.tx_email_from,""))%>">
    <INPUT TYPE="hidden" NAME="recipients" VALUE="">
    <INPUT TYPE="hidden" NAME="nm_from" VALUE="<%=oObj.getStringNull(DB.nm_from,"")%>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong">Name:</TD>
            <TD ALIGN="left" WIDTH="440" CLASS="formplain"><%=oObj.getStringNull(DB.nm_mailing,"")%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong">Inline Images:</TD>
            <TD ALIGN="left" WIDTH="440" CLASS="formplain"><INPUT TYPE="radio" NAME="bo_attachments" VALUE="1" <% if (oObj.isNull(DB.bo_attachments)) out.write("CHECKED"); else if (oObj.getShort(DB.bo_attachments)!=(short)0) out.write("CHECKED"); %>>&nbsp;Attach images at message<BR/><INPUT TYPE="radio" NAME="bo_attachments" VALUE="0" <% if (!oObj.isNull(DB.bo_attachments)) if (oObj.getShort(DB.bo_attachments)==(short)0) out.write("CHECKED"); %>>&nbsp;Load imagen on demand from server when message is opened</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong">SMTP Account:</TD>
            <TD ALIGN="left" WIDTH="440">
            	<SELECT NAME="gu_account"><OPTION VALUE=""></OPTION><% for (int a=0; a<iAccs; a++) out.write("<OPTION VALUE=\""+oAccs.getString(0,a)+"\">"+oAccs.getString(1,a)+"&nbsp;&lt;"+oAccs.getString(2,a)+"&gt;</OPTION>"); %></SELECT>
            	&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New">&nbsp;<A HREF="../hipermail/account_edit.jsp?bo_popup=true&id_user=<%=id_user%>" CLASS="linkplain">New</A>
            	</TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">From e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="500" CLASS="formplain"><%=oObj.getStringNull(DB.tx_email_from,"")%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">E-mail Reply-To:</FONT></TD>
            <TD ALIGN="left" WIDTH="500" CLASS="formplain"><%=oObj.getStringNull(DB.tx_email_reply,"")%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Display-Name</FONT></TD>
            <TD ALIGN="left" WIDTH="500" CLASS="formplain"><%=oObj.getStringNull(DB.nm_from,"")%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Subject:</FONT></TD>
            <TD ALIGN="left" WIDTH="500" CLASS="formplain"><%=oObj.getStringNull(DB.tx_subject,"")%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong" VALIGN="top">Recipients:</TD>
            <TD ALIGN="left" WIDTH="500">
            	<TABLE>
            	  <TR><TD><INPUT TYPE="text" NAME="tx_recipient1" MAXLENGTH="100" SIZE="50" /></TD></TR>
            	  <TR><TD><INPUT TYPE="text" NAME="tx_recipient2" MAXLENGTH="100" SIZE="50" /></TD></TR>
            	  <TR><TD><INPUT TYPE="text" NAME="tx_recipient3" MAXLENGTH="100" SIZE="50" /></TD></TR>
            	  <TR><TD><INPUT TYPE="text" NAME="tx_recipient4" MAXLENGTH="100" SIZE="50" /></TD></TR>
            	  <TR><TD><INPUT TYPE="text" NAME="tx_recipient5" MAXLENGTH="100" SIZE="50" /></TD></TR>
            	</TABLE>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Send" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.history.back()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
