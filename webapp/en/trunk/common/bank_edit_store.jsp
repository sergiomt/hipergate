<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.BankAccount" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String linktable = request.getParameter("linktable");
  String linkfield = request.getParameter("linkfield");
  String linkvalue = request.getParameter("linkvalue");  
  String nu_bank_acc = request.getParameter("nu_bank_acc");

  BankAccount oAcc = new BankAccount();

  JDCConnection oConn = null;
  Statement oStmt;
  
  try {
    oConn = GlobalDBBind.getConnection("bank_edit_store"); 
  
    loadRequest(oConn, request, oAcc);

    oConn.setAutoCommit (false);
    
    oAcc.store(oConn);

    // Borrar la cuenta anterior y asociar la nueva    
    if (linktable.length()>0) {
      oStmt = oConn.createStatement();
      oStmt.execute("DELETE FROM " + linktable + " WHERE " + DB.nu_bank_acc + "='" + oAcc.getString(DB.nu_bank_acc) + "' AND " + DB.gu_workarea + "='" + gu_workarea + "' AND " + linkfield + "='" + linkvalue +"'");
      oStmt.close();

      oStmt = oConn.createStatement();
      oStmt.execute("INSERT INTO " + linktable + "(" + DB.nu_bank_acc + "," + DB.gu_workarea + "," + linkfield + ") VALUES ('" + oAcc.getString(DB.nu_bank_acc) + "','" + gu_workarea + "','" + linkvalue + "')");
      oStmt.close();            
    }

    oConn.commit();
    oConn.close("bank_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"bank_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"bank_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>