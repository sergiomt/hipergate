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

import java.sql.SQLException;

import javax.naming.NamingException;

import java.beans.Beans;

import java.lang.reflect.InvocationTargetException;

import java.util.Properties;

import com.knowgate.misc.Environment;

public final class Manager extends Beans {

  private final static String PROFILE = "hipergate";

  private Class[] aDataSourceClass;
  private Class[] aEngineClass2;
  private Class[] aStringClass1;
  private Class[] aStringClass2;
  private String sPro;
  private Engine oEng;
  private RecordQueueProducer oRqp;
  private Properties oSyn = new Properties();

  public Manager() throws StorageException,NamingException,InstantiationException, ClassNotFoundException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException {
  	this(Engine.DEFAULT, PROFILE);
  }

  public Manager(Engine oDBEngine) throws StorageException,NamingException,InstantiationException, ClassNotFoundException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException {
    this(oDBEngine, PROFILE);
  }
  
  public Manager(Engine oDBEngine, String sProfile)
  	throws StorageException,NamingException,InstantiationException, ClassNotFoundException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException {
	aStringClass1 = new Class[]{String.class};
    aStringClass2 = new Class[]{String.class,String.class};
    aEngineClass2 = new Class[]{Engine.class,String.class};
    oEng = oDBEngine;
    sPro = sProfile;
    String sRqp = Environment.getProfileVar(sPro, "queue", "com.knowgate.ramqueue.RAMQueueProducer");
	if (sRqp.equals("com.knowgate.ramqueue.RAMQueueProducer"))
	  oRqp = (RecordQueueProducer) Class.forName(sRqp).getConstructor(aEngineClass2).newInstance(new Object[]{oDBEngine, sPro});
	else
      oRqp = (RecordQueueProducer) Class.forName(sRqp).getConstructor(aStringClass1).newInstance(new Object[]{sPro});
	oSyn = new Properties();
    oSyn.put("synchronous","true");
    try {
      aDataSourceClass = new Class[]{Class.forName("com.knowgate.storage.DataSource")};
    } catch (ClassNotFoundException neverthrown) {}
  }
  
  public void close() throws StorageException {
    oRqp.close();
  }
  
  public Properties getProperties() {
    return Environment.getProfile(sPro);
  }

  public DataSource getDataSource() throws StorageException,InstantiationException {
    return DataSourcePool.get(oEng, sPro, false);
  }

  public void free(DataSource oDts) throws StorageException {
  	if (null!=oDts) DataSourcePool.free(oDts);    	
  }

  public boolean exists(String sTableName, String sKey)
  	throws StorageException,InstantiationException {
    Table oTbl = null;
    boolean bRetVal = false;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(oEng, sPro, true);
      oTbl = oDts.openTable(sTableName);
      bRetVal = oTbl.exists(sKey);
	  try { oTbl.close(); oTbl=null; }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return bRetVal;
  }

  public Record load(String sTableName, String sKey)
  	throws StorageException,InstantiationException {
    Table oTbl = null;
    Record oRec= null;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(oEng, sPro, true);
      oTbl = oDts.openTable(sTableName);
      oRec = oTbl.load(sKey);
	  try { oTbl.close(); oTbl=null; }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return oRec;
  }
  
  public void store(Record oRec, boolean bSynchronous)
  	throws StorageException,InstantiationException {
  	if (bSynchronous)
	  oRqp.store(oRec, oSyn);
	else
	  oRqp.store(oRec);		
  }

  public void delete(Record oRec, String[] aKeys)
  	throws StorageException,InstantiationException {
	oRqp.delete(oRec,aKeys,oSyn);
  }

  public RecordSet fetch(String sTableName)
  	throws StorageException,InstantiationException {
    Table oTbl = null;
    RecordSet oRst= null;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(oEng, sPro, true);
      oTbl = oDts.openTable(sTableName);
      oRst = oTbl.fetch();
	  try { oTbl.close(); oTbl=null; }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return oRst;	
  }
  
  public RecordSet fetch(String sTableName, String sIndexColumn, String sIndexValue)
  	throws StorageException,InstantiationException {
    Table oTbl = null;
    RecordSet oRst= null;
    DataSource oDts = null;
    try {
      oDts = DataSourcePool.get(oEng, sPro, true);
      oTbl = oDts.openTable(sTableName, new String[] {sIndexColumn});
      oRst = oTbl.fetch(sIndexColumn, sIndexValue);
	  try { oTbl.close(); oTbl=null; }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
	  if (null!=oDts) DataSourcePool.free(oDts);    	
    }
    return oRst;	
  }

  public Record createRecord(String sClassName)
  	throws InstantiationException,ClassNotFoundException,ClassCastException,
  	       IllegalAccessException,NoSuchMethodException,StorageException {
  	Record oRetVal;
  	switch (oEng) {
  	  case JDBCRDBMS:
  	    oRetVal = (Record) Class.forName(sClassName).newInstance();
		break;
  	  case BERKELYDB:
        DataSource oDts = null;
		try {
		  oDts = DataSourcePool.get(oEng, sPro, true);
		  oRetVal = (Record) Class.forName(sClassName).getConstructor(aDataSourceClass).newInstance(new Object[]{oDts});
		  DataSourcePool.free(oDts);
		} catch (InvocationTargetException ite) {
		  throw new InstantiationException(ite.getMessage());
		} finally {
		  if (oDts!=null) DataSourcePool.free(oDts);
		}
		break;
  	  default:
  	  	throw new InstantiationException("Invalid ENGINE value");
  	}
  	return oRetVal;
  }

}
