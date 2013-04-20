<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.Supplier" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
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
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_supplier = nullif(request.getParameter("gu_supplier"));
  
  Supplier oSupp = new Supplier();
  Address oAddr = new Address();
  Term oTerm = new Term();
    
  String sStatusLookUp = "", sTypeLookUp = "", sCountriesLookUp = null, sStreetLookUp = null, sTerms = "";

  boolean bIsGuest = true;

  JDCConnection oConn = null;
    
  try {

    bIsGuest = isDomainGuest (GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("supplier_edit");  
    
    sStatusLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_suppliers_lookup, gu_workarea, DB.id_status  , sLanguage);
    sTypeLookUp    = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_suppliers_lookup, gu_workarea, DB.tp_supplier, sLanguage);
    sStreetLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_street, sLanguage);    
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);

    if (gu_supplier.length()>0) {
      oSupp.load(oConn, gu_supplier);
      oAddr=oSupp.getAddress();
      if (!oSupp.isNull(DB.gu_geozone))
        oTerm.load(oConn, new Object[]{oSupp.getString(DB.gu_geozone)});
    }

    sTerms = GlobalCacheClient.getString("[" + id_domain + "," + gu_workarea + ",geozone,thesauri]");
    
    if (null==sTerms) {
      sTerms = GlobalDBLang.getHTMLTermSelect(oConn, Integer.parseInt(id_domain), gu_workarea);
      GlobalCacheClient.put ("[" + id_domain + "," + gu_workarea + ",geozone,thesauri]", sTerms);      
    } // fi (sTerms)

    oConn.close("supplier_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("supplier_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit supplier</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_suppliers_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_suppliers_lookup&id_language=" + getUserLanguage() + "&id_section=tp_supplier&tp_control=2&nm_control=sel_type&nm_coding=tp_supplier", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_street&tp_control=2&nm_control=sel_street&nm_coding=tp_street", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            if (frm.sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.sel_country) + "&tp_control=2&nm_control=sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("A country must be chosen prior to state or province");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------
      
      function loadstates(setval) {
	      var frm = window.document.forms[0];

        clearCombo(frm.sel_state);
        
        if (frm.sel_country.options.selectedIndex>0) {
          if (setval==null)
            parent.frames[1].location.href = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state";        
          else
            parent.frames[1].location.href = "../common/addr_load.jsp?id_language=" + getUserLanguage() + "&gu_workarea=" + getCookie("workarea") + "&id_section=" + getCombo(frm.sel_country) + "&control=sel_state&set_value=" + setval;
        
          sortCombo(frm.sel_state);
        }  
      }

      // ------------------------------------------------------
              
      function lookupZone() {
        var frm = window.document.forms[0];      
        window.open("../common/thesauri_f.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&id_scope=geozones&nm_control=nm_geozone&nm_coding=gu_geozone", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=" + String(Math.floor(600*(screen.width/800))) + ",height=" + String(Math.floor(520*(screen.height/600))));
      }
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
		    var txt;
		    
	      if (frm.nm_legal.value.length>254) {
	        alert ("The Corporate Name is required");
	        return false;
	      }

	      txt = ltrim(rtrim(frm.tx_email.value));
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
	      } else {
	        frm.id_state.value = "";
	        frm.nm_state.value = "";
	      }

	      frm.mn_city.value = frm.mn_city.value.toUpperCase();
	
	      if (frm.id_country.value=="es" && frm.zipcode.value.length!=0 && frm.zipcode.value.length!=5) {
	        alert("The zipcode must have five digits");
	        return false;
	      }

	      frm.id_status.value = getCombo(frm.sel_status);
	      frm.tp_supplier.value = getCombo(frm.sel_type);
	      frm.gu_geozone.value = getCombo(frm.sel_geozone);
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo  (frm.sel_country, "<%=oAddr.getStringNull(DB.id_country,"").trim()%>");
        setCombo(frm.sel_street,"<% out.write(oAddr.getStringNull(DB.tp_street,"")); %>");
        setCombo(frm.sel_geozone,"<% out.write(oSupp.getStringNull(DB.gu_geozone,"")); %>");

        loadstates(frm.id_state.value);
        
        if (frm.sel_country.options.selectedIndex>0) {
	        frm.id_country.value = getCombo(frm.sel_country);
	        frm.nm_country.value = getComboText(frm.sel_country);
        }

        return true;
      } // setCombos()
    //-->
  </SCRIPT> 
</HEAD>
<BODY MARGINWIDTH="8" TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit supplier</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="supplier_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=getCookie (request, "userid", "")%>">
    <INPUT TYPE="hidden" NAME="gu_supplier" VALUE="<%=gu_supplier%>">
    <INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=oAddr.getStringNull(DB.gu_address,"")%>">
    <INPUT TYPE="hidden" NAME="ix_address" VALUE="<% if (!oAddr.isNull(DB.ix_address)) out.write(String.valueOf(oAddr.getInt(DB.ix_address))); %>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="1">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="nm_company" VALUE="<%=oAddr.getStringNull(DB.nm_company,oSupp.getStringNull(DB.nm_legal,""))%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Corporate Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_legal" MAXLENGTH="70" SIZE="60" VALUE="<%=oSupp.getStringNull(DB.nm_legal,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Brand Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_commercial" MAXLENGTH="70" SIZE="60" VALUE="<%=oSupp.getStringNull(DB.nm_commercial,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Reference:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="32" VALUE="<%=oSupp.getStringNull(DB.id_ref,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Type</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_supplier">
              <SELECT NAME="sel_type"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Types List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Status</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="id_status">
              <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Status List"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Zone</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            <INPUT TYPE="hidden" NAME="gu_geozone" VALUE="<%=oSupp.getStringNull(DB.gu_geozone,"")%>">
            <INPUT TYPE="hidden" NAME="nm_geozone" SIZE="40" VALUE="<%=oTerm.getStringNull(DB.tx_term,"")%>">
            <SELECT NAME="sel_geozone"><OPTION VALUE=""></OPTION><% out.write (sTerms); %></SELECT>&nbsp;<A HREF="#" onclick="lookupZone()"><IMG SRC="../images/images/find16.gif" BORDER="0"></A>            
            </TD>
          </TR>
<% if (sLanguage.equalsIgnoreCase("es")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <!-- <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>&nbsp; -->
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
              <!-- <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A> -->
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
              <A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View states"></A>&nbsp;<SELECT CLASS="combomini" NAME="sel_state"></SELECT>
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
                  <TD><FONT CLASS="textsmall">Personal</FONT></TD>
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
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">URL:</FONT></TD>
            <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="url_addr" MAXLENGTH="254" SIZE="42" VALUE="<%=oAddr.getStringNull(DB.url_addr,"")%>">
<% 	    if (!oAddr.isNull(DB.url_addr)) {
	      String sURL = oAddr.getString(DB.url_addr).toLowerCase();
	      if (sURL.startsWith("http:") || sURL.startsWith("https:"))
                 out.write ("            &nbsp;<A HREF=\"" + oAddr.getString(DB.url_addr) + "\" TARGET=\"_blank\" TITLE=\"View website on a new windows\"><IMG SRC=\"../images/images/navigate16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View website on a new windows\"></A>");
	      else
                 out.write ("            &nbsp;<A HREF=\"http://" + oAddr.getString(DB.url_addr) + "\" TARGET=\"_blank\" TITLE=\"View website on a new windows\"><IMG SRC=\"../images/images/navigate16x16.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\" ALT=\"View website on a new windows\"></A>");	      
	    }
%>       
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Contact Person</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="contact_person" MAXLENGTH="254" SIZE="42" VALUE="<%=oAddr.getStringNull(DB.contact_person,"")%>">
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
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
