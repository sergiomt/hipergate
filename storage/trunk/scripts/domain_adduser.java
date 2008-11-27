/**
  * Añade al dominio DomainNm un nuevo usuario con nickname NuevoNickName
  @param NuevoNickName nickname del nuevo usuario
  @param NuevoMainmail mail del nuevo usuario
  @param NuevaPwd password del usuario
  @param DomainNm nm_domain del dominio al que se añade

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
  
  
  //aqui faltaría por pillar el usuario fuente
  //dependiendo del dominio y de los permisos que se quieran dar
  //ahora mismo se está utilizando el superusuario del dominio profe (1050)
  //gu_user de superusuario del dominio PROFE (1050)
  String GU_USER_SUPER_USUARIO_1050 =  "c0a80146f5691b9dbe10000eb39331dd";
  
    
  //Recogida de parámetros del script y construccion de datos necesarios
  String iSourceDomainNm = "PROFE";
  String iSourceDomainId = "1050";
  
  String iTargetDomainNm = DomainNm;
  
  ReturnValue = new Properties();
  
  if (0 == iTargetDomainNm.length())
  	iTargetDomainNm = "PROFE";
  	
   	
  String NewUserNickName = NuevoNickName;  
  
  String NewUserPwd = NuevaPwd;  
  
  if (0 == NewUserPwd.length())
  	NewUserPwd = Gadgets.generateUUID().substring(1,7);
  
  
   
  String NewUserId = Gadgets.generateUUID();  
  String NewUserMainMail = NuevoMainmail;
  String NewUserNm = "MisApellidos";
  
      
  //ReturnValue = "Usuario ('" + NewUserId + "','" + NewUserNickName + "','" + NewUserMainMail + "','" + NewUserNm + ") añadido al dominio " + DomainNm + " con exito.";
  
  //valor de retorno 
  ReturnValue.put("sCodError", "0");
  ReturnValue.put("sMessage", "Usuario ('" + NewUserId + "','" + NewUserNickName + "','" + NewUserMainMail + "','" + NewUserNm + ") añadido al dominio " + DomainNm + " con exito.");
  ReturnValue.put("sIdObjetoOK", NewUserId);
  

  String iSourceUser = new String(GU_USER_SUPER_USUARIO_1050);
  String iTargetUser = new String(NewUserId);
  


  Object[] oPKOr = {null};
  Object[] oPKTr = {null };
  
  
    
    
  String sStorage = Environment.getProfileVar("hipergate", "storage");
  
  
  
  Properties oParams = new Properties();
  DataStruct oDS = new DataStruct();
  
      

  try {

    
    DefaultConnection.setReadOnly(true);
    DefaultConnection.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
    
    // Código de acceso a datos
    oDS.setOriginConnection(DefaultConnection);
    oDS.setTargetConnection(AlternativeConnection);

    AlternativeConnection.setAutoCommit (false);
    
    
    //obtencion del id_domain a traves del nombre
    DBSubset oDomains;
    int iDomains;
    oDomains = new DBSubset(DB.k_domains,
			       DB.id_domain + "," + DB.nm_domain,
    			       "LOWER(" + DB.nm_domain + ")='" + iTargetDomainNm.toLowerCase() + "' " , 4);		      
    			       
    iDomains = oDomains.load(AlternativeConnection);
    String iTargetDomainId = oDomains.getString(0,0);
     
    //ReturnValue = iTargetDomainId;
    
    oParams.put("OldUserId", iSourceUser);
    oParams.put("NewUserId", NewUserId);
    oParams.put("NewUserNickName", NewUserNickName);
    oParams.put("NewUserMainMail", NewUserMainMail);
    oParams.put("NewUserNm", NewUserNm);
    oParams.put("iTargetDomain", iTargetDomainId.toString());
    oParams.put("iSourceDomainNm", iSourceDomainNm);
    oParams.put("NewUserPwd", NewUserPwd);
  
    // Inserta el nuevo usuario
    oDS.parse(sStorage + "/scripts/domain_adduser.xml", oParams);	           
        
    oDS.insert(oPKOr, oPKTr, 1);   

    oDS.clear();	           
  
    // Inserta la nueva workarea
    oDS.parse(sStorage + "/scripts/domain_addworkarea.xml", oParams);	           
        
    oDS.insert(oPKOr, oPKTr, 1);   
    
    // *****************************************************
    // Código para asignar ls categorías home a cada usuario

    PreparedStatement oStmt;
    DBSubset oCategories;
    int iCategories;
    int iUnderscore;
    String sCatName;
    String sGuCategory;
    String sNickName;

    
    // Leer la categoría padre del nuevo usuario
    
    oCategories = new DBSubset(DB.k_categories,
			       DB.gu_category + "," + DB.nm_category,
    			       DB.gu_owner + "='" + iTargetUser.toString() + "' AND " + DB.nm_category + " like '%" + NewUserNickName.toString() + "'  ", 4);		      
    
    
    iCategories = oCategories.load(AlternativeConnection);

    
    // Para cada categoría buscar un usuario cuyo nick coincida con el final del nombre de la categoria
    // Es decir, el matching entre las categorías creadas y los usuarios creados se hace usando el
    // convenio del campo nm_category de tener la forma DOMINIO_usuario_categoria
    
      
    oStmt = AlternativeConnection.prepareStatement("UPDATE " + DB.k_users + " SET " + DB.gu_category + "=? WHERE " + DB.id_domain + "=" + iTargetDomainId.toString() + " AND " + DB.tx_nickname + "=?");
    
    
    for (int c=0; c<iCategories; c++) {
    
      sCatName = oCategories.getString(1,c);
      sGuCategory = oCategories.getString(0,c);
      iUnderscore = sCatName.indexOf("_");
      if (iUnderscore>0) {
        sNickName = sCatName.substring(iUnderscore+1);
        
        oStmt.setString(1, oCategories.getString(0,c));
        oStmt.setString(2, NewUserNickName);
	oStmt.executeUpdate();
      } // fi()
     
    } // next (c)    
    oStmt.close();
    
    // *****************************************************
        
    //crear la estructura de directorio para las aplicaciones
    
    DBSubset oWorkAreas;
    int iWorkAreas;
    String iWorkAreaId;
    oWorkAreas = new DBSubset(DB.k_workareas,
			    DB.gu_workarea + "," + DB.nm_workarea,
    			    DB.id_domain + "=" + iTargetDomainId + " AND " + DB.gu_owner + "= '" + NewUserId + "'"   , 4);		      
    			       
    iWorkAreas = oWorkAreas.load(AlternativeConnection);
    String iWorkAreaId = oWorkAreas.getString(0,0);
    
    //pillar el gu_workarea source (workarea por defecto del user que se copia)
    oWorkAreas = new DBSubset(DB.k_users,
			    DB.gu_workarea,
    			    DB.gu_user + "='" + iSourceUser + "'"   , 4);		      
    			       
    iWorkAreas = oWorkAreas.load(AlternativeConnection);
    String iWorkAreaSourceId = oWorkAreas.getString(0,0);
    
    //////
    
    
    
    
    java.io.File oFileDir;
    
    String Base_path_A_crear = sStorage + "/domains/" + iTargetDomainId.toString() + "/workareas";  
    String Path_workarea_a_crear = Base_path_A_crear + "/" + iWorkAreaId + "/apps";
    String Path_MailWireData_a_crear = Path_workarea_a_crear + "/Mailwire/data";
    String Path_MailWireHtml_a_crear = Path_workarea_a_crear + "/Mailwire/html";
    String Path_MailWireDataImages_a_crear = Path_workarea_a_crear + "/Mailwire/data/images/thumbs";
    
    
    String Path_WebBuilderData_a_crear = Path_workarea_a_crear + "/WebBuilder/data/images/thumbs";
    String Path_WebBuilderHtml_a_crear = Path_workarea_a_crear + "/WebBuilder/html";
    
       
    //creación de directorios
    oFileDir = new File (Path_MailWireHtml_a_crear);
    if (!oFileDir.exists()) oFileDir.mkdirs();
    
    oFileDir = new File (Path_MailWireDataImages_a_crear);
    if (!oFileDir.exists()) oFileDir.mkdirs();
    
    oFileDir = new File (Path_WebBuilderData_a_crear);
    if (!oFileDir.exists()) oFileDir.mkdirs();
    
    oFileDir = new File (Path_WebBuilderHtml_a_crear);
    if (!oFileDir.exists()) oFileDir.mkdirs();
    
    oFileDir = null;
    //////fin creacion de directorios
    
    
    //copia de archivos
    
    FileSystem oFileSystem;
    oFileSystem = new FileSystem(Environment.getProfile("hipergate"));
    oFileSystem.os(FileSystem.OS_UNIX);
    
    /*
    String Base_path_Source = Base_path_A_crear; 
    String Path_workarea_Source = Base_path_Source + "/" + iWorkAreaSourceId + "/apps";
    String Path_MailWireData_Source = Path_workarea_Source + "/Mailwire/data";
    String Path_MailWireHtml_Source = Path_workarea_Source + "/Mailwire/html";
    String Path_MailWireDataImages_Source = Path_workarea_Source + "/Mailwire/data/images/thumbs";
    */
    
    
    //pillar las pagesets de la workarea source para pillar los nombres de los archivos xml y copiarlos
    //a la nueva workarea
    
    DBSubset oPageSets, oPageSetTarget;
    int iPageSets, iPageSetTarget;
    String sNmPageset, sFile, sPathData, sPathDataNew, sGuPageSetSource, sGuPageSetTarget;
    PreparedStatement oStmt;
    
    oStmt = AlternativeConnection.prepareStatement("UPDATE " + DB.k_pagesets + " SET " + DB.path_data + "=? WHERE " + DB.gu_workarea + "=? AND " + DB.path_data + "=?");
    
    
    oPageSets = new DBSubset(DB.k_pagesets,
			    DB.gu_pageset + "," + DB.nm_pageset + "," + DB.path_data,
    			    DB.gu_workarea +  "= '" + iWorkAreaSourceId + "'"   , 4);		      
    			       
    iPageSets = oPageSets.load(AlternativeConnection);
    
    for (int c=0; c<iPageSets; c++) {
    
      sGuPageSetSource = oPageSets.getString(0,c);    
      sNmPageset = oPageSets.getString(1,c);
      sFile = sNmPageset + ".xml";
      sPathData = oPageSets.getString(2,c);
      
      //String sSourceURI = "file://" + Path_MailWireData_Source + "/" + sFile; 
      String sSourceURI = "file://" + sPathData; 
      //String sTargetURI = "file://" + Path_MailWireData_a_crear + "/" + sFile; 
      String sTargetURI = Gadgets.replace(sSourceURI,"([a-z]|[A-Z]|[0-9]){32}", iWorkAreaId);
      String sTargetURI = Gadgets.replace(sTargetURI,"/" + iSourceDomainId + "/", "/" + iTargetDomainId + "/");	
      String sPathDataNew = Gadgets.replace(sTargetURI,"file://", "");	
    
      //obtenemos el nuevo gu_pageset
      
      oPageSetTarget = new DBSubset(DB.k_pagesets,
			    DB.gu_pageset ,
    			    DB.gu_workarea +  "= '" + iWorkAreaId + "' AND " + DB.path_data + "='" + sPathData + "'" , 4);		      
    			       
      iPageSetTarget = oPageSetTarget.load(AlternativeConnection);
      
      sGuPageSetTarget = oPageSetTarget.getString(0,0);
      
  
    //Leemos el fichero xml, sustituimos el guid=gu_pageset por el gu_pageset nuevo y escribimos el nuevo fichero
      
      //esto peta despues de vacaciones 
      //lo comentamos por ahora
      
      /*
      File oFile = new File(sPathData);
      File oFileOut = new File(sPathDataNew);

    FileInputStream oStream = new FileInputStream(oFile);
    FileOutputStream oStreamOut = new FileOutputStream(oFileOut);
    Long lLength = new Long(oFile.length());
    byte[] aBytes = new byte[lLength.intValue()];
    oStream.read(aBytes);
    String sPageSetSourceData = new String(aBytes);
  
    sPageSetSourceData = Gadgets.replace(sPageSetSourceData, sGuPageSetSource , sGuPageSetTarget);
    
    //sTemplateData = Gadgets.replace(sTemplateData,":gu_microsite",GU_MICROSITE);
        
    oStreamOut.write(sPageSetSourceData.getBytes());
    oStreamOut.close();
    
    */// fin comentario despues de vacaciones
      
      
      
      
      //Actualizar el campo path_data de cada pageset nueva
      oStmt.setString(1, sPathDataNew);
      oStmt.setString(2, iWorkAreaId);
      oStmt.setString(3, sPathData);
      oStmt.executeUpdate();
      
               
      //ReturnValue += "<br>" + sSourceURI + "--->" + sTargetURI;
      
      /*
      try {
        
        //oFileSystem.copy (sPathWorkAreasPutSource,sPathWorkAreasPutTarget);  
      }
      catch (IOException ioe) {
    	ReturnValue = "ERROR: " + ioe.getMessage() + " oFileSystem.copy (" + sSourceURI + "," + sTargetURI + ")";      
      }
   	*/
   	
    }
    /////

    
    oStmt.close();	


    //copiar imagenes por defecto
      String sVarWorkAreasPut = "file://" + Environment.getProfileVar("hipergate", "workareasput");
      String sPathWorkAreasPutSource = sVarWorkAreasPut + "/" + iWorkAreaSourceId + "/apps/Mailwire/data/images/";
      String sPathWorkAreasPutTarget = sVarWorkAreasPut + "/" + iWorkAreaId + "/apps/Mailwire/data/";
      
      try {
        
        oFileSystem.copy (sPathWorkAreasPutSource,sPathWorkAreasPutTarget);  
      }
      catch (IOException ioe) {
    	ReturnValue = "ERROR: " + ioe.getMessage() + " oFileSystem.copy (" + sPathWorkAreasPutSource + "," + sPathWorkAreasPutTarget + ")";      
      }

    oFileSystem = null;    
    
    /////fin copia de archivos
    
    //actualizar campo gu_workarea en k_users
    oStmt = AlternativeConnection.prepareStatement("UPDATE " + DB.k_users + " SET " + DB.gu_workarea + "=? WHERE " + DB.gu_user + "=?");
    oStmt.setString(1, iWorkAreaId);
    oStmt.setString(2, NewUserId);  
    oStmt.executeUpdate();	
    oStmt.close();	

    
    //DBAudit.log(AlternativeConnection, ACLDomain.ClassId, "NDOM", "unknown", "0", null, 0, 0, null, null);
  
     
  }
 
  catch (SQLException e) {  
    //ReturnValue = "ERROR: " + e.getMessage();
    ReturnValue.put("sCodError", "1");
    ReturnValue.put("sMessage", "ERROR: " + e.getMessage());
    ReturnValue.put("sIdObjetoOK", "");
  }


