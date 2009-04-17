/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

import java.sql.DatabaseMetaData;
import java.sql.Types;
import java.sql.Timestamp;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.math.BigDecimal;

/**
 * <p>Object representing metadata for a database table column.</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public final class DBColumn {

  public DBColumn() { }

  public DBColumn(String sTable, String sColName,
                  short iColType, String sColType,
                  int iPrecision, int iDecDigits,
                  int iNullable, int iColPos)

  {
    sName = sColName;
    iPosition = iColPos;
    sTableName = sTable;
    iSQLType = iColType;
    sSQLTypeName = sColType;
    iMaxSize = iPrecision;
    iDecimalDigits = iDecDigits;
    bNullable = (iNullable==DatabaseMetaData.columnNullable);
  }

  //-----------------------------------------------------------

  /**
   *
   * @return Column Name
   */
  public String getName()  { return sName; }

  /**
   * Set column name
   * @param sColName String
   */
  public void setName(String sColName)  { sName=sColName; }

  /**
   *
   * @return Column Position (starting at column 1)
   */
  public int getPosition() { return iPosition; }

  /**
   * Set column position
   * @param iPos int
   */
  public void setPosition(int iPos) { iPosition=iPos; }

  /**
   *
   * @return Name of table containing this column
   */
  public String getTableName() { return sTableName; }

  /**
   *
   * @return Column SQL Type
   * @see java.sql.Types
   */

  public short getSqlType() { return iSQLType; }

  /**
   * Set SQL type for this column
   * @param iType short
   */
  public void setSqlType(short iType) {
    iSQLType=iType;
    sSQLTypeName=DBColumn.typeName(iSQLType);
  }

  public void setSqlType(int iType) {
    iSQLType=(short) iType;
    sSQLTypeName=DBColumn.typeName(iSQLType);
  }

  /**
   *
   * @return SQL Type Name
   */
  public String getSqlTypeName() { return sSQLTypeName; }

  /**
   *
   * @return Column Precision
   */

  public int getPrecision() { return iMaxSize; }

  /**
   *
   * @return Decimal Digits
   */

  public int getDecimalDigits() { return iDecimalDigits; }

  /**
   *
   * @return Allows NULLs?
   */

  public boolean isNullable() { return bNullable; }

  //-----------------------------------------------------------

  public void setDateFormat(String sFmt) throws IllegalArgumentException {
    oDtFmt = new SimpleDateFormat(sFmt);
  }

  //-----------------------------------------------------------

  public SimpleDateFormat getDateFormat()  {
    return oDtFmt;
  }

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
    else if (sToken.equalsIgnoreCase("NVARCHAR"))
      iSQLType = Types.VARCHAR;
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

  // -------------------------------------------------

  public Object convert(String sIn)
    throws NumberFormatException,ParseException,NullPointerException {
    if (sIn==null) return null;
    if (sIn.length()==0) return null;
    switch (iSQLType) {
      case Types.SMALLINT:
        return new Short(sIn);
      case Types.INTEGER:
        return new Integer(sIn);
      case Types.FLOAT:
        return new Float(sIn);
      case Types.DOUBLE:
        return new Double(sIn);
      case Types.DECIMAL:
      case Types.NUMERIC:
        return new BigDecimal(sIn);
      case Types.DATE:
        return oDtFmt.parse(sIn);
      case Types.TIMESTAMP:
        return new Timestamp(oDtFmt.parse(sIn).getTime());
      default:
        return sIn;
    }
  } // convert

  //-----------------------------------------------------------

  private String sName;
  private int iPosition;
  private String sTableName;
  private short iSQLType;
  private String sSQLTypeName;
  private int iMaxSize;
  private int iDecimalDigits;
  private boolean bNullable;
  private SimpleDateFormat oDtFmt;
} // DBColumn
