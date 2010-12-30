package com.knowgate.storage;

import java.io.Serializable;

import java.util.Map;
import java.util.Date;
import java.util.Locale;
import java.util.HashMap;
import java.util.ArrayList;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;

public interface Record extends Map,Serializable {

  public ArrayList<Column> columns();

  public void delete(Table oConn) throws StorageException;
  
  public boolean load(Table oConn, String sKey) throws StorageException;

  public String store(Table oConn) throws StorageException;

  public void replace(String sKey, Object oValue);

  public String getTableName();

  public String getPrimaryKey(); 

  public void setPrimaryKey(String sValue) throws NullPointerException;

  public Column getColumn(String sColName) throws ArrayIndexOutOfBoundsException;

  public boolean isNull(String sKey);

  public boolean isEmpty(String sKey);

  public Integer getInteger(String sKey);

  public int getInt(String sKey);

  public Date getDate(String sKey);

  public Date getDate(String sKey, Date dtDefault);

  public String getString(String sKey);

  public String getString(String sKey, String sDefault);

  public boolean getBoolean(String sKey, boolean bDefault);

  public String toXML(String sIdent, HashMap<String,String> oAttrs, Locale oLoc);
  
  public String toXML(String sIdent, HashMap<String,String> oAttrs,
  					  SimpleDateFormat oXMLDate, NumberFormat oXMLDecimal);

}
