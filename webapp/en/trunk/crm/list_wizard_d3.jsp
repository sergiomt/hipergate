<%@ page import="com.oreilly.servlet.MultipartRequest,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.*" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%
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

  File oEMails;
  MultipartRequest oReq = null;
  
  // Obtener el directorio temp
  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = com.knowgate.misc.Gadgets.chomp(sTempDir,java.io.File.separator);

  try {
    oReq = new MultipartRequest(request, sTempDir, 512000, "UTF-8");
  }
  catch (IOException ioe) {
    oReq = null;
    oEMails = oReq.getFile("emails");
    oEMails.delete();
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Archivo Demasiado Grande&desc=El archivo que esta intentado cargar excede la longuitud maxima permitida de 500Kb&resume=_back"));
  }

  if (null==oReq) return;

  ACLUser oUsr;
  String sEMail = null;
  String sFullName = null;
  
  String id_user = oReq.getParameter("id_user");

  JDCConnection oConn = GlobalDBBind.getConnection("listwizardd3");  

  try {
    
    oUsr = new ACLUser(oConn, id_user);
    
    sEMail = oUsr.getStringNull(DB.tx_main_email,"");
    sFullName = oUsr.getStringNull(DB.nm_user,"");
    sFullName += " " + oUsr.getStringNull(DB.tx_surname1,"");
    sFullName += " " + oUsr.getStringNull(DB.tx_surname2,"");
    sFullName = sFullName.trim();
    
    oConn.close("listwizardd3");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("listwizardd3");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  oConn = null;
  
  String sFileId = Gadgets.generateUUID();
  
  File oTmp = new File(sTempDir + sFileId + ".tmp");
  oEMails = oReq.getFile("emails");
  oEMails.renameTo(oTmp);
  
%>

<HTML>
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript">
    <!--
      function setInputs() {
	var frm = document.forms[0];
	
	frm.id_domain.value = "<% out.write(oReq.getParameter("id_domain")); %>";
	frm.n_domain.value = "<% out.write(oReq.getParameter("n_domain")); %>";
	frm.gu_workarea.value = "<% out.write(oReq.getParameter("gu_workarea")); %>";
	frm.tp_list.value = "<% out.write(oReq.getParameter("tp_list")); %>";
	frm.gu_query.value = "<% out.write(sFileId); %>";

<% if (	oReq.getParameter("desc_file").indexOf(34)>=0)
     out.write ("	frm.desc_file.value = '" + oReq.getParameter("desc_file") + "';\n");
   else
     out.write ("	frm.desc_file.value = \"" + oReq.getParameter("desc_file") + "\";\n");
%>
<%	if (null!=oReq.getParameter("tx_sender"))
	  out.write("        frm.tx_sender.value = \"" + oReq.getParameter("tx_sender") + "\";\n");
	if (null!=oReq.getParameter("tx_from"))
	  out.write("        frm.tx_from.value = \"" + oReq.getParameter("tx_from") + "\";\n");
	if (null!=oReq.getParameter("tx_reply"))
	  out.write("        frm.tx_reply.value = \"" + oReq.getParameter("tx_reply") + "\";\n");
%>
      } // setInputs()
    //-->
  </SCRIPT>
  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function validate() {
	var frm = document.forms[0];
	
	if (frm.tx_from.value.length>0) {
	  if (!check_email(frm.tx_from.value)) {
	    alert ("sender e-mail address is not valid");
	    return false;
	  }
	}

	if (frm.tx_reply.value.length>0) {
	  if (!check_email(frm.tx_reply.value)) {
	    alert ("return e-mail address is not valid");
	    return false;
	  }
	}
	  
	if (frm.action!="list_wizard_02.jsp") {
	  frm.method = "post";
	  frm.action = "list_wizard_04.jsp";	  	  
        }
        else
	  frm.method = "get";        
                
        return true; 
      }
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Create Distribution List - Step 3 of 4</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setInputs()">
  <FORM onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain">
    <INPUT TYPE="hidden" NAME="n_domain">
    <INPUT TYPE="hidden" NAME="gu_workarea">
    <INPUT TYPE="hidden" NAME="tp_list">
    <INPUT TYPE="hidden" NAME="gu_query" VALUE="<% out.write(sFileId); %>">
    <INPUT TYPE="hidden" NAME="sel_encoding" VALUE="<% out.write(oReq.getParameter("sel_encoding")); %>">
    <INPUT TYPE="hidden" NAME="desc_file" VALUE="<% out.write(oReq.getParameter("desc_file")); %>">
    <CENTER>
    <TABLE>
      <TR><TD WIDTH="310px" CLASS="striptitle"><FONT CLASS="title1">Create List - Step 2 of 4</FONT></TD></TR>
      <TR><TD><IMG SRC="../images/images/spacer.gif" WIDTH="300" HEIGHT="4" BORDER="0"></TD></TR>
    </TABLE>
    <TABLE WIDTH="310px" CLASS="formback">
      <TR>
        <TD ALIGN="left" CLASS="formstrong">
          Specify sender and return addresses
        </TD>
      </TR>
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left">
	      <FONT CLASS="formplain">Sender e-mail address</FONT>
	      <BR>
	      <INPUT TYPE="text" CLASS="combomini" NAME="tx_from" MAXLENGTH="100" SIZE="48" VALUE="<%=sEMail%>">
	      <BR>
	      <FONT CLASS="formplain">Display sender name</FONT>
	      <BR>
	      <INPUT TYPE="text" CLASS="combomini" NAME="tx_sender" MAXLENGTH="100" SIZE="48" VALUE="<%=sFullName%>">
	      <BR>
	      <FONT CLASS="formplain">e-mail return address</FONT>
	      <BR>
	      <INPUT TYPE="text" CLASS="combomini" NAME="tx_reply" MAXLENGTH="100" SIZE="48" VALUE="<%=sEMail%>">	      
            </TD>
          </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
    <TABLE SUMMARY="Buttons">
      <TR><TD><INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" STYLE="width:100px" onClick="window.document.location='list_wizard_cancel.jsp?tp_list=' + document.forms[0].tp_list.value + '&gu_query=<% out.write(sFileId); %>';">&nbsp;<INPUT TYPE="button" CLASS="pushbutton" VALUE="<< Previous" STYLE="width:100px" onClick="window.history.back()">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Next >>" STYLE="width:100px"></TD></TR>
    </TABLE>
    </CENTER>
  </FORM>
</BODY>
</HTML>