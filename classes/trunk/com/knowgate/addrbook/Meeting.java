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

package com.knowgate.addrbook;

import java.util.Date;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.Timestamp;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBPersist;

/**
 * <p>Meeting for Fellows</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class Meeting extends DBPersist {

  public Meeting() {
     super(DB.k_meetings, "Meeting");
  }

  public Meeting(String sMeetingId) {
     super(DB.k_meetings, "Meeting");

     put(DB.gu_meeting, sMeetingId);
  }

  public Meeting(JDCConnection oConn, String sMeetingId) throws SQLException {
     super(DB.k_meetings, "Meeting");

     load(oConn, new Object[] {sMeetingId});
  }

  // ----------------------------------------------------------

  public Date lastModified() {
    Date dtLastMod = isNull(DB.dt_modified) ? getDate(DB.dt_created) : getDate(DB.dt_modified);
    if (null==dtLastMod) dtLastMod = getDate(DB.dt_start);
    return dtLastMod;
  }

  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {
    return Meeting.delete(oConn, getString(DB.gu_meeting));
  }

  // ----------------------------------------------------------

  /**
   * <p>Store meeting</p>
   * gu_meeting is automatically assigned if not set for new meetings<br>
   * dt_modified is automatically updated for existing meetings<br>
   * bo_private is set to zero if value for it is not specified
   * Since version 4.0, as a shortcut, if a single value for nm_room property is set,
   * then it is added to k_x_meeting_room table without need of
   * calling setRoom() method
   * @param oConn JDCConnection
   * @return boolean
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {

    // Si no se especificó un identificador para el encuentro, entonces añadirlo automáticamente
    if (!AllVals.containsKey(DB.gu_meeting))
      put(DB.gu_meeting, Gadgets.generateUUID());
    else
      replace(DB.dt_modified, new Timestamp(new Date().getTime()));

    if (!AllVals.containsKey(DB.bo_private))
      put(DB.bo_private, (short)0);

	/*
    if (AllVals.containsKey(DB.nm_legal) && !AllVals.containsKey(DB.gu_company)) {
	  String sGuCompany = Company.getIdFromName(oConn, getString(DB.nm_legal));
	  if (null!=sGuCompany) {
	  	AllVals.put(DB.gu_company, sGuCompany);
	  	
	  } // fi
    } //
	*/

    boolean bRetVal = super.store(oConn);
    
    if (bRetVal) {
      if (AllVals.containsKey(DB.nm_room)) {
	    setRoom(oConn, getString(DB.nm_room));
      } // fi
    } // fi

    return bRetVal;
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Get Fellows attending to this Meeting</p>
   * <p>Retrieves Fellows from k_x_meeting_fellow table.</p>
   * @param oConn Database Connection
   * @return {@link DBSubset} with 5 columns {gu_fellow,tx_name,tx_surname,de_title,tx_email}
   * @throws SQLException
   * @see {@link Fellow}
   */
  public DBSubset getFellows(JDCConnection oConn) throws SQLException {

    DBSubset oFellows = new DBSubset(DB.k_fellows + " f," + DB.k_x_meeting_fellow + " x",
                                     " f." + DB.gu_fellow + ",f." + DB.tx_name + ",f." + DB.tx_surname + ",f." + DB.de_title + ",f." + DB.tx_email,
                                     "f." + DB.gu_fellow + "=x." + DB.gu_fellow  + " AND x." + DB.gu_meeting + "=?", 4);

    oFellows.load(oConn, new Object[] { getString(DB.gu_meeting) });

    return oFellows;

  } // getFellows

  // ----------------------------------------------------------

  /**
   * <p>External Enterprise Contacts Attending to this meeting</p>
   * <p>Retrieves Contacts from k_x_meeting_contact table.</p>
   * @param oConn Database Connection
   * @return {@link DBSubset} with 3 columns {gu_contact,tx_name,tx_surname}
   * @throws SQLException
   * @see {@link Contact}
   */

  public DBSubset getContacts(JDCConnection oConn) throws SQLException {

    DBSubset oContacts = new DBSubset(DB.k_contacts + " c," + DB.k_x_meeting_contact + " x",
                                      " c." + DB.gu_contact + ",c." + DB.tx_name + ",c." + DB.tx_surname,
                                      "c." + DB.gu_contact + "=x." + DB.gu_contact + " AND x." + DB.gu_meeting + "=?", 4);

    oContacts.load(oConn, new Object[] { getString(DB.gu_meeting) });

    return oContacts;

  } // getContacts

  // ----------------------------------------------------------

  /**
   * <p>Get Rooms and other Resources reserved for thsi meeting<.</p>
   * <p>Retrieves Rooms from k_x_meeting_room table.</p>
   * @param oConn Database Connection
   * @return {@link DBSubset} with 5 columns {nm_room,tp_room,tx_company,tx_location,tx_comments}
   * @throws SQLException
   */

  public DBSubset getRooms(JDCConnection oConn) throws SQLException {

    DBSubset oRooms = new DBSubset(DB.k_rooms + " r," + DB.k_x_meeting_room + " x",
                                   " r." + DB.nm_room + ",r." + DB.tp_room + ",r." + DB.tx_company + ",r." + DB.tx_location + ",r." + DB.tx_comments,
                                   "r."+ DB.nm_room + "=x." + DB.nm_room + " AND x." + DB.gu_meeting + "=?", 1);

    oRooms.load(oConn, new Object[] { getString(DB.gu_meeting) });

    return oRooms;
  } // getRooms

  // ----------------------------------------------------------

  /**
   * @return Meeting starting hour
   */

  public String getHour() {
    return String.valueOf(getDate(DB.dt_start).getHours());
  } // getHour

  // ----------------------------------------------------------

  /**
   * @return Meeting starting minute
   */
  public String getMinute() {

    String sMins = String.valueOf(getDate(DB.dt_start).getMinutes());
    return sMins.length()==1 ? "0" + sMins : sMins;
  } // getMinute

  // ----------------------------------------------------------

  /**
   * @return Meeting ending hour
   */
  public String getHourEnd() {
    return String.valueOf(getDate(DB.dt_end).getHours());
  } // getHourEnd

  // ----------------------------------------------------------

  /**
   * @return Meeting ending minute
   */

  public String getMinuteEnd() {

    String sMins = String.valueOf(getDate(DB.dt_end).getMinutes());

    return sMins.length()==1 ? "0" + sMins : sMins;
  } // getMinuteEnd

  // ----------------------------------------------------------

  /**
   * <p>Remove all attendants to Meeting</p>
   * <p>Delete registers from k_x_meeting_fellow and k_x_meeting_contact tables</p>
   * @param oConn Database Connection
   * @throws SQLException
   */

  public void clearAttendants(JDCConnection oConn) throws SQLException {
    Statement oStmt = oConn.createStatement();
    oStmt.executeUpdate("DELETE FROM " + DB.k_x_meeting_fellow + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
    oStmt.executeUpdate("DELETE FROM " + DB.k_x_meeting_contact + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
    oStmt.executeUpdate("UPDATE " + DB.k_meetings + " SET " + DB.dt_modified + "=" + DBBind.Functions.GETDATE + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
    oStmt.close();

  } // clearAttendants

  // ----------------------------------------------------------

  /**
   * <p>Remove all Rooms and other booked Resources for Meeting</p>
   * Delete registers from k_x_meeting_room
   * @param oConn Database Connection
   * @throws SQLException
   */

  public void clearRooms(JDCConnection oConn) throws SQLException {
    Statement oStmt = oConn.createStatement();
    oStmt.executeUpdate("DELETE FROM " + DB.k_x_meeting_room + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
    oStmt.executeUpdate("UPDATE " + DB.k_meetings + " SET " + DB.dt_modified + "=" + DBBind.Functions.GETDATE + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
    oStmt.close();
  } // clearRooms

  // ----------------------------------------------------------

  /**
   * <p>Assign a Room or Resource to a Meeting</p>
   * <p>If Room was already assigned, booking dates (dt_start and dt_end at k_x_meeting_room)
   * are updated and no error is raised.</p>
   * @param oConn Database Connection
   * @param sRoomNm Room Name
   * @throws SQLException
   */

  public void setRoom(JDCConnection oConn, String sRoomNm) throws SQLException {
    boolean bBooked;
    PreparedStatement oStmt;
    Statement oExec;
    ResultSet oRSet;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Meeting.setRoom([Connection], " + sRoomNm + ")");
      DebugFile.incIdent();
    }

    oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_x_meeting_room + " WHERE " + DB.gu_meeting + "=? AND " + DB.nm_room + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1,getString(DB.gu_meeting));
    oStmt.setString(2,sRoomNm);
    oRSet = oStmt.executeQuery();
    bBooked = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (bBooked) {
      sSQL = "UPDATE " + DB.k_x_meeting_room + " SET " + DB.dt_start + "=" + DBBind.escape(getDate(DB.dt_start), "ts") + "," + DB.dt_end + "=" + DBBind.escape(getDate(DB.dt_end), "ts") + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "' AND " + DB.nm_room + "='" + sRoomNm + "'";
      oExec = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oExec.execute(sSQL);
      oExec.close();
    }
    else {
      sSQL = "INSERT INTO " + DB.k_x_meeting_room + "(" + DB.gu_meeting + "," + DB.nm_room + "," + DB.dt_start + "," + DB.dt_end + ") VALUES ('" + getString(DB.gu_meeting) + "','" + sRoomNm + "'," + DBBind.escape(getDate(DB.dt_start), "ts") + "," + DBBind.escape(getDate(DB.dt_end), "ts") + ")";
      oExec = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oExec.execute(sSQL);
      oExec.close();
    }

    Statement oUpdt = oConn.createStatement();
    oUpdt.executeUpdate("UPDATE " + DB.k_meetings + " SET " + DB.dt_modified + "=" + DBBind.Functions.GETDATE  + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
    oUpdt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Meeting.setRoom()");
    }
  } // setRoom

  // ----------------------------------------------------------

  /**
   * <p>Assign Attendant to Meeting</p>
   * <p>Attendants may be Fellows or Contacts</p>
   * <p>If Attendant was already assigned an SQLException in thrown.</p>
   * @param oConn Database Connection
   * @param sAttendantId {@link Fellow} or {@link Contact} Unique Identifier
   * @throws SQLException
   * @since 5.0
   */

  public void addAttendant(JDCConnection oConn, String sAttendantId) throws SQLException {
    boolean bExists;
    PreparedStatement oStmt;
    Statement oExec;
    Statement oUpdt;
    ResultSet oRSet;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Meeting.addAttendant([Connection], " + sAttendantId + ")");
      DebugFile.incIdent();
    }

    sSQL = "SELECT NULL FROM " + DB.k_fellows + " WHERE " + DB.gu_fellow + "=?";
    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement( " + sSQL + ")");
    oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1,sAttendantId);
    oRSet = oStmt.executeQuery();
    bExists = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (bExists) {
      sSQL = "INSERT INTO " + DB.k_x_meeting_fellow + "(" + DB.gu_meeting + "," + DB.gu_fellow + "," + DB.dt_start + "," + DB.dt_end + ") VALUES ('" + getString(DB.gu_meeting) + "','" + sAttendantId + "'," + DBBind.escape(getTimestamp(DB.dt_start), "ts") + "," + DBBind.escape(getTimestamp(DB.dt_end), "ts") + ")";
      oExec = oConn.createStatement();
      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oExec.executeUpdate(sSQL);
      oExec.close();
     }
     else {
       sSQL = "SELECT NULL FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?";
       if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement( " + sSQL + ")");
       oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
       oStmt.setString(1,sAttendantId);
       oRSet = oStmt.executeQuery();
       bExists = oRSet.next();
       oRSet.close();
       oStmt.close();

       if (bExists) {
         sSQL = "INSERT INTO " + DB.k_x_meeting_contact + "(" + DB.gu_meeting + "," + DB.gu_contact + "," + DB.dt_start + "," + DB.dt_end + ") VALUES ('" + getString(DB.gu_meeting) + "','" + sAttendantId + "'," + DBBind.escape(getTimestamp(DB.dt_start), "ts") + "," + DBBind.escape(getTimestamp(DB.dt_end), "ts") + ")";
         oExec = oConn.createStatement();
         if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
         oExec.executeUpdate(sSQL);
         oExec.close();
        }
      }

    oUpdt = oConn.createStatement();
    oUpdt.executeUpdate("UPDATE " + DB.k_meetings + " SET " + DB.dt_modified + "=" + DBBind.Functions.GETDATE + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
    oUpdt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Meeting.addAttendant()");
    }
  } // addAttendant

  // ----------------------------------------------------------

  /**
   * <p>Assign Attendant to Meeting</p>
   * <p>Attendants may be Fellows or Contacts</p>
   * <p>If Attendant was already assigned, meeting dates are updated and no error is raised.</p>
   * @param oConn Database Connection
   * @param sAttendantId {@link Fellow} or {@link Contact} Unique Identifier
   * @throws SQLException
   */

  public void setAttendant(JDCConnection oConn, String sAttendantId) throws SQLException {
    boolean bAttends;
    boolean bExists;
    PreparedStatement oStmt;
    Statement oUpdt;
    Statement oExec;
    ResultSet oRSet;
    String sSQL;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Meeting.setAttendant([Connection], " + sAttendantId + ")");
      DebugFile.incIdent();
    }

    oStmt = oConn.prepareStatement("SELECT NULL FROM " + DB.k_x_meeting_fellow + " WHERE " + DB.gu_meeting + "=? AND " + DB.gu_fellow + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1,getString(DB.gu_meeting));
    oStmt.setString(2,sAttendantId);
    oRSet = oStmt.executeQuery();
    bAttends = oRSet.next();
    oRSet.close();
    oStmt.close();

    if (bAttends) {
      sSQL = "UPDATE " + DB.k_x_meeting_fellow + " SET " + DB.dt_start + "=" + DBBind.escape(getTimestamp(DB.dt_start), "ts") + "," + DB.dt_end + "=" + DBBind.escape(getTimestamp(DB.dt_end), "ts") + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "' AND " + DB.gu_fellow + "='" + sAttendantId + "'";
      oExec = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
      oExec.executeUpdate(sSQL);
      oExec.close();

      oUpdt = oConn.createStatement();
      oUpdt.executeUpdate("UPDATE " + DB.k_meetings + " SET " + DB.dt_modified + "=" + DBBind.Functions.GETDATE + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
      oUpdt.close();
    }
    else {
      sSQL = "SELECT NULL FROM " + DB.k_x_meeting_contact + " WHERE " + DB.gu_meeting + "=? AND " + DB.gu_contact + "=?";
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement( " + sSQL + ")");
      oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1,getString(DB.gu_meeting));
      oStmt.setString(2,sAttendantId);
      oRSet = oStmt.executeQuery();
      bAttends = oRSet.next();
      oRSet.close();
      oStmt.close();

      if (bAttends) {
        sSQL = "UPDATE " + DB.k_x_meeting_contact + " SET " + DB.dt_start + "=" + DBBind.escape(getTimestamp(DB.dt_start), "ts") + "," + DB.dt_end + "=" + DBBind.escape(getTimestamp(DB.dt_end), "ts") + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "' AND " + DB.gu_contact + "='" + sAttendantId + "'";
        oExec = oConn.createStatement();
        if (DebugFile.trace) DebugFile.writeln("Statement.execute(" + sSQL + ")");
        oExec.executeUpdate(sSQL);
        oExec.close();

        oUpdt = oConn.createStatement();
        oUpdt.executeUpdate("UPDATE " + DB.k_meetings + " SET " + DB.dt_modified + "=" + DBBind.Functions.GETDATE + " WHERE " + DB.gu_meeting + "='" + getString(DB.gu_meeting) + "'");
        oUpdt.close();      }

      else {

		addAttendant(oConn, sAttendantId);

      }
    } // fi (bAttends)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Meeting.setAttendant()");
    }
  } // setAttendant

  /**
   * Make copies of this meeting
   * @param oConn JDCConnection
   * @param nDaysGap int Frecuency in days. One means that the meeting is repeated
   * daily for the number of specified times. Seven means that the meeting is repeated weekly.
   * Twenty eight is approximately once per month (every 4 weeks).
   * @param nTimes int Number of times to repeat the meeting
   * @throws SQLException
   * @throws IllegalArgumentException if nDaysGap<=0 or nTimes<0
   */
  public void repeat (JDCConnection oConn, int nDaysGap, int nTimes, boolean bSkipHolidays)
    throws SQLException,IllegalArgumentException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin Meeting.repeat([Connection], " + String.valueOf(nDaysGap) + "," + String.valueOf(nTimes) + ")");
      DebugFile.incIdent();
    }
    if (nDaysGap<=0) throw new IllegalArgumentException("Meeting.repeat() days gap must be an integer greater than zero");
    if (nTimes<0) throw new IllegalArgumentException("Meeting.repeat() days gap must be an integer greater than or equal to zero");
    final long lDaysGap = ((long) nDaysGap)*86400000l;
    Date dtStart, dtEnd;
    Meeting oClone = new Meeting();
    oClone.clone(this);
    DBSubset oConts = getContacts(oConn);
    DBSubset oFells = getFellows(oConn);
    DBSubset oRooms = getRooms(oConn);
    long lStart = getDate(DB.dt_start).getTime()+lDaysGap;
    long lEnd = getDate(DB.dt_end).getTime()+lDaysGap;
    for (int t=0; t<nTimes; t++) {
      dtStart = new Date(lStart);
      dtEnd = new Date(lEnd);
      oClone.replace(DB.gu_meeting, Gadgets.generateUUID());
      oClone.replace(DB.dt_start, dtStart);
      oClone.replace(DB.dt_end, dtEnd);
      // Skip Saturday and Sunday
      if (!bSkipHolidays || (dtStart.getDay()!=0 && dtStart.getDay()!=6)) {
        oClone.store(oConn);
        for (int c=0; c<oConts.getRowCount(); c++)
          oClone.setAttendant(oConn, oConts.getString(0,c));
        for (int f=0; f<oFells.getRowCount(); f++)
          oClone.setAttendant(oConn, oFells.getString(0,f));
        for (int r=0; r<oRooms.getRowCount(); r++)
         oClone.setRoom(oConn, oRooms.getString(0,r));
      } // fi (!bSkipHolidays || (getDay()!=0 && getDay()!=6))
      lStart += lDaysGap;
      lEnd += lDaysGap;
    } // next
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Meeting.repeat()");
    }
  } // repeat

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete Meeting</p>
   * Calls k_sp_del_meeting stored procedure
   * @param oConn Database Connection
   * @param sMeetingGUID Meeting Unique Identifier
   * @throws SQLException
   */

  public static boolean delete(JDCConnection oConn, String sMeetingGUID) throws SQLException {
    boolean bRetVal;

    CallableStatement oCall = oConn.prepareCall("{call k_sp_del_meeting ('" + sMeetingGUID + "')}");
    bRetVal = oCall.execute();
    oCall.close();

    return bRetVal;
  } // delete

  // **********************************************************
  // Public Constants

  public static final short ClassId = 21;
}
