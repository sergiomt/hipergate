/*
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate;

import java.rmi.RemoteException;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.knowgate.cache.DistributedCachePeer;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.jdc.JDCConnection;

/**
 * Wrapper around DistributedCachePeer for caching distances from k_distances_cache table
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class Distances {

  private static DistributedCachePeer oCache = null;

  // --------------------------------------------------------------------------

  private Distances() {};
  
  // --------------------------------------------------------------------------

  /**
   * Set distance between two locations at volatile memory cache
   * @param sLocationFrom String up to 254 characters
   * @param sLocationTo String up to 254 characters
   * @param fKm float Distance in kilometters
   * @param sLocale String locale for locations
   */
  public static void setDistance(String sLocationFrom, String sLocationTo, float fKm, String sLocale)
    throws InstantiationException,NullPointerException,RemoteException {
    if (null==sLocationFrom) throw new NullPointerException("Distances.setDistance() from location cannot be null");
    if (null==sLocationTo) throw new NullPointerException("Distances.setDistance() to location cannot be null");
    if (null==sLocale) throw new NullPointerException("Distances.setDistance() locale cannot be null");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Distances.setDistance("+sLocationFrom+","+sLocationTo+","+String.valueOf(fKm)+","+String.valueOf(sLocale)+")");
      DebugFile.incIdent();
    }
    
    if (null==oCache) oCache = new DistributedCachePeer();

	String sFromTo = sLocationFrom + "|" + sLocationTo;
	synchronized (oCache) {
	  if (oCache.keySet().contains(sFromTo)) {
	    oCache.expire(sFromTo);
	  } // fi
      oCache.put(sFromTo, new Float(fKm));
	} // synchronized

    if (DebugFile.trace) {
      DebugFile.writeln("End Distances.setDistance()");
      DebugFile.decIdent();
    }
  } // setDistance

  // --------------------------------------------------------------------------

  /**
   * <p>Set distance between two locations at volatile memory cache and at k_distances_cache database table</p>
   * Transaction management is responsability of the calling method,
   * no commit nor rollback is performed after writting to the database if autocommit mode is set to off
   * @param oConn Connection Opened JDBC database connection
   * @param sLocationFrom String up to 254 characters
   * @param sLocationTo String up to 254 characters
   * @param fKm float Distance in kilometters
   * @param sLocale String locale for locations
   */

  public static void setDistance(Connection oConn, String sLocationFrom, String sLocationTo, float fKm, String sLocale)
    throws InstantiationException,NullPointerException,RemoteException,SQLException {
    PreparedStatement oStmt = null;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Distances.setDistance([Connection], "+sLocationFrom+","+sLocationTo+","+String.valueOf(fKm)+","+String.valueOf(sLocale)+")");
      DebugFile.incIdent();
    }

    setDistance(sLocationFrom, sLocationTo, fKm, sLocale);
	
	try {
	  sSQL = "UPDATE "+DB.k_distances_cache+" SET "+DB.nu_km+"=?,"+DB.id_locale+"=? WHERE "+DB.lo_from+"=? AND "+DB.lo_to+"=?";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
	  oStmt = oConn.prepareStatement(sSQL);
	  oStmt.setFloat(1,fKm);
	  oStmt.setString(2,sLocale);
	  oStmt.setString(3,sLocationFrom);
	  oStmt.setString(4,sLocationTo);
	  int nAffected = oStmt.executeUpdate();
	  oStmt.close();
	  oStmt=null;
	  if (0==nAffected) {
        sSQL = "INSERT INTO "+DB.k_distances_cache+" ("+DB.lo_from+","+DB.lo_to+","+DB.nu_km+","+DB.id_locale+") VALUES (?,?,?,?)";
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
	    oStmt = oConn.prepareStatement(sSQL);
	    oStmt.setString(1,sLocationFrom);
	    oStmt.setString(2,sLocationTo);
	    oStmt.setFloat(3,fKm);
	    oStmt.setString(4,sLocale);
	    oStmt.executeUpdate();
	    oStmt.close();
	    oStmt=null;
	  } // fi
	} finally {
	  if (oStmt!=null) oStmt.close();
	}
    if (DebugFile.trace) {
      DebugFile.writeln("End Distances.setDistance()");
      DebugFile.decIdent();
    }
  } // setDistance

  // --------------------------------------------------------------------------

  public static void setDistance(JDCConnection oConn, String sLocationFrom, String sLocationTo, float fKm, String sLocale)
    throws InstantiationException,NullPointerException,RemoteException,SQLException {
    setDistance((Connection) oConn, sLocationFrom, sLocationTo, fKm, sLocale);
  }

  // --------------------------------------------------------------------------

  /**
   * Get distance between two locations from volatile memory cache
   * @return Float distance in kilometters or <b>null</b> if no cached distance for given locations is found
   */
  public static Float getDistance(String sLocationFrom, String sLocationTo, String sLocale)
  	throws InstantiationException,RemoteException,ClassCastException {
    if (null==oCache) oCache = new DistributedCachePeer();
	return oCache.getFloat(sLocationFrom + "|" + sLocationTo);
  }

  // --------------------------------------------------------------------------

  /**
   * Get distance between two locations from volatile memory cache or the database
   * @return Float distance in kilometters or <b>null</b> if no distance for given locations is found
   * neither at volatile memory cache nor at the database
   */

  public static Float getDistance(Connection oConn, String sLocationFrom, String sLocationTo, String sLocale)
  	throws InstantiationException,RemoteException,ClassCastException,SQLException {

    Float oFlt = getDistance(sLocationFrom, sLocationTo, sLocale);
    
    if (null==oFlt) {
      PreparedStatement oStmt = null;
      ResultSet oRSet = null;
      try {
      	oStmt = oConn.prepareStatement("SELECT "+DB.nu_km+" FROM "+DB.k_distances_cache+" WHERE "+DB.lo_from+"=? AND "+DB.lo_to+"=?",
      								   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sLocationFrom);
        oStmt.setString(2, sLocationTo);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          float fKm = oRSet.getFloat(1);
          oFlt = new Float(fKm);
          setDistance(sLocationFrom, sLocationTo, fKm, sLocale);
        }
        oRSet.close();
        oRSet=null;
        oStmt.close();
        oStmt=null;
      } finally {
        if (null!=oRSet) oRSet.close();
        if (null!=oStmt) oStmt.close();
      }
    }
    return oFlt;
  } // getDistance

  // --------------------------------------------------------------------------

  public static Float getDistance(JDCConnection oConn, String sLocationFrom, String sLocationTo, String sLocale)
  	throws InstantiationException,RemoteException,ClassCastException,SQLException {
    return getDistance((Connection) oConn, sLocationFrom, sLocationTo, sLocale);
  }
  
  // --------------------------------------------------------------------------

  public void expireAll() throws RemoteException {
    if (null!=oCache) oCache.expireAll();  
  }

  // --------------------------------------------------------------------------

} // Distances
