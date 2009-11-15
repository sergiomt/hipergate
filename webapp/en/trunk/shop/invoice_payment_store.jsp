<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.InvoicePayment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
/*
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "invoice_payment_store";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);
  String gu_invoice = request.getParameter("gu_invoice") ;
  String pg_payment = request.getParameter("pg_payment") ;
  if (pg_payment==null) pg_payment = "";
  boolean bAlreadyExists = (pg_payment.length()!=0);

  InvoicePayment oPay = new InvoicePayment();

  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

    oConn.setAutoCommit (false);

	  if (bAlreadyExists) {
      InvoicePayment oPrev = new InvoicePayment();
      oPrev.load(oConn, new Object[]{gu_invoice, new Integer(pg_payment)});
      if (!oPrev.isNull(DB.im_paid)) {
        oStmt = oConn.prepareStatement("UPDATE "+DB.k_invoices+" SET "+DB.im_paid+"="+DBBind.Functions.ISNULL+"("+DB.im_paid+",0)-? WHERE "+DB.gu_invoice+"=?");
        oStmt.setBigDecimal(1, oPrev.getDecimal(DB.im_paid));
        oStmt.setString(2, gu_invoice);
        oStmt.executeUpdate();
        oStmt.close();
      }
    }
    
    loadRequest(oConn, request, oPay);
    
    oPay.store(oConn);

		if (!oPay.isNull(DB.im_paid)) {
      oStmt = oConn.prepareStatement("UPDATE "+DB.k_invoices+" SET "+DB.im_paid+"="+DBBind.Functions.ISNULL+"("+DB.im_paid+",0)+? WHERE "+DB.gu_invoice+"=?");
      oStmt.setBigDecimal(1, oPay.getDecimal(DB.im_paid));
      oStmt.setString(2, gu_invoice);
      oStmt.executeUpdate();
      oStmt.close();
    }

    DBAudit.log(oConn, oPay.ClassId, bAlreadyExists ? "MPAY" : "NPAY", id_user, oPay.getString(DB.gu_invoice), null, oPay.getInt(DB.pg_payment), 0, request.getParameter("dt_payment")+" "+request.getParameter("nm_client"), request.getParameter("im_paid"));

    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("invoice_payments.jsp?gu_invoice="+request.getParameter("gu_invoice")+"&gu_workarea="+request.getParameter("gu_workarea")));
%>