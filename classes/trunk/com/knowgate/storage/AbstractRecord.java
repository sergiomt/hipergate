package com.knowgate.storage;

import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Iterator;
import java.util.Calendar;
import java.util.ArrayList;

import java.text.NumberFormat;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;

import com.knowgate.storage.Table;
import com.knowgate.storage.StorageException;

public abstract class AbstractRecord extends HashMap implements Record {

  private String sTableName;
  private String sPkColumnName;
  private ArrayList<Column> oColumns;
  private static final long serialVersionUID = 600000101201000090l;

  public AbstractRecord() {
  	ArrayList<Column> oColumns = new ArrayList<Column>();
    sTableName=null;
  }

  public AbstractRecord(String sBaseTableName, ArrayList<Column> oColumnsList) {
  	sTableName=sBaseTableName;
  	setPrimaryKey(null);
  	oColumns = oColumnsList;
  	if (null!=oColumnsList) {
  	  for (Column c : oColumnsList) {
  	  	if (c.isPrimaryKey()) {
  	  	  setPrimaryKey(c.getName());
  	  	  break;
  	  	} // fi
  	  } // next
  	} // fi
  }

  public ArrayList<Column> columns() {
  	return oColumns;
  }

  public void delete(Table oConn) throws StorageException {
  	oConn.delete(this);
  }
  
  public boolean load(Table oConn, String sKey) throws StorageException {
  	Record oRec = oConn.load(sKey);
  	clear();
  	if (null==oRec) {
  	  return false;
  	} else {
	  putAll(oRec);
	  return true;
  	}
  } // load

  public String store(Table oConn) throws StorageException {
  	RecordXMLCache.expire(oConn.getName(), getPrimaryKey());
	oConn.store(this);
	return getPrimaryKey();
  }

  public void replace(String sKey, Object oValue) {
  	if (containsKey(sKey)) remove(sKey);
	put(sKey, oValue);
  }

  public String getTableName() {
  	return sTableName;
  }

  public abstract String getPrimaryKey();

  public abstract void setPrimaryKey(String sValue) throws NullPointerException;

  public Column getColumn(String sColName) throws ArrayIndexOutOfBoundsException {
  	for (Column c : columns()) {
  	  if (c.getName().equalsIgnoreCase(sColName))
  	  	return c;
  	}
  	throw new ArrayIndexOutOfBoundsException ("Column not found "+sColName);
  }

  public boolean isNull(String sKey) {
    if (containsKey(sKey))
      return (get(sKey)!=null);
    else
      return true;
  }

  public boolean isEmpty(String sKey) {
    if (isNull(sKey))
      return true;
    else
      return get(sKey).equals("");
  }

  public Integer getInteger(String sKey) {
    if (containsKey(sKey)) {
      Object oInt = get(sKey);
      if (oInt instanceof Integer)
        return (Integer) oInt;
      else if (oInt instanceof String)
      	return new Integer((String) oInt);
      else
      	return new Integer(oInt.toString());
    } else {
      return null;
    }
  }

  public int getInt(String sKey) {
    if (containsKey(sKey)) {
      Object oInt = get(sKey);
      if (oInt instanceof Integer)
        return ((Integer) oInt).intValue();
      else if (oInt instanceof String)
      	return Integer.parseInt((String) oInt);
      else
      	return Integer.parseInt(oInt.toString());      
    } else {
      throw new NullPointerException("Column "+sKey+" is null");
    }
  }

  public abstract Date getDate(String sKey);

  public abstract Date getDate(String sKey, Date dtDefault);

  public String getString(String sKey) throws ClassCastException {
    if (containsKey(sKey))
      return (String) get(sKey);
    else
      return null;  	
  }

  public String getString(String sKey, String sDefault) {
    if (containsKey(sKey))
      return (String) get(sKey);
    else
      return sDefault;  	
  }

  public boolean getBoolean(String sKey, boolean bDefault) {
    if (containsKey(sKey))
      return ((Boolean) get(sKey)).booleanValue();
    else
      return bDefault;  	
  }

  public String toXML(String sIdent, HashMap<String,String> oAttrs, Locale oLoc) {
  	if (oLoc.getLanguage().equals("es"))
      return toXML(sIdent, oAttrs, new SimpleDateFormat("DD/MM/yyyy HH:mm:ss"),
    							   DecimalFormat.getNumberInstance(oLoc));
    else
      return toXML(sIdent, oAttrs, new SimpleDateFormat("yyyy-MM-DD HH:mm:ss"),
    							   DecimalFormat.getNumberInstance());
  }
  
  public String toXML(String sIdent, HashMap<String,String> oAttrs,
  					  SimpleDateFormat oXMLDate, NumberFormat oXMLDecimal) {

	final String LF = "\n";
    StringBuffer oBF = new StringBuffer(4000);
    Iterator<Column> oIT = columns().iterator();
    Object oColValue;
    String sColName;
    String sStartElement = sIdent + sIdent + "<";
    String sEndElement = ">" + LF;
    Class oColClass, ClassString = null, ClassDate = null, ClassDecimal = null;

    try {
      ClassString = Class.forName("java.lang.String");
      ClassDate = Class.forName("java.util.Date");
      ClassDecimal = Class.forName("java.math.BigDecimal");
    } catch (ClassNotFoundException ignore) { }

    if (null==oAttrs) {
      oBF.append(sIdent + "<" + getClass().getName() + ">" + LF);
    } else {
      oBF.append(sIdent + "<" + getClass().getName());
      Iterator<String> oNames = oAttrs.keySet().iterator();
      while (oNames.hasNext()) {
        String sName = oNames.next();
        oBF.append(" "+sName+"=\""+oAttrs.get(sName)+"\"");
      } // wend
      oBF.append(">" + LF);
    } // fi

    while (oIT.hasNext()) {
      Column oCol = oIT.next();
      sColName = oCol.getName();
      oColValue = get(sColName);

      oBF.append(sStartElement);
      oBF.append(sColName);
      oBF.append(">");
      if (null!=oColValue) {
        oColClass = oColValue.getClass();
        if (oColClass.equals(ClassString))
          oBF.append("<![CDATA[" + oColValue + "]]>");
        else if (oColClass.equals(ClassDate))
          oBF.append(oXMLDate.format((java.util.Date) oColValue));
        else if (oColClass.equals(ClassDecimal))
          oBF.append(oXMLDecimal.format((java.math.BigDecimal) oColValue));
        else
          oBF.append(oColValue);
      }
      oBF.append("</");
      oBF.append(sColName);
      oBF.append(sEndElement);
    } // wend

    oBF.append(sIdent + "</" + getClass().getName() + ">");

    return oBF.toString();
  } // toXML
}
