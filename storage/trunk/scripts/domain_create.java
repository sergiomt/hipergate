/**
  * Crea un dominio clonado del dominio MODEL
  @param DomainId GUID del nuevo dominio (si "" entonces se calcula uno aleatorio entre 1670 y 524287 )
  @param DomainNm nm_domain del nuevo dominio

  * Parametros respuesta
  //param sCodError   		codigo de error (0->ok, 1->ko)
  //param sIdObjetoOK 		id_domain del nuevo dominio si sCodError = 0 sino ""
  //param sMessage 		Mensaje de exito si sCodError = 0 o de error si sCodError = 1
  //param sGuUserAdmin 		gu_user del administrador del dominio
	
**/



  import java.sql.SQLException;
  import java.sql.Connection;
  import java.sql.PreparedStatement;
  import java.util.Properties;
  import java.lang.Math;
  import java.lang.Number;
  
  import com.knowgate.dataobjs.DB;
  import com.knowgate.dataobjs.DBAudit;  
  import com.knowgate.dataobjs.DBBind;
  import com.knowgate.dataobjs.DBSubset;
  import com.knowgate.datacopy.DataStruct;
  import com.knowgate.acl.ACLDomain;  
  import com.knowgate.misc.Environment;
  import com.knowgate.hipergate.datamodel.ModelManager;

  // Dominio Modelo a clonar (no cambiar)
  int MODEL = 1025;
  
  // Parametros del nuevo dominio
  //String NewDomainId = "1032" ;  // NO PONER AQUÍ 1024 NI 1025 O TE CARGAS LOS DOMINIOS BUENOS
  //String NewDomainNm = "TEST5";
  
  String NewDomainId = String.valueOf( DBBind.nextVal(AlternativeConnection, "seq_k_domains") );
  String NewDomainNm = DomainNm;
  
  
  /* Código antiguo de generación automática
  double iRandValue = Math.random();
  //valores tomados de k_sequences
  //int iMinValue = 1026;
  //ponemos un numero suficientemente grande para que no pise los dominios anteriores
  int iMinValue = 1670;
  int iMaxValue = 524287;
  
  //calculo del id_domain aleatorio entre iMinValue e iMaxValue
  double iNewDomainId =  Math.round( iRandValue * (iMaxValue-iMinValue) )  + iMinValue ;
    //to do : hay que evitar colisiones
  
  //Valores por defecto si se recibe null
  if (0 == NewDomainId.length())
    	NewDomainId =  String.valueOf( (int) iNewDomainId);
  	//NewDomainId =  "524288";
  */
  
  
  //valor de retorno 
  ReturnValue = new Properties();
  
  ReturnValue.put("sCodError", "0");
  ReturnValue.put("sMessage", "Dominio (" + NewDomainId + "," + NewDomainNm + ") creado con exito.");
  ReturnValue.put("sIdObjetoOK", NewDomainId);
  
  
  Integer iSourceDomain = new Integer(MODEL);
  //Integer iTargetDomain = new Integer(NewDomainId);
  Integer iTargetDomain = new Integer(NewDomainId);
  
  Object[] oPKOr = { iSourceDomain };
  Object[] oPKTr = { iTargetDomain };
    
  String sStorage = Environment.getProfileVar("hipergate", "storage");
    
  Properties oParams = new Properties();
  oParams.put("DomainId", iTargetDomain.toString());
  oParams.put("DomainNm", NewDomainNm);
  
  DataStruct oDS = new DataStruct();
  //oDS.parse(sStorage + "/scripts/domain_clon.xml", oParams);
     oDS.parse(ModelManager.getResourceAsString("scripts/domain_clon.xml"), oParams);

  try {

    
    DefaultConnection.setReadOnly(true);
    DefaultConnection.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
    
    // Código de acceso a datos
    oDS.setOriginConnection(DefaultConnection);
    oDS.setTargetConnection(AlternativeConnection);

    AlternativeConnection.setAutoCommit (false);
    
        
    oDS.insert(oPKOr, oPKTr, 1);   
  
    
    // *****************************************************
    // Código para asignar ls categorías home a cada usuario

    PreparedStatement oStmt;
    DBSubset oCategories;
    int iCategories;
    int iUnderscore;
    String sCatName;
    String sNickName;

      
    // Leer todas las categorías del nuevo dominio    
    oCategories = new DBSubset(DB.k_categories,
			       DB.gu_category + "," + DB.nm_category,
    			       DB.gu_owner + " IN (SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.id_domain + "=" + iTargetDomain.toString() + ") ", 4);
    iCategories = oCategories.load(AlternativeConnection);

    
    // Para cada categoría buscar un usuario cuyo nick coincida con el final del nombre de la categoria
    // Es decir, el matching entre las categorías creadas y los usuarios creados se hace usando el
    // convenio del campo nm_category de tener la forma DOMINIO_usuario_categoria
    
      
    oStmt = AlternativeConnection.prepareStatement("UPDATE " + DB.k_users + " SET " + DB.gu_category + "=? WHERE " + DB.id_domain + "=" + iTargetDomain.toString() + " AND " + DB.tx_nickname + "=?");
    
    
    for (int c=0; c<iCategories; c++) {
    
      sCatName = oCategories.getString(1,c);
      iUnderscore = sCatName.indexOf("_");
      if (iUnderscore>0) {
        sNickName = sCatName.substring(iUnderscore+1);
        
        oStmt.setString(1, oCategories.getString(0,c));
        oStmt.setString(2, sNickName);
	oStmt.executeUpdate();
      } // fi()
     
    } // next (c)    
    oStmt.close();
    
    // *****************************************************
    
    //Calculo del usuario admin del nuevo dominio y pasarlo en ReturnValue
    //Necesario para la creación de accounts
    
    DBSubset oDomains;
    int iDomains;
    oDomains = new DBSubset(DB.k_domains,
			  DB.gu_owner ,
    			  DB.id_domain + "=" + NewDomainId  , 4);		      
    			       
    iUsers = oDomains.load(AlternativeConnection);
    
    String sGuUserAdmin = oDomains.getString(0,0);
    ReturnValue.put("sGuUserAdmin", sGuUserAdmin);
  
        
    DBAudit.log(AlternativeConnection, ACLDomain.ClassId, "NDOM", "unknown", "0", null, 0, 0, null, null);
  
    
  }
 
  catch (SQLException e) {  
    //ReturnValue = "ERROR: " + e.getMessage();
    ReturnValue.put("sCodError", "1");
    ReturnValue.put("sMessage", "ERROR: " + e.getMessage());
    ReturnValue.put("sIdObjetoOK", "");
  }


