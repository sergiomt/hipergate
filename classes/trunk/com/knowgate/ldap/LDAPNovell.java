package com.knowgate.ldap;

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

import java.util.Properties;

import com.novell.ldap.LDAPAttribute;
import com.novell.ldap.LDAPAttributeSet;
import com.novell.ldap.LDAPEntry;
import com.novell.ldap.LDAPConnection;
import com.novell.ldap.LDAPSearchResults;
import com.novell.ldap.LDAPException;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.ResultSetMetaData;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * Very Basic LDAP interface API implementation
 * @author Sergio Montoro Ten
 * @version 2.1
 */

public class LDAPNovell extends LDAPModel {
  private LDAPConnection oConn;

  /**
   * This is the default pattern for the name of the hive that contains information about user logins
   * Parameters are as follows:
   * $1 = workarea name
   * $2 = domain name
   */
  private String USERS_HIVE_PATTERN = "dc=users,dc=$1,dc=$2";

  /**
   * This is the default pattern for the name of the leaf that contains the private contacts entries for a given user
   * Parameters are as follows:
   * $1 = e-mail of contact
   * $2 = e-mail of user owner of the contact
   * $3 = workarea name
   * $4 = domain name
   */
  private String PRIVATE_CONTACTS_LEAF_PATTERN = "cn=$1,dc=privateContacts,cn=$2,dc=users,dc=$3,dc=$4";

  /**
   * This is the default pattern for the name of the hive that contains the public contacts
   * Parameters are as follows:
   * $1 = e-mail of contact
   * $2 = workarea name
   * $3 = domain name
   */
  private String PUBLIC_CONTACTS_LEAF_PATTERN = "cn=$1,dc=publicContacts,dc=$2,dc=$3";

  // ---------------------------------------------------------------------------

  public LDAPNovell() {
    oConn = null;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Connect to LDAP Service</p>
   * At this point, there is no authentication, and any operations are conducted as an anonymous client.
   * @param sConnStr ldap://<i>host</i>:port/<i>distinguished_name</i><br><b>Example</b> "ldap://fobos.kg.int:389/dc=hipergate,dc=org"
   * @throws com.knowgate.ldap.LDAPException
   */
  public void connect(String sConnStr) throws com.knowgate.ldap.LDAPException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.connect(" + sConnStr + ")");
      DebugFile.incIdent();
    }

    if (sConnStr.startsWith("ldap://")) sConnStr = sConnStr.substring(7);

    String sService = sConnStr.substring(0, sConnStr.indexOf('/'));
    String[] aService = Gadgets.split2(sService, ':');

    try {
      oConn = new LDAPConnection();
      if (aService.length<2)
        oConn.connect(aService[0].trim(), 389);
      else
        oConn.connect(aService[0].trim(), Integer.parseInt(aService[1]));
      setPartitionName(sConnStr.substring(sConnStr.indexOf('/')+1));
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      if (DebugFile.trace)
        DebugFile.decIdent();
      setPartitionName(null);
      if (DebugFile.trace) {
        DebugFile.writeln("LDAPNovell.connect() LDAPException "+xcpt.getMessage());
        DebugFile.decIdent();
      }
      throw new com.knowgate.ldap.LDAPException(xcpt.getMessage(), xcpt);
    }
    catch (java.lang.NumberFormatException nfe) {
      if (DebugFile.trace) {
        DebugFile.writeln("LDAPNovell.connect() NumberFormatException Invalid port number");
        DebugFile.decIdent();
      }
      setPartitionName(null);
      throw new com.knowgate.ldap.LDAPException("Invalid port number", nfe);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.connect()");
    }
  } // connect

  // ---------------------------------------------------------------------------

  /**
   * <P>Connect to LDAP Server using a Properties object</P>
   * @param oProps Properties for connecting to LDAP server.<BR>
   * For example :<BR>
   * ldapconnect=ldap://fobos.kg.int:389/dc=hipergate,dc=org<BR>
   * ldapuser=cn=Manager,dc=hipergate,dc=org<BR>
   * ldappassword=manager<BR>
   * @throws com.knowgate.ldap.LDAPException
   */
  public void connectAndBind (Properties oProps)
    throws com.knowgate.ldap.LDAPException {

    connect (oProps.getProperty("ldapconnect"));
    bind(oProps.getProperty("ldapuser"), oProps.getProperty("ldappassword"));
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Synchronously disconnects from the LDAP server</p>
   * The disconnect method abandons any outstanding requests, issues an unbind request to the server, and then closes the socket.
   * @throws com.knowgate.ldap.LDAPException
   */
  public void disconnect() throws com.knowgate.ldap.LDAPException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.disconnect()");
      DebugFile.incIdent();
    }

    try {
      if (oConn!=null) oConn.disconnect();
      oConn = null;
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      if (DebugFile.trace)
        DebugFile.decIdent();
      throw new com.knowgate.ldap.LDAPException(xcpt.getMessage(), xcpt);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.disconnect()");
    }
  } // disconnect

  // ---------------------------------------------------------------------------

  /**
   * <p>Synchronously authenticates to the LDAP server using LDAP_V3.</p>
   * If the object has been disconnected from an LDAP server, this method attempts to reconnect to the server. If the object has already authenticated, the old authentication is discarded.
   * @param sUser If non-null and non-empty, specifies that the connection and all operations through it should be authenticated with dn as the distinguished name.
   * @param sPass If non-null and non-empty, specifies that the connection and all operations through it should be authenticated with dn as the distinguished name and passwd as password.
   * @throws LDAPException
   * @throws IllegalStateException If not conencted to LDAP
   */
  public void bind(String sUser, String sPass) throws com.knowgate.ldap.LDAPException,IllegalStateException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.bind(" + sUser + ",...)");
      DebugFile.incIdent();
    }

    if (null==oConn)
      throw new IllegalStateException ("Not connected to LDAP");

    try {
      oConn.bind(LDAPConnection.LDAP_V3, sUser, sPass.getBytes("UTF8"));
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      throw new com.knowgate.ldap.LDAPException(xcpt.getMessage(), xcpt);
    }
    catch (java.io.UnsupportedEncodingException xcpt) {
      // never thrown
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.bind()");
    }
  } // bind

  // ---------------------------------------------------------------------------

  /**
   * <p>Check whether or not an LDAP entry exists</p>
   * The directory is searched from the connection string key.<br>
   * For example if ldapconnect connection property is ldap://192.168.1.1:389/dc=hipergate,dc=org
   * then only entries under "dc=hipergate,dc=org" will be searched
   * @param sSearchString LDAP search string, for example "cn=user@mail.com,dc=publicContacts,dc=my_workarea,dc=my_domain"
   * @throws com.knowgate.ldap.LDAPException
   */
  public boolean exists (String sSearchString)
    throws com.knowgate.ldap.LDAPException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.exists(" + sSearchString + ")");
      DebugFile.incIdent();
    }

    LDAPSearchResults searchResults = null;

    try {
        searchResults = oConn.search(getPartitionName(), LDAPConnection.SCOPE_SUB, sSearchString, new String[] {"dn"}, true);
    }
    catch (com.novell.ldap.LDAPException e) {
        throw new com.knowgate.ldap.LDAPException(e.getMessage(), e);
    }

    boolean bExists = searchResults.hasMore();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.exists() : " + String.valueOf(bExists));
    }

    return bExists;
  } // exists

  // ---------------------------------------------------------------------------

  private void addHive(String sDN, String sCN)
    throws com.knowgate.ldap.LDAPException {
    LDAPAttributeSet attrs;

    if (DebugFile.trace) {
      DebugFile.writeln("LDAPNovell.addHive(" + sDN + "," + sCN + ")");
    }

    try {
      attrs = new LDAPAttributeSet();
      attrs.add(new LDAPAttribute("objectClass", new String[] {"dcObject",
                                  "organizationalUnit"}));
      attrs.add(new LDAPAttribute("dc", sCN));
      attrs.add(new LDAPAttribute("ou", sCN));
      oConn.add(new LDAPEntry(sDN, attrs));
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      throw new com.knowgate.ldap.LDAPException(xcpt.getMessage(), xcpt);
    }
  }

  // ---------------------------------------------------------------------------

  private void addLeaf(String sDN, LDAPAttributeSet attrs)
    throws com.knowgate.ldap.LDAPException {

    if (DebugFile.trace) {
      DebugFile.writeln("LDAPNovell.addLeaf(" + sDN + ", ...)");
    }

    try {
      attrs.add(new LDAPAttribute("objectClass", new String[] {"inetOrgPerson",
                                  "organizationalPerson"}));
      oConn.add(new LDAPEntry(sDN, attrs));
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      throw new com.knowgate.ldap.LDAPException(xcpt.getMessage() + " " + sDN, xcpt);
    }
  }

  // ---------------------------------------------------------------------------

  private LDAPAttributeSet mapJdbcToLdap (ResultSet oRSet, ResultSetMetaData oMDat)
    throws SQLException {

    Object oFld;
    String sFld;
    String sCol;
    LDAPAttributeSet oAttrs = new LDAPAttributeSet();

    int iCols = oMDat.getColumnCount();

    for (int c=1; c<=iCols; c++) {
      oFld = oRSet.getObject(c);

      if (!oRSet.wasNull()) {
        sFld = oFld.toString();
        sCol = oMDat.getColumnName(c).toLowerCase();
        if (!sCol.startsWith("control_")) {
          oAttrs.add(new LDAPAttribute(sCol, sFld));
        }
      }
    } // next

    return oAttrs;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Add an address from v_ldap_contacts view to an LDAP directory</p>
   * Addresses may be either public or private depending on the value of field
   * v_ldap_contacts.bo_private. If bo_private is zero then the address is public,
   * if bo_private is not zero then the address is private.<br>
   * Private addresses are only visible to the user that created them.<br>
   * Public addresses are stored at cn=<i>user@mail.com</i>,dc=publicContacts,dc=<i>workarea_name</i>,dc=<i>domain_name</i>,dc=hipergate,dc=org<br>
   * Private addresses are stored at cn=<i>user@mail.com</i>,dc=privateContacts,cn=<i>owner_guid</i>,dc=users,dc=<i>domain_name</i>,dc=hipergate,dc=org
   * @param oJdbc JDBC Connection
   * @param sAddrId GUID of address to be added
   * @throws com.knowgate.ldap.LDAPException If address already exists at directory
   * @throws SQLException If sAddrId is not found at v_ldap_contacts SQL view
   * @throws IllegalStateException If not connected to LDAP
   */
  public void addAddress (Connection oJdbc, String sAddrId)
      throws com.knowgate.ldap.LDAPException, java.sql.SQLException, java.lang.IllegalStateException {

    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    LDAPAttributeSet oAttrs = null;
    boolean bPrivate = true;
    String sDomainName = null, sWorkAreaName = null, sOwner = null, sTxEmail = null;

    if (null==oConn)
      throw new IllegalStateException ("LDAPNovell.addAddress() Not connected to LDAP");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.addAddress([Connection], " + sAddrId + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_contacts WHERE \"uid\"=" + sAddrId + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_contacts WHERE \"uid\"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sAddrId);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();
    boolean bFound = oRSet.next();

    if (bFound) {
      sDomainName = oRSet.getString("control_domain_name");
      sWorkAreaName = oRSet.getString("control_workarea_name");
      oAttrs = mapJdbcToLdap(oRSet, oMDat);
      bPrivate = (oRSet.getShort("control_priv") != (short) 0);
      sOwner = oRSet.getString("control_owner");
      sTxEmail = oRSet.getString("mail");
    }

    oRSet.close();
    oStmt.close();

    if (!bFound)
      throw new SQLException ("Address " + sAddrId + " could not be found at v_ldap_contacts view", "01S06");

    if (bPrivate) {
      // Contacto Privado
      addLeaf (makeName(PRIVATE_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sOwner,sWorkAreaName,sDomainName})+","+getPartitionName(), oAttrs);
    } else {
      // Contacto Público (workarea)
      addLeaf (makeName(PUBLIC_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sWorkAreaName,sDomainName})+","+getPartitionName(), oAttrs);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.addAddress()");
    }
  } // addAddress

  // ---------------------------------------------------------------------------

  /**
   * <p>Add or replace an Address</p>
   * This method is the same as addAddress() except that it does not raise an
   * LDAPException if address already exists; in that case address is just replaced.
   * @param oJdbc JDBC Connection
   * @param sAddrId GUID of address to be added or replaced
   * @throws com.knowgate.ldap.LDAPException
   * @throws java.sql.SQLException
   */
  public void addOrReplaceAddress (Connection oJdbc, String sAddrId)
    throws com.knowgate.ldap.LDAPException, java.sql.SQLException {

    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    LDAPAttributeSet oAttrs = null;
    boolean bPrivate = true;
    String sDomainName = null, sWorkAreaName = null, sOwner = null, sTxEmail = null;

    if (null==oConn)
      throw new IllegalStateException ("LDAPNovell.addOrReplaceAddress() Not connected to LDAP");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.addOrReplaceAddress([Connection], " + sAddrId + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_contacts WHERE \"uid\"=" + sAddrId + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_contacts WHERE \"uid\"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sAddrId);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();
    boolean bFound = oRSet.next();

    if (bFound) {
      sDomainName = oRSet.getString("control_domain_name");
      sWorkAreaName = oRSet.getString("control_workarea_name");
      oAttrs = mapJdbcToLdap(oRSet, oMDat);
      bPrivate = (oRSet.getShort("control_priv") != (short) 0);
      sOwner = oRSet.getString("control_owner");
      sTxEmail = oRSet.getString("mail");
    }

    oRSet.close();
    oStmt.close();

    if (!bFound)
      throw new SQLException ("Address " + sAddrId + " could not be found at v_ldap_contacts view", "01S06");

    if (bPrivate) {

      // Contacto Privado
      if (exists(makeName(PRIVATE_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sOwner,sWorkAreaName,sDomainName})+","+getPartitionName()))
        deleteAddress (oJdbc, sAddrId);

      addLeaf (makeName(PRIVATE_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sOwner,sWorkAreaName,sDomainName})+","+getPartitionName(), oAttrs);
    } else {

      // Contacto Público (workarea)
      if (exists(makeName(PUBLIC_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sWorkAreaName,sDomainName})+","+getPartitionName()))
        deleteAddress (oJdbc, sAddrId);

      addLeaf (makeName(PUBLIC_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sWorkAreaName,sDomainName})+","+getPartitionName(), oAttrs);
    } // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.addOrReplaceAddress()");
    }
  } // addOrReplaceAddress

  // ---------------------------------------------------------------------------

  /**
   * Delete an address from LDAP directory
   * @param oJdbc JDBC Connection
   * @param sAddrId GUID of address to be deleted
   * @throws com.knowgate.ldap.LDAPException
   * @throws SQLException If sAddrId is not found at v_ldap_contacts SQL view
   * @throws IllegalStateException If not connected to LDAP
   */
  public void deleteAddress (Connection oJdbc, String sAddrId)
      throws com.knowgate.ldap.LDAPException, java.sql.SQLException, java.lang.IllegalStateException {

    if (null==oConn)
      throw new IllegalStateException ("LDAPNovell.deleteAddress() Not connected to LDAP");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.deleteAddress([Connection], " + sAddrId + ")");
      DebugFile.incIdent();
    }

    LDAPAttributeSet oAttrs;
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bPrivate = true;
    String sDN = null, sDomainName = null, sWorkAreaName = null, sOwner = null, sTxEmail = null;

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_contacts WHERE \"uid\"=" + sAddrId + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_contacts WHERE \"uid\"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sAddrId);
    oRSet = oStmt.executeQuery();
    boolean bFound = oRSet.next();

    if (bFound) {
      sDomainName = oRSet.getString("control_domain_name");
      sWorkAreaName = oRSet.getString("control_workarea_name");
      bPrivate = (oRSet.getShort("control_priv") != (short) 0);
      sOwner = oRSet.getString("control_owner");
      sTxEmail = oRSet.getString("mail");
    }

    oRSet.close();
    oStmt.close();

    if (!bFound)
      throw new SQLException ("Address " + sAddrId + " could not be found at v_ldap_contacts view", "01S06");

    if (bPrivate)
      sDN = makeName(PRIVATE_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sOwner,sWorkAreaName,sDomainName})+","+getPartitionName();
    else
      sDN = makeName(PUBLIC_CONTACTS_LEAF_PATTERN,new String[]{sTxEmail,sWorkAreaName,sDomainName})+","+getPartitionName();

    if (DebugFile.trace) DebugFile.writeln("LDAPConnection.delete(" + sDN + ")");

    try {
      oConn.delete(sDN);
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new com.knowgate.ldap.LDAPException (xcpt.getMessage(), xcpt);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.deleteAddress()");
    }
  } // deleteAddress

  // ---------------------------------------------------------------------------


  /**
   * <p>Add a User from v_ldap_users view to an LDAP directory</p>
   * Users are added under cn=<i>user@mail.com</i>,dc=users,dc=<i>workarea_name</i>,dc=<i>domain_name</i>,dc=hipergate,dc=org
   * @param oJdbc JDBC Connection
   * @param sUserId GUID of user to be added
   * @throws LDAPException
   * @throws SQLException If sUserId is not found at v_ldap_users SQL view
   * @throws IllegalStateException If not connected to LDAP
   */
  public void addUser (Connection oJdbc, String sUserId)
    throws com.knowgate.ldap.LDAPException, java.sql.SQLException,IllegalStateException {

    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    LDAPAttributeSet oAttrs = null;
    String sDomainName = null, sWorkAreaName = null, sTxEmail = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.addUser([Connection], " + sUserId + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_users WHERE \"uid\"=" + sUserId + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_users WHERE \"uid\"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sUserId);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();
    boolean bFound = oRSet.next();

    if (bFound) {
      sDomainName = oRSet.getString("control_domain_name");
      sWorkAreaName = oRSet.getString("control_workarea_name");
      oAttrs = mapJdbcToLdap(oRSet, oMDat);
      sTxEmail = oRSet.getString("mail");
    } // fi (bFound)

    oRSet.close();
    oStmt.close();

    if (!bFound)
      throw new SQLException ("User " + sUserId + " could not be found at v_ldap_users view", "01S06");

    addLeaf ("cn="+sTxEmail+","+makeName(USERS_HIVE_PATTERN,new String[]{sWorkAreaName,sDomainName})+","+getPartitionName(), oAttrs);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.addUser()");
    }
  } // addUser

  // ---------------------------------------------------------------------------

  /**
   * Add or replace a User from v_ldap_users SQL view to the LDAP directory
   * @param oJdbc JDBC database connection
   * @param sUserId GUID of user to be added or replaced
   * @throws com.knowgate.ldap.LDAPException
   * @throws java.sql.SQLException
   */
  public  void addOrReplaceUser (Connection oJdbc, String sUserId)
      throws com.knowgate.ldap.LDAPException, java.sql.SQLException {


    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    LDAPAttributeSet oAttrs = null;
    String sDomainName = null, sWorkAreaName = null, sTxEmail = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.addOrReplaceUser([Connection], " + sUserId + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_users WHERE \"uid\"=" + sUserId + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_users WHERE \"uid\"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sUserId);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();
    boolean bFound = oRSet.next();

    if (bFound) {
      sDomainName = oRSet.getString("control_domain_name");
      sWorkAreaName = oRSet.getString("control_workarea_name");
      oAttrs = mapJdbcToLdap(oRSet, oMDat);
      sTxEmail = oRSet.getString("mail");
    } // fi

    oRSet.close();
    oStmt.close();

    if (!bFound)
      throw new SQLException ("User " + sUserId + " could not be found at v_ldap_users view", "01S06");

    if (exists(makeName("cn="+sTxEmail+","+USERS_HIVE_PATTERN,new String[]{sWorkAreaName,sDomainName})+","+getPartitionName()))
      deleteUser(oJdbc, sUserId);

    addLeaf (makeName("cn="+sTxEmail+","+USERS_HIVE_PATTERN,new String[]{sWorkAreaName,sDomainName})+","+getPartitionName(), oAttrs);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.addOrReplaceUser()");
    }
  } // addOrReplaceUser

  // ---------------------------------------------------------------------------

  /**
   * Delete a User from LDAP directory
   * @param oJdbc JDBC Connection
   * @param sUserId GUID of user to be added
   * @throws com.knowgate.ldap.LDAPException
   * @throws SQLException If sUserId is not found at v_ldap_users SQL view
   */
  public void deleteUser (Connection oJdbc, String sUserId)
    throws com.knowgate.ldap.LDAPException, java.sql.SQLException {

    LDAPAttributeSet oAttrs;
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sTxEmail = null, sDN = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.deleteUser([Connection], " + sUserId + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_users WHERE \"uid\"=" + sUserId + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_users WHERE \"uid\"=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sUserId);
    oRSet = oStmt.executeQuery();
    boolean bFound = oRSet.next();

    if (bFound) {
      sTxEmail = oRSet.getString("mail");
      sDN = makeName("cn="+sTxEmail+","+USERS_HIVE_PATTERN, new String[]{oRSet.getString("control_workarea_name"),oRSet.getString("control_domain_name")}) + "," + getPartitionName();
    } // bFound

    oRSet.close();
    oStmt.close();

    if (!bFound)
      throw new SQLException ("User " + sUserId + " could not be found at v_ldap_users view", "01S06");

    if (DebugFile.trace) DebugFile.writeln("LDAPConnection.delete(" + sDN + ")");

    try {
      oConn.delete(sDN);
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new com.knowgate.ldap.LDAPException (xcpt.getMessage(), xcpt);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.deleteUser()");
    }
  } // deleteUser

  // ---------------------------------------------------------------------------

  /**
   * <P>Load all users and contact address from a Domain into an LDAP directory</P>
   * @param oJdbc JDBC Connection
   * @param iDomainId Numeric Identifier for Domain
   * @throws com.knowgate.ldap.LDAPException
   * @throws SQLException
   */
  public void loadDomain (Connection oJdbc, int iDomainId)
    throws com.knowgate.ldap.LDAPException, java.sql.SQLException {

    LDAPAttributeSet oAttrs;
    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    String sDN, sDomainNm, sWorkAreaNm;
    LDAPSearchResults searchResults = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.loadDomain([Connection]" + String.valueOf(iDomainId) + ",...)");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT nm_domain FROM k_domains WHERE id_domain=" + String.valueOf(iDomainId) + ")");

    oStmt = oJdbc.prepareStatement("SELECT nm_domain FROM k_domains WHERE id_domain=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iDomainId);
    oRSet = oStmt.executeQuery();
    oRSet.next();
    sDomainNm = oRSet.getString(1);
    oRSet.close();
    oStmt.close();

    // *************
    // Create Domain

    sDN = "dc=" + sDomainNm + "," + getPartitionName();

    try {
      searchResults = oConn.search(getPartitionName(), LDAPConnection.SCOPE_ONE,"(dc=" + sDomainNm + ")", new String[] {"dn"}, true);
    }
    catch (com.novell.ldap.LDAPException e) {
      throw new com.knowgate.ldap.LDAPException(e.getMessage(), e);
    }

    if (!searchResults.hasMore())
      addHive(sDN, sDomainNm);

    // ****************
    // Create Workareas

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT nm_workarea FROM k_workareas WHERE id_domain=" + String.valueOf(iDomainId) + ")");

    oStmt = oJdbc.prepareStatement("SELECT nm_workarea FROM k_workareas WHERE id_domain=?",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iDomainId);
    oRSet = oStmt.executeQuery();

    while (oRSet.next()) {
      sWorkAreaNm = oRSet.getString(1);

      sDN = "dc=" + sWorkAreaNm + ",dc=" + sDomainNm + "," + getPartitionName();

      try {
        searchResults = oConn.search("dc=" + sDomainNm + "," + getPartitionName(), LDAPConnection.SCOPE_ONE,"(dc=" + sWorkAreaNm + ")", new String[] {"dn"}, true);
      }
      catch (com.novell.ldap.LDAPException e) {
        throw new com.knowgate.ldap.LDAPException(e.getMessage(), e);
      }

      if (!searchResults.hasMore()) {
        // Primero crear la rama de la WorkArea
        addHive (sDN, sWorkAreaNm);

        // Despues se crean los subcontenedores necesarios
        addHive ("dc=users," + sDN, "users");
        addHive ("dc=publicContacts," + sDN, "publicContacts");
        addHive ("dc=employees," + sDN, "employees");
      }
    } // wend

    oRSet.close();
    oStmt.close();

    // ***************
    // Create Users

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_users WHERE control_domain_guid=" + String.valueOf(iDomainId) + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_users WHERE control_domain_guid=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iDomainId);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();

    while (oRSet.next()) {
      sWorkAreaNm = oRSet.getString("control_workarea_name");
      sDN = "dc=" + sWorkAreaNm + ",dc=" + sDomainNm + "," + getPartitionName();

      oAttrs = mapJdbcToLdap(oRSet, oMDat);

      // Usuario
      addLeaf ("cn=" + oRSet.getString("mail") + ",dc=users," + sDN, oAttrs);
      // Añadir el contenedor de contactos privados
      addHive ("dc=privateContacts,cn=" + oRSet.getString("mail") + ",dc=users," + sDN, "privateContacts");
    } // wend

    oRSet.close();
    oStmt.close();

    // ***************
    // Create Contacts

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM v_ldap_contacts ld WHERE control_domain_guid=" + String.valueOf(iDomainId) + ")");

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_contacts ld WHERE control_domain_guid=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iDomainId);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();

    while (oRSet.next()) {
      sWorkAreaNm = oRSet.getString("control_workarea_name");
      sDN = "dc=" + sWorkAreaNm + ",dc=" + sDomainNm + "," + getPartitionName();

      oAttrs = mapJdbcToLdap(oRSet, oMDat);

        if (oRSet.getShort("control_priv")!=(short)0) {
          // Contacto Privado
          addLeaf("cn=" + oRSet.getString("mail") + "dc=privateContacts,cn=" + oRSet.getString("control_owner") + ",dc=users," + sDN, oAttrs);
        } else {
          // Contacto Público (workarea)
          addLeaf("cn=" + oRSet.getString("mail") + ",dc=publicContacts," + sDN, oAttrs);
        }
    } // wend

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.loadDomain()");
    }
  } // loadDomain

  // ---------------------------------------------------------------------------

  /**
   * <P>Load all users and contact address from a WorkArea into an LDAP directory</P>
   * @param oJdbc JDBC Connection
   * @param sDomainNm Name for Domain containing the WorkArea
   * @param sWorkAreaNm WorkArea Name
   * @throws com.knowgate.ldap.LDAPException
   * @throws SQLException
   */
  public void loadWorkArea (Connection oJdbc, String sDomainNm, String sWorkAreaNm)
    throws com.knowgate.ldap.LDAPException, java.sql.SQLException {

    LDAPAttributeSet oAttrs;
    String sDN;
    LDAPSearchResults searchResults = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.loadWorkArea([Connection]" + sDomainNm + "," + sWorkAreaNm + ",...)");
      DebugFile.incIdent();
    }

    // **********************************
    // Create Domain if it does not exist

    sDN = "dc=" + sDomainNm + "," + getPartitionName();

    try {
      searchResults = oConn.search(getPartitionName(), LDAPConnection.SCOPE_ONE,"(dc=" + sDomainNm + ")", new String[] {"dn"}, true);
    }
    catch (com.novell.ldap.LDAPException e) {
      throw new com.knowgate.ldap.LDAPException(e.getMessage(), e);
    }

    if (!searchResults.hasMore())
      addHive(sDN, sDomainNm);

    // ***************
    // Create WorkArea

    sDN = "dc=" + sWorkAreaNm + ",dc=" + sDomainNm + "," + getPartitionName();

    try {
        searchResults = oConn.search("dc=" + sDomainNm + "," + getPartitionName(), LDAPConnection.SCOPE_ONE,"(dc=" + sWorkAreaNm + ")", new String[] {"dn"}, true);
    }
    catch (com.novell.ldap.LDAPException e) {
        throw new com.knowgate.ldap.LDAPException(e.getMessage(), e);
    }

    if (!searchResults.hasMore()) {
      // Primero crear la rama de la WorkArea
      addHive (sDN, sWorkAreaNm);

      // Despues se crean los subcontenedores necesarios
      addHive ("dc=users," + sDN, "users");
      addHive ("dc=publicContacts," + sDN, "publicContacts");
      addHive ("dc=employees," + sDN, "employees");
    } // fi


    // ***************
    // Create Users

    PreparedStatement oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_users WHERE control_domain_name=? AND control_workarea_name=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sDomainNm);
    oStmt.setString(2, sWorkAreaNm);
    ResultSet oRSet = oStmt.executeQuery();
    ResultSetMetaData oMDat = oRSet.getMetaData();

    while (oRSet.next()) {
      sWorkAreaNm = oRSet.getString("control_workarea_name");
      sDN = "cn=" + oRSet.getString("mail") + makeName(USERS_HIVE_PATTERN,new String[]{sWorkAreaNm,sDomainNm}) + "," + getPartitionName();

      oAttrs = mapJdbcToLdap(oRSet, oMDat);

      // Usuario      
      addLeaf (sDN, oAttrs);
      // Añadir el contenedor de contactos privados
      addHive ("dc=privateContacts," + sDN, "privateContacts");
    } // wend

    oRSet.close();
    oStmt.close();

    // ***************
    // Create Contacts

    oStmt = oJdbc.prepareStatement("SELECT * FROM v_ldap_contacts ld WHERE control_domain_name=? AND control_workarea_name=?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sDomainNm);
    oStmt.setString(2, sWorkAreaNm);
    oRSet = oStmt.executeQuery();
    oMDat = oRSet.getMetaData();

    while (oRSet.next()) {
      sWorkAreaNm = oRSet.getString("control_workarea_name");
      sDN = "dc=" + sWorkAreaNm + ",dc=" + sDomainNm + "," + getPartitionName();

      oAttrs = mapJdbcToLdap(oRSet, oMDat);

        if (oRSet.getShort("control_priv")!=(short)0) {
          // Contacto Privado          
          addLeaf(makeName(PRIVATE_CONTACTS_LEAF_PATTERN,new String[]{oRSet.getString("mail"),oRSet.getString("control_owner"),sWorkAreaNm,sDomainNm}) + "," + getPartitionName(), oAttrs);
        } else {
          // Contacto Público (workarea)
          addLeaf(makeName(PUBLIC_CONTACTS_LEAF_PATTERN,new String[]{oRSet.getString("mail"),sWorkAreaNm,sDomainNm}) + "," + getPartitionName(), oAttrs);
        }
    } // wend

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.loadWorkArea()");
    }
  } // loadWorkArea

  // ---------------------------------------------------------------------------

  /**
   * Delete LDAP entry and all its childs
   * @param oEntry LDAPEntry to be deleted
   * @throws com.knowgate.ldap.LDAPException
   * @throws IllegalStateException If not connected to LDAP
   */
  private void deleteEntry (LDAPEntry oEntry)
    throws com.knowgate.ldap.LDAPException, IllegalStateException {

    if (null==oConn)
      throw new IllegalStateException ("LDAPNovell.deleteEntry() Not connected to LDAP");

    String sDN = oEntry.getDN();
    LDAPEntry nextEntry;

    try {
      LDAPSearchResults searchResults = oConn.search(sDN, LDAPConnection.SCOPE_ONE,"(objectClass=*)",new String[] {"dn"}, true);

      while (searchResults.hasMore()) {
        try {
          nextEntry = searchResults.next();
        }
        catch (com.novell.ldap.LDAPException e) { continue; }

        deleteEntry (nextEntry);
      } // wend

      if (DebugFile.trace) DebugFile.writeln("LDAPConnection.delete(" + sDN + ")");

      oConn.delete(sDN);
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      throw new com.knowgate.ldap.LDAPException (xcpt.getMessage(), xcpt);
    }
  } // deleteEntry

  // ---------------------------------------------------------------------------

  /**
   * <p>Delete a WorkArea from the LDAP directory</p>
   * All entries under dc=<i>sDomainNm</i>,dc=hipergate,dc=org that match dc=<i>sWorkAreaNm</i> are deleted
   * @param sDomainNm Domain Name
   * @param sWorkAreaNm WorkArea Name
   * @throws com.knowgate.ldap.LDAPException
   * @throws IllegalStateException If not connected to LDAP
   */
  public void deleteWorkArea (String sDomainNm, String sWorkAreaNm)
    throws com.knowgate.ldap.LDAPException, IllegalStateException {

    String sDN = "dc=" + sDomainNm + "," + getPartitionName();
    LDAPEntry oWrkAHive = null;

    try {
      LDAPSearchResults searchResults = oConn.search(sDN, LDAPConnection.SCOPE_ONE,"(dc=" + sWorkAreaNm + ")", new String[] {"dn"}, true);

      if (searchResults.hasMore()) {
        oWrkAHive = searchResults.next();
      }
    }
    catch (com.novell.ldap.LDAPException e) {
      throw new com.knowgate.ldap.LDAPException(e.getMessage(), e);
    }

    if (oWrkAHive!=null)
      deleteEntry (oWrkAHive);
  } // deleteWorkArea

  // ---------------------------------------------------------------------------

  /**
   * Drop an entire LDAP directory
   * @throws com.knowgate.ldap.LDAPException
   * @throws IllegalStateException If not connected to LDAP
   */
  public void dropAll ()
    throws com.knowgate.ldap.LDAPException, IllegalStateException {

    if (null==oConn)
      throw new IllegalStateException ("LDAPNovell.dropAll() Not connected to LDAP");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin LDAPNovell.dropAll()");
      DebugFile.incIdent();
    }

    LDAPSearchResults searchResults = null;
    LDAPEntry nextEntry = null;

    try {
        // Dropar todo el modelo de datos

        searchResults = oConn.search(getPartitionName(), LDAPConnection.SCOPE_ONE,"(objectClass=*)",new String[] {"dn"}, true);

        while (searchResults.hasMore()) {
          try {
            nextEntry = searchResults.next();
          }
          catch (LDAPException e) { continue; }

          if (!getPartitionName().equals(nextEntry.getDN()))
            deleteEntry(nextEntry); // No borrar el elemento raíz!!!
        } // wend
    }
    catch (com.novell.ldap.LDAPException xcpt) {
      throw new com.knowgate.ldap.LDAPException (xcpt.getMessage(), xcpt);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End LDAPNovell.dropAll()");
    }
  } // dropAll

  // ---------------------------------------------------------------------------

  private static void printUsage() {
    System.out.println("");
    System.out.println("Usage:");
    System.out.println("LDAPNovell path load all");
    System.out.println("path: path to hipergate.cnf file ej. /opt/knowgate/hipergate.cnf");
  }

  public static void main(String[] argv)
     throws java.lang.ClassNotFoundException, java.io.IOException, java.sql.SQLException, com.knowgate.ldap.LDAPException {

     if (argv.length<3 || argv.length>3)
       printUsage();
     else {
       java.util.Properties oProps = new java.util.Properties();
       java.io.FileInputStream ioProps = new java.io.FileInputStream(argv[0]);
       oProps.load(ioProps);
       ioProps.close();

       LDAPNovell oLDP = new LDAPNovell();

       oLDP.connectAndBind(oProps);

       Class oDriver = Class.forName(oProps.getProperty("driver"));

       Connection oCon = java.sql.DriverManager.getConnection(oProps.getProperty("dburl"), oProps.getProperty("dbuser"), oProps.getProperty("dbpassword"));

       oLDP.dropAll();

       Statement oStm = oCon.createStatement();
       ResultSet oRst = oStm.executeQuery("SELECT id_domain FROM k_domains WHERE bo_active<>0");

       while (oRst.next()) {
         oLDP.loadDomain(oCon, oRst.getInt(1));
       }

       oRst.close();
       oStm.close();

       oCon.close();
       oLDP.disconnect();
     }
   }
}
