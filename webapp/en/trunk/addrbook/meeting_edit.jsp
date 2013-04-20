<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Meeting,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets,com.knowgate.crm.MemberAddress" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="meeting_edit.jspf" %><%
/*
  Copyright (C) 2003-2007  Know Gate S.L. All rights reserved.
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
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Activity</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      var users_type = -1;
      
      function showCalendar(ctrl) {       
        var dtnw;
        var dtsp;
        
        if (isDate(document.forms[0].dt_start.value, "d")) {
          dtsp = document.forms[0].dt_start.value.split("-");
          dtnw = new Date(parseInt(dtsp[0]), parseFloat(dtsp[1])-1, parseFloat(dtsp[2]));
        }
        else
          dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

    // ------------------------------------------------------

    function findValue(opt,val) {
      var fnd = -1;
      
      for (var g=0; g<opt.length; g++) {
        if (opt[g].value==val) {
          fnd = g;
          break;
        }      
      }
      return fnd;
    }

    // ------------------------------------------------------
    
    function addUsrs() {
      var opt1 = document.forms[0].sel_users.options;
      var opt2 = document.forms[0].sel_attendants.options;
      var sel2 = document.forms[0].sel_attendants;
      var opt;
      
      for (var g=0; g<opt1.length; g++) {
        if (opt1[g].selected && (-1==findValue(opt2,opt1[g].value))) {          
          opt = new Option(opt1[g].text, opt1[g].value);
          opt2[sel2.length] = opt;
        }
      }
    }

    function remUsrs() {
      var opt2 = document.forms[0].sel_attendants.options;
      var flw = getURLParam("gu_fellow");
      
      for (var g=0; g<opt2.length; g++) {
        if (opt2[g].selected && opt2[g].value!=flw)
          opt2[g--] = null;
      }
    }      
      // ------------------------------------------------------

      function loadContacts() {
        var frm = document.forms[0];
        
        users_type = 1; 

        if (frm.sel_users.options.length>0) {
        
          if (frm.sel_users.options[0].value!="COMBOLOADING") {
                        
            clearCombo(frm.sel_users);
        
            comboPush (frm.sel_users, "Loading...", "COMBOLOADING", true, true);
        
            parent.meetexec.location = "load_contacts.jsp?gu_workarea=" + getURLParam("gu_workarea") + (frm.nm_assistant.value.length==0 ? "" : "&find="+escape(frm.nm_assistant.value));
          }
        }
        else {
          comboPush (frm.sel_users, "Loading...", "COMBOLOADING", true, true);
        
          parent.meetexec.location = "load_contacts.jsp?gu_workarea=" + getURLParam("gu_workarea") + (frm.nm_assistant.value.length==0 ? "" : "&find="+escape(frm.nm_assistant.value));
        }        
      }

      // ------------------------------------------------------

      function loadFellows(list) {
        var frm = document.forms[0];
        
        users_type = 2; 
        
        clearCombo(frm.sel_users);
        if (null==list)
          parent.meetexec.location = "load_fellows.jsp?gu_workarea=" + getURLParam("gu_workarea") + (frm.nm_assistant.value.length==0 ? "" : "&find="+escape(frm.nm_assistant.value));
        else
          parent.meetexec.location = "load_fellows.jsp?gu_workarea=" + getURLParam("gu_workarea") + (frm.nm_assistant.value.length==0 ? "" : "&find="+escape(frm.nm_assistant.value)) + "&list=" + list;
      }

      // ------------------------------------------------------
      
      function modifyUser() {
	var sel = document.forms[0].sel_users;

<%      if ((iAppMask & (1<<Sales))!=0) { %>
          if (1==users_type && sel.selectedIndex>0)
	    self.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + sel.options[sel.selectedIndex].value, "editcontact", "directories=no,toolbar=no,menubar=no,width=640,height=520");
<%      } %>
          if (2==users_type && sel.selectedIndex>0)
	    self.open ("fellow_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_fellow=" + sel.options[sel.selectedIndex].value + "&gu_workarea=<%=gu_workarea%>", "editfellow", "directories=no,toolbar=no,menubar=no,width=640,height="+ (screen.height<=600 ? "520" : "600"));

      } // modifyUser()

      // ------------------------------------------------------
              
      function showComments() {
        var frm = document.forms[0];
        var opt = frm.sel_rooms.options;
        var idx = opt.selectedIndex;
                
        if (idx>=0) {
          var txt = jsComments[idx-1];
          if (txt)
            frm.read_comments.value = txt;
          else
            frm.read_comments.value = "";
        }
      }

      // ------------------------------------------------------
              
      function wholeDay() {
        var frm = document.forms[0];
	
	      if (frm.whole_day.checked) {
      	  setCombo(frm.sel_h_start, "00");
      	  setCombo(frm.sel_m_start, "00");
      	  setCombo(frm.sel_h_end, "23");
      	  setCombo(frm.sel_m_end, "55");
      	  
      	  frm.sel_h_start.style.visibility = "hidden";
      	  frm.sel_m_start.style.visibility = "hidden";
      	  frm.sel_h_end.style.visibility = "hidden";
      	  frm.sel_m_end.style.visibility = "hidden";
      	}
      	else {
      	  frm.sel_h_start.style.visibility = "visible";
      	  frm.sel_m_start.style.visibility = "visible";
      	  frm.sel_h_end.style.visibility = "visible";
      	  frm.sel_m_end.style.visibility = "visible";
      	}
      }
            
      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_table_lookup&id_language=" + getUserLanguage() + "&id_section=tx_field&tp_control=2&nm_control=sel_field&nm_coding=tx_field", "lookup", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
	    // window.open("...
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var txt;
        var opt = frm.sel_attendants.options;
        var opr = frm.sel_rooms.options;

      	txt = frm.tx_meeting.value;
      	
      	if (txt.indexOf("'")>=0 || txt.indexOf('"')>=0 || txt.indexOf('%')>=0 || txt.indexOf('*')>=0 || txt.indexOf('&')>=0 || txt.indexOf('?')>=0) {
      	  alert ("Activity title contains invalid characters");
      	  return false;
      	}
      
      	if (rtrim(txt)=="") {
      	  alert ("Activity title is mandatory");
      	  return false;
      	}
      	
      	if (frm.dt_start.value.length==0) {
      	  alert ("Start date is mandatory");
      	  return false;
      	}
      
      	if (!isDate(frm.dt_start.value, "d") ) {
      	  alert ("Start date is not valid");
      	  return false;	  
      	}
      
      	if (frm.dt_end.value.length==0) {
      	  alert ("End date is mandatory");
      	  return false;
      	}
      
      	if (!isDate(frm.dt_end.value, "d") ) {
      	  alert ("End date is not valid");
      	  return false;	  
      	}
      	
      	if (frm.dt_start.value==frm.dt_end.value) {  
      	  if (parseInt(getCombo(frm.sel_h_start),10)*100+parseInt(getCombo(frm.sel_m_start),10)>=parseInt(getCombo(frm.sel_h_end),10)*100+parseInt(getCombo(frm.sel_m_end),10)) {
      	    alert ("End time must be after Start time");
      	    return false;	  
      	  }
      	}
      	
      	if (frm.de_meeting.value.length>1000) {
      	  alert ("Activity description cannot be longer than 1000 chars.");
      	  return false;
      	}
        
        frm.attendants.value = getURLParam("gu_fellow") + ",";     
        for (var g=0; g<opt.length; g++)
          frm.attendants.value += opt[g].value + ",";
        txt = frm.attendants.value; 
        if (txt.charAt(txt.length-1)==',') frm.attendants.value = txt.substr(0,txt.length-1);

        frm.rooms.value = "";
        for (var r=0; r<opr.length; r++)
          if (opr[r].selected && opr[r].value.length>0)
            frm.rooms.value += opr[r].value + ",";
        txt = frm.rooms.value; 
        if (txt.charAt(txt.length-1)==',') frm.rooms.value = txt.substr(0,txt.length-1);
	        
	      frm.tp_meeting.value = getCombo(frm.sel_tp_meeting);
	      frm.ts_start.value = frm.dt_start.value + " " + getCombo(frm.sel_h_start) + ":" + getCombo(frm.sel_m_start) + ":00";
	      frm.ts_end.value = frm.dt_end.value + " " + getCombo(frm.sel_h_end) + ":" + getCombo(frm.sel_m_end) + ":00";
	
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
<%  
    out.write("      var jsComments = new Array(");
    for (int r=0; r<iRooms; r++) {
      if (r>0) out.write(",");
      out.write("\"" + oRooms.getStringNull(DB.tx_comments,r,"").replace('\n',' ').replace('"',' ').replace('\r',' ') + "\"");
    }
    out.write(");\n");
%>

      var met = false;
      var lst = new Array();
      var available = true;
      
      function checkAvailability() {
	      available = true;
	      var frm = document.forms[0];
	      var crm = frm.sel_rooms;
                
        if (isDate(frm.dt_start.value,"d") && isDate(frm.dt_end.value,"d")) {          
          var s = frm.dt_start.value;
          var e = frm.dt_end.value;          
          var dts = new Date (parseInt(s.substr(0,4)),parseFloat(s.substr(5,2))-1,parseFloat(s.substr(8,2)),parseFloat(getCombo(frm.sel_h_start)),parseFloat(getCombo(frm.sel_m_start)), 0);
          var dte = new Date (parseInt(e.substr(0,4)),parseFloat(e.substr(5,2))-1,parseFloat(e.substr(8,2)),parseFloat(getCombo(frm.sel_h_end))  ,parseFloat(getCombo(frm.sel_m_end))  ,59);
      	  for (var r=0; r<crm.options.length; r++) {
      	    if (crm.options[r].selected) {
      	      for (var m=0; m<lst.length; m++) {
      	        var mts = lst[m][2];
      	        var mte = lst[m][3];	        
      	        if ("<%=gu_meeting%>"!=lst[m][0] && crm.options[r].value==lst[m][1] && ((dts<=mts && dte>mts) || (dts>=mts && dts<=mte) || (dts<mte && dte>=mte))) {
      	          alert (lst[m][1]+" The resource is already in use by another activity at the designed time Booked by  "+lst[m][4]);
      	          available = false;
      	          break;
      	        }
      	      }
      	    }
      	  } // next
   	      if (dte<dts) frm.dt_end.value=frm.dt_start.value;
	      } //	
	      return available;
      } // checkAvailability
      
      function processMeetingsList() {
          if (met.readyState == 4) {
            if (met.status == 200) {
              var meetings = met.responseXML.getElementsByTagName("meeting");
              var imeetings = meetings.length;
              if (imeetings>0) {
                lst = new Array(imeetings);
                for (var m=0; m<imeetings; m++) {
		              var gum = getElementText(meetings[m],"gu_meeting");
		              var nmr = getElementText(meetings[m],"nm_room");
		              var nmf = getElementText(meetings[m],"tx_name")+" "+getElementText(meetings[m],"tx_surname");
                  var s = getElementText(meetings[m],"dt_start");
                  var e = getElementText(meetings[m],"dt_end");                
                  var dts = new Date (parseInt(s.substr(0,4)),parseFloat(s.substr(5,2))-1,parseFloat(s.substr(8,2)),parseFloat(s.substr(11,2)),parseFloat(s.substr(14,4)),parseFloat(s.substr(17,2)));
                  var dte = new Date (parseInt(e.substr(0,4)),parseFloat(e.substr(5,2))-1,parseFloat(e.substr(8,2)),parseFloat(e.substr(11,2)),parseFloat(e.substr(14,4)),parseFloat(e.substr(17,2)));
                  lst[m] = new Array(gum,nmr,dts,dte,nmf);
                }
              } else {
                lst = new Array();
              }
              met = false;
            }
	        }
      } // processMeetingsList
      
      function loadDailyMeetings() {
        met = createXMLHttpRequest();
        if (met) {
        	var dts = document.forms[0].dt_start.value;
        	var dte = document.forms[0].dt_end.value;
        	if (isDate(dts,"d") && isDate(dte,"d")) {
	          met.onreadystatechange = processMeetingsList;
            met.open("GET", "room_availability.jsp?gu_workarea=<%=gu_workarea%>&dt_start="+dts+"&dt_end="+dte, true);
            met.send(null);
          }
        }
      } // loadDailyMeetings

      function setCombos() {
        var frm = document.forms[0];
        var idx;
	
<%    if (nm_room.length()>0) { %>
        setCombo(frm.sel_rooms,"<% out.write(nm_room);%>");
        showComments();
<%    } %>
        
<%    if (gu_meeting.length()>0) { %>        
        setCombo(frm.sel_tp_meeting,"<% out.write(oMeet.getStringNull(DB.tp_meeting,""));%>");
        setCombo(frm.sel_h_start,"<% out.write(oMeet.getHour().length()==1 ? "0" + String.valueOf(oMeet.getHour()) : String.valueOf(oMeet.getHour())); %>");
        setCombo(frm.sel_m_start,"<% out.write(oMeet.getMinute().length()==1 ? "0" + String.valueOf(oMeet.getMinute()) : String.valueOf(oMeet.getMinute())); %>");
        setCombo(frm.sel_h_end,"<% out.write(oMeet.getHourEnd().length()==1 ? "0" + String.valueOf(oMeet.getHourEnd()) : String.valueOf(oMeet.getHourEnd())); %>");
        setCombo(frm.sel_m_end,"<% out.write(oMeet.getMinuteEnd().length()==1 ? "0" + String.valueOf(oMeet.getMinuteEnd()) : String.valueOf(oMeet.getMinuteEnd())); %>");
<%            
        for (int b=0; b<oBookedRooms.getRowCount(); b++) {
          out.write("        idx = comboIndexOf(frm.sel_rooms,\"" + oBookedRooms.getString(0,b) + "\");\n");
          out.write("        frm.sel_rooms.options[idx].selected = true;\n");
        } // next (b)
      } else {
        if (null!=tm_hour) {
          String[] aHour = Gadgets.split2(tm_hour, ':');
          out.write("        setCombo(frm.sel_h_start,\""+aHour[0]+"\");\n");
          out.write("        setCombo(frm.sel_m_start,\""+aHour[1]+"\");\n");
          if (aHour[0].equals("23"))
            out.write("        setCombo(frm.sel_h_end,\"23\");\n");
	    else
            out.write("        setCombo(frm.sel_h_end,\""+String.valueOf(Integer.parseInt(aHour[0])+1)+"\");\n");
          out.write("        setCombo(frm.sel_m_end,\"+aHour[1]+\");\n");
          if (iRecentUsers>0)
            out.write("        loadFellows(\""+sRecentList.toString()+"\");\n");
        }

				if (gu_contact.length()>0) {
  	      DBPersist oContact = new DBPersist(DB.k_contacts,"Contact");
          if (oContact.load(oConn, gu_contact)) {
					  out.write ("        comboPush (document.forms[0].sel_attendants, \""+(oContact.getStringNull(DB.tx_name,"")+" "+oContact.getStringNull(DB.tx_surname,"")).replace('\n',' ')+"\", \""+oContact.getString(DB.gu_contact)+"\", false, true)\n;");
          }
        }
      }
      
      // fi (gu_meeting)
%>
        loadDailyMeetings();
        return true;
      } // setCombos;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <FORM NAME="" METHOD="post" ACTION="meeting_edit_store.jsp" onSubmit="return validate()">
    <TABLE WIDTH="100%">
      <TR><TD><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="4" BORDER="0"></TD></TR>
      <TR>
        <TD CLASS="striptitle" WIDTH="100%"><FONT CLASS="title1">Edit Activity</FONT></TD>
        <TD ALIGN="right">
    	  <DIV class="cxMnu1" style="width:230px"><DIV class="cxMnu2">
            <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
            <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
          </DIV></DIV>
        </TD>
      </TR>
    </TABLE>  
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_meeting" VALUE="<%=gu_meeting%>">
    <INPUT TYPE="hidden" NAME="gu_fellow" VALUE="<%=gu_fellow%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
<% if (gu_meeting.length()>0) { %>      
          <TR>
            <TD></TD>
            <TD><FONT CLASS="formplain">Organizada por <%=oCreator.getStringNull(DB.nm_user,"")+" "+oCreator.getStringNull(DB.tx_surname1,"")+" "+oCreator.getStringNull(DB.tx_surname2,"")%></FONT>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">Start:</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <INPUT TYPE="hidden" NAME="ts_start">
              <INPUT CLASS="combomini" TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="12" VALUE="<% out.write(dt_start); %>" onchange="loadDailyMeetings();checkAvailability();">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
              <SELECT CLASS="combomini" NAME="sel_h_start" onchange="checkAvailability()"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_m_start" onchange="checkAvailability()"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>
	      &nbsp;&nbsp;<IMG SRC="../images/images/addrbook/smalllock.gif" BORDER="0" HSPACE="2"><INPUT TYPE="checkbox" NAME="bo_private" VALUE="1" <%=(bo_private ? "CHECKED" : "")%>>&nbsp;<FONT CLASS="formplain">Private</FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">End:</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
	            <INPUT TYPE="hidden" NAME="ts_end">
              <INPUT CLASS="combomini" TYPE="text" NAME="dt_end" MAXLENGTH="10" SIZE="12" VALUE="<% out.write(dt_end); %>" onchange="loadDailyMeetings();checkAvailability();">
              <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>              
              <SELECT CLASS="combomini" NAME="sel_h_end" onchange="checkAvailability()"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_m_end" onchange="checkAvailability()"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>
	      &nbsp;&nbsp;<IMG SRC="../images/images/spacer.gif" WIDTH="10" HEIGHT="12" BORDER="0" HSPACE="2"><INPUT TYPE="checkbox" NAME="whole_day" onclick="wholeDay()">&nbsp;<FONT CLASS="formplain">All day</FONT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formplain">Ativity Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <INPUT TYPE="hidden" NAME="tp_meeting">
              <SELECT CLASS="combomini" NAME="sel_tp_meeting"><OPTION VALUE=""></OPTION><OPTION VALUE="meeting">Meeting</OPTION><OPTION VALUE="call">Call</OPTION><OPTION VALUE="followup">Follow up</OPTION><OPTION VALUE="breakfast">Breakfast<OPTION VALUE="lunch">Lunch</OPTION><OPTION VALUE="course">Course</OPTION><OPTION VALUE="demo">Demo</OPTION><OPTION VALUE="workshop">Journey<OPTION VALUE="congress">Congress</OPTION><OPTION VALUE="tradeshow">Trade Show</OPTION><OPTION VALUE="bill">Send Invoice</OPTION><OPTION VALUE="pay">Pay</OPTION><OPTION VALUE="holidays">Holidays</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formplain">Title</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <INPUT CLASS="textsmall" TYPE="text" NAME="tx_meeting" MAXLENGTH="100" SIZE="60" VALUE="<%=oMeet.getStringNull(DB.tx_meeting,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formplain">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <TEXTAREA STYLE="font-family:Verdana,sans-serif,Arial,Helvetica;font-size:7pt" NAME="de_meeting" ROWS="2" COLS="40"><%=oMeet.getStringNull(DB.de_meeting,"")%></TEXTAREA>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formplain">Resources:</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <INPUT TYPE="hidden" NAME="rooms">
              <SELECT NAME="sel_rooms" CLASS="textsmall" SIZE="4" STYLE="width:340px" onChange="showComments();checkAvailability();" MULTIPLE>
              <OPTION VALUE=""></OPTION>
<%	      for (int r=0; r<iRooms; r++) {
		out.write("<OPTION VALUE=\"" + oRooms.getString(0,r) + "\">");
		if (!oRooms.isNull(DB.tp_room,r))
		  out.write(DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_rooms_lookup, gu_workarea, "tp_room", sLanguage, oRooms.getString(DB.tp_room,r)) + " ");
		out.write(oRooms.getString(0,r) + "</OPTION>");
	      }
%>
              </SELECT>
              <BR>
            </TD>
          </TR>          
          <TR>
            <TD></TD>
            <TD><TEXTAREA ROWS="2" CLASS="textsmall" NAME="read_comments" STYLE="border-style:none;width:340px" TABINDEX="-1" onfocus="document.forms[0].sel_rooms.focus()"></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2" ALIGN="center">
              <TABLE CELLSPACING="0" CELLPADDING="0" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                <TR HEIGHT="20">
                  <TD WIDTH="8">&nbsp;</TD>
                  <TD NOWRAP>
                    <INPUT TYPE="text" NAME="nm_assistant" SIZE="14">&nbsp;<A HREF="#" onclick="loadContacts()"><IMG SRC="../images/images/find16.gif" BORDER="0"></A>
                    <BR>
                    <INPUT TYPE="radio" NAME="tp_assistant" onClick="loadContacts()">&nbsp;<FONT CLASS="textsmallfront">Contacts</FONT>&nbsp;&nbsp;<INPUT TYPE="radio" NAME="tp_assistant" onClick="loadFellows(null)">&nbsp;<FONT CLASS="textsmallfront">Personal</FONT>
                  </TD>
                  <TD WIDTH="50"></TD>
                  <TD><FONT CLASS="textsmallfront">Attendants</FONT></TD>
                  <TD WIDTH="8">&nbsp;</TD>
                </TR>
                <TR>
                  <TD WIDTH="8">&nbsp;</TD>
                  <TD><SELECT NAME="sel_users" ondblclick="modifyUser()" CLASS="textsmall" STYLE="width:180px" SIZE="7" MULTIPLE></SELECT></TD>
                  <TD ALIGN="center" VALIGN="middle"><INPUT TYPE="button" NAME="AddUsrs" VALUE="++ >>" TITLE="Add" STYLE="width:40px" onclick="addUsrs()"><BR><BR><INPUT TYPE="button" NAME="RemUsrs" VALUE="<< - -" TITLE="Remove" STYLE="width:40px" onclick="remUsrs()"></TD>
                  <TD>
                    <SELECT NAME="sel_attendants" CLASS="textsmall" STYLE="width:180px" SIZE="7" MULTIPLE><%=sFellows%><%=sContacts%></SELECT>
                    <INPUT TYPE="hidden" NAME="attendants" VALUE="">
                  </TD>
                  <TD WIDTH="8">&nbsp;</TD>
                </TR>
                <TR><TD></TD><TD COLSPAN="4" ALIGN="left"><INPUT TYPE="checkbox" NAME="bo_notify" VALUE="1">&nbsp;<FONT CLASS="textsmallfront">Notify attendants by e-mail</FONT></TD></TR>
                <TR><TD COLSPAN="5" HEIGHT="8"></TD></TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<%	    if (gu_fellow.equals(getCookie(request, "userid", "")))
              if (bIsGuest) { %>    
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<%            } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<%          } %>
    	      <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
    </CENTER>
  </FORM>
</BODY>
</HTML>
<%
  oConn.close("meetingedit");
  oConn = null;
%>
<%@ include file="../methods/page_epilog.jspf" %>
