package com.knowgate.berkeleydb;

import com.sleepycat.db.Transaction;
import com.sleepycat.db.DatabaseException;
import com.sleepycat.db.SecondaryCursor;
import com.sleepycat.db.SecondaryDatabase;

import com.knowgate.debug.DebugFile;

public class DBIndex {
  private String sTable;
  private String sColumn;
  private String sRelation;
  private SecondaryDatabase oSdb;
  
  public DBIndex(String sTableName, String sColumnName, String sRelationType) {
  	sTable = sTableName;
  	sColumn = sColumnName;
  	sRelation = sRelationType;
  	oSdb = null;
  }
  
  public String getName() {
  	return sColumn;
  }
  
  public String getRelationType() {
  	return sRelation;
  }

  public void open(SecondaryDatabase oSecDb) {
  	oSdb = oSecDb;
  }
  
  public void close() throws DatabaseException {
  	if (oSdb!=null) {
  	  oSdb.close();
  	  oSdb=null;
  	}
  }

  public boolean isClosed() {
    return oSdb==null;
  }
  
  public SecondaryCursor getCursor(Transaction oTrn) throws DatabaseException {
    if (DebugFile.trace) DebugFile.writeln("SecondaryDatabase.openSecondaryCursor(null,null)");
  	return oSdb.openSecondaryCursor(oTrn, null);
  }
  
}
