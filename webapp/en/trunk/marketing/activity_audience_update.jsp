<%@ page import="com.knowgate.marketing.ActivityAudience,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  String gu_activity = request.getParameter("gu_activity");
  String id_status = request.getParameter("sel_new_status");
    
  JDCConnection oCon = null;
  PreparedStatement oStm = null;
      
  try {
    oCon = GlobalDBBind.getConnection("activity_audience_update");

		oStm = oCon.prepareStatement("UPDATE "+DB.k_x_activity_audience+" SET "+
																(id_status.indexOf("confirmed")>=0 ? DB.bo_confirmed :
																 id_status.indexOf("went")>=0 ? DB.bo_went : DB.bo_paid)+"="+
																(id_status.startsWith("no") || id_status.startsWith("un") ? "0 " : "1 ")+
                                 "WHERE "+DB.gu_activity+"='"+gu_activity+"' AND "+DB.gu_contact+"=?");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
		  oStm.setString(1, a_items[i]);
		  oStm.executeUpdate();
      DBAudit.log(oCon, ActivityAudience.ClassId, "UACA", id_user, gu_activity, a_items[i], 0, 0, id_status, null);
    } // next ()
    
	  oStm.close();
	  oStm=null;

    oCon.commit();
    oCon.close("activity_audience_update");
  } 
  catch (SQLException e) {
      if (oStm!=null) oStm.close();
      disposeConnection(oCon,"activity_audience_update");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='activity_audience.jsp?gu_activity="+gu_activity+"';<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>