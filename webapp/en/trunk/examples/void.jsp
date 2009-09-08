<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("poner_aqui_el_nombre_(cualquiera)_de_la_conexion");
    
    oConn.setAutoCommit(false);
    
    /* TO DO: Your database access stuff */
    
    oConn.commit();
      
    oConn.close("poner_aqui_el_nombre_(cualquiera)_de_la_conexion");
  }
  catch (Exception e) {
    // Si algo peta 
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("poner_aqui_el_nombre_(cualquiera)_de_la_conexion");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  /* TO DO: Write HTML or redirect to another page */
%>