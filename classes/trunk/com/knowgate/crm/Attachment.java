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
import java.sql.Statement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.hipergate.Product;

/**
 * <p>Contact Attachment</p>
 * <p>Copyright: Copyright (c) KnowGate 2003</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class Attachment extends DBPersist {

  public Attachment() {
    super(DB.k_contact_attachs, "Attachment");
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Product as Contact Attachment.</p>
   * <p>A Product object must have been stored at database prior to storing the
   * Attachment object.<br>
   * The link between Product and Attachment is done just by setting the
   * gu_product field at Attachment object.<br>
   * An Attachment progressive numeric identifier is automatically computed
   * for field pg_product of table k_contact_attachs if one is not explicitly set.<br>
   * Automatically generates dt_modified DATE if not explicitly set.<br></p>
   * k_contact.nu_attachs fields is incremented by 1
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Attachment.store([Connection])");
      DebugFile.incIdent();
    }

    replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.pg_product)) {

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeQuery(SELECT " + DBBind.Functions.ISNULL + "(MAX(" + DB.pg_product + "),0)+1 FROM " + DB.k_contact_attachs + " WHERE " + DB.gu_contact + "='" + getStringNull(DB.gu_contact,"null") + "')");

      oRSet = oStmt.executeQuery("SELECT " + DBBind.Functions.ISNULL + "(MAX(" + DB.pg_product + "),0)+1 FROM " + DB.k_contact_attachs + " WHERE " + DB.gu_contact + "='" + getString(DB.gu_contact) + "'");
      oRSet.next();
      put (DB.pg_product, oRSet.getObject(1));
      oRSet.close();
      oStmt.close();
    }

    bRetVal = super.store(oConn);

    oStmt = oConn.createStatement();

    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_contacts + " SET " + DB.nu_attachs + "=" + DB.nu_attachs + "+1 WHERE gu_contact='" +  getStringNull(DB.gu_contact,"null") + "')");

    oStmt.executeUpdate("UPDATE " + DB.k_contacts + " SET " + DB.nu_attachs + "=" + DB.nu_attachs + "+1 WHERE gu_contact='" +  getString(DB.gu_contact) + "'");
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Attachment.store() : " + String.valueOf(getInt(DB.pg_product)));
    }

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Delete Attachment</p>
   * <p>The associated Product and physical files are automatically deleted as well.<br></p>
   * k_contact.nu_attachs fields is decremented by 1
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    Statement oStmt;
    boolean bRetVal;

    Product oProd = new Product(oConn, getString(DB.gu_product));
    bRetVal = oProd.delete(oConn);

    if (bRetVal) bRetVal = super.delete(oConn);

    oStmt = oConn.createStatement();
    oStmt.executeUpdate("UPDATE " + DB.k_contacts + " SET " + DB.nu_attachs + "=" + DB.nu_attachs + "-1 WHERE gu_contact='" +  getString(DB.gu_contact) + "'");
    oStmt.close();

    return bRetVal;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 94;
}
