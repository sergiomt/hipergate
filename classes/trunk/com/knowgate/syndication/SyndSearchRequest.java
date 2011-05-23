package com.knowgate.syndication;


import java.util.Date;

import com.knowgate.dataobjs.DB;

import com.knowgate.clocial.Serials;

import com.knowgate.storage.Table;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordDelegator;
import com.knowgate.storage.StorageException;

public class SyndSearchRequest extends RecordDelegator {

  private static final long serialVersionUID = Serials.SyndSearchReq;

  public SyndSearchRequest(DataSource oDts) throws InstantiationException {
    super(oDts, DB.k_syndsearch_request);
  }	

  public SyndSearchRequest(DataSource oDts, String sQry, Date dtRequest, int nMilis, String sGuAccount)
  	throws InstantiationException {
    super(oDts, DB.k_syndsearch_request);
    put ("tx_sought", sQry);
    put ("dt_request", dtRequest);
    put ("nu_milis", nMilis);
    if (null!=sGuAccount) put ("gu_account", sGuAccount);
  }
}
