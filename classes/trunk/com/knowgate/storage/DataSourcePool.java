package com.knowgate.storage;

import java.util.Date;
import java.util.Stack;
import java.util.concurrent.ConcurrentHashMap;

import com.knowgate.berkeleydb.DBEnvironment;

public class DataSourcePool {
  
  private static ConcurrentHashMap<DataSource,Date> oLastUse = new ConcurrentHashMap<DataSource,Date>();
  private static Stack<DataSource> oReadOnly = new Stack<DataSource>();
  
  public static DataSource get(Engine eEngine, String sProfileName, boolean bReadOnly)
  	throws StorageException,InstantiationException {
  	DataSource oRetDts;
  	if (bReadOnly) {
  	  if (oReadOnly.empty()){
  	    oRetDts = Factory.createDataSource(eEngine, sProfileName, true);
  	  } else {
  	    oRetDts = oReadOnly.pop();
  	  }
  	} else {
  	  oRetDts = Factory.createDataSource(eEngine, sProfileName, false);
  	}
  	if (oLastUse.containsKey(oRetDts)) oLastUse.remove(oRetDts);
	oLastUse.put(oRetDts, new Date());  
  	return oRetDts;
  } // get
   
  public static void free(DataSource oDts)
  	throws StorageException {
  	if (oLastUse.containsKey(oDts)) oLastUse.remove(oDts);
	if (!oDts.isClosed()) {
  	  if (oDts instanceof DBEnvironment) {
	    ((DBEnvironment) oDts).closeTables();
  	  }
	  if (oDts.isReadOnly()) {
	    oReadOnly.push(oDts);
	  } else {
	    oDts.close();
	  }
	}
  } // free

  public static void close()
  	throws StorageException {
    DataSource oDts;
    while (!oReadOnly.empty()) {     
      oDts = oReadOnly.pop();
  	  if (oLastUse.containsKey(oDts)) oLastUse.remove(oDts);
      if (!oDts.isClosed()) oDts.close();
    }
    for (DataSource d : oLastUse.keySet()) {
      if (!d.isClosed()) d.close();
    }
    oLastUse.clear();
  } // close

}