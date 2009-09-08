<%@ page import="com.knowgate.addrbook.ToDo,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);

  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
  
  ToDo oTD = new ToDo();
    
  try {
    oCon = GlobalDBBind.getConnection("to_do_delete");

    oCon.setAutoCommit (false);
  
    for (int i=0;i<a_items.length;i++) {
      oTD.replace (DB.gu_to_do, a_items[i]);
      oTD.delete(oCon);
    } // next ()
  
    oCon.commit();

    oCon.setAutoCommit (true);
    
    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon, id_user, "com.knowgate.http.portlets.CalendarTab", getCookie(request,"workarea",""));

    oCon.close("to_do_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"to_do_delete");
      oCon = null;
      
      if (com.knowgate.debug.DebugFile.trace) {      
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getMessage(), "");
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='to_do_listing.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>
<%@ include file="../methods/page_epilog.jspf" %>