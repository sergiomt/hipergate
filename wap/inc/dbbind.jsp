<jsp:useBean id="GlobalDBBind" scope="application" class="com.knowgate.dataobjs.DBBind"/><%
	
request.setCharacterEncoding("UTF-8");

com.knowgate.acl.ACLUser oUser = (com.knowgate.acl.ACLUser) session.getAttribute("user");

com.knowgate.jdc.JDCConnection oConn = null;

final String sLanguage = request.getLocale().getLanguage().substring(0,2).toLowerCase();

final java.util.ResourceBundle Labels = java.util.ResourceBundle.getBundle("Labels", request.getLocale());

if (oUser==null) {
  response.sendRedirect ("index.jsp");
  return;
}
%>