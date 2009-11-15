<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.dfs.StreamPipe" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_job = request.getParameter("gu_job");
  String gu_workarea = getCookie(request,"workarea","");

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sJobLog = sStorage + "jobs" + File.separator + gu_workarea + File.separator + gu_job + ".txt";
  File oJobLog = new File(sJobLog);
  
  if (!oJobLog.exists()) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File not found&desc=There is no log file for given job batch&resume=_close"));  
    return;
  }

  JDCConnection oConn = null;  
  DBPersist oJob = new DBPersist(DB.k_jobs, "Job");

  try {    
    oConn = GlobalDBBind.getConnection("job_viewlog");
    if (!oJob.load(oConn, new Object[]{gu_job}))
      throw new SQLException ("Job batch does not exist");
    if (!oJob.getStringNull(DB.gu_workarea,"").equals(gu_workarea))
      throw new SQLException ("The given file does not belong to current WorkArea");
    oConn.close("job_viewlog");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("job_viewlog");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }  
  if (null==oConn) return;    
  oConn = null;

  StreamPipe.between(sJobLog, response.getOutputStream());
  
  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"
%>