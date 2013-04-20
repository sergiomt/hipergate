package com.knowgate.syndication;

import com.knowgate.dataobjs.DB;

import com.knowgate.clocial.Serials;

import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordDelegator;

public class SyndSearchReferer extends RecordDelegator {
	
  private static final String tableName = DB.k_syndreferers;
  
  private static final long serialVersionUID = Serials.SyndSearchRef;
	
  public SyndSearchReferer(DataSource oDts) throws InstantiationException {
    super(oDts, tableName);
  }	
	
}
