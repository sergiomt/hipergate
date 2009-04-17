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
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

/**
 * <p>Meeting Room or other type of Resource used at Meeting</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class Room extends DBPersist {
  public Room() {
    super(DB.k_rooms, "Room");
  }

  // ----------------------------------------------------------

  /**
   * Load Room
   * @param oConn JDCConnection
   * @param sNmRoom String Room name
   * @param sGuWorkArea String WorkArea Guid
   * @return boolean
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object sNmRoom, Object sGuWorkArea) throws SQLException {
    Object oCol;
    clear();
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.id_domain+","+DB.bo_available+","+DB.tp_room+","+DB.nu_capacity+","+DB.tx_company+","+DB.tx_location+","+DB.tx_comments+
    						  " FROM "+DB.k_rooms+ " WHERE "+DB.nm_room+"=? AND "+DB.gu_workarea+"=?",
                              ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setObject(1, sNmRoom, Types.VARCHAR);
    oStmt.setObject(2, sGuWorkArea, Types.CHAR);
    ResultSet oRSet = oStmt.executeQuery();
    boolean bRetVal = oRSet.next();
    if (bRetVal) {
      put(DB.nm_room, sNmRoom);
      put(DB.gu_workarea, sGuWorkArea);
      put(DB.id_domain, oRSet.getInt(1));
      put(DB.bo_available, oRSet.getShort(2));
      oCol = oRSet.getObject(3);
      if (!oRSet.wasNull()) put(DB.tp_room, oCol);
      oCol = oRSet.getObject(4);
      if (!oRSet.wasNull()) put(DB.nu_capacity, oCol);
      oCol = oRSet.getObject(5);
      if (!oRSet.wasNull()) put(DB.tx_company, oCol);
      oCol = oRSet.getObject(6);
      if (!oRSet.wasNull()) put(DB.tx_location, oCol);
      oCol = oRSet.getObject(7);
      if (!oRSet.wasNull()) put(DB.tx_comments, oCol);
    }
    oRSet.close();
    oStmt.close();
    return bRetVal;
  } // load

  // ----------------------------------------------------------

  /**
   * Load Room
   * @param oConn JDCConnection
   * @param NmRoomGuWrkA Object[] { Room Name, WorkArea Guid}
   * @return boolean
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] NmRoomGuWrkA)
    throws SQLException {
    return load(oConn, NmRoomGuWrkA[0], NmRoomGuWrkA[1]);
  }

  // ----------------------------------------------------------

  public boolean delete(JDCConnection oConn) throws SQLException {

    return Room.delete(oConn, getString(DB.nm_room), getString(DB.gu_workarea));
  }

  // ----------------------------------------------------------

  /**
   * Get meeting that takes place at this room on given dates
   * @param oConn JDCConnection
   * @param dtFrom Date From
   * @param dtTo Date To
   * @return String GUID of meeting taking place or <b>null</b> if room is available at that time.
   * @throws SQLException
   * @since 3.0
   */
  public String getMeetingForDate(JDCConnection oConn, Date dtFrom, Date dtTo)
    throws SQLException {
    String sGuMeeting;
    Timestamp tsFrom = new Timestamp(dtFrom.getTime());
    Timestamp tsTo = new Timestamp(dtTo.getTime());
    PreparedStatement oStmt = oConn.prepareStatement("SELECT x."+DB.gu_meeting+" FROM "+
      DB.k_rooms+" r,"+DB.k_x_meeting_room+" x WHERE r."+DB.nm_room+"=x."+DB.nm_room+
      " AND r."+DB.gu_workarea+"=? AND r."+DB.nm_room+"=? AND (x."+DB.dt_start+" BETWEEN ? AND ?"+
      "OR x."+DB.dt_end+" BETWEEN ? AND ? OR (x."+DB.dt_start+"<=? AND x."+DB.dt_end+">=?))",
      ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, getString(DB.gu_workarea));
    oStmt.setString(2, getString(DB.nm_room));
    oStmt.setTimestamp(3, tsFrom);
    oStmt.setTimestamp(4, tsTo);
    oStmt.setTimestamp(5, tsFrom);
    oStmt.setTimestamp(6, tsTo);
    oStmt.setTimestamp(7, tsFrom);
    oStmt.setTimestamp(8, tsTo);
    ResultSet oRset = oStmt.executeQuery();
    if (oRset.next())
      sGuMeeting = oRset.getString(1);
    else
      sGuMeeting = null;
    oRset.close();
    oStmt.close();
    return sGuMeeting;
  } // available

  // ----------------------------------------------------------

  /**
   * Check whether or not this room is available between two dates
   * @param oConn JDCConnection
   * @param dtFrom Date From
   * @param dtTo Date To
   * @return boolean <b>true</b> if room is available on given dates, <b>false</b> otherwise.
   * @throws SQLException
   * @since 3.0
   */
  public boolean isAvailable(JDCConnection oConn, Date dtFrom, Date dtTo)
    throws SQLException {
      return (getMeetingForDate(oConn, dtFrom, dtTo)==null);
    }

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete Room</p>
   * Calls k_sp_del_room stored procedure
   * @param oConn Database Connection
   * @param sRoomNm Room Name
   * @param sWrkAId Identifier of {@link WorkArea} to witch Room belongs
   * @throws SQLException
   */

  public static boolean delete(JDCConnection oConn, String sRoomNm, String sWrkAId) throws SQLException {
    boolean bRetVal;

    CallableStatement oCall = oConn.prepareCall("{call k_sp_del_room ('" + sRoomNm + "','" + sWrkAId + "')}");
    bRetVal = oCall.execute();
    oCall.close();

    return bRetVal;
  } // delete

  // **********************************************************
  // Variables Privadas

  public static final short ClassId = 21;

} // Room
