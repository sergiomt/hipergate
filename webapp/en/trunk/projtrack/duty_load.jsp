<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_project = request.getParameter("gu_project");
  
  JDCConnection oConn = null;  
  DBSubset oDuties = new DBSubset (DB.k_duties, DB.gu_duty+","+DB.tp_duty+","+DB.nm_duty+","+DB.dt_start+","+
  																              DB.dt_end+","+DB.dt_scheduled+","+DB.ti_duration+","+DB.od_priority+","+
  																              DB.pr_cost+","+DB.tx_status+","+DB.pct_complete+","+DB.tx_comments+ " ",
  																              DB.gu_project+"='"+gu_project+"' ORDER BY 3", 50);    
  try {
    oConn = GlobalDBBind.getConnection("duty_load");
    
	  oDuties.print(oConn, request.getOutputStream());
 
    oConn.close("duty_load");
    if (true) return;
    
  }
  catch (SQLException e) {
¡    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("duty_load");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;
%>