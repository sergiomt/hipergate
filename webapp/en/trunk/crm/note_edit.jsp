<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%   
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = getCookie(request,"workarea",null);
  String id_user = getCookie (request, "userid", null);
  
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
      
  // Identifica si es un registro nuevo o modificado
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String sContactNm = nullif(request.getParameter("nm_contact"));
    
  ACLUser oUser = null;
  JDCConnection oConn = GlobalDBBind.getConnection("note_edit");    
  
  try {    
    // [~//Código de acceso a datos~]
    
    oUser = new ACLUser(oConn, id_user);
    
    oConn.close("note_edit"); 
  }
  catch (SQLException e) {  
    oConn.close("note_edit");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  oConn = null;      
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//en">
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>        
  <TITLE>hipergate :: Add Note</TITLE>

    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
      <!--        

      // ------------------------------------------------------
      
      function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()
      
      // ------------------------------------------------------
      
      function validate() {
	var frm = window.document.forms[0];

	if (!isDate(frm.dt_modified.value, "d") && frm.dt_modified.value.length>0) {
	  alert ("Date is not valid");
	  return false;	  
	}
	
	if (frm.tx_note.value.length>4000) {
	  alert ("Note cannot be longer than 4000 characters");
	  return false;
	}

	if (frm.tx_note.value.length==0) {
	  alert ("Note text may not be empty");
	  return false;
	}
	
	frm.tx_fullname.value = rtrim(frm.tx_fullname.value);
	
	return true;
       } // validate()
      //-->
    </SCRIPT>
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
      <!--
        
      //-->     
    </SCRIPT>    
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">

  <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1">Add Note<%=(sContactNm.length()>0 ? " for&nbsp;" + sContactNm : "")%></FONT></TD></TR></TABLE>
  <FORM NAME="" METHOD="post" ACTION="note_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <TABLE ALIGN="center" CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="70"><FONT CLASS="formplain">Title</FONT></TD>
            <TD ALIGN="left" WIDTH="400"><INPUT TYPE="text" NAME="tl_note" MAXLENGTH="128" SIZE="40"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="70"><FONT CLASS="formplain">Writer:</FONT></TD>
            <TD ALIGN="left" WIDTH="400"><INPUT TYPE="text" NAME="tx_fullname" MAXLENGTH="200" SIZE="40" VALUE="<%=oUser.getStringNull(DB.nm_user,"") + " " + oUser.getStringNull(DB.tx_surname1,"") + " " + oUser.getStringNull(DB.tx_surname2,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="70"><FONT CLASS="formplain">e-mail:</FONT></TD>
            <TD ALIGN="left" WIDTH="400"><INPUT TYPE="text" NAME="tx_main_email" MAXLENGTH="100" SIZE="40" VALUE="<%=oUser.getStringNull(DB.tx_main_email,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="70"><FONT CLASS="formplain">Date:</FONT></TD>
            <TD ALIGN="left" WIDTH="400">
              <INPUT TYPE="text" NAME="dt_modified" MAXLENGTH="10" SIZE="10" VALUE="<%=oSimpleDate.format(new Date())%>">
              &nbsp;&nbsp;<A HREF="javascript:showCalendar('dt_modified')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show Calendar"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="70"><FONT CLASS="formplain">Note:</FONT></TD>
            <TD ALIGN="left" WIDTH="400"><TEXTAREA NAME="tx_note" ROWS="9" COLS="60"></TEXTAREA></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>          
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
</FORM>
</BODY>
</HTML>
