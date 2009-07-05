<%@ page import="java.io.IOException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser,com.knowgate.hipergate.Address" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%   
   
  String sTxEmail = request.getParameter("email");
  String sGuWorkA = request.getParameter("workarea");

  if (null==sTxEmail) {
    out.write ("error NullPointerException parameter email is required");
    return;
  }

  if (null==sGuWorkA) {
    out.write ("error NullPointerException parameter workarea is required");
    return;
  }

  JDCConnection oConn = null;  
  String sAddrGuid=null;

  try {
    oConn = GlobalDBBind.getConnection("address_lookup");
        
    sAddrGuid = Address.getIdFromEmail(oConn, sTxEmail, sGuWorkA);

    oConn.close("address_lookup");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("address_lookup");      
      }
    oConn = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (null==sAddrGuid)
    out.write ("notfound");
  else
    out.write ("found "+sAddrGuid);
%>