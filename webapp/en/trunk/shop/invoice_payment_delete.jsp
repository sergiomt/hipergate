<%@ page import="com.knowgate.hipergate.InvoicePayment,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_invoice = request.getParameter("gu_invoice");
  int pg_payment = Integer.parseInt(request.getParameter("pg_payment"));
    
  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("invoice_payment_delete");

    oCon.setAutoCommit (false);
  
      InvoicePayment oPay = new InvoicePayment();
      oPay.load(oCon, new Object[]{gu_invoice new Integer(pg_payment)});
      
      oPay.delete(oCon);

      DBAudit.log(oCon, InvoicePayment.ClassId, "DPAY", id_user, gu_invoice, null, pg_payment, 0, null, null);
  
    oCon.commit();
    oCon.close("invoice_payment_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"invoice_payment_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  response.sendRedirect (response.encodeRedirectUrl ("invoice_payments.jsp?gu_invoice="+gu_invoice+"&gu_workarea="+request.getParameter("gu_workarea")));
 %>