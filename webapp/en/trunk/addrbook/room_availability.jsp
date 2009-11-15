<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Timestamp,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);

  String[] aStartDt = Gadgets.split(request.getParameter("dt_start"),'-');
  String[] aEndDt = Gadgets.split(request.getParameter("dt_end"),'-');
  Timestamp oTsStart = new Timestamp(new Date (Integer.parseInt(aStartDt[0])-1900, Integer.parseInt(aStartDt[1])-1, Integer.parseInt(aStartDt[2]), 0, 0).getTime());
  Timestamp oTsEnd = new Timestamp(new Date (Integer.parseInt(aEndDt[0])-1900, Integer.parseInt(aEndDt[1])-1, Integer.parseInt(aEndDt[2]), 23, 59).getTime());
  
  JDCConnection oConn = null;  
  DBSubset oMeetings = new DBSubset(DB.k_meetings +" m," + DB.k_x_meeting_room + " r," + DB.k_fellows + " f",
  				    "m."+DB.gu_meeting+",r."+DB.nm_room+",m."+DB.dt_start+",m."+DB.dt_end+","+DB.tx_name+","+DB.tx_surname,
  				    "m."+DB.gu_meeting+"=r."+DB.gu_meeting+" AND m."+DB.gu_fellow+"=f."+DB.gu_fellow+" AND m."+DB.gu_workarea+"=?"+
  				    " AND ((m."+DB.dt_start+"<=? AND m."+DB.dt_end+"> ?) OR "+
  				    "      (m."+DB.dt_start+">=? AND m."+DB.dt_end+"<=?) OR "+
      				    "      (m."+DB.dt_start+"< ? AND m."+DB.dt_end+">=?))", 10);
  try {
    oConn = GlobalDBBind.getConnection("room_availability");
    oMeetings.load (oConn, new Object[]{gu_workarea,oTsStart,oTsStart,oTsStart,oTsEnd,oTsEnd,oTsEnd});      
    oConn.close("room_availability");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("room_availability");      
      }
    oConn = null;
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }  
  if (null==oConn) return; 
  oConn = null;

  out.write("<meetings>"+oMeetings.toXML("","meeting")+"</meetings>");
%>