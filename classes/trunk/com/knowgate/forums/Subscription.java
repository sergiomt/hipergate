/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

package com.knowgate.forums;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

/**
 * <p>NewsGroup Subscription</p>
 * <p>Handles subscriptions of users from k_users table to newsgroups from k_newsgroups table</p>
 * @author Sergio Montoro Ten
 * @version 2.0
 */

public class Subscription extends DBPersist {

  /**
   * Default constructor
   */
  public Subscription() {
    super(DB.k_newsgroup_subscriptions, "Subscription");
  }

  public Subscription(JDCConnection oConn, String sNewsGroupId, String sUserId)
    throws SQLException {

    super(DB.k_newsgroup_subscriptions, "Subscription");

    load (oConn, new Object[]{sNewsGroupId, sUserId});
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Subscribe ACLUser to a NewsGroup</p>
   * <p>Newly created subscriptions are activated by default.</p>
   * @param oConn JDBC Database Connection
   * @param sNewsGroupId NewsGroup GUID
   * @param sUserId ACLUser GUID
   * @param sMessageFormat Message Format {TXT | HTM}
   * @param sUserId iMessagesGrouping Message Grouping { GROUP_NONE | GROUP_DIGEST }
   * @return <b>true</b> if ACLUser was successfully subscribed to NewsGroup, <b>false</b> if no ACLUser with such GUID was found at k_users table.
   * @throws SQLException
   */
  public static boolean subscribe (JDCConnection oConn, String sNewsGroupId, String sUserId, String sMessageFormat, short iMessagesGrouping)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Subscription.subscribe ([Connection], " + sNewsGroupId + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    String sTxEmail;

    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery (SELECT " + DB.tx_main_email + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "='" + sUserId + "')");

    ResultSet oRSet = oStmt.executeQuery("SELECT " + DB.tx_main_email + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "='" + sUserId + "'");

    if (oRSet.next())
      sTxEmail = oRSet.getString(1);
    else
      sTxEmail = null;

    oRSet.close();
    oStmt.close();

    if (null!=sTxEmail) {
      Subscription oUsrSubs = new Subscription();

      oUsrSubs.put(DB.gu_newsgrp, sNewsGroupId);
      oUsrSubs.put(DB.gu_user, sUserId);
      oUsrSubs.put(DB.id_msg_type, sMessageFormat);
      oUsrSubs.put(DB.tp_subscrip, iMessagesGrouping);
      oUsrSubs.put(DB.tx_email, sTxEmail);

      oUsrSubs.store(oConn);
    } // fi (sTxEmail)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Subscription.subscribe() : " + (null!=sTxEmail ? sTxEmail : "false"));
    }

    return (null!=sTxEmail);
  } // Subscribe

  //----------------------------------------------------------------------------

  /**
   * <p>Subscribe ACLUser to a NewsGroup</p>
   * <p>Message format is TXT with no grouping by default.</p>
   * @param oConn JDBC Database Connection
   * @param sNewsGroupId NewsGroup GUID
   * @param sUserId ACLUser GUID
   * @return <b>true</b> if ACLUser was successfully subscribed to NewsGroup, <b>false</b> if no ACLUser with such GUID was found at k_users table.
   * @throws SQLException
   */
  public static boolean subscribe (JDCConnection oConn, String sNewsGroupId, String sUserId)
    throws SQLException {

    return subscribe (oConn, sNewsGroupId, sUserId, "TXT", Subscription.GROUP_NONE);
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Unsubscribe ACLUser to a NewsGroup</p>
   * <p>The ACLUser is removed from table k_newsgroup_subscriptions for given NewsGroup.<br>
   * If you want to remove an e-mail directly first call ACLUser.getIdFromEmail() method.<br></p>
   * @param oConn JDBC Database Connection
   * @param sNewsGroupId NewsGroup GUID
   * @param sUserId ACLUser GUID
   * @return <b>true</b> if ACLUser was successfully unsubscribed from NewsGroup, <b>false</b> if no ACLUser with such GUID was found at k_newsgroup_subscriptions.
   * @throws SQLException
   */
  public static boolean unsubscribe (JDCConnection oConn, String sNewsGroupId, String sUserId)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Subscription.unsubscribe ([Connection], " + sNewsGroupId + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    Statement oStmt = oConn.createStatement();

    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate (DELETE FROM " + DB.k_newsgroup_subscriptions + " WHERE " + DB.gu_newsgrp + "='" + sNewsGroupId + "' AND " + DB.gu_user + "='" + sUserId + "')");

    int iAffected = oStmt.executeUpdate("DELETE FROM " + DB.k_newsgroup_subscriptions + " WHERE " + DB.gu_newsgrp + "='" + sNewsGroupId + "' AND " + DB.gu_user + "='" + sUserId + "'");

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Subscription.unsubscribe() : " + (iAffected!=0 ? "true" : "false"));
    }

    return (iAffected!=0);
  } // Unsubscribe

  //----------------------------------------------------------------------------

  /**
   * <p>Activate a Subscription</p>
   * <p>Set k_newsgroup_subscriptions.id_status=ACTIVE</p>
   * @param oConn JDBC Database Connection
   * @param sNewsGroupId Newsgroup GUID
   * @param sUserId ACLUser GUID
   * @return <b>true</b> if subscription from ACLUser was successfully activated, <b>false</b> if no ACLUser with such GUID was found at k_newsgroup_subscriptions.
   * @throws SQLException
   */
  public static boolean activate (JDCConnection oConn, String sNewsGroupId, String sUserId)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Subscription.activate ([Connection], " + sNewsGroupId + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    Statement oStmt = oConn.createStatement();

    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_newsgroup_subscriptions + " SET " + DB.id_status + "=" + String.valueOf(ACTIVE) + " WHERE " + DB.gu_newsgrp + "='" + sNewsGroupId + "' AND " + DB.gu_user + "='" + sUserId + "')");

    int iAffected = oStmt.executeUpdate("UPDATE " + DB.k_newsgroup_subscriptions + " SET " + DB.id_status + "=" + String.valueOf(ACTIVE) + " WHERE " + DB.gu_newsgrp + "='" + sNewsGroupId + "' AND " + DB.gu_user + "='" + sUserId + "'");

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Subscription.activate() : " + (iAffected!=0 ? "true" : "false"));
    }

    return (iAffected!=0);
  } // activate

  //----------------------------------------------------------------------------

  /**
   * <p>Deactivate a Subscription</p>
   * <p>Set k_newsgroup_subscriptions.id_status=UNACTIVE</p>
   * @param oConn JDBC Database Connection
   * @param sNewsGroupId Newsgroup GUID
   * @param sUserId ACLUser GUID
   * @return <b>true</b> if subscription from ACLUser was successfully deactivated, <b>false</b> if no ACLUser with such GUID was found at k_newsgroup_subscriptions.
   * @throws SQLException
   */
  public static boolean deactivate (JDCConnection oConn, String sNewsGroupId, String sUserId)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Subscription.deactivate ([Connection], " + sNewsGroupId + "," + sUserId + ")");
      DebugFile.incIdent();
    }

    Statement oStmt = oConn.createStatement();

    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_newsgroup_subscriptions + " SET " + DB.id_status + "=" + String.valueOf(UNACTIVE) + " WHERE " + DB.gu_newsgrp + "='" + sNewsGroupId + "' AND " + DB.gu_user + "='" + sUserId + "')");

    int iAffected = oStmt.executeUpdate("UPDATE " + DB.k_newsgroup_subscriptions + " SET " + DB.id_status + "=" + String.valueOf(UNACTIVE) + " WHERE " + DB.gu_newsgrp + "='" + sNewsGroupId + "' AND " + DB.gu_user + "='" + sUserId + "'");

    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Subscription.deactivate() : " + (iAffected!=0 ? "true" : "false"));
    }

    return (iAffected!=0);
  } // deactivate

  //----------------------------------------------------------------------------

  public static final short UNACTIVE = 0;
  public static final short ACTIVE = 1;
  public static final short ACTIVE_MY_FOR_THREADS_ONLY = 2;

  public static final short GROUP_NONE = 1;
  public static final short GROUP_DIGEST = 2;
}