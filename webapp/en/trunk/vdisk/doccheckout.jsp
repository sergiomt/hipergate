<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.Product,com.knowgate.hipergate.Category" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_user = getCookie (request, "userid", null);
  String gu_item = request.getParameter("gu_item");
  String tp_item = request.getParameter("tp_item");
  String gu_category = request.getParameter("gu_category");

  JDCConnection oConn = null;  
  Category oCatg = new Category(gu_category);
  int iACLMask = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("doccheckout");
    
    oConn.setAutoCommit(false);
    
    iACLMask = oCatg.getUserPermissions(oConn,id_user);

    if ((iACLMask&ACL.PERMISSION_MODIFY)==0) {
      throw new SecurityException(String.valueOf(iACLMask)+" You don't have enought access rights to check-in this document");
    }
    
    if (tp_item.equals("category")) {
		  oCatg.checkOut(oConn, id_user);
    } else if (tp_item.equals("product")) {
		  Product oProd = new Product(oConn, gu_item);
		  oProd.checkOut(oConn, id_user);
    } else {
      throw new IllegalArgumentException("Unrecognized item type "+tp_item);    
    }

    oConn.commit();
      
    oConn.close("doccheckout");
    out.write("SUCCESS\n1.0:OK");
  }
  catch (Exception e) {
    disposeConnection(oConn,"doccheckout");
    oConn = null;
    out.write("ERROR\n"+e.getClass().getName()+" "+e.getMessage());
  }  
%>