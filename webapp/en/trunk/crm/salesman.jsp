<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.SalesMan,com.knowgate.hipergate.Term,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
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
  
  final int Shop=20;
    
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  String sLanguage = getNavigatorLanguage(request);
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_sales_man = request.getParameter("gu_sales_man");
  String nm_zone = "";
  
  SalesMan oMan = new SalesMan();
  ACLUser oUsr = new ACLUser();
  
  String sCountriesLookUp = "", sSalesGroupsLookUp = "";
    
  JDCConnection oConn = null;
    
  try {
    
    oConn = GlobalDBBind.getConnection("salesman");

    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);    

    sSalesGroupsLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_sales_men_lookup, gu_workarea, "id_sales_group", sLanguage);
    
    oUsr.load (oConn, new Object[]{gu_sales_man});
        
    oMan.load (oConn, new Object[]{gu_sales_man});
    
    if (!oMan.isNull(DB.gu_geozone)) {
      Term oZone = new Term();
      if (oZone.load(oConn, new Object[]{oMan.getString(DB.gu_geozone)}))
        nm_zone = oZone.getString(DB.tx_term);
    } // fi (gu_geozone!=null)

    oConn.close("salesman");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("salesman");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>Edit Salesman</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      // ------------------------------------------------------

      function viewSalesHistory() {

        var u = "../shop/order_list.jsp?salesman=<% out.write(gu_sales_man); %>&selected=7&subselected=1";
        window.open(u);
/*
	var w = window.opener;
		
	if (typeof(w)=="undefined")
	  window.open("../shop/order_list.jsp?salesman=<% out.write(gu_sales_man); %>&selected=7&subselected=1");
	else {
	  w.document.location.href = "../shop/order_list.jsp?salesman=<% out.write(gu_sales_man); %>&selected=7&subselected=1";
	  w.focus();
        }
*/
      }

      // ----------------------------------------------------

      function viewSalesObjectives() {
	  
        top.location.href = "salesman_edit_f.jsp?gu_workarea=<%=gu_workarea%>" + "&gu_sales_man=<%=gu_sales_man%>&n_sales_man=" + escape("<%=oMan.getStringNull(DB.tx_name,"")+" "+oMan.getStringNull(DB.tx_surname,"")%>");
      
      } // viewSalesObjectives

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
              
      function lookup(odctrl) {
        var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_sales_men_lookup&id_language=" + getUserLanguage() + "&id_section=id_sales_group&tp_control=2&nm_control=sel_group&nm_coding=id_sales_group", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            if (frm.sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.sel_country) + "&tp_control=2&nm_control=sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("A Country must be selected before choosing a State");
            break;
            
        } // end switch()
      } // lookup()

      // ------------------------------------------------------
              
      function lookupZone() {
        var frm = window.document.forms[0];
      
        window.open("../common/thesauri_f.jsp?id_domain=" + getCookie("domainid") + "&gu_workarea=" + getCookie("workarea") + "&id_scope=geozones&nm_control=nm_geozone&nm_coding=gu_geozone", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=" + String(Math.floor(600*(screen.width/800))) + ",height=" + String(Math.floor(520*(screen.height/600))) );
      }
      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
	
	frm.id_country.value = getCombo(frm.sel_country);
	
	frm.id_state.value = getCombo(frm.sel_state);

	frm.id_sales_group.value = getCombo(frm.sel_group);
	        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];

	setCombo(frm.sel_country, "<%=oMan.getStringNull(DB.id_country,"").trim()%>");

        if (frm.sel_country.options.selectedIndex>0) {
	  frm.id_country.value = getCombo(frm.sel_country);
        }

        loadstates(frm.id_state.value);

	setCombo(frm.sel_state, "<%=oMan.getStringNull(DB.id_state,"").trim()%>");

	setCombo(frm.sel_group, "<%=oMan.getStringNull(DB.id_sales_group,"")%>");
        
        return true;
      } // validate;
    //-->
  </SCRIPT>    
</HEAD>
<BODY  LEFTMARGIN="8" TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>

  <TABLE CELLSPACING="2" CELLPADDING="2">
    <TR><TD COLSPAN="4"><IMG SRC="../images/images/spacer.gif" HEIGHT="4"></TD></TR>
    <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    <TR>
<% if ((iAppMask & (1<<Shop))!=0) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/history16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewSalesHistory()" CLASS="linkplain">Order History</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% }  %>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/target16.gif" WIDTH="17" HEIGHT="18" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewSalesObjectives()" CLASS="linkplain">Sales Objectives</A></TD>
    </TR>
    <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>    

  <TABLE WIDTH="98%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Salesman <% out.write(oUsr.getStringNull(DB.tx_name,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")); %></FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="salesman_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_sales_man" VALUE="<%=gu_sales_man%>">

    <TABLE CLASS="formback" WIDTH="98%">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Sales Zone:</FONT></TD>
            <TD ALIGN="left" WIDTH="440">
              <INPUT TYPE="hidden" NAME="gu_geozone" VALUE="<%=oMan.getStringNull(DB.gu_geozone,"")%>">
              <INPUT TYPE="text" NAME="nm_geozone" SIZE="40" TABINDEX="-1" onfocus="document.forms[0].sel_country.focus()" VALUE="<%=nm_zone%>">&nbsp;<A HREF="#" onclick="lookupZone()"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Geographic Thesaurus"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Country:</FONT></TD>
            <TD ALIGN="left" WIDTH="440">
	      <SELECT NAME="sel_country" onchange="loadstates(null)"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
              <INPUT TYPE="hidden" NAME="id_country" VALUE="<%=oMan.getStringNull(DB.id_country,"").trim()%>">
              <INPUT TYPE="hidden" NAME="nm_country">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">State/Province:</FONT></TD>
            <TD ALIGN="left" WIDTH="440">
              <SELECT NAME="sel_state"></SELECT>&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View States"></A>
              <INPUT TYPE="hidden" NAME="id_state" VALUE="<%=oMan.getStringNull(DB.id_state,"").trim()%>">
              <INPUT TYPE="hidden" NAME="nm_state">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="160"><FONT CLASS="formplain">Sales Group:</FONT></TD>
            <TD ALIGN="left" WIDTH="440">
              <INPUT TYPE="hidden" NAME="id_sales_group">
              <SELECT NAME="sel_group"><OPTION VALUE=""></OPTION><%=sSalesGroupsLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Sales Groups"></A>
            </TD>
          </TR>          
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.parent.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
