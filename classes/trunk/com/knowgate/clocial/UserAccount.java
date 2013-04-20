package com.knowgate.clocial;

import java.sql.SQLException;

import java.util.Date;
import java.util.LinkedList;

import com.knowgate.storage.*;

import com.knowgate.misc.Gadgets;

public class UserAccount extends RecordDelegator {

  private static final long serialVersionUID = Serials.UserAccount;
  
  private static final String tableName = "k_user_accounts";

  public UserAccount(DataSource oDts) throws InstantiationException {
  	super(oDts,tableName);
  }	

  public UserAccount(DataSource oDts,Record oRec) throws InstantiationException {
  	super(oDts,tableName);
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

  public String getUniqueNickName(Table oTbl, String sTxSuggested)
  	throws StorageException, NullPointerException {
    String sTxNickName;
    if (sTxSuggested==null)
      throw new NullPointerException("Suggested nickname may not be null");
    if (sTxSuggested.length()==0)
      throw new NullPointerException("Suggested nickname may not be an empty string");
    RecordSet oRst = oTbl.fetch("tx_nickname", sTxSuggested, 1);
    if (oRst.size()==0) {
      sTxNickName = sTxSuggested;
    } else {
      int iUnderscore = sTxSuggested.indexOf('_');
      if (iUnderscore<=0) {
        sTxNickName = getUniqueNickName(oTbl, sTxSuggested+"_"+String.valueOf(new Date().getYear()));
      } else {
      	String sNumberSuffix = sTxSuggested.substring(++iUnderscore);
        if (sNumberSuffix.matches("\\d+"))
          sTxNickName = getUniqueNickName(oTbl, sTxSuggested.substring(0,iUnderscore)+String.valueOf(Integer.parseInt(sNumberSuffix)+1));
        else
          sTxNickName = getUniqueNickName(oTbl, sTxSuggested+"_"+String.valueOf(new Date().getYear()));        
      }
    }
    return sTxNickName;
  } // getUniqueNickName

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

  public static UserAccount forEmail(DataSource oDtSrc, String sEmail) throws StorageException,InstantiationException  {
	UserAccount oRetVal = null;
  	Table oConn = null;
  	RecordSet oRecs = null;
  	try {
  	  oConn = oDtSrc.openTable(tableName, new String[]{"tx_main_email"});
  	  oRecs = oConn.fetch("tx_main_email", sEmail);
  	  if (oRecs.size()>0)
	    oRetVal = new UserAccount(oDtSrc, oRecs.get(0));
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
 
}
