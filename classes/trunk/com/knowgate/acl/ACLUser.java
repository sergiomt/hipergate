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

import java.util.Arrays;
import java.util.Date;
import java.util.StringTokenizer;

import java.math.BigDecimal;

import java.io.IOException;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import java.rmi.RemoteException;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.hipergate.Category;
import com.knowgate.hipergate.datamodel.ModelManager;
import com.knowgate.cache.DistributedCachePeer;

import com.knowgate.misc.Base64Encoder;
import com.knowgate.misc.Base64Decoder;
import com.knowgate.misc.Gadgets;

/**
 * <p>Object mapping for k_users table registers</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public final class ACLUser extends DBPersist {

  /**
   * Default constructor.
   */
  public ACLUser() {
   super(DB.k_users, "ACLUser");
  }

  /**
   * <p>Constructs ACLUser and set GUID</p>
   * Does not load any fields from database.
   * @param sUserGUID user Unique Identifier (gu_user field at k_users table)
   * @throws SQLException
   */

  public ACLUser(String sUserGUID) throws SQLException {
    super(DB.k_users,"ACLUser");

    put(DB.gu_user, sUserGUID);
  }

  /**
   * <p>Constructs ACLUser and load attributes from k_users table</p>
   * @param oConn Database Connection
   * @param sUserGUID user Unique Identifier (gu_user field at k_users table)
   * @throws SQLException
   */

  public ACLUser(JDCConnection oConn, String sUserGUID) throws SQLException {
    super(DB.k_users,"ACLUser");

    Object aUser[] = { sUserGUID };

    load (oConn, aUser);
  }

  // ----------------------------------------------------------

  /**
   * Get full name
   * @return trim(nm_user+tx_surname1+tx_surname2)
   * @since 4.0
   */
  public String getFullName() {
	return (getStringNull(DB.nm_user,"")+" "+getStringNull(DB.tx_surname1,"")+" "+getStringNull(DB.tx_surname2,"")).trim();
  }

  // ----------------------------------------------------------

  /**
   * <p>Get Addresses associated with user at k_x_addr_user table.</p>
   * @param oConn Database Connection
   * @return A {@link DBSubset} with a 3 columns containing
   * Address Unique Identifier (gu_address), Address Ordinal Position (ix_address)
   * and Address Location Type (tp_location).
   * @throws SQLException
   * @see {@link Address}
   */
  public DBSubset getAddresses(JDCConnection oConn) throws SQLException {
    Object aUser[] = { get(DB.gu_user) };
    oAddresses = new DBSubset(DB.k_x_addr_user,DB.gu_address + "," + DB.ix_address + "," + DB.tp_location, DB.gu_user + "=?",10);

    oAddresses.load (oConn, aUser);
    return oAddresses;
  }

  // ----------------------------------------------------------

  /**
   * </p>Get security role groups to witch this user belongs looking a k_x_group_user table.</p>
   * @param oConn Database Connection
   * @return A {@link DBSubset} with a 1 column containing each group unique identifier (gu_acl_group).
   * @throws SQLException
   */
  public DBSubset getGroups(JDCConnection oConn) throws SQLException {
    Object aUser[] = { get(DB.gu_user) };
    oGroups = new DBSubset(DB.k_x_group_user,DB.gu_acl_group,DB.gu_user + "=?",10);

    oGroups.load (oConn, aUser);
    return oGroups;
  }

  // ----------------------------------------------------------

  /**
   * <p>Add User to Groups.</p>
   * <p>Insert new registers at k_x_group_user table.</p>
   * @param oConn Database Connection
   * @param sGroupList A string of comma delimited ACLGroup GUIDs to with this ACLUser must be added.
   * @throws SQLException May throw a primary key constraint violation if user already belongs to group.
   */
  public int addToACLGroups(JDCConnection oConn, String sGroupList) throws SQLException {

     if (DebugFile.trace) {
        DebugFile.writeln("Begin ACLUser.addToACLGroups(Connection], " + sGroupList + ")");
        DebugFile.incIdent();
     }

     Statement oStmt;
     int iRetVal = 0;
     StringTokenizer oStrTok = new StringTokenizer(sGroupList, ",");
     String sIdGroup;

     oStmt = oConn.createStatement();

     while (oStrTok.hasMoreElements()) {
       sIdGroup = oStrTok.nextToken();

       if (DebugFile.trace)
         DebugFile.writeln("Statement.executeUpdate(INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_user + "," + DB.gu_acl_group + ") VALUES('" + getStringNull(DB.gu_user, "null") + "','" + sIdGroup + "')");

       iRetVal += oStmt.executeUpdate("INSERT INTO " + DB.k_x_group_user + "(" + DB.gu_user + "," + DB.gu_acl_group + ") VALUES('" + getString(DB.gu_user) + "','" + sIdGroup + "')");
     } // wend

     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ACLUser.addToACLGroups() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // addToACLGroups

  // ----------------------------------------------------------

  /**
   * <p>Find out is this user has administrator.</p>
   * <p>A user may have administrator priviledges in two ways:<br>
   * 1.- It can belong to the group gu_admins from k_domains table.<br>
   * 2.- Its user identifier may be the one at gu_owner field of k_domains table.<br></p>
   * <p>The domain owner is a special kind of administrator user that cannot be deleted from domain.</p>
   * @param oConn Database Connection
   * @return true is user has adminsitrator priviledges, false otherwise.
   * @throws IllegalStateException if id_domain or gu_user is not set
   * @throws SQLException
   */
  public boolean isDomainAdmin(JDCConnection oConn) throws SQLException, IllegalStateException {
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bAdmin;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin ACLUser.sDomainAdmin(Connection])");
       DebugFile.incIdent();
    }

    if (isNull(DB.id_domain)) {
      if (DebugFile.trace) {
        DebugFile.writeln("ERROR id_domain not set");
        DebugFile.decIdent();
      }

      throw new IllegalStateException("ACLUSer.isDomainAdmin() Property id_domain is not set");
    }

    if (isNull(DB.gu_user)) {
      if (DebugFile.trace) {
        DebugFile.writeln("ERROR gu_user not set");
        DebugFile.decIdent();
      }

      throw new IllegalStateException("ACLUSer.isDomainAdmin() Property gu_user is not set");
    }

    if (DebugFile.trace)
       DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM " + DB.k_x_group_user + " x," + DB.k_domains + " d WHERE d." + DB.id_domain + "=" + String.valueOf(getInt(DB.id_domain)) + " AND x." + DB.gu_user + "='" + getString(DB.gu_user) + "'" + " AND x." + DB.gu_acl_group + "=d." + DB.gu_admins + ")");

    int iDomainId;
    if (isNull(DB.id_domain))
      iDomainId  = -1;
    else
      iDomainId  = getInt(DB.id_domain);

    oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_x_group_user + " x," + DB.k_domains + " d WHERE d." + DB.id_domain + "=?" + " AND x." + DB.gu_user + "=?" + " AND x." + DB.gu_acl_group + "=d." + DB.gu_admins, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1,iDomainId);
    oStmt.setString(2,getStringNull(DB.gu_user,null));
    oRSet = oStmt.executeQuery();
    bAdmin = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (!bAdmin) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_owner + " FROM " + DB.k_domains + " WHERE " + DB.id_domain + "=" + String.valueOf(getInt(DB.id_domain)) + ")");

      oStmt = oConn.prepareStatement("SELECT " + DB.gu_owner + " FROM " + DB.k_domains + " WHERE " + DB.id_domain + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setInt(1,getInt(DB.id_domain));
      oRSet = oStmt.executeQuery();

      if (oRSet.next())
        if (null!=oRSet.getObject(1))
          bAdmin = oRSet.getString(1).equals(getString(DB.gu_user));
        else
          bAdmin = false;
      else
        bAdmin = false;

      oRSet.close();
      oStmt.close();
    }

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End ACLUser.isDomainAdmin() : " + String.valueOf(bAdmin));
    }

    return bAdmin;
  } // isDomainAdmin

  // ----------------------------------------------------------

  /**
   * <p>Store ACLUser</p>
   * If gu_user is not set then a new GUID is assigned.<br>
   * If dt_last_update is not set then current system date is assigned.<br>
   * If len_quota is not set then zero is assigned.<br>
   * If max_quota is not set then 100Mb assigned.<br>
   * Syntax for tx_main_email and tx_alt_email is verified if these fields are not null
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    boolean bRetVal;
    Object oDomainId;
    String NmWorkArea;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin ACLUser.store([Connection])");
       DebugFile.incIdent();
    }

    if (!AllVals.containsKey(DB.gu_user))
      put (DB.gu_user, Gadgets.generateUUID());

    if (!AllVals.containsKey(DB.dt_last_update))
      put (DB.dt_last_update, new java.sql.Timestamp(DBBind.getTime()));

    if (!AllVals.containsKey(DB.len_quota))
      put (DB.len_quota, new BigDecimal(0d));

    if (!AllVals.containsKey(DB.max_quota))
      put (DB.max_quota, new BigDecimal(104857600d));

    if (AllVals.containsKey(DB.gu_workarea) && AllVals.containsKey(DB.id_domain)) {
      if (!isNull(DB.gu_workarea)) {

        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.id_domain + "," + DB.nm_workarea + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "='" + getString(DB.gu_workarea) + "')");

        oStmt = oConn.prepareStatement("SELECT " + DB.id_domain + "," + DB.nm_workarea + " FROM " + DB.k_workareas + " WHERE " + DB.gu_workarea + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, getString(DB.gu_workarea));
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          oDomainId = oRSet.getObject(1);
          NmWorkArea = oRSet.getString(2);
        }
        else {
          oDomainId = null;
          NmWorkArea = null;
        }
        oRSet.close();
        oStmt.close();

        if (null!=oDomainId) {
          if (!oDomainId.toString().equals(get(DB.id_domain).toString()))
            throw new SQLException("ACLUSer.store() Integrity constraint violation: WorkArea " + NmWorkArea + " must belong to Domain " + oDomainId.toString() + " as User does but it belongs to " + oDomainId.toString(), "23000");
        } // fi (null!=oDomainId)

      } // fi (null!=gu_workarea)
    } // fi (containsKey(DB.gu_workarea) && containsKey(DB.id_domain))

    String sMailAddr = getStringNull(DB.tx_main_email,"nobody@nodomain.com");
    if (!Gadgets.checkEMail(sMailAddr) && sMailAddr.length()>0) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new SQLException("ACLUSer.store() Check constraint violation: main e-mail address "+getString(DB.tx_main_email)+" does not have a valid syntax", "23000");
    }

    sMailAddr = getStringNull(DB.tx_alt_email,"nobody@nodomain.com");
    if (!Gadgets.checkEMail(sMailAddr) && sMailAddr.length()>0) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new SQLException("ACLUSer.store() Check constraint violation: alternative e-mail address "+getString(DB.tx_alt_email)+" does not have a valid syntax", "23000");
    }

    bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
       DebugFile.writeln("End ACLUser.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {
    try {
      return ACLUser.delete(oConn, getString(DB.gu_user));
    } catch (IOException ioe) {
      throw new SQLException ("IOException " + ioe.getMessage());
    }
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Remove user from all security role groups</p>
   * @param oConn Database Connection
   * @return Count of groups from witch user was removed.
   * @throws SQLException
   */
  public int clearACLGroups(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLUser.clearACLGroups([Connection])");
      DebugFile.incIdent();
    }

     int iRetVal;

     Statement oStmt = oConn.createStatement();
     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + getString(DB.gu_user) + "'");
     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ACLUser.clearACLGroups() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // clearACLGroups

  // ----------------------------------------------------------

  /**
   * <p>Remove User from Group.</p>
   * <p>remove register from k_x_group_user table.</p>
   * @param oConn Database Connection
   * @param sIdGroup Group Unique Identifier.
   * @throws SQLException
   */

  public int removeFromACLGroup(JDCConnection oConn, String sIdGroup) throws SQLException {

    if (DebugFile.trace) {
       DebugFile.writeln("Begin ACLUser.removeFromACLGroup(Connection], " + sIdGroup + ")");
       DebugFile.incIdent();
    }

     int iRetVal;
     Statement oStmt = oConn.createStatement();

     if (DebugFile.trace)
       DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + getStringNull(DB.gu_user, "null") + "' AND " + DB.gu_acl_group + "='" + sIdGroup + "'");

     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_user + " WHERE " + DB.gu_user + "='" + getString(DB.gu_user) + "' AND " + DB.gu_acl_group + "='" + sIdGroup + "'");
     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ACLUser.removeFromACLGroup() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // removeFromACLGroup

  // ---------------------------------------------------------------------------

  /**
   * <p>Get GUID of user mail root category</p>
   * The user mail root category is always named <i>DOMAIN</i>_<i>nickname</i>_mail
   * at nm_category field of k_categories.<br>
   * If there is no category named <i>DOMAIN</i>_<i>nickname</i>_mail but the
   * user has his gu_category field set at k_users table then this method tries
   * to create a new mail root category.
   * @param oConn Database Connection
   * @return a gu_category value from k_categories or <b>null</b> if this user
   * does not have a mail root category and a new one could not be created
   * @throws SQLException
   */
  public String getMailRoot (JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt;
    CallableStatement oCall;
    ResultSet oRSet;
    String sRetVal;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin ACLUser.getMailRoot(Connection])");
       DebugFile.incIdent();
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_POSTGRESQL:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT k_sp_get_user_mailroot('"+getStringNull(DB.gu_user,"null")+"'))");
        oStmt = oConn.prepareStatement("SELECT k_sp_get_user_mailroot(?)");
        oStmt.setString(1, getString(DB.gu_user));
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sRetVal = oRSet.getString(1);
        else
          sRetVal = null;
        oRSet.close();
        oStmt.close();
        break;
      default:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_get_user_mailroot('"+getStringNull(DB.gu_user,"null")+"',?) }");
        oCall = oConn.prepareCall("{ call k_sp_get_user_mailroot(?,?) }");
        oCall.setString(1, getString(DB.gu_user));
        oCall.registerOutParameter(2, java.sql.Types.CHAR);
        oCall.execute();
        sRetVal = oCall.getString(2);
        oCall.close();
        break;
    }

    if (sRetVal==null) {
      if (DebugFile.trace) DebugFile.writeln("user mail root not found creating new one...");
      ACLUser oMe = new ACLUser();
      if (oMe.load(oConn, new Object[]{getString(DB.gu_user)})) {
        if (!oMe.isNull(DB.gu_category)) {
          ACLDomain oDom = new ACLDomain(oConn, oMe.getInt(DB.id_domain));

          Statement oInsr = oConn.createStatement();
          String sNewGUID = Gadgets.generateUUID();

          String sSQL = "INSERT INTO "+DB.k_categories+" ("+DB.gu_category+","+DB.gu_owner+","+DB.nm_category+","+DB.bo_active+","+DB.dt_modified+","+DB.nm_icon+","+DB.id_doc_status+","+DB.nm_icon2+") VALUES ('"+sNewGUID+"','"+oMe.getString(DB.gu_user)+"','"+oDom.getString(DB.nm_domain)+"_"+oMe.getString(DB.tx_nickname)+"_mail',1,NULL,'myemailc_16x16.gif',1,'myemailo_16x16.gif')";
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate("+sSQL+")");
          oInsr.executeUpdate(sSQL);

          String[] aLabels = DBLanguages.SupportedLanguages;

          for (int l=0; l<aLabels.length; l++)
            oInsr.executeUpdate("INSERT INTO "+DB.k_cat_labels+" ("+DB.gu_category+","+DB.id_language+","+DB.tr_category+","+DB.url_category+") VALUES ('"+sNewGUID+"','"+aLabels[l]+"','e-mail',NULL)");

          oInsr.executeUpdate("INSERT INTO "+DB.k_x_cat_user_acl+" ("+DB.gu_category+","+DB.gu_user+","+DB.acl_mask+") VALUES ('"+sNewGUID+"','"+oMe.getString(DB.gu_user)+"',2147483647)");

          if (!oMe.getString(DB.gu_user).equals(oDom.getString(DB.gu_owner)))
            oInsr.executeUpdate("INSERT INTO "+DB.k_x_cat_user_acl+" ("+DB.gu_category+","+DB.gu_user+","+DB.acl_mask+") VALUES ('"+sNewGUID+"','"+oDom.getString(DB.gu_owner)+"',2147483647)");

          sSQL = "INSERT INTO "+DB.k_cat_tree+" ("+DB.gu_parent_cat+","+DB.gu_child_cat+") VALUES ('"+oMe.getString(DB.gu_category)+"','"+sNewGUID+"')";
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate("+sSQL+")");
          oInsr.executeUpdate(sSQL);

          oInsr.close();
          sRetVal = sNewGUID;
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("user " + getString(DB.gu_user) + " has not home category");
        }
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("unable to load user " + getString(DB.gu_user));
      }
    }
    else
      sRetVal = sRetVal.trim();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End ACLUser.getMailRoot() : " + String.valueOf(sRetVal));
    }

    return sRetVal;
  } // getMailRoot

  // ---------------------------------------------------------------------------

  /**
   * <p>Get GUID of user mail folder category</p>
   * The Inbox category is where messages downloaded from the mail server are cached by default.
   * The user mail inbox category is always named <i>DOMAIN</i>_<i>nickname</i>_inbox at nm_category field of k_categories.<br>
   * If there is no category named <i>DOMAIN</i>_<i>nickname</i>_inbox but the
   * user has a mail root category then this method tries to create a new mail
   * inbox category under mail root.<BR>
   * @param oConn Database Connection
   * @param sFolderName One of { "inbox", "drafts", "deleted", "sent", "spam" }
   * @return a gu_category value from k_categories or <b>null</b> if this user
   * does not have a mail inbox category and a new one could not be created
   * @throws SQLException
   * @throws NullPointerException if sFolderName is <b>null</b> or empty string
   */

  public String getMailFolder (JDCConnection oConn, String sFolderName)
    throws SQLException {
    PreparedStatement oStmt;
    CallableStatement oCall;
    ResultSet oRSet;
    String sRetVal;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin ACLUser.getMailFolder([JDCConnection],"+sFolderName+")");
       DebugFile.incIdent();
    }

    if (sFolderName==null) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("ACLUser.getMailFolder() folder name cannot be null");
    }
    if (sFolderName.length()==0) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("ACLUser.getMailFolder() folder name cannot be an empty string");
    }

    String sIcon1 = sFolderName.equalsIgnoreCase("inbox") ? "mailbox_16x16.gif" : "folderclosed_16x16.gif";
    String sIcon2 = sFolderName.equalsIgnoreCase("inbox") ? "mailbox_16x16.gif" : "folderopen_16x16.gif";

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_POSTGRESQL:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT k_sp_get_user_mailfolder('"+getStringNull(DB.gu_user,"null")+"','"+sFolderName+"')");

        oStmt = oConn.prepareStatement("SELECT k_sp_get_user_mailfolder(?,?)");
        oStmt.setString(1, getString(DB.gu_user));
        oStmt.setString(2, sFolderName);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sRetVal = oRSet.getString(1);
        else
          sRetVal = null;
        oRSet.close();
        oStmt.close();
        break;
      default:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_get_user_mailfolder('"+getStringNull(DB.gu_user,"null")+"','"+sFolderName+"',?)})");
        oCall = oConn.prepareCall("{ call k_sp_get_user_mailfolder(?,?,?) }");
        oCall.setString(1, getString(DB.gu_user));
        oCall.setString(2, sFolderName);
        oCall.registerOutParameter(3, java.sql.Types.CHAR);
        oCall.execute();
        sRetVal = oCall.getString(3);
        oCall.close();
        break;
    }

    if (sRetVal==null) {
      if (DebugFile.trace) DebugFile.writeln("Creating new mail folder " + sFolderName + " for user " + getStringNull(DB.gu_user,"null"));
      ACLUser oMe = new ACLUser();
      if (oMe.load(oConn, new Object[] {getString(DB.gu_user)})) {
        if (!oMe.isNull(DB.gu_category)) {
          String sGuMailRoot = getMailRoot(oConn);
          if (sGuMailRoot!=null) {
            ACLDomain oDom = new ACLDomain(oConn, oMe.getInt(DB.id_domain));

            Statement oInsr = oConn.createStatement();
            String sNewGUID = Gadgets.generateUUID();

            String sSQL = "INSERT INTO "+DB.k_categories+" ("+DB.gu_category+","+DB.gu_owner+","+DB.nm_category+","+DB.bo_active+","+DB.dt_modified+","+DB.nm_icon+","+DB.id_doc_status+","+DB.nm_icon2+","+DB.len_size+") VALUES ('"+sNewGUID+"','"+oMe.getString(DB.gu_user)+"','"+oDom.getString(DB.nm_domain)+"_"+oMe.getString(DB.tx_nickname)+"_"+sFolderName+"',1,NULL,'"+sIcon1+"',1,'"+sIcon2+"',0)";

            if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");

            oInsr.executeUpdate(sSQL);

            String[] aLabels = DBLanguages.SupportedLanguages;

            for (int l=0; l<aLabels.length; l++) {
              sSQL = "INSERT INTO "+DB.k_cat_labels+" ("+DB.gu_category+","+DB.id_language+","+DB.tr_category+","+DB.url_category+") VALUES ('"+sNewGUID+"','"+aLabels[l]+"','"+sFolderName.substring(0,1).toUpperCase()+sFolderName.substring(1).toLowerCase()+"',NULL)";
              if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
              oInsr.executeUpdate(sSQL);
            }

            sSQL = "INSERT INTO "+DB.k_x_cat_user_acl+" ("+DB.gu_category+","+DB.gu_user+","+DB.acl_mask+") VALUES ('"+sNewGUID+"','"+oMe.getString(DB.gu_user)+"',2147483647)";
            if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
            oInsr.executeUpdate(sSQL);

            if (!oMe.getString(DB.gu_user).equals(oDom.getString(DB.gu_owner))) {
              sSQL = "INSERT INTO "+DB.k_x_cat_user_acl+" ("+DB.gu_category+","+DB.gu_user+","+DB.acl_mask+") VALUES ('"+sNewGUID+"','"+oDom.getString(DB.gu_owner)+"',2147483647)";
              if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
              oInsr.executeUpdate(sSQL);
            }

            sSQL = "INSERT INTO "+DB.k_cat_tree+" ("+DB.gu_parent_cat+","+DB.gu_child_cat+") VALUES ('"+sGuMailRoot+"','"+sNewGUID+"')";
            if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
            oInsr.executeUpdate(sSQL);

            oInsr.close();

            Category oMailRoot = new Category(sGuMailRoot);
            oMailRoot.expand(oConn);
            sRetVal = sNewGUID;
          }
        }
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("user " + getStringNull(DB.gu_user,"null") + " does not exist");
        throw new SQLException ("User "+getStringNull(DB.gu_user,"null")+" not found", "02000", 0);
      }
    }
    else
      sRetVal = sRetVal.trim();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End ACLUser.getMailFolder() : " + String.valueOf(sRetVal));
    }

    return sRetVal;
  } // getMailFolder

  // ---------------------------------------------------------------------------

  /**
   * <p>Get GUID of all user mail folders</p>
   * @return Array of Category GUIDs
   * @throws SQLException
   * @since 4.0
   */
  public String[] getMailFolders (JDCConnection oConn)
    throws SQLException {
    
    DBSubset oCats = new DBSubset (DB.k_categories+" c, "+DB.k_cat_tree+" t",
    						       DB.gu_category,
    						       "c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+"=?", 10);
	int iCats = oCats.load(oConn, new Object[]{getMailRoot(oConn)});
	String[] aRetVal = new String[iCats];
	for (int c=0; c<iCats; c++) aRetVal[c] = oCats.getString(0,c);
	return aRetVal;
  } // getMailFolders

  // ---------------------------------------------------------------------------

  /**
   * <p>Get name of all user mail folders</p>
   * @return Array of Category Names
   * @throws SQLException
   * @since 4.0
   */
  public String[] getMailFolderNames (JDCConnection oConn)
    throws SQLException {
    
    DBSubset oCats = new DBSubset (DB.k_categories+" c, "+DB.k_cat_tree+" t",
    						       DB.nm_category,
    						       "c."+DB.gu_category+"=t."+DB.gu_child_cat+" AND t."+DB.gu_parent_cat+"=?", 10);
	int iCats = oCats.load(oConn, new Object[]{getMailRoot(oConn)});
	String[] aRetVal = new String[iCats];
	for (int c=0; c<iCats; c++) aRetVal[c] = oCats.getString(0,c);
	return aRetVal;
  } // getMailFolderNames

  // ---------------------------------------------------------------------------

  /**
   * Get roles of this user for a given application and workarea
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return int Any bitwise OR combination of { ACL.ROLE_ADMIN || ACL.ROLE_POWERUSER || ACL.ROLE_USER || ACL.ROLE_GUEST }
   * @throws SQLException
   * @since 3.0
   */
  public int getRolesForApplication(JDCConnection oConn, int iIdApp, String sGuWorkArea)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLUser.getRolesForApplication([JDCConnection],"+String.valueOf(iIdApp)+","+sGuWorkArea+")");
      DebugFile.incIdent();
    }

    int iRolesBitMask = ACL.ROLE_NONE;
    String sGuAdmins, sGuPowUsers, sGuUser, sGuGuest;
    PreparedStatement oStmt = oConn.prepareStatement(
      "SELECT "+DB.gu_admins+","+DB.gu_powusers+","+DB.gu_users+","+DB.gu_guests+
      " FROM "+DB.k_x_app_workarea+" WHERE "+DB.id_app+"=? AND "+DB.gu_workarea+"=?",
      ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iIdApp);
    oStmt.setString(2, sGuWorkArea);
    ResultSet oRSet = oStmt.executeQuery();
    boolean bFound = oRSet.next();
    if (bFound) {
      sGuAdmins = oRSet.getString(1);
      sGuPowUsers = oRSet.getString(2);
      sGuUser = oRSet.getString(3);
      sGuGuest  = oRSet.getString(4);
    } else {
      sGuAdmins = sGuPowUsers = sGuUser = sGuGuest = null;
    }
    oRSet.close();
    oStmt.close();
    if (bFound) {
      oStmt = oConn.prepareStatement(
                "SELECT NULL FROM "+DB.k_x_group_user+" WHERE "+DB.gu_acl_group+"=? AND "+DB.gu_user+"='"+getString(DB.gu_user)+"'",
                ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      if (null!=sGuAdmins) {
        oStmt.setString(1, sGuAdmins);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) iRolesBitMask = ACL.ROLE_ADMIN;
        oRSet.close();
      }
      if (null!=sGuPowUsers) {
        oStmt.setString(1, sGuPowUsers);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) iRolesBitMask |= ACL.ROLE_POWERUSER;
        oRSet.close();
      }
      if (null!=sGuUser) {
        oStmt.setString(1, sGuUser);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) iRolesBitMask |= ACL.ROLE_USER;
        oRSet.close();
      }
      if (null!=sGuGuest) {
        oStmt.setString(1, sGuGuest);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) iRolesBitMask |= ACL.ROLE_GUEST;
        oRSet.close();
      }
      oStmt.close();
    } // fi (bFound)

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End ACLUser.getRolesForApplication() : " + String.valueOf(iRolesBitMask));
    }

    return iRolesBitMask;
  } // getRolesForApplication

  // ---------------------------------------------------------------------------

  /**
   * Find out if this user has administrator role over given application and workarea
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return boolean
   * @throws SQLException
   * @since 3.0
   */
  public boolean isAdminForApplication(JDCConnection oConn, int iIdApp, String sGuWorkArea)
    throws SQLException {
    return ((getRolesForApplication(oConn, iIdApp, sGuWorkArea)&ACL.ROLE_ADMIN)!=0);
  }

  // ---------------------------------------------------------------------------

  /**
   * Find out if this user has power user role over given application and workarea
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return boolean
   * @throws SQLException
   * @since 3.0
   */
  public boolean isPowerUserForApplication(JDCConnection oConn, int iIdApp, String sGuWorkArea)
    throws SQLException {
    return ((getRolesForApplication(oConn, iIdApp, sGuWorkArea)&ACL.ROLE_POWERUSER)!=0);
  }

  // ---------------------------------------------------------------------------

  /**
   * Find out if this user has plain user role over given application and workarea
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return boolean
   * @throws SQLException
   * @since 3.0
   */
  public boolean isUserForApplication(JDCConnection oConn, int iIdApp, String sGuWorkArea)
    throws SQLException {
    return ((getRolesForApplication(oConn, iIdApp, sGuWorkArea)&ACL.ROLE_USER)!=0);
  }

  // ---------------------------------------------------------------------------

  /**
   * Find out if this user has administrator role in his default workarea over given application
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return boolean
   * @throws SQLException
   * @since 3.0
   */
  public boolean isAdminForApplication(JDCConnection oConn, int iIdApp)
    throws SQLException {
    return ((getRolesForApplication(oConn, iIdApp, getString(DB.gu_workarea))&ACL.ROLE_ADMIN)!=0);
  }

  // ---------------------------------------------------------------------------

  /**
   * Find out if this user has power user role in his default workarea over given application
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return boolean
   * @throws SQLException
   * @since 3.0
   */
  public boolean isPowerUserForApplication(JDCConnection oConn, int iIdApp)
    throws SQLException {
    return ((getRolesForApplication(oConn, iIdApp, getString(DB.gu_workarea))&ACL.ROLE_POWERUSER)!=0);
  }

  // ---------------------------------------------------------------------------

  /**
   * Find out if this user has plain user role in his default workarea over given application
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return boolean
   * @throws SQLException
   * @since 3.0
   */
  public boolean isUserForApplication(JDCConnection oConn, int iIdApp)
    throws SQLException {
    return ((getRolesForApplication(oConn, iIdApp, getString(DB.gu_workarea))&ACL.ROLE_USER)!=0);
  }

  // ---------------------------------------------------------------------------

  /**
   * Find out if this user has guest role in his default workarea over given application
   * @param oConn JDCConnection
   * @param iIdApp int Id of application (from k_apps table)
   * @param sGuWorkArea String Guid of WorkArea (from k_workareas table)
   * @return boolean
   * @throws SQLException
   * @since 3.0
   */
  public boolean isGuestForApplication(JDCConnection oConn, int iIdApp)
    throws SQLException {
    return ((getRolesForApplication(oConn, iIdApp, getString(DB.gu_workarea))&ACL.ROLE_GUEST)!=0);
  }

  // ----------------------------------------------------------

  /**
   * Check whether the given reply matches the challenge question anwser
   * Comparison is case insensitive and ignores white spaces and accents
   * @return <b>true</b> if reply matches stored anwser,
   * <b>false</b> if either sReply is <b>null</b> or there is no previously stored answer
   */   
  public boolean checkChallengeReply(JDCConnection oConn, String sReply) {
	if (isNull(DB.tx_reply) || sReply==null) {
	  return false;
	} else {
	  return Gadgets.removeChar(Gadgets.ASCIIEncode(getString(DB.tx_reply)),' ').equalsIgnoreCase(Gadgets.removeChar(Gadgets.ASCIIEncode(sReply),' '));
	}
  } // checkChallengeReply

  // ---------------------------------------------------------------------------

  // ***************************************************************************
  // Static Methods

  /**
   * <p>Get User Unique Id. from its main e-mail address.</p>
   * <p>This method calls k_get_user_from_email stored procedure.</p>
   * @param oConn Database Connection
   * @param sUserEMail User main e-mail (tx_main_email from k_users table)
   * @return User Unique Id. or <b>null</b> if no user was found with such e-mail.
   * @throws SQLException
   */
  public static String getIdFromEmail(Connection oConn, String sUserEMail) throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.tx_main_email + "='" + sUserEMail + "')");

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.tx_main_email + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sUserEMail);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();

    return sRetVal;
  } // getIdFromEmail

  // ----------------------------------------------------------

  /**
   * <p>Get User Unique Id. from its main e-mail address.</p>
   * <p>This method calls k_get_user_from_email stored procedure.</p>
   * @param oConn Database Connection
   * @param sUserEMail User main e-mail (tx_main_email from k_users table)
   * @return User Unique Id. or <b>null</b> if no user was found with such e-mail.
   * @throws SQLException
   */
  public static String getIdFromEmail(JDCConnection oConn, String sUserEMail) throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_MYSQL:
      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_ORACLE:
        sRetVal = DBPersist.getUIdFromName(oConn, null, sUserEMail, "k_get_user_from_email");
        break;

      default:
        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.tx_main_email + "='" + sUserEMail + "')");

        oStmt = oConn.prepareStatement("SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.tx_main_email + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sUserEMail);
        oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sRetVal = oRSet.getString(1);
        else
          sRetVal = null;
        oRSet.close();
        oStmt.close();
        break;

    } // end switch

    return sRetVal;
  } // getIdFromEmail

  // ----------------------------------------------------------

  /**
   * <p>Get User main e-mail from its GUID.</p>
   * @param oConn Database Connection
   * @param sUserId User GUID (gu_user from k_users table)
   * @return User tx_main_email or <b>null</b> if no user was found with such GUID.
   * @throws SQLException
   */

  public static String getEmailFromId(JDCConnection oConn, String sUserId) throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tx_main_email + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "='" + sUserId + "')");

    oStmt = oConn.prepareStatement("SELECT " + DB.tx_main_email + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sUserId);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();

    return sRetVal;
  } // getEmailFromId

  // ----------------------------------------------------------

  /**
   * <p>Get User Unique Id. from its nickname.</p>
   * <p>This method executes a SQL query with a ResultSet</p>
   * @param oConn Database Connection
   * @param iDomainId Domain Numeric Id. (id_domain from k_users table)
   * @param sUserNick User nickname (tx_nickname from k_users table)
   * @return User Unique Id. or <b>null</b> if no user was found with such e-mail at given domain.
   * @throws SQLException
   */

  public static String getIdFromNick(Connection oConn, int iDomainId, String sUserNick)
    throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.id_domain + "=? AND " + DB.tx_nickname + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt   (1, iDomainId);
    oStmt.setString(2, sUserNick);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();
    return sRetVal;
  } // getIdFromNick

// ----------------------------------------------------------

  /**
   * <p>Get User Unique Id. from its nickname.</p>
   * <p>This method executes a SQL query with a ResultSet</p>
   * @param oConn Database Connection
   * @param sUserNick User nickname (tx_nickname from k_users table)
   * @return User Unique Id. or <b>null</b> if no user was found with such e-mail at any domain.
   * @throws SQLException If more than one user is found with the same nickname at
   * different domains.
   * @since 5.0
   */

  public static String getIdFromNick(Connection oConn, String sUserNick)
    throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bAmbiguousNick = false;
    
    oStmt = oConn.prepareStatement("SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.tx_nickname + "=?", ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sUserNick);
    oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      sRetVal = oRSet.getString(1);
      bAmbiguousNick = oRSet.next();
    }
    else {
      sRetVal = null;
    }
    oRSet.close();
    oStmt.close();

    if (bAmbiguousNick) throw new SQLException ("ACLUser.getIdFromNick("+sUserNick+") Ambiguous nickname");

    return sRetVal;
  } // getIdFromNick

  // ----------------------------------------------------------

  /**
   * <p>Get User Unique Id. from its nickname.</p>
   * <p>This method calls k_get_user_from_nick stored procedure.</p>
   * @param oConn Database Connection
   * @param iDomainId Domain Numeric Unique Identifier
   * @param sUserNick User nickname (tx_nickname from k_users table)
   * @return User Unique Id. or <b>null</b> if no user was found with such e-mail.
   * @throws SQLException
   * @since 3.0
   */

  public static String getIdFromNick(JDCConnection oConn, int iDomainId, String sUserNick)
    throws SQLException {
    String sRetVal;

    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_ORACLE:
        sRetVal = DBPersist.getUIdFromName(oConn, new Integer(iDomainId), sUserNick, "k_get_user_from_nick");
        break;
      default:
        sRetVal = getIdFromNick((Connection) oConn, iDomainId, sUserNick);
    }
    return sRetVal;
  } // getIdFromNick

  // ----------------------------------------------------------

  /**
   * <p>Delete User</p>
   * <p>Categories owned by this user are also deleted, but other data and references for user are not checked.</p>
   * @param oConn Database Connection
   * @param sUserGUID User Unique Identifier
   * @throws SQLException
   * @throws IOException
   */

  public static boolean delete(JDCConnection oConn, String sUserGUID) throws SQLException,IOException {
    boolean bRetVal;
    int iCats, iConts, iMsgs;
    DBSubset oCats, oProds, oConts, oMsgs;
    Statement oStmt;
    PreparedStatement oPtmt;
    ResultSet oRSet;
    CallableStatement oCall;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLUser.delete([Connection], " + sUserGUID + ")");
      DebugFile.incIdent();
    }

    // -----------------------------------------------------------------------------------
    // Verify that user exists before proceeding and, also, avoid deleting more registers
    // than should by a malicious inyection of SQL code at sUserGUID

    oPtmt = oConn.prepareStatement("SELECT "+DB.gu_user+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"=?",
                                   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oPtmt.setString(1, sUserGUID);
    oRSet = oPtmt.executeQuery();
    boolean bExists = oRSet.next();
    oRSet.close();
    oPtmt.close();

    if (!bExists) {
      if (DebugFile.trace) {
        DebugFile.writeln("user " + sUserGUID + " not found");
        DebugFile.decIdent();
        DebugFile.writeln("End ACLUser.delete() : false");
      }
      return false;
    }

    // ************
    // New for v5.0

    if (DBBind.exists(oConn, DB.k_activities, "U")) {
      oStmt = oConn.createStatement();
      oStmt.executeUpdate("UPDATE "+DB.k_x_activity_audience+" SET "+DB.gu_writer+"=NULL WHERE "+DB.gu_writer+"='"+sUserGUID+"'");
      oStmt.executeUpdate("UPDATE "+DB.k_activities+" SET "+DB.gu_writer+"=NULL WHERE "+DB.gu_writer+"='"+sUserGUID+"'");
	  oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_sms_audit, "U")) {
      oStmt = oConn.createStatement();
      oStmt.executeUpdate("UPDATE "+DB.k_sms_audit+" SET "+DB.gu_writer+"=NULL WHERE "+DB.gu_writer+"='"+sUserGUID+"'");
	  oStmt.close();
    }

    // End new for v5.0
    // ****************

    // ************
    // New for v4.0

    if (DBBind.exists(oConn, DB.k_working_calendar, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_working_time + " WHERE " + DB.gu_calendar + " IN (SELECT " + DB.gu_calendar + " FROM " + DB.k_working_calendar + " WHERE " + DB.gu_user + "='" + sUserGUID + "'))");
      oStmt.executeUpdate("DELETE FROM " + DB.k_working_time + " WHERE " + DB.gu_calendar + " IN (SELECT " + DB.gu_calendar + " FROM " + DB.k_working_calendar + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");
      oStmt.close();
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_working_calendar + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_working_calendar + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");
      oStmt.close();
    }

    // ************
    // New for v3.0

    if (DBBind.exists(oConn, DB.k_user_pwd, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + " IN (SELECT "+DB.gu_pwd+" FROM "+DB.k_user_pwd+" WHERE " + DB.gu_user + "='" + sUserGUID + "'))");
      oStmt.executeUpdate("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + " IN (SELECT "+DB.gu_pwd+" FROM "+DB.k_user_pwd+" WHERE " + DB.gu_user + "='" + sUserGUID + "')");
      oStmt.close();

      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_user_pwd + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_user_pwd + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");
      oStmt.close();
    } // fi

    if (DBBind.exists(oConn, DB.k_user_mail, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_user_mail + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_user_mail + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");
      oStmt.close();
    }

    /* Actualizar los estados de negocio creados por el usuario */
    if (DBBind.exists(oConn, DB.k_business_states, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace)
        DebugFile.writeln("UPDATE " + DB.k_business_states + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.executeUpdate("UPDATE " + DB.k_business_states + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.close();
    }

    /* Borrar la referencia este usuario desde los cuestionarios que haya rellenado */
    if (DBBind.exists(oConn, DB.k_pageset_answers, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace)
        DebugFile.writeln("UPDATE " + DB.k_pageset_answers + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.executeUpdate("UPDATE " + DB.k_pageset_answers + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.close();
    }

    /* Desasociar las evaluaciones */
    if (DBBind.exists(oConn, DB.k_evaluations, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace)
        DebugFile.writeln("UPDATE " + DB.k_evaluations + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.executeUpdate("UPDATE " + DB.k_evaluations + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.close();
    }

    /* Desasociar los partes de absentismo */
    if (DBBind.exists(oConn, DB.k_absentisms, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace)
        DebugFile.writeln("UPDATE " + DB.k_absentisms + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.executeUpdate("UPDATE " + DB.k_absentisms + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.close();
    }

    // End new for v3.0
    // ****************

    // ************
    // New for v6.0

    /* Eliminar los permisos sobre cursos */
    if (DBBind.exists(oConn, DB.k_x_user_acourse, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_user_acourse + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_x_user_acourse + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");
      oStmt.close();
    }

    // End new for v6.0
    // ****************

    // ************
    // New for v2.1

    /* Desasociar los e-mails */
    if (DBBind.exists(oConn, DB.k_inet_addrs, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace)
        DebugFile.writeln("UPDATE " + DB.k_inet_addrs + " SET " + DB.gu_user + "=NULL WHERE " + DB.gu_user + "='" + sUserGUID + "'");

      oStmt.executeUpdate("UPDATE " + DB.k_inet_addrs + " SET " + DB.gu_user + "=NULL WHERE " + DB.gu_user + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_x_portlet_user, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_portlet_user + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_portlet_user + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_images, "U")) {

      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_images + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "')");

      oStmt.executeUpdate("UPDATE " + DB.k_images + " SET "  + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_bugs_lookup, "U")) {

      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_bugs + " SET "  + DB.nm_assigned + "=NULL WHERE " + DB.nm_assigned + "='" + sUserGUID + "')");

      oStmt.executeUpdate("UPDATE " + DB.k_bugs + " SET "  + DB.nm_assigned + "=NULL WHERE " + DB.nm_assigned + "='" + sUserGUID + "'");

      oStmt.close();

      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_bugs_lookup + " WHERE " + DB.vl_lookup + "='" + sUserGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_bugs_lookup + " WHERE " + DB.vl_lookup + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_x_duty_resource, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_duty_resource + " WHERE " + DB.nm_resource + "='" + sUserGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_duty_resource + " WHERE " + DB.nm_resource + "='" + sUserGUID + "'");

      oStmt.close();

      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_duties_lookup + " WHERE " + DB.vl_lookup + "='" + sUserGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_duties_lookup + " WHERE " + DB.vl_lookup + "='" + sUserGUID + "'");

      oStmt.close();
    }

    // End new for v2.1
    // ****************

    // ************
    // New for v4.0

    oStmt = oConn.createStatement();
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_duties + " SET " + DB.gu_writer + "=NULL WHERE "+ DB.gu_writer + "='" + sUserGUID + "')");
    oStmt.executeUpdate("UPDATE " + DB.k_duties + " SET " + DB.gu_writer + "=NULL WHERE "+ DB.gu_writer + "='" + sUserGUID + "'");
    oStmt.close();

    // End new for v4.0
    // ****************

    // ************
    // New for v2.0

    if (DBBind.exists(oConn, DB.k_newsgroup_subscriptions, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_newsgroup_subscriptions + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_newsgroup_subscriptions + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");

      oStmt.close();
    }

    // End new for v2.0
    // ****************

    if (DBBind.exists(oConn, DB.k_newsmsgs, "U")) {
      oStmt = oConn.createStatement();

      // Remove user GUID from messages he validated
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_newsmsgs + " SET " + DB.gu_validator + "=NULL WHERE " + DB.gu_validator + "='" + sUserGUID + "'");

      oStmt.executeUpdate("UPDATE " + DB.k_newsmsgs + " SET " + DB.gu_validator + "=NULL WHERE " + DB.gu_validator + "='" + sUserGUID + "'");

      // Delete forum messages written by this user without file attachments
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.gu_product + " IS NULL");

      oStmt.executeUpdate("DELETE FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.gu_product + " IS NULL");

      oStmt.close();

      // Delete forum messages written by this user with file attachments
      oMsgs = new DBSubset(DB.k_newsmsgs, DB.gu_msg, DB.gu_writer + "='" + sUserGUID + "'", 100);

      iMsgs = oMsgs.load(oConn);

      for (int m=0; m<iMsgs; m++)
        com.knowgate.forums.NewsMessage.delete(oConn, oMsgs.getString(0,m));

      oMsgs = null;
    } // fi (exists(k_newsmsgs,))

    if (DBBind.exists(oConn, DB.k_member_address, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_member_address + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "')");

      oStmt.executeUpdate("UPDATE " + DB.k_member_address + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_member_address + " SET " + DB.gu_sales_man + "=NULL WHERE " + DB.gu_sales_man + "='" + sUserGUID + "')");

      oStmt.executeUpdate("UPDATE " + DB.k_member_address + " SET " + DB.gu_sales_man + "=NULL WHERE " + DB.gu_sales_man + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_companies_recent, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_companies_recent + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_companies_recent + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_companies, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_companies + " SET " + DB.gu_sales_man + "=NULL WHERE " + DB.gu_sales_man + "='" + sUserGUID + "')");

      oStmt.executeUpdate("UPDATE " + DB.k_companies + " SET " + DB.gu_sales_man + "=NULL WHERE " + DB.gu_sales_man + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_contacts_recent, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_contacts_recent + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_contacts_recent + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_contacts, "U")) {
      oConts = new DBSubset(DB.k_contacts, DB.gu_contact, DB.gu_writer + "='" + sUserGUID + "' AND " + DB.bo_private + "<>0", 100);
      iConts = oConts.load(oConn);

      for (int t=0; t<iConts; t++)
         com.knowgate.crm.Contact.delete(oConn, oConts.getString(0,t));

      oConts = null;

      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_contacts + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.bo_private + "=0)");

      oStmt.executeUpdate("UPDATE " + DB.k_contacts + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.bo_private + "=0");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_contact_notes + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "')");

      oStmt.executeUpdate("UPDATE " + DB.k_contact_notes + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_contact_attachs + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "')");

      oStmt.executeUpdate("UPDATE " + DB.k_contact_attachs + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "'");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_oportunities, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_oportunities + " WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.bo_private + "<>0)");

      oStmt.executeUpdate("DELETE FROM " + DB.k_oportunities + " WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.bo_private + "<>0");

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_oportunities + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.bo_private + "=0)");

      oStmt.executeUpdate("UPDATE " + DB.k_oportunities + " SET " + DB.gu_writer + "=NULL WHERE " + DB.gu_writer + "='" + sUserGUID + "' AND " + DB.bo_private + "=0");

      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_sales_men, "U")) {
       if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_sales_man ('" + sUserGUID + "') })");

       oCall = oConn.prepareCall("{call k_sp_del_sales_man ('" + sUserGUID + "')}");
       bRetVal = oCall.execute();
       oCall.close();
     }

    if (DBBind.exists(oConn, DB.k_products, "U")) {
      oProds = new DBSubset(DB.k_products, DB.gu_product, DB.gu_owner + "='" + sUserGUID + "'", 100);
      int iProds = oProds.load(oConn);

      for (int p=0; p<iProds; p++)
        new com.knowgate.hipergate.Product(oConn, oProds.getString(0, p)).delete(oConn);
      oProds = null;
    } // fi (exists(DB.k_products))

    // Delete categories associated with user
    if (DBBind.exists(oConn, DB.k_categories, "U")) {
      String sGuRootCat = null;
      oStmt = oConn.createStatement();
      ResultSet oRCat = oStmt.executeQuery("SELECT " + DB.gu_category + " FROM " + DB.k_users + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");
      if (oRCat.next())
        sGuRootCat = oRCat.getString(1);
      oRCat.close();
      oStmt.close();
      if (sGuRootCat!=null) {
        oStmt = oConn.createStatement();
        oStmt.executeUpdate("UPDATE " + DB.k_users + " SET " + DB.gu_category + "=NULL WHERE " + DB.gu_user + "='" + sUserGUID + "'");
        oStmt.close();
        Category.delete(oConn, sGuRootCat);
      }

      oCats = new DBSubset(DB.k_categories, DB.gu_category, DB.gu_owner + "=?", 10);
      iCats = oCats.load(oConn, new Object[]{sUserGUID});

      for (int r=0; r<iCats; r++)
         Category.delete(oConn, oCats.getString(0,r));

      oCats = null;
    } // fi (exists(oConn, DB.k_categories))

    if (DBBind.exists(oConn, DB.k_phone_calls, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(DELETE FROM " + DB.k_phone_calls + " WHERE " + DB.gu_user + "='" + sUserGUID + "' OR " + DB.gu_writer + "='" + sUserGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_phone_calls + " WHERE " + DB.gu_user + "='" + sUserGUID + "' OR " + DB.gu_writer + "='" + sUserGUID + "'");
      oStmt.close();
    } // fi (exists(oConn, DB.k_phone_calls))

    if (DBBind.exists(oConn, DB.k_to_do, "U")) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(DELETE FROM " + DB.k_to_do + " WHERE " + DB.gu_user + "='" + sUserGUID + "')");
      oStmt.executeUpdate("DELETE FROM " + DB.k_to_do + " WHERE " + DB.gu_user + "='" + sUserGUID + "'");
      oStmt.close();
    } // fi (exists(oConn, DB.k_to_do))

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_user ('" + sUserGUID + "') })");

    oCall = oConn.prepareCall("{call k_sp_del_user ('" + sUserGUID + "')}");
    bRetVal = oCall.execute();
    oCall.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACLUser.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Shortcut for creating a new user with a given GUID</p>
   * @param oConn Database Connection
   * @param sGuid GUID of new user
   * @param Values User fields, all required, must be in this order { (Integer)id_domain, (String)tx_nickname, (String)tx_pwd, (Short)bo_active, (Short)bo_searchable, (Short)bo_change_pwd, (String)tx_main_email, (String)tx_alt_email, (String)nm_user, (String)tx_surname1, (String)tx_surname2, (String)tx_challenge, (String)tx_reply, (String)nm_company, (String)de_title, (String)gu_workarea, (String)tx_comments, (Date)dt_pwd_expires }<br>
   * Values up to and including tx_surname1 must be NOT NULL, values from tx_surname2 are required but may be null.
   * @return New User Unique Identifier
   * @throws SQLException If another user with the same GUID already exists
   * @throws ClassCastException
   * @throws NullPointerException
   * @since 6.0
   */
  public static String create(JDCConnection oConn, String sGuid, Object[] Values)
    throws SQLException,ClassCastException,NullPointerException {

    if (DebugFile.trace) {
       DebugFile.writeln("Begin ACLUser.create([Connection])");
       DebugFile.incIdent();
    }

      ACLUser oUsr = new ACLUser();
      oUsr.getTable(oConn); // Do not remove this line

      if (null==Values[0]) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new NullPointerException("ACLUSer.create() a domain identifier is required");
      }
      if (Values[0].getClass().equals(Integer.TYPE)) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new ClassCastException("ACLUSer.create() the domain identifier must be an object of type Integer");
      }

	  if (null!=sGuid) {
	  	oUsr.put(DB.gu_user,sGuid);
	  	if (oUsr.exists(oConn)) {
          if (DebugFile.trace) DebugFile.decIdent();
	  	  throw new SQLException("User "+sGuid+" already exists");
	  	}
	  } // fi

      oUsr.put(DB.id_domain, Values[0]);
      oUsr.put(DB.tx_nickname, Values[1]);
      oUsr.put(DB.tx_pwd, Values[2]);
      oUsr.put(DB.bo_active, Values[3]);
      oUsr.put(DB.bo_searchable, Values[4]);
      oUsr.put(DB.bo_change_pwd, Values[5]);
      oUsr.put(DB.tx_main_email, Values[6]);
      oUsr.put(DB.tx_alt_email, Values[7]);
      oUsr.put(DB.nm_user, Values[8]);
      oUsr.put(DB.tx_surname1, Values[9]);
      if (Values.length>10)
        if (null!=Values[10]) oUsr.put(DB.tx_surname2, Values[10]);
      if (Values.length>11)
        if (null!=Values[11]) oUsr.put(DB.tx_challenge, Values[11]);
      if (Values.length>12)
        if (null!=Values[12]) oUsr.put(DB.tx_reply, Values[12]);
      if (Values.length>13)
        if (null!=Values[13]) oUsr.put(DB.nm_company, Values[13]);
      if (Values.length>14)
        if (null!=Values[14]) oUsr.put(DB.de_title, Values[14]);
      if (Values.length>15)
        if (null!=Values[15]) oUsr.put(DB.gu_workarea, Values[15]);
      if (Values.length>16)
        if (null!=Values[16]) oUsr.put(DB.tx_comments, Values[16]);
      if (Values.length>17)
        if (null!=Values[17]) oUsr.put(DB.dt_pwd_expires, Values[17]);

      oUsr.store(oConn);

      String sRetVal = oUsr.getString(DB.gu_user);

	  // ************
	  // New for v4.0

	  ModelManager oModMan = new ModelManager();
	  oModMan.setConnection((Connection)oConn);
	  try {
	    oModMan.createCategoriesForUser(sRetVal);
	    if (oModMan.report().length()>0) throw new SQLException(oModMan.report(), "EVAL");
      } catch (IOException ioe) {
        throw new SQLException("IOException "+ioe.getMessage());
      } catch (SQLException sql) {
        throw new SQLException("SQLException "+sql.getMessage(), sql.getSQLState(), sql.getErrorCode());
      }
      
	  oModMan=null;
	  // ************

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End ACLUser.create() : " + sRetVal);
      }
      return sRetVal;
  } // create()

  // ----------------------------------------------------------

  /**
   * <p>Shortcut for creating a new user</p>
   * @param oConn Database Connection
   * @param Values User fields, all required, must be in this order { (Integer)id_domain, (String)tx_nickname, (String)tx_pwd, (Short)bo_active, (Short)bo_searchable, (Short)bo_change_pwd, (String)tx_main_email, (String)tx_alt_email, (String)nm_user, (String)tx_surname1, (String)tx_surname2, (String)tx_challenge, (String)tx_reply, (String)nm_company, (String)de_title, (String)gu_workarea, (String)tx_comments, (Date)dt_pwd_expires }<br>
   * Values up to and including tx_surname1 must be NOT NULL, values from tx_surname2 are required but may be null.
   * @return New User Unique Identifier
   * @throws SQLException
   * @throws ClassCastException
   * @throws NullPointerException
   */
  public static String create(JDCConnection oConn, Object[] Values)
    throws SQLException,ClassCastException,NullPointerException {
    return create(oConn, null, Values);
  }
    
  // ----------------------------------------------------------

  /**
   * Update tx_pwd password column at k_users table for given user
   * @param oConn JDCConnection
   * @param sUserId String User GUID
   * @param sNewPwd String New password (up to 50 characters)
   * @param dtExpire Date of expiration of new password or <b>null</b> if password never expires
   * @return <b>true</b> if password was actually reset or <b>false</b> if no user with given GUID was found
   * @throws SQLxception
   * @throws NullPointerException
   * @since 4.0
   */
  public static boolean resetPassword(JDCConnection oConn, String sUserId, String sNewPwd, Date dtExpire)
  	throws SQLException,NullPointerException {
  	if (sUserId==null) throw new NullPointerException("ACLUser.resetPassword() user guid cannot be null");
  	if (sNewPwd==null) throw new NullPointerException("ACLUser.resetPassword() new password cannot be null");
  	if (sNewPwd.length()>50) throw new SQLException("ACLUser.resetPassword() new password cannot be longer than 50 characters");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLUser.resetPassword([Connection], " + sUserId + ",..., " + dtExpire + ")");
      DebugFile.incIdent();
    }

  	PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+DB.k_users+" SET "+DB.tx_pwd+"=?,"+DB.dt_last_update+"=?,"+DB.dt_pwd_expires+"=? WHERE "+DB.gu_user+"=?");
    oStmt.setString(1, sNewPwd);
    oStmt.setTimestamp(2, new Timestamp(new Date().getTime()));
	if (null==dtExpire)
	  oStmt.setNull(3, Types.TIMESTAMP);
	else
	  oStmt.setTimestamp(3, new Timestamp(dtExpire.getTime()));
    oStmt.setString(4, sUserId);
	int nAffected = oStmt.executeUpdate();
	oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACLUser.resetPassword() : " + String.valueOf((nAffected>0)));
    }

	return (nAffected>0);
  } // resetPassword

  // ----------------------------------------------------------

  /**
   * Update tx_pwd password column at k_users table for given user
   * Password expiration is not modified
   * @param oConn JDCConnection
   * @param sUserId String User GUID
   * @param sNewPwd String New password (up to 50 characters)
   * @return <b>true</b> if password was actually reset or <b>false</b> if no user with given GUID was found
   * @throws SQLxception
   * @throws NullPointerException
   * @since 4.0
   */
  public static boolean resetPassword(JDCConnection oConn, String sUserId, String sNewPwd)
  	throws SQLException,NullPointerException {

  	if (sUserId==null) throw new NullPointerException("ACLUser.resetPassword() user guid cannot be null");
  	if (sNewPwd==null) throw new NullPointerException("ACLUser.resetPassword() new password cannot be null");
  	if (sNewPwd.length()>50) throw new SQLException("ACLUser.resetPassword() new password cannot be longer than 50 characters");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACLUser.resetPassword([Connection], " + sUserId + ")");
      DebugFile.incIdent();
    }

  	PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+DB.k_users+" SET "+DB.tx_pwd+"=?,"+DB.dt_last_update+"=? WHERE "+DB.gu_user+"=?");
    oStmt.setString(1, sNewPwd);
    oStmt.setTimestamp(2, new Timestamp(new Date().getTime()));
    oStmt.setString(3, sUserId);
	int nAffected = oStmt.executeUpdate();
	oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACLUser.resetPassword() : " + String.valueOf((nAffected>0)));
    }

	return (nAffected>0);
  } // resetPassword

  // ----------------------------------------------------------

  /**
   * Update tx_pwd password column at k_users table for given user
   * and remove it from memory cache if it was previously cached.
   * Password expiration is not modified
   * @param oConn JDCConnection
   * @param sUserId String User GUID
   * @param sNewPwd String New password (up to 50 characters)
   * @param oCache DistributedCachePeer
   * @return <b>true</b> if password was actually reset or <b>false</b> if no user with given GUID was found
   * @throws SQLxception
   * @throws NullPointerException
   * @since 4.0
   */
  public static boolean resetPassword(JDCConnection oConn, String sUserId, String sNewPwd,
  									  DistributedCachePeer oCache)
  	throws SQLException,NullPointerException,RemoteException {
	boolean bRetVal = resetPassword(oConn, sUserId, sNewPwd);
	if (bRetVal) {
	  if (null!=oCache.get("["+sUserId+",authstr]")) {
	    oCache.expire ("["+sUserId+",authstr]");
	  } // fi
	} // fi (bRetVal)
	return bRetVal;
  } // resetPassword

  // ----------------------------------------------------------

  /**
   * Update tx_pwd password column at k_users table for given user
   * and remove it from memory cache if it was previously cached.
   * @param oConn JDCConnection
   * @param sUserId String User GUID
   * @param sNewPwd String New password (up to 50 characters)
   * @param dtExpire Date of expiration of new password or <b>null</b> if password never expires
   * @param oCache DistributedCachePeer
   * @return <b>true</b> if password was actually reset or <b>false</b> if no user with given GUID was found
   * @throws SQLxception
   * @throws NullPointerException
   * @since 4.0
   */
  public static boolean resetPassword(JDCConnection oConn, String sUserId, String sNewPwd,
  									  Date dtExpire, DistributedCachePeer oCache)
  	throws SQLException,NullPointerException,RemoteException {
	boolean bRetVal = resetPassword(oConn, sUserId, sNewPwd, dtExpire);
	if (bRetVal) {
	  if (null!=oCache.get("["+sUserId+",authstr]")) {
	    oCache.expire ("["+sUserId+",authstr]");
	  } // fi
	} // fi (bRetVal)
	return bRetVal;
  } // resetPassword

  /**
   * Checks if a given signature password matches the one previously assigned
   * @param JDCConnection
   * @param sUserId User GUID
   * @param sSign Signature Password to be checked
   * @throws SQLException if no user with given GUID exists at the database
   * @throws NullPointerException is sSign is null
   * @since 5.0
   */
  public static boolean checkSignature(JDCConnection oConn, String sUserId, String sSign)
  	throws SQLException,NullPointerException {
  	
  	if (sSign==null) throw new NullPointerException("ACLUser.checkSignature() Signature password to be checked may not be null");
  	
  	boolean bCheck = false;
  	
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.tx_pwd_sign+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"=?");
    oStmt.setString(1, sUserId);
    ResultSet oRSet = oStmt.executeQuery();
    boolean bFound = oRSet.next();
    if (bFound) {
      String sSignatureStrTest = oRSet.getString(1);
      if (!oRSet.wasNull()) {
	    bCheck = Arrays.equals(Base64Decoder.decodeToBytes(oRSet.getString(1)),
	                           new RC4(sSign).rc4("Signature password test string"));
      } // fi
    } // fi
    oRSet.close();
    oStmt.close();
    
    if (!bFound) throw new SQLException("ACLUser.checkSignature() User "+sUserId+" not found");

    return bCheck;
  } // checkSignature
  
  /**
   * Change signature password and delete any previous entries encrypted with former password
   * @param JDCConnection
   * @param sUserId User GUID
   * @param sNewSign New Signature Password
   * @throws SQLException if no user with given GUID exists at the database
   * @throws NullPointerException is sSign is null
   */
  public static boolean resetSignature(JDCConnection oConn, String sUserId, String sNewSign)
  	throws SQLException {

  	if (sNewSign==null) throw new NullPointerException("ACLUser.checkSignature() Signature password to be checked may not be null");
  	
  	if (!checkSignature(oConn, sUserId, sNewSign)) {
  	  RC4 oCrypto = new RC4(sNewSign);
      PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+DB.k_users+" SET "+DB.tx_pwd_sign+"=?, "+DB.dt_last_update+"=? WHERE "+DB.gu_user+"=?");
      oStmt.setString(1, Base64Encoder.encode(oCrypto.rc4("Signature password test string")));
	  oStmt.setTimestamp(2, new Timestamp(new Date().getTime()));
      oStmt.setString(3, sUserId);
      int iAffected = oStmt.executeUpdate();
      oStmt.close();
      
      if (iAffected==0) throw new SQLException("ACLUser.resetSignature() User "+sUserId+" not found");

      oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_user_pwd+" WHERE "+DB.id_enc_method+"='RC4' AND "+DB.gu_user+"=?");
      oStmt.setString(1, sUserId);
      oStmt.executeUpdate();
      oStmt.close();      
  	} // fi
  	return true;
  } // resetSignature

  /**
   * <p>Suggest a unique nick name for a given e-mail</p>
   * If a user with given e-mail already exists at k_users table,
   * then the nick name of that user is returned,
   * else a new nick name unique for that e-mail is suggested
   * @param JDCConnection
   * @param sEmail
   * @throws SQLException if no user with given GUID exists at the database
   * @throws NullPointerException is sEmail is null
   * @since 5.5
   */

  public static String suggestNickForEmail(JDCConnection oConn, String sEmail)
  	throws SQLException,NullPointerException {
  	String sTxNick = DBCommand.queryStr(oConn, "SELECT "+DB.tx_nickname+" FROM "+DB.k_users+" WHERE "+DB.tx_main_email+"='"+sEmail+"'");
  	if (sTxNick==null) {
  	  sTxNick = DBCommand.queryStr(oConn, "SELECT "+DB.tx_nickname+" FROM "+DB.k_users+" WHERE "+DB.tx_nickname+"='"+sEmail.substring(0,sEmail.indexOf('@'))+"'");
	  if (null==sTxNick) {
	  	sTxNick = sEmail.substring(0,sEmail.indexOf('@'));
	  } else {
	  	String sNumericSuffix = "";
	  	for (int c=sTxNick.length()-1; c>=0; c--) {
	  	  char cAt = sTxNick.charAt(c);
	  	  if (cAt>='0' && cAt<='9') sNumericSuffix = cAt + sNumericSuffix;
	  	} // next
	  	if (sNumericSuffix.length()==0) {
	  	  sTxNick += "1";
	  	} else if (sNumericSuffix.length()==sTxNick.length()) {
	  	  sTxNick = String.valueOf(Integer.parseInt(sTxNick)+1);
	  	} else {
	  	  sTxNick = sTxNick.substring(0, sTxNick.length()-sNumericSuffix.length()) + String.valueOf(Integer.parseInt(sNumericSuffix)+1);
	  	}
	  }
  	} // fi
  	return sTxNick;
  } // suggestNickForEmail

  /**
   * <p>Get a new unique nick name for a given suggestion</p>
   * The returned nick name is granted not to exist at k_users table.
   * The search for a previous nick name the same as the suggested is case insensitive
   * @param JDCConnection
   * @param sTxSuggested String suggested nick name
   * @throws SQLException
   * @throws NullPointerException is sTxSuggested is null or an empty string
   * @since 7.0
   */
  public static String getUniqueNickName(JDCConnection oConn, String sTxSuggested)
  	throws NullPointerException, ArrayIndexOutOfBoundsException, NumberFormatException, SQLException {
    String sTxNickName;
    if (sTxSuggested==null)
      throw new NullPointerException("Suggested nickname may not be null");
    if (sTxSuggested.length()==0)
      throw new NullPointerException("Suggested nickname may not be an empty string");
    DBSubset oDbs = new DBSubset(DB.k_users, DB.gu_user, DBBind.Functions.LOWER+"("+DB.tx_nickname+")=?", 1);
    if (oDbs.load(oConn, new Object[]{sTxSuggested.toLowerCase()})==0) {
      sTxNickName = sTxSuggested;
    } else {
      int iUnderscore = sTxSuggested.indexOf('_');
      if (iUnderscore<=0) {
        sTxNickName = getUniqueNickName(oConn, sTxSuggested+"_"+String.valueOf(new Date().getYear()));
      } else {
      	String sNumberSuffix = sTxSuggested.substring(++iUnderscore);
        if (sNumberSuffix.matches("\\d+"))
          sTxNickName = getUniqueNickName(oConn, sTxSuggested.substring(0,iUnderscore)+String.valueOf(Integer.parseInt(sNumberSuffix)+1));
        else
          sTxNickName = getUniqueNickName(oConn, sTxSuggested+"_"+String.valueOf(new Date().getYear()));        
      }
    }
    return sTxNickName;
   } // getUniqueNickName
  
  // **********************************************************
  // Public Constants

  public static final short ClassId = 2;

  // **********************************************************
  // Private Variables

  private DBSubset oAddresses;
  private DBSubset oGroups;
}
