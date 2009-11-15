<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.crm.Company" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  if (!bIsAdmin) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=Having administrator role is required for editing company access restrictions&resume=_back"));
    return;
  }

  JDCConnection oConn = null;  
  Company oComp = new Company(request.getParameter("gu_company"));
    
  try {
    oConn = GlobalDBBind.getConnection("company_security_store");
    
    oConn.setAutoCommit(false);
    
    oComp.clearACLGroups(oConn);
	  oComp.addToACLGroups(oConn, request.getParameter("memberof"));
    
    oConn.commit();
      
    oConn.close("company_security_store");
  }
  catch (Exception e) {
    disposeConnection(oConn,"company_security_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("company_security.jsp?id_domain="+request.getParameter("id_domain")+"&gu_company="+request.getParameter("gu_company")));

%>