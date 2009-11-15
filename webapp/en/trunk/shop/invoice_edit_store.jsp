<%@ page import="java.math.BigDecimal,com.knowgate.hipergate.Invoice,com.knowgate.hipergate.Product,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><% 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String tx_lines = request.getParameter("tx_lines");
  String gu_invoice = request.getParameter("gu_invoice");
  String im_taxes = request.getParameter("im_taxes");

  String sOpCode = gu_invoice.length()>0 ? "NODR" : "MODR";
  String aLines[], aLine[];
  int nLines = 0;
  int iUBound = 0;
  
  if (tx_lines.length()>0)
    aLines = Gadgets.split(tx_lines, '¨');      
  else
    aLines = null;
  
  JDCConnection oConn = GlobalDBBind.getConnection("invoice_edit_store");  
  
  Invoice oOrdr = new Invoice();
  
  float fQuantity;
  BigDecimal dQuantity, dImTaxes, dImSubtotal, dPrTotal, dPrSale, dPctTax;
  
  try {
    loadRequest(oConn, request, oOrdr);

    dImSubtotal = new BigDecimal(0d);
    dImTaxes = new BigDecimal(0d);
    
    if (null!=aLines) nLines = aLines.length;
    
    if (im_taxes.length()==0) {      
      for (int l=nLines-1; l>=0; l--) {
        aLine = Gadgets.split(aLines[l], '`');
        dQuantity = new BigDecimal(aLine[2].replace(',','.'));
        dPrSale = new BigDecimal(aLine[3].replace(',','.'));
        dPctTax = new BigDecimal(aLine[4].replace(',','.'));
        dImSubtotal = dImSubtotal.add(dPrSale.multiply(dQuantity));
        dImTaxes = dImTaxes.add(dPrSale.multiply(dQuantity).multiply(dPctTax));
      }
      oOrdr.replace (DB.im_taxes, dImTaxes);
    } else {
      for (int l=nLines-1; l>=0; l--) {
        aLine = Gadgets.split(aLines[l], '`');
        dQuantity = new BigDecimal(aLine[2].replace(',','.'));
        dPrSale = new BigDecimal(aLine[3].replace(',','.'));
        dImSubtotal = dImSubtotal.add(dPrSale.multiply(dQuantity));
      }    
    }

    oOrdr.put (DB.im_subtotal, dImSubtotal);

    oConn.setAutoCommit (false);
    
    oOrdr.store(oConn);
    
    if (gu_invoice.length()>0)
      oOrdr.removeAllProducts(oConn);
      
    if (null!=aLines) {

      for (int l=0; l<nLines; l++) {
      
        aLine = Gadgets.split(aLines[l], '`');
	iUBound = aLine.length;
		
	fQuantity = Float.parseFloat(aLine[2].replace(',','.'));
	dQuantity = new BigDecimal(fQuantity);
	dPrSale = new BigDecimal(aLine[3].replace(',','.'));
	dPctTax = new BigDecimal(aLine[4].replace(',','.'));

	dPrTotal = dPrSale.add(dPrSale.multiply(dPctTax)).multiply(dQuantity);
	
	if (aLine[0].startsWith("null_")) {
	  oOrdr.addProduct(oConn, null, aLine[1], dPrSale, fQuantity, dPrTotal, dPctTax.floatValue(), (short) (dPctTax.signum()==0 ? 1 : 0), null, null);
	} else {
	  oOrdr.addProduct(oConn, aLine[0], aLine[1], dPrSale, fQuantity, dPrTotal, dPctTax.floatValue(), (short) (dPctTax.signum()==0 ? 1 : 0), null, null);
	}

      } // next
      
    } // fi (null!=aLines)
    
    oConn.commit();
    oConn.close("invoice_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"invoice_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (ArrayIndexOutOfBoundsException e) {  
    disposeConnection(oConn,"invoice_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=Array index " + e.getMessage() + " is out of bounds " + String.valueOf(iUBound) + "&resume=_back"));
  }
  catch (NumberFormatException e) {  
    disposeConnection(oConn,"invoice_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }  

  if (null==oConn) return;
    
  oConn = null;
  
  // //Refrescar el padre y cerrar la ventana
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.opener.location.reload(true); window.document.location='invoice_edit.jsp?id_domain=" + request.getParameter("id_domain") + "&gu_workarea=" + request.getParameter("gu_workarea") + "&gu_invoice=" + oOrdr.getStringNull(DB.gu_invoice,"null") + "';<" + "/SCRIPT" +"></HEAD></HTML>");

%>