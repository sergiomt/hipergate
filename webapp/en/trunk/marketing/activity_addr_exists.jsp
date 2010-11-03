<%@ page import="java.io.IOException,com.knowgate.jdc.JDCConnection,java.sql.PreparedStatement,java.sql.ResultSet" language="java" session="false" contentType="text/plain;charset=ISO-8859-1" %><%@ include file="../methods/dbbind.jsp" %><%

  String sTxEmail = request.getParameter("email");
  String sGuWorkA = request.getParameter("workarea");
  String sGuActiv = request.getParameter("activity");

  if (null==sTxEmail) {
    out.write ("error NullPointerException parameter email is required");
    return;
  }

  if (null==sGuWorkA) {
    out.write ("error NullPointerException parameter workarea is required");
    return;
  }

  if (null==sGuActiv) {
    out.write ("error NullPointerException parameter activity is required");
    return;
  }

  JDCConnection oConn = null;  
	PreparedStatement oStmt = null;
  ResultSet oRset = null;
	
  try {
    oConn = GlobalDBBind.getConnection("activity_addr_exists",true);
    oStmt = oConn.prepareStatement("SELECT NULL FROM k_x_activity_audience x, k_addresses a WHERE a.gu_address=x.gu_address AND x.gu_activity=? AND a.gu_workarea=? AND a.tx_email=?",
    														   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuActiv);
    oStmt.setString(2, sGuWorkA);
    oStmt.setString(3, sTxEmail);
    oRset = oStmt.executeQuery();
    if (oRset.next())
      out.write("found");
    else
    	out.write("notfound");
    oRset.close();
    oStmt.close();
    oConn.close("activity_addr_exists");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("activity_addr_exists");      
      }
    oConn = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
%>