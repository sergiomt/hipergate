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
package com.knowgate.syndication.fetcher;

import java.io.File;

import java.util.Map;
import java.util.ArrayList;
import java.util.Properties;
import java.util.HashMap;

import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.Engine;
import com.knowgate.syndication.FeedEntry;
import com.knowgate.syndication.fetcher.BDBFeedInfoCache;

import com.sun.syndication.fetcher.impl.FeedFetcherCache;

/**
 * A batch of parallel web searches
 */
public class EntriesBatch {

  private FeedFetcherCache oCache;
  private String sDir;     // Path of directory for caching RSS feeds
  private Properties oPrp; // Environment properties
  private DataSource oDts; // DataSource where indexes will be stored
  
  // All entries retrieved from the fetcher threads are written here
  // if two fetchers find the same result only the first one is taken
  // into account and the second one is ignored.
  private HashMap<String,FeedEntry> mEntries;
  
  // Array of fetcher threads
  private ArrayList<AbstractEntriesFetcher> aFetchers;

  public EntriesBatch(DataSource oDataSrc, Properties oEnvProps) {
  	oPrp = oEnvProps;
  	oDts = oDataSrc;
  	if (oPrp.getProperty("storage")==null) {
  	  sDir = null;
  	}
  	else {
  	  sDir = Gadgets.chomp(oPrp.getProperty("storage"),File.separator)+"syndication";
  	  if (!new File(sDir).exists()) {
  		try { new FileSystem().mkdirs("file://"+sDir); }
  		catch (Exception xcpt) {
  		  if (DebugFile.trace) DebugFile.writeln("Could not create directory "+sDir+" "+xcpt.getClass().getName()+" "+xcpt.getMessage());
  		}
  	  }
  	}
  	oCache = null;
    mEntries = new HashMap<String,FeedEntry>(500);
    aFetchers = new ArrayList<AbstractEntriesFetcher>(10);
  }

  public void close() {
	if (oCache instanceof BDBFeedInfoCache)
	  ((BDBFeedInfoCache) oCache).close();
	oCache=null;
	mEntries.clear();
	mEntries=null;
	aFetchers.clear();
	aFetchers=null;
  }

  public Properties properties() {
    return oPrp;
  }

  /**
   * Register a fetcher thread into this batch
   * @param oFetcher AbstractEntriesFetcher
   */
  public void registerFetcher(AbstractEntriesFetcher oFetcher) {
    aFetchers.add(oFetcher);
  }
  
  /**
   * Register a set of fetcher threads into this batch
   * @param vFetcher Variable number of AbstractEntriesFetcher
   */
  public void registerFetchers(AbstractEntriesFetcher... vFetchers) {
  	for (AbstractEntriesFetcher oFetcher : vFetchers)
  	  registerFetcher(oFetcher);
  }

  /**
   * Get array of fetcher threads
   * @return ArrayList<AbstractEntriesFetcher>
   */
  public ArrayList<AbstractEntriesFetcher> fetchers() {
  	return aFetchers;
  }

  /**
   * Check whther or not the list of URIs found by
   * fetcher threads contains a given URI
   * @return <b>true</b> if any fetcher thread as already found the given URI
   */ 
  public boolean contains(String sUri) {
  	boolean bContains;
  	if (sUri==null) {
      bContains = false;
  	} else {
  	  if (sUri.startsWith("http://") || sUri.startsWith("https://")) {
        bContains = mEntries.containsKey(sUri);
        if (!bContains) {
      	  if (sUri.endsWith("/"))
      	    bContains = mEntries.containsKey(sUri.substring(0, sUri.length()-2));
          else
      	    bContains = mEntries.containsKey(sUri+"/");
        }
      } else {
      bContains = mEntries.containsKey(sUri);
      }
  	} // fi
  	return bContains;
  } // contains


  public FeedFetcherCache getFeedsCache() {
  	if (null==oCache && sDir!=null) {
  	  Engine oEng = oDts.getEngine();
  	  if (oEng.equals(Engine.BERKELYDB))
  	    oCache = new BDBFeedInfoCache(sDir);
  	  else if (oEng.equals(Engine.JDBCRDBMS))
  		oCache = new DBFeedInfoCache(oDts);
  	}
  	return oCache;
  }

  /**
   * Get DataSource where indexes are written
   */
  public DataSource getDataSource() {
  	return oDts;
  }

  /**
   * Add a entry to the common list of them shared by all fetcher threads
   * @param sUri String entry unique identifier
   * @param oEntry FeedEntry
   */
  public void addEntry(String sUri, FeedEntry oEntry) {
    mEntries.put(sUri, oEntry);
  }

  /**
   * Get entry by its URI
   * @param URI String
   * @return FeedEntry
   */
  public FeedEntry getEntry(String sUri) {
  	FeedEntry oFentry = mEntries.get(sUri);
  	if (oFentry==null) {
  	  if (sUri.endsWith("/"))
  	  	oFentry = mEntries.get(sUri.substring(0,sUri.length()-2));
  	  else
  	  	oFentry = mEntries.get(sUri+"/");
  	}
  	return oFentry;
  } // getEntry
  
  /**
   * Get entries already retrieved by fetcher threads
   * @return ConcurrentHashMap<String,FeedEntry>
   */
  public Map<String,FeedEntry> entries() {
  	return mEntries;
  }

  /**
   * Execute all registered fetcher threads
   * Wait until all of them have finished before returning
   */  
  public void mapReduce() {
  	if (DebugFile.trace) {
      DebugFile.writeln("Begin EntriesBatch.mapReduce()");
  	  DebugFile.incIdent();
  	}

	mEntries.clear();

	// *********
	// Map stage
	
    for (AbstractEntriesFetcher f : aFetchers) {
      f.start();
    } // next

  	if (DebugFile.trace) {
      DebugFile.writeln(String.valueOf(aFetchers.size())+" fetcher threads started");
  	}

    for (int t=0; t<aFetchers.size(); t++) {
	  try {
        aFetchers.get(t).join();
      } catch (InterruptedException e) {
        if (DebugFile.trace) DebugFile.writeln("join("+String.valueOf(t)+") interrupted");
      }
    } // next  	

	if (oCache instanceof BDBFeedInfoCache)
	  ((BDBFeedInfoCache) oCache).close();
	oCache=null;

  	if (DebugFile.trace) {
      int nMapping = 0;
      for (AbstractEntriesFetcher f : aFetchers) {
        nMapping += f.entries().size();
      } // next
      DebugFile.writeln(String.valueOf(nMapping)+" URLs found");
  	}

	// ************
	// Reduce stage

    for (AbstractEntriesFetcher f : aFetchers) {
      for (FeedEntry e : f.entries()) {
    	String sUrl = e.getURL();
    	if (sUrl.length()>0) {
          if (!mEntries.containsKey(sUrl))
    	    mEntries.put(e.getURL(), e);    		
    	} else {
    	  if (DebugFile.trace) {
    	    DebugFile.writeln("EntriesBatch.mapReduce() NullPointerException URL of "+f.getSourceType()+" entry "+e.getString(DB.tl_entry,"")+" is null");
    	  }
    	}
      }
    } // next
		
  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
      DebugFile.writeln("End EntriesBatch.mapReduce() : "+String.valueOf(mEntries.size()));
  	}
  } // mapReduce
}
