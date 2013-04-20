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


import java.io.File;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.net.ProtocolException;

import javax.mail.FetchProfile;
import javax.mail.Session;
import javax.mail.URLName;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.StoreClosedException;
import javax.mail.AuthenticationFailedException;
import javax.mail.FolderNotFoundException;
import javax.mail.internet.MimeMessage;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Environment;
import com.knowgate.hipergate.Category;
import com.knowgate.acl.*;
import com.knowgate.dfs.FileSystem;

/**
 * Manages local storage of mail messages at RDBMS and MBOX files
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class DBStore extends javax.mail.Store {

  private JDCConnection oConn;
  private ACLUser oUser;
  private URLName oURL;

  public DBStore (javax.mail.Session session, URLName url)
    throws MessagingException {
    super(session, url);

    try {
      Class.forName("javax.mail.Store");
    } catch (ClassNotFoundException cnf) {}

    oURL = new URLName(url.getProtocol(), url.getHost(), url.getPort(), url.getFile(), url.getUsername(), url.getPassword());

    if (null!=url.getFile()) {
      File oDir = new File(url.getFile());

      if (!oDir.exists()) {
        FileSystem oFS = new FileSystem();
        try {
          oFS.mkdirs(url.getFile());
        } catch (Exception e) {
          if (DebugFile.trace) DebugFile.writeln(e.getClass().getName() + " " + e.getMessage());
          throw new MessagingException(e.getMessage(), e);
        }
      }
    }

    oConn = null;
    oUser = null;
  }

  // ----------------------------------------------------------------------------------------

  /**
   * Create new DBStore instance and open connection to the database
   * @param oMailSession Session
   * @param sProfile String
   * @param sMBoxDir String
   * @param sGuUser String
   * @param sPwd String
   * @return DBStore
   * @throws MessagingException
   */
  public static DBStore open (Session oMailSession, String sProfile,
                              String sMBoxDir, String sGuUser, String sPwd)
    throws MessagingException {
    DBStore oNewInstance = new DBStore (oMailSession, new URLName("jdbc://", sProfile, -1, sMBoxDir, sGuUser, sPwd));
    oNewInstance.connect(sProfile, sGuUser, sPwd);
    return oNewInstance;
  } // open

  // ---------------------------------------------------------------------------

  public JDCConnection getConnection()
  	throws SQLException,MessagingException {

    if (!isConnected()) {

      if (DebugFile.trace) DebugFile.writeln("DBStore.getConnection() connection is null");      

      connect();

    } else if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {

      long lStartValidation = new java.util.Date().getTime();
      
      if (!oConn.isValid(10)) {

        long lEndValidation = new java.util.Date().getTime();

        if (DebugFile.trace) DebugFile.writeln("DBStore.getConnection() connection with process id. "+oConn.pid()+" is not valid after "+String.valueOf(lEndValidation-lStartValidation)+" ms of connection testing");

	    try {
	  	  oConn.close();
	      oConn=null;
	    }
	    catch (Exception xcpt) {
          if (DebugFile.trace)
      	    DebugFile.writeln("DBStore.getConnection() "+xcpt.getClass().getName()+" "+xcpt.getMessage());
	    } 

	    connect();

	  } // isValid
    } // fi (DBMS_POSTGRESQL)
    	
    if (DebugFile.trace) {
      if (oConn!=null) DebugFile.writeln("DBStore.getConnection() Connection process id. is " + oConn.pid());
    }

    return oConn;
  } // getConnection

  // ---------------------------------------------------------------------------

  public Session getSession() {
    return session;
  }

  // ---------------------------------------------------------------------------

  public boolean isConnected() {
    return (oConn!=null);
  }

  // ---------------------------------------------------------------------------

  /**
   *
   * @param host Name of profile file without extension { hipergate, real, test, demo }
   * @param port Not used, must be -1
   * @param user GUID of user to be authenticated
   * @param password User password in clear text
   * @return <b>true</b>
   * @throws MessagingException
   */
  protected boolean protocolConnect(String host, int port, String user, String password)
    throws AuthenticationFailedException, MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBStore.protocolConnect("+host+", "+user+", ...)");
      DebugFile.incIdent();
    }

    if (oConn!=null || isConnected()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException("DBStore is already connected");
    }

    String dburl = Environment.getProfileVar(host, "dburl");
    String dbusr = Environment.getProfileVar(host, "dbuser");
    String dbpwd = Environment.getProfileVar(host, "dbpassword");
    String schema = Environment.getProfileVar(host, "schema", "");

    try {
      if (DebugFile.trace)
        DebugFile.writeln("DriverManager.getConnection("+dburl+", "+dbusr+", ...)");

      if (schema.length()>0)
        oConn = new JDCConnection(DriverManager.getConnection(dburl, dbusr, dbpwd), null, schema);
      else
        oConn = new JDCConnection(DriverManager.getConnection(dburl, dbusr, dbpwd), null);

      short iAuth = ACL.autenticate(oConn, user, password, ACL.PWD_CLEAR_TEXT);

      if (iAuth<0) {
        oConn.close();
        oConn = null;
        if (DebugFile.trace) DebugFile.decIdent();
        throw new AuthenticationFailedException(ACL.getErrorMessage(iAuth) + " (" + user + ")");
      }
      else {
        oUser = new ACLUser(oConn, user);
        setConnected(true);
        oConn.setAutoCommit(false);
      }
    }
    catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException(sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) {
      try { if (oConn!=null) DebugFile.writeln("Connection process id. is "+oConn.pid()); } catch (Exception ignore ) { }
      DebugFile.decIdent();
      DebugFile.writeln("End DBStore.protocolConnect()");
    }

    return true;
  } // protocolConnect

  // ---------------------------------------------------------------------------

  public void connect (String host, String user, String password)
    throws MessagingException {

    protocolConnect (host, -1, user, password);
  }

  // ---------------------------------------------------------------------------

  public void commit ()
    throws MessagingException {

    try {
      if (oConn!=null) {
      	if (!oConn.isClosed()) {
      	  oConn.commit();
      	}
      }
    } catch (Exception xcpt) {
    	throw new MessagingException(xcpt.getMessage(), xcpt);
    }
  }

  // ---------------------------------------------------------------------------

  public void connect() throws MessagingException {
    URLName oURLName = getURLName();

    protocolConnect (oURLName.getHost(), oURLName.getPort(), oURLName.getUsername(), oURLName.getPassword());
  }

  // ---------------------------------------------------------------------------

  public void close() throws MessagingException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBStore.close()");
      DebugFile.incIdent();
    }
    if (null!=oConn && isConnected()) {
      try {
        oConn.close();
        oConn=null;
        oUser=null;
        setConnected(false);
      }
      catch (SQLException sqle) {
        throw new MessagingException(sqle.getMessage(), sqle);
      }
    }
    else {
      throw new StoreClosedException(this, "Store already closed");
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBStore.close()");
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * Calls getFolder(oURL.getFile());
   * @param oURL URLName
   * @return DBFolder instance
   * @throws StoreClosedException
   * @throws FolderNotFoundException
   * @throws MessagingException
   */
  public Folder getFolder(URLName oURL)
    throws StoreClosedException,FolderNotFoundException,MessagingException {

    return getFolder(oURL.getFile());
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get folder by guid or name</p>
   * @param sFolderName String This parameter may be either the folder GUID or its name
   * valid folder names are {inbox, outbox, drafts, sent, spam, deleted, received}
   * @return DBFolder instance
   * @throws StoreClosedException
   * @throws FolderNotFoundException
   * @throws MessagingException
   */
  public Folder getFolder(String sFolderName)
    throws StoreClosedException,FolderNotFoundException,MessagingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBStore.getFolder("+sFolderName+")");
      DebugFile.incIdent();
    }

    if (sFolderName==null) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("DBStore.getFolder() folder name cannot be null");
    }
    if (sFolderName.length()==0) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("DBStore.getFolder() folder name cannot be an empty string");
    }
    if (sFolderName.equalsIgnoreCase("null")) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("DBStore.getFolder() folder name cannot be 'null'");
    }

    if (!isConnected()) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new StoreClosedException(this, "Store is closed");
    }

    DBFolder oRetVal = new DBFolder(this, sFolderName);
    boolean bExistsGuid = false;
    PreparedStatement oStmt = null;
    ResultSet oRSet = null;

    try {
      if (sFolderName.length()==32) {
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT NULL FROM "+DB.k_categories+" WHERE "+DB.gu_category+"='"+sFolderName+"')");

        oStmt = getConnection().prepareStatement("SELECT NULL FROM "+DB.k_categories+" WHERE "+DB.gu_category+"=?");
        oStmt.setString(1, sFolderName);
        oRSet = oStmt.executeQuery();
        bExistsGuid = oRSet.next();
        oRSet.close();
        oStmt.close();
      }
      else
        bExistsGuid = false;

      if (bExistsGuid) {
        oRetVal.getCategory().load(oConn, new Object[] {sFolderName});
      }
      else {
        String sGuid = oUser.getMailFolder(oConn, sFolderName);

        if (null==sGuid) {
          if (DebugFile.trace) DebugFile.decIdent();
          throw new FolderNotFoundException(oRetVal, sFolderName);
        }
        oRetVal.getCategory().load(oConn, new Object[] {sGuid});
      }
    }
    catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException(sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBStore.getFolder("+sFolderName+")");
    }

    return oRetVal;
  } // getFolder

  // ---------------------------------------------------------------------------

  /**
   * Same as getFolder() but casting result to DBFolder
   * @param sFolderName String
   * @return DBFolder
   * @throws StoreClosedException
   * @throws FolderNotFoundException
   * @throws MessagingException
   */
  public DBFolder getDBFolder(String sFolderName)
    throws StoreClosedException,FolderNotFoundException,MessagingException {
    return (DBFolder) getFolder(sFolderName);
  }

  // ---------------------------------------------------------------------------

  /**
   * Get DBFolder and open it in the specified mode
   * @param sFolderName String
   * @param iMode int {DBFolder.READ_ONLY | DBFolder.READ_WRITE}
   * @return DBFolder
   * @throws StoreClosedException
   * @throws FolderNotFoundException
   * @throws MessagingException
   */
  public DBFolder openDBFolder(String sFolderName, int iMode)
    throws StoreClosedException,FolderNotFoundException,MessagingException {
    DBFolder oFldr = (DBFolder) getFolder(sFolderName);
    oFldr.open(iMode);
    return oFldr;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get inbox Folder
   * @return DBFolder
   * @throws StoreClosedException
   * @throws FolderNotFoundException
   * @throws MessagingException
   */
  public Folder getDefaultFolder()
    throws StoreClosedException,FolderNotFoundException,MessagingException {

    return getFolder("inbox");
  } // getDefaultFolder

  // ---------------------------------------------------------------------------

  public Folder[] getPersonalNamespaces()
    throws StoreClosedException,FolderNotFoundException,MessagingException {

    DBFolder[] aRetVal;

    if (!isConnected())
      throw new StoreClosedException(this, "Store is closed");

    try {

      String sGuid = oUser.getMailRoot(oConn);

      if (null == sGuid)
        throw new FolderNotFoundException(new DBFolder(this, "mailroot"), "mailroot");

      Category oMailRoot = new Category(sGuid);
      DBSubset oChilds = oMailRoot.getChilds(oConn);
      int iFolders = oChilds.getRowCount();

      if (0==iFolders)
        aRetVal = null;
      else {
        Object[] oPK = new Object[]{null};
        DBFolder oFR;
        aRetVal = new DBFolder[iFolders];
        for (int f=0; f<iFolders; f++) {
          oPK[0] = oChilds.get(0,f);
          oFR = new DBFolder(this, null);
          oFR.getCategory().load(oConn, oPK);
          aRetVal[f] = oFR;
        } // next
      } // fi
    }
    catch (SQLException sqle) {
      throw new MessagingException(sqle.getMessage(), sqle);
    }
    return aRetVal;
  }

  // ---------------------------------------------------------------------------

  public Folder[] getSharedNamespaces() {
    return null;
  }

  // ---------------------------------------------------------------------------

  public Folder[] getUserNamespaces(String sUserId)
      throws StoreClosedException,FolderNotFoundException,MessagingException {
    DBFolder[] aRetVal;

    if (!isConnected())
      throw new StoreClosedException(this, "Store is closed");

    try {

      ACLUser oUsr = new ACLUser(sUserId);

      String sGuid = oUsr.getMailRoot(oConn);

      if (null == sGuid)
        throw new FolderNotFoundException(new DBFolder(this, "mailroot"), "mailroot");

      Category oMailRoot = new Category(sGuid);
      DBSubset oChilds = oMailRoot.getChilds(oConn);
      int iFolders = oChilds.getRowCount();

      if (0==iFolders)
        aRetVal = null;
      else {
        Object[] oPK = new Object[]{null};
        DBFolder oFR;
        aRetVal = new DBFolder[iFolders];
        for (int f=0; f<iFolders; f++) {
          oPK[0] = oChilds.get(0,f);
          oFR = new DBFolder(this, null);
          oFR.getCategory().load(oConn, oPK);
          aRetVal[f] = oFR;
        } // next
      } // fi
    }
    catch (SQLException sqle) {
      throw new MessagingException(sqle.getMessage(), sqle);
    }
    return aRetVal;
  } // getUserNamespaces

  // ---------------------------------------------------------------------------

  public URLName getURLName() {
    return oURL;
  }

  // ---------------------------------------------------------------------------

  public ACLUser getUser() {
    return oUser;
  }

  // ----------------------------------------------------------------------------------------

  /**
   * Fetch a message from remote folder into local cache
   * @param oIncomingFldr Incoming Folder (POP3, IMAP, or other)
   * @param iMsgNum int Message number
   * @return DBMimeMessage
   * @throws MessagingException
   * @throws ArrayIndexOutOfBoundsException
   */
  public DBMimeMessage preFetchMessage(Folder oIncomingFldr, int iMsgNum)
    throws MessagingException,ArrayIndexOutOfBoundsException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBStore.preFetchMessage([Folder],"+String.valueOf(iMsgNum)+")");
      DebugFile.incIdent();
    }

    if (null==oIncomingFldr)
      throw new MessagingException("Unable to open folder",
                                   new NullPointerException("DBStore.preFetchMessage() Folder is null"));

    boolean bWasConnected = isConnected();
    if (!bWasConnected) connect();
    boolean bWasOpen = oIncomingFldr.isOpen();
    if (!bWasOpen) oIncomingFldr.open(Folder.READ_ONLY);
    DBMimeMessage oMimeMsg = new DBMimeMessage ((MimeMessage) oIncomingFldr.getMessage(iMsgNum));
    
    DBFolder oInboxFldr = (DBFolder) getDefaultFolder();
    oInboxFldr.open(Folder.READ_WRITE|DBFolder.MODE_MBOX);
    oInboxFldr.appendMessage(oMimeMsg);
    oInboxFldr.close(false);

    DBFolder oLocalFldr = openDBFolder("inbox", Folder.READ_ONLY|DBFolder.MODE_MBOX);
    oMimeMsg.setFolder(oInboxFldr);
    oLocalFldr.close(false);
    
    if (!bWasOpen) oIncomingFldr.close(false);
    if (!bWasConnected) close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBStore.preFetchMessage() : " + oMimeMsg.getMessageGuid());
    }

    return oMimeMsg;
  } // prefetchMessage

  // ----------------------------------------------------------------------------------------

  /**
   * Fetch a message from remote folder into local cache
   * @param oIncomingFldr Incoming Folder (POP3, IMAP, or other)
   * @param sMsgId String Message Id.
   * @return DBMimeMessage
   * @throws MessagingException
   * @throws ArrayIndexOutOfBoundsException
   */
  public DBMimeMessage preFetchMessage(Folder oIncomingFldr, String sMsgId)
    throws MessagingException,ArrayIndexOutOfBoundsException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBStore.preFetchMessage([Folder],"+sMsgId+")");
      DebugFile.incIdent();
    }

    if (null==oIncomingFldr)
      throw new MessagingException("Unable to open folder",
                                   new NullPointerException("DBStore.preFetchMessage() Folder is null"));

    boolean bWasConnected = isConnected();
    if (!bWasConnected) connect();
    boolean bWasOpen = oIncomingFldr.isOpen();
    if (!bWasOpen) oIncomingFldr.open(Folder.READ_ONLY);
    DBMimeMessage oMimeMsg = null;
    
    Message[] aMsgs = oIncomingFldr.getMessages();
    if (null!=aMsgs) {
      final int nMsgs =  aMsgs.length;
      if (nMsgs>0) {
    	FetchProfile oFtchPrfl = new FetchProfile();
    	oFtchPrfl.add(FetchProfile.Item.CONTENT_INFO);
    	oIncomingFldr.fetch(aMsgs, oFtchPrfl);
    	for (int m=0; m<nMsgs; m++) {
    	  if (DebugFile.trace)
    	    DebugFile.writeln("reading message "+((MimeMessage)aMsgs[m]).getMessageID());
    	  if (sMsgId.equals(((MimeMessage)aMsgs[m]).getMessageID())) {
    		oMimeMsg = new DBMimeMessage ((MimeMessage) oIncomingFldr.getMessage(m+1));
    		break;
    	  }
    	} // next
      } else {
        throw new ArrayIndexOutOfBoundsException("Folder "+oIncomingFldr.getName()+" contains no messages");    	  
      }
    } else {
      throw new ArrayIndexOutOfBoundsException("Folder "+oIncomingFldr.getName()+" is empty");
    }
    
    if (null==oMimeMsg)
      throw new ArrayIndexOutOfBoundsException("No message with id "+sMsgId+" was found at folder "+oIncomingFldr.getName());
    
    DBFolder oInboxFldr = (DBFolder) getDefaultFolder();
    oInboxFldr.open(Folder.READ_WRITE|DBFolder.MODE_MBOX);
    oInboxFldr.appendMessage(oMimeMsg);
    oInboxFldr.close(false);

    DBFolder oLocalFldr = openDBFolder("inbox", Folder.READ_ONLY|DBFolder.MODE_MBOX);
    oMimeMsg.setFolder(oInboxFldr);
    oLocalFldr.close(false);
    
    if (!bWasOpen) oIncomingFldr.close(false);
    if (!bWasConnected) close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBStore.preFetchMessage() : " + oMimeMsg.getMessageGuid());
    }

    return oMimeMsg;
  } // prefetchMessage
  
  // ----------------------------------------------------------------------------------------

  public static String MBoxDirectory(String sProfile, int iDomainId, String sWorkAreaGu)
    throws ProtocolException {
    String sSep = System.getProperty("file.separator");
    String sFileProtocol = Environment.getProfileVar(sProfile, "fileprotocol", "file://");
    String sMBoxDir;
    if (sFileProtocol.equals("file://"))
      sMBoxDir = sFileProtocol + Environment.getProfilePath(sProfile, "storage") + "domains" + sSep + String.valueOf(iDomainId) + sSep + "workareas" + sSep + sWorkAreaGu;
    else
      throw new java.net.ProtocolException(sFileProtocol);
    return sMBoxDir;
    } // MBoxDirectory
}
