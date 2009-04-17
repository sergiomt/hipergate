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

package com.knowgate.crm;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import java.util.Date;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.hipergate.Address;
import com.knowgate.misc.Gadgets;

public class Supplier extends DBPersist {

  private Address oAddr;

  public Supplier() {
    super(DB.k_suppliers, "Supplier");
    oAddr = new Address();
  }

  public Supplier(JDCConnection oConn, String sGuSupplier) throws SQLException {
    this();
    load(oConn, sGuSupplier);
  }

  public Address getAddress() {
  	return oAddr;
  }

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    boolean bRetVal = super.load(oConn, PKVals);
    if (bRetVal) {
      if (!isNull(DB.gu_address)) oAddr.load(oConn, getString(DB.gu_address));
    }
    return bRetVal;
  }

  public boolean load(JDCConnection oConn, String sGuSupplier) throws SQLException {
    boolean bRetVal = super.load(oConn, sGuSupplier);
    if (bRetVal) {
      if (!isNull(DB.gu_address)) oAddr.load(oConn, getString(DB.gu_address));
    }
    return bRetVal;
  }

  public boolean store(JDCConnection oConn) throws SQLException {
	Date dtNow = new Date();

    if (AllVals.containsKey(DB.gu_supplier))
	  replace(DB.dt_modified, dtNow);
    else
      put(DB.gu_supplier, Gadgets.generateUUID());

    if (AllVals.containsKey(DB.gu_address)) {
	  oAddr.replace(DB.dt_modified, dtNow);
    } else {
      oAddr.put(DB.gu_address, Gadgets.generateUUID());
      put(DB.gu_address, oAddr.getString(DB.gu_address));
    }

	if (oAddr.isNull(DB.ix_address)) oAddr.put(DB.ix_address, 1);

    oAddr.store(oConn);
    
	boolean bRetVal = super.store(oConn);

	return bRetVal;
  } // store

  public boolean delete(JDCConnection oConn) throws SQLException {
    return Supplier.delete(oConn,getString(DB.gu_supplier));
  }
  
  public static boolean delete(JDCConnection oConn, String sGuSupplier) throws SQLException {
    boolean bRetVal;
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      PreparedStatement oStmt = oConn.prepareStatement("SELECT k_sp_del_supplier(?)");
      oStmt.setString(1, sGuSupplier);
      oStmt.executeQuery();
      oStmt.close();
    } else {
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_supplier(?) }");
      oCall.setString(1, sGuSupplier);
      oCall.execute();
      oCall.close();
    }
    return true;
  } // delete
  
  // **********************************************************
  // Public Constants

  public static final short ClassId = 89;

} // Supplier
