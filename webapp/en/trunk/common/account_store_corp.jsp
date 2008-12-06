<%@ page import="com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dfs.FileSystem,java.sql.SQLException,java.util.Properties,java.util.Enumeration,java.io.File,java.io.FileInputStream,java.io.IOException,java.net.URLDecoder,com.knowgate.misc.Environment,com.knowgate.misc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%@ include file="../methods/propertiesreqload.jspf" %>
<%@ include file="account_msgmail.jsp" %>
<%
 
 short iStatus;
 String sUserId  = getCookie (request, "userid", "");
 String sAuthStr = nullif(request.getParameter("NuevaPwd"),"");
 String NuevoMainmail = nullif(request.getParameter("NuevoMainmail"),"");
 
 String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");  	
 String sNameScript, path_script, sScript ;
        	
 Properties oRetVal = new Properties();
 JInterpreterLocal oIntr = null;
 
 Properties oParams = new Properties();
 Properties oEnvProps = Environment.getProfile("appserver");
 String s3Tiers = oEnvProps.getProperty("threetiers", "disabled");
 boolean b3Tiers = s3Tiers.equalsIgnoreCase("enabled") || s3Tiers.equalsIgnoreCase("yes") || s3Tiers.equalsIgnoreCase("true") || s3Tiers.equalsIgnoreCase("on") || s3Tiers.equals("1");

 String sIdAccount = "";
 
 JDCConnection oConn;
 ACLUser oUser;
 boolean bDomainAdmin = false;
 
 int ExisteError = 0;
 String sErrorScript;
 String sMensajeScript = "";
 
 oConn = GlobalDBBind.getConnection("account_store_corp");
 
 //comprobamos la existencia del usuario
 try {
        
        
        oUser = new ACLUser(oConn, sUserId);        
        
        
        if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 2 , comprobando existencia : " + sUserId + "--" + oUser.toString());
	
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
          		//ya existía usuario de prueba y su password es ok
          		//comprobamos que es administrador del dominio
          		
          		bDomainAdmin = oUser.isDomainAdmin(oConn);
          		if (!bDomainAdmin) 
          			ExisteError = 4;
          		
          
        	}
        	else
        	{
        		//ya existía usuario de prueba y su password ko
          		ExisteError = 1;
          	         	
        	}  
        }	
        else 	
        {
        	//no existe usuario de prueba.
        	//Como la cuenta es corporativa debemos crear un dominio
        	//y pillar el gu_user del usuario administrador del dominio
        	//para posteriormente asociarlo a la cuenta
        	
        	
        	sNameScript = "domain_create.java";
        	path_script = sStorage + "/scripts/" + sNameScript;
        	sScript = new String(FileSystem.readfile(path_script));
        	
        	//NOTA  
		//posible mejora a lo anterior: 
		//sobrecargar el metodo eval de Jinterpreter 
		//para que se le pueda pasar directamente un path 
		//de archivo en lugar de tenerlo que cargar desde jsp
		
        	
        			
  		// Carga los parámetros de la url en oParams para su posterior fusión con el script
  		// @param DomainNm 
  		// @param DomainId debemos ponerlo en blanco para que se genere el id_domain automaticamente
    		
    		    		
    		loadRequestNull(request, oParams, ""); 
 		
    		oParams.put("DomainId", "");
  		
		if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint (creacion cuenta corporativa) 2");
  		
        	if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint (creacion cuenta corporativa) 5");
            
  		try {
    			if (b3Tiers) {
      			 if (DebugFile.trace) DebugFile.writeln("bsh_exec 3 tier mode");
      				oIntr = JInterpreterFactory.createInterpreter(oEnvProps);
    			}
    			else {
      				if (DebugFile.trace) DebugFile.writeln("bsh_exec 2 tier mode");

      				oIntr = JInterpreterFactory.createInterpreter(GlobalDBBind);
    			}

    			if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 6");

    			oIntr.connect("DefaultConnection2");  
    			oIntr.connect("AlternativeConnection2");

    			if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 7");
    
    			   			
    			oRetVal = ( Properties ) oIntr.eval(sScript, oParams);
    				
    			if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 8");

    			oIntr.commit("AlternativeConnection2");
    			oIntr.commit("DefaultConnection2");        
    			
  		}
  		catch (JInterpreterException e) {
  			if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint la cagamos 9");
    			//oRetVal = e.getMessage();
    			response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error BSF&desc=" + e.getMessage() + "&resume=_back"));
  		}
  		finally {
    			if (null!=oIntr) {
      				oIntr.disconnect("AlternativeConnection2");
      				oIntr.disconnect("DefaultConnection2");
      				oIntr = null;
    			}
  		}    
  		
  		
  		//testeamos los valores de vuelta del script guardados en properties oRetVal
 
		 ExisteError = 0; 
 		 sErrorScript = oRetVal.getProperty("sCodError");
 		 if ( sErrorScript.equalsIgnoreCase("0") == true )
 		 {
  			//aquí pillamos el gu_user que será asignado a la cuenta.
  			sUserId = oRetVal.getProperty("sGuUserAdmin");
 		 } 	
 		 else
 		 {
 			sMensajeScript = oRetVal.getProperty("sMessage");
 			ExisteError = 2;
 		 }
  		
  		
  		if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 10:Recogemos valor sUserId : " + sUserId + " -");
  		  		
  		
  		//fin de creacion de dominio nuevo
        
        }
    
 }
 catch (java.sql.SQLException e) {
        iStatus = -255; 
 }
 finally{
 	if (!oConn.isClosed())
 		oConn.close("account_store_corp");
 
 }



  
 if (ExisteError != 0) 
 {
   switch (ExisteError) {
 
      case 1:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Contraseña No Válida&desc=La contraseña especificada para el usuario no es válida&resume=_back"));  
        return;
      case 2:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=No se pudo crear el usuario&desc=" + sMensajeScript +  "&resume=_back"));  
        return;
      case 4:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=No hay suficientes permisos&desc=Para poder actualizar la cuenta es necesario ser administrador&resume=_back"));  
        return;
      
    }
 
 
 }
 
 // creacion de una cuenta asociada al usuario
 
 sNameScript = "account_create.java";
 path_script = sStorage + "/scripts/" + sNameScript;
 sScript = new String(FileSystem.readfile(path_script));
 Properties oRetVal2 = new Properties();
        	
/* Carga los parámetros de la url en oParams para su posterior fusión con el script
  @param sGuUser 	Usuario Profesional o Usuario se promocionó desde cuenta gratuita (es el sUserId)
  @param sTpAccount 	Tipo de la cuenta P=Profesional C=corporativa (se toma del formulario en new_customer.jsp)
  @param iMaxUsers 	Numero máximo de usuarios de la cuenta (es = 1)
  @param sSnPassport 	Nº de documento legal del contratante (se toma del formulario en new_customer.jsp)
  @param sTpPassport 	Tipo de documento legal {DNI,NIF,CIF,...} (se toma del formulario en new_customer.jsp)
  @param sTpBilling 	Tipo de opción de cobro { T=Tarjeta, B=Banco, ... } (se toma del formulario en new_customer.jsp)
    
*/  
    		
  //antes sería conveniente limpiar Oparams 
    		
  loadRequestNull(request, oParams, ""); 
    		
  oParams.put("sGuUser", sUserId);
  oParams.put("sTpAccount", "P");
  oParams.put("iMaxUsers", "1");
  		
 if (DebugFile.trace) DebugFile.writeln("bsh_exec ccuenta checkpoint 2");

 
 if (DebugFile.trace) DebugFile.writeln("bsh_exec ccuenta checkpoint 5");
            
 try {
   if (b3Tiers) {
    	if (DebugFile.trace) DebugFile.writeln("bsh_exec 3 ccuenta tier mode");
		oIntr = JInterpreterFactory.createInterpreter(oEnvProps);
   }
   else {
   	if (DebugFile.trace) DebugFile.writeln("bsh_exec 2 ccuenta tier mode");
		oIntr = JInterpreterFactory.createInterpreter(GlobalDBBind);
   } 	

    if (DebugFile.trace) DebugFile.writeln("bsh_exec ccuenta checkpoint 6");

    oIntr.connect("DefaultConnection");  
    oIntr.connect("AlternativeConnection");

    if (DebugFile.trace) DebugFile.writeln("bsh_exec ccuenta checkpoint 7");
    
    oRetVal = ( Properties ) oIntr.eval(sScript, oParams);
    				
    if (DebugFile.trace) DebugFile.writeln("bsh_exec ccuenta checkpoint 8");

    oIntr.commit("AlternativeConnection");
    oIntr.commit("DefaultConnection");        
    			
 } 
 catch (JInterpreterException e) {
    if (DebugFile.trace) DebugFile.writeln("bsh_exec ccuenta checkpoint 9");
    //oRetVal2 = e.getMessage();
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error BSF&desc=" + e.getMessage() + "&resume=_back"));
 }
 finally {
    if (null!=oIntr) {
    	oIntr.disconnect("AlternativeConnection");
    	oIntr.disconnect("DefaultConnection");
    	oIntr = null;
    }
 }    
  		
 //testeamos los valores de vuelta del script guardados en properties oRetVal
 
 ExisteError = 0; 
 sErrorScript = oRetVal.getProperty("sCodError");
 if ( sErrorScript.equalsIgnoreCase("0") == true )
 {
  	sIdAccount = oRetVal.getProperty("sIdObjetoOK");
 } 	
 else
 {
 	sMensajeScript = oRetVal.getProperty("sMessage");
 	ExisteError = 3;
 }	
 		
 if (DebugFile.trace) DebugFile.writeln("bsh_exec checkpoint 10:Recogemos valor sIdAccount : " + sIdAccount + " -");
   			
 if (ExisteError != 0) 
 {
   switch (ExisteError) {
 
      case 3:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=No se pudo crear la cuenta&desc=" + sErrorScript + "//" + sMensajeScript + "&resume=_back"));  
        return;
      
      
    }
 
 
 }
 
  		
 //fin de creacion de cuenta
        
        
  
%>
      
<html>
<head>
<TITLE>hipergate ::</TITLE>
<SCRIPT LANGUAGE="javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
      <!--      
        var dt1Min = new Date();
	dt1Min.setTime(dt1Min.getTime()+60000);	// Give cookie 1 minute lifetime
        setCookie ("NickCookie","<%=NuevoMainmail%>",dt1Min);

	        
        setCookie ("userid","<%=sUserId%>",dt1Min);
        setCookie ("authstr","<%=sAuthStr%>",dt1Min);
        
      //-->
      
      <!--      
        function envia()
        {
        	//document.frm.submit();
        	//document.frmmail.submit();
        	//document.location.href='/common/login_chk.jsp';
        }
        
      //-->
    </SCRIPT>
</head>
<body onload="envia();">
<!--Cuenta <%=sIdAccount%> creada con éxito.-->
<form name="frm" action="/common/login_chk.jsp">
<input type="text" name="nickname" value="<%=NuevoMainmail%>">
<input type="text" name="pwd_txt" value="<%=sAuthStr%>">
<input type="submit">
</form>

</body>
</html>