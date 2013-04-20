/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.datacopy;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import java.util.HashMap;

import java.io.IOException;
import java.io.StringReader;

import org.xml.sax.SAXException;

import com.knowgate.datacopy.DataStruct;

/**
 * <p>Copy data from one table to another</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class FullTableCopy extends DataStruct {

  public FullTableCopy() {
  }

  /**
   * Copy some data from origin table to target table
   * @param sOriginTable String
   * @param sTargetTable String
   * @param sOriginWhere String Filter clause (SQL WHERE) to be applied to origin table
   * @param bTruncate boolean if <b>true</b> Truncate target table before inserting
   * @throws SQLException
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws InstantiationException
   * @throws IllegalAccessException
   * @throws SAXException
   */
  public void insert(String sOriginTable, String sTargetTable,
                     String sOriginWhere, boolean bTruncate)
    throws SQLException,ClassNotFoundException,IOException,InstantiationException,
           IllegalAccessException,SAXException {
    PreparedStatement oStInsert;
    PreparedStatement oStSelect;
    Statement oStDelete;
    Statement oStMeta;
    ResultSet oRsMeta;
    ResultSet oRsSelect;
    ResultSetMetaData oRsMetaData;
    StringReader oRead;
    Object oField;
    String sSQL;
    int iColCount;
    int iSQLType;
    HashMap oSourceCols;
    String sColList = "";

    oStMeta = getOriginConnection().createStatement();
    oRsMeta = oStMeta.executeQuery("SELECT * FROM " + sOriginTable + " WHERE 1=0");
    oRsMetaData = oRsMeta.getMetaData();
    iColCount = oRsMetaData.getColumnCount();
    oSourceCols = new HashMap(iColCount*2+2);
    for (int c=1; c<=iColCount; c++)
      oSourceCols.put(oRsMetaData.getColumnName(c),null);
    oRsMeta.close();
    oStMeta.close();

    sSQL = "INSERT INTO "+sTargetTable+" VALUES (?";
    for (int c=2; c<=iColCount; c++) sSQL+=",?";
    sSQL += ")";

    oStInsert = getTargetConnection().prepareStatement(sSQL);

    oStMeta = getTargetConnection().createStatement();
    oRsMeta = oStMeta.executeQuery("SELECT * FROM " + sTargetTable + " WHERE 1=0");
    oRsMetaData = oRsMeta.getMetaData();
    iColCount = oRsMetaData.getColumnCount();
    for (int c=1; c<=iColCount; c++) {
      if (oSourceCols.containsKey(oRsMetaData.getColumnName(c)))
        sColList += (sColList.length()==0 ? "" : ",") + oRsMetaData.getColumnName(c);
      else
        sColList += (sColList.length()==0 ? "" : ",") + "NULL AS "+oRsMetaData.getColumnName(c);
    } // next

    if (null==sOriginWhere)
      oStSelect = getOriginConnection().prepareStatement("SELECT "+sColList+" FROM "+sOriginTable);
    else if (sOriginWhere.trim().length()==0)
      oStSelect = getOriginConnection().prepareStatement("SELECT "+sColList+" FROM "+sOriginTable);
    else
      oStSelect = getOriginConnection().prepareStatement("SELECT "+sColList+" FROM "+sOriginTable+" WHERE "+sOriginWhere);

    oRsSelect = oStSelect.executeQuery();

    if (bTruncate) {
      oStDelete = getTargetConnection().createStatement();
      oStDelete.execute("DELETE FROM " + sTargetTable);
      oStDelete.close();
    } // fi (bTruncate)

    iRows = 0;

    while (oRsSelect.next()) {
      oRead = null;
      for (int p=1; p<=iColCount; p++) {
        iSQLType = oRsMetaData.getColumnType(p);
        oField = oRsSelect.getObject(p);
        if (iSQLType==-1) {
          oRead = new StringReader(oField.toString()+" ");
          oStInsert.setCharacterStream(p, oRead, oField.toString().length()-1);
          }
        else
          oStInsert.setObject ( p,
                                convert(oField,iSQLType),
                                mapType(iSQLType));
      }  // next
      oStInsert.executeUpdate();
      if (oRead!=null) oRead.close();

      iRows++;
    } // wend

    oRsSelect.close();
    oStSelect.close();
    oRsMeta.close();
    oStMeta.close();
    oStInsert.close();
  }

  /**
   * Copy all data from origin table to target table
   * @param sOriginTable String
   * @param sTargetTable String
   * @param bTruncate boolean if <b>true</b> Truncate target table before inserting
   * @throws SQLException
   * @throws ClassNotFoundException
   * @throws IOException
   * @throws InstantiationException
   * @throws IllegalAccessException
   * @throws SAXException
   */
  public void insert(String sOriginTable, String sTargetTable, boolean bTruncate)
    throws SQLException,ClassNotFoundException,IOException,InstantiationException,
           IllegalAccessException,SAXException {
    insert (sOriginTable, sTargetTable, null, bTruncate);
  }

}
