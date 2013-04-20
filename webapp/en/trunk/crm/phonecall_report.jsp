<%@ page import="java.util.Date,java.util.Arrays,java.util.HashMap,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Calendar" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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
  SimpleDateFormat oFdt = new SimpleDateFormat(sLanguage.startsWith("es") ? "EEE d MMM" : "EEE MMM d");
  
  String gu_workarea = nullif(request.getParameter("gu_workarea"), getCookie (request, "workarea", null));
  Timestamp dt_from = new Timestamp(oFmt.parse(nullif(request.getParameter("dt_from"),"1970-01-01")+" 00:00:00").getTime());
  Timestamp dt_to = new Timestamp(oFmt.parse(request.getParameter("dt_to")+" 23:59:59").getTime());
  String gu_campaign = nullif(request.getParameter("gu_campaign"));
  String nm_campaign = null;
    
  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  int nSent = 0;
  int nReceived = 0;
  int nOprts = 0;
  int nOprtsWholeCampaign = 0;
  int nCallDays = 0;
  Date dtFirstSentCall=null, dtLastSentCall=null;
  Date dtFirstRecvCall=null, dtLastRecvCall=null;

  StringBuffer oByStatus = new StringBuffer();
  StringBuffer oByStatusWholeCampaign = new StringBuffer();
  StringBuffer oWonByCause = new StringBuffer();
  StringBuffer oLostByCause = new StringBuffer();
  StringBuffer oAbanByCause = new StringBuffer();
  int[] aSentCallsByDay = null;
  int[] aRecvCallsByDay = null;

  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);
    
    if (gu_campaign.length()==0)
      oStmt = oConn.prepareStatement("SELECT MIN("+DB.dt_start+"),MAX("+DB.dt_start+") FROM "+DB.k_phone_calls+" WHERE "+DB.gu_workarea+"=? AND "+DB.tp_phonecall+"=? AND "+DB.dt_start+" BETWEEN ? AND ?");
	  else
      oStmt = oConn.prepareStatement("SELECT MIN("+DB.dt_start+"),MAX("+DB.dt_start+") FROM "+DB.k_phone_calls+" p,"+DB.k_oportunities +" o WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND o."+DB.gu_campaign+"='"+gu_campaign+"' AND p."+DB.gu_workarea+"=? AND p."+DB.tp_phonecall+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?");
	  oStmt.setString(1, gu_workarea);
	  oStmt.setString(2, "S");
	  oStmt.setTimestamp(3, dt_from);
	  oStmt.setTimestamp(4, dt_to);
	  oRSet = oStmt.executeQuery();
	  oRSet.next();
	  dtFirstSentCall = oRSet.getDate(1);
	  dtLastSentCall = oRSet.getDate(2);
    oRSet.close();
	  oStmt.setString(1, gu_workarea);
	  oStmt.setString(2, "R");
	  oStmt.setTimestamp(3, dt_from);
	  oStmt.setTimestamp(4, dt_to);
	  oRSet = oStmt.executeQuery();
	  oRSet.next();
	  dtFirstRecvCall = oRSet.getDate(1);
	  dtLastRecvCall = oRSet.getDate(2);
    oRSet.close();
    oStmt.close();

    if (gu_campaign.length()==0)
      oStmt = oConn.prepareStatement("SELECT "+DB.dt_start+" FROM "+DB.k_phone_calls+" WHERE "+DB.gu_workarea+"=? AND "+DB.tp_phonecall+"=? AND "+DB.dt_start+" BETWEEN ? AND ?");
	  else
      oStmt = oConn.prepareStatement("SELECT "+DB.dt_start+" FROM "+DB.k_phone_calls+" p,"+DB.k_oportunities +" o WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND o."+DB.gu_campaign+"='"+gu_campaign+"' AND p."+DB.gu_workarea+"=? AND p."+DB.tp_phonecall+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?");
    if (dtFirstSentCall!=null && dtLastSentCall!=null) {
      nCallDays = Calendar.DaysBetween(dtFirstSentCall,dtLastSentCall);
      aSentCallsByDay = new int[nCallDays+1];
      Arrays.fill(aSentCallsByDay,0);    
	    oStmt.setString(1, gu_workarea);
	    oStmt.setString(2, "S");
	    oStmt.setTimestamp(3, dt_from);
	    oStmt.setTimestamp(4, dt_to);
	    oRSet = oStmt.executeQuery();
	    while (oRSet.next()) aSentCallsByDay[Calendar.DaysBetween(dtFirstSentCall,oRSet.getDate(1))]++;
      oRSet.close();
	  }
    if (dtFirstRecvCall!=null && dtLastRecvCall!=null) {
      nCallDays = Calendar.DaysBetween(dtFirstRecvCall,dtLastRecvCall);
      aRecvCallsByDay = new int[nCallDays+1];
      Arrays.fill(aRecvCallsByDay,0);    
	    oStmt.setString(1, gu_workarea);
	    oStmt.setString(2, "R");
	    oStmt.setTimestamp(3, dt_from);
	    oStmt.setTimestamp(4, dt_to);
	    oRSet = oStmt.executeQuery();
	    while (oRSet.next()) aRecvCallsByDay[Calendar.DaysBetween(dtFirstRecvCall,oRSet.getDate(1))]++;
      oRSet.close();
	  }
    oStmt.close();

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
      oStmt = oConn.prepareStatement("SELECT o."+DB.tx_cause+",COUNT(o."+DB.gu_oportunity+") FROM "+DB.k_oportunities+" o WHERE o."+DB.id_status+"=? AND EXISTS (SELECT NULL FROM "+DB.k_phone_calls+" p WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND p."+DB.gu_workarea+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?) GROUP BY "+DB.tx_cause);
	  else {
      oStmt = oConn.prepareStatement("SELECT o."+DB.tx_cause+",COUNT(o."+DB.gu_oportunity+") FROM "+DB.k_oportunities+" o WHERE o."+DB.id_status+"=? AND o."+DB.gu_campaign+"='"+gu_campaign+"' AND EXISTS (SELECT NULL FROM "+DB.k_phone_calls+" p WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND p."+DB.gu_workarea+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?) GROUP BY "+DB.tx_cause);
	  }
	  oStmt.setString(1, "GANADA");
	  oStmt.setString(2, gu_workarea);
	  oStmt.setTimestamp(3, dt_from);
	  oStmt.setTimestamp(4, dt_to);
	  oRSet = oStmt.executeQuery();
	  while(oRSet.next()) {
	    String sWonBecause = DBLanguages.getLookUpTranslation(oConn, DB.k_oportunities_lookup, gu_workarea, DB.tx_cause, sLanguage, oRSet.getString(1));
	    if (null==sWonBecause) sWonBecause = oRSet.getString(1);	    
	    oWonByCause.append("<TR><TD CLASS=\"textsmall\" ALIGN=\"right\">"+sWonBecause+" "+String.valueOf(oRSet.getInt(2))+"</TD><TD></TD></TR>");
	  } // wend
	  oRSet.close();
	  oStmt.setString(1, "PERDIDA");
	  oStmt.setString(2, gu_workarea);
	  oStmt.setTimestamp(3, dt_from);
	  oStmt.setTimestamp(4, dt_to);
	  oRSet = oStmt.executeQuery();
	  while(oRSet.next()) {
	    String sLostBecause = DBLanguages.getLookUpTranslation(oConn, DB.k_oportunities_lookup, gu_workarea, DB.tx_cause, sLanguage, oRSet.getString(1));
	    if (null==sLostBecause) sLostBecause = oRSet.getString(1);	    
	    oLostByCause.append("<TR><TD CLASS=\"textsmall\" ALIGN=\"right\">"+sLostBecause+" "+String.valueOf(oRSet.getInt(2))+"</TD><TD></TD></TR>");
	  } // wend
	  oRSet.close();
	  oStmt.setString(1, "ABANDONADA");
	  oStmt.setString(2, gu_workarea);
	  oStmt.setTimestamp(3, dt_from);
	  oStmt.setTimestamp(4, dt_to);
	  oRSet = oStmt.executeQuery();
	  while(oRSet.next()) {
	    String sAbanBecause = DBLanguages.getLookUpTranslation(oConn, DB.k_oportunities_lookup, gu_workarea, DB.tx_cause, sLanguage, oRSet.getString(1));
	    if (null==sAbanBecause) sAbanBecause = oRSet.getString(1);	    
	    oAbanByCause.append("<TR><TD CLASS=\"textsmall\" ALIGN=\"right\">"+sAbanBecause+" "+String.valueOf(oRSet.getInt(2))+"</TD><TD></TD></TR>");
	  } // wend
	  oRSet.close();
	  oStmt.close();
	  
    if (gu_campaign.length()==0)
      oStmt = oConn.prepareStatement("SELECT o."+DB.id_status+",COUNT(o."+DB.gu_oportunity+") FROM "+DB.k_oportunities+" o WHERE EXISTS (SELECT NULL FROM "+DB.k_phone_calls+" p WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND p."+DB.gu_workarea+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?) GROUP BY "+DB.id_status);
	  else {
      nm_campaign = DBCommand.queryStr(oConn, "SELECT "+DB.nm_campaign+" FROM "+DB.k_campaigns+" WHERE "+DB.gu_campaign+"='"+gu_campaign+"'");
      oStmt = oConn.prepareStatement("SELECT o."+DB.id_status+",COUNT(o."+DB.gu_oportunity+") FROM "+DB.k_oportunities+" o WHERE o."+DB.gu_campaign+"='"+gu_campaign+"' AND EXISTS (SELECT NULL FROM "+DB.k_phone_calls+" p WHERE p."+DB.gu_oportunity+"=o."+DB.gu_oportunity+" AND p."+DB.gu_workarea+"=? AND p."+DB.dt_start+" BETWEEN ? AND ?) GROUP BY "+DB.id_status);
	  }
	  oStmt.setString(1, gu_workarea);
	  oStmt.setTimestamp(2, dt_from);
	  oStmt.setTimestamp(3, dt_to);
	  oRSet = oStmt.executeQuery();
	  while(oRSet.next()) {
	    String sStatus = DBLanguages.getLookUpTranslation(oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_status, sLanguage, oRSet.getString(1));
	    if (null==sStatus) sStatus = oRSet.getString(1);	    
	    if (null==sStatus) sStatus = "";
	    nOprts += oRSet.getInt(2);
	    oByStatus.append("<TR><TD CLASS=\"textplain\">"+sStatus+"</TD><TD CLASS=\"textplain\">"+String.valueOf(oRSet.getInt(2))+"</TD></TR>");
	    if ("GANADA".equals(oRSet.getString(1))) oByStatus.append(oWonByCause.toString());
	    if ("PERDIDA".equals(oRSet.getString(1))) oByStatus.append(oLostByCause.toString());
	    if ("ABANDONADA".equals(oRSet.getString(1))) oByStatus.append(oAbanByCause.toString());		
	  } // wend
	  oRSet.close();
	  oStmt.close();

    if (gu_campaign.length()>0) {
      oStmt = oConn.prepareStatement("SELECT "+DB.id_status+",COUNT("+DB.gu_oportunity+") FROM "+DB.k_oportunities+" WHERE "+DB.gu_campaign+"=? AND "+DB.gu_workarea+"=? GROUP BY "+DB.id_status);
	    oStmt.setString(1, gu_campaign);
	    oStmt.setString(2, gu_workarea);
	    oRSet = oStmt.executeQuery();
	    while(oRSet.next()) {
	      String sStatusW = DBLanguages.getLookUpTranslation(oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_status, sLanguage, oRSet.getString(1));
	      if (null==sStatusW) sStatusW = oRSet.getString(1);	    
	      if (null==sStatusW) sStatusW = "";
	      nOprtsWholeCampaign += oRSet.getInt(2);
	      oByStatusWholeCampaign.append("<TR><TD CLASS=\"textplain\">"+sStatusW+"</TD><TD CLASS=\"textplain\">"+String.valueOf(oRSet.getInt(2))+"</TD></TR>");
	    } // wend
	    oRSet.close();
	    oStmt.close();
    }

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
  <TITLE>hipergate :: Telemarketing effectiveness</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY>
  <DIV class="cxMnu1" style="width:190px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%" SUMMARY="Telemarketing effectiviness">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Telemarketing effectiveness</FONT></TD></TR>
  </TABLE>
  <BR/>
  <FONT CLASS="textstrong">Campaign&nbsp;<%=nm_campaign%></FONT>
  <BR/>
  <FONT CLASS="textplain"><% if (request.getParameter("dt_from")!=null) out.write("from&nbsp;"+request.getParameter("dt_from")+"&nbsp;&nbsp;"); out.write("to&nbsp;"+request.getParameter("dt_to"));%></FONT>
  <BR/><BR/>
  <TABLE SUMMARY="Sent & Received" BORDER="1">
    <TR><TD CLASS="textstrong" COLSPAN="2">Total Calls</TD></TR>
    <TR><TD CLASS="textplain">Sent calls</TD><TD CLASS="textplain"><% out.write(String.valueOf(nSent)); %></TD></TR>
    <TR><TD CLASS="textplain">Received calls</TD><TD CLASS="textplain"><% out.write(String.valueOf(nReceived)); %></TD></TR>
    <TR><TD CLASS="textplain">Mean by lead</TD><TD CLASS="textplain"><% if (nOprts==0) out.write("0"); else out.write(String.valueOf(((int)(100f*(nSent+nReceived))/(float)nOprts)/100f)); %></TD></TR>
  </TABLE>
  <BR/>
  <TABLE SUMMARY="By Status" BORDER="1">
    <TR><TD CLASS="textstrong" COLSPAN="2">Status of leads with calls</TD></TR>
    <%=oByStatus.toString()%>
    <TR><TD CLASS="textstrong">Total</TD><TD CLASS="textstrong"><% out.write(String.valueOf(nOprts)); %></TD></TR>
  </TABLE>
<% if (gu_campaign.length()>0) { %>
  <BR/>
  <TABLE SUMMARY="By Status Whole Campaign" BORDER="1">
    <TR><TD CLASS="textstrong" COLSPAN="2">Status of all leads of the campaign</TD></TR>
    <%=oByStatusWholeCampaign.toString()%>
    <TR><TD CLASS="textstrong">Total</TD><TD CLASS="textstrong"><% out.write(String.valueOf(nOprtsWholeCampaign)); %></TD></TR>
  </TABLE>
<% }
   Date dt;
   int t;
   if (aSentCallsByDay!=null) {
     dt = new Date (dtFirstSentCall.getTime());
     nCallDays = aSentCallsByDay.length;
     t = 0;
%>
  <BR/>
  <TABLE SUMMARY="Sent By Day" BORDER="1">
    <TR><TD CLASS="textstrong" COLSPAN="2">Calls sent each day</TD></TR>
<%  for (int e=0; e<nCallDays; e++) {
      out.write("<TD CLASS=\"textplain\">"+oFdt.format(dt)+"</TD><TD CLASS=\"textplain\">"+String.valueOf(aSentCallsByDay[e])+"</TD></TR>");
      t+= aSentCallsByDay[e];
      dt = new Date(dt.getTime()+86400000l);
    }
%>
    <TR><TD CLASS="textstrong">Total</TD><TD CLASS="textstrong"><% out.write(String.valueOf(t)); %></TD></TR>
  </TABLE>
<% }
   if (aRecvCallsByDay!=null) {
     dt = new Date (dtFirstRecvCall.getTime());
     nCallDays = aRecvCallsByDay.length;
     t = 0;
%>
  <BR/>
  <TABLE SUMMARY="Received By Day" BORDER="1">
    <TR><TD CLASS="textstrong" COLSPAN="2">Call received each day</TD></TR>
<%  for (int e=0; e<nCallDays; e++) {
      out.write("<TD CLASS=\"textplain\">"+oFdt.format(dt)+"</TD><TD CLASS=\"textplain\">"+String.valueOf(aRecvCallsByDay[e])+"</TD></TR>");
      t+= aRecvCallsByDay[e];
      dt = new Date(dt.getTime()+86400000l);
    }
%>
    <TR><TD CLASS="textstrong">Total</TD><TD CLASS="textstrong"><% out.write(String.valueOf(t)); %></TD></TR>
  </TABLE>
<% } %>
  <BR/>
  <FORM><INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()"></FORM>
</BODY>
</HTML>