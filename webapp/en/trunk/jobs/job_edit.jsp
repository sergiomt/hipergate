<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.scheduler.Job" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  String tl_job = null;
  boolean bo_attachments = true;
  
  DBSubset oJobs = null;
  int iJobCount = 0;
      
  Statement oStmt;
  ResultSet oRSet;
  JDCConnection oConn = GlobalDBBind.getConnection("jobedit");  

  boolean bIsGuest = true;
    
  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oJobs = new DBSubset (DB.k_lu_job_commands, DB.tx_command, DB.id_command + "='" + id_command + "'", 10);      				 
    iJobCount = oJobs.load (oConn);
    
    if (id_command.equals("MAIL")) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT " + DB.nm_pageset + " FROM " + DB.k_pagesets + " WHERE " + DB.gu_pageset + "='" + gu_pageset + "'");
      oRSet.next();
      tl_job = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
    } else if (id_command.equals("SEND")) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT " + DB.nm_mailing + "," + DB.bo_attachments + " FROM " + DB.k_adhoc_mailings + " WHERE " + DB.gu_mailing + "='" + gu_pageset + "'");
      oRSet.next();
      tl_job = oRSet.getString(1);
      bo_attachments = (oRSet.getShort(2)!=(short) 0);
      oRSet.close();
      oStmt.close();    
    }

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
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
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
          frm.action = "job_store.jsp";
    
    	  frm.tx_parameters.value += ",bo_attachimages:" + (frm.attachimages[0].checked ? "1" : "0");

    	  frm.tx_parameters.value += ",bo_webbeacon:" + (frm.webbeacon.checked ? "1" : "0");

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
              <INPUT TYPE="text" NAME="dt_execution" MAXLENGTH="20" SIZE="20" VALUE="As soon as possible">
              <A HREF="javascript:showCalendar('dt_execution')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>          
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Images</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <INPUT TYPE="radio" NAME="attachimages" VALUE="1" <%=(bo_attachments ? "CHECKED" : "")%>><FONT CLASS="formplain">&nbsp;images will be attached with message.</FONT>
              <BR>
              <FONT CLASS="textsmall"><I>with this option messages will take more time and bandwith to be send but will display faster on the recipient</I></FONT>
              <BR>
              <INPUT TYPE="radio" NAME="attachimages" VALUE="0" <%=(bo_attachments ? "" : "CHECKED")%>><FONT CLASS="formplain">&nbsp;images will be links to the web server.</FONT>              
              <BR>
              <FONT CLASS="textsmall"><I>with this option, messages will be sent faster but they will take longer to display at recipient</I></FONT>
<% if (id_command.equals("SEND")) { %>
              <BR>
              <INPUT TYPE="radio" NAME="attachimages" VALUE="2"><FONT CLASS="formplain">&nbsp;attached files for thick e-mail clients and server online for common WebMails</FONT>              
              <BR>
              <FONT CLASS="textsmall"><I>this option is a mixture of the two previous ones optimizing the e-mail format for each user-agent</I></FONT>
<% } %>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110" CLASS="formplain">Web Beacon:</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
              <INPUT TYPE="checkbox" VALUE="1" NAME="webbeacon" CHECKED="checked">&nbsp;Add a hidden image for tracing readed e-mails
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
