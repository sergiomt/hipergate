<%@ page import="java.util.Date,java.util.HashMap,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "phonecall_report";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sLanguage = getNavigatorLanguage(request);
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
  
  String gu_workarea = nullif(request.getParameter("gu_workarea"), getCookie (request, "workarea", null));
  Timestamp dt_from = new Timestamp(oFmt.parse(request.getParameter("dt_from")+" 00:00:00").getTime());
  Timestamp dt_to = new Timestamp(oFmt.parse(request.getParameter("dt_to")+" 23:59:59").getTime());
  String gu_campaign = nullif(request.getParameter("gu_campaign"));
    
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  int nSent = 0;
  int nReceived = 0;
  int nOprts = 0;
  StringBuffer oByStatus = new StringBuffer();
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);
    if (gu_campaign.length()==0)
      oStmt = oConn.prepareStatement("SELECT "+DB.tp_phonecall+","+"COUNT("+DB.tp_phonecall+") FROM "+DB.k_phone_calls+" WHERE "+DB.gu_workarea+"=? AND "+DB.dt_start+" BETWEEN ? AND ? GROUP BY "+DB.tp_phonecall);
	  else
      oStmt = oConn.prepareStatement("SELECT p."+DB.tp_phonecall+","+"COUNT(p."+DB.tp_phonecall+") FROM "+DB.k_phone_calls+" p,"+DB.k_oportunities +" o WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND o."+DB.gu_campaign+"='"+gu_campaign+"' AND p."+DB.gu_workarea+"=? AND p."+DB.dt_start+" BETWEEN ? AND ? GROUP BY "+DB.tp_phonecall);
	  oStmt.setString(1, gu_workarea);
	  oStmt.setTimestamp(2, dt_from);
	  oStmt.setTimestamp(3, dt_to);
	  oRSet = oStmt.executeQuery();
	  while(oRSet.next()) {
	    String sTpCall = oRSet.getString(1);
	    if (!oRSet.wasNull()) {
	      if (sTpCall.equals("S"))
	        nSent = oRSet.getInt(2);
	      else if (sTpCall.equals("R"))
	        nReceived = oRSet.getInt(2);
	    }
	  } // wend
	  oRSet.close();
	  oStmt.close();
	  
    if (gu_campaign.length()==0)
      oStmt = oConn.prepareStatement("SELECT o."+DB.id_status+",COUNT(o."+DB.gu_oportunity+") FROM "+DB.k_oportunities+" o WHERE EXISTS (SELECT NULL FROM "+DB.k_phone_calls+" p WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND p."+DB.gu_workarea+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?) GROUP BY "+DB.id_status);
	  else
      oStmt = oConn.prepareStatement("SELECT o."+DB.id_status+",COUNT(o."+DB.gu_oportunity+") FROM "+DB.k_oportunities+" o WHERE o."+DB.gu_campaign+"='"+gu_campaign+"' AND EXISTS (SELECT NULL FROM "+DB.k_phone_calls+" p WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND p."+DB.gu_workarea+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?) GROUP BY "+DB.id_status);
	  oStmt.setString(1, gu_workarea);
	  oStmt.setTimestamp(2, dt_from);
	  oStmt.setTimestamp(3, dt_to);
	  oRSet = oStmt.executeQuery();
	  while(oRSet.next()) {
	    String sStatus = DBLanguages.getLookUpTranslation(oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_status, sLanguage, oRSet.getString(1));
	    if (null==sStatus) sStatus = oRSet.getString(1);	    
	    nOprts += oRSet.getInt(2);
	    oByStatus.append("<TR><TD CLASS=\"textplain\">"+sStatus+"</TD><TD CLASS=\"textplain\">"+String.valueOf(oRSet.getInt(2))+"</TD></TR>");
	  } // wend
	  oRSet.close();
	  oStmt.close();
	  
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close(PAGE_NAME);
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }  
  if (null==oConn) return;    
  oConn = null;

%>
<HTML>
<HEAD>
  <TITLE>hipergate :: [~Efectividad del telemarketing~]</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY>
  <DIV class="cxMnu1" style="width:190px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="[~Atras~]"> [~Atras~]</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="[~Imprimir~]"> [~Imprimir~]</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%" SUMMARY="Telemarketing effectiviness">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Efectividad del telemarketing~]</FONT></TD></TR>
  </TABLE>
  <BR/>
  <TABLE SUMMARY="Sent & Received" BORDER="1">
    <TR><TD CLASS="textstrong" COLSPAN="2">[~Llamadas~]</TD></TR>
    <TR><TD CLASS="textplain">[~Llamadas enviadas~]</TD><TD CLASS="textplain"><% out.write(String.valueOf(nSent)); %></TD></TR>
    <TR><TD CLASS="textplain">[~Llamadas recibidas~]</TD><TD CLASS="textplain"><% out.write(String.valueOf(nReceived)); %></TD></TR>
    <TR><TD CLASS="textplain">[~Media por oportunidad~]</TD><TD CLASS="textplain"><% if (nOprts==0) out.write("0"); else out.write(String.valueOf(((int)(100f*(nSent+nReceived))/(float)nOprts)/100f)); %></TD></TR>
  </TABLE>
  <BR/>
  <TABLE SUMMARY="By Status" BORDER="1">
    <TR><TD CLASS="textstrong" COLSPAN="2">[~Estado de las oportunidades~]</TD></TR>
    <%=oByStatus.toString()%>
    <TR><TD CLASS="textstrong">[~Total~]</TD><TD CLASS="textstrong"><% out.write(String.valueOf(nOprts)); %></TD></TR>
  </TABLE>
</BODY>
</HTML>