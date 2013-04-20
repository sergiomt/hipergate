/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.berkeleydb;

import java.io.File;
import java.io.FileNotFoundException;

import java.util.Set;
import java.util.Random;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Properties;
import java.util.Collection;

import java.util.concurrent.ConcurrentHashMap;

import com.knowgate.debug.DebugFile;

import com.knowgate.storage.ErrorCode;
import com.knowgate.storage.Table;
import com.knowgate.storage.Engine;
import com.knowgate.storage.Column;
import com.knowgate.storage.Record;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.SchemaMetaData;
import com.knowgate.storage.StorageException;

import com.sleepycat.db.Database;
import com.sleepycat.db.DatabaseType;
import com.sleepycat.db.DatabaseEntry;
import com.sleepycat.db.DatabaseConfig;
import com.sleepycat.db.DatabaseException;
import com.sleepycat.db.EnvironmentConfig;
import com.sleepycat.db.Transaction;
import com.sleepycat.db.Environment;
import com.sleepycat.db.SecondaryDatabase;
import com.sleepycat.db.SecondaryKeyCreator;
import com.sleepycat.db.SecondaryMultiKeyCreator;
import com.sleepycat.db.Sequence;
import com.sleepycat.db.SequenceConfig;

import com.sleepycat.bind.EntryBinding;
import com.sleepycat.bind.serial.SerialBinding;
import com.sleepycat.bind.serial.StoredClassCatalog;

public class DBEnvironment implements DataSource {
	
  // --------------------------------------------------------------------------

  private static DBEnvironment DEFAULT_ENVIRONMENT = null;

  private static final String CLASS_CATALOG = "JavaClassCatalog";
  
  // --------------------------------------------------------------------------

  private final boolean TRANSACTIONAL = true;

  private boolean bReadOnly;
  private String sPath;
  private SchemaMetaData oSmd;
  private Environment oEnv;
  private EnvironmentConfig oCfg;
  private Database oJcc;
  private DatabaseConfig oDfg;
  private DatabaseConfig oDro;
  private StoredClassCatalog oCtg;
  private EntryBinding oKey;
  private Random oRnd;
  
  private ConcurrentHashMap<String,DBTable> oConnectionMap;

  // --------------------------------------------------------------------------

  protected class SecondaryIndexCreator implements SecondaryKeyCreator {
 
 	private DBEntityBinding oDbeb;
 	private String sIndx;

	public SecondaryIndexCreator(DBEntityBinding oBind, String sIndex) {
      oDbeb = oBind;
      sIndx = sIndex;
    }
 	
    public boolean createSecondaryKey(SecondaryDatabase secDb,
                                      DatabaseEntry keyEntry, 
                                      DatabaseEntry dataEntry,
                                      DatabaseEntry resultEntry) {
      DBEntity oEnt = oDbeb.entryToObject(keyEntry,dataEntry);
      Object oFld = oEnt.get(sIndx);
      if (null==oFld) {
        resultEntry.setData(new String("").getBytes());
      } else {
        resultEntry.setData(oFld.toString().getBytes());
      }
      return true;
    } // createSecondaryKey

  } // SecondaryIndexCreator 

  // --------------------------------------------------------------------------

  protected class SecondaryMultiIndexCreator implements SecondaryMultiKeyCreator {

 	private DBEntityBinding oDbeb;
 	private String sIndx;

	public SecondaryMultiIndexCreator(DBEntityBinding oBind, String sIndex) {
      oDbeb = oBind;
      sIndx = sIndex;
    }

    public void createSecondaryKeys(SecondaryDatabase secondary,
                                    DatabaseEntry keyEntry,
                                    DatabaseEntry dataEntry,
                                    Set results)
             						throws DatabaseException {
      DBEntity oEnt = oDbeb.entryToObject(keyEntry,dataEntry);
      Collection oFld = (Collection) oEnt.get(sIndx);
      if (null!=oFld) results.addAll(oFld);
    } // createSecondaryKeys
  } // SecondaryMultiIndexCreator

  // --------------------------------------------------------------------------

  public SecondaryKeyCreator getKeyCreator(String sIdx) {
    return new SecondaryIndexCreator(new DBEntityBinding(oCtg), sIdx);
  }

  // --------------------------------------------------------------------------

  public SecondaryMultiKeyCreator getMultiKeyCreator(String sIdx) {
    return new SecondaryMultiIndexCreator(new DBEntityBinding(oCtg), sIdx);
  }
  
  // --------------------------------------------------------------------------

  protected void finalize() {
    try { close(); } catch (StorageException ignore) {}
  }

  // --------------------------------------------------------------------------

  private DBEnvironment() { } 

  // --------------------------------------------------------------------------

  public DBEnvironment(String sEnvUrl, SchemaMetaData oMetaData, boolean bReadOnly)
  	throws StorageException {
    oSmd = oMetaData;
  	open(sEnvUrl, null, null, bReadOnly);
  } // DBEnvironment

  // --------------------------------------------------------------------------

  public Environment getEnvironment() {
	return oEnv;
  } // getEnvironment

  // --------------------------------------------------------------------------

  public boolean isTransactional() {
  	return TRANSACTIONAL;
  }
  
  // --------------------------------------------------------------------------

  public void open(String sDbEnv, String sUser, String sPassw, boolean bReadOnlyMode)
  	throws StorageException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin DBEnvironment.open("+sDbEnv+", ..., ..., "+String.valueOf(bReadOnlyMode)+")");
	  DebugFile.incIdent();
	}
	
	try {
	  if (null==sDbEnv) throw new DatabaseException("DBEnvironment location may not be null");
	  sPath = sDbEnv.endsWith(java.io.File.separator) ? sDbEnv : sDbEnv + java.io.File.separator;

      oRnd = new Random();

	  oConnectionMap = new ConcurrentHashMap<String,DBTable>();
    
      bReadOnly = bReadOnlyMode;

	  oCfg = new EnvironmentConfig();
      oCfg.setAllowCreate(true);
      
      oCfg.setInitializeCache(true);

      if (TRANSACTIONAL) {
        oCfg.setInitializeLocking(true);
        oCfg.setInitializeLogging(true);
        oCfg.setTransactional(true);
      } else {
        oCfg.setInitializeCDB(true);
      }

	  //oCfg.setMaxMutexes(1000);
	  //oCfg.setMutexIncrement(200);

	  if (DebugFile.trace) {
	    DebugFile.writeln("Created new EnvironmentConfig with max "+String.valueOf(oCfg.getMaxMutexes())+" mutexes and mutex increment "+String.valueOf(oCfg.getMutexIncrement()));
	  }
	  
      // For Berkeley DB Java
      // oCfg.setReadOnly(bReadOnly);
	
	  // String sDbEnv = getProperty("dbenvironment");
	
      oDfg = new DatabaseConfig();
      oDfg.setTransactional(TRANSACTIONAL);
      oDfg.setSortedDuplicates(false);
      oDfg.setAllowCreate(true);
	  oDfg.setReadOnly(false);
	  
	  // For Berkeley DB Standard Only
	  oDfg.setType(DatabaseType.BTREE);

      oDro = new DatabaseConfig();
      oDro.setTransactional(TRANSACTIONAL);
      oDro.setSortedDuplicates(false);
      oDro.setAllowCreate(true);
      oDro.setReadOnly(true);

	  // For Berkeley DB Standard Only
	  oDro.setType(DatabaseType.BTREE);

	  if (DebugFile.trace) DebugFile.writeln("Creating new Environment at "+sDbEnv);

      oEnv = new Environment(new File(sDbEnv), oCfg);	  

      DatabaseConfig oCtf = new DatabaseConfig();
      oCtf.setTransactional(TRANSACTIONAL);
      oCtf.setAllowCreate(true);
	  oCtf.setType(DatabaseType.BTREE);

	  // For Berkeley DB Java Only
	  // oJcc = oEnv.openDatabase(null, CLASS_CATALOG, bReadOnly ? oDro : oDfg);

	  if (DebugFile.trace) DebugFile.writeln("Environment.openDatabase("+getPath()+CLASS_CATALOG+".db"+")");
	  
	  oJcc = oEnv.openDatabase(null, getPath()+CLASS_CATALOG+".db", CLASS_CATALOG, oCtf);

      oCtg = new StoredClassCatalog(oJcc);
	  try {
        oKey = new SerialBinding(oCtg, Class.forName("java.lang.String"));
	  } catch (ClassNotFoundException neverthrown) { }

	} catch (DatabaseException dbe) {
      if (DebugFile.trace) {
    	  DebugFile.writeln("DatabaseException "+dbe.getMessage());
    	  DebugFile.decIdent();
      }
	  throw new StorageException(dbe.getMessage(), dbe);
	} catch (FileNotFoundException fnf) {
	  if (DebugFile.trace) {
	    DebugFile.writeln("FileNotFoundException "+fnf.getMessage());
	    DebugFile.decIdent();
	  }
	  throw new StorageException(fnf.getMessage(), fnf);
	}

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End DBEnvironment.open()");
	}

  } // DBEnvironment

  // --------------------------------------------------------------------------

  public DBTable openTable(Properties oConnectionProperties)
  	throws StorageException,IllegalArgumentException {
  	DBTable oDbc = null;
  	Database oPdb = null;
  	Database oFdb = null;
  	String[] aIdxs = null;
  	String sIdx = null;
  	String sRel = null;
  	String sFdb = null;
  	String sDbk = oConnectionProperties.getProperty("name","unnamed");
  	String sRo = null;
  	boolean bRo = false;
    HashMap<String,DBIndex> oIdxs = new HashMap<String,DBIndex>();
  	
  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBEnvironment.openTable("+oConnectionProperties+")");
  	  DebugFile.incIdent();
  	}
  	
  	try {

      // For Berkeley DB Java
      // sRo = oConnectionProperties.getProperty("readonly");
      // if (null!=sRo) bRo = (sRo.equalsIgnoreCase("true") || sRo.equalsIgnoreCase("1")) || oCfg.getReadOnly();
	  
      sFdb = oConnectionProperties.getProperty("foreigndatabase");

      if (null!=sFdb) {
  	    if (DebugFile.trace)
  	      DebugFile.writeln("Environment.openDatabase(null,"+getPath()+sFdb+".db"+","+sFdb+")");
      	oFdb = oEnv.openDatabase(null, getPath()+sFdb+".db", sFdb, oDfg);
      }

      if (oConnectionProperties.containsKey("indexes")) {
  	    
        // For Berkeley DB Java
  	    // oPdb = oEnv.openDatabase(null, sDbk, bRo ? oDro : oDfg);

  	    if (DebugFile.trace)
  	      DebugFile.writeln(oEnv+".openDatabase(null,"+getPath()+sDbk+".db"+","+sDbk+","+String.valueOf(bRo)+")");
  	    
  	    oPdb = oEnv.openDatabase(null, getPath()+sDbk+".db", sDbk, bRo ? oDro : oDfg);

        aIdxs = oConnectionProperties.getProperty("indexes").split(",");
		
        for (int i=0;i<aIdxs.length; i++) {

		  int iSpc = aIdxs[i].indexOf(' ');
		  if (iSpc>0) {
			sRel = aIdxs[i].substring(0,iSpc).trim();
		  	sIdx = aIdxs[i].substring(iSpc+1).trim();
		  } else {
		  	sRel = "many-to-one";
		  	sIdx = aIdxs[i];
		  }

		  oIdxs.put(sIdx, new DBIndex(sDbk,sIdx,sRel));

        } // next
        
      } else {

        // For Berkeley DB Java
  	    // oPdb = oEnv.openDatabase(null, sDbk, bRo ? oDro : oDfg);

  	    if (DebugFile.trace)
  	      DebugFile.writeln(oEnv+".openDatabase(null,"+getPath()+sDbk+".db"+","+sDbk+","+String.valueOf(bRo)+")");

  	    oPdb = oEnv.openDatabase(null, getPath()+sDbk+".db", sDbk, bRo ? oDro : oDfg);

      }

      String sCnm = sDbk + (null==sIdx ? ".PrimaryKey:" : "."+sIdx+":") + String.valueOf(new java.util.Date().getTime()) + "#" + String.valueOf(oRnd.nextInt());
      oDbc = new DBTable(this, sCnm, sDbk, oPdb, oIdxs, oFdb, oCtg, oKey);
      oConnectionMap.put(sCnm, oDbc);

  	} catch (DatabaseException dbe) {
  	  throw new StorageException(dbe.getMessage(), dbe);
  	} catch (FileNotFoundException fnf) {
  	  throw new StorageException(fnf.getMessage(), fnf);
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBEnvironment.openTable()");
  	}

	return oDbc;
  } // openTable

  // --------------------------------------------------------------------------

  public Table openTable(String sName)
  	throws StorageException,IllegalArgumentException {
    Properties oProps = new Properties();
    oProps.put("name", sName);
    oProps.put("readonly", "false");
    return openTable(oProps);
  } // openTable

  // --------------------------------------------------------------------------

  public Table openTable(String sName, String[] aIndexes)
  	throws StorageException,IllegalArgumentException {
  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBEnvironment.openTable("+sName+", String[])");
  	  DebugFile.incIdent();
  	}
    Properties oProps = new Properties();
    oProps.put("name", sName);
    oProps.put("readonly", "false");
    if (aIndexes!=null) {
      String sIndexes = "";
      for (int i=0; i<aIndexes.length; i++) {
        sIndexes += (sIndexes.length()==0 ? "" : ",") + aIndexes[i];
      }
      oProps.put("indexes", sIndexes);
    } // fi

    Table oRetVal = openTable(oProps);

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBEnvironment.openTable(String, String[])");
  	}

	return oRetVal;
  } // openTable

  // --------------------------------------------------------------------------

  public Table openTable(Record oRec) throws StorageException,IllegalArgumentException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBEnvironment.openTable("+oRec.getClass().getName()+")");
  	  DebugFile.incIdent();
  	}

    Properties oProps = new Properties();
    oProps.put("name", oRec.getTableName());
    oProps.put("readonly", "false");
    String sIndexes = "";
  	for (Column c : oRec.columns()) {
      if (c.isIndexed() && !c.isPrimaryKey())
        sIndexes += (sIndexes.length()==0 ? "" : ",") + c.getName();
  	} // next
    if (sIndexes.length()>0) oProps.put("indexes", sIndexes);
  	Table oRetVal = openTable(oProps);

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBEnvironment.openTable(Record)");
  	}
  	
  	return oRetVal;
  } // openTable
  
 // --------------------------------------------------------------------------

  @SuppressWarnings("unused")
public long nextVal(String sSequenceName) throws StorageException {
  	long iRetVal = -1l;
  	SequenceConfig oQqg = new SequenceConfig();
  	oQqg.setAutoCommitNoSync(true);
  	oQqg.setAllowCreate(true);
  	// oSqg.setRange(65536l,2147483647l);

	DatabaseEntry oKey = new DatabaseEntry(sSequenceName.getBytes());
    Database oQdb = null;
    Sequence oSqc = null;
	Transaction oTrn = null;

    DatabaseConfig oSqg = new DatabaseConfig();
    oSqg.setTransactional(false);
    oSqg.setAllowCreate(true);
	oSqg.setReadOnly(false);
	oSqg.setType(DatabaseType.BTREE);

    try {
      oTrn = null; // isTransactional() ? getEnvironment().beginTransaction(null,null) : null;
  	  oQdb = new Database(getPath()+"Sequence.db", sSequenceName, oSqg);
      oSqc = oQdb.openSequence(oTrn, oKey, oQqg);
      iRetVal = (int) oSqc.get(oTrn, 1);
      oSqc.close();
      oSqc=null;
      if (oTrn!=null) oTrn.commit();
      oTrn = null;
	} catch (FileNotFoundException fnf) {
      throw new StorageException("DBTable.nextVal("+sSequenceName+") "+fnf.getMessage()+" "+getPath()+"Sequence.db", ErrorCode.IO_EXCEPTION, fnf);
    } catch (IllegalArgumentException iae) {
      throw new StorageException("DBTable.nextVal("+sSequenceName+") "+iae.getMessage(), ErrorCode.ILLEGALARGUMENT_EXCEPTION, iae);
    } catch (DatabaseException dbe) {
      throw new StorageException("DBTable.nextVal("+sSequenceName+") "+dbe.getMessage(), ErrorCode.DATABASE_EXCEPTION, dbe);
    } finally {
      if (oTrn!=null) {
        try {
	      oTrn.abort();
        } catch (DatabaseException ignore) { }
  	  } // fi
      if (null!=oSqc) { try { oSqc.close(); } catch (DatabaseException ignore) { } }
      if (null!=oQdb) { try { oQdb.close(); } catch (DatabaseException ignore) { } }
    }
    
    return iRetVal;
  } // nextVal

  // --------------------------------------------------------------------------

  protected void ungetConnection(String sConnectionName) {
    if (oConnectionMap.containsKey(sConnectionName)) oConnectionMap.remove(sConnectionName);
  }

  // --------------------------------------------------------------------------

  /*
  public String getName() {
    return sProfile;  	
  }
  */

  // --------------------------------------------------------------------------

  /*
  public static DBEnvironment openDefault()
  	throws StorageException {
	if (null==DEFAULT_ENVIRONMENT) DEFAULT_ENVIRONMENT = new DBEnvironment("extranet",true);
	return DEFAULT_ENVIRONMENT;
  }
  */
  
  // --------------------------------------------------------------------------
  
  public String getPath() {
	return sPath;
  }

  // --------------------------------------------------------------------------

  public void closeTables()
  	throws StorageException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin DBEnvironment.closeTables()");
	  DebugFile.incIdent();
	}

	Iterator<String> oItr = oConnectionMap.keySet().iterator();
	while (oItr.hasNext()) {
	  oConnectionMap.get(oItr.next()).close();
	}
	  
	oConnectionMap.clear();

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End DBEnvironment.closeTables()");
	}

  } // closeTables
  	
  // --------------------------------------------------------------------------
  
  public void close()
  	throws StorageException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin DBEnvironment.close()");
	  DebugFile.incIdent();
	}

    try {
  	  if (oEnv!=null) {  	  

		closeTables();

	    if (oCtg!=null) {
	  	  oCtg.close();
	  	  oCtg=null;
	    }

  	    oEnv.close();
  	    oEnv = null;
  	  }
    } catch (DatabaseException dbe) {
	  if (DebugFile.trace) {
	    DebugFile.writeln("DatabaseException "+dbe.getMessage());
	    DebugFile.decIdent();
	  }
      throw new StorageException(dbe.getMessage(),dbe);
    }

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End DBEnvironment.close()");
	}
  } // close

  // --------------------------------------------------------------------------

  public boolean isClosed() {
    return oEnv==null;
  }

  // --------------------------------------------------------------------------

  public boolean isReadOnly() {
    return bReadOnly;
  }

  // --------------------------------------------------------------------------

  public Engine getEngine() {
    return Engine.BERKELYDB;
  }

  // --------------------------------------------------------------------------

  public SchemaMetaData getMetaData() throws StorageException {
    return oSmd;
  }
  
} // DBEnvironment

