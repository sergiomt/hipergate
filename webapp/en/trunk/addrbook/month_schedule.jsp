<%@ page import="java.util.Date,java.text.SimpleDateFormat,java.net.URLDecoder,java.sql.SQLException,java.sql.Timestamp,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Calendar,com.knowgate.billing.Account,com.knowgate.addrbook.WorkingCalendar,com.knowgate.gdata.GCalendarSynchronizer" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sFace = nullif(request.getParameter("face"),getCookie(request,"face","crm"));
  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
  
  String id_domain = request.getParameter("id_domain"); 
  String gu_workarea = request.getParameter("gu_workarea"); 

  String sFellow = nullif(request.getParameter("gu_fellow"), getCookie(request, "userid", ""));
  boolean bItsMe = sFellow.equals(getCookie(request, "userid", ""));

  int iScreenWidth;
  float fScreenRatio;

  String screen_width = request.getParameter("screen_width");

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  fScreenRatio = ((float) iScreenWidth) / 800f;

  Date dtNow = new Date();
  int year, month;

  if (request.getParameter("year")==null)
    year = dtNow.getYear();
  else
    year = Integer.parseInt(request.getParameter("year"));

  if (request.getParameter("month")==null)
    month = dtNow.getMonth();
  else
    month = Integer.parseInt(request.getParameter("month"));
  if (-1==month) month = dtNow.getMonth();

  final long lOneDayMilis = 24l*60l*60l*1000l;
  Date dtToday = new Date(year, month, 1, 0, 0, 0);
  Date dtNextM = new Date(dtToday.getTime()+(((long)Calendar.LastDay(month,year+1900))*lOneDayMilis));
  Date dtLastD = new Date(dtNextM.getTime()-lOneDayMilis);
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");

  String sToday = DBBind.escape(dtToday, "shortDate");
  String sMonth = Calendar.MonthName(month, sLanguage);
  int  FirstDay;   // First day of the month. (1 = Monday)
  int  CurrentDay; // Used to print dates in calendar
  int  LastDay = Calendar.LastDay(month, year+1900);

  int iFirstDayOfWeek;
	if (sLanguage.startsWith("es"))
	  iFirstDayOfWeek = 1;
	else
	  iFirstDayOfWeek = 0;
    
  int iMeetCount = 0;
  int iLastMeeting = 0;
  DBSubset oMeetings = null;
  DBSubset oFellowList = null;
  int iFellowCount = 0;
  WorkingCalendar oWCal = null;
    
  final String sCorporateAccount = "C";  
  
  JDCConnection oConn = null;

  boolean bIsGuest = true;
  boolean bIsAdmin = false;

  try {
    oConn = GlobalDBBind.getConnection("monthschedule");  

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

    // Read meetings from Google Calendar if synchronization is activated and a valid email+password+calendar name is found at k_user_pwd table
    final String sGDataSync = GlobalDBBind.getProperty("gdatasync", "1");
    if (sGDataSync.equals("1") || sGDataSync.equalsIgnoreCase("true") || sGDataSync.equalsIgnoreCase("yes")) {
      GCalendarSynchronizer oGSync = new GCalendarSynchronizer();
      if (oGSync.connect(oConn, sFellow, gu_workarea, GlobalCacheClient)) {
        oGSync.readMeetingsFromGoogle(oConn, dtToday, dtNextM);
      } // fi
    } // fi

    oMeetings = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
    			     "m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.de_meeting,
    			     "f." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND f." + DB.gu_fellow + "='" + sFellow + "' AND m." + DB.dt_start + " BETWEEN ? AND ? ORDER BY 2", 60);

    iMeetCount = oMeetings.load(oConn, new Object[]{new Timestamp(dtToday.getTime()), new Timestamp(dtNextM.getTime())});

    oWCal = WorkingCalendar.forUser(oConn, sFellow, dtToday, dtNextM, null, null);
  									    
%><%@ include file="schedule_fellows_boilerplate.jspf" %><%
	     
  }
  catch (Exception e) {
  
    if (null!=oConn)
      oConn.close("monthschedule");

    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Monthly Calendar</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      var activity_edition_page = "<% out.write(sFace.equalsIgnoreCase("healthcare") ? "appointment_edit_f.htm" : "meeting_edit_f.htm"); %>";

      var intervalId;
      var wincalendar;

      function findCalendar() {
        var dt;
        
        if (wincalendar.closed) {
          clearInterval(intervalId);
          dt = document.forms[0].newdate.value.split("-");
          window.location = "room_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=" + String(parseInt(dt[0])-1900) + "&month=" + String(parseInt(dt[1])-1) + "&day=" + dt[2];
        }
      } // findCalendar() 
           
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        wincalendar = window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "schedulecalendar", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
        intervalId = setInterval ("findCalendar()", 100);
      } // showCalendar()

      // ------------------------------------------------------
      
      function createMeeting() {
        window.open(activity_edition_page+"?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid"), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }

      // ------------------------------------------------------
      
      function modifyMeeting(gu) {
        window.open(activity_edition_page+"?id_domain=" + getURLParam("id_domain") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getURLParam("gu_workarea") + "&gu_fellow=" + getCookie("userid") + "&gu_meeting=" + gu, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }
  
      // ----------------------------------------------------

      function showDay() {	  
	  window.location = "schedule.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=<%=sFellow%>";
      }

      // ------------------------------------------------------

      function showWeek() {
        window.location = "week_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=" + getCombo(document.forms[0].sel_fellow) + "&screen_width=" + String(screen.width);
      }

      // ----------------------------------------------------
      
      function showMonth() {
        window.location = "month_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&gu_fellow=" + getCombo(document.forms[0].sel_fellow) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&screen_width=" + String(screen.width);
      }

      // ------------------------------------------------------
      
      function showRooms() {
        window.location = "room_schedule.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
      }

      // ----------------------------------------------------

      function jumpToDay(iDay) {	  
	      window.location = "schedule.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=<%=sFellow%>" + "&year=<%=year%>&month=<%=month%>&day=" + String(iDay);
      }

      // ------------------------------------------------------
      
      function deleteMeeting(gu,tx,dt) {
        if (tx) {
          if (confirm("Are you sure that you want to delete activity  " + tx + "?"))
            window.location = "meeting_edit_delete.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_meeting=" + gu + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&day="+dt+"&referer=month_schedule";
	      } else {
          if (confirm("Are you sure that you want to delete activity ?"))
            window.location = "meeting_edit_delete.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_meeting=" + gu + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&day="+dt+"&referer=month_schedule";
	      }
      }
	
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function setCombos() {
        var frm = document.forms[0];        
        setCombo(frm.sel_fellow,"<% out.write(sFellow); %>");
        setCombo(frm.sel_year,getURLParam("year"));
        setCombo(frm.sel_month,String(parseInt(getURLParam("month"))));                
      } //  setCombos()
    //-->    
  </SCRIPT>
  <!--============================
  Highlight today with a red border.
  Author : Eugene Quah 20040515  eugene@quah.org
  =============================-->
  <STYLE type="text/css">
    .today { padding:4px;border:solid firebrick 2px }
    .microlink { color:red;Arial,Helvetica,sans-serif;font-size:8pt;text-decoration:none;
  </STYLE>
  <!--========================-->  
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <BR>
    <FORM>
    <TABLE WIDTH="<%=iTabWidth*iActive%>" CELLSPACING="0" CELLPADDING="0" BORDER="0">
      <TR>
        <TD CLASS="striptitle"><FONT CLASS="title1">Calendar</FONT></TD>
        <TD ALIGN="right" CLASS="striptitle"><FONT CLASS="title1"><%=sMonth%>&nbsp;&nbsp;<%=dtToday.getYear()+1900%></FONT></TD>
      </TR>    
    </TABLE>
      <INPUT TYPE="hidden" NAME="newdate">
      <TABLE CELLSPACING="2" CELLPADDING="2" BORDER="0">
      <TR><TD COLSPAN="2" HEIGHT="4"><IMG SRC="../images/images/spacer.gif" BORDER="0" HEIGHT="4"></TD></TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>
          <FONT CLASS="textplain">View&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showDay()">day&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showWeek()">&nbsp;week&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" CHECKED>&nbsp;month&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="rooms" onClick="showRooms()">&nbsp;Rooms and Resources</FONT>
        </TD>
        <TD>
          <FONT CLASS="textplain">Calendar for</FONT>&nbsp;
          <SELECT NAME="sel_fellow" CLASS="combomini" onChange="showMonth()">
<%    for (int f=0; f<iFellowCount; f++) {      
        out.write("<OPTION VALUE=\"" + oFellowList.getString(0,f) + "\">" + oFellowList.getStringNull(1,f,"") + " " + oFellowList.getStringNull(2,f,"") + "</OPTION>");
      }
%>
          </SELECT>
        </TD>
      </TR>
      <TR>
        <TD>
	  <!--
	  <A HREF="#" CLASS="linkplain" onclick="window.open('ical_upload.jsp','uploadcalendar','directories=no,toolbar=no,menubar=no,width=560,height=200')">Load Calendar</A>
	  &nbsp;	  
	  <A HREF="ical.jsp?gu_fellow=<%=sFellow%>&tx_from=<%=oFmt.format(dtToday)%>&tx_to=<%=oFmt.format(dtLastD)%>" CLASS="linkplain" TARGET="_blank">Download Monthly Calendar</A>
    -->
        </TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR><TD COLSPAN="2" HEIGHT="4"><IMG SRC="../images/images/spacer.gif" BORDER="0" HEIGHT="4"></TD></TR>
      </TABLE>
      <CENTER>
        <TABLE SUMMARY="Change Month">
          <TR>
            <TD>
              <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
<% if (bIsGuest)        
     out.write("              <A HREF=\"#\" onClick=\"alert('Your credential level as Guest does not allow you to perform this action')\" CLASS=\"linkplain\" TITLE=\"New Activity\">New</A>");
   else
     out.write("              <A HREF=\"#\" onClick=\"createMeeting();return false\" CLASS=\"linkplain\" TITLE=\"New Activity\">New</A>");
%>
            </TD>
            <TD>
              <IMG SRC="../images/images/spacer.gif" WIDTH="32" HEIGHT="1" BORDER="0">&nbsp;
	    </TD>
            <TD NOWRAP>
              <SELECT NAME="sel_month" CLASS="combomini"><OPTION VALUE="0">January</OPTION><OPTION VALUE="1">February</OPTION><OPTION VALUE="2">March</OPTION><OPTION VALUE="3">April</OPTION><OPTION VALUE="4">May</OPTION><OPTION VALUE="5">June</OPTION><OPTION VALUE="6">July</OPTION><OPTION VALUE="7">August</OPTION><OPTION VALUE="8">September</OPTION><OPTION VALUE="9">October</OPTION><OPTION VALUE="10">November</OPTION><OPTION VALUE="11">December</OPTION></SELECT>
              <SELECT NAME="sel_year" CLASS="combomini"><OPTION VALUE="108">2008</OPTION><OPTION VALUE="109">2009</OPTION><OPTION VALUE="110">2010</OPTION><OPTION VALUE="111">2011</OPTION><OPTION VALUE="112">2012</OPTION><OPTION VALUE="113">2013</OPTION><OPTION VALUE="114">2014</OPTION></SELECT>
              &nbsp;<A CLASS="linkplain" HREF="javascript:window.location='month_schedule.jsp?id_domain=' + getURLParam('id_domain') + '&gu_workarea=' + getURLParam('gu_workarea') + '&gu_fellow=' + getCombo(document.forms[0].sel_fellow) + '&selected=' + getURLParam('selected') + '&subselected=' + getURLParam('subselected') + '&year=' + getCombo(document.forms[0].sel_year) + '&month=' + getCombo(document.forms[0].sel_month) + '&screen_width=' + screen.width;">View other month</A>
            </TD>
          </TR>
        </TABLE>
        <TABLE SUMMARY="Days of the Month" CELLSPACING="0" CELLPADDING="2" CLASS="tableborder">
        <TR>
<% for (int d=0; d<7; d++) { %>
          <TD ALIGN="center" CLASS="tableborder"><FONT CLASS="formstrong"><% out.write (Calendar.WeekDayName((d+iFirstDayOfWeek)%7+1, sLanguage)); %></FONT></TD>
<% } %>
        </TR>
<%      	
        FirstDay = (dtToday.getDay()+6-iFirstDayOfWeek)%7;
        CurrentDay = 1;
	
	for (int row=0; row<6; row++) {
	    out.write("          <TR HEIGHT=\"" + String.valueOf(48f*fScreenRatio) + "\">\n");
	    
	    for (int col=0; col<7; col++) {
	      
          if ((CurrentDay<=LastDay) && (0!=row || col>FirstDay)) {
				    Boolean bWorkDay;
						if (null!=oWCal)
	            bWorkDay = oWCal.isWorkingDay(new Date(year, month, CurrentDay));
	          else
	            bWorkDay = bWorkDay = Boolean.TRUE;

	        if (null==bWorkDay) bWorkDay = Boolean.TRUE;

	        out.write("            <TD VALIGN=\"top\" CLASS=\"tableborder"+(bWorkDay.booleanValue() ? "" : " formback")+"\" WIDTH=\"" + String.valueOf(100f*fScreenRatio) + "\">\n");

                if (iLastMeeting==iMeetCount)

                    // ================================
                    // Highlight today with a red border.
                    // Author : Eugene Quah 20040515 eugene@quah.org
                    // ================================

                    if (year == dtNow.getYear() && month == dtNow.getMonth() && CurrentDay == dtNow.getDate())
                      out.write ("              <TABLE CLASS=\"formfront\" CELLSPACING=0 CELLPADDING=0 BORDER=0><TR VALIGN=\"top\"><TD CLASS=\"textsmall today\"  TITLE=\"Today\"><A HREF=\"javascript:jumpToDay('" + String.valueOf(CurrentDay) + "')\" CLASS=\"linksmall\"><B>" + String.valueOf(CurrentDay) + "</B></A></TD></TR><TR><TD></TD></TR></TABLE>");
                    else
                      out.write ("              <TABLE CLASS=\"formfront\" CELLSPACING=0 CELLPADDING=0 BORDER=0><TR VALIGN=\"top\"><TD CLASS=\"textsmall\"><A HREF=\"javascript:jumpToDay('" + String.valueOf(CurrentDay) + "')\" CLASS=\"linksmall\"><B>" + String.valueOf(CurrentDay) + "</B></A></TD></TR><TR><TD></TD></TR></TABLE>");

                    // =================================

                else if (oMeetings.getDate(1,iLastMeeting).getDate()>CurrentDay)

                    // ================================
		                // Highlight today with a red border.
		                // Author : Eugene Quah 20040515  eugene@quah.org
                    // ================================                    

                    if (year == dtNow.getYear() && month == dtNow.getMonth() && CurrentDay == dtNow.getDate())
		      			      out.write ("              <TABLE CLASS=\"formfront\" CELLSPACING=0 CELLPADDING=0 BORDER=0><TR VALIGN=\"top\"><TD CLASS=\"textsmall today\" TITLE=\"Today\"><A HREF=\"javascript:jumpToDay('" + String.valueOf(CurrentDay) + "')\" CLASS=\"linksmall\"><B>" + String.valueOf(CurrentDay) + "</B></A></TD></TR><TR><TD></TD></TR></TABLE>");
		                else
		                  out.write ("              <TABLE CLASS=\"formfront\" CELLSPACING=0 CELLPADDING=0 BORDER=0><TR VALIGN=\"top\"><TD CLASS=\"textsmall\"><A HREF=\"javascript:jumpToDay('" + String.valueOf(CurrentDay) + "')\" CLASS=\"linksmall\"><B>" + String.valueOf(CurrentDay) + "</B></A></TD></TR><TR><TD></TD></TR></TABLE>");

		                // ================================

		else {
                  out.write ("              <TABLE CLASS=\"formfront\" CELLSPACING=0 CELLPADDING=0 BORDER=0><TR VALIGN=\"top\"><TD>");
                  out.write ("<A HREF=\"javascript:jumpToDay('" + String.valueOf(CurrentDay) + "')\" CLASS=\"linksmall\"><B>" + String.valueOf(CurrentDay) + "</B></A></TD></TR><TR><TD>");
                  do {
                    if (bItsMe || oMeetings.getShort(2,iLastMeeting)==(short)0) {
                      out.write ("<A HREF=\"#\" TITLE=\""+oMeetings.getStringNull(4,iLastMeeting,"").replace('\n',' ').replace('\r',' ')+"\"CLASS=\"linksmall\" onClick=\"modifyMeeting('" + oMeetings.getString(0,iLastMeeting) + "');return false\" >" + DBBind.escape(oMeetings.getDate(1,iLastMeeting),"shortTime") + " " + oMeetings.getStringNull(3,iLastMeeting,"") + "</A><BR>");

               		  if (bItsMe)
                      if (bIsGuest && !bIsAdmin)
                        out.write("<FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"#\" onClick=\"alert('Your credential level as Guest does not allow you to perform this action')\" TITLE=\"Delete\">x</A>]</FONT><BR>\n");
                 		  else if (!bIsAdmin && !oMeetings.getString(0,iLastMeeting).equals(getCookie(request, "userid", "")))
                        out.write("<FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"#\" onClick=\"alert('It is not allowed to delete activities not created by you')\" TITLE=\"Delete\">x</A>]</FONT><BR>\n");
                 		  else
                   		  out.write("<FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"javascript:deleteMeeting('" + oMeetings.getString(DB.gu_meeting,iLastMeeting) + "','" + oMeetings.getStringNull(DB.tx_meeting,iLastMeeting,"Untitled").replace((char)39,'´') + "','"+String.valueOf(oMeetings.getDate(1,iLastMeeting).getDate())+"')\" TITLE=\"Delete\">x</A>]</FONT><BR>\n");
                    } else {
                      out.write ("<FONT CLASS=\"textsmall\">" + DBBind.escape(oMeetings.getDate(1,iLastMeeting),"shortTime") + "</FONT><IMG SRC=\"../images/images/addrbook/smalllock.gif\" BORDER=\"0\"><BR>");
                    }

                    if (++iLastMeeting==iMeetCount) break;
                  } while (oMeetings.getDate(1,iLastMeeting).getDate()<=CurrentDay);
                  out.write ("</TD></TR></TABLE>");
		  
		}
		                
                CurrentDay++;
	      } else {
	        out.write("            <TD VALIGN=\"top\" CLASS=\"tableborder\" WIDTH=\"" + String.valueOf(100f*fScreenRatio) + "\">\n");	      
	      }
	      out.write("            </TD>\n");
	    }
	    out.write("          </TR>\n");
	}	  
%>
        </TABLE>        
      </CENTER>      
    </FORM>
</BODY>
</HTML>
<%
  oConn.close("monthschedule"); 
  oConn = null;
%>
<%@ include file="../methods/page_epilog.jspf" %>