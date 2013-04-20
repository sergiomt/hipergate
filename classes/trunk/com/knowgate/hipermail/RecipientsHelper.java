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

import java.io.IOException;
import java.io.UnsupportedEncodingException;

import java.util.Date;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.sql.Types;

import javax.mail.Address;
import javax.mail.Message;
import javax.mail.internet.InternetHeaders;
import javax.mail.MessagingException;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import com.sun.mail.dsn.MultipartReport;
import com.sun.mail.dsn.DispositionNotification;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.crm.DistributionList;
import com.knowgate.misc.Gadgets;

/**
 * Helper class for working with recipients lists
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public class RecipientsHelper {

  private InternetAddress[] aToAddrs;
  private InternetAddress[] aCcAddrs;
  private InternetAddress[] aBccAddrs;
  private boolean bHasLists;
  private String sWorkAreaId;
  // ---------------------------------------------------------------------------

  /**
   * Default Constructor
   */
  public RecipientsHelper() {
    bHasLists = false;
    aToAddrs = null;
    aCcAddrs = null;
    aBccAddrs = null;
    sWorkAreaId = null;
  }

  // ---------------------------------------------------------------------------

  /**
   * Construct and set default workarea for this recipients helper
   */
  public RecipientsHelper(String sWorkAreaGUID) {
    bHasLists = false;
    aToAddrs = null;
    aCcAddrs = null;
    aBccAddrs = null;
    sWorkAreaId = sWorkAreaGUID;
  }

  // ---------------------------------------------------------------------------

  /**
   * Create RecipientsHelper and fill it with MimeMessage recipients
   * @param oMsg MimeMessage
   * @throws MessagingException
   */
  public RecipientsHelper(MimeMessage oMsg)
    throws MessagingException {
    bHasLists = false;
    setRecipients(oMsg);
  }

  // ---------------------------------------------------------------------------

  /**
   * If called after parseRecipientsList(), this methods returns whether or not
   * any distribution list was expanded during the parsing process
   * @return boolean
   */
  public boolean hasLists() {
    return bHasLists;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get array with recipients of a given type
   * @param oRecTp RecipientType
   * @return InternetAddress[]
   */
  public String[] getAddresses(Message.RecipientType oRecTp) {
    String[] aEmails = null;
    if (oRecTp.equals(Message.RecipientType.TO)) {
      if (aToAddrs==null) {
        aEmails = null;
      } else {
        aEmails = new String[aToAddrs.length];
        for (int a=aToAddrs.length-1; a>=0; a--)
          aEmails[a] = aToAddrs[a].getAddress();
      }
    }
    else if (oRecTp.equals(Message.RecipientType.CC)) {
      if (aCcAddrs==null) {
        aEmails = null;
      } else {
        aEmails = new String[aCcAddrs.length];
        for (int a=aCcAddrs.length-1; a>=0; a--)
          aEmails[a] = aCcAddrs[a].getAddress();
      }
    }
    else if (oRecTp.equals(Message.RecipientType.BCC)) {
      if (aBccAddrs==null) {
        aEmails = null;
      } else {
        aEmails = new String[aBccAddrs.length];
        for (int a=aBccAddrs.length-1; a>=0; a--)
          aEmails[a] = aBccAddrs[a].getAddress();
      }
    }
    return aEmails;
  } // getAddresses

  // ---------------------------------------------------------------------------

  /**
   * Get array with recipients of a given type
   * @param oRecTp RecipientType
   * @return InternetAddress[]
   */
  public Address[] getRecipients(Message.RecipientType oRecTp) {
    if (oRecTp.equals(Message.RecipientType.TO))
      return aToAddrs;
    else if (oRecTp.equals(Message.RecipientType.CC))
      return aCcAddrs;
    else if (oRecTp.equals(Message.RecipientType.BCC))
      return aBccAddrs;
    else
      return null;
  } // getRecipients

  // ---------------------------------------------------------------------------

  public void setRecipients(Address[] oAddrs, Message.RecipientType oRecTp)
    throws ClassCastException {
    if (oRecTp.equals(Message.RecipientType.TO))
      aToAddrs = (InternetAddress[]) oAddrs;
    else if (oRecTp.equals(Message.RecipientType.CC))
      aCcAddrs = (InternetAddress[]) oAddrs;
    else if (oRecTp.equals(Message.RecipientType.BCC))
      aBccAddrs = (InternetAddress[]) oAddrs;
  }

  // ---------------------------------------------------------------------------

  public void setRecipients(MimeMessage oMsg)
    throws ClassCastException, MessagingException {
    try {
      aToAddrs = (InternetAddress[]) oMsg.getRecipients(Message.RecipientType.TO);
    } catch (AddressException adre) { if (DebugFile.trace) DebugFile.writeln("Recipient AddressException " + adre.getMessage()); }
    try {
      aCcAddrs = (InternetAddress[]) oMsg.getRecipients(Message.RecipientType.CC);
    } catch (AddressException adre) { if (DebugFile.trace) DebugFile.writeln("Recipient AddressException " + adre.getMessage()); }
    try {
      aBccAddrs= (InternetAddress[]) oMsg.getRecipients(Message.RecipientType.BCC);
    } catch (AddressException adre) { if (DebugFile.trace) DebugFile.writeln("Recipient AddressException " + adre.getMessage()); }
  }

  // ---------------------------------------------------------------------------

  /**
   * Add recipients of a given type
   * @param oAddrs InternetAddress[]
   * @param oRecTp RecipientType
   * @throws ClassCastException
   */
  public void addRecipients(Address[] oAddrs, Message.RecipientType oRecTp)
    throws ClassCastException {
    InternetAddress[] aTmpAddrs;
    if (null==oAddrs) return;
    if (oAddrs.length==0) return;
    if (oRecTp.equals(Message.RecipientType.TO)) {
      if (null==aToAddrs) {
        aToAddrs = new InternetAddress[oAddrs.length];
        System.arraycopy(oAddrs, 0, aToAddrs, 0, oAddrs.length);
      } else {
        aTmpAddrs = new InternetAddress[aToAddrs.length+oAddrs.length];
        System.arraycopy(aToAddrs, 0, aTmpAddrs, 0, aToAddrs.length);
        System.arraycopy(oAddrs, 0, aTmpAddrs, aToAddrs.length, oAddrs.length);
        aToAddrs = aTmpAddrs;
      }
    } else if (oRecTp.equals(Message.RecipientType.CC)) {
      if (null==aCcAddrs) {
        aCcAddrs = new InternetAddress[oAddrs.length];
        System.arraycopy(oAddrs, 0, aCcAddrs, 0, oAddrs.length);
      } else {
        aTmpAddrs = new InternetAddress[aCcAddrs.length+oAddrs.length];
        System.arraycopy(aCcAddrs, 0, aTmpAddrs, 0, aCcAddrs.length);
        System.arraycopy(oAddrs, 0, aTmpAddrs, aCcAddrs.length, oAddrs.length);
        aCcAddrs = aTmpAddrs;
      }
    } else if (oRecTp.equals(Message.RecipientType.BCC))
      if (null==aBccAddrs) {
        aBccAddrs = new InternetAddress[oAddrs.length];
        System.arraycopy(oAddrs, 0, aBccAddrs, 0, oAddrs.length);
      } else {
        aTmpAddrs = new InternetAddress[aBccAddrs.length+oAddrs.length];
        System.arraycopy(aBccAddrs, 0, aTmpAddrs, 0, aBccAddrs.length);
        System.arraycopy(oAddrs, 0, aTmpAddrs, aBccAddrs.length, oAddrs.length);
        aBccAddrs = aTmpAddrs;
      }
    } // addRecipients

  // ---------------------------------------------------------------------------

  /**
   * Join mail addresses array on a single String
   * @param aRecipients Address[]
   * @return String Mail addresses delimited by semicolons
   */
  public static String joinAddressList (Address[] aRecipients) {
    InternetAddress oInetAdr;
    String sList = "";
    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecipientsHelper.joinAddressList(Address[])");
      DebugFile.incIdent();
    }
    if (aRecipients!=null) {
      int cRecipients = aRecipients.length;
      if (cRecipients>0) {
        for (int a=0; a<cRecipients; a++) {
          oInetAdr = (InternetAddress) aRecipients[a];
          if (0!=a) sList += ";";
          sList += oInetAdr.getAddress();
        } // next
      } // fi (cRecipients>0)
    } // fi (aRecipients)
    if (DebugFile.trace) {
      DebugFile.writeln("End RecipientsHelper.joinAddressList() : " + sList);
      DebugFile.incIdent();
    }
    return sList;
    } // joinAddressList

  // ---------------------------------------------------------------------------

  /**
   * <p>Parse a String of comma or semicolon delimited addresses</p>
   * Addresses may be of any format accepted by DBInetAddr.parseAddress() method.<br>
   * Distribution lists present at input string are expanded into BCC internal array.<br>
   * Distribution list names begin with "list@" and end with ".list".<br>
   * Or, also distribution list names are enclosed by brackets like "{this is a list}"<br>
   * Thus if "engineers" is the GUID of a list containing members luke@engineers.com,peter@engineers.com
   * then TO "jhon@code.com,martin@maths.com,list@engineers.list,steve@maths.com"
   * will be parsed as<br>
   * TO  jhon@code.com,martin@maths.com,steve@maths.com<br>
   * BCC luke@engineers.com,peter@engineers.com
   * @param oAdCn JDCConnection
   * @param sDelimitedList String with addresses to be parsed
   * @param oRecTp RecipientType
   * @throws SQLException
   * @throws IndexOutOfBoundsException
   * @throws NullPointerException
   * @throws AddressException
   * @throws UnsupportedEncodingException
   */
  public void parseRecipientsList(JDCConnection oAdCn,
                                  String sDelimitedList,
                                  Message.RecipientType oRecTp)
    throws SQLException,IndexOutOfBoundsException,NullPointerException,
           AddressException,UnsupportedEncodingException{
    int nRecipients;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecipientsHelper.parseRecipientsList([JDCConnection],"+sDelimitedList+","+oRecTp+")");
      DebugFile.incIdent();
    }
    String sLId;
    String[] aRecipients = Gadgets.split(sDelimitedList, new char[]{',',';'});
    InternetAddress[] aAdrSet;
    InternetAddress[] aBccSet;
    int iPos;
    int iListCount = 0;

    if (aRecipients!=null) {
      nRecipients = aRecipients.length;
      if (nRecipients>0) {
        for (int a=0; a<nRecipients; a++) {
          sLId = aRecipients[a].trim();
          if (sLId.length()>4) {
            if (sLId.startsWith("list@") && sLId.endsWith(".list") ||
                sLId.charAt(0)=='{' && sLId.charAt(sLId.length()-1)=='}') {
              bHasLists=true;
              iListCount++;
              // *******************************
              // Resolve list name to member set
              DistributionList oLst;
              if (sLId.charAt(0)=='{') {
                oLst = new DistributionList(oAdCn, sLId.substring(1,sLId.length()-1), sWorkAreaId);
                if (oLst.isNull(DB.gu_list)) {
                  if (DebugFile.trace) DebugFile.decIdent();
                  throw new AddressException("RecipientsHelper.parseRecipientsList() list "+sLId.substring(1,sLId.length()-1)+" not found");
                }
              } else {
                oLst = new DistributionList(oAdCn, sLId.substring(sLId.indexOf('@')+1,sLId.indexOf('.')));
                if (oLst.isNull(DB.gu_list)) {
                  if (DebugFile.trace) DebugFile.decIdent();
                  throw new AddressException("RecipientsHelper.parseRecipientsList() list "+sLId.substring(sLId.indexOf('@')+1,sLId.indexOf('.'))+" not found");
                }
              }
              String sPer = oLst.getStringNull(DB.de_list,null);
              String sLst = oLst.activeMembers(oAdCn);
              if (sLst.length()>0) {
                String[] aLst = Gadgets.split(sLst,',');
                int iLst = aLst.length;
                if (null==aBccAddrs) {
                  iPos = 0;
                  aBccSet = new InternetAddress[iLst];
                } else {
                  iPos = aBccAddrs.length;
                  aBccSet = new InternetAddress[iLst+iPos];
                  System.arraycopy(aBccSet, 0, aBccAddrs, 0, iPos);
                }
                if (sPer==null) {
                  for (int l=0; l<iLst; l++) aBccSet[l+iPos] = new InternetAddress(aLst[l]);
                } else {
                  for (int l=0; l<iLst; l++) aBccSet[l+iPos] = new InternetAddress(aLst[l],sPer);
                } // fi (sPer)
                aBccAddrs = aBccSet;
                aRecipients[a] = null;
              } // fi (sLst!="")
            } // fi (aRecipients[a] LIKE list@%.list)
          } // fi (sLId.length>4)
        } // next (a)
        aAdrSet = new InternetAddress[nRecipients-iListCount];
        iPos = 0;
        for (int a=0; a<nRecipients; a++) {
          if (null!=aRecipients[a]) {
            aAdrSet[iPos] = DBInetAddr.parseAddress(aRecipients[a]);
            iPos++;
          }
        } // next
        addRecipients(aAdrSet, oRecTp);
      } // fi (nRecipients==0)
    } // fi (aTo!=null)
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RecipientsHelper.parseRecipientsList()");
    }
  } // parseRecipientsList

  // ---------------------------------------------------------------------------

  /**
   * Delete rows at k_inet_addrs table for given message
   * @param oConn JDCConnection
   * @param sGuMimeMsg String GUID of message which addresses are to be cleared
   * @throws SQLException
   */
  public static void clearRecipientsForMessage (JDCConnection oConn, String sGuMimeMsg) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecipientsHelper.clearRecipientsForMessage([JDCConnection], "+sGuMimeMsg+")");
      DebugFile.incIdent();
    }

    PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_inet_addrs+" WHERE "+DB.gu_mimemsg+"=?");
    oStmt.setString(1, sGuMimeMsg);
    oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RecipientsHelper.clearRecipientsForMessage()");
    }
  } // clearRecipientsForMessage

  // ---------------------------------------------------------------------------

  public static InternetAddress getFromAddress(MimeMessage oMsg) throws MessagingException {
    Address[] aFrom = null;
    try {
      aFrom = oMsg.getFrom();
    } catch (AddressException adre) {
      if (DebugFile.trace) DebugFile.writeln("From AddressException " + adre.getMessage());
    }
    InternetAddress oFrom;
    if (aFrom!=null) {
      if (aFrom.length>0)
        oFrom = (InternetAddress) aFrom[0];
      else
        oFrom = null;
    }
    else
      oFrom = null;
    return oFrom;
  } // getFromAddress

  // ---------------------------------------------------------------------------

  public static InternetAddress getReplyAddress(MimeMessage oMsg) throws MessagingException {
    Address[] aReply = null;
    InternetAddress oReply;
    try {
      aReply = oMsg.getReplyTo();
    } catch (AddressException adre) {
      if (DebugFile.trace) DebugFile.writeln("Reply-To AddressException " + adre.getMessage());
    }

    if (aReply!=null) {
      if (aReply.length>0)
        oReply = (InternetAddress) aReply[0];
      else
        oReply = null;
    } else {
      if (DebugFile.trace) DebugFile.writeln("no reply-to address found");
      oReply = null;
    }
    return oReply;
  }

  // ---------------------------------------------------------------------------

  public static int acknowledgeNotification(JDCConnection oCon, MultipartReport oCnt)
  	throws SQLException, IOException, MessagingException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin acknowledgeNotification([JDCConnection],[MimeMessage])");
      DebugFile.incIdent();
    }

	int iAffected = 0;	
	DispositionNotification oRpt = (DispositionNotification) oCnt.getReport();
	InternetHeaders oInetHdrs = oRpt.getNotifications();			        					
    String sHeader = oInetHdrs.getHeader("Disposition", null);

	if (DebugFile.trace) DebugFile.writeln("Disposition: "+sHeader);
    
	if (sHeader!=null) {
      if (sHeader.endsWith("displayed")) {						
        String sSQL = "UPDATE "+DB.k_inet_addrs+ " SET "+DB.dt_displayed+"=";
        PreparedStatement oUpdt = oCon.prepareStatement("UPDATE "+DB.k_inet_addrs+ " SET "+DB.dt_displayed+"=?,"+DB.user_agent+"=? WHERE "+DB.id_message+"=? AND "+DB.tx_email+"=?");
		Timestamp oTs = new Timestamp(new Date().getTime());
		oUpdt.setTimestamp(1, oTs);
        sSQL+=oTs.toString()+","+DB.user_agent+"=";
        sHeader = oInetHdrs.getHeader("Reporting-UA", null);
		if (null==sHeader) {
		  sSQL+="null";
          oUpdt.setNull(2, Types.VARCHAR);
		} else {
		  sSQL+="'"+Gadgets.left(sHeader, 254)+"'";
		  oUpdt.setString(2, Gadgets.left(sHeader, 254));
        }
        String sMsgId = oInetHdrs.getHeader("Original-Message-ID",null);
		sSQL+=" WHERE "+DB.id_message+"='"+sMsgId+"' AND ";
        oUpdt.setString(3, sMsgId);
		String sTxEmail = oInetHdrs.getHeader("Final-Recipient", null);
		if (sTxEmail.indexOf(';')>0)
		  sTxEmail = Gadgets.split2(sTxEmail,';')[1];
	    sSQL+=DB.tx_email+"='"+sTxEmail+"'";
	    oUpdt.setString(4, sTxEmail);
    	if (DebugFile.trace) {
          DebugFile.writeln("PreparedStatement.executeUpdate("+sSQL+")");
    	}        
        iAffected = oUpdt.executeUpdate();
		oUpdt.close();
      } // fi
	} // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End acknowledgeNotification() : "+String.valueOf(iAffected));
    }
    return iAffected;
  } // acknowledgeNotification

  // ---------------------------------------------------------------------------

}
