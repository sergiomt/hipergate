
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
import com.knowgate.dataobjs.DBCommand;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.*;
import com.knowgate.hipergate.Category;
import com.knowgate.hipergate.CategoryLabel;
import com.knowgate.hipergate.DBLanguages;

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
      final int nLangs = DBLanguages.SupportedLanguages.length;
      for (int l=0; l<nLangs; l++) {
        CategoryLabel.create (DefaultConnection, new Object[] { sHomeId, DBLanguages.SupportedLanguages[l], sTxNick, null });      
      } // next

      // Create Documents Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_docs", iTrue, iOne, "docsclosed_16x16.gif", "docsopen_16x16.gif" });
          
      // Assign translated labels for Documents Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "documentos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "gl", "documentos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ca", "documents", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "documents", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "documents", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "dokumente", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "dokumenti", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pt", "dokumentos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pl", "dokumenty", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "no", "dokumenter", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fi", "asiakirjat", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "th", "เอกสาร", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "vn", "tài liệu", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "uk", "Документи", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Документы", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "cn", "文件", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "tw", "文件", null });
      
      // Create Favorites Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_favs", iTrue, iOne, "folderfavsc_16x16.gif", "folderfavso_16x16.gif" });
          
      // Assign translated labels for Favourites Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "favoritos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "gl", "preferidos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ca", "favorits", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "favourites", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "favoris", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "favoriten", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "preferiti", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pt", "preferidos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pl", "ulubione", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "no", "favoritter", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fi", "suosikit", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "th", "รายการโปรด", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "vn", "liên kết", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "uk", "Вибране", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Избранное", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "cn", "我的最爱", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "tw", "我的最愛", null });
      
      // Create Temp Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_temp", iTrue, iOne, "foldertempc_16x16.gif", "foldertempo_16x16.gif" });
      
      // Assign translated labels for Temp Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ca", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "gl", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pt", "temp", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pl", "tymczasowych", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "no", "midlertidig", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fi", "väliaikainen", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "th", "ชั่วคราว", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "vn", "tạm thời", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "uk", "тимчасовий", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Временный", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "cn", "临时", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "tw", "臨時", null });
      
      // Create e-mails Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_email", iTrue, iOne, "myemailc_16x16.gif", "myemailo_16x16.gif" });
          
      // Assign translated labels for e-mails Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "correos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ca", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "gl", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pt", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pl", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "no", "e-post", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fi", "sähköpostit", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "th", "อีเมล", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "vn", "emails", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "uk", "листи", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "письма", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "cn", "电子邮件", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "tw", "電子郵件", null });
      
      // Create Recycled Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_recycled", iTrue, iOne, "recycledfull_16x16.gif", "recycledfull_16x16.gif" });
          
      // Assign translated labels for Recycled Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "eliminados", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ca", "eliminats", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "gl", "suprimidos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "deleted", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "efface", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "geloescht", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "cancellati", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pt", "suprimidos", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pl", "skreślony", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "no", "slettet", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fi", "poistetaan", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "th", "ที่ถูกลบ", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "vn", "đã xóa", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "uk", "виключити", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "Удалённый", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "cn", "删除", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "tw", "刪除", null });

      // Create Passwords Category
      sCatgId = Category.create(DefaultConnection, new Object[] { sHomeId, UserId, sDomainNick + "_passwords", iTrue, iOne, "folderpwds_16x16.gif", "folderpwds_16x16.gif" });

      // Assign translated labels for Passwords Category
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "es", "contraseñas", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ca", "contrasenyes", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "gl", "contrasinal", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "en", "passwords", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fr", "mots de passe", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "de", "passwörter", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "it", "passwords", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pt", "senhas", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "pl", "haseł", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "no", "passord", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "fi", "salasanoja", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "th", "รหัสผ่าน", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "vn", "mật khẩu", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "uk", "паролі", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "ru", "пароли", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "cn", "密码", null });
      CategoryLabel.create (DefaultConnection, new Object[] { sCatgId, "tw", "密碼", null });
      
      // *****************************************************************************
      // Set reference to User Home Category
      DBCommand.executeUpdate(DefaultConnection, "UPDATE " + DB.k_users + " SET " + DB.gu_category + "='" + sHomeId + "' WHERE " + DB.gu_user + "='" + UserId + "'");
      
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
        oMe.getMailFolder(DefaultConnection, "receipts");
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
catch (Exception e) {
  ReturnValue = null;
  ErrorCode = -1;
  ErrorMessage = e.getClass().getName()+": " + e.getMessage();
}