<%
String _msgmail_body = "Bienvenido a Hipergate, ahorre tiempo y esfuerzo en su negocio.<BR>";

_msgmail_body += "Estos son los datos que le permitirá comprobar la potencia de nuestra herramienta durante 60 días: <BR><BR>";
_msgmail_body += "E-mail: {#email}  <BR>";
_msgmail_body += "Clave: {#clave} <BR>";
_msgmail_body += "Pinche en el enlace que aparece a continuación y teclee su clave :<BR><BR>";
_msgmail_body += "<a href='http://demo.hipergate.com/index.jsp?email={#email}'>http://demo.hipergate.com/index.jsp?email={#email}</a> <BR>";

String _msgmail_subject = "Hipergate : Alta de usuario";

String _msgmail_from_addr = "support@hipergate.com";
String _msgmail_from_name = "Soporte Hipergate";
String _msgmail_cc = "";
String _msgmail_bcc = "";
 

%>