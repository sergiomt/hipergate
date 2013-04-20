package com.knowgate.clocial;

import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordDelegator;


public class Domain extends RecordDelegator {

  private static final long serialVersionUID = Serials.Domain;
  
  private static final String tableName = "k_domains";

  public Domain(DataSource oDts) throws InstantiationException {
  	super(oDts, tableName);
  }
}
