<%@ page import="com.knowgate.hipergate.Term,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
    
  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("term_delete");

    oCon.setAutoCommit (false);
  
    Term.delete (oCon, request.getParameter("gu_term"));
  
    oCon.commit();
    oCon.close("term_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"term_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  GlobalCacheClient.expire("[" + request.getParameter("id_domain") + "," + request.getParameter("gu_workarea") + "," + request.getParameter("id_scope") + ",thesauri]");
  GlobalCacheClient.expire("[" + request.getParameter("id_domain") + "," + request.getParameter("gu_workarea") + ",all,thesauri]");
  GlobalCacheClient.expire("[" + request.getParameter("id_domain") + "," + request.getParameter("gu_workarea") + ",geozone,thesauri]");
  
  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.frames[0].document.location.reload(true); window.document.location.href = 'term_edit.jsp?id_domain=" + request.getParameter("id_domain") + "&gu_workarea=" + request.getParameter("gu_workarea") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>