<%@ page import="java.io.IOException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.ACLUser" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%   
   
  String sTxEmail = request.getParameter("email");

  if (null==sTxEmail) {
    out.write ("error NullPointerException parameter email is required");
    return;
  }

  JDCConnection oConn = null;  
  String sUserGuid=null;

  try {
    oConn = GlobalDBBind.getConnection("email_lookup");
        
    sUserGuid = ACLUser.getIdFromEmail(oConn, sTxEmail);

    oConn.close("email_lookup");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("email_lookup");      
      }
    oConn = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (null==sUserGuid)
    out.write ("notfound");
  else
    out.write ("found");
%>