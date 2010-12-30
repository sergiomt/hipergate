package com.knowgate.berkeleydb;

import java.io.IOException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Date;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import com.knowgate.storage.Connection;
import com.knowgate.storage.Column;
import com.knowgate.storage.AbstractRecord;
import com.knowgate.storage.StorageException;

import com.sleepycat.bind.EntityBinding;
import com.sleepycat.bind.serial.ClassCatalog;
import com.sleepycat.bind.serial.SerialSerialBinding;

public class DBEntity extends AbstractRecord {

  private static final long serialVersionUID = 600000101201000110l;
  private static SimpleDateFormat oTsFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  private String sPkColumnName;

  public DBEntity(String sBaseTable, ArrayList<Column> oColumnsList) {
    super(sBaseTable,oColumnsList);
  }

  /*
  public DBEntity(String sValue) {
  	sPkColumnName = "PrimaryKey";
  	put(sPkColumnName, sValue);
  }
  */

  public DBEntity(String sValue, HashMap<String,Object> oData) {
  	putAll(oData);
  	setPrimaryKey(sValue);
  }
  
  public String getPrimaryKey() {
  	if (sPkColumnName==null)
  	  return null;
  	else
  	  return (String) get(sPkColumnName);
  }

  public void setPrimaryKey(String sValue) {
  	if (sPkColumnName==null) {
  	  sPkColumnName = "PrimaryKey";
  	  put(sPkColumnName, sValue);
  	} else {
  	  if (containsKey(sPkColumnName)) remove(sPkColumnName);
  	  put(sPkColumnName, sValue);
  	}
  }

  public Date getDate(String sKey) {
    if (containsKey(sKey)) {
      String sDate = (String) get(sKey);
      try {
        if (sDate.equals("0000-00-00 00:00:00"))
      	  return null;
        else
      	  return oTsFmt.parse(sDate);
      } catch (ParseException neverthrown) { return null; }
    } else {
      return null;
    }
  }

  public Date getDate(String sKey, Date dtDefault) {
    if (containsKey(sKey)) {
      String sDate = (String) get(sKey);
      try {
        if (sDate.equals("0000-00-00 00:00:00"))
      	  return null;
        else
      	  return oTsFmt.parse(sDate);
      } catch (ParseException neverthrown) { return null; }
    } else {
      return dtDefault;
    }
  }

  public void delete(Connection oConn) throws StorageException {
  	((DBConnection) oConn).delete(this);
  }

}

