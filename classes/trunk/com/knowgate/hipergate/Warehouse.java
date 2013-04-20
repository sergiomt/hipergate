/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

import java.util.HashMap;

import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.misc.Gadgets;

import com.knowgate.hipergate.Address;

public class Warehouse extends Address {

  private DBPersist oWarehouse;

  public Warehouse() {
  	oWarehouse = new DBPersist(DB.k_warehouses, "Warehouse");
  }

  public Warehouse(JDCConnection oConn, String sGuid) throws SQLException {
  	oWarehouse = new DBPersist(DB.k_warehouses, "Warehouse");
	load(oConn, sGuid);
  }

  public HashMap getItemMap() {
    HashMap oMap = (HashMap) AllVals.clone();
    oMap.putAll(oWarehouse.getItemMap());
    return oMap;
  }

  public boolean load (JDCConnection oConn, Object[] aPk) throws SQLException {
    boolean bRetVal = false;
    if (oWarehouse.load(oConn, aPk)) {
      bRetVal = super.load(oConn, aPk);
      if (bRetVal) {
		put(DB.gu_warehouse, oWarehouse.get(DB.gu_warehouse));
		put(DB.nm_warehouse, oWarehouse.get(DB.nm_warehouse));
      }
    }
	return bRetVal;
  } // load

  public boolean load (JDCConnection oConn, String sPk) throws SQLException {
    return load(oConn, new Object[]{sPk});
  }

  public boolean store (JDCConnection oConn) throws SQLException {
  	String sNewGuid = Gadgets.generateUUID();

  	if (!oWarehouse.getItemMap().containsKey(DB.gu_warehouse))
  	  put(DB.gu_warehouse, sNewGuid);

  	if (!AllVals.containsKey(DB.gu_address))
  	  put(DB.gu_address, sNewGuid);

	boolean bRetVal = super.store(oConn);

    if (bRetVal) {
      oWarehouse.clear();
      if (!isNull(DB.gu_warehouse)) oWarehouse.put(DB.gu_warehouse, get(DB.gu_warehouse));
      if (!isNull(DB.nm_warehouse)) oWarehouse.put(DB.nm_warehouse, get(DB.nm_warehouse));
      if (!isNull(DB.bo_active)) oWarehouse.put(DB.bo_active, get(DB.bo_active));
      bRetVal = oWarehouse.store(oConn);
    }

    return bRetVal;
  } // store

  public boolean delete(JDCConnection oConn) throws SQLException {
	if (super.delete(oConn)) {
	  oWarehouse.replace(DB.gu_warehouse, get(DB.gu_warehouse));
	  return oWarehouse.delete(oConn);
	} else {
	  return false;
	}   
  } // delete
  
  public static final short ClassId = (short) 49;
}