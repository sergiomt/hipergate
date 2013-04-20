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
import com.knowgate.storage.RDBMS;
import com.knowgate.debug.DebugFile;


/**
 * <p>Object representing metadata for a database table column.</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public final class DBColumn extends Column {

  private static final long serialVersionUID = 70000l;

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
    setTypeName(Column.typeName(getSqlType()));
  }

  public void setSqlType(int iType) {
    setType(iType);
    setTypeName(Column.typeName(getSqlType()));
  }

  /**
   *
   * @return SQL Type Name
   */
  public String getSqlTypeName() { return getTypeName(); }

  // -------------------------------------------------

  /**
   * Try to convert an input String into the type of object that this column holds
   * @param sIn String
   * @return Object
   * @throws NumberFormatException
   * @throws ParseException
   * @throws NullPointerException
   */
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

  /**
   * Get SQL script definition for this column.
   * @param eRDBMS Target database management system
   * @return String like "column_name VARCHAR2(30) NOT NULL DEFAULT '0'"
   * @since 7.0
   */
  public String sqlScriptDef(RDBMS eRDBMS)  {
    String sTypedef = getName() + " ";
	switch (getSqlType()) {
      case Types.TIMESTAMP:
    	sTypedef += Timestamp[eRDBMS.intValue()];
    	break;
      case Types.DECIMAL:
      case Types.NUMERIC:
    	sTypedef += getSqlTypeName()+"("+String.valueOf(getPrecision())+","+String.valueOf(getDecimalDigits())+")";
    	break;
      case Types.VARCHAR:
  	    sTypedef += VarChar[eRDBMS.intValue()]+"("+String.valueOf(getPrecision())+")";
  	    break;
      case Types.LONGVARCHAR:
        sTypedef += LongVarChar[eRDBMS.intValue()];
    	break;
      case Types.LONGVARBINARY:
        sTypedef += LongVarBinary[eRDBMS.intValue()];
      	break;
      case Types.BLOB:
        sTypedef += Blob[eRDBMS.intValue()];
      	break;
      case Types.CLOB:
        sTypedef += Clob[eRDBMS.intValue()];
      	break;
      default:
    	sTypedef += getSqlTypeName();
    }
	sTypedef += (isNullable() ? " NULL" : " NOT NULL");
	if (getDefaultValue()!=null) {
	  sTypedef += " DEFAULT ";
	  switch (getSqlType()) {
        case Types.BIGINT:
        case Types.INTEGER:
          if (getDefaultValue().equals("SERIAL") || getDefaultValue().equals("serial"))
        	sTypedef += Serial[eRDBMS.intValue()];
          else
        	sTypedef += getDefaultValue();
          break;
        case Types.TIMESTAMP:
          if (getDefaultValue().equals("CURRENT_TIMESTAMP") || getDefaultValue().equals("current_timestamp"))
        	sTypedef += CurrentTimeStamp[eRDBMS.intValue()];
          else
          	sTypedef += getDefaultValue();
          break;
        case Types.CHAR:
        case Types.VARCHAR:
        case Types.NCHAR:
        case Types.NVARCHAR:
          sTypedef += "'" + getDefaultValue() + "'";
          break;
        default:
          sTypedef += getDefaultValue();
          break;
	  }	
	} // fi	
	return sTypedef;
  } // sqlScriptDef
  
  //-----------------------------------------------------------

  private static final String CurrentTimeStamp[] = { null, "CURRENT_TIMESTAMP", "CURRENT_TIMESTAMP", "GETDATE()", null, "SYSDATE" };
  private static final String Timestamp[] = { null, "TIMESTAMP", "TIMESTAMP", "DATETIME", null, "DATE" };
  private static final String LongVarChar[] = { null, "MEDIUMTEXT", "TEXT", "NTEXT", null, "LONG" };
  private static final String LongVarBinary[] = { null, "MEDIUMBLOB", "BYTEA", "IMAGE", null, "LONG RAW" };
  private static final String Serial[] = { null, "AUTO_INCREMENT", "", "IDENTITY", null, "" };
  private static final String VarChar[] = { null, "VARCHAR", "VARCHAR", "NVARCHAR", null, "VARCHAR2" };
  private static final String Blob[] = { null, "MEDIUMBLOB", "BYTEA", "IMAGE", null, "BLOB" };
  private static final String Clob[] = { null, "MEDIUMTEXT", "TEXT", "NTEXT", null, "CLOB" };

  private SimpleDateFormat oDtFmt;
  
} // DBColumn
