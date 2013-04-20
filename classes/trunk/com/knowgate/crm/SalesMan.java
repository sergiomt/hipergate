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
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.acl.ACLUser;

/**
 * <p>Sales Man</p>
 * <p>Copyright: Copyright (c) KnowGate 2003-2012</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class SalesMan extends DBPersist {

  private ACLUser oUser;

  public SalesMan() {
    super(DB.k_sales_men, "SalesMan");
    oUser=null;
  }

  /**
   * Get user for this sales man
   * @return ACLUser
   */
  public ACLUser getUser() {
    return oUser;
  }

  /**
   * Load sales man and initialize internal user instance
   * @param oConn JDCConnection
   * @param sGuSalesMan String Sales man GUID
   * @return boolean
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, String sGuSalesMan) throws SQLException {
    boolean bRetVal = super.load(oConn, sGuSalesMan);
    if (bRetVal)
      oUser = new ACLUser(oConn, getString(DB.gu_sales_man));
    return bRetVal;
  }
  
  /**
   * Load sales man and initialize internal user instance
   * @param oConn JDCConnection
   * @param PKVals Object[]
   * @return boolean
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    boolean bRetVal = super.load(oConn, PKVals);
    if (bRetVal)
      oUser = new ACLUser(oConn, getString(DB.gu_sales_man));
    return bRetVal;
  }

  /**
   * <p>Store sales man</p>
   * This method initializes internal user inctance if it was not previously set
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException
   */
  public boolean store (JDCConnection oConn) throws SQLException {
    boolean bRetVal = super.store(oConn);
    if (oUser==null)
      oUser = new ACLUser(oConn, getString(DB.gu_sales_man));
    return bRetVal;
  }

  /**
   * Delete sales man.
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return SalesMan.delete(oConn, getString(DB.gu_sales_man));
  }

  /**
   * <p>Delete sales man</p>
   * This method calls k_sp_del_sales_man stored procedure
   * @param oConn JDCConnection
   * @param sSalesManGUID String GUID of sales man to be deleted
   * @return boolean
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sSalesManGUID) throws SQLException {
    CallableStatement oCall;
    Statement oStmt;
    if (DebugFile.trace) {
      DebugFile.writeln("Begin SalesMan.delete([Connection], " + sSalesManGUID + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareCall({ call k_sp_del_sales_man('" + sSalesManGUID + "')}");
    }
    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_POSTGRESQL:
        oStmt = oConn.createStatement();
        oStmt.executeQuery("SELECT k_sp_del_sales_man('" + sSalesManGUID + "')").close();
        oStmt.close();
        oStmt=null;
        break;
      default:
        oCall = oConn.prepareCall("{ call k_sp_del_sales_man('" + sSalesManGUID + "')}");
        oCall.execute();
        oCall.close();
        oCall = null;
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SalesMan.delete()");
    }

    return true;
  } // delete

  /**
   * Get whether a user exists as a sales man or not
   * @param oConn JDCConnection
   * @param sSalesManGUID String sales man GUID
   * @return boolean <b>true</b> if a record with gu_sales_man=sSalesManGUID
   * exists at table k_sales_men, <b>false</b> otherwise
   * @throws SQLException
   */
  public static boolean exists(JDCConnection oConn, String sSalesManGUID) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_sales_men+" WHERE "+DB.gu_sales_man+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sSalesManGUID);
    ResultSet oRSet = oStmt.executeQuery();
    boolean bExists = oRSet.next();
    oRSet.close();
    oStmt.close();
    return bExists;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 97;
}
