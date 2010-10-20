<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  final String gu_workarea = request.getParameter("gu_workarea");
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
  PreparedStatement oDel;
  
  try {
    oCon = GlobalDBBind.getConnection("url_delete");

    oDel = oCon.prepareStatement("DELETE FROM "+DB.k_urls+" WHERE "+DB.gu_url+"=? AND "+DB.gu_workarea+"=?");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
      oDel.setString(1, a_items[i]);
      oDel.setString(2, gu_workarea);
		  oDel.executeUpdate();
    } // next ()

		oDel.close();  
    oCon.commit();
    oCon.close("url_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"url_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='urls_followup_list.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>