<%@ page import="com.knowgate.hipergate.Invoice,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  String id_status = nullif(request.getParameter("id_status"));
  String id_payment = nullif(request.getParameter("id_payment"));
  
  JDCConnection oCon = null;
  PreparedStatement oStm = null;
  
  try {
    oCon = GlobalDBBind.getConnection("invoice_delete");
    
    if (id_status.length()>0 && id_payment.length()>0)
      oStm = oCon.prepareStatement("UPDATE "+DB.k_invoices+" SET "+DB.id_status+"='"+id_status+"', "+DB.id_pay_status+"='"+id_payment+"' WHERE "+DB.gu_invoice+"=?");
    else if (id_status.length()>0)
      oStm = oCon.prepareStatement("UPDATE "+DB.k_invoices+" SET "+DB.id_status+"='"+id_status+"' WHERE "+DB.gu_invoice+"=?");
    else if (id_payment.length()>0)
      oStm = oCon.prepareStatement("UPDATE "+DB.k_invoices+" SET "+DB.id_pay_status+"='"+id_payment+"' WHERE "+DB.gu_invoice+"=?");
    
    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
      oStm.setString(1, a_items[i]);
      oStm.executeUpdate();
    } // next ()
  
    oStm.close();

    oCon.commit();
    oCon.close("invoice_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"object_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='invoice_list.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>