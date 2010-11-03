<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
  InvoicePayment oPay = new InvoicePayment();
  
  try {
    oCon = GlobalDBBind.getConnection("payment_delete");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
      oPay.replace(DB.gu_invoice, a_items[i].substring(0,a_items[i].lastIndexOf('_'))); 
      oPay.replace(DB.pg_payment, Integer.parseInt(a_items[i].substring(a_items[i].lastIndexOf('_')+1)));
      oPay.delete(oCon);
      DBAudit.log(oCon, InvoicePayment.ClassId, "DPAY", id_user, a_items[i].substring(0,a_items[i].lastIndexOf('_')), String.valueOf(a_items[i].substring(a_items[i].lastIndexOf('_')+1)), 0, 0, null, null);
    } // next ()
  
    oCon.commit();
    oCon.close("payment_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"payment_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='payment_list.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>