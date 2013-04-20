<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.Category,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/customattrs.jspf" %><%
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

  final int Directory = 19, Shop=20;
     
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_category = nullif(request.getParameter("id_category"));

  String id_user = getCookie (request, "userid", null);
  String nm_sector = "";
  String nm_legal = "";
  
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
    
  String gu_company = request.getParameter("gu_company")==null ? "" : request.getParameter("gu_company");

  Company oComp = new Company();
  String sStatusLookUp = "";
  String sTypeLookUp = "";
  String sFareLookUp = "";
  
  String sIdCategory = "", sTrCategory = "";
  
  JDCConnection oConn = null;    
  DBSubset oSalesMen = null;
  DBSubset oProdSelected = null;
  DBSubset oProdFamilies = null;
  String sProdSelected = "";
  String sSalesMen = "";
  StringBuffer sProdFamilies = null;
  int iProdFamilies = 0;
  PreparedStatement oStmt;
  ResultSet oRSet;
  
  boolean bIsGuest = true;
  boolean bIsAdmin = false;
  
  try {    
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

    oConn = GlobalDBBind.getConnection("company_edit");
    
    sStatusLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_companies_lookup, gu_workarea, DB.id_status, sLanguage);
    sTypeLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_companies_lookup, gu_workarea, DB.tp_company, sLanguage);
    sFareLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_prod_fares_lookup, gu_workarea, DB.id_fare, sLanguage);

    sSalesMen = GlobalCacheClient.getString("k_sales_men["+gu_workarea+"]");
    if (null==sSalesMen) {
      oSalesMen = new DBSubset(DB.k_sales_men+" m,"+DB.k_users+" u","m."+DB.gu_sales_man+",u."+DB.nm_user+",u."+DB.tx_surname1+",u."+DB.tx_surname2,
      																	"m."+DB.gu_sales_man+"=u."+DB.gu_user+" AND m."+DB.gu_workarea+"=? ORDER BY 2,3,4", 100);
      int nSalesMen = oSalesMen.load(oConn,new Object[]{gu_workarea});
      StringBuffer oMenBuff = new StringBuffer(100*(nSalesMen+1));
      for (int m=0; m<nSalesMen; m++) {
        oMenBuff.append("<OPTION VALUE=\"");
        oMenBuff.append(oSalesMen.getString(0,m));
        oMenBuff.append("\">");
        oMenBuff.append(oSalesMen.getStringNull(1,m,""));
        oMenBuff.append(" ");
        oMenBuff.append(oSalesMen.getStringNull(2,m,""));
        oMenBuff.append(" ");
        oMenBuff.append(oSalesMen.getStringNull(3,m,""));
        oMenBuff.append("</OPTION>");
      } // next
      sSalesMen = oMenBuff.toString();
      GlobalCacheClient.put("k_sales_men["+gu_workarea+"]", sSalesMen);
      oMenBuff = null;
      oSalesMen = null;
    } // fi

    if (gu_company.length()>0) {
      Object aComp[] = { gu_company };
      if (!oComp.load(oConn, aComp))
        throw new SQLException("Could not find any company with GUID "+gu_company);
          
      nm_sector = nullif(DBLanguages.getLookUpTranslation((java.sql.Connection) oConn, DB.k_companies_lookup, gu_workarea, DB.id_sector, sLanguage, oComp.getStringNull(DB.id_sector,"")));
      nm_legal = oComp.getString(DB.nm_legal);
    
      if ((iAppMask & (1<<Directory))!=0) {
        oStmt = oConn.prepareStatement("SELECT x." + DB.gu_category + "," + DB.tr_category + " FROM " + DB.k_x_cat_objs + " x, " + DB.k_cat_labels + " l WHERE x." + DB.gu_object + "=? AND x." + DB.id_class + "=" + String.valueOf(Company.ClassId) + " AND l." + DB.gu_category + "=x." + DB.gu_category + " AND l." + DB.id_language + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, gu_company);
        oStmt.setString(2, sLanguage);      
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          sIdCategory = oRSet.getString(1);
          sTrCategory = oRSet.getString(2);
        }
        oRSet.close();
        oStmt.close();
      }

      oConn.setAutoCommit (true);

      com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, id_user, "com.knowgate.http.portlets.RecentContactsTab", gu_workarea);

    }
    else if (id_category.length()>0) {
      Category oCatg = new Category(oConn, id_category);
      sIdCategory = id_category;
      sTrCategory = oCatg.getLabel(oConn, sLanguage);
    }
    
    if ((iAppMask & (1<<Shop))!=0) {

      if (gu_company.length()>0) {
        oProdSelected = new DBSubset ("k_x_company_prods", DB.gu_category, DB.gu_company + "='" + gu_company + "'",10);
	oProdSelected.load(oConn);
      }

      oProdFamilies = new DBSubset (DB.k_cat_labels + " l," + DB.k_cat_expand + " e," + DB.k_shops + " s",
      				    "l." + DB.gu_category + ", l." + DB.tr_category + ", e." + DB.od_level + ", e." + DB.od_walk,
      				    "l." + DB.gu_category + "=e." + DB.gu_category + " AND " +
      				    "s." + DB.gu_root_cat + "=e." + DB.gu_rootcat + " AND " +
      				    "l." + DB.id_language + "='" + sLanguage + "' AND " +
      				    "s." + DB.gu_workarea + "='" + gu_workarea + "' ORDER BY 3,4", 10);
      
      oProdFamilies.load(oConn);
      
      iProdFamilies = oProdFamilies.getRowCount();
      
      sProdFamilies = new StringBuffer(iProdFamilies*100);
      
      for (int f=0; f<iProdFamilies; f++) {

        sProdFamilies.append ("<OPTION VALUE=\"" + oProdFamilies.getString(0,f) + "\"");
        
        if (null!=oProdSelected)
          if (oProdSelected.find(0, oProdFamilies.getString(0,f))!=-1) sProdFamilies.append (" SELECTED");

        sProdFamilies.append (">");

        for (int s=0; s<oProdFamilies.getInt(2,f); s++)
          sProdFamilies.append ("&nbsp;");          

        sProdFamilies.append (oProdFamilies.getString(1,f) + "</OPTION>");      
      } // next(f) 
    } // fi (iAppMask & Shop)
    
    sendUsageStats(request, "company_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("company_edit");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
    oConn = null; 
  }
  
  if (null==oConn) return;
  
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>        
  <TITLE>hipergate :: Edit Company</TITLE>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
      <!--        
      
      // ------------------------------------------------------

        function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_companies_lookup&id_language=" + getUserLanguage() + "&id_section=id_sector&tp_control=1&nm_control=nm_sector&nm_coding=id_sector", "lookupsectors", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_companies_lookup&id_language=" + getUserLanguage() + "&id_section=id_status&tp_control=2&nm_control=sel_status&nm_coding=id_status", "lookupstatus", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_companies_lookup&id_language=" + getUserLanguage() + "&id_section=tp_company&tp_control=2&nm_control=sel_typecompany&nm_coding=tp_company", "lookuptypecompany", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            window.open("../common/lookup_f.jsp?nm_table=k_prod_fares_lookup&id_language=" + getUserLanguage() + "&id_section=id_fare&tp_control=2&nm_control=id_fare", "lookuptypefare", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
            
      // ------------------------------------------------------

      function viewAddrs() {
        var frm = window.document.forms[0];
      
        window.location = "../common/addr_list.jsp?nm_company=" + escape(frm.nm_legal.value) + "&linktable=k_x_company_addr&linkfield=gu_company&linkvalue=" + getURLParam("gu_company");
      }

      // ------------------------------------------------------

      function viewBankAccounts() {
        var frm = window.document.forms[0];
      
        window.location = "../common/bank_list.jsp?nm_company=" + escape(frm.nm_legal.value) + "&linktable=k_x_company_bank&linkfield=gu_company&linkvalue=" + getURLParam("gu_company");
      }

      // ------------------------------------------------------

      function viewContacts() {            
        
        if (window.opener) {
          window.opener.parent.location = "contact_listing_f.jsp?id_domain=" + getURLParam("id_domain") + "&n_domain=" + getURLParam("n_domain") + "&skip=0&orderby=0&field=nm_legal&find=" + encodeURIComponent("<%=nm_legal%>") + "&selected=2&subselected=1";
          window.opener.focus();
        } else {
          open ("contact_listing_f.jsp?id_domain=" + getURLParam("id_domain") + "&n_domain=" + getURLParam("n_domain") + "&skip=0&orderby=0&field=nm_legal&find=" + encodeURIComponent("<%=nm_legal%>") + "&selected=2&subselected=1");
        }
        self.close();
      }

      // ------------------------------------------------------

      function viewSalesHistory() {

	var w = window.opener;
		
	if (typeof(w)=="undefined")
	  window.open("../shop/order_list.jsp?company=<% out.write(gu_company); %>&selected=7&subselected=1");
	else {
	  w.document.location.href = "../shop/order_list.jsp?company=<% out.write(gu_company); %>&selected=7&subselected=1";
	  w.focus();
        }
      }
  
      // --------------------------------------------------------

<% if ((iAppMask & (1<<Directory))!=0) { %>
    
      function selectCategory() {
        if (navigator.javaEnabled() && 1==0) {          
          window.open("../vdisk/pickdipu.jsp?inputid=id_category&inputtr=tr_category", "pickcategory", "toolbar=no,directories=no,menubar=no,resizable=no,width=320,height=460");
        }
        else {
          window.open("../vdisk/catjtree_f.jsp?id_user=" + getCookie("userid") + "&nm_coding=id_category&nm_control=tr_category", "jcattree", "toolbar=no,directories=no,menubar=no,resizable=no,width=400,height=500");
	}	
      }    
<% } %>
      
      // ------------------------------------------------------
      
      function validate() {
	var frm = window.document.forms[0];
	var lst = "";

	
	if (ltrim(frm.nm_legal.value)=="") {
	  alert ("Legal Name is required");
	  return false;
	}

	if (frm.nm_legal.value.indexOf("'")>0 || frm.nm_legal.value.indexOf("¡")>0 || frm.nm_legal.value.indexOf("?")>0 || frm.nm_legal.value.indexOf('"')>0 || frm.nm_legal.value.indexOf("\\")>0 || frm.nm_legal.value.indexOf("/")>0 || frm.nm_legal.value.indexOf("*")>0 || frm.nm_legal.value.indexOf("`")>0 || frm.nm_legal.value.indexOf("´")>0 || frm.nm_legal.value.indexOf("¨")>0 || frm.nm_legal.value.indexOf('^')>0) {
	  alert ("Legal name contains forbidden characters");
	  return false;	  
	}
	
	frm.nm_legal.value = rtrim(frm.nm_legal.value.toUpperCase());

	txt = frm.nu_employees.value;
	for (var c=0; c<txt.length; c++)
	  if (txt.charCodeAt(c)<48 || txt.charCodeAt(c)>57) {
	    alert ("Head count must be an integer quantity");
	    return false;
	  }
	
	txt = frm.im_revenue.value;
	if (txt.length>0 && isNaN(txt)) {
	    alert ("Billing is not valid");
	    return false;	
	}

        if (!isDate(frm.dt_founded.value, "d") && frm.dt_founded.value.length>0) {
	  alert ("Date founded is not valid");
	  return false;
	}
	
	if (frm.de_company.value.length>254) {
	  alert ("Company description must not be longer than 254 characters");
	  return false;
	}

<% if ((iAppMask & (1<<Shop))!=0) { %>
	var prd = frm.sel_prods.options;	
	for (var n=0; n<prd.length; n++)
          if (prd[n].selected) {
            if (lst.length>0) lst += ",";
            lst += prd[n].value;
          }
        frm.tx_prods.value = lst;
<% } %>
 
	frm.id_status.value = getCombo(frm.sel_status);
	frm.tp_company.value = getCombo(frm.sel_typecompany);

	return true;
       } // validate()
       
       
      //-->
    </SCRIPT>
    <SCRIPT TYPE="text/javascript">
      <!--
        function setCombos() {
          var frm = document.forms[0];         
          
          setCombo(frm.sel_status,"<%=oComp.getStringNull(DB.id_status,"")%>");
          setCombo(frm.sel_typecompany,"<%=oComp.getStringNull(DB.tp_company,"")%>");
          setCombo(frm.id_fare,"<%=oComp.getStringNull(DB.id_fare,"")%>");
          setCombo(frm.gu_sales_man,"<%=oComp.getStringNull(DB.gu_sales_man,"")%>");
        }

      //-->     
    </SCRIPT>
    <!--
    tabbed panel by Jamie Jaworski taken from builder.com
    http://builder.cnet.com/webbuilding/0-7701-8-5056260-1.html?tag=st.bl.3882.dir1.7701-8-5056260-1
    -->    
    <SCRIPT TYPE="text/javascript">
      <!--
        function selectTab(n) {
        	var frm = document.forms["fixedAttrs"];
        	
        	if (0==n) {
        	  frm.sel_status.style.visibility = "visible";
        	  frm.sel_typecompany.style.visibility = "visible";
        	  frm.sel_delcustomfield.style.visibility = "hidden";
<% if ((iAppMask & (1<<Shop))!=0) { %>
        	  frm.sel_prods.style.visibility = "visible";
<% } %>
        	}
        	else  {
        	  frm.sel_status.style.visibility = "hidden";
        	  frm.sel_typecompany.style.visibility = "hidden";        	  
        	  frm.sel_delcustomfield.style.visibility = "visible";
<% if ((iAppMask & (1<<Shop))!=0) { %>
        	  frm.sel_prods.style.visibility = "hidden";
<% } %>
        	}
        	
        	var panelID = "p1";
        	var numDiv = 2;
        	// iterate all tab-panel pairs
        	for(var i=0; i < numDiv; i++) {
        		var panelDiv = window.document.getElementById(panelID+"panel"+i);
        		var tabDiv = document.getElementById(panelID+"tab"+i);
        		z = panelDiv.style.zIndex;
        		// if this is the one clicked and it isn't in front, move it to the front
        		if (z != numDiv && i == n) { z = numDiv; }
        		// in all other cases move it to the original position
        		else { z = (numDiv-i); }
        		panelDiv.style.zIndex = z;
        		tabDiv.style.zIndex = z;
        	}
        }
      //-->
    </SCRIPT>
    <STYLE TYPE="text/css">
      <!--
      .tab {
      font-family: sans-serif; font-size: 12px; line-height:150%; font-weight: bold; position:absolute; text-align: center; border: 2px; border-color:#999999; border-style: outset; border-bottom-style: none; width:180px; margin:0px;
      }

      .panel {
      font-family: sans-serif; font-size: 12px; position:absolute; border: 2px; border-color:#999999; border-style:outset; width:600px; height:560px; left:0px; top:24px; margin:0px; padding:6px;
      }
      -->
    </STYLE>                
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onload="setCombos()">
<FORM NAME="fixedAttrs" METHOD="post" ACTION="company_edit_store.jsp" onSubmit="return validate()">
  <DIV class="cxMnu1" style="width:<%=(gu_company.length()>0 && bIsAdmin ? "4" : "3")%>20px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
<% if (gu_company.length()>0 && bIsAdmin) { %>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='company_security.jsp?id_domain=<%=id_domain%>&gu_company=<%=gu_company%>'"><IMG src="../images/images/crm/padlock16.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Security"> Security</SPAN>
<% } %>
  </DIV></DIV>
<% if (gu_company.length()>0) { %>
  <TABLE CELLSPACING="2" CELLPADDING="2">
    <TR><TD COLSPAN="8"><IMG SRC="../images/images/spacer.gif" HEIGHT="4"></TD></TR>
    <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    <TR>
      <TD VALIGN="middle"><IMG SRC="../images/images/theworld16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="javascript:viewAddrs()" CLASS="linkplain">Addresses</A></TD>
      <TD VALIGN="middle"><IMG SRC="../images/images/contactos.gif" WIDTH="20" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewContacts()" CLASS="linkplain">Contacts</A></TD>
<% if (gu_company.length()>0) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/bankacc.gif" WIDTH="17" HEIGHT="17" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="javascript:viewBankAccounts()" CLASS="linkplain">Bank Account</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
<% if (((iAppMask & (1<<Shop))!=0) && (gu_company.length()>0)) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/history16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewSalesHistory()" CLASS="linkplain">Order History</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
    </TR>
    <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>
<% } else { out.write("<BR><BR>"); } // fi (gu_company) %>
 
  <DIV style="background-color:transparent;position:relative;width:600px;">
  <DIV id="p1panel0" class="panel" style="background-color:#eee;z-index:2">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=gu_company%>">
    <INPUT TYPE="hidden" NAME="bo_restricted" VALUE="<% if (!oComp.isNull(DB.bo_restricted)) out.write(String.valueOf(oComp.getShort(DB.bo_restricted))); else out.write("0"); %>">
    <INPUT TYPE="hidden" NAME="noreload" VALUE="<%=nullif(request.getParameter("noreload"),"0")%>">
    <TABLE WIDTH="100%">
      <TR><TD>
        <TABLE ALIGN="center">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Legal Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_legal" MAXLENGTH="50" SIZE="40" STYLE="text-transform:uppercase" VALUE="<%=oComp.getStringNull(DB.nm_legal,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Commercial Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_commercial" MAXLENGTH="50" SIZE="40" VALUE="<%=oComp.getStringNull(DB.nm_commercial,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Sector:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="nm_sector" MAXLENGTH="32" SIZE="40" VALUE="<%=nm_sector%>" TABINDEX="-1" onfocus="document.forms[0].sel_status.focus()">&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Sectors List"></A>&nbsp;&nbsp;<A HREF="#" onclick="document.forms[0].nm_sector.value='';document.forms[0].id_sector.value='';"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Unassign Sector"></A>
              <INPUT TYPE="hidden" NAME="id_sector" VALUE="<%=oComp.getStringNull(DB.id_sector,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Legal Id:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="id_legal" MAXLENGTH="16" SIZE="10" VALUE="<%=oComp.getStringNull(DB.id_legal,"")%>">
	             &nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Your Reference:</FONT>&nbsp;
              <INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="15" VALUE="<%=oComp.getStringNull(DB.id_ref,"")%>">
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Company Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="hidden" NAME="tp_company" MAXLENGTH="30" SIZE="20" VALUE="<%=oComp.getStringNull(DB.tp_company,"")%>"><SELECT NAME="sel_typecompany"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Company Types"></A>
            &nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Status:</FONT>&nbsp;<SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Status List"></A>
            <INPUT TYPE="hidden" NAME="id_status" VALUE="<%=oComp.getStringNull(DB.id_status,"")%>">
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Billing:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="im_revenue" MAXLENGTH="11" SIZE="10" VALUE="<%=oComp.getStringNull(DB.im_revenue,"")%>">
              &nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Head Count:</FONT>&nbsp;
              <INPUT TYPE="text" NAME="nu_employees" MAXLENGTH="9" SIZE="10" VALUE="<%=oComp.getStringNull(DB.nu_employees,"")%>">
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Date Founded:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_founded" MAXLENGTH="10" SIZE="10" VALUE="<%=nullif(oComp.getDateFormated(DB.dt_founded,"yyyy-MM-dd"))%>">
              <A HREF="javascript:showCalendar('dt_founded')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
<% if ((iAppMask & (1<<Directory))!=0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Category</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="id_category" VALUE="<%=sIdCategory%>">
              <INPUT TYPE="text" NAME="tr_category" MAXLENGTH="30" SIZE="34" onfocus="document.forms[0].de_company.focus();" TABINDEX="-1" VALUE="<%=sTrCategory%>">&nbsp;
              <A HREF="#" onclick="selectCategory()" CLASS="formplain"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Change Category"></A>
            </TD>
          </TR>
<% } %>
<% if ((iAppMask & (1<<Shop))!=0) { %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Product Families:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tx_prods" VALUE="<% out.write(sIdCategory); %>">
	      <SELECT NAME="sel_prods" SIZE="5" MULTIPLE><% out.write(sProdFamilies.toString()); %></SELECT>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Fare:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><SELECT NAME="id_fare"><OPTION VALUE=""></OPTION><%=sFareLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Fares List"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Salesman:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><SELECT NAME="gu_sales_man"><OPTION VALUE=""></OPTION><%=sSalesMen%></SELECT></TD>
          </TR>
          <TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA NAME="de_company" ROWS="3" COLS="40"><% out.write(oComp.getStringNull(DB.de_company,"")); %></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>          
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	    </TD>	            
	  </TR>
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </DIV>
  <DIV onclick="selectTab(0)" id="p1tab0" class="tab" style="background-color:#eee; height:26px; left:0px; top:0px; z-index:2"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Fixed Fields</SPAN></DIV>
  <DIV id="p1panel1" class="panel" style="background-color:#ddd;z-index:1">
    <TABLE WIDTH="100%">
      <TR><TD>
        <TABLE ALIGN="center">  
  	   <% if (oConn!=null) out.write(paintAttributes (oConn, GlobalCacheClient, id_domain, id_user, iAppMask, DB.k_companies_attrs, "Companies", gu_workarea, sLanguage, gu_company)); %>
        </TABLE>
      </TD></TR>
      <TR>
        <TD COLSPAN="2"><HR></TD>
      </TR>          
      <TR>
    	<TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
          <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your credential level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<% } else { %>
          <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
          <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	</TD>	            
       </TR>
    </TABLE>    
  </DIV>
  <DIV onclick="selectTab(1)" id="p1tab1" class="tab" style="width:240px; background-color:#ddd; height:26px; left:180px; top:0px; z-index:1"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Defined by User</SPAN></DIV>
  </DIV>  
</FORM>
</BODY>
</HTML>
<%
if (null!=oConn)  oConn.close("company_edit");
oConn=null; 
%>
