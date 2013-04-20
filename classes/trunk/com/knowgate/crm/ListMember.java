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

package com.knowgate.crm;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;

import java.util.Date;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

/**
 * <p>List Member</p>
 * <p>List Members are kept at database differently depending on the type of list
 * they belong to.<br><br>
 * For Members of Dynamic Lists (k_lists.tp_list=2) no member record is explicitly
 * stored at database, but members are dynamically extracted from k_member_address
 * view each time that the DistributionList is used.<br><br>
 * For Members of Static Lists (k_lists.tp_list=1) a record is stored at
 * k_x_list_members table. Members of Static Lists can be Companies from k_companies
 * table of Contacts from k_contacts table. If Member is a Company then tp_member is
 * set to 91 and gu_company is set to Company GUID. If Member is a Contact then
 * tp_member is set to 90 and gu_contact is set to Contact GUID.<br><br>
 * For Members of Direct and Black Lists (k_lists.tp_list=3 and k_lists.tp_list=4)
 * tp_member is set to 95. One record is stored at k_x_list_members table and
 * another record is stored at k_list_members. There is one unique record per
 * Member at k_list_members and one record per member and list at k_x_list_members.<br><br>
 * <b>List Member Storage Summary<b><br>
 * <table cellpadding="4" border="1">
 * <tr><td>List Type</td><td>k_lists.tp_member</td><td>k_x_list_member.gu_contact</td><td>k_x_list_member.gu_company</td><td>k_list_member.gu_member</td></tr>
 * <tr><td>DYNAMIC</td><td align="middle">90 or 91</td><td align="middle">NONE</td><td align="middle">NONE</td><td align="middle">NONE</td></tr>
 * <tr><td>STATIC</td><td align="middle">90 or 91</td><td>References k_contacts if tp_member=90</td><td align="middle">References k_companies if tp_member=91</td><td align="middle">NONE</td></tr>
 * <tr><td>DIRECT</td><td align="middle">95</td><td>References k_list_members</td><td align="middle">NULL</td><td align="middle">Member GUID</td></tr>
 * </table>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class ListMember {

  private DBPersist oMember;

  // ----------------------------------------------------------

  private short getListType (JDCConnection oConn, String sListGUID) throws SQLException {

    PreparedStatement oList;
    ResultSet oRSet;
    short iTpList;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ListMember.getListType([Connection], " + (null!=sListGUID ? sListGUID : "null") + ")");
      DebugFile.incIdent();
    }

    if (null==sListGUID)
      iTpList = 0;

    else {

      if (!oMember.getItemMap().containsKey(DB.tp_list)) {

        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.tp_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_list + "='" + (null!=sListGUID ? sListGUID : "null") + "'");

        oList = oConn.prepareStatement("SELECT " + DB.tp_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_list + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oList.setString(1, sListGUID);

        try { oList.setQueryTimeout(20); }  catch (SQLException sqle) { /* ignore */}

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");

        oRSet = oList.executeQuery();

        if (oRSet.next()) {
          iTpList = oRSet.getShort(1);
          oMember.put(DB.tp_list, iTpList);
        }
        else
          iTpList = 0;

        oRSet.close();
        oList.close();

      }
      else

        iTpList = oMember.getShort(DB.tp_list);
    } // fi (sListGUID)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ListMember.getListType() : " + String.valueOf(iTpList));
    }

    return iTpList;
  } // getListType

  // ----------------------------------------------------------

  public ListMember() {
    oMember = new DBPersist(DB.k_list_members, "ListMember");
  }

  /**
   * Create ListMember and load its fields from database.
   * ListMember with given GUID or e-mail is seeked at k_x_list_members table.
   * @param oConn Database Connection
   * @param sMemberId One of: GUID for Contact, GUID for Company or Member e-mail.
   * @param sListGUID DistributionList GUID
   * @throws SQLException
   */
  public ListMember(JDCConnection oConn, String sMemberId, String sListGUID) throws SQLException {

    PreparedStatement oStmt;
    ResultSet oRSet;
    ResultSetMetaData oMDat;
    Object oFld;
    int iCols;

    oMember = new DBPersist(DB.k_list_members, "ListMember");

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT * FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sListGUID + "' AND (" + DB.gu_contact + "='" + sMemberId + "' OR " + DB.gu_company + "='" + sMemberId + "' OR " + DB.tx_email + "='" + sMemberId + "'))");

      oStmt = oConn.prepareStatement("SELECT * FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND (" + DB.gu_contact + "=? OR " + DB.gu_company + "=? OR " + DB.tx_email + "=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      try { oStmt.setQueryTimeout(20); }  catch (SQLException sqle) { /* ignore */}

      oStmt.setString(1, sListGUID);
      oStmt.setString(2, sMemberId);
      oStmt.setString(3, sMemberId);
      oStmt.setString(4, sMemberId);

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");

      oRSet = oStmt.executeQuery();

      oMDat = oRSet.getMetaData();
      iCols = oMDat.getColumnCount();

      if (oRSet.next()) {
        for (int c=1; c<=iCols; c++) {
          if (!oMDat.getColumnName(c).equalsIgnoreCase(DB.dt_created)) {
            oFld = oRSet.getObject(c);
            if (!oRSet.wasNull())
              oMember.put(oMDat.getColumnName(c).toLowerCase(), oFld);
          } // fi (getColumnName(c)!=DB.dt_created)
        } // next
      } // fi (oRSet)
      else {
        if (DebugFile.trace) DebugFile.writeln("member " + sMemberId + " not found at list " + sListGUID);
      }

      oRSet.close();
      oStmt.close();
  }

  // ----------------------------------------------------------

  /**
   * Internal DBPersist object reference for k_list_members register.
   */
  public DBPersist member() {
    return oMember;
  }

  // ----------------------------------------------------------

  public java.util.Date getDate(String sKey) {
    return oMember.getDate(sKey);
  }

  // ----------------------------------------------------------

  public String getDateFormated(String sKey, String sFormat) {
    return oMember.getDateFormated(sKey, sFormat);
  }

  // ----------------------------------------------------------

  public short getShort(String sKey) throws java.lang.NullPointerException {
    return oMember.getShort(sKey);
  }

  // ----------------------------------------------------------

  public String getString(String sKey) throws java.lang.NullPointerException {
    return oMember.getString(sKey);
  }

  // ----------------------------------------------------------

  public String getStringNull(String sKey, String sDefault) {
    return oMember.getStringNull(sKey, sDefault);
  }

  // ----------------------------------------------------------

  public boolean isNull(String sColumnName) {
    return oMember.isNull(sColumnName);
  }

  // ----------------------------------------------------------

  public void put(String sKey, String sVal) {
    oMember.put(sKey, sVal);
  }

  // ----------------------------------------------------------

  public void put(String sKey, short iVal) {
    oMember.put(sKey, iVal);
  }

  // ----------------------------------------------------------

  public void put(String sKey, java.util.Date dtVal) {
    oMember.put(sKey, dtVal);
  }

  // ----------------------------------------------------------

  public void put(String sKey, Object oObj) {
    oMember.put(sKey, oObj);
  }

  // ----------------------------------------------------------

  public void replace(String sKey, Object oObj) {
    oMember.replace(sKey,oObj);
  }

  // ----------------------------------------------------------

  public void replace(String sKey, short iVal) {
    oMember.replace(sKey,iVal);
  }

  // ----------------------------------------------------------

  public void remove(String sKey) {
    oMember.remove(sKey);
  }


  // ----------------------------------------------------------

  /**
   * <p>Get whether or not a List Member is Blocked</p>
   * Blocked Members are those present on the associated black list.<br>
   * Companies and Contacts are considered to be in the black list if its
   * gu_company or gu_contact is into black list register at k_x_list_members<br>
   * Direct List Members are considered to be in the black list if its
   * tx_email is into black list register at k_x_list_members<br>
   * This way, by searching Companies and Contacts by GUID and Direct Members by
   * e-mail, a Contact or Company may have several e-mail addresses all of them
   * blocked by a single black list entry.<br>
   * This method calls stored procedures: k_sp_company_blocked, k_sp_contact_blocked and k_sp_email_blocked
   * @param oConn Database Connection
   * @return <b>true</b> if member is blocked (present at associated black list for this list) <b>false</b> otherwise.
   * @throws SQLException
   */
  public boolean isBlocked (JDCConnection oConn) throws SQLException {
    boolean bBlocked;
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sList;
    String sProc;
    String sParm;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ListMember.isBlocked([Connection])");
      DebugFile.incIdent();
    }

    sList = oMember.getString(DB.gu_list);

    switch (oMember.getShort(DB.tp_member)) {
      case Company.ClassId:
        sProc = "k_sp_company_blocked";
        sParm = oMember.getString(DB.gu_company);
        if (DebugFile.trace) DebugFile.writeln("gu_company=" + sParm);
        break;
      case Contact.ClassId:
        sProc = "k_sp_contact_blocked";
        sParm = oMember.getString(DB.gu_contact);
        if (DebugFile.trace) DebugFile.writeln("gu_contact=" + sParm);
        break;
      default:
        sProc = "k_sp_email_blocked";
        sParm = oMember.getString(DB.tx_email);
        if (DebugFile.trace) DebugFile.writeln("tx_email=" + sParm);
    }

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_POSTGRESQL:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + sProc + "(?,?))");

        oStmt = oConn.prepareStatement("SELECT " + sProc + "(?,?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sList);
        oStmt.setString(2, sParm);
        oRSet = oStmt.executeQuery();
        oRSet.next();
        bBlocked = (oRSet.getShort(1)!=(short)0);
        oRSet.close();
        oStmt.close();
        break;

      case JDCConnection.DBMS_ORACLE:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call " + sProc + "(?,?,?)})");

        oCall = oConn.prepareCall("{ call " + sProc + "(?,?,?)}");
        oCall.setString(1, sList);
        oCall.setString(2, sParm);
        oCall.registerOutParameter(3, java.sql.Types.DECIMAL);
        oCall.execute();
        bBlocked = (oCall.getBigDecimal(3).intValue()!=0);
        oCall.close();
        break;

      default:
        if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call " + sProc + "(?,?,?)})");

        oCall = oConn.prepareCall("{ call " + sProc + "(?,?,?)}");
        oCall.setString(1, sList);
        oCall.setString(2, sParm);
        oCall.registerOutParameter(3, java.sql.Types.SMALLINT);
        oCall.execute();
        bBlocked = (oCall.getShort(3)!=(short)0);
        oCall.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ListMember.isBlocked() : " + String.valueOf(bBlocked));
    }

    return bBlocked;
  }

  // ----------------------------------------------------------

  /**
   * <p>Remove Member from a DistributionList.</p>
   * Member is also removed from associated black list.
   * @param oConn Database Connection
   * @param sListId GUID of DistributionList from witch Member is to be removed.
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn, String sListId) throws SQLException {
    PreparedStatement oDlte;
    PreparedStatement oStmt;
    ResultSet oRSet;
    boolean bRetVal;
    String sBlackList;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ListMember.delete([Connection], " + sListId + ")");
      DebugFile.incIdent();
    }

    // Find associated Black List

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_query + "='" + sListId + "' AND " + DB.tp_list + "=" + String.valueOf(DistributionList.TYPE_BLACK) + ")");

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_list + " FROM " + DB.k_lists + " WHERE " + DB.gu_query + "=? AND " + DB.tp_list + "=" + String.valueOf(DistributionList.TYPE_BLACK), ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sListId);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sBlackList = oRSet.getString(1);
    else
      sBlackList = null;
    oRSet.close();
    oStmt.close();

    // Delete Member from Black List

    if (null!=sBlackList) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sBlackList + "' AND (" + DB.gu_contact + "='" + oMember.getStringNull(DB.gu_member,"null") + "' OR " + DB.gu_company + "='" + oMember.getStringNull(DB.gu_member,"null") + "' OR " + DB.tx_email + "='" + oMember.getStringNull(DB.tx_email,"null") + "'))");

      oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND (" + DB.gu_contact + "=? OR " + DB.gu_company + "=? OR " + DB.tx_email + "=?)");

      oDlte.setString(1, sBlackList);
      oDlte.setString(2, oMember.getString(DB.gu_member));
      oDlte.setString(3, oMember.getString(DB.gu_member));
      oDlte.setString(4, oMember.getString(DB.tx_email));

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

      bRetVal = oDlte.executeUpdate()>0;
      oDlte.close();
    }

    // Delete Member from List

    if (DebugFile.trace)
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sListId + "' AND (" + DB.gu_contact + "='" + oMember.getStringNull(DB.gu_member,"null") + "' OR " + DB.gu_company + "='" + oMember.getStringNull(DB.gu_member,"null") + "' OR " + DB.tx_email + "='" + oMember.getStringNull(DB.tx_email,"null") + "'))");

    oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND (" + DB.gu_contact + "=? OR " + DB.gu_company + "=? OR " + DB.tx_email + "=?)");

    oDlte.setString(1, sListId);
    oDlte.setString(2, oMember.getString(DB.gu_member));
    oDlte.setString(3, oMember.getString(DB.gu_member));
    oDlte.setString(4, oMember.getString(DB.tx_email));

    if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

    bRetVal = oDlte.executeUpdate()>0;
    oDlte.close();

    int iTpList = getListType(oConn, sListId);

    if (DistributionList.TYPE_DIRECT==iTpList || DistributionList.TYPE_BLACK==iTpList)
      bRetVal = oMember.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ListMember.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  /**
   * Remove Member from all DistributionList.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    PreparedStatement oDlte;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ListMember.delete([Connection])");
      DebugFile.incIdent();
    }

    oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_contact + "=? OR " + DB.gu_company + "=?");
    oDlte.setString(1, oMember.getString(DB.gu_member));
    oDlte.setString(2, oMember.getString(DB.gu_member));
    oDlte.execute();
    oDlte.close();

    bRetVal = oMember.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ListMember.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Store Member at a DistributionList</p>
   * <p>Automatically generates gu_member GUID for Direct List Members and dt_modified DATE if not explicitly set.</p>
   * @param oConn Database Connection
   * @param sListGUID GUID of Distribution List
   * @throws ClassCastException If sListId type is DYNAMIC.
   * @throws NoSuchFieldException If List is Static and gu_member field is not set
   * @throws SQLException
   */

  public boolean store(JDCConnection oConn, String sListGUID)
    throws ClassCastException,NoSuchFieldException,SQLException {
    boolean bRetVal;
    String sSQL;
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());
    PreparedStatement oStmt;
    int iAffected;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ListMember.store([Connection])");
      DebugFile.incIdent();
    }

    int iTpList = getListType(oConn, sListGUID);

    if (iTpList==DistributionList.TYPE_DYNAMIC)
      throw new ClassCastException("Dynamic Distribution Lists cannot have additional Members directly added");

    if (!oMember.getItemMap().containsKey(DB.gu_member)) {
      if (iTpList==DistributionList.TYPE_STATIC)
        throw new NoSuchFieldException("gu_member field must be set before storing a Member from a Static Distribution List");

      oMember.put(DB.gu_member, Gadgets.generateUUID());
    }

    // Forzar la fecha de modificación del registro
    oMember.replace(DB.dt_modified, dtNow);

    if (DistributionList.TYPE_DIRECT==iTpList || DistributionList.TYPE_BLACK==iTpList)
      bRetVal = oMember.store(oConn);

    if (DebugFile.trace) {
      String sActive;
      if (oMember.getItemMap().containsKey(DB.bo_active))
        sActive = String.valueOf(oMember.getShort(DB.bo_active));
      else
        sActive = "null";

      sSQL = "UPDATE " + DB.k_x_list_members + " SET " + DB.tx_email + "='" + oMember.getStringNull(DB.tx_email,"null") + "'," + DB.tx_name + "=?," + DB.tx_surname + "=?," + DB.tx_salutation + "=?,"+ DB.bo_active + "=" + sActive + "," + DB.id_format + "='" + oMember.getStringNull(DB.id_format, "TXT") + "'," + DB.dt_modified + "=? WHERE " + DB.gu_list + "='" + sListGUID + "' AND (" + DB.gu_contact + "='" + oMember.getStringNull(DB.gu_member,"null") + "' OR " + DB.gu_company + "=? OR " + DB.tx_email + "='" + oMember.getStringNull(DB.tx_email,"null") + "')";

      DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
    }

    sSQL = "UPDATE " + DB.k_x_list_members + " SET " + DB.tx_email + "=?," + DB.tx_name + "=?," + DB.tx_surname + "=?," + DB.tx_salutation + "=?,"+ DB.bo_active + "=?," + DB.id_format + "=?," + DB.dt_modified + "=? WHERE " + DB.gu_list + "=? AND (" + DB.gu_contact + "=? OR " + DB.gu_company + "=? OR " + DB.tx_email + "=?)";

    oStmt = oConn.prepareStatement(sSQL);

    oStmt.setString(1, oMember.getString(DB.tx_email));
    oStmt.setString(2, oMember.getStringNull(DB.tx_name, null));
    oStmt.setString(3, oMember.getStringNull(DB.tx_surname, null));
    oStmt.setString(4, oMember.getStringNull(DB.tx_salutation, null));

    if (oMember.getItemMap().containsKey(DB.bo_active))
      oStmt.setShort (5, oMember.getShort(DB.bo_active));
    else
      oStmt.setShort (5, (short)1);

    oStmt.setString(6, oMember.getStringNull(DB.id_format, "TXT"));

    oStmt.setTimestamp(7, new Timestamp(new Date().getTime()));

    oStmt.setString(8, sListGUID);

    if (oMember.getItemMap().containsKey(DB.tp_member)) {

      if (DebugFile.trace) DebugFile.writeln("tp_member=" + String.valueOf(oMember.getShort(DB.tp_member)));

      if (oMember.getShort(DB.tp_member)==Company.ClassId) {

        if (DebugFile.trace)
          DebugFile.writeln("gu_contact=" + oMember.getStringNull(DB.gu_member,"null") + " , gu_company=null");

        oStmt.setString(9, oMember.getString(DB.gu_member));
        oStmt.setString(10, null);
      }
      else {
        if (DebugFile.trace)
          DebugFile.writeln("gu_contact=null, gu_company=" + oMember.getStringNull(DB.gu_member,"null"));

        oStmt.setString(9, null);
        oStmt.setString(10, oMember.getString(DB.gu_member));
      }
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("tp_member not set");

      if (DebugFile.trace)
        DebugFile.writeln("gu_contact=null, gu_company=" + oMember.getStringNull(DB.gu_member,"null"));

      oStmt.setString(9, null);
      oStmt.setString(10, oMember.getString(DB.gu_member));
    }

    oStmt.setString(11, oMember.getString(DB.tx_email));

    if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");

    iAffected = oStmt.executeUpdate();

    if (DebugFile.trace) DebugFile.writeln("affected rows = " + String.valueOf(iAffected));

    oStmt.close();

    if (0==iAffected) {

      if (DebugFile.trace) {
        sSQL = "INSERT INTO " + DB.k_x_list_members + " (" + DB.gu_list + "," + DB.tx_email + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_salutation + "," + DB.bo_active + "," + DB.tp_member + "," + DB.gu_company + "," + DB.gu_contact + "," + DB.id_format + ") VALUES ('" + sListGUID + "','" + oMember.getStringNull(DB.tx_email,"null") + "',?,?,?,?,?,?,'" + oMember.getStringNull(DB.gu_member,"null") + "','" + oMember.getStringNull(DB.id_format,"TXT") + "')";

        DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");
      }

      sSQL = "INSERT INTO " + DB.k_x_list_members + " (" + DB.gu_list + "," + DB.tx_email + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_salutation + "," + DB.bo_active + "," + DB.tp_member + "," + DB.gu_company + "," + DB.gu_contact + "," + DB.id_format + ") VALUES (?,?,?,?,?,?,?,?,?,?)";

      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1, sListGUID);
      oStmt.setString(2, oMember.getString(DB.tx_email));
      oStmt.setString(3, oMember.getStringNull(DB.tx_name,null));
      oStmt.setString(4, oMember.getStringNull(DB.tx_surname,null));
      oStmt.setString(5, oMember.getStringNull(DB.tx_salutation,null));

      if (oMember.getItemMap().containsKey(DB.bo_active))
        oStmt.setShort (6, oMember.getShort(DB.bo_active));
      else
        oStmt.setShort (6, (short)1);

      if (oMember.getItemMap().containsKey(DB.tp_member)) {
        if (DebugFile.trace) DebugFile.writeln ("member type is " + String.valueOf(oMember.getShort(DB.tp_member)));

        oStmt.setShort(7, oMember.getShort(DB.tp_member));

        if (oMember.getShort(DB.tp_member)==Company.ClassId) {
          oStmt.setString(8, oMember.getString(DB.gu_member));
          oStmt.setString(9, null);
        }
        else {
          oStmt.setString(8, null);
          oStmt.setString(9, oMember.getString(DB.gu_member));
        }
      }
      else {

        if (new Contact(getString(DB.gu_member)).exists(oConn)) {
          if (DebugFile.trace) DebugFile.writeln("member type automatically set to " + String.valueOf(Contact.ClassId));

          oStmt.setShort (7, Contact.ClassId);
          oStmt.setString(8, null);
          oStmt.setString(9, oMember.getString(DB.gu_member));
        }
        else if (new Company(getString(DB.gu_member)).exists(oConn)) {
          if (DebugFile.trace) DebugFile.writeln("member type automatically set to " + String.valueOf(Company.ClassId));

          oStmt.setShort (7, Company.ClassId);
          oStmt.setString(8, oMember.getString(DB.gu_member));
          oStmt.setString(9, null);
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("member type automatically set to " + String.valueOf(ListMember.ClassId));

          oStmt.setShort (7, ListMember.ClassId);
          oStmt.setString(8, null);
          oStmt.setString(9, oMember.getString(DB.gu_member));
        }
      }

      oStmt.setString(10, oMember.getStringNull(DB.id_format,"TXT"));

      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.execute()");

      bRetVal = oStmt.execute();

      oStmt.close();
    }
    else
      bRetVal = true;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ListMember.store() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store()

  /**
   * <p>Block Member</p>
   * <p>Add member to Black List associated to Base List.</p>
   * @param oConn Database Connection
   * @param sListGUID Base List GUID
   * @throws SQLException
   * @throws NoSuchFieldException
   */

  public void block (JDCConnection oConn, String sListGUID)
    throws SQLException, NoSuchFieldException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ListMember.block([Connection], " + sListGUID + ")");
      DebugFile.incIdent();
    }

    DistributionList oList = new DistributionList(oConn, sListGUID);

    String sBlack = oList.blackList (oConn);

    if (null==sBlack) {
      sBlack = Gadgets.generateUUID();

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(INSERT INTO " + DB.k_lists + "(" + DB.gu_list + "," + DB.gu_workarea + "," + DB.tp_list + "," + DB.gu_query + "," + DB.de_list + ") VALUES('" + sBlack + "','" + getStringNull(DB.gu_workarea,"null") + "',4,'" + getStringNull(DB.gu_list,"null") + "','" + getStringNull(DB.de_list,"null") + "'))");

      PreparedStatement oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_lists + "(" + DB.gu_list + "," + DB.gu_workarea + "," + DB.tp_list + "," + DB.gu_query + "," + DB.de_list + ") VALUES(?,?,?,?,?)");
      oStmt.setString(1, sBlack);
      oStmt.setString(2, oList.getString(DB.gu_workarea));
      oStmt.setShort (3, DistributionList.TYPE_BLACK);
      oStmt.setString(4, sListGUID);
      oStmt.setString(5, oList.getString(DB.de_list));
      oStmt.executeUpdate();
      oStmt.close();
    }

    store (oConn, sBlack);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ListMember.block()");
    }
  }

  /**
   * <p>Unblock Member</p>
   * <p>Remove member from Black List associated to Base List.</p>
   * @param oConn Database Connection
   * @param sListGUID Base List GUID
   * @throws SQLException
   */

  public void unblock (JDCConnection oConn, String sListGUID)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ListMember.unblock([Connection], " + sListGUID + ")");
      DebugFile.incIdent();
    }

    DistributionList oList = new DistributionList(oConn, sListGUID);

    String sBlack = oList.blackList (oConn);

    if (null!=sBlack) {
      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + sBlack + "' AND " + DB.tx_email + "='" + getStringNull(DB.tx_email,"null")+ "')");

      PreparedStatement oDlte = oConn.prepareStatement("DELETE FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "=? AND " + DB.tx_email + "=?");
      oDlte.setString (1, sBlack);
      oDlte.setString (2, getString(DB.tx_email));
      oDlte.executeUpdate();
      oDlte.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ListMember.unblock()");
    }
  } // unblock


  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 95;

}