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

package com.knowgate.projtrack;

import com.knowgate.debug.DebugFile;

import com.knowgate.dataobjs.DB;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.lucene.Indexer;
import com.knowgate.lucene.BugIndexer;

import com.knowgate.misc.Gadgets;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Properties;

import java.io.FileNotFoundException;
import java.io.IOException;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

/**
 * <p>Bug or Project Incident</p>
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public class Bug extends DBPersist {

  /**
   * Create empty bug
   */
  public Bug() {
    super(DB.k_bugs, "Bug");
  }

  // ----------------------------------------------------------

  /**
   * Load Bug from database.
   * @param oConn Database Connection
   * @param sIdBug GUID of Bug to be loaded.
   * @throws SQLException
   */
  public Bug(JDCConnection oConn, String sIdBug) throws SQLException {
    super(DB.k_bugs,"Bug");

    Object aBug[] = { sIdBug };

    load (oConn,aBug);
  }

  // ----------------------------------------------------------

  /**
   * Load Bug from database.
   * @param oConn Database Connection
   * @param iPgBug int Numeric identifier of bug to be loaded
   * @param sWorkArea String GUID of WorkArea to which Bug belongs
   * @throws SQLException
   * @since 3.0
   */
  public Bug(JDCConnection oConn, int iPgBug, String sWorkArea) throws SQLException {
    super(DB.k_bugs,"Bug");
    Object aBug[] = { Bug.getIdFromPg(oConn, iPgBug, sWorkArea) };
    if (null!=aBug[0]) load (oConn,aBug);
  }

  // ----------------------------------------------------------

  /**
   * <p>Delete Bug</p>
   * Calls k_sp_del_bug stored procedure.
   * @param oConn Database Connection
   * @return boolean
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return Bug.delete(oConn, getString(DB.gu_bug));
  }

  // ----------------------------------------------------------

  /**
   * <p>Delete Bug from database and from lucene index</p>
   * @param oConn Database Connection
   * @param oCnf Properties containing luceneindex path
   * @return boolean
   * @throws SQLException
   * @throws IOException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @since 3.0
   */
  public boolean delete(JDCConnection oConn, Properties oCnf)
    throws SQLException, IOException, NoSuchFieldException, IllegalAccessException {
    return Bug.delete(oConn, getString(DB.gu_bug), oCnf);
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Bug and write its change log</p>
   * This method automatically assigns a new bug number (pg_bug) if one is not
   * supplied by calling seq_k_bugs sequence
   * It also updates last modified date (dt_modified) and sinve v2.2 writes changes
   * to k_bugs_changelog if that table exists
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    int iPgBug;
    Timestamp dtNow;
    Object oOldValue;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Bug.store()");
      DebugFile.incIdent();
    }

    dtNow = new Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_bug)) {
      put(DB.gu_bug, Gadgets.generateUUID());
      if (!AllVals.containsKey(DB.pg_bug)) {
        iPgBug = Bug.getPgFromId(oConn, getString(DB.gu_bug));
        if (-1==iPgBug) iPgBug = DBBind.nextVal(oConn, "seq_" + DB.k_bugs);
        put(DB.pg_bug, iPgBug);
      }
    } else {
      if (!AllVals.containsKey(DB.pg_bug)) {
        iPgBug = Bug.getPgFromId(oConn, getString(DB.gu_bug));
        if (-1==iPgBug) iPgBug = DBBind.nextVal(oConn, "seq_" + DB.k_bugs);
        put(DB.pg_bug, iPgBug);
      }
      replace(DB.dt_modified, dtNow);
      Bug oOld = new Bug ();
      if (oOld.load(oConn, new Object[]{get(DB.gu_bug)})) {
        if (DBBind.exists(oConn, DB.k_bugs_changelog,"U")) {
          HashMap oLog = changelog(oOld);
          sSQL = "INSERT INTO "+DB.k_bugs_changelog+" ("+DB.gu_bug+","+DB.pg_bug+","+DB.nm_column+","+DB.gu_writer+","+DB.tx_oldvalue+") VALUES (?,?,?,?,?)";
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.prepareStatement("+sSQL+")");
          PreparedStatement oWriteLog = oConn.prepareStatement(sSQL);
          oWriteLog.setString(1, getString(DB.gu_bug));
          oWriteLog.setInt   (2, getInt(DB.pg_bug));
          Iterator oIter = oLog.keySet().iterator();
          while (oIter.hasNext()) {
            String sColumnName = (String) oIter.next();
            if (!sColumnName.equalsIgnoreCase(DB.dt_modified)) {
              oWriteLog.setString(3, sColumnName);
              oWriteLog.setString(4, getStringNull(DB.gu_writer,null));
              oOldValue = oLog.get(sColumnName);
              if (null==oOldValue)
                oWriteLog.setNull(5, Types.VARCHAR);
              else
                oWriteLog.setString(5, Gadgets.left(oOldValue.toString(),255));
              if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate("+sColumnName+")");
              oWriteLog.executeUpdate();
            }
          } // wend
          if (DebugFile.trace) DebugFile.writeln("PreparedStatement.close()");
          oWriteLog.close();
        } // fi (exists(k_bugs_changelog))
      } // fi (load(gu_bug))
    } // fi (AllVals.containsKey(gu_bug))

    boolean bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Bug.store()");
    }
    return bRetVal;
  } // store

  // ---------------------------------------------------------------------------

  /**
   * Store bug and add it to a Lucene index
   * @param oConn JDCConnection
   * @param oCnf Properties containing luceneindex path
   * @return boolean
   * @throws SQLException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @since 3.0
   */
  public boolean storeAndIndex(JDCConnection oConn, Properties oCnf)
    throws SQLException, IOException,ClassNotFoundException,NoSuchFieldException,
           IllegalAccessException,InstantiationException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Bug.storeAndIndex([JDCConnection], [Properties])");
      DebugFile.incIdent();
    }
    boolean bStore = store(oConn);
    if (bStore) {
      String sLuceneIndex = oCnf.getProperty("luceneindex","");
      if (sLuceneIndex.length()>0) {
        String sWrkA = getWorkArea(oConn, getString(DB.gu_bug));
        BugIndexer.addBug(oCnf, oConn, sWrkA, this);
      }
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Bug.storeAndIndex()");
    }
    return bStore;
  } // storeAndIndex

  /**
   * Re-index bug
   * @param oConn JDCConnection
   * @param oCnf Properties
   * @throws SQLException
   * @throws IOException
   * @throws ClassNotFoundException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @throws InstantiationException
   * @since 3.0
   */
  public void reIndex(JDCConnection oConn, Properties oCnf)
    throws SQLException, IOException,ClassNotFoundException,NoSuchFieldException,
           IllegalAccessException,InstantiationException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Bug.reIndex([JDCConnection], [Properties])");
      DebugFile.incIdent();
    }

    String sLuceneIndex = oCnf.getProperty("luceneindex","");
    if (sLuceneIndex.length()>0) {
      String sWrkA = getWorkArea(oConn, getString(DB.gu_bug));
      if (null!=sWrkA) {
        Indexer.delete("k_bugs", sWrkA, oCnf, getString(DB.gu_bug));
        BugIndexer.addBug(oCnf, oConn, sWrkA, this);
      } // fi
    } // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Bug.reIndex()");
    }
  } // reIndex

  // ---------------------------------------------------------------------------

  /**
   * Insert attachment into k_bugs_attach table
   * @param oConn JDCConnection
   * @param sFilePath String Full path to local file
   * @throws SQLException
   * @throws FileNotFoundException
   * @throws IOException
   * @throws NullPointerException
   * @since 3.0
   */
  public void attachFile(JDCConnection oConn, String sFilePath)
    throws SQLException, FileNotFoundException, IOException, NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Bug.attachFile([JDCConnection],"+sFilePath+")");
      DebugFile.incIdent();
    }

    BugAttachment.createFromFile(oConn, getString(DB.gu_bug), sFilePath);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Bug.attachFile()");
    }
  } // attachFile

  // ---------------------------------------------------------------------------

  /**
   * Remove attachment from k_bugs_attach table
   * @param oConn JDCConnection
   * @param sFileName String
   * @throws SQLException
   */
  public void removeAttachment(JDCConnection oConn, String sFileName)
    throws SQLException {
    BugAttachment.delete(oConn, getString(DB.gu_bug), sFileName);
  } // removeAttachment

  // ---------------------------------------------------------------------------

  /**
   * Get array of attachments
   * @param oConn JDCConnection
   * @return BugAttachment[] Array of BugAttachment objects or <b>null</b> if this Bug has no attachments
   * @throws SQLException
   * @since 3.0
   */
  public BugAttachment[] attachments(JDCConnection oConn)
    throws SQLException {
    DBSubset oAttachs = new DBSubset(DB.k_bugs_attach, DB.tx_file+","+DB.len_file, DB.gu_bug+"=?", 10);
    int iAttachs = oAttachs.load(oConn, new Object[]{getString(DB.gu_bug)});
    if (0==iAttachs)
      return null;
    else {
      BugAttachment[] aAttachs = new BugAttachment[iAttachs];
      for (int a=0; a<iAttachs; a++)
        aAttachs[a] = new BugAttachment(getString(DB.gu_bug),oAttachs.getString(1,a), oAttachs.getInt(2,a));
      return aAttachs;
    }
  } // attachments

  // ---------------------------------------------------------------------------

  /**
   * Get change log for all the values of a bug
   * @param oConn JDCConnection
   * @return BugChangeLog[]
   * @throws SQLException
   * @since 3.0
   */
  public BugChangeLog[] changeLog(JDCConnection oConn)
    throws SQLException {
    BugChangeLog[] aBcl;
    DBSubset oLog = new DBSubset(DB.k_bugs_changelog,
                                 DB.gu_bug+","+DB.pg_bug+","+DB.nm_column+","+DB.dt_modified+","+DB.gu_writer+","+DB.tx_oldvalue,
                                 DB.gu_bug+"=? ORDER BY 4", 10);
    int iLog = oLog.load(oConn, new Object[]{getString(DB.gu_bug)});
    if (0==iLog) {
      aBcl = null;
    } else {
      aBcl = new BugChangeLog[iLog];
      for (int l=0; l<iLog; l++) {
        aBcl[l] = new BugChangeLog();
        aBcl[l].putAll(oLog.getRowAsMap(l));
        aBcl[l].setWriter(oConn, oLog.getStringNull(4,l,null));
      } // next
    } // fi
    return aBcl;
  } // changeLog

  // ---------------------------------------------------------------------------

  /**
   * Get change log for a column of a bug
   * @param oConn JDCConnection
   * @param sColumnName String
   * @return BugChangeLog[]
   * @throws SQLException
   * @since 3.0
   */
  public BugChangeLog[] changeLog(JDCConnection oConn, String sColumnName)
    throws SQLException {
    BugChangeLog[] aBcl;
    DBSubset oLog = new DBSubset(DB.k_bugs_changelog,
                                 DB.gu_bug+","+DB.pg_bug+","+DB.nm_column+","+DB.dt_modified+","+DB.gu_writer+","+DB.tx_oldvalue,
                                 DB.gu_bug+"=? AND "+DB.nm_column+"=? ORDER BY 4", 10);
    int iLog = oLog.load(oConn, new Object[]{getString(DB.gu_bug), sColumnName});
    if (0==iLog) {
      aBcl = null;
    } else {
      aBcl = new BugChangeLog[iLog];
      for (int l=0; l<iLog; l++) {
        aBcl[l] = new BugChangeLog();
        aBcl[l].putAll(oLog.getRowAsMap(l));
        aBcl[l].setWriter(oConn, oLog.getStringNull(4,l,null));
      } // next
    } // fi
    return aBcl;
  } // changeLog

  // ---------------------------------------------------------------------------

  /**
   * Get track of conversations for a bug
   * @param oConn JDCConnection
   * @return BugTrack[] or <b>null</b> if there is no track record for this bug
   * @throws SQLException
   * @since 3.0
   */
  public BugTrack[] getTrack(JDCConnection oConn)
    throws SQLException {
    BugTrack[] aTrk;
    DBSubset oTrk = new DBSubset(DB.k_bugs_track,
                                 DB.gu_bug+","+DB.pg_bug_track+","+DB.dt_created+","+DB.nm_reporter+","+DB.tx_rep_mail+","+DB.gu_writer+","+DB.tx_bug_track,
                                 DB.gu_bug+"=? ORDER BY 2 DESC", 20);
    int iTrk = oTrk.load(oConn, new Object[]{getString(DB.gu_bug)});
    if (0==iTrk) {
      aTrk = null;
    } else {
      aTrk = new BugTrack[iTrk];
      for (int l=0; l<iTrk; l++) {
        aTrk[l] = new BugTrack();
        aTrk[l].putAll(oTrk.getRowAsMap(l));
      } // next
    } // fi
    return aTrk;
  } // getTrack

  // ---------------------------------------------------------------------------


  // ***************************************************************************
  // Static Methods

  /**
   * Get WorkArea to which bug belongs
   * @param oConn JDCConnection
   * @param sGuid String Bug GUID
   * @return String WorkArea GUID
   */
  private static String getWorkArea(JDCConnection oConn, String sGuid)
    throws SQLException {
    String sWrkA;
    if (DebugFile.trace) {
      DebugFile.writeln("JDCConnection.prepareStatement(SELECT p."+DB.gu_owner+" FROM "+DB.k_projects+" p,"+DB.k_bugs+" b WHERE p."+DB.gu_project+"=b."+DB.gu_project+" AND b."+DB.gu_bug+"='"+sGuid+"'");
    }
    PreparedStatement oStmt = oConn.prepareStatement("SELECT p."+DB.gu_owner+" FROM "+DB.k_projects+" p,"+DB.k_bugs+" b WHERE p."+DB.gu_project+"=b."+DB.gu_project+" AND b."+DB.gu_bug+"=?",
                                                     ResultSet.TYPE_FORWARD_ONLY,ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sGuid);
    ResultSet oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sWrkA = oRSet.getString(1);
    else
      sWrkA = null;
    oRSet.close();
    oStmt.close();
    return sWrkA;
  } // getWorkArea

  /**
   * <p>Delete Bug.</p>
   * Typically, bugs are never deleted, but their status is changed to some
   * definitive solved or archived condition.<br>
   * Calls k_sp_del_bug stored procedure.
   * @param oConn Database Connection
   * @param sBugGUID GUID of Bug to be deleted.
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sBugGUID) throws SQLException {
    boolean bRetVal;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(SELECT k_sp_del_bug ('" + sBugGUID + "'))");
      Statement oStmt = oConn.createStatement();
      ResultSet oRSet = oStmt.executeQuery("SELECT k_sp_del_bug ('" + sBugGUID + "')");
      oRSet.close();
      oStmt.close();
      bRetVal = true;
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_bug ('" + sBugGUID + "')})");
      CallableStatement oCall = oConn.prepareCall("{call k_sp_del_bug ('" + sBugGUID + "')}");
      bRetVal = oCall.execute();
      oCall.close();
    }

    return bRetVal;
  } // delete()

  /**
   * Delete bug from database and from Lucene index
   * @param oConn JDCConnection
   * @param sBugGUID String Bug GUID
   * @param oCnf Properties containing luceneindex path
   * @return boolean
   * @throws SQLException
   * @throws IOException
   * @throws NoSuchFieldException
   * @throws IllegalAccessException
   * @since 3.0
   */
  public static boolean delete(JDCConnection oConn, String sBugGUID, Properties oCnf)
      throws SQLException, IOException, NoSuchFieldException, IllegalAccessException {
    String sLuceneIndex = oCnf.getProperty("luceneindex","");
    if (sLuceneIndex.length()>0) {
      String sWrkA = getWorkArea(oConn, sBugGUID);
      if (null!=sWrkA) Indexer.delete("k_bugs", sWrkA, oCnf, sBugGUID);
    }
    return delete(oConn, sBugGUID);
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Get Bug Numeric Identifier from Global Unique Identifier.</p>
   * Each Bug is assigned a GUID. But, as GUID are 32 characters hexadecimals
   * string very difficult to remember, each bug is also automatically assigned
   * to an integer identifier. The bug numeric identifier is an alternative
   * primary key.
   * @param oConn Database Connection
   * @param sBugId Bug GUID
   * @return Bug Integer Identifier
   * @throws SQLException
   */
  public static int getPgFromId(JDCConnection oConn, String sBugId) throws SQLException {
    int iRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

    oStmt = oConn.prepareStatement("SELECT " + DB.pg_bug + " FROM " + DB.k_bugs + " WHERE " + DB.gu_bug + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sBugId);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      iRetVal = oRSet.getInt(1);
    else
      iRetVal = -1;
    oRSet.close();
    oStmt.close();
    return iRetVal;
  } // getPgFromId

  // ----------------------------------------------------------

  /**
   * <p>Get Bug Unique Identifier from its numeric identifier.</p>
   * Each Bug is assigned a GUID. But, as GUID are 32 characters hexadecimals
   * string very difficult to remember, each bug is also automatically assigned
   * to an integer identifier. The bug numeric identifier is an alternative
   * primary key.
   * @param oConn Database Connection
   * @param iBugPg Bug numeric identifier
   * @param sWorkArea GUID
   * @return Bug GUID or <b>null</b> if no bug with such numeric identifier is found at given WorkArea
   * @throws SQLException
   * @since 2.2
   */
  public static String getIdFromPg(JDCConnection oConn, int iBugPg, String sWorkArea) throws SQLException {
    String sRetVal;
    PreparedStatement oStmt;
    ResultSet oRSet;

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_bug + " FROM " + DB.k_bugs +
                                   " b WHERE b." + DB.pg_bug + "=? AND EXISTS " +
                                   " (SELECT p." + DB.gu_project + " FROM " + DB.k_projects + " p WHERE b." + DB.gu_project + "=p." + DB.gu_project + " AND p." + DB.gu_owner + "=?)",
                                   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setInt(1, iBugPg);
    oStmt.setString(2, sWorkArea);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sRetVal = oRSet.getString(1);
    else
      sRetVal = null;
    oRSet.close();
    oStmt.close();

    return sRetVal;
  } // getIdFromPg

  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 82;
}
