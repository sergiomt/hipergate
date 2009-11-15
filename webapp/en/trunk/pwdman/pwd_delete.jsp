<%@ page import="com.knowgate.acl.PasswordRecord,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="true" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

	boolean bSession = (session.getAttribute("validated")!=null);

	if (!bSession) {
	  response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Session Expired&desc=Session has expired. Please log in again&resume=_close"));
    return;
  } else if (!((Boolean) session.getAttribute("validated")).booleanValue()) {
	  response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Session Expired&desc=Session has expired. Please log in again&resume=_close"));
    return;
  }
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("password_delete");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
      String sGuUser = DBCommand.queryStr(oCon, "SELECT "+DB.gu_user+" FROM "+DB.k_user_pwd+" WHERE "+DB.gu_pwd+"='"+a_items[i]+"'");
      if (id_user.equals(sGuUser)) {
        String sTlPwd = DBCommand.queryStr(oCon, "SELECT "+DB.tl_pwd+" FROM "+DB.k_user_pwd+" WHERE "+DB.gu_pwd+"='"+a_items[i]+"'");
        PasswordRecord.delete(oCon, a_items[i]);
        DBAudit.log(oCon, PasswordRecord.ClassId, "DPWD", id_user, a_items[i], null, 0, 0, sTlPwd, null);
      } else {
        throw new SQLException("Cannot delete password from another user");
      }
    } // next ()
  
    oCon.commit();
    oCon.close("password_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"password_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='pwdmanhome.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "&gu_category=" + request.getParameter("gu_category") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>