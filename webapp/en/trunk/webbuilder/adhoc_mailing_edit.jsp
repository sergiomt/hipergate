<%@ page import="java.util.ArrayList,java.io.ByteArrayOutputStream,java.io.FileInputStream,java.io.File,java.io.PrintWriter,java.io.IOException,java.net.URL,java.net.URLDecoder,java.sql.SQLException,org.w3c.tidy.Tidy,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.hipergate.*,com.knowgate.hipermail.AdHocMailing,com.knowgate.hipermail.MailAccount,com.knowgate.hipermail.HtmlMimeBodyPart,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  final int MarketingTools = 18;

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "adhoc_mailing_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_mailing = request.getParameter("gu_mailing");
  String pg_mailing = request.getParameter("pg_mailing");

  String id_user = getCookie(request, "userid", "");

	ArrayList<String> aLinksWarnings = null;
	ArrayList<String> aHrefUrls = null;
  URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;
  String sTargetDir = null;
	String sWrkGetDir = null;
	String sHtmlFile = null;
	String sPlainFile = null;
  String[] aTidyOut = null;
  String[] aFiles = null;
  
  String sDefaultFrom = "", sDefaultReply = "", sDefaultDisplay = "";

  AdHocMailing oObj = new AdHocMailing();
  DBSubset oAtc = new DBSubset(DB.v_activity_locat, DB.gu_product + "," + DB.nm_product + "," + DB.gu_location + "," + DB.pg_product,
                               DB.gu_activity+" IN (SELECT "+DB.gu_activity+" FROM "+DB.k_activities+" WHERE "+DB.gu_mailing+"=?)", 10);
  int iAtc = 0;
  int nSent = 0;

  String sStatusLookUp = "";
    
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

		oConn.setReadOnly(true);

    sStatusLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_adhoc_mailings_lookup, gu_workarea, DB.id_status, sLanguage);
    
    if (null!=gu_mailing) {
      oObj.load(oConn, new Object[]{gu_mailing});
      if ((iAppMask & (1<<MarketingTools))!=0)
			  iAtc = oAtc.load(oConn, new Object[]{gu_mailing});
			nSent = DBCommand.queryCount(oConn, "*", DB.k_job_atoms_archived, DB.gu_job+" IN (SELECT "+DB.gu_job+" FROM "+DB.k_jobs+" WHERE "+DB.gu_job_group+"='"+gu_mailing+"')");
    }
    
    else if (null!=pg_mailing) if (pg_mailing.length()>0 && !pg_mailing.equalsIgnoreCase("null")) oObj.load(oConn, Integer.parseInt(pg_mailing), gu_workarea);

		if (!oObj.isNull(DB.pg_mailing)) {
      sTargetDir = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Hipermail" + File.separator + "html" + File.separator + Gadgets.leftPad(String.valueOf(oObj.getInt(DB.pg_mailing)), '0', 5);
      sWrkGetDir = oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()))+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+request.getParameter("gu_workarea")+"/apps/Hipermail/html/"+Gadgets.leftPad(String.valueOf(oObj.getInt(DB.pg_mailing)),'0',5)+"/";
    }

		if (oObj.isNull(DB.tx_email_from)) {
			MailAccount oMac = MailAccount.forUser(oConn, id_user);
			if (oMac!=null) {
			  sDefaultFrom = oMac.getStringNull(DB.tx_main_email,"");
			  sDefaultReply = oMac.getStringNull(DB.tx_reply_email,"");
			  sDefaultDisplay = oMac.getStringNull(DB.tl_account,"");
			}
		}

    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.dispose(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Ad hoc e-mailing</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

<% if (sTargetDir!=null) {
     aFiles = new File(sTargetDir).list();
     if (aFiles!=null) {
       out.write("var jsFiles = new Array(");
       for (int f=0; f<aFiles.length; f++) {
        out.write((f==0 ? "" : ",")+"\""+aFiles[f]+"\"");
        if (aFiles[f].endsWith(".htm") || aFiles[f].endsWith(".html") || aFiles[f].endsWith(".HTM") || aFiles[f].endsWith(".HTML")) {
          sHtmlFile = aFiles[f];
          try {
            ByteArrayOutputStream oNull = new ByteArrayOutputStream();
          	ByteArrayOutputStream oErrs = new ByteArrayOutputStream();
            Tidy oTdy = new Tidy();
						oTdy.setErrout(new PrintWriter(oErrs,true));
						FileInputStream oFins = new FileInputStream(Gadgets.chomp(sTargetDir,File.separator)+sHtmlFile);            
            oTdy.parse(oFins,oNull);
					  aTidyOut = oErrs.toString().split("\n");
						if (aTidyOut.length<=5) aTidyOut=null;
            oFins.close();
            oErrs.close();
            oNull.close();
          } catch (Exception ignore) { }
        }
        if (aFiles[f].endsWith(".txt") || aFiles[f].endsWith(".TXT"))
          sPlainFile = aFiles[f];   
       }
       out.write(");\n");       
     }

		 if (null!=sHtmlFile) {
		   HtmlMimeBodyPart oHtmBdy = new HtmlMimeBodyPart(new FileSystem().readfilestr(Gadgets.chomp(sTargetDir,File.separator)+sHtmlFile,null),"UTF-8");
		   aLinksWarnings = oHtmBdy.extractLocalUrls();
       aHrefUrls = oHtmBdy.extractHrefs();
     }
%>

      function deleteFile(f) {
        if (window.confirm("Are you sure that you want to delete the file? "+jsFiles[f])) {
          document.getElementById("d"+String(f)).style.display=document.getElementById("f"+String(f)).style.display="none";
  				var req = createXMLHttpRequest();
  				var prm = "gu_workarea=<%=gu_workarea%>&gu_mailing=<%=gu_mailing%>&nu_mailing=<%=Gadgets.leftPad(String.valueOf(oObj.getInt(DB.pg_mailing)),'0',5)%>&nm_file="+jsFiles[f];
  				req.open("POST","adhoc_file_delete.jsp",true);
          req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
          req.setRequestHeader("Content-length", prm.length);
  				req.setRequestHeader("Connection", "close");
          req.send(prm);
        }
      }
<% } %>
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_adhoc_mailings_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------


      function validate() {
        var frm = window.document.forms[0];

	      frm.id_status.value = getCombo(frm.sel_status);
        
        frm.tx_email_from.value=frm.tx_email_from.value.toLowerCase();

        if (frm.tx_email_from.value.length>0) {
          if (!check_email(frm.tx_email_from.value)) {
            alert ("From e-mail is not valid");
            frm.tx_email_from.focus();
            return false;
          }
        }

        frm.tx_email_reply.value=frm.tx_email_reply.value.toLowerCase();

        if (frm.tx_email_reply.value.length>0) {
          if (!check_email(frm.tx_email_reply.value)) {
            alert ("Reply-To e-mail is not valid");
            frm.tx_email_reply.focus();
            return false;
          }
        }

				if (getCombo(frm.sel_year)!="" || getCombo(frm.sel_month)!="" || getCombo(frm.sel_day)!="") {
      	  frm.dt_execution.value = getCombo(frm.sel_year)+"-"+getCombo(frm.sel_month)+"-"+getCombo(frm.sel_day);
          if (!isDate(frm.dt_execution.value,"d")) {
            alert ("Dend date is not valid");
            return false;
          } 				
				} else {
					frm.dt_execution.value = "";
				}
      
        return true;
      } // validate;

      // ----------------------------------------------------

      function listStats() {
	      document.location = "../jobs/job_followup_stats_xls.jsp?gu_job_group=<%=gu_mailing%>";
	    } // listStats

      // ------------------------------------------------------

			function sendMail() {
				if (validate())
		      document.location = "list_choose.jsp?gu_pageset=<%=gu_mailing%>&id_command=SEND";
		  }

      function toogleWarnings() {
        document.getElementById("warnings_text").style.display = (document.getElementById("warnings_text").style.display=="block" ? "none" : "block");
      }
      
      // ------------------------------------------------------

			var req = false;
			var hrf = null;
			var urls = new Array();
			
			function notifyUrlAvailability() {
      	if (req.readyState == 4) {
          if (req.status == 200) {
						if (req.responseText!="200") {
						  document.getElementById("warnings_label").innerHTML = "<A ID=\"warnings\"><IMG SRC=\"../images/images/warn16.gif\" WIDTH=\"16\" HEIGHT=\"16\" ALT=\"Warnings\" BORDER=\"0\"></A>&nbsp;<A HREF=\"#warnings\" onclick=\"toogleWarnings()\">WARNINGS</A>";
						  document.getElementById("warnings_text").innerHTML = document.getElementById("warnings_text").innerHTML + hrf + " " + req.responseText + " The URL is not available<BR>";
						} // fi
				    if (urls.length>0)
				      checkUrlAvailability();
				    else
				    	req = false;
				  } // fi
        } // fi
      } // notifyUrlAvailability

			function checkUrlAvailability() {
			  if (urls.length>0) { 
			    hrf = urls.pop();
			    req = createXMLHttpRequest();
	        req.onreadystatechange = notifyUrlAvailability;
	        req.open("GET", "../common/url_availability.jsp?u="+hrf, true);
	        req.send(null);
	      }
			} 

      // ------------------------------------------------------

      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_status,"<% out.write(oObj.getStringNull(DB.id_status,"")); %>");
<%      if (!oObj.isNull(DB.dt_execution)) { %>
          setCombo(frm.sel_year,"<% out.write(String.valueOf(oObj.getDate(DB.dt_execution).getYear()+1900)); %>");
          setCombo(frm.sel_month,"<% out.write(Gadgets.leftPad(String.valueOf(oObj.getDate(DB.dt_execution).getMonth()+1),'0',2)); %>");
          setCombo(frm.sel_day,"<% out.write(Gadgets.leftPad(String.valueOf(oObj.getDate(DB.dt_execution).getDate()),'0',2)); %>");			
<%      }

				if (null!=sHtmlFile) {
				  if (aHrefUrls.size()>0) {
				    for (String h : aHrefUrls) {
				      if (h.startsWith("http://") || h.startsWith("https://"))
				        out.write("          urls.push(\""+Gadgets.URLEncode(h)+"\");\n");
				    }
				  out.write("          checkUrlAvailability();\n");
				  }
				}
%>
        return true;
      } // setCombos
    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Ad hoc e-mailing <% if (!oObj.isNull(DB.pg_mailing)) out.write(String.valueOf(oObj.getInt(DB.pg_mailing))); %></FONT></TD></TR>
  </TABLE>
  <FORM METHOD="post" ACTION="adhoc_mailing_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_mailing" VALUE="<%=oObj.getStringNull("gu_mailing","")%>">
    <INPUT TYPE="hidden" NAME="pg_mailing" VALUE="<% if (!oObj.isNull(DB.pg_mailing)) out.write(String.valueOf(oObj.getInt(DB.pg_mailing))); %>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="440">
            	<TABLE>
            	  <TR>
            	  	<TD><INPUT TYPE="text" NAME="nm_mailing" MAXLENGTH="30" SIZE="30" VALUE="<%=oObj.getStringNull(DB.nm_mailing,"")%>"></TD>
<% if (sHtmlFile!=null) { %>            	  	
            	  	<TD><IMG SRC="../images/images/viewtxt.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Preview"></TD>
            	  	<TD><A HREF="adhoc_mailing_preview_f.jsp?gu_workarea=<%=gu_workarea%>&gu_mailing=<%=gu_mailing%>" CLASS="linkplain">Preview</A></TD>
            	  	<TD><IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1" BORDER="0" ALT=""></TD>
            	  	<TD><IMG SRC="../images/images/mailto16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Test"></TD>
            	  	<TD><A HREF="adhoc_mailing_test.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_mailing=<%=oObj.getString("gu_mailing")%>&pg_mailing=<%=String.valueOf(oObj.getInt("pg_mailing"))%>&nm_html=<%=Gadgets.URLEncode(sHtmlFile)%>&nm_plain=<%=Gadgets.URLEncode(sPlainFile==null ? "" : sPlainFile)%>" CLASS="linkplain">Test E-Mailing</A></TD>
<% } %>
							  </TR>
						  </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formplain">Send Date:</TD>
            <TD ALIGN="left" WIDTH="440" CLASS="formplain">
              <INPUT TYPE="hidden" NAME="dt_execution" VALUE="<% out.write(oObj.isNull(DB.dt_execution) ? "" : oObj.getDateShort(DB.dt_execution)); %>">
              <SELECT CLASS="combomini" NAME="sel_day"><OPTION VALUE=""></OPTION><% for (int d=1; d<=31; d++) out.write("<OPTION VALUE=\""+Gadgets.leftPad(String.valueOf(d),'0',2)+"\">"+Gadgets.leftPad(String.valueOf(d),'0',2)+"</OPTION>"); %></SELECT>
              <SELECT CLASS="combomini" NAME="sel_month"><OPTION VALUE=""></OPTION><OPTION VALUE="01">Enero</OPTION><OPTION VALUE="02">Febrero</OPTION><OPTION VALUE="03">Marzo</OPTION><OPTION VALUE="04">Abril</OPTION><OPTION VALUE="05">Mayo</OPTION><OPTION VALUE="06">Junio</OPTION><OPTION VALUE="07">Julio</OPTION><OPTION VALUE="08">Agosto</OPTION><OPTION VALUE="09">Septiembre</OPTION><OPTION VALUE="10">Octubre</OPTION><OPTION VALUE="11">Noviembre</OPTION><OPTION VALUE="12">Diciembre</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_year"><OPTION VALUE=""></OPTION><OPTION VALUE="2010">2010</OPTION><OPTION VALUE="2011">2011</OPTION><OPTION VALUE="2012">2012</OPTION><OPTION VALUE="2013">2013</OPTION><OPTION VALUE="2014">2014</OPTION></SELECT>
              <DIV STYLE="display:none">&nbsp;<INPUT TYPE="checkbox" NAME="bo_reminder" VALUE="1" <% if (!oObj.isNull(DB.bo_reminder)) out.write(oObj.getShort("bo_reminder")==0 ? "" : "CHECKED"); %>>&nbsp;Con recordatorio</DIV>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong">Urgent:</TD>
            <TD ALIGN="left" WIDTH="440" CLASS="formplain">
            	<INPUT TYPE="checkbox" NAME="bo_urgent" VALUE="1" <% if (oObj.isNull(DB.bo_urgent)) out.write(""); else out.write(oObj.getShort(DB.bo_urgent)!=0 ? "CHECKED" : ""); %>>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong">Parts:</TD>
            <TD ALIGN="left" WIDTH="440" CLASS="formplain">
            	<INPUT TYPE="checkbox" NAME="bo_html_part" VALUE="1" <% if (oObj.isNull(DB.bo_html_part)) out.write("CHECKED"); else out.write(oObj.getShort(DB.bo_html_part)!=0 ? "CHECKED" : ""); %>>&nbsp;HTML
            	&nbsp;&nbsp;&nbsp;<INPUT TYPE="checkbox" NAME="bo_plain_part" VALUE="1" <% if (oObj.isNull(DB.bo_plain_part)) out.write("CHECKED"); else out.write(oObj.getShort(DB.bo_plain_part)!=0 ? "CHECKED" : ""); %>>&nbsp;Plain text:
            </TD>
          </TR>
          <INPUT TYPE="hidden" NAME="bo_attachments" VALUE="1">
<!--          
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong">Inline Images:</TD>
            <TD ALIGN="left" WIDTH="440" CLASS="formplain"><INPUT TYPE="radio" NAME="bo_attachments" VALUE="1" <% if (oObj.isNull(DB.bo_attachments)) out.write("CHECKED"); else if (oObj.getShort(DB.bo_attachments)!=(short)0) out.write("CHECKED"); %>>&nbsp;Attach images at message<BR/><INPUT TYPE="radio" NAME="bo_attachments" VALUE="0" <% if (!oObj.isNull(DB.bo_attachments)) if (oObj.getShort(DB.bo_attachments)==(short)0) out.write("CHECKED"); %>>&nbsp;Load imagen on demand from server when message is opened</TD>
          </TR>
-->
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formplain">Status:</FONT></TD>
            <TD ALIGN="left" WIDTH="440">
              <INPUT TYPE="hidden" NAME="id_status">
              <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Status List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">From e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="tx_email_from" MAXLENGTH="254" SIZE="50" STYLE="text-transform:lowercase" VALUE="<%=oObj.getStringNull(DB.tx_email_from,sDefaultFrom)%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Reply-To e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="tx_email_reply" MAXLENGTH="254" SIZE="50" STYLE="text-transform:lowercase" VALUE="<%=oObj.getStringNull(DB.tx_email_reply,sDefaultReply)%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Display-Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="nm_from" MAXLENGTH="254" SIZE="50" VALUE="<%=oObj.getStringNull(DB.nm_from,sDefaultDisplay)%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Subject:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="tx_subject" MAXLENGTH="254" SIZE="50" VALUE="<%=oObj.getStringHtml(DB.tx_subject,"")%>"></TD>
          </TR>
<%    if (iAtc>0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160" VALIGN="top"><FONT CLASS="formplain">Activity Files:</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <TABLE SUMMARY="Activity Attachments">
              <% for (int a=0; a<iAtc; a++) {
                   out.write("                <TR><TD><DIV ID=\"a"+String.valueOf(iAtc)+"\"><A CLASS=\"linksmall\" HREF=\"../servlet/HttpBinaryServlet?id_product="+oAtc.getString(0,a)+"&id_user="+id_user+"\" onContextMenu=\"return false;\">"+oAtc.getString(1,a)+"</A></DIV></TD></TR>\n");
                 }
              %>
              </TABLE>
            </TD>
          </TR>
<%    } %>
<!--          
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Allow only</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="tx_allow_regexp" MAXLENGTH="254" SIZE="50" VALUE="<%=oObj.getStringNull(DB.tx_allow_regexp,"")%>">&nbsp;<A HREF="#" CLASS="linkplain" onclick="document.forms[0].tx_allow_regexp.value='[\\w\\x2E_-]+@((?:yahoo)|(?:terra)|(?:hotmail)|(?:gmail))\\x2E\\D{2,4}'">&larr;&nbsp;WebMails:</A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="200"><FONT CLASS="formstrong">Deny:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="tx_deny_regexp" MAXLENGTH="254" SIZE="50" VALUE="<%=oObj.getStringNull(DB.tx_deny_regexp,"")%>">&nbsp;<A HREF="#" CLASS="linkplain" onclick="document.forms[0].tx_deny_regexp.value='[\\w\\x2E_-]+@((?:yahoo)|(?:terra)|(?:hotmail)|(?:gmail))\\x2E\\D{2,4}'">&larr;&nbsp;WebMails:</A></TD>
          </TR>
-->
<% if (sTargetDir!=null) { %>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong" VALIGN="top">Attached Files:</TD>
            <TD ALIGN="left" WIDTH="500">
              <TABLE BORDER="0">
							  <TR>
							    <TD ALIGN="center"><A HREF="wb_file_upload.jsp?gu_microsite=adhoc&gu_pageset=<%=gu_mailing%>&caller=adhoc_mailing_edit.jsp&title=Newsletter" CLASS="linkplain"><IMG SRC="../images/images/up18x22.gif" WIDTH="18" HEIGHT="22" BORDER="0" ALT="Upload"></A></TD>
							  	<TD><A HREF="wb_file_upload.jsp?gu_microsite=adhoc&gu_pageset=<%=gu_mailing%>&pg_mailing=<% if (!oObj.isNull(DB.pg_mailing)) out.write(String.valueOf(oObj.getInt(DB.pg_mailing))); %>&doctype=newsletter&caller=adhoc_mailing_edit.jsp&title=Newsletter" CLASS="linkplain">Upload files</A></TD>
							    <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
							    <TD ALIGN="center">
<% if (aFiles!=null) { if (aFiles.length>0) { %>
							    	<A HREF="wb_zipfile_download.jsp?gu_microsite=adhoc&gu_pageset=<%=gu_mailing%>" TARGET="_blank" CLASS="linkplain"><IMG SRC="../images/images/downzip18x22.gif" WIDTH="18" HEIGHT="22" BORDER="0" ALT="Download ZIP"></A>
<% } } %>
							    </TD>
							  	<TD>
<% if (aFiles!=null) { if (aFiles.length>0) { %>
							  		<A HREF="wb_zipfile_download.jsp?gu_microsite=adhoc&gu_pageset=<%=gu_mailing%>" TARGET="_blank" CLASS="linkplain">Download files inside a ZIP</A>
<% } } %>
							  	</TD>
							  </TR>
              </TABLE>
              <TABLE BORDER="0">
          		  <TR>
          		    <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>File</B></TD>
          		    <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          		    <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
							  </TR>
<% 
   if (aFiles!=null) {
     for (int f=0; f<aFiles.length; f++) {
       String sStrip = String.valueOf((f%2)+1);
		   out.write("<TR><TD CLASS=\"strip"+sStrip+"\"><DIV ID=\"f"+String.valueOf(f)+"\"><A HREF=\""+sWrkGetDir+aFiles[f]+"\" CLASS=\"linkplain\">"+aFiles[f]+"</A></DIV></TD><TD CLASS=\"strip"+sStrip+"\"><DIV ID=\"d"+String.valueOf(f)+"\"><A HREF=\"#\" onclick=\"deleteFile("+String.valueOf(f)+")\" TITLE=\"Eliminar Archivo\"><IMG SRC=\"../images/images/hipermail/deletemsgs.gif\" WIDTH=\"23\" HEIGHT=\"17\" BORDER=\"0\" ALT=\"Delete\"></A></TD>");
      if (aFiles[f].endsWith(".htm") || aFiles[f].endsWith(".html") || aFiles[f].endsWith(".txt") ||
          aFiles[f].endsWith(".HTM") || aFiles[f].endsWith(".HTML") || aFiles[f].endsWith(".txt"))
		    out.write("<TD CLASS=\"strip"+sStrip+"\"><DIV ID=\"e"+String.valueOf(f)+"\"><A HREF=\"adhoc_file_edit.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_mailing="+gu_mailing+"&nm_file="+Gadgets.URLEncode(aFiles[f])+"\" CLASS=\"linkplain\"><IMG SRC=\"../images/images/webbuilder/htmldocedit.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Edit HTML\"></A></DIV></TD>");
      else
      	out.write("<TD CLASS=\"strip"+sStrip+"\"><DIV ID=\"e"+String.valueOf(f)+"\"></DIV></TD>");
      out.write("</TR>\n");
     } // next
   } // fi
%>
							</TABLE>
					  </TD>
					</TR>
          <TR>
            <TD ALIGN="right" WIDTH="200" CLASS="formstrong" VALIGN="top"><DIV id="warnings_label"><% if (sHtmlFile!=null) if (aLinksWarnings.size()>0 || aTidyOut!=null) out.write("<A ID=\"warnings\"><IMG SRC=\"../images/images/warn16.gif\" WIDTH=\"16\" HEIGHT=\"16\" ALT=\"Warnings\" BORDER=\"0\"></A>&nbsp;<A HREF=\"#warnings\" onclick=\"toogleWarning()\">WARNINGS</A>"); %></DIV></TD>
            <TD ALIGN="left" WIDTH="500" CLASS="textsmall"><DIV id="warnings_text" STYLE="display:none"><%

   if (sHtmlFile!=null) {
		 for (String w : aLinksWarnings)
		   out.write(Gadgets.replace(Gadgets.HTMLEncode(w.indexOf("href=")>0 ? w.substring(w.indexOf("href=")+5).replace('"',' ') : w.indexOf("src=")>0 ? w.substring(w.indexOf("src=")+4).replace('"',' ') : w ), gu_workarea, "&hellip;") +" Points to a local resource<BR>");
		 if (aTidyOut!=null) {
		   for (int t=2; t<aTidyOut.length-3; t++) {
		    if (!aTidyOut[t].trim().endsWith("lacks \"summary\" attribute")) out.write(Gadgets.HTMLEncode(aTidyOut[t])+"<br/>");
		   }
		 }
   }
%></DIV></TD>
          </TR>
<% } %>
          <TR>
<% if (nSent>0) { %>
          <TR>
            <TD ALIGN="right"><IMG SRC="../images/images/jobs/statistics16.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Statistics"></TD>
            <TD><A HREF="#" CLASS="linkplain" onclick="listStats()">Show Statistics</A></TD>
          </TR>
<% } %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
<% if (sTargetDir!=null) { %>
              &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="m" VALUE="Send" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+m" onclick="sendMail()">&nbsp;
<% } %>
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
