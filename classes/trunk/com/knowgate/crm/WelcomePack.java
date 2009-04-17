/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

import java.util.Date;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.hipergate.Address;
import com.knowgate.misc.Gadgets;

/**
 * <p>Welcome Packs</p>
 * <p>Copyright: Copyright (c) KnowGate 2006</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class WelcomePack extends DBPersist {

    /**
     * Default constructor
     */
    public WelcomePack() {
    super (DB.k_welcome_packs, "WelcomePack");
  }

  /**
   * Create Welcome Pack and load data
   * @param oConn JDCConnection
   * @param sGuPack String Welcome Pack GUID
   * @throws SQLException
   */
  public WelcomePack(JDCConnection oConn, String sGuPack)
    throws SQLException {
    super (DB.k_welcome_packs, "WelcomePack");
    load(oConn, new Object[]{sGuPack});
  }

  /**
   * Get Company to which this Welcome Pack belongs
   * @param oConn JDCConnection
   * @return Company or <b>null</b> if this Welcome Pack is not associated to a Company
   * @throws SQLException
   */
  public Company getCompany(JDCConnection oConn)
      throws SQLException {
    if (isNull(DB.gu_company))
      return null;
    else
      return new Company(oConn, getString(DB.gu_company));
  }

  /**
   * Get Contact to which this Welcome Pack belongs
   * @param oConn JDCConnection
   * @return Company or <b>null</b> if this Welcome Pack is not associated to a Contact
   * @throws SQLException
   */
  public Contact getContact(JDCConnection oConn)
      throws SQLException {
    if (isNull(DB.gu_contact))
      return null;
    else
      return new Contact(oConn, getString(DB.gu_contact));
  }

  /**
   * Get Address to which this Welcome Pack belongs
   * @param oConn JDCConnection
   * @return com.knowgate.hipergate.Address or <b>null</b> if this Welcome Pack is not associated to an Address
   * @throws SQLException
   */
  public Address getAddress(JDCConnection oConn)
      throws SQLException {
    if (isNull(DB.gu_address))
      return null;
    else
      return new Address(oConn, getString(DB.gu_address));
  }

  /**
   * <p>Store Welcome Pack</p>
   * Automatically assign values to ix_pack and dt_modified fields if they are not set
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException
   */
  public boolean store (JDCConnection oConn) throws SQLException {
    boolean bRetVal;
    String sOldStatus;
    PreparedStatement oStmt;

    boolean bNew = isNull(DB.gu_pack);

    if (bNew) {
      sOldStatus = "";
      put (DB.gu_pack, Gadgets.generateUUID());
    } else {
      oStmt = oConn.prepareStatement("SELECT "+DB.id_status+","+DB.gu_writer+" FROM "+DB.k_welcome_packs+" WHERE "+DB.gu_pack+"=?",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, getString(DB.gu_pack));
      ResultSet oRSet = oStmt.executeQuery();
      bNew = !oRSet.next();
      if (bNew) {
        sOldStatus = "";
      } else {
        sOldStatus = oRSet.getString(1);
        if (oRSet.wasNull()) sOldStatus = "";
        replace(DB.gu_writer, oRSet.getString(2));
      }
      oRSet.close();
      oStmt.close();
    } // fi (bNew)

    replace(DB.dt_modified, new Date());

    if (isNull(DB.dt_cancel) && getStringNull(DB.id_status,"").equalsIgnoreCase(CANCELLED) && !sOldStatus.equalsIgnoreCase(CANCELLED))
      put(DB.dt_cancel, new Date());

    if (isNull(DB.dt_sent) && getStringNull(DB.id_status,"").equalsIgnoreCase(SENT) && !sOldStatus.equalsIgnoreCase(SENT))
      put(DB.dt_sent, new Date());

    if (isNull(DB.dt_delivered) && getStringNull(DB.id_status,"").equalsIgnoreCase(DELIVERED) && !sOldStatus.equalsIgnoreCase(DELIVERED))
      put(DB.dt_delivered, new Date());

    if (isNull(DB.dt_returned) && getStringNull(DB.id_status,"").equalsIgnoreCase(RETURNED) && !sOldStatus.equalsIgnoreCase(RETURNED))
      put(DB.dt_returned, new Date());

    if (bNew) {
      put (DB.ix_pack, DBBind.nextVal(oConn,"seq_k_welcme_pak"));
      bRetVal = super.store(oConn);
    } else {
      bRetVal = super.store(oConn);
      if (!sOldStatus.equalsIgnoreCase(getStringNull(DB.id_status, ""))) {
        oStmt = oConn.prepareStatement("INSERT INTO " +
                                       DB.k_welcome_packs_changelog + " (" +
                                       DB.gu_pack + "," + DB.gu_writer+","+
                                       DB.dt_last_update+","+DB.id_old_status+","+
                                       DB.id_new_status+") VALUES (?,?,"+DBBind.Functions.GETDATE+",?,?)");
        oStmt.setString(1, getString(DB.gu_pack));
        oStmt.setString(2, getString(DB.gu_writer));
        if (sOldStatus.length()==0)
          oStmt.setNull(3, Types.VARCHAR);
        else
          oStmt.setString(3, sOldStatus);
        if (getStringNull(DB.id_status, "").length()==0)
          oStmt.setNull(4, Types.VARCHAR);
        else
          oStmt.setString(4, getString(DB.id_status));
        oStmt.executeUpdate();
        oStmt.close();
      }
    } // fi (bNew)

    return bRetVal;
  }

  /**
   * Delete Welcome Pack incluing its change log
   * @param oConn JDCConnection
   * @return boolean <b>true</b> if Welcome Pack actually existed, <b>false</b> otherwise.
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt;
    int iAffected;
    oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_welcome_packs_changelog+" WHERE "+DB.gu_pack+"=?");
    oStmt.setObject(1, get(DB.gu_pack), Types.CHAR);
    oStmt.executeUpdate();
    oStmt.close();
    oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_welcome_packs+" WHERE "+DB.gu_pack+"=?");
    oStmt.setObject(1, get(DB.gu_pack), Types.CHAR);
    iAffected = oStmt.executeUpdate();
    oStmt.close();
    return (iAffected>0);
  } // delete

  /**
   * Get log for modifications of status of this Welcome Pack
   * @param oConn JDCConnection
   * @return WelcomePackChangeLog[]
   * @throws SQLException
   */
  public WelcomePackChangeLog[] changeLog(JDCConnection oConn)
    throws SQLException {
    WelcomePackChangeLog[] aWcl;
    DBSubset oLog = new DBSubset(DB.k_welcome_packs_changelog,
                                 DB.gu_pack+","+DB.dt_last_update+","+
                                 DB.gu_writer+","+
                                 DB.id_old_status+","+DB.id_new_status,
                                 DB.gu_pack+"=? ORDER BY 2", 10);
    int iLog = oLog.load(oConn, new Object[]{getString(DB.gu_pack)});
    if (0==iLog) {
      aWcl = null;
    } else {
      aWcl = new WelcomePackChangeLog[iLog];
      for (int l=0; l<iLog; l++) {
        aWcl[l] = new WelcomePackChangeLog();
        aWcl[l].putAll(oLog.getRowAsMap(l));
        aWcl[l].setWriter(oConn, oLog.getStringNull(4,l,null));
      } // next
    } // fi
    return aWcl;
  } // changeLog

  /**
   * Get the most recent Welcome Pack associated to a Contact
   * @param oConn JDCConnection
   * @param sGuContact String Contact GUID
   * @return WelcomePack
   * @throws SQLException
   */
  public static WelcomePack forContact(JDCConnection oConn, String sGuContact)
    throws SQLException {
    WelcomePack oRetObj;
    if (null==sGuContact) {
      oRetObj = null;
    } else {
      PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_pack+" FROM "+
                                                       DB.k_welcome_packs+" WHERE "+DB.gu_contact+"=? ORDER BY "+DB.dt_created+" DESC",
                                                       ResultSet.TYPE_FORWARD_ONLY,
                                                       ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sGuContact);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oRetObj = new WelcomePack(oConn, oRSet.getString(1));
        oRSet.close();
      } else {
        oRSet.close();
        oRetObj = null;
      }
      oStmt.close();
    }
    return oRetObj;
  } // forContact

  /**
   * Get the most recent Welcome Pack associated to a Company
   * @param oConn JDCConnection
   * @param sGuCompany String Company GUID
   * @return WelcomePack
   * @throws SQLException
   */
  public static WelcomePack forCompany(JDCConnection oConn, String sGuCompany)
    throws SQLException {
    WelcomePack oRetObj;
    if (null==sGuCompany) {
      oRetObj = null;
    } else {
      PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_pack+" FROM "+
                                                       DB.k_welcome_packs+" WHERE "+DB.gu_company+"=? ORDER BY "+DB.dt_created+" DESC",
                                                       ResultSet.TYPE_FORWARD_ONLY,
                                                       ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sGuCompany);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oRetObj = new WelcomePack(oConn, oRSet.getString(1));
        oRSet.close();
      } else {
        oRSet.close();
        oRetObj = null;
      }
      oStmt.close();
    }
    return oRetObj;
  } // forCompany

  /**
   * Get the most recent Welcome Pack associated to an Address
   * @param oConn JDCConnection
   * @param sGuAddres String Address GUID
   * @return WelcomePack
   * @throws SQLException
   */
  public static WelcomePack forAddress(JDCConnection oConn, String sGuAddres)
    throws SQLException {
    WelcomePack oRetObj;
    if (null==sGuAddres) {
      oRetObj = null;
    } else {
      PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_pack+" FROM "+
                                                       DB.k_welcome_packs+" WHERE "+DB.gu_address+"=? ORDER BY "+DB.dt_created+" DESC",
                                                       ResultSet.TYPE_FORWARD_ONLY,
                                                       ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sGuAddres);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oRSet.close();
        oRetObj = new WelcomePack(oConn, oRSet.getString(1));
      } else {
        oRSet.close();
        oRetObj = null;
      }
      oStmt.close();
    }
    return oRetObj;
  } // forAdress

  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 99;

  public static final String PENDING = "PENDING";
  public static final String CANCELLED = "CANCELLED";
  public static final String SENT = "SENT";
  public static final String DELIVERED = "DELIVERED";
  public static final String RETURNED = "RETURNED";

}
