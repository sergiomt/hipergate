<%@ page import="com.knowgate.training.ContactLanguages,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.lucene.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  final String PAGE_NAME = "cv_contact_languages_delete";
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  final String id_language = request.getParameter("id_language");
    
  JDCConnection oCon = null;
  ContactLanguages oCsc = new ContactLanguages();
  oCsc.put(DB.gu_contact, request.getParameter("gu_contact"));
  oCsc.put(DB.id_language, id_language);
  
  try {
    oCon = GlobalDBBind.getConnection(PAGE_NAME);

    oCon.setAutoCommit (false);

    oCsc.delete(oCon);

    DBAudit.log(oCon, ContactLanguages.ClassId, "DCLA", id_user, id_language, null, 0, 0, null, null);
 
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

  response.sendRedirect (response.encodeRedirectUrl ("cv_contact_edit.jsp?gu_contact="+request.getParameter("gu_contact")+"&fullname="+Gadgets.URLEncode(request.getParameter("fullname"))+"&selectTab=4"));
 %>