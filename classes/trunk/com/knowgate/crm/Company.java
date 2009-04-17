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

import java.util.HashMap;
import java.util.StringTokenizer;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.hipergate.Address;
import com.knowgate.hipergate.DBLanguages;

/**
 * <p>Company</p>
 * <p>Copyright: Copyright (c) KnowGate 2003</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class Company extends DBPersist {

  /**
   * Create Empty Company.
  */
  public Company() {
    super(DB.k_companies, "Company");
  }

  /**
   * Create Company and set gu_company field.
   * Does not load other fields from database.
   * @param sCompanyId Company GUID
   */
  public Company(String sCompanyId) {
    super(DB.k_companies, "Company");

    put (DB.gu_company, sCompanyId);
  }

  // ----------------------------------------------------------

  /**
   * Create Company and load fields from database.
   * @param oConn JDCConnection
   * @param sCompanyId Company GUID
   * @throws SQLException
   */
  public Company(JDCConnection oConn, String sCompanyId)
    throws SQLException {
    super(DB.k_companies, "Company");
    load (oConn, sCompanyId);
  }

  // ----------------------------------------------------------

  /**
   * </p>Get groups that may have access to this company.</p>
   * @param oConn Database Connection
   * @return A {@link DBSubset} with a 1 column containing each group unique identifier (gu_acl_group).
   * @throws SQLException
   * @since 4.0
   */
  public DBSubset getGroups(JDCConnection oConn) throws SQLException {
    Object aCompany[] = { get(DB.gu_company) };
    DBSubset oGroups = new DBSubset(DB.k_x_group_company,DB.gu_acl_group,DB.gu_company + "=?",10);

    oGroups.load (oConn, aCompany);
    return oGroups;
  } // getGroups

  // ----------------------------------------------------------

  /**
   * <p>Add Company to a set of security restrictions groups.</p>
   * <p>Insert new registers at k_x_group_company table.</p>
   * @param oConn Database Connection
   * @param sGroupList A string of comma delimited ACLGroup GUIDs to with this ACLUser must be added.
   * @throws SQLException May throw a primary key constraint violation if company already belongs to group.
   * @since 4.0
   */
  public int addToACLGroups(JDCConnection oConn, String sGroupList) throws SQLException {

     if (DebugFile.trace) {
        DebugFile.writeln("Begin Company.addToACLGroups(Connection], " + sGroupList + ")");
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
         DebugFile.writeln("Statement.executeUpdate(INSERT INTO " + DB.k_x_group_company + "(" + DB.gu_company + "," + DB.gu_acl_group + ") VALUES('" + getStringNull(DB.gu_company, "null") + "','" + sIdGroup + "')");

       iRetVal += oStmt.executeUpdate("INSERT INTO " + DB.k_x_group_company + "(" + DB.gu_company + "," + DB.gu_acl_group + ") VALUES('" + getString(DB.gu_company) + "','" + sIdGroup + "')");
     } // wend
	 
	 oStmt.executeUpdate("UPDATE "+DB.k_companies+" SET "+DB.bo_restricted+"="+(iRetVal>0 ? "1" : "0")+" WHERE "+DB.gu_company+"='"+getString(DB.gu_company)+"'");
	 
     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Company.addToACLGroups() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // addToACLGroups

  // ----------------------------------------------------------

  /**
   * <p>Remove company from all security restrictions groups</p>
   * @param oConn Database Connection
   * @return Count of groups from witch user was removed.
   * @throws SQLException
   * @since 4.0
   */
  public int clearACLGroups(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Company.clearACLGroups([Connection])");
      DebugFile.incIdent();
    }

     int iRetVal;

     Statement oStmt = oConn.createStatement();
     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_company + " WHERE " + DB.gu_company + "='" + getString(DB.gu_company) + "'");
	 oStmt.executeUpdate("UPDATE "+DB.k_companies+" SET "+DB.bo_restricted+"=0 WHERE "+DB.gu_company+"='"+getString(DB.gu_company)+"'");
     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Company.clearACLGroups() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // clearACLGroups

  // ----------------------------------------------------------

  /**
   * <p>Remove Company from security restrictions group.</p>
   * <p>remove register from k_x_group_user table.</p>
   * @param oConn Database Connection
   * @param sIdGroup Group Unique Identifier.
   * @throws SQLException
   * @since 4.0
   */

  public int removeFromACLGroup(JDCConnection oConn, String sIdGroup) throws SQLException {

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Company.removeFromACLGroup(Connection], " + sIdGroup + ")");
       DebugFile.incIdent();
    }

     int iRetVal;
     Statement oStmt = oConn.createStatement();

     if (DebugFile.trace)
       DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_group_company + " WHERE " + DB.gu_company + "='" + getStringNull(DB.gu_company, "null") + "' AND " + DB.gu_acl_group + "='" + sIdGroup + "'");

     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_company + " WHERE " + DB.gu_company + "='" + getString(DB.gu_company) + "' AND " + DB.gu_acl_group + "='" + sIdGroup + "'");
     oStmt.close();

	 int iRemaining = DBCommand.queryInt(oConn,"SELECT COUNT(*) FROM " + DB.k_x_group_company + " WHERE " + DB.gu_company + "='" + getString(DB.gu_company) + "'");
	 if (0==iRemaining) DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_companies+" SET "+DB.bo_restricted+"=0 WHERE "+DB.gu_company+"='"+getString(DB.gu_company)+"'");
	 
     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Company.removeFromACLGroup() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // removeFromACLGroup
  
  // ----------------------------------------------------------

  /**
   * <P>Add a bank account to this Company</P>
   * If company is already associated to the given bank account then a foreign key violation SQLException is thrown
   * @param oConn Database Connection
   * @throws SQLException
   * @since 3.0
   */
  public boolean addBankAccount(JDCConnection oConn, String sFullBankAccount)
    throws SQLException {
    PreparedStatement oStmt = null;
    boolean bRetVal;

    try {
      oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_company_bank + " (" + DB.gu_company + "," + DB.nu_bank_acc + "," + DB.gu_workarea + ") VALUES (?,?,?)");
      oStmt.setString(1, getStringNull(DB.gu_company, null));
      oStmt.setString(2, sFullBankAccount);
      oStmt.setString(3, getStringNull(DB.gu_workarea, null));
      int iAffected = oStmt.executeUpdate();
      oStmt.close();
      oStmt = null;
      bRetVal = (iAffected > 0);
    } catch (SQLException sqle) {
      bRetVal = false;
      try { if (oStmt!=null) oStmt.close(); } catch (Exception ignore) {}
    }
    return bRetVal;
  } // addBankAccount

  // ----------------------------------------------------------

  /**
   * Get all bank accounts associated with Company
   * @param oConn JDCConnection
   * @return DBSubset nu_bank_acc,dt_created,bo_active,tp_account,nm_bank,tx_addr,nm_cardholder,nu_card,tp_card,tx_expire,nu_pin,nu_cvv2,im_credit_limit,de_bank_acc
   * @throws SQLException
   * @throws IllegalStateException if gu_company or gu_workarea are not set
   * @since 3.0
   */
  public DBSubset getAllBankAccounts(JDCConnection oConn)
    throws SQLException,IllegalStateException {
    if (isNull(DB.gu_company))
      throw new IllegalStateException("Company.getAllBankAccounts() gu_company property is not set");
    if (isNull(DB.gu_workarea))
      throw new IllegalStateException("Company.getAllBankAccounts() gu_workarea property is not set");

    DBSubset oAccs = new DBSubset (DB.k_bank_accounts,
                                   DB.nu_bank_acc+","+DB.dt_created+","+DB.bo_active+","+DB.tp_account+","+DB.nm_bank+","+DB.tx_addr+","+DB.nm_cardholder+","+DB.nu_card+","+DB.tp_card+","+DB.tx_expire+","+DB.nu_pin+","+DB.nu_cvv2+","+DB.im_credit_limit+","+DB.de_bank_acc,
                                   DB.gu_workarea+"=? AND "+DB.nu_bank_acc+" IN (SELECT "+DB.nu_bank_acc+" FROM "+DB.k_x_company_bank+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_company+"=?)",10);

    oAccs.load(oConn, new Object[]{get(DB.gu_workarea),get(DB.gu_workarea),get(DB.gu_company)});
    return oAccs;
  } // getAllBankAccounts

  // ----------------------------------------------------------

  /**
   * Get active bank accounts for this Company
   * @param oConn JDCConnection
   * @return DBSubset nu_bank_acc,dt_created,tp_account,nm_bank,tx_addr,nm_cardholder,nu_card,tp_card,tx_expire,nu_pin,nu_cvv2,im_credit_limit,de_bank_acc
   * @throws SQLException
   * @throws IllegalStateException if gu_company or gu_workarea are not set
   * @since 3.0
   */
  public DBSubset getActiveBankAccounts(JDCConnection oConn)
    throws SQLException,IllegalStateException {
    if (isNull(DB.gu_company))
      throw new IllegalStateException("Company.getActiveBankAccounts() gu_company property is not set");
    if (isNull(DB.gu_workarea))
      throw new IllegalStateException("Company.getActiveBankAccounts() gu_workarea property is not set");

    DBSubset oAccs = new DBSubset (DB.k_bank_accounts,
                                   DB.nu_bank_acc+","+DB.dt_created+","+DB.tp_account+","+DB.nm_bank+","+DB.tx_addr+","+DB.nm_cardholder+","+DB.nu_card+","+DB.tp_card+","+DB.tx_expire+","+DB.nu_pin+","+DB.nu_cvv2+","+DB.im_credit_limit+","+DB.de_bank_acc,
                                   DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 AND "+DB.nu_bank_acc+" IN (SELECT "+DB.nu_bank_acc+" FROM "+DB.k_x_company_bank+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_company+"=?)",10);

    oAccs.load(oConn, new Object[]{get(DB.gu_workarea),get(DB.gu_workarea),get(DB.gu_company)});
    return oAccs;
  } // getActiveBankAccounts

  // ----------------------------------------------------------

  /**
   * Get unactive bank accounts for this Company
   * @param oConn JDCConnection
   * @return DBSubset nu_bank_acc,dt_created,tp_account,nm_bank,tx_addr,nm_cardholder,nu_card,tp_card,tx_expire,nu_pin,nu_cvv2,im_credit_limit,de_bank_acc
   * @throws SQLException
   * @throws IllegalStateException if gu_company or gu_workarea are not set
   * @since 3.0
   */
  public DBSubset getUnactiveBankAccounts(JDCConnection oConn)
    throws SQLException,IllegalStateException {
    if (isNull(DB.gu_company))
      throw new IllegalStateException("Company.getUnactiveBankAccounts() gu_company property is not set");
    if (isNull(DB.gu_workarea))
      throw new IllegalStateException("Company.getUnactiveBankAccounts() gu_workarea property is not set");

    DBSubset oAccs = new DBSubset (DB.k_bank_accounts,
                                   DB.nu_bank_acc+","+DB.dt_created+","+DB.tp_account+","+DB.nm_bank+","+DB.tx_addr+","+DB.nm_cardholder+","+DB.nu_card+","+DB.tp_card+","+DB.tx_expire+","+DB.nu_pin+","+DB.nu_cvv2+","+DB.im_credit_limit+","+DB.de_bank_acc,
                                   DB.gu_workarea+"=? AND "+DB.bo_active+"=0 AND "+DB.nu_bank_acc+" IN (SELECT "+DB.nu_bank_acc+" FROM "+DB.k_x_company_bank+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_company+"=?)",10);

    oAccs.load(oConn, new Object[]{get(DB.gu_workarea),get(DB.gu_workarea),get(DB.gu_company)});
    return oAccs;
  } // getUnactiveBankAccounts

  // ----------------------------------------------------------

  /**
   * Store Company
   * Automatically generates gu_company GUID and dt_modified DATE if not explicitly set.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_company))
      put(DB.gu_company, Gadgets.generateUUID());

    replace(DB.dt_modified, dtNow);

    return super.store(oConn);
  } // store

  // ----------------------------------------------------------

  /**
   * Delete Company
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return Company.delete(oConn, getString(DB.gu_company));
  }

  // ----------------------------------------------------------

  /**
   * <p>Find out whether or not a company exists at database</p>
   * Look up company by GUID or by legal name and work area.
   * @param oConn database connection
   * @return <b>true</b> if a company with such GUID or legal name+work area is found.
   * @throws SQLException
   */

  public boolean exists(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_companies+" WHERE "+DB.gu_company+"=? OR ("+DB.nm_legal+"=? AND "+DB.gu_workarea+"=?)",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getStringNull(DB.gu_company,null));
    oStmt.setString(2, getStringNull(DB.nm_legal,null));
    oStmt.setString(3, getStringNull(DB.gu_workarea,null));
    ResultSet oRSet = oStmt.executeQuery();
    boolean bExists = oRSet.next();
    oRSet.close();
    oStmt.close();
    return bExists;
  } // exists

  // ----------------------------------------------------------

  /**
   * <P>Add an Address to this Company</P>
   * If contact is already associated to the given address a foreign key violation
   * SQLExceception is raised.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean addAddress(JDCConnection oConn, String sAddrGUID) throws SQLException {
    PreparedStatement oStmt = null;
    boolean bRetVal;

    try {
      oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_company_addr + " (" + DB.gu_company + "," + DB.gu_address + ") VALUES (?,?)");
      oStmt.setString(1, getStringNull(DB.gu_company, null));
      oStmt.setString(2, sAddrGUID);
      int iAffected = oStmt.executeUpdate();
      oStmt.close();
      oStmt = null;
      bRetVal = (iAffected > 0);
    } catch (SQLException sqle) {
      bRetVal = false;
      try { if (oStmt!=null) oStmt.close(); } catch (Exception ignore) {}
    }
    return bRetVal;
  } // addAddress

  // ----------------------------------------------------------

  /**
   * Get address by location type
   * @param oConn JDCConnection
   * @param sTpLocation String Value for column tp_location from k_addresses table
   * @return Address or <b>null</b> is no address with such location type was found
   * @throws SQLException
   * @throws IllegalStateException if gu_company property is not set
   * @since 3.0
   */
  public Address getAddress(JDCConnection oConn, String sTpLocation)
    throws SQLException,IllegalStateException {

    Address oRetAdr;

    if (isNull(DB.gu_company))
      throw new IllegalStateException("Company.getAddress([Connection],"+sTpLocation+") gu_company property is not set");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Company.getAddress([Connection],"+sTpLocation+")" );
      DebugFile.incIdent();
    }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT x." + DB.gu_address +
                                                     " FROM " + DB.k_x_company_addr + " x," +
                                                     DB.k_addresses + " a WHERE " +
                                                     "x." + DB.gu_address + "=a." + DB.gu_address +
                                                     " AND x." + DB.gu_company+"=?" +
                                                     " AND a." + DB.tp_location+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getString(DB.gu_company));
    oStmt.setString(2, sTpLocation);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      oRetAdr = new Address(oConn, oRSet.getString(1));
    else
      oRetAdr = null;
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Company.getAddress()");
    }
    return oRetAdr;
  } // getAddress

  // ----------------------------------------------------------

  /**
   * <p>Get Company Addresses</p>
   * @param oConn Database Connection
   * @return A DBSubset with all columns from k_addresses for Company
   * @throws SQLException
   * @throws IllegalStateException if gu_company property is not set
   */
  public DBSubset getAddresses(JDCConnection oConn)
      throws SQLException,IllegalStateException {

    if (isNull(DB.gu_company))
      throw new IllegalStateException("Company.getAddresses() gu_company property is not set");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Company.getAddresses([Connection])" );
      DebugFile.incIdent();
    }

    Address oAddr = new Address();

    DBSubset oAddrs = new DBSubset (DB.k_addresses,
                                    oAddr.getTable(oConn).getColumnsStr(),
                                    DB.gu_address + " IN (SELECT " + DB.gu_address +  " FROM " + DB.k_x_company_addr + " WHERE " + DB.gu_company + "=?)", 10);
    int iAddrs = oAddrs.load(oConn, new Object[]{getString(DB.gu_company)});

    oAddr = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Company.getAddresses() : " + String.valueOf(iAddrs));
    }

    return oAddrs;
  } // getAddresses

  // ----------------------------------------------------------

  /**
   * <p>Get Company Addresses</p>
   * @param oConn Database Connection
   * @return A DBSubset with all columns from k_addresses for Company
   * @throws SQLException
   * @throws IllegalStateException if gu_company property is not set
   * @since 4.0
   */
  public DBSubset getActiveAddresses(JDCConnection oConn)
      throws SQLException,IllegalStateException {

    if (isNull(DB.gu_company))
      throw new IllegalStateException("Company.getActiveAddresses() gu_company property is not set");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Company.getActiveAddresses([Connection])" );
      DebugFile.incIdent();
    }

    Address oAddr = new Address();

    DBSubset oAddrs = new DBSubset (DB.k_addresses,
                                    oAddr.getTable(oConn).getColumnsStr(),
                                    DB.bo_active+"<>0 AND "+
                                    DB.gu_address + " IN (SELECT " + DB.gu_address +  " FROM " + DB.k_x_company_addr + " WHERE " + DB.gu_company + "=?)", 10);
    int iAddrs = oAddrs.load(oConn, new Object[]{getString(DB.gu_company)});

    oAddr = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Company.getActiveAddresses() : " + String.valueOf(iAddrs));
    }

    return oAddrs;
  } // getActiveAddresses

  // ----------------------------------------------------------

  /**
   * <p>Get an XML dump for Company and its associated addresses</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @param sDelim Line delimiter (usually "\n" or "\r\n")
   * @throws IllegalStateException If XML method is invoked before Company object is loaded
   * @throws SQLException
   * @since 4.0
   */
  public String toXML(JDCConnection oConn, String sIdent, String sDelim)
  	throws IllegalStateException,SQLException {
    String sXml = toXML(sIdent, sDelim);
	DBSubset oAddrs = getAddresses(oConn);
	int nAddrs = oAddrs.getRowCount();
    StringBuffer oXml = new StringBuffer(sXml.length()+512*nAddrs);
	oXml.append(sXml.substring(0,sXml.indexOf(sIdent + "</" + sAuditCls + ">")));
	oXml.append(sIdent+"  <Addresses count=\""+String.valueOf(nAddrs)+"\">"+sDelim);
	Address oAddr = new Address();
	oAddr.getTable(oConn);
	for (int a=0; a<nAddrs; a++) {
	  oAddr.putAll(oAddrs.getRowAsMap(a));
	  oXml.append(oAddr.toXML(sIdent+"    ", sDelim));
	  oXml.append(sDelim);
	  oAddr.clear();
	} // next
	oXml.append(sIdent+"  </Addresses>"+sDelim);
    oXml.append(sIdent + "</" + sAuditCls + ">");
    return oXml.toString();
  } // toXML

  // ----------------------------------------------------------

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete Company.</p>
   * Delete all associated contacts and call k_sp_del_company stored procedure.<br>
   * If k_orders table exists, then Orders for this Company are deleted.<br>
   * If k_projects table exists, then Projects for this Company are deleted.<br>
   * @param oConn Database Connection
   * @param sCompanyGUID Company GUID
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sCompanyGUID) throws SQLException {
    boolean bRetVal;
    Statement oStmt;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Company.delete([Connection], " + sCompanyGUID + ")");
      DebugFile.incIdent();
    }

    /* Desasociar los e-mails */
     if (DBBind.exists(oConn, DB.k_inet_addrs, "U")) {
       oStmt = oConn.createStatement();

       if (DebugFile.trace)
         DebugFile.writeln("UPDATE " + DB.k_inet_addrs + " SET " + DB.gu_company + "=NULL WHERE " + DB.gu_company + "='" + sCompanyGUID + "'");

       oStmt.executeUpdate("UPDATE " + DB.k_inet_addrs + " SET " + DB.gu_company + "=NULL WHERE " + DB.gu_company + "='" + sCompanyGUID + "'");

       oStmt.close();
     }

    if (DBBind.exists(oConn, DB.k_projects, "U")) {
      DBSubset oProjs = new DBSubset(DB.k_projects, DB.gu_project, DB.gu_company + "='" + sCompanyGUID + "'", 10);

      int iProjs = oProjs.load(oConn);

      for (int p=0; p<iProjs; p++)
        com.knowgate.projtrack.Project.delete (oConn, oProjs.getString(0,p));
    }

    if (DBBind.exists(oConn, DB.k_orders, "U")) {
      DBSubset oOrders = new DBSubset(DB.k_orders, DB.gu_order, DB.gu_company + "='" + sCompanyGUID + "'", 1000);

      int iOrders = oOrders.load(oConn);

      for (int o=0; o<iOrders; o++)
        com.knowgate.hipergate.Order.delete (oConn, oOrders.getString(0,o));
    } // fi (exists(DB.k_orders))

    DBSubset oContacts = new DBSubset(DB.k_contacts, DB.gu_contact, DB.gu_company + "='" + sCompanyGUID + "'", 1000);
    int iContacts = oContacts.load(oConn);

    for (int c=0; c<iContacts; c++)
      Contact.delete(oConn, oContacts.getString(0,c));

    oContacts = null;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT k_sp_del_company ('" + sCompanyGUID + "')");
      oStmt.executeQuery("SELECT k_sp_del_company ('" + sCompanyGUID + "')");
      oStmt.close();
      bRetVal = true;
    }
    else {

      if (DebugFile.trace)
        DebugFile.writeln ("Conenction.prepareCall({call k_sp_del_company ('" + sCompanyGUID + "')}");

      CallableStatement oCall = oConn.prepareCall("{call k_sp_del_company ('" + sCompanyGUID + "')}");
      bRetVal = oCall.execute();
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Company.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  /**
   * <p>Add a Company Sector lookup value</a>
   * @param oConn Connection
   * @param sGuWorkArea String GUID of WorkArea
   * @param sDeTitle String Sector Internal Identifier
   * @param oTranslations HashMap with one entry for each language
   * @return boolean <b>true</b> if new sector was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 3.0
   */
  public static boolean addLookupSector (Connection oConn, String sGuWorkArea, String sIdSector, HashMap oTranslations)
    throws SQLException {
    return DBLanguages.addLookup(oConn, DB.k_companies_lookup, sGuWorkArea, DB.id_sector, sIdSector, oTranslations);
  }

  /**
   * <p>Add a Company Type lookup value</a>
   * @param oConn Connection
   * @param sGuWorkArea String GUID of WorkArea
   * @param sDeTitle String Company Type Internal Identifier
   * @param oTranslations HashMap with one entry for each language
   * @return boolean <b>true</b> if new sector was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 3.0
   */
  public static boolean addLookupCompanyType (Connection oConn, String sGuWorkArea, String sIdType, HashMap oTranslations)
    throws SQLException {
    return DBLanguages.addLookup(oConn, DB.k_companies_lookup, sGuWorkArea, DB.tp_company, sIdType, oTranslations);
  }

  /**
   * <p>Get company GUID given its legal name</p>
   * @param oConn Connection
   * @param sLegalName String Legal name of sought Company
   * @param sWorkArea String GUID of WorkArea where to search
   * @return String Company GUID or <b>null</b> if no company with such legal name was found at given work area
   * @throws SQLException
   * @since 3.0
   */
  public static String getIdFromName(Connection oConn, String sLegalName, String sWorkArea)
    throws SQLException {
    String sRetVal;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_companies+" WHERE "+DB.nm_legal+"=? AND "+DB.gu_workarea+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sLegalName);
    oStmt.setString(2, sWorkArea);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();
    return sRetVal;
  } // getIdFromName

  /**
   * <p>Get company GUID given its external reference</p>
   * @param oConn Connection
   * @param sLegalName String External reference of sought Company
   * @param sWorkArea String GUID of WorkArea where to search
   * @return String Company GUID or <b>null</b> if no company with such reference was found at given work area
   * @throws SQLException
   * @since 3.0
   */
  public static String getIdFromRef(Connection oConn, String sReference, String sWorkArea)
    throws SQLException {
    String sRetVal;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_companies+" WHERE "+DB.id_ref+"=? AND "+DB.gu_workarea+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sReference);
    oStmt.setString(2, sWorkArea);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();
    return sRetVal;
  } // getIdFromRef

  /**
   * <p>Get company GUID given its legal number</p>
   * @param oConn Connection
   * @param sLegalName String Legal Number of sought Company
   * @param sWorkArea String GUID of WorkArea where to search
   * @return String Company GUID or <b>null</b> if no company with such legal number was found at given work area
   * @throws SQLException
   * @since 3.0
   */
  public static String getIdFromLegalNum(Connection oConn, String sLegalId, String sWorkArea)
    throws SQLException {
    String sRetVal;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_companies+" WHERE "+DB.id_legal+"=? AND "+DB.gu_workarea+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sLegalId);
    oStmt.setString(2, sWorkArea);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();
    return sRetVal;
  } // getIdFromLegalNum
  
  public static Company forAddress(JDCConnection oConn, String sGuAddr)
    throws SQLException {
    
    String sGuCompany;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_x_company_addr+" WHERE "+DB.gu_address+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuAddr);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sGuCompany = oRSet.getString(1);
    else
      sGuCompany = null;
    oRSet.close();
    oStmt.close();
    if (sGuCompany!=null) {
      return new Company(oConn, sGuCompany);
    } else {
      return null;
    }	  
  } // forAddress

  // **********************************************************
  // Public Constants

  public static final short ClassId = 91;
}
