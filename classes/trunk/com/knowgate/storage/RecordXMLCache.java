package com.knowgate.storage;

import com.knowgate.berkeleydb.DBEnvironment;

import com.knowgate.cache.DistributedCachePeer;

import com.knowgate.clocial.MetaData;

import java.util.TreeSet;
import java.util.HashMap;
import java.util.Locale;

import java.rmi.RemoteException;

public class RecordXMLCache {

  private static TreeSet<String> oLanguages = new TreeSet<String>();
  private static DataSource oDts = null;
  private static DistributedCachePeer oChe = null;
  
  public String get(String sTable, String sKey, Locale oLoc)
  	throws StorageException {

  	String sXml = null;
  	
  	try {
  	  sXml = oChe.getString(sTable+"."+sKey);
  	
  	  if (null==sXml) {
  	    if (oDts==null) {
  	  	  oDts = new DBEnvironment(MetaData.getDefaultSchema().getSchemaName(), true);
  	    }
  	    Table oCon = oDts.openTable(sTable);
  	    Record oRec = oCon.load(sKey);
  	    oCon.close();
  	    if (oRec!=null) {
  	      HashMap<String,String> oAttrs = new HashMap(7);
  	      String sLanguage = oLoc.getLanguage();
  	      oAttrs.put("language",sLanguage);
  	  	  oChe.put(sTable+"."+sKey+"$"+sLanguage, oRec.toXML("",oAttrs,oLoc));
  	      if (!oLanguages.contains(sLanguage)) oLanguages.add(sLanguage);
  	    }
  	  } // fi
  	} catch (RemoteException xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}
  	return sXml;
  } // get

  public static void expire(String sTable, String sKey)
  	throws StorageException {
  	try {
  	  for (String sLang : oLanguages) {
  	    oChe.expire(sTable+"."+sKey+"$"+sLang);
  	  } // next
  	} catch (RemoteException xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}
  }

  public static void expireAll()
  	throws StorageException {
  	try {
  	  oChe.expireAll();
  	} catch (RemoteException xcpt) {
  	  throw new StorageException(xcpt.getMessage(), xcpt);
  	}
  }

  protected void finalize() {
  	if (null!=oDts) { try { oDts.close(); } catch (Exception ignore) {} oDts=null; }
  	if (null!=oChe) { try { oChe.expireAll(); } catch (Exception ignore) {} oChe=null; }
  }
}
