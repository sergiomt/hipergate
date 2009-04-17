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
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

/**
 * <p>Contact Note</p>
 * <p>Copyright: Copyright (c) KnowGate 2003</p>
 * @author Sergio Montoro Ten
 * @version 2.1
 */
public class Note extends DBPersist {

  public Note() {
    super(DB.k_contact_notes, "Note");
  }

  // ----------------------------------------------------------

  /**
   * Store Note
   * A new pg_note is automatically generated if not explicitly set.<br>
   * k_contact.nu_notes fields is incrmented by 1
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());
    PreparedStatement oStmt;
    ResultSet oRSet;
    Object oMax;
    Integer iMax;

    if (!AllVals.containsKey(DB.pg_note)) {
      oStmt = oConn.prepareStatement("SELECT MAX(pg_note) FROM " + DB.k_contact_notes + " WHERE " + DB.gu_contact + "=?");
      oStmt.setString(1, getString(DB.gu_contact));
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oMax = oRSet.getObject(1);
        if (oRSet.wasNull())
          iMax = new Integer(1);
        else
          iMax = new Integer(Integer.parseInt(oMax.toString())+1);
      }
      else
        iMax = new Integer(1);
      oRSet.close();
      oStmt.close();

      put(DB.pg_note, iMax.intValue());
    } // fi(DB.pg_note)

    // Poner por defecto la fecha de modificación del registro
    if (!AllVals.containsKey(DB.dt_modified))
      put(DB.dt_modified, dtNow);

    boolean bRetVal = super.store(oConn);

    oStmt = oConn.prepareStatement("UPDATE " + DB.k_contacts + " SET " + DB.nu_notes + "=" + DB.nu_notes + "+1 WHERE gu_contact=?");
    oStmt.setString(1, getString(DB.gu_contact));
    oStmt.executeUpdate();
    oStmt.close();

    return bRetVal;
  } // store

  /**
   * Delete Note
   * k_contact.nu_notes fields is decremented by 1
   * @param oConn Database Connection
   * @return
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    boolean bRetVal = super.delete(oConn);

    PreparedStatement oStmt = oConn.prepareStatement("UPDATE " + DB.k_contacts + " SET " + DB.nu_notes + "=" + DB.nu_notes + "-1 WHERE gu_contact=?");
    oStmt.setString(1, getString(DB.gu_contact));
    oStmt.executeUpdate();
    oStmt.close();

    return bRetVal;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 93;
}