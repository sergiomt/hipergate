<%@ page import="com.knowgate.debug.DebugFile, com.knowgate.jdc.*,  java.sql.SQLException, java.sql.PreparedStatement, java.util.Properties,java.util.Enumeration,java.io.File,java.io.FileInputStream,java.io.IOException,java.net.URLDecoder,com.knowgate.misc.Environment,com.knowgate.misc.*, com.knowgate.acl.*, com.knowgate.beanservices.JInterpreterFactory,com.knowgate.beanservices.JInterpreterLocal,com.knowgate.beanservices.JInterpreterException, com.knowgate.dataobjs.*, com.knowgate.billing.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%@ include file="../methods/propertiesreqload.jspf" %>
<%@ include file="../methods/iofiles.jspf" %>
<%@ include file="account_msgmail.jsp" %>

<%
 
 
  
 
 short iStatus;
 String sUserId  = getCookie (request, "userid", "");
 String sAuthStr = nullif(request.getParameter("NuevaPwd"),"");
 String NuevoMainmail = nullif(request.getParameter("NuevoMainmail"),"");
 
 String sIdAccount = "";
 
 int ExisteError = 0;
 boolean ConectaConTpv=false;
 
 JDCConnection oConn;
 ACLUser oUser;
 
 
 oConn = GlobalDBBind.getConnection("account_store_prof_pay");
 
 //comprobamos la existencia del usuario/cuenta
 try {
        
        
        oUser = new ACLUser(oConn, sUserId);        
        
        
        if (true) DebugFile.writeln("bsh_exec checkpoint 2 , comprobando existencia : " + sUserId + "--" + oUser.toString());
	
	//si existe el usuario
	//if (oUser.exists()) 
	//esto no me funciona así que despues de una hora dándole k te pego al coco
	
	sUserId = oUser.getStringNull(DB.gu_user,"");
	if (sUserId.length() == 32 )
        {
        	
        	//comprobar que la clave es ok
        	
          	iStatus = com.knowgate.acl.ACL.autenticate(oConn, sUserId, sAuthStr, ENCRYPT_ALGORITHM);
          	
        
        	if (iStatus>=0 && sAuthStr!=null)
        	{
          		//ya existía usuario de prueba y su password ok
          		//no hacemos nada y tenemos que conectar con el TPV
          		//Obtenemos el id de cuenta para posteriormente ligar
          		//la transacción electrónica con la cuenta
          		
          		sIdAccount = oUser.getStringNull(DB.id_account,"");
          		ConectaConTpv = true;
          
        	}
        	else
        	{
        		//ya existía usuario de prueba y su password ko
          		ExisteError = 1;
          	         	
        	}  
        }	
        else 	
        {
        	//Tenemos que crear un usuario/cuenta y recuperar el user_id/cuenta
        	%>
        	
        	<%@ include file="account_store_prof.jsp" %>
        	
        	<%
        	//recogemos los valores de los id's de el usuario y cuenta recien creados
       		sUserId = _sUserId;	 
        	sIdAccount = _sIdAccount;
        }	

 }
 catch (java.sql.SQLException e) {
        iStatus = -255; 
 }
 finally{
 	if (!oConn.isClosed())
 		oConn.close("account_store_prof_pay");
 
 }       	

 oConn.close("account_store_prof_pay");
 
 //control errores
 if (ExisteError != 0) 
 {
   switch (ExisteError) {
 
      case 1:
      	DebugFile.writeln("usuario creado pero error1");
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Invalid Password&desc=Password for user is not valid&resume=_back"));  
        return;
      
    }
 
 
 }
%>
      
<%@ include file="../register/launchTpv.jsp" %>
