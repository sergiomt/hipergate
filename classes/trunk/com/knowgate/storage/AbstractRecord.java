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
import java.util.HashMap;
import java.util.Locale;
import java.util.Iterator;
import java.util.LinkedList;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;

import com.knowgate.debug.DebugFile;

import com.knowgate.storage.Table;
import com.knowgate.storage.StorageException;

public abstract class AbstractRecord extends HashMap implements Record {

  protected String sTableName;
  protected String sPkColumnName;
  private LinkedList<Column> oColumns;
  private static final long serialVersionUID = 600000101201000090l;

  public AbstractRecord() {
  	oColumns = null;
    sTableName=null;
    sPkColumnName=null;
  }

  public AbstractRecord(String sTblName) {
  	oColumns = null;
    sTableName=sTblName;
    sPkColumnName=null;
  }

  public AbstractRecord(String sBaseTableName, LinkedList<Column> oColumnsList)
    throws IllegalArgumentException {
  	boolean bHasPk = false;
	sTableName=sBaseTableName;
  	setPrimaryKey(null);
  	oColumns = oColumnsList;
  	if (null!=oColumnsList) {
  	  for (Column c : oColumnsList) {
  	  	if (c.isPrimaryKey()) {
  	  	  if (bHasPk) throw new IllegalArgumentException("AbstractRecord for "+sBaseTableName+" has a duplicated primary key "+sPkColumnName+" and"+c.getName());
  	  	  bHasPk=true;
  	  	  sPkColumnName = c.getName();
  	  	  break;
  	  	} // fi
  	  } // next
  	} // fi
    if (DebugFile.trace) {
  	  String sColNames = "";
  	  for (Column c : oColumnsList) sColNames += " "+c.getName();
      DebugFile.writeln("created AbstractRecord for "+sBaseTableName+" with columns "+sColNames);
    }
  }

  public LinkedList<Column> columns() {
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

  public boolean load(Table oConn, Object[] aKey) throws StorageException {
	Record oRec = oConn.load(aKey);
	clear();
	if (null==oRec) {
	  return false;
	} else {
	  putAll(oRec);
	  return true;
	}
  } // load
  
  public String store(Table oConn) throws StorageException {
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

  /**
   * @return <b>true</b> if Record does not contain the given key or its value is <b>null</b>
   */
  public boolean isNull(String sKey) {
    if (containsKey(sKey)) {
      Object oVal = get(sKey);
      if (null==oVal)
      	return true;
      else
        return oVal.equals("null") || oVal.equals("NULL");
    } else {
      return true;
    }
  }

  /**
   * @return <b>true</b> if Record does not contain the given key or its value is <b>null</b> or its value is an empty string ""
   */
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

  public BigDecimal getDecimal(String sKey) {
	 if (containsKey(sKey)) {
	 Object oDec = get(sKey);
	 if (oDec instanceof BigDecimal)
	   return (BigDecimal) oDec;
	 else if (oDec instanceof String)
	   return new BigDecimal((String) oDec);
	 else
	   return new BigDecimal(oDec.toString());      
	 } else {
	   throw new NullPointerException("Column "+sKey+" is null");
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

  public long getLong(String sKey) {
    if (containsKey(sKey)) {
      Object oLng = get(sKey);
      if (oLng instanceof Long)
        return ((Long) oLng).longValue();
      else if (oLng instanceof String)
      	return Long.parseLong((String) oLng);
      else
      	return Long.parseLong(oLng.toString());      
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

  public void put(String parm1, short parm2) {
	  put(parm1,new Short(parm2));
  }

  public void put(String parm1, int parm2) {
	  put(parm1,new Integer(parm2));
  }

  public void put(String parm1, float parm2) {
	  put(parm1,new Float(parm2));
  }

  public void put(String parm1, double parm2) {
	  put(parm1,new Double(parm2));
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
