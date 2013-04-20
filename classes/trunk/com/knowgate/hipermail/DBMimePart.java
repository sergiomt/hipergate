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
import com.knowgate.dataobjs.DBBind;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.io.FileInputStream;
import java.io.File;

import java.util.LinkedList;
import java.util.Properties;

import java.math.BigDecimal;


import java.sql.ResultSet;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.activation.DataHandler;

import javax.mail.BodyPart;
import javax.mail.Multipart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimePart;
import javax.mail.internet.MimeMultipart;
import javax.mail.internet.MimeBodyPart;
import javax.mail.MessagingException;

import org.apache.oro.text.regex.MalformedPatternException;
import org.apache.oro.text.regex.Perl5Compiler;

import com.knowgate.dfs.ByteArrayDataSource;
import com.knowgate.dfs.FileSystem;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class DBMimePart extends BodyPart implements MimePart {
  private int iPartId, iSize;
  private String sMD5,sFile;
  private MimeBodyPart oMimeBody;
  private Multipart oParent;
  private Properties oHeaders;

  public DBMimePart(Multipart oMultipart) {
    oMimeBody = null;
    oParent = oMultipart;
    oHeaders = new Properties();
  }

  public DBMimePart(InputStream oInStrm)
    throws MessagingException {
    oMimeBody = new MimeBodyPart(oInStrm);

    iPartId = -1;
    iSize = oMimeBody.getSize();

    oHeaders = new Properties();
    oHeaders.setProperty("Content-ID", oMimeBody.getContentID());
    oHeaders.setProperty("Content-Type", oMimeBody.getContentType());
    oHeaders.setProperty("Content-Transfer-Encoding", oMimeBody.getEncoding());
    oHeaders.setProperty("Content-Description", oMimeBody.getDescription());
    oHeaders.setProperty("Content-Disposition", oMimeBody.getDisposition());

    sMD5 = oMimeBody.getContentMD5();
    sFile = oMimeBody.getFileName();
  }

  // ---------------------------------------------------------------------------

  public DBMimePart(Multipart oMultipart, int iIdPart, String sIdContent, String sContentType, String sContentMD5, String sDescription, String sDisposition, String sEncoding, String sFileName, int nBytes)
    throws MessagingException {

    oMimeBody = null;

    oParent = oMultipart;
    iPartId = iIdPart;
    sMD5 = sContentMD5;
    sFile = sFileName;
    iSize = nBytes;

    oHeaders = new Properties();
    if (null!=sIdContent) oHeaders.setProperty("Content-ID", sIdContent);
    if (null!=sContentType) oHeaders.setProperty("Content-Type", sContentType);
    if (null!=sDescription) oHeaders.setProperty("Content-Description", sDescription);
    if (null!=sDisposition) oHeaders.setProperty("Content-Disposition", sDisposition);
    if (null!=sEncoding) oHeaders.setProperty("Content-Transfer-Encoding", sEncoding);
  }

  // ---------------------------------------------------------------------------

  private DBMimeMessage getMessage() {
    return (DBMimeMessage)(oParent.getParent());
  }

  // ---------------------------------------------------------------------------

  public String[] getHeader(String name) throws MessagingException {
    return new String[] {oHeaders.getProperty(name)};
  }

  // ---------------------------------------------------------------------------

  public String getHeader(String name, String delimiter) throws MessagingException {
    return oHeaders.getProperty(name);
  }

  // ---------------------------------------------------------------------------

  public java.util.Enumeration getAllHeaders() throws MessagingException {
    return oHeaders.keys();
  }

  // ---------------------------------------------------------------------------

  public java.util.Enumeration getMatchingHeaders(java.lang.String[] names) throws MessagingException {
    return null;
  }

  // ---------------------------------------------------------------------------

  public java.util.Enumeration getNonMatchingHeaders(java.lang.String[] names) throws MessagingException {
    return null;
  }

  // ---------------------------------------------------------------------------

  public void addHeader(String s1, String s2) throws MessagingException {
    throw new UnsupportedOperationException("Cannot call addHeader() on DBMimePart)");
  }

  // ---------------------------------------------------------------------------

  public void setHeader(String s1, String s2) throws MessagingException {
    throw new UnsupportedOperationException("Cannot call setHeader() on DBMimePart)");
  }

  // ---------------------------------------------------------------------------

  public void removeHeader(String header) throws MessagingException {
    throw new UnsupportedOperationException("Cannot call removeHeader() on DBMimePart)");
  }

  // ---------------------------------------------------------------------------

  public void addHeaderLine(java.lang.String line) throws MessagingException {
    throw new UnsupportedOperationException("Cannot call addHeaderLine() on DBMimePart)");
  }

  // ---------------------------------------------------------------------------

  public java.util.Enumeration getAllHeaderLines() throws MessagingException {
    throw new UnsupportedOperationException("Cannot call getAllHeaderLines() on DBMimePart)");
  }

  // ---------------------------------------------------------------------------

  public java.util.Enumeration getMatchingHeaderLines(java.lang.String[] names) throws MessagingException {
    throw new UnsupportedOperationException("Cannot call getMatchingHeaderLines() on DBMimePart)");
  }

  // ---------------------------------------------------------------------------

  public java.util.Enumeration getNonMatchingHeaderLines(java.lang.String[] names) throws MessagingException {
    throw new UnsupportedOperationException("Cannot call getNonMatchingHeaderLines() on DBMimePart)");
  }

  // ---------------------------------------------------------------------------

  public Object getContent() throws MessagingException, IOException, NullPointerException {

    int iLen;
    long lPos, lOff;
    String sFilePath;
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    Object oRetVal = null;
    DBFolder oFldr = (DBFolder) getMessage().getFolder();
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimePart.getContent()");
      DebugFile.incIdent();
      DebugFile.writeln("Message Content-Id is " + getMessage().getContentID() + " and Part Id is " + String.valueOf(iPartId));
    }

    if (oFldr==null && oMimeBody!=null) {
      if (DebugFile.trace) DebugFile.decIdent();
      return oMimeBody.getContent();
    }

    try {
      if (null==oFldr) {
    	throw new NullPointerException("DBMimePart.getContent() Folder not set and no MIME body part found");
      } else {
        sSQL = "SELECT m.pg_message,p.id_disposition,m.nu_position,p.file_name,p.len_part,p.nu_offset,p.id_content,m.by_content FROM k_mime_msgs m, k_mime_parts p WHERE (m.gu_mimemsg=? OR m.id_message=?) AND m.gu_mimemsg=p.gu_mimemsg AND p.id_part=? AND m.gu_category=?";
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
        oStmt = oFldr.getConnection().prepareStatement(sSQL);
        oStmt.setString(1, getMessage().getMessageGuid());
        oStmt.setString(2, getMessage().getContentID());
        oStmt.setInt(3, iPartId);
        oStmt.setString(4, oFldr.getCategoryGuid());
      }

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");
      oRSet = oStmt.executeQuery();

      if (oRSet.next()) {
        String id_disposition = oRSet.getString(2);

        if (oRSet.wasNull()) id_disposition = "inline";

        if (id_disposition.equals("reference")) {
          if (DebugFile.trace) DebugFile.writeln("content disposition is reference");
          sFilePath = oRSet.getString(4);

          FileSystem oFS = new FileSystem();
          byte[] byData = oFS.readfilebin(sFilePath);
          String sContentType = oRSet.getString(7);
          if (DebugFile.trace) DebugFile.writeln("new ByteArrayDataSource("+sFilePath+", "+sContentType+")");
          ByteArrayDataSource baDataSrc = new ByteArrayDataSource(byData, sContentType);

          oMimeBody = new MimeBodyPart();
          oMimeBody.setDataHandler(new DataHandler(baDataSrc));
        }
        else if (id_disposition.equals("pointer")) {
          if (DebugFile.trace) DebugFile.writeln("content disposition is pointer");
          lPos = oRSet.getBigDecimal(3).longValue();
          sFilePath = oRSet.getString(4);
          iLen = oRSet.getInt(5);
          lOff = oRSet.getBigDecimal(6).longValue();
          MboxFile oMbox = new MboxFile(sFilePath, MboxFile.READ_ONLY);
          InputStream oPartStrm = oMbox.getPartAsStream(lPos, lOff, iLen);
          oMimeBody = new MimeBodyPart(oPartStrm);
        }
        else if ((oFldr.getType()&DBFolder.MODE_BLOB)!=0) {
          if (DebugFile.trace) DebugFile.writeln("content disposition is " + id_disposition + " mode is BLOB");
          if (DebugFile.trace) DebugFile.writeln("new MimeBodyPart([InputStream])");
          oMimeBody = new MimeBodyPart(oRSet.getBinaryStream(8));
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("content disposition is " + id_disposition + " mode is MBOX");
          BigDecimal oPosition;
          Object oLenPart, oOffset;

          oPosition = oRSet.getBigDecimal(3);
          if (!oRSet.wasNull()) lPos = Long.parseLong(oPosition.toString()); else lPos = -1;
          oLenPart = oRSet.getObject(5);
          if (!oRSet.wasNull()) iLen = Integer.parseInt(oLenPart.toString()); else iLen = -1;
          oOffset = oRSet.getObject(6);
          if (!oRSet.wasNull()) lOff = Long.parseLong(oOffset.toString()); else lOff = -1;

          if (lPos!=-1) {
            if (iLen==-1) throw new MessagingException("Part " + String.valueOf(iPartId) + " length not set at k_mime_parts table for message "+getMessage().getMessageGuid());
            if (lOff==-1 ) throw new MessagingException("Part " + String.valueOf(iPartId) + " offset not set at k_mime_parts table for message "+getMessage().getMessageGuid());

            if (DebugFile.trace) DebugFile.writeln("new MboxFile("+((DBFolder)getMessage().getFolder()).getFile()+")");

            MboxFile oMbox = new MboxFile(((DBFolder)getMessage().getFolder()).getFile(), MboxFile.READ_ONLY);

            InputStream oInStrm = oMbox.getPartAsStream(lPos, lOff, iLen);
            oMimeBody = new MimeBodyPart(oInStrm);
            oInStrm.close();

            oMbox.close();
          }
          else {
            if (DebugFile.trace) DebugFile.decIdent();
            throw new MessagingException("Part " + String.valueOf(iPartId) + " not found for message " + getMessage().getContentID());
          }
        } // fi (MODE_MBOX)
      } else {
        if (DebugFile.trace) {
          if (null==oFldr)
            DebugFile.writeln("Part "+String.valueOf(iPartId) + " not found in message ["+getMessage().getMessageGuid()+"] " + getMessage().getContentID());
          else
            DebugFile.writeln("Part "+String.valueOf(iPartId) + " not found in message ["+getMessage().getMessageGuid()+"] " + getMessage().getContentID() + " at folder " + oFldr.getCategoryGuid());
        }
      } // fi (oRset.next();

      oRSet.close();
      oRSet = null;
      oStmt.close();
      oStmt = null;
    } catch (SQLException sqle) {
      try { if (null!=oRSet) oRSet.close(); } catch (Exception ignore) {}
      try { if (null!=oStmt) oStmt.close(); } catch (Exception ignore) {}
      throw new MessagingException(sqle.getMessage(), sqle);
    } catch (com.enterprisedt.net.ftp.FTPException xcpt) {
      try { if (null!=oRSet) oRSet.close(); } catch (Exception ignore) {}
      try { if (null!=oStmt) oStmt.close(); } catch (Exception ignore) {}
      throw new MessagingException(xcpt.getMessage(), xcpt);
    }

    if (oMimeBody!=null) {
      if (DebugFile.trace) DebugFile.writeln("MimeBodyPart.getContent()");
      oRetVal = oMimeBody.getContent();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oRetVal)
        DebugFile.writeln("End DBMimePart.getContent() : null");
      else
        DebugFile.writeln("End DBMimePart.getContent() : " + oRetVal.getClass().getName());
    }

    return oRetVal;
  } // getContent ()

  // ---------------------------------------------------------------------------

  public DataHandler getDataHandler () throws MessagingException {
    throw new UnsupportedOperationException("Method getDataHandler() not implemented for DBMimePart");
  }

  // ---------------------------------------------------------------------------

  public InputStream getInputStream () throws MessagingException, IOException {
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    InputStream oRetVal = null;
    DBFolder oFldr = (DBFolder) getMessage().getFolder();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimePart.getInputStream()");
      DebugFile.incIdent();
    }

    if (oMimeBody!=null) {
      if (DebugFile.trace) DebugFile.writeln("BodyPart.getInputStream()");
      if (DebugFile.trace) DebugFile.decIdent();
      return oMimeBody.getInputStream();
    }

    try {

      if (null!=getMessage().getMessageGuid()) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT m.pg_message,m.nu_position,p.id_disposition,p.file_name,p.len_part,p.nu_offset,m.by_content FROM k_mime_msgs m, k_mime_parts p WHERE m.gu_mimemsg='"+getMessage().getMessageGuid()+"' AND m.gu_mimemsg=p.gu_mimemsg AND p.id_part="+String.valueOf(iPartId)+")");
        oStmt = ((DBFolder)getMessage().getFolder()).getConnection().prepareStatement("SELECT m.pg_message,m.nu_position,p.id_disposition,p.file_name,p.len_part,p.nu_offset,m.by_content FROM k_mime_msgs m, k_mime_parts p WHERE m.gu_mimemsg=? AND m.gu_mimemsg=p.gu_mimemsg AND p.id_part=?");
        oStmt.setString(1, getMessage().getMessageGuid());
        oStmt.setInt(2, iPartId);
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT m.pg_message,m.nu_position,p.id_disposition,p.file_name,p.len_part,p.nu_offset,m.by_content FROM k_mime_msgs m, k_mime_parts p WHERE m.id_message='"+getMessage().getMessageID()+"' AND m.gu_mimemsg=p.gu_mimemsg AND p.id_part="+String.valueOf(iPartId)+")");
        oStmt = ((DBFolder)getMessage().getFolder()).getConnection().prepareStatement("SELECT m.pg_message,m.nu_position,p.id_disposition,p.file_name,p.len_part,p.nu_offset,m.by_content FROM k_mime_msgs m, k_mime_parts p WHERE m.id_message=? AND m.gu_mimemsg=p.gu_mimemsg AND p.id_part=?");
        oStmt.setString(1, getMessage().getMessageID());
        oStmt.setInt(2, iPartId);
      }

      oRSet = oStmt.executeQuery();

      if (oRSet.next()) {
        BigDecimal oMsgPos = oRSet.getBigDecimal(2);
        if (oRSet.wasNull()) oMsgPos = null;
        String id_disposition = oRSet.getString(3);
        if (oRSet.wasNull()) id_disposition = "inline";
        String sTmpFilePath = oRSet.getString(4);

        if (id_disposition.equals("reference")) {
          if (DebugFile.trace) DebugFile.writeln("new FileInputStream(" + sTmpFilePath + ")");
          oRetVal = new FileInputStream(sTmpFilePath);
        }
        else if (id_disposition.equals("pointer")) {
          if (null==oMsgPos) throw new SQLException ("nu_position column may not be null for parts with pointer disposition", "22002", 22002);
          Object oPartLen = oRSet.getObject(5);
          if (oRSet.wasNull()) throw new SQLException ("len_part column may not be null for parts with pointer disposition", "22002", 22002);
          BigDecimal oPartOffset = oRSet.getBigDecimal(6);
          if (oRSet.wasNull()) throw new SQLException ("nu_offset column may not be null for parts with pointer disposition", "22002", 22002);
          if (DebugFile.trace) DebugFile.writeln("new File(" + sTmpFilePath + ")");
          File oFile = new File (sTmpFilePath);
          MboxFile oMbox = new MboxFile(oFile, MboxFile.READ_ONLY);
          oRetVal = oMbox.getPartAsStream(oMsgPos.longValue(), oPartOffset.longValue(), Integer.parseInt(oPartLen.toString()));
          oMimeBody = new MimeBodyPart(oRetVal);
          oRetVal.close();
        }
        else if ((oFldr.getType()&DBFolder.MODE_BLOB)!=0) {
          if (DebugFile.trace) DebugFile.writeln("new MimeBodyPart(ResultSet.getBinaryStream(...))");
          oMimeBody = new MimeBodyPart(oRSet.getBinaryStream(7));
        }
        else {
          BigDecimal oPosition;
          Object oMsgNum, oLenPart, oOffset;
          long iPosition = -1, iOffset = -1;
          int iLenPart = -1;

          oMsgNum = oRSet.getObject(1);
          oPosition = oRSet.getBigDecimal(2);
          if (!oRSet.wasNull()) iPosition = Long.parseLong(oPosition.toString());
          oLenPart = oRSet.getObject(5);
          if (!oRSet.wasNull()) iLenPart = oRSet.getInt(5);
          oOffset = oRSet.getObject(6);
          if (!oRSet.wasNull()) iOffset = oRSet.getInt(6);

          if (iPosition!=-1) {
            if (iLenPart==-1) throw new MessagingException("Part " + String.valueOf(iPartId) + " length not set at k_mime_parts table");
            if (iOffset==-1 ) throw new MessagingException("Part " + String.valueOf(iPartId) + " offset not set at k_mime_parts table");

            if (DebugFile.trace) DebugFile.writeln("new MboxFile("+((DBFolder)getMessage().getFolder()).getFile()+")");

            MboxFile oMbox = new MboxFile(((DBFolder)getMessage().getFolder()).getFile(), MboxFile.READ_ONLY);

            oMimeBody = new MimeBodyPart(oMbox.getPartAsStream(iPosition, iOffset, iLenPart));

            oMbox.close();
          }
          else {
            if (DebugFile.trace) DebugFile.decIdent();
            throw new MessagingException("Part " + String.valueOf(iPartId) + " not found for message " + getMessage().getContentID());
          }
        } // fi (MODE_MBOX)
      } // fi (oRset.next();

      oRSet.close();
      oRSet = null;
      oStmt.close();
      oStmt = null;
    } catch (SQLException sqle) {
      try { if (null!=oRSet) oRSet.close(); } catch (Exception ignore) {}
      try { if (null!=oStmt) oStmt.close(); } catch (Exception ignore) {}
      throw new MessagingException(sqle.getMessage(), sqle);
    }

    if (oMimeBody!=null) oRetVal = oMimeBody.getInputStream();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==oRetVal)
        DebugFile.writeln("End DBMimePart.getInputStream() : null");
      else
        DebugFile.writeln("End DBMimePart.getInputStream() : " + oRetVal.getClass().getName());
    }

    return oRetVal;
  } // getInputStream

  // ---------------------------------------------------------------------------

  public String getContentMD5 () throws MessagingException {
    throw new UnsupportedOperationException("Method getContentMD5() not implemented for DBMimePart");
  }

  // ---------------------------------------------------------------------------

  public int getLineCount () throws MessagingException {
    throw new UnsupportedOperationException("Method getLineCount() not implemented for DBMimePart");
  }

  // ---------------------------------------------------------------------------

  public boolean isMimeType (String sMimeTp) throws MessagingException {
    throw new UnsupportedOperationException("Method isMimeType() not implemented for DBMimePart");
  }

  // ---------------------------------------------------------------------------

  public String getContentID () { return oHeaders.getProperty("Content-ID"); }

  // ---------------------------------------------------------------------------

  public void setDisposition (String sDisposition) {
    throw new UnsupportedOperationException("Method setDisposition() not implemented for DBMimePart");
  }

  // ---------------------------------------------------------------------------

  public void setContentLanguage (String[] aLangs) {
    throw new UnsupportedOperationException("Method setContentLanguage() not implemented for DBMimePart");
  }

  // ---------------------------------------------------------------------------

  public String[] getContentLanguage () {
    throw new UnsupportedOperationException("Method getContentLanguage() not implemented for DBMimePart");
  }

  // ---------------------------------------------------------------------------

  public String getDescription () throws MessagingException {
    return oHeaders.getProperty("Content-Description");
  }

  // ---------------------------------------------------------------------------

  public String getDisposition () throws MessagingException  {
    return oHeaders.getProperty("Content-Disposition");
  }

  // ---------------------------------------------------------------------------

  public String getFileName () throws MessagingException {

    DBFolder oFldr = (DBFolder) getMessage().getFolder();
    PreparedStatement oStmt = null;
    String sFileName;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin DBMimePart.getFileName()");
       DebugFile.incIdent();
       if (oFldr==null) DebugFile.writeln("Folder is null");
       if (oMimeBody==null) DebugFile.writeln("MimeBody is null");
    }

    if (sFile!=null)
      sFileName = sFile;
    else if (oFldr==null && oMimeBody!=null) {
      sFileName = oMimeBody.getFileName();
    }
    else if (oFldr==null) {
      try {
        if (getMessage().getMessageGuid()!=null) {
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.file_name + " FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='"+getMessage().getMessageGuid()+"' AND " + DB.id_part + "="+String.valueOf(iPartId)+")");
          oStmt = oFldr.getConnection().prepareStatement("SELECT " + DB.file_name + " FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "=? AND " + DB.id_part + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, getMessage().getMessageGuid());
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.file_name + " FROM " + DB.k_mime_parts + " WHERE " + DB.id_message + "='"+getMessage().getContentID()+"' AND " + DB.id_part + "="+String.valueOf(iPartId)+")");
          oStmt = oFldr.getConnection().prepareStatement("SELECT " + DB.file_name + " FROM " + DB.k_mime_parts + " WHERE " + DB.id_message + "=? AND " + DB.id_part + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, getMessage().getContentID());
        }

        oStmt.setInt(2, iPartId);

        ResultSet oRSet = oStmt.executeQuery();

        if (oRSet.next())
          sFileName = oRSet.getString(1);
        else
          sFileName = null;

        oRSet.close();
        oRSet = null;
        oStmt.close();
        oStmt = null;
      }
      catch (SQLException sqle) {
        sFileName = null;
        if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) {} }
        if (DebugFile.trace) DebugFile.decIdent();
        throw new MessagingException(sqle.getMessage(), sqle);
      }
    }
    else {
      sFileName = null;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimePart.getFileName() : " + sFileName);
    }

    return sFileName;
  } // getFileName

  // ---------------------------------------------------------------------------

  public String getContentType () { return oHeaders.getProperty("Content-Type"); }

  // ---------------------------------------------------------------------------

  public String getEncoding () { return oHeaders.getProperty("Content-Transfer-Encoding"); }

  // ---------------------------------------------------------------------------

  public int getPartId () { return iPartId; }

  // ---------------------------------------------------------------------------

  public int getSize () { return iSize; }

  // ---------------------------------------------------------------------------

  public String getText ()
    throws SQLException,UnsupportedEncodingException,MessagingException,IOException {

    String sMsgGuid = getMessage().getMessageGuid();
    JDCConnection oConn = ((DBFolder)getMessage().getFolder()).getConnection();
    String sText = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimePart.getText()");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(SELECT "+DB.id_message+","+DBBind.Functions.ISNULL+"(len_part,0),id_encoding,by_content FROM "+ DB.k_mime_parts + " WHERE (" + DB.gu_mimemsg + "='"+sMsgGuid+"') AND id_part='"+String.valueOf(iPartId)+")");
    }

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.id_message+","+DBBind.Functions.ISNULL+"(len_part,0),id_encoding,by_content FROM "+ DB.k_mime_parts + " WHERE (" + DB.gu_mimemsg + "=?) AND id_part=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setString(1, sMsgGuid);
    oStmt.setInt(2, iPartId);

    ResultSet oRSet = oStmt.executeQuery();

    if (oRSet.next()) {

      oMimeBody = new MimeBodyPart (oRSet.getBinaryStream(4));

      oRSet.close();
      oStmt.close();

      StringBuffer oText = new StringBuffer();

      parseMimePart (oText, null, getMessage().getFolder().getName(),
                     getMessage().getMessageID()!=null ? getMessage().getMessageID() : getMessage().getContentID(),
                     oMimeBody, iPartId);

      sText = oText.toString();
    }
    else {
      oRSet.close();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimePart.getText()");
    }

    return sText;
  }

  // ---------------------------------------------------------------------------

  public void setDataHandler (DataHandler oDataHndlr) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setDataHandler() for them");
  }

  // ---------------------------------------------------------------------------

  public void setText (String sTxt) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setText() for them");
  }

  // ---------------------------------------------------------------------------

  public void setText (String sTxt, String sEncoding) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setText() for them");
  }

  // ---------------------------------------------------------------------------

  public void setText (String sTxt, String sEncoding, String sStr) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setText() for them");
  }

  // ---------------------------------------------------------------------------

  public void setContentMD5 (String sMD5) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setContentMD5() for them");
  }

  // ---------------------------------------------------------------------------

  public void setContent (Object oObj) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setContent() for them");
  }

  // ---------------------------------------------------------------------------

  public void setContent (Object oObj, String s) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setContent() for them");
  }

  // ---------------------------------------------------------------------------

  public void setContent (Multipart oPart) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setContent() for them");
  }

  // ---------------------------------------------------------------------------

  public void setFileName (String sName) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setFileName() for them");
  }

  // ---------------------------------------------------------------------------

  public void setDescription (String sDesc) {
    throw new UnsupportedOperationException("DBMimePart objects are read-only. Cannot setDescription() for them");
  }

  // ---------------------------------------------------------------------------

  public void setContentId (String sId) { oHeaders.setProperty("Content-ID", sId); }

  // --------------------------------------------------------------------------

  public void setEncoding (String sEncoding) { oHeaders.setProperty("Content-Transfer-Encoding", sEncoding); }

  // --------------------------------------------------------------------------

  public void setPartId (int iId) { iPartId = iId; }

  // --------------------------------------------------------------------------

  public void setSize (int nBytes) { iSize = nBytes; }

  // --------------------------------------------------------------------------

  public static String textToHtml(String sText) {

    try {
      sText = Gadgets.replace(sText, "(http|https):\\/\\/(\\S*)",
                              "<a href=\"$1://$2\" target=\"_blank\">$1://$2</a>",
                               Perl5Compiler.CASE_INSENSITIVE_MASK);
    }
    catch (Exception ignore) { }

    final int iLen = sText.length();
    StringBuffer oHtml = new StringBuffer(iLen+1000);
    char cAt;

    for (int i=0; i<iLen; i++) {
      cAt = sText.charAt(i);

      switch (cAt) {
        case 10:
          oHtml.append("<BR>");
          break;
        case 13:
          break;
        default:
          oHtml.append(cAt);
      }
    }

    return oHtml.toString();
  } //  textToHtml

  // ---------------------------------------------------------------------------

  public static MimePart getMessagePart (MimePart oPart, int nPart)
    throws MessagingException, IOException, UnsupportedEncodingException {

    MimeBodyPart oNext = null;
    MimeMultipart oAlt;
    String sType;
    MimePart oRetVal;

    sType = oPart.getContentType().toUpperCase();

    if (DebugFile.trace) DebugFile.writeln("Begin DBMimePart.getMessagePart("+String.valueOf(nPart)+", "+sType.replace('\n',' ').replace('\r',' ')+")");

    if (sType.startsWith("MESSAGE/RFC822")) {
      DBMimeMessage oAttachment = new  DBMimeMessage((MimeMessage) oPart.getContent());
      oRetVal = oAttachment.getBody ();
    }
    else if (sType.startsWith("MULTIPART/ALTERNATIVE") || sType.startsWith("MULTIPART/RELATED") || sType.startsWith("MULTIPART/SIGNED")) {
      oAlt = (MimeMultipart) oPart.getContent();

      int iAlt = 0;
      String[] aPreferred = {"TEXT/HTML","TEXT"};
      boolean bFound = false;

      while (iAlt<aPreferred.length && !bFound) {
        for (int q=0; q<oAlt.getCount(); q++) {
          oNext = (MimeBodyPart) oAlt.getBodyPart(q);
          if (DebugFile.trace && (iAlt==0)) DebugFile.writeln("  " + oNext.getContentType().toUpperCase().replace('\n',' ').replace('\r',' ') + " ID=" + oNext.getContentID());
          bFound = oNext.getContentType().toUpperCase().startsWith(aPreferred[iAlt]);
          if (bFound) break;
        } // next
        iAlt++;
      } // wend

      if (bFound)
        oRetVal = getMessagePart (oNext, -1);
      else
        oRetVal = getMessagePart ((MimeBodyPart) oAlt.getBodyPart(0), -1);
    }
    else {
      oRetVal = oPart;
    }

    if (DebugFile.trace) DebugFile.writeln("End DBMimePart.getMessagePart() : " + oRetVal.getContentType().replace('\n',' ').replace('\r',' '));

    return oRetVal;
  }  // getMessagePart

  // --------------------------------------------------------------------------

  public static int parseMimePart (StringBuffer oStrBuff, LinkedList oAttachments,
                                   String sFolder, String sMsgId,
                                   MimePart oPart, int nPart)
    throws MessagingException, IOException, UnsupportedEncodingException {

    String sType;
    int iRetVal;
    String sContent;

    sType = oPart.getContentType().toUpperCase();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimePart.parseMimePart(" + sMsgId + "," +String.valueOf(nPart) + "," + sType.replace('\n',' ').replace('\r',' ') + ")");
      DebugFile.incIdent();
    }

    oPart = getMessagePart(oPart, nPart);
    sType = oPart.getContentType().toUpperCase();

    if (DebugFile.trace) DebugFile.writeln("body type = " + sType);

    if (sType.startsWith("TEXT/PLAIN")) {
      sContent = (String) oPart.getContent(); if (null==sContent) sContent="";

      boolean bHtml = false;
      int iLT = 0, iLen = sContent.length();
      for (int p=0; p<iLen; p++) {
        char cAt = sContent.charAt(p);
        if (cAt=='<') {
          if (cAt<iLen-6) {
            bHtml = sContent.substring(p+1, p+5).equalsIgnoreCase("HTML");
          }
          break;
        } // fi (<)
      } // next (p)

      if (bHtml)
        oStrBuff.append (sContent);
      else
        oStrBuff.append (textToHtml(sContent));

      iRetVal = nPart;
    }
    else if (sType.startsWith("TEXT/HTML")) {

      sContent = (String) oPart.getContent(); if (null==sContent) sContent="";

      try {
        StringBuffer sMsgIdEsc = new StringBuffer(sMsgId.length()+10);
        final int iMsgLen = sMsgId.length();
        for (int i=0; i<iMsgLen; i++) {
          char c = sMsgId.charAt(i);
          if (c=='$')
            sMsgIdEsc.append("\\");
          sMsgIdEsc.append(c);
        }

        if (sFolder!=null) {
        // Replace image cid: with relative references to msg_part.jsp
        sContent = Gadgets.replace(sContent, "src\\s*=\\s*(\"|')cid:(.*?)(\"|')",
                                   "src=\"msg_part.jsp\\?folder="+sFolder+"&msgid="+sMsgIdEsc+
                                   "&cid=$2\"",
                                   Perl5Compiler.CASE_INSENSITIVE_MASK);

        // Set all anchor targets to _blank
        sContent = Gadgets.replace(sContent, "<a\\s*href=(.*?)\\s*target\\s*=\\s*(\"|')?(\\w*)(\"|')?",
                                   "<a href=$1 target=\"_blank\"",
                                   Perl5Compiler.CASE_INSENSITIVE_MASK);
        }
      }
      catch (MalformedPatternException neverthrown) { }

      oStrBuff.append (sContent);

      iRetVal = nPart;
    }
    else if (sType.startsWith("APPLICATION/")) {

      if ((nPart!=-1) && (null!=oAttachments)) {
        Properties oAttachment = new Properties();
        String sFile_Name = oPart.getFileName();
        if (null!=oPart.getContentID()) oAttachment.setProperty("Content-Id", oPart.getContentID());
        oAttachment.setProperty("Part-Number", String.valueOf(nPart));
        oAttachment.setProperty("Part-Number", String.valueOf(nPart));
        oAttachment.setProperty("File-Name", sFile_Name==null ? "file"+String.valueOf(nPart) : sFile_Name);

        if (DebugFile.trace) DebugFile.writeln("size = " + String.valueOf(oPart.getSize()));

        if (oPart.getSize()>1048576) {
          oAttachment.setProperty("File-Length", String.valueOf(oPart.getSize()/1048576) + "Mb");
        } else if (oPart.getSize()>1024) {
          oAttachment.setProperty("File-Length", String.valueOf(oPart.getSize()/1024) + "Kb");
        } else {
          oAttachment.setProperty("File-Length", String.valueOf(oPart.getSize())+"bytes");
        }

        oAttachments.addLast(oAttachment);
      } // fi (nPart!=-1 && null!=oAttachments)
      iRetVal = -1;
    }
    else {
      oStrBuff.append ("Type: " + sType);
      oStrBuff.append ("&nbsp;&nbsp;");
      oStrBuff.append ("Id:" + oPart.getContentID());
      oStrBuff.append ("&nbsp;&nbsp;");
      oStrBuff.append ("File:" + oPart.getFileName());
      oStrBuff.append ("&nbsp;&nbsp;");
      oStrBuff.append ("Desc:" + oPart.getDescription());
      oStrBuff.append ("<BR/>");
      iRetVal = -1;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MimePartDB.parseMimePart() : " + String.valueOf(iRetVal));
    }

    return iRetVal;
  }  // parseMimePart

  // ---------------------------------------------------------------------------

  public static String getMimeType(JDCConnection oConn, String sFileName) throws SQLException {
    String sMimeType;

    if (null==sFileName) return null;

    int iDot = sFileName.lastIndexOf('.');

    if (iDot<0 || iDot==sFileName.length()-1) return "application/octec-stream";

    String sFileExtension = sFileName.substring(++iDot).toUpperCase();

    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.mime_type+" FROM "+DB.k_lu_prod_types+" WHERE "+DB.id_prod_type+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sFileExtension);

    ResultSet oRSet = oStmt.executeQuery();

    if (oRSet.next())
      sMimeType = oRSet.getString(1);
    else
      sMimeType = null;

    oRSet.close();
    oStmt.close();

    return (sMimeType==null ? "application/octec-stream" : sMimeType);
  } // getMimeType

  // ---------------------------------------------------------------------------

  public void writeTo (OutputStream oOutStrm)
      throws IOException, MessagingException {
  }
}
