/*
  Copyright (C) 2003-2012  Know Gate S.L. All rights reserved.

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

import java.util.LinkedList;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.Collection;

import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.text.NumberFormat;

import com.knowgate.storage.Table;
import com.knowgate.storage.Column;
import com.knowgate.storage.Record;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;

public class RecordDelegator implements Record {

	private static final long serialVersionUID = 70000l;
	
	private AbstractRecord impl;

    public RecordDelegator(DataSource oDts, String sBaseTable)
      throws NullPointerException,InstantiationException {

      if (null==oDts) throw new NullPointerException("RecordDelegator DataSource may not be null");
      if (null==sBaseTable) throw new NullPointerException("RecordDelegator table name may not be null");
      if (sBaseTable.length()==0) throw new NullPointerException("RecordDelegator table name may not be an empty string");

      try {
        switch (oDts.getEngine()) {
     	  case BERKELYDB:
		    impl = (AbstractRecord) Factory.createRecord(oDts.getEngine(), sBaseTable, oDts.getMetaData().getColumns(sBaseTable));
            break;
     	  case JDBCRDBMS:
            impl = (AbstractRecord) Factory.createRecord(oDts.getEngine(), sBaseTable, null);
            break;
          default:
            throw new InstantiationException("RecordDelegator could not instantiate Record implementation for "+oDts.getEngine());
        }
      } catch (Exception e) {
    	throw new InstantiationException(e.getClass().getName()+" "+e.getMessage());
	  }
    }		
    
	public LinkedList<Column> columns() {
      return impl.columns();
	}

	public void delete(Table oConn) throws StorageException {
	  impl.delete(oConn);
	}

	public boolean load(Table oConn, String sKey) throws StorageException {
	  return impl.load(oConn, sKey);
	}

	public boolean load(Table oConn, Object[] aKey) throws StorageException {
	  return impl.load(oConn, aKey);
	}
	
	public String store(Table oConn) throws StorageException {
	  return impl.store(oConn);
	}

	public void replace(String sKey, Object oValue) {
	  impl.replace(sKey, oValue);
	}

	public String getTableName() {
	  return impl.getTableName();
	}

	public String getPrimaryKey() {
	  return impl.getPrimaryKey();
	}

	public void setPrimaryKey(String sValue) throws NullPointerException {
	  impl.setPrimaryKey(sValue);
	}

	public Column getColumn(String sColName) throws ArrayIndexOutOfBoundsException {
	  return impl.getColumn(sColName);
	}

	public boolean isNull(String sKey) {
	  return impl.isNull(sKey);
	}

	public boolean isEmpty(String sKey) {
	  return impl.isEmpty(sKey);
	}

	public Integer getInteger(String sKey) {
	  return impl.getInteger(sKey);
	}

	public int getInt(String sKey) {
	  return impl.getInt(sKey);
	}

	public long getLong(String sKey) {
	  return impl.getLong(sKey);
	}

	public Date getDate(String sKey) {
	  return impl.getDate(sKey);
	}

	public Date getDate(String sKey, Date dtDefault) {
	  return impl.getDate(sKey, dtDefault);
	}

	public BigDecimal getDecimal(String sKey) {
      return impl.getDecimal(sKey);
	}
	
	public String getString(String sKey) {
	  return impl.getString(sKey);
	}

	public String getString(String sKey, String sDefault) {
	  return impl.getString(sKey, sDefault);
	}

	public boolean getBoolean(String sKey, boolean bDefault) {
	  return impl.getBoolean(sKey, bDefault);
	}

	public String toXML(String sIdent, HashMap oAttrs, Locale oLoc) {
	  return impl.toXML(sIdent, oAttrs, oLoc);
	}

	public String toXML(String sIdent, HashMap oAttrs, 
				SimpleDateFormat oXMLDate, NumberFormat oXMLDecimal) {
	  return impl.toXML(sIdent, oAttrs, oXMLDate, oXMLDecimal);
	}

	public int size() {
	  return impl.size();
	}

	public boolean isEmpty() {
	  return impl.isEmpty();
	}

	public boolean containsKey(Object parm1) {
	  return impl.containsKey(parm1);
	}

	public boolean containsValue(Object parm1) {
	  return impl.containsValue(parm1);
	}

	public Object get(Object parm1) {
	  return impl.get(parm1);
	}

	public Object put(String parm1, short parm2) {
	  Short oRetVal = new Short(parm2);
	  impl.put(parm1,oRetVal);
	  return oRetVal;
	}

	public Object put(String parm1, int parm2) {
	  Integer oRetVal = new Integer(parm2);
	  impl.put(parm1,oRetVal);
	  return oRetVal;
	}

	public Object put(String parm1, float parm2) {
	  Float oRetVal = new Float(parm2);
	  impl.put(parm1,oRetVal);
	  return oRetVal;
	}

	public Object put(String parm1, double parm2) {
	  Double oRetVal = new Double(parm2);
	  impl.put(parm1,oRetVal);
	  return oRetVal;
	}

	public Object put(Object parm1, Object parm2) {
	  impl.put(parm1,parm2);
	  return parm2;
	}

	public Object remove(Object parm1) {
	  return impl.remove(parm1);
	}

	public void putAll(Map parm1) {
	  impl.putAll(parm1);
	}

	public void clear() {
	  impl.clear();
	}

	public Set keySet() {
	  return impl.keySet();
	}

	public Collection values() {
	  return impl.values();
	}

	public Set entrySet() {
	  return impl.entrySet();
	}

	public boolean equals(Object parm1) {
	  return impl.equals(parm1);
	}

	public int hashCode() {
	  return impl.hashCode();
	}	
}
