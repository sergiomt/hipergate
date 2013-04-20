<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
  String id_user = getCookie (request, "userid", null);

  JDCConnection oConn = GlobalDBBind.getConnection("listwizard03");  
  ACLUser oUsr;
  String sEMail = null;
  String sFullName = null;

  try {
    
    oUsr = new ACLUser(oConn, id_user);
    
    sEMail = oUsr.getStringNull(DB.tx_main_email,"");
    sFullName = oUsr.getStringNull(DB.nm_user,"");
    sFullName += " " + oUsr.getStringNull(DB.tx_surname1,"");
    sFullName += " " + oUsr.getStringNull(DB.tx_surname2,"");
    sFullName = sFullName.trim();
    
    oConn.close("listwizard03");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("listwizard03");
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;
%>

<HTML>
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function validate() {
	var frm = document.forms[0];
	
	if (document.forms[0].action=="list_wizard_03.jsp")
	  return true;
	  
	if (frm.tx_subject.value.length==0) {
	  alert("Subject is mandatory");
	  return false;
	}
	else {
	  if (frm.de_list.value.length==0)
	    frm.de_list.value = frm.tx_subject.value;
	}

	if (frm.tx_subject.value.indexOf("'")>=0) {
	  alert("Subject contains forbidden characters");
	  return false;	
	}

	if (frm.de_list.value.indexOf("'")>=0) {
	  alert("Description contains invalid characters");
	  return false;	
	}
	
	if (frm.de_list.value.length>50) {
	  alert("Description cannot be longer than 50 characters");
	  return false;	
	}
		
	if (frm.action!="list_wizard_03.jsp")
          frm.action='list_wizard_store.jsp';
        
        if (frm.tp_list.value=="3") {
          hideLayer("frm1");
          window.resizeTo(700,520);
          frm.action = "list_wizard_preview.jsp";
          }
        else
          frm.action = "list_wizard_store.jsp";
 
        return true;
      }
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Create Distribution List - Step 4 of 4</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="window.resizeTo(380,340);">
  <DIV ID="frm1">  
  <FORM METHOD="post" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="caller" VALUE="wizard">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=request.getParameter("id_domain")%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=request.getParameter("n_domain")%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=request.getParameter("gu_workarea")%>">
    <INPUT TYPE="hidden" NAME="tp_list" VALUE="<%=request.getParameter("tp_list")%>">
    <INPUT TYPE="hidden" NAME="gu_query" VALUE="<%=request.getParameter("gu_query")%>">
    <INPUT TYPE="hidden" NAME="sel_encoding" VALUE="<%=nullif(request.getParameter("sel_encoding"),"ISO8859_1")%>">
    <INPUT TYPE="hidden" NAME="tx_sender" VALUE="<%=request.getParameter("tx_sender")%>">
    <INPUT TYPE="hidden" NAME="tx_from" VALUE="<%=request.getParameter("tx_from")%>">
    <INPUT TYPE="hidden" NAME="tx_reply" VALUE="<%=request.getParameter("tx_reply")%>">
    <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=Gadgets.generateUUID()%>">

<% if (null==request.getParameter("desc_file"))
     out.write("<INPUT TYPE=\"hidden\" NAME=\"desc_file\">\n");
   else if (request.getParameter("desc_file").length()==0)
     out.write("<INPUT TYPE=\"hidden\" NAME=\"desc_file\">\n");
   else if (request.getParameter("desc_file").indexOf(34)>=0)
     out.write("<INPUT TYPE=\"hidden\" NAME=\"desc_file\" VALUE='" + request.getParameter("desc_file") + "'>\n");
   else
     out.write("<INPUT TYPE=\"hidden\" NAME=\"desc_file\" VALUE=\"" + request.getParameter("desc_file") + "\">\n");
%>         
    
    <TABLE><TR><TD WIDTH="310px" CLASS="striptitle"><FONT CLASS="title1">Create List - Step 4 of 4</FONT></TD></TR></TABLE>
    <BR>  
    <TABLE WIDTH="310px" CLASS="formback">
      <TR>
        <TD ALIGN="left" CLASS="formstrong">
          Specify Subject and Description
        </TD>
      </TR>
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left">
	      <FONT CLASS="formstrong">Subject for e-mails</FONT>
	      <BR>
	      <INPUT TYPE="text" MAXLENGTH="100" SIZE="48" CLASS="combomini" NAME="tx_subject">
	      <FONT CLASS="formplain">List Description</FONT>
	      <BR>
	      <TEXTAREA CLASS="combomini" NAME="de_list" ROWS="3" COLS="48"></TEXTAREA>
            </TD>
          </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
    <BR>
   <CENTER><INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" STYLE="width:100px" onclick="window.document.location='list_wizard_cancel.jsp?tp_list=' + document.forms[0].tp_list.value + '&gu_query=' + document.forms[0].gu_query.value;">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="<< Previous" STYLE="width:100px" onClick="document.forms[0].action='list_wizard_03.jsp';document.forms[0].submit();">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Finish" STYLE="width:100px"></CENTER>
  </FORM>
  </DIV>
</BODY>
</HTML>