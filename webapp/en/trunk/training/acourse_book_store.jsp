<%@ page import="java.math.BigDecimal,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.misc.Gadgets,com.knowgate.acl.*,com.knowgate.crm.Contact,com.knowgate.crm.Company,com.knowgate.training.AcademicCourseBooking,com.knowgate.hipergate.Invoice,com.knowgate.hipergate.InvoicePayment,com.knowgate.hipermail.SendMail" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

  JDCConnection oConn = null;

  final String sUserId  = request.getParameter("userid");
  final String sAuthStr = request.getParameter("authstr");
  short iAuth = ACL.USER_NOT_FOUND;
  
  if (null!=sUserId && null!=sAuthStr) {
    oConn = GlobalDBBind.getConnection("acourse_book_store.autenticate", true);
    iAuth = ACL.autenticate(oConn, sUserId, sAuthStr, ACL.PWD_CLEAR_TEXT);
    oConn.close("acourse_book_store.autenticate");
  } else {
    iAuth = autenticateSession(GlobalDBBind, request, response);
  }

  if (iAuth<0) return;
  
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");

  String[] aDiscardList = Gadgets.split(request.getParameter("gu_discard"),',');
  String[] aInsertList = Gadgets.split(request.getParameter("checkeditems"),',');
  String[] aPayments = Gadgets.split(request.getParameter("payments"),'|');
  int nPayments = 0;
  if (null!=aPayments) nPayments = aPayments.length;

  boolean bCreateInvoice = nullif(request.getParameter("bo_invoice"),"0").equals("1");
  boolean bCreatePayments = nullif(request.getParameter("bo_payments"),"0").equals("1");
  short iInvoiceFor = Short.parseShort(nullif(request.getParameter("invoice_for"),String.valueOf(Contact.ClassId)));
  
  String tx_email_notify = nullif(request.getParameter("tx_email_notify"),"sergiom@knowgate.com");
  String gu_acourse = request.getParameter("gu_acourse");
  String id_classroom = request.getParameter("id_classroom");
  String gu_shop = request.getParameter("gu_shop");
  String dt_paid = request.getParameter("dt_paid");
  String tp_billing = request.getParameter("tp_billing");
  String nm_course = "";
  BigDecimal im_paid = null;
  if (request.getParameter("im_paid").length()>0)
    im_paid = new BigDecimal(request.getParameter("im_paid"));  
  short bo_confirmed = Short.parseShort(nullif(request.getParameter("bo_confirmed"),"0"));
  short bo_paid = Short.parseShort(nullif(request.getParameter("bo_paid"),"0"));
  short bo_waiting = Short.parseShort(nullif(request.getParameter("bo_waiting"),"0"));
  
  AcademicCourseBooking oACBk = new AcademicCourseBooking();
  Invoice oInvc = null;
  InvoicePayment oPay1 = null;
  InvoicePayment oPaym = null;
  
  try {
    oConn = GlobalDBBind.getConnection("acourse_book_store"); 
    oConn.setAutoCommit (false);

    if (null!=aInsertList) {
      for (int c=0; c<aInsertList.length; c++) {
        boolean bDiscard = false;
        oACBk.load(oConn, new Object[]{gu_acourse, aInsertList[c]});
        oACBk.replace(DB.gu_acourse, gu_acourse);
        oACBk.replace(DB.gu_contact, aInsertList[c]);
        oACBk.replace(DB.id_classroom, id_classroom);
        oACBk.replace(DB.bo_confirmed, bo_confirmed);
        oACBk.replace(DB.bo_paid, bo_paid);
        if (null!=im_paid) oACBk.replace(DB.im_paid, im_paid);
        if (dt_paid.length()>0)
          oACBk.replace(DB.dt_paid, oFmt.parse(dt_paid));
        else
        	oACBk.remove(DB.dt_paid);
        if (tp_billing.length()>0)
          oACBk.replace("tp_billing", tp_billing);
        else
        	oACBk.remove("tp_billing");
        oACBk.replace(DB.bo_waiting, bo_waiting);        
        if (null!=aDiscardList) {
          for (int d=0; d<aDiscardList.length; d++) {
            bDiscard = bDiscard || aDiscardList[d].equals(aInsertList[c]);
          } // next
        } // fi (aDiscardList)
        if (!bDiscard) {
          oACBk.store(oConn);
          if (bCreateInvoice) {
            oInvc = oACBk.getInvoice(oConn);
            if (oInvc==null) {
              if (Contact.ClassId==iInvoiceFor)
                oInvc = oACBk.createInvoiceForContact(oConn, gu_shop);
              else if (Company.ClassId==iInvoiceFor)
                oInvc = oACBk.createInvoiceForCompany(oConn, gu_shop);            	
              else
              	throw new InstantiationException("Could not instantiate class for Id. "+String.valueOf(iInvoiceFor));
              if (bCreatePayments) {							  
								nm_course = DBCommand.queryStr(oConn, "SELECT "+DB.nm_course+" FROM "+DB.k_academic_courses+" WHERE "+DB.gu_acourse+"='"+gu_acourse+"'");
								if (null!=im_paid) {
							    oPay1 = new InvoicePayment();
							    oPay1.put(DB.gu_invoice, oInvc.getString(DB.gu_invoice));
							    oPay1.put(DB.bo_active, (short)1);
							    oPay1.put(DB.id_currency, oInvc.getString(DB.id_currency));
							    oPay1.put(DB.im_paid, im_paid);
							    if (dt_paid.length()>0) 
							      oPay1.put(DB.dt_paid, oFmt.parse(dt_paid));
							    if (tp_billing.length()>0) oPay1.put(DB.tp_billing, tp_billing);
							    oPay1.put(DB.id_ref, Gadgets.generateRandomId(8, null, Character.UNASSIGNED));
							    oPay1.store(oConn);
							  } // fi
							  for (int p=0; p<nPayments; p++) {
							    oPaym = new InvoicePayment();
							    String[] aPayment = Gadgets.split(aPayments[p],';');
							    if (null==aPayment) throw new NullPointerException("Error parsing payments list "+request.getParameter("payments"));
							    oPaym.put(DB.gu_invoice, oInvc.getString(DB.gu_invoice));
							    oPaym.put(DB.bo_active, (short)1);
							    oPaym.put(DB.id_currency, oInvc.getString(DB.id_currency));
							    oPaym.put(DB.im_paid, new BigDecimal(aPayment[0]));
							    oPaym.put(DB.dt_payment, oFmt.parse(aPayment[1]));
							    if (tp_billing.length()>0) oPaym.put(DB.tp_billing, tp_billing);
							    oPaym.put(DB.id_ref, Gadgets.generateRandomId(8, null, Character.UNASSIGNED));
							    oPaym.store(oConn);
							  } // next
              } // fi (bCreatePayments)
            } else {
            	Contact oCntc = new Contact(oConn, aInsertList[c]);
              throw new SQLException("Another previous invoice already exists "+oCntc.getStringNull(DB.tx_name,"")+" "+oCntc.getStringNull(DB.tx_surname,"")+" Invoice Number "+String.valueOf(oInvc.getInt(DB.pg_invoice)));
            }
          }
        }
      } // next (c)
    } // fi (aInsertList)
    
    oConn.commit();
    oConn.close("acourse_book_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"acourse_book_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;

    if (null!=tx_email_notify && bCreateInvoice && bCreatePayments && null!=im_paid && oPay1!=null) {
      SendMail.send(GlobalDBBind.getProperties(),
								    "Gracias por inscribirse al curso "+nm_course+"\npara acceder al pago online de su reserva, haga click en:\nhttp://hipergate1.eoi.adminia.es:8080/eoi/pago1.jsp?i="+oInvc.getString(DB.gu_invoice)+"&p="+String.valueOf(oPay1.getInt(DB.pg_payment))+"&r="+oPay1.getStringNull(DB.id_ref,""),
								 	  "Acceso al pago online de su reserva",
								 	  "sergio.montoro@eoi.es",
								 	  "EOI",
								 	  "sergio.montoro@eoi.es",							     
							      new String[]{"sergiom@knowgate.com"});			     
    } // fi
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>