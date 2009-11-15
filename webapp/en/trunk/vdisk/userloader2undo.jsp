<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,java.io.File,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String sWorkArea = request.getParameter("workarea");
  String sAction = request.getParameter("action");
  String sFileName = request.getParameter("filename");

  String sTmpDir = Gadgets.chomp(Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir()),File.separator) + sWorkArea;
  
  File oTxt = new File(sTmpDir+File.separator+sFileName);
  if (oTxt.exists()) oTxt.delete();

  if (sAction.equals("_back")) {
    response.sendRedirect (response.encodeRedirectUrl ("userloader1.jsp"));
  } else {
    out.write("<HTML><BODY onload=\"window.close()\"></BODY></HTML>");
  }
%>