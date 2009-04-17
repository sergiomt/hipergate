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

package com.knowgate.crm;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

/**
 * <p>Sales Oportunity</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Oportunity extends DBPersist {

  public Oportunity() {
    super(DB.k_oportunities, "Oportunity");
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Oportunity</p>
   * Fields gu_oportunity, dt_modified, tx_contact and tx_company are automatically filled if not given
   * @param oConn Database Connection
   * @return
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Oportunity.store([Connection])");
      DebugFile.incIdent();
    }

    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_oportunity))
      put(DB.gu_oportunity, Gadgets.generateUUID());

    replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.tx_contact)) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tx_surname + "," + DB.tx_name + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "='" + getStringNull(DB.gu_contact, "null") + "')");

      oStmt = oConn.prepareStatement("SELECT " + DB.tx_surname + "," + DB.tx_name + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setObject (1, get(DB.gu_contact), java.sql.Types.CHAR);
      oRSet = oStmt.executeQuery();
      if (oRSet.next())
        put (DB.tx_contact, oRSet.getString(1) + ", " + oRSet.getString(2));
      oRSet.close();
      oStmt.close();
    }

    if (!AllVals.containsKey(DB.tx_company)) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "='" + getStringNull(DB.gu_company, "null") + "')");

      oStmt = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setObject (1, get(DB.gu_company), java.sql.Types.CHAR);
      oRSet = oStmt.executeQuery();
      if (oRSet.next())
        put (DB.tx_company, oRSet.getString(1));
      oRSet.close();
      oStmt.close();
    }

    bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Oportunity.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {
    return Oportunity.delete(oConn, getString(DB.gu_oportunity));
  }

  // **********************************************************
  // Static Methods

  /**
   * Delete Oportunity
   * Call k_sp_del_oportunity stored procedure
   * @param oConn Database Connection
   * @param sOportunityGUID GUID of Oportunity to be deleted.
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sOportunityGUID) throws SQLException {
    CallableStatement oCall;
    Statement oStmt;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Oportunity.delete([Connection], " + sOportunityGUID + ")");
      DebugFile.incIdent();

    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.execute(SELECT k_sp_del_oportunity ('" + sOportunityGUID + "'))");

      bRetVal = oStmt.execute("SELECT k_sp_del_oportunity ('" + sOportunityGUID + "')");
      oStmt.close();
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_oportunity('" + sOportunityGUID + "')})");

      oCall = oConn.prepareCall("{ call k_sp_del_oportunity ('" + sOportunityGUID + "')}");
      bRetVal = oCall.execute();
      oCall.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Oportunity.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  }

  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 92;
}