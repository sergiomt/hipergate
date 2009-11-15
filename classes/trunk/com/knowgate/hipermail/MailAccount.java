/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipermail;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.CallableStatement;

import java.io.IOException;

import java.util.Properties;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.acl.ACLUser;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.Category;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class MailAccount extends DBPersist {

  public MailAccount() {
    super (DB.k_user_mail, "MailAccount");
  }

  // ----------------------------------------------------------

  public MailAccount(JDCConnection oConn, String sGuAccount) throws SQLException {
    super (DB.k_user_mail, "MailAccount");
    load(oConn, new Object[]{sGuAccount});
  }

  // ----------------------------------------------------------

  /**
   * <p>Store mail account</p>
   * This method has a special side effect: only one mail account may be the
   * default one for a given user. So each time that an account is stored with
   * it bo_default flag set to 1 the other account for the same user are set to
   * bo_default=0.<br>
   * This method also calls Gadgets.checkEMail() on tx_main_email and tx_reply_mail
   * if they do not have a valid syntax a SQLException is thrown
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException If tx_main_email or tx_reply_mail do not have a valid syntax
   */
  public boolean store (JDCConnection oConn) throws SQLException {
    if (isNull(DB.gu_account)) {
      put(DB.gu_account, Gadgets.generateUUID());
    }
    if (isNull(DB.bo_default)) {
      replace (DB.bo_default, (short)0);
    }
    if (isNull(DB.incoming_spa)) {
      replace (DB.incoming_spa, (short)0);
    }
    if (isNull(DB.incoming_ssl)) {
      replace (DB.incoming_ssl, (short)0);
    }
    if (isNull(DB.outgoing_spa)) {
      replace (DB.outgoing_spa, (short)0);
    }
    if (isNull(DB.outgoing_ssl)) {
      replace (DB.outgoing_ssl, (short)0);
    }
    if (!isNull(DB.tx_main_email)) {
      if (!Gadgets.checkEMail(getString(DB.tx_main_email)))
        throw new SQLException ("Mail account "+getString(DB.tx_main_email)+" is not valid","23000");
    }
    if (!isNull(DB.tx_reply_email)) {
      if (!Gadgets.checkEMail(getString(DB.tx_reply_email)))
        throw new SQLException ("Mail account "+getString(DB.tx_reply_email)+" is not valid","23000");
    }
    if (!isNull(DB.bo_default)) {
      if (getShort(DB.bo_default)==(short)1) {
        PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+DB.k_user_mail+" SET "+DB.bo_default+"=0 WHERE "+DB.gu_user+"=?");
        oStmt.setString(1, getStringNull(DB.gu_user,null));
        oStmt.executeUpdate();
        oStmt.close();
      }
    }
    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  public Properties getProperties() {

    Properties oProps = new Properties();

	oProps.put("mail.account", getStringNull(DB.incoming_account,getStringNull(DB.outgoing_account,"")));
	oProps.put("mail.user", getStringNull(DB.incoming_account,getStringNull(DB.outgoing_account,"")));
    oProps.put("mail.password", getStringNull(DB.incoming_password,getStringNull(DB.outgoing_password,"")));
    oProps.put("mail.store.protocol", getStringNull(DB.incoming_protocol,"pop3"));
    oProps.put("mail.transport.protocol", getStringNull(DB.outgoing_protocol,"smtp"));
    oProps.put("mail.incoming", getStringNull(DB.incoming_server,"localhost"));
    oProps.put("mail.outgoing", getStringNull(DB.outgoing_server,"localhost"));
    oProps.put("mail."+getStringNull(DB.incoming_protocol,"pop3")+".host", getStringNull(DB.incoming_server,"localhost"));
    oProps.put("mail."+getStringNull(DB.outgoing_protocol,"smtp")+".host", getStringNull(DB.outgoing_server,"localhost"));

    if (isNull(DB.incoming_port))
      oProps.put("mail."+getStringNull(DB.incoming_protocol,"pop3")+".port", "110");
    else
      oProps.put("mail."+getString(DB.incoming_protocol)+".port", String.valueOf(getShort(DB.incoming_port)));
    if (isNull(DB.outgoing_port))
      oProps.put("mail."+getStringNull(DB.outgoing_protocol,"smtp")+".port", "25");
    else
      oProps.put("mail."+getString(DB.outgoing_protocol)+".port", String.valueOf(getShort(DB.outgoing_port)));

	if (!isNull(DB.incoming_ssl)) {
	  if (getShort(DB.incoming_ssl)!=(short) 0) {
        oProps.put(getString(DB.incoming_protocol)+".socketFactory.class", "javax.net.ssl.SSLSocketFactory");
        oProps.put(getString(DB.incoming_protocol)+".socketFactory.port", String.valueOf(getShort(DB.incoming_port)));
	  }
	}

	if (!isNull(DB.outgoing_ssl)) {
	  if (getShort(DB.outgoing_ssl)!=(short) 0) {
        oProps.put(getString(DB.outgoing_protocol)+".socketFactory.class", "javax.net.ssl.SSLSocketFactory");
        oProps.put(getString(DB.outgoing_protocol)+".socketFactory.port", String.valueOf(getShort(DB.outgoing_port)));	  
	  }
	}

    return oProps;
  }

  // ----------------------------------------------------------

  public void setProperties(Properties oProps) {
    replace(DB.incoming_account, oProps.getProperty("mail.user"));
    replace(DB.outgoing_account, oProps.getProperty("mail.user"));
    replace(DB.incoming_protocol, oProps.getProperty("mail.store.protocol","pop3"));
    replace(DB.outgoing_protocol, oProps.getProperty("mail.transport.protocol","smtp"));
    replace(DB.incoming_server, oProps.getProperty("mail."+getString(DB.incoming_protocol)+".host",oProps.getProperty("mail.incoming","localhost")));
    replace(DB.outgoing_server, oProps.getProperty("mail."+getString(DB.outgoing_protocol)+".host",oProps.getProperty("mail.outgoing","localhost")));
    replace(DB.incoming_port, oProps.getProperty("mail."+getString(DB.incoming_protocol)+".port","110"));
    replace(DB.outgoing_port, oProps.getProperty("mail."+getString(DB.outgoing_protocol)+".port","25"));
  }

  // **********************************************************
  // Static Methods

  /**
   * <p>Get MailAccount for ACLUser</p>
   * Get the default mail account for an ACLUser or the first account if there is no default.
   * @param oConn JDCConnection
   * @param sGuUser String ACLUser GUID (from k_users.gu_user)
   * @return MailAccount instance or <b>null</b> if there are no mail accounts for the given user
   * @throws SQLException
   */
  public static MailAccount forUser(JDCConnection oConn, String sGuUser)
    throws SQLException {
    String sGuAccount;
    PreparedStatement oStmt;
    ResultSet oRSet;
    MailAccount oRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MailAccount.forUser(JDCConnection, "+sGuUser+")");
      DebugFile.incIdent();
    }

    oStmt = oConn.prepareStatement("SELECT "+DB.gu_account+" FROM "+DB.k_user_mail+ " WHERE "+DB.gu_user+"=? AND "+DB.bo_default+"=?");
    oStmt.setString(1, sGuUser);
    oStmt.setShort (2, (short)1);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sGuAccount = oRSet.getString(1);
    else
      sGuAccount = null;
    oRSet.close();
    oStmt.close();
    if (null==sGuAccount) {
      oStmt = oConn.prepareStatement("SELECT "+DB.gu_account+" FROM "+DB.k_user_mail+ " WHERE "+DB.gu_user+"=?");
      oStmt.setString(1, sGuUser);
      oRSet = oStmt.executeQuery();
      if (oRSet.next())
        sGuAccount = oRSet.getString(1);
      oRSet.close();
      oStmt.close();
    }
    if (null==sGuAccount) {
      oRetVal = null;
    } else {
      oRetVal = new MailAccount();
      oRetVal.load(oConn, new Object[]{sGuAccount});
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oRetVal)
        DebugFile.writeln("End MailAccount.forUser() : null");
      else
        DebugFile.writeln("End MailAccount.forUser() : "+sGuAccount);
    }

    return oRetVal;
  } // forUser

  /**
   * <p>Get MailAccount for ACLUser or create a default one</p>
   * If no account for given user is found at k_user_mail then one is temporaly
   * created by using properties given at parameter oProps and taking user's
   * tx_main_email and tx_pwd as mail address and password.
   * @param oConn JDCConnection
   * @param sGuUser String ACLUser GUID (from k_users.gu_user)
   * @param oProps Properties usually take from an hipergate.cnf file by calling
   * Environment.getProfile("hipergate")
   * @return MailAccount instance or <b>null</b> if there is no user with the given GUID
   * @throws SQLException
   */
  public static MailAccount forUser(JDCConnection oConn, String sGuUser, Properties oProps)
    throws SQLException {

    if (DebugFile.trace) {
      if (null==oProps)
        DebugFile.writeln("Begin MailAccount.forUser(JDCConnection, "+sGuUser+",null)");
      else
        DebugFile.writeln("Begin MailAccount.forUser(JDCConnection, "+sGuUser+","+oProps.toString()+")");
      DebugFile.incIdent();
    }

    MailAccount oRetVal = MailAccount.forUser(oConn, sGuUser);
    if (null==oRetVal) {
      ACLUser oUser = new ACLUser();
      if (oUser.load(oConn, new Object[]{sGuUser})) {
        oRetVal = new MailAccount();
        oRetVal.setProperties(oProps);
        oRetVal.put(DB.gu_user, oUser.getString(DB.gu_user));
        oRetVal.put(DB.tl_account, "Default account for " + oUser.getString(DB.tx_nickname));
        oRetVal.put(DB.bo_default, (short)1);
        oRetVal.put(DB.bo_synchronize, (short)0);
        oRetVal.put(DB.tx_main_email, oUser.getString(DB.tx_main_email));
        oRetVal.put(DB.tx_reply_email, oUser.getString(DB.tx_main_email));
        oRetVal.put(DB.incoming_password, oUser.getString(DB.tx_pwd));
        oRetVal.put(DB.outgoing_password, oUser.getString(DB.tx_pwd));
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oRetVal)
        DebugFile.writeln("End MailAccount.forUser() : null");
      else
        DebugFile.writeln("End MailAccount.forUser() : "+oRetVal.getString(DB.gu_account));
    }

    return oRetVal;
  } // forUser

  // --------------------------------------------------------------------------
  
  private static void deleteCategorySet(JDCConnection oConn, DBSubset oCatgSet)
    throws SQLException, IOException {
    final int iSize = oCatgSet.getRowCount();
    // Delete recursively children categories first
    for (int c=0; c<iSize; c++) {
      DBSubset oChildCatgs = new DBSubset(DB.k_cat_tree, DB.gu_child_cat, DB.gu_parent_cat+"=?", 10);
      oChildCatgs.load(oConn, new Object[]{oCatgSet.getString(0,c)});
      deleteCategorySet(oConn, oChildCatgs);
    }
    // Deleting the category will delete the associated MimeMessages, but it is faster to do it first
    // for avoiding lots of calls to MimeMessage.delete() method
    for (int d=0; d<iSize; d++) {
      DBSubset oDeleted = new DBSubset(DB.k_mime_msgs, DB.gu_mimemsg, DB.gu_category+"=?", 100);
      oDeleted.load(oConn, new Object[]{oCatgSet.getString(0,d)});
      final int iDeleted = oDeleted.getRowCount();
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        Statement oStmt = oConn.createStatement();
        for (int m=0; m<iDeleted; m++) {
          oStmt.executeQuery("SELECT k_sp_del_mime_msg('" + oDeleted.getString(0,m) + "')");
        } // next (message)
        oStmt.close();
        oStmt=null;
      } else {
        CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_mime_msg(?) }");
        for (int m=0; m<iDeleted; m++) {
          oCall.setString(1, oDeleted.getString(0,m));
          oCall.execute();
        } // next
        oCall.close();
        oCall=null;
      } // fi
      // When the Category is deleted its associated Products are erased from disk.
      // As the MBOX files are stored as products of the category, the MBOX files
      // will be deleted as a side effect of deleting the Category
      Category.delete(oConn, oCatgSet.getString(0,d));
    } // next (category)
  } // deleteCategorySet

  public boolean delete(JDCConnection oConn)
    throws SQLException {
    ACLUser oUsr = new ACLUser(getString(DB.gu_user));
    Category oRootCat = new Category(oConn, oUsr.getMailRoot(oConn));
    DBSubset oMailFoldersCatgs = new DBSubset(DB.k_cat_tree, DB.gu_child_cat, DB.gu_parent_cat+"=?", 10);
    oMailFoldersCatgs.load(oConn, new Object[]{oRootCat.getString(DB.gu_category)});
    try {
      deleteCategorySet(oConn, oMailFoldersCatgs);
    } catch (IOException ioe) {
      throw new SQLException (ioe.getMessage());
    }
    return super.delete(oConn);
  } // delete

  public static boolean delete(JDCConnection oConn, String sGuAccount)
    throws SQLException, IOException {
    boolean bRetVal;
    MailAccount oAcc = new MailAccount();
    if (oAcc.load(oConn, new Object[]{sGuAccount})) {
      bRetVal = oAcc.delete(oConn);
    } else {
      bRetVal = false;
    }
    return bRetVal;
  } // delete

  // **********************************************************
  // Public Constants

  public static final short ClassId = 810;

}
