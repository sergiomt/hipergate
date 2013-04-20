<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%

/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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
  
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 
  String gu_user = getCookie(request,"userid",null); 
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);

  String sLinkTable = request.getParameter("linktable")==null ? "" : request.getParameter("linktable");
  String sLinkField = request.getParameter("linkfield")==null ? "" : request.getParameter("linkfield");
  String sLinkValue = request.getParameter("linkvalue")==null ? "" : request.getParameter("linkvalue");
  
  String gu_address = request.getParameter("gu_address")==null ? "" : request.getParameter("gu_address");
  
  String ix_address = "";
  String tx_location = "";
  String nm_company = "";
  
  JDCConnection oConn = null;  
  Address oAddr = null;
  String sLocationLookUp = null;
  String sSalutationLookUp = null;
  String sCountriesLookUp = null;
  String sStreetLookUp = null;
  
  boolean bIsGuest = true;
  boolean bGoogleMapsEnabled = false;
   
  try {
    oConn = GlobalDBBind.getConnection("addr_edit");
    
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    bGoogleMapsEnabled = (GlobalDBBind.getProperty("googlemapskey","").length()>0);

    if (gu_address.length()>0) {
      oAddr = new Address();
      if (oAddr.load(oConn,new Object[]{gu_address})) {
        ix_address = String.valueOf(oAddr.getInt(DB.ix_address));
      
        RecentlyUsed oRecent;
        DBPersist oItem;
      
        oConn.setAutoCommit(true);

        if (sLinkTable.equals(DB.k_x_company_addr)) {

          oRecent = new RecentlyUsed (DB.k_companies_recent, 10, DB.gu_company, DB.gu_user);

	        oItem = new DBPersist (DB.k_companies_recent, "RecentCompany");

      	  oItem.put (DB.gu_company, sLinkValue);
      	  oItem.put (DB.gu_user, gu_user);
      	  oItem.put (DB.gu_workarea, gu_workarea);
      	  oItem.put (DB.nm_company, nullif(request.getParameter("nm_company")));
      	  if (oAddr.getItemMap().containsKey(DB.work_phone))
      	    oItem.put (DB.work_phone, oAddr.getStringNull(DB.work_phone,null));
      	  if (oAddr.getItemMap().containsKey(DB.tx_email))
      	    oItem.put (DB.tx_email, oAddr.getStringNull(DB.tx_email,null));
      	  
      	  oRecent.add (oConn, oItem);
        }
        else if (sLinkTable.equals(DB.k_x_contact_addr)) {
        
          oRecent = new RecentlyUsed (DB.k_contacts_recent, 10, DB.gu_contact, DB.gu_user);

      	  oItem = new DBPersist (DB.k_contacts_recent, "RecentContact");
      	
        	DBPersist oCont = new DBPersist (DB.k_contacts, "Contact");
      	  oCont.load (oConn, new Object[]{sLinkValue});
      	
      	  oItem.put (DB.gu_contact, oCont.getString(DB.gu_contact));
      	  oItem.put (DB.full_name, oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""));
      	  oItem.put (DB.gu_user, gu_user);
      	  oItem.put (DB.gu_workarea, gu_workarea);
      	  oItem.put (DB.nm_company, nullif(request.getParameter("nm_company")));
      
      	  if (oAddr.getItemMap().containsKey(DB.work_phone))
      	    oItem.put (DB.work_phone, oAddr.getStringNull(DB.work_phone,null));
      
      	  if (oAddr.getItemMap().containsKey(DB.tx_email))
      	    oItem.put (DB.tx_email, oAddr.getStringNull(DB.tx_email,null));
      	  
      	  oRecent.add (oConn, oItem);
        }
      } else {
        ix_address = "1";
      }
    }
    else {
      oAddr = new Address();
    }

    if (nullif(request.getParameter("nm_company")).length()>0)
      nm_company = request.getParameter("nm_company");
    else
      nm_company = oAddr.getStringNull(DB.nm_company,"");
    
    sLocationLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_location, sLanguage);
    sStreetLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_street, sLanguage);
    sSalutationLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tx_salutation, sLanguage);
    
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);
    
    oConn.close("addr_edit");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("addr_edit");
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
  }
  oConn = null;  
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
  <TITLE>hipergate :: Edit Address</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript">
      <!--        

      function lookup(odctrl) {
        var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
        
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_location&tp_control=2&nm_control=sel_location&nm_coding=tp_location", "lookupaddrlocation", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_street&tp_control=2&nm_control=sel_street&nm_coding=tp_street", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            if (frm.sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.sel_country) + "&tp_control=2&nm_control=sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("You must select a Country before choosing a State");
            break;
          case 5:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tx_salutation&tp_control=2&nm_control=sel_salutation&nm_coding=tx_salutation", "lookupaddrsalutation", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
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

      function showGoogleMap() {
    	  window.open("../common/google_map.jsp?gu_address=<%=gu_address%>","google_map_<%=gu_address%>","directories=no,toolbar=no,scrollbars=yes,menubar=no,width=540,height=400");
      }
      
      // ------------------------------------------------------
      
      function validate() {
	      var frm = window.document.forms[0];
      	var txt;
      	
      	if(frm.tx_remarks.value.length>254) {
      	  alert("Comments may not be longer than 254 characters");
      	  return false;
      	}
      
      	txt = ltrim(rtrim(frm.tx_email.value));
      	if (txt.length>0)
      	  if (!check_email(txt)) {
      	    alert ("e-mail address is not valid");
      	    return false;
          }
      	frm.tx_email.value = txt.toLowerCase();
      	
        if (frm.sel_location.options.selectedIndex>0)
      	    frm.tp_location.value = getCombo(frm.sel_location);
      	else
      	    frm.tp_location.value = "";
      	
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
      	
      	if (frm.id_country.value=="es" && frm.zipcode.value.length!=0 && frm.zipcode.value.length!=5) {
      	    alert("Zipcode must have 5 characters");
      	    return false;
      	}
      	
        if (frm.sel_salutation.options.selectedIndex>0)
      	    frm.tx_salutation.value = getCombo(frm.sel_salutation);
      	else
      	    frm.tx_salutation.value = "";
      	
      	return true;
      } // validate()

      // ------------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];
  
	      if (""=="<%=oAddr.getStringNull(DB.id_country,"").trim()%>")
          setCombo (frm.sel_country, getUserLanguage());
	      else
          setCombo  (frm.sel_country, "<%=oAddr.getStringNull(DB.id_country,"").trim()%>");
      
        setCombo (frm.sel_street, frm.tp_street.value);
        setCombo (frm.sel_location, frm.tp_location.value);
        setCombo (frm.sel_salutation, frm.tx_salutation.value);
        
        loadstates(frm.id_state.value);
        
        if (frm.sel_country.options.selectedIndex>0) {
	        frm.id_country.value = getCombo(frm.sel_country);
	        frm.nm_country.value = getComboText(frm.sel_country);
        }      
      } // setCombos()          
      //-->
    </SCRIPT>  
</HEAD>
<BODY TOPMARGIN="8" LEFTMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
   <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Address<%=(nm_company.length()>0 ? " of&nbsp;" + nm_company : "")%></FONT></TD></TR></TABLE>
  <BR>
  <FORM NAME="editaddr" METHOD="post" ACTION="addr_edit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">
    <INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=gu_address%>">
    <INPUT TYPE="hidden" NAME="ix_address" VALUE="<%=ix_address%>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="1">
    <INPUT TYPE="hidden" NAME="linktable" VALUE="<%=sLinkTable%>">
    <INPUT TYPE="hidden" NAME="linkfield" VALUE="<%=sLinkField%>">    
    <INPUT TYPE="hidden" NAME="linkvalue" VALUE="<%=sLinkValue%>">
    <INPUT TYPE="hidden" NAME="noreload" VALUE="<%=nullif(request.getParameter("noreload"),"0")%>">
        
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Address Type</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <TABLE WIDTH="100%" CELLSPACING="0" CELLPADDING="0" BORDER="0"><TR>
                <TD ALIGN="left">
                  <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View address types"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_location"><OPTION VALUE=""></OPTION><%=sLocationLookUp%></SELECT>          
                  <INPUT TYPE="hidden" NAME="tp_location" VALUE="<%=oAddr.getStringNull(DB.tp_location,"")%>">
                </TD>
                <TD ALIGN="right">
                  <FONT CLASS="formplain">Company</FONT>
                  &nbsp;
                  <INPUT TYPE="text" NAME="nm_company" MAXLENGTH="50" SIZE="20" VALUE="<%=nm_company%>">
                </TD>
              </TR></TABLE>
            </TD>
          </TR>
<% if (sLanguage.equalsIgnoreCase("es") || sLanguage.equalsIgnoreCase("it")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160">
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="<%=oAddr.getStringNull(DB.tp_street,"")%>">            
<% if (!oAddr.isNull(DB.nm_street) && !oAddr.isNull(DB.mn_city)) { %>
						<TABLE><TR><TD><INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="30" VALUE="<%=oAddr.getStringNull(DB.nm_street,"")%>"> &nbsp;&nbsp;<FONT CLASS="formplain">Num.</FONT>&nbsp;<INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oAddr.getStringNull(DB.nu_street,"")%>"></TD><TD><IMG SRC="../images/images/gmaps16.gif" WIDTH="20" HEIGHT="20" ALT="Map"></TD><% if (bGoogleMapsEnabled) { %><TD VALING="middle"><A HREF="#" CLASS="linkplain" onclick="showGoogleMap()">Map</A></TD><% } %></TR></TABLE>
            </TD>
          </TR>
<% } else { %>
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="30" VALUE="<%=oAddr.getStringNull(DB.nm_street,"")%>"> &nbsp;&nbsp;<FONT CLASS="formplain">Num.</FONT>&nbsp;<INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oAddr.getStringNull(DB.nu_street,"")%>">
<% } %>
            </TD>
          </TR>
<% } else if (sLanguage.equalsIgnoreCase("fr")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="160">
	            <FONT CLASS="formplain">Num.</FONT>&nbsp;
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="<%=oAddr.getStringNull(DB.tp_street,"")%>">
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>              
              <INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oAddr.getStringNull(DB.nu_street,"")%>">
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="40" VALUE="<%=oAddr.getStringNull(DB.nm_street,"")%>">
<% if (bGoogleMapsEnabled && !oAddr.isNull(DB.nm_street) && !oAddr.isNull(DB.mn_city)) { %>
							&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="showGoogleMap()">Map</A>
<% } %>
            </TD>
          </TR>
<% } else { %>
          <TR>
            <TD ALIGN="right" WIDTH="160">
	            <FONT CLASS="formplain">Num.</FONT>&nbsp;
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oAddr.getStringNull(DB.nu_street,"")%>">
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="40" VALUE="<%=oAddr.getStringNull(DB.nm_street,"")%>">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="<%=oAddr.getStringNull(DB.tp_street,"")%>">
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>              
<% if (bGoogleMapsEnabled && !oAddr.isNull(DB.nm_street) && !oAddr.isNull(DB.mn_city)) { %>
							&nbsp;&nbsp;<A HREF="#" CLASS="linkplain" onclick="showGoogleMap()">Map</A>
<% } %>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Flat</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="tx_addr1" MAXLENGTH="100" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.tx_addr1,"")%>">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Rest:</FONT>&nbsp;
              <INPUT TYPE="text" NAME="tx_addr2" MAXLENGTH="100" SIZE="32" VALUE="<%=oAddr.getStringNull(DB.tx_addr2,"")%>">              
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Country:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
	            <SELECT CLASS="combomini" NAME="sel_country" onchange="loadstates()"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
              <INPUT TYPE="hidden" NAME="id_country" VALUE="<%=oAddr.getStringNull(DB.id_country,"").trim()%>">
              <INPUT TYPE="hidden" NAME="nm_country" VALUE="<%=oAddr.getStringNull(DB.nm_country,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">State/Region:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View states"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_state"></SELECT>
              <INPUT TYPE="hidden" NAME="id_state" MAXLENGTH="16" VALUE="<%=oAddr.getStringNull(DB.id_state,"")%>">
              <INPUT TYPE="hidden" NAME="nm_state" MAXLENGTH="30" VALUE="<%=oAddr.getStringNull(DB.nm_state,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">City:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="mn_city" STYLE="text-transform:uppercase" MAXLENGTH="50" SIZE="30" VALUE="<%=oAddr.getStringNull(DB.mn_city,"")%>">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Zipcode:</FONT>
              &nbsp;
              <INPUT TYPE="text" NAME="zipcode" MAXLENGTH="30" SIZE="5" VALUE="<%=oAddr.getStringNull(DB.zipcode,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160">
              <FONT CLASS="formplain">Telephones</FONT>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <TABLE CLASS="formback">
                <TR>
                  <TD><FONT CLASS="textsmall">Main</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.work_phone,"")%>"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Direct</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="direct_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.direct_phone,"")%>"></TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">Personnel</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="home_phone" MAXLENGTH="16" SIZE="12" VALUE="<%=oAddr.getStringNull(DB.home_phone,"")%>"></TD>              
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Mobile</FONT></TD>
                  <TD>
                  	<INPUT TYPE="text" NAME="mov_phone" MAXLENGTH="16" SIZE="12" VALUE="<%=oAddr.getStringNull(DB.mov_phone,"")%>">
<%                  if (gu_address.length()>0 && GlobalDBBind.getProperty("smsprovider","").length()>0) { %>
										  &nbsp;<A HREF="sms_edit.jsp?gu_address=<%=gu_address%>&nu_msisdn=<%=Gadgets.URLEncode(oAddr.getStringNull(DB.mov_phone,""))%>&<%=sLinkField%>=<%=sLinkValue%>" TITLE="Send SMS"><IMG SRC="../images/images/mobilephone16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Send SMS" /></A>
<%                  } %>
                  </TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                </TR>
                <TR>                
                  <TD><FONT CLASS="textsmall">Fax</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="fax_phone" MAXLENGTH="16" SIZE="12" VALUE="<%=oAddr.getStringNull(DB.fax_phone,"")%>"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Other</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="other_phone" MAXLENGTH="16" SIZE="12" VALUE="<%=oAddr.getStringNull(DB.other_phone,"")%>"></TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="tx_email" STYLE="text-transform:lowercase" MAXLENGTH="100" SIZE="42" VALUE="<%=oAddr.getStringNull(DB.tx_email,"")%>">
<% 	    if (!oAddr.isNull(DB.tx_email))
                 out.write ("            &nbsp;<A HREF=\"mailto:" + oAddr.getString(DB.tx_email) + "\" TITLE=\"Send e-mail\"><IMG SRC=\"../images/images/mailto16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Send e-mail\"></A>");
%>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">URL:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="url_addr" MAXLENGTH="254" SIZE="42" VALUE="<%=oAddr.getStringNull(DB.url_addr,"")%>">
<% 	    if (!oAddr.isNull(DB.url_addr)) {
	      String sURL = oAddr.getString(DB.url_addr).toLowerCase();
	      if (sURL.startsWith("http:") || sURL.startsWith("https:"))
                 out.write ("            &nbsp;<A HREF=\"" + oAddr.getString(DB.url_addr) + "\" TARGET=\"_blank\" TITLE=\"Browse web site in new window\"><IMG SRC=\"../images/images/navigate16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Browse web site in new window\"></A>");
	      else
                 out.write ("            &nbsp;<A HREF=\"http://" + oAddr.getString(DB.url_addr) + "\" TARGET=\"_blank\" TITLE=\"Browse web site in new window\"><IMG SRC=\"../images/images/navigate16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Browse web site in new window\"></A>");	      
	    }
%>
            
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Contact Person:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Salutations"></A>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_salutation"><OPTION VALUE=""></OPTION><%=sSalutationLookUp%></SELECT>&nbsp;
              <INPUT TYPE="hidden" NAME="tx_salutation" VALUE="<%=oAddr.getStringNull(DB.tx_salutation,"")%>">
              <INPUT TYPE="text" NAME="contact_person" MAXLENGTH="254" SIZE="32" VALUE="<%=oAddr.getStringNull(DB.contact_person,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">e-mail Contact:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="tx_email_alt" STYLE="text-tansform:lowercase" MAXLENGTH="100" SIZE="42" VALUE="<%=oAddr.getStringNull("tx_email_alt","")%>">
<% 	    if (!oAddr.isNull("tx_email_alt"))
                 out.write ("            &nbsp;<A HREF=\"mailto:" + oAddr.getString("tx_email_alt") + "\" TITLE=\"Send e-mail\"><IMG SRC=\"../images/images/mailto16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Enviar e-mail\"></A>");
%>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><TEXTAREA NAME="tx_remarks" ROWS="2" COLS="40"><%=oAddr.getStringNull(DB.tx_remarks,"")%></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<% } else { %>
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
              <INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>