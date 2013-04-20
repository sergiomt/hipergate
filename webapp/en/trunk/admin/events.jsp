<%@ page import="java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
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

  final String sLanguage = getNavigatorLanguage(request);  
  final String sSkin = getCookie(request, "skin", "xp");

  final String id_domain = getCookie(request,"domainid","");
  final String gu_workarea = getCookie(request,"workarea","");

  final String PAGE_NAME = "events";

  JDCConnection oConn = null;
  DBSubset oWrkAs = new DBSubset (DB.k_workareas, DB.gu_workarea+","+DB.nm_workarea, DB.id_domain+"=?", 50);
  DBSubset oCmmds = new DBSubset (DB.k_lu_job_commands, DB.id_command+","+DB.tx_command, DB.nm_class+" LIKE 'com.knowgate.scheduler.events.%'", 50);
  DBSubset oApps = new DBSubset (DB.k_apps, DB.id_app+","+DB.nm_app, null, 50);
  DBSubset oEvents = new DBSubset (DB.k_events, DB.id_event+","+DB.bo_active+","+DB.id_command+","+DB.id_app+","+DB.gu_workarea+","+DB.de_event+","+DB.fixed_rate, DB.id_domain+"=? ORDER BY 1", 100);
  int nEvents = 0;
  int iCmmds = 0;
  int nWrkAs = 0;
  int iApps = 0;

  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME,true);
        
    iApps = oApps.load(oConn);

    iCmmds = oCmmds.load(oConn);

		nEvents = oEvents.load(oConn, new Object[]{new Integer(id_domain)});

		nWrkAs = oWrkAs.load(oConn, new Object[]{new Integer(id_domain)});
      
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {  
    if (null!=oConn) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&"+e.getClass().getName()+"=" + e.getMessage() + "&resume=_back"));  
  }
  
  if (null==oConn) return;    
  oConn = null;

%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <%@ include file="../common/header.jspf" %>
  <TABLE>
    <TR>
      <TD>
        <DIV class="cxMnu1" style="width:220px"><DIV class="cxMnu2">
          <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
          <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
        </DIV></DIV>
      </TD>
      <TD CLASS="striptitle"><FONT CLASS="title1">Actions performed upon triggering an event</FONT></TD>
    </TR>
  </TABLE>
  <FORM METHOD="post" ACTION="events_store.jsp" onsubmit="return validate()">
  	<INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
  	<INPUT TYPE="hidden" NAME="nu_events" VALUE="<%=String.valueOf(nEvents)%>">
<%
  for (int e=0; e<nEvents; e++) {
    String s = String.valueOf(e);
    int r;
    if (oEvents.isNull(6,e))
      r = 0;
    else
      r = oEvents.getInt(6,e);
    out.write("<DIV ID=\"div_"+s+"\"><TABLE><TR><TD CLASS=\"textplain\">Active</TD><TD CLASS=\"textplain\">Identifier</TD><TD CLASS=\"textplain\">Work Area</TD><TD CLASS=\"textplain\">Application</TD><TD CLASS=\"textplain\">Command</TD><TD CLASS=\"textplain\">[~Ejecuci&oacute;n Peri&oacute;dica~]</TD><TD CLASS=\"textplain\">Description</TD></TR><TR><TD ALIGN=\"center\" CLASS=\"textplain\"><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"chk_"+s+"\" ");
    if (oEvents.isNull(1,e)) out.write(" CHECKED=\"checked\""); else out.write(oEvents.getShort(1,e)==(short)1 ? " CHECKED=\"checked\"" : "");
    out.write("></TD><TD><INPUT TABINDEX=\"-1\" TYPE=\"text\" MAXLENGTH=\"64\" VALUE=\""+oEvents.getString(0,e)+"\" NAME=\"id_"+s+"\" onfocus=\"document.forms[0].wrk_"+s+".focus()\"></TD><TD><SELECT NAME=\"wrk_"+s+"\">");
    for (int w=0; w<nWrkAs; w++) out.write("<OPTION VALUE=\""+oWrkAs.getString(0,w)+"\">"+oWrkAs.getString(1,w)+"</OPTION>");
    out.write("</SELECT></TD><TD><SELECT NAME=\"app_"+s+"\">");
    for (int a=0; a<iApps; a++) {
      out.write("<OPTION VALUE=\""+String.valueOf(oApps.getInt(0,a))+"\" ");
      if (!oEvents.isNull(3,e)) if (oEvents.getInt(3,e)==oApps.getInt(0,a)) out.write(" SELECTED=\"selected\"");
      out.write(">"+oApps.getString(1,a)+"</OPTION>");
    }
    out.write("</SELECT></TD><TD><SELECT NAME=\"cmd_"+s+"\">");    
    for (int c=0; c<iCmmds; c++) out.write("<OPTION VALUE=\""+oCmmds.getString(0,c)+"\" "+(oCmmds.getString(0,c).equals(oEvents.getString(2,e)) ? "SELECTED=\"selected\"" : "")+">"+oCmmds.getString(1,c)+"</OPTION>");
    out.write("</SELECT></TD>");
    out.write("<TD><SELECT NAME=\"rt_"+s+"\"><OPTION VALUE=\"0\""+(r==0 ? " SELECTED" : "")+">[~Sin ejecuci&oacute;n peri&oacute;dica~]</OPTION><OPTION VALUE=\"1\""+(r==1 ? " SELECTED" : "")+">[~Cada segundo~]</OPTION><OPTION VALUE=\"10\""+(r==10 ? " SELECTED" : "")+">[~Cada 10 segundos~]</OPTION><OPTION VALUE=\"60\""+(r==60 ? " SELECTED" : "")+">[~Cada minuto~]</OPTION><OPTION VALUE=\"300\""+(r==300 ? " SELECTED" : "")+">[~Cada 5 minutos~]</OPTION><OPTION VALUE=\"600\""+(r==600 ? " SELECTED" : "")+">[~Cada 10 minutos~]</OPTION><OPTION VALUE=\"3600\""+(r==3600 ? " SELECTED" : "")+">[~Cada hora~]</OPTION><OPTION VALUE=\"86400\""+(r==86400 ? " SELECTED" : "")+">[~Cada dia~]</OPTION></SELECT></TD>");
    out.write("<TD><INPUT TYPE=\"text\" MAXLENGTH=\"254\" SIZE=\"50\" NAME=\"de_"+s+"\" VALUE=\""+oEvents.getStringNull(5,e,"")+"\"></TD>");
    out.write("</TR></TABLE></DIV>\n");
  } // next
  out.write("<DIV><TABLE><TR><TD CLASS=\"textplain\">Active</TD><TD CLASS=\"textplain\">Identifier</TD><TD CLASS=\"textplain\">Work Area</TD><TD CLASS=\"textplain\">Application</TD><TD CLASS=\"textplain\">Command</TD><TD CLASS=\"textplain\">[~Ejecuci&oacute;n Peri&oacute;dica~]</TD><TD CLASS=\"textplain\">Description</TD></TR><TR><TD ALIGN=\"center\"><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"chk\" CHECKED=\"checked\"></TD><TD><INPUT TYPE=\"text\" MAXLENGTH=\"64\" VALUE=\"\" NAME=\"id\" STYLE=\"text-transform:lowercase\"></TD><TD><SELECT NAME=\"wrk\"><OPTION VALUE=\"\">All</OPTION>");
  for (int w=0; w<nWrkAs; w++) out.write("<OPTION VALUE=\""+oWrkAs.getString(0,w)+"\" "+(gu_workarea.equals(oWrkAs.getString(0,w)) ? "SELECTED=\"selected\"" : "")+">"+oWrkAs.getString(1,w)+"</OPTION>");
  out.write("</SELECT></TD><TD><SELECT NAME=\"app\">");
  for (int a=0; a<iApps; a++) out.write("<OPTION VALUE=\""+oApps.getString(0,a)+"\">"+oApps.getString(1,a)+"</OPTION>");
  out.write("</SELECT></TD><TD><SELECT NAME=\"cmd\">");
  for (int c=0; c<iCmmds; c++) out.write("<OPTION VALUE=\""+oCmmds.getString(0,c)+"\">"+oCmmds.getString(1,c)+"</OPTION>");  
  out.write("</SELECT></TD>");
  out.write("<TD><SELECT NAME=\"rt\"><OPTION VALUE=\"0\">[~Sin ejecuci&oacute;n peri&oacute;dica~]</OPTION><OPTION VALUE=\"1\">[~Cada segundo~]</OPTION><OPTION VALUE=\"10\">[~Cada 10 segundos~]</OPTION><OPTION VALUE=\"60\">[~Cada minuto~]</OPTION><OPTION VALUE=\"300\">[~Cada 5 minutos~]</OPTION><OPTION VALUE=\"600\">[~Cada 10 minutos~]</OPTION><OPTION VALUE=\"3600\">[~Cada hora~]</OPTION><OPTION VALUE=\"86400\">[~Cada dia~]</OPTION></SELECT></TD>");
  out.write("<TD><INPUT TYPE=\"text\" MAXLENGTH=\"254\" SIZE=\"50\" NAME=\"de\"></TD>");
  out.write("</TR></TABLE></DIV>\n");
%>
  <INPUT TYPE="submit" CLASS="pushbutton" VALUE="Save">
  </FORM>
</BODY>
</HTML>
