/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

package com.knowgate.forums;

import java.util.Date;
import java.util.HashMap;

import java.io.IOException;
import java.io.Reader;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.hipergate.Product;

/**
 * <p>NewsMessage</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class NewsMessage extends DBPersist{

  private HashMap<String,NewsMessageTag> oTagsSet;

  /**
   * Create empty NewsMessage
   */
  public NewsMessage() {
    super(DB.k_newsmsgs, "NewsMessage");
	oTagsSet = new HashMap<String,NewsMessageTag>();
  }

  /**
   * Load NewsMessage from database
   * @since 4.0
   */
  public NewsMessage(JDCConnection oConn, String sGuMsg) throws SQLException {
    super(DB.k_newsmsgs, "NewsMessage");
    oTagsSet = new HashMap<String,NewsMessageTag>();
    load(oConn, new Object[]{sGuMsg});
  }
	
  // ----------------------------------------------------------

  /**
   * Post a Plain Text Message
   * @param oConn Database Conenction
   * @param sNewsGroupId GUID of NewsGroup for posting
   * @param sThreadId GUID of message thread (may be <b>null</b>)
   * @param dtStart Start publishing date (may be <b>null</b>)
   * @param dtEnd Expiration date (may be <b>null</b>)
   * @param iStatus STATUS_VALIDATED or STATUS_PENDING
   * @param sText Message Text
   * @return GUID of new message
   * @throws SQLException
   */
  public String post (JDCConnection oConn, String sNewsGroupId, String sThreadId, Date dtStart, Date dtEnd, short iStatus, String sText) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsMessage.post([Connection], " + sNewsGroupId + "," + sThreadId + ")");
      DebugFile.incIdent();
    }

    String sRetVal;

    remove(DB.gu_newsgrp);
    if (sNewsGroupId!=null) put(DB.gu_newsgrp, sNewsGroupId);

    remove(DB.gu_thread_msg);
    if (sThreadId!=null) put(DB.gu_thread_msg, sThreadId);

    remove(DB.dt_start);
    if (dtStart!=null) put(DB.dt_start, dtStart);

    remove(DB.dt_end);
    if (dtEnd!=null) put(DB.dt_end, dtEnd);

    remove(DB.id_status);
    put(DB.id_status, iStatus);

    remove(DB.tx_msg);
    if (sText!=null) put(DB.tx_msg, sText);

    if (store(oConn))
      sRetVal = getString(DB.gu_msg);
    else
      sRetVal = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsMessage.post() : " + sRetVal);
    }

    return sRetVal;
  } // post

  // ----------------------------------------------------------

  /**
   * Load message
   * @param oConn JDCConnection
   * @param sGuMsg String Message GUID
   * @return boolean <b>true</b> if message was successfully loaded,
   * <b>false</b> if no message with such GUID was found
   * @throws SQLException
   * @since 3.0
   */
  public boolean load (JDCConnection oConn, String sGuMsg) throws SQLException {
    final int BufferSize = 2048;
    String sSQL = "SELECT * FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_msg + "=?";
    boolean bRetVal;
    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsMessage.load([Connection], " + sGuMsg + ")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    }
    getTable(oConn);
    PreparedStatement oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuMsg);
    ResultSet oRSet = oStmt.executeQuery();
    bRetVal = oRSet.next();
    if (bRetVal) {
      ResultSetMetaData oMDat = oRSet.getMetaData();
      int nCols = oMDat.getColumnCount();
      int iType;
      int iReaded;
      for (int c=1; c<=nCols; c++) {
        iType = oMDat.getColumnType(c);
        if ((iType!=Types.LONGVARCHAR) && (iType!=Types.LONGVARBINARY) &&
            (iType!=Types.CLOB) && (iType!=Types.BLOB)) {
          put (oMDat.getColumnName(c).toLowerCase(), oRSet.getObject(c));
        } else if (iType==Types.LONGVARCHAR) {
          char Buffer[] = new char[BufferSize];
          StringBuffer oBody = new StringBuffer();
          Reader oRead = oRSet.getCharacterStream(c);
          if (null!=oRead) {
            try {
              do {
                iReaded = oRead.read(Buffer,0,BufferSize);
                if (iReaded>0) oBody.append(Buffer,0,iReaded);
              } while (BufferSize==iReaded);
              oRead.close();
            } catch (IOException ioe) {
              try { oRSet.close(); } catch (Exception ignore) {}
              try { oStmt.close(); } catch (Exception ignore) {}
              throw new SQLException (ioe.getMessage());
            }
            put (oMDat.getColumnName(c).toLowerCase(), oBody.toString());
          } // fi (oRead!=null)
        }
      } // next (c)
    } // fi (bRetVal)
    oRSet.close();
    oStmt.close();
    
    // Added at v4.0
    sSQL = "SELECT "+DB.gu_category+" FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + "=? AND " + DB.id_class + "=" + String.valueOf(NewsMessage.ClassId);
    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuMsg);
    oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      put(DB.gu_newsgrp, oRSet.getString(1));
    }
    oRSet.close();
    oStmt.close();

    oTagsSet.clear();
    DBSubset oTags = new DBSubset(DB.k_newsmsg_tags, "*", DB.gu_msg+"=?", 10);
    int nTags = oTags.load(oConn, new Object[]{sGuMsg});
    for (int t=0; t<nTags; t++) {
      NewsMessageTag oNnts = new NewsMessageTag();
      oNnts.putAll(oTags.getRowAsMap(t));
      oTagsSet.put(oNnts.getString(DB.gu_tag), oNnts);
    } // next
    	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsMessage.load() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  // ----------------------------------------------------------

  /**
   * Get attachments
   * @param oConn JDCConnection
   * @return DBSubset listing attachments or <b>null</b> if this message has no attachments
   * @throws SQLException
   * @since 3.0
   */
  public DBSubset getAttachments(JDCConnection oConn) throws SQLException {
    Product oProd;
    if (isNull(DB.gu_product))
      return null;
    else {
      oProd = new Product(getString(DB.gu_product));
      return oProd.getLocations(oConn);
    }
  } // getAttachments

  // ----------------------------------------------------------

  public boolean load (JDCConnection oConn, Object[] aPK) throws SQLException {
    return load(oConn, (String) aPK[0]);
  }

  // ----------------------------------------------------------

  /**
   * <p>Store NewsMessage</p>
   * Message is posted into a NewsGroup by setting gu_newsgrp property of
   * NewsMessage to the GUID of newsMessage that will contain it.<br>
   * If gu_msg is <b>null</b> then a new GUID will be assigned.<br>
   * If gu_thread_msg is <b>null</b> and gu_parent_msg is <b>null</b> then gu_thread_msg will be assigned the same value as gu_msg.<br>
   * If gu_thread_msg is <b>null</b> and gu_parent_msg is not <b>null</b> then gu_thread_msg will be assigned the same the parent message thread.<br>
   * If id_status is <b>null</b> then it will be assigned to NewsMessage.STATUS_PENDING.<br>
   * If id_msg_type is <b>null</b> then it will be assigned to "TXT" by default.<br>
   * If dt_start is <b>null</b> then message visibility will start inmediately.<br>
   * If dt_end is <b>null</b> then message will never expire.<br>
   * dt_published will be set to the currents system date if not passed as a parameter.<br>
   * nu_thread_msgs will be updated in all messages from this thread by calling k_sp_count_thread_msgs stored procedure.<br>
   * Column k_newsgroups.dt_last_update is automatically set to the current date each time a new message is stored.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    boolean bNewMsg;
    boolean bRetVal;
    String sMsgId;
    int nThreadMsgs;
    ResultSet oRSet;
    Statement oStmt;
    CallableStatement oCall;
    PreparedStatement oUpdt = null;
    String sSQL;

    Timestamp dtNow = new Timestamp(DBBind.getTime());

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsMessage.store([Connection])");
      DebugFile.incIdent();
    }

    // Si no se especificó un identificador para el mensaje, entonces añadirlo automáticamente
    if (!AllVals.containsKey(DB.gu_msg)) {
      bNewMsg = true;
      sMsgId = Gadgets.generateUUID();
      put(DB.gu_msg, sMsgId);
    }
    else {
      bNewMsg = false;
      sMsgId = getString(DB.gu_msg);
    }

    if (!AllVals.containsKey(DB.id_status))
      put(DB.id_status, STATUS_PENDING);

    if (!AllVals.containsKey(DB.gu_thread_msg))
      if (AllVals.containsKey(DB.gu_parent_msg)) {
        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT " + DB.gu_thread_msg + " FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_msg + "='" + getStringNull(DB.gu_parent_msg, "null") + "'");

        oRSet = oStmt.executeQuery("SELECT " + DB.gu_thread_msg + " FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_msg + "='" + getString(DB.gu_parent_msg) + "'");
        if (oRSet.next())
          put (DB.gu_thread_msg, oRSet.getString(1));
        else
          put (DB.gu_thread_msg, sMsgId);
        oRSet.close();
        oStmt.close();
      }
      else
        put (DB.gu_thread_msg, sMsgId);

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
        sSQL = "SELECT k_sp_count_thread_msgs ('" + getString(DB.gu_thread_msg) + "')";

        oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

        oRSet = oStmt.executeQuery(sSQL);
        oRSet.next();
        nThreadMsgs = oRSet.getInt(1);
        oRSet.close();
        oStmt.close();
    }
    else {
        sSQL = "{call k_sp_count_thread_msgs(?,?)}";
        if (DebugFile.trace) DebugFile.writeln("CallableStatement.prepareCall(" + sSQL + ")");
        oCall = oConn.prepareCall(sSQL);
        oCall.setString(1, getString(DB.gu_thread_msg));
        oCall.registerOutParameter(2, Types.INTEGER);
        oCall.execute();
        nThreadMsgs = oCall.getInt(2);
        oCall.close();
    }

    if (bNewMsg) replace(DB.nu_thread_msgs, ++nThreadMsgs);

    replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.dt_start))
      put(DB.dt_start, dtNow);

    if (!AllVals.containsKey(DB.id_msg_type))
      put(DB.id_msg_type, "TXT");

    if (isNull(DB.dt_published)) replace(DB.dt_published, dtNow);

    bRetVal = super.store(oConn);

    oStmt = oConn.createStatement();
    sSQL = "UPDATE " + DB.k_newsmsgs + " SET " + DB.nu_thread_msgs + "=" + String.valueOf(nThreadMsgs) + " WHERE " + DB.gu_thread_msg + "='" + getString(DB.gu_thread_msg) + "'";
    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
    oStmt.executeUpdate(sSQL);
    oStmt.close();

    if (!AllVals.containsKey(DB.gu_newsgrp) && !sMsgId.equals(get (DB.gu_thread_msg))) {

      sSQL = "SELECT " + DB.gu_category + " FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + "='" + getStringNull(DB.gu_thread_msg, "null") + "'";

      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");

      oRSet = oStmt.executeQuery(sSQL);

      if (oRSet.next())
        put (DB.gu_newsgrp, oRSet.getString(1));

      oRSet.close();
      oStmt.close();
    }

	if (AllVals.containsKey(DB.gu_newsgrp)) {
      sSQL = "UPDATE " + DB.k_newsgroups + " SET " + DB.dt_last_update + "=? WHERE " + DB.gu_newsgrp + "=?";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement (" + sSQL + ")");
      oUpdt = oConn.prepareStatement(sSQL);
      oUpdt.setTimestamp(1, new Timestamp(new Date().getTime()));
      oUpdt.setObject(2, AllVals.get(DB.gu_newsgrp), java.sql.Types.CHAR);
      oUpdt.executeUpdate();
      oUpdt.close();
      oUpdt = null;

      if (bRetVal) {
        if (DebugFile.trace) DebugFile.writeln("Category.store() && containsKey(DB.gu_newsgrp)");

        if (!bNewMsg) {
          sSQL = "DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "='" + getString(DB.gu_newsgrp) + "' AND " + DB.gu_object + "='" + sMsgId + "'";
          oStmt = oConn.createStatement();
          if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
          oStmt.executeUpdate(sSQL);
          oStmt.close();
        } // fi (!bNewMsg)

        sSQL = "INSERT INTO " + DB.k_x_cat_objs + "(" + DB.gu_category + "," + DB.gu_object + "," + DB.id_class + "," + DB.bi_attribs + "," + DB.od_position + ") VALUES ('" + getString(DB.gu_newsgrp) + "','" + sMsgId + "'," + String.valueOf(NewsMessage.ClassId) + ",0,NULL)";
        oStmt = oConn.createStatement();
        if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
        oStmt.execute(sSQL);
        oStmt.close();
      } // fi (bRetVal)
	} // fi

	DBSubset oOldTags = new DBSubset (DB.k_newsmsg_tags, DB.gu_tag, DB.gu_msg+"=?", 10);
	int nTags = oOldTags.load(oConn, new Object[]{getString(DB.gu_msg)});
	for (int t=0; t<nTags; t++) {
      DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_newsgroup_tags+" SET "+DB.nu_msgs+"="+DB.nu_msgs+"-1 WHERE "+DB.gu_newsgrp+"='"+getString(DB.gu_newsgrp)+"' AND "+DB.gu_tag+"='"+oOldTags.getString(0,t)+"'");
	}
	DBCommand.executeUpdate(oConn, "DELETE FROM "+DB.k_newsmsg_tags+" WHERE "+DB.gu_msg+"='"+getString(DB.gu_msg)+"'");

	if (!isNull(DB.tx_tags)) {
	  String[] aTags = Gadgets.split(getString(DB.tx_tags),',');
	  nTags = aTags.length;
	  PreparedStatement oTagi = oConn.prepareStatement("INSERT INTO "+DB.k_newsmsg_tags+" ("+DB.gu_msg+","+DB.gu_tag+") VALUES (?,?)");
	  PreparedStatement oTagu = oConn.prepareStatement("UPDATE "+DB.k_newsgroup_tags+" SET "+DB.nu_msgs+"="+DB.nu_msgs+"+1 WHERE "+DB.gu_newsgrp+"=? AND "+DB.gu_tag+"=?");
      for (int t=0; t<nTags; t++) {
		oTagi.setString(1, getString(DB.gu_msg));
		oTagi.setString(2, aTags[t].trim());
		oTagu.setString(1, getString(DB.gu_newsgrp));
		oTagu.setString(2, aTags[t].trim());
	  } // next
      oTagu.close();
      oTagi.close();
	} // fi (tx_tags)
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsMessage.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  /**
   * Move this message and all its replies to another NewsGroup
   * @param oConn Database Conenction
   * @param sNewsGroupId GUID of the target NewsGroup
   * @throws SQLException
   * @since 5.0
   */
  public void move (JDCConnection oConn, String sNewsGroupId) throws SQLException {
    if (!isNull(DB.gu_parent_msg))
	  throw new SQLException("NewsMessage.move() only the first message of each thread can be moved with all its replies");

      if (DebugFile.trace) {
        DebugFile.writeln("Begin NewsMessage.move([Connection],"+sNewsGroupId+")");
        DebugFile.incIdent();
      }

      String sSQL = "UPDATE " + DB.k_x_cat_objs + " SET "+DB.gu_category+"=? WHERE "+DB.gu_object+" IN (SELECT "+DB.gu_msg+" FROM "+DB.k_newsmsgs+" WHERE "+DB.gu_thread_msg+"=?)";

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
      PreparedStatement oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1, sNewsGroupId);
      oStmt.setString(2, getString(DB.gu_msg));
      oStmt.executeUpdate();
      oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsMessage.move()");
    }
  } // move

  // ----------------------------------------------------------

  /**
   * <p>Delete NewsMessage.</p>
   * Files attached to NewsMessage (stored as Products) are delete prior to
   * the NewsMessage itself. Then k_sp_del_newsmsg stored procedure is called.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    Product oProd;
    Statement oStmt;
    CallableStatement oCall;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsMessage.delete([Connection])");
      DebugFile.incIdent();
      DebugFile.writeln("gu_msg=" + getStringNull(DB.gu_msg,"null"));
    }

    if (!isNull(DB.gu_product)) {
      oProd = new Product(oConn, getString(DB.gu_product));

      oStmt = oConn.createStatement();
      sSQL = "UPDATE " + DB.k_newsmsgs + " SET " + DB.gu_product + "=NULL WHERE " + DB.gu_msg + "='" + getString(DB.gu_msg) + "'";
      if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");
      oStmt.executeUpdate(sSQL);
      oStmt.close();

      oProd.delete(oConn);

      remove(DB.gu_product);
    } // fi

    sSQL = "{ call k_sp_del_newsmsg ('" + getString(DB.gu_msg) + "') }";
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall(" + sSQL + ")");
    oCall = oConn.prepareCall(sSQL);
    oCall.execute();
    oCall.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsMessage.delete() : true");
    }

    return true;
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Get e-mails subscribed to current message group or thread</p>
   * Only active subscribers with digest option not selected are returned
   * @param oConn Database Connection
   * @return Array of e-mail addresses as strings
   * @throws SQLException
   * @since 4.0
   */
  public String[] subscribers(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsMessage.subscribers([Connection])");
      DebugFile.incIdent();
    }

    DBSubset oGroupSubscribers = new DBSubset(DB.k_newsgroup_subscriptions,
    										  DB.tx_email,
    										  DB.id_status+"="+String.valueOf(Subscription.ACTIVE)+ " AND "+
    										  DB.tp_subscrip+"="+String.valueOf(Subscription.GROUP_NONE)+ " AND "+
    										  DB.gu_newsgrp+"=?", 100);
    
    String[] aSubscribers;
    
    int nGroupSubscribers = oGroupSubscribers.load(oConn, new Object[]{get(DB.gu_newsgrp)});
    
    DBSubset oThreadSubscribers = new DBSubset(DB.k_newsgroup_subscriptions,
    										  DB.tx_email,
    										  DB.id_status+"="+String.valueOf(Subscription.ACTIVE_MY_FOR_THREADS_ONLY)+ " AND "+
    										  DB.tp_subscrip+"="+String.valueOf(Subscription.GROUP_NONE)+ " AND "+
    										  DB.gu_user + " IN (SELECT "+DB.gu_writer+" FROM "+DB.k_newsmsgs+" WHERE "+DB.gu_thread_msg+"=?) AND "+
    										  DB.gu_newsgrp+"=?", 10);
    int nThreadSubscribers = oThreadSubscribers.load(oConn, new Object[]{get(DB.gu_thread_msg),get(DB.gu_newsgrp)});

	if (nGroupSubscribers+nThreadSubscribers==0) {
	  aSubscribers=null;
	} else {
	  aSubscribers = new String[nGroupSubscribers+nThreadSubscribers];
	  int s = 0;
	  for (int g=0; g<nGroupSubscribers; g++) {
	    aSubscribers[s++] = oGroupSubscribers.getString(DB.tx_email,g);
	  }
	  for (int t=0; t<nThreadSubscribers; t++) {
	    aSubscribers[s++] = oThreadSubscribers.getString(DB.tx_email,t);
	  }
	}

    if (DebugFile.trace) {
      DebugFile.decIdent();
      if (null==aSubscribers)
        DebugFile.writeln("End NewsMessage.subscribers() : null");
      else
        DebugFile.writeln("End NewsMessage.subscribers() : String["+String.valueOf(aSubscribers.length)+"]");
    }

	return aSubscribers;	
  } // subscribers

  // ----------------------------------------------------------
  
  /**
   * Count number of votes of a message
   * @param oConn Database Connection
   * @return Count of rows from k_newsmsg_vote table having gu_msg as current message
   * @throws SQLException
   * @since 4.0
   */
  public int countVotes(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM "+DB.k_newsmsg_vote + " WHERE "+DB.gu_msg + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getString(DB.gu_msg));
    ResultSet oRSet = oStmt.executeQuery();
    oRSet.next();
    int nVotes = oRSet.getInt(1);
    oRSet.close();
    oStmt.close();
    return nVotes;
  } // countVotes

  // ----------------------------------------------------------

  /**
   * Get tags for this message
   * @return HashMap of NewsMessageTag objects
   * @since 5.0
   */
  public HashMap<String,NewsMessageTag> tags() {
  	return oTagsSet;
  }

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete NewsMessage.</p>
   * Files attached to NewsMessage (stored as Products) are delete prior to
   * the NewsMessage itself. Then k_sp_del_newsmsg stored procedure is called.
   * @param oConn Database Connection
   * @param sNewsMsgGUID GUID of NewsMessage to be deleted
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sNewsMsgGUID) throws SQLException {
    NewsMessage oMsg = new NewsMessage();

    if (oMsg.load(oConn, new Object[]{sNewsMsgGUID}))
      return oMsg.delete(oConn);
    else
      return false;
  } // delete

  // **********************************************************
  // Constantes Publicas

   public static final short STATUS_VALIDATED = 0;
   public static final short STATUS_PENDING = 1;
   public static final short STATUS_DISCARDED = 2;
   public static final short STATUS_EXPIRED = 3;

   public static final short ClassId = 31;

}
