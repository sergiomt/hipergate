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

import java.sql.Types;
import java.sql.Timestamp;

import java.math.BigDecimal;

import java.util.Date;
import java.util.HashMap;

import java.io.Serializable;

import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.MalformedPatternException;

public class Column implements Serializable {

  private static final long serialVersionUID = 600000101201000100l;

  private int iPosition;
  private int nLength;
  private int iDecimalDigits;
  private int iType;
  private String sSQLTypeName;
  private String sName;
  private String sTableName;
  private boolean bNullable;
  private boolean bIndexed;
  private boolean bPk;
  private String sForeignKey;
  private Object oDefault;
  private Pattern oPattern;

  private static HashMap<String,Pattern> oRegExps = new HashMap<String,Pattern>();
  private static Perl5Compiler oCompiler = new Perl5Compiler();
  private static Perl5Matcher oMatcher = new Perl5Matcher();

  public Column() {}
  
  public Column(String sTable, String sColName, int iColType,
  				int nColLen, int iDecDigits,
  				boolean bIsNullable, boolean bIsIndexed,
  				String sForeignKeyTableName, Object oDefaultValue,
  				boolean bIsPrimaryKey, int iColPos ) {
  	sTableName = sTable;
  	iPosition = iColPos;
  	sName = sColName;
  	iType = iColType;
  	nLength = nColLen;
  	iDecimalDigits = iDecDigits;
  	bNullable = bIsNullable;
  	bIndexed = bIsIndexed;
  	bPk = bIsPrimaryKey;
  	oDefault = oDefaultValue;
  	sForeignKey = sForeignKeyTableName;
  	oPattern = null;
  }
  
  public Column(int iColPos, String sColName, int iColType, int nColLen,
  				boolean bIsNullable, boolean bIsIndexed, String sCheckRegExp,
  				String sForeignKeyTableName, Object oDefaultValue,
  				boolean bIsPrimaryKey)
  	throws MalformedPatternException {
  	iPosition = iColPos;
  	sName = sColName;
  	iType = iColType;
  	nLength = nColLen;
  	bNullable = bIsNullable;
  	bIndexed = bIsIndexed;
  	bPk = bIsPrimaryKey;
  	oDefault = oDefaultValue;
  	sForeignKey = sForeignKeyTableName;
  	if (null==sCheckRegExp) {
  	  oPattern = null;
  	} else if (oRegExps.containsKey(sCheckRegExp)) {
	  oPattern = oRegExps.get(sCheckRegExp);
  	} else {
	  oPattern = oCompiler.compile(sCheckRegExp,Perl5Compiler.CASE_INSENSITIVE_MASK);
	  oRegExps.put(sCheckRegExp, oPattern);
  	}
  }

  /**
   *
   * @return Column Name
   */
  public String getName() {
    return sName;
  }  

  /**
   * Set column name
   * @param sColName String
   */
  public void setName(String sColName)  {
  	sName=sColName;
  }

  /**
   *
   * @return Column Position (starting at column 1)
   */
  public int getPosition() {
  	return iPosition;
  }

  /**
   * Set column position
   * @param iPos int
   */
  public void setPosition(int iPos) {
  	iPosition=iPos;
  }

  /**
   *
   * @return Column Precision
   */
  public int getPrecision() {
  	return nLength;
  }

  /**
   *
   * @return Decimal Digits
   */

  public int getDecimalDigits() {
  	return iDecimalDigits;
  }

  /**
   *
   * @return Name of table containing this column
   */
  public String getTableName() {
  	return sTableName;
  }

  public int getType() {
    return iType;
  }  

  public void setType(int iSqlType) {
    iType=iSqlType;
  }  

  public void setType(short iSqlType) {
    iType=(int) iSqlType;
  }  

  protected String getTypeName() {
    return sSQLTypeName;
  }  

  protected void setTypeName(String sTypeName) {
    sSQLTypeName=sTypeName;
  }  

  public int getLength() {
    return nLength;
  }  

  public Object getDefaultValue() {
    return oDefault;
  }  

  public String getConstraint() {
  	if (getForeignKey()==null)
      if (oPattern==null)
        return null;
      else
        return oPattern.getPattern();
    else
      return "foreign key "+getForeignKey();
  }  

  public boolean isIndexed() {
    return bIndexed;
  }  

  public boolean isPrimaryKey() {
    return bPk;
  }  

  /**
   *
   * @return Allows NULLs?
   */
  public boolean isNullable() {
    return bNullable;
  }  

  public String getForeignKey() {
    return sForeignKey;
  }  

  public boolean check(Object sValue) {
  	boolean bRetVal;
  	if (null==sValue) {
  	  bRetVal = bNullable;
  	} else {
  	  if (null==oPattern) {
		bRetVal = true;
      } else {
      	if (sValue instanceof String) {
      	  bRetVal = oMatcher.matches(sValue.toString(), oPattern) ||
      	  	        (bNullable && ((String)sValue).length()==0);
      	} else {
      	  switch (getType()) {
      	  	case Types.SMALLINT:
      	  	  bRetVal = sValue instanceof Short;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.INTEGER:
      	  	  bRetVal = sValue instanceof Integer;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.BIGINT:
      	  	  bRetVal = sValue instanceof Long;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.FLOAT:
      	  	  bRetVal = sValue instanceof Float;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.DOUBLE:
      	  	  bRetVal = sValue instanceof Double;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.DECIMAL:
      	  	case Types.NUMERIC:
      	  	  bRetVal = sValue instanceof BigDecimal;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.TIMESTAMP:
      	  	case Types.DATE:
      	      bRetVal = sValue instanceof Date || sValue instanceof Timestamp;
      	      break;
      	    default:
      	      bRetVal = false;
      	  }
      	}
      }
  	}
  	return bRetVal;
  } // check
  
  //-----------------------------------------------------------

  /**
   * Get SQL type name from its integer identifier
   * @param iSQLtype int
   * @return String
   */
  public static String typeName(int iSQLtype) {
    switch (iSQLtype) {
      case Types.BIGINT:
        return "BIGINT";
      case Types.BINARY:
        return "BINARY";
      case Types.BIT:
        return "BIT";
      case Types.BLOB:
        return "BLOB";
      case Types.BOOLEAN:
        return "BOOLEAN";
      case Types.CHAR:
        return "CHAR";
      case Types.CLOB:
        return "CLOB";
      case Types.DATE:
        return "DATE";
      case Types.DECIMAL:
        return "DECIMAL";
      case Types.DOUBLE:
        return "DOUBLE";
      case Types.FLOAT:
        return "FLOAT";
      case Types.INTEGER:
        return "INTEGER";
      case Types.LONGVARBINARY:
        return "LONGVARBINARY";
      case Types.LONGVARCHAR:
        return "LONGVARCHAR";
      case Types.NCHAR:
        return "NCHAR";
      case Types.NVARCHAR:
        return "NVARCHAR";
      case Types.NULL:
        return "NULL";
      case Types.NUMERIC:
        return "NUMERIC";
      case Types.REAL:
        return "REAL";
      case Types.SMALLINT:
        return "SMALLINT";
      case Types.TIME:
        return "TIME";
      case Types.TIMESTAMP:
        return "TIMESTAMP";
      case Types.TINYINT:
        return "TINYINT";
      case Types.VARBINARY:
        return "VARBINARY";
      case Types.VARCHAR:
        return "VARCHAR";
      case Types.ARRAY:
          return "ARRAY";
      default:
        return "OTHER";
    }
  }

  //-----------------------------------------------------------

  /**
   * Get SQL type identifier from its name
   * @param sToken String
   * @return String
   */

  public static int getSQLType (String sToken) {
    int iSQLType;
    if (sToken.equalsIgnoreCase("VARCHAR"))
      iSQLType = Types.VARCHAR;
    else if (sToken.equalsIgnoreCase("CHAR"))
      iSQLType = Types.CHAR;
    else if (sToken.equalsIgnoreCase("SMALLINT"))
      iSQLType = Types.SMALLINT;
    else if (sToken.equalsIgnoreCase("INTEGER"))
      iSQLType = Types.INTEGER;
    else if (sToken.equalsIgnoreCase("BIGINT"))
      iSQLType = Types.BIGINT;
    else if (sToken.equalsIgnoreCase("FLOAT"))
      iSQLType = Types.FLOAT;
    else if (sToken.equalsIgnoreCase("DOUBLE"))
      iSQLType = Types.DOUBLE;
    else if (sToken.equalsIgnoreCase("NUMERIC"))
      iSQLType = Types.NUMERIC;
    else if (sToken.equalsIgnoreCase("DECIMAL"))
      iSQLType = Types.DECIMAL;
    else if (sToken.equalsIgnoreCase("DATE"))
      iSQLType = Types.DATE;
    else if (sToken.equalsIgnoreCase("TIMESTAMP"))
      iSQLType = Types.TIMESTAMP;
    else if (sToken.equalsIgnoreCase("DATETIME"))
      iSQLType = Types.TIMESTAMP;
    else if (sToken.equalsIgnoreCase("NCHAR"))
      iSQLType = Types.NCHAR;
    else if (sToken.equalsIgnoreCase("NVARCHAR"))
      iSQLType = Types.NVARCHAR;
    else if (sToken.equalsIgnoreCase("VARCHAR2"))
      iSQLType = Types.VARCHAR;
    else if (sToken.equalsIgnoreCase("LONGVARCHAR"))
      iSQLType = Types.LONGVARCHAR;
    else if (sToken.equalsIgnoreCase("LONG"))
      iSQLType = Types.LONGVARCHAR;
    else if (sToken.equalsIgnoreCase("TEXT"))
      iSQLType = Types.LONGVARCHAR;
    else if (sToken.equalsIgnoreCase("LONGVARBINARY"))
      iSQLType = Types.LONGVARBINARY;
    else if (sToken.equalsIgnoreCase("LONG RAW"))
      iSQLType = Types.LONGVARBINARY;
    else if (sToken.equalsIgnoreCase("BLOB"))
      iSQLType = Types.BLOB;
    else if (sToken.equalsIgnoreCase("CLOB"))
      iSQLType = Types.CLOB;
    else
      iSQLType = Types.NULL;
    return iSQLType;
  }
  
}
