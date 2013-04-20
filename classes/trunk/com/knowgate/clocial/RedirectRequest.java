package com.knowgate.clocial;


import java.sql.SQLException;

import com.knowgate.storage.Table;
import com.knowgate.storage.Record;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.RecordDelegator;

public class RedirectRequest extends RecordDelegator {
	
  private static final String tableName = "k_redirect_requests";

  private static final long serialVersionUID = Serials.RedirectReq;

  public RedirectRequest(DataSource oDts) throws InstantiationException {
  	super(oDts,tableName);
  }
  
  public static long store(DataSource oDts, String sURL, String sIP,
                           String sJob, String sContact, String sEmail)
  	throws StorageException, InstantiationException {
    Record oRec = new RedirectRequest(oDts);
    Table oTbl = oDts.openTable(oRec);
    oRec.put("url_addr", sURL);
    if (sIP!=null) oRec.put("ip_addr", sIP);
    if (sJob!=null) oRec.put("gu_job", sJob);
    if (sEmail!=null) oRec.put("tx_email", sEmail);
    if (sContact!=null) oRec.put("gu_contact", sContact);
    oRec.store(oTbl);
    long lId = oRec.getLong("id_request");
	try { if (null!=oTbl) oTbl.close(); }
	catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    return lId;
  }
}
