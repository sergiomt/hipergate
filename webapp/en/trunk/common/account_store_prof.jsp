<%@ page import="com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dfs.FileSystem,java.sql.SQLException, java.sql.PreparedStatement, java.util.Properties,java.util.Enumeration,java.io.File,java.io.FileInputStream,java.io.IOException,java.net.URLDecoder,com.knowgate.misc.Environment,com.knowgate.misc.*, com.knowgate.acl.*, com.knowgate.beanservices.JInterpreterFactory,com.knowgate.beanservices.JInterpreterLocal,com.knowgate.beanservices.JInterpreterException, com.knowgate.dataobjs.*, com.knowgate.billing.*" contentType="text/html;charset=UTF-8" %>
<%

 
// account_store_prof (fichero include)
//	Crea un usuario y una cuenta profesional asociada
// 	Devuelve en las siguientes variables los id's de usuario y cuenta respectivamente

 String _sUserId="";
 String _sIdAccount="";
 
  
 String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");  	
 String sNameScript, path_script, sScript ;
        	
 Properties oRetVal = new Properties();
 JInterpreterLocal oIntr = null;
 
 Properties oParams = new Properties();
 Properties oEnvProps = Environment.getProfile("appserver");
 String s3Tiers = oEnvProps.getProperty("threetiers", "disabled");
 boolean b3Tiers = s3Tiers.equalsIgnoreCase("enabled") || s3Tiers.equalsIgnoreCase("yes") || s3Tiers.equalsIgnoreCase("true") || s3Tiers.equalsIgnoreCase("on") || s3Tiers.equals("1");

 
 
 JDCConnection oConnJS;
 
 
 int _ExisteError = 0;
 
 String sErrorScript = "";
 String sMensajeScript = "";
 
 oConnJS = GlobalDBBind.getConnection("account_store_prof");
 
 
 
        
               	//Tenemos que crear un usuario y recuperar el user_id
        	
               	sNameScript = "domain_adduser.java";
        	path_script = sStorage + "/scripts/" + sNameScript;
        	sScript = new String(FileSystem.readfile(path_script));

        	
        	//NOTA  
		//posible mejora a lo anterior: 
		//sobrecargar el metodo eval de Jinterpreter 
		//para que se le pueda pasar directamente un path 
		//de archivo en lugar de tenerlo que cargar desde jsp
		
               	
  		
  		// Carga los parámetros de la url en oParams para su posterior fusión con el script
  		// @param NuevoNickName lo coge del formulario en new_customer.jsp
   		// @param NuevoMainmail lo coge del formulario en new_customer.jsp
    		// @param NuevaPwd lo coge del formulario en new_customer.jsp
    		
    		// @param DomainNm lo inicializamos a "" para que por defecto
    		// se cree en el dominio "PROFE"
    		
    		// podría ser interesante definir una variable en el hipergate.cnf 
    		// para decidir por defecto en que dominio se crean las cuentas profesionales
    		// o incluso un mecanismo para balancear las cuentas profesionales entre varios
    		// dominios
    		
    		loadRequestNull(request, oParams, ""); 
 		
    		oParams.put("DomainNm", "");
  		
		if (true) DebugFile.writeln("bsh_exec checkpoint 2");
  		
        	if (true) DebugFile.writeln("bsh_exec checkpoint 5");
            
  		try {
    			if (b3Tiers) {
      			 if (true) DebugFile.writeln("bsh_exec 3 tier mode");
      				oIntr = JInterpreterFactory.createInterpreter(oEnvProps);
    			}
    			else {
      				if (true) DebugFile.writeln("bsh_exec 2 tier mode");

      				oIntr = JInterpreterFactory.createInterpreter(GlobalDBBind);
    			}

    			if (true) DebugFile.writeln("bsh_exec checkpoint 6");

    			oIntr.connect("DefaultConnection");  
    			oIntr.connect("AlternativeConnection");

    			if (true) DebugFile.writeln("bsh_exec checkpoint 7");
    
    			   			
    			oRetVal = ( Properties )oIntr.eval(sScript, oParams);
    				
    			//oRetVal = "5";

    			if (true) DebugFile.writeln("bsh_exec checkpoint 8");

    			oIntr.commit("AlternativeConnection");
    			oIntr.commit("DefaultConnection");        
    			
  		}
  		catch (JInterpreterException e) {
  			if (true) DebugFile.writeln("bsh_exec checkpoint 9");
    			//oRetVal = e.getMessage();
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
 
		 _ExisteError = 0; 
 		 sErrorScript = oRetVal.getProperty("sCodError");
 		 if ( sErrorScript.equalsIgnoreCase("0") == true )
 		 {
  			_sUserId = oRetVal.getProperty("sIdObjetoOK");
 		 } 	
 		 else
 		 {
 			sMensajeScript = oRetVal.getProperty("sMessage");
 			_ExisteError = 2;
 		 }
  		
  		
  		
  		
  		
  		if (true) DebugFile.writeln("bsh_exec checkpoint 10:Recogemos valor sUserId : " + _sUserId + " -");
  		
  		  		
  		//fin de creacion de usuario
        
        
 
 

DebugFile.writeln("usuario creado");

  
 if (_ExisteError != 0) 
 {
   switch (_ExisteError) {
 
     case 2:
      	DebugFile.writeln("usuario creado pero error2");
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=No se pudo crear el usuario&desc=" + sMensajeScript +  "&resume=_back"));  
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
    		
  oParams.put("sGuUser", _sUserId);
  
  //por seguridad estos parametros no se cogen del formulario
  oParams.put("sTpAccount", "P");
  oParams.put("iMaxUsers", "1");
  		
      
  
 
 if (true) DebugFile.writeln("bsh_exec ccuenta checkpoint 2" + oParams);

 
 if (true) DebugFile.writeln("bsh_exec ccuenta checkpoint 5");
            
 try {
   if (b3Tiers) {
    	if (true) DebugFile.writeln("bsh_exec 3 ccuenta tier mode");
		oIntr = JInterpreterFactory.createInterpreter(oEnvProps);
   }
   else {
   	if (true) DebugFile.writeln("bsh_exec 2 ccuenta tier mode");
		oIntr = JInterpreterFactory.createInterpreter(GlobalDBBind);
   } 	

    if (true) DebugFile.writeln("bsh_exec ccuenta checkpoint 6");

    oIntr.connect("DefaultConnection");  
    oIntr.connect("AlternativeConnection");

    if (true) DebugFile.writeln("bsh_exec ccuenta checkpoint 7");
    
    oRetVal = ( Properties ) oIntr.eval(sScript, oParams);
    				
    if (true) DebugFile.writeln("bsh_exec ccuenta checkpoint 8");

    
    oIntr.commit("AlternativeConnection");
    oIntr.commit("DefaultConnection");        
    
    			
 } 
 catch (JInterpreterException e) {
    if (true) DebugFile.writeln("bsh_exec ccuenta checkpoint 9");
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
 
 _ExisteError = 0; 
 sErrorScript = oRetVal.getProperty("sCodError");
 if ( sErrorScript.equalsIgnoreCase("0") == true )
 {
  	_sIdAccount = oRetVal.getProperty("sIdObjetoOK");
 } 	
 else
 {
 	sMensajeScript = oRetVal.getProperty("sMessage");
 	_ExisteError = 3;
 }	
 		
 if (true) DebugFile.writeln("bsh_exec checkpoint 10:Recogemos valor sIdAccount : " + _sIdAccount + " -");
   			
 if (_ExisteError != 0) 
 {
   switch (_ExisteError) {
 
      case 3:
        response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=No se pudo crear la cuenta&desc=" + sErrorScript + "//" + sMensajeScript + "&resume=_back"));  
        return;
      
      
    }
 
 
 }
 
  		
 //fin de creacion de cuenta

//actualizacion de los valores de k_users con datos de la cuenta

    PreparedStatement oStmt = oConnJS.prepareStatement("UPDATE " + DB.k_users + " SET " + DB.id_account + "=? WHERE " + DB.gu_user + "=?");
    oStmt.setString(1, _sIdAccount);
    oStmt.setString(2, _sUserId);  
    oStmt.executeUpdate();	
    oStmt.close();	

        
oConnJS.close("account_store_prof");
%>
      
