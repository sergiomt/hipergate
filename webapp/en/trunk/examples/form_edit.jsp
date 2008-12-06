<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.example.Example" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Form for editing a DBPersist subclass object.
  
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

  // 03. Get parameters

  final String PAGE_NAME = "form_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_example = request.getParameter("gu_instance");

  String id_user = getCookie(request, "userid", "");

  // 04. Create proper DBPersist subclass
  
  Example oObj = new Example();
  
  String sTypeLookUp = "";
    
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

    sTypeLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, "k_examples_lookup", gu_workarea, "tp_example", sLanguage);
    
    if (null!=gu_example) oObj.load(oConn, new Object[]{gu_example});
    
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Example Form</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
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
            window.open("../common/lookup_f.jsp?nm_table=k_examples_lookup&id_language=" + getUserLanguage() + "&id_section=tp_example&tp_control=2&nm_control=sel_type&nm_coding=tp_example", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
	          // window.open("...
            break;
        } // end switch()
      } // lookup()
      
      // ------------------------------------------------------

      // 09. Fields values validation.

      function validate() {
        var frm = window.document.forms[0];

	/*
	if (frm.tx_comments.value.length>254) {
	  alert ("Comments cannot exceed 254 characters");
	  return false;
	}
	
	if (!isDate(frm.dt_xxxx.value, "d") && frm.dt_xxxx.value.length>0) {
	  alert ("Invalid Date");
	  return false;	  
	}

	// Move selected combo value into hidden field
	frm.id_status.value = getCombo(frm.sel_status);
        */
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        // setCombo(frm.sel_xxxx,"<%/*out.write(oObj.getStringNull(DB.gu_object,""));*/%>");
        
        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Example Form</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="form_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_example" VALUE="<%=oObj.getStringNull("gu_example","")%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <!-- 11. Boolean Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Active:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="checkbox" NAME="bo_active" VALUE="1" <% if (oObj.isNull("bo_active")) out.write("CHECKED"); else out.write(oObj.getShort("bo_active")!=0 ? "CHECKED" : ""); %>></TD>
          </TR>
          <!-- 12. Mandatory Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nm_example" MAXLENGTH="50" SIZE="40" VALUE="<%=oObj.getStringNull("nm_example","")%>"></TD>
          </TR>
          <!-- 13. Optional Fields -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Integer:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nu_example" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull("nu_example")) out.write(String.valueOf(oObj.getInt("nu_example"))); %>" onkeypress="return acceptOnlyNumbers();"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Float:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="pr_example" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull("pr_example")) out.write(String.valueOf(oObj.getFloat("pr_example"))); %>"></TD>
          </TR>
          <!-- 14. Lookup Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Lookup Field:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="tp_example">
              <SELECT NAME="sel_type"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Types List"></A>
            </TD>
          </TR>
          <!-- 15. Date Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Date:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_example" MAXLENGTH="10" SIZE="10" VALUE="<% out.write(oObj.isNull("dt_example") ? "" : oObj.getDateFormated("dt_example","yyyy-MM-dd")); %>">
              <A HREF="javascript:showCalendar('dt_example')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
            </TD>
          </TR>          
          <!-- 16 Long Text Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Description:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><TEXTAREA NAME="de_example"><%=oObj.getStringNull("de_example","")%></TEXTAREA></TD>
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