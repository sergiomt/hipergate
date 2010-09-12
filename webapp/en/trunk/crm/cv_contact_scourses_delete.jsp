<%@ page import="com.knowgate.training.ContactShortCourses,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.lucene.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  final String PAGE_NAME = "cv_contact_scourses_delete";
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  final String gu_scourse = request.getParameter("gu_scourse");
    
  JDCConnection oCon = null;
  ContactShortCourses oCsc = new ContactShortCourses();
  oCsc.put(DB.gu_contact, request.getParameter("gu_contact"));
  oCsc.put(DB.gu_scourse, gu_scourse);
  
  try {
    oCon = GlobalDBBind.getConnection(PAGE_NAME);

    oCon.setAutoCommit (false);

    oCsc.delete(oCon);

    DBAudit.log(oCon, ContactShortCourses.ClassId, "DCSC", id_user, gu_scourse, null, 0, 0, null, null);
	
    if (null!=GlobalDBBind.getProperty("luceneindex")) {
		ContactIndexer.addOrReplaceContact(GlobalDBBind.getProperties(), request.getParameter("gu_contact"),request.getParameter("gu_workarea"),oCon);
	} 
  
    oCon.commit();
    oCon.close(PAGE_NAME);
  } 
  catch(SQLException e) {
      disposeConnection(oCon,PAGE_NAME);
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  response.sendRedirect (response.encodeRedirectUrl ("cv_contact_edit.jsp?gu_contact="+request.getParameter("gu_contact")+"&fullname="+Gadgets.URLEncode(request.getParameter("fullname"))+"&selectTab=2"));
 %>