package com.knowgate.berkeleydb;

import java.util.LinkedList;

import java.util.Date;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import com.knowgate.debug.DebugFile;
import com.knowgate.storage.Connection;
import com.knowgate.storage.Column;
import com.knowgate.storage.AbstractRecord;
import com.knowgate.storage.StorageException;

public class DBEntity extends AbstractRecord {

  private static final long serialVersionUID = 600000101201000110l;
  private static SimpleDateFormat oTsFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  public DBEntity(String sBaseTable, LinkedList<Column> oColumnsList) {
    super(sBaseTable,oColumnsList);
  }

  public String getPrimaryKey() {
  	if (sPkColumnName==null) {
  	  return null;
  	} else {
  	  Object oPkVal = get(sPkColumnName);
  	  if (null==oPkVal)
  	  	return null;
  	  else
  	  	return oPkVal.toString();
  	}
  }

  public void setPrimaryKey(String sValue) {
  	if (sPkColumnName==null) {
  	  sPkColumnName = "PrimaryKey";
  	  put(sPkColumnName, sValue);
  	} else {
  	  if (containsKey(sPkColumnName)) remove(sPkColumnName);
  	  if (DebugFile.trace) DebugFile.writeln("setting primary key value for "+sPkColumnName+" to "+sValue);
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
  	((DBTable) oConn).delete(this);
  }

}

