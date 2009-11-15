<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.projtrack.Project,com.knowgate.projtrack.ProjectSnapshot" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("prj_gantt_export");
    Project oProj = new Project(oConn, request.getParameter("gu_project"));
    ProjectSnapshot oSnap = oProj.snapshot(oConn);
    oConn.close("prj_gantt_export");

    response.setHeader("Content-Disposition","attachment; filename=\"" + oProj.getString("nm_project") + ".gan\"");

    response.setHeader("Cache-Control","no-cache");
    response.setHeader("Pragma","no-cache");
    response.setIntHeader("Expires", 0);
  
    out.write(oSnap.toGantt());

  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("prj_gantt_export");
      }
    oConn = null;
    out.write(e.getClass().getName()+" "+e.getMessage()+" "+com.knowgate.debug.StackTraceUtil.getStackTrace(e));
  }
  
  if (null==oConn) return;    
  oConn = null;
%>