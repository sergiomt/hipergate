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

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.StreamPipe;
import com.knowgate.dfs.ByteArrayDataSource;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;

import java.nio.charset.Charset;

import java.math.BigDecimal;

import java.util.ArrayList;

import java.sql.ResultSet;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.SQLException;
import java.sql.Types;

import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;

import java.text.SimpleDateFormat;

import java.net.URL;

import javax.activation.DataHandler;
import javax.activation.FileDataSource;

import javax.mail.BodyPart;
import javax.mail.Address;
import javax.mail.Part;
import javax.mail.Message;
import javax.mail.Flags;
import javax.mail.Folder;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.ParseException;
import javax.mail.internet.MimePart;
import javax.mail.internet.MimeMultipart;
import javax.mail.MessagingException;
import javax.mail.FolderClosedException;

import com.sun.mail.smtp.SMTPMessage;
import com.sun.mail.dsn.MultipartReport;

import org.htmlparser.Parser;
import org.htmlparser.util.ParserException;
import org.htmlparser.beans.StringBean;

import com.knowgate.misc.Hosts;

/**
 * MIME messages stored at database BLOB columns or MBOX files
 * @author Sergio Montoro Ten
 * @version 5.0
 */

public class DBMimeMessage extends MimeMessage implements MimePart,Part {

  private String sGuid;
  private Folder oFolder;
  private Address[] aAddrs;
  private HashMap<String,Object> oHeaders;

  // private static PatternMatcher oMatcher = new Perl5Matcher();
  // private static PatternCompiler oCompiler = new Perl5Compiler();

  /**
   * Create an empty message
   * @param oMailSession
   */

  public DBMimeMessage(Session oMailSession) {
    super(oMailSession);
    sGuid = null;
    oFolder = null;
    oHeaders = null;
  }

  /**
   * Create DBMimeMessage from a MimeMessage and assign a new GUID
   * @param oMsg MimeMessage
   * @throws MessagingException
   */
  public DBMimeMessage(MimeMessage oMsg)
    throws MessagingException {
    super(oMsg);
    sGuid = Gadgets.generateUUID();
    oHeaders = null;
  }

  /**
   * Create DBMimeMessage from an InputStream and assign a new GUID
   * @param oMailSession Session
   * @param oInStrm InputStream
   * @throws MessagingException
   */
  public DBMimeMessage(Session oMailSession, InputStream oInStrm)
    throws MessagingException {
    super(oMailSession, oInStrm);
    sGuid = Gadgets.generateUUID();
    oHeaders = null;
  }

  /**
   * Create DBMimeMessage from an InputStream, set folder and assign a new GUID
   * @param Folder oFldr
   * @param oInStrm InputStream
   * @throws MessagingException
   */
  public DBMimeMessage(Folder oFldr, InputStream oInStrm)
    throws MessagingException,ClassCastException {
    super(((DBStore)oFldr.getStore()).getSession(), oInStrm);
    setFolder(oFldr);
    sGuid = Gadgets.generateUUID();
    oHeaders = null;
  }

  /**
   * Create DBMimeMessage from a MimeMessage, set folder and assign a new GUID
   * @param oFldr Folder
   * @param MimeMessage oMsg
   * @throws MessagingException
   */
  public DBMimeMessage(Folder oFldr, MimeMessage oMsg)
    throws MessagingException {
    super(oMsg);
    setFolder(oFldr);
    sGuid = Gadgets.generateUUID();
    oHeaders = null;
  }

  /**
   * <p>Create DBMimeMessage from another DBMimeMessage</p>
   * GUID of this message is set to be the same as that of oMsg
   * @param oFldr Folder
   * @param MimeMessage oMsg
   * @throws MessagingException
   */
  public DBMimeMessage(Folder oFldr, DBMimeMessage oMsg)
    throws MessagingException {
    super(oMsg);
    setFolder(oFldr);
    sGuid = oMsg.getMessageGuid();
    oHeaders = null;
  }

  /**
   * Create empty message at the given folder
   * @param oFldr Folder
   * @param sMsgGuid String Message GUID
   * @throws MessagingException
   */
  public DBMimeMessage (Folder oFldr, String sMsgGuid)
    throws MessagingException {
    super(((DBStore)oFldr.getStore()).getSession());
    sGuid = sMsgGuid;
    setFolder(oFldr);
    oHeaders = null;    
  }

  // ---------------------------------------------------------------------------

  /**
   * Get message folder
   * @return Folder
   */
  public Folder getFolder()  {
    if (oFolder==null)
      return super.getFolder();
    else
      return oFolder;
  }

  // ---------------------------------------------------------------------------

  /**
   * Set message folder
   * @param oFldr Folder
   */
  public void setFolder(Folder oFldr) {
    oFolder = oFldr;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get message GUID</p>
   * If message had no previous GUID then a new one is assigned
   * @return String
   */
  public String getMessageGuid() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getMessageGuid()");
      DebugFile.incIdent();
    }

    if (null==sGuid) {
      if (DebugFile.trace) DebugFile.writeln("previous message GUID is null, assigning a new one");
      sGuid = Gadgets.generateUUID();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.getMessageGuid() : "+sGuid);
    }
    return sGuid;
  }

  // ---------------------------------------------------------------------------

  /**
   * Set message GUID
   * @param sId String
   */
  public void setMessageGuid(String sId) {
    sGuid = sId;
  }
  // ---------------------------------------------------------------------------

  /**
   * <p>Get message flags</p>
   * Message flags are readed from k_mime_msgs table at the database
   * @return Flags
   * @throws MessagingException
   */
  public Flags getFlags() throws MessagingException {
    Object oFlag;

    if (oFolder==null)
      return super.getFlags();
    else {
      Flags oRetVal = null;
      Statement oStmt = null;
      ResultSet oRSet = null;
      try {
        Flags.Flag[] aFlags = new Flags.Flag[]{Flags.Flag.RECENT, Flags.Flag.ANSWERED, Flags.Flag.DELETED, Flags.Flag.DRAFT, Flags.Flag.FLAGGED, Flags.Flag.SEEN};
        oStmt = ( (DBFolder) oFolder).getConnection().createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oRSet = oStmt.executeQuery("SELECT "+DB.bo_recent+","+DB.bo_answered+","+DB.bo_deleted+","+DB.bo_draft+","+DB.bo_flagged+","+DB.bo_recent+","+DB.bo_seen+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"='"+getMessageGuid()+"'");
        if (oRSet.next()) {
          oRetVal = new Flags();
          for (int f=1; f<=6; f++) {
            oFlag = oRSet.getObject(f);
            if (!oRSet.wasNull()) {
              if (oFlag.getClass().equals(Short.TYPE)) {
                if (((Short) oFlag).shortValue()==(short)1)
                  oRetVal.add(aFlags[f-1]);
              }
              else {
                if (Integer.parseInt(oFlag.toString())!=0)
                  oRetVal.add(aFlags[f-1]);
              }
            }
          } // next (f)
        }
        oRSet.close();
        oRSet = null;
        oStmt.close();
        oStmt = null;
        return oRetVal;
      }
      catch (SQLException sqle) {
        if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) {} }
        if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) {} }
      }
    }
    return null;
  } // getFlags

  // ---------------------------------------------------------------------------

  /**
   * <p>Get message recipients</p>
   * This method read recipients from a message stored at k_inet_addrs table
   * or if message is not already stored at k_inet_addrs then it delegates
   * behaviour to parent class MimMessage.getAllRecipients()
   * @return If this message is stored at the database then this method returns
   * an array of DBInetAddr objects. If this message has not been stored yet then
   * this method returns an array of javax.mail.internet.InternetAddress objects
   * @throws SQLException
   * @throws MessagingException
   * @throws NullPointerException
   * @throws IllegalArgumentException
   */
  public Address[] getAllRecipients()
    throws MessagingException, NullPointerException, IllegalArgumentException  {
    DBSubset oAddrs;
    int iAddrs;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getAllRecipients()");
      DebugFile.incIdent();
    }

    if (oFolder==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("Message is not stored at any Folder or Folder is closed");
        DebugFile.decIdent();
      }
      return super.getAllRecipients();
    }
    else {
      if (oFolder.getClass().getName().equals("com.knowgate.hipermail.DBFolder")) {

		try {
          if (((DBFolder)oFolder).getConnection()==null) {
            if (DebugFile.trace) DebugFile.decIdent();
            throw new MessagingException("DBMimeMessage.getAllRecipients() not connected to the database");
          }
		} catch (SQLException sqle) {
          if (DebugFile.trace) DebugFile.decIdent();
          throw new MessagingException(sqle.getMessage(), sqle);
        }

        oAddrs = new DBSubset(DB.k_inet_addrs,
                              DB.gu_mimemsg + "," + DB.id_message + "," +
                              DB.tx_email + "," + DB.tx_personal + "," +
                              DB.tp_recipient + "," + DB.gu_user + "," +
                              DB.gu_contact + "," + DB.gu_company,
                              DB.gu_mimemsg + "=?", 10);
        try {
          iAddrs = oAddrs.load(((DBFolder)oFolder).getConnection(), new Object[]{sGuid});
        } catch (SQLException sqle) {
          if (DebugFile.trace) DebugFile.decIdent();
          throw new MessagingException(sqle.getMessage(), sqle);
        }

        if (iAddrs>0) {
          aAddrs = new DBInetAddr[iAddrs];
          for (int a = 0; a < iAddrs; a++) {
            aAddrs[a] = new DBInetAddr(oAddrs.getString(0,a), // gu_mimemsg
                                       oAddrs.getString(1,a), // id_message
                                       oAddrs.getString(2,a), // tx_email
                                       oAddrs.getStringNull(3,a,null), // tx_personal
                                       oAddrs.getString(4,a), // tp_recipient
                                       oAddrs.getStringNull(5,a,null), // gu_user
                                       oAddrs.getStringNull(6,a,null), // gu_contact
                                       oAddrs.getStringNull(7,a,null)); // gu_company
          } // next
        } // fi (iAddrs)
        else {
          aAddrs = null;
        }
      } // fi (oFolder.getClass() == com.knowgate.hipergate.DBFolder)
      else {
        DebugFile.writeln("message Folder type is " + oFolder.getClass().getName());
        if (DebugFile.trace) DebugFile.decIdent();
        aAddrs = super.getAllRecipients();
      } // fi(oFolder instanceof DBFolder)
    } // fi (oFolder)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aAddrs)
        DebugFile.writeln("End DBMimeMessage.getAllRecipients() : Address[0]");
      else
        DebugFile.writeln("End DBMimeMessage.getAllRecipients() : Address["+String.valueOf(aAddrs.length)+"]");
    }

    return aAddrs;
  } // getAllRecipients

  // ---------------------------------------------------------------------------

  /**
   * <p>Get recipients of a particular type</p>
   * This method first calls getAllRecipients() and then filters retrieved recipients by their type.
   * @param cTpRecipient javax.mail.Message.RecipientType
   * @return Address[]
   * @throws MessagingException
   */
  public Address[] getRecipients(Message.RecipientType cTpRecipient)
    throws MessagingException {
    int a;
    int iRecipients = 0;
    DBInetAddr[] aRecipients = null;
    DBInetAddr oAdr;

    if (oFolder==null) {
      return super.getRecipients(cTpRecipient);
    }

    if (aAddrs==null) getAllRecipients();

    if (aAddrs!=null) {
        for (a=0; a<aAddrs.length; a++) {
          oAdr = ((DBInetAddr) aAddrs[a]);
          if ((oAdr.getStringNull(DB.tp_recipient, "").equalsIgnoreCase("to") && Message.RecipientType.TO.equals(cTpRecipient))
            ||(oAdr.getStringNull(DB.tp_recipient, "").equalsIgnoreCase("cc") && Message.RecipientType.CC.equals(cTpRecipient))
            ||(oAdr.getStringNull(DB.tp_recipient, "").equalsIgnoreCase("bcc") && Message.RecipientType.BCC.equals(cTpRecipient)))

            iRecipients++;
        } // next

        aRecipients = new DBInetAddr[iRecipients];

        int iRecipient = 0;

        for (a=0; a<aAddrs.length; a++) {
          oAdr = ((DBInetAddr)aAddrs[a]);
          if ((oAdr.getStringNull(DB.tp_recipient, "").equalsIgnoreCase("to") && Message.RecipientType.TO.equals(cTpRecipient))
            ||(oAdr.getStringNull(DB.tp_recipient, "").equalsIgnoreCase("cc") && Message.RecipientType.CC.equals(cTpRecipient))
            ||(oAdr.getStringNull(DB.tp_recipient, "").equalsIgnoreCase("bcc") && Message.RecipientType.BCC.equals(cTpRecipient)))

            aRecipients[iRecipient++] = (DBInetAddr) aAddrs[a];
        } // next
      }

    return aRecipients;
  } // getRecipients

  // ---------------------------------------------------------------------------

  public DBInetAddr getFromRecipient()
    throws MessagingException {

    DBInetAddr oFrom = null;

    if (aAddrs==null) getAllRecipients();

    if (aAddrs!=null) {
      for (int a=0; a<aAddrs.length && oFrom==null; a++) {

        if (((DBInetAddr)(aAddrs[a])).getStringNull(DB.tp_recipient, "").equals("from"))
          oFrom = (DBInetAddr) (aAddrs[a]);
      } // next

    } // fi

    return oFrom;
  } // getFrom

  // ---------------------------------------------------------------------------

  private void cacheHeaders(JDCConnection oConn)
    throws SQLException,MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.cacheHeaders([JDCConnection])");
      DebugFile.incIdent();
    }

    PreparedStatement oStmt = null;
    ResultSet oRSet = null;

        oStmt = oConn.prepareStatement( "SELECT "+
          DB.id_type+","+DB.tx_subject+","+DB.id_message+","+
          DB.len_mimemsg+","+DB.tx_md5+","+DB.de_mimemsg+","+DB.tx_encoding+","+
          DB.dt_sent+","+DB.dt_received+","+DB.dt_readed+","+
          DB.bo_spam+","+DB.id_compression+","+DB.id_priority+
          " FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"=?",
          ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, getMessageGuid());
        oRSet = oStmt.executeQuery();

        if (oRSet.next()) {
          oHeaders = new HashMap<String,Object> (23);
          oHeaders.put("Content-Type", oRSet.getString(1));
          oHeaders.put("Subject", oRSet.getString(2));
          oHeaders.put("Message-ID", oRSet.getString(3));
          oHeaders.put("Date", oRSet.getDate(8));
          oHeaders.put("Date-Received", oRSet.getDate(9));
          oHeaders.put("Date-Readed", oRSet.getDate(10));
          oHeaders.put("X-Spam-Flag", oRSet.getObject(11));
          oHeaders.put("Compression", oRSet.getString(12));
          oHeaders.put("X-Priority", oRSet.getString(13));
        }
        oRSet.close();
        oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.cacheHeaders()");
    }
  }

  // ---------------------------------------------------------------------------

  public String getMessageContentType()
    throws MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getMessageContentType()");
      DebugFile.incIdent();
    }

    String sRetVal;

    if (oFolder==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("Message is not stored at any Folder or Folder is closed");
      }
      sRetVal = super.getContentType();
    }
    else {
      try {
        if (null==oHeaders) cacheHeaders(((DBFolder) oFolder).getConnection());
        if (null==oHeaders)
          sRetVal = super.getContentType();
        else
          sRetVal = (String) oHeaders.get("Content-Type");
      }
      catch (SQLException sqle) {
        throw new MessagingException (sqle.getMessage(), sqle);
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.getMessageContentType() : " + sRetVal);
    }
    return sRetVal;
  } // getMessageContentType

  // ---------------------------------------------------------------------------

  public Date getSentDate()
    throws MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getSentDate()");
      DebugFile.incIdent();
    }

    Date dtRetVal;

    if (oFolder==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("Message is not stored at any Folder or Folder is closed");
      }
      dtRetVal = super.getSentDate();
    }
    else {
      try {
        if (null==oHeaders) cacheHeaders(((DBFolder) oFolder).getConnection());
        if (null==oHeaders)
          dtRetVal = super.getSentDate();
        else
          dtRetVal = (java.util.Date) oHeaders.get("Date");
      }
      catch (SQLException sqle) {
        throw new MessagingException (sqle.getMessage(), sqle);
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (dtRetVal==null)
        DebugFile.writeln("End DBMimeMessage.getSentDate() : null");
      else
        DebugFile.writeln("End DBMimeMessage.getSentDate() : " + dtRetVal.toString());
    }
    return dtRetVal;
  }

  // ---------------------------------------------------------------------------

  public String getSubject()
    throws MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getSubject()");
      DebugFile.incIdent();
    }

    String sRetVal;

    if (oFolder==null) {
      if (DebugFile.trace) {
        DebugFile.writeln("Message is not stored at any Folder or Folder is closed");
      }
      sRetVal = super.getSubject();
    }
    else {
      try {
        if (null==oHeaders) cacheHeaders(((DBFolder) oFolder).getConnection());
        if (null==oHeaders)
          sRetVal = super.getSubject();
        else
          sRetVal = (String) oHeaders.get("Subject");
      }
      catch (SQLException sqle) {
        throw new MessagingException (sqle.getMessage(), sqle);
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.getSubject() : " + sRetVal);
    }
    return sRetVal;
  }

  // ---------------------------------------------------------------------------

  public MimePart getMessageBody ()
    throws ParseException, MessagingException, IOException {

    MimePart oRetVal = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getMessageBody([MimeMessage])");
      DebugFile.incIdent();
    }

     Object oContent = getContent();

     if (DebugFile.trace) {
       if (null==oContent)
         DebugFile.writeln("message content is null");
       else
         DebugFile.writeln("message content class is " + oContent.getClass().getName());
     }

     String sContentClass = oContent.getClass().getName();

     if (sContentClass.equals("javax.mail.internet.MimeMultipart")) {

       MimeMultipart oParts = (MimeMultipart) oContent;
       int iParts = oParts.getCount();
       MimePart oPart;
       String sType, sPrevType, sNextType;

       for (int p=0; p<iParts; p++) {

         oPart = (MimeBodyPart) oParts.getBodyPart(0);

         sType = oPart.getContentType().toUpperCase();

         if (p<iParts-1)
           sNextType = ((MimeBodyPart) oParts.getBodyPart(p+1)).getContentType().toUpperCase();
         else
           sNextType = "";

         if (p>0 && iParts>1)
           sPrevType = ((MimeBodyPart) oParts.getBodyPart(p-1)).getContentType().toUpperCase();
         else
           sPrevType = "";

         // If a message has a dual content both text and html ignore the text and show only HTML
         if ((iParts<=1) && (sType.startsWith("TEXT/PLAIN") || sType.startsWith("TEXT/HTML"))) {
           if (DebugFile.trace) DebugFile.writeln("parts=" + String.valueOf(iParts) + ", content-type=" + oPart.getContentType());
           oRetVal = oPart;
           break;
         }
         else if (((p==0) && (iParts>1) && sType.startsWith("TEXT/PLAIN") && sNextType.startsWith("TEXT/HTML"))) {
           if (DebugFile.trace) DebugFile.writeln("parts=" + String.valueOf(iParts) + ", part=0, content-type=" + oPart.getContentType() + ", next-type=" + sNextType);
           oRetVal = ((MimeBodyPart) oParts.getBodyPart(p+1));
           break;
         }
         else if ((p==1) && sType.startsWith("TEXT/PLAIN") && sPrevType.startsWith("TEXT/HTML")) {
           if (DebugFile.trace) DebugFile.writeln("parts=" + String.valueOf(iParts) + ", part=1, content-type=" + oPart.getContentType() + ", prev-type=" + sPrevType);
           oRetVal = ((MimeBodyPart) oParts.getBodyPart(p-1));
           break;
         }
         else {
           oRetVal = DBMimePart.getMessagePart (oPart, p);
         }
       }  // next (p)
     }
     else if (sContentClass.equals("java.lang.String")) {
       oRetVal = new MimeBodyPart();
       oRetVal.setText((String) oContent);
     }
     else {
       throw new MessagingException("Unparsed Mime Content " + oContent.getClass().getName());
     }

     if (null==oRetVal) {
       oRetVal = new MimeBodyPart();
       oRetVal.setText("");
     }

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End DBMimeMessage.getMessageBody() : " + oRetVal.getContentType());
     }

     return oRetVal;
  } // getMessageBody

  // ---------------------------------------------------------------------------

  public void setFlag (Flags.Flag oFlg, boolean bFlg) throws MessagingException {
    String sColunm;

    super.setFlag(oFlg, bFlg);

    if (oFlg.equals(Flags.Flag.ANSWERED))
      sColunm = DB.bo_answered;
    else if (oFlg.equals(Flags.Flag.DELETED))
      sColunm = DB.bo_deleted;
    else if (oFlg.equals(Flags.Flag.DRAFT))
      sColunm = DB.bo_draft;
    else if (oFlg.equals(Flags.Flag.FLAGGED))
      sColunm = DB.bo_flagged;
    else if (oFlg.equals(Flags.Flag.RECENT))
      sColunm = DB.bo_recent;
    else if (oFlg.equals(Flags.Flag.SEEN))
      sColunm = DB.bo_seen;
    else
      sColunm = null;

    if (null!=sColunm && oFolder instanceof DBFolder) {
      JDCConnection oConn = null;
      PreparedStatement oUpdt = null;
      try {
      	if (getMessageGuid()!=null) {
          oConn = ((DBFolder)oFolder).getConnection();
          String sSQL = "UPDATE " + DB.k_mime_msgs + " SET " + sColunm + "=" + (bFlg ? "1" : "0") + " WHERE " + DB.gu_mimemsg + "=?";
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
          oUpdt = oConn.prepareStatement(sSQL);
          oUpdt.setString(1, getMessageGuid());
          oUpdt.executeUpdate();
          oUpdt.close();
          oUpdt=null;
          oConn.commit();
          oConn=null;
      	}
      }
      catch (SQLException e) {
        if (null!=oConn) { try { oConn.rollback(); } catch (Exception ignore) {} }
        if (null!=oUpdt) { try { oUpdt.close(); } catch (Exception ignore) {} }
        if (DebugFile.trace) DebugFile.decIdent();
        throw new MessagingException(e.getMessage(), e);
      }
    }
  } // setFlag

  // ---------------------------------------------------------------------------

  public void saveChanges() throws MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.saveChanges()");
      DebugFile.incIdent();
    }

    Flags oFlgs = getFlags();

    if (oFolder instanceof DBFolder) {
      JDCConnection oConn = null;
      try {
    	oConn = ((DBFolder) oFolder).getConnection();
        oConn.commit();
        oConn=null;
      }
      catch (SQLException e) {
        if (null!=oConn) { try { oConn.rollback(); } catch (Exception ignore) {} }
        if (DebugFile.trace) DebugFile.decIdent();
        throw new MessagingException(e.getMessage(), e);
      }
    }
    else {
      super.saveChanges();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.saveChanges()");
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * Get message parts as an array of DBMimePart objects
   * @return DBMimeMultiPart if this message folder is of type DBFolder
   * or another type of Object if this message folder is another subclass of javax.mail.Folder
   * such as POP3Folder.
   * @throws MessagingException
   * @throws IOException
   * @throws NullPointerException If this message Folder is <b>null</b>
   */
  public Multipart getParts () throws MessagingException, IOException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getParts()");
      DebugFile.incIdent();
    }

    if (oFolder==null) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("DBMimeMessage.getContent() : Folder for message cannot be null");
    }

    if (DebugFile.trace) DebugFile.writeln("Folder type " + oFolder.getClass().getName());

    Multipart oRetVal;

    if (oFolder.getClass().getName().equals("com.knowgate.hipermail.DBFolder")) {

      if (sGuid==null) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new NullPointerException("DBMimeMessage.getContent() : message GUID cannot be null");
      }

      PreparedStatement oStmt = null;
      ResultSet oRSet = null;
      DBMimeMultipart oMultiPart = new DBMimeMultipart((Part) this);

      try {
        if (DebugFile.trace) {
          DebugFile.writeln("Connection.prepareStatement(SELECT id_part,id_content,id_disposition,len_part,de_part,tx_md5,id_encoding,file_name,id_type FROM "+ DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='"+sGuid+"')");
        }

		JDCConnection oJdcc = ((DBFolder)oFolder).getConnection();
        oStmt = oJdcc.prepareStatement("SELECT id_part,id_content,id_disposition,len_part,de_part,tx_md5,id_encoding,file_name,id_type FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "=?",
                                        ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sGuid);

        oRSet = oStmt.executeQuery();

        while (oRSet.next()) {
          if (DebugFile.trace) DebugFile.writeln("DBMimeMultipart.addBodyPart("+sGuid+","+String.valueOf(oRSet.getInt(1))+","+oRSet.getString(2)+","+oRSet.getString(9)+","+oRSet.getString(6)+","+oRSet.getString(5)+","+oRSet.getString(3)+","+oRSet.getString(7)+","+oRSet.getString(8)+","+String.valueOf(oRSet.getInt(4)));

          MimePart oPart = new DBMimePart(oMultiPart, oRSet.getInt(1),oRSet.getString(2),oRSet.getString(9),oRSet.getString(6),oRSet.getString(5),oRSet.getString(3), oRSet.getString(7), oRSet.getString(8),oRSet.getInt(4));

          oMultiPart.addBodyPart(oPart );
        }

        oRSet.close();
        oRSet = null;
        oStmt.close();
        oStmt = null;

      } catch (SQLException sqle) {
        try { if (oRSet!=null) oRSet.close(); } catch (Exception e) {}
        try { if (oStmt!=null) oStmt.close(); } catch (Exception e) {}
        throw new MessagingException(sqle.getMessage(), sqle);
      }
      oRetVal = oMultiPart;
    }
    else {
      oRetVal = (MimeMultipart) super.getContent();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
        DebugFile.writeln("End DBMimeMessage.getParts() : " + (oRetVal==null ? "null" : oRetVal.getClass().getName()));
    }

    return oRetVal;
  } // getParts

  // ---------------------------------------------------------------------------

   public MimePart getBody ()
    throws ParseException, MessagingException, IOException {

    MimePart oRetVal = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getBody([MimeMessage])");
      DebugFile.incIdent();
    }

     Object oContent = null;

     try {
       oContent = super.getContent();
     }
     catch (Exception xcpt) {
       DebugFile.decIdent();
       throw new ParseException("MimeMessage.getContent() ParseException cause " + xcpt.getClass().getName() + " " + (xcpt.getMessage()==null ? "" : xcpt.getMessage()));
     }

     if (DebugFile.trace) {
       if (null==oContent)
         DebugFile.writeln("message content is null");
       else
         DebugFile.writeln("message content class is " + oContent.getClass().getName());
     }

     String sContentClass = oContent.getClass().getName();

     if (sContentClass.equals("javax.mail.internet.MimeMultipart")) {

       MimeMultipart oParts = (MimeMultipart) oContent;
       int iParts = oParts.getCount();
       MimePart oPart;
       String sType, sPrevType, sNextType;

       for (int p=0; p<iParts; p++) {

         oPart = (MimePart) oParts.getBodyPart(0);

         sType = oPart.getContentType().toUpperCase();

         if (p<iParts-1)
           sNextType = ((MimeBodyPart) oParts.getBodyPart(p+1)).getContentType().toUpperCase();
         else
           sNextType = "";

         if (p>0 && iParts>1)
           sPrevType = ((MimeBodyPart) oParts.getBodyPart(p-1)).getContentType().toUpperCase();
         else
           sPrevType = "";

         // If a message has a dual content both text and html ignore the text and show only HTML
         if ((iParts<=1) && (sType.startsWith("TEXT/PLAIN") || sType.startsWith("TEXT/HTML"))) {
           if (DebugFile.trace) DebugFile.writeln("parts=" + String.valueOf(iParts) + ", content-type=" + oPart.getContentType());
           oRetVal = oPart;
           break;
         }
         else if (((p==0) && (iParts>1) && sType.startsWith("TEXT/PLAIN") && sNextType.startsWith("TEXT/HTML"))) {
           if (DebugFile.trace) DebugFile.writeln("parts=" + String.valueOf(iParts) + ", part=0, content-type=" + oPart.getContentType() + ", next-type=" + sNextType);
           oRetVal = ((MimeBodyPart) oParts.getBodyPart(p+1));
           break;
         }
         else if ((p==1) && sType.startsWith("TEXT/PLAIN") && sPrevType.startsWith("TEXT/HTML")) {
           if (DebugFile.trace) DebugFile.writeln("parts=" + String.valueOf(iParts) + ", part=1, content-type=" + oPart.getContentType() + ", prev-type=" + sPrevType);
           oRetVal = ((MimeBodyPart) oParts.getBodyPart(p-1));
           break;
         }
         else {
           oRetVal = DBMimePart.getMessagePart (oPart, p);
         }
       }  // next (p)
     }
     else if (sContentClass.equals("com.sun.mail.dsn.MultipartReport")) {
       oRetVal = ((MultipartReport) oContent).getTextBodyPart();
     }
     else if (sContentClass.equals("java.lang.String")) {
       oRetVal = new MimeBodyPart();
       oRetVal.setText((String) oContent);
     }
     else if (oContent instanceof InputStream) {
       // This branch is reached when the content-type is not recognized
       // (usually with a com.sun.mail.util.SharedByteArrayInputStream)
       // Decode content as an ISO-8859-1 string
       if (DebugFile.trace) DebugFile.writeln("No data handler found for Content-Type, decoding as ISO-8859-1 string");
       InputStream oInStrm = (InputStream) oContent;
       ByteArrayOutputStream oBaStrm = new ByteArrayOutputStream();
       StreamPipe oPipe = new StreamPipe();
       oPipe.between(oInStrm, oBaStrm);
       oRetVal = new MimeBodyPart();
       oRetVal.setText(oBaStrm.toString("ISO8859_1"));
     }
     else {
       throw new MessagingException("Unparsed Mime Content " + oContent.getClass().getName());
     }

     if (null==oRetVal) {
       oRetVal = new MimeBodyPart();
       oRetVal.setText("");
     }

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End DBMimeMessage.getBody() : " + oRetVal.getContentType());
     }

     return oRetVal;
  } // getBody

  // ---------------------------------------------------------------------------

  /**
   * Get message body text into a StringBuffer
   * @param oBuffer StringBuffer
   * @throws MessagingException
   * @throws IOException
   * @throws ClassCastException
   */
  public void getText (StringBuffer oBuffer)
    throws MessagingException,IOException,ClassCastException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getText()");
      DebugFile.incIdent();
    }

    if (null==oFolder) {
      Multipart oParts = (Multipart) super.getContent();

      if (DebugFile.trace) DebugFile.writeln("MimeBodyPart = MimeMultipart.getBodyPart(0)");

      BodyPart oPart0 = oParts.getBodyPart(0);

      if (DebugFile.trace) {
        if (null==oPart0)
          DebugFile.writeln("part 0 is null");
        else
          DebugFile.writeln("part 0 is " + oPart0.getClass().getName());
      }
      DBMimePart.parseMimePart (oBuffer, null, null, getMessageID()!=null ? getMessageID() : getContentID(), (MimePart) oPart0, 0);
    }
    else {
      InputStream oInStrm;
      PreparedStatement oStmt = null;
      ResultSet oRSet = null;
      MimeBodyPart oBody = null;
      String sFolderNm = null;
      String sType = "multipart/";

      try {
        sFolderNm = ((DBFolder)oFolder).getCategory().getStringNull(DB.nm_category, null);
        if (getMessageGuid()!=null) {
          oStmt = ((DBFolder)oFolder).getConnection().prepareStatement("SELECT "+DB.id_type+","+DB.by_content+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"=?");
          oStmt.setString(1, getMessageGuid());
        }
        else {
          oStmt = ((DBFolder)oFolder).getConnection().prepareStatement("SELECT "+DB.id_type+","+DB.by_content+" FROM "+DB.k_mime_msgs+" WHERE "+DB.id_message+"=? AND "+DB.gu_category+"=?");
          oStmt.setString(1, getMessageID());
          oStmt.setString(2, ((DBFolder)oFolder).getCategory().getString(DB.gu_category));
        }
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          sType = oRSet.getString(1);
          oInStrm = oRSet.getBinaryStream(2);
          if (!oRSet.wasNull()) {
            oBody = new MimeBodyPart(oInStrm);
            oInStrm.close();
          }
        }
        oRSet.close();
        oRSet=null;
        oStmt.close();
        oStmt=null;
      }
      catch (SQLException sqle) {
        if (oRSet!=null) { try {oRSet.close();} catch (Exception ignore) {} }
        if (oStmt!=null) { try {oStmt.close();} catch (Exception ignore) {} }
        throw new MessagingException(sqle.getMessage(), sqle);
      }
      if (oBody!=null) {
        if (sType.startsWith("text/"))
          oBuffer.append(oBody.getContent());
        else
          DBMimePart.parseMimePart (oBuffer, null, sFolderNm, getMessageID()!=null ? getMessageID() : getContentID(), oBody, 0);
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.getText() : " + String.valueOf(oBuffer.length()));
    }
  } // getText

  // ---------------------------------------------------------------------------

  public String getText ()
    throws MessagingException,IOException {
    StringBuffer oStrBuff = new StringBuffer(16000);
    getText(oStrBuff);
    return oStrBuff.toString();
  }

  // ---------------------------------------------------------------------------

  public void getTextPlain (StringBuffer oBuffer)
    throws MessagingException,IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.getTextPlain()");
      DebugFile.incIdent();
    }
    final String sContentType = getContentType();
    boolean bHasPlainTextVersion = false;
    
    if (DebugFile.trace) DebugFile.writeln("content-type="+sContentType);

    if (sContentType.startsWith("text/plain")) {
      getText(oBuffer);
    }
    else if (getContentType().startsWith("text/html")) {
      StringBuffer oHtmlBuff = new StringBuffer();
      getText(oHtmlBuff);
      Parser oPrsr = Parser.createParser(oHtmlBuff.toString(), getEncoding());
      StringBean oStrBn = new StringBean();
      try {
        oPrsr.visitAllNodesWith (oStrBn);
      } catch (ParserException pe) {
        throw new MessagingException(pe.getMessage(), pe);
      }
      // Code for HTML parser 1.4
      // oStrBn.setInputHTML(oHtmlBuff.toString());
      oBuffer.append(oStrBn.getStrings());
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Multipart = DBMimeMessage.getParts()");

      Multipart oParts = getParts();

      final int iParts = oParts.getCount();

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iParts)+" parts found");
      
      MimePart oPart;

      int p;
      for (p=0; p<iParts && !bHasPlainTextVersion; p++) {
        oPart = (MimePart) oParts.getBodyPart(p);

        String sType = oPart.getContentType();
        if (null!=sType) sType=sType.toLowerCase();
        String sDisp = oPart.getDisposition();
        if (null==sDisp) sDisp="inline"; else if (sDisp.length()==0) sDisp="inline";

        if (DebugFile.trace) DebugFile.writeln("scanning part " + String.valueOf(p) + sDisp + " " + sType.replace('\r',' ').replace('\n', ' '));

        if (sType.startsWith("text/plain") && sDisp.equalsIgnoreCase("inline")) {
          bHasPlainTextVersion = true;
          DBMimePart.parseMimePart (oBuffer, null,
                                    getFolder().getName(),
                                    getMessageID()!=null ? getMessageID() : getContentID(),
                                    oPart, p);
        }
      }

      if (DebugFile.trace) {
        if (bHasPlainTextVersion)
          DebugFile.writeln("MimeMultipart has plain text version at part " + String.valueOf(p));
        else
          DebugFile.writeln("MimeMultipart has no plain text version, converting part 0 from HTML");
      }

      if (!bHasPlainTextVersion) {
        oPart = (MimePart) oParts.getBodyPart(0);
        StringBuffer oHtml = new StringBuffer();
        DBMimePart.parseMimePart (oHtml, null, getFolder().getName(), getMessageID()!=null ? getMessageID() : getContentID(), oPart, 0);

        Parser oPrsr = Parser.createParser(oHtml.toString(), getEncoding());
        StringBean oStrBn = new StringBean();

        try {
          oPrsr.visitAllNodesWith (oStrBn);
        } catch (ParserException pe) {
          throw new MessagingException(pe.getMessage(), pe);
        }

        // Code for HTML parser 1.4
        // oSB.setInputHTML(oHtml.toString());

        String sStrs = oStrBn.getStrings();

        if (DebugFile.trace) {
          DebugFile.writeln("StringBean.getStrings(");
          if (null!=sStrs) DebugFile.write(sStrs); else DebugFile.write("null");
          DebugFile.writeln(")");
        }
        oBuffer.append(sStrs);
      } // fi (!bHasPlainTextVersion)
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.getTextPlain() : " + String.valueOf(oBuffer.length()));
    }
  }

  // ---------------------------------------------------------------------------

  public void writeTo (OutputStream oOutStrm)
    throws IOException, FolderClosedException, MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.writeTo([OutputStream])");
      DebugFile.incIdent();
    }

    if (getFolder()==null) {
      DebugFile.decIdent();
      throw new MessagingException("No folder for message");
    }

    DBFolder oDBF = (DBFolder) getFolder();

    if ((oDBF.getType()&DBFolder.MODE_MBOX)!=0) {
      try {
        if (oDBF.getConnection()==null) {
          if (DebugFile.trace) DebugFile.decIdent();
          throw new FolderClosedException(oDBF, "Folder is closed");
        }
      } catch (SQLException sqle) {
      	throw new MessagingException(sqle.getMessage(), sqle);
      }

      PreparedStatement oStmt = null;
      ResultSet oRSet = null;
      BigDecimal oPos = null;
      int iLen = 0;

      try {
          oStmt = oDBF.getConnection().prepareStatement("SELECT " + DB.nu_position + "," + DB .len_mimemsg + " FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_mimemsg + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, getMessageGuid());
          oRSet = oStmt.executeQuery();
          boolean bFound = oRSet.next();
          if (bFound) {
            oPos = oRSet.getBigDecimal(1);
            iLen = oRSet.getInt(2);
          }
          oRSet.close();
          oRSet=null;
          oStmt.close();
          oStmt=null;

          if (!bFound) {
            if (DebugFile.trace) DebugFile.writeln("MimeMessage.writeTo(" + oOutStrm.getClass().getName() + ")");
            super.writeTo(oOutStrm);
            if (DebugFile.trace)  {
              DebugFile.decIdent();
              DebugFile.writeln("End DBMimeMessage.writeTo()");
            }
            return;
          } // fi (!bFound)
      }
      catch (SQLException sqle) {
        if (oRSet!=null) { try {oRSet.close();} catch (Exception ignore) {} }
        if (oStmt!=null) { try {oStmt.close();} catch (Exception ignore) {} }
      }

      File oFile = oDBF.getFile();
      MboxFile oMBox = new MboxFile(oFile, MboxFile.READ_ONLY);

      InputStream oInStrm = oMBox.getMessageAsStream(oPos.longValue(), iLen);
      StreamPipe oPipe = new StreamPipe();
      oPipe.between(oInStrm, oOutStrm);
      oInStrm.close();
      oMBox.close();
    }
    else {
      Multipart oDBParts = getParts();
      MimeMultipart oMimeParts = new MimeMultipart();

      for (int p=0;p<oDBParts.getCount(); p++) {
        oMimeParts.addBodyPart(oDBParts.getBodyPart(p));
        super.setContent(oMimeParts);
      }
      super.writeTo(oOutStrm);
    }
    if (DebugFile.trace)  {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.writeTo()");
    }
  }

  // ----------------------------------------------------------------------------------------

  public String tagBodyHtml()
    throws java.io.IOException, javax.mail.MessagingException {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.debug.DebugFile.writeln("Begin DBMimeMessage.tagBodyHtml()");
      com.knowgate.debug.DebugFile.incIdent();
    }

    StringBuffer oText = new StringBuffer();

    oText.append("<P><BR>------------------------------------------------------------<BR>");

    com.knowgate.hipermail.DBInetAddr oAddr;

    oAddr = (DBInetAddr) this.getFromRecipient();
    oText.append("<B>From:</B>&nbsp;<A HREF=\"mailto:"+oAddr.getAddress()+"\">&lt;");
    if (oAddr.getPersonal()!=null)
      oText.append(oAddr.getPersonal());
    else
      oText.append(oAddr.getAddress());
    oText.append("&gt;</A><BR>");

    aAddrs = this.getRecipients(Message.RecipientType.TO);
    if (aAddrs!=null) {
      if (aAddrs.length>0) {
        oText.append("<B>To:</B>&nbsp;");
        for (int a=0; a<aAddrs.length; a++) {
          oAddr = (DBInetAddr) aAddrs[a];
            oText.append("&lt;<A HREF=\"mailto:"+oAddr.getAddress()+"\">");
            if (oAddr.getPersonal()!=null)
              oText.append(oAddr.getPersonal());
            else
              oText.append(oAddr.getAddress());
            oText.append("</A>&gt;; ");
        } // next
        oText.append("<BR>");
      }
    } // fi (aAddrs.TO)

    aAddrs = this.getRecipients(Message.RecipientType.CC);
    if (aAddrs!=null) {
      if (aAddrs.length>0) {
        oText.append("<B>CC:</B>&nbsp;");
        for (int a=0; a<aAddrs.length; a++) {
          oAddr = (DBInetAddr) aAddrs[a];
            oText.append("&lt;<A HREF=\"mailto:"+oAddr.getAddress()+"\">");
            if (oAddr.getPersonal()!=null)
              oText.append(oAddr.getPersonal());
            else
              oText.append(oAddr.getAddress());
            oText.append("</A>&gt;; ");
        } // next
        oText.append("<BR>");
      }
    } // fi (aAddrs.CC)

    aAddrs = this.getRecipients(Message.RecipientType.BCC);
    if (aAddrs!=null) {
      if (aAddrs.length>0) {
        oText.append("<B>BCC:</B>&nbsp;");
        for (int a=0; a<aAddrs.length; a++) {
          oAddr = (DBInetAddr) aAddrs[a];
            oText.append("&lt;<A HREF=\"mailto:"+oAddr.getAddress()+"\">");
            if (oAddr.getPersonal()!=null)
              oText.append(oAddr.getPersonal());
            else
              oText.append(oAddr.getAddress());
            oText.append("</A>&gt;; ");
        } // next
        oText.append("<BR>");
      }
    } // fi (aAddrs.CCO)

   aAddrs = null;

    Date dtSent = this.getSentDate();
    if (dtSent!=null) {
      SimpleDateFormat dtFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

      oText.append("<B>Sent:</B>&nbsp;"+dtFmt.format(dtSent)+"<BR>");
    }

    oText.append("</P><BR>");

    getTextPlain(oText);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.tagBodyHtml()");
    }

    return oText.toString();
  } // tagBodyHtml

  // ----------------------------------------------------------------------------------------

  public String tagBodyPlain()
    throws java.io.IOException, javax.mail.MessagingException {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.debug.DebugFile.writeln("Begin DBMimeMessage.tagBodyPlain()");
      com.knowgate.debug.DebugFile.incIdent();
    }

    StringBuffer oText = new StringBuffer();

    oText.append("\n------------------------------------------------------------\n");

    com.knowgate.hipermail.DBInetAddr oAddr;

    oAddr = (DBInetAddr) this.getFromRecipient();
    oText.append("From: "+oAddr.getAddress());

    javax.mail.Address[] aAddrs;

    aAddrs = this.getRecipients(MimeMessage.RecipientType.TO);
    if (aAddrs!=null) {
      if (aAddrs.length>0) {
        oText.append("To: ");
        for (int a=0; a<aAddrs.length; a++) {
          oAddr = (DBInetAddr) aAddrs[a];
          oText.append(oAddr.getAddress());
        } // next
        oText.append("\n");
      }
    } // fi (aAddrs.TO)

    aAddrs = this.getRecipients(MimeMessage.RecipientType.CC);
    if (aAddrs!=null) {
      if (aAddrs.length>0) {
        oText.append("CC: ");
        for (int a=0; a<aAddrs.length; a++) {
          oAddr = (DBInetAddr) aAddrs[a];
          oText.append(oAddr.getAddress());
        } // next
        oText.append("\n");
      }
    } // fi (aAddrs.CC)

    aAddrs = this.getRecipients(MimeMessage.RecipientType.BCC);
    if (aAddrs!=null) {
      if (aAddrs.length>0) {
        oText.append("BCC: ");
        for (int a=0; a<aAddrs.length; a++) {
          oAddr = (DBInetAddr) aAddrs[a];
          oText.append(oAddr.getAddress());
        } // next
        oText.append("\n");
      }
    } // fi (aAddrs.CCO)

    java.util.Date dtSent = this.getSentDate();
    if (dtSent!=null) {
      java.text.SimpleDateFormat dtFmt = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

      oText.append("Sent: "+dtFmt.format(dtSent)+"\n");
    }

    oText.append("\n\n");

    this.getTextPlain(oText);

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.debug.DebugFile.decIdent();
      com.knowgate.debug.DebugFile.writeln("End DBMimeMessage.tagBodyPlain()");
    }

    return oText.toString();
  } // tagBodyPlain

  /**
   * <p>Create an SMTPMessage object from given components</p>
   * Depending on what is inside, message structure is as follows :<br>
   * <table>
   * <tr><td><b>Format/Attachments</b></td><td><b>No</b></td><td><b>Yes</b></td></tr>
   * <tr><td><b>plain</b></td><td><b>text/plain</b></td><td><b>multipart/mixed [text/plain, {attachment}]</b></td></tr>
   * <tr><td><b>html without images</b></td><td><b>multipart/alternative [text/plain, text/html]</b></td><td><b>multipart/mixed [multipart/alternative [text/plain, text/html], {attachment}]</b></td></tr>
   * <tr><td><b>html with images</b></td><td><b>multipart/alternative [text/plain, multipart/related[text/html, {image}]]</b></td><td><b>multipart/mixed [multipart/alternative [text/plain, multipart/related[text/html, {image}]], {attachment}]</b></td></tr>
   * </table>
   * @param oMailSession Session
   * @param sSubject String Message subject or <b>null</b>
   * @param sBody String Message text body or <b>null</b>
   * @param sId String Contend-ID for message or <b>null</b>
   * @param sContentType String should be either "plain" or "html"
   * @param sEncoding Character encoding for text
   * @return SMTPMessage
   * @throws IOException
   * @throws MessagingException
   * @throws SecurityException
   * @throws ArrayIndexOutOfBoundsException
   * @throws IllegalArgumentException if sContentType is not "plain" or "html"
   */
  public SMTPMessage composeFinalMessage(Session oMailSession, String sSubject, String sBody,
                                         String sId, String sContentType, String sEncoding,
                                         boolean bAttachInlineImages)
    throws IOException,MessagingException,IllegalArgumentException,
    	   ArrayIndexOutOfBoundsException,SecurityException {

    int iWebBeaconStart, iWebBeaconEnd, iSrcTagStart, iSrcTagEnd;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMessage.composeFinalMessage([Session],"+sSubject+",...,"+sId+","+sContentType+","+sEncoding+")");
    }

    if (!"html".equalsIgnoreCase(sContentType) && !"plain".equalsIgnoreCase(sContentType))
      throw new IllegalArgumentException("Content Type must be either plain or html but it is "+sContentType);

    if (DebugFile.trace) DebugFile.incIdent();

    // If message has no body then send it always as plain text even if marked as HTML
    if (null==sBody) {
      sBody = "";
      sContentType = "plain";
    } else if (sBody.length()==0) {
      sContentType = "plain";

    }

	if (sEncoding==null) sEncoding="ASCII";

    SMTPMessage oSentMessage = new SMTPMessage(oMailSession);

    Multipart oDraftParts = getParts();
    final int iDraftParts = oDraftParts.getCount();

    if (DebugFile.trace) DebugFile.writeln("Multipart.getCount() = " + String.valueOf(iDraftParts));

    MimeBodyPart oMsgPlainText = new MimeBodyPart();
    MimeMultipart oSentMsgParts = new MimeMultipart("mixed");

    if (sContentType.equalsIgnoreCase("html")) {

      MimeMultipart oHtmlRelated  = new MimeMultipart("related");
      MimeMultipart oTextHtmlAlt  = new MimeMultipart("alternative");

      // ************************************************************************
      // Replace image CIDs

      String sSrc, sCid, sText = "";

      Parser oPrsr = Parser.createParser(sBody, getEncoding());

      // String sCid, sSrc;

      HtmlMimeBodyPart oHtmBdy = new HtmlMimeBodyPart(sBody, getEncoding());

      try {

        // ****************************
        // Extract plain text from HTML
        if (DebugFile.trace) DebugFile.writeln("new StringBean()");

        StringBean oStrBn = new StringBean();

        try {
          oPrsr.visitAllNodesWith (oStrBn);
        } catch (ParserException pe) {
          if (DebugFile.trace) {
            DebugFile.writeln("org.htmlparser.util.ParserException " + pe.getMessage());
          }
          throw new MessagingException(pe.getMessage(), pe);
        }

        sText = oStrBn.getStrings();

        oStrBn = null;

        // *******************************
        // Set plain text alternative part

        oMsgPlainText.setDisposition("inline");
        oMsgPlainText.setText(sText,Charset.forName(sEncoding).name(),"plain");
        if (DebugFile.trace) DebugFile.writeln("MimeBodyPart(multipart/alternative).addBodyPart(text/plain)");
        oTextHtmlAlt.addBodyPart(oMsgPlainText);

        // *****************************************
        // Iterate images from HTML and replace CIDs

		if (bAttachInlineImages && sBody.length()>0) {
		  sBody = oHtmBdy.addPreffixToImgSrc("cid:");          
		} // fi (bAttachInlineImages)
      }
      catch (ParserException pe) {
        if (DebugFile.trace) {
          DebugFile.writeln("org.htmlparser.util.ParserException " + pe.getMessage());
        }
        throw new MessagingException(pe.getMessage(), pe);
      }
      // End replace image CIDs
      // ************************************************************************


      // ************************************************************************
      // Some defensive programming: ensure that all src="..." attributes point
      // either to an absolute http:// URL or to a cid:

      oHtmBdy.setHtml (sBody);
      ArrayList<String> aLocalUrls = oHtmBdy.extractLocalUrls();
      if (aLocalUrls.size()>0) {
        if (DebugFile.trace) {
          DebugFile.writeln("HTML body part contains local references to external resources");
          for (String i : aLocalUrls) {
            DebugFile.writeln(i);
          }
          DebugFile.write(sBody+"\n");
        }
      	throw new MessagingException("HTML body part "+(sId==null ? "" : "of message"+sId)+" contains local references to external resources such as "+aLocalUrls.get(0));
      } // aLocalUrls != {}
      
      // ************************************************************************
      // Add HTML related images

      if (oHtmBdy.getImagesCids().isEmpty()) {
          // Set HTML part
          MimeBodyPart oMsgHtml = new MimeBodyPart();
          oMsgHtml.setDisposition("inline");

          // ****************************************************************************
          // Replace <!--WEBBEACON SRC="http://..."--> tag by an <IMG SRC="http://..." />

	      try {
            iWebBeaconStart = Gadgets.indexOfIgnoreCase(sBody,"<!--WEBBEACON", 0);
            if (iWebBeaconStart>0) {
              iSrcTagStart = sBody.indexOf('"', iWebBeaconStart+13);
              iSrcTagEnd = sBody.indexOf('"', iSrcTagStart+1);
              iWebBeaconEnd = sBody.indexOf("-->", iWebBeaconStart+13);
              if (iWebBeaconEnd>0) {
		        sBody = sBody.substring(0,iWebBeaconStart)+"<IMG SRC=\""+sBody.substring(iSrcTagStart+1,iSrcTagEnd)+"\" WIDTH=\"1\" HEIGHT=\"1\" BORDER=\"0\" ALT=\"\" />"+sBody.substring(iWebBeaconEnd+3);
              }
            }
	      } catch (Exception malformedwebbeacon) {
	  	    if (DebugFile.trace) DebugFile.writeln("Malformed Web Beacon");
	      } 
          
          oMsgHtml.setText(sBody,Charset.forName(sEncoding).name(),"html");
          oTextHtmlAlt.addBodyPart(oMsgHtml);
          
      } else {

        // Set HTML text related part

        MimeBodyPart oMsgHtmlText = new MimeBodyPart();
        oMsgHtmlText.setDisposition("inline");

        // ****************************************************************************
        // Replace <!--WEBBEACON SRC="http://..."--> tag by an <IMG SRC="http://..." />
          
        try {
          iWebBeaconStart = Gadgets.indexOfIgnoreCase(sBody,"<!--WEBBEACON", 0);
          if (iWebBeaconStart>0) {
            iSrcTagStart = sBody.indexOf('"', iWebBeaconStart+13);
            iSrcTagEnd = sBody.indexOf('"', iSrcTagStart+1);
            iWebBeaconEnd = sBody.indexOf("-->", iWebBeaconStart+13);
            if (iWebBeaconEnd>0) {
		        sBody = sBody.substring(0,iWebBeaconStart)+"<IMG SRC=\""+sBody.substring(iSrcTagStart+1,iSrcTagEnd)+"\" WIDTH=\"1\" HEIGHT=\"1\" BORDER=\"0\" ALT=\"\" />"+sBody.substring(iWebBeaconEnd+3);
            }
          }
	    } catch (Exception malformedwebbeacon) {
	  	    if (DebugFile.trace) DebugFile.writeln("Malformed Web Beacon");
	    } 
        
        oMsgHtmlText.setText(sBody,Charset.forName(sEncoding).name(),"html");
        if (DebugFile.trace) DebugFile.writeln("MimeBodyPart(multipart/related).addBodyPart(text/html)");
        oHtmlRelated.addBodyPart(oMsgHtmlText);

        // Set HTML text related inline images

        Iterator oImgs = oHtmBdy.getImagesCids().keySet().iterator();

        while (oImgs.hasNext()) {
          BodyPart oImgBodyPart = new MimeBodyPart();

          sSrc = (String) oImgs.next();
          sCid = (String) oHtmBdy.getImagesCids().get(sSrc);

          if (sSrc.startsWith("www."))
            sSrc = "http://" + sSrc;

          if (sSrc.startsWith("http://") || sSrc.startsWith("https://")) {
            oImgBodyPart.setDataHandler(new DataHandler(new URL(Hosts.resolve(sSrc))));
          }
          else {
            oImgBodyPart.setDataHandler(new DataHandler(new FileDataSource(sSrc)));
          }
		  
		  if (sSrc.endsWith(".png")) oImgBodyPart.setHeader("Content-Type", "image/png;name="+sCid);
          oImgBodyPart.setDisposition("inline");
          oImgBodyPart.setHeader("Content-ID", sCid);
          oImgBodyPart.setFileName(sCid);

          // Add image to multi-part
          if (DebugFile.trace) DebugFile.writeln("MimeBodyPart(multipart/related).addBodyPart("+sCid+")");
          oHtmlRelated.addBodyPart(oImgBodyPart);
        } // wend

        // Set html text alternative part (html text + inline images)
        MimeBodyPart oTextHtmlRelated = new MimeBodyPart();
        oTextHtmlRelated.setContent(oHtmlRelated);
        if (DebugFile.trace) DebugFile.writeln("MimeBodyPart(multipart/alternative).addBodyPart(multipart/related)");
        oTextHtmlAlt.addBodyPart(oTextHtmlRelated);
      }

      // ************************************************************************
      // Create message to be sent and add main text body to it

      if (0==iDraftParts) {
        oSentMessage.setContent(oTextHtmlAlt);
      } else {
        MimeBodyPart oMixedPart = new MimeBodyPart();
        oMixedPart.setContent(oTextHtmlAlt);
        oSentMsgParts.addBodyPart(oMixedPart);
      }

    } else { // (sContentType=="plain")

      // *************************************************
      // If this is a plain text message just add the text

      if (0==iDraftParts) {
        oSentMessage.setText(sBody, Charset.forName(sEncoding).name(), "plain");
      } else {
        oMsgPlainText.setDisposition("inline");
        oMsgPlainText.setText(sBody,Charset.forName(sEncoding).name(),"plain");
        if (DebugFile.trace) DebugFile.writeln("MimeBodyPart(multipart/mixed).addBodyPart(text/plain)");
        oSentMsgParts.addBodyPart(oMsgPlainText);
      }
    }
    // fi (sContentType=="html")

    // ************************************************************************
    // Add attachments to message to be sent

    if (iDraftParts>0) {

      for (int p=0; p<iDraftParts; p++) {
        DBMimePart oPart = (DBMimePart) oDraftParts.getBodyPart(p);

        String sDisposition = oPart.getDisposition();
        if (sDisposition==null)
          sDisposition = "inline";
        else if (sDisposition.equals("reference") || sDisposition.equals("pointer"))
          sDisposition = "attachment";

        int iSize = oPart.getSize();
        if (iSize<=0) iSize = 4000;
        InputStream oInStrm = oPart.getInputStream();
        ByteArrayOutputStream oByStrm = new java.io.ByteArrayOutputStream(iSize);
        new StreamPipe().between(oInStrm, oByStrm);
        oInStrm.close();

        if (DebugFile.trace) DebugFile.writeln("part " + String.valueOf(p) + " size is " + String.valueOf(oByStrm.size()));

        ByteArrayDataSource oDataSrc = new ByteArrayDataSource(oByStrm.toByteArray(), oPart.getContentType());
        MimeBodyPart oAttachment = new MimeBodyPart();
        oAttachment.setDisposition(sDisposition);
        if (sDisposition.equals("attachment"))
        if (null==oPart.getDescription())
          oAttachment.setFileName(oPart.getFileName());
        else
          oAttachment.setFileName(oPart.getDescription());
        oAttachment.setHeader("Content-Transfer-Encoding", "base64");
        oAttachment.setDataHandler(new DataHandler(oDataSrc));
        oSentMsgParts.addBodyPart(oAttachment);
      } // next
      oSentMessage.setContent(oSentMsgParts);
    } // fi (iDraftParts>0)

    if (null!=sSubject) oSentMessage.setSubject(sSubject);

    if (sId!=null)
      if (sId.trim().length()>0)
        oSentMessage.setContentID(sId);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMessage.composeFinalMessage()");
    }

    return oSentMessage;
  } // composeFinalMessage

  // ---------------------------------------------------------------------------

  /**
   * <p>Create an SMTPMessage object from given components</p>
   * Depending on what is inside, message structure is as follows :<br>
   * <table>
   * <tr><td><b>Format/Attachments</b></td><td><b>No</b></td><td><b>Yes</b></td></tr>
   * <tr><td><b>plain</b></td><td><b>text/plain</b></td><td><b>multipart/mixed [text/plain, {attachment}]</b></td></tr>
   * <tr><td><b>html without images</b></td><td><b>multipart/alternative [text/plain, text/html]</b></td><td><b>multipart/mixed [multipart/alternative [text/plain, text/html], {attachment}]</b></td></tr>
   * <tr><td><b>html with images</b></td><td><b>multipart/alternative [text/plain, multipart/related[text/html, {image}]]</b></td><td><b>multipart/mixed [multipart/alternative [text/plain, multipart/related[text/html, {image}]], {attachment}]</b></td></tr>
   * </table>
   * @param oMailSession Session
   * @param sSubject String Message subject or <b>null</b>
   * @param sBody String Message text body or <b>null</b>
   * @param sId String Contend-ID for message or <b>null</b>
   * @param sContentType String should be either "plain" or "html"
   * @param sEncoding Character encoding for text
   * @return SMTPMessage
   * @throws IOException
   * @throws MessagingException
   * @throws SecurityException
   * @throws IllegalArgumentException if sContentType is not "plain" or "html"
   */
  public SMTPMessage composeFinalMessage(Session oMailSession, String sSubject, String sBody,
                                         String sId, String sContentType, String sEncoding)
    throws IOException,MessagingException,IllegalArgumentException,SecurityException {
    return composeFinalMessage(oMailSession, sSubject, sBody, sId, sContentType, sEncoding, true);
  }

  /**
   * <p>Create an SMTPMessage object from given components using UTF-8 for text encoding</p>
   * Depending on what is inside, message structure is as follows :<br>
   * <table>
   * <tr><td><b>Format/Attachments</b></td><td><b>No</b></td><td><b>Yes</b></td></tr>
   * <tr><td><b>plain</b></td><td><b>text/plain</b></td><td><b>multipart/mixed [text/plain, {attachment}]</b></td></tr>
   * <tr><td><b>html without images</b></td><td><b>multipart/alternative [text/plain, text/html]</b></td><td><b>multipart/mixed [multipart/alternative [text/plain, text/html], {attachment}]</b></td></tr>
   * <tr><td><b>html with images</b></td><td><b>multipart/alternative [text/plain, multipart/related[text/html, {image}]]</b></td><td><b>multipart/mixed [multipart/alternative [text/plain, multipart/related[text/html, {image}]], {attachment}]</b></td></tr>
   * </table>
   * @param oMailSession Session
   * @param sSubject String Message subject or <b>null</b>
   * @param sBody String Message text body or <b>null</b>
   * @param sId String Contend-ID for message or <b>null</b>
   * @param sContentType String should be either "plain" or "html"
   * @return SMTPMessage
   * @throws IOException
   * @throws MessagingException
   * @throws SecurityException
   * @throws IllegalArgumentException if sContentType is not "plain" or "html"
   */
  public SMTPMessage composeFinalMessage(Session oMailSession, String sSubject, String sBody,
                                         String sId, String sContentType)
    throws IOException,MessagingException,IllegalArgumentException,SecurityException {
    return composeFinalMessage(oMailSession, sSubject, sBody, sId, sContentType, "utf-8", true);
  }
  
  // ---------------------------------------------------------------------------

  /**
     * <p>Delete message from database</p>
     * This method calls stored procedure k_sp_del_mime_msg<br>
     * @param oConn JDBC database connection
     * @param sFolderId Folder GUID (k_mime_msgs.gu_category)
     * @param sMimeMsgId Message GUID (k_mime_msgs.gu_mimemsg)
     * @throws SQLException
  */

  public static void delete (JDCConnection oConn, String sFolderId, String sMimeMsgId)
      throws SQLException,IOException {
      Statement oStmt;
      CallableStatement oCall;

      if (DebugFile.trace) {
        DebugFile.writeln("Begin DBMimeMessage.delete([Connection], "+sMimeMsgId+")");
        DebugFile.incIdent();
      }

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      ResultSet oRSet = oStmt.executeQuery("SELECT " + DB.file_name + " FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='"+sMimeMsgId+"' AND " + DB.id_disposition + "='reference'");

      while (oRSet.next()) {
        String sFileName = oRSet.getString(1);
        if (!oRSet.wasNull()) {
          try {
            File oRef = new File(sFileName);
            oRef.delete();
          }
          catch (SecurityException se) {
            if (DebugFile.trace) DebugFile.writeln("SecurityException " + sFileName + " " + se.getMessage());
          }
        }
      } // wend

      oRSet.close();
      oRSet = null;
      oStmt.close();
      oStmt = null;

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oStmt = oConn.createStatement();
        oStmt.executeQuery("SELECT k_sp_del_mime_msg('" + sMimeMsgId + "')");
        oStmt.close();
      }
      else {
        oCall = oConn.prepareCall("{ call k_sp_del_mime_msg(?) }");
        oCall.setString(1, sMimeMsgId);
        oCall.execute();
        oCall.close();
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DBMimeMessage.delete()");
      }
  } // delete

  // ---------------------------------------------------------------------------

  public static String source (MimeMessage oMsg, String sEncoding)
   throws MessagingException, UnsupportedEncodingException, IOException {

   if (DebugFile.trace) {
     DebugFile.writeln("Begin DBMimeMessage.source([MimeMessage], "+sEncoding+")");
     DebugFile.incIdent();
   }

   final int iSize = oMsg.getSize();
   if (DebugFile.trace) DebugFile.writeln("size="+String.valueOf(iSize));
   ByteArrayOutputStream byOutStrm = new ByteArrayOutputStream(iSize>0 ? iSize : 16000);
   oMsg.writeTo(byOutStrm);
   String sSrc = byOutStrm.toString(sEncoding);
   byOutStrm.close();

   if (DebugFile.trace) {
     DebugFile.decIdent();
     if (null==sSrc)
       DebugFile.writeln("End DBMimeMessage.source() : null");
     else
       DebugFile.writeln("End DBMimeMessage.source() : " + String.valueOf(sSrc.length()));
   }
   return sSrc;
  } // source

  // ---------------------------------------------------------------------------

  public static String getGuidFromId (JDCConnection oConn, String sMsgId)
    throws SQLException {
      String sMsgGuid;

      switch (oConn.getDataBaseProduct()) {
        case JDCConnection.DBMS_POSTGRESQL:
          PreparedStatement oStmt = oConn.prepareStatement("SELECT k_sp_get_mime_msg(?)");
          oStmt.setString(1, sMsgId);
          ResultSet oRSet = oStmt.executeQuery();
          oRSet.next();
          sMsgGuid = oRSet.getString(1);
          oRSet.close();
          oRSet = null;
          oStmt.close();
          oStmt = null;
          break;
        default:
          CallableStatement oCall = oConn.prepareCall("{ call k_sp_get_mime_msg(?,?) }");
          oCall.setString(1, sMsgId);
          oCall.registerOutParameter(2, Types.CHAR);
          oCall.execute();
          sMsgGuid = oCall.getString(2);
          if (sMsgGuid!=null) sMsgGuid = sMsgGuid.trim();
          oCall.close();
          oCall = null;
      }
      return sMsgGuid;
    }

  // ===========================================================================
   public static final short ClassId = 822;
}
