<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%
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
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_job = request.getParameter("gu_job");
  String gu_workarea = getCookie(request,"workarea","");
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Schedule Task</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
   <!--
      function showCalendar(ctrl) {
        var dtnw = new Date();
        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

   // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var dte = rtrim(ltrim(frm.dt_execution.value));
        
        if (dte!="Lo antes posible" && dte!="As soon as posible" && !isDate(dte,"d")) {        
          alert ("Specified date is not valid");
          return false;
        }
        
        return true;
      } // validate;
      
   // ------------------------------------------------------

   //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">Schedule Task</FONT></TD></TR></TABLE>
  <FONT class="formplain">Set a date for executing task</FONT>
  <FORM NAME="frmJobEdit" METHOD="post" ACTION="job_update.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_job" VALUE="<%=gu_job%>">
    <TABLE CLASS="formback" WIDTH="100%">
      <TR>
       <TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR><TD colspan="2" ALIGN="center" class="formstrong">Update scheduled execution date<BR><BR></TD></TR>
          <TR><TD ALIGN="center" colspan="2" class="formplain">Date:&nbsp;<INPUT TYPE="text" NAME="dt_execution" MAXLENGTH="20" SIZE="20" VALUE="Lo antes posible"><A HREF="javascript:showCalendar('dt_execution')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A></TD></TR>
          <TR><TD COLSPAN="2"><HR></TD></TR>
          <TR><TD COLSPAN="2" ALIGN="center"><INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()"><BR><BR></TD>
        </TABLE>
       </TD>
      </TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>