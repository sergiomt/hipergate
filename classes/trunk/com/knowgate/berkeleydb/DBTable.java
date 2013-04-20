package com.knowgate.berkeleydb;

import java.io.FileNotFoundException;

import java.util.Date;
import java.util.HashMap;
import java.util.Random;

import java.text.SimpleDateFormat;

import java.sql.Types;

import java.net.InetAddress;
import java.net.UnknownHostException;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.LinkedList;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.NameValuePair;

import com.knowgate.storage.DataSource;
import com.knowgate.storage.Table;
import com.knowgate.storage.Column;
import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.AbstractRecord;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.IntegrityViolationException;

import com.sleepycat.db.Cursor;
import com.sleepycat.db.JoinCursor;
import com.sleepycat.db.JoinConfig;
import com.sleepycat.db.Database;
import com.sleepycat.db.LockMode;
import com.sleepycat.db.Transaction;
import com.sleepycat.db.DatabaseType;
import com.sleepycat.db.OperationStatus;
import com.sleepycat.db.DatabaseEntry;
import com.sleepycat.db.SecondaryConfig;
import com.sleepycat.db.SecondaryCursor;
import com.sleepycat.db.SecondaryDatabase;
import com.sleepycat.db.DatabaseException;
import com.sleepycat.db.DeadlockException;

import com.sleepycat.bind.EntryBinding;
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
  private Transaction oTrn;
    
  private static SimpleDateFormat oTsFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  @SuppressWarnings("unused")
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
    try {
      if (oRep.isTransactional())
	    oTrn = oRep.getEnvironment().beginTransaction(null,null);
      else
    	oTrn = null;
    } catch (DatabaseException dbe) {
      throw new StorageException(dbe.getMessage(),dbe);
    }
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

  private void abort() throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.abort()");
  	  DebugFile.incIdent();
  	}
  	
  	if (oTrn!=null) {
      try {
	    oTrn.abort();
	    oTrn = null;
      } catch (DatabaseException dbe) {
        throw new StorageException(dbe.getMessage(),dbe);
      }
  	} // fi

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.abort()");
  	}
  } // close
  
  // --------------------------------------------------------------------------

  public void close() throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.close()");
  	  DebugFile.incIdent();
  	}
  	
  	if (oTrn!=null) {
      try {
	    oTrn.commitNoSync();
	    oTrn = null;
      } catch (DatabaseException dbe) {
        throw new StorageException(dbe.getMessage(),dbe);
      }
  	} // fi
  	
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

  public LinkedList<Column> columns() {
  	LinkedList<Column> oLst;
  	try {
  	  if (null==getDataSource().getMetaData()) return null;
  	  oLst = getDataSource().getMetaData().getColumns(getName());
  	} catch (Exception xcpt) { oLst = null; }
    return oLst;
  }

  // --------------------------------------------------------------------------

  public Database getDatabase() {
  	return oPdb;
  }

  // --------------------------------------------------------------------------

  public DataSource getDataSource() {
  	return (DataSource) oRep;
  }

  // --------------------------------------------------------------------------

  public void delete(AbstractRecord oRec, Transaction oTrans) throws StorageException {

    if (oRec.getPrimaryKey()==null)
  	  throw new StorageException("Tried to delete record with no primary key");	

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.delete("+oRec.getTableName()+"."+oRec.getPrimaryKey()+")");
  	  DebugFile.incIdent();
  	  byte[] aByKey = oRec.getPrimaryKey().getBytes();
  	  StringBuffer oStrKey = new StringBuffer(aByKey.length*3);
  	  for (int b=0; b<aByKey.length; b++) oStrKey.append(" "+Integer.toHexString(aByKey[b]));
  	  DebugFile.writeln("raw key hex is"+oStrKey.toString());
  	}

	try {
	  oPdb.delete(oTrans, new DatabaseEntry(oRec.getPrimaryKey().getBytes()));
	} catch (DatabaseException dbe) {
  	  if (DebugFile.trace) DebugFile.decIdent();
  	  abort();
	  throw new StorageException(dbe.getMessage(), dbe);
	}

  	if (DebugFile.trace) {
  	  DebugFile.writeln("End DBTable.delete()");
  	  DebugFile.decIdent();
  	}
  } // delete

  // --------------------------------------------------------------------------

  public void delete(AbstractRecord oRec) throws StorageException {
    delete(oRec, oTrn);
  }
  
  // --------------------------------------------------------------------------
    
  public boolean exists(String sKey) throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.exists("+sKey+" at "+sCnm+"."+sDbk+")");
  	  DebugFile.incIdent();
  	  byte[] aByKey = sKey.getBytes();
  	  StringBuffer oStrKey = new StringBuffer(aByKey.length*3);
  	  for (int b=0; b<aByKey.length; b++) oStrKey.append(" "+Integer.toHexString(aByKey[b]));
  	  DebugFile.writeln("raw key hex is"+oStrKey.toString());
  	}

	boolean bRetVal = false;
	OperationStatus oOpSt;
	
  	try {
  	  oOpSt = oPdb.get(oTrn, new DatabaseEntry(sKey.getBytes()), new DatabaseEntry(), LockMode.DEFAULT);
  	  bRetVal = (OperationStatus.SUCCESS==oOpSt);
  	} catch (DeadlockException dlxc) {
  	  abort();
      throw new StorageException(dlxc.getMessage(), dlxc);
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
  	  if (OperationStatus.SUCCESS==oPdb.get(oTrn, oDbKey, oDbDat, LockMode.DEFAULT)) {
	    DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
  	    oDbEnt = oDbeb.entryToObject(oDbKey,oDbDat);
  	  }
  	} catch (DeadlockException dlxc) {
      if (DebugFile.trace) DebugFile.decIdent();
      abort();
      throw new StorageException(dlxc.getMessage(), dlxc);
  	} catch (Exception xcpt) {
  	  if (DebugFile.trace) DebugFile.decIdent();
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.load()");
  	}

  	return oDbEnt;
  } // load

  // --------------------------------------------------------------------------
  
  public Record load(Object[] aKey) throws StorageException {

	if (aKey.length!=1) throw new StorageException("Berkeley DB does not allow primary key composed of multiple values");

  	return load(aKey[0].toString());
  } // load
  
  // --------------------------------------------------------------------------
  
  public Record newRecord() throws StorageException {
  	return new DBEntity(getName(), columns());
  } // load

  // --------------------------------------------------------------------------

  public void store(AbstractRecord oRec, Transaction oTrans) throws StorageException {
  	
  	if (isReadOnly()) throw new StorageException("DBTable.store() table "+getName()+" is in read-only mode");

  	if (oRec==null) throw new NullPointerException("DBTable.store() Record to be stored is null");

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.store("+getName()+"."+oRec.getPrimaryKey()+")");
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
		
		boolean bHasCompoundIndexes = false;
		
  		if (DebugFile.trace) {
  	      String sColNames = "Iterating through";
  	      for (Column c : oRec.columns()) sColNames += " "+c.getName();
		  DebugFile.writeln(sColNames);
  	    }
		
  	    for (Column c : oRec.columns()) {
  	      String n = c.getName();

		  boolean bIsEmptyPk = !oRec.containsKey(n);
		  if (!bIsEmptyPk) bIsEmptyPk = (oRec.get(n).toString().length()==0);
		  Object sDefVal = c.getDefaultValue();

		  if (sDefVal!=null) {
  	        if (bIsEmptyPk) {

  	      	  if (sDefVal.equals("GUID")) {
  	            oRec.put(n, createUniqueKey());

  	      	  } else if (sDefVal.equals("SERIAL")) {
  	      	    String sSerial = String.valueOf(oRep.nextVal(n));
		        int iPadLen = (c.getType()==Types.BIGINT ? 21 : 11) - sSerial.length();
      		    if (iPadLen>0) {
      			  char aPad[] = new char[iPadLen];
      			  Arrays.fill(aPad, '0');
     		  	  sSerial = new String(aPad) + sSerial;
      		    }
  	            oRec.put(n, sSerial);

  	      	  } else if (sDefVal.equals("NOW")) {
  	            oRec.put(n, oTsFmt.format(new Date()));

  	      	  } else if (sDefVal.toString().indexOf('+')<0) {
  	            if (sDefVal.toString().startsWith("$"))
  	              oRec.put(n, Gadgets.ASCIIEncode(oRec.getString(sDefVal.toString().substring(1))).replace(' ','_').toLowerCase());
  	            else if (sDefVal.toString().startsWith("'"))
				  oRec.put(n, sDefVal.toString().substring(1, sDefVal.toString().indexOf((char) 39, 1)));
  	            else
  	              oRec.put(n, sDefVal);
  	      	  } else {
				String[] aCols = Gadgets.split(sDefVal.toString(),'+');
				sDefVal = "";
				if (aCols!=null)
				  for (int v=0; v<aCols.length; v++)
				  	if (aCols[v].startsWith("$"))
				  	  sDefVal = sDefVal + Gadgets.ASCIIEncode(oRec.getString(aCols[v].substring(1))).replace(' ','_').toLowerCase();
				  	else if (aCols[v].startsWith("'"))
				  	  sDefVal = sDefVal + aCols[v].substring(1, aCols[v].indexOf((char) 39, 1));
				  	else
				  	  sDefVal = sDefVal.toString() + oRec.get(aCols[v]);
  	            oRec.put(n, sDefVal);				
  	      	  }
  	          if (c.isPrimaryKey()) {
  			    if (DebugFile.trace)
  	  		      DebugFile.writeln("auto setting default value of "+n+" to "+oRec.get(n));
  	            oRec.setPrimaryKey(oRec.get(n).toString());
  	          }
  	        } // fi
  	        bHasCompoundIndexes = (sDefVal.toString().indexOf('+')>0);
		  } // fi
		  
  	  	  if (!c.isNullable() && !oRec.containsKey(n)) {
		    if (sDefVal==null)
		      throw new IntegrityViolationException(c, null);
			else if (sDefVal.toString().indexOf('+')<0)
		      throw new IntegrityViolationException(c, null);
  	  	  }

  	      if (oRec.containsKey(n) && c.getForeignKey()!=null) {
			if (oRec.get(n)!=null) {
			  if (oRec.get(n).toString().length()>0) {
  			    if (DebugFile.trace)
  	  		      DebugFile.writeln("Checking "+c.getForeignKey()+"."+c.getName()+" for value "+oRec.get(n));

  	  	        DBTable oFk = (DBTable) oRep.openTable(c.getForeignKey(), new String []{c.getName()});
  	            boolean bExists;
  	            String sNum;
  	            if (c.getType()==Types.INTEGER) {
  	              sNum = String.valueOf(oRec.getInt(n));
  	              if (sNum.length()>=11) {
  	                bExists = oFk.exists(sNum);
  	              } else {
			        bExists = oFk.exists(sNum);
			        if (!bExists) {
      				  char iPad[] = new char[11-sNum.length()];
      				  Arrays.fill(iPad, '0');
			          bExists = oFk.exists(new String(iPad) + sNum);
			          if (bExists) oRec.put(n,new String(iPad) + sNum);
			        } // fi (!bExists)
  	              }
  	            } else if (c.getType()==Types.BIGINT) {
  	              sNum = String.valueOf(oRec.getLong(n));
  	              if (sNum.length()>=21) {
  	                bExists = oFk.exists(sNum);
  	              } else {
			        bExists = oFk.exists(sNum);
			        if (!bExists) {
      				  char iPad[] = new char[21-sNum.length()];
      				  Arrays.fill(iPad, '0');
			          bExists = oFk.exists(new String(iPad) + sNum);
			          if (bExists) oRec.put(n,new String(iPad) + sNum);
			        } // fi (!bExists)
  	              }
  	            } else {
  	              sNum = oRec.getString(n);
			      bExists = oFk.exists(sNum);
  	            }
  	            oFk.close();
  	            if (!bExists) throw new IntegrityViolationException(c,sNum);
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
  	      if (c.getType()==Types.BOOLEAN) {
  	        if (oRec.containsKey(n)) {
  	      	  if (oRec.get(n) instanceof String) {
  	      	    if (oRec.get(n).equals("true") || oRec.get(n).equals("True") || oRec.get(n).equals("TRUE") ||
  	      	    	oRec.get(n).equals("yes")  || oRec.get(n).equals("Yes")  || oRec.get(n).equals("YES")  ||
  	      	    	oRec.get(n).equals("1"))
  	      	      oRec.replace(n, Boolean.TRUE);
  	      	    else if (oRec.get(n).equals("false") || oRec.get(n).equals("False") || oRec.get(n).equals("FALSE") ||
  	      	    	oRec.get(n).equals("no")  || oRec.get(n).equals("No")  || oRec.get(n).equals("NO")  ||
  	      	    	oRec.get(n).equals("0"))
  	      	      oRec.replace(n, Boolean.FALSE);
  	      	  } // fi (instanceof String)
  	      	  if (oRec.get(n) instanceof Short) {
  	      	    if (oRec.get(n).equals(new Short((short)1)))
  	      	      oRec.replace(n, Boolean.TRUE);
  	      	    else if (oRec.get(n).equals(new Short((short)0)))
  	      	      oRec.replace(n, Boolean.FALSE);
  	      	  } // fi (instanceof String)
  	      	  if (oRec.get(n) instanceof Integer) {
  	      	    if (oRec.get(n).equals(new Integer(1)))
  	      	      oRec.replace(n, Boolean.TRUE);
  	      	    else if (oRec.get(n).equals(new Integer(0)))
  	      	      oRec.replace(n, Boolean.FALSE);
  	      	  } // fi (instanceof String)  	        
  	      	  if (!(oRec.get(n) instanceof Boolean)) {
  	      	    throw new IntegrityViolationException(c,"Must be of type Boolean but is actually "+oRec.get(n).getClass().getName());
  	      	  }
  	        }
  	      } // fi (BOOLEAN)
  	    } // next
  	    
  	    if (DebugFile.trace) {
  	      DebugFile.writeln("table "+(bHasCompoundIndexes ? " has " : " has not ")+"compound indexes");  	    	
  	    }

  	    if (bHasCompoundIndexes) {
  	      for (Column c : oRec.columns()) {
  	        String n = c.getName();
		    if (c.getDefaultValue()!=null) {
		      String sDefVal = c.getDefaultValue().toString();
  	      	  if (sDefVal.indexOf('+')>0) {
		        // boolean bIsEmptyPk = !oRec.containsKey(n);
		  	    // if (!bIsEmptyPk) bIsEmptyPk = (oRec.get(n).toString().length()==0);
  	            // if (bIsEmptyPk) {
  	              String[] aIndexColumns = sDefVal.split("\\x2B");
				  StringBuffer oCompoundIndexValue = new StringBuffer(1000);
				  for (int i=0; i<aIndexColumns.length; i++) {
				  	oCompoundIndexValue.append(oRec.get(aIndexColumns[i]));
				  } // next
				  oRec.put(n, oCompoundIndexValue.toString());
  	    		  if (DebugFile.trace) {
  	      			DebugFile.writeln("compound index "+n+" value set to \""+oRec.getString(n)+"\"");
  	    		  }
  	            // } // fi
  	      	  } // fi (indexOf('+')>0)
		    } // fi (getDefaultValue())
		    if (!c.check(oRec.get(n)))
		      throw new IntegrityViolationException(c, oRec.get(n));
  	      } // next (c)
  	    } else {
  	      for (Column c : oRec.columns()) {
		    if (!c.check(oRec.get(c.getName())))
		      throw new IntegrityViolationException(c, oRec.get(c.getName()));
  	      } // next
  	    }
  	  } // fi

	  if (oRec.getPrimaryKey()==null)
	  	throw new IntegrityViolationException("Primary key not set and no default specified at table "+oRec.getTableName());
	  else if (oRec.getPrimaryKey().length()==0)
	  	throw new IntegrityViolationException("Empty string not allowed as primary key at table "+oRec.getTableName());
	  	
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
  	  
  	  if (DebugFile.trace) DebugFile.writeln("Database.put("+(oTrans==null ? "null" : oTrans)+","+oRec.getPrimaryKey()+","+"[DatabaseEntry])");
  	  	
  	  oPdb.put(oTrans, oDbKey, oDbDat);

  	} catch (DeadlockException dlxc) {
      if (DebugFile.trace) {
    	DebugFile.writeln("DeadlockException "+dlxc.getMessage());
    	try { DebugFile.writeln(StackTraceUtil.getStackTrace(dlxc)); } catch (java.io.IOException ignore) {}
    	  DebugFile.decIdent();
      }
      abort();
      throw new StorageException(dlxc.getMessage(), dlxc);  	  
  	} catch (Exception xcpt) {
  	  if (DebugFile.trace) {
  	  	DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
  	  	try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (java.io.IOException ignore) {}
  	  	DebugFile.decIdent();
  	  }
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.store() : "+oRec.getPrimaryKey());
  	}

  } // store

  // --------------------------------------------------------------------------

  public void store(AbstractRecord oRec) throws StorageException {  	
    store(oRec, oTrn);
  } // store

  // --------------------------------------------------------------------------

  public RecordSet fetch(final int iMaxRows, final int iOffset) throws StorageException {
    DBEntitySet oEst = new DBEntitySet();
    DatabaseEntry oDbKey = new DatabaseEntry();
    DatabaseEntry oDbDat = new DatabaseEntry();
    OperationStatus oOst;    
    Cursor oCur = null;
    int iFetched = 0;
    int iAdded = 0;

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.fetch()");
  	  DebugFile.incIdent();
  	}

	try {
	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);

	  oCur = oPdb.openCursor(null,null);
	  
	  oOst = oCur.getFirst(oDbKey, oDbDat, LockMode.DEFAULT);
      while (oOst == OperationStatus.SUCCESS && iAdded<iMaxRows) {
        if (++iFetched>iOffset) {
          oEst.add(oDbeb.entryToObject(oDbKey,oDbDat)); 
          iAdded++;
        }
        oOst = oCur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
      } // wend
      oCur.close();
      oCur=null;
  	} catch (DeadlockException dlxc) {
      if (DebugFile.trace) DebugFile.decIdent();
      abort();
      throw new StorageException(dlxc.getMessage(), dlxc);
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

  public RecordSet fetch() throws StorageException {
    return fetch(2147483647,0);
  }

  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, String sIndexValue, final int iMaxRows)
  	throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.fetch("+sIndexColumn+","+sIndexValue+","+String.valueOf(iMaxRows)+")");
  	  DebugFile.incIdent();
  	}
		
    if (null==sIndexColumn) throw new StorageException("DBTable.fetch() Column name may not be null");

	if (!oInd.containsKey(sIndexColumn)) throw new StorageException("DBTable.fetch() Column "+sIndexColumn+" is not a secondary index");

    if (null==sIndexValue) sIndexValue = "";
    
    if (iMaxRows<=0) throw new StorageException("Invalid value for max rows parameter "+String.valueOf(iMaxRows));

    DBEntitySet oEst = new DBEntitySet();
    Cursor oPur = null;
    SecondaryCursor oCur = null;
    OperationStatus oOst;

  	try {

	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
      DatabaseEntry oDbDat = new DatabaseEntry();
      DatabaseEntry oDbKey = new DatabaseEntry();

	  if (sIndexValue.equals("%") || sIndexValue.equalsIgnoreCase("IS NOT NULL")) {

  		if (DebugFile.trace) DebugFile.writeln("Database.openCursor(null,null)");

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

  		if (DebugFile.trace) DebugFile.writeln("Database.openCursor(null,null)");

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

        oCur = oIdx.getCursor(oTrn);
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

	    } else {

          oDbKey = new DatabaseEntry(sIndexValue.getBytes());
          oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
          while (oOst==OperationStatus.SUCCESS && iMaxRows>++r) {
            oEst.add(oDbeb.entryToObject(oDbKey,oDbDat)); 
            oOst = oCur.getNextDup(oDbKey, oDbDat, LockMode.DEFAULT);
          } // wend

	    } // fi

	    oCur.close();
		oCur=null;

	  } // fi 

  	} catch (DeadlockException dlxc) {
      if (DebugFile.trace) {
    	DebugFile.writeln(dlxc.getClass().getName()+" "+dlxc.getMessage());
    	try { DebugFile.writeln(StackTraceUtil.getStackTrace(dlxc)); } catch (Exception ignore) { }
    	DebugFile.decIdent();
      }
      abort();
      throw new StorageException(dlxc.getMessage(), dlxc);
  	} catch (Exception xcpt) {
  	  if (DebugFile.trace) {
  	    DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
		try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (Exception ignore) { }
  	    DebugFile.decIdent();
  	  }
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oPur!=null) oPur.close(); } catch (Exception ignore) { }
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.fetch() : " + String.valueOf(oEst.size()));
  	}

    return oEst;
  } // fetch

  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, String sIndexValueMin, String sIndexValueMax)
  	throws StorageException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin DBTable.fetch("+sIndexColumn+","+sIndexValueMin+","+sIndexValueMax+")");
  	  DebugFile.incIdent();
  	}
		
    if (null==sIndexColumn) throw new StorageException("DBTable.fetch() Column name may not be null");
    if (null==sIndexValueMin) throw new StorageException("DBTable.fetch() Index minimum value may not be null");
    if (null==sIndexValueMax) throw new StorageException("DBTable.fetch() Index maximum value may not be null");

	if (!oInd.containsKey(sIndexColumn)) throw new StorageException("DBTable.fetch() Column "+sIndexColumn+" is not indexed");
    
    DBEntitySet oEst = new DBEntitySet();
    Cursor oPur = null;
    SecondaryCursor oCur = null;
    OperationStatus oOst;

  	try {

      Comparable oValue;
      DBEntity oDbEnt;
	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
      DatabaseEntry oDbDat = new DatabaseEntry();
      DatabaseEntry oDbKey = new DatabaseEntry();;
      boolean bMinExists;

      DBIndex oIdx = oInd.get(sIndexColumn);
	  if (oIdx.isClosed()) openIndex(sIndexColumn);

      oCur = oIdx.getCursor(oTrn);

	  if (DebugFile.trace) DebugFile.writeln("got SecondaryCursor for "+sIndexColumn);

      oDbKey = new DatabaseEntry(sIndexValueMin.getBytes());
      oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
      bMinExists = (oOst==OperationStatus.SUCCESS);
      oCur.close();
	  oCur = null;

	  if (DebugFile.trace) DebugFile.writeln(sIndexColumn+" has "+(bMinExists ? "" : "not")+" a minimum value");

	  if (bMinExists) {
		oCur = oIdx.getCursor(oTrn);
		oDbKey = new DatabaseEntry(sIndexValueMin.getBytes());
        oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst==OperationStatus.SUCCESS) {
          oDbEnt = oDbeb.entryToObject(oDbKey,oDbDat);
          oValue = (Comparable)oDbEnt.get(sIndexColumn);
          if (oValue!=null) {
            if (oValue.compareTo(sIndexValueMax)>0) break;
            oEst.add(oDbEnt);
          }
          oOst = oCur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
        } // wend
	    oCur.close();
		oCur=null;

	  } else {
	    oPur = oPdb.openCursor(null,null);	  
	    oOst = oPur.getFirst(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst==OperationStatus.SUCCESS) {
          oDbEnt = oDbeb.entryToObject(oDbKey,oDbDat);
          oValue = (Comparable)oDbEnt.get(sIndexColumn);
          if (oValue!=null) {
            if (oValue.compareTo(sIndexValueMax)>0) break;
            oEst.add(oDbEnt);
          }
          oOst = oPur.getNext(oDbKey, oDbDat, LockMode.DEFAULT);
        } // wend
        oPur.close();
		oPur=null;
	  }

  	} catch (DeadlockException dlxc) {
      if (DebugFile.trace) {
    	DebugFile.writeln(dlxc.getClass().getName()+" "+dlxc.getMessage());
    	try { DebugFile.writeln(StackTraceUtil.getStackTrace(dlxc)); } catch (Exception ignore) { }
    	DebugFile.decIdent();
      }
      abort();
      throw new StorageException(dlxc.getMessage(), dlxc);
  	} catch (Exception xcpt) {
  	  if (DebugFile.trace) {
  	    DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
		try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (Exception ignore) { }
  	    DebugFile.decIdent();
  	  }
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oPur!=null) oPur.close(); } catch (Exception ignore) { }
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End DBTable.fetch() " + String.valueOf(oEst.size()));
  	}

    return oEst;
  } // fetch

  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, Date dtIndexValueMin, Date dtIndexValueMax)
  	throws StorageException {
  	if (dtIndexValueMax==null)
      return fetch (sIndexColumn, oTsFmt.format(dtIndexValueMin), 2147483647);
  	else if (dtIndexValueMin==null)
      return fetch (sIndexColumn, "0000-00-00 00:00:00", oTsFmt.format(dtIndexValueMax));
  	else
      return fetch (sIndexColumn, oTsFmt.format(dtIndexValueMin), oTsFmt.format(dtIndexValueMax));
  }

  // --------------------------------------------------------------------------

  public RecordSet fetch(NameValuePair[] aIndexedValues, final int iMaxRows)
  	throws StorageException {

    if (null==aIndexedValues) throw new StorageException("DBTable.fetch() Column names may not be null");

	final int nValues = aIndexedValues.length;

	if (1==nValues)	{

	  return fetch (aIndexedValues[0].getName(),aIndexedValues[0].getValue(), iMaxRows);

	} else {
  	  if (DebugFile.trace) {
  	    String sPairs = "";
  	    for (int nv=0; nv<nValues; nv++) {
  	    	sPairs+=(nv==0 ? "" : ",")+aIndexedValues[nv].getName()+":"+aIndexedValues[nv].getValue();
	      if (!oInd.containsKey(aIndexedValues[nv].getName()))
	        throw new StorageException("DBTable.fetch() Column "+aIndexedValues[nv].getName()+" is not indexed");
  	      if (aIndexedValues[nv].getValue()==null)
	        throw new StorageException("DBTable.fetch() Column "+aIndexedValues[nv].getName()+" may not be null");
  	      if (aIndexedValues[nv].getValue().indexOf('%')>=0)
	        throw new StorageException("DBTable.fetch() "+aIndexedValues[nv].getName()+" % wildcards are not allowed in join cursors");
  	      if (aIndexedValues[nv].getValue().equalsIgnoreCase("null") || aIndexedValues[nv].getValue().equalsIgnoreCase("is null") || aIndexedValues[nv].getValue().equalsIgnoreCase("is not null"))
	        throw new StorageException("DBTable.fetch() "+aIndexedValues[nv].getName()+" IS [NOT] NULL conditional is not allowed in join cursors");
  	    } // next
  	    DebugFile.writeln("Begin DBTable.fetch({"+sPairs+"},"+String.valueOf(iMaxRows)+")");
  	    DebugFile.incIdent();
  	  }
      
      if (iMaxRows<=0) throw new StorageException("Invalid value for max rows parameter "+String.valueOf(iMaxRows));
      
	    DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
      DatabaseEntry oDbDat = new DatabaseEntry();
      DatabaseEntry oDbKey = new DatabaseEntry();
      DBEntitySet oEst = new DBEntitySet();
      JoinCursor oJur = null;
      
      OperationStatus[] aOst = new OperationStatus[nValues];
	    DBIndex[] aIdxs = new DBIndex[nValues];	
      SecondaryCursor[] aCurs = new SecondaryCursor[aIndexedValues.length];
	    
  	  try {
      
	    for (int sc=0; sc<nValues; sc++) {
	      aIdxs[sc] = oInd.get(aIndexedValues[sc].getName());
	      if (aIdxs[sc].isClosed()) openIndex(aIndexedValues[sc].getName());	  
	      aCurs[sc] = aIdxs[sc].getCursor(oTrn);
	      aOst[sc] = aCurs[sc].getSearchKey(new DatabaseEntry(aIndexedValues[sc].getValue().getBytes()), new DatabaseEntry(), LockMode.DEFAULT);
	    } // next
      
	    oJur = oPdb.join(aCurs, JoinConfig.DEFAULT);
      
        while (oJur.getNext(oDbKey, oDbDat, LockMode.DEFAULT) == OperationStatus.SUCCESS) {
          Record oRec = oDbeb.entryToObject(oDbKey,oDbDat);
		  oEst.add(oRec);
        } // wend
      
	    oJur.close();
	    oJur=null;
	    
	    for (int sc=nValues-1; sc>=0; sc--) {
	    	aCurs[sc].close();
	      aIdxs[sc].close();
	    }
	    	  
  	  } catch (DeadlockException dlxc) {
    	if (DebugFile.trace) {
    	  DebugFile.writeln(dlxc.getClass().getName()+" "+dlxc.getMessage());
  		  try { DebugFile.writeln(StackTraceUtil.getStackTrace(dlxc)); } catch (Exception ignore) { }
    	  DebugFile.decIdent();
    	}
    	abort();
    	throw new StorageException(dlxc.getMessage(), dlxc);
  	  } catch (Exception xcpt) {
  	    if (DebugFile.trace) {
  	      DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
		  try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (Exception ignore) { }
  	      DebugFile.decIdent();
  	    }
  	    throw new StorageException(xcpt.getMessage(), xcpt);
  	  } finally {
  	    try { if (oJur!=null) oJur.close(); } catch (Exception ignore) { }
	    for (int sc=nValues-1; sc>=0; sc--) {
	      try { if (aCurs[sc]!=null) aCurs[sc].close(); } catch (Exception ignore) { }
	      try { if (aIdxs[sc]!=null) aIdxs[sc].close(); } catch (Exception ignore) { }
	    } // next
  	  }
      
  	  if (DebugFile.trace) {
  	    DebugFile.decIdent();
  	    DebugFile.writeln("End DBTable.fetch() : " + String.valueOf(oEst.size()));
  	  }	
      return oEst;
	} // fi
  } // fetch

  // --------------------------------------------------------------------------

  public RecordSet last(final String sOrderByColumn, final int iRows, final int iOffset) throws StorageException {

    DBEntitySet oEst = new DBEntitySet();
	DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
    DatabaseEntry oDbDat = new DatabaseEntry();
    DatabaseEntry oDbKey = new DatabaseEntry();;
	OperationStatus oOst;
	Cursor oPur = null;
    SecondaryCursor oCur = null;
	int iFetched = 0;
	int iAdded = 0;

  	try {
	  if (sOrderByColumn==null) {
	    oPur = oPdb.openCursor(null,null);	  
	    oOst = oPur.getLast(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst==OperationStatus.SUCCESS && iAdded<iRows) {
          if (++iFetched>iOffset) {
            oEst.add(oDbeb.entryToObject(oDbKey,oDbDat));
            iAdded++;
          }
          oOst = oPur.getPrev(oDbKey, oDbDat, LockMode.DEFAULT);
        } // wend
        oPur.close();
        oPur=null;
		
	  } else {
    	
        DBIndex oIdx = oInd.get(sOrderByColumn);
	    if (oIdx.isClosed()) openIndex(sOrderByColumn);

        oCur = oIdx.getCursor(oTrn);

        oOst = oCur.getLast(oDbKey, oDbDat, LockMode.DEFAULT);
        while (oOst==OperationStatus.SUCCESS && iAdded<iRows) {
          if (++iFetched>iOffset) {
            oEst.add(oDbeb.entryToObject(oDbKey,oDbDat));
            iAdded++;
          }
          oOst = oCur.getPrevDup(oDbKey, oDbDat, LockMode.DEFAULT);
        } // wend
        oCur.close();
        oCur=null;
	  }
	} catch (DeadlockException dlxc) {
	  abort();
	  throw new StorageException(dlxc.getMessage(), dlxc);
  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	  try { if (oPur!=null) oPur.close(); } catch (Exception ignore) { }
  	}

	return oEst;
  } // last


  // --------------------------------------------------------------------------

  public RecordSet fetch(final String sIndexColumn, final String sIndexValue) throws StorageException {
    return fetch (sIndexColumn, sIndexValue, 2147483647);
  }

  // --------------------------------------------------------------------------

  public void openIndex(String sColumnName) throws StorageException {

    if (DebugFile.trace) DebugFile.writeln("openIndex("+sColumnName+")");

	DBIndex oIdx = oInd.get(sColumnName);
    SecondaryConfig oSec = new SecondaryConfig(); 
    oSec.setAllowCreate(true);
    oSec.setAllowPopulate(true);
    oSec.setSortedDuplicates(true);
    oSec.setType(DatabaseType.BTREE);
    oSec.setReadOnly(isReadOnly());

    if (DebugFile.trace) DebugFile.writeln("relation type is "+oIdx.getRelationType());

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
      final String sSecDbPath = oRep.getPath()+oPdb.getDatabaseName()+"."+oIdx.getName()+".db";
      final String sSecIdxName= oPdb.getDatabaseName()+"_"+oIdx.getName();
      if (DebugFile.trace) DebugFile.writeln("DBIndex.open(openSecondaryDatabase("+oTrn+","+sSecDbPath+","+sSecIdxName+","+oPdb+","+oSec+","+String.valueOf(isReadOnly())+"))");
	  oIdx.open(oRep.getEnvironment().openSecondaryDatabase(oTrn, sSecDbPath, sSecIdxName, oPdb, oSec));
	} catch (DeadlockException dle) {
	  if (DebugFile.trace) DebugFile.writeln("DeadlockException "+String.valueOf(dle.getErrno())+" whilst opening secondary database "+dle.getMessage());
	  abort();
	  throw new StorageException(dle.getMessage(), dle);
    } catch (DatabaseException dbe) {
      if (DebugFile.trace) DebugFile.writeln("DatabaseException "+String.valueOf(dbe.getErrno())+" whilst opening secondary database "+dbe.getMessage());
      throw new StorageException(dbe.getMessage(), dbe);
    } catch (FileNotFoundException fnf) {
      if (DebugFile.trace) DebugFile.writeln("FileNotFoundException "+fnf.getMessage());
      throw new StorageException(fnf.getMessage(), fnf);
    }
	
  }
 
  // --------------------------------------------------------------------------
  
  public void delete(final String sIndexColumn, final String sIndexValue) throws StorageException {

    Transaction oTrd = null;
    SecondaryDatabase oSdb = null;
    SecondaryCursor oCur = null;
    SecondaryConfig oSec = new SecondaryConfig(); 
    oSec.setAllowCreate(false);
    oSec.setAllowPopulate(false);
    oSec.setType(DatabaseType.BTREE);
    oSec.setReadOnly(true);

  	try {
      String sIndexName;
      
	  if (sIndexColumn.startsWith("one-to-one")) {
        sIndexName = sIndexColumn.substring(10).trim();
        oSec.setKeyCreator(oRep.getKeyCreator(sIndexName));
	  } else if (sIndexColumn.startsWith("many-to-one")) {
        sIndexName = sIndexColumn.substring(11).trim();
        oSec.setKeyCreator(oRep.getKeyCreator(sIndexName));
	  } else if (sIndexColumn.startsWith("one-to-many")) {
        sIndexName = sIndexColumn.substring(11).trim();
        oSec.setMultiKeyCreator(oRep.getMultiKeyCreator(sIndexName));	
	  } else if (sIndexColumn.startsWith("many-to-many")) {
        sIndexName = sIndexColumn.substring(12).trim();
        oSec.setMultiKeyCreator(oRep.getMultiKeyCreator(sIndexName));	
	  } else /* many-to-one assumed by default */ {
        sIndexName = sIndexColumn.trim();
        oSec.setKeyCreator(oRep.getKeyCreator(sIndexName));
	  }

	  oSdb = oRep.getEnvironment().openSecondaryDatabase(oTrn, oRep.getPath()+oPdb.getDatabaseName()+"."+sIndexName+".db",
                                                         oPdb.getDatabaseName()+"_"+sIndexName, oPdb, oSec);
	  
	  DBEntityBinding oDbeb = new DBEntityBinding(oCtg);
      DatabaseEntry oDbKey = new DatabaseEntry(sIndexValue.getBytes());
      DatabaseEntry oDbDat = new DatabaseEntry();
      oCur = oSdb.openSecondaryCursor(oTrn,null);

	  ArrayList<String> aKeys = new ArrayList<String>(1000);

      OperationStatus oOst = oCur.getSearchKey(oDbKey, oDbDat, LockMode.DEFAULT);
      while (oOst == OperationStatus.SUCCESS) {
        aKeys.add(oDbeb.objectToKey(oDbeb.entryToObject(oDbKey,oDbDat)));
        oOst = oCur.getNextDup(oDbKey, oDbDat, LockMode.DEFAULT);
      } // wend
      
      oCur.close();
      oCur=null;
      oSdb.close();
      oSdb=null;
      
      oTrd = oRep.isTransactional() ? oRep.getEnvironment().beginTransaction(oTrn,null) : null;
      for (String k : aKeys) {
        delete(k,oTrd);
      }
      oTrd.commit();
      oTrd=null;
      
	} catch (DeadlockException dlxc) {
      try { if (oTrd!=null) oTrd.abort(); } catch (DatabaseException e) { }
	  abort();
  	  throw new StorageException(dlxc.getMessage(), dlxc);
	} catch (Exception xcpt) {
	  try { if (oTrd!=null) oTrd.abort(); } catch (DatabaseException e) { }
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	} finally {
  	  try { if (oTrd!=null) oTrd.discard(); } catch (Exception ignore) { }
  	  try { if (oCur!=null) oCur.close(); } catch (Exception ignore) { }
  	  try { if (oSdb!=null) oSdb.close(); } catch (Exception ignore) { }
  	}
  } // delete

  // --------------------------------------------------------------------------
  
  public void delete(final String sKeyValue, Transaction oTrans) throws StorageException {
	try {
      oPdb.delete(oTrans, new DatabaseEntry(sKeyValue.getBytes()));
  	} catch (Exception xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}
  } // delete

  // --------------------------------------------------------------------------
  
  public void delete(final String sKeyValue) throws StorageException {
    delete(sKeyValue, oTrn);
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
      oPdb.truncate(oTrn,false);
	} catch (DeadlockException dlxc) {
	  abort();
	  throw new StorageException(dlxc.getMessage(), dlxc);
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
