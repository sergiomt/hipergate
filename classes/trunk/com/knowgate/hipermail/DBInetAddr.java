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

package com.knowgate.hipermail;

import java.io.UnsupportedEncodingException;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import javax.mail.internet.AddressException;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

import javax.mail.internet.InternetAddress;

/**
 * <p>Internet Address register from k_inet_addrs</p>
 * @author Sergio Montoro Ten
 * @version 2.1
 */

public class DBInetAddr extends InternetAddress {

  private static final long serialVersionUID = 2l;

  private DBPersist oAddr;

  public DBInetAddr(String sMsgGUID, int iPart) {

    oAddr = new DBPersist(DB.k_inet_addrs, "InetAddrDB");

    oAddr.put(DB.gu_mimemsg, sMsgGUID);
    oAddr.put(DB.id_part, iPart);
  }

  /**
   * Constructor
   * @param sMsgGUID Message GUID
   * @param sMsgId Mime Message Identifier
   * @param sTxEMail Mail address
   * @param sTxPersonal Address displyed name
   * @param sTpRecipient Recipient type { from, to, cc, bcc } case sensitive
   * @param sGuUser GUID of User which tx_main_email is the same as this address
   * @param sGuContact GUID of Contact which tx_main_email is the same as this address
   * @param sGuCompany GUID of Copany which tx_main_email is the same as this address
   * @throws NullPointerException If sMsgGUID or sMsgId or sTxEMail or sTpRecipient is <b>null</b>.
   * @throws IllegalArgumentException If sTpRecipient is not one of { from, to, cc, bcc }
   */
  public DBInetAddr(String sMsgGUID, String sMsgId, String sTxEMail,
                    String sTxPersonal, String sTpRecipient,
                    String sGuUser, String sGuContact, String sGuCompany)
    throws NullPointerException, IllegalArgumentException {

    if (null==sMsgGUID) throw new NullPointerException("DBInetAddr message GUID cannot be null");
    if (null==sMsgId) throw new NullPointerException("DBInetAddr message identifier cannot be null");
    if (null==sTxEMail) throw new NullPointerException("DBInetAddr mail address cannot be null");
    if (null==sTpRecipient) throw new NullPointerException("DBInetAddr recipient type cannot be null");

    if (!sTpRecipient.equals("from") && !sTpRecipient.equals("to") && !!sTpRecipient.equals("cc") && !!sTpRecipient.equals("bcc"))
      throw new java.lang.IllegalArgumentException("Recipient type must be either from, to, cc or bcc");

    oAddr = new DBPersist(DB.k_inet_addrs, "InetAddrDB");

    oAddr.put(DB.gu_mimemsg, sMsgGUID);
    oAddr.put(DB.id_message, sMsgId);
    oAddr.put(DB.tx_email, sTxEMail);
    oAddr.put(DB.tp_recipient, sTpRecipient);

    if (null!=sTxPersonal) oAddr.put(DB.tx_personal, sTxPersonal);
    if (null!=sGuUser)     oAddr.put(DB.gu_user, sGuUser);
    if (null!=sGuContact)  oAddr.put(DB.gu_contact, sGuContact);
    if (null!=sGuCompany)  oAddr.put(DB.gu_company, sGuCompany);
  }

  // ---------------------------------------------------------------------------

  /**
   * Get e-mail address
   * @return String
   */
  public String getAddress () { return oAddr.getStringNull (DB.tx_email, null); }

  // ---------------------------------------------------------------------------

  public String getString (String sKey) { return oAddr.getString (sKey); }

  // ---------------------------------------------------------------------------

  public String getStringNull (String sKey, String sDefault) { return oAddr.getStringNull (sKey, sDefault); }

  // ---------------------------------------------------------------------------

  /**
   * Two addresses are equal if they hold the same e-mail
   * @param oOtherAddr DBInetAddr
   * @return boolean <b>true</b> if e-mail of this is equal to e-mail of oOtherAddr (case insensitive comparison)
   * @throws ClassCastException if oOtherAddr is not of type DBInetAddr
   */
  public boolean equals (Object oOtherAddr)
    throws ClassCastException {
    DBInetAddr oAddr2 = (DBInetAddr) oOtherAddr;

    if (getAddress()==null || oAddr2.getAddress()==null)
      return false;
    else
      return getAddress().equalsIgnoreCase(oAddr2.getAddress());
  }

  // ---------------------------------------------------------------------------

  /**
   *
   * @return String "rfc822"
   */
  public String getType () { return "rfc822"; }

  // ---------------------------------------------------------------------------

  /**
   * Get display (personal) name
   * @return String
   */
  public String getPersonal () { return oAddr.getStringNull (DB.tx_personal, null); }


  // ---------------------------------------------------------------------------

  /**
   * This method is unsupported and will always throw an exception when called
   * @throws UnsupportedOperationException
   */
  @SuppressWarnings("unused")
  public boolean store (JDCConnection oConn) throws UnsupportedOperationException {
    if (true) throw new UnsupportedOperationException("Method InetAddrDB.store() is not supported");
    return false;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Write address resolving e-mails to contact and company GUIDs</p>
   * This method writes to k_inet_addr table but it first lookup the given e-mail
   * at table k_member_address and fills gu_contact and gu_company fields of
   * k_inet_addr if there is a contact or company at the specified workarea that
   * has that e-mail
   * @param oConn JDCConnection
   * @param iDomainId int Domain Identifier
   * @param sWorkAreaId String WorkArea GUID (search for matches will be restricted to this WorkArea)
   * @param sGuMimeMsg String Message GUID
   * @param sIdMimeMsg String Message Identifier
   * @param sTxEMail String e-mail
   * @param sTpRecipient String One of {to, cc, bcc}
   * @param sTxPersonal String Display Name
   * @return boolean <b>true</b>
   * @throws SQLException
   */
  public static boolean write (JDCConnection oConn, int iDomainId, String sWorkAreaId,
                               String sGuMimeMsg, String sIdMimeMsg, String sTxEMail,
                               String sTpRecipient, String sTxPersonal)
    throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBInetAddr.write([Connection], " + String.valueOf(iDomainId) + "," + sWorkAreaId + "," +
                        sGuMimeMsg +  "," + sIdMimeMsg + "," + sTxEMail + "," + sTpRecipient + "," + sTxPersonal + ")");
      DebugFile.incIdent();
    }
    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) DebugFile.writeln("SELECT k_sp_write_inet_addr ("+String.valueOf(iDomainId)+",'"+sWorkAreaId+"',"+(sGuMimeMsg==null ? "null" : "'"+sGuMimeMsg+"'")+",'"+sIdMimeMsg+"','"+sTxEMail+"','"+sTpRecipient+"','"+(sTxPersonal==null ? "null" : "'"+sTxPersonal+"'")+"')");
      PreparedStatement oStmt = oConn.prepareStatement("SELECT k_sp_write_inet_addr (?,?,?,?,?,?,?)");
      oStmt.setInt   (1, iDomainId);
      oStmt.setString(2, sWorkAreaId);
      oStmt.setString(3, sGuMimeMsg);
      oStmt.setString(4, sIdMimeMsg);
      oStmt.setString(5, sTxEMail);
      oStmt.setString(6, sTpRecipient);
      if (sTxPersonal!=null)
        oStmt.setString(7, sTxPersonal);
      else
        oStmt.setNull(7, Types.VARCHAR);
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");
      
      ResultSet oRSet = oStmt.executeQuery();
      oRSet.next();
      if (DebugFile.trace) DebugFile.writeln("found "+String.valueOf(oRSet.getInt(1))+" rows");
	  oRSet.close();      
      oStmt.close();
    }
    else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
      if (DebugFile.trace) DebugFile.writeln("{call K_SP_WRITE_INET_ADDR (?,?,?,?,?,?,?)}");
      CallableStatement oCall = oConn.prepareCall("{call K_SP_WRITE_INET_ADDR (?,?,?,?,?,?,?)}");
      oCall.setBigDecimal(1 , new java.math.BigDecimal(iDomainId));
      oCall.setString(2, sWorkAreaId);
      oCall.setString(3, sGuMimeMsg);
      oCall.setString(4, sIdMimeMsg);
      if (sTpRecipient!=null)
        oCall.setString(5, sTpRecipient);
      else
        oCall.setNull(5, Types.VARCHAR);
      oCall.setString(6, sTxEMail);
      if (sTxPersonal!=null)
        oCall.setString(7, sTxPersonal);
      else
        oCall.setNull(7, Types.VARCHAR);
      if (DebugFile.trace) DebugFile.writeln("CallableStatement.execute()");
      oCall.execute();
      oCall.close();
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("{call k_sp_write_inet_addr (?,?,?,?,?,?,?)}");
      CallableStatement oCall = oConn.prepareCall("{call k_sp_write_inet_addr (?,?,?,?,?,?,?)}");
      oCall.setInt   (1, iDomainId);
      oCall.setString(2, sWorkAreaId);
      oCall.setString(3, sGuMimeMsg);
      oCall.setString(4, sIdMimeMsg);
      oCall.setString(5, sTpRecipient);
      oCall.setString(6, sTxEMail);
      if (sTxPersonal!=null)
        oCall.setString(7, sTxPersonal);
      else
        oCall.setNull(7, Types.VARCHAR);
      if (DebugFile.trace) DebugFile.writeln("CallableStatement.execute()");
      oCall.execute();
      oCall.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBInetAddr.write()");
    }
    return true;
  } // write

  // ---------------------------------------------------------------------------

  /**
   * <p>Forward call to static method DBInetAddr.write()</p>
   * @param oConn JDCConnection
   * @param iDomainId int Domain Identifier
   * @param sWorkAreaId String WorkArea GUID (search for matches will be restricted to this WorkArea)
   * @return boolean <b>true</b>
   * @throws SQLException
   */
  public boolean write (JDCConnection oConn, int iDomainId, String sWorkAreaId) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBInetAddrDB.write([Connection], " + String.valueOf(iDomainId) + "," + sWorkAreaId + ")");
      DebugFile.incIdent();
    }
    boolean bRetVal =
    DBInetAddr.write(oConn,iDomainId,sWorkAreaId,oAddr.getString(DB.gu_mimemsg),
                     oAddr.getStringNull(DB.id_message,null),
                     oAddr.getString(DB.tx_email),oAddr.getString(DB.tp_recipient),
                     oAddr.getStringNull(DB.tx_personal,null));
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End InetAddrDB.write()");
    }
    return bRetVal;
  } // write

  // ---------------------------------------------------------------------------

  /**
   * Parse address of the form (Name) <user@domain.com>, <user@domain.com> (Name),
   * "Name" <user@domain.com>, <user@domain.com> "Name", Name <user@domain.com>,
   * <user@domain.com> , user@domain.com
   * @param sNamePlusEMail String Display name and e-mail address
   * @return InternetAddress
   * @throws AddressException
   * @throws NullPointerException
   * @throws UnsupportedEncodingException
   */
  public static InternetAddress parseAddress(String sNamePlusEMail)
    throws AddressException,NullPointerException,UnsupportedEncodingException {
    InternetAddress oRetAdr = null;

    String sAddr = sNamePlusEMail.trim();

    int iLeftAng = sAddr.indexOf('<');
    int iRightAng= sAddr.indexOf('>');
    int iLeftPar = sAddr.indexOf('(');
    int iRightPar= sAddr.indexOf(')');
    int iLeftQuo = sAddr.indexOf('"');
    int iRightQuo;
    if (iLeftQuo>=0) iRightQuo = sAddr.indexOf('"',iLeftQuo+1); else iRightQuo = -1;

    if (iRightAng<iLeftAng) throw new AddressException("Misplaced right angle");
    if (iLeftAng<0 && iRightAng>=0) throw new AddressException("Missing left angle");
    if (iLeftAng>=0 && iRightAng<0) throw new AddressException("Missing right angle");
    if (iLeftPar<0 && iRightPar>=0) throw new AddressException("Missing left parenthesis");
    if (iLeftPar>=0 && iRightPar<0) throw new AddressException("Missing right parenthesis");
    if (iRightPar<iLeftPar) throw new AddressException("Misplaced right parenthesis");
    if (iLeftQuo>=0 && iRightQuo<0) throw new AddressException("Unclosed quote");

    if (iLeftAng>=0 && iRightAng>=0 && iLeftPar>=0 && iRightPar>=0) {
      // Address is (Name) <user@domain.com> or <user@domain.com> (Name)
      oRetAdr = new InternetAddress(sAddr.substring(iLeftAng+1,iRightAng),sAddr.substring(iLeftPar+1,iRightPar));
    } else if (iLeftAng>=0 && iRightAng>=0 && iLeftQuo>=0 && iRightQuo>=0) {
      // Address is "Name" <user@domain.com> or "Name" <user@domain.com>
      oRetAdr = new InternetAddress(sAddr.substring(iLeftAng+1,iRightAng),sAddr.substring(iLeftQuo+1,iRightQuo));
    } else if (iLeftAng>=0 && iRightAng>=0) {
      // Address is Name <user@domain.com> or <user@domain.com> Name
      if (0==iLeftAng)
        oRetAdr = new InternetAddress(sAddr.substring(1,iRightAng),sAddr.substring(iRightAng+1));
      else
        oRetAdr = new InternetAddress(sAddr.substring(iLeftAng+1,iRightAng),sAddr.substring(0,iLeftAng));
    } else {
      oRetAdr = new InternetAddress(sAddr);
    }
    return oRetAdr;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get Display name concatenated with e-mail into angles
   * @return String "Personal Name <user@domain.com>"
   */
  public String toString() {
    return getPersonal()+" <"+getAddress()+">";
  }
}
