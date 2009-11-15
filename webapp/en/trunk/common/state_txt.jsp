<%@ page import="java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><% 

  String sLanguage = getNavigatorLanguage(request);

  JDCConnection oConn = null;  
  String sStateList = null;
    
  try {
    oConn = GlobalDBBind.getConnection("state_txt");
    
    sStateList = GlobalDBLang.getPlainTextStateList(oConn, request.getParameter("id_country"), sLanguage);
      
    oConn.close("state_txt");
  }
  catch (Exception e) {
    // Si algo peta 
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("state_txt");
      }
    oConn = null;
    out.write("ERROR,"+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  out.write(sStateList);
%>