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

package com.knowgate.storage;

import java.util.Date;
import java.util.Stack;
import java.util.concurrent.ConcurrentHashMap;

import com.knowgate.jdc.JDCConnectionPool;
import com.knowgate.berkeleydb.DBEnvironment;

public class DataSourcePool {
  
  private static ConcurrentHashMap<DataSource,Date> oLastUse = new ConcurrentHashMap<DataSource,Date>();
  private static Stack<DataSource> oReadOnly = new Stack<DataSource>();
  
  public static DataSource get(Engine eEngine, String sProfileName, boolean bReadOnly)
  	throws StorageException,InstantiationException {
  	DataSource oRetDts;
  	if (bReadOnly || eEngine==Engine.JDBCRDBMS) {
  	  if (oReadOnly.empty()){
  	    oRetDts = Factory.createDataSource(eEngine, sProfileName, true);
  	  } else {
  	    oRetDts = oReadOnly.pop();
  	  }
  	} else {
  	  oRetDts = Factory.createDataSource(eEngine, sProfileName, false);
  	}
  	if (oLastUse.containsKey(oRetDts)) oLastUse.remove(oRetDts);
	oLastUse.put(oRetDts, new Date());  
  	return oRetDts;
  } // get
   
  public static void free(DataSource oDts)
  	throws StorageException {
  	if (oLastUse.containsKey(oDts)) oLastUse.remove(oDts);
	if (!oDts.isClosed()) {
  	  if (oDts.getEngine()==Engine.BERKELYDB) {
	    ((DBEnvironment) oDts).closeTables();
	    if (oDts.isReadOnly()) {
	      oReadOnly.push(oDts);
	    } else {
	      oDts.close();
	    }
  	  } if (oDts.getEngine()==Engine.JDBCRDBMS) {
  	  	oReadOnly.push(oDts);
  	  }
	}
  } // free

  public static void close()
  	throws StorageException {
    DataSource oDts;
    while (!oReadOnly.empty()) {     
      oDts = oReadOnly.pop();
  	  if (oLastUse.containsKey(oDts)) oLastUse.remove(oDts);
      if (!oDts.isClosed()) oDts.close();
    }
    for (DataSource d : oLastUse.keySet()) {
      if (!d.isClosed()) d.close();
    }
    oLastUse.clear();
  } // close

}