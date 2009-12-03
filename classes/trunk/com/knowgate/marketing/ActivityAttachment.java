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

package com.knowgate.marketing;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.Timestamp;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.hipergate.Product;

/**
 * <p>Activity Attachment</p>
 * <p>Copyright: Copyright (c) KnowGate 2009</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class ActivityAttachment extends DBPersist {

  public ActivityAttachment() {
    super(DB.k_activity_attachs, "ActivityAttachment");
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Product aa Activity Attachment.</p>
   * <p>A Product object must have been stored at database prior to storing the
   * Attachment object.<br>
   * The link between Product and ActivityAttachment is done just by setting the
   * gu_product field at ActivityAttachment object.<br>
   * An ActivityAttachment progressive numeric identifier is automatically computed
   * for field pg_product of table k_activity_attachs if one is not explicitly set.<br>
   * Automatically generates dt_modified DATE if not explicitly set.<br></p>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    Timestamp dtNow = new Timestamp(DBBind.getTime());
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ActivityAttachment.store([JDCConnection])");
      DebugFile.incIdent();
    }

    replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.pg_product)) {

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeQuery(SELECT " + DBBind.Functions.ISNULL + "(MAX(" + DB.pg_product + "),0)+1 FROM " + DB.k_activity_attachs + " WHERE " + DB.gu_activity + "='" + getStringNull(DB.gu_activity,"null") + "')");

      oRSet = oStmt.executeQuery("SELECT " + DBBind.Functions.ISNULL + "(MAX(" + DB.pg_product + "),0)+1 FROM " + DB.k_activity_attachs + " WHERE " + DB.gu_activity + "='" + getString(DB.gu_activity) + "'");
      oRSet.next();
      put (DB.pg_product, oRSet.getObject(1));
      oRSet.close();
      oStmt.close();
    }

    bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ActivityAttachment.store() : " + String.valueOf(getInt(DB.pg_product)));
    }

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Delete ActivityAttachment</p>
   * <p>The associated Product and physical files are automatically deleted as well.<br></p>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    boolean bRetVal;

    Product oProd = new Product(oConn, getString(DB.gu_product));
    bRetVal = oProd.delete(oConn);

    if (bRetVal) bRetVal = super.delete(oConn);

    return bRetVal;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 312;
}
