package com.knowgate.storage;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.Collection;

import java.text.SimpleDateFormat;
import java.text.NumberFormat;

import com.knowgate.storage.Table;
import com.knowgate.storage.Column;
import com.knowgate.storage.Record;
import com.knowgate.storage.Factory;
import com.knowgate.storage.StorageException;

import com.knowgate.berkeleydb.DBEntity;

public class RecordDelegator implements Record {

	private AbstractRecord impl;

    public RecordDelegator(Engine eEngine, String sBaseTable, ArrayList<Column> oColumnsList) {
      switch (eEngine) {
     	case BERKELYDB:
          impl = new DBEntity (sBaseTable,oColumnsList);
      }
    }		
    
	public ArrayList columns() {
      return impl.columns();
	}

	public void delete(Table oConn) throws StorageException {
	  impl.delete(oConn);
	}

	public boolean load(Table oConn, String sKey) throws StorageException {
	  return impl.load(oConn, sKey);
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
	  impl.getPrimaryKey();
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

	public Date getDate(String sKey) {
	  return impl.getDate(sKey);
	}

	public Date getDate(String sKey, Date dtDefault) {
	  return impl.getDate(sKey, dtDefault);
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

	public Object put(Object parm1, Object parm2) {
	  return impl.put(parm1,parm2);
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
