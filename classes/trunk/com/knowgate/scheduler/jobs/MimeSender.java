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

package com.knowgate.scheduler.jobs;

import java.io.IOException;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.util.Properties;

import javax.mail.Message;
import javax.mail.URLName;
import javax.mail.Folder;
import javax.mail.MessagingException;
import javax.mail.internet.InternetAddress;

import com.sun.mail.smtp.SMTPMessage;

import com.knowgate.debug.DebugFile;
import com.knowgate.acl.ACLUser;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataxslt.FastStreamReplacer;
import com.knowgate.hipermail.DBStore;
import com.knowgate.hipermail.DBFolder;
import com.knowgate.hipermail.DBInetAddr;
import com.knowgate.hipermail.DBMimeMessage;
import com.knowgate.hipermail.MailAccount;
import com.knowgate.hipermail.SessionHandler;
import com.knowgate.scheduler.Job;
import com.knowgate.scheduler.Atom;

/**
 * <p>Send mime mail message from the outbox of an account to a recipients list</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class MimeSender extends Job {

  private SessionHandler oHndlr;
  private DBStore oStor;
  private DBFolder oOutBox;
  private String sBody;
  private boolean bPersonalized;
  private DBMimeMessage oDraft;
  private Properties oHeaders;
  private InternetAddress[] aFrom;
  private InternetAddress[] aReply;

  public MimeSender() {
    sBody = null;
    oHndlr = null;
    oStor = null;
    oOutBox = null;
  }

  // ---------------------------------------------------------------------------

  private String personalizeBody(Atom oAtm) throws NullPointerException {
    JDCConnection oConn = null;
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    String sPersonalizedBody;
    String sNm, sSn, sSl, sCo, sEm;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.personalizeBody([Atom])");
      DebugFile.incIdent();
      DebugFile.writeln("gu_job="+oAtm.getStringNull(DB.gu_job,"null"));
      if (oAtm.isNull(DB.pg_atom)) {
        DebugFile.decIdent();
        throw new NullPointerException("MimeSender.personalizeBody() no Atom set");
      } else {
        DebugFile.writeln("pg_atom="+String.valueOf(oAtm.getInt(DB.pg_atom)));
      }
    }

    sEm = oAtm.getString(DB.tx_email);

    try {
      oConn = getDataBaseBind().getConnection("MimeSender");
      if (DebugFile.trace) {
        DebugFile.writeln("Connection.prepareStatement(SELECT "+DB.tx_name+","+DB.tx_surname+","+DB.tx_salutation+","+DB.nm_commercial+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+getStringNull(DB.gu_workarea,"null")+"' AND "+DB.tx_email+"='"+sEm+"')");
      }
      oStmt = oConn.prepareStatement("SELECT "+DB.tx_name+","+DB.tx_surname+","+DB.tx_salutation+","+DB.nm_commercial+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"='"+getString(DB.gu_workarea)+"' AND "+DB.tx_email+"=?",
                                     ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sEm);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        sNm = oRSet.getString(1); if (oRSet.wasNull()) sNm = "";
        sSn = oRSet.getString(2); if (oRSet.wasNull()) sSn = "";
        sSl = oRSet.getString(3); if (oRSet.wasNull()) sSl = "";
        sCo = oRSet.getString(4); if (oRSet.wasNull()) sCo = "";
      } else {
        sNm=sSn=sSl=sCo="";
      }
      oRSet.close();
      oRSet=null;
      oStmt.close();
      oStmt=null;
      FastStreamReplacer oRplcr = new FastStreamReplacer(sBody.length()+256);
      try {
        sPersonalizedBody = oRplcr.replace(sBody, FastStreamReplacer.createMap(
                             new String[]{"Data.Name","Data.Surname","Data.Salutation","Data.Legal_Name,Address.EMail",
                                          "Datos.Nombre","Datos.Apellidos","Datos.Saludo","Datos.Razon_Social","Direccion.EMail"},
                             new String[]{sNm,sSn,sSl,sCo,sEm,sNm,sSn,sSl,sCo,sEm}));
      } catch (IOException ioe) {
        if (DebugFile.trace) DebugFile.writeln("IOException " + ioe.getMessage() + " sending message "+getParameter("message") + " to " + sEm);
        log("IOException " + ioe.getMessage() + " sending message "+getParameter("message") + " to " + sEm);
        sPersonalizedBody = sBody;
      }
      oConn.close("MimeSender");
      oConn=null;
    } catch (SQLException sqle) {
      if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) {} }
      if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) {} }
      if (oConn!=null) { try { oConn.close(); } catch (Exception ignore) {} }
      if (DebugFile.trace) DebugFile.writeln("SQLException " + sqle.getMessage() + " sending message "+getParameter("message") + " to " + sEm);
      log("SQLException " + sqle.getMessage() + " sending message "+getParameter("message") + " to " + sEm);
      sPersonalizedBody = sBody;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimeSender.personalizeBody()");
    }
    return sPersonalizedBody;
  } // personalizeBody

  // ---------------------------------------------------------------------------

  private static int getDomainForWorkArea(JDCConnection oConn, String sWrkA)
    throws SQLException {
    int iDomainId = -1;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.getDomainForWorkArea([JDCConnection],"+sWrkA+")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT "+DB.id_domain+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sWrkA+"')");
    }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.id_domain+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"=?",
                              ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sWrkA);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next()) iDomainId = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimeSender.getDomainForWorkArea() : " +String.valueOf(iDomainId));
    }
    return iDomainId;
  } // getDomainForWorkArea

  // ---------------------------------------------------------------------------

  public void init(Atom oAtm)
    throws SQLException,MessagingException,NullPointerException {
      if (DebugFile.trace) {
        DebugFile.writeln("Begin MimeSender.init()");
        DebugFile.incIdent();
      }
      // If mail is personalized (contains {#...} tags) a special parameter must has been previously set
      bPersonalized = Boolean.getBoolean(getParameter("personalized"));
      if (DebugFile.trace) DebugFile.writeln("personalized="+getParameter("personalized"));
      JDCConnection oConn = null;
      PreparedStatement oStmt = null;
      PreparedStatement oUpdt = null;
      ResultSet oRSet = null;
      ACLUser oUser = new ACLUser();
      MailAccount oMacc = new MailAccount();
      if (DebugFile.trace) DebugFile.writeln("workarea="+getStringNull(DB.gu_workarea,"null"));
      String sWrkA = getString(DB.gu_workarea);
      int iDomainId=-1;
      try {
        if (DebugFile.trace) DebugFile.writeln("DBBind="+getDataBaseBind());
        // Get User, Account and Domain objects
        oConn = getDataBaseBind().getConnection("MimeSender");
        iDomainId = getDomainForWorkArea(oConn, sWrkA);
        if (!oUser.load(oConn, new Object[]{getStringNull(DB.gu_writer,null)})) oUser=null;
        if (!oMacc.load(oConn, new Object[]{getParameter("account")})) oMacc=null;
        // If message is personalized then fill data for each mail address
        if (bPersonalized) resolveAtomsEMails(oConn);
        oConn.close("MimeSender");
        oConn=null;
      } catch (SQLException sqle) {
        if (DebugFile.trace) DebugFile.writeln("MimeSender.process("+getStringNull(DB.gu_job,"null")+") " + sqle.getClass().getName() + " " + sqle.getMessage());
        if (oConn!=null) { try { oConn.close(); } catch (Exception ignore) {} }
        throw sqle;
      } catch (NullPointerException npe) {
        if (DebugFile.trace) DebugFile.writeln("MimeSender.process("+getStringNull(DB.gu_job,"null")+") " + npe.getClass().getName());
        if (oConn!=null) { try { oConn.close(); } catch (Exception ignore) {} }
        throw npe;
      }
      if (null==oUser) {
        if (DebugFile.trace) {
          DebugFile.decIdent();
          DebugFile.writeln("End MimeSender.init("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+") : abnormal process termination");
        }
        throw new NullPointerException("User "+getStringNull(DB.gu_writer,"null")+" not found");
      }
      if (null==oMacc) {
        if (DebugFile.trace) {
          DebugFile.decIdent();
          DebugFile.writeln("End MimeSender.init("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+") : abnormal process termination");
        }
        throw new NullPointerException("Mail Account "+getParameter("account")+" not found");
      }
      try {
        // Create mail session
        if (DebugFile.trace) DebugFile.writeln("new SessionHandler("+oMacc.getStringNull(DB.gu_account,"null")+")");
        oHndlr = new SessionHandler(oMacc);
        // Retrieve profile name to be used from a Job parameter
        // Profile is needed because it contains the path to /storage directory
        // which is used for composing the path to outbox mbox file containing
        // source of message to be sent
        String sProfile = getParameter("profile");
        String sMBoxDir = DBStore.MBoxDirectory(sProfile,iDomainId,sWrkA);
        oStor = new DBStore(oHndlr.getSession(), new URLName("jdbc://", sProfile, -1, sMBoxDir, oUser.getString(DB.gu_user), oUser.getString(DB.tx_pwd)));
        oStor.connect(sProfile, oUser.getString(DB.gu_user), oUser.getString(DB.tx_pwd));
        oOutBox = (DBFolder) oStor.getFolder("outbox");
        oOutBox.open(Folder.READ_WRITE);
        String sMsgId = getParameter("message");
        oDraft = oOutBox.getMessageByGuid(sMsgId);
        if (null==oDraft) throw new MessagingException("DBFolder.getMessageByGuid() Message "+sMsgId+" not found");
        oHeaders = oOutBox.getMessageHeaders(sMsgId);
        if (null==oHeaders) throw new MessagingException("DBFolder.getMessageHeaders() Message "+sMsgId+" not found");
        if (null==oHeaders.get(DB.nm_from))
          aFrom = new InternetAddress[]{new InternetAddress(oHeaders.getProperty(DB.tx_email_from))};
        else
          aFrom = new InternetAddress[]{new InternetAddress(oHeaders.getProperty(DB.tx_email_from),
                                                            oHeaders.getProperty(DB.nm_from))};
        if (null==oHeaders.get(DB.tx_reply_email))
          aReply = aFrom;
        else
          aReply = new InternetAddress[]{new InternetAddress(oHeaders.getProperty(DB.tx_reply_email))};
        sBody = oDraft.getText();
        if (DebugFile.trace) {
          if (null==sBody)
            DebugFile.writeln("Message body: null");
          else
            DebugFile.writeln("Message body: " + Gadgets.left(sBody.replace('\n',' '), 100));
        }
      } catch (Exception e) {
        if (DebugFile.trace) {
          DebugFile.decIdent();
          DebugFile.writeln("End MimeSender.init(" + oAtm.getString(DB.gu_job) + ":" + String.valueOf(oAtm.getInt(DB.pg_atom)) + ") : abnormal process termination");
        }
        if (null!=oOutBox) { try { oOutBox.close(false); oOutBox=null; } catch (Exception ignore) {} }
        if (null!=oStor) { try { oStor.close(); oStor=null; } catch (Exception ignore) {} }
        if (null!=oHndlr) { try { oHndlr.close(); oHndlr=null; } catch (Exception ignore) {} }
        throw new MessagingException(e.getMessage(),e);
      }
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End MimeSender.init()");
      }
  } // init

  // ---------------------------------------------------------------------------

  public void free() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.free()");
      DebugFile.incIdent();
      DebugFile.writeln("gu_job="+getStringNull(DB.gu_job,"null"));
    }
    oDraft=null;
    if (null!=oOutBox) { try { oOutBox.close(false); oOutBox=null; } catch (Exception ignore) {} }
    if (null!=oStor)   { try { oStor.close(); oStor=null; } catch (Exception ignore) {} }
    if (null!=oHndlr)  { try { oHndlr.close(); oHndlr=null; } catch (Exception ignore) {} }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimeSender.free()");
    }
  } // free

  // ---------------------------------------------------------------------------

  public Object process(Atom oAtm) throws SQLException, MessagingException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MimeSender.process("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+")");
      DebugFile.incIdent();
    }

    // ***************************************************
    // Create mail session if it does not previously exist

    if (oHndlr==null && iPendingAtoms>0) {
      init(oAtm);
    }

    if (null==oDraft) {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End MimeSender.process(" + oAtm.getString(DB.gu_job) + ":" + String.valueOf(oAtm.getInt(DB.pg_atom)) + ") : abnormal process termination");
      }
      throw new NullPointerException("Draft message "+getParameter("message")+" not found");
    }

    // ***********************************
    // Once session is created set message

    SMTPMessage oSentMsg;

    try {
      // Personalize mail if needed by replacing {#...} tags by values taken from Atom fields
      String sFormat = oAtm.getStringNull(DB.id_format,"plain").toLowerCase();
      if (sFormat.equals("text") || sFormat.equals("txt")) sFormat = "plain";
      if (sFormat.equals("htm")) sFormat = "html";

      if (bPersonalized)
        oSentMsg = oDraft.composeFinalMessage(oHndlr.getSession(), oDraft.getSubject(),
                                              personalizeBody(oAtm), getParameter("id"),
                                              sFormat);
      else
        oSentMsg = oDraft.composeFinalMessage(oHndlr.getSession(), oDraft.getSubject(),
                                              sBody, getParameter("id"),
                                              sFormat);

      // If there is no mail address at the atom then send message to recipients
      // that are already set into message object itself.
      // If there is a mail address at the atom then send message to that recipient
      if (!oAtm.isNull(DB.tx_email)) {
        if (DebugFile.trace) DebugFile.writeln("tx_email="+oAtm.getString(DB.tx_email));
        InternetAddress oRec = DBInetAddr.parseAddress(oAtm.getString(DB.tx_email));
        String sRecType = oAtm.getStringNull(DB.tp_recipient,"to");
        if (sRecType.equalsIgnoreCase("to"))
          oSentMsg.setRecipient(Message.RecipientType.TO, oRec);
        else if (sRecType.equalsIgnoreCase("cc"))
          oSentMsg.setRecipient(Message.RecipientType.CC, oRec);
        else
          oSentMsg.setRecipient(Message.RecipientType.BCC, oRec);
      } else {
        if (DebugFile.trace) DebugFile.writeln("tx_email is null");
      }

      // Set From and Reply-To addresses
      oSentMsg.addFrom(aFrom);
      oSentMsg.setReplyTo(aReply);

      // Send message here
      oHndlr.sendMessage(oSentMsg);

    } catch (Exception e) {
      if (DebugFile.trace) {
        DebugFile.writeStackTrace(e);
        DebugFile.write("\n");
        DebugFile.decIdent();
        DebugFile.writeln("End MimeSender.process("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+") : abnormal process termination");
      }
      throw new MessagingException(e.getMessage(),e);
    } finally {
      // Decrement de count of atoms pending of processing at this job
      if (0==--iPendingAtoms) {
        free();
      } // fi (iPendingAtoms==0)
    }

    if (DebugFile.trace) {
      DebugFile.writeln("End MimeSender.process("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+")");
      DebugFile.decIdent();
    }

    return null;
 } // process

 // ----------------------------------------------------------------------------

 public static MimeSender newInstance(JDCConnection oConn, String sProfile, String sIdWrkA,
                                      String sGuMsg, String sIdMsg,
                                      String sGuUser, String sGuAccount,
                                      boolean bIsPersonalizedMail,
                                      String sTxTitle)
   throws SQLException {
   MimeSender oJob = new MimeSender();

   if (DebugFile.trace) {
     DebugFile.writeln("Begin MimeSender.newInstance(JDCConnection, "+sProfile+", "+sIdWrkA+", "+sGuMsg+", "+sIdMsg+", "+sGuUser+", "+sGuAccount+", "+String.valueOf(bIsPersonalizedMail)+", "+sTxTitle+")");
     DebugFile.incIdent();
   }

   oJob.put(DB.gu_workarea, sIdWrkA);
   oJob.put(DB.gu_writer, sGuUser);
   oJob.put(DB.id_command, "SEND");
   oJob.put(DB.tl_job, Gadgets.left(sTxTitle,100));
   oJob.put(DB.tx_parameters, "profile:"+sProfile+
                              ",id:"+sIdMsg+
                              ",message:"+sGuMsg+
                              ",account:"+sGuAccount+
                              ",personalized:"+String.valueOf(bIsPersonalizedMail));
   oJob.store(oConn);

   if (DebugFile.trace) {
     DebugFile.writeln("End MimeSender.newInstance() " + oJob.getStringNull(DB.gu_job,"null"));
     DebugFile.decIdent();
   }

   return oJob;
 }

} // MimeSender
