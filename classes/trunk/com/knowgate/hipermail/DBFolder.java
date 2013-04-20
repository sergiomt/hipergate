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

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Blob;
import java.sql.Types;
import java.sql.Statement;
import java.sql.CallableStatement;

import java.math.BigDecimal;

import java.io.UnsupportedEncodingException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.InputStream;

import java.text.SimpleDateFormat;

import javax.mail.Session;
import javax.mail.Folder;
import javax.mail.Store;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.StoreClosedException;
import javax.mail.FolderClosedException;
import javax.mail.Flags;
import javax.mail.URLName;
import javax.mail.BodyPart;
import javax.mail.Address;

import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeUtility;
import javax.mail.internet.MimePart;
import javax.mail.internet.MimeMultipart;

import java.util.Properties;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.dfs.FileSystem;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBKeySet;
import com.knowgate.hipergate.Category;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.hipergate.Product;
import com.knowgate.hipergate.ProductLocation;


/**
 * <p>A subclass of javax.mail.Folder providing storage for MimeMessages at database
 * LONGVARBINARY columns and MBOX files.</p>
 * Folders are also a subclass of com.knowgate.hipergate.Category<br>
 * Category behaviour is obtained by delegation to a private Category instance.<br>
 * For each DBFolder there is a corresponding row at k_categories database table.
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class DBFolder extends Folder {

  // Store Messages using an MBOX file
  public static final int MODE_MBOX = 64;

  // Store Messages using database BLOB columns
  public static final int MODE_BLOB = 128;

  private int iOpenMode;

  private Category oCatg;

  private String sFolderDir, sFolderName;

  // ---------------------------------------------------------------------------

  protected DBFolder(Store oStor, String sName) {
    super(oStor);
    oCatg = new Category();
    iOpenMode = 0;
    sFolderName = sName;
  }

  // ---------------------------------------------------------------------------

  protected JDCConnection getConnection() throws SQLException,MessagingException {
    return ((DBStore) getStore()).getConnection();
  }

  // ---------------------------------------------------------------------------

  /**
   * Get instance of com.knowgate.hipergate.Category object
   */
  public Category getCategory() {
    return oCatg;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get Category GUID</p>
   * Each folder has a Global Unique Identifier which is stored at column
   * gu_category of table k_categories
   * @return String Category GUID or <b>null</b> if category is not set
   */
  public String getCategoryGuid() {
    if (null==oCatg)
      return null;
    else
      return oCatg.getStringNull(DB.gu_category,null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get set of identifiers for messages at this folder</p>
   * Set entries are the mime identifiers for each message
   * @return DBKeySet
   * @throws SQLException
   */
  public DBKeySet keySet() throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.keySet()");
      DebugFile.incIdent();
    }
    DBKeySet oKeySet = new DBKeySet(DB.k_mime_msgs,
                                    DB.id_message,
                                    DB.id_message+" IS NOT NULL AND "+DB.gu_category+"=? AND "+DB.bo_deleted+"<>1 AND "+DB.gu_parent_msg+" IS NULL",0);
    JDCConnection oCnn = null;
    try {
      oCnn = getConnection();
    } catch (MessagingException msge) {
      throw new SQLException(msge.getMessage(), msge);
    }
    
    oKeySet.load(oCnn,new Object[]{oCatg.getString(DB.gu_category)});
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.keySet() : " + String.valueOf(oKeySet.size()));
    }
    return oKeySet;
  } // keySet

  // ---------------------------------------------------------------------------

  /**
   * Append messages to this DBFolder
   * @param msgs Array of mime messages to be appended
   * @throws MessagingException
   * @throws ArrayIndexOutOfBoundsException
   */
  public void appendMessages(Message[] msgs)
    throws MessagingException, ArrayIndexOutOfBoundsException {

    for (int m=0; m<msgs.length; m++)
      appendMessage((MimeMessage) msgs[m]);
  }

  // ---------------------------------------------------------------------------

  /**
   * Copy a DBMimeMessage from another DBFolder to this DBFolder
   * @param oSrcMsg Source message.
   * @return GUID of new message
   * @throws MessagingException
   */
  public String copyMessage(DBMimeMessage oSrcMsg)
      throws MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.copyMessage()");
      DebugFile.incIdent();
    }

    BigDecimal oPg = null;
    BigDecimal oPos = null;
    int iLen = 0;
    String sId = null;
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    try {
      String sSQL = "SELECT "+DB.pg_message+","+DB.id_message+","+DB.nu_position+","+DB.len_mimemsg+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"=";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+"'"+oSrcMsg.getMessageGuid()+"')");

      oStmt = getConnection().prepareStatement(sSQL+"?",ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, oSrcMsg.getMessageGuid());
      oRSet = oStmt.executeQuery();
      if (!oRSet.next())
        throw new MessagingException("DBFolder.copyMessage() could not find source message " + oSrcMsg.getMessageGuid());
      oPg = oRSet.getBigDecimal(1);
      sId = oRSet.getString(2);
      oPos= oRSet.getBigDecimal(3);
      iLen= oRSet.getInt(4);
      oRSet.close();
      oRSet=null;
      oStmt.close();
      oStmt=null;
    }
    catch (SQLException sqle) {
      try { if (oRSet!=null) oRSet.close(); } catch (Exception ignore) {}
      try { if (oStmt!=null) oStmt.close(); } catch (Exception ignore) {}
      try { getConnection().rollback(); } catch (Exception ignore) {}
      if (DebugFile.trace) {
        DebugFile.writeln("DBFolder.copyMessage() SQLException " + sqle.getMessage());
        DebugFile.decIdent();
      }
      throw new MessagingException("DBFolder.copyMessage() SQLException " + sqle.getMessage(), sqle);
    }

    if (null==oPg) throw new MessagingException("DBFolder.copyMessage() Source Message not found");

    DBFolder oSrcFldr = (DBFolder) oSrcMsg.getFolder();

    MboxFile oMboxSrc = null;
    MimeMessage oMimeSrc;
    String sNewGuid = null;
    try {
      if ((oSrcFldr.mode&MODE_MBOX)!=0) {
        if (DebugFile.trace) DebugFile.writeln("new MboxFile(" + oSrcFldr.getFile() + ", MboxFile.READ_ONLY)");
        oMboxSrc = new MboxFile(oSrcFldr.getFile(), MboxFile.READ_ONLY);
        InputStream oInStrm = oMboxSrc.getMessageAsStream(oPos.longValue(), iLen);
        oMimeSrc = new MimeMessage(Session.getDefaultInstance(new Properties()), oInStrm);
        oInStrm.close();
        oMboxSrc.close();
        oMboxSrc=null;

        String sId2 = oMimeSrc.getMessageID();
        if ((sId!=null) && (sId2!=null)) {
          if (!sId.trim().equals(sId2.trim())) {
            throw new MessagingException("MessageID "+ sId + " at database does not match MessageID " + oMimeSrc.getMessageID() + " at MBOX file " + oSrcFldr.getFile().getName() + " for message index " + oPg.toString());
          }
        } // fi (sId!=null && sId2!=null)

        appendMessage(oMimeSrc);
      }
      else {
        ByteArrayOutputStream oByOutStrm = new ByteArrayOutputStream();
        oSrcMsg.writeTo(oByOutStrm);
        ByteArrayInputStream oByInStrm = new ByteArrayInputStream(oByOutStrm.toByteArray());
        oByOutStrm.close();
        oMimeSrc = new MimeMessage(Session.getDefaultInstance(new Properties()), oByInStrm);
        oByInStrm.close();
        appendMessage(oMimeSrc);
      }
    }
    catch (Exception e) {
      if (oMboxSrc!=null)  { try { oMboxSrc.close();  } catch (Exception ignore) {} }
      try { oSrcFldr.getConnection().rollback(); } catch (Exception ignore) {}
      if (DebugFile.trace) {
        DebugFile.writeln("DBFolder.copyMessage() " + e.getClass().getName() + " "+ e.getMessage());
        DebugFile.writeStackTrace(e);
        DebugFile.writeln("");
        DebugFile.decIdent();
      }
      throw new MessagingException(e.getMessage(), e);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.copyMessage() : " + sNewGuid);
    }

    return sNewGuid;
  } // copyMessage

  // ---------------------------------------------------------------------------

  /**
   * Move a DBMimeMessage from another DBFolder to this DBFolder
   * @param oSrcMsg Source message
   * @throws MessagingException
   */
  public void moveMessage(DBMimeMessage oSrcMsg)
    throws MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.moveMessage([DBMimeMessage])");
      DebugFile.incIdent();
    }

    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    BigDecimal oPg = null;
    BigDecimal oPos = null;
    int iLen = 0;
    boolean bNullLen = true;
    String sCatGuid = null;

    boolean bWasOpen = isOpen();
    if (!bWasOpen) open(Folder.READ_WRITE);

	JDCConnection oConn = null;
	
    try {
      oConn = getConnection();

      sCatGuid = getCategory().getString(DB.gu_category);
      
      if (null==sCatGuid) throw new SQLException("Could not find category for folder");

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT "+DB.pg_message+","+DB.nu_position+","+DB.len_mimemsg+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"='"+oSrcMsg.getMessageGuid()+"')");
      oStmt = oConn.prepareStatement("SELECT "+DB.pg_message+","+DB.nu_position+","+DB.len_mimemsg+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"=?");
      oStmt.setString(1, oSrcMsg.getMessageGuid());
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        oPg = oRSet.getBigDecimal(1);
        oPos = oRSet.getBigDecimal(2);
        iLen = oRSet.getInt(3);
        bNullLen = oRSet.wasNull();
      }
      oRSet.close();
      oRSet=null;
      oStmt.close();
      oStmt=null;

      if (DebugFile.trace) {
        if (oPg!=null) DebugFile.writeln("message number is "+oPg.toString()); else DebugFile.writeln("message number is null");
        if (oPos!=null) DebugFile.writeln("message position is "+oPos.toString()); else DebugFile.writeln("message position is null");
        if (!bNullLen) DebugFile.writeln("message length is "+String.valueOf(iLen)); else DebugFile.writeln("message length is null");
      }

      oConn.setAutoCommit(false);

      String sSrcCatg = null;
      if (DebugFile.trace) {
        DBFolder oSrcFldr = (DBFolder) oSrcMsg.getFolder();
        if (null==oSrcFldr)
          DebugFile.writeln("Source message folder is null");
        else {
          Category oSrcCatg = oSrcFldr.getCategory();
          if (null==oSrcCatg)
            DebugFile.writeln("Source message category is null");
          else {
            sSrcCatg = oSrcCatg.getStringNull(DB.gu_category,null);
          }
        }
        if (null==sSrcCatg) {
          DebugFile.decIdent();
          throw new MessagingException("Could not find folder for source message");
        }
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(UPDATE "+DB.k_categories+" SET "+DB.len_size+"="+DB.len_size+"-"+String.valueOf(iLen)+" WHERE "+DB.gu_category+"='"+sSrcCatg+"')");
      }
      sSrcCatg = ((DBFolder)(oSrcMsg.getFolder())).getCategory().getString(DB.gu_category);
      oStmt = oConn.prepareStatement("UPDATE "+DB.k_categories+" SET "+DB.len_size+"="+DB.len_size+"-"+String.valueOf(iLen)+" WHERE "+DB.gu_category+"=?");
      oStmt.setString(1, sSrcCatg);
      oStmt.executeUpdate();
      oStmt.close();
      oStmt=null;
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(UPDATE "+DB.k_categories+" SET "+DB.len_size+"="+DB.len_size+"+"+String.valueOf(iLen)+" WHERE "+DB.gu_category+"='"+getCategory().getStringNull(DB.gu_category,"null")+"')");
      oStmt = oConn.prepareStatement("UPDATE "+DB.k_categories+" SET "+DB.len_size+"="+DB.len_size+"+"+String.valueOf(iLen)+" WHERE "+DB.gu_category+"=?");
      oStmt.setString(1, getCategory().getString(DB.gu_category));
      oStmt.executeUpdate();
      oStmt.close();
      oStmt=null;

      if (DebugFile.trace) DebugFile.writeln("JDCConnection.commit()");

      oConn.commit();
    }
    catch (SQLException sqle) {
      if (DebugFile.trace) {
      	DebugFile.writeln("SQLException "+sqle.getMessage());
      	DebugFile.writeStackTrace(sqle);
      }
      if (null!=oRSet) { try {oRSet.close(); } catch (Exception ignore) {} }
      if (null!=oStmt) { try {oStmt.close(); } catch (Exception ignore) {} }
      if (null!=oConn) { try {oConn.rollback(); } catch (Exception ignore) {} }
      if (!bWasOpen) { try { close(false); } catch (Exception ignore) {} }
      throw new MessagingException(sqle.getMessage(), sqle);
    }

    if (null==oPg) {
      if (!bWasOpen) { try { close(false); } catch (Exception ignore) {} }
      throw new MessagingException("Source message "+oSrcMsg.getMessageGuid()+" not found");
    }

    // If position is null then message is only at the database and not also at
    // an MBOX file so skip moving from one MBOX file to another
    if (null!=oPos) {

      DBFolder oSrcFldr = (DBFolder) oSrcMsg.getFolder();

      MboxFile oMboxSrc = null, oMboxThis = null;
      
      try {
      	if (DebugFile.trace) DebugFile.writeln("new MboxFile("+oSrcFldr.getFile().getPath()+", MboxFile.READ_WRITE)");
      	  
        oMboxSrc = new MboxFile(oSrcFldr.getFile(), MboxFile.READ_WRITE);

      	if (DebugFile.trace) DebugFile.writeln("new MboxFile("+getFile().getPath()+", MboxFile.READ_WRITE)");

        oMboxThis = new MboxFile(getFile(), MboxFile.READ_WRITE);

      	if (DebugFile.trace) DebugFile.writeln("MboxFile.appendMessage([MboxFile], "+oPos.toString()+","+String.valueOf(iLen)+")");

        oMboxThis.appendMessage(oMboxSrc, oPos.longValue(), iLen);

        oMboxThis.close();
        oMboxThis=null;

        oMboxSrc.purge (new int[]{oPg.intValue()});

        oMboxSrc.close();
        oMboxSrc=null;
      }
      catch (Exception e) {
      	if (DebugFile.trace) {
      	  DebugFile.writeln(e.getClass()+" "+e.getMessage());
      	  DebugFile.writeStackTrace(e);
      	}
        if (oMboxThis!=null) { try { oMboxThis.close(); } catch (Exception ignore) {} }
        if (oMboxSrc!=null)  { try { oMboxSrc.close();  } catch (Exception ignore) {} }
        if (!bWasOpen) { try { close(false); } catch (Exception ignore) {} }
        throw new MessagingException(e.getMessage(), e);
      }
    } // fi (oPos)

    try {
      oConn = getConnection();
      oConn.setAutoCommit(false);

      BigDecimal dNext = getNextMessage(oConn);

      if (DebugFile.trace)
      	DebugFile.writeln("JDCConnection.prepareStatement(UPDATE "+DB.k_mime_msgs+" SET "+DB.gu_category+"='"+sCatGuid+"',"+DB.pg_message+"="+dNext.toString()+" WHERE "+DB.gu_mimemsg+"='"+oSrcMsg.getMessageGuid()+"')");

      oStmt = oConn.prepareStatement("UPDATE "+DB.k_mime_msgs+" SET "+DB.gu_category+"=?,"+DB.pg_message+"=? WHERE "+DB.gu_mimemsg+"=?");
      oStmt.setString(1, sCatGuid);
      oStmt.setBigDecimal(2, dNext);
      oStmt.setString(3, oSrcMsg.getMessageGuid());
      int iAffected = oStmt.executeUpdate();      
      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iAffected)+" updated rows");      
      oStmt.close();
      oStmt=null;

      if (DebugFile.trace) DebugFile.writeln("JDCConnection.commit()");

      oConn.commit();
    }
    catch (SQLException sqle) {

      if (DebugFile.trace) {
      	DebugFile.writeln("MessagingException "+sqle.getMessage());
      	DebugFile.writeStackTrace(sqle);
      }

      if (null!=oStmt) { try { oStmt.close(); } catch (Exception ignore) {}}
      if (null!=oConn) { try { oConn.rollback(); } catch (Exception ignore) {} }
      if (!bWasOpen) { try { close(false); } catch (Exception ignore) {} }

      throw new MessagingException(sqle.getMessage(), sqle);
    }

    if (!bWasOpen) close(false);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.moveMessage()");
    }
  } // moveMessage

  // ---------------------------------------------------------------------------

  /**
   * This method is not implemented and will always raise UnsupportedOperationException
   * @throws UnsupportedOperationException
   */
  public boolean create(int type) throws MessagingException {
    throw new UnsupportedOperationException("DBFolder.create()");
  }

  // ---------------------------------------------------------------------------

  /**
   * Create DBFolder with given name under current user mailroot Category
   * @param sFolderName Folder Name
   * @return <b>true</b>
   * @throws MessagingException
   */
  public boolean create(String sFolderName) throws MessagingException {

    try {
      String sGuid = ((DBStore) getStore()).getUser().getMailFolder(getConnection(),
                     Category.makeName(getConnection(), sFolderName));
      oCatg = new Category(getConnection(), sGuid);
    } catch (SQLException sqle) {
      throw new MessagingException(sqle.getMessage(), sqle);
    }
    return true;
  }

  // ---------------------------------------------------------------------------

  /**
   * Open this DBFolder
   * @param mode {READ_ONLY|READ_WRITE}
   * @throws MessagingException
   */
  public void open(int mode) throws MessagingException {
    final int ALL_OPTIONS = READ_ONLY|READ_WRITE|MODE_MBOX|MODE_BLOB;

    if (DebugFile.trace) {
      DebugFile.writeln("DBFolder.open("+String.valueOf(mode)+ ")");
      DebugFile.incIdent();
    }

    if ((0==(mode&READ_ONLY)) && (0==(mode&READ_WRITE))) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException("Folder must be opened in either READ_ONLY or READ_WRITE mode");
    }
    else if (ALL_OPTIONS!=(mode|ALL_OPTIONS)) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException("Invalid DBFolder open() option mode");
    } else {
      if ((0==(mode&MODE_MBOX)) && (0==(mode&MODE_BLOB)))
        mode |= MODE_MBOX;

      iOpenMode = mode;
      JDCConnection oConn = null;
      try {
        oConn = getConnection();
      } catch (SQLException sqle) {
      	throw new MessagingException(sqle.getMessage(), sqle);
      }
      if ((iOpenMode&MODE_MBOX)!=0) {
        String sFolderUrl;
        try {
          sFolderUrl = Gadgets.chomp(getStore().getURLName().getFile(), File.separator) + oCatg.getPath(oConn);
          if (DebugFile.trace) DebugFile.writeln("mail folder directory is " + sFolderUrl);
          if (sFolderUrl.startsWith("file://"))
            sFolderDir = sFolderUrl.substring(7);
          else
            sFolderDir = sFolderUrl;
          if (File.separator.equals("\\")) sFolderDir = sFolderDir.replace('/','\\');
        } catch (SQLException sqle) {
          iOpenMode = 0;
          oConn = null;
          if (DebugFile.trace) DebugFile.decIdent();
          throw new MessagingException (sqle.getMessage(), sqle);
        }
        try {
          File oDir = new File (sFolderDir);
          if (!oDir.exists()) {
            FileSystem oFS = new FileSystem();
            oFS.mkdirs(sFolderUrl);
          }
        } catch (IOException ioe) {
          iOpenMode = 0;
          oConn = null;
          if (DebugFile.trace) DebugFile.decIdent();
          throw new MessagingException (ioe.getMessage(), ioe);
        } catch (SecurityException se) {
          iOpenMode = 0;
          oConn = null;
          if (DebugFile.trace) DebugFile.decIdent();
          throw new MessagingException (se.getMessage(), se);
        } catch (Exception je) {
          iOpenMode = 0;
          oConn = null;
          if (DebugFile.trace) DebugFile.decIdent();
          throw new MessagingException (je.getMessage(), je);
        }

        // Create a ProductLocation pointing to the MBOX file if it does not exist
        try {
          oConn = getConnection();
        } catch (SQLException sqle) {
      	  throw new MessagingException(sqle.getMessage(), sqle);
        }
        PreparedStatement oStmt = null;
        ResultSet oRSet = null;
        boolean bHasFilePointer;

        try {
          oStmt = oConn.prepareStatement("SELECT NULL FROM "+DB.k_x_cat_objs+ " WHERE "+DB.gu_category+"=? AND "+DB.id_class+"=15",
                                         ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, getCategory().getString(DB.gu_category));
          oRSet = oStmt.executeQuery();
          bHasFilePointer = oRSet.next();
          oRSet.close();
          oRSet = null;
          oStmt.close();
          oStmt = null;

          if (!bHasFilePointer) {
            oConn.setAutoCommit(false);

            Product oProd = new Product();
            oProd.put(DB.gu_owner, oCatg.getString(DB.gu_owner));
            oProd.put(DB.nm_product, oCatg.getString(DB.nm_category));
            oProd.store(oConn);

            ProductLocation oLoca = new ProductLocation();
            oLoca.put(DB.gu_product, oProd.getString(DB.gu_product));
            oLoca.put(DB.gu_owner, oCatg.getString(DB.gu_owner));
            oLoca.put(DB.pg_prod_locat, 1);
            oLoca.put(DB.id_cont_type, 1);
            oLoca.put(DB.id_prod_type, "MBOX");
            oLoca.put(DB.len_file, 0);
            oLoca.put(DB.xprotocol, "file://");
            oLoca.put(DB.xhost, "localhost");
            oLoca.put(DB.xpath, Gadgets.chomp(sFolderDir, File.separator));
            oLoca.put(DB.xfile, oCatg.getString(DB.nm_category)+".mbox");
            oLoca.put(DB.xoriginalfile, oCatg.getString(DB.nm_category)+".mbox");
            oLoca.store(oConn);

            if (DebugFile.trace)
              DebugFile.writeln("JDCConection.prepareStatement(INSERT INTO "+DB.k_x_cat_objs+" ("+DB.gu_category+","+DB.gu_object+","+DB.id_class+") VALUES ('"+oCatg.getStringNull(DB.gu_category,"null")+"','"+oProd.getStringNull(DB.gu_product,"null")+"',15)");
 
            oStmt = oConn.prepareStatement("INSERT INTO "+DB.k_x_cat_objs+" ("+DB.gu_category+","+DB.gu_object+","+DB.id_class+") VALUES (?,?,15)");
            oStmt.setString(1, oCatg.getString(DB.gu_category));
            oStmt.setString(2, oProd.getString(DB.gu_product));
            oStmt.executeUpdate();
            oStmt.close();
            oStmt = null;

            oConn.commit();
          }
        }
        catch (SQLException sqle) {
          if (DebugFile.trace) {
            DebugFile.writeln("SQLException " + sqle.getMessage());
            DebugFile.decIdent();
          }
          if (oStmt!=null) { try { oStmt.close(); } catch (SQLException ignore) {} }
          if (oConn!=null) { try { oConn.rollback(); } catch (SQLException ignore) {} }
          throw new MessagingException(sqle.getMessage(), sqle);
        }
      }
      else {
        sFolderDir = null;
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        String sMode = "";
        if ((iOpenMode&READ_WRITE)!=0) sMode += " READ_WRITE ";
        if ((iOpenMode&READ_ONLY)!=0) sMode += " READ_ONLY ";
        if ((iOpenMode&MODE_BLOB)!=0) sMode += " MODE_BLOB ";
        if ((iOpenMode&MODE_MBOX)!=0) sMode += " MODE_MBOX ";
        DebugFile.writeln("End DBFolder.open()");
      }

    }
  } // open

  // ---------------------------------------------------------------------------

  /**
   * Close this folder
   * @param expunge
   * @throws MessagingException
   */
  public void close(boolean expunge) throws MessagingException {
    if (expunge) expunge();
    iOpenMode = 0;
    sFolderDir = null;
  }

  // ---------------------------------------------------------------------------

  /**
   * Wipe all messages and delete this folder
   * @param recurse boolean
   * @return boolean
   * @throws MessagingException
   */
  public boolean delete(boolean recurse) throws MessagingException {
    try {
      wipe();
      return oCatg.delete(getConnection());
    } catch (SQLException sqle) {
      throw new MessagingException(sqle.getMessage(), sqle);
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * Get folder by name or GUID
   * @param name String Folder name or GUID
   * @return Folder
   * @throws MessagingException
   */
  public Folder getFolder(String name) throws MessagingException {
    return ((DBStore) getStore()).getFolder(name);
  }

  // ---------------------------------------------------------------------------

  /**
   * This method is not implemented and will always raise UnsupportedOperationException
   * @throws UnsupportedOperationException
   */

  public boolean hasNewMessages() throws MessagingException {
    throw new UnsupportedOperationException("DBFolder.hasNewMessages()");
  }

  // ---------------------------------------------------------------------------

  public boolean renameTo(Folder f)
    throws MessagingException,StoreClosedException,NullPointerException {

    String[] aLabels = DBLanguages.SupportedLanguages;
    PreparedStatement oUpdt = null;

    if (!((DBStore)getStore()).isConnected())
      throw new StoreClosedException(getStore(), "Store is not connected");

    if (oCatg.isNull(DB.gu_category))
      throw new NullPointerException("Folder is closed");

    try {

      oUpdt = getConnection().prepareStatement("DELETE FROM " + DB.k_cat_labels + " WHERE " + DB.gu_category + "=?");
      oUpdt.setString(1, oCatg.getString(DB.gu_category));
      oUpdt.executeUpdate();
      oUpdt.close();

      oUpdt.getConnection().prepareStatement("INSERT INTO "+DB.k_cat_labels+" ("+DB.gu_category+","+DB.id_language+","+DB.tr_category+","+DB.url_category+") VALUES (?,?,?,NULL)");
      oUpdt.setString(1, oCatg.getString(DB.gu_category));

      for (int l=0; l<aLabels.length; l++) {
        oUpdt.setString(2, aLabels[l]);
        oUpdt.setString(3, f.getName().substring(0,1).toUpperCase()+f.getName().substring(1).toLowerCase());
        oUpdt.executeUpdate();
      }
      oUpdt.close();
      oUpdt=null;
      getConnection().commit();
    } catch (SQLException sqle) {
      try { if (null!=oUpdt) oUpdt.close(); } catch (SQLException ignore) {}
      try { getConnection().rollback(); } catch (SQLException ignore) {}
      throw new MessagingException(sqle.getMessage(), sqle);
    }
    return true;
  } // renameTo

  // ---------------------------------------------------------------------------

  public boolean exists() throws MessagingException,StoreClosedException {
    if (!((DBStore)getStore()).isConnected())
      throw new StoreClosedException(getStore(), "Store is not connected");

    try {
      return oCatg.exists(getConnection());
    } catch (SQLException sqle) {
      throw new MessagingException(sqle.getMessage(), sqle);
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Expunge deleted messages</p>
   * This method removes from the database and the MBOX file those messages flagged
   * as deleted at k_mime_msgs table
   * @return <b>null</b>
   * @throws MessagingException
   */
  @SuppressWarnings("unused")
public Message[] expunge() throws MessagingException {
    Statement oStmt = null;
    CallableStatement oCall = null;
    PreparedStatement oUpdt = null;
    PreparedStatement oPart = null;
    PreparedStatement oAddr = null;
    ResultSet oRSet;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.expunge()");
      DebugFile.incIdent();
    }

    // *************************************************************************
    // If Folder is not opened is read-write mode then raise an exception
    if (0==(iOpenMode&READ_WRITE)) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new javax.mail.FolderClosedException(this, "Folder is not open is READ_WRITE mode");
    }

    if ((0==(iOpenMode&MODE_MBOX)) && (0==(iOpenMode&MODE_BLOB))) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new javax.mail.FolderClosedException(this, "Folder is not open in MBOX nor BLOB mode");
    }

    // ***********************************************
    // First delete the empty messages
    // (used for clearing drafts that have no contents)

	DBSubset oEmptyDrafts = new DBSubset (DB.k_mime_msgs+" m",
										  "m."+DB.gu_mimemsg,
										  "m."+DB.gu_category+"=? AND m."+DB.gu_workarea+"=? AND " +
      	                                  "m." + DB.bo_deleted + "<>1 AND m." + DB.gu_parent_msg + " IS NULL AND " +
      	                                  DBBind.Functions.LENGTH+"("+DBBind.Functions.ISNULL+"(m."+DB.tx_subject+",''))=0 AND " +
      	                                  "m."+DB.len_mimemsg + "=0 AND NOT EXISTS (SELECT p." + DB.gu_mimemsg + " FROM " +
      	                                  DB.k_mime_parts + " p WHERE m." + DB.gu_mimemsg + "=p." + DB.gu_mimemsg + ")" , 10);
    int iEmptyDrafts = 0;
    
    JDCConnection oConn = null;

    try {
      oConn = getConnection();
      iEmptyDrafts = oEmptyDrafts.load(oConn, new Object[]{getCategoryGuid(),((DBStore)getStore()).getUser().getString(DB.gu_workarea)});
    } catch (SQLException sqle) {
	  throw new MessagingException(sqle.getMessage(), sqle);
    }
    
    if (iEmptyDrafts>0) {
	  sSQL = "UPDATE " + DB.k_mime_msgs + " SET " + DB.bo_deleted + "=1 WHERE " + DB.gu_mimemsg + "=?";
    
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    
      try {
        oUpdt = oConn.prepareStatement(sSQL);
        for (int d=0; d<iEmptyDrafts; d++) {
          oUpdt.setString(1,oEmptyDrafts.getString(0,d));
	      oUpdt.executeUpdate();
        } // next
	    oUpdt.close();
      } catch (SQLException sqle) {
	    throw new MessagingException(sqle.getMessage(), sqle);
      }
    } // fi

    // ***********************************************
    // Get the list of deleted and not purged messages

    MboxFile oMBox = null;
    DBSubset oDeleted = new DBSubset(DB.k_mime_msgs,
                                     DB.gu_mimemsg+","+DB.pg_message,
                                     DB.bo_deleted+"=1 AND "+DB.gu_category+"='"+oCatg.getString(DB.gu_category)+"'", 100);

    try {
      int iDeleted = oDeleted.load(oConn);

      File oFile = getFile();

      // *************************************
      // Purge deleted messages from MBOX file

      if (oFile.exists() && iDeleted>0) {
        oMBox = new MboxFile(oFile, MboxFile.READ_WRITE);
        int[] msgnums = new int[iDeleted];
        for (int m=0; m<iDeleted; m++)
          msgnums[m] = oDeleted.getInt(1, m);
        oMBox.purge(msgnums);
        oMBox.close();
      }

      // *********************************************************
      // Remove from disk the files referenced by deleted messages

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      
      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(SELECT p." + DB.file_name + " FROM " + DB.k_mime_parts + " p," + DB.k_mime_msgs + " m WHERE p." + DB.gu_mimemsg + "=m."+ DB.gu_mimemsg + " AND m." + DB.id_disposition + "='reference' AND m." + DB.bo_deleted + "=1 AND m." + DB.gu_category +"='"+oCatg.getString(DB.gu_category)+"')");

      oRSet = oStmt.executeQuery("SELECT p." + DB.id_part + ",p." + DB.id_type + ",p." + DB.file_name + " FROM " + DB.k_mime_parts + " p," + DB.k_mime_msgs + " m WHERE p." +
      	                         DB.gu_mimemsg + "=m."+ DB.gu_mimemsg + " AND m." + DB.id_disposition + "='reference' AND m." +
      	                         DB.bo_deleted + "=1 AND m." + DB.gu_category +"='"+oCatg.getString(DB.gu_category)+"'");

      while (oRSet.next()) {
      	if (DebugFile.trace) DebugFile.writeln("processing part "+String.valueOf(oRSet.getInt(1))+" "+oRSet.getString(2));
        String sFileName = oRSet.getString(3);
        if (!oRSet.wasNull()) {
          if (DebugFile.trace) DebugFile.writeln("trying to delete file "+sFileName);
          try {
            File oRef = new File(sFileName);
            if (oRef.exists())
              oRef.delete();
            else if (DebugFile.trace)
              DebugFile.writeln("file "+sFileName+" not found");            
          }
          catch (SecurityException se) {
            if (DebugFile.trace) DebugFile.writeln("SecurityException deleting file " + sFileName + " " + se.getMessage());
          }
        }
      } // wend

      oRSet.close();
      oRSet = null;
      oStmt.close();
      oStmt = null;

      // ****************************************************
      // Set Category size to length of MBOX file after purge

      oFile = getFile();
      oStmt = oConn.createStatement();
      oStmt.executeUpdate("UPDATE "+DB.k_categories+" SET "+DB.len_size+"="+String.valueOf(oFile.length())+" WHERE "+DB.gu_category+"='"+getCategory().getString(DB.gu_category)+"'");
      oStmt.close();
      oStmt=null;

      // *********************************************
      // Actually delete messages from database tables

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oStmt = oConn.createStatement();
        for (int d=0; d<iDeleted; d++)
          oStmt.executeQuery("SELECT k_sp_del_mime_msg('" + oDeleted.getString(0,d) + "')");
        oStmt.close();
        oStmt=null;
      }
      else {
        oCall = oConn.prepareCall("{ call k_sp_del_mime_msg(?) }");

        for (int d=0; d<iDeleted; d++) {
          oCall.setString(1, oDeleted.getString(0,d));
          oCall.execute();
        } // next
        oCall.close();
        oCall=null;
      }

      if (oFile.exists() && iDeleted>0) {

        // ***********************************************************************
        // Temporary move all messages at k_mime_msgs, k_mime_parts & k_inet_addrs
        // beyond its maximum so they do not clash when progressive identifiers
        // are re-assigned

        BigDecimal oUnit = new BigDecimal(1);
        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oRSet = oStmt.executeQuery("SELECT MAX("+DB.pg_message+") FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_category+"='"+getCategory().getString(DB.gu_category)+"'");
        oRSet.next();
        BigDecimal oMaxPg = oRSet.getBigDecimal(1);
        if (oRSet.wasNull()) oMaxPg = new BigDecimal(0);
        oRSet.close();
        oRSet = null;
        oStmt.close();
        oStmt = null;
        oMaxPg = oMaxPg.add(oUnit);

        String sCat = getCategory().getString(DB.gu_category);
        oStmt = oConn.createStatement();
        oStmt.executeUpdate("UPDATE "+DB.k_mime_msgs+" SET "+DB.pg_message+"="+DB.pg_message+"+"+oMaxPg.toString()+" WHERE "+DB.gu_category+"='"+sCat+"'");
        oStmt.close();
        oStmt = null;

        // *********************************************************************************
        // Re-assign ordinal position and byte offset for all messages remaining after purge

        DBSubset oMsgSet = new DBSubset(DB.k_mime_msgs,
        		                        DB.gu_mimemsg+","+DB.pg_message, DB.gu_category+"='"+getCategory().getString(DB.gu_category)+
        		                        "' ORDER BY "+DB.pg_message, 1000);
        final int iMsgCount = oMsgSet.load(oConn);

        if (iMsgCount>0) {
          oMBox = new MboxFile(oFile, MboxFile.READ_ONLY);
          long[] aPositions = oMBox.getMessagePositions();
          oMBox.close();
        
          if (iMsgCount!=aPositions.length)
            throw new SQLException("There are "+String.valueOf(iMsgCount)+" messages indexed at folder "+getCategory().getString(DB.gu_category)+" but MBOX file contains "+String.valueOf(aPositions.length)+" messages execute DBFolder.reindexMbox() for reconstructing the index");

          oMaxPg = new BigDecimal(0);
          oUpdt = oConn.prepareStatement("UPDATE "+DB.k_mime_msgs+" SET "+DB.pg_message+"=?,"+DB.nu_position+"=? WHERE "+DB.gu_mimemsg+"=?");
          oPart = oConn.prepareStatement("UPDATE "+DB.k_mime_parts+" SET "+DB.pg_message+"=? WHERE "+DB.gu_mimemsg+"=?");
          oAddr = oConn.prepareStatement("UPDATE "+DB.k_inet_addrs+" SET "+DB.pg_message+"=? WHERE "+DB.gu_mimemsg+"=?");
          for (int m=0; m<iMsgCount; m++) {
            String sGuMsg = oMsgSet.getString(0,m);
            oUpdt.setBigDecimal(1, oMaxPg);
            oUpdt.setBigDecimal(2, new BigDecimal(aPositions[m]));
            oUpdt.setString(3, sGuMsg);
            oUpdt.executeUpdate();
            oPart.setBigDecimal(1, oMaxPg);
            oPart.setString(2, sGuMsg);
            oPart.executeUpdate();
            oAddr.setBigDecimal(1, oMaxPg);
            oAddr.setString(2, sGuMsg);
            oAddr.executeUpdate();
            oMaxPg = oMaxPg.add(oUnit);
          }
          oUpdt.close();
          oPart.close();
          oAddr.close();
        }
      }
      oConn.commit();
    } catch (SQLException sqle) {
      try { if (oMBox!=null) oMBox.close(); } catch (Exception e) {}
      try { if (oStmt!=null) oStmt.close(); } catch (Exception e) {}
      try { if (oCall!=null) oCall.close(); } catch (Exception e) {}
      try { if (oConn!=null) oConn.rollback(); } catch (Exception e) {}
      throw new MessagingException (sqle.getMessage(), sqle);
    }
    catch (IOException sqle) {
      try { if (oMBox!=null) oMBox.close(); } catch (Exception e) {}
      try { if (oStmt!=null) oStmt.close(); } catch (Exception e) {}
      try { if (oCall!=null) oCall.close(); } catch (Exception e) {}
      try { if (oConn!=null) oConn.rollback(); } catch (Exception e) {}
      throw new MessagingException (sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.expunge()");
    }

    return null;
  } // expunge

  // ---------------------------------------------------------------------------

  /**
   * Delete all messages from this folder and clear MBOX file
   * @throws MessagingException
   */
  @SuppressWarnings("unused")
public void wipe() throws MessagingException {
    Statement oStmt = null;
    CallableStatement oCall = null;
    ResultSet oRSet;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.wipe()");
      DebugFile.incIdent();
    }

    // *************************************************************************
    // If Folder is not opened is read-write mode then raise an exception
    if (0==(iOpenMode&READ_WRITE)) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new javax.mail.FolderClosedException(this, "Folder is not open is READ_WRITE mode");
    }

    if ((0==(iOpenMode&MODE_MBOX)) && (0==(iOpenMode&MODE_BLOB))) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new javax.mail.FolderClosedException(this, "Folder is not open in MBOX nor BLOB mode");
    }

    // *************************************************
    // Get the list of all messages stored at this folder

    MboxFile oMBox = null;
    DBSubset oDeleted = new DBSubset(DB.k_mime_msgs, DB.gu_mimemsg+","+DB.pg_message, DB.gu_category+"='"+oCatg.getString(DB.gu_category)+"'", 100);
    JDCConnection oConn = null;

    try {
	  oConn = getConnection();
      int iDeleted = oDeleted.load(oConn);
      if (DebugFile.trace) DebugFile.writeln("there are "+String.valueOf(iDeleted)+" messages to be deleted");

      // ****************************************
      // Erase files referenced by draft messages	  
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT p." + DB.file_name + " FROM " + DB.k_mime_parts + " p," + DB.k_mime_msgs + " m WHERE p." + DB.gu_mimemsg + "=m."+ DB.gu_mimemsg + " AND m." + DB.id_disposition + "='reference' AND m." + DB.bo_deleted + "=1 AND m." + DB.gu_category +"='"+oCatg.getString(DB.gu_category)+"')");
      oRSet = oStmt.executeQuery("SELECT p." + DB.file_name + " FROM " + DB.k_mime_parts + " p," + DB.k_mime_msgs + " m WHERE p." + DB.gu_mimemsg + "=m."+ DB.gu_mimemsg + " AND m." + DB.id_disposition + "='reference' AND m." + DB.bo_deleted + "=1 AND m." + DB.gu_category +"='"+oCatg.getString(DB.gu_category)+"'");

      while (oRSet.next()) {
        String sFileName = oRSet.getString(1);
        if (!oRSet.wasNull()) {
          try {
            File oRef = new File(sFileName);
            if (oRef.exists()) oRef.delete();
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

      // *************************
      // Set Category size to zero

      oStmt = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(UPDATE "+DB.k_categories+" SET "+DB.len_size+"=0 WHERE "+DB.gu_category+"='"+getCategory().getString(DB.gu_category)+"')");
      oStmt.executeUpdate("UPDATE "+DB.k_categories+" SET "+DB.len_size+"=0 WHERE "+DB.gu_category+"='"+getCategory().getString(DB.gu_category)+"'");
      oStmt.close();
      oStmt=null;

      // *********************************************
      // Actually delete messages from database tables

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        oStmt = oConn.createStatement();
        for (int d=0; d<iDeleted; d++)
          oStmt.executeQuery("SELECT k_sp_del_mime_msg('" + oDeleted.getString(0,d) + "')");
        oStmt.close();
        oStmt=null;
      }
      else {
        oCall = oConn.prepareCall("{ call k_sp_del_mime_msg(?) }");

        for (int d=0; d<iDeleted; d++) {
          oCall.setString(1, oDeleted.getString(0,d));
          oCall.execute();
        } // next
        oCall.close();
        oCall=null;
      }

      // *************************************
      // Truncate MBOX file

      File oFile = getFile();
      if (oFile.exists()) {
        if (DebugFile.trace) DebugFile.writeln("File.delete("+getFilePath()+")");
        oFile.delete();
      }

      if (DebugFile.trace) DebugFile.writeln("Connection.commit()");

      oConn.commit();
    } catch (Exception sqle) {
      try { if (oMBox!=null) oMBox.close(); } catch (Exception e) {}
      try { if (oStmt!=null) oStmt.close(); } catch (Exception e) {}
      try { if (oCall!=null) oCall.close(); } catch (Exception e) {}
      try { if (oConn!=null) oConn.rollback(); } catch (Exception e) {}
      throw new MessagingException (sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.wipe()");
    }
  } // wipe

  // ---------------------------------------------------------------------------

  /**
   * <p>Get category subpath to directory holding MBOX files for this folder</p>
   * The category path is composed by concatenating the names of all the parent
   * folders separated by a slash. The name of a folder is stored at column nm_category
   * of table k_categories
   * @return String
   */
  public String getFullName() {
    try {
      if (oCatg.exists(getConnection()))
        return oCatg.getPath(getConnection());
      else
        return null;
    } catch (Exception sqle) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * Get path to directory containing files belonging to this folder
   * @return String
   */
  public String getDirectoryPath() {
    return Gadgets.chomp(sFolderDir, File.separator);
  }

  // ---------------------------------------------------------------------------

  /**
   * Get full path to MBOX file containing mime messages
   * @return String
   * @throws NullPointerException
   */
  public String getFilePath() throws NullPointerException {
	if (null==sFolderDir)
      throw new NullPointerException("DBFolder.getFilePath() directory of MBOX file is not set");
	if (oCatg.isNull(DB.nm_category))
	  throw new NullPointerException("DBFolder.getFilePath() MBOX file name is not set");
    return Gadgets.chomp(sFolderDir, File.separator)+oCatg.getString(DB.nm_category)+".mbox";
  }

  // ---------------------------------------------------------------------------

  /**
   * Get MBOX file that holds messages for this DBFolder
   * @return java.io.File object representing MBOX file.
   * @throws NullPointerException
   */
  public File getFile() {
    return new File(getFilePath());
  }

  // ---------------------------------------------------------------------------

  /**
   * Get column nm_category from table k_categories for this folder
   * @return String
   */
  public String getName() {
    return sFolderName==null ? oCatg.getString(DB.nm_category) : sFolderName;
  }

  // ---------------------------------------------------------------------------

  public URLName getURLName()
    throws MessagingException,StoreClosedException {

    if (!((DBStore)getStore()).isConnected())
      throw new StoreClosedException(getStore(), "Store is not connected");

    com.knowgate.acl.ACLUser oUsr = ((DBStore)getStore()).getUser();
    return new URLName("jdbc://", "localhost", -1, oCatg.getString(DB.gu_category), oUsr.getString(DB.gu_user), oUsr.getString(DB.tx_pwd));
  }

  // ---------------------------------------------------------------------------

  @SuppressWarnings("unused")
protected Message getMessage(String sMsgId, int IdType)
    throws MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.getMessage(" + sMsgId + "," + String.valueOf(IdType) + ")");
      DebugFile.incIdent();
    }

    // *************************************************************************
    // If Folder is not opened then raise an exception
    if (!isOpen()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new javax.mail.FolderClosedException(this, "Folder is closed");
    }

    DBMimeMessage oRetVal = null;

    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    String sSQL = "";
    Timestamp tsSent;
    String sMsgGuid, sContentId, sMsgDesc, sMsgDisposition, sMsgMD5, sMsgSubject, sMsgFrom, sReplyTo, sDisplayName;
    short iAnswered, iDeleted, iDraft, iFlagged, iRecent, iSeen;
    final String sColList =  DB.gu_mimemsg+","+DB.id_message+","+DB.id_disposition+","+
                             DB.tx_md5+","+DB.de_mimemsg+","+DB.tx_subject+","+
                             DB.dt_sent+","+DB.bo_answered+","+DB.bo_deleted+","+
                             DB.bo_draft+","+DB.bo_flagged+","+DB.bo_recent+","+
                             DB.bo_seen+","+DB.tx_email_from+","+DB.tx_email_reply+","+
                             DB.nm_from+","+DB.by_content;
    InternetAddress oFrom = null, oReply = null;
    MimeMultipart oParts = new MimeMultipart();
	JDCConnection oConn = null;
	
    try {
      oConn = getConnection();
      switch (IdType) {
        case 1:
          sSQL = "SELECT "+sColList+" FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_mimemsg + "=?";
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");

          oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, sMsgId);
          break;
        case 2:
          sSQL = "SELECT "+sColList+" FROM " + DB.k_mime_msgs + " WHERE " + DB.id_message + "=?";
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");

          oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setString(1, sMsgId);
          break;
        case 3:
          sSQL = "SELECT "+sColList+" FROM " + DB.k_mime_msgs + " WHERE " + DB.pg_message + "=?";
          if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");

          oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oStmt.setBigDecimal(1, new java.math.BigDecimal(sMsgId));
          break;
      }

      if (DebugFile.trace) DebugFile.writeln("ResultSet = PreparedStatement.executeQuery("+sSQL+")");

      oRSet = oStmt.executeQuery();

      if (oRSet.next()) {
        sMsgGuid = oRSet.getString(1);
        sContentId = oRSet.getString(2);

        if (DebugFile.trace) {
          DebugFile.writeln("gu_mimemsg="+sMsgGuid);
          DebugFile.writeln("id_message="+sContentId);
        }
        
        sMsgDisposition = oRSet.getString(3);
        sMsgMD5 = oRSet.getString(4);
        sMsgDesc = oRSet.getString(5);
        sMsgSubject = oRSet.getString(6);
        tsSent = oRSet.getTimestamp(7);
        iAnswered=oRSet.getShort(8);
        iDeleted=oRSet.getShort(9);
        iDraft=oRSet.getShort(10);
        iFlagged=oRSet.getShort(11);
        iRecent=oRSet.getShort(12);
        iSeen=oRSet.getShort(13);
        sMsgFrom = oRSet.getString(14);
        sReplyTo = oRSet.getString(15);
        sDisplayName = oRSet.getString(16);

        if (DebugFile.trace) DebugFile.writeln("ResultSet.getBinaryStream("+DB.by_content+")");

        InputStream oLongVarBin = oRSet.getBinaryStream(17);

        if (!oRSet.wasNull()) {
          if (DebugFile.trace) DebugFile.writeln("MimeMultipart.addBodyPart(new MimeBodyPart(InputStream)");
          oParts.addBodyPart(new MimeBodyPart(oLongVarBin));
        }

        oRSet.close();
        oRSet = null;

        oRetVal = new DBMimeMessage(this, sMsgGuid);

        oRetVal.setContentID(sContentId);
        oRetVal.setDisposition(sMsgDisposition);
        oRetVal.setContentMD5(sMsgMD5);
        oRetVal.setDescription(sMsgDesc);

        if (sMsgSubject!=null) {
          if (sMsgSubject.length()>0) {
            if (DebugFile.trace) DebugFile.writeln("tx_subject="+sMsgSubject);
            oRetVal.setSubject(sMsgSubject);
          }
        }

        oRetVal.setSentDate(tsSent);
        oRetVal.setFlag(Flags.Flag.ANSWERED, iAnswered!=0);
        oRetVal.setFlag(Flags.Flag.DELETED, iDeleted!=0);
        oRetVal.setFlag(Flags.Flag.DRAFT, iDraft!=0);
        oRetVal.setFlag(Flags.Flag.FLAGGED, iFlagged!=0);
        oRetVal.setFlag(Flags.Flag.RECENT, iRecent!=0);
        oRetVal.setFlag(Flags.Flag.SEEN, iSeen!=0);

        if (sMsgFrom!=null) {
          if (DebugFile.trace) DebugFile.writeln("from: "+sMsgFrom);
          if (null==sDisplayName)
            oFrom = new InternetAddress(sMsgFrom);
          else
            oFrom = new InternetAddress(sMsgFrom, sDisplayName);
          oRetVal.setFrom(oFrom);
        }

        if (sReplyTo!=null) {
          if (DebugFile.trace) DebugFile.writeln("reply to: "+sReplyTo);
          oReply = new InternetAddress(sReplyTo);
          oRetVal.setReplyTo(new Address[]{oReply});
        }

        oRetVal.setRecipients(Message.RecipientType.TO, oRetVal.getRecipients(Message.RecipientType.TO));
        oRetVal.setRecipients(Message.RecipientType.CC, oRetVal.getRecipients(Message.RecipientType.CC));
        oRetVal.setRecipients(Message.RecipientType.BCC, oRetVal.getRecipients(Message.RecipientType.BCC));

        if (DebugFile.trace) DebugFile.writeln("MimeMessage.setContent(MimeMultipart)");

        oRetVal.setContent(oParts);
      } else {
	    if (DebugFile.trace) DebugFile.writeln("Message "+sMsgId+" not found at "+DB.k_mime_msgs+" table");
        oRSet.close();
        oRSet = null;
      }// fi (oRSet.next())

	  if (DebugFile.trace) DebugFile.writeln("PreparedStatement.close()");
      oStmt.close();
      oStmt = null;

    } catch (SQLException sqle) {

      if (DebugFile.trace) {
        DebugFile.writeln("SQLException "+sqle.getMessage());
        DebugFile.writeln(sSQL);
        try { DebugFile.writeln(StackTraceUtil.getStackTrace(sqle)); } catch (IOException ignore) { }
        DebugFile.decIdent();
      }

      try { if (oRSet!=null) oRSet.close(); } catch (SQLException ignore) { }
      try { if (oStmt!=null) oStmt.close(); } catch (SQLException ignore) { }

      throw new MessagingException (sqle.getMessage(), sqle);
    }
    catch (UnsupportedEncodingException uee) {

      if (DebugFile.trace) {
        DebugFile.writeln("UnsupportedEncodingException "+uee.getMessage());
        DebugFile.decIdent();
      }

      try { if (oRSet!=null) oRSet.close(); } catch (SQLException ignore) { }
      try { if (oStmt!=null) oStmt.close(); } catch (SQLException ignore) { }

      throw new MessagingException (uee.getMessage(), uee);
    }

    if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DBFolder.getMessage() : " + (oRetVal!=null ? "[MimeMessage]" : "null"));
    }

    return oRetVal;
  } // getMessage

  // ---------------------------------------------------------------------------

  private void saveMimeParts (JDCConnection oConn, MimeMessage oMsg, String sMsgCharSeq,
                              String sBoundary, String sMsgGuid,
                              String sMsgId, int iPgMessage, int iOffset)
    throws MessagingException,OutOfMemoryError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.saveMimeParts([Connection], [MimeMessage], " + sBoundary + ", " + sMsgGuid + "," + sMsgId + ", " + String.valueOf(iPgMessage) + ", " + String.valueOf(iOffset) + ", [Properties])");
      DebugFile.incIdent();
    }

    PreparedStatement oStmt = null;
    Blob oContentTxt;
    ByteArrayOutputStream byOutPart;
    int iPrevPart = 0, iThisPart = 0, iNextPart = 0, iPartStart = 0;

    try {
      MimeMultipart oParts = (MimeMultipart) oMsg.getContent();

      final int iParts = oParts.getCount();

      if (DebugFile.trace) DebugFile.writeln("message has " + String.valueOf(iParts) + " parts");

      if (iParts>0) {
        // Skip boundary="..."; from Mime header
        // and boundaries from all previous parts
        if (sMsgCharSeq!=null && sBoundary!=null && ((iOpenMode&MODE_MBOX)!=0)) {
          // First boundary substring acurrence is the one from the message headers
          iPrevPart = sMsgCharSeq.indexOf(sBoundary, iPrevPart);
          if (iPrevPart>0) {
            iPrevPart += sBoundary.length();
            if (DebugFile.trace) DebugFile.writeln("found message boundary token at " + String.valueOf(iPrevPart));
          } // fi (message boundary)
        } // fi (sMsgCharSeq && sBoundary)

        String sSQL = "INSERT INTO " + DB.k_mime_parts + "(gu_mimemsg,id_message,pg_message,nu_offset,id_part,id_content,id_type,id_disposition,len_part,de_part,tx_md5,file_name,by_content) VALUES ('"+sMsgGuid+"',?,?,?,?,?,?,?,?,?,NULL,?,?)";

        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

        oStmt = oConn.prepareStatement(sSQL);

        for (int p = 0; p < iParts; p++) {
          if (DebugFile.trace) {
            DebugFile.writeln("processing part " + String.valueOf(p));
            DebugFile.writeln("previous part at " + String.valueOf(iPrevPart));
            DebugFile.writeln("part boundary is " + sBoundary);
            if (null==sMsgCharSeq) DebugFile.writeln("characer sequence is null");
          }

          BodyPart oPart = oParts.getBodyPart(p);
          byOutPart = new ByteArrayOutputStream(oPart.getSize() > 0 ? oPart.getSize() : 131072);
          oPart.writeTo(byOutPart);

          if (sMsgCharSeq!=null && sBoundary!=null && iPrevPart>0) {
            iThisPart = sMsgCharSeq.indexOf(sBoundary, iPrevPart);
            if (iThisPart>0) {
              if (DebugFile.trace) DebugFile.writeln("found part " + String.valueOf(p+iOffset) + " boundary at " + String.valueOf(iThisPart));
              iPartStart = iThisPart + sBoundary.length();
              while (iPartStart<sMsgCharSeq.length()) {
                if (sMsgCharSeq.charAt(iPartStart)!=' ' && sMsgCharSeq.charAt(iPartStart)!='\r' && sMsgCharSeq.charAt(iPartStart)!='\n' && sMsgCharSeq.charAt(iPartStart)!='\t')
                  break;
                else
                  iPartStart++;
              } // wend
            }
            iNextPart = sMsgCharSeq.indexOf(sBoundary, iPartStart);
            if (iNextPart<0)  {
              if (DebugFile.trace) DebugFile.writeln("no next part found");
              iNextPart = sMsgCharSeq.length();
            }
            else {
              if (DebugFile.trace) DebugFile.writeln("next part boundary found at " + String.valueOf(iNextPart));
            }
          } // fi (sMsgCharSeq!=null && sBoundary!=null && iPrevPart>0)

          String sContentType = oPart.getContentType();
          if (sContentType!=null) sContentType = MimeUtility.decodeText(sContentType);

          boolean bForwardedAttachment = false;

          if ((null!=sContentType) && (null!=((DBStore) getStore()).getSession())) {
            if (DebugFile.trace) DebugFile.writeln("Part Content-Type: " + sContentType.replace('\r',' ').replace('\n',' '));

            if (sContentType.toUpperCase().startsWith("MULTIPART/ALTERNATIVE") ||
              sContentType.toUpperCase().startsWith("MULTIPART/RELATED") ||
              sContentType.toUpperCase().startsWith("MULTIPART/SIGNED")) {
              try {
                ByteArrayInputStream byInStrm = new ByteArrayInputStream(byOutPart.toByteArray());

                MimeMessage oForwarded = new MimeMessage (((DBStore) getStore()).getSession(), byInStrm);

                saveMimeParts (oConn, oForwarded, sMsgCharSeq, getPartsBoundary(oForwarded), sMsgGuid, sMsgId, iPgMessage, iOffset+iParts);

                byInStrm.close();
                byInStrm = null;

                bForwardedAttachment = true;
              }
              catch (Exception e) {
               if (DebugFile.trace) DebugFile.writeln(e.getClass().getName() + " " + e.getMessage());
              }
            } // fi (MULTIPART/ALTERNATIVE)
          } // fi (null!=sContentType && null!=getSession())

          if (!bForwardedAttachment) {
            if (DebugFile.trace) {
              if ((iOpenMode&MODE_MBOX)!=0) {
                DebugFile.writeln("MBOX mode");
                DebugFile.writeln("nu_offset=" + String.valueOf(iPartStart));
                DebugFile.writeln("nu_len=" + String.valueOf(iNextPart-iPartStart));
              } else if ((iOpenMode&MODE_BLOB)!=0) {
                DebugFile.writeln("BLOB mode");
                DebugFile.writeln("nu_offset=null");
                DebugFile.writeln("nu_len=" + String.valueOf(oPart.getSize() > 0 ? oPart.getSize() : byOutPart.size()));
              }
              DebugFile.writeln("id_message=" + sMsgId);
              DebugFile.writeln("id_part=" + String.valueOf(p+iOffset));
              DebugFile.writeln("pg_message=" + String.valueOf(iPgMessage));
            }

            oStmt.setString(1, sMsgId); // id_message
            oStmt.setBigDecimal(2, new BigDecimal(iPgMessage)); // pg_message

            if ((iPartStart>0) && ((iOpenMode&MODE_MBOX)!=0))
              oStmt.setBigDecimal(3, new BigDecimal(iPartStart)); // nu_offset
            else
              oStmt.setNull(3, oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE ? Types.NUMERIC : Types.DECIMAL);

            oStmt.setInt(4, p+iOffset); // id_part
            oStmt.setString(5, ((javax.mail.internet.MimeBodyPart) oPart).getContentID()); // id_content
            oStmt.setString(6, Gadgets.left(sContentType, 254)); // id_type
            oStmt.setString(7, Gadgets.left(oPart.getDisposition(), 100));

            if ((iOpenMode&MODE_MBOX)!=0)
              oStmt.setInt(8, iNextPart-iPartStart);
            else
              oStmt.setInt(8, oPart.getSize() > 0 ? oPart.getSize() : byOutPart.size());

            if (oPart.getDescription()!=null)
              oStmt.setString(9, Gadgets.left(MimeUtility.decodeText(oPart.getDescription()), 254));
            else
              oStmt.setNull(9, Types.VARCHAR);

            if (DebugFile.trace) DebugFile.writeln("file name is " + oPart.getFileName());

            if (oPart.getFileName()!=null)
              oStmt.setString(10, Gadgets.left(MimeUtility.decodeText(oPart.getFileName()), 254));
            else
              oStmt.setNull(10, Types.VARCHAR);

            if ((iOpenMode&MODE_BLOB)!=0)
              oStmt.setBinaryStream(11, new ByteArrayInputStream(byOutPart.toByteArray()),byOutPart.size());
            else
              oStmt.setNull (11, Types.LONGVARBINARY);

            if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

            oStmt.executeUpdate();
          } // fi (bForwardedAttachment)

          byOutPart.close();
          byOutPart = null;
          oContentTxt = null;

          if ((iOpenMode&MODE_MBOX)!=0) iPrevPart = iNextPart;

        } // next (p)

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.close()");
        oStmt.close();
      } // fi (iParts>0)
    } catch (SQLException e) {
      if (DebugFile.trace) {
        DebugFile.writeln("SQLException " + e.getMessage());
        DebugFile.decIdent();
      }
      // Ensure that statement is closed and re-throw
      if (null!=oStmt) { try {oStmt.close();} catch (Exception ignore) {} }
      try { if (null!=oConn) oConn.rollback(); } catch (Exception ignore) {}
      throw new MessagingException (e.getMessage(), e);
    }
    catch (IOException e) {
      if (DebugFile.trace) {
        DebugFile.writeln("IOException " + e.getMessage());
        DebugFile.decIdent();
      }
      // Ensure that statement is closed and re-throw
      if (null!=oStmt) { try {oStmt.close();} catch (Exception ignore) {} }
      throw new MessagingException (e.getMessage(), e);
    }
    catch (Exception e) {
      if (DebugFile.trace) {
        DebugFile.writeln(e.getClass().getName() + " " + e.getMessage());
        DebugFile.decIdent();
      }
      // Ensure that statement is closed and re-throw
      if (null!=oStmt) { try {oStmt.close();} catch (Exception ignore) {} }
      throw new MessagingException (e.getMessage(), e);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.saveMimeParts()");
    }
  } // saveMimeParts

  // ---------------------------------------------------------------------------

  private static String getPartsBoundary(MimeMessage oMsg) throws MessagingException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.getPartsBoundary([MimeMessage])");
      DebugFile.incIdent();
    }

    String sBoundary = null;
    String sContentType = oMsg.getContentType();

    if (DebugFile.trace) DebugFile.writeln("Content-Type: "+sContentType);

    if (null!=sContentType) {
      int iTypeLen = sContentType.length();
      // Find first occurrence of "boundary" substring
      int iBoundary = sContentType.toLowerCase().indexOf("boundary");
      if (iBoundary>0) {
        // If "boundary" is found find first equals sign
        int iEq = sContentType.indexOf("=",iBoundary+8);
        if (iEq>0) {
          iEq++;
          // If equals sign is found skip any blank spaces and quotes
          while (iEq<iTypeLen) {
            char cAt = sContentType.charAt(iEq);
            if (cAt!=' ' && cAt!='"')
              break;
            else
              iEq++;
          }  // wend
          if (iEq<iTypeLen) {
            int iEnd = iEq;
            // Look forward in character sequence until quote, semi-colon or new line is found
            while (iEnd<iTypeLen) {
              char cAt = sContentType.charAt(iEnd);
              if (cAt!='"' && cAt!=';' && cAt!='\r' && cAt!='\n' && cAt!='\t')
                iEnd++;
              else
                break;
            }  // wend
            if (iEnd==iTypeLen)
              sBoundary = sContentType.substring(iEq);
            else
              sBoundary = sContentType.substring(iEq, iEnd);
          }
        } // fi (indexOf("="))
      } // fi (indexOf("boundary"))
    } // fi (sContentType)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.getPartsBoundary() : " + sBoundary);
    }

    return sBoundary;
  } // getPartsBoundary

  // ---------------------------------------------------------------------------

  private synchronized BigDecimal getNextMessage(JDCConnection oConn) throws MessagingException {
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    BigDecimal oNext;
	
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin DBFolder.getNextMessage([JDCConnection])");
	  DebugFile.incIdent();
	}

    try {

      oStmt = oConn.prepareStatement("SELECT MAX("+DB.pg_message+") FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_category+"=?",
                                     ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, getCategory().getString(DB.gu_category));
      oRSet = oStmt.executeQuery();
      oRSet.next();
      oNext = oRSet.getBigDecimal(1);
      if (oRSet.wasNull())
        oNext = new BigDecimal(0);
      else
        oNext = oNext.add(new BigDecimal(1));
      oRSet.close();
      oRSet=null;
      oStmt.close();
      oStmt=null;
    } catch (Exception xcpt) {
	  if (DebugFile.trace) DebugFile.decIdent();
      try { if (null!=oRSet) oRSet.close(); } catch (Exception ignore) {}
      try { if (null!=oStmt) oStmt.close(); } catch (Exception ignore) {}
      throw new MessagingException(xcpt.getMessage(),xcpt);
    }

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End DBFolder.getNextMessage() : "+oNext.toString());
	}

    return oNext;
  } // getNextMessage()

  // ---------------------------------------------------------------------------

  private  void  indexMessage(String sGuMimeMsg, String sGuWorkArea,
                              MimeMessage oMsg, Integer iSize,
                              BigDecimal dPosition, String sContentType,
                              String sContentID, String sMessageID,
                              String sDisposition, String sContentMD5,
                              String sDescription, String sFileName,
                              String sEncoding, String sSubject,
                              String sPriority, Flags oFlgs,
                              Timestamp tsSent, Timestamp tsReceived,
                              InternetAddress oFrom, InternetAddress oReply,
                              Address[] oTo, Address[] oCC, Address[] oBCC,
                              boolean bIsSpam, ByteArrayOutputStream byOutStrm,
                              String sMsgCharSeq)
    throws MessagingException {

    // *************************************************************************
    // Prepare insert statement for k_mime_msgs table.
    // This is the main table for referencing messages.

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.indexMessage("+sGuMimeMsg+", "+sGuWorkArea+", "+
      	                "[MimeMessage]"+", "+sContentType+", "+sContentID+","+
      	                sMessageID+","+sDisposition+", "+sContentMD5+", "+
      	                sDescription+", "+sFileName+", "+sEncoding+", "+
      	                sSubject+", "+sPriority+", [Flags], "+tsSent+
      	                tsReceived+", "+"[InternetAddress], [InternetAddress],"+
      	                "Address[], Address[], Address[], "+String.valueOf(bIsSpam)+", "+
      	                "[ByteArrayOutputStream], "+sMsgCharSeq+")");
      DebugFile.incIdent();
    }

    Properties pFrom = new Properties(), pTo = new Properties(), pCC = new Properties(), pBCC = new Properties();
    JDCConnection oConn = null;
    PreparedStatement oStmt = null;
    BigDecimal dPgMessage;
    String sSQL;

    String sBoundary = getPartsBoundary(oMsg);
    if (DebugFile.trace) DebugFile.writeln("part boundary is \"" + (sBoundary==null ? "null" : sBoundary) + "\"");

    try {
      oConn = getConnection();

      dPgMessage = getNextMessage(oConn);
      
      sSQL = "INSERT INTO " + DB.k_mime_msgs + "(gu_mimemsg,gu_workarea,gu_category,id_type,id_content,id_message,id_disposition,len_mimemsg,tx_md5,de_mimemsg,file_name,tx_encoding,tx_subject,dt_sent,dt_received,tx_email_from,nm_from,tx_email_reply,nm_to,id_priority,bo_answered,bo_deleted,bo_draft,bo_flagged,bo_recent,bo_seen,bo_spam,pg_message,nu_position,by_content) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1, sGuMimeMsg);
      oStmt.setString(2, sGuWorkArea);

      if (oCatg.isNull(DB.gu_category))
        oStmt.setNull(3,Types.CHAR);
      else
        oStmt.setString(3, oCatg.getString(DB.gu_category));

      oStmt.setString(4, Gadgets.left(sContentType,254));
      oStmt.setString(5, Gadgets.left(sContentID,254));
      oStmt.setString(6, Gadgets.left(sMessageID, 254));
      oStmt.setString(7, Gadgets.left(sDisposition, 100));
      oStmt.setObject(8, iSize, Types.INTEGER);

      oStmt.setString(9, Gadgets.left(sContentMD5, 32));
      oStmt.setString(10, Gadgets.left(sDescription, 254));
      oStmt.setString(11, Gadgets.left(sFileName, 254));
      oStmt.setString(12, Gadgets.left(sEncoding,16));
      oStmt.setString(13, Gadgets.left(sSubject,254));
      oStmt.setTimestamp(14, tsSent);
      oStmt.setTimestamp(15, tsReceived);

      if (null==oFrom) {
        oStmt.setNull(16, Types.VARCHAR);
        oStmt.setNull(17, Types.VARCHAR);
      }
      else {
        oStmt.setString(16, Gadgets.left(oFrom.getAddress(),254));
        oStmt.setString(17, Gadgets.left(oFrom.getPersonal(),254));
      }

      if (null==oReply)
        oStmt.setNull(18, Types.VARCHAR);
      else
        oStmt.setString(18, Gadgets.left(oReply.getAddress(),254));

      Address[] aRecipients;
      String sRecipientName;

      aRecipients = oTo;
      if (null!=aRecipients) if (aRecipients.length==0) aRecipients=null;

      if (null!=aRecipients) {
        sRecipientName = ((InternetAddress) aRecipients[0]).getPersonal();
        if (null==sRecipientName) sRecipientName = ((InternetAddress) aRecipients[0]).getAddress();
        oStmt.setString(19, Gadgets.left(sRecipientName,254));
      } else {
        aRecipients = oCC;
        if (null!=aRecipients) {
          if (aRecipients.length>0) {
            sRecipientName = ((InternetAddress) aRecipients[0]).getPersonal();
            if (null==sRecipientName)
              sRecipientName = ((InternetAddress) aRecipients[0]).getAddress();
            oStmt.setString(19, Gadgets.left(sRecipientName,254));
          }
          else
            oStmt.setNull(19, Types.VARCHAR);
        }
        else {
          aRecipients = oBCC;
          if (null!=aRecipients) {
            if (aRecipients.length>0) {
              sRecipientName = ( (InternetAddress) aRecipients[0]).getPersonal();
              if (null == sRecipientName)
                sRecipientName = ( (InternetAddress) aRecipients[0]).getAddress();
              oStmt.setString(19, Gadgets.left(sRecipientName,254));
            }
            else
              oStmt.setNull(19, Types.VARCHAR);
          }
          else {
            oStmt.setNull(19, Types.VARCHAR);
          } // fi (MimeMessage.RecipientType.BCC)
        } // fi (MimeMessage.RecipientType.CC)
      } // fi (MimeMessage.RecipientType.TO)

      if (null==sPriority)
        oStmt.setNull(20, Types.VARCHAR);
      else
        oStmt.setString(20, sPriority);

      // For Oracle insert flags in NUMBER columns and message body in a BLOB column.
      // for any other RDBMS use SMALLINT columns for Flags and a LONGVARBINARY column for the body.

      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_ORACLE) {
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setBigDecimal(21, ...)");

        oStmt.setBigDecimal(21, new BigDecimal(oFlgs.contains(Flags.Flag.ANSWERED) ? "1" : "0"));
        oStmt.setBigDecimal(22, new BigDecimal(oFlgs.contains(Flags.Flag.DELETED) ? "1" : "0"));
        oStmt.setBigDecimal(23, new BigDecimal(0));
        oStmt.setBigDecimal(24, new BigDecimal(oFlgs.contains(Flags.Flag.FLAGGED) ? "1" : "0"));
        oStmt.setBigDecimal(25, new BigDecimal(oFlgs.contains(Flags.Flag.RECENT) ? "1" : "0"));
        oStmt.setBigDecimal(26, new BigDecimal(oFlgs.contains(Flags.Flag.SEEN) ? "1" : "0"));
        oStmt.setBigDecimal(27, new BigDecimal(bIsSpam ? "1" : "0"));
        oStmt.setBigDecimal(28, dPgMessage);
        oStmt.setBigDecimal(29, dPosition);

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setBinaryStream(30, new ByteArrayInputStream("+String.valueOf(byOutStrm.size())+"))");

        if (byOutStrm.size()>0)
          oStmt.setBinaryStream(30, new ByteArrayInputStream(byOutStrm.toByteArray()), byOutStrm.size());
        else
          oStmt.setNull(30, Types.LONGVARBINARY);

      } else {
        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setShort(21, ...)");

        oStmt.setShort(21, (short) (oFlgs.contains(Flags.Flag.ANSWERED) ? 1 : 0));
        oStmt.setShort(22, (short) (oFlgs.contains(Flags.Flag.DELETED) ? 1 : 0));
        oStmt.setShort(23, (short) (0));
        oStmt.setShort(24, (short) (oFlgs.contains(Flags.Flag.FLAGGED) ? 1 : 0));
        oStmt.setShort(25, (short) (oFlgs.contains(Flags.Flag.RECENT) ? 1 : 0));
        oStmt.setShort(26, (short) (oFlgs.contains(Flags.Flag.SEEN) ? 1 : 0));
        oStmt.setShort(27, (short) (bIsSpam ? 1 : 0));
        oStmt.setBigDecimal(28, dPgMessage);
        oStmt.setBigDecimal(29, dPosition);

		if (DebugFile.trace) DebugFile.writeln("PreparedStatement.setBytes "+String.valueOf(byOutStrm.size()));
			
        if (byOutStrm.size()>0)
          oStmt.setBytes(30, byOutStrm.toByteArray());
          // oStmt.setBinaryStream(30, new ByteArrayInputStream(byOutStrm.toByteArray()), byOutStrm.size());
        else
          oStmt.setNull(30, Types.LONGVARBINARY);
      }

      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate()");

      oStmt.executeUpdate();
      oStmt.close();
      oStmt=null;

    } catch (SQLException sqle) {
      String sTrace = "";
      try { sTrace = com.knowgate.debug.StackTraceUtil.getStackTrace(sqle);
        DebugFile.writeln(sTrace);
      } catch (Exception ignore) {}
      try { if (null!=oStmt) oStmt.close(); oStmt=null; } catch (Exception ignore) {}
      try { if (null!=oConn) oConn.rollback(); } catch (Exception ignore) {}
      throw new MessagingException(DB.k_mime_msgs + " " + sqle.getMessage(), sqle);
    }
    if ((iOpenMode&MODE_BLOB)!=0) {
      // Deallocate byte array containing message body for freeing memory as soon as possible
      try { byOutStrm.close(); } catch (IOException ignore) {}
      byOutStrm = null;
    }

    if (DebugFile.trace) DebugFile.writeln("INSERT INTO k_mime_msgs done!");

    // *************************************************************************
    // Now that we have saved the main message reference proceed to store
    // its parts into k_mime_parts

    try {
      Object oContent = oMsg.getContent();

      if (DebugFile.trace) DebugFile.writeln("message content class is "+oContent.getClass().getName());

      if (oContent instanceof MimeMultipart) {
        try {
          saveMimeParts(oConn, oMsg, sMsgCharSeq, sBoundary, sGuMimeMsg, sMessageID, dPgMessage.intValue(), 0);
        } catch (MessagingException msge) {
          // Close Mbox file, rollback and re-throw
          try { if (!oConn.getAutoCommit()) oConn.rollback(); } catch (Exception ignore) {}
          throw new MessagingException(msge.getMessage(), msge.getNextException());
        }
      } // fi (MimeMultipart)

    } catch (Exception xcpt) {
      try { if (!oConn.getAutoCommit()) oConn.rollback(); } catch (Exception ignore) {}
      if (DebugFile.trace) {
    	try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (IOException ignore) { }
    	DebugFile.decIdent();
      }
      throw new MessagingException("MimeMessage.getContent() " + xcpt.getMessage(), xcpt);
    }

    // *************************************************************************
    // Store message recipients at k_inet_addrs

    try {
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
        sSQL = "SELECT "+DB.gu_contact+","+DB.gu_company+","+DB.tx_name+","+DB.tx_surname+","+DB.tx_surname+" FROM "+DB.k_member_address+" WHERE "+DB.tx_email+"=? AND "+DB.gu_workarea+"=? UNION SELECT "+DB.gu_user+",CONVERT('****************************USER' USING utf8),"+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+" FROM "+DB.k_users+" u WHERE (u."+DB.tx_main_email+"=? OR u."+DB.tx_alt_email+"=? OR EXISTS (SELECT a."+DB.gu_user+" FROM "+DB.k_user_mail+" a WHERE a."+DB.gu_user+"=u."+DB.gu_user+" AND a."+DB.tx_main_email+"=?)) AND "+DB.gu_workarea+"=?";
      else
        sSQL = "SELECT "+DB.gu_contact+","+DB.gu_company+","+DB.tx_name+","+DB.tx_surname+","+DB.tx_surname+" FROM "+DB.k_member_address+" WHERE "+DB.tx_email+"=? AND "+DB.gu_workarea+"=? UNION SELECT "+DB.gu_user+",'****************************USER',"+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+" FROM "+DB.k_users+" u WHERE (u."+DB.tx_main_email+"=? OR u."+DB.tx_alt_email+"=? OR EXISTS (SELECT a."+DB.gu_user+" FROM "+DB.k_user_mail+" a WHERE a."+DB.gu_user+"=u."+DB.gu_user+" AND a."+DB.tx_main_email+"=?)) AND "+DB.gu_workarea+"=?";
    } catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.writeln("SQLException " + sqle.getMessage());
      sSQL = "SELECT "+DB.gu_contact+","+DB.gu_company+","+DB.tx_name+","+DB.tx_surname+","+DB.tx_surname+" FROM "+DB.k_member_address+" WHERE "+DB.tx_email+"=? AND "+DB.gu_workarea+"=? UNION SELECT "+DB.gu_user+",'****************************USER',"+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+" FROM "+DB.k_users+" u WHERE (u."+DB.tx_main_email+"=? OR u."+DB.tx_alt_email+"=? OR EXISTS (SELECT a."+DB.gu_user+" FROM "+DB.k_user_mail+" a WHERE a."+DB.gu_user+"=u."+DB.gu_user+" AND a."+DB.tx_main_email+"=?)) AND "+DB.gu_workarea+"=?";
    }

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    PreparedStatement oAddr = null;

    try {
      oAddr = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      ResultSet oRSet;

      InternetAddress oInetAdr;
      String sTxEmail, sGuCompany, sGuContact, sTxName, sTxSurname1, sTxSurname2, sTxPersonal;

      // Get From address and keep them into pFrom properties

      if (oFrom!=null) {
        oAddr.setString(1, oFrom.getAddress());
        oAddr.setString(2, sGuWorkArea);
        oAddr.setString(3, oFrom.getAddress());
        oAddr.setString(4, oFrom.getAddress());
        oAddr.setString(5, oFrom.getAddress());
        oAddr.setString(6, sGuWorkArea);

        oRSet = oAddr.executeQuery();
        if (oRSet.next()) {
          sGuContact = oRSet.getString(1);
          if (oRSet.wasNull()) sGuContact = "null";
          sGuCompany = oRSet.getString(2);
          if (oRSet.wasNull()) sGuCompany = "null";

          if (sGuCompany.equals("****************************USER")) {
            sTxName = oRSet.getString(3);
            if (oRSet.wasNull()) sTxName = "";
            sTxSurname1 = oRSet.getString(4);
            if (oRSet.wasNull()) sTxSurname1 = "";
            sTxSurname2 = oRSet.getString(4);
            if (oRSet.wasNull()) sTxSurname2 = "";
            sTxPersonal = Gadgets.left(sTxName+" "+sTxSurname1+" "+sTxSurname2, 254).replace(',',' ').trim();
          }
          else
            sTxPersonal = "null";

          if (DebugFile.trace) DebugFile.writeln("from "+sGuContact+","+sGuCompany+","+sTxPersonal);
          pFrom.put(oFrom.getAddress(), sGuContact+","+sGuCompany+","+sTxPersonal);
        }
        else
          pFrom.put(oFrom.getAddress(), "null,null,null");

      oRSet.close();
      } // fi (oFrom)

      if (DebugFile.trace) DebugFile.writeln("from count = " + pFrom.size());

      // Get TO address and keep them into pTo properties

      if (oTo!=null) {
        for (int t=0; t<oTo.length; t++) {
          oInetAdr = (InternetAddress) oTo[t];
          sTxEmail = Gadgets.left(oInetAdr.getAddress(), 254);

          oAddr.setString(1, sTxEmail);
          oAddr.setString(2, sGuWorkArea);
          oAddr.setString(3, sTxEmail);
          oAddr.setString(4, sTxEmail);
          oAddr.setString(5, sTxEmail);
          oAddr.setString(6, sGuWorkArea);

          oRSet = oAddr.executeQuery();
          if (oRSet.next()) {
            sGuContact = oRSet.getString(1);
            if (oRSet.wasNull()) sGuContact = "null";
            sGuCompany = oRSet.getString(2);
            if (oRSet.wasNull()) sGuCompany = "null";
            if (sGuCompany.equals("****************************USER")) {
              sTxName = oRSet.getString(3);
              if (oRSet.wasNull()) sTxName = "";
              sTxSurname1 = oRSet.getString(4);
              if (oRSet.wasNull()) sTxSurname1 = "";
              sTxSurname2 = oRSet.getString(4);
              if (oRSet.wasNull()) sTxSurname2 = "";
              sTxPersonal = Gadgets.left(sTxName+" "+sTxSurname1+" "+sTxSurname2, 254).replace(',',' ').trim();
            }
            else
              sTxPersonal = "null";

            pTo.put(sTxEmail, sGuContact+","+sGuCompany+","+sTxPersonal);
          } // fi (oRSet.next())
          else
            pTo.put(sTxEmail, "null,null,null");

          oRSet.close();
        } // next (t)
      } // fi (oTo)

      if (DebugFile.trace) DebugFile.writeln("to count = " + pTo.size());

      // Get CC address and keep them into pTo properties

      if (oCC!=null) {
        for (int c=0; c<oCC.length; c++) {
          oInetAdr = (InternetAddress) oCC[c];
          sTxEmail = Gadgets.left(oInetAdr.getAddress(), 254);

          oAddr.setString(1, sTxEmail);
          oAddr.setString(2, sGuWorkArea);
          oAddr.setString(3, sTxEmail);
          oAddr.setString(4, sTxEmail);
          oAddr.setString(5, sTxEmail);
          oAddr.setString(6, sGuWorkArea);

          oRSet = oAddr.executeQuery();
          if (oRSet.next()) {
            sGuContact = oRSet.getString(1);
            if (oRSet.wasNull()) sGuContact = "null";
            sGuCompany = oRSet.getString(2);
            if (oRSet.wasNull()) sGuCompany = "null";
            if (sGuCompany.equals("****************************USER")) {
              sTxName = oRSet.getString(3);
              if (oRSet.wasNull()) sTxName = "";
              sTxSurname1 = oRSet.getString(4);
              if (oRSet.wasNull()) sTxSurname1 = "";
              sTxSurname2 = oRSet.getString(4);
              if (oRSet.wasNull()) sTxSurname2 = "";
              sTxPersonal = Gadgets.left(sTxName+" "+sTxSurname1+" "+sTxSurname2, 254).replace(',',' ').trim();
            }
            else
              sTxPersonal = "null";

            pCC.put(sTxEmail, sGuContact+","+sGuCompany+","+sTxPersonal);
          } // fi (oRSet.next())
          else
            pCC.put(sTxEmail, "null,null,null");

          oRSet.close();
        } // next (c)
      } // fi (oCC)

      if (DebugFile.trace) DebugFile.writeln("cc count = " + pCC.size());

      // Get BCC address and keep them into pTo properties

      if (oBCC!=null) {
        for (int b=0; b<oBCC.length; b++) {
          oInetAdr = (InternetAddress) oBCC[b];
          sTxEmail = Gadgets.left(oInetAdr.getAddress(), 254);

          oAddr.setString(1, sTxEmail);
          oAddr.setString(2, sGuWorkArea);
          oAddr.setString(3, sTxEmail);
          oAddr.setString(4, sTxEmail);
          oAddr.setString(5, sTxEmail);
          oAddr.setString(6, sGuWorkArea);

          oRSet = oAddr.executeQuery();
          if (oRSet.next()) {
            sGuContact = oRSet.getString(1);
            if (oRSet.wasNull()) sGuContact = "null";
            sGuCompany = oRSet.getString(2);
            if (oRSet.wasNull()) sGuCompany = "null";
            if (sGuCompany.equals("****************************USER")) {
              sTxName = oRSet.getString(3);
              if (oRSet.wasNull()) sTxName = "";
              sTxSurname1 = oRSet.getString(4);
              if (oRSet.wasNull()) sTxSurname1 = "";
              sTxSurname2 = oRSet.getString(4);
              if (oRSet.wasNull()) sTxSurname2 = "";
              sTxPersonal = Gadgets.left(sTxName+" "+sTxSurname1+" "+sTxSurname2, 254).replace(',',' ').trim();
            }
            else
              sTxPersonal = "null";

            pBCC.put(sTxEmail, sGuContact+","+sGuCompany);
          } // fi (oRSet.next())
          else
            pBCC.put(sTxEmail, "null,null,null");

          oRSet.close();
        } // next (b)
      } // fi (oCBB)

      if (DebugFile.trace) DebugFile.writeln("bcc count = " + pBCC.size());

      oAddr.close();

      sSQL = "INSERT INTO " + DB.k_inet_addrs + " (gu_mimemsg,id_message,pg_message,tx_email,tp_recipient,gu_user,gu_contact,gu_company,tx_personal) VALUES ('"+sGuMimeMsg+"',?,"+String.valueOf(dPgMessage.intValue())+",?,?,?,?,?,?)";

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

      oStmt = oConn.prepareStatement(sSQL);

      java.util.Enumeration oMailEnum;
      String[] aRecipient;

      if (!pFrom.isEmpty()) {
        oMailEnum = pFrom.keys();
        while (oMailEnum.hasMoreElements()) {
          oStmt.setString(1, sMessageID);
          sTxEmail = (String) oMailEnum.nextElement();
          if (DebugFile.trace) DebugFile.writeln("processing mail address "+sTxEmail);
          aRecipient = Gadgets.split(pFrom.getProperty(sTxEmail),',');

          oStmt.setString(2, sTxEmail);
          oStmt.setString(3, "from");

          if (aRecipient[0].equals("null") && aRecipient[1].equals("null")) {
            oStmt.setNull(4, Types.CHAR);
            oStmt.setNull(5, Types.CHAR);
            oStmt.setNull(6, Types.CHAR);
          }
          else if (aRecipient[1].equals("****************************USER")) {
            oStmt.setString(4, aRecipient[0]);
            oStmt.setNull(5, Types.CHAR);
            oStmt.setNull(6, Types.CHAR);
          }
          else {
            oStmt.setNull(4, Types.CHAR);
            oStmt.setString(5, aRecipient[0].equals("null") ? null : aRecipient[0]);
            oStmt.setString(6, aRecipient[1].equals("null") ? null : aRecipient[1]);
          }

          if (aRecipient[2].equals("null"))
            oStmt.setNull(7, Types.VARCHAR);
          else
            oStmt.setString(7, aRecipient[2]);

          if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate()");
          oStmt.executeUpdate();
        } // wend
      } // fi (from)

      if (!pTo.isEmpty()) {
        oMailEnum = pTo.keys();
        while (oMailEnum.hasMoreElements()) {
          oStmt.setString(1, sMessageID);
          sTxEmail = (String) oMailEnum.nextElement();
          aRecipient = Gadgets.split(pTo.getProperty(sTxEmail),',');

          oStmt.setString(2, sTxEmail);
          oStmt.setString(3, "to");

          if (aRecipient[0].equals("null") && aRecipient[1].equals("null")) {
            oStmt.setNull(4, Types.CHAR);
            oStmt.setNull(5, Types.CHAR);
            oStmt.setNull(6, Types.CHAR);
          }
          else if (aRecipient[1].equals("****************************USER")) {
            oStmt.setString(4, aRecipient[0]);
            oStmt.setNull(5, Types.CHAR);
            oStmt.setNull(6, Types.CHAR);
          }
          else {
            oStmt.setNull(4, Types.CHAR);
            oStmt.setString(5, aRecipient[0].equals("null") ? null : aRecipient[0]);
            oStmt.setString(6, aRecipient[1].equals("null") ? null : aRecipient[1]);
          }

          if (aRecipient[2].equals("null"))
            oStmt.setNull(7, Types.VARCHAR);
          else
            oStmt.setString(7, aRecipient[2]);

          if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate()");

          oStmt.executeUpdate();
        } // wend
      } // fi (to)

      if (!pCC.isEmpty()) {
        oMailEnum = pCC.keys();
        while (oMailEnum.hasMoreElements()) {
          oStmt.setString(1, sMessageID);
          sTxEmail = (String) oMailEnum.nextElement();
          aRecipient = Gadgets.split(pCC.getProperty(sTxEmail),',');

          oStmt.setString(2, sTxEmail);
          oStmt.setString(3, "cc");

          if (aRecipient[0].equals("null") && aRecipient[1].equals("null")) {
            oStmt.setNull(4, Types.CHAR);
            oStmt.setNull(5, Types.CHAR);
            oStmt.setNull(6, Types.CHAR);
          }
          else if (aRecipient[1].equals("****************************USER")) {
            oStmt.setString(4, aRecipient[0]);
            oStmt.setString(5, null);
            oStmt.setString(6, null);
          }
          else {
            oStmt.setString(4, null);
            oStmt.setString(5, aRecipient[0].equals("null") ? null : aRecipient[0]);
            oStmt.setString(6, aRecipient[1].equals("null") ? null : aRecipient[1]);
          }

          if (aRecipient[2].equals("null"))
            oStmt.setNull(7, Types.VARCHAR);
          else
            oStmt.setString(7, aRecipient[2]);

          if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate()");

          oStmt.executeUpdate();
        } // wend
      } // fi (cc)

      if (!pBCC.isEmpty()) {
        oMailEnum = pBCC.keys();
        while (oMailEnum.hasMoreElements()) {
          oStmt.setString(1, sMessageID);
          sTxEmail = (String) oMailEnum.nextElement();
          aRecipient = Gadgets.split(pBCC.getProperty(sTxEmail),',');

          oStmt.setString(2, sTxEmail);
          oStmt.setString(3, "bcc");

          if (aRecipient[0].equals("null") && aRecipient[1].equals("null")) {
            oStmt.setNull(4, Types.CHAR);
            oStmt.setNull(5, Types.CHAR);
            oStmt.setNull(6, Types.CHAR);
          }
          else if (aRecipient[1].equals("****************************USER")) {
            oStmt.setString(4, aRecipient[0]);
            oStmt.setNull(5, Types.CHAR);
            oStmt.setNull(6, Types.CHAR);
          }
          else {
            oStmt.setNull(4, Types.CHAR);
            oStmt.setString(5, aRecipient[0].equals("null") ? null : aRecipient[0]);
            oStmt.setString(6, aRecipient[1].equals("null") ? null : aRecipient[1]);
          }

          if (aRecipient[2].equals("null"))
            oStmt.setNull(7, Types.VARCHAR);
          else
            oStmt.setString(7, aRecipient[2]);

          oStmt.executeUpdate();
        } // wend
      } // fi (bcc)

      oStmt.close();
      oStmt=null;

      oStmt = oConn.prepareStatement("UPDATE "+DB.k_categories+" SET "+DB.len_size+"="+DB.len_size+"+"+String.valueOf(iSize)+" WHERE "+DB.gu_category+"=?");
      oStmt.setString(1, getCategory().getString(DB.gu_category));
      oStmt.executeUpdate();
      oStmt.close();
      oStmt=null;

      if (DebugFile.trace) DebugFile.writeln("autocommit="+oConn.getAutoCommit());
      
      if (!oConn.getAutoCommit()) oConn.commit();

    } catch (SQLException sqle) {
      try { if (!oConn.getAutoCommit()) oConn.rollback();} catch (Exception ignore) {};
      try { if (null!=oStmt) oStmt.close(); oStmt=null;  } catch (Exception ignore) {}
      try { if (null!=oAddr) oAddr.close(); oAddr=null;  } catch (Exception ignore) {}
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException(sqle.getMessage(), sqle);
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.indexMessage()");
    }
  } // indexMessage

  // ---------------------------------------------------------------------------

  private void checkAppendPreconditions()
    throws FolderClosedException, StoreClosedException {
    // *************************************************************************
    // If DBStore is not connected to the database then raise an exception

    if (!((DBStore)getStore()).isConnected()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new StoreClosedException(getStore(), "Store is not connected");
    }

    // *************************************************************************
    // If Folder is not opened is read-write mode then raise an exception
    if (0==(iOpenMode&READ_WRITE)) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new FolderClosedException(this, "Folder is not open is READ_WRITE mode");
    }

    if ((0==(iOpenMode&MODE_MBOX)) && (0==(iOpenMode&MODE_BLOB))) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new FolderClosedException(this, "Folder is not open in MBOX nor BLOB mode");
    }
  } // checkAppendPreconditions

  // ---------------------------------------------------------------------------

  /**
   * Get Message body taking into account its exact MimeMessage subclass
   * @param oMsg MimeMessage
   * @return ByteArrayOutputStream
   * @throws MessagingException
   * @throws IOException
   */
  private static ByteArrayOutputStream getBodyAsStream(MimeMessage oMsg)
    throws MessagingException,IOException {
    MimePart oText = null;
    ByteArrayOutputStream byStrm;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.getBodyAsStream([MimeMessage])");
      DebugFile.incIdent();
      if (null!=oMsg) DebugFile.writeln(oMsg.getClass().getName());
                 else DebugFile.writeln("MimeMessage is null");
    }

    if (oMsg.getClass().getName().equals("com.knowgate.hipermail.DBMimeMessage"))
      // If appended message is a DBMimeMessage then use DBMimeMessage.getBody()
      // for getting HTML text part or plain text part of the MULTIPART/ALTERNATIVE
      oText = ((DBMimeMessage) oMsg).getBody();
    else {
      // Else if the appended message is a MimeMessage use standard Java Mail getBody() method
      oText = new DBMimeMessage(oMsg).getBody();
    } // fi

    if (DebugFile.trace) {
      DebugFile.writeln("MimePart encoding is "+oText.getEncoding());
      DebugFile.writeln("MimePart size is "+String.valueOf(oText.getSize()));
    }

    // *************************************************************************
    // Initialize a byte array for containing the message body

    if (DebugFile.trace) DebugFile.writeln("ByteArrayOutputStream byOutStrm = new ByteArrayOutputStream("+String.valueOf(oText.getSize()>0 ? oText.getSize() : 8192)+")");

    byStrm = new ByteArrayOutputStream(oText.getSize()>0 ? oText.getSize() : 8192);
    oText.writeTo(byStrm);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.getBodyAsStream() : " + Gadgets.left(new String(byStrm.toByteArray()),100));
    }

    return byStrm;
  } // getBodyAsStream

  // ---------------------------------------------------------------------------

  /**
   *
   * @param oMsg MimeMessage
   * @return String
   * @throws FolderClosedException
   * @throws StoreClosedException
   * @throws MessagingException
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException if oMsg is <b>null</b>
   */
  public String appendMessage(MimeMessage oMsg)
    throws FolderClosedException, StoreClosedException, MessagingException,
    ArrayIndexOutOfBoundsException, NullPointerException {

  if (oMsg==null) {
    throw new NullPointerException("DBFolder.appendMessage() MimeMessage parameter cannot be null");
  }

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.appendMessage("+oMsg.getClass().getName()+")");
      DebugFile.incIdent();
    }

    // *************************************************************************
    // If Message does not have a GUID then assign a new one.
    // Message GUID is not the same as MimeMessage Id.

    String gu_mimemsg;
    if (oMsg.getClass().getName().equals("com.knowgate.hipermail.DBMimeMessage")) {
      gu_mimemsg = ((DBMimeMessage) oMsg).getMessageGuid();
      if (((DBMimeMessage) oMsg).getFolder()==null) ((DBMimeMessage) oMsg).setFolder(this);
    }
    else {
      gu_mimemsg = Gadgets.generateUUID();
    }

    checkAppendPreconditions();

    // *************************************************************************
    // Mails are assigned by default to the same WorkArea as their recipient user

    String gu_workarea = ((DBStore)getStore()).getUser().getString(DB.gu_workarea);

    // *************************************************************************
    // Gather some MimeMessage headers that will be later written at the database

    MboxFile oMBox = null;
    ByteArrayOutputStream byOutStrm = null;

    try {
      long lPosition = -1;
      HeadersHelper oHlpr = new HeadersHelper(oMsg);
      RecipientsHelper oRecps = new RecipientsHelper(oMsg);
      String sMessageID = oHlpr.decodeMessageId(gu_mimemsg);
      String sMsgCharSeq = DBMimeMessage.source(oMsg, "ISO8859_1");
      if (sMsgCharSeq==null) {
        if (DebugFile.trace) {
          DebugFile.writeln("DBFolder.appendMessage() : Original message source is null");
          DebugFile.decIdent();
        }
        throw new NullPointerException("DBFolder.appendMessage() : Original message source is null");
      } // fi (sMsgCharSeq==null)
      String sContentMD5 = oHlpr.getContentMD5();
      if (null==sContentMD5) sContentMD5 = HeadersHelper.computeContentMD5(sMsgCharSeq.getBytes());
      int iSize = ((iOpenMode&MODE_MBOX)!=0) ? sMsgCharSeq.length() : oMsg.getSize();
      Integer oSize = ((iSize>=0) ? new Integer(iSize) : null);

      byOutStrm = getBodyAsStream(oMsg);

      // *************************************************************************
      // Create Mbox file and adquire an exclusive lock on it before start writting on the database

      if ((iOpenMode&MODE_MBOX)!=0) {
          if (DebugFile.trace) DebugFile.writeln("new File("+Gadgets.chomp(sFolderDir, File.separator)+oCatg.getStringNull(DB.nm_category,"null")+".mbox)");

          File oFile = getFile();
          lPosition = oFile.length();

          if (DebugFile.trace) DebugFile.writeln("message position is " + String.valueOf(lPosition));

          oMBox = new MboxFile(oFile, MboxFile.READ_WRITE);

      } // fi (MODE_MBOX)

      indexMessage(gu_mimemsg, gu_workarea, oMsg, oSize,
                   ((iOpenMode&MODE_MBOX)!=0) ? new BigDecimal(lPosition) : null,
                   oHlpr.getContentType(),
                   oHlpr.getContentID(), sMessageID,
                   oHlpr.getDisposition(), sContentMD5,
                   oHlpr.getDescription(), oHlpr.getFileName(),
                   oHlpr.getEncoding(), oHlpr.getSubject(),
                   oHlpr.getPriority(), oHlpr.getFlags(),
                   oHlpr.getSentTimestamp(), oHlpr.getReceivedTimestamp(),
                   RecipientsHelper.getFromAddress(oMsg),
                   RecipientsHelper.getReplyAddress(oMsg),
                   oRecps.getRecipients(Message.RecipientType.TO),
                   oRecps.getRecipients(Message.RecipientType.CC),
                   oRecps.getRecipients(Message.RecipientType.BCC),
                   oHlpr.isSpam(), byOutStrm, sMsgCharSeq);

      if ((iOpenMode&MODE_MBOX)!=0) {
        if (DebugFile.trace) DebugFile.writeln("MboxFile.appendMessage("+(oMsg.getContentID()!= null ? oMsg.getContentID() : "")+")");

        oMBox.appendMessage(sMsgCharSeq);

        oMBox.close();
        oMBox=null;

        if (DebugFile.trace && ((iOpenMode&MODE_MBOX)!=0)) {
          oMBox = new MboxFile(getFile(), MboxFile.READ_ONLY);
          int iMsgCount = oMBox.getMessageCount();
          CharSequence sWrittenMsg = oMBox.getMessage(iMsgCount-1);
          if (!sMsgCharSeq.equals(sWrittenMsg.toString())) {
            DebugFile.writeln ("Readed message source does not match with original message source");
            DebugFile.writeln ("**** Original Message ****");
            DebugFile.writeln (sMsgCharSeq);
            DebugFile.writeln ("**** Readed Message ****");
            DebugFile.writeln (sWrittenMsg.toString());
          }
          oMBox.close();
        } // fi

      } // fi (MODE_MBOX)

      byOutStrm.close();
      byOutStrm=null;

    } catch (OutOfMemoryError oom) {
      try { if (null!=byOutStrm) byOutStrm.close(); } catch (Exception ignore) {}
      try { if (null!=oMBox) oMBox.close(); } catch (Exception ignore) {}
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException("OutOfMemoryError " + oom.getMessage());
    } catch (Exception xcpt) {
      try { if (null!=byOutStrm) byOutStrm.close(); } catch (Exception ignore) {}
      try { if (oMBox!=null) oMBox.close(); } catch (Exception ignore) {}
      if (DebugFile.trace) {
		DebugFile.writeln(xcpt.getClass().getName() + " " + xcpt.getMessage());
		DebugFile.writeStackTrace(xcpt);
        DebugFile.decIdent();
      }
      throw new MessagingException(xcpt.getClass().getName() + " " + xcpt.getMessage(), xcpt);
    }

    // End Gathering MimeMessage headers
    // *************************************************************************

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.appendMessage() : " + gu_mimemsg);
    }
    return gu_mimemsg;
  } // appendMessage

  // ---------------------------------------------------------------------------

  public Message getMessage(int msgnum) throws MessagingException  {
    return getMessage(String.valueOf(msgnum), 3);
  }

  // ---------------------------------------------------------------------------

  public DBMimeMessage getMessageByGuid(String sMsgGuid) throws MessagingException  {
    return (DBMimeMessage) getMessage(sMsgGuid, 1);
  }

  // ---------------------------------------------------------------------------

  public DBMimeMessage getMessageByID(String sMsgId) throws MessagingException  {
    return (DBMimeMessage) getMessage(sMsgId, 2);
  }

  // ---------------------------------------------------------------------------

  public int getMessageCount()
    throws FolderClosedException, MessagingException {

    PreparedStatement oStmt = null;
    ResultSet oRSet = null;
    Object oCount;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.getMessageCount()");
      DebugFile.incIdent();
    }

    // *************************************************************************
    // If Folder is not opened then raise an exception
    if (!isOpen()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new javax.mail.FolderClosedException(this, "Folder is closed");
    }

    try {
      oStmt = getConnection().prepareStatement("SELECT COUNT(*) FROM "+DB.k_mime_msgs+ " WHERE "+DB.gu_category+"=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, oCatg.getStringNull(DB.gu_category, null));
      oRSet = oStmt.executeQuery();
      oRSet.next();
      oCount = oRSet.getObject(1);
      oRSet.close();
      oRSet=null;
      oStmt.close();
      oStmt=null;
    } catch (SQLException sqle) {
      oCount = new Integer(0);
      try { if (null!=oRSet) oRSet.close(); }  catch (Exception ignore) {}
      try { if (null!=oStmt) oStmt.close(); }  catch (Exception ignore) {}
      throw new MessagingException(sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.getMessageCount() : " + oCount.toString());
    }

    return Integer.parseInt(oCount.toString());
  } // getMessageCount

  // ---------------------------------------------------------------------------

  public Folder getParent() throws MessagingException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.getParent()");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.getParent() : null");
    }

    return null;
  } // getParent

  // ---------------------------------------------------------------------------

  public Flags getPermanentFlags() {
    Flags oFlgs = new Flags();
    oFlgs.add(Flags.Flag.DELETED);
    oFlgs.add(Flags.Flag.ANSWERED);
    oFlgs.add(Flags.Flag.DRAFT);
    oFlgs.add(Flags.Flag.SEEN);
    oFlgs.add(Flags.Flag.RECENT);
    oFlgs.add(Flags.Flag.FLAGGED);

    return oFlgs;
  }

  // ---------------------------------------------------------------------------

  public char getSeparator() throws MessagingException {
    return '/';
  }

  // ---------------------------------------------------------------------------

  public Folder[] list(String pattern) throws MessagingException {
    return null;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get a list of all messages in this folder which are not deleted</p>
   * @return An array of strings with format
   * &lt;msg&gt;
   * &lt;num&gt;[1..n]&lt;/num&gt;
   * &lt;id&gt;message unique identifier&lt;/id&gt;
   * &lt;len&gt;message length in bytes&lt;/len&gt;
   * &lt;type&gt;message content-type&lt;/type&gt;
   * &lt;disposition&gt;message content-disposition&lt;/disposition&gt;
   * &lt;priority&gt;X-Priority header&lt;/priority&gt;
   * &lt;spam&gt;X-Spam-Flag header&lt;/spam&gt;
   * &lt;subject&gt;&lt;![CDATA[message subject]]&gt;&lt;/subject&gt;
   * &lt;sent&gt;yyy-mm-dd hh:mi:ss&lt;/sent&gt;
   * &lt;received&gt;yyy-mm-dd hh:mi:ss&lt;/received&gt;
   * &lt;from&gt;&lt;![CDATA[personal name of sender]]&gt;&lt;/from&gt;
   * &lt;to&gt;&lt;![CDATA[personal name or e-mail of receiver]]&gt;&lt;/to&gt;
   * &lt;size&gt;integer size in kilobytes&lt;/size&gt;
   * &lt;err&gt;error description (if any)&lt;/err&gt;
   * &lt;/msg&gt;
   * @throws SQLException
   * @since 4.0
   */

  public String[] listMessages() throws SQLException,MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.listMessages()");
      DebugFile.incIdent();
    }
    
	SimpleDateFormat DateFrmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	String[] aMsgsXml;
	StringBuffer oBuffXml = new StringBuffer(1024);
	
    DBSubset oMsgs = new DBSubset (DB.k_mime_msgs,
    							   DB.gu_mimemsg+","+DB.id_message+","+DB.id_priority+","+DB.nm_from+","+DB.nm_to+","+DB.tx_subject+","+DB.dt_received+","+DB.dt_sent+","+DB.len_mimemsg+","+DB.pg_message+","+DB.bo_deleted+","+DB.tx_email_from+","+DB.nm_to+","+DB.bo_spam+","+DB.id_type,
      			                   DB.gu_category+"=? AND "+DB.gu_workarea+"=? AND " + DB.bo_deleted + "<>1 AND " + DB.gu_parent_msg + " IS NULL ORDER BY " + DB.dt_received + "," + DB.dt_sent + " DESC", 10);
    int iMsgs = oMsgs.load(((DBStore)getStore()).getConnection(), new Object[]{getCategoryGuid(), ((DBStore)getStore()).getUser().getString(DB.gu_workarea)});

	if (iMsgs>0) {
	  aMsgsXml = new String[iMsgs];
	  for (int m=0; m<iMsgs; m++) {
	    oBuffXml.append("<msg>");
        oBuffXml.append("<num>"+String.valueOf(oMsgs.getInt(DB.pg_message,m))+"</num>");
        oBuffXml.append("<id><![CDATA["+oMsgs.getStringNull(DB.id_message,m,"").replace('\n',' ')+"]]></id>");
        oBuffXml.append("<len>"+String.valueOf(oMsgs.getInt(DB.len_mimemsg,m))+"</len>");
        String sCType = oMsgs.getStringNull(DB.id_type,m,"");
        int iCType = sCType.indexOf(';');
        if (iCType>0) sCType = sCType.substring(0, iCType);
        oBuffXml.append("<type>"+sCType+"</type>");
        String sDisposition = oMsgs.getStringNull(DB.id_type,m,"").substring(iCType+1).trim();
        int iDisposition = sDisposition.indexOf(';');
        if (iDisposition>0) sDisposition = sDisposition.substring(0, iDisposition);
        int iEq = sDisposition.indexOf('=');
        if (iEq>0) sDisposition = sDisposition.substring(iEq+1);
        oBuffXml.append("<disposition>"+sDisposition+"</disposition>");
        oBuffXml.append("<priority>"+oMsgs.getStringNull(DB.id_priority,m,"")+"</priority>");
        if (oMsgs.isNull(DB.bo_spam,m))
		  oBuffXml.append("<spam></spam>");
	    else
		  oBuffXml.append("<spam>"+(oMsgs.getShort(DB.bo_spam,m)==0 ? "NO" : "YES")+"</spam>");
		oBuffXml.append("<subject><![CDATA["+Gadgets.XHTMLEncode(oMsgs.getStringNull(DB.tx_subject,m,"no subject"))+"]]></subject>");
	    if (oMsgs.isNull(DB.dt_sent,m))
          oBuffXml.append("<sent></sent>");
        else
	      oBuffXml.append("<sent>"+oMsgs.getDateFormated(7,m,DateFrmt)+"</sent>");
	    if (oMsgs.isNull(DB.dt_received,m))
          oBuffXml.append("<received></received>");
        else
	      oBuffXml.append("<received>"+oMsgs.getDateFormated(6,m,DateFrmt)+"</received>");
        oBuffXml.append("<from>"+oMsgs.getStringNull(DB.nm_from,m,oMsgs.getStringNull(DB.tx_email_from,m,""))+"</from>");
        oBuffXml.append("<to>"+oMsgs.getStringNull(DB.nm_to,m,oMsgs.getStringNull(DB.nm_to,m,""))+"</to>");        
        if (oMsgs.getInt(DB.len_mimemsg,m)<=1024)
          oBuffXml.append("<kb>1</kb>");
        else
          oBuffXml.append("<kb>"+String.valueOf(oMsgs.getInt(DB.len_mimemsg,m)/1024)+"</kb>");
        oBuffXml.append("<err/>");
	    oBuffXml.append("</msg>");
	    aMsgsXml[m] = oBuffXml.toString();
	    oBuffXml.setLength(0);
	  } // next
	} else {
	  aMsgsXml = null;
	}// fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aMsgsXml)
        DebugFile.writeln("End DBFolder.listMessages() : 0");
      else
        DebugFile.writeln("End DBFolder.listMessages() : " + String.valueOf(aMsgsXml.length));
    }

	return aMsgsXml;
  } // listMessages

  // ---------------------------------------------------------------------------

  public int getType() throws MessagingException {
    return iOpenMode;
  }

  // ---------------------------------------------------------------------------

  public boolean isOpen() {
    return (iOpenMode!=0);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get message GUID, Id, Number, Subject, From and Reply-To from k_mime_msgs table</p>
   * This method is mainly used for testing whether or not a message is already present at current folder.
   * @param sMsgId String GUID or Id of message to be retrieved
   * @return Properties {gu_mimemsg, id_message, pg_message, tx_subject, tx_email_from,	tx_email_reply, nm_from }
   * or <b>null</b> if no message with such sMsgId was found referenced at k_mime_msgs
   * for current folder
   * @throws FolderClosedException
   * @throws SQLException
   */
  public Properties getMessageHeaders(String sMsgId)
    throws FolderClosedException, SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.getMessageHeaders()");
      DebugFile.incIdent();
    }

    // *************************************************************************
    // If Folder is not opened then raise an exception
    if (!isOpen()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new javax.mail.FolderClosedException(this, "Folder is closed");
    }

    Properties oRetVal;
    PreparedStatement oStmt;
    JDCConnection oJdcn = null;
    
    try {
      oJdcn = getConnection();
    } catch (MessagingException msge) {
      throw new SQLException(msge.getMessage(), msge);
    }
    
    if (sMsgId.length()==32) {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_mimemsg + "," + DB.id_message + "," + DB.pg_message + "," + DB.tx_subject + " FROM " + DB.k_mime_msgs + " WHERE " + DB.gu_mimemsg + "='"+sMsgId+"' OR " + DB.id_message + "='"+sMsgId+"') AND " + DB.gu_category + "='"+getCategoryGuid()+"' AND " + DB.bo_deleted + "<>1)");

      oStmt = oJdcn.prepareStatement("SELECT " + DB.gu_mimemsg + "," + DB.id_message + "," + DB.pg_message + "," + DB.tx_subject + "," + DB.tx_email_from + "," + DB.tx_email_reply + "," + DB.nm_from +
                                     " FROM " + DB.k_mime_msgs +
                                     " WHERE (" + DB.gu_mimemsg + "=? OR " + DB.id_message + "=?) AND " + DB.gu_category + "=? AND " + DB.bo_deleted + "<>1",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sMsgId);
      oStmt.setString(2, sMsgId);
      oStmt.setString(3, getCategoryGuid());
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_mimemsg + "," + DB.id_message + "," + DB.pg_message + "," + DB.tx_subject + "," + DB.tx_email_from + "," + DB.tx_email_reply + "," + DB.nm_from + " FROM " + DB.k_mime_msgs + " WHERE " + DB.id_message + "='"+sMsgId+"' AND " + DB.gu_category + "='"+getCategoryGuid()+"' AND " + DB.bo_deleted + "<>1)");

      oStmt = oJdcn.prepareStatement("SELECT " + DB.gu_mimemsg + "," + DB.id_message + "," + DB.pg_message + "," +
      	                                         DB.tx_subject + "," + DB.tx_email_from + "," + DB.tx_email_reply + "," +
      	                                         DB.nm_from + " FROM " + DB.k_mime_msgs +
      	                             " WHERE " + DB.id_message + "=? AND " + DB.gu_category + "=? AND " + DB.bo_deleted + "<>1",
                                     ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, sMsgId);
      oStmt.setString(2, getCategoryGuid());
    } // fi (sMsgId.length()==32)

    ResultSet oRSet = oStmt.executeQuery();

    if (oRSet.next()) {
      oRetVal = new Properties();
      String s;
      BigDecimal d;
      s = oRSet.getString(1);
      if (DebugFile.trace) DebugFile.writeln("gu_mimemsg="+s);
      oRetVal.put(DB.gu_mimemsg, s);
      s = oRSet.getString(2);
      if (!oRSet.wasNull()) oRetVal.put(DB.id_message, s);
      if (DebugFile.trace) DebugFile.writeln("id_message="+s);
      d = oRSet.getBigDecimal(3);
      if (!oRSet.wasNull()) oRetVal.put(DB.pg_message, d.toString());
      s = oRSet.getString(4);
      if (!oRSet.wasNull()) oRetVal.put(DB.tx_subject, s);
      s = oRSet.getString(5);
      if (!oRSet.wasNull()) oRetVal.put(DB.tx_email_from, s);
      s = oRSet.getString(6);
      if (!oRSet.wasNull()) oRetVal.put(DB.tx_email_reply, s);
      s = oRSet.getString(7);
      if (!oRSet.wasNull()) oRetVal.put(DB.nm_from, s);
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("message not found");
      oRetVal = null;
    }

    oRSet.close();
    oStmt.close();

    if (DebugFile.trace) {
      if (oRetVal==null) {
        DebugFile.decIdent();
        DebugFile.writeln("End DBFolder.getMessageHeaders() : null");
      } else {
        DebugFile.writeln(oRetVal.toString());
        DebugFile.decIdent();
        DebugFile.writeln("End DBFolder.getMessageHeaders() : Properties["+String.valueOf(oRetVal.size())+"]");
      }
    }

    return oRetVal;
  } // getMessageHeaders

  // ---------------------------------------------------------------------------

  public int importMbox(String sMboxFilePath)
    throws FileNotFoundException, IOException, MessagingException {

    MimeMessage oMsg;
    InputStream oMsgStrm;
    Session oSession = ((DBStore)getStore()).getSession();
    MboxFile oInputMbox = new MboxFile(sMboxFilePath, MboxFile.READ_ONLY);

    final int iMsgCount = oInputMbox.getMessageCount();

    for (int m=0; m<iMsgCount; m++) {
      oMsgStrm = oInputMbox.getMessageAsStream(m);
      oMsg = new MimeMessage(oSession, oMsgStrm);
      appendMessage(oMsg);
      oMsgStrm.close();
    }

    oInputMbox.close();

    return iMsgCount;
  } // importMbox

  // ---------------------------------------------------------------------------

  /**
   * Delete every message from the index and rebuild it by re-reading the specified MBOX file
   * @param sMboxFilePath String Full path to MBOX file
   * @throws FileNotFoundException
   * @throws IOException
   * @throws MessagingException
   * @throws SQLException
   */
  public void reindexMbox(String sMboxFilePath)
    throws FileNotFoundException, IOException, MessagingException, SQLException {

    MimeMessage oMsg;
    InputStream oMsgStrm;
    int iMsgCount;
    HeadersHelper oHlpr;
    RecipientsHelper oRecps;
    BigDecimal dPgMessage;
    String sGuMimeMsg;
    String sMessageID;
    String sMsgCharSeq;
    String sContentMD5;
    int iSize;
    Integer oSize;
    MboxFile oInputMbox = null;
	JDCConnection oConn = null;
	
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBFolder.reindexMbox("+sMboxFilePath+")");
      DebugFile.incIdent();
    }

    try {
      ByteArrayOutputStream byOutStrm = null;
      Session oSession = ((DBStore)getStore()).getSession();
      String sGuWorkArea = ((DBStore)getStore()).getUser().getString(DB.gu_workarea);
      String sGuFolder = getCategoryGuid();
      oInputMbox = new MboxFile(sMboxFilePath, MboxFile.READ_ONLY);
      DBSubset oMsgs = new DBSubset (DB.k_mime_msgs, DB.gu_mimemsg+","+DB.gu_workarea, DB.gu_category+"=?", 1000);
      oConn = getConnection();
      iMsgCount = oMsgs.load(oConn, new Object[]{sGuFolder});

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iMsgCount)+" indexed messages");

      for (int m=0; m<iMsgCount; m++)
        DBMimeMessage.delete(oConn, sGuFolder, oMsgs.getString(0,m));

      iMsgCount = oInputMbox.getMessageCount();
      
      if (!oConn.getAutoCommit()) oConn.commit();
      
      oConn = null;

      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iMsgCount)+" stored messages");

      for (int m=0; m<iMsgCount; m++) {
        sGuMimeMsg = Gadgets.generateUUID();
        oMsgStrm = oInputMbox.getMessageAsStream(m);
        oMsg = new MimeMessage(oSession, oMsgStrm);
        oHlpr = new HeadersHelper(oMsg);
        oRecps = new RecipientsHelper(oMsg);
        dPgMessage = new BigDecimal(m);
        sMessageID = oHlpr.decodeMessageId(sGuMimeMsg);
        sMsgCharSeq = DBMimeMessage.source(oMsg, "ISO8859_1");
        sContentMD5 = oHlpr.getContentMD5();
        if (null==sContentMD5) sContentMD5 = HeadersHelper.computeContentMD5(sMsgCharSeq.getBytes());
        iSize = ((iOpenMode&MODE_MBOX)!=0) ? sMsgCharSeq.length() : oMsg.getSize();
        oSize = (iSize>=0 ? new Integer(iSize) : null);
        byOutStrm = getBodyAsStream(oMsg);

        indexMessage(Gadgets.generateUUID(), sGuWorkArea, oMsg, oSize,
                   ((iOpenMode&MODE_MBOX)!=0) ? new BigDecimal(oInputMbox.getMessagePosition(m)) : null,
                   oHlpr.getContentType(),
                   oHlpr.getContentID(), sMessageID,
                   oHlpr.getDisposition(), sContentMD5,
                   oHlpr.getDescription(), oHlpr.getFileName(),
                   oHlpr.getEncoding(), oHlpr.getSubject(),
                   oHlpr.getPriority(), oHlpr.getFlags(),
                   oHlpr.getSentTimestamp(), oHlpr.getReceivedTimestamp(),
                   RecipientsHelper.getFromAddress(oMsg),
                   RecipientsHelper.getReplyAddress(oMsg),
                   oRecps.getRecipients(Message.RecipientType.TO),
                   oRecps.getRecipients(Message.RecipientType.CC),
                   oRecps.getRecipients(Message.RecipientType.BCC),
                   oHlpr.isSpam(), byOutStrm, sMsgCharSeq);

        byOutStrm.close();
        oMsgStrm.close();
      } // next
      oInputMbox.close();
      oInputMbox=null;
      
    } catch (FileNotFoundException fnfe) {
      try { if (null!=oConn) if (!oConn.isClosed()) if (!oConn.getAutoCommit()) oConn.rollback(); } catch (Exception ignore) {}
      throw fnfe;
    } catch (IOException ioe) {
      try { if (null!=oConn) if (!oConn.isClosed()) if (!oConn.getAutoCommit()) oConn.rollback(); } catch (Exception ignore) {}
      throw ioe;
    } catch (MessagingException me) {
        try { if (null!=oConn) if (!oConn.isClosed()) if (!oConn.getAutoCommit()) oConn.rollback(); } catch (Exception ignore) {}
      throw me;
    } catch (SQLException sqle) {
        try { if (null!=oConn) if (!oConn.isClosed()) if (!oConn.getAutoCommit()) oConn.rollback(); } catch (Exception ignore) {}
      throw sqle;
    } finally {
      try { if (null!=oInputMbox) oInputMbox.close(); } catch (Exception ignore) {}
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBFolder.reindexMbox()");
    }
  } // reindexMbox

  // ---------------------------------------------------------------------------

  /**
   * Delete very message from th eindex and rebuild it by reading the default MBOX file for this folder
   * @throws FileNotFoundException
   * @throws IOException
   * @throws MessagingException
   * @throws SQLException
   */
  public void reindexMbox()
    throws FileNotFoundException, IOException, MessagingException, SQLException {
    reindexMbox(getFilePath());
  }

  // ===========================================================================
   public static final short ClassId = 800;
}
