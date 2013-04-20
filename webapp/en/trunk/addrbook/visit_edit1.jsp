<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Meeting,com.knowgate.crm.Contact,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
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
 
  final int Sales=16;
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

  String id_user = getCookie (request, "userid", null);  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_meeting = nullif(request.getParameter("gu_meeting"));
  String gu_fellow = nullif(request.getParameter("gu_fellow"));
  String gu_sales_man = nullif(request.getParameter("gu_sales_man"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  boolean bo_private = false;
  
  String dt_start = null;
  String dt_end = null;
  DBSubset oFellows=null;
  Contact oContact = new Contact();
    
  DBSubset oRooms = GlobalCacheClient.getDBSubset("k_rooms.nm_room[" + gu_workarea + "]");
  DBSubset oSales = new DBSubset(DB.k_sales_men+" s,"+DB.k_users+" u",
  				 "u."+DB.gu_user+",u."+DB.nm_user+",u."+DB.tx_surname1+",u."+DB.tx_surname2,
  				 "s."+DB.gu_sales_man+"=u."+DB.gu_user+" AND u."+DB.bo_active+"<>0 AND s."+DB.gu_workarea+"=? "+
  				 (gu_sales_man.length()==0 ? "" : " AND s."+DB.gu_sales_man+"='"+gu_sales_man+"'")+" ORDER BY 1,2,3",100);
  int iRooms = 0;
  int iSales = 0;
  
  boolean bIsGuest = true;

  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection("meetingedit");
    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
       
    dt_end = dt_start = nullif(request.getParameter("date"), DBBind.escape(new Date(), "shortDate"));
    gu_fellow = nullif(request.getParameter("gu_fellow"));

    if (null==oRooms) {
      oRooms = new DBSubset (DB.k_rooms,
       			     DB.nm_room + "," + DB.tx_company + "," + DB.tx_location + "," + DB.tp_room + "," + DB.tx_comments,
      			     DB.bo_available + "=1 AND " + DB.gu_workarea + "='" + gu_workarea + "' ORDER BY 4,1", 50);
      
      iRooms = oRooms.load (oConn);
            
      GlobalCacheClient.putDBSubset("k_rooms", "k_rooms.nm_room[" + gu_workarea + "]", oRooms);           
    } // fi(oRooms)
    else {
      iRooms = oRooms.getRowCount();
    }
    iSales = oSales.load(oConn, new Object[]{gu_workarea});

		if (gu_contact.length()>0) {
	    oContact.load(oConn, gu_contact);
	  }
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("meetingedit");

    oConn=null;
    
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
     
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
   
%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Arrange meeting</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      var users_type = -1;
      
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
	
	if (frm.dt_start.value.length==0) {
	  alert ("Start date is mandatory");
	  return false;
	}

	if (!isDate(frm.dt_start.value, "d") ) {
	  alert ("Invalid Start Date");
	  return false;	  
	}

	if (frm.dt_end.value.length==0) {
	  alert ("End date is mandatory");
	  return false;
	}

	if (!isDate(frm.dt_end.value, "d") ) {
	  alert ("Invalid End Date");
	  return false;	  
	}
	
	if (frm.dt_start.value==frm.dt_end.value) {  
	  if (parseInt(getCombo(frm.sel_h_start),10)*100+parseInt(getCombo(frm.sel_m_start),10)>=parseInt(getCombo(frm.sel_h_end),10)*100+parseInt(getCombo(frm.sel_m_end),10)) {
	    alert ("End time must be after Start time");
	    return false;	  
	  }
	}
	
	if (frm.de_meeting.value.length>1000) {
	  alert ("Meeting description cannot exceed 1000 characters");
	  return false;
	}
        
        frm.attendants.value = "";     
        for (var g=0; g<opt.length; g++)
          frm.attendants.value += opt[g].value + ",";
        txt = frm.attendants.value;
        if (frm.attendants.value.length==0) {
	  alert ("At least one salesman must be selected for attending the meeting");
	  return false;
        }
        if (txt.charAt(txt.length-1)==',') frm.attendants.value = txt.substr(0,txt.length-1);

        frm.rooms.value = "";
        for (var r=0; r<opr.length; r++)
          if (opr[r].selected && opr[r].value.length>0)
            frm.rooms.value += opr[r].value + ",";
        txt = frm.rooms.value; 
        if (txt.charAt(txt.length-1)==',') frm.rooms.value = txt.substr(0,txt.length-1);
	        
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
      out.write("\"" + oRooms.getStringNull(DB.tx_comments,r,"") + "\"");
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
	        }
	      }
	    }
	  }
	  if (dte<dts) frm.dt_end.value=frm.dt_start.value;
	}
	return true;
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
	  met.onreadystatechange = processMeetingsList;
          met.open("GET", "room_availability.jsp?gu_workarea=<%=gu_workarea%>&dt_start=<%=dt_start%>&dt_end=<%=dt_end%>", true);
          met.send(null);
        }
      }

      function setCombos() {
        var opt1 = document.forms[0].sel_users.options;
        var opt2 = document.forms[0].sel_attendants.options;
        var sel2 = document.forms[0].sel_attendants;
			  var opt;
			  
        loadDailyMeetings();

<%      if (gu_sales_man.length()>0) { %>
	        opt = new Option(opt1[0].text, opt1[0].value);
          opt2[sel2.length] = opt;
<%      }
        if (gu_contact.length()>0) { %>
	        opt = new Option("<%=oContact.getStringNull(DB.tx_name,"")+" "+oContact.getStringNull(DB.tx_surname,"")%>", "<%=oContact.getString(DB.gu_contact)%>");
          opt2[sel2.length] = opt;        
<%      } %>
      } // setCombos
      
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <FORM NAME="" METHOD="post" ACTION="visit_edit2.jsp" onSubmit="return validate()">
    <TABLE WIDTH="100%">
      <TR><TD><IMG style="display:block" SRC="../images/images/spacer.gif" HEIGHT="4" BORDER="0"></TD></TR>
      <TR><TD CLASS="striptitle"><FONT CLASS="title1">Arrange meeting</FONT></TD></TR>
    </TABLE>  
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_meeting" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_fellow" VALUE="<%=gu_fellow%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="tp_meeting" VALUE="meeting">
    <INPUT TYPE="hidden" NAME="bo_private" VALUE="">
    <CENTER>
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Start:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="ts_start">
              <INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(dt_start); %>" onchange="loadDailyMeetings();checkAvailability();">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
              <SELECT NAME="sel_h_start" onchange="checkAvailability()"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT NAME="sel_m_start" onchange="checkAvailability()"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>	      
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">End:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	      <INPUT TYPE="hidden" NAME="ts_end">
              <INPUT TYPE="text" NAME="dt_end" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(dt_end); %>" onchange="loadDailyMeetings();checkAvailability();">
              <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>              
              <SELECT NAME="sel_h_end" onchange="checkAvailability()"><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT NAME="sel_m_end" onchange="checkAvailability()"><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="55">55</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <TEXTAREA NAME="de_meeting" ROWS="2" COLS="40"></TEXTAREA>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Resources:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
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
                  <TD><FONT CLASS="textsmallfront">Sales Men</FONT></TD>
                  <TD WIDTH="50"></TD>
                  <TD><FONT CLASS="textsmallfront">Attendants</FONT></TD>
                  <TD WIDTH="8">&nbsp;</TD>
                </TR>
                <TR>
                  <TD WIDTH="8">&nbsp;</TD>
                  <TD>
                    <SELECT NAME="sel_users" CLASS="textsmall" STYLE="width:180px" SIZE="12" MULTIPLE><%
                    for (int s=0; s<iSales; s++)
		                  out.write("<OPTION VALUE=\""+oSales.getString(0,s)+"\">"+oSales.getStringNull(1,s,"")+" "+oSales.getStringNull(2,s,"")+" "+oSales.getStringNull(3,s,"")+"</OPTION>"); %>
                    </SELECT>
                  </TD>
                  <TD ALIGN="center" VALIGN="middle"><INPUT TYPE="button" NAME="AddUsrs" VALUE="++ >>" TITLE="Add" STYLE="width:40px" onclick="addUsrs()"><BR><BR><INPUT TYPE="button" NAME="RemUsrs" VALUE="<< - -" TITLE="Remove" STYLE="width:40px" onclick="remUsrs()"></TD>
                  <TD>
                    <SELECT NAME="sel_attendants" CLASS="textsmall" STYLE="width:180px" SIZE="12" MULTIPLE></SELECT>
                    <INPUT TYPE="hidden" NAME="attendants" VALUE="">
                  </TD>
                  <TD WIDTH="8">&nbsp;</TD>
                </TR>
                <TR><TD></TD><TD COLSPAN="4" ALIGN="left"><INPUT TYPE="checkbox" NAME="bo_notify" VALUE="1" CHECKED>&nbsp;<FONT CLASS="textsmallfront">Notify salesmen by e-mail</FONT></TD></TR>
                <TR><TD COLSPAN="5" HEIGHT="8"></TD></TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<%          if (bIsGuest) { %>    
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Next" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<%            } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Next" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<%            } %>
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
