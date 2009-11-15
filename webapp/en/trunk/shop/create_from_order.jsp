<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Order,com.knowgate.hipergate.OrderLine,com.knowgate.hipergate.DespatchAdvice,com.knowgate.hipergate.Invoice,com.knowgate.hipergate.Product" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_domain = getCookie (request, "domainid", null);
  String gu_workarea = getCookie (request, "workarea", null);

  String gu_order = request.getParameter("gu_order");
  short doctype = Short.parseShort(request.getParameter("doctype"));

  JDCConnection oConn = null;  
  String sGuNewDoc = null;
  
  try {
    oConn = GlobalDBBind.getConnection("create_from_order");

    Order oOrd = new Order();

    if (!oOrd.load(oConn, new Object[]{gu_order})) {
      throw new SQLException("Order "+gu_order+" not found");
    }

    OrderLine oLin = oOrd.getLine(oConn, 1);
    if (oLin==null) {
      oOrd.put(DB.id_currency, "999");
    } else {
      if (oLin.isNull(DB.gu_product)) {
        oOrd.put(DB.id_currency, "999");      
      } else {
	Product oPrd = new Product(oConn, oLin.getString(DB.gu_product));
	if (oPrd.isNull(DB.id_currency))
          oOrd.put(DB.id_currency, "999");
	else
          oOrd.put(DB.id_currency, oPrd.getString(DB.id_currency));	      
      }   
    }

    oConn.setAutoCommit(false);
    
    switch (doctype) {
      case DespatchAdvice.ClassId:
        sGuNewDoc = oOrd.createDespatchAdvice(oConn,true).getString(DB.gu_despatch);
        response.sendRedirect (response.encodeRedirectUrl ("despatch_edit_f.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_invoice="+sGuNewDoc));
        break;
      case Invoice.ClassId:
        sGuNewDoc = oOrd.createInvoice(oConn).getString(DB.gu_invoice);
        response.sendRedirect (response.encodeRedirectUrl ("invoice_edit_f.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_invoice="+sGuNewDoc));
        break;
      default:
        throw new SQLException("Unrecognized class " + String.valueOf(doctype));
    }
    
    oConn.commit();
      
    oConn.close("create_from_order");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"create_from_order");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
%>