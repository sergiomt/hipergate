<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.QueryByForm" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String gu_query = request.getParameter("gu_query");
  String queryspec = request.getParameter("queryspec");
  String caller = request.getParameter("queryspec");
      
  JDCConnection oCon = null;
    
  try {
    oCon = GlobalDBBind.getConnection("qbf_delete");
    oCon.setAutoCommit (false);
    QueryByForm.delete(oCon, gu_query);
    oCon.commit();
    oCon.close("qbf_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"qbf_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  if (null==oCon) return;
  oCon = null; 

  response.sendRedirect (response.encodeRedirectUrl ("qbf.jsp?caller="+caller+"&queryspec="+queryspec));

%>