<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Form for editing a DBPersist subclass object.
  
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Add no-cache headers
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 03. Get parameters

  String sLanguage = getNavigatorLanguage(request);

  String id_user = request.getParameter("gu_writer");  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_fellow = request.getParameter("gu_fellow");
  String field = request.getParameter("field");
  String find = request.getParameter("find");
  int skip = Integer.parseInt(nullif(request.getParameter("skip"),"0"));

  String sCountriesLookUp = null;
  String sStreetLookUp = null;
  String sWhere;
  Object[] aParam;
  JDCConnection oConn = null;
  DBSubset oContacts = null;
  int iContacts = 0;
  int iMaxRows = 100;
  
  try {    
    oConn = GlobalDBBind.getConnection("visit_edit2");      
    sStreetLookUp = DBLanguages.getHTMLSelectLookUp (oConn, "k_addresses_lookup", gu_workarea, "tp_street", sLanguage);    
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);    
    if (field!=null && find!=null) {
      if (field.equals("tx_name")) {
        sWhere = DB.tx_name + " " + DBBind.Functions.ILIKE + " ?";
        aParam = new Object[]{gu_workarea,id_user,find+"%"};
      } else if (field.equals("tx_surname")) {
        sWhere = DB.tx_surname + " " + DBBind.Functions.ILIKE + " ?";
        aParam = new Object[]{gu_workarea,id_user,"%"+find+"%"};
      } else if (field.equals("nm_legal")) {
        sWhere = "("+DB.nm_legal + " " + DBBind.Functions.ILIKE + " ? OR "+DB.nm_commercial + " " + DBBind.Functions.ILIKE + " ?)";
        aParam = new Object[]{gu_workarea,id_user,"%"+find+"%","%"+find+"%"};        
      } else if (field.equals("sn_passport")) {
        sWhere = DB.sn_passport + " = ?";
        aParam = new Object[]{gu_workarea,id_user,find};
      } else if (field.equals("tx_phone")) {
        sWhere = "("+DB.work_phone+"=? OR "+DB.direct_phone+"=? OR "+DB.home_phone+"=? OR "+DB.mov_phone+"=?)";
        aParam = new Object[]{gu_workarea,id_user,find,find,find,find};
      } else {
        sWhere = field + " = ?";
        aParam = new Object[]{gu_workarea,id_user,find};
      }
      
      oContacts = new DBSubset (DB.k_member_address,
        			DB.gu_address+","+DB.gu_contact+","+DB.tx_name+","+DB.tx_surname+","+DB.nm_legal+","+DB.nm_commercial+","+DB.nm_street+","+DB.nu_street+","+DB.mn_city,
        			DB.gu_contact+" IS NOT NULL AND "+DB.gu_workarea+"=? AND ("+DB.bo_private+"=0 OR "+DB.gu_writer+"=?) AND "+sWhere+" ORDER BY 3,4", 100);
      oContacts.setMaxRows(iMaxRows);
      iContacts = oContacts.load(oConn,aParam,skip);		  
    }
    oConn.close("visit_edit2");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("visit_edit2");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  if (null==oConn) return;
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Select Customer</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

        // ----------------------------------------------------

	function modifyContact(id) {
	  self.open ("../crm/contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));
	}	
      
      // ------------------------------------------------------

      function lookup(odctrl) {
        var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
        
          case 1:
            if (frm.nm_legal.value.indexOf("'")>=0)
              alert("The company name has forbidden characters");
            else
              window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal&nm_coding=gu_company"+(frm.nm_legal.value.length==0 ? "" : "&where=" + escape(" (nm_legal <%=DBBind.Functions.ILIKE%> '"+frm.nm_legal.value+"%' OR nm_commercial <%=DBBind.Functions.ILIKE%> '"+frm.nm_legal.value+"%') ")), "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_street&tp_control=2&nm_control=sel_street&nm_coding=tp_street", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            if (frm.sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.sel_country) + "&tp_control=2&nm_control=sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("[~Debe seleccionar un Pais antes de poA country must be selected before picking up state or province");
            break;
        }
      } // lookup()
      
      // ------------------------------------------------------
      
      function loadstates(setval) {
	var frm = window.document.forms[0];

        clearCombo(frm.sel_state);
        
        if (frm.sel_country.options.selectedIndex>0) {          
          if (setval==null)
            parent.frames[1].location.href = "addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state";        
          else
            parent.frames[1].location.href = "addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state&set_value=" + setval;
        
          sortCombo(frm.sel_state);
        }  
      }  

      // ------------------------------------------------------

      function toggle(id) {
        var div = document.getElementById(id);
        if (div.style.display=="block") {
          div.style.display="none";
          document.getElementById("toggle_"+id).src="../images/images/maximize16.gif";
        } else {
          div.style.display="block";
          document.getElementById("toggle_"+id).src="../images/images/minimize16.gif";
        }
      }
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	if (frm.tx_name.value.indexOf('"')>=0) {
	  alert ("The name contains forbidden characters");
	  return false;
	}        
	if (frm.tx_surname.value.indexOf('"')>=0) {
	  alert ("Surname contains forbidden characters");
	  return false;
	}        
	if (frm.nm_legal.value.indexOf('"')>=0) {
	  alert ("The company name has forbidden characters");
	  return false;
	}
	if (frm.nm_street.value.indexOf('"')>=0) {
	  alert ("The street name has forbidden characters");
	  return false;
	}        
	if (frm.mn_city.value.indexOf('"')>=0) {
	  alert ("The city name has forbidden characters");
	  return false;
	}        

	var txt = ltrim(rtrim(frm.tx_email.value));
	if (txt.length>0)
	  if (!check_email(txt)) {
	    alert ("The e-mail address is not valid");
	    return false;
          }
	frm.tx_email.value = txt.toLowerCase();

        if (frm.sel_street.options.selectedIndex>0)
	  frm.tp_street.value = getCombo(frm.sel_street);
	else
	  frm.tp_street.value = "";
	  
        if (frm.sel_country.options.selectedIndex>0) {
	  frm.id_country.value = getCombo(frm.sel_country);
	  frm.nm_country.value = getComboText(frm.sel_country);
	}
	else {
	  frm.id_country.value = "";
	  frm.nm_country.value = "";
	}

        if (frm.sel_state.options.selectedIndex>0) {
	  frm.id_state.value = getCombo(frm.sel_state);
	  frm.nm_state.value = getComboText(frm.sel_state);
	}
	else {
	  frm.id_state.value = "";
	  frm.nm_state.value = "";
	}

	frm.mn_city.value = frm.mn_city.value.toUpperCase();
        frm.attendants.value = frm.attendants.value+","+frm.gu_contact.value; 
        frm.tx_meeting.value = (frm.tx_name.value+" "+frm.tx_surname.value).substr(0,100);
        
        alert(frm.attendants.value);
        
        return true;
      } // validate;

      // ------------------------------------------------------

      function validate2() {
	var frm = document.forms[1];
        
	if (frm.find.value.length==0) {
	  alert ("Value sought");
	  return false;
	}
	
	frm.skip.value="0";
	
	return true;
      } // validate2;

      // ------------------------------------------------------

      function validate3() {
	var frm = document.forms[1];
        var con = frm.contact;

	var selection = false;
	for (var r=frm.contact.length-1; r>=0 && !selection; r--) {
	  frm.gu_contact.value = contact[r].value;
	  selection = contact[r].checked;
	}
	if (!selection) {
	  alert ("Select a contact");
	  return false;
	}

        frm.tx_meeting.value = (frm.tx_name.value+" "+frm.tx_surname.value).substr(0,100);
        frm.attendants.value = frm.attendants.value+","+frm.gu_contact.value; 

	frm.action = "meeting_edit_store.jsp";
	
	return true;
      } // validate3;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--      
      function setCombos() {
        setCombo(document.forms[1].field,"<%=field%>");
        document.forms[1].find.value = "<%=nullif(find)%>";
      }
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
  <TABLE WIDTH="100%" CELLSPACING="0" CELLPADDING="2" BORDER="0">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD><TD></TD></TR>
    <TR>
      <TD CLASS="striptitle"><FONT CLASS="title2">Create New Customer</FONT></TD>
      <TD CLASS="striptitle" ALIGN="right"><A HREF="#" onclick="toggle('new')" TITLE="Minimize"><IMG ID="toggle_new" SRC="../images/images/minimize16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Minimize"></A></TD>
    </TR>    
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD><TD></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="visit_edit3.jsp" onSubmit="return validate()">
    <DIV ID="new" STYLE="display_block">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_meeting" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_fellow" VALUE="<%=gu_fellow%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="tx_meeting" VALUE="">
    <INPUT TYPE="hidden" NAME="tp_meeting" VALUE="meeting">
    <INPUT TYPE="hidden" NAME="bo_private" VALUE="0">
    <INPUT TYPE="hidden" NAME="dt_start" VALUE="<%=request.getParameter("dt_start")%>">
    <INPUT TYPE="hidden" NAME="dt_end" VALUE="<%=request.getParameter("dt_end")%>">
    <INPUT TYPE="hidden" NAME="ts_start" VALUE="<%=request.getParameter("ts_start")%>">
    <INPUT TYPE="hidden" NAME="ts_end" VALUE="<%=request.getParameter("ts_end")%>">
    <INPUT TYPE="hidden" NAME="rooms" VALUE="<%=request.getParameter("rooms")%>">
    <INPUT TYPE="hidden" NAME="attendants" VALUE="<%=request.getParameter("attendants")%>">
    <INPUT TYPE="hidden" NAME="de_meeting" VALUE="<%=request.getParameter("de_meeting")%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=Gadgets.generateUUID()%>">
    <INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=Gadgets.generateUUID()%>">    

    <TABLE CLASS="formback" WIDTH="100%">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Name</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" CLASS="combomini" NAME="tx_name" MAXLENGTH="100" SIZE="15">
              <FONT CLASS="formplain">&nbsp;&nbsp;Surname</FONT>
	      <INPUT TYPE="text" CLASS="combomini" NAME="tx_surname" MAXLENGTH="100" SIZE="26">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Company</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" CLASS="combomini" NAME="nm_legal" MAXLENGTH="70" SIZE="40" onchange="document.forms[0].gu_company.value=''">&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search Company"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Identity Document</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" CLASS="combomini" NAME="sn_passport" MAXLENGTH="16" SIZE="20"></TD>
          </TR>
<% if (sLanguage.equalsIgnoreCase("es")) { %>
          <TR>
            <TD ALIGN="right">
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Street Types"></A>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
            </TD>
            <TD ALIGN="left">
              <INPUT TYPE="hidden" NAME="tp_street">
              <INPUT TYPE="text" CLASS="combomini" NAME="nm_street" MAXLENGTH="100" SIZE="25">             
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Num.</FONT>&nbsp;<INPUT CLASS="combomini" TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4">
            </TD>
          </TR>
<% } else { %>
          <TR>
            <TD ALIGN="right">
	      <FONT CLASS="formplain">Num.</FONT>&nbsp;
            </TD>
            <TD ALIGN="left">
              <INPUT CLASS="combomini" TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4">
              <INPUT CLASS="combomini" TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="25">
              <INPUT TYPE="hidden" NAME="tp_street">
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Street Types"></A>              
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Flat/Room</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" CLASS="combomini" NAME="tx_addr1" MAXLENGTH="100" SIZE="10">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Other:</FONT>&nbsp;
              <INPUT TYPE="text" CLASS="combomini" NAME="tx_addr2" MAXLENGTH="100" SIZE="20">              
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">Country:</FONT></TD>
            <TD ALIGN="left">
	      <SELECT CLASS="combomini" NAME="sel_country" onchange="loadstates()"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
              <INPUT TYPE="hidden" NAME="id_country">
              <INPUT TYPE="hidden" NAME="nm_country">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">State/Province</FONT></TD>
            <TD ALIGN="left">
              <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View States"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_state"></SELECT>
              <INPUT TYPE="hidden" NAME="id_state" MAXLENGTH="16">
              <INPUT TYPE="hidden" NAME="nm_state" MAXLENGTH="30">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">City:</FONT></TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" CLASS="combomini" NAME="mn_city" STYLE="text-transform:uppercase" MAXLENGTH="50" SIZE="30">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Zipcode:</FONT>
              &nbsp;
              <INPUT TYPE="text" CLASS="combomini" NAME="zipcode" MAXLENGTH="30" SIZE="5">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right">
              <FONT CLASS="formplain">Telephones:</FONT>
            </TD>
            <TD ALIGN="left">
              <TABLE BGCOLOR="#E5E5E5">
                <TR>
                  <TD><FONT CLASS="textsmall">Main</FONT></TD>
                  <TD><INPUT CLASS="combomini" TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="10"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Direct</FONT></TD>
                  <TD><INPUT CLASS="combomini" TYPE="text" NAME="direct_phone" MAXLENGTH="16" SIZE="10"></TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">Personal</FONT></TD>
                  <TD><INPUT CLASS="combomini" TYPE="text" NAME="home_phone" MAXLENGTH="16" SIZE="10"></TD>              
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Mobile Phone</FONT></TD>
                  <TD><INPUT CLASS="combomini" TYPE="text" NAME="mov_phone" MAXLENGTH="16" SIZE="10"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" CLASS="combomini" NAME="tx_email" STYLE="text-tansform:lowercase" MAXLENGTH="100" SIZE="42"></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="n" VALUE="New" CLASS="minibutton" STYLE="width:80" TITLE="ALT+n">&nbsp;
    	      <BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>
    </DIV>         
  </FORM>
  <TABLE WIDTH="100%" CELLSPACING="0" CELLPADDING="2" BORDER="0">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD><TD></TD></TR>
    <TR>
      <TD CLASS="striptitle"><FONT CLASS="title2">Select an already existing customer</FONT></TD>
      <TD CLASS="striptitle" ALIGN="right"><A HREF="#" onclick="toggle('sel')" TITLE="Minimize"><IMG ID="toggle_sel" SRC="../images/images/minimize16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Minimize"></A></TD>
    </TR>    
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD><TD></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="visit_edit2.jsp" onSubmit="return validate()">
    <DIV ID="sel">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_meeting" VALUE="">
    <INPUT TYPE="hidden" NAME="gu_fellow" VALUE="<%=gu_fellow%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="tx_meeting" VALUE="">
    <INPUT TYPE="hidden" NAME="tp_meeting" VALUE="meeting">
    <INPUT TYPE="hidden" NAME="bo_private" VALUE="0">
    <INPUT TYPE="hidden" NAME="dt_start" VALUE="<%=request.getParameter("dt_start")%>">
    <INPUT TYPE="hidden" NAME="dt_end" VALUE="<%=request.getParameter("dt_end")%>">
    <INPUT TYPE="hidden" NAME="ts_start" VALUE="<%=request.getParameter("ts_start")%>">
    <INPUT TYPE="hidden" NAME="ts_end" VALUE="<%=request.getParameter("ts_end")%>">
    <INPUT TYPE="hidden" NAME="rooms" VALUE="<%=request.getParameter("rooms")%>">
    <INPUT TYPE="hidden" NAME="attendants" VALUE="<%=request.getParameter("attendants")%>">
    <INPUT TYPE="hidden" NAME="de_meeting" VALUE="<%=request.getParameter("de_meeting")%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="">
    <INPUT TYPE="hidden" NAME="skip" VALUE="<%=skip%>">


    <TABLE>
      <TR>
        <TD><SELECT NAME="field" CLASS="combomini"><OPTION VALUE="tx_name">Name</OPTION><OPTION VALUE="tx_surname">Surname</OPTION><OPTION VALUE="nm_legal">Company</OPTION><OPTION VALUE="sn_passport">Identity Document</OPTION><OPTION VALUE="tx_phone">Telephone</OPTION></SELECT></TD>
        <TD><INPUT TYPE="text" NAME="find" SIZE="20" MAXLENGTH="50" CLASS="combomini"></TD>
        <TD>
          <INPUT TYPE="submit" ACCESSKEY="f" VALUE="Search" CLASS="minibutton" STYLE="width:80" TITLE="ALT+f" onclick="return validate2();">
        </TD>
      </TR>        
    </TABLE>
    <TABLE CELLSPACING="0" CELLPADDING="2" BORDER="0" WIDTH="100%">
      <TR>
        <TD CLASS="striptitle" WIDTH="1" ROWSPAN="3"></TD>
        <TD CLASS="striptitle" COLSPAN="2"><INPUT TYPE="button" ACCESSKEY="s" VALUE="Select" CLASS="minibutton" STYLE="width:80" TITLE="ALT+s"></TD>
        <TD CLASS="striptitle" WIDTH="1" ROWSPAN="3"></TD>                
      </TR>
      <TR>
<% for (int c=0;c<iContacts; c++) { %>
        <TD><INPUT TYPE="radio" NAME="contact" VALUE="<%=oContacts.getString(1,c)%>"></TD>
        <TD>
          <A CLASS="linksmall" HREF="#" onclick="modifyContact('<%=oContacts.getString(1,c)%>')"><%=oContacts.getStringNull(2,c," ")+" "+oContacts.getStringNull(3,c," ")%></A> <% if (!oContacts.isNull(0,c)) { if (sLanguage.equals("es")) out.write(oContacts.getStringNull(6,c,"")+", "+oContacts.getStringNull(7,c,"")+" "+"("+oContacts.getStringNull(8,c,"")+")"); else out.write(oContacts.getStringNull(7,c,"")+", "+oContacts.getStringNull(6,c,"")+" ("+oContacts.getStringNull(8,c,"")+")"); } %>
        </TD>
<% } %>
      </TR>
      <TR>
        <TD CLASS="striptitle" COLSPAN="2">
<% if (iContacts==iMaxRows) { %>
	<A CLASS="linksmall" HREF="#" onclick=""></A>
<% } else { %>
          <IMG SRC="../images/images/spacer.gif" HEIGHT="2" WIDTH="1" BORDER="0">
<% } %>
        </TD>
      </TR>
    </TABLE>
    </DIV>
  </FORM>
</BODY>
</HTML>
