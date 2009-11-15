<%@ page import="com.knowgate.crm.AttachmentUploader,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
  AttachmentUploader.main(new String[]{"hipergate", "/opt/knowgate/tmp/", "7f00000110f01b01fbd100001a1b74ec", "true"});
  
  out.write("1.0:OK");
%>