package com.knowgate.clocial;

import java.sql.SQLException;

import java.util.LinkedList;
import java.util.Properties;

import com.knowgate.storage.*;

import com.knowgate.misc.Gadgets;

import com.knowgate.berkeleydb.DBEntity;

public class UserAccount extends RecordDelegator {

  private static final long serialVersionUID = Serials.UserAccount;
  
  private static final String tableName = "k_user_accounts";

  public UserAccount() throws InstantiationException {
  	super(Engine.DEFAULT,tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }	
  
  public UserAccount(Engine eEngine) throws InstantiationException {
  	super(eEngine,tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }	

  public UserAccount(Engine eEngine,Record oRec) throws InstantiationException {
  	super(eEngine,tableName,MetaData.getDefaultSchema().getColumns(tableName));
    putAll(oRec);
  }	

  public String store(Table oConn) throws StorageException {
	replace("nm_ascii", Gadgets.left(Gadgets.ASCIIEncode(getString("nm_user","")+getString("tx_surname1","")+getString("tx_surname2","")),254));	
	return super.store(oConn);
  }

  public LinkedList<String> recentSearches() {
    return (LinkedList<String>) get("jv_recent_searches");
  }

  public LinkedList<String> pushSearch(String sTxSought) {
    LinkedList<String> oSearches;
    if (!containsKey("jv_recent_searches")) {
      oSearches = new LinkedList<String>();
      oSearches.add(sTxSought);
      put("jv_recent_searches",oSearches);
    } else {
      oSearches = (LinkedList<String>) get("jv_recent_searches");
      if (oSearches.contains(sTxSought)) {
      	oSearches.remove(sTxSought);
      }
      oSearches.addFirst(sTxSought);
    } // fi
    return oSearches;
  } // pushSearch
 
  public ErrorCode authenticate(String sPassword)
  	throws StorageException {
  	if (!containsKey("gu_account"))
      return ErrorCode.USER_NOT_FOUND;
  	if (!containsKey("tx_pwd"))
      return ErrorCode.PASSWORD_MAY_NOT_BE_NULL;
    if (!getBoolean("bo_active",true))
      return ErrorCode.ACCOUNT_DEACTIVATED;
    else if (sPassword.equals(get("tx_pwd")))
      return ErrorCode.SUCCESS;
    else
      return ErrorCode.PASSWORD_MISMATCH;
  } // authenticate

  public static UserAccount forEmail(DataSource oDtSrc, String sEmail) throws StorageException,InstantiationException  {
	UserAccount oRetVal = null;
  	Table oConn = null;
  	RecordSet oRecs = null;
  	try {
  	  oConn = oDtSrc.openTable(tableName, new String[]{"tx_main_email"});
  	  oRecs = oConn.fetch("tx_main_email", sEmail);
  	  if (oRecs.size()>0)
	    oRetVal = new UserAccount(oDtSrc.getEngine(), oRecs.get(0));
  	} finally {
	  if (null!=oConn) {
	  	try {
	  	  oConn.close();
	  	} catch (SQLException sqle) {
	  	  throw new StorageException(sqle.getMessage(), sqle);
	  	}
	  }
  	}
	
	return oRetVal;
  } // forEmail

  public static ErrorCode authenticate(DataSource oDtSrc, String sEmail, String sPassword)
  	throws StorageException,InstantiationException  {
    if (null==sEmail) {
      return ErrorCode.EMAIL_MAY_NOT_BE_NULL;
    } else if (sEmail.length()==0) {
      return ErrorCode.EMAIL_IS_NOT_VALID;
    }
	if (null==sPassword) {
	  return ErrorCode.PASSWORD_MAY_NOT_BE_EMPTY;
	}
    UserAccount oUacc = forEmail(oDtSrc, sEmail);
    if (null==oUacc) {
      return ErrorCode.USER_NOT_FOUND;
    } else {
      return oUacc.authenticate(sPassword);
    }
  } // authenticate
}
