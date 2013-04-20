<i></i><%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.addrbook.WorkingCalendar" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
  String gu_calendar = request.getParameter("gu_calendar");

  String nu_selected = nullif(request.getParameter("nu_selected"),"1");
  String nu_subselected = nullif(request.getParameter("nu_subselected"),"6");

  Date dtNow = new Date();
  int year, year1, month, month1;
  String pyear, pmonth, nyear, nmonth;

  if (request.getParameter("year")==null)
    year = dtNow.getYear();
  else
    year = Integer.parseInt(request.getParameter("year"));

  year1 = year;

  if (request.getParameter("month")==null)
    month = dtNow.getMonth();
  else
    month = Integer.parseInt(request.getParameter("month"));
  if (-1==month) month = dtNow.getMonth();

  month1 = month;

	pyear = String.valueOf(month>0 ? year : year-1);
	pmonth = String.valueOf(month>0 ? month-1 : 11);
	nyear = String.valueOf(month<11 ? year : year+1);
	nmonth = String.valueOf(month<11 ? month+1 : 0);
	
  int iFirstDayOfWeek;
	if (sLanguage.startsWith("es"))
	  iFirstDayOfWeek = 1;
	else
	  iFirstDayOfWeek = 0;

  final long lOneDayMilis = 24l*60l*60l*1000l;
  int  FirstDay;   // First day of the month.
  int  CurrentDay; // Used to print dates in calendar
  int  LastDay;    // Last day of the month
  Date dtToday, dtNextM, dtLastD;
  String sMonth;
  
  JDCConnection oConn = null;
  WorkingCalendar oWCal = new WorkingCalendar(gu_calendar);
  DBPersist oCalendarInfo = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
  short[] aWCalDays = null;
  boolean bIsGuest = true;
  
  try {
    oConn = GlobalDBBind.getConnection("workcalendar_setdays");
    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
	  aWCalDays = oWCal.getWorkDaysArray(oConn, year+1900, month, 6); 

	  oCalendarInfo.load(oConn, gu_calendar);
	  
    oConn.close("workcalendar_setdays");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("workcalendar_setdays");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  final int nWCalDays = aWCalDays.length;
%>
<HTML>
	<HEAD>
    <TITLE>hipergate :: Six-monthly Calendar</TITLE>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
        var wcaldays = new Array(<% out.write(String.valueOf(aWCalDays[0])); for (int a=1; a<nWCalDays; a++) out.write(","+String.valueOf(aWCalDays[a])); %>);

        function toggle(d) {
          if (wcaldays[d-1]==0)
            wcaldays[d-1] = 1;
          else
            wcaldays[d-1] = -wcaldays[d-1];
					document.images["I"+String(d)].src = "../images/images/addrbook/"+(wcaldays[d-1]==-1 ? "checkedstatecheckbox13.gif" : "uncheckedstatecheckbox13.gif");          	
        }

        function toggleMonth(f,t,c) {
          for (var d=f; d<t; d++) {
            wcaldays[d] = c ? 1 : -1;
					  document.images["I"+String(d)].src = "../images/images/addrbook/"+(c ? "checkedstatecheckbox13.gif" : "uncheckedstatecheckbox13.gif");            
          }
        }

			  function validate() {
			  	var frm = document.forms[1];
			  	frm.workdays.value = wcaldays.join(",");
			  	
			  	if (frm.hh_start1.selectedIndex>0 && frm.mi_start1.selectedIndex<=0) {
			  	  alert ("Ending minute for morning timetable is required");
			  	  frm.mi_start1.focus();
			  	  return false;
			  	}
			  	if (frm.mi_start1.selectedIndex>0 && frm.hh_start1.selectedIndex<=0) {
			  	  alert ("Starting hour for morning timetable is required");
			  	  frm.hh_start1.focus();
			  	  return false;
			  	}
			  	if (frm.hh_start2.selectedIndex>0 && frm.mi_start2.selectedIndex<=0) {
			  	  alert ("Starting minute for morning timetable is required");
			  	  frm.mi_start2.focus();
			  	  return false;
			  	}
			  	if (frm.mi_start2.selectedIndex>0 && frm.hh_start2.selectedIndex<=0) {
			  	  alert ("Starting hour for morning timetable is required");
			  	  frm.hh_start2.focus();
			  	  return false;
			  	}
			  	if (frm.hh_end1.selectedIndex>0 && frm.mi_end1.selectedIndex<=0) {
			  	  alert ("Ending minute for morning timetable is required");
			  	  frm.mi_end1.focus();
			  	  return false;
			  	}
			  	if (frm.mi_end1.selectedIndex>0 && frm.hh_end1.selectedIndex<=0) {
			  	  alert ("Ending hour for morning timetable is required");
			  	  frm.hh_end1.focus();
			  	  return false;
			  	}
			  	if (frm.hh_end2.selectedIndex>0 && frm.mi_end2.selectedIndex<=0) {
			  	  alert ("Ending minute for evening timetable is required");
			  	  frm.mi_end2.focus();
			  	  return false;
			  	}
			  	if (frm.mi_end2.selectedIndex>0 && frm.hh_end2.selectedIndex<=0) {
			  	  alert ("Ending hour for evening timetable is required");
			  	  frm.hh_end2.focus();
			  	  return false;
			  	}
			  	if (frm.hh_start1.selectedIndex>0 && frm.hh_end1.selectedIndex<=0) {
			  	  alert ("Ending hour for morning timetable is required");			  	
			  	  frm.hh_end1.focus();
			  	  return false;
			  	}
			  	if (frm.hh_start2.selectedIndex>0 && frm.hh_end2.selectedIndex<=0) {
			  	  alert ("Ending hour for evening timetable is required");			  	
			  	  frm.hh_end2.focus();
			  	  return false;
			  	}
			  	if (frm.hh_end1.selectedIndex>0 && frm.hh_start1.selectedIndex<=0) {
			  	  alert ("Starting hour for morning timetable is required");			  	
			  	  frm.hh_start1.focus();
			  	  return false;
			  	}
			  	if (frm.hh_end2.selectedIndex>0 && frm.hh_start2.selectedIndex<=0) {
			  	  alert ("Starting hour for morning timetable is required");			  	
			  	  frm.hh_start2.focus();
			  	  return false;
			  	}
			  	if (Number(getCombo(frm.hh_start1))*100+Number(getCombo(frm.mi_start1))<Number(getCombo(frm.hh_end1))*100+Number(getCombo(frm.mi_end1))) {
			  	  alert ("Ending hour for morning timetable is required");
			  	  frm.hh_end1.focus();
			  	  return false;
			  	}
			  	if (Number(getCombo(frm.hh_start2))*100+Number(getCombo(frm.mi_start2))<Number(getCombo(frm.hh_end2))*100+Number(getCombo(frm.mi_end2))) {
			  	  alert ("Ending hour for evening timetable is required");
			  	  frm.hh_end1.focus();
			  	  return false;
			  	}

			  	return true;	  	
			  } // validate

      //-->
    </SCRIPT>
  </HEAD>
  <BODY>
    <%@ include file="../common/tabmenu.jspf" %>
    <BR>
    <FORM>
    <TABLE SUMMARY="Title" WIDTH="<%=iTabWidth*iActive%>" CELLSPACING="0" CELLPADDING="0" BORDER="0">
      <TR>
        <TD CLASS="striptitle"><FONT CLASS="title1">Edit working days&nbsp;::&nbsp;Calendar&nbsp;<%=oCalendarInfo.getString(DB.nm_calendar)%></FONT></TD>
      </TR>    
    </TABLE>
    <TABLE SUMMARY="Legend">
      <TR>
        <TD><IMG SRC="../images/images/addrbook/uncheckedstatecheckbox13.gif" WIDTH="13" HEIGHT="13" BORDER="1" ALT="Workingday"></TD><TD CLASS="textplain">=</TD><TD CLASS="textplain">Workingday</TD>
    	  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
    	  <TD><IMG SRC="../images/images/addrbook/checkedstatecheckbox13.gif" WIDTH="13" HEIGHT="13" BORDER="1" ALT="Holiday"></TD><TD CLASS="textplain">=</TD><TD CLASS="textplain">Holiday</TD>
    	</TR>
    </TABLE>    		
    <TABLE SUMMARY="Six Months">
      <TR>
<%
  int d = 0;
  for (int m=0; m<6; m++) { 
    dtToday = new Date(year, month, 1, 0, 0, 0);
    dtNextM = new Date(dtToday.getTime()+(((long)Calendar.LastDay(month,year+1900))*lOneDayMilis));
    dtLastD = new Date(dtNextM.getTime()-lOneDayMilis);

    sMonth = Calendar.MonthName(month, sLanguage);
    FirstDay = (dtToday.getDay()+6-iFirstDayOfWeek)%7;
    LastDay = Calendar.LastDay(month, year+1900);

%>
        <TD VALIGN="top">
          <TABLE SUMMARY="Days of the Month" CELLSPACING="0" CELLPADDING="2" CLASS="tableborder">
<% switch (m) {
     case 0:
       out.write("<TR><TD><A HREF=\"workcalendar_setdays.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_calendar="+gu_calendar+"&year="+pyear+"&month="+pmonth+"&selected="+nu_selected+"&subselected="+nu_subselected+"\" CLASS=\"linkplain\" TITLE=\"Previous Month\">&lt;&lt;</A></TD><TD COLSPAN=\"5\" ALIGN=\"center\"><FONT CLASS=textplain>"+sMonth+"&nbsp;"+String.valueOf(year+1900)+"</FONT></TD><TD ALIGN=\"right\"><INPUT TYPE=\"checkbox\" onclick=\"toggleMonth("+String.valueOf(d+1)+","+String.valueOf(d+1+LastDay)+",this.checked)\"></TD></TR>\n");
       break;
     case 5:
       out.write("<TR><TD COLSPAN=\"6\" ALIGN=\"center\"><FONT CLASS=textplain>"+sMonth+"&nbsp;"+String.valueOf(year+1900)+"</FONT></TD><TD><INPUT TYPE=\"checkbox\" onclick=\"toggleMonth("+String.valueOf(d+1)+","+String.valueOf(d+1+LastDay)+",this.checked)\"><A HREF=\"workcalendar_setdays.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_calendar="+gu_calendar+"&year="+nyear+"&month="+nmonth+"&selected="+nu_selected+"&subselected="+nu_subselected+"\" CLASS=\"linkplain\" TITLE=\"Next month\">&gt;&gt;</A></TD></TR>\n");
       break;
     default:
       out.write("<TR><TD COLSPAN=\"6\" ALIGN=\"center\"><FONT CLASS=textplain>"+sMonth+"</FONT></TD><TD ALIGN=\"right\"><INPUT TYPE=\"checkbox\" onclick=\"toggleMonth("+String.valueOf(d+1)+","+String.valueOf(d+1+LastDay)+",this.checked)\"></TD></TR>\n");
   }
   out.write("            <TR>\n");
   for (int w=0; w<=6; w++) { %>
              <TD ALIGN="center" CLASS="tableborder"><FONT CLASS="textplain"><% out.write (Gadgets.left(Calendar.WeekDayName(((w+iFirstDayOfWeek)%7)+1, sLanguage),1)); %></FONT></TD>
<% } %>
            </TR>
<%

    CurrentDay = 1;
	
	  for (int row=0; row<6; row++) {
	    out.write(" <TR>\n");
	    
	    for (int col=0; col<7; col++) {
	      
        if ((CurrentDay<=LastDay) && (0!=row || col>FirstDay)) {
			    short iWorkDay = aWCalDays[d++];
	        out.write("            <TD ALIGN=\"right\" VALIGN=\"top\" NOWRAP=\"nowrap\"><FONT CLASS=textplain>"+String.valueOf(CurrentDay)+"</FONT>&nbsp;<A HREF=\"#"+String.valueOf(d)+"\" onclick=\"toggle("+String.valueOf(d)+")\"><IMG ID=\"I"+String.valueOf(d)+"\" SRC=\"../images/images/addrbook/"+(iWorkDay==0 ? "unknownstatecheckbox13.gif" : (iWorkDay==1 ? "uncheckedstatecheckbox13.gif" : "checkedstatecheckbox13.gif"))+"\" WIDTH=\"13\" HEIGHT=\"13\" BORDER=\"0\" ALT=\"\"></A>");
          CurrentDay++;
	      } else {
	
          out.write("            <TD VALIGN=\"top\">");	      
	      } // fi 
	
        out.write("</TD>\n");
	    } // next (col)
	    out.write("</TR>\n");
	  } // next (row)	  

    out.write("        </TABLE></TD>\n");

    if (month<11) { month++; } else { month=0; year++; }
    if (m==2) out.write("      </TR><TR>\n");
  } // next (m)
%>
      </TR>
      <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>

    </TABLE>
    </FORM>
    <FORM METHOD="post" ACTION="workcalendar_setdays_store.jsp" onsubmit="return validate()">
<% if (!bIsGuest) { %>
    	<INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    	<INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    	<INPUT TYPE="hidden" NAME="gu_calendar" VALUE="<%=gu_calendar%>">
    	<INPUT TYPE="hidden" NAME="year" VALUE="<%=String.valueOf(year1+1900)%>">
    	<INPUT TYPE="hidden" NAME="month" VALUE="<%=String.valueOf(month1)%>">
    	<INPUT TYPE="hidden" NAME="workdays">
    	<INPUT TYPE="hidden" NAME="selected" VALUE="<%=request.getParameter("selected")%>">
    	<INPUT TYPE="hidden" NAME="subselected" VALUE="<%=request.getParameter("subselected")%>">
    	<FONT CLASS="formstrong">Working timetables</FONT>
    	<TABLE SUMMARY="Working Hours" BORDER="0">
    	  <TR>
    	    <TD CLASS="formplain">Morning&nbsp;&nbsp;</TD>
    	    <TD CLASS="formplain">from&nbsp;</TD>
    	    <TD CLASS="formplain">
    	      <SELECT NAME="hh_start1" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
    	      <SELECT NAME="mi_start1" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></SELECT>
    	      &nbsp;&nbsp;to&nbsp;
    	      <SELECT NAME="hh_end1" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
    	      <SELECT NAME="mi_end1" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></SELECT>
    	    </TD>
    	  </TR>
    	  <TR>
    	    <TD CLASS="formplain">Evening&nbsp;&nbsp;</TD>
    	    <TD CLASS="formplain">from&nbsp;</TD>
    	    <TD CLASS="formplain">
    	      <SELECT NAME="hh_start2" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
    	      <SELECT NAME="mi_start2" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></SELECT>
    	      &nbsp;&nbsp;to&nbsp;
    	      <SELECT NAME="hh_end2" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
    	      <SELECT NAME="mi_end2" CLASS="combomini"><OPTION VALUE="-1" SELECTED></OPTION><OPTION VALUE="0">00</OPTION><OPTION VALUE="1">01</OPTION><OPTION VALUE="2">02</OPTION><OPTION VALUE="3">03</OPTION><OPTION VALUE="4">04</OPTION><OPTION VALUE="5">05</OPTION><OPTION VALUE="6">06</OPTION><OPTION VALUE="7">07</OPTION><OPTION VALUE="8">08</OPTION><OPTION VALUE="9">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="29">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="39">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="49">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="59">59</OPTION></SELECT>
          </TD>
        </TR>
      </TABLE>
      <INPUT TYPE="submit" CLASS="pushbutton" VALUE="Save">&nbsp;&nbsp;
<% } %>
      <INPUT TYPE="button" CLASS="closebutton" VALUE="Back" onclick="document.location='workcalendar_list.jsp?selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>'">
    </FORM>
  </BODY>
</HTML>