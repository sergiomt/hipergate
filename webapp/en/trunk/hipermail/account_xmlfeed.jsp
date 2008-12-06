<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/xml;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);

  JDCConnection oConn = null;  
  DBSubset oAccs = new DBSubset (DB.k_user_mail,DB.gu_account+","+DB.tl_account+","+DB.tx_main_email,DB.gu_user+"=? ORDER BY 2",10);
  
  try {
    oConn = GlobalDBBind.getConnection("account_xmlfeed");
    oAccs.load(oConn, new Object[]{id_user});    
    oConn.close("account_xmlfeed");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("account_xmlfeed");      
      }
    oConn = null;
    out.write("<"+DB.k_user_mail+"><error>SQLException " + e.getMessage()+"</error></"+DB.k_user_mail+">");
  }  
  if (null==oConn) return;    
  oConn = null;
  out.write("<accounts>"+oAccs.toXML("","k_user_mail")+"</accounts>");
%>