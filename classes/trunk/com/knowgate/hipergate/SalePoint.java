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

public class SalePoint extends Address {

  private DBPersist oSalePoint;

  public SalePoint() {
  	oSalePoint = new DBPersist(DB.k_sale_points, "SalePoint");
  }

  public SalePoint(JDCConnection oConn, String sGuid) throws SQLException {
  	oSalePoint = new DBPersist(DB.k_sale_points, "SalePoint");
	load(oConn, sGuid);
  }

  public HashMap getItemMap() {
    HashMap oMap = (HashMap) AllVals.clone();
    oMap.putAll(oSalePoint.getItemMap());
    return oMap;
  }

  public boolean load (JDCConnection oConn, Object[] aPk) throws SQLException {
    boolean bRetVal = false;
    if (oSalePoint.load(oConn, aPk)) {
      bRetVal = super.load(oConn, new Object[]{oSalePoint.getString(DB.gu_address)});
      if (bRetVal) {
		put(DB.gu_sale_point, oSalePoint.get(DB.gu_sale_point));
		put(DB.nm_sale_point, oSalePoint.get(DB.nm_sale_point));
      }
    }
	return bRetVal;
  } // load

  public boolean load (JDCConnection oConn, String sPk) throws SQLException {
    return load(oConn, new Object[]{sPk});
  }

  public void replace (String sKey, String sValue) {
	super.replace(sKey, sValue);
	oSalePoint.replace(sKey, sValue);
  }

  public void replace (String sKey, short iValue) {
	super.replace(sKey, iValue);
	oSalePoint.replace(sKey, iValue);
  }
  
  public void put (String sKey, String sValue) {
	super.put(sKey, sValue);
	oSalePoint.put(sKey, sValue);
  }

  public void put (String sKey, short iValue) {
	super.put(sKey, iValue);
	oSalePoint.put(sKey, iValue);
  }

  public boolean store (JDCConnection oConn) throws SQLException {
  	String sNewGuid = Gadgets.generateUUID();
  	if (!oSalePoint.getItemMap().containsKey(DB.gu_sale_point))
  	  put(DB.gu_sale_point, sNewGuid);

  	if (!AllVals.containsKey(DB.gu_address))
  	  put(DB.gu_address, sNewGuid);

	boolean bRetVal = super.store(oConn);

    if (bRetVal) {
      oSalePoint.clear();
      if (!isNull(DB.gu_sale_point)) oSalePoint.put(DB.gu_sale_point, get(DB.gu_sale_point));
      if (!isNull(DB.nm_sale_point)) oSalePoint.put(DB.nm_sale_point, get(DB.nm_sale_point));
      if (!isNull(DB.bo_active)) oSalePoint.put(DB.bo_active, get(DB.bo_active));
      if (!isNull(DB.gu_workarea)) oSalePoint.put(DB.gu_workarea, get(DB.gu_workarea));
      if (!isNull(DB.gu_address)) oSalePoint.put(DB.gu_address, get(DB.gu_address));
      bRetVal = oSalePoint.store(oConn);
    }

    return bRetVal;
  } // store
  
  public boolean delete(JDCConnection oConn) throws SQLException {
	oSalePoint.replace(DB.gu_sale_point, get(DB.gu_sale_point));
	if (oSalePoint.delete(oConn)) {
	  return super.delete(oConn);
	} else {
	  return false;
	}   
  } // delete
  
  public static final short ClassId = (short) 48;
}
