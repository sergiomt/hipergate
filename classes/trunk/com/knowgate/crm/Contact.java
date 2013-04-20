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

import java.io.File;
import java.io.IOException;
import java.io.FileNotFoundException;

import java.util.Date;
import java.util.HashMap;
import java.util.Properties;
import java.util.ListIterator;
import java.util.StringTokenizer;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;

import org.xml.sax.SAXException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Environment;
import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.ACLDomain;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.hipergate.Product;
import com.knowgate.hipergate.Address;
import com.knowgate.datacopy.DataStruct;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.hipergate.ProductLocation;
import com.knowgate.workareas.FileSystemWorkArea;

/**
 * <p>Contact</p>
 * <p>Copyright: Copyright (c) KnowGate 2003</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class Contact extends DBPersist {

  /**
   * Create Empty Contact.
   */
  public Contact() {
     super(DB.k_contacts, "Contact");
  }

  /**
   * Create Contact and set gu_contact field.
   * Does not load other fields from database.
   * @param sIdContact Contact GUID
   */
  public Contact(String sIdContact) throws SQLException {
    super(DB.k_contacts,"Contact");
    put(DB.gu_contact, sIdContact);
  }

  /**
   * Create Contact and load fields from database.
   * @param oConn Database Connection
   * @param sIdContact Contact GUID
   */
  public Contact(JDCConnection oConn, String sIdContact) throws SQLException {
    super(DB.k_contacts,"Contact");

    Object aCont[] = { sIdContact };

    load (oConn,aCont);
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Contact</p>
   * Automatically generates gu_contact GUID and dt_modified DATE if not explicitly set.<br>
   * If gu_company field is <b>null</b> and nm_legal field is not <b>null</b> then gu_company
   * field is automatically looked up at k_companies table and put in this DBPersist before storing it.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Contact.store([Connection])");
      DebugFile.incIdent();
    }

    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_contact))
      put(DB.gu_contact, Gadgets.generateUUID());

    if (!AllVals.containsKey(DB.gu_company) && AllVals.containsKey(DB.nm_legal)) {

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_company + " FROM " + DB.k_companies + " WHERE " + DB.gu_workarea + "='" + getStringNull(DB.gu_workarea, "null") + "' AND " + DB.nm_legal + "='" + getStringNull(DB.nm_legal, "null") + "')");

      oStmt = oConn.prepareStatement("SELECT " + DB.gu_company + " FROM " + DB.k_companies + " WHERE " + DB.gu_workarea + "=? AND " + DB.nm_legal + "=?",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      oStmt.setString(1, getStringNull(DB.gu_workarea, null));
      oStmt.setString(2, getStringNull(DB.nm_legal, null));
      oRSet = oStmt.executeQuery();

      if (oRSet.next()) {
        if (DebugFile.trace) DebugFile.writeln("gu_company=" + oRSet.getString(1));

        AllVals.put(DB.gu_company, oRSet.getString(1));
      }
      else
        if (DebugFile.trace) DebugFile.writeln("no company guid found for " + getStringNull(DB.nm_legal, null));

      oRSet.close();
      oStmt.close();
    } // fi (gu_company==null && nm_legal!=null)

    replace(DB.dt_modified, dtNow);

    boolean bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Contact.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  /**
   * Delete Contact.
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return Contact.delete(oConn, getString(DB.gu_contact));
  }

  // ----------------------------------------------------------

  /**
   * Clone Contact.
   * @param oConn JDBC connection
   * @param sTargetWorkAreaId GUID of targer WorkArea or <b>null</b> if the contact is to be cloned in the same WorkArea as this one.
   * @throws SQLException
   * @see com.knowgate.hipergate.datamodel.ModelManager#cloneContacts(String,String,String)
   * @since 6.0
   */
  public void clone(JDCConnection oConn, String sTargetWorkAreaId, String sNewOwnerId)
  	throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Contact.clone(" + sTargetWorkAreaId + "," + sNewOwnerId + ")");
      DebugFile.incIdent();
    }

	DataStruct oDS = null;
    Object[] oPKOr = new Object[] { getString(DB.gu_contact) };
	Object[] oPKTr = new Object[] { Gadgets.generateUUID() } ;
	String sContactXml = null;
	String sCompanyXml = null;
	
	FileSystemWorkArea oFsw = new FileSystemWorkArea(((DBBind)oConn.getPool().getDatabaseBinding()).getProperties());
    try {
        switch (oConn.getDataBaseProduct()) {
          case com.knowgate.jdc.JDCConnection.DBMS_MSSQL:
            sContactXml = oFsw.readstorfilestr("datacopy/mssql/contact_clon.xml", "UTF-8");
            sCompanyXml = oFsw.readstorfilestr("datacopy/mssql/company_clon.xml", "UTF-8");
            break;
          case com.knowgate.jdc.JDCConnection.DBMS_MYSQL:
            sContactXml = oFsw.readstorfilestr("datacopy//mysql/contact_clon.xml", "UTF-8");
            sCompanyXml = oFsw.readstorfilestr("datacopy//mysql/company_clon.xml", "UTF-8");
            break;
          case com.knowgate.jdc.JDCConnection.DBMS_ORACLE:
            sContactXml = oFsw.readstorfilestr("datacopy/oracle/contact_clon.xml", "UTF-8");
            sCompanyXml = oFsw.readstorfilestr("datacopy/oracle/company_clon.xml", "UTF-8");
            break;
          case com.knowgate.jdc.JDCConnection.DBMS_POSTGRESQL:
            sContactXml = oFsw.readstorfilestr("datacopy/postgresql/contact_clon.xml", "UTF-8");
            sCompanyXml = oFsw.readstorfilestr("datacopy/postgresql/company_clon.xml", "UTF-8");
            break;
          default:
            if (DebugFile.trace) {
              DebugFile.writeln("Unsupported database "+oConn.getMetaData().getDatabaseProductName());
              DebugFile.decIdent();
            }
      	    throw new SQLException ("Unsupported database "+oConn.getMetaData().getDatabaseProductName());
        }
    } catch (com.enterprisedt.net.ftp.FTPException neverthrown) { }
	  catch (IOException ioe) { throw new SQLException (ioe.getMessage(), ioe); }

    Properties oParams = new Properties();
    oParams.put("WorkAreaId", sTargetWorkAreaId==null ? getString(DB.gu_workarea) : sTargetWorkAreaId);
    oParams.put("OwnerId", sNewOwnerId==null ? getStringNull(DB.gu_writer,null) : sNewOwnerId);

	try {
	  String sCompanyGuid = null;

	  if (!isNull(DB.gu_company) && !getString(DB.gu_workarea).equals(sTargetWorkAreaId)) {        
        String[] aCompanyInfo = DBCommand.queryStrs(oConn, "SELECT "+DB.nm_legal+","+DB.id_legal+" FROM "+DB.k_companies+" WHERE "+DB.gu_company+"='"+getString(DB.gu_company)+"'");
        
        PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_company+" FROM "+DB.k_companies+" WHERE "+DB.gu_workarea+"='"+sTargetWorkAreaId+"' AND ("+DB.nm_legal+"=? OR "+DB.id_legal+"=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
		oStmt.setString(1, aCompanyInfo[0]);
		oStmt.setString(2, aCompanyInfo[1]);
		ResultSet oRSet = oStmt.executeQuery();
		if (oRSet.next())
		  sCompanyGuid = oRSet.getString(1);
		else
		  sCompanyGuid = Gadgets.generateUUID();
		oRSet.close();
		oStmt.close();

        oDS = new DataStruct();
        oDS.setOriginConnection(oConn);
        oDS.setTargetConnection(oConn);
        oDS.setAutoCommit(false);
        oDS.parse (sCompanyXml, oParams);
        oDS.insert(new Object[]{getString(DB.gu_company)}, new Object[]{sCompanyGuid}, 0);
	    oDS.commit();
	    oDS.clear();
	    oDS = null;
	  }
	  
      oDS = new DataStruct();

      oDS.setOriginConnection(oConn);
      oDS.setTargetConnection(oConn);
      oDS.setAutoCommit(false);

      oDS.parse (sContactXml, oParams);
      oDS.insert(oPKOr, oPKTr, 0);
	  oDS.commit();
	  
	  if (sCompanyGuid!=null)
	    DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_contacts+" SET "+DB.gu_company+"='"+sCompanyGuid+"' WHERE "+DB.gu_contact+"='"+oPKTr[0]+"'");

	} catch (SAXException se) {
	  throw new SQLException (se.getMessage(), se);
	} catch (IOException io) {
	  throw new SQLException (io.getMessage(), io);
	} catch (ClassNotFoundException ce) {
	  throw new SQLException (ce.getMessage(), ce);
	} catch (IllegalAccessException ia) {
	  throw new SQLException (ia.getMessage(), ia);
	} catch (InstantiationException ie) {
	  throw new SQLException (ie.getMessage(), ie);
	} finally {
      if (oDS!=null) oDS.clear();
	}

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Contact.clone()");
    }
  } // clone

  // ----------------------------------------------------------

  /**
   * </p>Get groups that may have access to this contact.</p>
   * @param oConn Database Connection
   * @return A {@link DBSubset} with a 1 column containing each group unique identifier (gu_acl_group).
   * @throws SQLException
   * @since 4.0
   */
  public DBSubset getGroups(JDCConnection oConn) throws SQLException {
    Object aContact[] = { get(DB.gu_contact) };
    DBSubset oGroups = new DBSubset(DB.k_x_group_contact,DB.gu_acl_group,DB.gu_contact + "=?",10);

    oGroups.load (oConn, aContact);
    return oGroups;
  } // getGroups

  // ----------------------------------------------------------

  /**
   * <p>Add Contact to a set of security restrictions groups.</p>
   * <p>Insert new registers at k_x_group_contact table.</p>
   * @param oConn Database Connection
   * @param sGroupList A string of comma delimited ACLGroup GUIDs to with this ACLUser must be added.
   * @throws SQLException May throw a primary key constraint violation if contact already belongs to group.
   * @since 4.0
   */
  public int addToACLGroups(JDCConnection oConn, String sGroupList) throws SQLException {

     if (DebugFile.trace) {
        DebugFile.writeln("Begin Contact.addToACLGroups(Connection], " + sGroupList + ")");
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
         DebugFile.writeln("Statement.executeUpdate(INSERT INTO " + DB.k_x_group_contact + "(" + DB.gu_contact + "," + DB.gu_acl_group + ") VALUES('" + getStringNull(DB.gu_contact, "null") + "','" + sIdGroup + "')");

       iRetVal += oStmt.executeUpdate("INSERT INTO " + DB.k_x_group_contact + "(" + DB.gu_contact + "," + DB.gu_acl_group + ") VALUES('" + getString(DB.gu_contact) + "','" + sIdGroup + "')");
     } // wend

	 oStmt.executeUpdate("UPDATE "+DB.k_contacts+" SET "+DB.bo_restricted+"="+(iRetVal>0 ? "1" : "0")+" WHERE "+DB.gu_contact+"='"+getString(DB.gu_contact)+"'");

     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Contact.addToACLGroups() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // addToACLGroups

  // ----------------------------------------------------------

  /**
   * <p>Remove contact from all security restrictions groups</p>
   * @param oConn Database Connection
   * @return Count of groups from witch user was removed.
   * @throws SQLException
   * @since 4.0
   */
  public int clearACLGroups(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Contact.clearACLGroups([Connection])");
      DebugFile.incIdent();
    }

     int iRetVal;

     Statement oStmt = oConn.createStatement();
     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_contact + " WHERE " + DB.gu_contact + "='" + getString(DB.gu_contact) + "'");
	 oStmt.executeUpdate("UPDATE "+DB.k_contacts+" SET "+DB.bo_restricted+"=0 WHERE "+DB.gu_contact+"='"+getString(DB.gu_contact)+"'");
     oStmt.close();

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Contact.clearACLGroups() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // clearACLGroups

  // ----------------------------------------------------------

  /**
   * <p>Remove Contact from security restrictions group.</p>
   * <p>remove register from k_x_group_user table.</p>
   * @param oConn Database Connection
   * @param sIdGroup Group Unique Identifier.
   * @throws SQLException
   * @since 4.0
   */

  public int removeFromACLGroup(JDCConnection oConn, String sIdGroup) throws SQLException {

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Contact.removeFromACLGroup(Connection], " + sIdGroup + ")");
       DebugFile.incIdent();
    }

     int iRetVal;
     Statement oStmt = oConn.createStatement();

     if (DebugFile.trace)
       DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_group_contact + " WHERE " + DB.gu_contact + "='" + getStringNull(DB.gu_contact, "null") + "' AND " + DB.gu_acl_group + "='" + sIdGroup + "'");

     iRetVal = oStmt.executeUpdate("DELETE FROM " + DB.k_x_group_contact + " WHERE " + DB.gu_contact + "='" + getString(DB.gu_contact) + "' AND " + DB.gu_acl_group + "='" + sIdGroup + "'");
     oStmt.close();

	 int iRemaining = DBCommand.queryInt(oConn,"SELECT COUNT(*) FROM " + DB.k_x_group_company + " WHERE " + DB.gu_company + "='" + getString(DB.gu_company) + "'");
	 if (0==iRemaining) DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_companies+" SET "+DB.bo_restricted+"=0 WHERE "+DB.gu_company+"='"+getString(DB.gu_company)+"'");

     if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End Contact.removeFromACLGroup() : " + String.valueOf(iRetVal));
     }

     return iRetVal;
  } // removeFromACLGroup

  // ----------------------------------------------------------

  /**
   * <P>Add an Address to this Contact</P>
   * If contact is already associated to the given address then a foreign key violation is thrown
   * @param oConn Database Connection
   * @throws SQLException
   * @throws NullPointerException
   * @since 3.0
   */
  public boolean addAddress(JDCConnection oConn, String sAddrGUID)
  	throws SQLException, NullPointerException {
    PreparedStatement oStmt = null;
    boolean bRetVal;

	if (isNull(DB.gu_contact))
	  throw new NullPointerException("Contact.addAddress() gu_contact may not be null");

	if (!DBCommand.queryExists(oConn, DB.k_x_contact_addr,
							   DB.gu_contact+"='"+getString(DB.gu_contact)+"' AND "+
							   DB.gu_address+"='"+sAddrGUID+"'")) {
      try {
        oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_contact_addr + " (" + DB.gu_contact + "," + DB.gu_address + ") VALUES (?,?)");
        oStmt.setString(1, getString(DB.gu_contact));
        oStmt.setString(2, sAddrGUID);
        int iAffected = oStmt.executeUpdate();
        oStmt.close();
        oStmt = null;
        bRetVal = (iAffected > 0);
      } catch (SQLException sqle) {
        bRetVal = false;
        try { if (oStmt!=null) oStmt.close(); } catch (Exception ignore) {}
      }
    } else {
      throw new SQLException("Contact.addAddress() The address "+sAddrGUID+" is already associated to contact "+getString(DB.gu_contact));
    }
    return bRetVal;
  } // addAddress

  // ----------------------------------------------------------

  /**
   * <P>Add a bank account to this Contact</P>
   * If contact is already associated to the given bank account then a foreign key violation SQLException is thrown
   * @param oConn Database Connection
   * @throws SQLException
   * @since 3.0
   */
  public boolean addBankAccount(JDCConnection oConn, String sFullBankAccount) throws SQLException {
    PreparedStatement oStmt = null;
    boolean bRetVal;

    try {
      oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_contact_bank + " (" + DB.gu_contact + "," + DB.nu_bank_acc + "," + DB.gu_workarea + ") VALUES (?,?,?)");
      oStmt.setString(1, getStringNull(DB.gu_contact, null));
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
   * Get Contact Address by index
   * @param oConn JDCConnection
   * @param iIndex int Address index as set at column ix_address of k_addresses table
   * @return Address or <b>null</b> if no Address with such index was found
   * @throws SQLException
   * @since 3.0
   */
  public Address getAddress(JDCConnection oConn, int iIndex) throws SQLException {
    String sGuAddr;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT a."+DB.gu_address+" FROM "+DB.k_addresses+" a,"+DB.k_x_contact_addr+" x WHERE a."+DB.gu_address+"=x."+DB.gu_address+" AND x."+DB.gu_contact+"=? AND a."+DB.ix_address+"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getStringNull(DB.gu_contact,null));
    oStmt.setInt(2, iIndex);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sGuAddr = oRSet.getString(1);
    else
      sGuAddr = null;
    oRSet.close();
    oStmt.close();
    if (null!=sGuAddr)
      return new Address(oConn, sGuAddr);
    else
      return null;
  }

  // ----------------------------------------------------------

  /**
   * Get Contact Address by location type
   * @param oConn JDCConnection
   * @param sTpLocation String Address type as set at column tp_location of k_addresses table
   * @return Address or <b>null</b> if no Address with such location type was found
   * @throws SQLException
   * @since 2.2
   */
  public Address getAddress(JDCConnection oConn, String sTpLocation) throws SQLException {
    String sGuAddr;
    PreparedStatement oStmt = oConn.prepareStatement("SELECT a."+DB.gu_address+" FROM "+DB.k_addresses+" a,"+DB.k_x_contact_addr+" x WHERE a."+DB.gu_address+"=x."+DB.gu_address+" AND x."+DB.gu_contact+"=? AND a."+DB.tp_location+"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getStringNull(DB.gu_contact,null));
    oStmt.setString(2, sTpLocation);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sGuAddr = oRSet.getString(1);
    else
      sGuAddr = null;
    oRSet.close();
    oStmt.close();
    if (null!=sGuAddr)
      return new Address(oConn, sGuAddr);
    else
      return null;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get Contact Addresses</p>
   * @param oConn Database Connection
   * @return A DBSubset with all columns from k_addresses for Contact
   * @throws SQLException
   * @throws NullPointerException If gu_contact is <b>null</b>
   */
  public DBSubset getAddresses(JDCConnection oConn) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Contact.getAddresses([Connection])" );
      DebugFile.incIdent();
    }

    if (isNull(DB.gu_contact)) throw new NullPointerException ("gu_contact not set");

    Address oAddr = new Address();

    DBSubset oAddrs = new DBSubset (DB.k_addresses,
                                    oAddr.getTable(oConn).getColumnsStr(),
                                    DB.gu_address + " IN (SELECT " + DB.gu_address +  " FROM " + DB.k_x_contact_addr + " WHERE " + DB.gu_contact + "='" + getString(DB.gu_contact) + "')", 10);
    int iAddrs = oAddrs.load (oConn);

    oAddr = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Contact.getAddresses() : " + String.valueOf(iAddrs));
    }

    return oAddrs;
  } // getAddresses

  // ----------------------------------------------------------

  /**
   * Get all bank accounts associated with Contact
   * @param oConn JDCConnection
   * @return DBSubset nu_bank_acc,dt_created,bo_active,tp_account,nm_bank,tx_addr,nm_cardholder,nu_card,tp_card,tx_expire,nu_pin,nu_cvv2,im_credit_limit,de_bank_acc
   * @throws SQLException
   * @throws IllegalStateException if gu_contact or gu_workarea are not set
   * @since 3.0
   */
  public DBSubset getAllBankAccounts(JDCConnection oConn)
    throws SQLException,IllegalStateException {
    if (isNull(DB.gu_contact))
      throw new IllegalStateException("Contact.getAllBankAccounts() gu_contact property is not set");
    if (isNull(DB.gu_workarea))
      throw new IllegalStateException("Contact.getAllBankAccounts() gu_workarea property is not set");

    DBSubset oAccs = new DBSubset (DB.k_bank_accounts,
                                   DB.nu_bank_acc+","+DB.dt_created+","+DB.bo_active+","+DB.tp_account+","+DB.nm_bank+","+DB.tx_addr+","+DB.nm_cardholder+","+DB.nu_card+","+DB.tp_card+","+DB.tx_expire+","+DB.nu_pin+","+DB.nu_cvv2+","+DB.im_credit_limit+","+DB.de_bank_acc,
                                   DB.gu_workarea+"=? AND "+DB.nu_bank_acc+" IN (SELECT "+DB.nu_bank_acc+" FROM "+DB.k_x_contact_bank+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_contact+"=?)",10);

    oAccs.load(oConn, new Object[]{get(DB.gu_workarea),get(DB.gu_workarea),get(DB.gu_contact)});
    return oAccs;
  } // getAllBankAccounts

  // ----------------------------------------------------------

  /**
   * Get active bank accounts for this Contact
   * @param oConn JDCConnection
   * @return DBSubset nu_bank_acc,dt_created,tp_account,nm_bank,tx_addr,nm_cardholder,nu_card,tp_card,tx_expire,nu_pin,nu_cvv2,im_credit_limit,de_bank_acc
   * @throws SQLException
   * @throws IllegalStateException if gu_contact or gu_workarea are not set
   * @since 3.0
   */
  public DBSubset getActiveBankAccounts(JDCConnection oConn)
    throws SQLException,IllegalStateException {
    if (isNull(DB.gu_contact))
      throw new IllegalStateException("Contact.getActiveBankAccounts() gu_contact property is not set");
    if (isNull(DB.gu_workarea))
      throw new IllegalStateException("Contact.getActiveBankAccounts() gu_workarea property is not set");

    DBSubset oAccs = new DBSubset (DB.k_bank_accounts,
                                   DB.nu_bank_acc+","+DB.dt_created+","+DB.tp_account+","+DB.nm_bank+","+DB.tx_addr+","+DB.nm_cardholder+","+DB.nu_card+","+DB.tp_card+","+DB.tx_expire+","+DB.nu_pin+","+DB.nu_cvv2+","+DB.im_credit_limit+","+DB.de_bank_acc,
                                   DB.gu_workarea+"=? AND "+DB.bo_active+"<>0 AND "+DB.nu_bank_acc+" IN (SELECT "+DB.nu_bank_acc+" FROM "+DB.k_x_contact_bank+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_contact+"=?)",10);

    oAccs.load(oConn, new Object[]{get(DB.gu_workarea),get(DB.gu_workarea),get(DB.gu_contact)});
    return oAccs;
  } // getActiveBankAccounts

  // ----------------------------------------------------------

  /**
   * Get unactive bank accounts for this Contact
   * @param oConn JDCConnection
   * @return DBSubset nu_bank_acc,dt_created,tp_account,nm_bank,tx_addr,nm_cardholder,nu_card,tp_card,tx_expire,nu_pin,nu_cvv2,im_credit_limit,de_bank_acc
   * @throws SQLException
   * @throws IllegalStateException if gu_contact or gu_workarea are not set
   * @since 3.0
   */
  public DBSubset getUnactiveBankAccounts(JDCConnection oConn)
    throws SQLException,IllegalStateException {
    if (isNull(DB.gu_company))
      throw new IllegalStateException("Contact.getUnactiveBankAccounts() gu_company property is not set");
    if (isNull(DB.gu_workarea))
      throw new IllegalStateException("Contact.getUnactiveBankAccounts() gu_contact property is not set");

    DBSubset oAccs = new DBSubset (DB.k_bank_accounts,
                                   DB.nu_bank_acc+","+DB.dt_created+","+DB.tp_account+","+DB.nm_bank+","+DB.tx_addr+","+DB.nm_cardholder+","+DB.nu_card+","+DB.tp_card+","+DB.tx_expire+","+DB.nu_pin+","+DB.nu_cvv2+","+DB.im_credit_limit+","+DB.de_bank_acc,
                                   DB.gu_workarea+"=? AND "+DB.bo_active+"=0 AND "+DB.nu_bank_acc+" IN (SELECT "+DB.nu_bank_acc+" FROM "+DB.k_x_contact_bank+" WHERE "+DB.gu_workarea+"=? AND "+DB.gu_company+"=?)",10);

    oAccs.load(oConn, new Object[]{get(DB.gu_workarea),get(DB.gu_workarea),get(DB.gu_contact)});
    return oAccs;
  } // getUnactiveBankAccounts

  // ----------------------------------------------------------

  /**
   * Add an Attachment to a Contact
   * @param oConn JDCConnection
   * @param sGuWriter String GUID of user (from k_users table) who is uploading the attachment
   * @param sDirPath String Physical path (directory) where file to be attached ir located
   * @param sFileName String Name of file to be attached
   * @param bDeleteOriginalFile boolean <b>true</b> if original file must be deleted after being attached
   * @return Attachment
   * @throws SQLException
   * @throws NullPointerException
   * @throws FileNotFoundException
   * @throws Exception
   * @since 3.0
   */
  public Attachment addAttachment(JDCConnection oConn, String sGuWriter,
                                  String sDirPath, String sFileName,
                                  boolean bDeleteOriginalFile)
    throws SQLException,NullPointerException,FileNotFoundException,Exception {
    return addAttachment(oConn, sGuWriter, sDirPath, sFileName, null, bDeleteOriginalFile);
  }
  
  // ----------------------------------------------------------

  /**
   * Add an Attachment to a Contact
   * @param oConn JDCConnection
   * @param sGuWriter String GUID of user (from k_users table) who is uploading the attachment
   * @param sDirPath String Physical path (directory) where file to be attached ir located
   * @param sFileName String Name of file to be attached
   * @param sDescription String File Description (up to 254 characters)
   * @param bDeleteOriginalFile boolean <b>true</b> if original file must be deleted after being attached
   * @return Attachment
   * @throws SQLException
   * @throws NullPointerException
   * @throws FileNotFoundException
   * @throws Exception
   * @since 4.0
   */
  public Attachment addAttachment(JDCConnection oConn, String sGuWriter,
                                  String sDirPath, String sFileName,
                                  String sDescription,
                                  boolean bDeleteOriginalFile)
    throws SQLException,NullPointerException,FileNotFoundException,Exception {

  if (DebugFile.trace) {
    DebugFile.writeln("Begin Contact.addAttachment([Connection],"+sGuWriter+","+
                      sDirPath+","+sFileName+","+sDescription+","+String.valueOf(bDeleteOriginalFile)+")" );
    DebugFile.incIdent();
  }

    Date dtNow = new Date();
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sNmLegal;
    String sProfile;

    // Check that Contact is loaded
    if (isNull(DB.gu_contact) || isNull(DB.gu_workarea))
      throw new NullPointerException("Contact.addAttachment() Contact not loaded");

    if (null==sDirPath)
      throw new NullPointerException("Contact.addAttachment() File path may not be null");

    if (null==sFileName)
      throw new NullPointerException("Contact.addAttachment() File name may not be null");

    File oDir = new File(sDirPath);
    if (!oDir.isDirectory())
      throw new FileNotFoundException("Contact.addAttachment() "+sDirPath+" is not a directory");

    if (!oDir.exists())
      throw new FileNotFoundException("Contact.addAttachment() Directory "+sDirPath+" not found");

    File oFile = new File(Gadgets.chomp(sDirPath,File.separatorChar)+sFileName);
    if (!oFile.exists())
      throw new FileNotFoundException("Contact.addAttachment() File "+Gadgets.chomp(sDirPath,File.separatorChar)+sFileName+" not found");

    // Get Id. of Domain to which Contact belongs
    Integer iDom = ACLDomain.forWorkArea(oConn, getString(DB.gu_workarea));

    if (DebugFile.trace) DebugFile.writeln("id_domain="+iDom);

    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_ORACLE:
        oStmt = oConn.prepareStatement("SELECT k." + DB.nm_legal + " FROM " + DB.k_contacts + " c, " + DB.k_companies + " k WHERE c." + DB.gu_company + "=k." + DB.gu_company + "(+) AND c." + DB.gu_contact + "=? AND c." + DB.gu_company + " IS NOT NULL",
                                       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        break;
      default:
        oStmt = oConn.prepareStatement("SELECT k." + DB.nm_legal + " FROM " + DB.k_contacts + " c LEFT OUTER JOIN " + DB.k_companies + " k ON c." + DB.gu_company + "=k." + DB.gu_company + " WHERE c." + DB.gu_contact + "=? AND c." + DB.gu_company + " IS NOT NULL",
                                       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    }
    oStmt.setString(1, getString(DB.gu_contact));
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sNmLegal = Gadgets.ASCIIEncode(oRSet.getString(1));
    else
      sNmLegal = "_NOCOMPANY";
    oRSet.close();
    oStmt.close();

    String sCatPath = "apps/Sales/"+sNmLegal+"/"+getString(DB.gu_contact)+"/";

    if (DebugFile.trace) DebugFile.writeln("category path = "+sCatPath);

    if (null==oConn.getPool())
      sProfile = "hipergate";
    else
      sProfile = ((DBBind) oConn.getPool().getDatabaseBinding()).getProfileName();

    if (DebugFile.trace) DebugFile.writeln("profile = "+sProfile);

    FileSystemWorkArea oFileSys = new FileSystemWorkArea(Environment.getProfile(sProfile));
    oFileSys.mkstorpath(iDom.intValue(), getString(DB.gu_workarea), sCatPath);

    String sStorage = Environment.getProfilePath(sProfile, "storage");
    String sFileProtocol = Environment.getProfileVar(sProfile, "fileprotocol", "file://");
    String sFileServer = Environment.getProfileVar(sProfile, "fileserver", "localhost");

    String sWrkAHome = sStorage + "domains" + File.separator + iDom.toString() + File.separator + "workareas" + File.separator + getString(DB.gu_workarea) + File.separator;
    if (DebugFile.trace) DebugFile.writeln("workarea home = "+sWrkAHome);

    Product oProd = new Product();
    oProd.put(DB.nm_product,Gadgets.left(sFileName, 128));
    oProd.put(DB.gu_owner, sGuWriter);
    oProd.put(DB.dt_uploaded, dtNow);
    if (sDescription!=null) oProd.put(DB.de_product, Gadgets.left(sDescription,254));
    oProd.store(oConn);

    ProductLocation oLoca = new ProductLocation();
    oLoca.put(DB.gu_owner, sGuWriter);
    oLoca.put(DB.gu_product, oProd.get(DB.gu_product));
    oLoca.put(DB.dt_uploaded, dtNow);
    oLoca.setPath  (sFileProtocol, sFileServer, sWrkAHome + sCatPath, sFileName, sFileName);
    oLoca.setLength(oFile.length());
    oLoca.replace(DB.id_cont_type, oLoca.getContainerType());
    oLoca.store(oConn);

    if (sFileProtocol.equalsIgnoreCase("ftp://"))
      oLoca.upload(oConn, oFileSys, "file://" + sDirPath, sFileName, "ftp://" + sFileServer + sWrkAHome + sCatPath, sFileName);
    else
      oLoca.upload(oConn, oFileSys, "file://" + sDirPath, sFileName, sFileProtocol + sWrkAHome + sCatPath, sFileName);

    Attachment oAttach = new Attachment();
    oAttach.put(DB.gu_contact, getString(DB.gu_contact));
    oAttach.put(DB.gu_product, oProd.getString(DB.gu_product));
    oAttach.put(DB.gu_location, oLoca.getString(DB.gu_location));
    oAttach.put(DB.gu_writer, sGuWriter);
    oAttach.store(oConn);

    if (bDeleteOriginalFile) {
      if (DebugFile.trace) DebugFile.writeln("deleting file "+oFile.getAbsolutePath());
      oFile.delete();
      if (DebugFile.trace) DebugFile.writeln("deleting file "+sFileName+" deleted");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Contact.addAttachment() : " + String.valueOf(oAttach.getInt(DB.pg_product)));
    }

    return oAttach;
  } // addAttachment

  // ----------------------------------------------------------

  /**
   * Attach all files from a given directory
   * @param oConn JDCConnection
   * @param sGuWriter String GUID of user attaching the files
   * @param sDirPath String Directory Path
   * @param bDeleteOriginalFiles boolean <b>true</b> if original files must be deleted after being attached
   * @throws SQLException
   * @throws NullPointerException
   * @throws FileNotFoundException
   * @throws Exception
   * @since 3.0
   */
  public void addAttachments(JDCConnection oConn, String sGuWriter,
                             String sDirPath, boolean bDeleteOriginalFiles)
    throws SQLException,NullPointerException,FileNotFoundException,Exception {

    File oDir = new File(sDirPath);

    if (!oDir.exists())
      throw new FileNotFoundException("Contact.addAttachment() Directory "+sDirPath+" not found");

    if (!oDir.isDirectory())
      throw new FileNotFoundException("Contact.addAttachment() "+sDirPath+" is not a directory");

    if (!oDir.exists())
      throw new FileNotFoundException("Contact.addAttachment() Directory "+sDirPath+" not found");

    File[] aFiles = oDir.listFiles();
    if (null!=aFiles) {
      int nFiles = aFiles.length;
      for (int f=0; f<nFiles; f++)
        addAttachment(oConn, sGuWriter, sDirPath, aFiles[f].getName(), false);
      if (bDeleteOriginalFiles) {
        for (int f=0; f<nFiles; f++)
          aFiles[f].delete();
      } // fi (bDeleteOriginalFiles)
    } // fi
  } // addAttachments

  // ----------------------------------------------------------

  /**
   * Remove attachment
   * @param oConn JDCConnection
   * @param iPgAttachment int
   * @return boolean
   * @throws SQLException
   * @throws NullPointerException
   * @since 3.0
   */
  public boolean removeAttachment(JDCConnection oConn, int iPgAttachment)
    throws SQLException {
    Attachment oAttach = new Attachment();
    if (oAttach.load(oConn, new Object[]{get(DB.gu_contact),new Integer(iPgAttachment)}))
      return oAttach.delete(oConn);
    else
      return false;
  } // removeAttachment

  // ----------------------------------------------------------

  /**
   * Get array of products attached to this Contact
   * @param oConn JDCConnection
   * @return Attachment[] array or <b>null</b> if no products are attached to this contact
   * @throws SQLException
   * @throws NullPointerException if gu_contact is <b>null</b>
   * @since 3.0
   */
  public Attachment[] getAttachments(JDCConnection oConn)
    throws SQLException,NullPointerException {

    if (isNull(DB.gu_contact))
      throw new NullPointerException("Contact.getAttachments() Contact not loaded");

    Attachment oAttach = new Attachment();
    Attachment[] aAttachs;
    DBSubset oAttachs = new DBSubset(DB.k_contact_attachs,
                                     oAttach.getTable(oConn).getColumnsStr(),
                                     DB.gu_contact+"=?", 10);
    int iAttachs = oAttachs.load(oConn, new Object[]{get(DB.gu_contact)});
    if (0==iAttachs) {
      aAttachs = null;
    } else {
      aAttachs = new Attachment[iAttachs];
      ListIterator oCols = oAttach.getTable(oConn).getColumns().listIterator();
      while (oCols.hasNext()) {
        String sKey = (String) oCols.next();
        if (!sKey.equalsIgnoreCase(DB.dt_created)) {
          for (int a=0; a<iAttachs; a++) {
            aAttachs[a].put(sKey, oAttachs.get(sKey,a));
          } // next (a)
        } // fi (sKey!="dt_created")
      } // wend
    } // fi (iAttachs)
    return aAttachs;
  } // getAttachments

  // ----------------------------------------------------------

  /**
   * Get most recent WelCome Pack associated to this contact
   * @param oConn JDCConnection
   * @return WelcomePack
   * @throws SQLException
   * @since 3.0
   */
  public WelcomePack getWelcomePack(JDCConnection oConn) throws SQLException {
    return WelcomePack.forContact(oConn, getString(DB.gu_contact));
  }

  // ----------------------------------------------------------

  /**
   * Get Sales Man
   * @param oConn JDCConnection
   * @return SalesMan or <b>null</b> if gu_sales_man field is <b>null</b>
   * @throws SQLException
   * @since 7.0
   */
  public SalesMan getSalesMan(JDCConnection oConn) throws SQLException {
    if (isNull(DB.gu_sales_man)) {
      return null;
    } else {
      SalesMan oSlm = new SalesMan();
      oSlm.load(oConn, getString(DB.gu_sales_man));
      return oSlm;
    }
  }
  
  // ----------------------------------------------------------

  /**
   * <p>Get an XML dump for Contact and its associated addresses</p>
   * @param sIdent Number of blank spaces for left padding at every line.
   * @param sDelim Line delimiter (usually "\n" or "\r\n")
   * @throws IllegalStateException If XML method is invoked before Contact object is loaded
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

  // **********************************************************
  // Static Methods

  /**
   * Delete Contact.
   * The delete step by step is as follows:<br>
   * If k_x_meeting_contact table exists, then Contact is deleted from Meetings.<br>
   * If k_orders table exists, then Orders for this Contact are deleted.<br>
   * All Contact Attachments are deleted.<br>
   * Stored Procedure k_sp_del_contact is called
   * @param oConn Database Connection
   * @param sContactGUID GUID of Contact to be deleted
   * @throws SQLException
   */

  public static boolean delete(JDCConnection oConn, String sContactGUID) throws SQLException {
    boolean bRetVal;
    Statement oUpdt;
    PreparedStatement oDlte;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Contact.delete([Connection], " + sContactGUID + ")");
      DebugFile.incIdent();
    }

    /* Desasociar los e-mails */
    if (DBBind.exists(oConn, DB.k_inet_addrs, "U")) {
      oUpdt = oConn.createStatement();

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_inet_addrs + " SET " + DB.gu_contact + "=NULL WHERE " + DB.gu_contact + "='" + sContactGUID + "')");

      oUpdt.executeUpdate("UPDATE " + DB.k_inet_addrs + " SET " + DB.gu_contact + "=NULL WHERE " + DB.gu_contact + "='" + sContactGUID + "'");

      oUpdt.close();
    }

    /* Desasociar los proyectos */
    if (DBBind.exists(oConn, DB.k_projects, "U")) {
      oUpdt = oConn.createStatement();

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeUpdate(UPDATE " + DB.k_projects + " SET " + DB.gu_contact + "=NULL WHERE " + DB.gu_contact + "='" + sContactGUID + "')");

      oUpdt.executeUpdate("UPDATE " + DB.k_projects + " SET " + DB.gu_contact + "=NULL WHERE " + DB.gu_contact + "='" + sContactGUID + "'");
      oUpdt.close();
      oUpdt = null;
    }

    /* Borrar los pedidos, si existen */
    if (DBBind.exists(oConn, DB.k_orders, "U")) {
      DBSubset oOrders = new DBSubset(DB.k_orders, DB.gu_order, DB.gu_contact + "='" + sContactGUID + "'", 1000);

      int iOrders = oOrders.load(oConn);

      for (int o=0; o<iOrders; o++)
        com.knowgate.hipergate.Order.delete (oConn, oOrders.getString(0,o));
    } // fi (exists(DB.k_orders))

    /* Borrar las convocatorias a actividades, si existen */
    if (DBBind.exists(oConn, DB.k_x_meeting_contact, "U")) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_x_meeting_contact + " WHERE " + DB.gu_contact + "='" + sContactGUID + "')");

      oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_x_meeting_contact + " WHERE " + DB.gu_contact + "=?");

      oDlte.setString(1, sContactGUID);

      oDlte.executeUpdate();

      oDlte.close();

      oDlte = null;
    } // fi (exists(oConn, DB.k_x_meeting_contact))

    /* Borrar las llamadas telefónicas */
    if (DBBind.exists(oConn, DB.k_phone_calls, "U")) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_phone_calls + " WHERE " + DB.gu_contact + "='" + sContactGUID + "')");

      oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_phone_calls + " WHERE " + DB.gu_contact + "=?");

      oDlte.setString(1,sContactGUID);

      oDlte.executeUpdate();

      oDlte.close();
    } // fi (exists(oConn, DB.k_phone_calls))

    /* Borrar las reservas en cursos */
    if (DBBind.exists(oConn, DB.k_x_course_bookings, "U")) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_x_course_bookings + " WHERE " + DB.gu_contact + "='" + sContactGUID + "')");

      oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_x_course_bookings + " WHERE " + DB.gu_contact + "=?");

      oDlte.setString(1,sContactGUID);

      oDlte.executeUpdate();

      oDlte.close();
    } // fi (exists(oConn, DB.k_x_course_bookings))

    DBSubset oAttachs = new DBSubset(DB.k_contact_attachs, DB.gu_product, DB.gu_contact + "='" + sContactGUID + "'" , 64);
    int iAttachs = oAttachs.load(oConn);

    if (DebugFile.trace) DebugFile.writeln("new Product()");

    Product oProd = new Product();

    for (int a=0;a<iAttachs; a++) {
      oProd.replace(DB.gu_product, oAttachs.getString(0,a));
      oProd.delete(oConn);
    } // next (a)

    oProd = null;

    oAttachs = null;

    Statement oStmt = oConn.createStatement();

    if (DebugFile.trace)
      DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_contact_attachs + " WHERE " + DB.gu_contact + "='" + sContactGUID + "')");

    oStmt.executeUpdate("DELETE FROM " + DB.k_contact_attachs + " WHERE " + DB.gu_contact + "='" + sContactGUID + "'");
    oStmt.close();

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT k_sp_del_contact ('" + sContactGUID + "')");
      oStmt.executeQuery("SELECT k_sp_del_contact ('" + sContactGUID + "')");
      oStmt.close();
      bRetVal = true;
    }
    else {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareCall({ call k_sp_del_contact ('" + sContactGUID + "') }");

      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_contact ('" + sContactGUID + "') }");
      bRetVal = oCall.execute();
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Contact.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  /**
   * <p>Add a legal identification document type lookup value</a>
   * @param oConn Connection
   * @param sGuWorkArea String GUID of WorkArea
   * @param sTpPassport String Passport Type Internal Value
   * @param oTranslations HashMap with one entry for each language
   * @return boolean <b>true</b> if new legal identification document type was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 3.0
   */
  public static boolean addLookupPassportType (Connection oConn, String sGuWorkArea, String sTpPassport, HashMap<String,String> oTranslations)
    throws SQLException {
    return DBLanguages.addLookup(oConn,DB.k_contacts_lookup, sGuWorkArea, DB.tp_passport, sTpPassport, oTranslations);
  }

  /**
   * <p>Add a Job Title lookup value</a>
   * @param oConn Connection
   * @param sGuWorkArea String GUID of WorkArea
   * @param sDeTitle String Passport Type Internal Value
   * @param oTranslations HashMap with one entry for each language
   * @return boolean <b>true</b> if new job title was added, <b>false</b> if it already existed
   * @throws SQLException
   * @since 3.0
   */
  public static boolean addLookupJobTitle (Connection oConn, String sGuWorkArea, String sDeTitle, HashMap<String,String> oTranslations)
    throws SQLException {
    return DBLanguages.addLookup(oConn,DB.k_contacts_lookup, sGuWorkArea, DB.de_title, sDeTitle, oTranslations);
  }

  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 90;
}
