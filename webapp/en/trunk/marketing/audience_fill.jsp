<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.Types,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  String gu_company = null;
  String gu_contact = request.getParameter("gu_contact");
  String gu_address = request.getParameter("gu_address");
  String gu_workarea = request.getParameter("gu_workarea");
  
  String tx_name = "", tx_surname = "", nm_legal = "", sn_passport = "", tx_email = "", work_phone = "", mov_phone = "", gu_sales_man = "";

  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
    
  try {  
    oConn = GlobalDBBind.getConnection("audience_fill");  
    
    oStmt = oConn.prepareStatement("SELECT "+DB.gu_contact+","+DB.gu_company+","+DB.gu_address+","+DB.tx_name+","+DB.tx_surname+","+DB.nm_legal+","+DB.sn_passport+","+DB.tx_email+","+DB.work_phone+","+DB.mov_phone+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"=? AND "+(gu_address==null ? DB.gu_contact+"=?" : DB.gu_address+"=?"));
    oStmt.setString(1, gu_workarea);
    oStmt.setString(2, gu_address==null ? gu_contact : gu_address);
    oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      gu_contact = nullif(oRSet.getString(1));
      gu_company = nullif(oRSet.getString(2));
      gu_address = nullif(oRSet.getString(3));
      tx_name    = nullif(oRSet.getString(4));
      tx_surname = nullif(oRSet.getString(5));
      nm_legal   = nullif(oRSet.getString(6));
      sn_passport= nullif(oRSet.getString(7));
      tx_email   = nullif(oRSet.getString(8));
      work_phone = nullif(oRSet.getString(9));
      mov_phone  = nullif(oRSet.getString(10));
    }
    oRSet.close();
    oStmt.close();
    
    if (gu_contact!=null) {
      oStmt = oConn.prepareStatement("SELECT "+DB.gu_sales_man+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_contact+"=?");
      oStmt.setString(1, gu_workarea);
      oStmt.setString(2, gu_contact);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        gu_sales_man = nullif(oRSet.getString(1));
      }
      oRSet.close();
      oStmt.close();
    }

    if (gu_company!=null && nm_legal.length()==0) {
      oStmt = oConn.prepareStatement("SELECT "+DB.nm_legal+" FROM "+DB.k_companies+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_company+"=?");
      oStmt.setString(1, gu_workarea);
      oStmt.setString(2, gu_company);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        nm_legal = nullif(oRSet.getString(1));
      }
      oRSet.close();
      oStmt.close();
    }
    
    oConn.close("audience_fill");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("audience_fill");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (oConn==null) return;
  oConn = null;

%><HTML>
<HEAD>
<TITLE>Wait...</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
<SCRIPT TYPE="text/javascript">
<!--
  function setCombos() {
    var opt;
    var frm = parent.msgslist.document.forms[0];
    
		frm.gu_contact.value = "<%=nullif(gu_contact)%>";
		frm.gu_company.value = "<%=nullif(gu_company)%>";
		frm.gu_address.value = "<%=nullif(gu_address)%>";
		frm.tx_name.value = "<%=tx_name%>";
		frm.tx_surname.value = "<%=tx_surname%>";
		if (frm.nm_legal.value.length==0) frm.nm_legal.value = "<%=nm_legal%>";
		if (frm.sn_passport.value.length==0) frm.sn_passport.value = "<%=sn_passport%>";
		if (frm.tx_email.value.length==0) frm.tx_email.value = "<%=tx_email%>";
		if (frm.work_phone.value.length==0) frm.work_phone.value = "<%=work_phone%>";
		if (frm.mov_phone.value.length==0) frm.mov_phone.value = "<%=mov_phone%>";
		if (frm.gu_sales_man.options.selectedIndex<=0) setCombo(frm.gu_sales_man,"<%=gu_sales_man%>");
    self.document.location = "../blank.htm";
  } // setCombo()    
//-->
</SCRIPT>
</HEAD>
<BODY onload="setCombos()"></BODY>
</HTML>