<%@ page import="com.knowgate.hipergate.Order,com.knowgate.hipergate.Product,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/reqload.jspf" %>
<% 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String tx_lines = request.getParameter("tx_lines");
  String gu_order = request.getParameter("gu_order");

  String sOpCode = gu_order.length()>0 ? "NODR" : "MODR";
  String aLines[], aLine[];
  int iUBound = 0;
  
  if (tx_lines.length()>0)
    aLines = Gadgets.split(tx_lines, '¨');      
  else
    aLines = null;
  
  JDCConnection oConn = GlobalDBBind.getConnection("order_edit_store");  
  
  Order oOrdr = new Order();
  
  try {
    loadRequest(oConn, request, oOrdr);

    oConn.setAutoCommit (false);
    
    oOrdr.store(oConn);
    
    if (gu_order.length()>0)
      oOrdr.removeAllProducts(oConn);
      
    if (null!=aLines) {
      
      for (int l=0; l<aLines.length; l++) {
      
        aLine = Gadgets.split(aLines[l], '`');
	iUBound = aLine.length;
		
  	oOrdr.addProduct(oConn, aLine[0], aLine[1], Float.parseFloat(aLine[2].replace(',','.')), null, null);  	
      
      } // next
      
    } // fi (null!=aLines)
    
    DBAudit.log(oConn, oOrdr.ClassId, sOpCode, id_user, oOrdr.getStringNull(DB.gu_order,"null"), null, 0, 0, null, null);
    
    oConn.commit();
    oConn.close("order_edit_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"order_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (ArrayIndexOutOfBoundsException e) {  
    disposeConnection(oConn,"order_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=Array index " + e.getMessage() + " is out of bounds " + String.valueOf(iUBound) + "&resume=_back"));
  }
  catch (NumberFormatException e) {  
    disposeConnection(oConn,"order_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }  

  if (null==oConn) return;
    
  oConn = null;
  
  // [~//Refrescar el padre y cerrar la ventana~]
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.opener.location.reload(true); window.document.location='order_edit.jsp?id_domain=" + request.getParameter("id_domain") + "&gu_workarea=" + request.getParameter("gu_workarea") + "&gu_order=" + oOrdr.getStringNull(DB.gu_order,"null") + "';<" + "/SCRIPT" +"></HEAD></HTML>");

%>