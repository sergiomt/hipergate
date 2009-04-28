/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate.datamodel;

import java.sql.SQLException;
import java.sql.Connection;

import com.knowgate.hipergate.DBLanguages;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public interface ImportLoader {

  int MODE_APPEND = 1;
  int MODE_UPDATE = 2;
  int MODE_APPENDUPDATE = 3;
  int WRITE_LOOKUPS = 4;

  final String LOOUKP_TR_COLUMNS = DBLanguages.getLookupTranslationsColumnList();
  final int LOOUKP_TR_COUNT = DBLanguages.SupportedLanguages.length; // This must be the count of column names of the previous String
  
  /**
   * Get columns count
   * @return int
   */
  int columnCount();

  /**
   * Get array of column names
   * @return String[]
   */
  String[] columnNames() throws IllegalStateException;

  /**
   * Get current value for a column given its index
   * @param iColumnIndex int [0..columnCount()-1]
   * @return Object
   * @throws ArrayIndexOutOfBoundsException
   */
  Object get(int iColumnIndex) throws ArrayIndexOutOfBoundsException;

  /**
   * Get current value for a column given its name
   * @param sColumnName Case insensitive String
   * @return Object
   * @throws ArrayIndexOutOfBoundsException if no column with such name was found
   */
  Object get(String sColumnName) throws ArrayIndexOutOfBoundsException;

  /**
   * Get column index from its name
   * @param sColumnName String
   * @return int [0..columnCount()-1] or -1 if column was not found
   */
  int getColumnIndex(String sColumnName);

  /**
   * Put current value for a column
   * @param iColumnIndex int [0..columnCount()-1]
   * @param oValue Object
   * @throws ArrayIndexOutOfBoundsException
   */
  void put(int iColumnIndex, Object oValue) throws ArrayIndexOutOfBoundsException;

  /**
   * Put current value for a column
   * @param sColumnName String Column name
   * @param oValue Object
   * @throws ArrayIndexOutOfBoundsException
   */
  void put(String sColumnName, Object oValue) throws ArrayIndexOutOfBoundsException;

  /**
   * Set all current values to null
   */
  void setAllColumnsToNull();

  /**
   * Prepare ImportLoader for repeated execution
   * @param oConn Connection
   * @param oCols ColumnList List of columns that will be inserted or updated at the database
   * @throws SQLException
   */
  void prepare(Connection oConn, ColumnList oCols) throws SQLException;

  /**
   * <p>Close ImportLoader</p>
   * Must be always called before ImportLoader is destroyed
   * @throws SQLException
   */
  void close() throws SQLException;

  /**
   * Store a single row or a set of related rows
   * @param oConn Connection
   * @param sWorkArea String
   * @param iFlags int
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws NullPointerException
   */
  void store(Connection oConn, String sWorkArea, int iFlags) throws SQLException,IllegalArgumentException,NullPointerException;
}
