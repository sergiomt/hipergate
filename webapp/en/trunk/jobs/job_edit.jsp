<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Job" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><% 
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

  String id_domain = getCookie (request, "domainid", null);
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = getCookie(request,"workarea","");

  String sLanguage = getNavigatorLanguage(request);
    
  String id_command = request.getParameter("id_command");
  String gu_pageset = request.getParameter("gu_pageset");
  int pg_mailing;
  String tl_job = null;
  boolean bo_attachments = true;
  
  DBSubset oJobs = null;
  int iJobCount = 0;
      
  Statement oStmt;
  ResultSet oRSet;
  JDCConnection oConn = GlobalDBBind.getConnection("jobedit");  

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;
  String sTargetDir = null;

  boolean bIsGuest = true;
  boolean bHasHtmlPart = false;
  boolean bHasPlainPart = false;
      
  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oJobs = new DBSubset (DB.k_lu_job_commands, DB.tx_command, DB.id_command + "='" + id_command + "'", 10);      				 
    iJobCount = oJobs.load (oConn);
    
    if (id_command.equals("MAIL")) {

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT " + DB.nm_pageset + " FROM " + DB.k_pagesets + " WHERE " + DB.gu_pageset + "='" + gu_pageset + "'");
      oRSet.next();
      tl_job = Gadgets.ASCIIEncode(oRSet.getString(1)).toLowerCase();
      oRSet.close();
      oStmt.close();

  		sTargetDir = Gadgets.chomp(GlobalDBBind.getProperty("workareasput",sDefWrkArPut),File.separator) + gu_workarea + File.separator + "apps" + File.separator + "Mailwire" + File.separator + "html" + File.separator + gu_pageset + File.separator;

    } else if (id_command.equals("SEND")) {

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT " + DB.nm_mailing + "," + DB.bo_attachments + "," + DB.pg_mailing + " FROM " + DB.k_adhoc_mailings + " WHERE " + DB.gu_mailing + "='" + gu_pageset + "'");
      oRSet.next();
      tl_job = Gadgets.ASCIIEncode(oRSet.getString(1)).toLowerCase();
      bo_attachments = (oRSet.getShort(2)!=(short) 0);
      pg_mailing = oRSet.getInt(3);
      oRSet.close();
      oStmt.close();    

      sTargetDir = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Hipermail" + File.separator + "html" + File.separator + Gadgets.leftPad(String.valueOf(pg_mailing), '0', 5);
    } // fi (id_command)

    String[] aFiles = new File(sTargetDir).list();
    if (aFiles!=null) {
      for (int f=0; f<aFiles.length; f++) {
        String sFileName = aFiles[f].toLowerCase();
        if (sFileName.endsWith(".htm") || sFileName.endsWith(".html"))
          bHasHtmlPart = true;   
        if (sFileName.endsWith(".txt"))
          bHasPlainPart = true;               
      } // next
    } // fi

    oConn.close("jobedit");

  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("jobedit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }

  if (null==oConn) return;
  
  oConn = null;
  
  if (0==iJobCount) {    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Tipo de Accion no Valida&desc=No se encontro la definicion de la accion " + id_command + "&resume=_close"));  
    return;
  }
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Schedule Task (2/2)</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function showCalendar(ctrl) {       
        var dtnw = new Date();
        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
        document.getElementById("id_hour").style.visibility="visible";
        document.getElementById("id_minute").style.visibility="visible";
      } // showCalendar()

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
	      var cmd = getURLParam("id_command");
	      
	      if (!isDate(frm.dt_execution.value, "d") && frm.dt_execution.value.length>0 && frm.dt_execution.value!="As soon as possible") {
	        alert ("Execution date is not valid");
	        return false;	  
	      }
	      else if (frm.dt_execution.value=="As soon as possible") {
	        frm.dt_execution.value = "ASAP";
	      }
        
	      if (frm.tl_job.value.length==0) {
	        alert ("Task description is mandatory");
	        return false;
	      }
	      
	      if (hasForbiddenChars(frm.tl_job.value)) {
	        alert ("Task description contains invalid characters");
	        return false;
	      }
	                
        if (cmd=="MAIL" || cmd=="FAX" || cmd=="FTP")
          frm.action = "../webbuilder/wb_document_build_f.jsp";
        else
          frm.action = "job_confirm.jsp";
    
    	  frm.tx_parameters.value += ",bo_attachimages:" + (frm.attachimages[0].checked ? "1" : "0");

    	  frm.tx_parameters.value += ",bo_webbeacon:" + (frm.webbeacon.checked ? "1" : "0");

    	  frm.tx_parameters.value += ",bo_clickthrough:" + (frm.clickthrough.checked ? "1" : "0");

        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  >
  <TABLE CELLSPACING="0" CELLPADDING="0" WIDTH="100%">
    <TR><TD COLSPAN="2"><IMG SRC="../images/images/spacer.gif" WIDTH="1" HEIGHT="4" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Schedule Task</FONT></TD><TD CLASS="striptitle" align="right"><FONT CLASS="title1">(2 / 2)</FONT></TD></TR>
  </TABLE>  
  <CENTER>
  <FORM NAME="frmJobEdit" METHOD="post" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<% out.write(id_domain); %>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<% out.write(gu_workarea); %>">
    <INPUT TYPE="hidden" NAME="gu_pageset" VALUE="<% out.write(gu_pageset); %>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<% out.write(id_user); %>">    
    <INPUT TYPE="hidden" NAME="gu_job" VALUE="<% out.write(Gadgets.generateUUID()); %>">
    <INPUT TYPE="hidden" NAME="gu_job_group" VALUE="<% out.write(Gadgets.generateUUID()); %>">
    <INPUT TYPE="hidden" NAME="id_command" VALUE="<% out.write(id_command); %>">
    <INPUT TYPE="hidden" NAME="tx_parameters" VALUE="<% out.write(request.getParameter("parameters")); %>">
    <INPUT TYPE="hidden" NAME="id_status" VALUE="<% out.write(String.valueOf(Job.STATUS_PENDING)); %>">
    <INPUT TYPE="hidden" NAME="tx_job" VALUE="<% out.write(oJobs.getString(0,0)); %>">
    <INPUT TYPE="hidden" NAME="target_dir" VALUE="<%=sTargetDir%>">
    <BR/>
    <INPUT TYPE="hidden" NAME="doctype" VALUE="newsletter">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Action:</FONT></TD>
            <TD class="formplain" ALIGN="left" WIDTH="480"><% out.write(oJobs.getString(0,0)); %></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD class="formplain" ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="tl_job"  MAXLENGTH="100" SIZE="70" VALUE="<% out.write(tl_job); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Date:</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <INPUT TYPE="text" NAME="dt_execution" MAXLENGTH="20" SIZE="20" VALUE="As soon as possible" onblur="if (this.value!='As soon as possible') { document.getElementById('id_hour').style.visibility='visible'; document.getElementById('id_minute').style.visibility='visible'; } ">
              <A HREF="javascript:showCalendar('dt_execution')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
              <SELECT ID="id_hour" NAME="sel_hour" STYLE="visibility:hidden"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT ID="id_minute" NAME="sel_minute" STYLE="visibility:hidden"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>
            </TD>
          </TR>          
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Images</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <INPUT TYPE="radio" NAME="attachimages" VALUE="1" <%=(bo_attachments || !bHasHtmlPart ? "CHECKED" : "")%>><FONT CLASS="formplain">&nbsp;images will be attached with message.</FONT>
              <BR>
              <FONT CLASS="textsmall"><I>with this option messages will take more time and bandwith to be send but will display faster on the recipient</I></FONT>
              <BR>
              <INPUT TYPE="radio" NAME="attachimages" VALUE="0" <%=(bo_attachments || !bHasHtmlPart ? "" : "CHECKED")%> <%=(bHasHtmlPart ? "" : "DISABLED")%>><FONT CLASS="formplain">&nbsp;images will be links to the web server.</FONT>              
              <BR>
              <FONT CLASS="textsmall"><I>with this option, messages will be sent faster but they will take longer to display at recipient</I></FONT>
              <BR>
              <INPUT TYPE="radio" NAME="attachimages" VALUE="2" <%=(bHasHtmlPart ? "" : "DISABLED")%>><FONT CLASS="formplain">&nbsp;attached files for thick e-mail clients and server online for common WebMails</FONT>              
              <BR>
              <FONT CLASS="textsmall"><I>this option is a mixture of the two previous ones optimizing the e-mail format for each user-agent</I></FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formplain">Web Beacon:</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
              <INPUT TYPE="checkbox" VALUE="1" NAME="webbeacon" <%=bHasHtmlPart ? "CHECKED=\"checked\"" : "DISABLED"%>>&nbsp;Add a hidden image for tracing readed e-mails
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formplain">Click through metter:</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
              <INPUT TYPE="checkbox" VALUE="1" NAME="clickthrough" <%=bHasHtmlPart ? "" : "DISABLED"%>>&nbsp;Measure links click through
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"></TD>
          </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
    <HR>
    <CENTER>
      <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" TITLE="ALT+c" onclick="window.close()">
      &nbsp;&nbsp;
<% if (bIsGuest) { %>
      <INPUT TYPE="button" ACCESSKEY="f" VALUE="Finish" CLASS="pushbutton" TITLE="ALT+f" onclick="alert('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>
      <INPUT TYPE="submit" ACCESSKEY="f" VALUE="Finish" CLASS="pushbutton" TITLE="ALT+f">
<% } %>
    </CENTER>                 
  </FORM>
  </CENTER>
</BODY>
</HTML>
