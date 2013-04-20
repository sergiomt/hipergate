<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.marketing.*,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
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
  
  String gu_campaign = request.getParameter("gu_campaign");
  String gu_campaign_target = request.getParameter("gu_campaign_target");
  String gu_workarea = request.getParameter("gu_workarea");

  boolean bRefresh = nullif(request.getParameter("bo_refresh"),"false").equals("true");

  JDCConnection oConn = null;

  String sShops = "", sTerms = "";
  Campaign oCamp = new Campaign();
  CampaignTarget oTrgt = new CampaignTarget();

	DBSubset oShops = new DBSubset(DB.k_shops, DB.gu_shop+","+DB.nm_shop+","+DB.gu_bundles_cat,
	  														DB.bo_active+"<>0 AND "+DB.gu_workarea+"=? ORDER BY 2", 10);

  int iShops = 0;
  int iProds = 0;
  int iDomain = 0;
  
  try {

    oConn = GlobalDBBind.getConnection("campaign_target_edit");
    
    oCamp.load(oConn, gu_campaign);

    if (null!=gu_campaign_target) {
      oTrgt.load(oConn, gu_campaign_target);
      if (bRefresh) oTrgt.refreshTargetAchievement(oConn);
    }
    
    iDomain = new WorkArea(oConn, gu_workarea).getInt(DB.id_domain);
    
    sTerms = GlobalDBLang.getHTMLTermSelect(oConn, iDomain, gu_workarea);

	  iShops = oShops.load(oConn, new Object[]{ gu_workarea});
		iProds = oShops.loadSubrecords(oConn, DB.v_prod_cat, DB.gu_category, 2);

	  for (int s=0; s<iShops; s++) {
	    sShops += "<OPTGROUP LABEL=\""+oShops.getString(1,s)+"\"></OPTGROUP>";
	    
	    if (iProds>0) {
	      DBSubset oProds = oShops.getSubrecords(s);
	      for (int p=0; p<oProds.getRowCount(); p++) {
	        sShops += "<OPTION VALUE=\""+oProds.getString(DB.gu_product,p)+"\">"+oProds.getString(DB.nm_product,p)+"</OPTION>";	      
	      } // next
	    }  // fi (iProds)
    } // next (s)

    oConn.close("campaign_target_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("campaign_target_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Campaign Target</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js" DEFER="defer"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js" DEFER="defer"></SCRIPT>  
  <SCRIPT TYPE="text/javascript">
    <!--

      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------
              
      function lookupZone() {
        var frm = window.document.forms[0];
      
        window.open("../common/thesauri_f.jsp?id_domain=<%=String.valueOf(iDomain)%>&gu_workarea=<%=gu_workarea%>&id_scope=geozones&nm_control=nm_geozone&nm_coding=gu_geozone", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=" + String(Math.floor(600*(screen.width/800))) + ",height=" + String(Math.floor(520*(screen.height/600))) );
      }
            
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];

			  if (!isDate(frm.dt_start.value,"d")) {
          alert ("Start date is required");
          frm.dt_start.focus();
          return false;
			  }

			  if (!isDate(frm.dt_end.value,"d")) {
          alert ("End date is required");
          frm.dt_end.focus();
          return false;
			  }

			  if (parseDate(frm.dt_end.value,"d")<parseDate(frm.dt_start.value,"d")) {
          alert ("End date must be later than start date");
          frm.dt_end.focus();
          return false;
			  }

        if (frm.sel_package.options.selectedIndex<=0) {
          alert ("The product is required");
          frm.sel_package.focus();
          return false;
        } else {
          frm.gu_product.value = getCombo(frm.sel_package);
        }

        if (frm.sel_zone.options.selectedIndex<=0) {
          alert ("Zone is required");
          frm.sel_zone.focus();
          return false;
        } else {
          frm.gu_geozone.value = getCombo(frm.sel_zone);
        }

			  if (frm.nu_planned.value.length==0) {
          alert ("Estimated  target is required");
          frm.nu_planned.focus();
          return false;
			  }        

			  if (!isFloatValue(frm.nu_planned.value)) {
          alert ("Forseen target is not valid");
          frm.nu_planned.focus();
          return false;
			  }        

			  if (frm.nu_achieved.value.length==0) {
          alert ("Reached target is required");
          frm.nu_achieved.focus();
          return false;
			  }        

			  if (!isFloatValue(frm.nu_achieved.value)) {
          alert ("The reached target is not valid");
          frm.nu_achieved.focus();
          return false;
			  }        

        return true;
      } // validate;

      // ------------------------------------------------------

      function setCombos() {
        var frm = window.document.forms[0];
      
        setCombo(frm.sel_package, "<%=oTrgt.getStringNull(DB.gu_product,"")%>");
        setCombo(frm.sel_zone, "<%=oTrgt.getStringNull(DB.gu_geozone,"")%>");
      }
      
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE SUMMARY="Form Title" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Campaign Target</FONT></TD></TR>
  </TABLE>

<% if (null==gu_campaign_target) { %>
  <DIV class="cxMnu1" style="width:100px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='campaign_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_campaign=<%=gu_campaign%>'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
  </DIV></DIV>
<% } else { %>
  <DIV class="cxMnu1" style="width:200px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='campaign_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_campaign=<%=gu_campaign%>'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='campaigntarget_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_campaign=<%=gu_campaign%>&gu_campaign_target=<%=gu_campaign_target%>&bo_refresh=true"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
  </DIV></DIV>
<% } %>

  <BR>  
  <FORM NAME="" METHOD="post" ACTION="campaigntarget_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_campaign" VALUE="<%=nullif(gu_campaign)%>">
    <INPUT TYPE="hidden" NAME="gu_campaign_target" VALUE="<%=nullif(gu_campaign_target)%>">
    <INPUT TYPE="hidden" NAME="gu_product" VALUE="<%=oTrgt.getStringNull(DB.gu_product,"")%>">
    <INPUT TYPE="hidden" NAME="gu_geozone" VALUE="<%=oTrgt.getStringNull(DB.gu_geozone,"")%>">
    <INPUT TYPE="hidden" NAME="nm_geozone" VALUE="">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Campaign</TD>
            <TD ALIGN="left" WIDTH="370" CLASS="formplain"><%=oCamp.getString(DB.nm_campaign)%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Product</TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_package"><OPTION VALUE="" SELECTED></OPTION><%=sShops%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Zone</TD>
            <TD ALIGN="left" WIDTH="370">
              <SELECT NAME="sel_zone"><OPTION VALUE="" SELECTED></OPTION><%=sTerms%></SELECT>&nbsp;<A HREF="#" onclick="lookupZone()"><IMG SRC="../images/images/find16.gif" BORDER="0"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">From</TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_start" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oTrgt.isNull(DB.dt_start)) out.write(oTrgt.getDateFormated(DB.dt_start,"yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_start')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">To</TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_end" MAXLENGTH="10" SIZE="10" VALUE="<% if (!oTrgt.isNull(DB.dt_end)) out.write(oTrgt.getDateFormated(DB.dt_end,"yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_end')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Forseen</TD>
            <TD ALIGN="left" WIDTH="370">
            	<INPUT TYPE="text" NAME="nu_planned" MAXLENGTH="9" SIZE="11" VALUE="<% if (!oTrgt.isNull(DB.nu_planned)) out.write(String.valueOf(oTrgt.getFloat(DB.nu_planned))); else out.write("0"); %>" onkeypress="return acceptOnlyNumbers();">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formstrong">Reached</TD>
            <TD ALIGN="left" WIDTH="370">
            	<INPUT TYPE="text" NAME="nu_achieved" MAXLENGTH="9" SIZE="11" VALUE="<% if (!oTrgt.isNull(DB.nu_achieved)) out.write(String.valueOf(oTrgt.getFloat(DB.nu_achieved))); else out.write("0"); %>" onkeypress="return acceptOnlyNumbers();">
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
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
