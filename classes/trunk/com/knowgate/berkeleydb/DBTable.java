package com.knowgate.berkeleydb;

import java.io.FileNotFoundException;

import java.util.Date;
import java.util.HashMap;
import java.util.Random;
import java.util.Collection;
import java.util.Properties;

import java.text.SimpleDateFormat;

import java.sql.Types;

import java.net.InetAddress;
import java.net.UnknownHostException;

import com.knowgate.debug.DebugFile;
import com.knowgate.storage.*;

import com.sleepycat.db.Cursor;
import com.sleepycat.db.Database;
import com.sleepycat.db.LockMode;
import com.sleepycat.db.DatabaseType;
import com.sleepycat.db.OperationStatus;
import com.sleepycat.db.DatabaseEntry;
import com.sleepycat.db.SecondaryConfig;
import com.sleepycat.db.SecondaryCursor;
import com.sleepycat.db.SecondaryDatabase;
import com.sleepycat.db.DatabaseException;
import com.sleepycat.db.SecondaryKeyCreator;
import com.sleepycat.db.SecondaryMultiKeyCreator;

import com.sleepycat.bind.EntryBinding;
import com.sleepycat.bind.serial.ClassCatalog;
import com.sleepycat.bind.serial.StoredClassCatalog;

public class DBTable implements Table {

  private String sCnm;
  private String sDbk;
  private DBEnvironment oRep;
  private Database oPdb;
  private Database oFdb;
  private HashMap<String,DBIndex> oInd;
  private StoredClassCatalog oCtg;
  private EntryBinding oKey;
    
  private static SimpleDateFormat oTsFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  private DBTable() { }

  // --------------------------------------------------------------------------

  protected DBTable(DBEnvironment oDatabaseEnvironment,
  					String sConnectionName,
  					String sDatabaseName,
  					Database oPrimaryDatabase,
  					HashMap<String,DBIndex> oIndexes,
  					Database oForeignDatabase,
  					StoredClassCatalog oClassCatalog,
  					EntryBinding oEntryBind)
  	throws StorageException {

    sCnm = sConnectionName;
    oRep = oDatabaseEnvironment;
    sDbk = sDatabaseName;
    oPdb = oPrimaryDatabase;
    oInd = oIndexes;
    oFdb = oForeignDatabase;
    oCtg = oClassCatalog;
    oKey = oEntryBind;

    if (!isReadOnly()) {
  	  for (String sColumnName : oInd.keySet()) {
  	  	openIndex(sColumnName);
  	  } // next
    } // fi
  }

  // --------------------------------------------------------------------------

  protected void finalize() {
    try { close(); } catch (StorageException ignore) {}
  }

  // --------------------------------------------------------------------------

  public void close() throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.close()");
  	  DebugFile.incIdent();
  	}
  	
  	try {
  	  for (String sColumnName : oInd.keySet()) {
  	    oInd.get(sColumnName).close();
  	  } // next
  	  oRep.ungetConnection(sCnm);
  	  if (oFdb!=null) oFdb.close();
  	  oFdb = null;
  	  if (oPdb!=null) oPdb.close();
  	  oPdb = null;
  	} catch (DatabaseException dbe) {
  	  if (DebugFile.trace) DebugFile.decIdent();
  	  throw new StorageException(dbe.getMessage(), dbe);
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.close()");
  	}
  } // close

  // --------------------------------------------------------------------------

  public boolean isReadOnly() throws StorageException {
  	try {
      return oPdb.getConfig().getReadOnly();
  	} catch (DatabaseException dbe) {
  	  throw new StorageException(dbe.getMessage(), dbe);
  	}
  }

  // --------------------------------------------------------------------------

  public String getName() {
  	return sCnm;
  }

  // --------------------------------------------------------------------------

  public DataSource getDataSource() {
  	return (DataSource) oRep;
  }

  // --------------------------------------------------------------------------

  public void delete(AbstractRecord oRec) throws StorageException {
    if (oRec.getPrimaryKey()==null)
  	  throw new StorageException("Tried to delete record with no primary key");	
	try {
	  oPdb.delete(null, new DatabaseEntry(new DBEntityBinding(oCtg).objectToKey((DBEntity) oRec).getBytes()));	
	} catch (DatabaseException dbe) {
	  throw new StorageException(dbe.getMessage(), dbe);
	}
  }

  // --------------------------------------------------------------------------
    
  public boolean exists(String sKey) throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.exists("+sKey+")");
  	  DebugFile.incIdent();
  	  byte[] aByKey = sKey.getBytes();
  	  StringBuffer oStrKey = new StringBuffer(aByKey.length*3);
  	  for (int b=0; b<aByKey.length; b++) oStrKey.append(" "+Integer.toHexString(aByKey[b]));
  	  DebugFile.writeln("raw key hex is"+oStrKey.toString());
  	}

	boolean bRetVal = false;
	OperationStatus oOpSt;
	
  	try {
  	  oOpSt = oPdb.get(null, new DatabaseEntry(sKey.getBytes()), new DatabaseEntry(), LockMode.DEFAULT);
  	  bRetVal = (OperationStatus.SUCCESS==oOpSt);
  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}

  	if (DebugFile.trace) {
  	  if (oOpSt!=OperationStatus.SUCCESS) DebugFile.writeln("get() operation status was "+oOpSt.toString());
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.exists() : "+String.valueOf(bRetVal));
  	}

	return bRetVal;
  }

  // --------------------------------------------------------------------------
    
  public Record load(String sKey) throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.load("+sKey+")");
  	  DebugFile.incIdent();
  	  byte[] aByKey = sKey.getBytes();
  	  StringBuffer oStrKey = new StringBuffer(aByKey.length*3);
  	  for (int b=0; b<aByKey.length; b++) oStrKey.append(" "+Integer.toHexString(aByKey[b]));
  	  DebugFile.writeln("raw key hex is"+oStrKey.toString());
  	}

  	DBEntity oDbEnt = null;
  	try {
	  DatabaseEntry oDbKey = new DatabaseEntry(sKey.getBytes());
      DatabaseEntry oDbDat = new DatabaseEntry();
  	  if (OperationStatus.SUCCESS==oPdb.get(null, oDbKey, oDbDat, LockMode.DEFAULT)) {
	    DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
  	    oDbEnt = oDbeb.entryToObject(oDbKey,oDbDat);
  	  }
  	} catch (Exception xcpt) {
  	  if (DebugFile.trace) DebugFile.decIdent();
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.load() : "+oDbEnt);
  	}

  	return oDbEnt;
  } // load

  // --------------------------------------------------------------------------

  public void store(AbstractRecord oRec) throws StorageException {
  	
  	if (isReadOnly()) throw new StorageException("DBTable.store() table "+getName()+" is in read-only mode");

  	if (oRec==null) throw new NullPointerException("DBTable.store() Record to be stored is null");

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.store("+oRec.getPrimaryKey()+")");
  	  DebugFile.incIdent();
  	}

  	try {
  	  
  	  if (oRec.getPrimaryKey()==null) {
  	  	if (oRec.containsKey("dt_created"))
  	  	  oRec.remove("dt_created");
  	  	oRec.put("dt_created", oTsFmt.format(new Date()));
  	  } else {
  	  	if (oRec.containsKey("dt_created")) {
 	  	  if (oRec.get("dt_created")==null)
  	  	    oRec.put("dt_created", oTsFmt.format(new Date()));
		  else if (oRec.get("dt_created").equals(""))
  	  	    oRec.put("dt_created", oTsFmt.format(new Date()));
  	  	} else {
  	  	  oRec.put("dt_created", oTsFmt.format(new Date()));
  	  	}
  	  	if (oRec.containsKey("dt_modified"))
  	  	  oRec.remove("dt_modified");
  	  	oRec.put("dt_modified", oTsFmt.format(new Date()));
  	  }
  	  
  	  if (null!=oRec.columns()) {

  	    for (Column c : oRec.columns()) {
  	      String n = c.getName();

		  boolean bIsEmptyPk = !oRec.containsKey(n);
		  if (!bIsEmptyPk) bIsEmptyPk = (oRec.get(n).toString().length()==0);
		  	
  	      if (bIsEmptyPk && c.getDefaultValue()!=null) {
  	      	if (c.getDefaultValue().equals("GUID"))
  	          oRec.put(n, createUniqueKey());
  	      	else if (c.getDefaultValue().equals("SERIAL"))
  	          oRec.put(n, String.valueOf(oRep.nextVal(n)));
  	      	else if (c.getDefaultValue().equals("NOW"))
  	          oRec.put(n, oTsFmt.format(new Date()));
  	        else
  	          oRec.put(n, c.getDefaultValue());
  			if (DebugFile.trace)
  	  		  DebugFile.writeln("auto setting default value of "+n+" to "+oRec.get(n).toString());
  	        if (c.isPrimaryKey()) oRec.setPrimaryKey(oRec.get(n).toString());
  	      } // fi

  	  	  if (!c.isNullable() && !oRec.containsKey(n))
		    throw new IntegrityViolationException(c, null);

		  if (!c.check(oRec.get(c.getName())))
		    throw new IntegrityViolationException(c, oRec.get(n));

  	      if (oRec.containsKey(n) && c.getForeignKey()!=null) {
			if (oRec.get(n)!=null) {
			  if (oRec.get(n).toString().length()>0) {
  			    if (DebugFile.trace)
  	  		      DebugFile.writeln("Checking "+c.getForeignKey()+"."+c.getName()+" for value "+oRec.get(n));

  	  	        DBTable oFk = (DBTable) oRep.openTable(c.getForeignKey(), new String []{c.getName()});
  	            boolean bExists;
  	            if (c.getType()==Types.INTEGER) {
  	              bExists = oFk.exists(String.valueOf(oRec.getInt(n)));
  	            } else {
			      bExists = oFk.exists(oRec.getString(n));
  	            }
  	            oFk.close();
  	            if (!bExists) throw new IntegrityViolationException(c,oRec.get(n));
			  } // fi
			} // fi ()
  	      } // fi (c.getForeignKey())
  	      if (c.getType()==Types.DATE || c.getType()==Types.TIMESTAMP) {
  	        if (oRec.containsKey(n)) {
  	      	  if (oRec.get(n) instanceof Date) {
  	            String dt = oTsFmt.format((Date) oRec.get(n));
  	            oRec.remove(n); 	            
  	            oRec.put(n,dt);
  	      	  } // fi
  	        } // fi
  	      } // fi
  	    } // next
  	  } // fi

	  if (oRec.getPrimaryKey()==null) throw new IntegrityViolationException("Primary key not set and no default specified at table "+oRec.getTableName());

  	  DBEntity oEnt = (DBEntity) oRec;
  	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);

  	  if (DebugFile.trace) {
  	  	byte[] aByKey = oRec.getPrimaryKey().getBytes();
  	  	StringBuffer oStrKey = new StringBuffer(aByKey.length*3);
  	  	for (int b=0; b<aByKey.length; b++) oStrKey.append(" "+Integer.toHexString(aByKey[b]));
  	    DebugFile.writeln("string key his "+oRec.getPrimaryKey());
  	    DebugFile.writeln("raw key hex his"+oStrKey.toString());
  	  }

	  DatabaseEntry oDbKey = new DatabaseEntry(oRec.getPrimaryKey().getBytes());
      DatabaseEntry oDbDat = new DatabaseEntry(oDbeb.objectToData(oEnt));
  	  oPdb.put(null, oDbKey, oDbDat);

  	} catch (Exception xcpt) {
  	  if (DebugFile.trace) DebugFile.decIdent();
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.store() : "+oRec.getPrimaryKey());
  	}

  } // store

  // --------------------------------------------------------------------------

  public void store(AbstractRecord oRec, Transaction oTrans) throws StorageException {
  	store(oRec);
  }

  // --------------------------------------------------------------------------

  public RecordSet fetch() throws StorageException {
    DBEntitySet oEst = new DBEntitySet();
    DatabaseEntry oDbKey = new DatabaseEntry();
    DatabaseEntry oDbDat = new DatabaseEntry();
    OperationStatus oOst;    
    Cursor oCur = null;

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.fetch()");
  	  DebugFile.incIdent();
  	}

	try {
	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);

	  oCur = oPdb.openCursor(null,null);
	  
	  oOst = oCur.getFirst(oDbKey, oDbDat, LockMode.DEFAULT);
      while (oOst == OperationStatus.SUCCESS) {
        oEst.add(oDbeb.entryToObject(oDbKey,oDbDat)); 
        oOst = oCur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
      } // wend
  	} catch (Exception xcpt) {
  	  if (DebugFile.trace) DebugFile.decIdent();
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.fetch()");
  	}

  	return oEst;
  } // fetch

  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, String sIndexValue, final int iMaxRows)
  	throws StorageException {
		
    if (null==sIndexColumn) throw new StorageException("DBTable.fetch() Column name may not be null");

	if (!oInd.containsKey(sIndexColumn)) throw new StorageException("DBTable.fetch() Column "+sIndexColumn+" is not indexed");

    if (null==sIndexValue) sIndexValue = "";
    
    if (iMaxRows<=0) throw new StorageException("Invalid value for max rows parameter "+String.valueOf(iMaxRows));

    DBEntitySet oEst = new DBEntitySet();
    Cursor oPur = null;
    SecondaryCursor oCur = null;
    OperationStatus oOst;

  	try {

	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
      DatabaseEntry oDbDat = new DatabaseEntry();
      DatabaseEntry oDbKey = new DatabaseEntry();;
      DatabaseEntry oPkKey;

	  if (sIndexValue.equals("%") || sIndexValue.equalsIgnoreCase("IS NOT NULL")) {

	    oPur = oPdb.openCursor(null,null);
	  
	    oOst = oPur.getFirst(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst == OperationStatus.SUCCESS) {
          Record oRec = oDbeb.entryToObject(oDbKey,oDbDat);
          if (oRec.containsKey(sIndexColumn))
            if (oRec.get(sIndexColumn)!=null) oEst.add(oRec);
          oOst = oPur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
        } // wend
        oPur.close();
        oPur = null;
        
	  } else if (sIndexValue.equalsIgnoreCase("NULL") || sIndexValue.equalsIgnoreCase("IS NULL")) {

	    oPur = oPdb.openCursor(null,null);
	    oOst = oPur.getFirst(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst == OperationStatus.SUCCESS) {
          Record oRec = oDbeb.entryToObject(oDbKey,oDbDat);
          if (!oRec.containsKey(sIndexColumn))
          	oEst.add(oRec);
          else if (oRec.get(sIndexColumn)==null) 
          	oEst.add(oRec);
          oOst = oPur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
        } // wend
        oPur.close();
	    oPur=null;

	  } else {

        DBIndex oIdx = oInd.get(sIndexColumn);
	    if (oIdx.isClosed()) openIndex(sIndexColumn);

        oCur = oIdx.getCursor();
	    int r = -1;

	    if (sIndexValue.endsWith("%")) {
		  sIndexValue = sIndexValue.substring(0,sIndexValue.length()-1);
          oDbKey = new DatabaseEntry(sIndexValue.getBytes());
		  oOst = oCur.getSearchKeyRange(oDbKey, oDbDat, LockMode.DEFAULT);

          while (oOst==OperationStatus.SUCCESS && iMaxRows>++r) {
            Record oRec = oDbeb.entryToObject(oDbKey,oDbDat);
            if (oRec.containsKey(sIndexColumn)) {
              if (oRec.getString(sIndexColumn,"").startsWith(sIndexValue)) {
                oEst.add(oRec);
                oOst = oCur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
              } else {
                oOst=OperationStatus.NOTFOUND;
              }
            } else {
          	  oOst=OperationStatus.KEYEMPTY;
            }
          } // wend
		  oCur.close();
		  oCur=null;

	    } else {

          oDbKey = new DatabaseEntry(sIndexValue.getBytes());
          oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
          while (oOst==OperationStatus.SUCCESS && iMaxRows>++r) {
            oEst.add(oDbeb.entryToObject(oDbKey,oDbDat)); 
            oOst = oCur.getNextDup(oDbKey, oDbDat, LockMode.DEFAULT);
          } // wend
          oCur.close();
          oCur.close();

	    } // fi
	  } // fi 

  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oPur!=null) oPur.close(); } catch (Exception ignore) { }
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	}
    return oEst;
  } // fetch

  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, String sIndexValueMin, String sIndexValueMax)
  	throws StorageException {
		
    if (null==sIndexColumn) throw new StorageException("DBTable.fetch() Column name may not be null");
    if (null==sIndexValueMin) throw new StorageException("DBTable.fetch() Index minimum value may not be null");
    if (null==sIndexValueMax) throw new StorageException("DBTable.fetch() Index maximum value may not be null");

	if (!oInd.containsKey(sIndexColumn)) throw new StorageException("DBTable.fetch() Column "+sIndexColumn+" is not indexed");
    
    DBEntitySet oEst = new DBEntitySet();
    Cursor oPur = null;
    SecondaryCursor oCur = null;
    OperationStatus oOst;

  	try {

      DBEntity oDbEnt;
	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
      DatabaseEntry oDbDat = new DatabaseEntry();
      DatabaseEntry oDbKey = new DatabaseEntry();;
      DatabaseEntry oPkKey;
      boolean bMinExists, bMaxExists;

      DBIndex oIdx = oInd.get(sIndexColumn);
	  if (oIdx.isClosed()) openIndex(sIndexColumn);

      oCur = oIdx.getCursor();
	  int r = -1;

      oDbKey = new DatabaseEntry(sIndexValueMin.getBytes());
      oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
      bMinExists = (oOst==OperationStatus.SUCCESS);
      oCur.close();
	  oCur = null;

	  if (bMinExists) {
        oDbKey = new DatabaseEntry(sIndexValueMin.getBytes());
        oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst==OperationStatus.SUCCESS) {
          oDbEnt = oDbeb.entryToObject(oDbKey,oDbDat);
          if (((Comparable)oDbEnt.get(sIndexColumn)).compareTo(sIndexValueMax)>0) break;
          oEst.add(oDbEnt);
          oOst = oCur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
        } // wend
	    oCur.close();
		oCur=null;

	  } else {
	    oPur = oPdb.openCursor(null,null);	  
	    oOst = oPur.getFirst(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst==OperationStatus.SUCCESS) {
          oDbEnt = oDbeb.entryToObject(oDbKey,oDbDat);
          if (((Comparable)oDbEnt.get(sIndexColumn)).compareTo(sIndexValueMax)>0) break;
          if (((Comparable)oDbEnt.get(sIndexColumn)).compareTo(sIndexValueMin)>=0) {
            oOst = oPur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
          } // fi
        } // wend
        oPur.close();
		oPur=null;
	  }

  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oPur!=null) oPur.close(); } catch (Exception ignore) { }
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	}
    return oEst;
  } // fetch

  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, Date dtIndexValueMin, Date dtIndexValueMax)
  	throws StorageException {
  	if (dtIndexValueMax==null)
      return fetch (sIndexColumn, oTsFmt.format(dtIndexValueMin), 2147483647);
  	else
      return fetch (sIndexColumn, oTsFmt.format(dtIndexValueMin), oTsFmt.format(dtIndexValueMin));
  }

  // --------------------------------------------------------------------------

  public RecordSet last(int iRows) throws StorageException {

    DBEntitySet oEst = new DBEntitySet();
	DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
    DatabaseEntry oDbDat = new DatabaseEntry();
    DatabaseEntry oDbKey = new DatabaseEntry();;
	int iFetched = 0;
	Cursor oPur = null;

  	try {
	  oPur = oPdb.openCursor(null,null);	  
	  OperationStatus oOst = oPur.getLast(oDbKey, oDbDat, LockMode.DEFAULT);
      while (oOst==OperationStatus.SUCCESS && ++iFetched<=iRows) {
        oEst.add(oDbeb.entryToObject(oDbKey,oDbDat));
        oOst = oPur.getPrev(oDbKey, oDbDat, LockMode.DEFAULT);
      } // wend
      oPur.close();
      oPur=null;
  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oPur!=null) oPur.close(); } catch (Exception ignore) { }
  	}

	return oEst;
  }

  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, final String sIndexValue) throws StorageException {
    return fetch (sIndexColumn, sIndexValue, 2147483647);
  }

  // --------------------------------------------------------------------------

  public void openIndex(String sColumnName) throws StorageException {
	DBIndex oIdx = oInd.get(sColumnName);
	
    SecondaryConfig oSec = new SecondaryConfig();      
    oSec.setAllowCreate(true);
    oSec.setAllowPopulate(true);
    oSec.setSortedDuplicates(true);
    oSec.setType(DatabaseType.BTREE);
    oSec.setReadOnly(isReadOnly());

    if (oIdx.getRelationType().equalsIgnoreCase("one-to-one") ||
    	oIdx.getRelationType().equalsIgnoreCase("many-to-one")) {
      oSec.setKeyCreator(oRep.getKeyCreator(oIdx.getName()));
    } else if (oIdx.getRelationType().equalsIgnoreCase("one-to-many") ||
    	       oIdx.getRelationType().equalsIgnoreCase("many-to-many")) {
      oSec.setMultiKeyCreator(oRep.getMultiKeyCreator(oIdx.getName()));	
    } else {
      throw new StorageException("Invalid relationship "+oIdx.getRelationType());
    }

    try {
	  oIdx.open(oRep.getEnvironment().openSecondaryDatabase(null, oRep.getPath()+oPdb.getDatabaseName()+"."+oIdx.getName()+".db",
                                                            oPdb.getDatabaseName()+"_"+oIdx.getName(), oPdb, oSec));
    } catch (DatabaseException dbe) {
      throw new StorageException(dbe.getMessage(), dbe);
    } catch (FileNotFoundException dbe) {
      throw new StorageException(dbe.getMessage(), dbe);
    }
	
  }
 
  // --------------------------------------------------------------------------
  
  public void delete(final String sIndexColumn, final String sIndexValue) throws StorageException {

    SecondaryDatabase oSdb = null;
    SecondaryCursor oCur = null;

  	try {
    
	  DBIndex oIdx = oInd.get(sIndexColumn);
	  
	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
      DatabaseEntry oDbKey = new DatabaseEntry(sIndexValue.getBytes());
      DatabaseEntry oDbDat = new DatabaseEntry();
      oCur = oIdx.getCursor();
      
      // oCur.setCacheMode(CacheMode.UNCHANGED);

      OperationStatus oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
      while (oOst == OperationStatus.SUCCESS) {
        oCur.delete();
        oOst = oCur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
      } // wend
  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	}
  } // delete

  // --------------------------------------------------------------------------
  
  public void delete(final String sKeyValue) throws StorageException {

	try {
      oPdb.delete(null, new DatabaseEntry(sKeyValue.getBytes()));
  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}
  } // delete

  // --------------------------------------------------------------------------
  
  public void dropIndex(final String sIndexColumn) throws StorageException {
  	try {

  	  if (oInd.containsKey(sIndexColumn)) {
	    DBIndex oIdx = oInd.get(sIndexColumn);
	    oIdx.close();
	    oInd.remove(sIndexColumn);
		Database.remove(oRep.getPath()+oPdb.getDatabaseName()+"."+oIdx.getName()+".db",
                        oPdb.getDatabaseName()+"_"+oIdx.getName(), null);
  	  } else {
  	  	throw new StorageException("Index not found "+sIndexColumn);
  	  }
 
  	} catch (DatabaseException dbe) {
  	  throw new StorageException(dbe.getMessage(), dbe);
  	} catch (FileNotFoundException fnf) {
  	  throw new StorageException(fnf.getMessage(), fnf);
  	}
  } // dropIndex

  // --------------------------------------------------------------------------

  public void truncate() throws StorageException {

	if (isReadOnly()) throw new StorageException("DBTable.truncate() table "+getName()+" is in read-only mode");

	try {

      oPdb.truncate(null,false);

  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} 
  } // truncate

  // --------------------------------------------------------------------------

  public static String createUniqueKey() {

    int iRnd;
    long lSeed = new Date().getTime();
    Random oRnd = new Random(lSeed);
    String sHex;
    StringBuffer sUUID = new StringBuffer(32);
    byte[] localIPAddr = new byte[4];

    try {

      // 8 characters Code IP address of this machine
      localIPAddr = InetAddress.getLocalHost().getAddress();

      sUUID.append(byteToStr[((int) localIPAddr[0]) & 255]);
      sUUID.append(byteToStr[((int) localIPAddr[1]) & 255]);
      sUUID.append(byteToStr[((int) localIPAddr[2]) & 255]);
      sUUID.append(byteToStr[((int) localIPAddr[3]) & 255]);
    }
    catch (UnknownHostException e) {
      // Use localhost by default
      sUUID.append("7F000000");
    }

    // Append a seed value based on current system date
    sUUID.append(Long.toHexString(lSeed));

    // 6 characters - an incremental sequence
    sUUID.append(Integer.toHexString(iSequence++));

    if (iSequence>16777000) iSequence=1048576;

    do {
      iRnd = oRnd.nextInt();
      if (iRnd>0) iRnd = -iRnd;
      sHex = Integer.toHexString(iRnd);
    } while (0==iRnd);

    // Finally append a random number
    sUUID.append(sHex);

    return sUUID.substring(0, 32);
  } // generateUUID()

  private static int iSequence = 1048576;

  private static String[] byteToStr = {
                                 "00","01","02","03","04","05","06","07","08","09","0a","0b","0c","0d","0e","0f",
                                 "10","11","12","13","14","15","16","17","18","19","1a","1b","1c","1d","1e","1f",
                                 "20","21","22","23","24","25","26","27","28","29","2a","2b","2c","2d","2e","2f",
                                 "30","31","32","33","34","35","36","37","38","39","3a","3b","3c","3d","3e","3f",
                                 "40","41","42","43","44","45","46","47","48","49","4a","4b","4c","4d","4e","4f",
                                 "50","51","52","53","54","55","56","57","58","59","5a","5b","5c","5d","5e","5f",
                                 "60","61","62","63","64","65","66","67","68","69","6a","6b","6c","6d","6e","6f",
                                 "70","71","72","73","74","75","76","77","78","79","7a","7b","7c","7d","7e","7f",
                                 "80","81","82","83","84","85","86","87","88","89","8a","8b","8c","8d","8e","8f",
                                 "90","91","92","93","94","95","96","97","98","99","9a","9b","9c","9d","9e","9f",
                                 "a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","aa","ab","ac","ad","ae","af",
                                 "b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","ba","bb","bc","bd","be","bf",
                                 "c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","ca","cb","cc","cd","ce","cf",
                                 "d0","d1","d2","d3","d4","d5","d6","d7","d8","d9","da","db","dc","dd","de","df",
                                 "e0","e1","e2","e3","e4","e5","e6","e7","e8","e9","ea","eb","ec","ed","ee","ef",
                                 "f0","f1","f2","f3","f4","f5","f6","f7","f8","f9","fa","fb","fc","fd","fe","ff" };

}
