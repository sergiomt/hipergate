/*
  Copyright (C) 2004-2008  Know Gate S.L. All rights reserved.
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

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.mail.MessagingException;
import javax.mail.Message.RecipientType;
import javax.mail.internet.MimeBodyPart;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;

/**
 * <p>Helper methods for composing new e-mails</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class DraftsHelper {
  public DraftsHelper() {
  }

  // ----------------------------------------------------------------------------------------

  public static DBMimeMessage draftMessage(DBFolder oDraftsFldr,
                                    String sMailHost, String sGuWorkArea,
                                    String sUserId, String sContentType)
    throws SQLException,MessagingException,IOException {

	int nAffected;
	
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DraftsHelper.draftMessage("+sMailHost+","+sGuWorkArea+","+sUserId+","+sContentType+")");
      DebugFile.incIdent();
    }

    JDCConnection oConn = oDraftsFldr.getConnection();

    java.sql.PreparedStatement oStmt;
    java.sql.ResultSet oRSet;

    com.knowgate.acl.ACLUser oUsr = new com.knowgate.acl.ACLUser();
    if (!oUsr.load(oConn, new Object[]{sUserId})) {
      
      if (DebugFile.trace) {
        DebugFile.writeln("ERROR: User "+sUserId+" not found");
        DebugFile.decIdent();
      }	  
	  throw new SQLException("DraftsHelper.draftMessage() User "+sUserId+" not found");
    } // fi

    String sGuMsg = Gadgets.generateUUID();
    String sGuFldr= oDraftsFldr.getCategoryGuid();
    String sFrom  = oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"");
    String sIdMsg = "<"+sGuMsg+"."+oUsr.getStringNull(DB.tx_nickname,"")+"@"+sMailHost+">";

    oConn.setAutoCommit(false);

    if (DebugFile.trace) {
      DebugFile.writeln("Creating message "+sGuMsg+" "+sIdMsg+" at folder "+oDraftsFldr.getName()+" "+sGuFldr);
      DebugFile.writeln("JDCConnection.prepareStatement(SELECT MAX("+DB.pg_message+") FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_category+"='"+sGuFldr+"')");
    }

    oStmt = oConn.prepareStatement("SELECT MAX("+DB.pg_message+") FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_category+"=?");
    oStmt.setString (1,sGuFldr);
    oRSet = oStmt.executeQuery();
    oRSet.next();
    java.math.BigDecimal oMax = oRSet.getBigDecimal(1);
    if (oRSet.wasNull()) oMax = new java.math.BigDecimal(0);
    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.writeln("JDCConnection.prepareStatement(INSERT INTO "+DB.k_mime_msgs+" ("+DB.gu_mimemsg+","+DB.pg_message+","+DB.gu_workarea+","+DB.gu_category+","+DB.id_type+","+DB.id_message+","+DB.tx_subject+","+DB.tx_email_from+","+DB.tx_email_reply+","+DB.nm_from+","+DB.len_mimemsg+","+DB.bo_draft+","+DB.bo_deleted+") VALUES('"+sGuMsg+"',"+oMax.add(new java.math.BigDecimal(1)).toString()+",'"+sGuWorkArea+"','"+sGuFldr+"','text/"+sContentType+"; charset=utf-8','"+sIdMsg+"','','"+oUsr.getString(DB.tx_main_email)+"','"+oUsr.getString(DB.tx_main_email)+"','"+sFrom.trim()+"',0,1,0))");
    }

    oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_mime_msgs+" ("+DB.gu_mimemsg+","+DB.pg_message+","+DB.gu_workarea+","+DB.gu_category+","+DB.id_type+","+DB.id_message+","+DB.tx_subject+","+DB.tx_email_from+","+DB.tx_email_reply+","+DB.nm_from+","+DB.len_mimemsg+","+DB.bo_draft+","+DB.bo_deleted+") VALUES(?,?,?,?,?,?,?,?,?,?,0,1,0)");
    oStmt.setString (1,sGuMsg);
    oStmt.setBigDecimal (2,oMax.add(new java.math.BigDecimal(1)));
    oStmt.setString (3,sGuWorkArea);
    oStmt.setString (4,sGuFldr);
    oStmt.setString (5,"text/"+sContentType+"; charset=utf-8");
    oStmt.setString (6,sIdMsg);
    oStmt.setString (7,"");
    oStmt.setString (8,oUsr.getString(DB.tx_main_email));
    oStmt.setString (9,oUsr.getString(DB.tx_main_email));
    oStmt.setString (10,sFrom.trim());

    if (DebugFile.trace) {
      DebugFile.writeln("JDCConnection.executeUpdate(INSERT INTO "+DB.k_mime_msgs+" ("+DB.gu_mimemsg+","+DB.pg_message+","+DB.gu_workarea+","+DB.gu_category+","+DB.id_type+","+DB.id_message+","+DB.tx_subject+","+DB.tx_email_from+","+DB.tx_email_reply+","+DB.nm_from+","+DB.len_mimemsg+","+DB.bo_draft+","+DB.bo_deleted+") VALUES('"+sGuMsg+"',?,'"+sGuWorkArea+"','"+sGuFldr+"','text/"+sContentType+"; charset=utf-8','"+sIdMsg+"','','"+oUsr.getString(DB.tx_main_email)+"','"+oUsr.getString(DB.tx_main_email)+"','"+sFrom.trim()+"',0,1,0))");
    }	  

    nAffected = oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.writeln(String.valueOf(nAffected)+" affected rows");
    }	  
				
    oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_inet_addrs+" ("+DB.gu_mimemsg+","+DB.id_message+","+DB.tx_email+","+DB.tp_recipient+","+DB.tx_personal+","+DB.gu_user+") VALUES (?,?,?,?,?,?)");
    oStmt.setString (1,sGuMsg);
    oStmt.setString (2,sIdMsg);
    oStmt.setString (3,oUsr.getString(DB.tx_main_email));
    oStmt.setString (4,"from");
    oStmt.setString (5,sFrom.trim());
    oStmt.setString (6,sUserId);

    if (DebugFile.trace) {
      DebugFile.writeln("JDCConnection.executeUpdate(INSERT INTO "+DB.k_inet_addrs+" ("+DB.gu_mimemsg+","+DB.id_message+","+DB.tx_email+","+DB.tp_recipient+","+DB.tx_personal+","+DB.gu_user+") VALUES ('"+sGuMsg+"','"+sIdMsg+"','"+oUsr.getString(DB.tx_main_email)+"','from','"+sFrom.trim()+"','"+sUserId+"'))");
    }

    nAffected = oStmt.executeUpdate();
    oStmt.close();

    if (DebugFile.trace) {
      DebugFile.writeln(String.valueOf(nAffected)+" affected rows");
    }	  

    if (!oConn.getAutoCommit()) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.commit()");
      oConn.commit();
    }

	DBMimeMessage oRetVal = oDraftsFldr.getMessageByGuid(sGuMsg);
    		
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DraftsHelper.draftMessage() : "+sGuMsg);
    }

    return oRetVal;

  } // draftMessage

  // ----------------------------------------------------------------------------------------

  public static DBMimeMessage draftMessageForReply(DBFolder oDraftsFldr,
                                            String sMailHost, String sGuWorkArea,
                                            String sUserId, DBFolder oOriginalFldr,
                                            String sGuOriginalMsg, boolean bReplyAll,
                                            String sContentType)
    throws SQLException,MessagingException,IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DraftsHelper.draftMessageForReply([DBStore],"+sMailHost+","+sGuWorkArea+","+sUserId+",[DBFolder],"+sGuOriginalMsg+")");
      DebugFile.incIdent();
    }

	String sSQL;
    PreparedStatement oStmt;

    JDCConnection oConn = oDraftsFldr.getConnection();

    DBMimeMessage oDraft = draftMessage(oDraftsFldr, sMailHost, sGuWorkArea, sUserId, sContentType);

    com.knowgate.acl.ACLUser oUsr = new com.knowgate.acl.ACLUser();
    oUsr.load(oConn, new Object[]{sUserId});

    String sIdMsg = "<"+oDraft.getMessageGuid()+"."+oUsr.getStringNull(DB.tx_nickname,"")+"@"+sMailHost+">";

    DBMimeMessage oOrMsg = new DBMimeMessage(oOriginalFldr, sGuOriginalMsg);
    DBInetAddr oFrom = (DBInetAddr) oOrMsg.getFromRecipient();

    String sText;
    if (sContentType.equals("html"))
      sText = oOrMsg.tagBodyHtml();
    else
      sText = oOrMsg.tagBodyPlain();

    MimeBodyPart oText = new MimeBodyPart();
    oText.setContent(sText, "text/html");
    java.io.ByteArrayOutputStream oBaStrm = new java.io.ByteArrayOutputStream(sText.length()*2+2);
    oText.writeTo(oBaStrm);

    oStmt = oConn.prepareStatement("UPDATE "+DB.k_mime_msgs+" SET "+DB.len_mimemsg+"=?"+","+DB.tx_subject+"=?,"+DB.by_content+"=? WHERE "+DB.gu_mimemsg+"=?");
    oStmt.setInt(1, oBaStrm.size());
    oStmt.setString(2, oOrMsg.getSubject());
    oStmt.setBinaryStream(3, new java.io.ByteArrayInputStream(oBaStrm.toByteArray()), oBaStrm.size());
    oStmt.setString(4, oDraft.getMessageGuid());
    oStmt.executeUpdate();
    oStmt.close();

	sSQL = "INSERT INTO "+DB.k_inet_addrs+" ("+DB.gu_mimemsg+","+DB.id_message+","+DB.tx_email+","+DB.tp_recipient+","+DB.tx_personal+","+DB.gu_user+","+DB.gu_contact+","+DB.gu_company+") (SELECT '"+oDraft.getMessageGuid()+"','"+sIdMsg+"',"+DB.tx_email+",'to',"+DB.tx_personal+","+DB.gu_user+","+DB.gu_contact+","+DB.gu_company+" FROM "+DB.k_inet_addrs+" WHERE "+DB.gu_mimemsg+"=? AND "+DB.tp_recipient+"='from')";

    if (DebugFile.trace) DebugFile.writeln("JDCConnection.prepareStatement("+sSQL+")");

    oStmt = oConn.prepareStatement(sSQL);
    oStmt.setString (1, sGuOriginalMsg );
    oStmt.executeUpdate();
    oStmt.close();
    
    if (oFrom!=null) {
      if (DebugFile.trace)
      	DebugFile.writeln("DBMimeMessage.addRecipient(RecipientType.TO, "+oFrom.getAddress()+")");
      oDraft.addRecipient(RecipientType.TO, oFrom);
    }

    if (bReplyAll) {
      sSQL = "INSERT INTO "+DB.k_inet_addrs+" ("+DB.gu_mimemsg+","+DB.id_message+","+DB.tx_email+","+DB.tp_recipient+","+DB.tx_personal+","+DB.gu_user+","+DB.gu_contact+","+DB.gu_company+") (SELECT '"+oDraft.getMessageGuid()+"','"+sIdMsg+"',"+DB.tx_email+",'to',"+DB.tx_personal+","+DB.gu_user+","+DB.gu_contact+","+DB.gu_company+" FROM "+DB.k_inet_addrs+" WHERE "+DB.gu_mimemsg+"=? AND "+DB.tp_recipient+"='to')";
      if (DebugFile.trace) DebugFile.writeln("JDCConnection.prepareStatement("+sSQL+")");
      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString (1,sGuOriginalMsg);
      oStmt.executeUpdate();
      oStmt.close();

      oDraft.addRecipients(RecipientType.TO, oOrMsg.getRecipients(RecipientType.TO));

	  sSQL = "INSERT INTO "+DB.k_inet_addrs+" ("+DB.gu_mimemsg+","+DB.id_message+","+DB.tx_email+","+DB.tp_recipient+","+DB.tx_personal+","+DB.gu_user+","+DB.gu_contact+","+DB.gu_company+") (SELECT '"+oDraft.getMessageGuid()+"','"+sIdMsg+"',"+DB.tx_email+",'cc',"+DB.tx_personal+","+DB.gu_user+","+DB.gu_contact+","+DB.gu_company+" FROM "+DB.k_inet_addrs+" WHERE "+DB.gu_mimemsg+"=? AND "+DB.tp_recipient+"='cc')";
      if (DebugFile.trace) DebugFile.writeln("JDCConnection.prepareStatement("+sSQL+")");
      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString (1,sGuOriginalMsg);
      oStmt.executeUpdate();
      oStmt.close();

      oDraft.addRecipients(RecipientType.CC, oOrMsg.getRecipients(RecipientType.CC));
    } // bReplyAll

    if (!oConn.getAutoCommit()) oConn.commit();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DraftsHelper.draftMessageForReply() : "+oDraft.getMessageGuid());
    }

    return oDraft;
  } // draftMessageForReply

  // ----------------------------------------------------------------------------------------

  public static DBMimeMessage draftMessageForForward(DBFolder oDraftsFldr,
                                              String sMailHost, String sGuWorkArea,
                                              String sUserId, DBFolder oOriginalFldr,
                                              String sGuOriginalMsg, String sContentType)
    throws SQLException,MessagingException,IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DraftsHelper.draftMessageForForward([DBStore],"+sMailHost+","+sGuWorkArea+","+sUserId+",[DBFolder],"+sGuOriginalMsg+","+sContentType+")");
      DebugFile.incIdent();
    }

    PreparedStatement oStmt;
    ResultSet oRSet;

    JDCConnection oConn = oDraftsFldr.getConnection();

    DBMimeMessage oDraft = draftMessage(oDraftsFldr, sMailHost, sGuWorkArea, sUserId, sContentType);

    // Compose message id by concatenating guid, user nickname and mail host
    com.knowgate.acl.ACLUser oUsr = new com.knowgate.acl.ACLUser();
    oUsr.load(oConn, new Object[]{sUserId});

    String sIdMsg = "<"+oDraft.getMessageGuid()+"."+oUsr.getStringNull(DB.tx_nickname,"")+"@"+sMailHost+">";

    DBMimeMessage oOrMsg = new DBMimeMessage(oOriginalFldr, sGuOriginalMsg);
    DBInetAddr oFrom = (DBInetAddr) oOrMsg.getFromRecipient();

    String sText;
    if (sContentType.equals("html"))
      sText = oOrMsg.tagBodyHtml();
    else
      sText = oOrMsg.tagBodyPlain();

    MimeBodyPart oText = new MimeBodyPart();
    oText.setContent(sText, "text/html");
    java.io.ByteArrayOutputStream oBaStrm = new java.io.ByteArrayOutputStream(sText.length()*2+2);
    oText.writeTo(oBaStrm);

    java.math.BigDecimal oPosition;
    oStmt = oConn.prepareStatement("SELECT "+DB.nu_position+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"=?");
    oStmt.setString(1, sGuOriginalMsg);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      oPosition = oRSet.getBigDecimal(1);
    else
      oPosition = null;
    oRSet.close();
    oRSet = null;
    oStmt.close();
    oStmt = null;

    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.debug.DebugFile.writeln("Connection.prepareStatement(UPDATE "+DB.k_mime_msgs+" SET "+DB.nu_position+"=?,"+DB.len_mimemsg+"=?"+","+DB.by_content+"=? WHERE "+DB.gu_mimemsg+"='"+oDraft.getMessageGuid()+"')");

    oStmt = oConn.prepareStatement("UPDATE "+DB.k_mime_msgs+" SET "+DB.nu_position+"=?,"+DB.len_mimemsg+"=?,"+DB.tx_subject+"=?,"+DB.by_content+"=? WHERE "+DB.gu_mimemsg+"=?");
    oStmt.setBigDecimal(1, oPosition);
    oStmt.setInt(2, oBaStrm.size());
    oStmt.setString(3, oOrMsg.getSubject());
    oStmt.setBinaryStream(4, new java.io.ByteArrayInputStream(oBaStrm.toByteArray()), oBaStrm.size());
    oStmt.setString(5, oDraft.getMessageGuid());
    oStmt.executeUpdate();
    oStmt.close();

    if (com.knowgate.debug.DebugFile.trace)
      com.knowgate.debug.DebugFile.writeln("Connection.prepareStatement(INSERT INTO "+DB.k_mime_parts+" ("+DB.gu_mimemsg+","+DB.id_message+","+DB.pg_message+","+DB.nu_offset+","+DB.id_part+","+DB.id_content+","+DB.id_type+","+DB.id_disposition+","+DB.id_encoding+","+DB.len_part+","+DB.de_part+","+DB.tx_md5+","+DB.file_name+","+DB.id_compression+","+DB.by_content+") (SELECT '"+oDraft.getMessageGuid()+"','"+sIdMsg+"',NULL,"+DB.nu_offset+","+DB.id_part+","+DB.id_content+","+DB.id_type+",'pointer',"+DB.id_encoding+","+DB.len_part+","+DB.file_name+","+DB.tx_md5+",'"+oOriginalFldr.getFilePath()+"',"+DB.id_compression+",NULL FROM "+DB.k_mime_parts+" WHERE "+DB.gu_mimemsg+"='"+sGuOriginalMsg+"'))");
    oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_mime_parts+" ("+DB.gu_mimemsg+","+DB.id_message+","+DB.pg_message+","+DB.nu_offset+","+DB.id_part+","+DB.id_content+","+DB.id_type+","+DB.id_disposition+","+DB.id_encoding+","+DB.len_part+","+DB.de_part+","+DB.tx_md5+","+DB.file_name+","+DB.id_compression+","+DB.by_content+") (SELECT '"+oDraft.getMessageGuid()+"','"+sIdMsg+"',NULL,"+DB.nu_offset+","+DB.id_part+","+DB.id_content+","+DB.id_type+",'pointer',"+DB.id_encoding+","+DB.len_part+","+DB.file_name+","+DB.tx_md5+",?,"+DB.id_compression+",NULL FROM "+DB.k_mime_parts+" WHERE "+DB.gu_mimemsg+"=? AND "+DB.id_disposition+"='attachment')");
    oStmt.setString (1,sGuOriginalMsg);
    oStmt.setString (2,oOriginalFldr.getFilePath());    	
    oStmt.executeUpdate();
    oStmt.close();

    if (!oConn.getAutoCommit()) oConn.commit();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DraftsHelper.draftMessageForForward() : "+oDraft.getMessageGuid());
    }

    return oDraft;
  } // draftMessageForForward

  // ----------------------------------------------------------------------------------------

  /**
   *
   * @param oConn JDCConnection
   * @param iIdDomain int
   * @param sGuWorkarea String
   * @param sGuMsg String
   * @param sIdMsg String
   * @param sTxMailFrom String
   * @param sTxMailReply String
   * @param sNmFrom String
   * @param sTxSubject String
   * @param sContentType String
   * @param sBody String
   * @param aTo String[]
   * @param aCc String[]
   * @param aBcc String[]
   * @throws NullPointerException if sBody is null
   * @throws UnsupportedDataTypeException
   * @throws SQLException
   * @throws MessagingException
   * @throws IOException
   */
  public static void draftUpdate(JDCConnection oConn,
                          int iIdDomain, String sGuWorkarea,
                          String sGuMsg, String sIdMsg,
                          String sTxMailFrom, String sTxMailReply, String sNmFrom,
                          String sTxSubject, String sContentType, String sBody,
                          String[] aTo, String[] aCc, String[] aBcc)
    throws SQLException, MessagingException, IOException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DraftsHelper.draftUpdate([JDCConnection],"+
                        String.valueOf(iIdDomain)+","+sGuWorkarea+","+
                        sGuMsg+","+sIdMsg+","+sTxMailFrom+","+sTxMailReply+","+
                        sNmFrom+","+sTxSubject+","+sContentType+","+
                        Gadgets.left(sBody,100)+", String[], String[], String[])");
      DebugFile.incIdent();
    }

	if (null==sBody) {
	  if (DebugFile.trace) {
	  	DebugFile.writeln("NullPointerException: Message body is null");
	  	DebugFile.decIdent();
	  }
	  throw new NullPointerException("DraftsHelper.draftUpdate() message body cannot be null");
	}

    String sAddr;
    String sSQL = "UPDATE "+DB.k_mime_msgs+" SET "+DB.bo_draft+"=1,"+
                  DB.tx_email_from+"=?,"+DB.tx_email_reply+"=?,"+DB.nm_from+"=?,"+
                  DB.tx_subject+"=?,"+DB.id_type+"=?,"+DB.len_mimemsg+"=?,"+DB.by_content+"=? "+
                  "WHERE "+DB.gu_mimemsg+"=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");

    PreparedStatement oStmt = oConn.prepareStatement(sSQL);

    oStmt.setString(1, sTxMailFrom);
    oStmt.setString(2, sTxMailReply);
    oStmt.setString(3, sNmFrom);
    oStmt.setString(4, sTxSubject);
    oStmt.setString(5, "text/"+sContentType);
    MimeBodyPart oBody = new MimeBodyPart();
    if (DebugFile.trace) DebugFile.writeln("MimeBodyPart.setContent(\""+Gadgets.left(sBody,255)+"\",\"text/"+sContentType+"\")");
    if (sContentType.toLowerCase().startsWith("text/"))
      oBody.setContent(sBody, sContentType);
    else
      oBody.setContent(sBody, "text/"+sContentType);
    ByteArrayOutputStream oBodyStrm = new ByteArrayOutputStream((sBody.length()*2)+2);
    oBody.writeTo(oBodyStrm);
    oStmt.setInt(6, oBodyStrm.size());
    oStmt.setBytes(7, oBodyStrm.toByteArray());    
    oStmt.setString(8, sGuMsg);
    if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");	
    oStmt.executeUpdate();
    oStmt.close();

    RecipientsHelper.clearRecipientsForMessage(oConn, sGuMsg);

    DBInetAddr.write(oConn, iIdDomain, sGuWorkarea, sGuMsg, sIdMsg, sTxMailFrom, "from", sNmFrom);

    if (aTo!=null) {
      if (DebugFile.trace) DebugFile.writeln("to recipients count is " + String.valueOf(aTo.length));
      for (int t=0; t<aTo.length; t++) {
        sAddr = aTo[t].trim();
        if (sAddr.length()>0) {
          DBInetAddr.write(oConn, iIdDomain, sGuWorkarea,  sGuMsg, sIdMsg, aTo[t].trim(), "to", null);
        }
      } // next
    } // fi
    if (aCc!=null) {
      if (DebugFile.trace) DebugFile.writeln("cc recipients count is " + String.valueOf(aCc.length));
      for (int t=0; t<aCc.length; t++) {
        sAddr = aCc[t].trim();
        if (sAddr.length()>0) {
          DBInetAddr.write(oConn, iIdDomain, sGuWorkarea,  sGuMsg, sIdMsg, aCc[t].trim(), "cc", null);
        }
      } // next
    } // fi
    if (aBcc!=null) {
      if (DebugFile.trace) DebugFile.writeln("bcc recipients count is " + String.valueOf(aBcc.length));
      for (int t=0; t<aBcc.length; t++) {
        sAddr = aBcc[t].trim();
        if (sAddr.length()>0) {
          DBInetAddr.write(oConn, iIdDomain, sGuWorkarea,  sGuMsg, sIdMsg, aBcc[t].trim(), "bcc", null);
        }
      } // next
    } // fi
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DraftsHelper.draftUpdate");
    }
  } // draftUpdate
}
