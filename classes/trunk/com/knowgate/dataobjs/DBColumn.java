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

import com.knowgate.storage.Column;
import com.knowgate.debug.DebugFile;


/**
 * <p>Object representing metadata for a database table column.</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public final class DBColumn extends Column {

  public DBColumn() {}

  public DBColumn(String sTable, String sColName,
                short iColType, String sColType,
                int iPrecision, int iDecDigits,
                int iNullable, int iColPos) {
    super(sTable, sColName,iColType, iPrecision, iDecDigits, iNullable==DatabaseMetaData.columnNullable, false, null, null, false, iColPos);
  }

  //-----------------------------------------------------------

  /**
   *
   * @return Column SQL Type
   * @see java.sql.Types
   */

  public short getSqlType() { return (short) getType(); }

  /**
   * Set SQL type for this column
   * @param iType short
   */
  public void setSqlType(short iType) {
    setType(iType);
    setTypeName(DBColumn.typeName(getSqlType()));
  }

  public void setSqlType(int iType) {
    setType(iType);
    setTypeName(DBColumn.typeName(getSqlType()));
  }

  /**
   *
   * @return SQL Type Name
   */
  public String getSqlTypeName() { return getTypeName(); }

  // -------------------------------------------------

  public Object convert(String sIn)
    throws NumberFormatException,ParseException,NullPointerException {
    if (sIn==null) return null;
    if (sIn.length()==0) return null;
    if (DebugFile.trace) DebugFile.writeln("Converting "+getName()+" from String value "+sIn+" to "+getSqlTypeName());
    switch (getSqlType()) {
      case Types.SMALLINT:
        return new Short(sIn);
      case Types.INTEGER:
        return new Integer(sIn);
      case Types.BIGINT:
        return new Long(sIn);
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

  public void setDateFormat(String sFmt) throws IllegalArgumentException {
    oDtFmt = new SimpleDateFormat(sFmt);
  }

  //-----------------------------------------------------------

  public SimpleDateFormat getDateFormat()  {
    return oDtFmt;
  }

  //-----------------------------------------------------------

  /*
  private String sName;
  private int iPosition;
  private String sTableName;
  private short iSQLType;
  private String sSQLTypeName;
  private int iMaxSize;
  private int iDecimalDigits;
  private boolean bNullable;
  */

  private SimpleDateFormat oDtFmt;
  
} // DBColumn
