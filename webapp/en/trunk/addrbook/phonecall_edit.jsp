<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.Contact,com.knowgate.misc.Gadgets,com.knowgate.crm.PhoneCall,com.knowgate.projtrack.Bug" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<% 
/*
  
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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
  String sLastCall = getCookie(request, "lastcallfor", null);

  final int BugTracker=10;
  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  final boolean bBugTrackerEnabled = ((iAppMask & (1<<BugTracker))!=0);
  
  String sLanguage = getNavigatorLanguage(request);
  Date dtNow = new Date();
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_phonecall = request.getParameter("gu_phonecall");
  String gu_contact = request.getParameter("gu_contact");
  String gu_fellow = request.getParameter("gu_fellow");
  String gu_bug = nullif(request.getParameter("gu_bug"));

  String sUsersCombo = null;
  
  PhoneCall oCall = new PhoneCall();
    
  JDCConnection oConn = null;
  DBSubset oUsrs = null;
  int iUsrs = 0;
  ACLUser oLastCalled = null;
  Contact oCont = null;
  String sTlBug = null;
  String sTxPhone = "";

  try {
    
    oConn = GlobalDBBind.getConnection("phonecall_edit");  

    if (gu_bug.length()>0)
      sTlBug = Gadgets.left(new Bug(oConn, gu_bug).getString(DB.tl_bug),30); 
    
    if (gu_fellow!=null) {
        oUsrs = new DBSubset(DB.k_users, DB.gu_user + "," + DBBind.Functions.ISNULL + "(" + DB.nm_user + "," + DB.tx_nickname + ")," + DB.tx_surname1 + "," + DB.tx_surname2, DB.gu_user + "=? ORDER BY 2,3,4", 100);

        iUsrs = oUsrs.load(oConn, new Object[]{gu_fellow});      

	if (iUsrs>0) {
          sUsersCombo = "<OPTION VALUE=\"" + oUsrs.getString(0,0) + "\">";        
          sUsersCombo += Gadgets.HTMLEncode(oUsrs.getStringNull(1,0,""));        
          if (!oUsrs.isNull(2,0)) sUsersCombo += " " + Gadgets.HTMLEncode(oUsrs.getString(2,0));
          if (!oUsrs.isNull(3,0)) sUsersCombo += " " + Gadgets.HTMLEncode(oUsrs.getString(3,0));
	}
	else
	  sUsersCombo = "";
	
	if (oCall.isNull(DB.tp_phonecall))
          oCall.replace(DB.tp_phonecall, "R");
    }
    else {
      sUsersCombo = GlobalCacheClient.getString("["+gu_workarea+",users]");
      
      if (null==sUsersCombo) {

        oUsrs = new DBSubset(DB.k_users, DB.gu_user + "," + DBBind.Functions.ISNULL + "(" + DB.nm_user + "," + DB.tx_nickname + ") ," + DB.tx_surname1 + "," + DB.tx_surname2, DB.gu_workarea + "=? ORDER BY 2,3,4", 100);

        iUsrs = oUsrs.load(oConn, new Object[]{gu_workarea});      
      } // fi (null==sUsersCombo)
    }
    
    if (null!=sLastCall)
      oLastCalled = new ACLUser(oConn, sLastCall);
    
    if (null!=gu_phonecall) {
      oCall.load(oConn, new Object[]{gu_phonecall});    
      if (!oCall.isNull(DB.gu_bug)) {
        gu_bug = oCall.getString(DB.gu_bug);
      }
    } else {
      oCall.put(DB.id_status, (short) 0);
      if (gu_bug.length()>0) oCall.put(DB.gu_bug, gu_bug);
    }

    if (null!=gu_contact) {
      oCont = new Contact(oConn, gu_contact);
      if (oCall.isNull(DB.tp_phonecall))
        oCall.replace(DB.tp_phonecall, "R");
      sTxPhone = DBCommand.queryStr(oConn, "SELECT tx_phone FROM "+DB.k_phone_calls+" WHERE "+DB.gu_contact+"='"+gu_contact+"'");
      if (null==sTxPhone) {
        String[] aTxPhones = DBCommand.queryStrs(oConn, "SELECT a."+DB.work_phone+",a."+DB.home_phone+",a."+DB.mov_phone+" FROM "+DB.k_member_address+" a,"+DB.k_x_contact_addr+" x WHERE a."+DB.gu_contact+"=x."+DB.gu_contact+" AND x."+DB.gu_contact+"='"+gu_contact+"'");
        if (aTxPhones[0]!=null) sTxPhone = aTxPhones[0];
        else if (aTxPhones[1]!=null) sTxPhone = aTxPhones[1];
        else if (aTxPhones[2]!=null) sTxPhone = aTxPhones[2];
        else sTxPhone = "";
      }
    }
    
    oConn.close("phonecall_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("phonecall_edit");
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  

  if (null==sUsersCombo) {

    StringBuffer oStrBuff = new StringBuffer(100*iUsrs);

    for (int u=0; u<iUsrs; u++) {
      oStrBuff.append("<OPTION VALUE=\"" + oUsrs.getString(0,u) + "\">");
      oStrBuff.append(Gadgets.HTMLEncode(oUsrs.getStringNull(1,u,"")));
      if (!oUsrs.isNull(2,u)) oStrBuff.append (" " + Gadgets.HTMLEncode(oUsrs.getString(2,u)));
      if (!oUsrs.isNull(3,u)) oStrBuff.append (" " + Gadgets.HTMLEncode(oUsrs.getString(3,u)));
      oStrBuff.append("</OPTION>");
    } // next (u)
  
    sUsersCombo = oStrBuff.toString();
    
    GlobalCacheClient.put ("["+gu_workarea+",users]", sUsersCombo);

    oStrBuff = null;
  }
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=(null==gu_phonecall ? "New Call" : "Edit Call") %></TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/autosuggest20.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      

      // ------------------------------------------------------

      function loadContacts() {
        var frm = document.forms[0];
                    
        if (frm.sel_users.options.length>0) {
        
          if (frm.sel_users.options[0].value!="COMBOLOADING") {
                        
            clearCombo(frm.sel_users);
        
            comboPush (frm.sel_users, "Loading...", "COMBOLOADING", true, true);
        
            if (frm.contact_person.value.length>0)
              parent.phonecallexec.location.href = "load_contacts.jsp?gu_workarea=" + getURLParam("gu_workarea") + "&find=" + escape(frm.contact_person.value);
            else
              parent.phonecallexec.location.href = "load_contacts.jsp?gu_workarea=" + getURLParam("gu_workarea");        
          }
        }
        else {
          clearCombo(frm.sel_users);
          comboPush (frm.sel_users, "Loading...", "COMBOLOADING", true, true);
        
          if (frm.contact_person.value.length>0) {
            parent.phonecallexec.location.href = "load_contacts.jsp?gu_workarea=" + getURLParam("gu_workarea") + "&find=" + escape(frm.contact_person.value);
          }
          else {
            parent.phonecallexec.location.href = "load_contacts.jsp?gu_workarea=" + getURLParam("gu_workarea");
          }
        }
      } // loadContacts()

      // ------------------------------------------------------

      function loadProjects() {
<%      if (bBugTrackerEnabled && (nullif(request.getParameter("gu_bug")).length()==0)) { %>      
        var frm = document.forms[0];
        var cmb = document.forms[0].sel_project;
        var bug = document.forms[0].sel_bugs;
	      var loading = false;
	
        clearCombo(cmb);
        clearCombo(bug);
        
        if (cmb.options.length>0) loading = (cmb.options[0].value=="COMBOLOADING");

        if (!loading) {
	  var usr;	    
	  if (frm.sel_users.options.selectedIndex>0)
	    usr = getCombo(frm.sel_users);
	  else
	    usr = "";
          comboPush (cmb, "Loading...", "COMBOLOADING", true, true);
          comboPush (cmb, "", "", false, false);
          comboPush (bug, "Loading...", "COMBOLOADING", true, true);
          comboPush (bug, "", "", false, false);          
          parent.phonecallexec.location.href = "load_projects.jsp?gu_user=" + getCombo(frm.sel_recipients) + "&gu_fellow=" + getURLParam("gu_fellow") + "&gu_contact=" + getCombo(frm.sel_users) + "&gu_workarea=" + getURLParam("gu_workarea");        
        } // fi
<% } %>        
      } // loadProjects()
      
      // ------------------------------------------------------

      function createProject() {	  
          window.open("../projtrack/prj_new.jsp?standalone=1", "newproject", "menubar=no,toolbar=no,width=780,height=520");       
      } // createProject()

      // ------------------------------------------------------

      function setFromTo(ft) {
        if (ft=="R") {
          document.getElementById("from").innerHTML = "From";
          document.getElementById("to").innerHTML = "To";
        } else {
          document.getElementById("from").innerHTML = "To";
          document.getElementById("to").innerHTML = "From";        
        }
      } // setFromTo()

      // ------------------------------------------------------
	
      function validate() {
        var frm = window.document.forms[0];

        if (!frm.tp_phonecall[0].checked && !frm.tp_phonecall[1].checked) {
	  alert ("You must select either Sent or Received call");
	  return false;          
        }
        
	if (frm.tx_comments.value.length>254) {
	  alert ("Subject cannot exceed 254 characters");
	  return false;
	}

	if (frm.tx_comments.value.indexOf('"')>=0 || frm.tx_comments.value.indexOf("'")>=0) {
	  alert ("Subject field contains invalid characters");
	  return false;
	}
	
	if (frm.sel_recipients.options.selectedIndex<1) {
	  alert ("You must select a recipient for the call");
	  return false;
	}
        
        if (frm.tx_phone.value.length==0 && frm.contact_person.value.length==0) {
	  alert ("You must select a contact person or phone number for the call");
	  return false;
	}

        if (frm.tp_phonecall[0].checked && frm.contact_person.value.length==0) {
	  if (!window.confirm("Received call lacks origin specification. Save it anyway?")) 
	    return false;
        }

			  if (!isDate(frm.tx_start.value,"d")) {
	  	    alert ("Call date is not valid");
	        frm.tx_start.focus();
	        return false;
			  }	
	
	frm.dt_start.value = frm.tx_start.value + " " + getCombo(frm.sel_h_start) + ":" + getCombo(frm.sel_m_start) + ":00";
	
	if (frm.sel_recipients.options.length>0)
          frm.gu_user.value = getCombo(frm.sel_recipients);

        
        if (frm.contact_person.value.length==0 && frm.sel_users.selectedIndex>=0)
	frm.contact_person.value = getComboText(frm.sel_users);
	
	if (frm.chk_bug.checked) {
	  if (frm.sel_project.selectedIndex<=0) {
	    alert ("A project is required for the incident");
	    return false;	
	  }
	  if (frm.sel_bugs.selectedIndex>0) {
	    alert ("It is not possible to create an incident and assign to an already existing one all at the same time");
	    return false;	
	  }
	}

        if (frm.sel_project.selectedIndex>0) frm.gu_project.value = getCombo(frm.sel_project);
	if (frm.sel_bugs.selectedIndex>0) frm.gu_bug.value = getCombo(frm.sel_bugs);

        var opt = frm.sel_users.options;
        var ops = opt.length;        
	var txt = frm.contact_person.value;
	                
        for (var o=0; o<ops; o++)
          if (opt[o].text==txt) {
            frm.gu_contact.value = opt[o].value;
            break;
          }
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo (frm.sel_h_start,"<% if (oCall.isNull(DB.dt_start)) out.write(Gadgets.leftPad(String.valueOf(dtNow.getHours()), '0', 2)); else out.write(Gadgets.leftPad(String.valueOf(oCall.getDate(DB.dt_start).getHours()), '0', 2));%>");
        setCombo (frm.sel_m_start,"<% if (oCall.isNull(DB.dt_start)) out.write(Gadgets.leftPad(String.valueOf(dtNow.getMinutes()), '0', 2)); else out.write(Gadgets.leftPad(String.valueOf(oCall.getDate(DB.dt_start).getMinutes()), '0', 2)); %>");
        setCombo (frm.sel_recipients, getCookie("lastcallfor"));

<%      if (null!=oLastCalled && oCall.isNull(DB.gu_user)) {
	  out.write ("        frm.gu_user.value = \"" + sLastCall + "\";");
	  out.write ("        setCombo (frm.sel_users, \"" + sLastCall + "\");\n");
        }
        else if (!oCall.isNull(DB.gu_user)) {
	  out.write ("        frm.gu_user.value = \"" + oCall.getString(DB.gu_user) + "\";");
	  out.write ("        setCombo (frm.sel_users, \"" + oCall.getString(DB.gu_user) + "\");\n");
        }
        
        if (null!=gu_contact) {
          String sFullName = oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,"");
          sFullName = sFullName.trim();
          
	  out.write ("        frm.contact_person.value = \"" + sFullName + "\";");
	  out.write ("        frm.gu_contact.value = \"" + gu_contact + "\";");
	  out.write ("        comboPush (frm.sel_users, \"" + sFullName + "\",\"" + gu_contact + "\", true, true);\n");
        }
	if (sTlBug!=null) {
	  out.write ("        comboPush (frm.sel_bugs, \"" + sTlBug + "\",\"" + oCall.getString(DB.gu_bug) + "\", true, true);\n");
	}

	if (oCall.getStringNull(DB.tp_phonecall, "").equals("S")) {
	  out.write ("        document.getElementById(\"from\").innerHTML = \"To\";\n");
	  out.write ("        document.getElementById(\"to\").innerHTML = \"From\";\n");
	}

%>        
      } // setCombos;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=(null==gu_phonecall ? "New Call" : "Edit Call") %></FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="phonecall_edit_store.jsp" onSubmit="return validate()">
  	<INPUT TYPE="hidden" NAME="gu_phonecall" VALUE="<%=nullif(gu_phonecall)%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="id_status" VALUE="<% out.write(String.valueOf(oCall.getShort(DB.id_status))); %>">
    <INPUT TYPE="hidden" NAME="gu_project" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_bug" VALUE="<%=gu_bug%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Type</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="radio" NAME="tp_phonecall" VALUE="R" <% out.write(oCall.getStringNull(DB.tp_phonecall, "").equals("R") ? "CHECKED" : ""); %> onclick="setFromTo('R')">&nbsp;<FONT CLASS="formplain">Received</FONT>&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="tp_phonecall" VALUE="S" <% out.write(oCall.getStringNull(DB.tp_phonecall, "").equals("S") ? "CHECKED" : ""); %> onclick="setFromTo('S')">&nbsp;<FONT CLASS="formplain">Sent</FONT>
            </TD>
	  </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Date</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="dt_start">
              <INPUT TYPE="text" NAME="tx_start" MAXLENGTH="10" SIZE="10" VALUE="<% if (oCall.isNull(DB.dt_start)) out.write(DBBind.escape(dtNow, "shortDate")); else out.write(DBBind.escape(oCall.getDate(DB.dt_start), "shortDate")); %>">
              <A HREF="javascript:showCalendar('tx_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
              <SELECT NAME="sel_h_start"><OPTION VALUE=""><OPTION VALUE="00">00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09" SELECTED>09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION></SELECT>
              <SELECT NAME="sel_m_start"><OPTION VALUE=""><OPTION VALUE="00" SELECTED>00</OPTION><OPTION VALUE="01">01</OPTION><OPTION VALUE="02">02</OPTION><OPTION VALUE="03">03</OPTION><OPTION VALUE="04">04</OPTION><OPTION VALUE="05">05</OPTION><OPTION VALUE="06">06</OPTION><OPTION VALUE="07">07</OPTION><OPTION VALUE="08">08</OPTION><OPTION VALUE="09">09</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION><OPTION VALUE="13">13</OPTION><OPTION VALUE="14">14</OPTION><OPTION VALUE="15">15</OPTION><OPTION VALUE="16">16</OPTION><OPTION VALUE="17">17</OPTION><OPTION VALUE="18">18</OPTION><OPTION VALUE="19">19</OPTION><OPTION VALUE="20">20</OPTION><OPTION VALUE="21">21</OPTION><OPTION VALUE="22">22</OPTION><OPTION VALUE="23">23</OPTION><OPTION VALUE="24">24</OPTION><OPTION VALUE="25">25</OPTION><OPTION VALUE="26">26</OPTION><OPTION VALUE="27">27</OPTION><OPTION VALUE="28">28</OPTION><OPTION VALUE="19">29</OPTION><OPTION VALUE="30">30</OPTION><OPTION VALUE="31">31</OPTION><OPTION VALUE="32">32</OPTION><OPTION VALUE="33">33</OPTION><OPTION VALUE="34">34</OPTION><OPTION VALUE="35">35</OPTION><OPTION VALUE="36">36</OPTION><OPTION VALUE="37">37</OPTION><OPTION VALUE="38">38</OPTION><OPTION VALUE="19">39</OPTION><OPTION VALUE="40">40</OPTION><OPTION VALUE="41">41</OPTION><OPTION VALUE="42">42</OPTION><OPTION VALUE="43">43</OPTION><OPTION VALUE="44">44</OPTION><OPTION VALUE="45">45</OPTION><OPTION VALUE="46">46</OPTION><OPTION VALUE="47">47</OPTION><OPTION VALUE="48">48</OPTION><OPTION VALUE="19">49</OPTION><OPTION VALUE="50">50</OPTION><OPTION VALUE="51">51</OPTION><OPTION VALUE="52">52</OPTION><OPTION VALUE="53">53</OPTION><OPTION VALUE="54">54</OPTION><OPTION VALUE="55">55</OPTION><OPTION VALUE="56">56</OPTION><OPTION VALUE="57">57</OPTION><OPTION VALUE="58">58</OPTION><OPTION VALUE="19">59</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong"><DIV ID="to">To</DIV></TD>
            <TD ALIGN="left" WIDTH="370">
	      <INPUT TYPE="hidden" NAME="gu_user" VALUE="<% out.write(oCall.getStringNull(DB.gu_user, "")); %>">
              <SELECT NAME="sel_recipients" STYLE="width:360px" onchange="<% if (bBugTrackerEnabled) { out.write("loadProjects();"); } %>"><OPTION VALUE=""></OPTION><% out.write(sUsersCombo); %></SELECT>
	    </TD>
	  </TR>
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="90" CLASS="formstrong"><DIV ID="from">From</DIV></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<% out.write(oCall.getStringNull(DB.gu_contact, "")); %>">
              <TABLE><TR><TD><INPUT TYPE="text" NAME="contact_person" SIZE="35" MAXLENGTH="200" VALUE="<% out.write(oCall.getStringNull(DB.contact_person, "")); %>" onkeypress="clearCombo(document.forms[0].sel_users)"></TD><TD><IMG SRC="../images/images/search16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD><TD><A HREF="#" CLASS="linkplain" onclick="loadContacts()">Search</A></TD></TR></TABLE>
              <SELECT NAME="sel_users" STYLE="width:360px" onchange="document.forms[0].contact_person.value=getComboText(this); <% if (bBugTrackerEnabled) { out.write("loadProjects();"); } %>"></SELECT>
	    </TD>
	  </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Phone</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	          <INPUT TYPE="text" MAXLENGTH="16" NAME="tx_phone" SIZE="20" VALUE="<% out.write(oCall.getStringNull(DB.tx_phone, sTxPhone)); %>">
	    </TD>
	  </TR>
          <TR>
            <TD VALIGN="top" ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Subject</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	      <TEXTAREA ROWS="2" COLS="40" NAME="tx_comments"><% out.write(oCall.getStringNull(DB.tx_comments, "")); %></TEXTAREA>
	    </TD>
	  </TR>
<% if (bBugTrackerEnabled) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Incident</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	      <SELECT NAME="sel_bugs" STYLE="display:block" onchange="if (this.selectedIndex>0) { if (document.forms[0].tx_comments.value.length==0) document.forms[0].tx_comments.value=this.options[this.selectedIndex].text; document.forms[0].chk_bug.checked=false; }"></SELECT>
	    </TD>
	  </TR>
          <TR>
            <TD></TD>
            <TD>
              <INPUT TYPE="checkbox" NAME="chk_bug" VALUE="1" onclick="if (this.checked)  { loadProjects(); document.forms[0].sel_project.style.display='block'; document.forms[0].sel_bugs.style.display='none'; document.forms[0].sel_bugs.selectedIndex=0; } else { document.forms[0].sel_project.style.display='none'; document.forms[0].sel_bugs.style.display='block'; document.forms[0].sel_project.selectedIndex=0; }" <% if (!oCall.isNull(DB.gu_bug)) out.write("DISABLED=\"true\""); %>>&nbsp;<FONT CLASS="formplain">Create incident from this call</FONT>
            </TD>
          </TR>
<% if (sTlBug==null) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><A HREF="#" onclick="createProject()" CLASS="linkplain">Project</A></TD>
            <TD ALIGN="left" WIDTH="370"><SELECT NAME="sel_project" STYLE="display:none"></SELECT></TD>
	        </TR>

<% } } %>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
    	      <BR>
    	    </TD>
    	  </TR>            
        </TABLE>        
      </TD></TR>      
    </TABLE>                 
  </FORM>
</BODY>
<SCRIPT TYPE="text/javascript">
    <!--  
      
      var AutoSuggestOptions = { script:"String('../common/autocomplete.jsp?nm_table=k_contact_telephone&gu_workarea=<%=gu_workarea%>&tx_where=')+getCombo(document.forms[0].sel_users)+'&'", varname:"tx_like",minchars:2,form:0, callback: function (obj) { } };
      
      var AutoSuggestPhone = new AutoSuggest("tx_phone", AutoSuggestOptions);
    //-->
</SCRIPT>

</HTML>
<%@ include file="../methods/page_epilog.jspf" %>
