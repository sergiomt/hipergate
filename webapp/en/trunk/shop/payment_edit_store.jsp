<%@ page import="java.util.ArrayList,java.math.BigDecimal,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.Contact,com.knowgate.crm.Company,com.knowgate.hipergate.Address,com.knowgate.hipergate.Invoice,com.knowgate.hipergate.InvoicePayment,com.knowgate.hipergate.Product,com.knowgate.misc.Gadgets,com.knowgate.hipermail.SendMail" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "payment_edit_store";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  ArrayList oMailMsgs = null;
  
  SimpleDateFormat oDtFmt = new SimpleDateFormat("yyyy-MM-dd");

  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_invoice = request.getParameter("gu_invoice");
  String pg_payment = request.getParameter("pg_payment");
  String gu_contact = request.getParameter("gu_contact");
  String gu_company = request.getParameter("gu_company");
  String gu_product = request.getParameter("sel_product");
  String nm_client = request.getParameter("nm_client");
  String id_legal = request.getParameter("id_legal");
  String tp_client = request.getParameter("tp_client");
  String tx_email_to = request.getParameter("tx_email_to");
  String gu_address = null;
  BigDecimal im_paid = new BigDecimal(request.getParameter("im_paid"));

  boolean bIsNew = (gu_invoice.length()==0);
  String sOpCode = gu_invoice.length()>0 ? "NPAY" : "MPAY";
      
  Contact oCnt = null;
  Company oCmp = null;
  Address oAdr = null;
  Product oPrd = null;
  Invoice oInv = null;
  InvoicePayment oPay = null;

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

		oPrd = new Product(oConn, gu_product);
		
    oConn.setAutoCommit (false);
  
	  if (gu_contact.length()==0 && gu_company.length()==0) {

			String aClient[] = DBCommand.queryStrs(oConn, "SELECT "+DB.gu_contact+","+DB.gu_company+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND ("+DB.id_legal+"='"+id_legal+"' OR "+DB.sn_passport+"='"+id_legal+"')");
			if (null==aClient) aClient = new String[]{null,null};

	    if (aClient[0]!=null) {

	      oCnt = new Contact(oConn, aClient[0]);

				gu_address = DBCommand.queryStr(oConn, "SELECT "+DB.gu_address+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_contact+"='"+aClient[0]+"' AND "+DB.tx_email+"='"+tx_email_to+"'");

				if (gu_address==null) {
				  oAdr = new Address();
				  oAdr.put(DB.ix_address, 1);
	        oAdr.put(DB.gu_user, id_user);
	        oAdr.put(DB.gu_workarea, gu_workarea);
	        oAdr.put(DB.bo_active, (short) 1);
	        oAdr.put(DB.tx_email, tx_email_to);
					oAdr.store(oConn);					
					oCnt.addAddress(oConn, oAdr.getString(DB.gu_address));
				} else {
				  oAdr = new Address(oConn, gu_address);
				}

	    } else if (aClient[1]!=null) {

	      oCmp = new Company(oConn, aClient[1]);

				gu_address = DBCommand.queryStr(oConn, "SELECT "+DB.gu_address+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.gu_company+"='"+aClient[1]+"' AND "+DB.tx_email+"='"+tx_email_to+"'");

				if (gu_address==null) {
				  oAdr = new Address();
				  oAdr.put(DB.ix_address, 1);
	        oAdr.put(DB.gu_user, id_user);
	        oAdr.put(DB.gu_workarea, gu_workarea);
	        oAdr.put(DB.bo_active, (short) 1);
	        oAdr.put(DB.tx_email, tx_email_to);
					oAdr.store(oConn);					
					oCmp.addAddress(oConn, oAdr.getString(DB.gu_address));
				} else {
				  oAdr = new Address(oConn, gu_address);
				}

	    } else {

				if (tp_client.equals("Contact")) {
	        oCnt = new Contact();
	        oCnt.put(DB.gu_writer, id_user);
	        oCnt.put(DB.gu_workarea, gu_workarea);
	        oCnt.put(DB.bo_restricted, (short) 0);
	        oCnt.put(DB.bo_private, (short) 0);
	        oCnt.put(DB.bo_change_pwd, (short) 1);
	        oCnt.put(DB.nu_notes, 0);
	        oCnt.put(DB.nu_attachs, 0);
	        oCnt.put(DB.sn_passport, id_legal);
					String[] aNameSurname = Gadgets.split2(nm_client, ' ');
	        oCnt.put(DB.tx_name, aNameSurname[0]);
					if (aNameSurname.length>1) oCnt.put(DB.tx_surname, aNameSurname[1]);
				  oCnt.store(oConn);

				  oAdr = new Address();
				  oAdr.put(DB.ix_address, 1);
	        oAdr.put(DB.gu_user, id_user);
	        oAdr.put(DB.gu_workarea, gu_workarea);
	        oAdr.put(DB.bo_active, (short) 1);
	        oAdr.put(DB.tx_email, tx_email_to);
					oAdr.store(oConn);
					
					oCnt.addAddress(oConn, oAdr.getString(DB.gu_address));
					
				}	else if (tp_client.equals("Company")) {
					oCmp = new Company();
	        oCmp.put(DB.gu_workarea, gu_workarea);
	        oCnt.put(DB.bo_restricted, (short) 0);
	        oCmp.put(DB.nm_legal, nm_client);
	        oCmp.put(DB.nm_commercial, nm_client);
	        oCmp.put(DB.id_legal, id_legal);
				  oCmp.store(oConn);

				  oAdr = new Address();
				  oAdr.put(DB.ix_address, 1);
	        oAdr.put(DB.gu_user, id_user);
	        oAdr.put(DB.gu_workarea, gu_workarea);
	        oAdr.put(DB.bo_active, (short) 1);
	        oAdr.put(DB.tx_email, tx_email_to);
					oAdr.store(oConn);

					oCmp.addAddress(oConn, oAdr.getString(DB.gu_address));
				}
	    }
	  } // fi

    float pct_tax_rate;
    short is_tax_included;
    
    if (oPrd.isNull(DB.pct_tax_rate))
      pct_tax_rate = 0f;
    else 
      pct_tax_rate = oPrd.getFloat(DB.pct_tax_rate);
    
    if (oPrd.isNull(DB.is_tax_included))
      is_tax_included = (short) 0;
    else
      is_tax_included = oPrd.getShort(DB.is_tax_included);
       
  	oInv = new Invoice();
		oPay = new InvoicePayment();

    if (bIsNew) {

			gu_invoice = Gadgets.generateUUID();
			oInv.put(DB.gu_invoice,gu_invoice);
			oInv.put(DB.id_legal, id_legal);
	    oInv.put(DB.bo_active, (short) 1);
	    oInv.put(DB.gu_workarea, gu_workarea);
	    oInv.put(DB.pg_invoice, Invoice.nextVal(oConn, gu_workarea));
	    oInv.put(DB.id_currency, request.getParameter("id_currency"));
	    oInv.put(DB.gu_shop, oPrd.getShop(oConn).getString(DB.gu_shop));
	    if (request.getParameter("dt_payment").length()>0)
	      oInv.put(DB.dt_payment, request.getParameter("dt_payment"), oDtFmt);
	    if (request.getParameter("dt_paid").length()>0) {
	      oInv.put(DB.dt_paid, request.getParameter("dt_paid"), oDtFmt);
	      oInv.put(DB.im_paid, im_paid);	      
	    }
	    oInv.put(DB.tp_billing, request.getParameter("sel_type"));
	    oInv.put(DB.im_total, im_paid);	      
	    if (request.getParameter("tx_email_to").length()>0) oInv.put(DB.tx_email_to, request.getParameter("tx_email_to"));
	    if (request.getParameter("gu_company").length()>0) oInv.put(DB.gu_company, request.getParameter("gu_company"));
	    if (request.getParameter("gu_contact").length()>0) oInv.put(DB.gu_contact, request.getParameter("gu_contact"));
  	  oInv.put(DB.nm_client, nm_client);
  	  if (oAdr!=null) oInv.put(DB.gu_bill_addr, oAdr.getString(DB.gu_address));
  	  oInv.put(DB.de_order, Gadgets.left(oPrd.getString(DB.nm_product)+" / "+nm_client,100));
  	  oInv.put(DB.tx_comments, request.getParameter("tx_comments"));
			oInv.store(oConn);
      oInv.addLine (oConn, oPrd.getDecimal(DB.pr_list), 1f, null, im_paid,
                    pct_tax_rate, is_tax_included, oPrd.getString(DB.nm_product),
                    oPrd.getString(DB.gu_product), null, null, null);

			oPay.put(DB.bo_active, (short)1);
			oPay.put(DB.id_currency, oInv.getString(DB.id_currency));
			oPay.put(DB.im_paid, im_paid);
			if (request.getParameter("dt_paid").length()>0) oPay.put(DB.dt_paid, request.getParameter("dt_paid"), oDtFmt);
      oPay.put(DB.tp_billing, request.getParameter("sel_type"));
			oPay.put(DB.id_ref, Gadgets.generateRandomId(8, null, Character.UNASSIGNED));
  	  oPay.put(DB.nm_client, nm_client);
			oPay.put(DB.gu_invoice, gu_invoice);
			oPay.store(oConn);

    } else {

  	  if (!oInv.load(oConn, new Object[]{gu_invoice}))
  	    throw new SQLException("Invoice "+gu_invoice+" not found");
  	  
      oInv.storeLine(oConn, 1, oPrd.getDecimal(DB.pr_list), 1f,  null, im_paid,
                     pct_tax_rate, is_tax_included, oPrd.getString(DB.nm_product),
                     oPrd.getString(DB.gu_product), null, null, null);

		  if (!oPay.load(oConn, new Object[]{gu_invoice,new Integer(pg_payment)}))
  	    throw new SQLException("Payment "+gu_invoice+":"+pg_payment+" not found");
		  
			oPay.replace(DB.id_currency, oInv.getString(DB.id_currency));
			oPay.replace(DB.im_paid, im_paid);
			if (request.getParameter("dt_paid").length()>0) oPay.put(DB.dt_paid, request.getParameter("dt_paid"), oDtFmt);
      oPay.replace(DB.tp_billing, request.getParameter("sel_type"));
  	  oPay.put(DB.nm_client, nm_client);			
			oPay.store(oConn);		  
  	}
    
    DBAudit.log(oConn, InvoicePayment.ClassId, sOpCode, id_user, gu_invoice, pg_payment, 0, 0, Gadgets.left(oPrd.getString(DB.nm_product)+"/"+nm_client,100), im_paid.toString());

    if (nullif(request.getParameter("chk_invite")).equals("1")) {
      String sUrl = "https://www.eoi.es/pagoonline/pago1.jsp?i="+oInv.getString(DB.gu_invoice)+"&p="+String.valueOf(oPay.getInt(DB.pg_payment))+"&r="+oPay.getStringNull(DB.id_ref,"")+"&c="+oPrd.getString(DB.gu_product);
      String sHtml = "<html><body><table cellspacing=\"0\" cellpadding=\"0\" align=\"center\" width=\"626\" border=\"0\"><tr><td><img src=\""+Gadgets.chomp(GlobalDBBind.getProperty("imageserver"),"/")+"images/eoi/EOI313x77.gif\" width=\"313\" height=\"77\" border=\"0\" /></td><td width=\"100%\" bgcolor=\"darkgray\"></td></tr><tr><td colspan=\"2\"><font face=\"Verdana,Arial,Helvetica,sans-serif\" size=\"2\"><br/>Tengo el placer de ponerme en contacto contigo para confirmarte la recepci&oacute;n de tu<br/>peticion de reserva de plaza.<br/><br/>Para garantizarte una plaza "+oPrd.getString(DB.nm_product)+", debes proceder al pago online<br/>del importe de la reserva con n&uacute;mero de referencia <b>"+oPay.getString(DB.id_ref)+"</b>, el cual puedes efectuar pinchando <a href=\""+sUrl+"\">aqu&iacute;</a>.<br/><br/>En nombre de EOI Escuela de Negocios te doy la bienvenida a la escuela y te reitero<br/>nuestro agradecimiento por la confianza que depositas en nuestra instituci&oacute;n,<br/>que estamos seguros redundar&aacute; muy positivamente en tu formaci&oacute;n y desarrollo profesional. <br/><br/>En breve, desde la Direcci&oacute;n del programa se pondr&aacute;n en contacto contigo para ampliar cualquier otra informaci&oacute;n que necesites.<br/><br/><a href=\""+sUrl+"\"><big>Proceder al pago de la reserva</big></a><br/><br/>Sin otro particular,  y a la espera de poder saludarte personalmente,<br/>te env&iacute;o un cordial saludo,<br/><br/><b>Rosa Fern&aacute;ndez Pe&ntilde;uelas</b><br/>Directora del Dpto. de Admisiones<br/><a href=\"mailto:informacion@eoi.es\">informacion@eoi.es</a><br/>Telf. 91 349 56 00</font></td></tr></table></body></html>";
      String sPlain = "Gracias por inscribirte a "+oPrd.getString(DB.nm_product)+"\npara acceder al pago online de tu reserva, haz click en:\n"+sUrl;

      oMailMsgs = SendMail.send(GlobalDBBind.getProperties(),
      					    sHtml, sPlain, "ISO-8859-1", 
								 	  "Acceso al pago online de tu reserva",
								 	  "informacion@eoi.es",
								 	  "EOI - Admisiones",
								 	  "informacion@eoi.es",							     
							      new String[]{request.getParameter("tx_email_to")});

    } // fi

    oConn.commit();
    oConn.close(PAGE_NAME);

  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  if (oMailMsgs!=null) {
    if (((String) oMailMsgs.get(0)).indexOf("Exception")!=-1)
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=MessagingException&desc=" + ((String) oMailMsgs.get(0)) + "&resume=_close"));
    return;
  }
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>