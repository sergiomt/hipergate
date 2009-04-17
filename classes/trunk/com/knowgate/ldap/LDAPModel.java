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
import java.sql.Connection;
import java.sql.SQLException;

import com.knowgate.misc.Gadgets;
/**
 * LDAP Abstract Base Class
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public abstract class LDAPModel {

  public LDAPModel() {
    sPartitionName = null;	
  }

  /**
   * <p>Connect to LDAP Service</p>
   * At this point, there is no authentication, and any operations are conducted as an anonymous client.
   * @param sConnStr ldap://<i>host</i>:port/<i>distinguished_name</i><br><b>Example</b> "ldap://fobos.kg.int:389/dc=hipergate,dc=org"
   * @throws LDAPException
   */

  public abstract void connect (String sConnStr) throws LDAPException;

  /**
   * <P>Connect to LDAP Server using a Properties object</P>
   * @param oProps Properties for connecting to LDAP server.<BR>
   * For example :<BR>
   * ldapconnect=ldap://fobos.kg.int:389/dc=hipergate,dc=org<BR>
   * ldapuser=cn=Manager,dc=hipergate,dc=org<BR>
   * ldappassword=manager<BR>
   * @throws LDAPException
   */

  public abstract void connectAndBind (Properties oProps) throws LDAPException;

  /**
   * <p>Synchronously authenticates to the LDAP server using LDAP_V3.</p>
   * If the object has been disconnected from an LDAP server, this method attempts to reconnect to the server. If the object has already authenticated, the old authentication is discarded.
   * @param sUser If non-null and non-empty, specifies that the connection and all operations through it should be authenticated with dn as the distinguished name.
   * @param sPass If non-null and non-empty, specifies that the connection and all operations through it should be authenticated with dn as the distinguished name and passwd as password.
   * @throws LDAPException
   * @throws IllegalStateException If not conencted to LDAP
   */

  public abstract void bind (String sUser, String sPass) throws LDAPException;

  /**
   * <p>Synchronously disconnects from the LDAP server</p>
   * The disconnect method abandons any outstanding requests, issues an unbind request to the server, and then closes the socket.
   * @throws LDAPException
   */

  public abstract void disconnect() throws LDAPException;

  /**
   * <p>Check whether or not an LDAP entry exists</p>
   * The directory is searched from the connection string key.<br>
   * For example if ldapconnect connection property is ldap://192.168.1.1:389/dc=hipergate,dc=org
   * then only entries under "dc=hipergate,dc=org" will be searched
   * @param sSearchString LDAP search string, for example "cn=user@mail.com,dc=publicContacts,dc=my_workarea,dc=my_domain"
   * @throws LDAPException
   */

  public abstract boolean exists (String sSearchString) throws LDAPException;

  /**
   * Drop an entire LDAP directory
   * @throws LDAPException
   * @throws IllegalStateException If not connected to LDAP
   */

  public abstract void dropAll () throws LDAPException;

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

  public abstract void addAddress (Connection oJdbc, String sAddrId) throws LDAPException, SQLException;

  /**
   * <p>Add or replace an Address</p>
   * This method is the same as addAddress() except that it does not raise an
   * LDAPException if address already exists; in that case address is just replaced.
   * @param oJdbc JDBC Connection
   * @param sAddrId GUID of address to be added or replaced
   * @throws LDAPException
   * @throws SQLException
   */

  public abstract void addOrReplaceAddress (Connection oJdbc, String sAddrId) throws LDAPException, SQLException;

  /**
   * Delete an address from LDAP directory
   * @param oJdbc JDBC Connection
   * @param sAddrId GUID of address to be deleted
   * @throws LDAPException
   * @throws SQLException If sAddrId is not found at v_ldap_contacts SQL view
   * @throws IllegalStateException If not connected to LDAP
   */

  public abstract void deleteAddress (Connection oJdbc, String sAddrId) throws LDAPException, SQLException;

  /**
   * <p>Add a User from v_ldap_users view to an LDAP directory</p>
   * Users are added under cn=<i>user@mail.com</i>,dc=users,dc=<i>workarea_name</i>,dc=<i>domain_name</i>,dc=hipergate,dc=org
   * @param oJdbc JDBC Connection
   * @param sUserId GUID of user to be added
   * @throws LDAPException
   * @throws SQLException If sUserId is not found at v_ldap_users SQL view
   * @throws IllegalStateException If not connected to LDAP
   */

  /**
   * <p>Add a User from v_ldap_users view to an LDAP directory</p>
   * Users are added under cn=<i>user@mail.com</i>,dc=users,dc=<i>workarea_name</i>,dc=<i>domain_name</i>,dc=hipergate,dc=org
   * @param oJdbc JDBC Connection
   * @param sUserId GUID of user to be added
   * @throws LDAPException
   * @throws SQLException If sUserId is not found at v_ldap_users SQL view
   * @throws IllegalStateException If not connected to LDAP
   */

  public abstract void addUser (Connection oJdbc, String sUserId) throws LDAPException, SQLException;


  /**
   * Add or replace a User from v_ldap_users SQL view to the LDAP directory
   * @param oJdbc JDBC database connection
   * @param sUserId GUID of user to be added or replaced
   * @throws com.knowgate.ldap.LDAPException
   * @throws java.sql.SQLException
   */

  public abstract void addOrReplaceUser (Connection oJdbc, String sUserId) throws LDAPException, SQLException;

  /**
    * Delete a User from LDAP directory
    * @param oJdbc JDBC Connection
    * @param sUserId GUID of user to be added
    * @throws LDAPException
    * @throws SQLException If sUserId is not found at v_ldap_users SQL view
    */

  public abstract void deleteUser (Connection oJdbc, String sUserId) throws LDAPException, SQLException;

  /**
   * <P>Load all users and contact address from a Domain into an LDAP directory</P>
   * @param oJdbc JDBC Connection
   * @param iDomainId Numeric Identifier for Domain
   * @throws LDAPException
   * @throws SQLException
   */

  public abstract void loadDomain (Connection oJdbc, int iDomainId) throws LDAPException, SQLException;

  /**
   * <P>Load all users and contact address from a WorkArea into an LDAP directory</P>
   * @param oJdbc JDBC Connection
   * @param sDomainNm Name for Domain containing the WorkArea
   * @param sWorkAreaNm WorkArea Name
   * @throws LDAPException
   * @throws SQLException
   */

  public abstract void loadWorkArea (Connection oJdbc, String sDomainNm, String sWorkAreaNm) throws LDAPException, SQLException;

  /**
   * <p>Delete a WorkArea from the LDAP directory</p>
   * All entries under dc=<i>sDomainNm</i>,dc=hipergate,dc=org that match dc=<i>sWorkAreaNm</i> are deleted
   * @param sDomainNm Domain Name
   * @param sWorkAreaNm WorkArea Name
   * @throws LDAPException
   * @throws IllegalStateException If not connected to LDAP
   */

  public abstract void deleteWorkArea (String sDomainNm, String sWorkAreaNm) throws LDAPException, IllegalStateException;

  // ---------------------------------------------------------------------------

  public String getPartitionName() { return sPartitionName; }

  // ---------------------------------------------------------------------------

  public void setPartitionName(String sName) { sPartitionName = sName; }

  // ---------------------------------------------------------------------------

  /**
   * Replace parameters market as $1, $2, ... $n with given values
   * For example: "cn=$1,dc=$2,dc=com" {"partition","domain"} will
   * be returned as "cn=partition,dc=domain,dc=com"
   * @param sPattern Base pattern with dollar parameters
   * @param Values to be replaced at sPattern
   * @throws LDAPException
   */
  protected String makeName(String sPattern, String[] aParams)
  	throws LDAPException {
    StringBuffer oDistinguishedName = new StringBuffer();
    int iDollar = -1;
    int iFrom = 0;
    if (null==aParams) {
      oDistinguishedName.append(sPattern);
    } else {
      for (int p=0; p<aParams.length; p++) {
      	String sParam = "$"+String.valueOf(p+1);
		iDollar = sPattern.indexOf(sParam,iFrom);
		if (iDollar<0) {
		  throw new LDAPException("LDAPModel.makeName("+sPattern+") insufficient number of parameters", new IllegalArgumentException(Gadgets.join(aParams,",")));
		} else {
		  oDistinguishedName.append(sPattern.substring(iFrom, iDollar));
		  oDistinguishedName.append(aParams[p]);
		  iFrom = iDollar+sParam.length();
		} // fi
      } // next
      if (iFrom<sPattern.length()-1) oDistinguishedName.append(sPattern.substring(iFrom));
    } // fi
    return oDistinguishedName.toString();
  } // makeName

  // ---------------------------------------------------------------------------

  private String sPartitionName;

  protected String organizationalUnitPattern;

  public static final int PWD_CLEAR_TEXT = 0;
  public static final int PWD_DTIP_RC4 = 1;

  public static final short USER_NOT_FOUND = -1;
  public static final short INVALID_PASSWORD = -2;
  public static final short ACCOUNT_DEACTIVATED = -3;
  public static final short SESSION_EXPIRED = -4;
  public static final short DOMAIN_NOT_FOUND = -5;
  public static final short WORKAREA_NOT_FOUND = -6;
  public static final short WORKAREA_NOT_SET = -7;
  public static final short ACCOUNT_CANCELLED = -8;
  public static final short PASSWORD_EXPIRED = -9;
  public static final short INTERNAL_ERROR = -255;
}