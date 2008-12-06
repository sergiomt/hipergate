<%@ page import="com.knowgate.debug.DebugFile, com.knowgate.jdc.*,  java.sql.SQLException, java.sql.PreparedStatement, java.util.Properties,java.util.Enumeration,java.io.File,java.io.FileInputStream,java.io.IOException,java.net.URLDecoder,com.knowgate.misc.Environment,com.knowgate.misc.*, com.knowgate.acl.*, com.knowgate.beanservices.JInterpreterFactory,com.knowgate.beanservices.JInterpreterLocal,com.knowgate.beanservices.JInterpreterException, com.knowgate.dataobjs.*, com.knowgate.billing.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%@ include file="../methods/propertiesreqload.jspf" %>
<%@ include file="../methods/iofiles.jspf" %>
<%@ include file="account_msgmail.jsp" %>
<%@ include file="../methods/mail.jspf" %>
<%
 
 
 //variables que utiliza el archivo account_store_prof.jsp
 //para devolver los identificadores de usuario (_sUserId) y cuenta (_sIdAccount)
 //siempre que se utilice este archivo hay que definirlas
  
 
 short iStatus;
 String sUserId  = "";
 String sIdAccount = "";
 
 String sAuthStr = nullif(request.getParameter("NuevaPwd"),"");
 String NuevoMainmail = nullif(request.getParameter("NuevoMainmail"),"");
 
 
 int ExisteError = 0;
 boolean ConectaConTpv=false;
 
 JDCConnection oConn;
 ACLUser oUser;
 
 
 oConn = GlobalDBBind.getConnection("account_store_prof_test");
 
 //TO DO
 //comprobar si existe el username (tx_main_email)  
 try {
        
        sUserId = ACLUser.getIdFromEmail(oConn, NuevoMainmail);  
        
        
        if (true) DebugFile.writeln("bsh_exec checkpoint 2 , comprobando existencia a partir del mail: " + sUserId + "--" );
	
	
	 
	if (null != sUserId )
        {
        	
        	//Ya existe un usuario con ese email y no se puede crear
        	ExisteError = 1;
                	  
        }	
        else 	
        {
        	//Tenemos que crear un usuario/cuenta y recuperar el user_id/cuenta
        	%>
        	
        	<%@ include file="account_store_prof.jsp" %>
        	
        	<%
        	sUserId = _sUserId;
        	
        }	

 }
 catch (java.sql.SQLException e) {
        iStatus = -255; 
 }
 finally{
 	if (!oConn.isClosed())
 		oConn.close("account_store_prof_test");
 
 }       	

 oConn.close("account_store_prof_test");
 
 //control errores
 if (ExisteError != 0) 
 {
   switch (ExisteError) {
 
      case 1:
      	DebugFile.writeln("usuario creado pero error1");
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Correo no valido&desc=El correo que suministro en el campo e-mail ya está siendo utilizado, elija otro por favor&resume=_back"));  
        return;
      
    }
 
 
 }
 
 //Envio de correo de confirmacion
 
 
 // Variables utilizadas para el mail de confirmacion
 // Generara una nueva clave tomando los 6 últimos caracteres de un GUID
  
 //La variable _msgmail_body esta declarada en msgmail.jsp y contiene el cuerpo del mensaje de bievenida
 String mail_body = Gadgets.replace(_msgmail_body,"{#email}",NuevoMainmail); 

 //Aqui pegamos el cambiazo con los datos del nuevo usuario
 mail_body = Gadgets.replace(mail_body,"{#clave}",sAuthStr); 
  
 //La variable _msgmail_subject esta declarada en msgmail.jsp y contiene el subject del mensaje de bienvenida
 String mail_subject = _msgmail_subject;
 
 //lo mismo para las siguientes variables
 String mail_from_addr = _msgmail_from_addr;
 String mail_from_name = _msgmail_from_name;
 String mail_cc  = _msgmail_cc;
 String mail_bcc = _msgmail_bcc;
 
 Properties oMail = new Properties();
 
 oMail.put("mail_to","juanhc@knowgate.es");
 oMail.put("mail_from_addr",mail_from_addr);
 oMail.put("mail_from_name",mail_from_name);
 oMail.put("mail_subject",mail_subject);
 oMail.put("mail_cc",mail_cc);
 oMail.put("mail_bcc",mail_bcc);
 oMail.put("mail_body",mail_body);
	
 sendMail(oMail);	

%>
<html>
<head>
<TITLE>hipergate ::</TITLE>
<SCRIPT LANGUAGE="javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
      <!--      
        //setCookie ("userid","<%=sUserId%>");
        //setCookie ("authstr","<%=sAuthStr%>");
        //setCookie ("NickCookie","<%=NuevoMainmail%>");
      //-->
      
    
      <!--      
        function envia()
        {
        	document.location.href='/index.jsp?msg=quickok';
        }
        
      //-->
    </SCRIPT>
</head>
<!--body-->
<body onload="envia();">

</body>
</html>      

