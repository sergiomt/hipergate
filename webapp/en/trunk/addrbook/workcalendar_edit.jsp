<%@ page import="java.util.Date,java.util.GregorianCalendar,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Calendar" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  Integer id_domain = new Integer(request.getParameter("id_domain"));
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_calendar = request.getParameter("gu_calendar");
  String id_user = getCookie (request, "userid", null);

  ACLUser oUser = new ACLUser(id_user);
  DBPersist oWCal = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
  
  JDCConnection oConn = null;
  DBSubset oUsersList = null;
  DBSubset oGroupList = new DBSubset(DB.k_acl_groups,DB.gu_acl_group+","+DB.nm_acl_group,DB.bo_active+"<>0 AND "+DB.id_domain+"=? ORDER BY 2",10);
  int nGroupCount = 0;
  int nUserCount = 0;
  String sCountriesLookup = null;
  boolean bIsGuest = true;
  String sNmState = "";
  
  try {

    oConn = GlobalDBBind.getConnection("workcalendar_edit");  
    
    sCountriesLookup = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);
    
    bIsGuest = isDomainGuest(GlobalCacheClient, GlobalDBBind, request, response);
    
    if (isDomainAdmin(GlobalCacheClient, GlobalDBBind, request, response)) {
      oUsersList = new DBSubset(DB.k_users,DB.gu_user+","+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2,DB.bo_active+"<>0 AND "+DB.id_domain+"=?",100);
      nUserCount = oUsersList.load (oConn, new Object[]{id_domain});    
    } else {
      oUsersList = new DBSubset(DB.k_users,DB.gu_user+","+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2,DB.bo_active+"<>0 AND "+DB.id_domain+"=? AND "+DB.gu_workarea+"=?",100);
      nUserCount = oUsersList.load (oConn, new Object[]{id_domain,gu_workarea});
    } // fi
    
    nGroupCount = oGroupList.load (oConn, new Object[]{id_domain});
    
    if (gu_calendar!=null) {
      oWCal.load(oConn, gu_calendar);
      if (!oWCal.isNull(DB.id_state)) {
        DBPersist oState = new DBPersist(DB.k_lu_states,"State");
        oState.load(oConn, new Object[]{oWCal.get(DB.id_state)});
        sNmState = oState.getStringNull(DB.tr_+"state_"+sLanguage, oState.getString(DB.nm_state));
      }
    }

    oConn.close("workcalendar_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("workcalendar_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Timetable</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------
      
      var StatesSelectRequest = false;

      function loadStatesCallback() {
        if (StatesSelectRequest.readyState == 4) {
          if (StatesSelectRequest.status == 200) {
            var cmb = document.forms[0].sel_state;
            clearCombo(cmb);
            var res = StatesSelectRequest.responseText.split("\n");
            var len = res.length;
            for (var s=0; s<len; s++) {
	      if (res[s].length>0) {
                var idtr = res[s].split(",");
                cmb[cmb.length] = new Option(idtr[1], idtr[0], false, false);        	
	      } // fi            
            } // next
            StatesSelectRequest = false;
          } // fi
        } // fi
      } // loadStatesCallback
      
      function listStates(cntr) {
        var cmb = document.forms[0].sel_state;
        if (!StatesSelectRequest) {
          clearCombo(cmb);
          if (cntr.length>0) {
            comboPush (cmb, "Loading...", "", true, true);
            StatesSelectRequest = createXMLHttpRequest();
  	    if (StatesSelectRequest) {
    	      StatesSelectRequest.onreadystatechange = loadStatesCallback;
    	      StatesSelectRequest.open("GET", "../common/state_txt.jsp?id_country="+cntr, true);
    	      StatesSelectRequest.send(null);
  	    } // fi (createXMLHttpRequest)
  	  } // fi (cntr)
        } // fi (!StatesSelectRequest) 
      } // listStates

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
	      var scp = getCheckedValue(frm.wcal_scope);

				if (frm.dt_from.value.length==0) {
	        alert ("From date is required");
	        frm.dt_from.focus();
	        return false;
				}

				if (frm.dt_to.value.length==0) {
	        alert ("To date is required");
	        frm.dt_to.focus();
	        return false;
				}
				
	if (!isDate(frm.dt_from.value, "d") && frm.dt_from.value.length>0) {
	  alert ("From date is not valid");
	  frm.dt_from.focus();
	  return false;
	}

	if (!isDate(frm.dt_to.value, "d") && frm.dt_to.value.length>0) {
	  alert ("To date is not valid");
	  frm.dt_to.focus();
	  return false;	  
	}

	if (parseDate(frm.dt_to.value, "d")<parseDate(frm.dt_from.value, "d")) {
	  alert ("To date must be later than From date");
	  return false;	  
	}

	if (null==scp) {
	  alert ("It is required to select a scope to which the calendar must be applied");
	  return false;	  
	}        

        if (scp=="global") {
	        frm.gu_user.value=frm.gu_acl_group.value=frm.id_country.value=frm.id_state.value="";
        } else if (scp=="country") {
          if (frm.sel_country.selectedIndex==-1) {
	    alert ("It is required to selected a country to which the calendar applies");
	    frm.sel_country.focus();
	    return false;	  
          } else {
	    frm.id_country.value=getCombo (frm.sel_country);          
          }	  
	  frm.gu_user.value=frm.gu_acl_group.value=frm.id_state.value="";
        } else if (scp=="state") {
          if (frm.sel_country.selectedIndex==-1) {
	    alert ("It is required to selected a country to which the calendar applies");
	    frm.sel_country.focus();
	    return false;	  
          } else if (frm.sel_state.selectedIndex==-1) {
	    alert ("It is required to select a state to which the calendar must be applied");
	    frm.sel_state.focus();
	    return false;  
          } else {
	    frm.id_country.value=getCombo (frm.sel_country);          
	    frm.id_state.value=getCombo (frm.sel_state);          
          }	  
	  frm.gu_user.value=frm.gu_acl_group.value="";
        } else if (scp=="group") {
          if (frm.sel_group.selectedIndex==-1) {
	    alert ("It is required to select a group to which the calendar must be applied");
	    frm.sel_group.focus();
	    return false;	  
          } else {
	    frm.gu_acl_group.value=getCombo (frm.sel_group);          
          }	  
	  frm.gu_user.value=frm.id_country.value=frm.id_state.value="";
        } else if (scp=="user") {
          if (frm.sel_user.selectedIndex==-1) {
	    alert ("It is required to select a user to which the calendar must be applied");
	    frm.sel_user.focus();
	    return false;	  
          } else {
	    frm.gu_user.value=getCombo (frm.sel_user);          
          }	  
	  frm.gu_acl_group.value=frm.id_country.value=frm.id_state.value="";
        } 

        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_country,"<% out.write(oWCal.getStringNull(DB.id_country,"").trim()); %>");
        setCombo(frm.sel_state  ,"<% out.write(oWCal.getStringNull(DB.id_state,"").trim()); %>");
        setCombo(frm.sel_group  ,"<% out.write(oWCal.getStringNull(DB.gu_acl_group,"")); %>");
        setCombo(frm.sel_user   ,"<% out.write(oWCal.getStringNull(DB.gu_user,"")); %>");

<%	if (oWCal.isNull(DB.gu_user) && oWCal.isNull(DB.gu_acl_group) && oWCal.isNull(DB.id_country) && oWCal.isNull(DB.id_state))
	  out.write("        setScope(\"global\");\n");
	else if (oWCal.isNull(DB.gu_user) && oWCal.isNull(DB.gu_acl_group) && !oWCal.isNull(DB.id_country) && oWCal.isNull(DB.id_state))	
	  out.write("        setScope(\"country\");\n");
	else if (oWCal.isNull(DB.gu_user) && oWCal.isNull(DB.gu_acl_group) && !oWCal.isNull(DB.id_country) && !oWCal.isNull(DB.id_state))	
	  out.write("        setScope(\"state\");\n");
	else if (oWCal.isNull(DB.gu_user) && !oWCal.isNull(DB.gu_acl_group) && oWCal.isNull(DB.id_country) && oWCal.isNull(DB.id_state))	
	  out.write("        setScope(\"group\");\n");
	else if (!oWCal.isNull(DB.gu_user) && oWCal.isNull(DB.gu_acl_group) && oWCal.isNull(DB.id_country) && oWCal.isNull(DB.id_state))	
	  out.write("        setScope(\"user\");\n");
%>
        return true;
      } // setCombos;

      // ------------------------------------------------------
      
      function setScope(scp) {
        var frm = document.forms[0];

	      frm.gu_user.value=frm.gu_acl_group.value=frm.id_country.value=frm.id_state.value="";

        if (scp=="global") {
          document.getElementById("wcal_country").style.display="none";
          document.getElementById("wcal_state").style.display="none";
          document.getElementById("wcal_group").style.display="none";
          document.getElementById("wcal_user").style.display="none";
        } else if (scp=="country") {
          document.getElementById("wcal_country").style.display="block";
          document.getElementById("wcal_state").style.display="none";
          document.getElementById("wcal_group").style.display="none";
          document.getElementById("wcal_user").style.display="none";        
        } else if (scp=="state") {
          document.getElementById("wcal_country").style.display="block";
          document.getElementById("wcal_state").style.display="block";
          document.getElementById("wcal_group").style.display="none";
          document.getElementById("wcal_user").style.display="none";        
        } else if (scp=="group") {
          document.getElementById("wcal_country").style.display="none";
          document.getElementById("wcal_state").style.display="none";
          document.getElementById("wcal_group").style.display="block";
          document.getElementById("wcal_user").style.display="none";        
        } else if (scp=="user") {
          document.getElementById("wcal_country").style.display="none";
          document.getElementById("wcal_state").style.display="none";
          document.getElementById("wcal_group").style.display="none";
          document.getElementById("wcal_user").style.display="block";        
        } 
      } // setScope
      
    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Timetable</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="workcalendar_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=oWCal.getStringNull(DB.gu_user,"")%>">
    <INPUT TYPE="hidden" NAME="gu_acl_group" VALUE="<%=oWCal.getStringNull(DB.gu_acl_group,"")%>">
    <INPUT TYPE="hidden" NAME="id_country" VALUE="<%=oWCal.getStringNull(DB.id_country,"").trim()%>">
    <INPUT TYPE="hidden" NAME="id_state" VALUE="<%=oWCal.getStringNull(DB.id_state,"").trim()%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Name</TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_calendar" MAXLENGTH="100" SIZE="32" VALUE="<%=oWCal.getStringNull(DB.nm_calendar,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">From</TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_from" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oWCal.get(DB.dt_from)!=null ? oWCal.getDateFormated(DB.dt_from,"yyyy-MM-dd") : ""); %>">
              <A HREF="javascript:showCalendar('dt_from')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
            </TD>
          </TR>        
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">to</TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_to" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oWCal.get(DB.dt_to)!=null ? oWCal.getDateFormated(DB.dt_to,"yyyy-MM-dd") : ""); %>">
              <A HREF="javascript:showCalendar('dt_to')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong" VALIGN="top">Scope</TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">
	      <INPUT TYPE="radio" NAME="wcal_scope" VALUE="global" onclick="setScope(this.value)" <% if (oWCal.isNull(DB.id_country) && oWCal.isNull(DB.id_state) && oWCal.isNull(DB.gu_acl_group) && oWCal.isNull(DB.gu_user)) out.write("CHECKED"); %>>&nbsp;Global Calendar
	      <BR>
	      <INPUT TYPE="radio" NAME="wcal_scope" VALUE="country" onclick="setScope(this.value)" <% if (!oWCal.isNull(DB.id_country) && oWCal.isNull(DB.id_state)) out.write("CHECKED"); %>>&nbsp;Calendar for a Country
	      <BR>
	      <INPUT TYPE="radio" NAME="wcal_scope" VALUE="state" onclick="setScope(this.value)" <% if (!oWCal.isNull(DB.id_state)) out.write("CHECKED"); %>>&nbsp;Calendar for a state
	      <BR>
	      <INPUT TYPE="radio" NAME="wcal_scope" VALUE="group" onclick="setScope(this.value)" <% if (!oWCal.isNull(DB.gu_acl_group)) out.write("CHECKED"); %>>&nbsp;Calendar for a Group of users
	      <BR>
	      <INPUT TYPE="radio" NAME="wcal_scope" VALUE="user" onclick="setScope(this.value)" <% if (!oWCal.isNull(DB.gu_user)) out.write("CHECKED"); %>>&nbsp;Calendar for a single user
	      <BR><BR>
	      <DIV ID="wcal_country" STYLE="display:none">
	        <SELECT NAME="sel_country" STYLE="width:320px" onchange="listStates(this.options[this.selectedIndex].value)"><%=sCountriesLookup%></SELECT>
	      </DIV>
	      <DIV ID="wcal_state" STYLE="display:none">
	        <SELECT NAME="sel_state" STYLE="width:320px"><% if (!oWCal.isNull(DB.id_state)) out.write("<OPTION VALUE=\""+oWCal.getString(DB.id_state).trim()+"\" SELECTED>"+sNmState+"</OPTION>"); %></SELECT>
	      </DIV>
	      <DIV ID="wcal_group" STYLE="display:none">
	        <SELECT NAME="sel_group"><% for (int g=0; g<nGroupCount; g++) out.write("<OPTION VALUE=\""+oGroupList.getString(0,g)+"\">"+oGroupList.getString(1,g)+"</OPTION>");  %></SELECT>
	      </DIV>
	      <DIV ID="wcal_user" STYLE="display:none">
	        <SELECT NAME="sel_user"><% for (int u=0; u<nUserCount; u++) out.write("<OPTION VALUE=\""+oUsersList.getString(0,u)+"\">"+(oUsersList.getStringNull(1,u,"")+" "+oUsersList.getStringNull(2,u,"")+" "+oUsersList.getStringNull(3,u,"")).trim()+"</OPTION>"); %></SELECT>
	      </DIV>
            </TD>
          </TR>          
<% if (gu_calendar==null) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Holidays</TD>
            <TD ALIGN="left" WIDTH="370">
              <TABLE SUMMARY="Week days">
                <TR>
                  <TD CLASS="formplain"><INPUT TYPE="checkbox" NAME="weekday_<%=String.valueOf(GregorianCalendar.MONDAY)%>" VALUE="<%=String.valueOf(GregorianCalendar.MONDAY)%>">&nbsp;<%=Calendar.WeekDayName(GregorianCalendar.MONDAY,sLanguage)%></TD>
                  <TD CLASS="formplain"><INPUT TYPE="checkbox" NAME="weekday_<%=String.valueOf(GregorianCalendar.TUESDAY)%>" VALUE="<%=String.valueOf(GregorianCalendar.TUESDAY)%>">&nbsp;<%=Calendar.WeekDayName(GregorianCalendar.TUESDAY,sLanguage)%></TD>
                  <TD CLASS="formplain"><INPUT TYPE="checkbox" NAME="weekday_<%=String.valueOf(GregorianCalendar.WEDNESDAY)%>" VALUE="<%=String.valueOf(GregorianCalendar.WEDNESDAY)%>">&nbsp;<%=Calendar.WeekDayName(GregorianCalendar.WEDNESDAY,sLanguage)%></TD>
		  <TD></TD>
                </TR>
                <TR>
                  <TD CLASS="formplain"><INPUT TYPE="checkbox" NAME="weekday_<%=String.valueOf(GregorianCalendar.THURSDAY)%>" VALUE="<%=String.valueOf(GregorianCalendar.THURSDAY)%>">&nbsp;<%=Calendar.WeekDayName(GregorianCalendar.THURSDAY,sLanguage)%></TD>
                  <TD CLASS="formplain"><INPUT TYPE="checkbox" NAME="weekday_<%=String.valueOf(GregorianCalendar.FRIDAY)%>" VALUE="<%=String.valueOf(GregorianCalendar.FRIDAY)%>">&nbsp;<%=Calendar.WeekDayName(GregorianCalendar.FRIDAY,sLanguage)%></TD>
                  <TD CLASS="formplain"><INPUT TYPE="checkbox" NAME="weekday_<%=String.valueOf(GregorianCalendar.SATURDAY)%>" VALUE="<%=String.valueOf(GregorianCalendar.SATURDAY)%>">&nbsp;<%=Calendar.WeekDayName(GregorianCalendar.SATURDAY,sLanguage)%></TD>
                  <TD CLASS="formplain"><INPUT TYPE="checkbox" NAME="weekday_<%=String.valueOf(GregorianCalendar.SUNDAY)%>" VALUE="<%=String.valueOf(GregorianCalendar.SUNDAY)%>" CHECKED>&nbsp;<%=Calendar.WeekDayName(GregorianCalendar.SUNDAY,sLanguage)%></TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Timetable</TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain">
              <TABLE SUMMARY="Working Hours">
                <TR CLASS="formplain">
                  <TD>Morning</TD>
                  <TD>of</TD>
                  <TD><SELECT NAME="hh_start1"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT></TD>	      
	          <TD><SELECT NAME="mi_start1"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT></TD>
                  <TD>to</TD>
                  <TD><SELECT NAME="hh_end1"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT></TD>	      
	          <TD><SELECT NAME="mi_end1"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT></TD>
                  <TD>&nbsp;&nbsp;&nbsp;</TD>
		</TR>
                <TR CLASS="formplain">
                  <TD>Evening</TD>
                  <TD>of</TD>
                  <TD><SELECT NAME="hh_start2"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT></TD>	      
	          <TD><SELECT NAME="mi_start2"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT></TD>
                  <TD>to</TD>
                  <TD><SELECT NAME="hh_end2"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT></TD>	      
	          <TD><SELECT NAME="mi_end2"><OPTION VALUE="-1" SELECTED><OPTION VALUE="00">00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT></TD>
		</TR>
	      </TABLE>
            </TD>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="90"></TD>
            <TD ALIGN="left" WIDTH="370"><A HREF="#" CLASS="linkplain" onclick="window.opener.location='workcalendar_setdays.jsp?gu_calendar=<%=gu_calendar%>&id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&selected=<%=request.getParameter("selected")%>&subselected=<%=request.getParameter("subselected")%>'; window.close();">Edit working days</A>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (!bIsGuest && gu_calendar==null) { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;
<% } %>
    	      <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
