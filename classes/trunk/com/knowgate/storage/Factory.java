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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.util.HashMap;
import java.util.LinkedList;

import java.lang.reflect.InvocationTargetException;

import com.knowgate.misc.Environment;

public final class Factory {
  
  private static HashMap<String,SchemaMetaData> oSch = new HashMap<String,SchemaMetaData>();
		  
  public static DataSource createDataSource(Engine eEngine, String sProfileName, boolean bReadOnly)
  	throws InstantiationException, StorageException, ClassNotFoundException, IllegalAccessException,
  	       IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException, NullPointerException {
  	  Class oCls;
	  Object oObj;
  	  switch (eEngine) {

  	  case JDBCRDBMS:
  		oCls = Class.forName("com.knowgate.dataobjs.DBBind");
  		oObj = oCls.getConstructor(String.class).newInstance(sProfileName);
  		return (DataSource) oCls.getMethod("connectionPool").invoke(oObj);

  	  case BERKELYDB:
  		SchemaMetaData oSmd;
  		try {
  	      oCls = Class.forName("com.knowgate.berkeleydb.DBEnvironment");
    	  final String sPackageBase = Environment.getProfileVar(sProfileName, "package");
    	  if (null==sPackageBase) throw new NullPointerException("Property package is required at "+sProfileName+".cnf file");
    	  if (oSch.containsKey(sPackageBase)) {
    		  oSmd = oSch.get(sPackageBase);
    	  } else {
        	File oPackDir = new File(SchemaMetaData.getAbsolutePath(sPackageBase)+"tables");
          	if (!oPackDir.exists()) throw new FileNotFoundException("Directory "+oPackDir.getAbsolutePath()+" not found");
          	if (!oPackDir.isDirectory()) throw new FileNotFoundException(oPackDir.getAbsolutePath()+" is not a directory");
          	oSmd = new SchemaMetaData();
        	oSmd.load(oPackDir);
        	oSch.put(sPackageBase, oSmd);
    	  }    	  
    	  return (DataSource) oCls.getConstructor(String.class, oSmd.getClass(), boolean.class).newInstance(Environment.getProfilePath(sProfileName,"dbenvironment"), oSmd, bReadOnly);    		
  		} catch (IOException ioe) { throw new StorageException(ioe.getMessage(), ioe); }

  	  default:
  	  	throw new InstantiationException("Invalid ENGINE value");
  	}
  }

  public static Record createRecord(Engine eEngine, String sTableName, LinkedList<Column> oColumnsList)
  	throws InstantiationException, StorageException, ClassNotFoundException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException {
  	Class oCls;
  	switch (eEngine) {
  	  case JDBCRDBMS:
  		oCls = Class.forName("com.knowgate.dataobjs.DBPersist");
  		return (Record) oCls.getConstructor(String.class,String.class).newInstance(sTableName,sTableName);
  	  case BERKELYDB:
        oCls = Class.forName("com.knowgate.berkeleydb.DBEntity");
      	return (Record) oCls.getConstructor(String.class,oColumnsList.getClass()).newInstance(sTableName,oColumnsList);
  	  default:
  	  	throw new InstantiationException("Invalid ENGINE value");
  	}
  }
  
}
