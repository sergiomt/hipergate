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

import java.io.IOException;
import java.io.Reader;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;

import java.util.Date;

import org.jibx.runtime.IBindingFactory;
import org.jibx.runtime.IUnmarshallingContext;
import org.jibx.runtime.BindingDirectory;
import org.jibx.runtime.JiBXException;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.hipergate.Category;
import com.knowgate.hipergate.Product;

/**
 * <p>NewsGroup</p>
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public class NewsGroup extends Category {

  private NewsGroupJournal oJournal;
  
  /**
   * Create empty newsgroup
   */
  public NewsGroup() {
    super(DB.k_newsgroups,"NewsGroup");
    oJournal = null;
  }

  // ----------------------------------------------------------

  /**
   * Create NewsGroup and set its Category GUID
   * @param sIdNewsGroup GUID of NewsGroup/Category
   * @throws SQLException
   */
  public NewsGroup(String sIdNewsGroup) throws SQLException {
    super(DB.k_newsgroups,"NewsGroup");

    put(DB.gu_category, sIdNewsGroup);
    put(DB.gu_newsgrp , sIdNewsGroup);
    oJournal = null;
  }

  // ----------------------------------------------------------

  /**
   * <p>Create newsGroup and load properties from Database</p>
   * Both field sets from k_categories and k_newsgroups are loaded into
   * internal properties collection upon load.
   * @param oConn Database Conenction
   * @param sIdNewsGroup GUID of newsGroup to be loaded
   * @throws SQLException
   */
  public NewsGroup(JDCConnection oConn, String sIdNewsGroup)
  	throws SQLException {
    super(DB.k_newsgroups,"NewsGroup");

    load (oConn, new Object[]{sIdNewsGroup});
  }

  // ----------------------------------------------------------

  /**
   * <p>Count messages for this NewsGroup</p>
   * @param oConn Database connection
   * @return Message Count
   * @throws SQLException If NewsGroup does not exist
   */
  public int countMessages(JDCConnection oConn) throws SQLException {
    int iRetVal;


    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsGroup.countMessages([Connection])");
      DebugFile.incIdent();

    }

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT COUNT(*) FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "='" + getStringNull(DB.gu_newsgrp, "null") + "' AND " + DB.id_class + "=" + String.valueOf(NewsMessage.ClassId) + ")");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(*) FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "=? AND " + DB.id_class + "=" + String.valueOf(NewsMessage.ClassId));

    oStmt.setString(1, getString(DB.gu_newsgrp));

    ResultSet oRSet = oStmt.executeQuery();

    if (oRSet.next()) {
      iRetVal = Integer.parseInt(oRSet.getObject(1).toString());
      oRSet.close();
      oStmt.close();
    }
    else {
      oRSet.close();
      oStmt.close();
      throw new SQLException("NewsGroup " + getString(DB.gu_newsgrp) + " not found", "42000");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsGroup.countMessages() : " + String.valueOf(iRetVal));
    }

    return iRetVal;
  } // countMessages

  // ----------------------------------------------------------

  /**
   * <p>Count messages for this NewsGroup in a given status</p>
   * @param oConn Database connection
   * @param iMsgStatus One of { NewsMessage.STATUS_VALIDATED, NewsMessage.STATUS_PENDING, NewsMessage.STATUS_DISCARDED, NewsMessage.STATUS_EXPIRED }
   * @return Message Count
   * @throws SQLException If NewsGroup does not exist
   */
  public int countMessages(JDCConnection oConn, short iMsgStatus) throws SQLException {
    int iRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsGroup.countMessages([Connection], " + String.valueOf(iMsgStatus) + ")");
      DebugFile.incIdent();
    }

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT COUNT(x." + DB.gu_object + ") FROM " + DB.k_x_cat_objs + " x, " + DB.k_newsmsgs + " m WHERE m." + DB.gu_msg + "=" + "x." + DB.gu_object + " AND m." + DB.id_status + "=" + String.valueOf(iMsgStatus) + " AND x." + DB.gu_category + "='" + getStringNull(DB.gu_newsgrp, "null") + "' AND x." + DB.id_class + "=" + String.valueOf(NewsMessage.ClassId) + ")");

    PreparedStatement oStmt = oConn.prepareStatement("SELECT COUNT(x." + DB.gu_object + ") FROM " + DB.k_x_cat_objs + " x, " + DB.k_newsmsgs + " m WHERE m." + DB.gu_msg + "=" + "x." + DB.gu_object + " AND m." + DB.id_status + "=?" + " AND x." + DB.gu_category + "=? AND x." + DB.id_class + "=" + String.valueOf(NewsMessage.ClassId));

    oStmt.setShort (1, iMsgStatus);
    oStmt.setString(2, getString(DB.gu_newsgrp));

    ResultSet oRSet = oStmt.executeQuery();

    if (oRSet.next()) {
      iRetVal = Integer.parseInt(oRSet.getObject(1).toString());
      oRSet.close();
      oStmt.close();
    }
    else {
      oRSet.close();
      oStmt.close();
      throw new SQLException("NewsGroup " + getString(DB.gu_newsgrp) + " not found", "42000");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsGroup.countMessages() : " + String.valueOf(iRetVal));
    }

    return iRetVal;
  } // countMessages

  // ----------------------------------------------------------

  /**
   * <p>Load NewsGroup from database</p>
   * Both field sets from k_categories and k_newsgroups are loaded into
   * internal properties collection upon load.
   * @param oConn Database Conenction
   * @param PKVals A single element array containing the GUID of NewsGroup to be
   * loaded. For example: oNewsGrpObj.load(oConnection, new object[]{"123456789012345678901234567890AB"});
   * @return <b>true</b> if NewsGroup was successfully loaded, <b>false</b> if
   * Newsgroup GUID was not found at k_newsgropus o k_categories tables.
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    boolean bRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    int iColCount;
    String sColName;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsGroup.load([Connection], ...)");
      DebugFile.incIdent();
      DebugFile.writeln("gu_newsgrp=" + (String) PKVals[0]);
    }

	getTable(oConn);
	
    clear();

    sSQL = "SELECT * FROM " + DB.k_categories + " WHERE " + DB.gu_category + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setString(1, (String) PKVals[0]);

    oRSet = oStmt.executeQuery();

    bRetVal = oRSet.next();

    if (bRetVal) {
      oMDat = oRSet.getMetaData();
      iColCount = oMDat.getColumnCount();

      for (int c=1; c<=iColCount; c++) {
        sColName = oMDat.getColumnName(c).toLowerCase();
        if (!sColName.equalsIgnoreCase(DB.dt_created));
          put(sColName, oRSet.getObject(c));
      } // next
      oMDat = null;
    } // fi (bRetVal)

    oRSet.close();
    oStmt.close();

    if (bRetVal) {
      sSQL = "SELECT * FROM " + DB.k_newsgroups + " WHERE " + DB.gu_newsgrp + "=?";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
      oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, (String) PKVals[0]);
      oRSet = oStmt.executeQuery();
      bRetVal = oRSet.next();
      if (bRetVal) {
        oMDat = oRSet.getMetaData();
        iColCount = oMDat.getColumnCount();

        for (int c=1; c<=iColCount; c++) {
          sColName = oMDat.getColumnName(c).toLowerCase();
          if (sColName.equalsIgnoreCase(DB.tx_journal)) {
    		try {
			  Reader oRdr = oRSet.getCharacterStream(c);
              if (!oRSet.wasNull()) {
    		    IBindingFactory bfact = BindingDirectory.getFactory(NewsGroupJournal.class);
    		    IUnmarshallingContext uctx = bfact.createUnmarshallingContext();
                oJournal = (NewsGroupJournal) uctx.unmarshalDocument (oRdr);
    		    oRdr.close();
                put(DB.tx_journal, oRSet.getString(c));
    		  } else {
              oJournal = null;
              } // fi
    		} catch (JiBXException xcpt) {
    		  throw new SQLException(xcpt.getMessage(), "JIBX", xcpt);
    		} catch (IOException ioe) {
    		  throw new SQLException(ioe.getMessage(), "IO", ioe);
    		}
          }
          else if (!sColName.equalsIgnoreCase(DB.dt_created)) {
            put(sColName, oRSet.getObject(c));
          }
        } // next
        oMDat = null;
      }
      oRSet.close();
      oStmt.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsGroup.load() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // load

  // ----------------------------------------------------------

  /**
   * <p>Load NewsGroup from database</p>
   * Both field sets from k_categories and k_newsgroups are loaded into
   * internal properties collection upon load.
   * @param oConn Database Conenction
   * @param String GUID of NewsGroup to be loaded.
   * @return <b>true</b> if NewsGroup was successfully loaded, <b>false</b> if
   * Newsgroup GUID was not found at k_newsgropus o k_categories tables.
   * @throws SQLException
   */

  public boolean load(JDCConnection oConn, String sGuNewsGroup) throws SQLException {
    return load(oConn, new Object[]{sGuNewsGroup});
  }

  // ----------------------------------------------------------

  /**
   * <p>Get ACLUsers subscribed to this NewsGroup</p>
   * @param oConn JDBC Database Connection
   * @return A DBSubset with the following columns:<br>
   * <table>
   * <tr><td><b>gu_user</b></td><td><b>tx_email</b></td><td><b>id_msg_type</b></td><td><b>tp_subscrip</b></td></tr>
   * <tr><td>ACLUser GUID</td><td><b>ACLUser main e-mail</b></td><td>Message Format {TXT | HTM}</td><td>Message Grouping {GROUP_NONE | GROUP_DIGEST}</td></tr>
   * </table>
   * @throws SQLException
   */
  public DBSubset subscribers (JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsGroup.subscribers ([Connection])");
      DebugFile.incIdent();
      DebugFile.writeln("gu_newsgrp=" + getStringNull(DB.gu_newsgrp, "null"));
    }

    DBSubset oSubs = new DBSubset (DB.k_newsgroup_subscriptions,
                                   DB.gu_user + "," + DB.tx_email + "," + DB.id_msg_type + "," + DB.tp_subscrip,
                                   DB.gu_newsgrp + "=? AND " + DB.id_status + "=" + String.valueOf(Subscription.ACTIVE), 100);

    oSubs.load(oConn, new Object[] {getString(DB.gu_newsgrp)});

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsGroup.subscribers() : " + String.valueOf(oSubs.getRowCount()));
    }

    return oSubs;
  } // subscribers

  // ----------------------------------------------------------

  /**
   * <p>Get whether or not a user is subcribed this news group</p>
   * @param oConn JDBC Database Connection
   * @param sUserId User GUID
   * @return <b>true</b> if user is subscribed to this news group and he is active (k_newsgroup_subscriptions.id_status=1),
   * <b>false</b> if user is not subscribed or if he is subscribed but unactive (k_newsgroup_subscriptions.id_status=0)
   * @throws SQLException
   */
  public boolean isSubscriber (JDCConnection oConn, String sUserId)
    throws SQLException {

    PreparedStatement oStmt = oConn.prepareStatement("SELECT " + DB.tx_email + " FROM " + DB.k_newsgroup_subscriptions + " WHERE " + DB.gu_newsgrp + "=? AND " + DB.gu_user + "=? AND " + DB.id_status + "=" + String.valueOf(Subscription.ACTIVE), ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oStmt.setString(1, getString(DB.gu_newsgrp));
    oStmt.setString(2, sUserId);

    ResultSet oRSet = oStmt.executeQuery();

    boolean bSubscriber = oRSet.next();

    oRSet.close();
    oStmt.close();

    return bSubscriber;
  } //  isSubscriber

  // ----------------------------------------------------------

  public NewsGroupJournal getJournal() {
  	return oJournal;
  }
  // ----------------------------------------------------------

  /**
   * <p>Delete this NewsGroup and all its messages</p>
   * @param oConn JDBC Database Connection
   * @return
   * @throws SQLException
   */

  public boolean delete(JDCConnection oConn) throws SQLException {
    return NewsGroup.delete(oConn,getString(DB.gu_newsgrp));
  }

  /**
   * <p>Get messages</p>
   * @param oConn Database Connection
   * @param nMaxMsgs Maximum number of messages to get
   * @param sOrderBy Attribute to sort messages. By default it is dt_published which corresponds to publishing date. Can be also nu_votes to sort messages by number of votes or nm_author to sort by author.
   * @return DBSubset containing the following columns: gu_msg,nm_author,gu_writer,dt_published,dt_start,id_language,id_status,id_msg_type,nu_thread_msgs,gu_thread_msg,nu_votes,tx_email,tx_subject,dt_expire,dt_validated,gu_validator,gu_product,tx_msg
   * @throws SQLException
   * @throws IllegalArgumentException If nMaxMsgs<=0
   * @throws IllegalStateException If this Newsgroup message has not been previously loaded
   * @since 4.0
   */
  public DBSubset getTopLevelMessages(JDCConnection oConn, int nMaxMsgs, String sOrderBy)
    throws SQLException,IllegalArgumentException,IllegalStateException {
	
	if (nMaxMsgs<=0) throw new IllegalArgumentException("NewsGroup.getTopLevelMessages() The number of messages to get must be greater than zero");
	if (isNull(DB.gu_category)) throw new IllegalStateException("NewsGroup.getTopLevelMessages() Cannot get most voted messages for a NewsGroup than as not been previously loaded");
	if (null==sOrderBy) sOrderBy = DB.dt_published;
    if (sOrderBy.length()==0) sOrderBy = DB.dt_published;

	DBSubset oDbss = new DBSubset(DB.k_newsmsgs + " m," + DB.k_x_cat_objs +" g",
			"m."+DB.gu_msg+",m."+DB.nm_author+",m."+DB.gu_writer+",m."+DB.dt_published+",m."+DB.dt_start+",m."+DB.id_language+",m."+DB.id_status+",m."+DB.id_msg_type+",m."+DB.nu_thread_msgs+",m."+DB.gu_thread_msg+",m."+DB.nu_votes+",m."+DB.tx_email+",m."+DB.tx_subject+",m."+DB.dt_expire+",m."+DB.dt_validated+",m."+DB.gu_validator+",m."+DB.gu_product+",m."+DB.tx_msg,
			"g."+DB.gu_category+"=? AND g."+DB.id_class+"="+String.valueOf(NewsMessage.ClassId)+" AND g."+DB.gu_object+"=m."+DB.gu_msg+" AND "+
			"m."+DB.gu_parent_msg + " IS NULL ORDER BY "+sOrderBy+" DESC",nMaxMsgs);

	oDbss.setMaxRows(nMaxMsgs);

	oDbss.load(oConn, new Object[]{getString(DB.gu_category)});
	
	return oDbss;
  } // getTopLevelMessages

  public String toXML(JDCConnection oConn, String sIdent, String sDelim) throws SQLException {
  	String sXml = toXMLWithLabels(oConn, sIdent, sDelim);
  	String sEndTag = "</"+sAuditCls+">";
  	String sBeforeEndTag = sXml.substring(0, sXml.length()-sEndTag.length());
	String sNewsGrpTags = Forums.XMLListTags(oConn, getString(DB.gu_newsgrp));
	return sBeforeEndTag+"\n"+sNewsGrpTags+"\n"+sEndTag;
  }

  public String toXML(JDCConnection oConn, String sIdent) throws SQLException {
  	return toXML(oConn, sIdent, "\n");
  }

  public String toXML(JDCConnection oConn) throws SQLException {
  	return toXML(oConn, "", "\n");
  }

  // **********************************************************
  // Static Methods

  /**
   * <p>Store Newsgroup</p>
   * @param oConn Database Connection
   * @param iDomain Identifier of Domain to with the NewsGroup will belong.
   * @param sWorkArea GUID of WorkArea to with the NewsGroup will belong.
   * @param sCategoryId Category GUID (newsgroups are subregisters of categories)
   * @param sParentId GUID of Parent Group (groups, as categories, are hierarchical)
   * @param sCategoryName Category name (k_categories.nm_category)
   * @param iIsActive 1 if group is activem, 0 if it is inactive.
   * @param iDocStatus Initial Document Status. One of { Newsgroup.FREE, Newsgroup.MODERATED }
   * @param sOwner GUID of User owner of this NewsGroup
   * @param sIcon1 Closed Folder Icon
   * @param sIcon2 Opened Folder Icon
   * @return GUID of newly created NewsGroup
   * @throws SQLException
   */
  public static String store(JDCConnection oConn, int iDomain, String sWorkArea, String sCategoryId, String sParentId, String sCategoryName, short iIsActive, int iDocStatus, String sOwner, String sIcon1, String sIcon2 ) throws SQLException {
    String sCatId = Category.store(oConn, sCategoryId, sParentId, sCategoryName, iIsActive, iDocStatus, sOwner, sIcon1, sIcon2);

    NewsGroup oGrp = new NewsGroup(sCatId);
    oGrp.put(DB.id_domain, iDomain);
    oGrp.put(DB.gu_workarea, sWorkArea);
    oGrp.put(DB.bo_binaries, (short)0);
    oGrp.put(DB.dt_last_update, new Timestamp(new Date().getTime()));

    oGrp.store(oConn);

    return sCatId;
  } // store

  /**
   * <p>Store Newsgroup</p>
   * @param oConn Database Connection
   * @param iDomain Identifier of Domain to with the NewsGroup will belong.
   * @param sWorkArea GUID of WorkArea to with the NewsGroup will belong.
   * @param sCategoryId Category GUID (newsgroups are subregisters of categories)
   * @param sParentId GUID of Parent Group (groups, as categories, are hierarchical)
   * @param sCategoryName Category name (k_categories.nm_category)
   * @param iIsActive 1 if group is activem, 0 if it is inactive.
   * @param iDocStatus Initial Document Status. One of { Newsgroup.FREE, Newsgroup.MODERATED }
   * @param sOwner GUID of User owner of this NewsGroup
   * @param sIcon1 Closed Folder Icon
   * @param sIcon2 Opened Folder Icon
   * @param boBinaries <b>true if group allows binay attachments <b>false</b> otherwise
   * @param sDesc News Group Description (up to 254 characters)
   * @param sTxJournalXml Journal XML definition file (up to 4000 characters)
   * @return GUID of newly created NewsGroup
   * @throws SQLException
   * @since 5.0
   */
  public static String store(JDCConnection oConn, int iDomain, String sWorkArea, String sCategoryId, String sParentId, String sCategoryName, short iIsActive, int iDocStatus,
  							 String sOwner, String sIcon1, String sIcon2, boolean boBinaries, String sDesc, String sTxJournalXml) throws SQLException {
    String sCatId = Category.store(oConn, sCategoryId, sParentId, sCategoryName, iIsActive, iDocStatus, sOwner, sIcon1, sIcon2);

    NewsGroup oGrp = new NewsGroup(sCatId);
    oGrp.put(DB.id_domain, iDomain);
    oGrp.put(DB.gu_workarea, sWorkArea);
    oGrp.put(DB.bo_binaries, (short) (boBinaries ? 1 : 0));
    oGrp.put(DB.dt_last_update, new Timestamp(new Date().getTime()));
    if (null!=sDesc) if (sDesc.length()>0) oGrp.put(DB.de_newsgrp, sDesc);
    if (null!=sTxJournalXml) if (sTxJournalXml.length()>0) oGrp.put(DB.tx_journal, sTxJournalXml);
    
    oGrp.store(oConn);

    return sCatId;
  } // store

  /**
   * <p>Delete NewsGroup and all its messages.</p>
   * Delete all files attached to messages contained in group and then call
   * k_sp_del_newsgroup stored procedure.<br>
   * @param oConn Database Connection
   * @param sNewsGroupGUID GUID of NewsGroup to be deleted.
   * @throws SQLException
   * @see com.knowgate.hipergate.Product#delete(JDCConnection)
   */
  public static boolean delete(JDCConnection oConn, String sNewsGroupGUID) throws SQLException {
    Statement oStmt;
    ResultSet oRSet;
    String sProductId;
    Product oProd;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsGroup.delete([Connection], " + sNewsGroupGUID + ")");
      DebugFile.incIdent();
    }

    // Borrar los archivos adjuntos
    sSQL = "SELECT " + DB.gu_product + "," + DB.gu_msg + " FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_product + " IS NOT NULL AND " + DB.gu_msg + " IN (SELECT " + DB.gu_object + " FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_category + "='" + sNewsGroupGUID + "')";
    oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE);
    if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(" + sSQL + ")");
    oRSet = oStmt.executeQuery(sSQL);
    while (oRSet.next()) {
      sProductId = oRSet.getString(1);

      if (DebugFile.trace) DebugFile.writeln("ResultSet.updateString gu_product = " + sProductId + " to NULL");

      oRSet.updateString(1, null);

      if (DebugFile.trace) DebugFile.writeln("ResultSet.updateRow();");

      oRSet.updateRow();

      if (DebugFile.trace) DebugFile.writeln("new Product([Connection], " + sProductId + ")");

      oProd = new Product(oConn, sProductId);

      oProd.delete(oConn);
    } // wend
    oRSet.close();
    oStmt.close();

    // Borrar los mensajes y la categoría subyacente
    CallableStatement oCall;

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_newsgroup('" + sNewsGroupGUID + "') })");

    oCall = oConn.prepareCall("{ call k_sp_del_newsgroup('" + sNewsGroupGUID + "') }");

    if (DebugFile.trace) DebugFile.writeln("CallableStatement.execute({ call k_sp_del_newsgroup('" + sNewsGroupGUID + "') })");
    oCall.execute();
    oCall.close();

    return true;
  } // delete
  
  // **********************************************************
  // Constantes Publicas

   public static final short ClassId = 30;

   public static final short FREE = 0;
   public static final short MODERATED = 1;

} // NewsGroup
