<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String nm_room = request.getParameter("nm_room");
  String gu_workarea = request.getParameter("gu_workarea");

  String[] aStartDt = Gadgets.split(request.getParameter("dt_start"),'-');
  String[] aEndDt = Gadgets.split(request.getParameter("dt_end"),'-');
  Timestamp oTsFrom = new Timestamp(new Date (Integer.parseInt(aStartDt[0])-1900, Integer.parseInt(aStartDt[1])-1, Integer.parseInt(aStartDt[2]), Integer.parseInt(request.getParameter("tx_h_start")), Integer.parseInt(request.getParameter("tx_m_start"))).getTime());
  Timestamp oTsTo = new Timestamp(new Date (Integer.parseInt(aEndDt[0])-1900, Integer.parseInt(aEndDt[1])-1, Integer.parseInt(aEndDt[2]), Integer.parseInt(request.getParameter("tx_h_end")), Integer.parseInt(request.getParameter("tx_m_end"))).getTime());

  JDCConnection oConn = null;  
  Room oRoom = new Room();
  String sMeeting = null;
  try {
    oConn = GlobalDBBind.getConnection("room_available");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT x."+DB.gu_meeting+" FROM "+
      DB.k_rooms+" r,"+DB.k_x_meeting_room+" x WHERE r."+DB.nm_room+"=x."+DB.nm_room+
      " AND r."+DB.gu_workarea+"=? AND r."+DB.nm_room+"=? AND (x."+DB.dt_start+" BETWEEN ? AND ?"+
      "OR x."+DB.dt_end+" BETWEEN ? AND ? OR (x."+DB.dt_start+"<=? AND x."+DB.dt_end+">=?))",
      ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, gu_workarea);
    oStmt.setString(2, nm_room);
    oStmt.setTimestamp(3, oTsFrom);
    oStmt.setTimestamp(4, oTsTo);
    oStmt.setTimestamp(5, oTsFrom);
    oStmt.setTimestamp(6, oTsTo);
    oStmt.setTimestamp(7, oTsFrom);
    oStmt.setTimestamp(8, oTsTo);
    ResultSet oRset = oStmt.executeQuery();
    if (oRset.next())
      sMeeting = oRset.getString(1);
    oRset.close();
    oStmt.close();

    oConn.close("room_available");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("room_available");      
      }
    oConn = null;
    
    out.write("<meeting>"+e.getMessage()+"</meeting>");
  }  
  if (null==oConn) return; 
  oConn = null;

  out.write("<meeting>"+nullif(sMeeting)+"</meeting>");
%>