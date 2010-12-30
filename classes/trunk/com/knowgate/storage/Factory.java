package com.knowgate.storage;

import java.util.ArrayList;

import com.knowgate.berkeleydb.*;

public final class Factory {
  
  public static DataSource createDataSource(Engine eEngine, String sProfileName, boolean bReadOnly)
  	throws InstantiationException,StorageException {
  	switch (eEngine) {
  	  case BERKELYDB:
  	  	return new DBEnvironment(sProfileName, bReadOnly);
  	  default:
  	  	throw new InstantiationException("Invalid ENGINE value");
  	}
  }

  public static Record createRecord(Engine eEngine, String sTableName, ArrayList<Column> oColumnsList)
  	throws InstantiationException,StorageException {
  	switch (eEngine) {
  	  case BERKELYDB:
  	  	return new DBEntity(sTableName,oColumnsList);
  	  default:
  	  	throw new InstantiationException("Invalid ENGINE value");
  	}
  }
  
}
