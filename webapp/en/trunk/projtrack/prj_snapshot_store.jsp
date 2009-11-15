<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.projtrack.Project" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  JDCConnection oConn = null;  
  Project oProj = new Project();
  
  try {
    oConn = GlobalDBBind.getConnection("prj_snapshot_store");
    
    oProj.load(oConn, new Object[]{request.getParameter("gu_project")});
    oProj.setAuditUser(getCookie (request, "userid", null));

    oConn.setAutoCommit(false);
    
    oProj.snapshot(oConn).store(oConn);
        
    oConn.commit();
      
    oConn.close("prj_snapshot_store");
  }
  catch (Exception e) {
    disposeConnection(oConn,"prj_snapshot_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

    response.sendRedirect (response.encodeRedirectUrl ("prj_snapshot_list.jsp?gu_project="+request.getParameter("gu_project")+"&standalone="+request.getParameter("is_standalone")));
%>