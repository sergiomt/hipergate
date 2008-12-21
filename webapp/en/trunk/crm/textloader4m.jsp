<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body scrolling="no">
<%
  String id_status = request.getParameter("id_status");
  if (id_status.equals("success"))
    out.write("<h2>[~Importación de datos finalizada con éxito~]</h2>");
  else if (id_status.equals("warning"))
    out.write("<h2>[~Importación de datos finalizada con avisos~]</h2>");
  else if (id_status.equals("error")) {
    out.write("<h2>[~Importacion de datos fallida~]</h2><br>"+request.getParameter("desc"));
  }
%>
</body>
</html>
