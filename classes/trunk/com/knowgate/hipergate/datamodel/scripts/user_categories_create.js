
// Create Default Categories for a user
// param UserId User GUID
// param DefaultConnection Database Connection

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Connection;
import java.util.Properties;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBAudit;  
import com.knowgate.dataobjs.DBBind;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.*;
import com.knowgate.hipergate.Category;
import com.knowgate.hipergate.CategoryLabel;

ReturnValue = "";

Integer iOne = new Integer(1);
Short iTrue = new Short((short)1);

try {
  ACLUser oUser = new ACLUser (DefaultConnection, UserId);
  
  // ************************************************
  // Get information about the Domain:
  // Name, Administrator, Administrator Groups, etc.
  
  ACLDomain oDomain = new ACLDomain(DefaultConnection, oUser.getInt(DB.id_domain));
  String sDomainNm = oDomain.getStringNull(DB.nm_domain,"noname");
  
  if (sDomainNm.length()>0) {
  
    // ********************************************
    // Get GUID for Category named DOMAINNAME_USERS
     
    String sParentId = Category.getIdFromName(DefaultConnection, sDomainNm + "_" + "USERS");
    
    if (sParentId!=null) {
      // **********************
      // Create User Categories
      
      String sTxNick = oUser.getString(DB.tx_nickname);
      
      String sDomainNick = sDomainNm + "_" + sTxNick; // Combined nick of domain + user
      
      String sCatgId; // Intermediate Varaible for holding categories GUIDs as they are created
      
      // Create Home Category for User
      String sHomeId = Category.create(DefaultConnection, new Object[] { sParentId, UserId, sDomainNick, iTrue, iOne, "mydesktopc_16x16.gif", "mydesktopc_16x16.gif" });
          
      // Assign translated labels for Home Category
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "es", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "en", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "de", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "it", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "fr", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "pt", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "ru", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "fi", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "cn", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "tw", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "ca", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "eu", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "ja", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "pl", sTxNick, null });
      CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, "sk", sTxNick, null });

      // Create Documents Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_docs", iTrue, iOne, "docsclosed_16x16.gif", "docsopen_16x16.gif" });
          
      // Assign translated labels for Documents Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "documentos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "documents", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "documents", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "dokumente", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "dokumenti", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Документы", null });
      
      // Create Favorites Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_favs", iTrue, iOne, "folderfavsc_16x16.gif", "folderfavso_16x16.gif" });
          
      // Assign translated labels for Favourites Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "favoritos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "favourites", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "favoris", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "favoriten", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "preferiti", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Избранное", null });
      
      // Create Temp Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_temp", iTrue, iOne, "foldertempc_16x16.gif", "foldertempo_16x16.gif" });
      
      // Assign translated labels for Temp Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Временный", null });
      
      // Create e-mails Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_email", iTrue, iOne, "myemailc_16x16.gif", "myemailo_16x16.gif" });
          
      // Assign translated labels for e-mails Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "correos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "emails", null });
      
      // Create Recycled Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_recycled", iTrue, iOne, "recycledfull_16x16.gif", "recycledfull_16x16.gif" });
          
      // Assign translated labels for Recycled Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "eliminados", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "deleted", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "efface", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "geloescht", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "cancellati", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Удалённый", null });
      
      // *****************************************************************************
      // Set reference to User Home Category
      oStmt = DefaultConnection.createStatement();
      oStmt.executeUpdate("UPDATE " + DB.k_users + " SET " + DB.gu_category + "='" + sHomeId + "' WHERE " + DB.gu_user + "='" + UserId + "'");
      oStmt.close();
      
      // *******************************************
      // propagate permission from new Home Category
      
      Category oCatg = new Category(sHomeId);
      
      // Set permissions for current user
      oCatg.setUserPermissions(DefaultConnection, UserId, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, iTrue.shortValue(), (short) 0);
      
      // Set permissions for domain administrator
      oCatg.setUserPermissions(DefaultConnection, oDomain.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, iTrue.shortValue(), (short) 0);
      
      // Set permissions for domain administrators
      oCatg.setGroupPermissions(DefaultConnection, oDomain.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, iTrue.shortValue(), (short) 0);
      
      oCatg = null;

      // ******************
      // Create mailfolders

      if (DBBind.exists(DefaultConnection, DB.k_mime_msgs, "U")) {
        ACLUser oMe = new ACLUser(UserId);
        oMe.getMailRoot (DefaultConnection);                  
        oMe.getMailFolder(DefaultConnection, "inbox");
        oMe.getMailFolder(DefaultConnection, "outbox");
        oMe.getMailFolder(DefaultConnection, "drafts");
        oMe.getMailFolder(DefaultConnection, "deleted");
        oMe.getMailFolder(DefaultConnection, "sent");
        oMe.getMailFolder(DefaultConnection, "spam");
        oMe.getMailFolder(DefaultConnection, "received");        
      }
  
      ReturnValue = sHomeId;
      ErrorCode = new Integer(0);
      ErrorMessage = "Categories successfully created.";
    }
    else {
      ReturnValue = null;
      ErrorCode = new Integer(100);
      ErrorMessage = "ERROR: Category " + sDomainNm + "_USERS not found";
    }
  }
  else {
      ReturnValue = null;
      ErrorCode = new Integer(100);
      ErrorMessage = "ERROR: Domain not found";
  }
}
catch (java.sql.SQLException e) {
  ReturnValue = null;
  ErrorCode = new Integer(e.getErrorCode());
  ErrorMessage = "SQLException: " + e.getMessage();
}