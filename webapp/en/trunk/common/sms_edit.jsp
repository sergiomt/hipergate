<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "sms_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = getCookie(request,"workarea",null);
  String gu_user = getCookie(request,"userid",null); 
  
  String nu_msisdn  = nullif(request.getParameter("nu_msisdn"));
  String gu_address = nullif(request.getParameter("gu_address"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String gu_company = nullif(request.getParameter("gu_company"));

  if (GlobalDBBind.getProperty("smsprovider","").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error SMS Provider not found&desc=No SMS provider class found at property smsprovider of hipergate.cnf&resume=_close"));
    return;
  } // fi
  if (GlobalDBBind.getProperty("smsaccount","").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error SMS Account not found&desc=No SMS account class found at property smsaccount of hipergate.cnf&resume=_close"));
    return;
  } // fi
  if (GlobalDBBind.getProperty("smspassword","").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error SMS Password not found&desc=No SMS password class found at property smsaccount of hipergate.cnf&resume=_close"));
    return;
  } // fi

  JDCConnection oConn = null;

	String sFrom = "";    

  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

		DBSubset oFrom = new DBSubset(DB.k_sms_msisdn, DB.nu_msisdn, DB.bo_validated+"<>0 AND "+DB.gu_workarea+"=?", 10);
    int nFrom = oFrom.load(oConn, new Object[]{gu_workarea});
    for (int f=0; f<nFrom; f++) sFrom += "<OPTION VALUE=\""+oFrom.getString(0,f)+"\">"+oFrom.getString(0,f)+"</OPTION>";

    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;  
  oConn = null;  

%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Send SMS</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--      
      // ------------------------------------------------------

      function validate() {
        var frm = window.document.forms[0];
        
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Send SMS</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="sms_send.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=gu_user%>">
    <INPUT TYPE="hidden" NAME="gu_address" VALUE="<%=gu_address%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=gu_company%>">

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Sender</FONT></TD>
            <TD ALIGN="left" WIDTH="270"><SELECT NAME="nu_from"><%=sFrom%></SELECT>&nbsp;<A HREF="sms_from_list.jsp" TITLE="Editar Remitentes"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Editar Remitentes"></A></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">MSISDN</FONT></TD>
            <TD ALIGN="left" WIDTH="270"><INPUT TYPE="text" NAME="nu_msisdn" MAXLENGTH="20" SIZE="16" VALUE="<%=nu_msisdn%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formstrong">Text</FONT></TD>
            <TD ALIGN="left" WIDTH="270"><TEXTAREA NAME="tx_msg" ROWS="6"></TEXTAREA></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Send" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="if (window.history.length==0) window.close(); else window.history.back()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>
