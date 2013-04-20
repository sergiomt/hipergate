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
  <TITLE>hipergate :: [~Editar Cita~]</TITLE>
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

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        var txt;
        var dts;
        var dte;
        var opr = frm.sel_rooms.options;
      	
      	if (frm.dt_start.value.length==0) {
      	  alert ("[~La fecha de inicio es obligatoria~]");
      	  return false;
      	}
      
      	if (!isDate(frm.dt_start.value, "d") ) {
      	  alert ("[~La fecha de inicio no es válida~]");
      	  return false;	  
      	}
      
      	dts = parseDate(frm.dt_start.value+" "+getCombo(frm.sel_h_start)+":"+getCombo(frm.sel_m_start)+":00", "ts");
      	dte = parseDate(frm.dt_start.value+" "+getCombo(frm.sel_h_end)+":"+getCombo(frm.sel_m_end)+":00", "ts");
      	//dte = addHours(dts, parseInt(getCombo(frm.ti_duration)));
      	frm.dt_end.value = dateToString(dte, "d");
      
      	if (frm.de_meeting.value.length>1000) {
      	  alert ("[~La descripción de la actividad no puede superar los 1000 caracteres~]");
      	  return false;
      	}

        frm.rooms.value = "";
        for (var r=0; r<opr.length; r++)
          if (opr[r].selected && opr[r].value.length>0)
            frm.rooms.value += opr[r].value + ",";
        txt = frm.rooms.value; 
        if (txt.charAt(txt.length-1)==',') frm.rooms.value = txt.substr(0,txt.length-1);
	        
	      frm.tp_meeting.value = getCombo(frm.sel_tp_meeting);
	      frm.ts_start.value = dateToString(dts, "ts");
	      frm.ts_end.value = dateToString(dte, "ts");

			  if (frm.sel_companies.selectedIndex<0) {
			    alert ("[~El cliente es obligatorio~]");
			    frm.sel_companies.focus();
			    return false;
			  }

			  if (frm.tp_meeting.value=="withhr" && frm.sel_users.selectedIndex<0) {
			    alert ("[~El especialista es obligatorio~]");
			    frm.sel_users.focus();
			    return false;
			  }
			  frm.attendants.value = getCombo(frm.sel_users);
			  
			  frm.gu_address.value = getCombo(frm.sel_companies);
			  
      	var cus = getComboText(frm.sel_companies);
      	if (cus.indexOf("(")>0) cus=cus.substring(0,cus.indexOf("("));
				var esp = getComboText(frm.sel_users);
      	if (esp.indexOf("(")>0) esp=esp.substring(0,esp.indexOf("("));
      	frm.tx_meeting.value = cus+" / "+esp;

        return true;
      } // validate;

      // ------------------------------------------------------
      
      function showCalendar(ctrl) {       
        var dtnw;
        var dtsp;
        
        if (isDate(document.forms[0].dt_start.value, "d")) {
          dtsp = document.forms[0].dt_start.value.split("-");
          dtnw = new Date(parseInt(dtsp[0]), parseInt(dtsp[1])-1, parseInt(dtsp[2]));
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
    } // findValue

      // ------------------------------------------------------

      function loadCompanies() {
        var frm = document.forms[0];
        
        users_type = 1; 

        if (frm.sel_companies.options.length>0) {
        
          if (frm.sel_companies.options[0].value!="COMBOLOADING") {
                        
            clearCombo(frm.sel_companies);
        
            // comboPush (frm.sel_companies, "[~Cargando...~]", "COMBOLOADING", true, true);
        
            parent.meetexec.location = "load_members.jsp?type=company&control=sel_companies&gu_workarea=" + getURLParam("gu_workarea") + (frm.nm_company.value.length>0 ? "&find="+frm.nm_company.value : "");
          }
        }
        else {
          // comboPush (frm.sel_companies, "[~Cargando...~]", "COMBOLOADING", true, true);
        
          parent.meetexec.location = "load_members.jsp?type=company&control=sel_companies&gu_workarea=" + getURLParam("gu_workarea") + (frm.nm_company.value.length>0 ? "&find="+frm.nm_company.value : "");
        }        
      } // loadCompanies

      // ------------------------------------------------------

      function loadFellows() {
        var frm = document.forms[0];
        
        users_type = 1; 

        if (frm.sel_companies.options.length>0) {
        
          if (getCombo(frm.sel_users)!="COMBOLOADING") {
                        
            clearCombo(frm.sel_users);
        
            // comboPush (frm.sel_companies, "[~Cargando...~]", "COMBOLOADING", true, true);
                	  
            parent.meetexec.location = "load_fellows.jsp?address="+getCombo(frm.sel_companies)+"&control=sel_users&gu_workarea=" + getURLParam("gu_workarea");
          }
        }
        else {
          // comboPush (frm.sel_companies, "[~Cargando...~]", "COMBOLOADING", true, true);
        
          parent.meetexec.location = "load_fellows.jsp?control=sel_users&gu_workarea=" + getURLParam("gu_workarea");
        }        
      } // loadFellows

      // ------------------------------------------------------
              
      function showComments() {
        var frm = document.forms[0];
                
          var txt = jsComments[getCombo(frm.sel_rooms)];
          if (txt)
            frm.read_comments.value = txt;
          else
            frm.read_comments.value = "";
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
      
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
<%  
    out.write("      var jsComments = new Object();\n");
    for (int r=0; r<iRooms; r++) {
      out.write("      jsComments[\""+oRooms.getStringNull(DB.nm_room,r,"")+"\"]=\"" + oRooms.getStringNull(DB.tx_comments,r,"").replace('\n',' ') + "\";\n");
    }
%>

      var met = false;
      var lst = new Array();
      var available = true;
      
      function checkAvailability() {
		    available = true;
	      var frm = document.forms[0];
	      var crm = frm.sel_rooms;
                
        if (isDate(frm.dt_start.value,"d")) {
          var s = frm.dt_start.value;
          
          var dts = new Date (parseInt(s.substr(0,4)),parseFloat(s.substr(5,2))-1,parseFloat(s.substr(8,2)),parseFloat(getCombo(frm.sel_h_start)),parseFloat(getCombo(frm.sel_m_start)), 0);
          var dte = new Date (dts.valueOf()+((Number(getCombo(frm.ti_duration))+Number(getCombo(frm.pr_cost)))*3600000));	        	        
	        for (var r=0; r<crm.options.length; r++) {
	          if (crm.options[r].selected) {
	            for (var m=0; m<lst.length; m++) {
	              var mts = lst[m][2];
	              var mte = lst[m][3];	        
	              if ("<%=gu_meeting%>"!=lst[m][0] && crm.options[r].value==lst[m][1] && ((dts<=mts && dte>mts) || (dts>=mts && dts<=mte) || (dts<mte && dte>=mte))) {
	                alert (lst[m][1]+" [~El recurso ya esta ocupado por otra actividad a la hora seleccionada~] [~Reservado por ~] "+lst[m][4]);
	                available = false;
	              } // fi
	            } // next
	          } // fi (sel_rooms.selected)
	        } // next (r) 
   	      if (dte<dts) frm.dt_end.value=frm.dt_start.value;
	      }	// fi (isDate(dt_start))
			  return true;
      } // checkAvailability

      function checkFellowAvailability() {
      	var frm = document.forms[0];
        if (isDate(frm.dt_start.value,"d") && document.forms[0].sel_users.selectedIndex>=0) {
          var ava = httpRequestText("fellow_availability.jsp?gu_meeting=<%=gu_meeting%>&gu_fellow="+getCombo(frm.sel_users)+"&dt_hour="+frm.dt_start.value+" "+getCombo(frm.sel_h_start)+":"+getCombo(frm.sel_m_start));
          if (ava=="false") {
            alert ("[~El especialista asignado ya está ocupado en otra cita a las ~]"+getCombo(frm.sel_h_start)+":"+getCombo(frm.sel_m_start));
          }
        }
      } // checkFellowAvailability
      
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
                  var dts = new Date (parseInt(s.substr(0,4)),parseInt(s.substr(5,2))-1,parseInt(s.substr(8,2)),parseInt(s.substr(11,2)),parseInt(s.substr(14,4)),parseInt(s.substr(17,2)));
                  var dte = new Date (parseInt(e.substr(0,4)),parseInt(e.substr(5,2))-1,parseInt(e.substr(8,2)),parseInt(e.substr(11,2)),parseInt(e.substr(14,4)),parseInt(e.substr(17,2)));
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
        	var dt = document.forms[0].dt_start.value;
        	if (isDate(dt,"d")) {
	          met.onreadystatechange = processMeetingsList;
            met.open("GET", "room_availability.jsp?gu_workarea=<%=gu_workarea%>&dt_start="+dt+"&dt_end="+dt, true);
            met.send(null);
          }
        }
      }

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
        setCombo(frm.pr_cost,"<% if (!oMeet.isNull(DB.pr_cost)) out.write(String.valueOf((int)oMeet.getFloat(DB.pr_cost)));%>");
<%
        if (oBookedRooms.getRowCount()>0) {
          out.write("        setCombo(frm.sel_tp_room,\""+oBookedRooms.getStringNull(DB.tp_room,0,"")+"\");\n");        
          out.write("        loadRooms(\""+oBookedRooms.getStringNull(DB.tp_room,0,"")+"\");\n");
          out.write("        setCombo(frm.sel_rooms,\""+oBookedRooms.getStringNull(DB.nm_room,0,"")+"\");\n");        
        }
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
        }
      } // fi (gu_meeting) %>        
        loadDailyMeetings();
        return true;
      } // setCombos;
      
      // ***********************************************************************************************
      
      function loadRooms(roomtype) {
        var frm = document.forms[0];
        
        clearCombo(frm.sel_rooms);
        var rms = httpRequestText("load_rooms.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&bo_available=1"+(roomtype.length>0 ? "&tp_room="+roomtype : ""));
        rms = rms.split("¨");
        var nln = rms.length;
        for (var l=0; l<nln; l++) {
          var lin = rms[l].split("`");
          if (lin.length>1) {
            comboPush (frm.sel_rooms, lin[1]+(lin[5]!="null" ? " ("+lin[5]+")" : ""), lin[1], false, false);
          }
        }
      } // loadRooms
      
      
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <FORM NAME="" METHOD="post" ACTION="meeting_edit_store.jsp" onSubmit="return validate()">
    <TABLE WIDTH="100%">
      <TR><TD><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="4" BORDER="0"></TD></TR>
      <TR>
        <TD CLASS="striptitle" WIDTH="100%"><FONT CLASS="title1">[~Editar Cita~]</FONT></TD>
        <TD ALIGN="right">
    	  <DIV class="cxMnu1" style="width:230px"><DIV class="cxMnu2">
            <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="[~Actualizar~]"> [~Actualizar~]</SPAN>
            <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="[~Imprimir~]"> [~Imprimir~]</SPAN>
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
    <INPUT TYPE="hidden" NAME="tx_meeting" MAXLENGTH="100" SIZE="60" VALUE="<%=oMeet.getStringNull(DB.tx_meeting,"")%>">
    <INPUT TYPE="hidden" NAME="bo_private" VALUE="0">
    <INPUT TYPE="hidden" NAME="ts_start">
    <INPUT TYPE="hidden" NAME="ts_end">
    <INPUT TYPE="hidden" NAME="dt_end" VALUE="<% out.write(dt_end); %>">
    <INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=oMeet.getStringNull(DB.gu_address,"")%>">
    <INPUT TYPE="hidden" NAME="attendants" VALUE="">

    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
<% if (gu_meeting.length()>0) { %>      
          <TR>
            <TD></TD>
            <TD><FONT CLASS="formplain">[~Organizada por~] <%=oCreator.getStringNull(DB.nm_user,"")+" "+oCreator.getStringNull(DB.tx_surname1,"")+" "+oCreator.getStringNull(DB.tx_surname2,"")%></FONT>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">[~Inicio:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="360" CLASS="formplain">
              <INPUT CLASS="combomini" TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="12" VALUE="<% out.write(dt_start); %>" onchange="loadDailyMeetings();checkAvailability();">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Ver Calendario~]"></A>
              &nbsp;de&nbsp;
              <SELECT CLASS="combomini" NAME="sel_h_start" onchange="checkAvailability()"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10" SELECTED>10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_m_start" onchange="checkAvailability()"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>      
              &nbsp;a&nbsp;
              <SELECT CLASS="combomini" NAME="sel_h_end" onchange="checkAvailability()"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14" SELECTED>14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT CLASS="combomini" NAME="sel_m_end" onchange="checkAvailability()"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT> 
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><INPUT TYPE="checkbox" NAME="bo_tentative"></TD>
            <TD ALIGN="left" WIDTH="360" CLASS="formplain">
					    [~La hora de inicio es s&oacute;lo tentativa sin confirmar~]
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">[~Duración:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <SELECT CLASS="combomini" NAME="ti_duration"><OPTION VALUE="4">[~Medio d&iacute;a~]</OPTION><OPTION VALUE="8">[~Dia Completo~]</OPTION></SELECT>
	            <FONT CLASS="formplain">[~Hrs extra~]</FONT>
              <SELECT CLASS="combomini" NAME="pr_cost"><OPTION VALUE="0"></OPTION><OPTION VALUE="1">1</OPTION><OPTION VALUE="2">2</OPTION><OPTION VALUE="3">3</OPTION><OPTION VALUE="4">4</OPTION><OPTION VALUE="5">5</OPTION><OPTION VALUE="6">6</OPTION><OPTION VALUE="7">7</OPTION><OPTION VALUE="8">8</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formplain">[~Tipo:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <INPUT TYPE="hidden" NAME="tp_meeting">
              <SELECT CLASS="combomini" NAME="sel_tp_meeting"><OPTION VALUE="withhr">[~Con especialista~]</OPTION><OPTION VALUE="withouthr">[~Sin Especialista~]</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100" VALIGN="top"><FONT CLASS="formplain">[~M&aacute;quina:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="360" CLASS="formplain">
              <INPUT TYPE="hidden" NAME="rooms">
              <SELECT NAME="sel_tp_room" STYLE="width:300px" onChange="loadRooms(this.options[this.selectedIndex].value)"><% out.write(sRoomTypesLookUp); %></SELECT><BR>
              <SELECT NAME="sel_rooms" CLASS="textsmall" SIZE="4" STYLE="width:340px" onChange="showComments();checkAvailability();">
              </SELECT>
              <BR>
            </TD>
          </TR>          
          <TR>
            <TD><FONT CLASS="formplain">[~Comentarios:~]</FONT></TD>
            <TD><TEXTAREA ROWS="2" CLASS="textsmall" NAME="read_comments" STYLE="border-style:none;width:340px" TABINDEX="-1" onfocus="document.forms[0].sel_rooms.focus()"></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2" ALIGN="center">
              <TABLE CELLSPACING="0" CELLPADDING="0" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                <TR HEIGHT="20">
                  <TD WIDTH="8">&nbsp;</TD>
                  <TD NOWRAP><FONT CLASS="textsmallfront">[~Clientes~]</FONT>&nbsp;<INPUT TYPE="text" NAME="nm_company" SIZE="14" onblur="if (document.forms[0].sel_companies.options.length==0) loadCompanies();">&nbsp;<A HREF="#" onclick="loadCompanies()"><IMG SRC="../images/images/find16.gif" BORDER="0"></A></TD>
                  <TD WIDTH="20"></TD>
                  <TD><FONT CLASS="textsmallfront">[~Especialistas~]</FONT></TD>
                  <TD WIDTH="8">&nbsp;</TD>
                </TR>
                <TR>
                  <TD WIDTH="8">&nbsp;</TD>
                  <TD><SELECT NAME="sel_companies" CLASS="textsmall" STYLE="width:220px" SIZE="7" onchange="loadFellows()"><%
                  	  if (oMbrAddr!=null) {
                  	    out.write("<OPTION VALUE=\""+oMbrAddr.getString(DB.gu_address)+"\" SELECTED>"+oMbrAddr.getStringNull(DB.nm_commercial,oMbrAddr.getStringNull(DB.nm_legal,""))+" ("+oMbrAddr.getStringNull(DB.nm_state,"")+")");
                  	  }
                  	  %></SELECT></TD>
                  <TD WIDTH="20"></TD>
                  <TD>
                    <SELECT NAME="sel_users" CLASS="textsmall" STYLE="width:220px" SIZE="7" onchange="checkFellowAvailability()"><%=sFellows%></SELECT>
                  </TD>
                  <TD WIDTH="8">&nbsp;</TD>
                </TR>
                <TR><TD></TD><TD COLSPAN="4" ALIGN="left"><INPUT TYPE="checkbox" NAME="bo_notify" VALUE="1">&nbsp;<FONT CLASS="textsmallfront">[~Notificar por e-mail a los clientes~]</FONT></TD></TR>
                <TR><TD COLSPAN="5" HEIGHT="8"></TD></TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formplain">[~Comentarios:~]</FONT></TD>
            <TD ALIGN="left" WIDTH="360">
              <TEXTAREA STYLE="font-family:Verdana,sans-serif,Arial,Helvetica;font-size:7pt;width:340px" NAME="de_meeting" ROWS="2"><%=oMeet.getStringNull(DB.de_meeting,"")%></TEXTAREA>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<%	    if (gu_fellow.equals(getCookie(request, "userid", "")))
              if (bIsGuest) { %>    
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="[~Guardar~]" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('[~Su nivel de privilegio como Invitado no le permite efectuar esta acción~]')">&nbsp;&nbsp;&nbsp;
<%            } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="[~Guardar~]" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<%          } %>
    	      <INPUT TYPE="button" ACCESSKEY="c" VALUE="[~Cancelar~]" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
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