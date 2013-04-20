package com.knowgate.syndication;

import java.util.Date;

import com.knowgate.dataobjs.DB;

import com.knowgate.clocial.Serials;

import com.knowgate.misc.Gadgets;

import com.knowgate.storage.DataSource;
import com.knowgate.storage.Engine;
import com.knowgate.storage.RecordDelegator;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.Table;

public class SyndSearchRun extends RecordDelegator {

  private static final long serialVersionUID = Serials.SyndSearchRun;

  private static final String tableName = DB.k_syndsearch_run;
  
  public SyndSearchRun(DataSource oDts) throws InstantiationException {
    super(oDts, tableName);
  }	

  public SyndSearchRun(DataSource oDts, String sQry, Date dtRun, int nMilis, int nEntries)
  	throws InstantiationException {
    super(oDts, tableName);
    put ("tx_sought", Gadgets.left(sQry,254));
    put ("dt_run", dtRun);
    put ("nu_milis", nMilis);
    put ("nu_entries", nEntries);
  }	

  public String store(Table oTbl) throws StorageException {
    DataSource oDts = oTbl.getDataSource();
	if (oDts.getEngine().equals(Engine.JDBCRDBMS)) {
	  if (isNull("id_run"))
		put ("id_run", oDts.nextVal("seq_"+tableName));
	}
	return super.store(oTbl);
  }  
}
