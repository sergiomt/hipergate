<%@ page import="com.knowgate.jdc.JDCConnection,com.knowgate.hipergate.Distances" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%

  JDCConnection oConn = null;  
  float fNuKm = Float.parseFloat(request.getParameter("nu_km"));
  
  try {
    oConn = GlobalDBBind.getConnection("distance_store");
    
    oConn.setAutoCommit(true);

    Distances.setDistance(oConn, request.getParameter("lo_from"), request.getParameter("lo_to"), fNuKm, request.getParameter("id_locale"));

    oConn.close("distance_store");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("distance_store");
      }
    oConn = null;
    out.write("ERROR distance_store.jsp "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  out.write(String.valueOf(fNuKm));  
%>