<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%

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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
   
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 
  String gu_user = getCookie(request,"userid",null); 

  String id_class = request.getParameter("id_class");
  
  String gu_sale_point = request.getParameter("gu_sale_point");
  
  String ix_address = "";
  String tx_location = "";
  
  JDCConnection oConn = null;  
  Address oAddr = null;
  String sLocationLookUp = null;
  String sSalutationLookUp = null;
  String sCountriesLookUp = null;
  String sStreetLookUp = null;
  
  boolean bIsGuest = true;
   
  try {
    oConn = GlobalDBBind.getConnection("salepoint_edit");
    
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    if (id_class.equals(String.valueOf(Warehouse.ClassId))) {
      oAddr = new Warehouse();
      if (gu_sale_point!=null) {
        if (((Warehouse)oAddr).load(oConn, gu_sale_point))
          ix_address = String.valueOf(oAddr.getInt(DB.ix_address));
      }
    } else {
      oAddr = new SalePoint();
      if (gu_sale_point!=null) {
        if (((SalePoint)oAddr).load(oConn, gu_sale_point))
          ix_address = String.valueOf(oAddr.getInt(DB.ix_address));
      }
    }
    
    sLocationLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_location, sLanguage);
    sStreetLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_street, sLanguage);
    sSalutationLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tx_salutation, sLanguage);
    
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);
    
    oConn.close("salepoint_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("salepoint_edit");
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../blank.htm"));  
  }
  oConn = null;  
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
<% if (id_class.equals(String.valueOf(Warehouse.ClassId))) { %>
  <TITLE>hipergate :: Edit Warehouse</TITLE>
<% } else { %>
  <TITLE>hipergate :: Edit Sale Point:</TITLE>
<% } %>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
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
              alert ("A country must be selected before chosing the state");
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
            parent.frames[1].location = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state";        
          else
            parent.frames[1].location = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state&set_value=" + setval;
        
          sortCombo(frm.sel_state);
        }  
      }
      
      // ------------------------------------------------------
      
      function validate() {
	      var frm = window.document.forms[0];
	      var txt;
	
	      if (frm.tx_remarks.value.length>254) {
	        alert ("Comments may not exceed 254 characters");
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
	        alert("The zipcode must have five digits");
	        return false;
	      }
	
        if (frm.sel_salutation.options.selectedIndex>0)
	        frm.tx_salutation.value = getCombo(frm.sel_salutation);
	      else
	        frm.tx_salutation.value = "";
	
			  if (frm.nm_sale_point.value.length==0) {
	        alert("Sale Point name is required");
	        return false;			  	
			  } else {
			    frm.nm_company.value = frm.nm_sale_point.value;
			  }
			  
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
<BODY  TOPMARGIN="8" LEFTMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">

   <TABLE SUMMARY="Form Title">
     <TR>
       <TD CLASS="striptitle">
<% if (id_class.equals(String.valueOf(Warehouse.ClassId))) { %>
     	   <FONT CLASS="title1">Edit Warehouse</FONT>
<% } else { %>
     	   <FONT CLASS="title1">Edit Sale Point:</FONT>
<% } %>
     	 </TD>
     </TR>
   </TABLE>
  <BR>
  <FORM NAME="editaddr" METHOD="post" ACTION="salepoint_edit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=gu_user%>">
    <INPUT TYPE="hidden" NAME="gu_sale_point" VALUE="<%=nullif(gu_sale_point)%>">
    <INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=oAddr.getStringNull(DB.gu_address,"")%>">
    <INPUT TYPE="hidden" NAME="ix_address" VALUE="1">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="1">
    <INPUT TYPE="hidden" NAME="id_class" VALUE="<%=id_class%>">
    <INPUT TYPE="hidden" NAME="nm_company" VALUE="<%=oAddr.getStringNull(DB.nm_company,"")%>">
    <INPUT TYPE="hidden" NAME="tp_location" VALUE="<%=oAddr.getStringNull(DB.tp_location,"")%>">
        
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
<% if (id_class.equals(String.valueOf(Warehouse.ClassId))) { %>
              <INPUT TYPE="text" NAME="nm_warehouse" MAXLENGTH="50" SIZE="40" VALUE="<%=oAddr.getStringNull(DB.nm_warehouse,"")%>">
<% } else { %>
              <INPUT TYPE="text" NAME="nm_sale_point" MAXLENGTH="50" SIZE="40" VALUE="<%=oAddr.getStringNull(DB.nm_sale_point,"")%>">
<% } %>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View address types"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_location"><OPTION VALUE=""></OPTION><%=sLocationLookUp%></SELECT>
            </TD>
          </TR>
<% if (sLanguage.equalsIgnoreCase("es")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="<%=oAddr.getStringNull(DB.tp_street,"")%>">
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="40" VALUE="<%=oAddr.getStringNull(DB.nm_street,"")%>">             
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Number</FONT>&nbsp;<INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oAddr.getStringNull(DB.nu_street,"")%>">
            </TD>
          </TR>
<% } else { %>
          <TR>
            <TD ALIGN="right" WIDTH="140">
	            <FONT CLASS="formplain">Number</FONT>&nbsp;
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oAddr.getStringNull(DB.nu_street,"")%>">
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="40" VALUE="<%=oAddr.getStringNull(DB.nm_street,"")%>">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="<%=oAddr.getStringNull(DB.tp_street,"")%>">
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>              
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Flat:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="tx_addr1" MAXLENGTH="100" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.tx_addr1,"")%>">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Rest:</FONT>&nbsp;
              <INPUT TYPE="text" NAME="tx_addr2" MAXLENGTH="100" SIZE="32" VALUE="<%=oAddr.getStringNull(DB.tx_addr2,"")%>">              
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Country:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
	            <SELECT CLASS="combomini" NAME="sel_country" onchange="loadstates()"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
              <INPUT TYPE="hidden" NAME="id_country" VALUE="<%=oAddr.getStringNull(DB.id_country,"").trim()%>">
              <INPUT TYPE="hidden" NAME="nm_country" VALUE="<%=oAddr.getStringNull(DB.nm_country,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">State:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View states"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_state"></SELECT>
              <INPUT TYPE="hidden" NAME="id_state" MAXLENGTH="16" VALUE="<%=oAddr.getStringNull(DB.id_state,"")%>">
              <INPUT TYPE="hidden" NAME="nm_state" MAXLENGTH="30" VALUE="<%=oAddr.getStringNull(DB.nm_state,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">City:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="mn_city" STYLE="text-transform:uppercase" MAXLENGTH="50" SIZE="30" VALUE="<%=oAddr.getStringNull(DB.mn_city,"")%>">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Zipcode:</FONT>
              &nbsp;
              <INPUT TYPE="text" NAME="zipcode" MAXLENGTH="30" SIZE="5" VALUE="<%=oAddr.getStringNull(DB.zipcode,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <FONT CLASS="formplain">Telephones:</FONT>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <TABLE CLASS="formback">
                <TR>
                  <TD><FONT CLASS="textsmall">Call Center</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.work_phone,"")%>"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Direct</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="direct_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.direct_phone,"")%>"></TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">Personal:</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="home_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.home_phone,"")%>"></TD>              
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Mobile</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="mov_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.mov_phone,"")%>"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                </TR>
                <TR>                
                  <TD><FONT CLASS="textsmall">Fax</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="fax_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.fax_phone,"")%>"></TD>
                  <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                  <TD><FONT CLASS="textsmall">Other</FONT></TD>
                  <TD><INPUT TYPE="text" NAME="other_phone" MAXLENGTH="16" SIZE="10" VALUE="<%=oAddr.getStringNull(DB.other_phone,"")%>"></TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="tx_email" STYLE="text-transform:lowercase" MAXLENGTH="100" SIZE="42" VALUE="<%=oAddr.getStringNull(DB.tx_email,"")%>">
<% 	    if (!oAddr.isNull(DB.tx_email))
                 out.write ("            &nbsp;<A HREF=\"mailto:" + oAddr.getString(DB.tx_email) + "\" TITLE=\"Send e-mail\"><IMG SRC=\"../images/images/mailto16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Enviar e-mail\"></A>");
%>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">URL:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="url_addr" MAXLENGTH="254" SIZE="42" VALUE="<%=oAddr.getStringNull(DB.url_addr,"")%>">
<% 	    if (!oAddr.isNull(DB.url_addr)) {
	      String sURL = oAddr.getString(DB.url_addr).toLowerCase();
	      if (sURL.startsWith("http:") || sURL.startsWith("https:"))
                 out.write ("            &nbsp;<A HREF=\"" + oAddr.getString(DB.url_addr) + "\" TARGET=\"_blank\" TITLE=\"View website in a new window\"><IMG SRC=\"../images/images/navigate16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View website in a new window\"></A>");
	      else
                 out.write ("            &nbsp;<A HREF=\"http://" + oAddr.getString(DB.url_addr) + "\" TARGET=\"_blank\" TITLE=\"View website in a new window\"><IMG SRC=\"../images/images/navigate16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View website in a new window\"></A>");	      
	    }
%>
            
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Contact Person</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Salutation"></A>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_salutation"><OPTION VALUE=""></OPTION><%=sSalutationLookUp%></SELECT>&nbsp;
              <INPUT TYPE="hidden" NAME="tx_salutation" VALUE="<%=oAddr.getStringNull(DB.tx_salutation,"")%>">
              <INPUT TYPE="text" NAME="contact_person" MAXLENGTH="254" SIZE="32" VALUE="<%=oAddr.getStringNull(DB.contact_person,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="tx_email_alt" STYLE="text-tansform:lowercase" MAXLENGTH="100" SIZE="42" VALUE="<%=oAddr.getStringNull("tx_email_alt","")%>">
<% 	    if (!oAddr.isNull("tx_email_alt"))
                 out.write ("            &nbsp;<A HREF=\"mailto:" + oAddr.getString("tx_email_alt") + "\" TITLE=\"Send e-mail\"><IMG SRC=\"../images/images/mailto16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"Enviar e-mail\"></A>");
%>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><TEXTAREA NAME="tx_remarks" ROWS="2" COLS="40"><%=oAddr.getStringNull(DB.tx_remarks,"")%></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your priviledge level as guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
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
