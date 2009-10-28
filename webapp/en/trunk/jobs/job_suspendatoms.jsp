<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.scheduler.Job,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_job = request.getParameter("gu_job");
  
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
    
  JDCConnection oCon = null;
  PreparedStatement oStm = null;
  
  try {
    oCon = GlobalDBBind.getConnection("job_suspendatoms");
	  oStm = oCon.prepareStatement("UPDATE "+DB.k_job_atoms+" SET "+DB.id_status+"="+String.valueOf(Job.STATUS_SUSPENDED)+" WHERE "+DB.gu_job+"='"+gu_job+"' AND "+DB.pg_atom+"=?");

    oCon.setAutoCommit (false);

    for (int i=0;i<a_items.length;i++) {
      oStm.setInt(1, Integer.parseInt(a_items[i]));
      oStm.executeUpdate();

    } // next ()
    oStm.close();

    oCon.commit();
    oCon.close("job_suspendatoms");
  } 
  catch (SQLException e) {
      disposeConnection(oCon,"job_suspendatoms");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oCon) return;
  oCon = null; 

  response.sendRedirect (response.encodeRedirectUrl ("job_viewatoms.jsp?gu_job="+gu_job+"&id_status="+String.valueOf(Job.STATUS_SUSPENDED)));
 %>