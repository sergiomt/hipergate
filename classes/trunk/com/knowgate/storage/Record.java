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

import java.io.Serializable;
import java.math.BigDecimal;

import java.util.Map;
import java.util.Date;
import java.util.Locale;
import java.util.HashMap;
import java.util.LinkedList;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;

public interface Record extends Map,Serializable {

  public LinkedList<Column> columns();

  public void delete(Table oConn) throws StorageException;

  public boolean load(Table oConn, Object[] aKey) throws StorageException;
  
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

  public long getLong(String sKey);

  public Date getDate(String sKey);

  public Date getDate(String sKey, Date dtDefault);

  public BigDecimal getDecimal(String sKey);
  
  public String getString(String sKey);

  public String getString(String sKey, String sDefault);

  public boolean getBoolean(String sKey, boolean bDefault);

  public String toXML(String sIdent, HashMap<String,String> oAttrs, Locale oLoc);
  
  public String toXML(String sIdent, HashMap<String,String> oAttrs,
  					  SimpleDateFormat oXMLDate, NumberFormat oXMLDecimal);

}
