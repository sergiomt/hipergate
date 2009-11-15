<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.training.AcademicCourseBooking" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String a_alumni[] = Gadgets.split(request.getParameter("alumni"), ',');
  
  JDCConnection oCon = null;
  AcademicCourseBooking oBok = new AcademicCourseBooking(request.getParameter("gu_acourse"), null);
    
  try {
    oCon = GlobalDBBind.getConnection("bookings_to_alumni");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_alumni.length;i++) {
      oBok.replace(DB.gu_contact,a_alumni[i]);
      oBok.createAlumni(oCon);
    } // next ()
  
    oCon.commit();
    oCon.close("bookings_to_alumni");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"bookings_to_alumni");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    } 
%>