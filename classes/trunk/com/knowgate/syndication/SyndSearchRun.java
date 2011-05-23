package com.knowgate.syndication;

import java.util.Date;

import com.knowgate.dataobjs.DB;

import com.knowgate.clocial.Serials;
import com.knowgate.clocial.MetaData;

import com.knowgate.misc.Gadgets;

import com.knowgate.storage.Table;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordDelegator;
import com.knowgate.storage.StorageException;

public class SyndSearchRun extends RecordDelegator {

  private static final long serialVersionUID = Serials.SyndSearchRun;
	
  public SyndSearchRun(DataSource oDts) throws InstantiationException {
    super(oDts, DB.k_syndsearch_run);
  }	

  public SyndSearchRun(DataSource oDts, String sQry, Date dtRun, int nMilis, int nEntries)
  	throws InstantiationException {
    super(oDts, DB.k_syndsearch_run);
    put ("tx_sought", Gadgets.left(sQry,254));
    put ("dt_run", dtRun);
    put ("nu_milis", nMilis);
    put ("nu_entries", nEntries);
  }	

}
