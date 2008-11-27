/**
  * Crea una cuenta provisionando los siguientes datos minimos
  * Es necesario que haya un usuario previo creado
  
  * Parametros externos
  @param sGuUser 	Usuario Profesional o Usuario se promocionó desde cuenta gratuita 
  @param sTpAccount 	Tipo de la cuenta P=Profesional C=corporativa
  @param iMaxUsers 	Numero máximo de usuarios de la cuenta
  @param sSnPassport 	Nº de documento legal del contratante
  @param sTpPassport 	Tipo de documento legal {DNI,NIF,CIF,...}
  @param sTpBilling 	Tipo de opción de cobro { T=Tarjeta, B=Banco, ... } 
  
  * Parametros calculados
  //param sNewIdAccount id de la cuenta
  //param iDomain 	Id del dominio a que pertenece el usuario
  //param sGuWorkarea 	guid de la workarea del usuario  

  * Parametros respuesta
  //param sCodError   		codigo de error (0->ok, 1->ko)
  //param sIdObjetoOK 		id_cuenta del nuevo dominio si sCodError = 0 sino ""
  //param sMessage 		Mensaje de exito si sCodError = 0 o de error si sCodError = 1	

**/

  
  import java.io.IOException;
  
  import java.sql.SQLException;
  import java.sql.Connection;
  import java.sql.PreparedStatement;
  import java.util.Properties;
  
  import com.knowgate.dataobjs.DB;
  import com.knowgate.dataobjs.DBAudit;  
  import com.knowgate.dataobjs.DBBind;
  import com.knowgate.dataobjs.DBSubset;
  import com.knowgate.datacopy.DataStruct;
  import com.knowgate.acl.*;  
  import com.knowgate.misc.Environment;
  import com.knowgate.misc.Gadgets;
  import com.knowgate.dfs.FileSystem;  
  import com.knowgate.billing.*;  
  
        
  //Recogida de parámetros externos
  String XinsGuUser 	= sGuUser;	
  String XinsTpAccount 	= sTpAccount;	
  String XiniMaxUsers	= iMaxUsers;	
  String XinsSnPassport	= sSnPassport;	
  String XinsTpPassport = sTpPassport;		
  String XinsTpBilling 	= sTpBilling;		
  
  ReturnValue = new Properties();
  
  //Valores por defecto si se recibe null
  
  if (0 == XinsTpAccount.length())
  	XinsTpAccount = "P";
  	
  if (0 == XiniMaxUsers.length())
  	XiniMaxUsers = "1";
  	
  if (0 ==XinsSnPassport.length())
  	XinsSnPassport = "dni";
  	
  if (0 == XinsTpPassport.length())
  	XinsTpPassport = "D";
  	
  if (0 == XinsTpBilling.length())
    	XinsTpBilling = "T";
  
  //***********************************
  
  //** Parámetros calculados ** //
  String XcsNewIdAccount = Gadgets.generateUUID().substring(22,32);
  
  
      

  //infraestructura necesarias para operaciones con DataStruct
  Object[] oPKOr = {null};
  Object[] oPKTr = {null};
  
  
    
  //Obtener variables de la aplicación
  String sStorage = Environment.getProfileVar("hipergate", "storage");
  
  
  //infraestructura necesarias para operaciones con DataStruct
  Properties oParams = new Properties();
  DataStruct oDS = new DataStruct();
  
  try {

    
    
     
    DefaultConnection.setReadOnly(true);
    DefaultConnection.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
    
    // Código de acceso a datos
    oDS.setOriginConnection(DefaultConnection);
    oDS.setTargetConnection(AlternativeConnection);

    AlternativeConnection.setAutoCommit (false);
    
    
    
    //Calculo de los parámetros XciDomain y XcsGuWorkarea a partir de XinsGuUser
    DBSubset oUsers;
    int iUsers;
    oUsers = new DBSubset(DB.k_users,
			       DB.id_domain + "," + DB.gu_workarea,
    			       DB.gu_user + "='" + XinsGuUser + "' " , 4);		      
    			       
    iUsers = oUsers.load(AlternativeConnection);
    
    String XciDomain = oUsers.getString(0,0);
    String XcsGuWorkarea = oUsers.getString(1,0); 
  
  
    //ReturnValue = "Account ('" + XcsNewIdAccount + "','" + XinsTpAccount + "','" + XiniMaxUsers + "','" + XinsSnPassport + "','" + XciDomain + "','" + XcsGuWorkarea + "') añadido con exito.";
    
    ReturnValue.put("sCodError", "0");
    ReturnValue.put("sMessage", "Account ('" + XcsNewIdAccount + "','" + XinsTpAccount + "','" + XiniMaxUsers + "','" + XinsSnPassport + "','" + XciDomain + "','" + XcsGuWorkarea + "') añadido con exito.");
    ReturnValue.put("sIdObjetoOK", XcsNewIdAccount);
    
    //Cargar los parámetros para luego pasarlos al script
    
    oParams.put("sGuUser", XinsGuUser);
    oParams.put("sTpAccount", XinsTpAccount);
    oParams.put("iMaxUsers", XiniMaxUsers);
    oParams.put("sSnPassport", XinsSnPassport);
    oParams.put("sTpPassport", XinsTpPassport);
    oParams.put("sTpBilling", XinsTpBilling);
    oParams.put("iDomain", XciDomain);
    oParams.put("sGuWorkarea", XcsGuWorkarea);
    oParams.put("sNewIdAccount", XcsNewIdAccount);
    
    
  
    // Inserta la nueva cuenta
    oDS.parse(sStorage + "/scripts/account_create.xml", oParams);	           
        
    
    oDS.insert(oPKOr, oPKTr, 1);   
    
    

    //oDS.clear();	           
  
    // *****************************************************
    // TO DO : Código para activar el usuario
    
    
    // *****************************************************
    // TO DO : Código para actualizar el id_account del usuario
    
     
    DBAudit.log(AlternativeConnection, Account.ClassId, "Acc", "unknown", "0", null, 0, 0, null, null);
  
    
     
  }
 
  catch (SQLException e) {  
    //ReturnValue = "ERROR: " + e.getMessage();
    ReturnValue.put("sCodError", "1");
    ReturnValue.put("sMessage", "ERROR: " + e.getMessage());
    ReturnValue.put("sIdObjetoOK", "");
    
  }
  
