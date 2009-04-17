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

package com.knowgate.billing;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.Types;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.misc.Gadgets;

/**
 * <p>Billing Accounts Support for Application Service Providers</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class Account extends DBPersist {
  public Account() {
    super(DB.k_accounts, "Account");
  }

  // ----------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());
    java.math.BigDecimal d;

    if (!AllVals.containsKey(DB.id_account)) {
      String sNextAccount = Gadgets.leftPad(String.valueOf(DBBind.nextVal(oConn, "seq_" + DB.k_accounts)), '0', 10);
      put (DB.id_account, sNextAccount);
    }

    replace(DB.dt_modified, dtNow);

    return super.store(oConn);
  } // store

  // **********************************************************
  // Static Methods

  /**
   * <p>Get User Account Type</p>
   * In the standard version there are 3 account types:<br>
   * 'C' for Corporate Accounts, those having its own domain and a variable number or Users.<br>
   * 'P' for Professional Accounts, those sharing a domain and having a single User.<br>
   * 'S' for System Accounts, those having special priviledges for system administration.
   * @param oConn Database Connection
   * @param sUserId User Unique Identifier (k_users table primary key)
   * @return User Account Type
   * @throws SQLException
   */
  public static String getUserAccountType(JDCConnection oConn, String sUserId) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    String sTp;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT k_get_account_tp ('" + sUserId + "')");
      oRSet.next();
      sTp = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
    }
    else {
      oCall = oConn.prepareCall("{ call k_get_account_tp (?,?) }");

      oCall.setString(1, sUserId);
      oCall.registerOutParameter(2, Types.CHAR);

      oCall.execute();

      if (JDCConnection.DBMS_ORACLE==oConn.getDataBaseProduct())
        sTp = oCall.getString(2);
      else
        sTp = oCall.getString(2);

      if (sTp!=null) sTp = sTp.trim();

      oCall.close();
    }
    return sTp;
  } // getUserAccountType()

  // ----------------------------------------------------------

  /**
   * <p>Get User Account Status.</p>
   * @param oConn Database Connection
   * @param sAccId Account Identifier
   * @return <b>true</b> if account is valid and active, <b>false</b> otherwise.
   * @throws SQLException
   */
  public static boolean checkStatus (JDCConnection oConn, String sAccId) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    short iActive;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT k_check_account ('" + sAccId + "')");
      oRSet.next();
      iActive = oRSet.getShort(1);
      oRSet.close();
      oStmt.close();
    }
    else {
      oCall = oConn.prepareCall("{ call k_check_account (?,?) }");
      oCall.setString(1, sAccId);
      oCall.registerOutParameter(2, Types.SMALLINT);
      oCall.execute();
      iActive = oCall.getShort(2);
      oCall.close();
    }

    return ((short)0!=iActive);

  } // checkStatus

  // ----------------------------------------------------------

  /**
   * <p>Get number of days left until account automatically expires.<p>
   * @param oConn Database Connection
   * @param sAccId Account Identifier
   * @return Number of days left for expiration.
   * @throws SQLException
   */
  public static int daysLeft (JDCConnection oConn, String sAccId) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    int iDaysLeft;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT k_get_account_days_left ('" + sAccId + "')");
      oRSet.next();
      iDaysLeft = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();
    }
    else {
      oCall = oConn.prepareCall("{ call k_get_account_days_left (?,?) }");
      oCall.setString(1, sAccId);
      oCall.registerOutParameter(2, Types.INTEGER);
      oCall.execute();
      iDaysLeft = oCall.getInt(2);
      oCall.close();
    }

    return iDaysLeft;
  } // daysLeft

  // ----------------------------------------------------------

  /**
   * <p>Find out whether or not and Account is in Trial Mode.</p>
   * @param oConn Database Connection
   * @param sAccId Account Identifier
   * @return <b>true</b> if account is in trial mode, <b>false</b> otherwise.
   * @throws SQLException
   */
  public static boolean isTrial (JDCConnection oConn, String sAccId) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    CallableStatement oCall;
    short iTrial;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT k_get_account_trial ('" + sAccId + "')");
      oRSet.next();
      iTrial = oRSet.getShort(1);
      oRSet.close();
      oStmt.close();
    }
    else {
      oCall = oConn.prepareCall("{ call k_get_account_trial (?,?) }");
      oCall.setString(1, sAccId);
      oCall.registerOutParameter(2, Types.SMALLINT);
      oCall.execute();
      iTrial = oCall.getShort(2);
      oCall.close();
    }

    return ((short)0!=iTrial);
  } // isTrial

  // **********************************************************
  // Variables Estaticas

  public static final short ClassId = 6;

  public static final String TYPE_CORPORATE = "C";
  public static final String TYPE_PROFFESIONAL = "T";
  public static final String TYPE_SYSTEM = "S";

} // Account