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

package com.knowgate.acl;

import java.util.StringTokenizer;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DBSubset;

/**
 * <p>Security Role Groups</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public final class ACLGroup  extends DBPersist {

  /**
   * Default constructor.
   */
  public ACLGroup() {
    super(DB.k_acl_groups, "ACLGroup");
  }

  /**
   * Construct object and set gu_acl_group field.
   * Object is not fully loaded from database.
   * @param sGroupUId Group Unique Identifier
   */
  public ACLGroup(String sGroupUId) {
    super(DB.k_acl_groups, "ACLGroup");
    put(DB.gu_acl_group, sGroupUId);
  }

  // ----------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {

    if (!AllVals.containsKey(DB.gu_acl_group)) {
      put(DB.gu_acl_group, Gadgets.generateUUID());
    }

    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Add User to Group.</p>
   * <p>Insert new register at k_x_group_user table.</p>
   * @param oConn Database Connection
   * @param sIdUser User Unique Identifier.
   * @throws SQLException May throw a primary key constraint violation is user already belongs to group.
   */
  public int addACLUser(JDCConnection oConn, String sIdUser) throws SQLException {
     Statement oStmt;
     int iRetVal;

     if (DebugFile.trace) {
        DebugFile.writeln("Begin ACLGroup.addACLUser(Connection], " + sIdUser + ")");
        DebugFile.incIdent();
     }

     oStmt = oConn.createStatement();

     if (DebugFile.trace)
       DebugFile.writeln("Statement.executeUpdate(INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_acl_group + "," + DB.gu_user + ") VALUES('" + getStringNull(DB.gu_acl_group, "null") + "','" + sIdUser + "')");

     iRetVal = oStmt.executeUpdate("INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_acl_group + "," + DB.gu_user + ") VALUES('" + getString(DB.gu_acl_group) + "','" + sIdUser + "')");
     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ACLGroup.addACLUser() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // addACLUser

  // ----------------------------------------------------------

  /**
   * <p>Add Users to Group.</p>
   * <p>Insert new registers at k_x_group_user table.</p>
   * @param oConn Database Connection
   * @param sUserList A string of comma delimited User GUIDs that must be added to this ACLGroup.
   * @throws SQLException May throw a primary key constraint violation is user already belongs to group.
   */
  public int addACLUsers(JDCConnection oConn, String sUserList) throws SQLException {

     if (DebugFile.trace) {
        DebugFile.writeln("Begin ACLGroup.addACLUsers(Connection], " + sUserList + ")");
        DebugFile.incIdent();
     }

     Statement oStmt;
     int iRetVal = 0;
     StringTokenizer oStrTok = new StringTokenizer(sUserList, ",");
     String sIdUser;

     oStmt = oConn.createStatement();

     while (oStrTok.hasMoreElements()) {
       sIdUser = oStrTok.nextToken();

       if (DebugFile.trace)
         DebugFile.writeln("Statement.executeUpdate(INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_acl_group + "," + DB.gu_user + ") VALUES('" + getStringNull(DB.gu_acl_group, "null") + "','" + sIdUser + "')");

       iRetVal += oStmt.executeUpdate("INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_acl_group + "," + DB.gu_user + ") VALUES('" + getString(DB.gu_acl_group) + "','" + sIdUser + "')");
       oStmt.close();
     } // wend

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ACLGroup.addACLUsers() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // addACLUser

  // ----------------------------------------------------------

  /**
   * <p>Remove User from Group.</p>
   * <p>remove register from k_x_group_user table.</p>
   * @param oConn Database Connection
   * @param sIdUser User Unique Identifier.
   * @throws SQLException
   */

  public int removeACLUser(JDCConnection oConn, String sIdUser) throws SQLException {

    if (DebugFile.trace) {
       DebugFile.writeln("Begin ACLGroup.removeACLUser(Connection], " + sIdUser + ")");
       DebugFile.incIdent();
    }

     int iRetVal;
     Statement oStmt = oConn.createStatement();

     if (DebugFile.trace)
       DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + sIdUser + "' AND " + DB.gu_acl_group + "='" + getStringNull(DB.gu_acl_group, "null") + "'");

     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + sIdUser + "' AND " + DB.gu_acl_group + "='" + getString(DB.gu_acl_group) + "'");
     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ACLGroup.removeACLUser() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // removeACLUser

  // ----------------------------------------------------------

  /**
   * <p>Remove all users from this group.</p>
   * <p>Delete registers from k_x_group_user</p>
   * @param oConn Database connection
   * @throws SQLException
   */
  public int clearACLUsers(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLGroup.clearACLUsers([Connection])");
      DebugFile.incIdent();
    }

     int iRetVal;

     Statement oStmt = oConn.createStatement();

     if (DebugFile.trace) DebugFile.writeln("DELETE FROM " + DB.k_x_group_user + " WHERE " + DB.gu_acl_group + "='" + getStringNull(DB.gu_acl_group, "null") + "'");

     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_user + " WHERE " + DB.gu_acl_group + "='" + getString(DB.gu_acl_group) + "'");

     oStmt.close();

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End ACLGroup.clearACLUsers() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  }  // clearACLUsers

  /**
   * Get users that belong to this group
   * @param oConn JDCConnection
   * @return DBSubset with all the columns from k_users table
   * @throws SQLException
   * @since 3.0
   */
  public DBSubset getACLUsers(JDCConnection oConn) throws SQLException {
    Object aGroup[] = { get(DB.gu_acl_group) };
    DBSubset oUsers = new DBSubset(DB.k_x_group_user+" x,"+DB.k_users+" u",
                                   "u."+DB.gu_user+",u."+DB.dt_created+",u."+DB.id_domain+",u."+
                                   DB.tx_nickname+",u."+DB.tx_pwd+",u."+DB.tx_pwd_sign+",u."+
                                   DB.bo_change_pwd+",u."+DB.bo_searchable+",u."+
                                   DB.bo_active+",u."+DB.len_quota+",u."+DB.max_quota+",u."+
                                   DB.tp_account+",u."+DB.id_account+",u."+
                                   DB.dt_last_update+",u."+DB.dt_last_visit+",u."+
                                   DB.dt_cancel+",u."+DB.tx_main_email+",u."+
                                   DB.tx_alt_email+",u."+DB.nm_user+",u."+
                                   DB.tx_surname1+",u."+DB.tx_surname2+",u."+
                                   DB.tx_challenge+",u."+DB.tx_reply+",u."+
                                   DB.dt_pwd_expires+",u."+DB.gu_category+",u."+
                                   DB.gu_workarea+",u."+DB.nm_company+",u."+
                                   DB.de_title+",u."+DB.id_gender+",u."+DB.dt_birth+",u."+
                                   DB.ny_age+",u."+DB.marital_status+",u."+
                                   DB.tx_education+",u."+DB.icq_id+",u."+
                                   DB.sn_passport+",u."+DB.tp_passport+",u."+
                                   DB.tx_comments,
                                   "x."+DB.gu_acl_group + "=? AND "+
                                   "x."+DB.gu_user+"=u."+DB.gu_user,10);

    oUsers.load (oConn, aGroup);
    return oUsers;
  } // getACLUsers

  // **********************************************************
  // Metodos Estaticos

  /**
   * <p>Get Group Unique Id. from its name.</p>
   * <p>This method executes a SQL query with a ResultSet</p>
   * @param oConn Connection Database Connection
   * @param iDomainId int Domain Identifier to with Group belongs
   * @param sGroupNm String Group Name
   * @return Group Unique Identifier or <b>null</b> if no group with such name was found at given domain.
   * @throws SQLException
   * @since 3.0
   */

  public static String getIdFromName(Connection oConn, int iDomainId, String sGroupNm) throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;
    oStmt = oConn.prepareStatement("SELECT " + DB.gu_acl_group + " FROM " + DB.k_acl_groups  + " WHERE " + DB.id_domain + "=? AND " + DB.nm_acl_group + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt   (1, iDomainId);
    oStmt.setString(2, sGroupNm);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();
    return sRetVal;
  }

  /**
   * <p>Get Group Unique Id. from its name.</p>
   * <p>This method calls k_sp_get_group_id stored procedure.</p>
   * @param oConn JDCConnection
   * @param iDomainId int Domain Identifier to with Group belongs
   * @param sGroupNm Group Name
   * @return Group String Unique Identifier or <b>null</b> if no group with such name was found at given domain.
   * @throws SQLException
   */

  public static String getIdFromName(JDCConnection oConn, int iDomainId, String sGroupNm) throws SQLException {
     String sRetVal;

     switch (oConn.getDataBaseProduct()) {

       case JDCConnection.DBMS_MYSQL:
       case JDCConnection.DBMS_MSSQL:
       case JDCConnection.DBMS_ORACLE:
         sRetVal = DBPersist.getUIdFromName(oConn, new Integer(iDomainId), sGroupNm, "k_sp_get_group_id");
         break;
       default:
         sRetVal = getIdFromName((Connection) oConn, iDomainId, sGroupNm);
     } // end switch

     return sRetVal;
  } // getIdFromName

  // ----------------------------------------------------------

  /**
   * <p>Delete Group</p>
   * <p>Call k_sp_del_group stored procedure</p>
   * @param oConn Database Connection
   * @param sGroupGUID Group Unique Identifier
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sGroupGUID) throws SQLException {
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLGroup.delete([Connection], " + sGroupGUID + ")");
      DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_POSTGRESQL:
        Statement oStmt = oConn.createStatement();
        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT k_sp_del_group ('" + sGroupGUID + "'))");
        ResultSet oRSet = oStmt.executeQuery("SELECT k_sp_del_group ('" + sGroupGUID + "')");
        oRSet.close();
        oStmt.close();
        bRetVal = true;
        break;
      default:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_group ('" + sGroupGUID + "') })");
        CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_group ('" + sGroupGUID + "') }");
        bRetVal = oCall.execute();
        oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACLGroup.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 3;

} // ACLGroup
