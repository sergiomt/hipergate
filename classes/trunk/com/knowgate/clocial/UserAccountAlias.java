package com.knowgate.clocial;

import java.util.Date;

import com.knowgate.storage.*;
import com.knowgate.misc.Gadgets;
import com.knowgate.clocial.Serials;

public class UserAccountAlias extends RecordDelegator {

  private static final long serialVersionUID = Serials.UserAccountAlias;
  
  private static final String tableName = "k_user_account_alias";
  
  public UserAccountAlias(DataSource oDts) throws InstantiationException {
  	super(oDts,tableName);
  }	

  public UserAccountAlias(DataSource oDts,Record oRec) throws InstantiationException {
  	super(oDts,tableName);
    putAll(oRec);
  }

  public String store(Table oTbl) throws StorageException,NullPointerException {
  	put("id_acalias", makeId(getString("nm_service"),getString("nm_alias")));
  	if (!isNull("nm_display"))
  	  put("nm_ascii", Gadgets.left(Gadgets.ASCIIEncode(getString("nm_display").toLowerCase()),100));
    return super.store(oTbl);
  }

  public static String makeId(String sNmService, String sNmAlias) {
    return sNmService.toLowerCase()+":"+sNmAlias.toLowerCase();
  }

  public static String getUserAccountId(DataSource oDts, String sNmService, String sNmAlias)
  	throws StorageException {
  	String sGuAccount;
  	Table oTbl = null;
  	try  {
  	  oTbl = oDts.openTable(new UserAccountAlias(oDts));
  	  Record oRec = oTbl.load(makeId(sNmService, sNmAlias));
  	  oTbl.close();
	  oTbl=null;
	  if (oRec==null) {
        sGuAccount = Gadgets.generateUUID();
        UserAccount oAcc = new UserAccount(oDts);
  	    oTbl = oDts.openTable(oAcc);	  
	    oAcc.put("gu_account", sGuAccount);
	    oAcc.put("id_domain", 0);
	    oAcc.put("nm_domain", "N/A");
	    oAcc.put("bo_active", false);
	    oAcc.put("tx_nickname", oAcc.getUniqueNickName(oTbl,sNmAlias));
	    oAcc.store(oTbl);
	    oTbl.close();
	    oTbl=null;
	    UserAccountAlias oUaa = new UserAccountAlias(oDts);
  	    oTbl = oDts.openTable(oUaa);	  
	    oUaa.put("id_acalias", makeId(sNmService, sNmAlias));
	    oUaa.put("gu_account", sGuAccount);
	    oUaa.put("nm_service", sNmService);
	    oUaa.put("nm_alias", sNmAlias);
	    oUaa.store(oTbl);
	    oTbl.close();
		oTbl=null;
	  } else {
	    sGuAccount = oRec.getString("gu_account");
	  }
  	} catch (Exception xcpt) {
  	  if (null!=oTbl) { try { oTbl.close(); } catch (Exception ignore) {} }
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}
	return sGuAccount;
  } // getUserAccountId
}
