/*
  Copyright (C) 2011  Know Gate S.L. All rights reserved.

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

package com.knowgate.http.oauth;

import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.PreparedStatement;

import java.util.Set;
import java.util.Collection;
import java.util.Enumeration;
import java.util.concurrent.ConcurrentHashMap;

import com.knowgate.storage.StorageException;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.jdc.JDCConnectionPool;

import com.knowgate.acl.ACL;
import com.knowgate.acl.ACLUser;

public class OAuthAccessCache {

  private JDCConnectionPool oConnPool;
  private AccessReaper oReaper;
  private ConcurrentHashMap<String,OAuthAccess> oAccessMap;
  private ConcurrentHashMap<String,String> oRefreshMap;

  public static final short USER_NOT_FOUND = -1;
  public static final short INVALID_PASSWORD = -2;
  public static final short ACCOUNT_DEACTIVATED = -3;
  public static final short SESSION_EXPIRED = -4;
  public static final short DOMAIN_NOT_FOUND = -5;
  public static final short WORKAREA_NOT_FOUND = -6;
  public static final short WORKAREA_NOT_SET = -7;
  public static final short ACCOUNT_CANCELLED = -8;
  public static final short PASSWORD_EXPIRED = -9;
  public static final short WORKAREA_ACCESS_DENIED = -12;
  public static final short INTERNAL_ERROR = -255;
  
  final class AccessReaper extends Thread {

   /**
    * Reference to reaped cache
    */
    private OAuthAccessCache cache;

    /**
     * Used to stop the access reaper thread
     */
    private boolean keepruning;

   /**
    * Reaper call interval (default = 1 min)
    */
    private long delay=60000l;

	AccessReaper(OAuthAccessCache forcache) {
        cache = forcache;
        keepruning = true;
        try {
          checkAccess();
          setDaemon(true);
          setPriority(MIN_PRIORITY);
        } catch (SecurityException ignore) { }
    }

    public void halt() {
      keepruning=false;
    }

    /**
     * Reap connections every n-minutes
     */
    public void run() {
        while (keepruning) {
           try {
             sleep(delay);
           } catch( InterruptedException e) { }
           if (keepruning) cache.reapExpiredTokens();
        } // wend
    } // run
  }
  
  public OAuthAccessCache(String sUrl, String sUsr, String sPwd)
  	throws StorageException {
  	oAccessMap = new ConcurrentHashMap<String,OAuthAccess>();
  	oRefreshMap = new ConcurrentHashMap<String,String>();
  	oConnPool = new JDCConnectionPool(sUrl, sUsr, sPwd);
    oReaper = new AccessReaper(this);
    oReaper.start();
  }

  private void reapExpiredTokens() {
  	Enumeration<String> oKeys = oAccessMap.keys();
  	while (oKeys.hasMoreElements()) {
  	  String sKey = oKeys.nextElement();
  	  OAuthAccess oAa = oAccessMap.get(sKey);
  	  if (oAa.isExpired()) remove(sKey);
  	} // wend
  }
  
  public void close() {
  	oReaper.halt();
  	oConnPool.close();
  	oAccessMap.clear();
  	oRefreshMap.clear();
  }
  
  public void put(OAuthAccess oAa)
  	throws NullPointerException,IllegalStateException {
  	if (oAa==null) throw new NullPointerException("Cannot put null OAuthAccess into cache");  	
  	String sValue = oAa.getValue();
  	if (sValue==null) throw new NullPointerException("Cannot put an OAuthAccess object with null value into access cache");
    if (oAccessMap.containsKey(sValue)) {
      throw new IllegalStateException("Access cache already contains the given key");
    } else {
      oAccessMap.put(sValue, oAa);
      if (oAa.getRefresh()!=null) oRefreshMap.put(oAa.getRefresh(),oAa.getValue());
    }
  } // put

  public OAuthAccess refresh(String sValue) {
	OAuthAccess oAa = null;
	if (oRefreshMap.containsKey(sValue)) {
	  oAa = oAccessMap.get(oRefreshMap.get(sValue));
      if (null==oAa)
        throw new IllegalStateException("Inconsistent cache state");
	  oAa.refresh();
	}
	return oAa;
  } // refresh

  public void remove(String sValue) {
	if (oAccessMap.containsKey(sValue)) {
	  OAuthAccess oAa = oAccessMap.get(sValue);
	  if (oAa.getRefresh()!=null) oRefreshMap.remove(oAa.getRefresh());
	  oAccessMap.remove(sValue);
	}
  } // remove

  public void remove(OAuthAccess oAa) {
	remove(oAa.getValue());
  } // remove

  public OAuthAccess get(String sValue) {
  	OAuthAccess oRetVal = null;
  	if (oAccessMap.containsKey(sValue)) {
  	  oRetVal = oAccessMap.get(sValue);
  	  if (oRetVal.isExpired()) oRetVal = null;
  	}
  	return oRetVal;
  } // get
  
  public short authenticate(String sUser, String sPassw, String sScope) {
  	JDCConnection oConn = null;
  	short iRetVal;
  	
  	try {
  	  oConn = oConnPool.getConnection("OAuthAcessCache");
  	  
  	  if (sScope.length()>0) {
  	    PreparedStatement oStmt = oConn.prepareStatement("SELECT tx_pwd FROM k_contacts WHERE gu_workarea=? AND (tx_nickname=? OR 	sn_passport=?)",
  	  												     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
  	    oStmt.setString(1, sScope);
  	    oStmt.setString(2, sUser);
  	    oStmt.setString(3, sUser);
  	    ResultSet oRSet = oStmt.executeQuery();
  	    if (oRSet.next()) {
  	      String sPwd = oRSet.getString(1);
  	      if (oRSet.wasNull()) sPwd = null;
  	      if (null==sPwd) {
  	      	iRetVal = ACL.ACCOUNT_DEACTIVATED;
  	      } else {
  	      	iRetVal = (sPwd.equals(sPassw) ? 0 : ACL.INVALID_PASSWORD);
  	      }
  	    } else {
  	      iRetVal = ACL.USER_NOT_FOUND;
  	    }
  	    oRSet.close();
  	    oStmt.close();
  	  } else {
  	    if (sUser.indexOf('@')>0) {
  	  	  sUser = ACLUser.getIdFromEmail(oConn, sUser);
  	  	  if (sUser==null) {
  	  	    iRetVal = ACL.USER_NOT_FOUND;
  	  	  } else {
  	  	    iRetVal = ACL.autenticate(oConn, sUser, sPassw, ACL.PWD_CLEAR_TEXT);
  	      }
  	    } else {
  	  	  iRetVal = ACL.autenticate(oConn, sUser, sPassw, ACL.PWD_CLEAR_TEXT);
  	    }
  	  }
  	    	  
  	  oConn.close("OAuthAcessCache");
  	  oConn=null;
  	} catch (SQLException sqle) {
  	  if (oConn!=null) { try { if (!oConn.isClosed()) { oConn.close("OAuthAcessCache"); } } catch(Exception ignore) {} }
  	  iRetVal = ACL.INTERNAL_ERROR;
  	}
  	
  	return iRetVal;
  }
  
  public Collection<OAuthAccess> values() {
  	return oAccessMap.values();
  }

  public Set<String> keySet() {
  	return oAccessMap.keySet();
  }

}
