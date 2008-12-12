<%@ page import="java.net.URLDecoder,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
  String sFace = nullif(request.getParameter("face"),getCookie(request,"face","crm"));
  String sTarget;
  
  if (sFace.equals("edu"))
    sTarget = "contact_edit_edu.jsp";
  else if (sFace.equals("healthcare"))
    sTarget = "contact_edit_hcr.jsp";
  else
    sTarget = "contact_edit_crm.jsp";
%>
<jsp:forward page="<%=sTarget%>">
  <jsp:param name="id_domain" value="<%=request.getParameter(\"id_domain\")%>" />
  <jsp:param name="n_domain" value="<%=Gadgets.URLEncode(request.getParameter(\"n_domain\"))%>" />
  <jsp:param name="gu_contact" value="<%=nullif(request.getParameter(\"gu_contact\"))%>" />
  <jsp:param name="gu_company" value="<%=nullif(request.getParameter(\"gu_company\"))%>" />
  <jsp:param name="noreload" value="<%=nullif(request.getParameter(\"noreload\"),\"0\")%>" />
</jsp:forward>