package com.knowgate.clocial;

import java.util.Properties;

import com.knowgate.storage.Engine;
import com.knowgate.storage.RecordDelegator;

import com.knowgate.misc.Gadgets;

public class Domain extends RecordDelegator {

  private static final long serialVersionUID = Serials.Domain;
  
  private static final String tableName = "k_domains";

  public Domain() throws InstantiationException {
  	super(Engine.DEFAULT, tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }	

  public Domain(Engine eEngine) throws InstantiationException {
  	super(eEngine, tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }
}
