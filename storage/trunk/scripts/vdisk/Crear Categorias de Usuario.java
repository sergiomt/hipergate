/**
  * Crear las categorías asociadas a un usuario
  * @param UserId GUID del usuario propietario de las categorías
  * @param TxNick Nick del usuario propietario de las categorías
  * @param DomainId ID del dominio al cual pertenece el usuario
**/  

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Connection;
import java.util.Properties;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBAudit;  
import com.knowgate.dataobjs.DBBind;

import com.knowgate.acl.ACL;
import com.knowgate.acl.ACLDomain;
import com.knowgate.hipergate.Category;
import com.knowgate.hipergate.CategoryLabel;

ReturnValue = "";

Integer iOne = new Integer(1);
Short iTrue = new Short((short)1);

// *********************************************************************
// Obtener la información del dominio al que pertenece el usuario:
// nombre, administrador, grupo de administradores, etc.
ACLDomain oDomain = new ACLDomain(DefaultConnection, new Integer(DomainId.toString()).intValue());
String sDomainNm = oDomain.getStringNull(DB.nm_domain,"noname");

if (sDomainNm.length()>0) {

  // *********************************************************************
  // Obtener el identificador unico de la categoria padre de usuarios para
  // el dominio al que pertenece el usuario propietario de la categoria.
  // La categoría padre se busca directamente usando un convenio en el
  // nombre fijado a capón que es = "DOMINIO_USERS".
   
  String sParentId = Category.getIdFromName(DefaultConnection, sDomainNm + "_" + "USERS");
  
  if (sParentId!=null) {
    // ***********************************************
    // Crear las categorias personales para el usuario
    
    String sDomainNick = sDomainNm + "_" + TxNick; // Nick combinado de dominio + usuario
    String sCatgId; // Variable intermedia que mantiene los GUIDs de las categorías según se van creando para crear las etiquetas de traducción
    
    // Crear la categoría home del usuario
    String sHomeId = Category.create(DefaultConnection, new Object[] { sParentId, UserId, sDomainNick, iTrue, iOne, "mydesktopc_16x16.gif", "mydesktopc_16x16.gif" });
    
    DBAudit.log(DefaultConnection, Category.ClassId, "NCAT", UserId, sHomeId, sParentId, 0, 0, sDomainNick, null);
    
    // Asignar etiquetas de nombres traducidos a la categoría home
    CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "es", TxNick, null });
    CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "en", TxNick, null });
    
    // Crear la categoría documentos del usuario
    sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_docs", iTrue, iOne, "docsclosed_16x16.gif", "docsopen_16x16.gif" });
    
    DBAudit.log(DefaultConnection, Category.ClassId, "NCAT", UserId, sCatgId, sHomeId, 0, 0, sDomainNick + "_docs", null);
    
    // Asignar etiquetas de nombres traducidos a la categoría documentos
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "documentos", null });
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "documents", null });
    
    // Crear la categoría favoritos del usuario
    sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_favs", iTrue, iOne, "folderfavsc_16x16.gif", "folderfavso_16x16.gif" });
    
    DBAudit.log(DefaultConnection, Category.ClassId, "NCAT", UserId, sCatgId, sHomeId, 0, 0, sDomainNick + "_favs", null);
    
    // Asignar etiquetas de nombres traducidos a la categoría favoritos
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "favoritos", null });
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "favourites", null });
    
    // Crear la categoría temp del usuario
    sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_temp", iTrue, iOne, "foldertempc_16x16.gif", "foldertempo_16x16.gif" });
    
    DBAudit.log(DefaultConnection, Category.ClassId, "NCAT", UserId, sCatgId, sHomeId, 0, 0, sDomainNick + "_temp", null);
    
    // Asignar etiquetas de nombres traducidos a la categoría temp
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "temp", null });
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "temp", null });
    
    // Crear la categoría emails del usuario
    sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_email", iTrue, iOne, "myemailc_16x16.gif", "myemailo_16x16.gif" });
    
    DBAudit.log(DefaultConnection, Category.ClassId, "NCAT", UserId, sCatgId, sHomeId, 0, 0, sDomainNick + "_email", null);
    
    // Asignar etiquetas de nombres traducidos a la categoría emails
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "correos", null });
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "emails", null });
    
    // Crear la categoría recycled del eliminados
    sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_recycled", iTrue, iOne, "recycledfull_16x16.gif", "recycledfull_16x16.gif" });
    
    DBAudit.log(DefaultConnection, Category.ClassId, "NCAT", UserId, sCatgId, sHomeId, 0, 0, sDomainNick + "_recycled", null);
    
    // Asignar etiquetas de nombres traducidos a la categoría eliminados
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "eliminados", null });
    CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "deleted", null });
    
    
    // *****************************************************************************
    // Establecer la referencia a la categoria home del usuario
    oStmt = DefaultConnection.createStatement();
    oStmt.executeUpdate("UPDATE " + DB.k_users + " SET " + DB.gu_category + "='" + sHomeId + "' WHERE " + DB.gu_user + "='" + UserId + "'");
    oStmt.close();
    
    // *****************************************************************************
    // Asignar y propagar permisos desde la categoria home del usuario recien creado
    
    Category oCatg = new Category(sHomeId);
    
    // Asignar permisos al usuario actual    
    oCatg.setUserPermissions(DefaultConnection, UserId, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, iTrue.shortValue(), (short) 0);
    
    // Asignar permisos al usuario administrador del dominio
    oCatg.setUserPermissions(DefaultConnection, oDomain.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, iTrue.shortValue(), (short) 0);
    
    // Asignar permisos al grupo de administradores del dominio
    oCatg.setGroupPermissions(DefaultConnection, oDomain.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, iTrue.shortValue(), (short) 0);
    
    oCatg = null;
  }
  else
    ReturnValue = "ERROR: Category " + sDomainNm + "_USERS not found";  
}
else
  ReturnValue = "ERROR: Domain not found";  
