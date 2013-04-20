<%@ page import="java.text.DecimalFormat,java.util.Vector,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Address,com.knowgate.misc.Gadgets,com.knowgate.hipergate.*,com.knowgate.training.AcademicCourse,com.knowgate.workareas.ApplicationModule,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/listchilds.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
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
  
  // 01. Authenticate user session by checking cookies
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // 02. Add no-cache headers
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 03. Get parameters

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  final boolean bShopActivated = ((iAppMask & (1<<20))!=0);
  boolean bIsAdmin = false;

  String id_user = getCookie (request, "userid", null);
  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_acourse = nullif(request.getParameter("gu_acourse"));
  String gu_category = null;

  AcademicCourse oCur = new AcademicCourse();
  Address oAdr = new Address();
  String sShopsList = "";
  
  StringBuffer oSelParents = new StringBuffer("<OPTION VALUE=\"\">None. This product will not be available at the shop.</OPTION>");    
  JDCConnection oConn = null;
  DBSubset oCourses = new DBSubset(DB.k_courses, DB.gu_course+","+DB.nm_course, DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 ORDER BY 2", 100);
  int iCourses = 0;
  
  try {
    
    oConn = GlobalDBBind.getConnection("acourse_edit");  
  
    bIsAdmin = WorkArea.isAdmin(oConn, gu_workarea, id_user);
  
    iCourses = oCourses.load(oConn, new Object[]{gu_workarea});
      
    if (gu_acourse.length()>0) {
      oCur.load(oConn, new Object[]{gu_acourse});
      if (!oCur.isNull(DB.gu_address)) {
        oAdr.load(oConn, new Object[]{oCur.getString(DB.gu_address)});
      } else {
        oAdr.put(DB.gu_address,Gadgets.generateUUID());
      }
      if (bShopActivated) {
        gu_category = DBCommand.queryStr(oConn, "SELECT "+DB.gu_category+" FROM "+DB.k_x_cat_objs+" WHERE "+DB.gu_object+"='"+gu_acourse+"'");
        DBSubset oShops = new DBSubset (DB.k_shops, DB.gu_root_cat+","+DB.nm_shop+","+DB.gu_shop, DB.id_domain+"=? AND "+DB.gu_workarea+"=?", 10);
        int nShops = oShops.load(oConn, new Object[]{new Integer(id_domain), gu_workarea});
        if (nShops>0) sShopsList = Gadgets.join(oShops.getColumnAsList(2),",");      
        PreparedStatement oBrowseChilds = oConn.prepareStatement("SELECT c." + DB.gu_category + "," + DBBind.Functions.ISNULL + "(l." + DB.tr_category + ",c." + DB.nm_category + ") FROM " + DB.k_categories + " c," + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND l." + DB.gu_category + "=c." + DB.gu_category + " AND l." + DB.id_language + "='" + sLanguage + "' AND t." + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        for (int s=0; s<nShops; s++) {
          oSelParents.append("<OPTGROUP LABEL=\""+oShops.getString(1,s)+"\">");
          listChilds (oSelParents, oBrowseChilds, oShops.getString(0,s), oShops.getString(0,s), 3);
          oSelParents.append("</OPTGROUP>");
        }
        oBrowseChilds.close();
      }
    } else {
      oAdr.put(DB.gu_address,Gadgets.generateUUID());    
    }

    // Get categories list in a <SELECT> tag
    if (bShopActivated) {
      DBSubset oShops = new DBSubset (DB.k_shops, DB.gu_root_cat+","+DB.nm_shop+","+DB.gu_shop, DB.id_domain+"=? AND "+DB.gu_workarea+"=?", 10);
      int nShops = oShops.load(oConn, new Object[]{new Integer(id_domain), gu_workarea});
      if (nShops>0) sShopsList = Gadgets.join(oShops.getColumnAsList(2),",");
      PreparedStatement oBrowseChilds = oConn.prepareStatement("SELECT c." + DB.gu_category + "," + DBBind.Functions.ISNULL + "(l." + DB.tr_category + ",c." + DB.nm_category + ") FROM " + DB.k_categories + " c," + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND l." + DB.gu_category + "=c." + DB.gu_category + " AND l." + DB.id_language + "='" + sLanguage + "' AND t." + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      for (int s=0; s<nShops; s++) {
        oSelParents.append("<OPTGROUP LABEL=\""+oShops.getString(1,s)+"\">");
        listChilds (oSelParents, oBrowseChilds, oShops.getString(0,s), oShops.getString(0,s), 3);
        oSelParents.append("</OPTGROUP>");
      }
      oBrowseChilds.close();
    }

    oConn.close("acourse_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("acourse_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }

  if (null==oConn) return;
  
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Call</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/autosuggest20.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_courses_lookup&id_language=" + getUserLanguage() + "&id_section=tx_dept&tp_control=2&nm_control=sel_dept&nm_coding=tx_dept", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_courses_lookup&id_language=" + getUserLanguage() + "&id_section=tx_area&tp_control=2&nm_control=sel_area&nm_coding=tx_area", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()

      // ------------------------------------------------------

			var winadr = null;
			var intrid = false;

      function checkAddressWindow() {
        if (winadr.closed) {
          clearInterval(intrid);
          var adrtx = httpRequestText("../common/address_line.jsp?address=<%=oAdr.getStringNull(DB.gu_address,"")%>&workarea=<%=gu_workarea%>");
          if (adrtx=="notfound")
					  document.getElementById("address_line").innerHTML="<A HREF=\"#\" CLASS=\"linkplain\" onclick=\"editAddress()\">Add Address</A>";
          else
					  document.getElementById("address_line").innerHTML="<A HREF=\"#\" CLASS=\"linkplain\" onclick=\"editAddress()\">"+adrtx+"</A>";
        }
      }

		  function editAddress() {
        winadr = open("../common/addr_edit_f.jsp?gu_address=<%=oAdr.getStringNull(DB.gu_address,"")%>&noreload=1", "editacraddr", "toolbar=no,directories=no,menubar=no,resizable=no,width=700,height=" + (screen.height<=600 ? "520" : "640"));
		    intrid = setInterval ("checkAddressWindow()", 100);
		  }

      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

	      if (frm.sel_course.selectedIndex<0) {
	        alert ("Base Course is required");
	        return false;
	      }
        
	      if (frm.nm_course.value.length==0) {
	        alert ("Academic Course name is required");
	        return false;
	      }
	      
	      if ((frm.nm_course.value.indexOf("'")>=0) || (frm.nm_course.value.indexOf('"')>=0)) {
	        alert ("Academic Course Name contains forbidden characters");
	        return false;
	      }
        
	      if (frm.tx_start.value.length==0) {
	        alert ("Start date is mandatory");
	        return false;
	      }
        
	      if (frm.tx_end.value.length==0) {
	        alert ("End date is mandatory");
	        return false;
	      }
        
	      if (frm.de_course.value.length>2000) {
	        alert ("Academic Course description cannot exceed 2000 characters");
	        return false;
	      }
	      
	      if ((frm.tx_tutor_email.value.length>0) && !check_email(frm.tx_tutor_email.value)) {
	        alert ("Tutor e-mail address is not valid");
	        return false;
	      }
        
        if (frm.pr_acourse.value.length>0 && !isFloatValue(frm.pr_acourse.value.replace(",","."))) {
	        alert ("Course price is not valid");
	        return false;
        } else {
          frm.pr_acourse.value = frm.pr_acourse.value.replace(",",".");
        }
        
        if (frm.pr_booking.value.length>0 && !isFloatValue(frm.pr_booking.value.replace(",","."))) {
	        alert ("Booking price is not valid");
	        return false;
        } else {
          frm.pr_booking.value = frm.pr_booking.value.replace(",",".");
        }
        
        if (frm.pr_payment.value.length>0 && !isFloatValue(frm.pr_payment.value.replace(",","."))) {
	        alert ("Monthly Payment amount is not valid");
	        return false;
        } else {
          frm.pr_payment.value = frm.pr_payment.value.replace(",",".");
        }
	      
	      if (frm.nu_max_alumni.value.length>0 && !isIntValue(frm.nu_max_alumni.value)) {
	        alert ("The capacity is not a valid integer");
	        return false;
	      }

	      frm.nm_course.value = frm.nm_course.value.toUpperCase();
	      frm.id_course.value = frm.id_course.value.toUpperCase();
	      
	      frm.gu_course.value = getCombo(frm.sel_course);
        
	      if (frm.chk_active.checked) frm.bo_active.value = "1"; else frm.bo_active.value = "0";

        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];

        setCombo(frm.sel_course,"<% out.write(oCur.getStringNull(DB.gu_course,"")); %>");
        setCombo(frm.nu_payments,"<% if (!oCur.isNull(DB.nu_payments)) out.write(String.valueOf(oCur.getInt(DB.nu_payments))); %>");
<%      if (gu_category!=null) { %>
          setCombo(frm.gu_category,"<% out.write(gu_category); %>");
<%      } %>	
        return true;
      } // setCombos;

      // -----------------------------------------------------------------

		  var req = false;

      function processProductInfo() {
        if (req.readyState == 4) {
          if (req.status == 200) {
          	var frm = document.forms[0];
          	var prd = req.responseText.split("\t");
            if (frm.gu_acourse.value.length==0) frm.gu_acourse.value=prd[0];
            if (frm.nm_course.value.length==0) frm.nm_course.value=prd[1];
            if (frm.de_course.value.length==0) frm.de_course.value=prd[2];
            if (frm.id_course.value.length==0) frm.id_course.value=prd[3];
            if (frm.tx_start.value.length==0 && prd[4].length>0 && prd[4]!="null") frm.tx_start.value=prd[4].substr(0,10);
            if (frm.tx_end.value.length==0 && prd[5].length>0 && prd[5]!="null") frm.tx_end.value=prd[5].substr(0,10);
            req = false;
          }
	  	  }
      } // processProductInfo
		  
      function loadProductInfo(gu) {
			  req = createXMLHttpRequest();
	      if (req) {
	        req.onreadystatechange = processProductInfo;
	        req.open("GET", "../shop/item_info.jsp?gu_product="+gu, true);
	        req.send(null);
	      }			  
      }

    //-->
  </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:420px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
<% if (gu_acourse.length()>0) { %>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='acourse_print.jsp?gu_acourse=<%=gu_acourse%>'"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Imprimir"> Print</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='acourse_excel.jsp?gu_acourse=<%=gu_acourse%>'"><IMG src="../images/images/excel16.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Excel"> Excel</SPAN>
<% } if (bIsAdmin) { %>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='acourse_users_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_acourse=<%=gu_acourse%>'"><IMG src="../images/images/crm/padlock16.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Permisos"> Permissions</SPAN>
<% } %>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Call</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="acourse_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=String.valueOf(id_domain)%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_acourse" VALUE="<%=gu_acourse%>">
    <INPUT TYPE="hidden" NAME="gu_supplier" VALUE="<%=oCur.getStringNull(DB.gu_supplier,"")%>">
    <INPUT TYPE="hidden" NAME="bo_active" VALUE="<% if (!oCur.isNull(DB.bo_active)) out.write(String.valueOf(oCur.getShort(DB.bo_active))); else out.write("1"); %>">
    <INPUT TYPE="hidden" NAME="nu_payments" VALUE="<% if (!oCur.isNull(DB.nu_payments)) out.write(String.valueOf(oCur.getInt(DB.nu_payments))); %>">
    <INPUT TYPE="hidden" NAME="nu_booked" VALUE="<% if (!oCur.isNull("nu_booked")) out.write(String.valueOf(oCur.getInt("nu_booked"))); %>">
    <INPUT TYPE="hidden" NAME="nu_confirmed" VALUE="<% if (!oCur.isNull("nu_confirmed")) out.write(String.valueOf(oCur.getInt("nu_confirmed"))); %>">
    <INPUT TYPE="hidden" NAME="nu_alumni" VALUE="<% if (!oCur.isNull("nu_alumni")) out.write(String.valueOf(oCur.getInt("nu_alumni"))); %>">
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formstrong">Active:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="checkbox" NAME="chk_active" <% if (!oCur.isNull(DB.bo_active)) out.write(oCur.getShort(DB.bo_active)!=0 ? "CHECKED" : ""); else out.write("CHECKED"); %>></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Identifier:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="id_course" MAXLENGTH="50" SIZE="10" STYLE="text-transform:uppercase" VALUE="<%=oCur.getStringNull(DB.id_course,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="nm_course" MAXLENGTH="100" SIZE="48" STYLE="text-transform:uppercase" VALUE="<%=oCur.getStringNull(DB.nm_course,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formstrong">Start:</FONT></TD>
            <TD ALIGN="left" WIDTH="500">
              <INPUT TYPE="text" NAME="tx_start" MAXLENGTH="30" SIZE="15" STYLE="text-transform:uppercase" VALUE="<%=oCur.getStringNull(DB.tx_start,"")%>">
              &nbsp;&nbsp;<FONT CLASS="formstrong">End:</FONT>&nbsp;
	            <INPUT TYPE="text" NAME="tx_end" MAXLENGTH="30" SIZE="15" STYLE="text-transform:uppercase" VALUE="<%=oCur.getStringNull(DB.tx_end,"")%>">              
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Base Course:</FONT></TD>
            <TD ALIGN="left" WIDTH="500">
              <INPUT TYPE="hidden" NAME="gu_course">
              <SELECT NAME="sel_course" CLASS="combomini" STYLE="width:400px"><OPTION VALUE=""></OPTION>
              <% for (int c=0; c<iCourses; c++)
                   out.write ("<OPTION VALUE=\""+oCourses.getString(0,c)+"\">"+Gadgets.HTMLEncode(oCourses.getString(1,c))+"</OPTION>");
              %>
              </SELECT>
              &nbsp;
              <A HREF="course_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>" TITLE="New Course"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Course"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Price:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="pr_acourse" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oCur.isNull(DB.pr_acourse)) { DecimalFormat oFmt2 = new DecimalFormat(); oFmt2.setMaximumFractionDigits(2); out.write(oFmt2.format(oCur.getDecimal(DB.pr_acourse).doubleValue())); } %>">
						&nbsp;&nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Booking:</FONT>&nbsp;
            <INPUT TYPE="text" NAME="pr_booking" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oCur.isNull(DB.pr_booking)) { DecimalFormat oFmt2 = new DecimalFormat(); oFmt2.setMaximumFractionDigits(2); out.write(oFmt2.format(oCur.getDecimal(DB.pr_booking).doubleValue())); } %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120" CLASS="formplain">Capacity:</TD>
            <TD ALIGN="left" WIDTH="500" CLASS="formplain">
            	<INPUT TYPE="text" NAME="nu_max_alumni" SIZE="10" VALUE="<% if (!oCur.isNull("nu_max_alumni")) out.write(String.valueOf(oCur.getInt("nu_max_alumni"))); %>">
              &nbsp;&nbsp;&nbsp;&nbsp;
              <% if (!oCur.isNull("nu_confirmed")) { %> Confirmed&nbsp;<% out.write(String.valueOf(oCur.getInt("nu_confirmed"))); } %>
              <% if (!oCur.isNull("nu_alumni")) { %> Accepted&nbsp;<% out.write(String.valueOf(oCur.getInt("nu_alumni"))); } %>
              &nbsp;&nbsp;&nbsp;&nbsp;
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Monthly Payment:</FONT></TD>
            <TD ALIGN="left" WIDTH="500">
            	<SELECT NAME="nu_payments"><OPTION VALUE="0">0</OPTION><OPTION VALUE="1">1</OPTION><OPTION VALUE="2">2</OPTION><OPTION VALUE="3">3</OPTION><OPTION VALUE="4">4</OPTION><OPTION VALUE="5">5</OPTION><OPTION VALUE="6">6</OPTION><OPTION VALUE="7">7</OPTION><OPTION VALUE="8">8</OPTION><OPTION VALUE="9">9</OPTION><OPTION VALUE="10">10</OPTION><OPTION VALUE="11">11</OPTION><OPTION VALUE="12">12</OPTION></SELECT>
            	&nbsp;&nbsp;&nbsp;
            	<INPUT TYPE="text" NAME="pr_payment" MAXLENGTH="10" SIZE="12" VALUE="<% if (!oCur.isNull(DB.pr_payment)) { DecimalFormat oFmt2 = new DecimalFormat(); oFmt2.setMaximumFractionDigits(2); out.write(oFmt2.format(oCur.getDecimal(DB.pr_payment).doubleValue())); } %>">
            </TD>
          </TR>
<% if (bShopActivated) { %>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Category:</FONT></TD>
            <TD ALIGN="left" WIDTH="500">
						  <SELECT NAME="gu_category" CLASS="combomini"><%=oSelParents.toString()%></SELECT>
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Address:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=oAdr.getStringNull(DB.gu_address,"")%>">
<% if (oCur.isNull(DB.gu_address)) { %>
						  <DIV ID="address_line"><A HREF="#" CLASS="linkplain" onclick="editAddress()">Add address</A></DIV>
<% } else { %>
						  <DIV ID="address_line"><A HREF="#" CLASS="linkplain" onclick="editAddress()"><%=oAdr.toLocaleString()%></A></DIV>
<% } %>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">Tutor:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="nm_tutor" MAXLENGTH="200" SIZE="48" VALUE="<%=oCur.getStringNull(DB.nm_tutor,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><INPUT TYPE="text" NAME="tx_tutor_email" MAXLENGTH="100" SIZE="48" VALUE="<%=oCur.getStringNull(DB.tx_tutor_email,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="120"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="500"><TEXTAREA ROWS="2" COLS="32" NAME="de_course"<%=oCur.getStringNull(DB.de_course,"")%>></TEXTAREA></TD>
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
<% if (sShopsList.length()>0) { %>
<SCRIPT TYPE="text/javascript">
    <!--  
      var AutoSuggestOptions = { script:"String('../common/autocomplete.jsp?gu_shop=<%=sShopsList%>&')", varname:"tx_like",minchars:3,form:0, callback: function (obj) { loadProductInfo(obj.id); } };
      var AutoSuggestNmCourse = new AutoSuggest("nm_course", AutoSuggestOptions);
      var AutoSuggestIdRef = new AutoSuggest("id_course", AutoSuggestOptions);
    //-->
</SCRIPT>
<% } %>
</HTML>
