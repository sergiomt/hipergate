<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  Integer id_domain = new Integer(request.getParameter("id_domain"));
  String gu_workarea = request.getParameter("gu_workarea");
  String tp_room = request.getParameter("tp_room");
  String bo_available = request.getParameter("bo_available");
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;  
  DBSubset oRooms = new DBSubset(DB.k_rooms, DB.tp_room+","+DB.nm_room+","+DB.bo_available+","+DB.nu_capacity+","+DB.tx_company+","+DB.tx_location+","+DB.tx_comments,
  				 DB.id_domain+"=? AND "+DB.gu_workarea+"=? "+(tp_room!=null ? " AND "+DB.tp_room+"='"+tp_room+"'" : "")+(bo_available!=null ? " AND "+DB.bo_available+"="+bo_available : "") +
  				 " ORDER BY 6,2", 100);
  try {
    oConn = GlobalDBBind.getConnection("load_rooms");
    oRooms.load(oConn, new Object[]{id_domain,gu_workarea});    
    oConn.close("load_rooms");    
    out.write(oRooms.toString());
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("load_rooms");
      }
    oConn = null;
    out.write("ERROR: "+e.getClass().getName()+" "+e.getMessage());    
  }
%>