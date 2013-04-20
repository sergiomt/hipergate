<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  // 03. Get parameters

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");

  // 04. Create proper DBPersist subclass
  
  DBPersist oObj = null;
  
  String sStatusLookUp = "", sPaymentLookUp = "";
    
  JDCConnection oConn = null;
    
  try {

    oConn = GlobalDBBind.getConnection("...");  
    

    sStatusLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_yourtable_lookup, gu_workarea, DB.id_section1, sLanguage);
    sPaymentLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_yourtable_lookup, gu_workarea, DB.id_section2, sLanguage);
    
    oConn.close("...");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("...");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Example Form</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>  
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
            window.open("../common/lookup_f.jsp?nm_table=k_table_lookup&id_language=" + getUserLanguage() + "&id_section=tx_field&tp_control=2&nm_control=sel_field&nm_coding=tx_field", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
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
  <SCRIPT TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        // setCombo(frm.sel_xxxx,"<%/*out.write(oObj.getStringNull(DB.gu_object,""));*/%>");
        
        return true;
      } // validate;
    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Example Form</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <!-- 11. Mandatory Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Mandatory Field:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="mandatory_field_name" MAXLENGTH="32" SIZE="32" VALUE="<%="hola"%>"></TD>
          </TR>
          <!-- 12. Optional Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Optional Field:</FONT></TD>
            <TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="optional_field_name" MAXLENGTH="32" SIZE="32" VALUE="<%="hola"%>"></TD>
          </TR>
          <!-- 13. Lookup Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Lookup Field:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="id_status">
              <SELECT NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;
              <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Status List"></A>
            </TD>
          </TR>          
          <!-- 14. Date Field -->
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Date:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="dt_xxxx" MAXLENGTH="10" SIZE="10" VALUE="<% /* out.write(oObj.get(DB.dt_xxxx)!=null ? oObj.getDateFormated(DB.dt_birth,"yyyy-MM-dd") : ""); */ %>">
              <A HREF="javascript:showCalendar('dt_xxxx')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
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
