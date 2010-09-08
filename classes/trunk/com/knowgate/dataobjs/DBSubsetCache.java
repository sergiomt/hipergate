/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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

package com.knowgate.dataobjs;

import java.util.TreeMap;
import java.util.SortedMap;
import java.util.Iterator;
import java.util.Collections;

final class DBSubsetCacheReaper extends Thread {

    private DBSubsetCache oDBCache;

    DBSubsetCacheReaper(DBSubsetCache objDBCache) {
        oDBCache = objDBCache;
    }

    private void reapEntries() {
      // Position of last recently used entry to discard
      int iLRU = oDBCache.iTopIndex-oDBCache.iUsed;
      // Count of entries to discard (20% of cache capacity)
      int iDiscardCount = (oDBCache.capacity()*2)/10;
      int iComma;    // Delimiter position "Table,Key"
      String sEntry; // Full entry descriptor "Table,Key"
      String sTable; // Entry related table
      String sKey;   // Entry key

      // Discard bottom 20% entries
      for (int i=iLRU; i<iLRU+iDiscardCount; i++) {
        sEntry = oDBCache.getKey(iLRU);
        if (null!=sEntry) {
          iComma = sEntry.indexOf(',');
          sTable = sEntry.substring(0, iComma);
          sKey = sEntry.substring(iComma+1);
          oDBCache.expire(sKey);
        } // fi(LRUList[])
      } // next (i)

      oDBCache.iUsed-=iDiscardCount; // Decrement used slots count
    } // reapEntries()

    public void run() {
      reapEntries();
    }
} // DBSubsetCache

// ============================================================

  /**
   *
   * <p>Local Cache for DBSubset Objects</p>
   * @version 3.0
   */

public final class DBSubsetCache {

      /**
       * <p>Default constructor</p>
       * Cache capacity is set to 100
       */
      public DBSubsetCache() {
      iUsed = 0;
      iTopIndex = 0;
      iCacheCapacity = 100;
      LRUList = new String[iCacheCapacity];
      for (int s=0; s<iCacheCapacity; s++) LRUList[s] = null;
      oCache = Collections.synchronizedSortedMap(new TreeMap<String,DBCacheEntry>());
    }

    /**
     *
     * @param iCapacity Maximum number of entries that cache can hold
     */

  public DBSubsetCache(int iCapacity) {
    iUsed = 0;
    iTopIndex = 0;
    iCacheCapacity = iCapacity;
    LRUList = new String[iCacheCapacity];
    for (int s=0; s<iCacheCapacity; s++) LRUList[s] = null;
    oCache = Collections.synchronizedSortedMap(new TreeMap<String,DBCacheEntry>());
  }

  // ----------------------------------------------------------

  /**
   * Get Maximum number of entries that cache can hold
   */

  public int capacity() {
    return iCacheCapacity;
  }

  // ----------------------------------------------------------

  /**
   * Add new entry to cache
   * @param sTableName Associated table (optional)
   * @param sKey Unique key for cache entry
   * @param oDBSS Stored DBSubset
   */
  public void put(String sTableName, String sKey, DBSubset oDBSS) {
    int iIndex = iTopIndex%iCacheCapacity; iTopIndex++; iUsed++;
    DBCacheEntry oEntry = new DBCacheEntry(oDBSS, sTableName, iIndex);
    DBSubsetCacheReaper oReaper;

    if (null==sTableName) sTableName="none";

    oCache.put(sKey, oEntry);
    LRUList[iIndex] = sTableName + "," + sKey;

    if (iUsed>=iCacheCapacity-1) {
      oReaper = new DBSubsetCacheReaper(this);
      oReaper.run();
    } // fi (iUsed>=iCacheCapacity-1)
  } // put()

  // ----------------------------------------------------------

  /**
   * Remove a cache entry
   * @param sKey Unique key for cache entry
   * @return <b>true</b> if cache already contained an entry with given key, <b>false</b> if no entry was removed from cache.
   */

  public boolean expire(String sKey) {
    Object objEntry = oCache.get(sKey);

    if (null!=objEntry) {
      setKey(null, ((DBCacheEntry) objEntry).iIndex);
      oCache.remove(sKey);
    }
    return null!=objEntry ? true : false;
  } // remove()

  // ----------------------------------------------------------

  /**
   * Replace a cache entry
   * @param sTableName Associated table (optional)
   * @param sKey Unique key for cache entry
   * @param oDBSS New DBSubset to be stored
   */

  public void replace(String sTableName, String sKey, DBSubset oDBSS) {

    expire(sKey);
    put(sTableName, sKey, oDBSS);
  } // replace()

  // ----------------------------------------------------------

  /**
   * Clear cache
   */

  public void clear() {
    oCache.clear();
    for (int s=0; s<iCacheCapacity; s++) LRUList[s] = null;
    iTopIndex=0;
    iUsed=0;
  } // clear()

  // ----------------------------------------------------------

  /**
   * Remove all entries from cache that are registers from a given table
   * @param sTable Table Name
   */

  public void clear(String sTable) {
    Iterator oIter = oCache.keySet().iterator();
    String sKey;
    DBCacheEntry oEntry;

    if (sTable==null) sTable = "none";

    while (oIter.hasNext()) {
      sKey = (String) oIter.next();
      oEntry = (DBCacheEntry) oCache.get(sKey);
      if (sTable.equals(oEntry.sTable))
        expire(sKey);
    } // wend
  } // clear()

  // ----------------------------------------------------------

  /**
   * Get DBSubset from cache
   * @param sKey Unique key for cache entry
   * @return DBSubset reference or <b>null</if no DBSubset with such key was found
   */

  public DBSubset get(String sKey) {
    Object oObj = oCache.get(sKey);
    DBCacheEntry oEntry;

    if (oObj!=null) {
      oEntry = (DBCacheEntry) oObj;
      oEntry.iTimesUsed++;
      oEntry.lastUsed = System.currentTimeMillis();
      return oEntry.oDBSubset;
    }
    else
      return null;
  } // get()

  // ----------------------------------------------------------

  /**
   * Get DBCacheEntry from cache
   * @param sKey Unique key for cache entry
   * @return DBCacheEntry reference or <b>null</if no DBCacheEntry with such key was found
   */

  public DBCacheEntry getEntry(String sKey) {
    Object oObj = oCache.get(sKey);
    DBCacheEntry oEntry;

    if (oObj!=null) {
      oEntry = (DBCacheEntry) oObj;
      oEntry.iTimesUsed++;
      oEntry.lastUsed = System.currentTimeMillis();
      return oEntry;
    }
    else
      return null;
  } // getEntry()

  // ----------------------------------------------------------

  public String getKey(int iEntryIndex) {
    return LRUList[iEntryIndex % iCacheCapacity];
  }

  // ----------------------------------------------------------

  public void setKey(String sKey, int iEntryIndex) {
    LRUList[iEntryIndex % iCacheCapacity] = sKey;
  }

  // ----------------------------------------------------------

  public class DBCacheEntry {
    public long lastModified;
    public long lastUsed;
    public int iTimesUsed;
    public int iIndex;
    public String sTable;
    public DBSubset oDBSubset;

    DBCacheEntry (DBSubset oDBSS, String sTbl, int iIdx) {
      sTable = sTbl;
      iIndex = iIdx;
      iTimesUsed = 0;
      lastUsed = lastModified = System.currentTimeMillis();
      oDBSubset = oDBSS;
    }
  } // DBCacheEntry

  private int iCacheCapacity; // Número máximo de entradas en el cache
  private String LRUList[];   // Slots usados por el algoritmo de limpieza Least Recently Used
  private SortedMap oCache;     // B-Tree con las entradas del cache

  public int iTopIndex;       // Máximo índice en el cache (siempre de accede módulo la capacidad)
  public int iUsed;           // Contador de entradas actualmente en uso
} // DBSubsetCache
