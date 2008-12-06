<%@ page import="com.knowgate.jdc.JDCConnection,com.knowgate.hipergate.Distances" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%

  JDCConnection oConn = null;  
  Float oNuKm = null;
  
  try {
    oConn = GlobalDBBind.getConnection("distance_dbms");
    
    oNuKm = Distances.getDistance(oConn, request.getParameter("from"), request.getParameter("to"), request.getParameter("locale"));

    oConn.close("distance_dbms");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("distance_dbms");
      }
    oConn = null;
    out.write("ERROR distance_dbms.jsp "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (oNuKm==null)
    out.write("not found");  
  else
    out.write(String.valueOf(oNuKm));  
%>