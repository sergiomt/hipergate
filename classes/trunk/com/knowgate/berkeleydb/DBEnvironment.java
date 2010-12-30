package com.knowgate.berkeleydb;

import java.io.File;
import java.io.IOException;
import java.io.FileNotFoundException;

import java.util.Set;
import java.util.Random;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Properties;
import java.util.Collection;
import java.util.Collections;

import com.knowgate.debug.DebugFile;

import com.knowgate.storage.ErrorCode;
import com.knowgate.storage.Table;
import com.knowgate.storage.Engine;
import com.knowgate.storage.Column;
import com.knowgate.storage.Record;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;

import com.sleepycat.db.Database;
import com.sleepycat.db.DatabaseType;
import com.sleepycat.db.DatabaseEntry;
import com.sleepycat.db.DatabaseConfig;
import com.sleepycat.db.DatabaseException;
import com.sleepycat.db.EnvironmentConfig;
import com.sleepycat.db.Environment;
import com.sleepycat.db.SecondaryConfig;
import com.sleepycat.db.SecondaryDatabase;
import com.sleepycat.db.SecondaryKeyCreator;
import com.sleepycat.db.SecondaryMultiKeyCreator;
import com.sleepycat.db.Sequence;
import com.sleepycat.db.SequenceConfig;

import com.sleepycat.bind.EntryBinding;
import com.sleepycat.bind.serial.ClassCatalog;
import com.sleepycat.bind.serial.SerialBinding;
import com.sleepycat.bind.serial.StoredClassCatalog;

public class DBEnvironment implements DataSource {
	
  // --------------------------------------------------------------------------

  private static DBEnvironment DEFAULT_ENVIRONMENT = null;

  private static final String CLASS_CATALOG = "JavaClassCatalog";
  
  // --------------------------------------------------------------------------

  private final boolean TRANSACTIONAL = false;

  private boolean bReadOnly;
  private String sProfile;
  private Environment oEnv;
  private EnvironmentConfig oCfg;
  private Database oJcc;
  private DatabaseConfig oDfg;
  private DatabaseConfig oDro;
  private StoredClassCatalog oCtg;
  private EntryBinding oKey;
  private Random oRnd;
  
  private HashMap<String,DBTable> oConnectionMap;

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

  public DBEnvironment(String sProfileName, boolean bReadOnly)
  	throws StorageException {
  	open(sProfileName, bReadOnly);
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

  public void open(String sProfileName, boolean bReadOnlyMode)
  	throws StorageException {

	try {
	  if (null!=sProfile) throw new DatabaseException("Environment is already opened");

      oRnd = new Random();

	  oConnectionMap = new HashMap<String,DBTable>();
    
      sProfile = sProfileName;
      bReadOnly = bReadOnlyMode;

	  oCfg = new EnvironmentConfig();
      oCfg.setTransactional(TRANSACTIONAL);
      oCfg.setAllowCreate(true);
      
      // For Berkeley DB Concurrent Data Store Only
      oCfg.setInitializeCDB(true);
      oCfg.setInitializeCache(true); 
	  
      // For Berkeley DB Java
      // oCfg.setReadOnly(bReadOnly);
	
	  String sDbEnv = getProperty("dbenvironment");
	
	  if (null==sDbEnv) throw new DatabaseException("DBEnvironment Property dbenvironment not found at "+sProfileName+" profile file");

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

      oEnv = new Environment(new File(sDbEnv), oCfg);	  

      DatabaseConfig oCtf = new DatabaseConfig();
      oCtf.setAllowCreate(true);
	  oCtf.setType(DatabaseType.BTREE);

	  // For Berkeley DB Java Only
	  // oJcc = oEnv.openDatabase(null, CLASS_CATALOG, bReadOnly ? oDro : oDfg);

	  oJcc = oEnv.openDatabase(null, getPath()+CLASS_CATALOG+".db", CLASS_CATALOG, oCtf);

      oCtg = new StoredClassCatalog(oJcc);
	  try {
        oKey = new SerialBinding(oCtg, Class.forName("java.lang.String"));
	  } catch (ClassNotFoundException neverthrown) { }

	} catch (DatabaseException dbe) {
	  throw new StorageException(dbe.getMessage(), dbe);
	} catch (FileNotFoundException fnf) {
	  throw new StorageException(fnf.getMessage(), fnf);
	}
  } // DBEnvironment

  // --------------------------------------------------------------------------

  public Table openTable(Properties oConnectionProperties) throws StorageException {
  	DBTable oDbc = null;
  	Database oPdb = null;
  	Database oFdb = null;
  	SecondaryDatabase[] aSdb = null;
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

      sRo = oConnectionProperties.getProperty("readonly");
      // For Berkeley DB Java
      // if (null!=sRo) bRo = (sRo.equalsIgnoreCase("true") || sRo.equalsIgnoreCase("1")) || oCfg.getReadOnly();
	  
      sFdb = oConnectionProperties.getProperty("foreigndatabase");

      if (null!=sFdb) oFdb = oEnv.openDatabase(null, getPath()+sFdb+".db", sFdb, oDfg);

      if (oConnectionProperties.containsKey("indexes")) {
  	    
        // For Berkeley DB Java
  	    // oPdb = oEnv.openDatabase(null, sDbk, bRo ? oDro : oDfg);
  	    
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

  public Table openTable(String sName) throws StorageException {
    Properties oProps = new Properties();
    oProps.put("name", sName);
    oProps.put("readonly", "true");
    return openTable(oProps);
  }

  // --------------------------------------------------------------------------

  public Table openTable(String sName, String[] aIndexes) throws StorageException {
  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBEnvironment.openTable("+sName+", String[])");
  	  DebugFile.incIdent();
  	}
    Properties oProps = new Properties();
    oProps.put("name", sName);
    oProps.put("readonly", "true");
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
  }

  // --------------------------------------------------------------------------

  public Table openTable(Record oRec) throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBEnvironment.openTable("+oRec.getClass().getName()+")");
  	  DebugFile.incIdent();
  	}

    Properties oProps = new Properties();
    oProps.put("name", oRec.getTableName());
    oProps.put("readonly", "false");
    String sIndexes = "";
  	for (Column c : oRec.columns()) {
      if (c.isIndexed()) {
        sIndexes += (sIndexes.length()==0 ? "" : ",") + c.getName();
      } // fi
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

  public int nextVal(String sSequenceName) throws StorageException {
  	int iRetVal = -1;
  	SequenceConfig oQqg = new SequenceConfig();
  	oQqg.setAllowCreate(true);
  	// oSqg.setRange(65536l,2147483647l);

	DatabaseEntry oKey = new DatabaseEntry(sSequenceName.getBytes());
    Database oQdb = null;
    Sequence oSqc = null;

    try {
  	  oQdb = new Database(getPath()+"Sequence.db", sSequenceName, oDfg);
      oSqc = oQdb.openSequence(null, oKey, oQqg);
      iRetVal = (int) oSqc.get(null, 1);
      oSqc.close();
      oSqc=null;
	} catch (FileNotFoundException fnf) {
      throw new StorageException("DBTable.nextVal("+sSequenceName+") "+fnf.getMessage()+" "+getPath()+"Sequence.db", ErrorCode.IO_EXCEPTION, fnf);
    } catch (IllegalArgumentException iae) {
      throw new StorageException("DBTable.nextVal("+sSequenceName+") "+iae.getMessage(), ErrorCode.ILLEGALARGUMENT_EXCEPTION, iae);
    } catch (DatabaseException dbe) {
      throw new StorageException("DBTable.nextVal("+sSequenceName+") "+dbe.getMessage(), ErrorCode.DATABASE_EXCEPTION, dbe);
    } finally {
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

  public String getName() {
    return sProfile;  	
  }

  // --------------------------------------------------------------------------

  public static DBEnvironment openDefault()
  	throws StorageException {
	if (null==DEFAULT_ENVIRONMENT) DEFAULT_ENVIRONMENT = new DBEnvironment("extranet",true);
	return DEFAULT_ENVIRONMENT;
  }
  
  // --------------------------------------------------------------------------
  
  public String getProperty(String sVariableName) {
    return com.knowgate.misc.Environment.getProfileVar(sProfile, sVariableName);
  }

  // --------------------------------------------------------------------------
  
  public Properties getProperties() {
    return com.knowgate.misc.Environment.getProfile(sProfile);
  }

  // --------------------------------------------------------------------------
  
  public String getPath() {
    String sPath = com.knowgate.misc.Environment.getProfileVar(sProfile,"dbenvironment");
    if (!sPath.endsWith(java.io.File.separator)) sPath += java.io.File.separator;
	return sPath;
  }

  // --------------------------------------------------------------------------

  public void closeTables()
  	throws StorageException {

	Iterator<String> oItr = oConnectionMap.keySet().iterator();
	while (oItr.hasNext()) {
	  oConnectionMap.get(oItr.next()).close();
	}
	  
	oConnectionMap.clear();
  } // closeTables
  	
  // --------------------------------------------------------------------------
  
  public void close()
  	throws StorageException {

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
      throw new StorageException(dbe.getMessage(),dbe);
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

  public Engine getEngine() {
    return Engine.BERKELYDB;
  }

} // DBEnvironment

