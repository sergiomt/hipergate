<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.projtrack.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
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
    
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = getCookie(request,"workarea","");
  String gu_project = request.getParameter("gu_project");
  String gu_cost = request.getParameter("gu_cost");
  
  Project oProj = new Project();
  ProjectCost oCost = new ProjectCost();
  DBSubset oUsrs = new DBSubset (DB.k_users, DB.gu_user+","+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2,
  				 DB.bo_active+"<>0 AND "+DB.gu_workarea+"=? ORDER BY 2,3,4", 100);
  int iUsrs = 0;
  String sTypeLookUp = "";
    
  JDCConnection oConn = null;
    
  try {    
    oConn = GlobalDBBind.getConnection("edit_cost");      
    sTypeLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_projects_lookup, gu_workarea, DB.tp_cost, sLanguage);    
    oProj.load(oConn, new Object[]{gu_project});
    if (gu_cost!=null) oCost.load(oConn, new Object[]{gu_cost});
    iUsrs = oUsrs.load(oConn, new Object[]{gu_workarea});
    oConn.close("edit_cost");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("edit_cost");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  if (null==oConn) return;
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Cost</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--

      // 07. Pop up for showing calendar.

      function showCalendar(ctrl) {       
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------

      // 08. Generic pop up for lookup values.
              
      function lookup(odctrl) {
	var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_projects_lookup&id_language=" + getUserLanguage() + "&id_section=tp_cost&tp_control=2&nm_control=sel_cost&nm_coding=tp_cost", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      // 09. Fields values validation.

      function validate() {
        var frm = window.document.forms[0];

	if (frm.de_cost.value.length>1000) {
	  alert ("Description cannot exceed 1000 characters");
	  return false;
	}
	
	if (!isDate(frm.dt_cost.value, "d") && frm.dt_cost.value.length>0) {
	  alert ("Date is not valid");
	  return false;	  
	}

	if (isNaN(Number(frm.pr_cost.value))) {
	  alert ("Cost is not valid");
	  return false;	  
	}

	frm.tp_cost.value = getCombo(frm.sel_cost);
	frm.gu_user.value = getCombo(frm.sel_user);
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        setCombo(frm.sel_cost,"<%out.write(oCost.getStringNull(DB.tp_cost,""));%>");
        setCombo(frm.sel_user,"<%out.write(oCost.getStringNull(DB.gu_user,""));%>");
        
        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Cost</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="cost_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_cost" VALUE="<%=oCost.getStringNull(DB.gu_cost,"")%>">
    <INPUT TYPE="hidden" NAME="gu_project" VALUE="<%=gu_project%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <!-- 11. Mandatory Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Project</FONT></TD>
            <TD WIDTH="370"><FONT CLASS="formstrong"><%=oProj.getString(DB.nm_project)%></FONT></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Title</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="tl_cost" MAXLENGTH="100" SIZE="50" VALUE="<%=oCost.getStringNull(DB.tl_cost,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Amount</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="pr_cost" MAXLENGTH="9" SIZE="12" VALUE="<% if (!oCost.isNull(DB.pr_cost)) out.write(String.valueOf(oCost.getFloatFormated(DB.pr_cost,"#0.00"))); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Type</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_cost">
              <SELECT NAME="sel_cost"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View cost types"></A>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Date</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_cost" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oCost.get(DB.dt_cost)!=null ? oCost.getDateFormated(DB.dt_cost,"yyyy-MM-dd") : ""); %>">
              <A HREF="javascript:showCalendar('dt_cost')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">User</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="gu_user">
              <SELECT NAME="sel_user"><OPTION VALUE=""></OPTION><% for (int u=0; u<iUsrs; u++) out.write("<OPTION VALUE=\""+oUsrs.getString(0,u)+"\">"+oUsrs.getStringNull(1,u,"")+" "+oUsrs.getStringNull(2,u,"")+" "+oUsrs.getStringNull(3,u,"")+"</OPTION>"); %></SELECT>
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right" VALIGN="top" WIDTH="90"><FONT CLASS="formplain">Description</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
	      <TEXTAREA NAME="de_cost"><%=oCost.getStringNull(DB.de_cost,"")%></TEXTAREA>
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