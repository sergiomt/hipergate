<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.training.AcademicCourseAlumni" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String a_alumni[] = Gadgets.split(request.getParameter("alumni"), ',');
  
  JDCConnection oCon = null;
  AcademicCourseAlumni oBok = new AcademicCourseAlumni(request.getParameter("gu_acourse"), null);
    
  try {
    oCon = GlobalDBBind.getConnection("alumni_delete");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_alumni.length;i++) {
      oBok.replace(DB.gu_alumni,a_alumni[i]);
      oBok.delete(oCon);
    } // next ()
  
    oCon.commit();
    oCon.close("alumni_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"alumni_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    } 
%>