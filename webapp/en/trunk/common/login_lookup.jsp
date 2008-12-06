<%@ page import="java.io.IOException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%
   
  String sTxEmail = request.getParameter("nickname");
  String sTxPsswd = request.getParameter("pwd_text");

  JDCConnection oConn = null;  

  try {
    oConn = GlobalDBBind.getConnection("login_lookup");
        
    String sUserGuid = ACLUser.getIdFromEmail(oConn, sTxEmail);
    if (null==sUserGuid) {
      out.write(String.valueOf(ACL.USER_NOT_FOUND));
    } else {
      out.write(String.valueOf(ACL.autenticate(oConn, sUserGuid, sTxPsswd, ENCRYPT_ALGORITHM)));
    }

    oConn.close("login_lookup");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("login_lookup");      
      }
    oConn = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;
%>