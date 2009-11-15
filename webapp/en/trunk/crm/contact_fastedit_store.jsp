<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.ContactLoader,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = request.getParameter("gu_workarea");
  
  int iMode, iFlags ;
  if (request.getParameter("id_mode").equals("append"))
    iMode = ContactLoader.MODE_APPEND;
  else if (request.getParameter("id_mode").equals("appendupdate"))
    iMode = ContactLoader.MODE_APPENDUPDATE;
  else {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalArgumentException&desc=Insert or update mode not valid&resume=_back"));  
    return;
  }

  final int iDefaultFlags = iMode|ContactLoader.WRITE_CONTACTS|ContactLoader.NO_DUPLICATED_MAILS|(nullif(request.getParameter("chk_dup_names")).equals("1") ? ContactLoader.NO_DUPLICATED_NAMES : 0)|(nullif(request.getParameter("chk_dup_emails")).equals("1") ? ContactLoader.NO_DUPLICATED_MAILS : 0);

  int r=0;
  String s, v;
  int nRows = Integer.parseInt(request.getParameter("nu_rows"));
  String[] aDesc = Gadgets.split(request.getParameter("tx_descriptor"), new char[]{'\t','|',',',';'});
  int iDesc = aDesc.length;
  ContactLoader oLoader = null;
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("contact_fastedit_store"); 
  
    oLoader = new ContactLoader(oConn);
  
    oConn.setAutoCommit (false);
  
    while (r<nRows) {
      s = String.valueOf(r);
      if (request.getParameter("tx_name"+s).length()>0 || request.getParameter("tx_surname"+s).length()>0) {
        for (int c=0; c<iDesc; c++) {
          v = request.getParameter(aDesc[c]+s);
          if (null!=v)
            if (v.length()>0)
              oLoader.put(aDesc[c], v);
        } // next (c)
        
        iFlags = iDefaultFlags;        
        if (nullif(request.getParameter("nm_legal"+s)).length()>0)
	  iFlags |= ContactLoader.WRITE_COMPANIES;
        if (nullif(request.getParameter("nm_street"+s)).length()>0 || nullif(request.getParameter("zipcode"+s)).length()>0 || nullif(request.getParameter("id_country"+s)).length()>0 || nullif(request.getParameter("direct_phone"+s)).length()>0 || nullif(request.getParameter("tx_email"+s)).length()>0)
	  iFlags |= ContactLoader.WRITE_ADDRESSES;

        oLoader.store(oConn, gu_workarea, iFlags);        

        oLoader.setAllColumnsToNull();
      } // fi (tx_name!="" || tx_surname!="")
      r++;
    } // wend

    oConn.commit();
    oConn.close("contact_fastedit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=Row " + String.valueOf(r+1) + " " + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IllegalArgumentException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalArgumentException&desc=Row " + String.valueOf(r+1) + " " + e.getMessage() + "&resume=_back"));
  }
  catch (ArrayIndexOutOfBoundsException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=Row " + String.valueOf(r+1) + " " + e.getMessage() + "&resume=_back"));
  }
  /*
  catch (NullPointerException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=Row " + String.valueOf(r+1) + e.getMessage() + "&resume=_back"));
  }
  */
  catch (ClassCastException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassCastException&desc=Row " + String.valueOf(r+1) + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;  
  oConn = null;

%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY TOPMARGIN="32" MARGINHEIGHT="32">
  <TABLE ALIGN="CENTER" WIDTH="90%" BGCOLOR="#000080">
    <TR><TD>
      <FONT FACE="Arial,Helvetica,sans-serif" COLOR="white" SIZE="2"><B><% out.write("Operación Completada"); %></B></FONT>
    </TD></TR>
    <TR><TD>
      <TABLE WIDTH="100%" BGCOLOR="#FFFFFF">
        <TR><TD>
          <TABLE BGCOLOR="#FFFFFF" BORDER="0" CELLSPACING="8" CELLPADDING="8">
            <TR VALIGN="middle">
              <TD><IMG SRC="../images/images/chequeredflag.gif" WIDTH="40" HEIGHT="38" BORDER="0" ALT="Chequered Flag"></TD>
              <TD><FONT CLASS="textplain"><% out.write(String.valueOf(nRows)+" Rows successfully saved"); %></FONT></TD>
	    </TR>
	  </TABLE>
        </TD></TR>
        <TR><TD ALIGN="center">
          <FORM>
            <INPUT TYPE="button" CLASS="pushbutton" VALUE="Back" onclick="window.location.href='contact_fastedit.jsp'">
          </FORM>
        </TD></TR>
      </TABLE>
    </TD></TR>    
  </TABLE>
</BODY>
</HTML>