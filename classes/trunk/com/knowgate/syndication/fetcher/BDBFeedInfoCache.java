package com.knowgate.syndication.fetcher;

import java.io.File;
import java.io.IOException;
import java.io.FileNotFoundException;

import java.net.URL;

import com.sun.syndication.fetcher.impl.FeedFetcherCache;
import com.sun.syndication.fetcher.impl.SyndFeedInfo;

import com.sleepycat.db.LockMode;
import com.sleepycat.db.Database;
import com.sleepycat.db.DatabaseType;
import com.sleepycat.db.DatabaseEntry;
import com.sleepycat.db.DatabaseConfig;
import com.sleepycat.db.DatabaseException;
import com.sleepycat.db.EnvironmentConfig;
import com.sleepycat.db.Environment;
import com.sleepycat.db.OperationStatus;

import com.sleepycat.bind.serial.StoredClassCatalog;

import com.knowgate.debug.DebugFile;

public class BDBFeedInfoCache implements FeedFetcherCache {
	
    private Environment oEnv;
    private String sPath;

	public BDBFeedInfoCache(String sDBPath) {
	  oEnv = null;
	  sPath = sDBPath + (sDBPath.endsWith(File.separator) ? "" : File.separator);
	  open(sDBPath);	  
	}

	private void open(String sDBPath) {
	  EnvironmentConfig oCfg = new EnvironmentConfig();
      oCfg.setAllowCreate(true);      
      oCfg.setInitializeCache(true);
      oCfg.setInitializeCDB(true);
	  
	  try {
	    oEnv = new Environment(new File(sDBPath), oCfg);	
	  } catch (DatabaseException dbe) {
	  	oEnv = null;
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache("+sDBPath+") DatabaseException "+dbe.getMessage());
	  } catch (FileNotFoundException fnf) {
	  	oEnv = null;
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache("+sDBPath+") FileNotFoundException "+fnf.getMessage());
	  }
	}

	public void close() {
	  if (oEnv!=null) {
	  	try {
	  	  oEnv.close();
	  	  oEnv=null;
	  	} catch (DatabaseException dbe) {
	  	  if (DebugFile.trace)
	  	  	DebugFile.writeln("BDBFeedInfoCache.close() DatabaseException "+dbe.getMessage());
	  	}
	  }
	}

	@SuppressWarnings("unused")
	public SyndFeedInfo getFeedInfo(URL oFeedURL) {
	  SyndFeedInfo oRetVal = null;
	  Database oJcc = null;
	  Database oPdb = null;
	  StoredClassCatalog oCtg = null;
	  
      DatabaseConfig oDfg = new DatabaseConfig();
      oDfg.setTransactional(false);
      oDfg.setSortedDuplicates(false);
      oDfg.setAllowCreate(false);
	  oDfg.setReadOnly(true);
	  oDfg.setType(DatabaseType.HASH);	  

	  try {
	    if (new File(sPath+"FeedInfoCache.db").exists()) {
	      oPdb = oEnv.openDatabase(null, sPath+"FeedInfoCache.db", "FeedInfoCache", oDfg);
	      DatabaseEntry oDbKey = new DatabaseEntry(oFeedURL.toString().getBytes());
          DatabaseEntry oDbDat = new DatabaseEntry();
  	      if (OperationStatus.SUCCESS==oPdb.get(null, oDbKey, oDbDat, LockMode.DEFAULT)) {
            DatabaseConfig oCtf = new DatabaseConfig();
            oCtf.setTransactional(false);
            oCtf.setAllowCreate(true);
	        oCtf.setType(DatabaseType.BTREE);
	  	    oJcc = oEnv.openDatabase(null, sPath+"FeedInfoCacheClassCatalog.db", "FeedInfoCacheClassCatalog", oCtf);
      	    oCtg = new StoredClassCatalog(oJcc);
	        BDBSyndFeedInfoBinding oDbeb = new BDBSyndFeedInfoBinding(oCtg);
  	        oRetVal = oDbeb.entryToObject(oDbKey,oDbDat);
	        oCtg.close();
	        oCtg=null;
	        oJcc.close(true);
	        oJcc=null;
  	      } // fi
	      oPdb.close(true);
	      oPdb=null;
	    } // fi
	  } catch (IllegalArgumentException iae) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.getFeedInfo("+oFeedURL.toString()+") IllegalArgumentException "+iae.getMessage());
	    try { if (oCtg!=null) oCtg.close(); oCtg=null; } catch (Exception ignore) {}
	    try { if (oJcc!=null) oJcc.close(); oJcc=null; } catch (Exception ignore) {}
	    try { if (oPdb!=null) oPdb.close(); oPdb=null; } catch (Exception ignore) {}
	  }catch (DatabaseException dbe) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.getFeedInfo("+oFeedURL.toString()+") DatabaseException "+dbe.getMessage());
	    try { if (oCtg!=null) oCtg.close(); oCtg=null; } catch (Exception ignore) {}
	    try { if (oJcc!=null) oJcc.close(); oJcc=null; } catch (Exception ignore) {}
	    try { if (oPdb!=null) oPdb.close(); oPdb=null; } catch (Exception ignore) {}
	  } catch (FileNotFoundException fnf) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.getFeedInfo("+oFeedURL.toString()+") FileNotFoundException "+fnf.getMessage());
	    try { if (oCtg!=null) oCtg.close(); oCtg=null; } catch (Exception ignore) {}
	    try { if (oJcc!=null) oJcc.close(); oJcc=null; } catch (Exception ignore) {}
	    try { if (oPdb!=null) oPdb.close(); oPdb=null; } catch (Exception ignore) {}
	  } catch (IOException ioe) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.getFeedInfo("+oFeedURL.toString()+") IOException "+ioe.getMessage());
	  }
	  return oRetVal;
	} // getFeedInfo()

	/**
	 * Method setFeedInfo
	 *
	 *
	 * @param parm1
	 * @param parm2
	 *
	 */
	public void setFeedInfo(URL oFeedURL, SyndFeedInfo oFeedInfo) {
      Database oPdb = null;
      Database oJcc = null;
      StoredClassCatalog oCtg = null;
      
      DatabaseConfig oDfg = new DatabaseConfig();
      oDfg.setTransactional(false);
      oDfg.setSortedDuplicates(false);
      oDfg.setAllowCreate(true);
	  oDfg.setReadOnly(false);
	  oDfg.setType(DatabaseType.HASH);	  

      DatabaseConfig oCtf = new DatabaseConfig();
      oCtf.setTransactional(false);
      oCtf.setAllowCreate(true);
	  oCtf.setType(DatabaseType.BTREE);

	  try {

	    oJcc = oEnv.openDatabase(null, sPath+"FeedInfoCacheClassCatalog.db", "FeedInfoCacheClassCatalog", oCtf);
        oCtg = new StoredClassCatalog(oJcc);
  	    BDBSyndFeedInfoBinding oDbeb = new BDBSyndFeedInfoBinding(oCtg);
	    DatabaseEntry oDbKey = new DatabaseEntry(oFeedURL.toString().getBytes());
        DatabaseEntry oDbDat = new DatabaseEntry(oDbeb.objectToData(oFeedInfo));	  	
	    oPdb = oEnv.openDatabase(null, sPath+"FeedInfoCache.db", "FeedInfoCache", oDfg);
  	    oPdb.put(null, oDbKey, oDbDat);
	    oPdb.close();
	    oPdb=null;
	    oCtg.close();
	    oCtg=null;
	    oJcc.close();
	    oJcc=null;
	  } catch (IllegalArgumentException iae) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.getFeedInfo("+oFeedURL.toString()+") IllegalArgumentException "+iae.getMessage());
	    try { if (oCtg!=null) oCtg.close(); oCtg=null; } catch (Exception ignore) {}
	    try { if (oJcc!=null) oJcc.close(); oJcc=null; } catch (Exception ignore) {}
	    try { if (oPdb!=null) oPdb.close(); oPdb=null; } catch (Exception ignore) {}
	  } catch (DatabaseException dbe) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.setFeedInfo("+oFeedURL.toString()+") DatabaseException "+dbe.getMessage());
	    try { if (oPdb!=null) oPdb.close(); } catch (Exception ignore) {}
	    try { if (oCtg!=null) oCtg.close(); } catch (Exception ignore) {}
	    try { if (oJcc!=null) oJcc.close(); } catch (Exception ignore) {}
	  } catch (FileNotFoundException fnf) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.setFeedInfo("+oFeedURL.toString()+") FileNotFoundException "+fnf.getMessage());
	    try { if (oCtg!=null) oCtg.close(); } catch (Exception ignore) {}
	    try { if (oJcc!=null) oJcc.close(); } catch (Exception ignore) {}
	    try { if (oPdb!=null) oPdb.close(); } catch (Exception ignore) {}
	  }
	} // setFeedInfo

	/**
	 * Method clear
	 *
	 *
	 */
	public void clear() {
		close();
		File oFle = new File(sPath+"FeedInfoCacheClassCatalog.db");
		if (oFle.exists()) oFle.delete();
		oFle = new File(sPath+"FeedInfoCache.db");
		if (oFle.exists()) oFle.delete();
		for (int d=1; ; d++) {
		  oFle = new File(sPath+"__db."+(d<10 ? "00" : d<100 ? "0" : "")+String.valueOf(d));
		  if (oFle.exists())
		    oFle.delete();
		  else
		  	break;
		} // next		
	} // clear

	/**
	 * Method remove
	 *
	 *
	 * @param parm1
	 *
	 * @return
	 *
	 */
	public SyndFeedInfo remove(URL oFeedURL) {
	  SyndFeedInfo oRemoved = null;
      Database oPdb = null;
      DatabaseConfig oDfg = new DatabaseConfig();
      oDfg.setTransactional(false);
      oDfg.setSortedDuplicates(false);
      oDfg.setAllowCreate(true);
	  oDfg.setReadOnly(false);
	  oDfg.setType(DatabaseType.HASH);	  

	  try {
        oRemoved = getFeedInfo(oFeedURL);
	    oPdb = oEnv.openDatabase(null, sPath+"FeedInfoCache.db", "FeedInfoCache", oDfg);
      	oPdb.delete(null, new DatabaseEntry(oFeedURL.toString().getBytes()));
	    oPdb.close();
	  } catch (DatabaseException dbe) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.remove("+oFeedURL.toString()+") DatabaseException "+dbe.getMessage());
	    try { if (oPdb!=null) oPdb.close(); } catch (Exception ignore) {}
      } catch (FileNotFoundException fnf) {
	  	if (DebugFile.trace)
	  	  DebugFile.writeln("BDBFeedInfoCache.remove("+oFeedURL.toString()+") FileNotFoundException "+fnf.getMessage());
	    try { if (oPdb!=null) oPdb.close(); } catch (Exception ignore) {}
	  }
	  return oRemoved;
	}
}
