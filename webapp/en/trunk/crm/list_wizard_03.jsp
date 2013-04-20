<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%  
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
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript">
    <!--
      function setInputs() {
	var frm = document.forms[0];
	frm.id_domain.value = "<%=request.getParameter("id_domain")%>";
	frm.n_domain.value = "<%=request.getParameter("n_domain")%>";
	frm.gu_workarea.value = "<%=request.getParameter("gu_workarea")%>";
	frm.tp_list.value = "<%=request.getParameter("tp_list")%>";
	frm.gu_query.value = "<%=request.getParameter("gu_query")%>";
<%	if (null!=request.getParameter("tx_sender"))
	  out.write("	frm.tx_sender.value = \"" + request.getParameter("tx_sender") + "\";");
	if (null!=request.getParameter("tx_from"))
	  out.write("	frm.tx_from.value = \"" + request.getParameter("tx_from") + "\";");
	if (null!=request.getParameter("tx_reply"))
	  out.write("	frm.tx_reply.value = \"" + request.getParameter("tx_reply") + "\";");
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
                
        return true; 
      }
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Create Distribution List - Step 3 of 4</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setInputs()">
  <FORM METHOD="get" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain">
    <INPUT TYPE="hidden" NAME="n_domain">
    <INPUT TYPE="hidden" NAME="gu_workarea">
    <INPUT TYPE="hidden" NAME="tp_list">
    <INPUT TYPE="hidden" NAME="gu_query">        
    <CENTER>
    <TABLE>
      <TR><TD WIDTH="310px" CLASS="striptitle"><FONT CLASS="title1">Create List - Step 3 of 4</FONT></TD></TR>
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
    <INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" STYLE="width:100px" onClick="self.close()">&nbsp;<INPUT TYPE="button" CLASS="pushbutton" VALUE="<< Previous" STYLE="width:100px" onClick="window.history.back()">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Next >>" STYLE="width:100px">
    </CENTER>
  </FORM>
</BODY>
</HTML>