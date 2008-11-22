package com.knowgate.hipergate.datamodel;

import java.util.ArrayList;

import com.knowgate.dataobjs.DBColumn;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class ColumnList extends ArrayList {

  private static final long serialVersionUID = 1l;
	
  public ColumnList() {
  }

  /**
   * Get column by position
   * @param index int [0..size()-1]
   * @return DBColumn
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   */
  public DBColumn getColumn(int index)
    throws ArrayIndexOutOfBoundsException, ClassCastException{
  return (DBColumn) get(index);
  }

  /**
   * Get column name by position
   * @param index int [0..size()-1]
   * @return DBColumn
   * @throws ArrayIndexOutOfBoundsException
   * @throws ClassCastException
   */
  public String getColumnName(int index)
    throws ArrayIndexOutOfBoundsException, ClassCastException, NullPointerException {
    return ((DBColumn) get(index)).getName();
  }

  /**
   * Get list of column names
   * @param sDelimiter String
   * @return String
   */
  public String toString(String sDelimiter) {
    final int cCount = size();
    StringBuffer oBuffer = new StringBuffer(30*cCount);
    for (int c=0; c<cCount; c++) {
      if (c>0) oBuffer.append(sDelimiter);
      oBuffer.append(getColumnName(c));
    }
    return oBuffer.toString();
  } // toString
}
