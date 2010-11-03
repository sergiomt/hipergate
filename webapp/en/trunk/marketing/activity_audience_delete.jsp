<%@ page import="com.knowgate.marketing.ActivityAudience,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  String gu_activity = request.getParameter("gu_activity");
    
  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("activity_audience_delete");

    oCon.setAutoCommit (false);
  
  	ActivityAudience oAcAu = new ActivityAudience();
  	oAcAu.put(DB.gu_activity, gu_activity);

    for (int i=0;i<a_items.length;i++) {
      oAcAu.replace(DB.gu_contact, a_items[i]);
      oAcAu.delete(oCon);

      DBAudit.log(oCon, ActivityAudience.ClassId, "DACA", id_user, gu_activity, a_items[i], 0, 0, null, null);
    } // next ()

    oCon.commit();
    oCon.close("activity_audience_delete");
  } 
  catch (SQLException e) {
      disposeConnection(oCon,"activity_audience_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='activity_audience.jsp?gu_activity="+gu_activity+"';<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>