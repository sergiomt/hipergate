/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.surveys;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

/**
 * Single DataSheet Answer for a Survey
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Answer extends DBPersist {

  // ---------------------------------------------------------------------------

  /**
   * Default constructor
   */
  public Answer() {
    super(DB.k_pageset_answers,"Answer");
  }

  // ---------------------------------------------------------------------------

  /**
   * Create answer and initialize some properties
   * @param sGuDataSheet GUID of DataSheet to which this Answer belongs
   * @param sGuPageSet GUID of PageSet to which this Answer belongs
   * @param sGuPage Page GUID
   * @param iPgPage Page number
   * @param sNmAnswer Unique Name for this Answer
   * @param iPgAnswer Answer number within the page
   * @param sGuWriter GUID of ACLUser writting the Answer
   */
  public Answer(String sGuDataSheet, String sGuPageSet, String sGuPage, int iPgPage, String sNmAnswer, int iPgAnswer, String sGuWriter) {
    super(DB.k_pageset_answers,"Answer");
    put (DB.gu_datasheet, sGuDataSheet);
    put (DB.gu_pageset, sGuPageSet);
    put (DB.gu_page, sGuPage);
    put (DB.pg_page, iPgPage);
    put (DB.nm_answer, sNmAnswer);
    put (DB.pg_answer, iPgAnswer);
    put (DB.gu_writer, sGuWriter);
  }

  // ---------------------------------------------------------------------------

  /**
   * Set Answer unique name within this DataSheet
   * @param sName Answer Name. No spaces, asterisks, angle brackets, ampersands,
   * quotes, slashes, question marks, or ats allowed.
   * @throws IllegalArgumentException if sName contains any forbidden character.
   */
  public void setName(String sName) throws IllegalArgumentException {
    if (DebugFile.trace) {
      if (sName.indexOf(' ')>=0 || sName.indexOf('*')>=0 || sName.indexOf('&')>=0 ||
          sName.indexOf('<')>=0 || sName.indexOf('>')>=0 || sName.indexOf('@')>=0 ||
          sName.indexOf('?')>=0 || sName.indexOf('"')>=0 || sName.indexOf(39 )>=0 ||
          sName.indexOf('/')>=0 || sName.indexOf('\\')>=0)
        throw new IllegalArgumentException("Answer name contains invalid characters");
    }
    replace(DB.nm_answer, sName);
  }

  // ---------------------------------------------------------------------------

  public String getName() {
    return getStringNull(DB.nm_answer, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Set value for answer</p>
   * If sValue contains single or double quotes then they are replace by acent
   * characters " if replace by ´´ and ' is replaced by ´
   * @param sValue String
   */
  public void setValue(String sValue) {
    if (null==sValue) {
      replace(DB.tx_answer, "");
    }
    else {
      try {
      // No single quotes nor double quotes allowed in answer texts
      replace(DB.tx_answer,
              Gadgets.replace(Gadgets.replace(sValue, "\"", "´´"), "'", "´")); }
      catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) {}
    }
  } // setValue

  // ---------------------------------------------------------------------------

  /**
   * Get Answer value
   * @return Answer value or empty string "" if there is no value for this Answer
   */
  public String getValue() {
    return getStringNull(DB.tx_answer, "");
  }

  // ---------------------------------------------------------------------------

  /**
   * Set Answer Type
   * @param sType Type name in uppercase. One of:
   * { TEXT, MEMO, CHOICE, LISTCHOICE, MULTICHOICE, LICKERT, MATRIX }
   */
  public void setType(String sType) {
    if (sType==null) {
      if (AllVals.containsKey(DB.tp_answer))
        AllVals.remove(DB.tp_answer);
    }
    else {
      replace(DB.tp_answer, sType.toUpperCase());
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * Get Answer Type Name
   * @return Answer Type Name
   */
  public String getType() {
    return getStringNull(DB.tp_answer, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Delete answer from k_pageset_answers</p>
   * This method overrides the default implementation of DBPersist superclass.<br>
   * It deletes the answer based on its name (nm_answer) or its position int the
   * page (pg_answer).
   * @param oConn JDCConnection Open JDBC database connection
   * @return <b>true</b> if register was successfully erased, <b>false</b> if not.
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+
      DB.k_pageset_answers+" WHERE "+DB.gu_datasheet+"=? AND ("+DB.nm_answer+"=? OR ("+
      DB.pg_answer+"=? AND ("+DB.gu_page+"=? OR "+DB.pg_page+"=?)))");
    oStmt.setString(1, getStringNull(DB.gu_datasheet,null));
    oStmt.setString(2, getStringNull(DB.nm_answer,null));
    oStmt.setString(3, getStringNull(DB.gu_page,null));
    if (isNull(DB.pg_page))
      oStmt.setNull(4, java.sql.Types.INTEGER);
    else
      oStmt.setInt(4, getInt(DB.pg_page));
    int iAffected = oStmt.executeUpdate();
    oStmt.close();
    return (iAffected>0);
  } // delete

  // ---------------------------------------------------------------------------

  /**
   * <p>Check whether or not a page already exists at k_pageset_answers</p>
   * This method  the default implementation of DBPersist superclass.<br>
   * It checks for answer existence based on its name (nm_answers) or its position
   * in the page (pg_answer)
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException
   */
  public boolean exists(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+
      DB.k_pageset_answers+" WHERE "+DB.gu_datasheet+"=? AND ("+DB.nm_answer+"=? OR ("+
      DB.pg_answer+"=? AND ("+DB.gu_page+"=? OR "+DB.pg_page+"=?)))");
    oStmt.setString(1, getStringNull(DB.gu_datasheet,null));
    oStmt.setString(2, getStringNull(DB.nm_answer,null));
    oStmt.setString(3, getStringNull(DB.gu_page,null));
    if (isNull(DB.pg_page))
      oStmt.setNull(4, java.sql.Types.INTEGER);
    else
      oStmt.setInt(4, getInt(DB.pg_page));
    ResultSet oRSet = oStmt.executeQuery();
    boolean bExists = oRSet.next();
    oRSet.close();
    oStmt.close();
    return bExists;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Store Answer at database</p>
   * Field k_pageset_answers.dt_modified is automatically updated to the current
   * date each time that an answer is stored.
   * @param oConn Open JDBC database connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Answer.store()");
      DebugFile.incIdent();
    }

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
     PreparedStatement oStmt = oConn.prepareStatement("SELECT k_sp_ins_answer(?,?,?,?,?,?,?,?,?)");
     oStmt.setString(1, getStringNull(DB.gu_datasheet,null));
     oStmt.setString(2, getStringNull(DB.gu_page,null));
     if (isNull(DB.pg_page))
       oStmt.setNull(3, java.sql.Types.INTEGER);
     else
       oStmt.setInt(3, getInt(DB.pg_page));
     if (isNull(DB.pg_answer))
       oStmt.setNull(4, java.sql.Types.INTEGER);
     else
       oStmt.setInt(4, getInt(DB.pg_answer));
     oStmt.setString(5, getStringNull(DB.gu_pageset,null));
     oStmt.setString(6, getStringNull(DB.nm_answer,null));
     oStmt.setString(7, getStringNull(DB.gu_writer,null));
     oStmt.setString(8, getStringNull(DB.tp_answer,null));
     oStmt.setString(9, getStringNull(DB.tx_answer,null));
     ResultSet oRset = oStmt.executeQuery();
     oRset.close();
     oStmt.close();
    }
    else {
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_ins_answer(?,?,?,?,?,?,?,?,?) }");
      oCall.setString(1, getStringNull(DB.gu_datasheet,null));
      oCall.setString(2, getStringNull(DB.gu_page,null));
      if (isNull(DB.pg_page))
        oCall.setNull(3, java.sql.Types.INTEGER);
      else
        oCall.setInt(3, getInt(DB.pg_page));
      if (isNull(DB.pg_answer))
        oCall.setNull(4, java.sql.Types.INTEGER);
      else
        oCall.setInt(4, getInt(DB.pg_answer));
      oCall.setString(5, getStringNull(DB.gu_pageset,null));
      oCall.setString(6, getStringNull(DB.nm_answer,null));
      oCall.setString(7, getStringNull(DB.gu_writer,null));
      oCall.setString(8, getStringNull(DB.tp_answer,null));
      oCall.setString(9, getStringNull(DB.tx_answer,null));
      oCall.execute();
      oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Answer.store()");
    }

    return true;
  }

 // ---------------------------------------------------------------------------

  public static final short ClassId = 212;

} // Answer
