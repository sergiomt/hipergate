/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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

package com.knowgate.dataobjs;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.File;
import java.io.ObjectOutputStream;
import java.io.ByteArrayOutputStream;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Time;
import java.sql.Array;
import java.sql.Timestamp;

import java.lang.ClassNotFoundException;
import java.lang.IllegalAccessException;
import java.lang.InstantiationException;

import java.util.Date;
import java.util.Map;
import java.util.Collection;
import java.util.Locale;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Set;
import java.util.Properties;

import java.math.BigDecimal;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.text.DecimalFormat;
import java.text.NumberFormat;

import org.xml.sax.SAXException;
import org.xml.sax.SAXNotRecognizedException;
import org.xml.sax.SAXNotSupportedException;
import org.xml.sax.SAXParseException;

import com.knowgate.debug.*;
import com.knowgate.jdc.*;
import com.knowgate.math.Money;
import com.knowgate.misc.Gadgets;

import com.knowgate.storage.Column;
import com.knowgate.storage.AbstractRecord;

/**
 * <p>Core class for persisting Java objects as registers in a RDMS.<p>
 * <p>Althought not an abstract class, DBPersist is mainly designed to be inherited
 * by a child class implementing specific behavior for reading a writting a Java
 * object from and to a relational database.</p>
 * <p>DBPersist mantains an internal collection of values each one mapped to a database field.</p>
 * This mapping is done automatically by DBPersist reading the target table metadata definition
 * and preparing the proper internal value set.</p>
 * <p>This object keeps the internal value set in memory as long as it is not garbage collected,
 * but it does not mantaing any session information nor transaction management with the database.
 * It is the programmer's responsability to pass an open database connection on each method call
 * and to commit or rollback transaction involving the usage of a DBPersist object.
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class DBPersist extends AbstractRecord {

  private static final long serialVersionUID = 70000l;

  /**
   * Create instance for reading and writing register from a table
   * @param sTable Database table name for storing objects.
   * @param sAuditClass Name of child Java class inheriting from DBPersist.
   * @throws IllegalStateException
  */

  public DBPersist (String sTable, String sAuditClass)
    throws IllegalStateException {

	super(sTable);

    sAuditCls = sAuditClass;
    sAuditUsr = "";
    sTransactId = "";
    bAllCaps = bHasLongVarBinaryData = false;
    AllVals = new HashMap();
  }

  /**
   * Create instance for reading and writing register from a table
   * @param sTable Database table name for storing objects.
   * @param sAuditClass Name of child Java class inheriting from DBPersist.
   * @param bAllValuesUpperCase Convert all put string values to uppercase
   * @throws IllegalStateException
   * @since 3.0
  */

  public DBPersist (String sTable, String sAuditClass, boolean bAllValuesUpperCase)
    throws IllegalStateException {

	super(sTable);

    sAuditCls = sAuditClass;
    sAuditUsr = "";
    sTransactId = "";
    bAllCaps = bAllValuesUpperCase;
    bHasLongVarBinaryData = false;
    AllVals = new HashMap();
  }

  /**
   * Automatically convert put string values to uppercase
   * @param bAllValuesUpperCase boolean
   * @since 3.0
   */
  public void allcaps(boolean bAllValuesUpperCase) {
    bAllCaps = bAllValuesUpperCase;
  }

  /**
   * Get allcaps state
   * @return boolean
   * @since 3.0
   */
  public boolean allcaps() {
    return bAllCaps;
  }

  /**
   * Set user id for automatic operation auditing.
   */
  public void setAuditUser (String sAuditUser) {
    sAuditUsr = sAuditUser;
  }

  /**
   * Set transaction id for automatic operation auditing.
   */

  public void setAuditTransact (String sAuditTransact) {
    sTransactId = sAuditTransact;
  }

  /**
   * Returns whether or not this DBPersist contains no field values
   * @return boolean
   */
  public boolean isEmpty() {
    return getItemMap().isEmpty();
  }

  /**
   * Actual number of field values on this DBPersist
   * @return int
   */
  public int size() {
    return getItemMap().size();
  }

  /**
   * <p>Clears internal values.</p>
   * <p>No register is deleted at the database.</p>
   */
  public void clear() {
    AllVals.clear();
  }

  /**
   * <p>Copy another DBPersist into this instance</p>
   * Table and audit class values are replaced with to ones from source object
   * @param oSource Source Object
   * @since 2.2
   */
  public void clone(DBPersist oSource) {
    sTableName = oSource.getTableName();
    sAuditCls = oSource.getAuditClassName();
    AllVals = new HashMap(oSource.AllVals);
  }

  /**
   * <p>Get list of columns from underlying table of this DBPersist</p>
   * Table and audit class values are replaced with to ones from source object
   * @param oSource Source Object
   * @since 7.0
   */
  public LinkedList<Column> columns() {
  	return getTable().getColumns();
  }

  /**
   * Returns true if any of this DBPersist fields has the specified value.
   * @param oKey Object whose presence in this map is to be tested
   * @return boolean
   * @since 2.2
   */
  public boolean containsValue(Object oKey) {
    return getItemMap().containsValue(oKey);
  }

  /**
   * Returns true if this DBPersist contains a field for the given name
   * @param oKey Field Name
   * @return boolean
   * @throws NullPointerException If oKey is <b>null</b>
   * @since 2.2
   */
  public boolean containsKey(Object oKey)
    throws NullPointerException {
    if (oKey==null) throw new NullPointerException("DBPersist.containsKey() field name cannot be null");
    return getItemMap().containsKey(oKey);
  }

  /**
   * <p>Get value for a field name</p>
   * @param sKey String Field Name
   * @return Field value. If field is <b>null</b> or DBPersist has not been loaded,
   * or no field with given name exists at table, get() returns <b>null</b>.
   */

  public Object get(String sKey) {
    return getItemMap().get(sKey);
  }

  /**
   * Get dt_created column of register corresponding to this DBPersist instace
   * @param oConn JDCConnection
   * @return Date or <b>null</b> if no data is found
   * @throws SQLException If table for this DBPersist does not have a column named dt_created
   */
  public Date getCreationDate(JDCConnection oConn) throws SQLException {
    Date oDt;
    ResultSet oRSet = null;
    PreparedStatement oStmt = null;
    DBTable oTbl = getTable(oConn);
    LinkedList<String> oList = oTbl.getPrimaryKey();
    ListIterator<String> oIter;
    String sSQL = "SELECT "+DB.dt_created+" FROM "+oTbl.getName()+" WHERE 1=1";
    oIter = oList.listIterator();
    while (oIter.hasNext())
      sSQL += " AND " + oIter.next() + "=?";
    try {
    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    int p=0;
    oIter = oList.listIterator();
    while (oIter.hasNext())
      oStmt.setObject(++p, get(oIter.next()));
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      oDt = oRSet.getDate(1);
    else
      oDt = null;
    oRSet.close();
    oRSet=null;
    oStmt.close();
    oStmt=null;
    } catch (Exception xcpt) {
      if (null!=oRSet) { try { oRSet.close(); } catch (Exception ignore) { /* ignore */ } }
      if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) { /* ignore */ } }
      throw new SQLException ("DBPersist.getCreationDate() "+xcpt.getClass().getName()+" "+xcpt.getMessage());
    }
    return oDt;
  } // getCreationDate

  /**
   * Set dt_created column of register corresponding to this DBPersist instace
   * @param oConn JDCConnection
   * @param dtCreated Date If <b>null</b> then current system date is set
   * @throws SQLException If table for this DBPersist does not have a column named dt_created
   * @since 5.0
   */

  public void setCreationDate(JDCConnection oConn, Date dtCreated) throws SQLException {
  	if (null==dtCreated) dtCreated = new Date();
    PreparedStatement oStmt = null;
    DBTable oTbl = getTable(oConn);
    LinkedList oList = oTbl.getPrimaryKey();
    ListIterator oIter;
    String sSQL = "UPDATE "+oTbl.getName()+" SET "+DB.dt_created+"=? WHERE 1=1";
    oIter = oList.listIterator();
    while (oIter.hasNext())
      sSQL += " AND " + oIter.next() + "=?";
    try {
    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setTimestamp(1, new Timestamp(dtCreated.getTime()));
    int p=1;
    oIter = oList.listIterator();
    while (oIter.hasNext())
      oStmt.setObject(++p, get(oIter.next()));
    oStmt.executeUpdate();
    oStmt.close();
    oStmt=null;
    } catch (Exception xcpt) {
      if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) { /* ignore */ } }
      throw new SQLException ("DBPersist.getCreationDate() "+xcpt.getClass().getName()+" "+xcpt.getMessage());
    }
  } // setCreationDate
  
  /**
   * <p>Get value for a field name</p>
   * @param sKey String Field Name
   * @return Field value. If field is <b>null</b> or DBPersist has not been loaded,
   * or no field with given name exists at table, get() returns <b>null</b>.
   * @throws NullPointerException If oKey is <b>null</b>
   * @since 2.2
   */

  public Object get(Object oKey) throws NullPointerException {
    if (oKey==null) throw new NullPointerException("DBPersist.get() field name cannot be null");
    return getItemMap().get(oKey);
  }

  /**
   * <p>Get value for a DECIMAL or NUMERIC field<p>
   * @param sKey Field Name
   * @return Field value or <b>null</b>.
   * @throws java.lang.ClassCastException
   * @throws java.lang.NumberFormatException
   */

  public BigDecimal getDecimal(String sKey)
    throws ClassCastException, NumberFormatException {

    Object oDec = getItemMap().get(sKey);

    if (oDec==null)
      return null;
    else {
      if (oDec.getClass().getName().equalsIgnoreCase("java.lang.String"))
        return new BigDecimal((String) oDec);
      else
        return (BigDecimal) oDec;
    }
  } // getDecimal


  /**
   * <p>Get BigDecimal formated as a String using the given pattern and the symbols for the default locale</p>
   * @param sKey Field Name
   * @param sPattern A non-localized pattern string, for example: "#0.00"
   * @return String decimal value formated according to sPatern or <b>null</b>
   * @throws ClassCastException
   * @throws NumberFormatException
   * @throws NullPointerException if sPattern is <b>null</b>
   * @throws IllegalArgumentException if sPattern is invalid
   */
  public String getDecimalFormated(String sKey, String sPattern)
    throws ClassCastException, NumberFormatException,NullPointerException,
           IllegalArgumentException {

    BigDecimal oDec = getDecimal(sKey);

    if (oDec==null)
      return null;
    else {
      return new DecimalFormat(sPattern).format(oDec.doubleValue());
    }
  } // getDecimalFormated

  /**
   * <p>Get BigDecimal formated as a String using the given locale and fractional digits</p>
   * @param sKey Field Name
   * @param Locale
   * @param nFractionDigits Number of digits at the right of the decimal separator
   * @return String decimal value formated according to Locale or <b>null</b>
   * @throws ClassCastException
   * @throws NumberFormatException
   * @throws NullPointerException if sPattern is <b>null</b>
   * @throws IllegalArgumentException if sPattern is invalid
   * @since 4.0
   */
  public String getDecimalFormated(String sKey, Locale oLoc, int nFractionDigits)
    throws ClassCastException, NumberFormatException,NullPointerException,
           IllegalArgumentException {

    BigDecimal oDec = getDecimal(sKey);

    if (oDec==null)
      return null;
    else {
	  DecimalFormat oNumFmt = (DecimalFormat) NumberFormat.getNumberInstance(oLoc);
	  oNumFmt.setMaximumFractionDigits(2);
	  return oNumFmt.format(oDec);
    }
  } // getDecimalFormated

  /**
   * <p>Get double formated as a String using the given pattern and the symbols for the default locale</p>
   * @param sKey Field Name
   * @param sPattern A non-localized pattern string, for example: "#0.00"
   * @return String decimal value formated according to sPatern or <b>null</b>
   * @throws ClassCastException
   * @throws NumberFormatException
   * @throws NullPointerException
   * @throws IllegalArgumentException
   */
  public String getDoubleFormated(String sKey, String sPattern)
      throws ClassCastException, NumberFormatException,NullPointerException,
             IllegalArgumentException {
    if (isNull(sKey))
        return null;
      else
        return new DecimalFormat(sPattern).format(getDouble(sKey));
  }

  /**
   * <p>Get float formated as a String using the given pattern and the symbols for the default locale</p>
   * @param sKey Field Name
   * @param sPattern A non-localized pattern string, for example: "#0.00"
   * @return String decimal value formated according to sPatern or <b>null</b>
   * @throws ClassCastException
   * @throws NumberFormatException
   * @throws NullPointerException
   * @throws IllegalArgumentException
   */
  public String getFloatFormated(String sKey, String sPattern)
    throws ClassCastException, NumberFormatException,NullPointerException,
           IllegalArgumentException {
    if (isNull(sKey))
      return null;
    else
      return new DecimalFormat(sPattern).format(getFloat(sKey));
  }

  /**
   * <p>Get value of a VARCHAR field that holds a money+currency amount<p>
   * Money values are stored with its currency sign embedded inside,
   * like "26.32 USD" or "$48.3" or "35.44 €"
   * @param sKey Field Name
   * @return com.knowgate.math.Money
   * @throws NumberFormatException
   * @since 3.0
   */
  public Money getMoney(String sKey)
    throws NumberFormatException {
    Object oVal = getItemMap().get(sKey);
    if (null!=oVal)
      if (oVal.toString().length()>0)
        return Money.parse(oVal.toString());
      else
        return null;
    else
      return null;
  } // getMoney

  /**
   * <p>Get value for a CHAR, VARCHAR or LONGVARCHAR field<p>
   * @param sKey Field Name
   * @return Field value or <b>null</b>.
   * @throws NullPointerException if field is <b>null</b> or no field with
   * such name was found at internal value collection.
   */
  public String getString(String sKey) throws NullPointerException {
    if (DebugFile.trace) {
      if (!AllVals.containsKey(sKey))
        DebugFile.writeln("NullPointerException at "+(getAuditClassName()==null ? "DBPersist" : getAuditClassName())+" does not contain any object with key "+sKey);
      else if (isNull(sKey))
        DebugFile.writeln("NullPointerException at "+(getAuditClassName()==null ? "DBPersist" : getAuditClassName())+".getString("+sKey+") is null");
    }
    return getItemMap().get(sKey).toString();
  }

  /**
   * <p>Get value for a CHAR, VARCHAR or LONGVARCHAR field replacing <b>null</b>
   * with a default value.<p>
   * @param sKey Field Name
   * @param sDefault Value to be returned if field is null. sDefault may itself
   * be <b>null</b>, provinding a null safe version of getString() method.
   * @return Field value or default value.
   */

  public String getStringNull(String sKey, String sDefault) {
    Object oVal;
    if (getItemMap().containsKey(sKey)) {
      oVal = getItemMap().get(sKey);
      if (null==oVal)
        return sDefault;
      else
        return oVal.toString();
    }
    else
      return sDefault;
  }

  /**
   * <p>Get value for a CHAR, VARCHAR or LONGVARCHAR field replacing <b>null</b>
   * with a default value and replacing non-ASCII and quote values with &#<i>code</i>;<p>
   * @param sKey Field Name
   * @param sDefault Value to be returned if field is null. sDefault may itself
   * be <b>null</b>, provinding a null safe version of getString() method.
   * @return Field value or default value.
   * @since 5.5
   */

  private String escapeHtmlEntites(String sHtml)
  	throws org.apache.oro.text.regex.MalformedPatternException {
  	if (null==sHtml) return null;
  	if (sHtml.length()==0) return "";
  	
  	String sEscHtml = Gadgets.XHTMLEncode(Gadgets.replace(sHtml,"&","&amp;"));
  		
    return Gadgets.replace(Gadgets.replace(Gadgets.replace(Gadgets.replace(sEscHtml,"\"", "&#34;"),"'", "&#39;"),"<","&lt;"),">","&gt;");
  }

  public String getStringHtml(String sKey, String sDefault) {
    Object oVal;
    try {
      if (getItemMap().containsKey(sKey)) {
        oVal = getItemMap().get(sKey);
        if (null==oVal)
          if (null==sDefault)
            return sDefault;
          else
            return escapeHtmlEntites(sDefault);
        else
          return escapeHtmlEntites(oVal.toString());
      }
      else {
        if (null==sDefault)
          return sDefault;
       else
      	  return escapeHtmlEntites(sDefault);
      }
    } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }
    return null;
  }

  /**
   * <p>Get value for SQL92 TIME field</p>
   * @param sKey Field Name
   * @return java.sql.Time
   * @since 3.0
   */
  public Time getTimeOfDay(String sKey) {
    Object oTm = getItemMap().get(sKey);
    if (null!=oTm)
      return (Time) oTm;
    else
      return null;
  } // getTimeOfDay

  /**
   * <p>Get value for a SMALLINT field<p>
   * @param sKey Field Name
   * @return Field value.
   * @throws NullPointerException if field is <b>null</b> or no field with
   * such name was found at internal value collection.
   */

  public short getShort(String sKey) throws java.lang.NullPointerException {
    Object oVal = getItemMap().get(sKey);

    if (oVal==null) throw new NullPointerException(sKey + " is null");

    return Short.parseShort(oVal.toString());
  }

  /**
   * <p>Get value for a DOUBLE or NUMBER([1..28],m) field<p>
   * @param sKey Field Name
   * @return Field value.
   * @throws NullPointerException if field is <b>null</b> or no field with
   * such name was found at internal value collection.
   * @throws NumberFormatException
   */

  public double getDouble(String sKey)
    throws NullPointerException, NumberFormatException {
    Object oVal = getItemMap().get(sKey);
    Class oCls;
    double dRetVal;

    if (oVal==null) throw new NullPointerException(sKey + " is null");

    oCls = oVal.getClass();

    try {
      if (oCls.equals(Short.TYPE))
        dRetVal = (double) ((Short) oVal).shortValue();
      else if (oCls.equals(Integer.TYPE))
        dRetVal = (double) ((Integer) oVal).intValue();
      else if (oCls.equals(Class.forName("java.math.BigDecimal")))
        dRetVal = ((java.math.BigDecimal) oVal).doubleValue();
      else if (oCls.equals(Float.TYPE))
        dRetVal = ((Float) oVal).floatValue();
      else if (oCls.equals(Double.TYPE))
        dRetVal = ((Double) oVal).doubleValue();
      else
        dRetVal = new Double(oVal.toString()).floatValue();
    } catch (ClassNotFoundException cnfe) { /* never thrown */ dRetVal = 0d; }

    return dRetVal;
  } // getDouble

  /**
   * <p>Get value for a FLOAT or NUMBER([1..28],m) field<p>
   * @param sKey Field Name
   * @return Field value.
   * @throws NullPointerException if field is <b>null</b> or no field with
   * such name was found at internal value collection.
   * @throws NumberFormatException
   */

  public float getFloat(String sKey)
    throws NullPointerException, NumberFormatException {
    Object oVal = getItemMap().get(sKey);
    Class oCls;
    float fRetVal;

    if (oVal==null) throw new NullPointerException(sKey + " is null");

    oCls = oVal.getClass();

    try {
      if (oCls.equals(Short.TYPE))
        fRetVal = (float) ((Short) oVal).shortValue();
      else if (oCls.equals(Integer.TYPE))
        fRetVal = (float) ((Integer) oVal).intValue();
      else if (oCls.equals(Class.forName("java.math.BigDecimal")))
        fRetVal = ((java.math.BigDecimal) oVal).floatValue();
      else if (oCls.equals(Float.TYPE))
        fRetVal = ((Float) oVal).floatValue();
      else if (oCls.equals(Double.TYPE))
        fRetVal = ((Double) oVal).floatValue();
      else
        fRetVal = new Float(oVal.toString()).floatValue();
    } catch (ClassNotFoundException cnfe) { /* never thrown */ fRetVal = 0f; }

    return fRetVal;

  } // getFloat

  /**
   * <p>Get value for a INTEGER or NUMBER([1..11]) field<p>
   * @param sKey Field Name
   * @return Field value.
   * @throws NullPointerException if field is <b>null</b> or no field with
   * such name was found at internal value collection.
   * @throws NumberFormatException
   */

  public int getInt(String sKey)
    throws NullPointerException, NumberFormatException {
    int iRetVal;
    Object oInt = getItemMap().get(sKey);

    if (Integer.TYPE.equals(oInt.getClass()))
      iRetVal = ((Integer)(oInt)).intValue();
    else
      iRetVal = Integer.parseInt(oInt.toString());

    return iRetVal;
  } // getInt

  /**
   * <p>Get value for a INTEGER or NUMBER([1..11]) field<p>
   * @param sKey Field Name
   * @return Field value or <b>null</b>.
   * @throws NumberFormatException
   */

  public Integer getInteger(String sKey) throws NumberFormatException {
    Object oInt = getItemMap().get(sKey);

    if (null!=oInt)
      if (Integer.TYPE.equals(oInt.getClass()))
        return (Integer) oInt;
      else
        return new Integer(oInt.toString());
    else
      return null;
  } // getInteger

  /**
   * <p>Get value for a DATETIME field<p>
   * @param sKey Field Name
   * @return Date value or <b>null</b>.
   * @throws ClassCastException if sKey field is not of type DATETIME
   */

  public java.util.Date getDate(String sKey)
    throws ClassCastException {
    Object oDt = getItemMap().get(sKey);
    java.util.Date dDt = null;
    if (null!=oDt) {
      if (oDt.getClass().equals(ClassUtilDate))
    	dDt = (java.util.Date) oDt;
      else if (oDt.getClass().equals(ClassTimestamp))
        dDt = new java.util.Date(((java.sql.Timestamp) oDt).getTime());
      else if (oDt.getClass().equals(ClassSQLDate))
    	dDt = new java.util.Date(((java.sql.Date) oDt).getYear(), ((java.sql.Date) oDt).getMonth(), ((java.sql.Date) oDt).getDate());
      else if (oDt.getClass().equals(ClassLangString)) {
    	try {
    	  dDt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse((String) oDt);    	  
        } catch (java.text.ParseException pe) {
          throw new ClassCastException("Cannot parse Date " + oDt);
        }
      }
    }
    return dDt;
  } // getDate

  /**
   * <p>Get value for a DATETIME field<p>
   * @param sKey Field Name
   * @param dtDefault Date default value
   * @return Date value or default value.
   * @throws ClassCastException if sKey field is not of type DATETIME
   * @since 7.0
   */
  public java.util.Date getDate(String sKey, java.util.Date dtDefault) {
    java.util.Date dtRetVal;
    if (containsKey(sKey)) {
      dtRetVal = dtDefault;
    } else {
      dtRetVal = getDate(sKey);
      if (null==dtRetVal) dtRetVal = dtDefault;
    }
    return dtRetVal;
  }

  /**
   * <p>Get DATE formated as ccyy-MM-dd<p>
   * @param sKey Field Name
   * @throws ClassCastException if sKey field is not of type DATE
   * @return String value for Date or <b>null</b>.
   */

  public String getDateShort(String sKey)
    throws ClassCastException {
	java.util.Date dDt = getDate(sKey);
    if (null!=dDt) {
      int y = dDt.getYear()+1900, m=dDt.getMonth()+1, d=dDt.getDate();
      return String.valueOf(y)+"-"+(m<10 ? "0" : "")+String.valueOf(m)+"-"+(d<10 ? "0" : "")+String.valueOf(d);
    }
    else
      return null;
  } // getDateShort

  /**
   * <p>Get value for a DATE, DATETIME or TIMESTAMP field formated a String<p>
   * @param sKey Field Name
   * @param sFormat Date Format (like "yyyy-MM-dd HH:mm:ss")
   * @return Formated date or <b>null</b>.
   * @throws ClassCastException if sKey field is not of type DATE, DATETIME or TIMESTAMP
   * @see java.text.SimpleDateFormat
   */

  public String getDateFormated(String sKey, String sFormat)
    throws ClassCastException {
	java.util.Date oDt = getDate(sKey);
    SimpleDateFormat oSimpleDate;

    if (null!=oDt) {
      oSimpleDate = new SimpleDateFormat(sFormat);
      return oSimpleDate.format(oDt);
    }
    else
      return null;
  } // getDateFormated()

  /**
   * <p>Get value for a DATE, DATETIME or TIMESTAMP field formated a yyyy-MM-dd hh:mm:ss<p>
   * @param sKey String Field Name
   * @return String Formated date or <b>null</b>.
   * @throws ClassCastException if sKey field is not of type DATE
   * @since 3.0
   */
  public String getDateTime(String sKey) {
    return getDateFormated(sKey, "yyyy-MM-dd hh:mm:ss");
  } // getDateTime

  /**
   * <p>Get value for a DATE, DATETIME or TIMESTAMP field formated a yyyy-MM-dd HH:mm:ss<p>
   * @param sKey String Field Name
   * @return String Formated date or <b>null</b>.
   * @throws ClassCastException if sKey field is not of type DATE, DATETIME or TIMESTAMP
   * @since 3.0
   */
  public String getDateTime24(String sKey) {
    return getDateFormated(sKey, "yyyy-MM-dd HH:mm:ss");
  } // getDateTime24()


  /**
   * <p>Get value for a DATE field<p>
   * @param sKey Field Name
   * @return java.sql.Date
   * @throws ClassCastException if sKey field is not of type DATE, DATETIME or TIMESTAMP
   * @since 3.0
   */
  public java.sql.Date getSQLDate(String sKey)
    throws ClassCastException {
    java.sql.Date oRetVal;
    Object oObj = getItemMap().get(sKey);

    if (oObj==null) {
      oRetVal = null;
    } else {
      String sCls = oObj.getClass().getName();
      if (sCls.equals("java.sql.Date"))
        oRetVal = (java.sql.Date) oObj;
      else if (sCls.equals("java.util.Date"))
        oRetVal = new java.sql.Date(((java.util.Date)oObj).getTime());
      else if (sCls.equals("java.sql.Timestamp"))
        oRetVal = new java.sql.Date(((java.sql.Timestamp)oObj).getTime());
      else
        throw new ClassCastException("DBPersist.getSQLDate() Cannot cast "+sCls+" to java.sql.Date");
    }
    return oRetVal;
  } // getSQLDate

  /**
   * <p>Get value for a TIME field<p>
   * @param sKey Field Name
   * @return java.sql.Time
   * @throws ClassCastException
   * @since 3.0
   */
  public Time getSQLTime(String sKey)
    throws ClassCastException {
    java.sql.Time oRetVal;
    Object oObj = getItemMap().get(sKey);

    if (oObj==null) {
      oRetVal = null;
    } else {
      String sCls = oObj.getClass().getName();
      if (sCls.equals("java.sql.Time"))
        oRetVal = (java.sql.Time) oObj;
      else if (sCls.equals("java.util.Date"))
        oRetVal = new java.sql.Time(((java.util.Date)oObj).getTime());
      else if (sCls.equals("java.sql.Timestamp"))
        oRetVal = new java.sql.Time(((java.sql.Timestamp)oObj).getTime());
      else
        throw new ClassCastException("DBPersist.getSQLTime() Cannot cast "+sCls+" to java.sql.Time");
    }
    return oRetVal;
  } // getSQLTime

  /**
   * <p>Get time part of date as a String</p>
   * @param sKey Field Name
   * @return String HH24:MI:SS or <b>null</b>
   * @throws ClassCastException if sKey field is not of type DATE
   */
  public String getTime(String sKey)
    throws ClassCastException {
    Object oObj = getItemMap().get(sKey);

    if (oObj!=null) {
      java.util.Date oDt = (java.util.Date) oObj;
      return (oDt.getHours()<10 ? "0" : "")+String.valueOf(oDt.getHours())+":"+(oDt.getMinutes()<10 ? "0" : "")+String.valueOf(oDt.getMinutes())+(oDt.getSeconds()<10 ? "0" : "")+":"+String.valueOf(oDt.getSeconds());
    }
    else {
      return null;
    }
  } // getTime

  /**
   * <p>Get a part of an interval value</p>
   * This function only works for PostgreSQL
   * @param sKey String String Field Name
   * @param sPart String Currently, only "days" is allowed as interval part
   * @return int Number of days in the given interval
   * @throws NullPointerException if interval is <b>null</b>
   * @throws IllegalArgumentException is sPart is not "days"
   * @throws NumberFormatException if interval has no days
   * @since 3.0
   */
  public int getIntervalPart(String sKey, String sPart)
    throws NullPointerException, NumberFormatException, IllegalArgumentException {
    if (sPart==null) throw new IllegalArgumentException("DBPersist.getIntervalPart() interval part to get cannot be null");
    if (!sPart.equalsIgnoreCase("days")) throw new IllegalArgumentException("DBPersist.getIntervalPart() interval part to get must be 'days'");
    Object oObj = getItemMap().get(sKey);
    if (oObj==null) throw new NullPointerException("DBPersist.getIntervalPart() value of interval is null");
    String sTI = oObj.toString().toLowerCase();
    int iMons = sTI.indexOf("mons")<0 ? 0 : sTI.indexOf("mons")+4;
    int iDays = sTI.indexOf("days");
    if (iDays<0) return 0;
    return Integer.parseInt(Gadgets.removeChars(sTI.substring(iMons,iDays), " "));
  } // getIntervalPart

  /**
   * <p>Get value for a DATETIME or TIMESTAMP field<p>
   * @param sKey Field Name
   * @return Field value or <b>null</b>.
   */

  public Timestamp getTimestamp(String sKey) {
    Object oDt = getItemMap().get(sKey);

    if (null!=oDt)
      return new Timestamp(((java.util.Date) oDt).getTime());
    else
      return null;
  } // getTimestamp

  /**
   * <p>Get value for an _int4[] field<p>
   * @param sKey Field Name
   * @throws SQLException
   * @return Field value or <b>null</b>.
   * @since 7.0
   */

  public Integer[] getIntegerArray(String sKey) throws SQLException {
    Array oArr = (Array) getItemMap().get(sKey);

    if (null!=oArr) {
      return (Integer[]) oArr.getArray();
    } else {
      return null;    	
    }
  } // getIntegerArray

  /**
   * <p>Get value for an _int4[] field<p>
   * @param sKey Field Name
   * @throws SQLException
   * @return Field value or <b>null</b>.
   * @since 7.0
   */

  public int[] getIntArray(String sKey) throws SQLException {
    Array oArr = (Array) getItemMap().get(sKey);

    if (null!=oArr) {
      Integer[] aArr = (Integer[]) oArr.getArray();
      final int l = aArr.length;
      int[] aRetVal = new int[l];
      for (int a=0; a<l; a++)
        aRetVal[a] = aArr[a].intValue();
      return aRetVal;
    } else {
      return null;    	
    }
  } // getIntegerArray
  
  /**
   * @return Field Names Set
   * @deprecated Use keySet() instead
   */
  public Set getItems() {
    return getItemMap().keySet();
  }

  /**
   * @return Field Names Set
   * @since 2.2
   */
  public Set keySet() {
    return getItemMap().keySet();
  }

  /**
   * @return Values Map
   */
  public HashMap getItemMap() {
    return AllVals;
  }

  /**
   * @return Values Collection
   * @since 2.2
   */
  public Collection values() {
    return getItemMap().values();
  }

  /**
   * @return Field Values Set
   * @since 2.2
   */
  public Set entrySet() {
    return getItemMap().entrySet();
  }

  /**
   * @return Iterator for values stored in-memory at this DBPersist.
   */

  public Iterator iterator() {
    return getItemMap().values().iterator();
  }

  /**
   * Get audit class name
   * @return Name of base table for this DBPersist
   */

  public String getAuditClassName() {
    return sAuditCls;
  }

  /**
   * Get value of primary key field for this DBPersist record
   * @return Value contained at primary key field
   * @since 7.0
   */
  public String getPrimaryKey() {
  	Object oPkValue = get((String) getTable().getPrimaryKey().getFirst());
  	if (oPkValue==null)
  	  return null;
  	else
  	  return oPkValue.toString();
  }

  /**
   * Set value of primary key field for this DBPersist record
   * @return Value contained at primary key field
   * @since 7.0
   */
  public void setPrimaryKey(String sValue) throws NullPointerException {
  	if (null==sValue) throw new NullPointerException("DBPersist.setPrimaryKey() Value of primary key may not be null");
  	put((String) getTable().getPrimaryKey().getFirst(), sValue);
  }

  /**
   * @return {@link DBTable} object where data is stored
   * or <b>null</b> if the table does not exist at the database.
   * @deprecated Use {@link #getTable(JDCConnection) getTable(JDCConnection)} instead
   */

  public DBTable getTable() {
    if (null==oTable) {
      try {
        oTable = DBBind.getTable(getTableName());
      } catch (IllegalStateException ise) {
    	DBBind oDbb = new DBBind();
        oTable = DBBind.getTable(getTableName());
        oDbb.close();
      }
    }
    return oTable;
  } // getTable()

  /**
   * Get DBTable object witch holds this DBPersist registers.
   * @param oConn JDBC Database Connection
   * @return {@link DBTable} object where data is stored
   * or <b>null</b> if the table does not exist at the database.
   * @throws IllegalStateException DBPersist uses the internal static table map
   * from DBBind. The internal DBBind table map is loaded upon first call to
   * a DBBind constructor. Thus, if a DBPersist object is instantiated before
   * instantiating any DBBind object, the internal table map will not be
   * preloaded and an IllegalStateException will be raised.
   * @since 2.0
   */
  public DBTable getTable(JDCConnection oConn)
    throws SQLException, IllegalStateException {

    if (null==oTable) {
      JDCConnectionPool oPool = oConn.getPool();

      if (null==oPool) {
        if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL)
          oTable = new DBTable(oConn.getCatalog(), null, getTableName(), 1);
        else
          oTable = new DBTable(oConn.getCatalog(), oConn.getSchemaName(), getTableName(), 1);

        oTable.readColumns(oConn, oConn.getMetaData());
      }
      else {
        DBBind oBind = (DBBind) oPool.getDatabaseBinding();

        if (null==oBind)
          throw new IllegalStateException("Connection Pool for " + sAuditCls + " is not binded to the database.");
        else
         oTable = oBind.getDBTable(getTableName());
      }
    }
    return oTable;
  } // getTable

  /**
   * Test is a readed field was null.
   * @param sKey Field Name
   * @return <b>true</b> if readed field was null or if no field with given name
   * was found at internal collection.
   */

  public boolean isNull(String sKey) {
    boolean bIsNull = !getItemMap().containsKey(sKey);
    if (!bIsNull)
      bIsNull = getItemMap().get(sKey)==null;
    return bIsNull;
  }

  /**
   * <p>Load the internal value set from a register at a database table</p>
   * @param oConn Database Connection
   * @param PKVals Primary key values in order of appearance
   * @return <b>true</b> if a register was found, <b>false</b> if no register was
   * found with such primary key.
   * @throws SQLException
   */

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    if (oTable==null) {
      oTable = getTable(oConn);
      if (null==oTable) throw new SQLException("Table not found "+getTableName(),"42S02", 42002);
      return oTable.loadRegister(oConn, PKVals, AllVals);
    } else
      return oTable.loadRegister(oConn, PKVals, AllVals);
  }

  /**
   * <p>Load the internal value set from a register at a database table</p>
   * @param oConn JDCConnection
   * @param sKey String Primary key value
   * @return <b>true</b> if a register was found, <b>false</b> if no register was
   * found with such primary key.
   * @throws SQLException
   * @since 3.0
   */
  public boolean load(JDCConnection oConn, String sKey) throws SQLException {
    if (oTable==null) {
      oTable = getTable(oConn);
      if (null==oTable) throw new SQLException("Table not found "+getTableName(),"42S02", 42002);
      return oTable.loadRegister(oConn, new Object[]{sKey}, AllVals);
    } else
      return oTable.loadRegister(oConn, new Object[]{sKey}, AllVals);
  }

  /**
   * <p>Set value at internal collection</p>
   * If allcaps is set tu <b>true</b> then sVal is converted to uppercase
   * @param sKey Field Name
   * @param sVal Field Value
   * @throws NullPointerException If sKey is <b>null</b>
  */

  public void put(String sKey, String sVal) throws NullPointerException {
    if (sKey==null)
      throw new NullPointerException("DBPersist.put(String,String) field name cannot be null");
    if (null==sVal)
      AllVals.put(sKey, null);
    else if (bAllCaps) {
      if (sKey.startsWith("id_") ||
      	  sKey.startsWith("gu_") ||
      	  sKey.startsWith("tp_") ||
      	  sKey.equalsIgnoreCase(DB.tx_note) ||
      	  sKey.equalsIgnoreCase(DB.tx_email) ||
    	  sKey.equalsIgnoreCase(DB.tx_alt_email) ||
    	  sKey.equalsIgnoreCase(DB.tx_email_alt) ||
    	  sKey.equalsIgnoreCase(DB.tx_main_email) ||
    	  sKey.equalsIgnoreCase(DB.tx_email_to) ||
    	  sKey.equalsIgnoreCase(DB.tx_email_from) ||
		  sKey.equalsIgnoreCase(DB.tx_email_reply) ||
		  sKey.equalsIgnoreCase(DB.tx_cause) ||
		  sKey.equalsIgnoreCase(DB.tx_comments) ||
		  sKey.equalsIgnoreCase(DB.tx_remarks) ||
		  sKey.equalsIgnoreCase(DB.tx_bug_info) ||
		  sKey.equalsIgnoreCase(DB.tx_bug_brief) ||
		  sKey.equalsIgnoreCase(DB.nm_attr) ||
		  sKey.equalsIgnoreCase(DB.nm_class) ||
		  sKey.equalsIgnoreCase(DB.nm_domain) ||
		  sKey.equalsIgnoreCase(DB.nm_mailing) ||
		  sKey.equalsIgnoreCase(DB.nm_microsite) ||
		  sKey.equalsIgnoreCase(DB.nm_workarea) ||
		  sKey.equalsIgnoreCase(DB.nm_zone))		  	
        AllVals.put(sKey, sVal);
      else
        AllVals.put(sKey, sVal.toUpperCase());
    }
    	     
    else
      AllVals.put(sKey, sVal);
  }

  /**
   * <p>Set value at internal collection</p>
   * @param sKey Field Name
   * @param oObj Field Value
   * @throws NullPointerException If sKey is <b>null</b>
   */

  public void put(String sKey, Object oObj) throws NullPointerException {

    if (sKey==null)
      throw new NullPointerException("DBPersist.put(String,Object) field name cannot be null");

	if (null==oObj) {
      AllVals.put(sKey, null);
	} else {
      DBColumn oCol = getTable().getColumnByName(sKey);
      if (oCol!=null) {
	    if (oCol.getSqlType()==java.sql.Types.BINARY || oCol.getSqlType()==java.sql.Types.VARBINARY || oCol.getSqlType()==java.sql.Types.LONGVARBINARY) {
	      Class[] aInts = oObj.getClass().getInterfaces();
	      if (null==aInts) {
            AllVals.put(sKey, oObj);
	      } else {
	      	boolean bIsSerializable = false;
	      	for (int i=0; i<aInts.length && !bIsSerializable; i++)
	      	  bIsSerializable |= aInts[i].getName().equals("java.io.Serializable");
	      	if (bIsSerializable) {
	      	  try {
                ByteArrayOutputStream oBOut = new ByteArrayOutputStream();
			    ObjectOutputStream oOOut = new ObjectOutputStream(oBOut);
			    oOOut.writeObject(oObj);
			    put(sKey, oBOut.toByteArray());
			    oOOut.close();
			    oBOut.close();              
	      	  } catch (IOException neverthrown) { }
	      	} else {
              AllVals.put(sKey, oObj);
	      	}
	      }
	    } else {
          AllVals.put(sKey, oObj);
	    }
      } else {
        AllVals.put(sKey, oObj);
      }
	}
  }

  /**
   * <p>Set Short value at internal collection</p>
   * If internal collection previously contained a mapping for this key, the old value is replaced.
   * @param sKey Field Name
   * @param oObj Short Value
   * @throws NullPointerException If sKey is <b>null</b>
   * @since 7.0
   */

  public void put(String sKey, Short oShr) throws NullPointerException {
    if (sKey==null)
      throw new NullPointerException("DBPersist.put(String,Short) field name cannot be null");
    if (null==oShr)
      AllVals.put(sKey, null);
    else
      AllVals.put(sKey, oShr);
  }

  /**
   * <p>Set Integer value at internal collection</p>
   * If internal collection previously contained a mapping for this key, the old value is replaced.
   * @param sKey Field Name
   * @param oObj Integer Value
   * @throws NullPointerException If sKey is <b>null</b>
   * @since 7.0
   */

  public void put(String sKey, Integer oInt) throws NullPointerException {
    if (sKey==null)
      throw new NullPointerException("DBPersist.put(String,Integer) field name cannot be null");
    if (null==oInt)
      AllVals.put(sKey, null);
    else
      AllVals.put(sKey, oInt);
  }

  /**
   * <p>Set Float value at internal collection</p>
   * If internal collection previously contained a mapping for this key, the old value is replaced.
   * @param sKey Field Name
   * @param oObj Float Value
   * @throws NullPointerException If sKey is <b>null</b>
   * @since 7.0
   */

  public void put(String sKey, Float oFlt) throws NullPointerException {
    if (sKey==null)
      throw new NullPointerException("DBPersist.put(String,Float) field name cannot be null");
    if (null==oFlt)
      AllVals.put(sKey, null);
    else
      AllVals.put(sKey, oFlt);
  }

  /**
   * <p>Set Double value at internal collection</p>
   * If internal collection previously contained a mapping for this key, the old value is replaced.
   * @param sKey Field Name
   * @param oObj Double Value
   * @throws NullPointerException If sKey is <b>null</b>
   * @since 7.0
   */

  public void put(String sKey, Double oDbl) throws NullPointerException {
    if (sKey==null)
      throw new NullPointerException("DBPersist.put(String,Double) field name cannot be null");
    if (null==oDbl)
      AllVals.put(sKey, null);
    else
      AllVals.put(sKey, oDbl);
  }

  /**
   * <p>Set value at internal collection</p>
   * If internal collection previously contained a mapping for this key, the old value is replaced.
   * @param sKey Field Name
   * @param oObj Field Value
   * @return previous value associated with specified key, or null if there was no mapping for key
   * @throws NullPointerException If sKey is <b>null</b>
   * @since 2.2
   */

  public Object put(Object sKey, Object oObj) throws NullPointerException {
    Object oPrevious;
    if (sKey==null)
      throw new NullPointerException("DBPersist.put(Object,Object) field name cannot be null");
    if (AllVals.containsKey(sKey)) {
      oPrevious = AllVals.get(sKey);
      AllVals.remove(sKey);
    } else {
      oPrevious = null;
    }
	if (null==oObj) {
      AllVals.put(sKey, null);
	} else {
	  if (oObj instanceof String || oObj instanceof Short || oObj instanceof Integer || oObj instanceof Float || oObj instanceof Double || oObj instanceof BigDecimal || oObj instanceof Date || oObj instanceof Timestamp) {
		  AllVals.put(sKey, oObj);  
	  } else {
	      DBColumn oCol = getTable().getColumnByName(sKey.toString());
	      if (oCol!=null) {
		    if (oCol.getSqlType()==java.sql.Types.BINARY || oCol.getSqlType()==java.sql.Types.VARBINARY || oCol.getSqlType()==java.sql.Types.LONGVARBINARY) {
		      Class[] aInts = oObj.getClass().getInterfaces();
		      if (null==aInts) {
	            AllVals.put(sKey, oObj);
		      } else {
		      	boolean bIsSerializable = false;
		      	for (int i=0; i<aInts.length && !bIsSerializable; i++)
		      	  bIsSerializable |= aInts[i].getName().equals("java.io.Serializable");
		      	if (bIsSerializable) {
		      	  try {
	                ByteArrayOutputStream oBOut = new ByteArrayOutputStream();
				    ObjectOutputStream oOOut = new ObjectOutputStream(oBOut);
				    oOOut.writeObject(oObj);
				    byte[] aBytes = oBOut.toByteArray();
				    if (aBytes!=null) {
	    			  if (!bHasLongVarBinaryData) LongVarBinaryValsLen = new HashMap();
	    			  LongVarBinaryValsLen.put(sKey, new Long(aBytes.length));
	    			  AllVals.put(sKey, aBytes);
	    			  bHasLongVarBinaryData = true;
				    }
				    oOOut.close();
				    oBOut.close();              
		      	  } catch (IOException neverthrown) { }
		      	} else {
	              AllVals.put(sKey, oObj);
		      	}
		      }
		    } else {
	          AllVals.put(sKey, oObj);
		    }
	      } else {
	        AllVals.put(sKey, oObj);
	      } // fi		  
	  }
	}
    return oPrevious;
  }

  /**
   * <p>Set value at internal collection</p>
   * @param sKey Field Name
   * @param iVal Field Value
   * @since 7.0
   */

  public void put(String sKey, byte byVal) {
    AllVals.put(sKey, new Byte(byVal));
  }

  /**
   * <p>Set value at internal collection</p>
   * @param sKey Field Name
   * @param iVal Field Value
   */

  public void put(String sKey, int iVal) {
    AllVals.put(sKey, new Integer(iVal));
  }
  
  /**
   * <p>Set value at internal collection</p>
   * @param sKey Field Name
   * @param iVal Field Value
   */

  public void put(String sKey, short iVal) {
    AllVals.put(sKey, new Short(iVal));
  }

  /**
   * <p>Set value at internal collection</p>
   * @param sKey Field Name
   * @param dtVal Field Value
   */

  public void put(String sKey, Date dtVal) {
    AllVals.put(sKey, dtVal);
  }

  /**
   * <p>Set value at internal collection</p>
   * @param sKey Field Name
   * @param tmVal Field Value
   * @since 3.0
   */

  public void put(String sKey, Time tmVal) {
    AllVals.put(sKey, tmVal);
  }

  /**
   * Put Date value using specified format
   * @param sKey String Field Name
   * @param sDate String Field Value as String
   * @param oPattern SimpleDateFormat Date format to be used
   * @since 3.0
   */
  public void put(String sKey, String sDate, SimpleDateFormat oPattern)
    throws ParseException {
    AllVals.put(sKey, oPattern.parse(sDate));
  }

  /**
   * <p>Put double value at internal collection</p>
   * @param sKey Field Name
   * @param dVal Field Value
   */

  public void put(String sKey, double dVal) {
    AllVals.put(sKey, new Double(dVal));
  }

  /**
   * <p>Put BigDecimal value at internal collection</p>
   * @param sKey Field Name
   * @param oDecVal Field Value
   */

  public void put(String sKey, BigDecimal oDecVal) {
    AllVals.put(sKey, oDecVal);
  }

  /**
   * Parse BigDecimal value and put it at internal collection
   * @param sKey String Field Name
   * @param sDecVal Field Name as String
   * @param oPattern DecimalFormat
   * @throws ParseException
   * @since 3.0
   */
  public void put(String sKey, String sDecVal, DecimalFormat oPattern)
    throws ParseException {
    AllVals.put(sKey, oPattern.parse(sDecVal));
  }

  /**
   * <p>Put float value at internal collection</p>
   * @param sKey Field Name
   * @param fVal Field Value
   */

  public void put(String sKey, float fVal) {
    AllVals.put(sKey, new Float(fVal));
  }

  /**
   * <p>Put Money value at internal collection</p>
   * @param sKey Field Name
   * @param mVal Field Value
   * @since 3.0
   */

  public void put(String sKey, Money mVal) {
    if (null==mVal)
      AllVals.put(sKey, null);
    else
      AllVals.put(sKey, mVal.toString());
  }

  /**
   * <p>Set reference to a binary file for a long field</p>
   * @param sKey Field Name
   * @param oFile File Object
   * @throws FileNotFoundException
   */

  public void put(String sKey, File oFile) throws FileNotFoundException {
    if (!bHasLongVarBinaryData) LongVarBinaryValsLen = new HashMap();

    LongVarBinaryValsLen.put(sKey, new Long(oFile.length()));

    AllVals.put(sKey, oFile);

    bHasLongVarBinaryData = true;
  } // put

  /**
   * <p>Set reference to a byte array for a long field</p>
   * <p>Use this method only for binding LONGVARBINARY or BLOB fields</p>
   * @param sKey Field Name
   * @param aBytes byte array
   */

  public void put(String sKey, byte[] aBytes) {
    if (!bHasLongVarBinaryData) LongVarBinaryValsLen = new HashMap();

    LongVarBinaryValsLen.put(sKey, new Long(aBytes.length));

    AllVals.put(sKey, aBytes);

    bHasLongVarBinaryData = true;
  } // put

  /**
   * <p>Set reference to a character array for a long field</p>
   * <p>Use this method only for binding LONGVARCHAR or CLOB fields</p>
   * @param sKey Field Name
   * @param aChars char array
   */

  public void put(String sKey, char[] aChars) {
    if (!bHasLongVarBinaryData) LongVarBinaryValsLen = new HashMap();

    LongVarBinaryValsLen.put(sKey, new Long(aChars.length));

    AllVals.put(sKey, aChars);

    bHasLongVarBinaryData = true;
  } // put

  /**
   * <p>Put Array value at internal collection</p>
   * @param sKey Field Name
   * @param aVal Field Value
   * @since 7.0
   */
  public void put(String sKey, Array aVal) {    
	AllVals.put(sKey, aVal);
  }
  
  /**
   * <p>Set value at internal collection</p>
   * @param sKey Field Name
   * @param sData Field Value as a String. If iSQLType is BLOB or LONGVARBINARY
   * then sData is interpreted as a full file path uri.
   * @param iSQLType SQL Type for field
   * @throws NullPointerException If sKey is <b>null</b>
   * @throws IllegalArgumentException If SQL Type is not recognized.
   * Recognized types are { CHAR, VARCHAR, LONGVARCHAR, CLOB, INTEGER, SMALLINT,
   * DATE, TIMESTAMP, DOUBLE, FLOAT, REAL, DECIMAL, NUMERIC, BLOB, LONGVARBINARY }
   */

  public void put(String sKey, String sData, int iSQLType)
    throws FileNotFoundException, IllegalArgumentException, NullPointerException {
    int iDecDot;

    if (sKey==null)
      throw new NullPointerException("DBPersist.put(String,String,int) field name cannot be null");

    switch (iSQLType) {
      case java.sql.Types.VARCHAR:
      case java.sql.Types.LONGVARCHAR:
      case java.sql.Types.CHAR:
      case java.sql.Types.CLOB:
        if (null==sData)
          AllVals.put(sKey, null);
        else if (bAllCaps)
          AllVals.put(sKey, sData.toUpperCase());
        else
          AllVals.put(sKey, sData);
        break;
      case java.sql.Types.INTEGER:
        AllVals.put(sKey, new Integer(sData));
        break;
      case java.sql.Types.SMALLINT:
        AllVals.put(sKey, new Short(sData));
        break;
      case java.sql.Types.DATE:
        if (null != sData)
          AllVals.put(sKey, java.sql.Date.valueOf(sData));
        else
          AllVals.put(sKey, null);
        break;
      case java.sql.Types.TIME:
        if (null != sData)
          AllVals.put(sKey, java.sql.Time.valueOf(sData));
        else
          AllVals.put(sKey, null);
        break;
      case java.sql.Types.TIMESTAMP:
      	long lTime = 0l;
      	try {      		
      	  SimpleDateFormat oSfmt = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
      	  lTime = oSfmt.parse(sData).getTime();
      	} catch (IllegalArgumentException id) {
          throw new IllegalArgumentException("DBPersist.put() IllegalArgumentException Can't parse Date "+sData+" for SQL Type TIMESTAMP");
      	} catch (ParseException pe) {
          throw new IllegalArgumentException("DBPersist.put() IllegalArgumentException Can't parse Date "+sData+" for SQL Type TIMESTAMP");
      	}      	
        if (null != sData)
          AllVals.put(sKey, new java.sql.Timestamp(lTime));
        else
          AllVals.put(sKey, null);
        break;
      case java.sql.Types.DOUBLE:
      case java.sql.Types.FLOAT:
        AllVals.put(sKey, new Double(sData));
        break;
      case java.sql.Types.REAL:
        AllVals.put(sKey, new Float(sData));
        break;
      case java.sql.Types.DECIMAL:
      case java.sql.Types.NUMERIC:
        iDecDot = sData.indexOf(".");
        if (iDecDot < 0) iDecDot = sData.indexOf(",");
        if (iDecDot < 0)
          AllVals.put(sKey, new BigDecimal(sData));
        else
          AllVals.put(sKey,
                      BigDecimal.valueOf(Long.parseLong(sData.substring(0, iDecDot)),
                                         Integer.parseInt(sData.substring(iDecDot +
              1))));
        break;
      case java.sql.Types.LONGVARBINARY:
      case java.sql.Types.BLOB:
        if (!bHasLongVarBinaryData) LongVarBinaryValsLen = new HashMap();

        File oFile = new File(sData);
        if (oFile.exists()) {
          LongVarBinaryValsLen.put(sKey, new Long(oFile.length()));
          AllVals.put(sKey, oFile);
        }
        bHasLongVarBinaryData = true;
        break;
      case 1111: // PostgreSQL interval
        if (DebugFile.trace) DebugFile.writeln("Binding interval "+sData);
        try {
          Class cPGIntval = Class.forName("org.postgresql.util.PGInterval");
          java.lang.reflect.Constructor cNewPGInt = null;
          Object oPGIntval;
          try {
            cNewPGInt = cPGIntval.getConstructor(new Class[]{String.class});
          } catch (NoSuchMethodException neverthrown) {}
          try {
            oPGIntval = cNewPGInt.newInstance(new Object[]{sData});
            AllVals.put(sKey, oPGIntval);
          } catch (InstantiationException neverthrown) {}
            catch (IllegalAccessException neverthrown) {}
            catch (java.lang.reflect.InvocationTargetException neverthrown) {}
        } catch (ClassNotFoundException cnfe) {
          throw new IllegalArgumentException("DBPersist.put() ClassNotFoundException org.postgresql.util.PGInterval");
        }
        if (DebugFile.trace) DebugFile.writeln("Interval successfully binded");
        break;
    } // end switch
  } // put

  /**
   * <p>Load values from a Properties object</p>
   */

  public void putAll(Properties oPropsCollection) throws FileNotFoundException {

	if (DebugFile.trace) {
      DebugFile.writeln("Begin DBPersist.putAll(Properties["+String.valueOf(oPropsCollection.size())+"])");
	  DebugFile.incIdent();
	}

    Iterator oIter = getTable().getColumns().iterator();
    DBColumn oDBCol;
    String sColName;
    String sPropValue;

    while (oIter.hasNext()) {
      oDBCol = (DBColumn) oIter.next();
      sColName = oDBCol.getName();
      sPropValue = oPropsCollection.getProperty(sColName);

      if (null!=sPropValue) {
        if (sPropValue.trim().length()>0) {
          switch(oDBCol.getSqlType()) {
            case java.sql.Types.INTEGER:
              replace(sColName, new Integer(sPropValue));
              break;
            case java.sql.Types.SMALLINT:
              replace(sColName, new Short(sPropValue));
              break;
            case java.sql.Types.DOUBLE:
            case java.sql.Types.REAL:
              replace(sColName, new Double(sPropValue));
              break;
            case java.sql.Types.FLOAT:
              replace(sColName, new Float(sPropValue));
              break;
            case java.sql.Types.NUMERIC:
            case java.sql.Types.DECIMAL:
              replace(sColName, new java.math.BigDecimal(sPropValue));
              break;
            default:
              put(sColName, sPropValue, oDBCol.getSqlType());
          } // end switch
        } // fi (s!="")
        else  if (!isNull(sColName))
          replace(sColName, null);
      } // fi (s!=null)
    } // wend

	if (DebugFile.trace) {
	  DebugFile.decIdent();
      DebugFile.writeln("End DBPersist.putAll()");
	}
  } // putAll()

  /**
   * <p>Put values from a Map into this DBPersist instance</p>
   * allcaps has no effect on input data when calling this method
   * @param oMap
   * @since 2.2
   */
  public void putAll(Map oMap) {

	if (DebugFile.trace) {
      DebugFile.writeln("Begin DBPersist.putAll(Map["+String.valueOf(oMap.size())+"])");
	  DebugFile.incIdent();
	}

    Iterator oIter = oMap.keySet().iterator();
    while (oIter.hasNext()){
      String sKey = oIter.next().toString();
      AllVals.put(sKey, oMap.get(sKey));
	  if (DebugFile.trace) DebugFile.writeln("set "+sKey+"="+oMap.get(sKey));
    } // wend

	if (DebugFile.trace) {
	  DebugFile.decIdent();
      DebugFile.writeln("End DBPersist.putAll()");
	}
  } // putAll

  /**
   * <p>Remove a value from internal collection</p>
   * @param sKey Field Name
   */

  public void remove(String sKey) {
    if (AllVals.containsKey(sKey)) AllVals.remove(sKey);
  }

  /**
   * <p>Remove a value from internal collection</p>
   * @param oKey Field Name
   * @return Object previos value associated with given field name
   * @since 2.2
   */

  public Object remove(Object oKey) {
    Object oPrevious;
    if (AllVals.containsKey(oKey)) {
      oPrevious = AllVals.get(oKey);
      AllVals.remove(oKey);
    } else {
      oPrevious = null;
    }
    return oPrevious;
  }

  /**
   * <p>Replace a value from internal collection</p>
   * @param sKey Field Name
   * @param oObj New Value
   */
  public void replace(String sKey, Object oObj) {
    remove(sKey);

    AllVals.put(sKey, oObj);
  }

  /**
   * <p>Replace a value from internal collection</p>
   * @param sKey Field Name
   * @param iVal New int value
   */

  public void replace(String sKey, int iVal) {
    Integer oObj = new Integer(iVal);

    remove(sKey);

    AllVals.put(sKey, oObj);
  }

  /**
   * <p>Replace a value from internal collection</p>
   * @param sKey Field Name
   * @param iVal New short value
   */

  public void replace(String sKey, short iVal) {
    Short oObj = new Short(iVal);

    remove(sKey);

    AllVals.put(sKey, oObj);
  }

  /**
   * <p>Replace a value from internal collection</p>
   * @param sKey Field Name
   * @param fVal New float value
   */

  public void replace(String sKey, float fVal) {
    Float oObj = new Float(fVal);

    remove(sKey);

    AllVals.put(sKey, oObj);
  }

  /**
   * <p>Replace a value from internal collection</p>
   * @param sKey Field Name
   * @param dVal New double value
   * @since 4.0
   */

  public void replace(String sKey, double dVal) {
    Double oObj = new Double(dVal);

    remove(sKey);

    AllVals.put(sKey, oObj);
  }

  /**
   * <p>Replace a value from internal collection</p>
   * @param sKey Field Name
   * @param mVal New Money value
   * @since 4.0
   */
  public void replace(String sKey, Money mVal) {
    remove(sKey);

    if (null==mVal)
      AllVals.put(sKey, null);
    else
      AllVals.put(sKey, mVal.toString());
  }

  /**
   * Replace Date value using specified format
   * @param sKey String Field Name
   * @param sDate String Field Value as String
   * @param oPattern SimpleDateFormat Date format to be used
   * @since 4.0
   */
  public void replace(String sKey, String sDate, SimpleDateFormat oPattern)
    throws ParseException {
    remove(sKey);
    AllVals.put(sKey, oPattern.parse(sDate));
  }

  /**
   * <p>Replace value at internal collection</p>
   * @param sKey Field Name
   * @param sData Field Value as a String. If iSQLType is BLOB or LONGVARBINARY
   * then sData is interpreted as a full file path uri.
   * @param iSQLType SQL Type for field
   * @throws NullPointerException If sKey is <b>null</b>
   * @throws IllegalArgumentException If SQL Type is not recognized.
   * Recognized types are { CHAR, VARCHAR, LONGVARCHAR, CLOB, INTEGER, SMALLINT,
   * DATE, TIMESTAMP, DOUBLE, FLOAT, REAL, DECIMAL, NUMERIC, BLOB, LONGVARBINARY }
   * @since 5.0
   */

  public void replace(String sKey, String sData, int iSQLType)
    throws FileNotFoundException, IllegalArgumentException, NullPointerException {
    remove(sKey);
    put(sKey, sData, iSQLType);
  }
    
  /**
   * Convert value kept with given key to lowercase
   * @param sKey String
   * @since 3.0
   */

  public void toLowerCase(String sKey) {
    if (!isNull(sKey))
      replace (sKey, getString(sKey).toLowerCase());
  }

  /**
   * Convert value kept with given key to uppercase
   * @param sKey String
   * @since 3.0
   */

  public void toUpperCase(String sKey) {
    if (!isNull(sKey))
      replace (sKey, getString(sKey).toUpperCase());
  }

  /**
   * <p>Store a register at database representing this instance of DBPersist</p>
   * <p><b>Insertions and updates</b> : The store method automatically manages
   * register insertions and updates. If the stored object already exists at
   * database then it is updated, if it does not exists then it is inserted.
   * A primary key violation error is never thrown so ther is no need to call
   * delete() method before re-writing an existing object.</p>
   * <p><b>NULL fields</b> : All values not set calling put() methods for DBPersist
   * will be assumed to be NULL. If a not nullable field is not set then an
   * SQLException will be raised.<br>
   * On storing an already existing object all values will we overwrited,
   * so is a DBPersist is not fully loaded before storing it, values not set
   * by calling put() methods that already were present at database will be lost.</p>
   * @param oConn Database Connection
   * @return boolean <b>true</b> if register was stored for the first time,
   * <b>false</b> if register already existed.
   * @throws SQLException
   */

  public boolean store(JDCConnection oConn) throws SQLException {
    boolean bRetVal;

    if (bHasLongVarBinaryData) {
      try {
        if (oTable==null) {
          oTable = getTable(oConn);
          if (null==oTable) throw new SQLException("Table not found "+getTableName(),"42S02", 42002);
          bRetVal = oTable.storeRegisterLong(oConn, AllVals, LongVarBinaryValsLen);
        } else
          bRetVal = oTable.storeRegisterLong(oConn, AllVals, LongVarBinaryValsLen);
      }
      catch (IOException ioe) {
        throw new SQLException(ioe.getMessage(),"40001",40001);
      }
      finally {
        LongVarBinaryValsLen.clear();
        bHasLongVarBinaryData = false;
      }
    }
    else
      if (oTable==null) {
        oTable = getTable(oConn);
        if (null==oTable) throw new SQLException("Table not found "+getTableName(),"42S02", 42002);
        bRetVal = oTable.storeRegister(oConn, AllVals);
      } else
        bRetVal = oTable.storeRegister(oConn, AllVals);

    return bRetVal;
  } // store()

  /**
   * <p>Delete a register from database</p>
   * <p>The deleted register will be the one matching this DBPersist primary key,
   * as set at constructor or load() method.</p>
   * @param oConn Database connection
   * @return <b>true</b> if register was successfully erased, <b>false</b> if not.
   * @throws SQLException
   */

  public boolean delete(JDCConnection oConn) throws SQLException {
    boolean bRetVal;

    if (null==oTable) {
      oTable = getTable(oConn);
      if (null==oTable) throw new SQLException("Table not found "+getTableName(),"42S02", 42002);
      bRetVal = oTable.deleteRegister(oConn, AllVals);
    } else
      bRetVal = oTable.deleteRegister(oConn, AllVals);

    return bRetVal;
  } // delete()

  /**
   * <p>Find out whether or not a particular register exists at database</p>
   * @param oConn database connection
   * @return <b>true</b> if a register exists a DBPersist base table witch
   * primary key coincides with the one set in memory for the DBPersist.
   * @throws SQLException
   */

  public boolean exists(JDCConnection oConn) throws SQLException {
    if (null==oTable) {
      oTable = getTable(oConn);
      if (null==oTable) throw new SQLException("Table not found "+getTableName(),"42S02", 42002);
      return oTable.existsRegister(oConn, AllVals);
    } else
      return oTable.existsRegister(oConn, AllVals);
  }

  /**
   * <p>Get an XML dump for the DBPersist values</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @param sDelim Line delimiter (usually "\n" or "\r\n")
   * @param oAttrs Map of values to be added as attributes of the toplevel node
   * @return XML String
   * @throws IllegalStateException If XML method is invoked before DBPersist object is loaded
   * @since 3.0
   */

  protected String toXML(String sIdent, String sDelim, HashMap oAttrs)

    throws IllegalStateException {

    if (null==oTable)
      throw new IllegalStateException("DBPersist.toXML() method invoked before load() method was called");

    StringBuffer oBF = new StringBuffer(80*oTable.columnCount());
    ListIterator oIT = oTable.getColumns().listIterator();
    DBColumn oColumn;
    Object oColValue;
    String sColName;
    String sStartElement = sIdent + sIdent + "<";
    String sEndElement = ">" + sDelim;
    Class oColClass, ClassString = null, ClassDate = null;
    SimpleDateFormat oXMLDate = new SimpleDateFormat("yyyy-MM-dd'T'hh:mm:ss");

    try {
      ClassString = Class.forName("java.lang.String");
      ClassDate = Class.forName("java.util.Date");
    } catch (ClassNotFoundException ignore) { }

    if (null==oAttrs) {
      oBF.append(sIdent + "<" + sAuditCls + ">" + sDelim);
    } else {
      oBF.append(sIdent + "<" + sAuditCls);
      Iterator oNames = oAttrs.keySet().iterator();
      while (oNames.hasNext()) {
        Object oName = oNames.next();
        oBF.append(" "+oName+"=\""+oAttrs.get(oName)+"\"");
      } // wend
      oBF.append(">" + sDelim);
    } // fi

    while (oIT.hasNext()) {
      oColumn = (DBColumn) oIT.next();
      sColName = oColumn.getName();
      oColValue = getItemMap().get(sColName);

      oBF.append(sStartElement);
      oBF.append(sColName);
      oBF.append(">");
      if (null!=oColValue) {
        oColClass = oColValue.getClass();
        if (oColClass.equals(ClassString))
          oBF.append("<![CDATA[" + oColValue + "]]>");
        else if (oColClass.equals(ClassDate))
          oBF.append(oXMLDate.format((java.util.Date) oColValue));
        else
          oBF.append(oColValue);
      }
      oBF.append("</");
      oBF.append(sColName);
      oBF.append(sEndElement);
    } // wend

    oBF.append(sIdent + "</" + sAuditCls + ">");

    return oBF.toString();
  } // toXML

  /**
   * <p>Get an XML dump for the DBPersist values</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @param sDelim Line delimiter (usually "\n" or "\r\n")
   * @return XML String
   @ @throws IllegalStateException If XML method is invoked before DBPersist object is loaded
   */

  public String toXML(String sIdent, String sDelim)
    throws IllegalStateException {
    return toXML(sIdent, sDelim, null);
  }

  /**
   * <p>Get an XML dump for the DBPersist values.</p>
   * <p>Lines are delimited by a single Line Feed CHR(10) '\n' character.</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @return XML String
   */

  public String toXML(String sIdent) {
    return toXML(sIdent, "\n", null);
  }

  /**
   * <p>Get an XML dump for the DBPersist values.</p>
   * <p>No left padding is placed to the left of each line.</p>
   * <p>Lines are delimited by a single Line Feed CHR(10) '\n' character.</p>
   * @return XML String
   */

  public String toXML() {
    return toXML("", "\n", null);
  }

  /**
   * <p>Load an XML String into DBPersist internal collection.</p>
   * <p>Each tag <field>...</field> found will be stored as a DBPersist value.</p>
   * <p>Example of input file:<br>
   * &lt;?xml version="1.0" encoding="ISO-8859-1"?&gt;<br>
   * &lt;ACLUser&gt;<br>
   * &nbsp;&nbsp;&lt;gu_user&gt;32f4f56fda343a5898c15a021203dd82&lt;/gu_user&gt;<br>
   * &nbsp;&nbsp;&lt;id_domain&gt;1026&lt;/id_domain&gt;<br>
   * &nbsp;&nbsp;&lt;nm_user&gt;The 7th Guest&lt;/nm_user&gt;<br>
   * &nbsp;&nbsp;&lt;tx_pwd&gt;123456&lt;/tx_pwd&gt;<br>
   * &nbsp;&nbsp;&lt;tx_main_email&gt;guest7@domain.com&lt;/tx_main_email&gt;<br>
   * &nbsp;&nbsp;&lt;tx_alt_email&gt;admin@hipergate.com&lt;/tx_alt_email&gt;<br>
   * &nbsp;&nbsp;&lt;dt_last_updated&gt;Fri, 29 Aug 2003 13:30:00 GMT+0130&lt;/dt_last_updated&gt;<br>
   * &nbsp;&nbsp;&lt;tx_comments&gt;&lt;![CDATA[Sôme ñasti & ïnternational chars stuff]]&gt;&lt;/tx_comments&gt;<br>
   * &lt;/ACLUser&gt;</p>
   * @param sXMLFilePath XML Path to XML file to parse
   * @throws SAXException
   * @throws SAXNotRecognizedException
   * @throws SAXNotSupportedException
   * @throws SAXParseException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   * @throws InstantiationException
   */

  public void parseXML(String sXMLFilePath) throws SAXException,SAXNotRecognizedException,SAXNotSupportedException,SAXParseException,IOException,ClassNotFoundException,IllegalAccessException,InstantiationException {
    DBSaxHandler oHandler = new DBSaxHandler(this);
    oHandler.parse(sXMLFilePath);
  }

  /**
   * Compares two objects and returns a Map of their differences
   * @param oOldInstance DBPersist
   * @return HashMap
   */
  protected HashMap changelog(DBPersist oOldInstance) {
    Object oKey, oOld, oNew;
    HashMap oLog = new HashMap(size()*2);

    // Iterate throught this instance and see what keys are different at oOldInstance
    Iterator oKeys = keySet().iterator();
    while (oKeys.hasNext()) {
      oKey = oKeys.next();
      oNew = get(oKey);
      oOld = oOldInstance.get(oKey);
      if (null!=oNew) {
        if (!oNew.equals(oOld)) oLog.put(oKey, oOld);
      } else if (oOld!=null) {
        oLog.put(oKey, oOld);
      }
    } // wend

    // Iterate throught oOldInstance and see what keys are different at this instance
    oKeys = oOldInstance.keySet().iterator();
    while (oKeys.hasNext()) {
      oKey = oKeys.next();
      if (!containsKey(oKey)) {
        oOld = oOldInstance.get(oKey);
        oLog.put(oKey, oOld);
      }
    } // wend
    return oLog;
  } // changelog

  /**
   * <p>Internal method for being called by inherited classes</p>
   * <p>Searches an object instance GUID from its unique name</p>
   * @param oConn Database Connection
   * @param iDomainId Domain Identifier
   * @param sInstanceNm Instance Name
   * @param sStoredProc Stored Procedure or PL/pgSQL Function Name
   * @return Global Unique Identifier of instance been searched or <n>null</n>
   * if no instance was found with such name.
   * @throws SQLException
   */

  protected static String getUIdFromName(JDCConnection oConn, Integer iDomainId, String sInstanceNm, String sStoredProc) throws SQLException {
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;

    String sInstanceId;

    if (null==iDomainId) {
      if (JDCConnection.DBMS_POSTGRESQL==oConn.getDataBaseProduct()) {
        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT " + sStoredProc + "('" + sInstanceNm + "')");

        oStmt = oConn.prepareStatement("SELECT " + sStoredProc + "(?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sInstanceNm);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sInstanceId = oRSet.getString(1);
        else
          sInstanceId = null;
        oRSet.close();
        oStmt.close();
      }
      else {
        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call " + sStoredProc + " ('" + sInstanceNm + "',?)})");

        oCall = oConn.prepareCall("{ call " + sStoredProc + " (?,?)}");

        oCall.setString(1, sInstanceNm);
        oCall.registerOutParameter(2, java.sql.Types.CHAR);

        oCall.execute();

        sInstanceId = oCall.getString(2);

        if (JDCConnection.DBMS_ORACLE==oConn.getDataBaseProduct() && null!=sInstanceId)
          sInstanceId = sInstanceId.trim();

        oCall.close();
        oCall = null;
      }
    }
    else {
      if (JDCConnection.DBMS_POSTGRESQL==oConn.getDataBaseProduct()) {
        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT " + sStoredProc + "(" + iDomainId.toString() + ",'" + sInstanceNm + "')");

        oStmt = oConn.prepareStatement("SELECT " + sStoredProc + "(?,?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setInt(1, iDomainId.intValue());
        oStmt.setString(2, sInstanceNm);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sInstanceId = oRSet.getString(1);
        else
          sInstanceId = null;
        oRSet.close();
        oStmt.close();
      }
      else {
        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareCall({ call " + sStoredProc + " (" + iDomainId.toString() + ",'" + sInstanceNm + "',?)})");

        oCall = oConn.prepareCall("{ call " + sStoredProc + " (?,?,?) }");
        try {
          oCall.setQueryTimeout(15);
        }
        catch (SQLException sqle) {}

        oCall.setInt(1, iDomainId.intValue());
        oCall.setString(2, sInstanceNm);
        oCall.registerOutParameter(3, java.sql.Types.CHAR);

        oCall.execute();

        sInstanceId = oCall.getString(3);

        if (null!=sInstanceId) sInstanceId = sInstanceId.trim();

        oCall.close();
        oCall = null;
      }
    }

    return sInstanceId;
  } // getUIdFromName

  private static Class getClassForName(String sClassName) {
    Class oRetVal;
	try {
	  oRetVal = Class.forName(sClassName);
	} catch (ClassNotFoundException cnfe) { oRetVal = null; }
	return oRetVal;
  } // getClassForName

  protected HashMap AllVals;
  protected String sAuditCls;
  protected String sAuditUsr;
  protected String sTransactId;
  private boolean bAllCaps;
  private boolean bHasLongVarBinaryData;
  private HashMap LongVarBinaryValsLen;
  private DBTable oTable;

  // ----------------------------------------------------------

  private static Class ClassLangString  = getClassForName("java.lang.String");
  private static Class ClassUtilDate  = getClassForName("java.util.Date");
  private static Class ClassSQLDate  = getClassForName("java.sql.Date");
  private static Class ClassSQLTime = getClassForName("java.sql.Time");
  private static Class ClassTimestamp = getClassForName("java.sql.Timestamp");  

  } //DBPersist
