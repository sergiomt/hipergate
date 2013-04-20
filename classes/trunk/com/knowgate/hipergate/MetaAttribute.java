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

package com.knowgate.hipergate;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

/**
 * <p>Table Meta-Attributes</p>
 * Meta-Attributes are "virtual columns" that may exists for each table on a per
 * WorkArea basis. This class holds only the meta-attributes definitions, not the
 * actual data contained on them.
 * @author Sergio Montoro Ten
 * @version 2.1
 */
public class MetaAttribute extends DBPersist {

  /**
   * Create empty Meta-Attribute
   */
  public MetaAttribute() {
   super(DB.k_lu_meta_attrs, "MetaAttribute");
  }

  /**
   * Load Meta-Attribute from database.
   * @param oConn Database Connection
   * @param sOwnerGUID GUID of WorkArea to witch the Meta-Attribute belongs.
   * @param sTableName Name of base table
   * @param sSectionName Section Name (emulates a column name on base table).
   * @throws SQLException
   */
  public MetaAttribute(JDCConnection oConn, String sOwnerGUID, String sTableName, String sSectionName) throws SQLException {
    super(DB.k_lu_meta_attrs, "MetaAttribute");
    PreparedStatement oStmt = oConn.prepareStatement("SELECT * FROM "+DB.k_lu_meta_attrs+" WHERE "+DB.gu_owner+"=? AND "+DB.nm_table+"=? AND "+DB.id_section+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sOwnerGUID);
    oStmt.setString(2, sTableName);
    oStmt.setString(3, sSectionName);
    ResultSet oRSet = oStmt.executeQuery();
    boolean bFound = oRSet.next();
    if (bFound) {
      ResultSetMetaData oMDat = oRSet.getMetaData();
      int iColCount = oMDat.getColumnCount();
      for (int c=1; c<=iColCount; c++) {
        put(oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
      } // next
      oRSet.close();
      oStmt.close();
    }
    else {
      oRSet.close();
      oStmt.close();
      throw new SQLException(DB.k_lu_meta_attrs + " No data found for "+sTableName+"."+sSectionName+" at WorkArea "+sOwnerGUID,"42S02",100);
    }
  }

  // ----------------------------------------------------------

  /**
   * Delete meta-Attribute definition and data.
   * @param oConn Database Connection
   * @throws SQLException
   * @throws NullPointerException If base table, workarea or attribute is <b>null</b>
   */
  public boolean delete(JDCConnection oConn)
    throws SQLException,NullPointerException {
    PreparedStatement oStmt;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MetaAttribute.delete([Connection])");
    }

    if (isNull(DB.nm_table))
      throw new NullPointerException("Base table for meta-attribute not set");
    if (isNull(DB.gu_owner))
      throw new NullPointerException("Owner WorkArea for meta-attribute not set");
    if (isNull(DB.id_section))
      throw new NullPointerException("Section for meta-attribute not set");

    if (DebugFile.trace) {
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_lu_meta_attrs + " WHERE " + DB.gu_owner + "='"+getStringNull(DB.gu_owner,"null")+"' AND " + DB.nm_table + "='" + getStringNull(DB.nm_table,"null")+"' AND " + DB.id_section + "='" + getStringNull(DB.id_section,"null") + "'");
    }

    oStmt = oConn.prepareStatement("DELETE FROM " + DB.k_lu_meta_attrs + " WHERE " + DB.gu_owner + "=? AND " + DB.nm_table + "=? AND " + DB.id_section + "=?");
    oStmt.setString(1, getString(DB.gu_owner));
    oStmt.setString(2, getString(DB.nm_table));
    oStmt.setString(3, getString(DB.id_section));
    oStmt.executeUpdate();
    oStmt.close();

    bRetVal = super.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MetaAttribute.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete()

  // ----------------------------------------------------------

  /**
   * <p>Store Meta-Attribute Definition</p>
   * Field pg_attr is automatically assigned to next free value in k_lu_meta_attrs
   * table for current WorkArea and Base Table.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    Object oMax;
    Integer iMax;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MetaAttribute.stor([Connection])");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT MAX(" + DB.pg_attr + ")+1 FROM " + DB.k_lu_meta_attrs + " WHERE " + DB.gu_owner + "='" + getStringNull(DB.gu_owner, "") + "' AND " + DB.nm_table + "='" + getStringNull(DB.nm_table,"") + "')");
    }

    if (!AllVals.containsKey(DB.pg_attr)) {
      oStmt = oConn.prepareStatement("SELECT MAX(" + DB.pg_attr + ")+1 FROM " + DB.k_lu_meta_attrs + " WHERE " + DB.gu_owner + "=? AND " + DB.nm_table + "=?");
      oStmt.setString(1, getString(DB.gu_owner));
      oStmt.setString(2, getString(DB.nm_table));
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oMax = oRSet.getObject(1);
        if (oRSet.wasNull())
          iMax = new Integer(1);
        else
          iMax = new Integer(oMax.toString());
      }
      else
        iMax = new Integer(1);
      oRSet.close();
      oStmt.close();

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE)
        put (DB.pg_attr, new java.math.BigDecimal(iMax.toString()));
      else
        put (DB.pg_attr, new Short(iMax.toString()));
    }

    bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MetaAttribute.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store()

  // **********************************************************
  // Public Constants

  public static final short ClassId = 12;
}
