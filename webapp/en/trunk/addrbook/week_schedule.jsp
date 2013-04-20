<%@ page import="java.util.Date,java.util.GregorianCalendar,java.text.SimpleDateFormat,java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Calendar,com.knowgate.misc.Environment,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Address,com.knowgate.billing.Account,com.knowgate.addrbook.Fellow,com.knowgate.addrbook.Meeting,com.knowgate.addrbook.Room,com.knowgate.addrbook.WeekPlan,com.knowgate.addrbook.WorkingCalendar,com.knowgate.crm.Company,com.knowgate.misc.Gadgets,com.knowgate.gdata.GCalendarSynchronizer" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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

  int iFirstDayOfWeek;
	if (sLanguage.startsWith("es"))
	  iFirstDayOfWeek = 1;
	else
	  iFirstDayOfWeek = 0;

  String id_domain = request.getParameter("id_domain"); 
  String gu_workarea = request.getParameter("gu_workarea"); 

  int iIdDomain = Integer.parseInt(id_domain);
  String sFellow = nullif(request.getParameter("gu_fellow"), getCookie(request, "userid", ""));
  boolean bItsMe = sFellow.equals(getCookie(request, "userid", ""));
  short iViewType = Short.parseShort(nullif(request.getParameter("viewtype"),"20"));
  String sViewFor = (nullif(request.getParameter("viewfor"),sFellow));

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
  int year, month, day;

  if (request.getParameter("year")==null)
    year = dtNow.getYear();
  else
    year = Integer.parseInt(request.getParameter("year"));

  if (request.getParameter("month")==null)
    month = dtNow.getMonth();
  else
    month = Integer.parseInt(request.getParameter("month"));
  if (-1==month) month = dtNow.getMonth();

  if (request.getParameter("day")==null)
    day = dtNow.getDate();
  else
    day = Integer.parseInt(request.getParameter("day"));
  
  Date dtFirstWeekDay = new Date(year,month,day,0,0,0);
  while (dtFirstWeekDay.getDay()!=iFirstDayOfWeek) {
    if (--day==0) {
      year  = (month==0 ? year-1 : year);
      month = (month==0 ? 11 : month-1);
      day   = (month==0 ? 31 : com.knowgate.misc.Calendar.LastDay(month, year+1900));
    }
    dtFirstWeekDay = new Date(year,month,day,0,0,0);
  } // wend

  final long lOneDayMilis = 24l*60l*60l*1000l;
  Date dtPrevWeek = new Date (dtFirstWeekDay.getTime()-(lOneDayMilis*7l));
  Date dtNextWeek = new Date (dtFirstWeekDay.getTime()+(lOneDayMilis*7l));

  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");
  
  int iMeetCount = 0;
  int iLastMeeting = 0;
  DBSubset oMeetings = null;
  DBSubset oFellowList = null;
  int iFellowCount = 0;
  WorkingCalendar oWCal = null;
  WeekPlan oWeekPlan = null;
  Fellow[] aAssistingFellows = null;
  Address[] aLocationAddresses = null;
  Room[] aUsedRooms = null;
  Meeting[] aMeetings = null;
    
  final String sCorporateAccount = "C";  
  
  JDCConnection oConn = null;

  boolean bIsGuest = true;
    
  try {
    oConn = GlobalDBBind.getConnection("weekschedule");  

    oWCal = WorkingCalendar.forUser(oConn, sFellow, dtFirstWeekDay, dtNextWeek, sLanguage, null);

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);

    // Read meetings from Google Calendar if synchronization is activated and a valid email+password+calendar name is found at k_user_pwd table
    final String sGDataSync = GlobalDBBind.getProperty("gdatasync", "1");
    if (sGDataSync.equals("1") || sGDataSync.equalsIgnoreCase("true") || sGDataSync.equalsIgnoreCase("yes")) {
      GCalendarSynchronizer oGSync = new GCalendarSynchronizer();
      if (oGSync.connect(oConn, sFellow, gu_workarea, GlobalCacheClient)) {
        oGSync.readMeetingsFromGoogle(oConn, dtFirstWeekDay, dtNextWeek);
      } // fi
    } // fi

    if (sCorporateAccount.equals(Account.getUserAccountType(oConn, getCookie(request, "userid", "")))) {
      oWeekPlan = new WeekPlan(iIdDomain, dtFirstWeekDay);
    } else {
      oWeekPlan = new WeekPlan(iIdDomain, gu_workarea, dtFirstWeekDay);    
    }// fi

    aAssistingFellows = oWeekPlan.getDistinctFellows(oConn);
    aLocationAddresses = oWeekPlan.getDistinctAddresses(oConn);
    aUsedRooms = oWeekPlan.getDistinctRooms(oConn);

    switch (iViewType) {
      case Fellow.ClassId:
        iMeetCount = oWeekPlan.loadMeetingsForFellow(oConn, sViewFor);
        break;
      case Room.ClassId:
        iMeetCount = oWeekPlan.loadMeetingsForRoom(oConn, sViewFor);
        break;
      case Address.ClassId:
        iMeetCount = oWeekPlan.loadMeetingsForAddress(oConn, sViewFor);
        break;
      case Company.ClassId:
        Company oComp = new Company(oConn, sViewFor);
        DBSubset oAddrs = oComp.getAddresses(oConn);
        if (oAddrs.getRowCount()>0)
          iMeetCount = oWeekPlan.loadMeetingsForAddress(oConn, oAddrs.getString(DB.gu_address,0));
			  else
			  	iMeetCount = 0;
        break;
    }

%><%@ include file="schedule_fellows_boilerplate.jspf" %><%


  }
  catch (Exception e) {
  
    if (null!=oConn)
      oConn.close("weekschedule");

    oConn = null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Weekly Calendar</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      var activity_edition_page = "<% out.write(sFace.equalsIgnoreCase("healthcare") ? "appointment_edit_f.htm" : "meeting_edit_f.htm"); %>";

      // ------------------------------------------------------
      
      function createMeeting(day) {
        window.open(activity_edition_page+"?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=" + getCookie("userid") + (day.length>0 ? "&date="+day : ""), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }

      // ------------------------------------------------------
      
      function modifyMeeting(gu) {
        window.open(activity_edition_page+"?id_domain=" + getURLParam("id_domain") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getURLParam("gu_workarea") + "&gu_fellow=" + getCookie("userid") + "&gu_meeting=" + gu, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }

      // ------------------------------------------------------
      
      function deleteMeeting(gu,tx) {
        if (tx) {
          if (confirm("Are you sure that you want to delete activity  " + tx + "?"))
            window.location = "meeting_edit_delete.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&gu_meeting=" + gu + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&day=<%=day%>&referer=week_schedule";
	      } else {
          if (confirm("Are you sure that you want to delete activity ?"))
            window.location = "meeting_edit_delete.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&gu_meeting=" + gu + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&day=<%=day%>&referer=week_schedule";
	      }
      }
  
      // ----------------------------------------------------

      function showDay() {	  
	  window.location = "schedule.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=<%=sFellow%>";
      }

      // ------------------------------------------------------

      function showWeek(y,m,d,v) {
        var viewfor = v.split(";");
        window.location = "week_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=<%=sFellow%>&year="+ y + "&month=" + m + "&day=" + d + "&viewtype=" + viewfor[0] + "&viewfor=" + viewfor[1] + "&screen_width=" + String(screen.width);
      }

      // ----------------------------------------------------
      
      function showMonth() {
        window.location = "month_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&gu_fellow=<%=sFellow%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&screen_width=" + String(screen.width);
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
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function setCombos() {
        var frm = document.forms[0];        
        setCombo(frm.sel_fellow,"<% out.write(String.valueOf(iViewType)+";"+sViewFor); %>");
      } //  setCombos()
    //-->    
  </SCRIPT>
  <STYLE type="text/css">
  <!--
    .microlink { color:red;Arial,Helvetica,sans-serif;font-size:8pt;text-decoration:none;
    }
  -->
  </STYLE>  
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <%@ include file="../common/tabmenu.jspf" %>
    <BR>
    <FORM>
      <TABLE SUMMARY="Header" WIDTH="<%=iTabWidth*iActive%>" CELLSPACING="0" CELLPADDING="0" BORDER="0">
        <TR>
          <TD CLASS="striptitle"><FONT CLASS="title1">Calendar</FONT></TD>
          <TD ALIGN="right" CLASS="striptitle"><FONT CLASS="title1"><%=localeDateFormat(gu_workarea,GlobalCacheClient,GlobalDBBind).format(dtFirstWeekDay)%> &gt;&gt; <%=localeDateFormat(gu_workarea,GlobalCacheClient,GlobalDBBind).format(new Date(dtFirstWeekDay.getTime()+lOneDayMilis*7l))%></FONT></TD>
        </TR>
      </TABLE>
      <INPUT TYPE="hidden" NAME="newdate">
      <TABLE CELLSPACING="2" CELLPADDING="2" BORDER="0">
      <TR><TD COLSPAN="2" HEIGHT="4"><IMG SRC="../images/images/spacer.gif" BORDER="0" HEIGHT="4"></TD></TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD>
          <FONT CLASS="textplain">Show&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showDay()">day&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" CHECKED>&nbsp;week&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onclick="showMonth()">&nbsp;month&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="rooms" onClick="showRooms()">&nbsp;Resources and Rooms</FONT>
        </TD>
        <TD>
          <SELECT NAME="sel_fellow" CLASS="combomini" onChange="showWeek('<%=year%>','<%=month%>','<%=day%>',this.options[this.selectedIndex].value)">	  
<%    
	  int iLoggedFellow = oFellowList.find(0,sFellow);

    out.write("<OPTION VALUE=\"" + String.valueOf(Fellow.ClassId) + ";" + sFellow + "\">" + oFellowList.getStringNull(DB.tx_name,iLoggedFellow,"") + " " + oFellowList.getStringNull(DB.tx_surname,iLoggedFellow,"") + "</OPTION>");

	  String sClassName;
	  if (null!=aAssistingFellows) {
	    sClassName = String.valueOf(Fellow.ClassId);
	    out.write("<OPTGROUP LABEL=\"People\">");
            for (int f=0; f<aAssistingFellows.length; f++) {
              if (!aAssistingFellows[f].getString(DB.gu_fellow).equals(sFellow)) {
                out.write("<OPTION VALUE=\"" + sClassName + ";" + aAssistingFellows[f].getString(DB.gu_fellow) + "\">" + aAssistingFellows[f].getStringNull(DB.tx_name,"") + " " + aAssistingFellows[f].getStringNull(DB.tx_surname,"") + "</OPTION>");
              } // fi
            } // next
	  } // fi

	  if (null!=aUsedRooms) {
	    sClassName = String.valueOf(Room.ClassId);
	    out.write("<OPTGROUP LABEL=\"Resource\">");
            for (int r=0; r<aUsedRooms.length; r++) {
              out.write("<OPTION VALUE=\"" + sClassName + ";" + aUsedRooms[r].getString(DB.nm_room) + "\">" + aUsedRooms[r].getString(DB.nm_room) + "</OPTION>");
            }
	  } // fi

	  if (null!=aLocationAddresses) {
	    sClassName = String.valueOf(Address.ClassId);
	    out.write("<OPTGROUP LABEL=\"Addresses\">");
            for (int a=0; a<aLocationAddresses.length; a++) {
	      if (sLanguage.startsWith("es"))
                out.write("<OPTION VALUE=\"" + sClassName + ";" + aLocationAddresses[a].getString(DB.gu_address) + "\">" + aLocationAddresses[a].getStringNull(DB.tp_street,"") + " " + aLocationAddresses[a].getStringNull(DB.nm_street,"") + " " + aLocationAddresses[a].getStringNull(DB.nu_street,"") + "</OPTION>");
              else
                out.write("<OPTION VALUE=\"" + sClassName + ";" + aLocationAddresses[a].getString(DB.gu_address) + "\">" + aLocationAddresses[a].getStringNull(DB.nu_street,"") + " " + aLocationAddresses[a].getStringNull(DB.nm_street,"") + " " + aLocationAddresses[a].getStringNull(DB.tp_street,"") + "</OPTION>");
            }
	  } // fi
      
%>
          </SELECT>
        </TD>
      </TR>
      <TR><TD COLSPAN="2" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR><TD COLSPAN="2" HEIGHT="4"><IMG SRC="../images/images/spacer.gif" BORDER="0" HEIGHT="4"></TD></TR>
      </TABLE>
      <TABLE SUMMARY="Change week" ALIGN="center">
        <TR>
          <TD>
            <IMG SRC="../images/images/new16x16.gif" BORDER="0">&nbsp;
<% if (bIsGuest)        
     out.write("              <A HREF=\"#\" onClick=\"alert('Your priviledge level as Guest does not allow you to perform this action')\" CLASS=\"linkplain\" TITLE=\"New Activity\">New</A>");
   else
     out.write("              <A HREF=\"#\" onClick=\"createMeeting('');return false\" CLASS=\"linkplain\" TITLE=\"New Activity\">New</A>");
%>
          </TD>
          <TD>
            <IMG SRC="../images/images/spacer.gif" WIDTH="32" HEIGHT="1" BORDER="0">&nbsp;
	  </TD>
          <TD NOWRAP>
            <A CLASS="linkplain" HREF="#" onclick="showWeek('<%=dtPrevWeek.getYear()%>','<%=dtPrevWeek.getMonth()%>','<%=dtPrevWeek.getDate()%>','<%=String.valueOf(iViewType)+";"+sViewFor%>')">Previous Week</A>
            &nbsp;&nbsp;&nbsp;
            <A CLASS="linkplain" HREF="#" onclick="showWeek('<%=dtNextWeek.getYear()%>','<%=dtNextWeek.getMonth()%>','<%=dtNextWeek.getDate()%>','<%=String.valueOf(iViewType)+";"+sViewFor%>')">Next Week</A>
          </TD>
        </TR>
      </TABLE>
      <TABLE SUMMARY="Week Days" ALIGN="center" CLASS="tableborder">
        <TR>
<%
	  String[] aHolidays = new String[]{"","","","","","",""};
  	  Boolean bWorkDay;
	  if (oWCal!=null) {
	    for (int h=0; h<=6; h++) {
	      bWorkDay = oWCal.isWorkingDay(dtFirstWeekDay.getTime()+(lOneDayMilis*(long)h));
	      if (null!=bWorkDay) {
	        if (!bWorkDay.booleanValue()) aHolidays[h] = "formback ";
	      } // fi	    
	    } // next
          }

    int iMonthDay = day;
	  for (int d=0; d<=6; d++) {
	    if (iMonthDay==0) {
	      if (month==0)
	        iMonthDay=31;
	      else
	      	iMonthDay = com.knowgate.misc.Calendar.LastDay(month-1, year+1900);
	    }	  
	    if (iMonthDay>com.knowgate.misc.Calendar.LastDay(month, year+1900)) iMonthDay = 1;	  
	    out.write("<TD CLASS=\"" + aHolidays[d] + "textstrong\" ALIGN=\"center\"><A HREF=\"\" CLASS=\"linknodecor\" onclick=\"createMeeting('"+String.valueOf(year+1900)+"-"+Gadgets.leftPad(String.valueOf(month),'0',2)+"-"+Gadgets.leftPad(String.valueOf(iMonthDay),'0',2)+"')\">"+Calendar.WeekDayName(((d+iFirstDayOfWeek)%7)+1,sLanguage)+" "+String.valueOf(iMonthDay++)+"</A></TD>");
	  }
%>
        </TR>
	<TR>
<%
	  for (int d=0; d<=6; d++) {
	    aMeetings = oWeekPlan.getMeetingsForFirstHalfDayOfWeek((iFirstDayOfWeek+d)%7);
	    if (null!=aMeetings) {
        out.write("<TD CLASS=\""+aHolidays[d]+"tableborder\" WIDTH=\"100px\">");
	      int nMeets = aMeetings.length;
	      for (int m=0; m<nMeets; m++) {
	        Meeting oMeet = aMeetings[m];
					if (bItsMe || oMeet.getShort(DB.bo_private)==(short)0) {
	          out.write("<FONT CLASS=\"textsmall\">"+(0==m ? "" : "<BR>")+oMeet.getHour()+":"+oMeet.getMinute()+"-"+oMeet.getHourEnd()+":"+oMeet.getMinuteEnd()+"&nbsp;<A CLASS=\"linksmall\" TITLE=\""+oMeet.getStringNull(DB.de_meeting,"").replace('\n',' ').replace('\r',' ').replace('"',' ')+"\" HREF=\"#\" onclick=\"modifyMeeting('"+oMeet.getString(DB.gu_meeting)+"'); return false;\">"+oMeet.getStringNull(DB.tx_meeting,"")+"</A></FONT><FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"javascript:deleteMeeting('" + oMeet.getString(DB.gu_meeting) + "','" + oMeet.getStringNull(DB.tx_meeting,"Untitled").replace('"',' ').replace((char)39,'´') + "')\" TITLE=\"Delete\">x</A>]</FONT>");
	        } else {
	          out.write("<FONT CLASS=\"textsmall\">"+(0==m ? "" : "<BR>")+oMeet.getHour()+":"+oMeet.getMinute()+"-"+oMeet.getHourEnd()+":"+oMeet.getMinuteEnd()+"</FONT><IMG SRC=\"../images/images/addrbook/smalllock.gif\" BORDER=\"0\">");
	        }
	      } // next
	    } else {
              out.write("<TD CLASS=\""+aHolidays[d]+"tableborder\" WIDTH=\"100px\" HEIGHT=\"100px\">"); 
	    }// fi
            out.write("</TD>");
	  } // next
%>
        </TR>
        <TR><TD COLSPAN="7"><HR></TD></TR>
<%
	  for (int d=0; d<=6; d++) {
	    aMeetings = oWeekPlan.getMeetingsForSecondHalfDayOfWeek((iFirstDayOfWeek+d)%7);
	    if (null!=aMeetings) {
        out.write("<TD CLASS=\""+aHolidays[d]+"tableborder\" WIDTH=\"100px\">");
	      int nMeets = aMeetings.length;
	      for (int m=0; m<nMeets; m++) {
	        Meeting oMeet = aMeetings[m];
					if (bItsMe || oMeet.getShort(DB.bo_private)==(short)0) {
	          out.write("<FONT CLASS=\"textsmall\">"+(0==m ? "" : "<BR>")+oMeet.getHour()+":"+oMeet.getMinute()+"-"+oMeet.getHourEnd()+":"+oMeet.getMinuteEnd()+"&nbsp;<A CLASS=\"linksmall\" TITLE=\""+oMeet.getStringNull(DB.de_meeting,"").replace('\n',' ').replace('\r',' ').replace('"',' ')+"\" HREF=\"#\" onclick=\"modifyMeeting('"+oMeet.getString(DB.gu_meeting)+"'); return false;\">"+oMeet.getStringNull(DB.tx_meeting,"")+"</A></FONT><FONT CLASS=\"microlink\">&nbsp;[<A CLASS=\"microlink\" HREF=\"javascript:deleteMeeting('" + oMeet.getString(DB.gu_meeting) + "','" + oMeet.getStringNull(DB.tx_meeting,"Untitled").replace('"',' ').replace((char)39,'´') + "')\" TITLE=\"Delete\">x</A>]</FONT>");
	        } else {
	          out.write("<FONT CLASS=\"textsmall\">"+(0==m ? "" : "<BR>")+oMeet.getHour()+":"+oMeet.getMinute()+"-"+oMeet.getHourEnd()+":"+oMeet.getMinuteEnd()+"</FONT><IMG SRC=\"../images/images/addrbook/smalllock.gif\" BORDER=\"0\">");
	        }
	      } // next
	    } else {
              out.write("<TD CLASS=\""+aHolidays[d]+"tableborder\" WIDTH=\"100px\" HEIGHT=\"100px\">");
	    } // fi
            out.write("</TD>");
	  } // next
%>
      </TABLE>
    </FORM>
</BODY>
</HTML><%

  oConn.close("weekschedule"); 
  oConn = null;
  
%><%@ include file="../methods/page_epilog.jspf" %>