<%@ page import="java.util.Date,java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Calendar" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

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

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "default");
  String sFace = nullif(request.getParameter("face"),getCookie(request,"face","crm"));    
  String id_domain = request.getParameter("id_domain"); 
  String gu_workarea = request.getParameter("gu_workarea"); 
  String sFellow = nullif(request.getParameter("gu_fellow"), getCookie(request, "userid", ""));
  boolean bItsMe = sFellow.equals(getCookie(request, "userid", ""));

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
  dtToday.setHours(0); dtToday.setMinutes(0); dtToday.setSeconds(0) ;
  dtToday.setTime((dtToday.getTime()/1000l)*1000l); // [~//truncar los milisegundos~]

  Date dtMidnight = new Date(dtToday.getTime());
  dtMidnight.setHours(23); dtMidnight.setMinutes(59); dtMidnight.setSeconds(59);

  Date dtYesterday = new Date(dtToday.getTime()-24*60*60*1000);
  Date dtTomorrow  = new Date(dtToday.getTime()+24*60*60*1000);

  String sToday = DBBind.escape(dtToday, "shortDate");
    
  String sDay=null,sMonth=null;
    
  try {
    sDay = Calendar.WeekDayName(dtToday.getDay()+1, sLanguage);
    sMonth = Calendar.MonthName(dtToday.getMonth(), sLanguage);
  }
  catch (IllegalArgumentException iae) {
    sDay = Calendar.WeekDayName(dtToday.getDay()+1, "en");
    sMonth = Calendar.MonthName(dtToday.getMonth(), "en");
  }

  if (null==sDay) return;             
  int iBookCount = 0;
  int iRoomCount = 0;  
  DBSubset oBooked = null;
  DBSubset oAllRooms = null;

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("roomlisting");  
    
    oBooked = new DBSubset (DB.k_meetings + " m," + DB.k_rooms + " r," + DB.k_x_meeting_room + " x," + DB.k_fellows + " f", 
      			   "r." + DB.tp_room + ",r." + DB.nm_room + ",m." + DB.dt_start + ",m." + DB.dt_end + ",f." + DB.tx_name + ",f." + DB.tx_surname + ",f." + DB.gu_fellow,
      			   "m." + DB.gu_workarea+ "='" + gu_workarea + "' AND r." + DB.gu_workarea + "='" + gu_workarea + "' AND m." + DB.gu_meeting + "=x." + DB.gu_meeting + " AND r." + DB.nm_room + "=x." + DB.nm_room + " AND m." + DB.gu_fellow + "=f." + DB.gu_fellow + " AND m." + DB.dt_start + " BETWEEN " + DBBind.escape(dtToday, "ts") + " AND " + DBBind.escape(dtMidnight, "ts") + " ORDER BY 2,3",
      			   10);
    iBookCount = oBooked.load (oConn);    

    oAllRooms = new DBSubset (DB.k_rooms,
      			      DB.tp_room + "," + DB.nm_room+","+DB.bo_available,
      			      DB.gu_workarea+ "='" + gu_workarea + "' ORDER BY 1,2",
      			      10);
    iRoomCount = oAllRooms.load(oConn);    
  }
  catch (SQLException e) {  
    oBooked = null;
    if (null!=oConn)
      oConn.close("roomlisting");

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }

    oConn = null;
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  if (null==oConn) return;

%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Rooms and Resources</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/findit.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      var intervalId;
      var wincalendar;

      var activity_edition_page = "<% out.write(sFace.equalsIgnoreCase("healthcare") ? "appointment_edit_f.htm" : "meeting_edit_f.htm"); %>";

      function findCalendar() {
        var dt;
        
        if (wincalendar.closed) {
          clearInterval(intervalId);
          dt = document.forms[0].newdate.value.split("-");
          if (!isNaN(parseInt(dt[0])))
            window.location = "room_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=" + String(parseInt(dt[0])-1900) + "&month=" + String(parseInt(dt[1])-1) + "&day=" + dt[2];
        }
      } // findCalendar() 
           
      function showCalendar(ctrl) {       
        var dtnw = new Date();

        wincalendar = window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "schedulecalendar", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
        intervalId = setInterval ("findCalendar()", 100);
      } // showCalendar()
  
      // ----------------------------------------------------
        	
      function modifyFellow(id,nm) {	  
	      self.open ("fellow_edit.jsp?id_domain=<%=id_domain%>&n_domain=&gu_fellow=" + id + "&n_fellow=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editfellow", "directories=no,toolbar=no,menubar=no,width=640,height=" + (screen.height<=600 ? "520" : "600"));
      }

      // ----------------------------------------------------

      function showDay() {	  
	      window.location = "schedule.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected")+ "&year=<%=dtToday.getYear()%>&month=<%=dtToday.getMonth()%>&day=<%=dtToday.getDate()%>";
      }

      // ------------------------------------------------------

      function showWeek() {
        window.location = "week_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&gu_fellow=<%=sFellow%>&screen_width=" + String(screen.width);
      }

      // ----------------------------------------------------

      function showYesterday() {	  
	      window.location = "room_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected")+ "&year=<%=dtYesterday.getYear()%>&month=<%=dtYesterday.getMonth()%>&day=<%=dtYesterday.getDate()%>";
      }

      // ----------------------------------------------------

      function showTomorrow() {	  
	      window.location = "room_schedule.jsp?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected")+ "&year=<%=dtTomorrow.getYear()%>&month=<%=dtTomorrow.getMonth()%>&day=<%=dtTomorrow.getDate()%>";
      }

      // ----------------------------------------------------

      function bookRoom(nm) {	  
        window.open(activity_edition_page+"?id_domain=" + getURLParam("id_domain") + "&gu_workarea=" + getURLParam("gu_workarea") + "&gu_fellow=" + getCookie("userid") + "&nm_room=" + escape(nm) + "&date=<%=sToday%>", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=500,height=580");
      }

      // ------------------------------------------------------
      
      function showMonth() {
        window.location = "month_schedule.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&gu_fellow=<%=sFellow%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&year=<%=year%>&month=<%=month%>&screen_width=" + String(screen.width);
      }
	
      // ------------------------------------------------------	

    //-->    
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
    <%@ include file="../common/tabmenu.jspf" %>
    <BR>
    <TABLE WIDTH="<%=iTabWidth*iActive%>" CELLSPACING="0" CELLPADDING="0" BORDER="0">
      <TR>
        <TD CLASS="striptitle"><FONT CLASS="title1">Rooms and Resources</FONT></TD>
        <TD ALIGN="right" CLASS="striptitle"><FONT CLASS="title1"><%=sDay%>&nbsp;<%=dtToday.getDate()%>&nbsp;from&nbsp;<%=sMonth%>&nbsp;de&nbsp;<%=dtToday.getYear()+1900%></FONT></TD>
      </TR>    
    </TABLE>  
    <FORM onSubmit="return false">
      <INPUT TYPE="hidden" NAME="newdate">
      <TABLE CELLSPACING="2" CELLPADDING="2" BORDER="0">
      <TR><TD BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR><TD><FONT CLASS="textplain">Ver&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showDay()">day&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showWeek()">&nbsp;week&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="view" onClick="showMonth()">&nbsp;month&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="rooms" CHECKED>&nbsp;Rooms and Resources</FONT></TD></TR>
      <TR><TD BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE BGCOLOR="white" CELLSPACING="0" CELLPADDING="0" BORDER="0">
        <TR VALIGN="middle">
          <TD WIDTH="20px" HEIGHT="30px">
            <IMG SRC="../images/images/addrbook/calendar.gif" BORDER="0">
          </TD>
          <TD HEIGHT="30px">
            <A HREF="#" onClick="showCalendar('newdate');" CLASS="linkplain">Calendar</A>
          </TD>
          <TD HEIGHT="30px"><IMG SRC="../images/images/spacer.gif" WIDTH="12" BORDER="0"></TD>
          <TD HEIGHT="30px">
            <IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search">
          </TD>
          <TD HEIGHT="30px">
      	    &nbsp;<INPUT TYPE="text" NAME="txt_find" MAXLENGTH="30" SIZE="10">
          </TD>
          <TD HEIGHT="30px">
      	    <A HREF="javascript:findit(document.forms[0].txt_find.value)" CLASS="linkplain">Search</A>
          </TD>
          <TD HEIGHT="30px"><IMG SRC="../images/images/spacer.gif" WIDTH="12" BORDER="0"></TD>
          <TD HEIGHT="30px" ALIGN="right">
            <A HREF="room_schedule.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&year=<%=dtYesterday.getYear()%>&month=<%=dtYesterday.getMonth()%>&day=<%=dtYesterday.getDate()%>" CLASS="linkplain">Yesterday</A>&nbsp;&nbsp;<A HREF="room_schedule.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>&year=<%=dtTomorrow.getYear()%>&month=<%=dtTomorrow.getMonth()%>&day=<%=dtTomorrow.getDate()%>" CLASS="linkplain">Tomorrow</A>
          </TD>
        </TR>
      </TABLE>
      <BR>
      <FONT CLASS="textplain">
<%
	  String sRoomTp,sRoomNm,sLocation,sStart,sEnd,sFellowNm;
	  int iMins;
	  int iBooked;
	  int iRoom;
	  boolean bFirst;
	  
	  for (int i=0; i<iRoomCount; i++) {
	    iBooked = oBooked.find(1, oAllRooms.get(1,i));
	    
	    if (-1==iBooked) {
	      sRoomTp = oAllRooms.getStringNull(0,i,"");
              if (sRoomTp.length()>0)
                sRoomTp = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_rooms_lookup, gu_workarea, "tp_room", sLanguage, sRoomTp) + " ";

              if (oAllRooms.getShort(2,i)==(short)0) {
                out.write("<FONT CLASS=\"textplainlight\"><B><BIG>" + sRoomTp + oAllRooms.getString(1,i) + "</BIG></B></FONT><BR>");
                out.write("<FONT CLASS=\"textplain\">this resource is out of order</FONT>&nbsp;");
              } else {
                out.write("<FONT CLASS=\"textplain\"><B><BIG>" + sRoomTp + oAllRooms.getString(1,i) + "</BIG></B></FONT><BR>");
                out.write("<FONT COLOR=\"green\"><B>free</B></FONT>&nbsp;");
                out.write("<A CLASS=\"linkplain\" HREF=\"#\" onClick=\"bookRoom('" + oAllRooms.getString(1,i) + "');return false\">book</A>");
              }
              out.write("<HR>");	    
	    }
	    else {
	      bFirst = true;	  
              do {        
                sRoomTp = oBooked.getStringNull(0,iBooked,"");
                if (sRoomTp.length()>0)
                  sRoomTp = DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_rooms_lookup, gu_workarea, "tp_room", sLanguage, sRoomTp);

                sRoomNm = oBooked.getString(1,iBooked);

                sStart = String.valueOf(oBooked.getDate(2,iBooked).getHours()) + ":";             
                iMins = oBooked.getDate(2,iBooked).getMinutes();
                if (iMins<10)
                  sStart += "0" + String.valueOf(iMins);
                else
                  sStart += String.valueOf(iMins);
            
                sEnd = String.valueOf(oBooked.getDate(3,iBooked).getHours()) + ":";             
                iMins = oBooked.getDate(3,iBooked).getMinutes();
                if (iMins<10)
                  sEnd += "0" + String.valueOf(iMins);
                else
                  sEnd += String.valueOf(iMins);

                sFellowNm = oBooked.getStringNull(4,iBooked,"") + " " + oBooked.getStringNull(5,iBooked,"");
                sFellowNm = sFellowNm.trim();
            
            	if (bFirst) {
                  out.write("<B><BIG>" + sRoomTp + " " + sRoomNm + "</BIG></B><BR>");
                  bFirst = false;
                }
                
                out.write("booked from&nbsp;" + sStart + " to&nbsp;" + sEnd + " by&nbsp;<A HREF=\"#\" CLASS=\"linkplain\" onClick=\"modifyFellow('" + oBooked.getString(6,iBooked) + "')\">" + sFellowNm + "</A><BR>");

                if (++iBooked>=iBookCount) break;                
              } while (sRoomNm.equals(oBooked.get(1,iBooked)));
              out.write("<A CLASS=\"linkplain\" HREF=\"#\" onClick=\"bookRoom('" + sRoomNm + "'); return false\">book</A>");
              out.write("<HR>");
            } // fi (iBooked)
	} // next(i)
%>          	  
      </FONT>
    </FORM>
</BODY>
</HTML>
<%
  oConn.close("roomlisting"); 
  oConn = null;
%><%@ include file="../methods/page_epilog.jspf" %>