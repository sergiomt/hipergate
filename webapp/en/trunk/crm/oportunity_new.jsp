<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*

  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_writer = getCookie (request, "userid", null);

  String sLocationLookUp = "", sStreetLookUp = "", sStatusLookUp = "", sOriginLookUp = "", sObjectiveLookUp = "", sCountriesLookUp = "";

  JDCConnection oConn = null;
  boolean bAllCaps = false;
    
  try {    
    oConn = GlobalDBBind.getConnection("oportunity_new");  

    bAllCaps = WorkArea.allCaps(oConn, gu_workarea);
    
    sLocationLookUp = DBLanguages.getHTMLSelectLookUp (oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_location, sLanguage);
    sStreetLookUp = DBLanguages.getHTMLSelectLookUp (oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_street, sLanguage);
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_status, sLanguage);
    sOriginLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_oportunities_lookup, gu_workarea, DB.tp_origin, sLanguage);
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);

    %><%@ include file="oportunity_listbox.jspf" %><%
    
    oConn.close("oportunity_new");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("oportunity_new");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: New Opportunity</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript">
    <!--
    
    var allcaps = <%=String.valueOf(bAllCaps)%>;

      function setCombos() {
        var frm = document.forms[0];
        setCombo(frm.sel_status, "NUEVA");
        if (frm.gu_address.value.length==0) {
          if (getUserLanguage()=="en")
            setCombo(frm.sel_country, "us");
          else
            setCombo(frm.sel_country, getUserLanguage());
	          loadstates();
        }
      }
      
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--

      // ------------------------------------------------------
      
      var httpreq = null;

      function processStatesList() {
          if (httpreq.readyState == 4) {
            if (httpreq.status == 200) {
	      var vl,lb;
	      var frm = window.document.forms[0];
	      var scmb = frm.sel_state;
    	      var lkup = httpreq.responseXML.getElementsByTagName("lookup");
	      if (lkup) {
    	        for (var l = 0; l < lkup.length; l++) {
    	          vl = getElementText(lkup[l], "value");
    	          lb = getElementText(lkup[l], "label");
		            comboPush (scmb, lb, vl, false, false);
	      } // next (l)
	      sortCombo(scmb);
	      } // fi (lkup)
	      httpreq = null;
	      if (adrxml!=null) {
	        frm.nm_state.value = nullif(getElementText(adrxml, "nm_state"));
  	        frm.id_state.value = nullif(getElementText(adrxml, "id_state"));
		          setCombo(frm.sel_state, frm.id_state.value);
	      }
            } // fi (status == 200)
	  } // fi (readyState == 4)
      } // processStatesList

      function loadstates() {
	      var frm = window.document.forms[0];

        clearCombo(frm.sel_state);
        
        if (frm.sel_country.options.selectedIndex>0) {
          httpreq = createXMLHttpRequest();
          if (httpreq) {
	          httpreq.onreadystatechange = processStatesList;            
            httpreq.open("GET", "../common/addr_xmlfeed.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country), true);
            httpreq.send(null);
          }
        }  
      } // loadstates

      // ------------------------------------------------------

      var addrreq = null;
      var adrxml = null;

      function loadContactData() {
	      var frm = window.document.forms[0];
	      var txt = frm.tx_email.value.trim();
	      if (txt.length>0) {
	      if (!check_email(txt)) {
	        alert ("email address is not valid");
	        return false;
        } else {
            var addrreq = createXMLHttpRequest();
            if (addrreq) {
              addrreq.open("GET", "../common/memberaddress_xmlfeed.jsp?email="+frm.tx_email.value+"&workarea="+frm.gu_workarea.value+"&writer="+frm.gu_writer.value, false);
              addrreq.send(null);              
    	        var adrxml = addrreq.responseXML.getElementsByTagName("MemberAddress");
	            if (adrxml) {
      	        adrxml = adrxml[0];
      	        frm.id_country.value = nullif(getElementText(adrxml, "id_country"));
 	              if (frm.id_country.value.length==0) frm.id_country.value = "es";
  	            setCombo(frm.sel_country, frm.id_country.value);
  	            frm.nm_country.value = nullif(getElementText(adrxml, "nm_country"));
  	            if (frm.nm_country.value.length==0) frm.nm_country.value = "España";
      	        frm.gu_address.value = nullif(getElementText(adrxml, "gu_address"));
      	        frm.ix_address.value = nullif(getElementText(adrxml, "ix_address"));
      	        frm.gu_contact.value = nullif(getElementText(adrxml, "gu_contact"));
      	        frm.gu_company.value = nullif(getElementText(adrxml, "gu_company"));
      	        frm.nm_legal.value = nullif(getElementText(adrxml, "nm_legal"));
      	        frm.tx_name.value = nullif(getElementText(adrxml, "tx_name"));
      	        frm.tx_surname.value = nullif(getElementText(adrxml, "tx_surname"));
      	        frm.sn_passport.value = nullif(getElementText(adrxml, "sn_passport"));
      	        frm.mn_city.value = nullif(getElementText(adrxml, "mn_city"));
      	        frm.tp_street.value = nullif(getElementText(adrxml, "tp_street"));
  		          setCombo(frm.sel_street, frm.tp_street.value);
      	        frm.nm_street.value = nullif(getElementText(adrxml, "nm_street"));
      	        frm.nu_street.value = nullif(getElementText(adrxml, "nu_street"));
      	        frm.zipcode.value = nullif(getElementText(adrxml, "zipcode"));
      	        frm.work_phone.value = nullif(getElementText(adrxml, "work_phone"));
      	        frm.direct_phone.value = nullif(getElementText(adrxml, "direct_phone"));
      	        frm.home_phone.value = nullif(getElementText(adrxml, "home_phone"));
      	        frm.mov_phone.value = nullif(getElementText(adrxml, "mov_phone"));
      	        if (nullif(getElementText(adrxml, "id_nationality")).length==0)
        	        setCombo(frm.id_nationality, "es");
      	        else
      	          setCombo(frm.id_nationality, nullif(getElementText(adrxml, "id_nationality")));
      	        setCombo(frm.id_gender, nullif(getElementText(adrxml, "id_gender")));
  	            addrreq = false;
  	      	    loadstates();
	            } // fi (adrxml)
            }
	          document.getElementById("continue").style.display = "none";
	          document.getElementById("lookupmail").style.visibility = "visible";
	          document.getElementById("contactdata").style.visibility = "visible";
          }
        } else {
	        alert ("e-mail address is required for continuing");
	        return false;        
        }
      } // loadContactData

      // ------------------------------------------------------

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      function reference(odctrl) {
        var frm = document.forms[0];
        var c1,c2,c12;
        
        switch(parseInt(odctrl)) {
          case 1:
            if (frm.nm_legal.value.indexOf("'")>=0)
              alert("The company name contains forbidden characters");
            else {
              window.open("../common/reference.jsp?ix_form=0&nm_table=k_companies&tp_control=1&nm_control=nm_legal&nm_coding=gu_company"+(frm.nm_legal.value.length==0 ? "" : "&where=" + escape(" <%=DB.nm_legal%> LIKE '"+frm.nm_legal.value+"%' ")), "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            }
            break;            
        } // end switch
      } // reference()

      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=id_objetive&tp_control=2&nm_control=sel_objetive&nm_coding=id_objetive", "lookupobjective", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "lookupstatus", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_street&tp_control=2&nm_control=sel_street&nm_coding=tp_street", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            if (frm.sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.sel_country) + "&tp_control=2&nm_control=sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("Must select a country before choosing the state");
            break;
          case 5:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=tp_origin&tp_control=2&nm_control=sel_origin&nm_coding=tp_origin", "lookuporigin", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

      	var txt = frm.tl_oportunity.value.trim();
      	
      	if (txt.length==0) {
      		txt = frm.tl_oportunity.value = getComboText(frm.sel_objetive);
      	}
      
      	if (hasForbiddenChars(txt)) {
      	  alert ("Opportunity title contains invalid characters");
      	  return false;	  
      	} else if (allcaps) {
      	  frm.tl_oportunity.value = txt.toUpperCase();
      	}
      
      	txt = frm.im_revenue.value;
      	for (var c=0; c<txt.length; c++)
      	  if (txt.charCodeAt(c)<48 || txt.charCodeAt(c)>57) {
      	    alert ("Amount must be an integer quantity");
      	    return false;
      	  }
      
      	if (frm.tx_name.value.length==0) {
      	  alert ("The name of contact person is required");
      	  return false;
      	} else if (allcaps) {
      	  frm.tx_name.value	= frm.tx_name.value.toUpperCase();
      	}
      
      	if (frm.tx_surname.value.length==0) {
      	  alert ("Surname of contact person is required");
      	  return false;
      	} else if (allcaps) {
      	  frm.tx_surname.value	= frm.tx_surname.value.toUpperCase();
      	}
      
      	if (frm.tx_note.value.length>254) {
      	  alert ("Comments cannot exceed 254 characters");
      	  return false;
      	}
      	
      	if (!isDate(frm.dt_next_action.value, "d") && frm.dt_next_action.value.length>0) {
      	  alert ("Date for next action is not valid");
      	  return false;	  
      	}

      	txt = frm.tx_email.value.trim();
      	if (txt.length>0)
      	  if (!check_email(txt)) {
      	    alert ("email address is not valid");
      	    return false;
                }
      	frm.tx_email.value = txt.toLowerCase();
      
      	// Move selected combo values into hidden fields
      
      	frm.nm_legal.value = frm.nm_legal.value.toUpperCase();
      	frm.nm_company.value = frm.nm_legal.value;
      	frm.tx_company.value = frm.nm_legal.value;
      	frm.tx_contact.value = frm.tx_name.value+" "+frm.tx_surname.value;
      	frm.id_objetive.value = getCombo(frm.sel_objetive);
      	frm.id_status.value = getCombo(frm.sel_status);
      	frm.tp_origin.value = getCombo(frm.sel_origin);
        frm.bo_private.value = frm.chk_private.checked ? "1" : "0";
      	frm.id_state.value = getCombo(frm.sel_state);
      	frm.nm_state.value = getComboText(frm.sel_state);

        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">New Opportunity</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="oportunity_new_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=gu_writer%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_writer%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">Title</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="bo_private">
              <INPUT TYPE="text" NAME="tl_oportunity" MAXLENGTH="128" SIZE="36">
              &nbsp;&nbsp;&nbsp;<FONT CLASS="formstrong">Private</FONT>&nbsp;<INPUT TYPE="checkbox" NAME="chk_private" VALUE="1">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">Target:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <SELECT NAME="sel_objetive" onChange="if (document.forms[0].tl_oportunity.value.length==0) document.forms[0].tl_oportunity.value=getComboText(document.forms[0].sel_objetive);"><OPTION VALUE=""></OPTION><%=sObjectiveLookUp%></SELECT>
              &nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Objectives List"></A>
              <INPUT TYPE="hidden" NAME="id_objetive">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">Status:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>
              &nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Status List"></A>
              <INPUT TYPE="hidden" NAME="id_status">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Media:</FONT>&nbsp;
              <SELECT NAME="sel_origin"><OPTION VALUE=""></OPTION><%=sOriginLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Origins List"></A>
              <INPUT TYPE="hidden" NAME="tp_origin">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="175"><FONT CLASS="formplain">Interest Degree</FONT></TD>
            <TD ALIGN="left" WIDTH="420" CLASS="formplain">
            	<INPUT TYPE="radio" NAME="lv_interest" VALUE="0">&nbsp;None&nbsp;&nbsp;&nbsp;
            	<INPUT TYPE="radio" NAME="lv_interest" VALUE="1">&nbsp;A few&nbsp;&nbsp;&nbsp;
            	<INPUT TYPE="radio" NAME="lv_interest" VALUE="2">&nbsp;Some&nbsp;&nbsp;&nbsp;
            	<INPUT TYPE="radio" NAME="lv_interest" VALUE="3">&nbsp;Much&nbsp;&nbsp;&nbsp;            	
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formstrong">Amount:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="im_revenue" MAXLENGTH="11" SIZE="11">
              &nbsp;&nbsp;&nbsp;
              <FONT CLASS="formplain">Next Date</FONT>
              &nbsp;<INPUT TYPE="text" MAXLENGTH="10" SIZE="10" NAME="dt_next_action">
              &nbsp;<A HREF="javascript:showCalendar('dt_next_action')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"></TD>
            <TD NOWRAP><INPUT TYPE="checkbox" NAME="chk_meeting" VALUE="1">&nbsp;<FONT CLASS="formplain">Create an activity at calendar for next action</FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="100"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><TEXTAREA NAME="tx_note" ROWS="3" COLS="40"></TEXTAREA></TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <TABLE BORDER="0">
                <TR>
                  <TD><INPUT TYPE="text" NAME="tx_email" STYLE="text-tansform:lowercase" MAXLENGTH="100" SIZE="42" onchange="document.forms[0].gu_address.value=''"></TD>
                  <TD><DIV ID="lookupmail" STYLE="visibility:hidden"><A HREF="#" CLASS="linkplain" onclick="loadContactData()">Search</A></DIV>
                </TR>
              </TABLE>
            </TD>
          </TR>
	</TABLE>
	<DIV ALIGN="center" ID="continue" STYLE="display:block">
	  <A HREF="#" CLASS="linkplain" onclick="loadContactData()">Continue</A>
	</DIV>
	<DIV ID="contactdata" STYLE="visibility:hidden">
	<TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Company</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="hidden" NAME="gu_address">
              <INPUT TYPE="hidden" NAME="ix_address">
              <INPUT TYPE="hidden" NAME="gu_contact">
              <INPUT TYPE="hidden" NAME="gu_company">
              <INPUT TYPE="hidden" NAME="nm_company">
              <INPUT TYPE="hidden" NAME="tx_company">
              <INPUT TYPE="text" NAME="nm_legal" MAXLENGTH="50" SIZE="40" STYLE="text-transform:uppercase" onChange="document.forms[0].gu_company.value='';">
              &nbsp;&nbsp;<A HREF="javascript:reference(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Companies List"></A>
            
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Name</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="tx_name" MAXLENGTH="50" SIZE="40" <%=bAllCaps ? "STYLE=\"text-transform:uppercase\"" : ""%> onchange="document.forms[0].gu_contact.value=''">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Surname</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="hidden" NAME="tx_contact">
              <INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="50" SIZE="40" <%=bAllCaps ? "STYLE=\"text-transform:uppercase\"" : ""%> onchange="document.forms[0].gu_contact.value=''">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Id. Card.</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="sn_passport" MAXLENGTH="16" SIZE="16" <%=bAllCaps ? "STYLE=\"text-transform:uppercase\"" : ""%>>
							&nbsp;&nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Gender</FONT>&nbsp;
              <SELECT name="id_gender"><OPTION VALUE=""></OPTION><OPTION VALUE="M">Hombre</OPTION><OPTION VALUE="F">Mujer</OPTION></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <FONT CLASS="formplain">Telephones:</FONT>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <TABLE CLASS="formback">
                <TR>
                  <TD><FONT CLASS="textsmall">Main</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="10"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Direct</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="direct_phone" MAXLENGTH="16" SIZE="10"></TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">Personal</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="home_phone" MAXLENGTH="16" SIZE="10"></TD>              
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Mobile Phone</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="mov_phone" MAXLENGTH="16" SIZE="10"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"></TD>
            <TD ALIGN="left" WIDTH="460">
              <TABLE WIDTH="100%" CELLSPACING="0" CELLPADDING="0" BORDER="0"><TR>
                <TD ALIGN="left">
                  <!--<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Address Types"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_location"><OPTION VALUE=""></OPTION><%=sLocationLookUp%></SELECT>-->
                  <INPUT TYPE="hidden" NAME="tp_location">
                </TD>
                <TD></TD>
              </TR></TABLE>
            </TD>
          </TR>
<% if (sLanguage.equalsIgnoreCase("es")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <!--<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Street Types"></A>&nbsp;-->
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="">
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="40" <%=bAllCaps ? "STYLE=\"text-transform:uppercase\"" : ""%> VALUE="" onchange="document.forms[0].gu_address.value=''">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Num.</FONT>&nbsp;<INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="" <%=bAllCaps ? "STYLE=\"text-transform:uppercase\"" : ""%>>
            </TD>
          </TR>
<% } else { %>
          <TR>
            <TD ALIGN="right" WIDTH="140">
	      <FONT CLASS="formplain">Num.</FONT>&nbsp;
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="">
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="40" VALUE="">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="">
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
              <!--<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Street Types"></A>-->
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Flat:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="tx_addr1" MAXLENGTH="100" SIZE="10" <%=bAllCaps ? "STYLE=\"text-transform:uppercase\"" : ""%>>
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Rest:</FONT>&nbsp;
              <INPUT TYPE="text" NAME="tx_addr2" MAXLENGTH="100" SIZE="32" <%=bAllCaps ? "STYLE=\"text-transform:uppercase\"" : ""%>>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <DIV id="country" STYLE="display:none"><FONT CLASS="formplain">Country:</FONT></DIV>
              <DIV id="nationality" STYLE="display:block"><FONT CLASS="formplain">Nationality</FONT></DIV>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <DIV id="country_select" STYLE="display:none">
	              <SELECT CLASS="combomini" NAME="sel_country" onchange="loadstates()"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
                <INPUT TYPE="hidden" NAME="id_country" VALUE="">
                <INPUT TYPE="hidden" NAME="nm_country" VALUE="">
              </DIV>
              <DIV id="nationality_select" STYLE="display:block">
	              <SELECT CLASS="combomini" NAME="id_nationality"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
                <INPUT TYPE="hidden" NAME="id_country" VALUE="">
                <INPUT TYPE="hidden" NAME="nm_country" VALUE="">
              </DIV>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">State/Province:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View States"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_state"></SELECT>
              <INPUT TYPE="hidden" NAME="id_state" MAXLENGTH="16" VALUE="">
              <INPUT TYPE="hidden" NAME="nm_state" MAXLENGTH="30" VALUE="">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">City:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="mn_city" STYLE="text-transform:uppercase" MAXLENGTH="50" SIZE="30" VALUE="" onchange="document.forms[0].gu_address.value=''">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Zipcode:</FONT>
              &nbsp;
              <INPUT TYPE="text" NAME="zipcode" MAXLENGTH="30" SIZE="5" VALUE="" onchange="document.forms[0].gu_address.value=''">
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>
        </TABLE>
        </DIV>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
