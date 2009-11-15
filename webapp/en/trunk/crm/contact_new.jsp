<%@ page import="java.net.URLDecoder,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %>
<%
  String sFace = getCookie(request,"face","crm");
  String sTarget;
  
  if (sFace.equals("edu"))
    sTarget = "contact_new_edu.jsp";
  else if (sFace.equals("healthcare"))
    sTarget = "contact_new_hcr.jsp";
  else
    sTarget = "contact_new_crm.jsp";
%>
<jsp:forward page="<%=sTarget%>">
  <jsp:param name="id_domain" value="<%=request.getParameter(\"id_domain\")%>" />
</jsp:forward>