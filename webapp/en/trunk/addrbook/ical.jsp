<%@ page import="java.text.SimpleDateFormat,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Fellow,com.knowgate.addrbook.jical.ICalendarFactory,org.jical.ICalendar" language="java" session="false" contentType="text/calendar;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
      
  String id_language = getNavigatorLanguage(request);  
  String gu_fellow = request.getParameter("gu_fellow");
  String tx_email = request.getParameter("tx_email");
  String tx_pwd = request.getParameter("tx_pwd");
  Date dt_from = oFmt.parse(request.getParameter("tx_from")+" 00:00:00");
  Date dt_to = oFmt.parse(request.getParameter("tx_to")+" 23:59:59");

  if (gu_fellow!=null)
    if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;  
  ICalendar oCal = null;
  Fellow oFlw = new Fellow();

  try {
    oConn = GlobalDBBind.getConnection("ical");  
    if (gu_fellow!=null) {
      oFlw.load(oConn, gu_fellow);
      oCal = ICalendarFactory.createICalendar(oConn, gu_fellow, dt_from, dt_to, id_language);
    } else {
      oCal = ICalendarFactory.createICalendar(oConn, tx_email, tx_pwd, dt_from, dt_to, id_language);
    }

    oConn.close("ical");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("ical");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;    
  oConn = null;

  if (gu_fellow!=null) {
    response.setHeader("Content-Disposition","inline; filename=\"" + oFlw.getStringNull(DB.tx_nickname,gu_fellow) + "_" + request.getParameter("tx_from") + "_" + request.getParameter("tx_to") + ".ics\"");
  } else {
    response.setHeader("Content-Disposition","inline; filename=\"" + tx_email.substring(0,tx_email.indexOf('@')) + "_" + request.getParameter("tx_from") + "_" + request.getParameter("tx_to") + ".ics\"");
  }

  out.write(oCal.getVCalendar());
%>