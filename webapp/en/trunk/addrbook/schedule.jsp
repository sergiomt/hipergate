<%@ page import="java.util.HashMap,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Calendar,com.knowgate.crm.SalesMan,com.knowgate.billing.Account,com.knowgate.gdata.GCalendarSynchronizer" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
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

  String sFace = nullif(request.getParameter("face"),getCookie(request,"face","crm"));
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  String sDomainId = getCookie(request, "domainid", "");
  String sWrkAId = getCookie(request, "workarea", "");
  String sFellow = nullif(request.getParameter("gu_fellow"), getCookie(request, "userid", ""));
  boolean bItsMe = sFellow.equals(getCookie(request, "userid", ""));
  boolean bItsSalesMan = false;
  
  Date dtNow = new Date();
  int year, month, day;

  if (request.getParameter("year")==null)
    year = dtNow.getYear();
  else
    year = Integer.parseInt(request.getParameter("year"));

  if (request.getParameter("month")==null)
    month = dtNow.getMonth();
  else
    month = Integer.parseInt(request.getParameter("month"));

  if (request.getParameter("day")==null)
    day = dtNow.getDate();
  else
    day = Integer.parseInt(request.getParameter("day"));
        
  Date dtToday = new Date(year, month, day);
  Date dtYesterday = new Date(dtToday.getTime()-24l*60l*60l*1000l);
  Date dtTomorrow  = new Date(dtToday.getTime()+24l*60l*60l*1000l);

  String sToday = DBBind.escape(dtToday, "shortDate").trim();

  String sDay=null,sMonth=null;
    
  try {
    sDay = Calendar.WeekDayName(dtToday.getDay()+1, sLanguage);
    sMonth = Calendar.MonthName(month, sLanguage);
  }
  catch (IllegalArgumentException iae) {
    sDay = Calendar.WeekDayName(dtToday.getDay()+1, "en");
    sMonth = Calendar.MonthName(month, "en");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalArgumentException&desc=" + iae.getMessage() + "&resume=_back"));
    return;
  }

  if (null==sDay) return;
    
  Meeting oMeeting;
  String  sMeeting;
  int iMeetings;
  HashMap oMeetMap = new HashMap();
  boolean bFixed;
  DBSubset oRooms;
  DBSubset oFellowList = null;
  int iFellowCount = 0;

  Object sTpRoom;
  final String sTypeRoom = "ROOM";
  final String sTypeAuditorium = "AUDITORIUM";
  final String sTypeSaloon = "SALOON";
    
  JDCConnection oConn = null;  
  DayPlan oPlan = new DayPlan();
  ACLUser oUsr;
  boolean bIsGuest = true;
  boolean bIsAdmin = false;
      
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("dailyschedule");  
    oConn.setAutoCommit(true);
    
    // Si el usuario no existe en la tabla k_fellows,
    // añadirlo automáticamente para que no casque
    oUsr = new ACLUser(oConn, sFellow);
    
    if (!oUsr.isNull(DB.de_title)) {
      FellowTitle oTitle = new FellowTitle(oUsr.getString(DB.gu_workarea), oUsr.getString(DB.de_title));
      if (!oTitle.exists(oConn)) oTitle.store(oConn);
    }

    Fellow oFlw = new Fellow(sFellow);
    if (!oFlw.exists(oConn)) {
      oFlw.clone(oUsr);
      oFlw.replace(DB.gu_workarea, sWrkAId);      
      oFlw.store(oConn);
      
      GlobalCacheClient.expire("k_fellows.id_domain[" + sDomainId + "]");
      GlobalCacheClient.expire("k_fellows.gu_workarea[" + sWrkAId + "]");
    } // fi (!oFlw.exists())
    oFlw = null;
    
    // Read meetings from Google Calendar if synchronization is activated and a valid email+password+calendar name is found at k_user_pwd table
    final String sGDataSync = GlobalDBBind.getProperty("gdatasync", "1");
    if (sGDataSync.equals("1") || sGDataSync.equalsIgnoreCase("true") || sGDataSync.equalsIgnoreCase("yes")) {
      GCalendarSynchronizer oGSync = new GCalendarSynchronizer();
      if (oGSync.connect(oConn, sFellow, sWrkAId, GlobalCacheClient)) {
        oGSync.readMeetingsFromGoogle(oConn, new Date(year, month, day, 0, 0, 0), new Date(year, month, day,23,59,59));
      } // fi
    } // fi
    
    oPlan.load(oConn, sFellow, dtToday);
    
    if (!bItsMe) {
      bItsSalesMan = SalesMan.exists(oConn,sFellow);
    }
    
    if (Account.TYPE_CORPORATE.equals(Account.getUserAccountType(oConn, getCookie(request, "userid", "")))) {
      oFellowList = GlobalCacheClient.getDBSubset("k_fellows.id_domain[" + sDomainId + "]");
      if (null==oFellowList) {
        oFellowList = new DBSubset(DB.k_fellows, DB.gu_fellow + "," + DB.tx_name + "," + DB.tx_surname, DB.id_domain + "=" + sDomainId + " ORDER BY 2,3", 100);
    	iFellowCount = oFellowList.load(oConn);
    	GlobalCacheClient.putDBSubset("k_fellows", "k_fellows.id_domain[" + sDomainId + "]", oFellowList);    
      }
      else
        iFellowCount = oFellowList.getRowCount();
    }
    else {
      oFellowList = GlobalCacheClient.getDBSubset("k_fellows.gu_workarea[" + sWrkAId + "]");
      
      if (null==oFellowList) {
        oFellowList = new DBSubset(DB.k_fellows, DB.gu_fellow + "," + DB.tx_name + "," + DB.tx_surname, DB.gu_workarea + "='" + sWrkAId + "' ORDER BY 2,3", 100);
    	iFellowCount = oFellowList.load(oConn);    
    	
    	GlobalCacheClient.putDBSubset("k_fellows", "k_fellows.gu_workarea[" + sWrkAId + "]", oFellowList);
      }
      else
        iFellowCount = oFellowList.getRowCount();
    }
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("dailyschedule");
  
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getMessage(), "");
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=../blank.htm"));  
    return;
  }
  
  String sLine = "    <TR><TD BGCOLOR=\"black\"><IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"1\" HEIGHT=\"1\" BORDER=\"0\"></TD><TD BGCOLOR=\"black\"><IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"400\" HEIGHT=\"1\" BORDER=\"0\"></TD><TD BGCOLOR=\"black\"><IMG SRC=\"../images/images/spacer.gif\" WIDTH=\"1\" HEIGHT=\"1\" BORDER=\"0\"></TD></TR>\n";
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Calendar</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--      
    
      var jsMeetId;

      var activity_edition_page = "<% out.write(sFace.equalsIgnoreCase("healthcare") ? "appointment_edit_f.htm" : "meeting_edit_f.htm"); %>";
      
      // ------------------------------------------------------
      
      function createMeeting(hour) {
        window.open(activity_edition_page+"?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&date=<%=sToday%>" + (hour.length>0 ? "&hour="+hour : ""), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }

      // ------------------------------------------------------

<% if (bItsSalesMan) { %>
      function createVisit() {
        window.open("visit_edit_f.htm?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&date=<%=sToday%>&gu_sales_man=<%=sFellow%>", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }
<% } %>

      // ------------------------------------------------------
      
      function modifyMeeting(gu) {
        window.open(activity_edition_page+"?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + "&gu_meeting=" + gu, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }

      // ------------------------------------------------------
      
      function repeatMeeting(gu) {
        window.open("meeting_repeat.jsp?gu_meeting=" + gu, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=600,height=160");
      }

      // ------------------------------------------------------
      
      function deleteMeeting(gu,tx) {
        if (tx) {
          if (confirm("Are you sure you want to delete activity&nbsp; " + tx + "?"))
            window.location = "meeting_edit_delete.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_meeting=" + gu + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&day=<%=day%>&referer=schedule";
	      } else {
          if (confirm("Are you sure you want to delete activity&nbsp;?"))
            window.location = "meeting_edit_delete.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_meeting=" + gu + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&day=<%=day%>&referer=schedule";
	      }
      }

      // ------------------------------------------------------

      function showDay() {
        var dtParts = document.forms[0].newdate.value.split("-");
        	  
        window.location = "schedule.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=" + getCombo(document.forms[0].sel_fellow) + "&year=" + String(parseInt(dtParts[0])-1900) + "&month=" + String(parseInt(dtParts[1])-1) + "&day=" + dtParts[2] + "&screen_width=" + String(screen.width);
      }

      // ------------------------------------------------------

      function showWeek() {
        var dtParts = document.forms[0].newdate.value.split("-");        	  
        window.location = "week_schedule.jsp?id_domain=<%=sDomainId%>&gu_workarea=<%=sWrkAId%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=" + getCombo(document.forms[0].sel_fellow) + "&year=" + String(parseInt(dtParts[0])-1900) + "&month=" + String(parseInt(dtParts[1])-1) + "&day=" + dtParts[2] + "&screen_width=" + String(screen.width);
      }

      // ----------------------------------------------------
      
      function showMonth() {
        window.location = "month_schedule.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=<%=sFellow%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&screen_width=" + String(screen.width);
      }
      
      // ------------------------------------------------------
      
      function showRooms() {
        window.location = "room_schedule.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&day=<%=day%>";
      }

      // ------------------------------------------------------

      var intervalId;
      var wincalendar;

      function findCalendar() {
        var dt;
        
        if (wincalendar.closed) {
          clearInterval(intervalId);
          dt = document.forms[0].newdate.value.split("-");
          if (!isNaN(parseInt(dt[0])))
            showDay();
        }
      } // findCalendar() 
           
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        wincalendar = window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "schedulecalendar", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
        intervalId = setInterval ("findCalendar()", 100);
      } // showCalendar()

      // ------------------------------------------------------
      
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      dynapi.library.setPath('../javascript/dynapi3/');
      dynapi.library.include('dynapi.api.DynLayer');

      var menuLayer;

      dynapi.onLoad(init);
    function init() {
 
        var frm = document.forms[0];        
        setCombo(frm.sel_fellow,"<% out.write(sFellow); %>");        
        menuLayer = new DynLayer();
        menuLayer.setWidth(160);
        menuLayer.setHTML(rightMenuHTML);      
      }
    //-->
  </SCRIPT>
  <STYLE type="text/css">
  <!--
    .microlink { color:red;Arial,Helvetica,sans-serif;font-size:8pt;text-decoration:none;
    }
  -->
  </STYLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
  <%@ include file="../common/tabmenu.jspf" %>
  <BR>
  <FORM><INPUT TYPE="hidden" NAME="newdate" VALUE="<% out.write(String.valueOf(dtToday.getYear()+1900) + "-" + String.valueOf(dtToday.getMonth()+1) + "-" + String.valueOf(dtToday.getDate())); %>">
  <TABLE WIDTH="<%=iTabWidth*iActive%>" CELLSPACING="0" CELLPADDING="0" BORDER="0">
    <TR>
      <TD CLASS="striptitle"><FONT CLASS="title1">Calendar</FONT></TD>
      <TD ALIGN="right" CLASS="striptitle"><FONT CLASS="title1"><% out.write(localeDateFormat(sWrkAId,GlobalCacheClient,GlobalDBBind).format(dtToday)); %></FONT></TD>
    </TR>    
  </TABLE>    
  <TABLE CELLSPACING="2" CELLPADDING="2" BORDER="0">
  <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  <TR>
    <TD>
      <FONT CLASS="textplain">View&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" CHECKED>day&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showWeek()">&nbsp;week&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showMonth()">&nbsp;month&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="rooms" onClick="showRooms()">&nbsp;Resources and Rooms</FONT>
    </TD>
    <TD><IMG SRC="../images/images/spacer.gif" WIDTH="12" BORDER="0"></TD>
    <TD>
      <FONT CLASS="textplain">Calendar of</FONT>&nbsp;
      <SELECT NAME="sel_fellow" CLASS="combomini" onChange="showDay()">
<%    for (int f=0; f<iFellowCount; f++) {      
        out.write("<OPTION VALUE=\"" + oFellowList.getString(0,f) + "\">" + oFellowList.getStringNull(1,f,"") + " " + oFellowList.getStringNull(2,f,"") + "</OPTION>");
      }
%>
      </SELECT>
    </TD>
  </TR>
  <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>
  <HR>
  <CENTER>
  <TABLE CELLSPACING="0" CELLPADDING="0" BORDER="0" BGCOLOR="#e1e5ea">
    <TR BGCOLOR="white">
      <TD></TD>
<%    if (bItsMe) { %>
      <TD nowrap>
        <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
<% if (bIsGuest)        
     out.write("        <A HREF=\"#\" onClick=\"alert('Your credential level as Guest does not allow you to perform this action')\" CLASS=\"linkplain\" TITLE=\"New Activity\">New</A>");
   else
     out.write("        <A HREF=\"#\" onClick=\"createMeeting('');\" CLASS=\"linkplain\" TITLE=\"New Activity\">New</A>");
%>
      </TD>
<%    } else if (bItsSalesMan) { %>
      <TD nowrap>
        <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
<% if (bIsGuest)        
     out.write("        <A HREF=\"#\" onClick=\"alert('Your credential level as Guest does not allow you to perform this action')\" CLASS=\"linkplain\" TITLE=\"New Activity\">New</A>");
   else
     out.write("        <A HREF=\"#\" onClick=\"createVisit();\" CLASS=\"linkplain\" TITLE=\"Arrange meeting\">Arrange meeting</A>");
%>
      </TD>
<%    } else { %>
      <TD></TD>
<%    } %>
      <TD>
        &nbsp;<IMG SRC="../images/images/addrbook/calendar.gif" BORDER="0">
        &nbsp;<A HREF="#" onClick="showCalendar('newdate');" CLASS="linkplain">Calendar</A>
      </TD>
      <TD COLSPAN="7" ALIGN="right"><A HREF="schedule.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&gu_fellow=<%=sFellow%>&year=<%=dtYesterday.getYear()%>&month=<%=dtYesterday.getMonth()%>&day=<%=dtYesterday.getDate()%>" CLASS="linkplain">Yesterday</A>&nbsp;&nbsp;<A HREF="schedule.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&gu_fellow=<%=sFellow%>&year=<%=dtTomorrow.getYear()%>&month=<%=dtTomorrow.getMonth()%>&day=<%=dtTomorrow.getDate()%>" CLASS="linkplain">Tomorrow</A></TD>
      <TD></TD>
    </TR>
<%
   String Slice[][] = new String[2][8];
      
   Slice[0][0] = null; Slice[1][0] = null;
   Slice[0][1] = null; Slice[1][1] = null;
   Slice[0][2] = null; Slice[1][2] = null;
   Slice[0][3] = null; Slice[1][3] = null;
   Slice[0][4] = null; Slice[1][4] = null;
   Slice[0][5] = null; Slice[1][5] = null;
   Slice[0][6] = null; Slice[1][6] = null;
   Slice[0][7] = null; Slice[1][7] = null;

   int iPreviousSlice = 0;
   int iCurrentSlice  = 1;
   
   for (int r=28; r<96+28; r++) {
     if (0==(r%4)) { %>
       <TR><TD WIDTH="1" BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD><TD COLSPAN="9" WIDTH="700px" BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD><TD WIDTH="1px" BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD></TR>
<%   } %>  
    <TR>
      <TD BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD>
<%   if (0==(r%4)) { %>
      <TD VALIGN="top" class="textsmall" WIDTH="40" ROWSPAN="4" BGCOLOR="#e1e5ea">&nbsp;<A HREF="#" onclick="createMeeting('<%=String.valueOf( (r/4)%96>23 ? ((r/4)%96)-24 : (r/4)%96 )%>:00')" CLASS="linknodecor" title="Create new activity at this time"><B><%=String.valueOf( (r/4)%96>23 ? ((r/4)%96)-24 : (r/4)%96 )%>:00</B></A></TD> 
<%   } %>
<%
     iMeetings = oPlan.concurrentMeetings(r%96);
     
     if (0==iMeetings)
       out.write("      <TD COLSPAN=\"8\"></TD>\n");
     else {
       Slice[iCurrentSlice][0] = "";
       Slice[iCurrentSlice][1] = "";
       Slice[iCurrentSlice][2] = "";
       Slice[iCurrentSlice][3] = "";
       Slice[iCurrentSlice][4] = "";
       Slice[iCurrentSlice][5] = "";
       Slice[iCurrentSlice][6] = "";
       Slice[iCurrentSlice][7] = "";
                                   
       for (int m=0; m<8; m++) { 
         oMeeting = oPlan.getMeeting(r%96,m);
         
         if (oMeeting!=null) {
           // [~//Obtener el GUID del siguiente meeting~]
           sMeeting = oMeeting.getString(DB.gu_meeting);
         
           // [~//Buscar el GUID en la rodaja de tiempo anterior~]
           // [~//si lo encuentra colocar la reunión en la misma~]
           // [~//posición de la rodaja~]
           bFixed = false;
           for (int n=0; n<8; n++) {
             if (sMeeting.equals(Slice[iPreviousSlice][n])) {
               Slice[iCurrentSlice][n] = sMeeting;
	       bFixed = true;
	       break;
	     }
           } // next (n)
           
           // [~//Si no encuentra el GUID colocarlo en la primera~]
           // [~//columna libre que se encuentre~]
           if (!bFixed)
             for (int p=0; p<8; p++)
               if (0==Slice[iCurrentSlice][p].length()) {
             	 Slice[iCurrentSlice][p] = sMeeting;
                 break;
               }
         } // fi (oMeeting)
       } // next (m)

       for (int q=0; q<8; q++) {
         if (0==Slice[iCurrentSlice][q].length())
           out.write("      <TD></TD>\n");
         else {
	   sMeeting = Slice[iCurrentSlice][q];                    
           if (!oMeetMap.containsKey(sMeeting)) {
             oMeetMap.put(sMeeting, sMeeting);
             oMeeting = oPlan.seekMeeting(sMeeting);
             oRooms = oMeeting.getRooms(oConn);
             
             out.write("      <TD BGCOLOR=\"white\"><FONT CLASS=\"textsmall\">" + (q>0 ? "&nbsp;|&nbsp;" : "") + oMeeting.getHour() + ":" + oMeeting.getMinute() + " - ");
             
             if (oMeeting.getShort(DB.bo_private)!=(short)0)
               out.write("<IMG SRC=\"../images/images/addrbook/smalllock.gif\" BORDER=\"0\" ALT=\"Private\" HSPACE=\"4\">");
             
             if (bItsMe || oMeeting.getShort(DB.bo_private)==(short)0) {
               out.write("<A HREF=\"#\" onClick=\"modifyMeeting('" + oMeeting.getString(DB.gu_meeting) + "')\" oncontextmenu=\"jsMeetId='"+oMeeting.getString(DB.gu_meeting)+"';return showRightMenu(event);\" TITLE=\"");
               if (!oMeeting.isNull(DB.tp_meeting)) out.write(oMeeting.getString(DB.tp_meeting) + ": ");
               out.write(oMeeting.getStringNull(DB.de_meeting,"").replace('\n',' ').replace('\r',' ') +  "\">" + oMeeting.getStringNull(DB.tx_meeting,"Untitled") + "</A></FONT>");
             
               for (int rm=0; rm<oRooms.getRowCount(); rm++) {
                 sTpRoom = oRooms.get(1,rm);
                 if (sTypeRoom.equals(sTpRoom) || sTypeAuditorium.equals(sTpRoom) || sTypeSaloon.equals(sTpRoom)) {
                   out.write("<FONT CLASS=\"textsmall\">&nbsp;(" + DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_rooms_lookup, sWrkAId, "tp_room", sLanguage, (String) sTpRoom) + " " + oRooms.getString(0,rm) + ")&nbsp;</FONT>");
                   break;
                 }
               } // next (rm)
             
               if (bItsMe)
                 if (bIsGuest && !bIsAdmin)
                   out.write("<FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"#\" onClick=\"alert('Your credential level as Guest does not allow you to perform this action')\" TITLE=\"Delete\">x</A>]</FONT></TD>\n");
                 else if (!bIsAdmin && !oMeeting.getString(DB.gu_fellow).equals(getCookie(request, "userid", "")))
                   out.write("<FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"#\" onClick=\"alert('It is not allowed to delete activities not created by you')\" TITLE=\"Delete\">x</A>]</FONT></TD>\n");
                 else
                   out.write("<FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"javascript:deleteMeeting('" + oMeeting.getString(DB.gu_meeting) + "','" + oMeeting.getStringNull(DB.tx_meeting,"Untitled").replace((char)39,'´') + "')\" TITLE=\"Delete\">x</A>]</FONT></TD>\n");

             } // fi (bItsMe || bo_private==0)
           }
           else {
             out.write("      <TD BGCOLOR=\"white\">"  + "</TD>\n");
           }
         }
       } // next (q)
     } // fi(iMeetings)
%>
      <TD BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD>
    </TR>    
<% 

   Slice[iPreviousSlice][0] = Slice[iCurrentSlice][0];
   Slice[iPreviousSlice][1] = Slice[iCurrentSlice][1];
   Slice[iPreviousSlice][2] = Slice[iCurrentSlice][2];
   Slice[iPreviousSlice][3] = Slice[iCurrentSlice][3];
   Slice[iPreviousSlice][4] = Slice[iCurrentSlice][4];
   Slice[iPreviousSlice][5] = Slice[iCurrentSlice][5];
   Slice[iPreviousSlice][6] = Slice[iCurrentSlice][6];
   Slice[iPreviousSlice][7] = Slice[iCurrentSlice][7];

   iPreviousSlice = (0==iPreviousSlice ? 1 : 0);
   iCurrentSlice  = (0==iCurrentSlice  ? 1 : 0);   
   } // next (r)
%>  
    <TR><TD WIDTH="1px" BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD><TD COLSPAN="9" WIDTH="700px" BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD><TD WIDTH="1px" BGCOLOR="darkgray"><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="1"></TD></TR>
  </TABLE>
  </CENTER>
  </FORM>
  <SCRIPT language="JavaScript" type="text/javascript">
    <!--
    addMenuOption("View Details","modifyMeeting(jsMeetId)",1);
    addMenuSeparator();
<%  if (bItsMe) {
      if (bIsGuest && !bIsAdmin) {
        out.write("addMenuOption(\"Delete\",\"alert('Your credential level as Guest does not allow you to perform this action')\",0);\n    addMenuSeparator();\n");
        out.write("addMenuOption(\"Repeat\",\"alert('Your credential level as Guest does not allow you to perform this action')\",0);\n    addMenuSeparator();\n");
      } else if (!bIsAdmin && !sFellow.equals(getCookie(request, "userid", ""))) {
        out.write("addMenuOption(\"Delete\",\"alert('It is not allowed to delete activities not created by you')\",0);\n    addMenuSeparator();\n");
        out.write("addMenuOption(\"Repeat\",\"alert('It is not allowed to repeat activities not created by you')\",0);\n    addMenuSeparator();\n");
      } else {
        out.write("addMenuOption(\"Delete\",\"deleteMeeting(jsMeetId,)\",0);\n    addMenuSeparator();\n");
        out.write("addMenuOption(\"Repeat\",\"repeatMeeting(jsMeetId)\",0);\n    addMenuSeparator();\n");
      }
    }
%>
    //-->
  </SCRIPT>

</BODY>
<%
  oConn.close("dailyschedule");
  oConn = null;
%>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>