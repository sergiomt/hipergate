package com.knowgate.syndication;

import com.knowgate.clocial.Serials;

import com.knowgate.dataobjs.DB;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordDelegator;

public class SyndReferer extends RecordDelegator {

  private static final String tableName = DB.k_syndreferers;
  
  private static final long serialVersionUID = Serials.SyndReferer;

  public SyndReferer(DataSource oDts, String sTxSought, String sDomain)
  	throws InstantiationException {
    super(oDts,tableName);
    put(DB.id_syndref,sTxSought+"/"+sDomain);
    put(DB.url_domain,sDomain);
    put(DB.tx_sought,sTxSought);
    put(DB.nu_entries,1);
  }
}
