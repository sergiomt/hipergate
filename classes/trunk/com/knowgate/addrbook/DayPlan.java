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

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;

/**
 * <p>A bidimensional array with daily scheduled meeting in quarters of an hour.</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

/*
   This class stores internally a bidimensional matrix that associates daily
   time slices with meetings having place at each slice. The association is
   stablished by first loading meetings for a given date and then building a
   list for each slice witch entries point to meetings having place at that
   slice.
   Lets say that there are four meetings in a day, one from 9:30 to 10:30
   [n 0], another from 10:00 to 10:30 [n 1], another from 11:00 to 12:00
   [n 2] and a last one from 11:45 to 12:30 [n 3].
   The internal array will then have this form:

   ... [slots from 00:00 up to 9:30]
   09:30 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           0     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   09:45 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           0     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   10:00 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           0        1     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   10:15 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           0        1     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   10:30 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
        (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   11:00 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           2     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   11:15 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           2     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   11:30 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           2     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   11:45 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           2        3     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   12:00 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           3     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)
   12:15 -----------------------------------------------------------------------
        slot 0 | slot 1 | slot 2 | slot 3 | slot 4 | slot 5 | slot 6 | slot 7
           3     (empty)  (empty)  (empty)  (empty)  (empty)  (empty)  (empty)

   ... [slots from 12:30:00 up to 23:45]

   This implies that there is a maximum of 8 concurrent meetings per slice.
   If there were more concurrent meeting the class shall not raise any error
   but will simply not show all of them.
*/

public class DayPlan {
  private int aMeetings[][];
  private DBSubset oMeetings;
  private Meeting oMeeting;

  private short MaxSlots = 8;   // Maximum allowed concurrent meetings per slot
  private short MaxSlices = 96; // Slices per day 96=24/4 -> slices of 15 mins.
  private final int EmptySlot = -1;
  private final long SliceLapsus = (24*3600*1000)/MaxSlices;

  /**
   * <p>Default constructor</p>
   * Creates a day plan with a maximun of eight concurrent meetings
   * and the day divided in 96 slices of 15 minutes each
   **/
  public DayPlan() {
    oMeeting = new Meeting();
    aMeetings = new int[MaxSlots][MaxSlices];
    for (int slice=0; slice<MaxSlices; slice++)
      for (int slot=0; slot<MaxSlots; slot++)
        aMeetings[slot][slice] = EmptySlot;
  } // DayPlan

  // ----------------------------------------------------------

  /**
   * <p>Constructor</p>
   * Creates a day plan dividing the day in 96 slices of 15 minutes each
   * @param iMaxConcurMeetingsiMaxConcurMeetings short Maximum concurrent meetings
   * @throws NegativeArraySizeException if iMaxConcurMeetings is less than one
   */
  public DayPlan(short iMaxConcurMeetings) throws NegativeArraySizeException {
  	if (iMaxConcurMeetings<=0)
  	  throw new NegativeArraySizeException ("DayPlan, maximum concurrent meetings may not be negative nor zero");
  	MaxSlots = iMaxConcurMeetings;
    oMeeting = new Meeting();
    aMeetings = new int[MaxSlots][MaxSlices];
    for (int slice=0; slice<MaxSlices; slice++)
      for (int slot=0; slot<MaxSlots; slot++)
        aMeetings[slot][slice] = EmptySlot;
  } // DayPlan

  // ----------------------------------------------------------

  /**
   * <p>Load scheduled meetings for a given Fellow.</p>
   * @param oConn Database Connection
   * @param iDomainId Domain Unique Identifier
   * @param sWorkAreaId WorkArea Global Unique Identifier
   * @param sFellowId Fellow Unique Identifier
   * @param dtToday Date for witch meeting are to be retrieved
   * @throws SQLException
   * @see {@link Fellow}
   * @since 4.0
   */
  public void loadMeetingsForFellow(JDCConnection oConn, int iDomainId, String sWorkAreaId, String sFellowId, java.util.Date dtToday) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DayPlan.loadMeetingsForFellow([Connection], " + sFellowId + "," + dtToday.toString() + ")");
      DebugFile.incIdent();
    }

	int mCount;
    long lToday = dtToday.getTime();
    java.util.Date zero = new java.util.Date(lToday);
    java.util.Date four = new java.util.Date(lToday);

    zero.setHours(0) ; zero.setMinutes(0) ; zero.setSeconds(0) ;
    zero.setTime((zero.getTime()/1000l)*1000l); // truncar los milisegundos

    four.setHours(23); four.setMinutes(59); four.setSeconds(59);

	if (null==sWorkAreaId) {
      oMeetings  = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
                                "m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.df_before + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ",m." + DB.de_meeting,
                                "m." + DB.id_domain + "=? AND " +
                                "m." + DB.gu_meeting +"=f." + DB.gu_meeting  + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + ">=" + DBBind.escape(zero, "ts") + " AND m." + DB.dt_start + "< " + DBBind.escape(four, "ts") + " ORDER BY m."+  DB.dt_start, 8);

      mCount = oMeetings.load(oConn, new Object[] { new Integer(iDomainId), sFellowId });
	} else {
      oMeetings  = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
                                "m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.df_before + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ",m." + DB.de_meeting,
                                "m." + DB.id_domain + "=? AND m." + DB.gu_workarea + "=? AND " +
                                "m." + DB.gu_meeting +"=f." + DB.gu_meeting  + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + ">=" + DBBind.escape(zero, "ts") + " AND m." + DB.dt_start + "< " + DBBind.escape(four, "ts") + " ORDER BY m."+  DB.dt_start, 8);

      mCount = oMeetings.load(oConn, new Object[] { new Integer(iDomainId), sWorkAreaId, sFellowId });
	}

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(mCount) + " meetings found");

    long dtStart, dtEnd, dtSliceBegin, dtZero = zero.getTime();

    for (int meeting=0; meeting<mCount; meeting++) {
      dtStart = oMeetings.getDate(2,meeting).getTime();
      dtEnd = oMeetings.getDate(3,meeting).getTime();

      dtSliceBegin = dtZero;
      for (int slice=0; slice<MaxSlices; slice++) {
        if ((dtStart>=dtSliceBegin && dtStart<dtSliceBegin+SliceLapsus) ||
            (dtStart<dtSliceBegin && dtEnd>dtSliceBegin+SliceLapsus))
          for (int slot=0; slot<MaxSlots; slot++)
            if (EmptySlot==aMeetings[slot][slice]) {
              if (DebugFile.trace) {
                DebugFile.writeln("set slot[" + String.valueOf(slot) + "][" + String.valueOf(slice) + "] to meeting " + String.valueOf(meeting) + " " + oMeetings.getStringNull(7,meeting,""));
                DebugFile.writeln("dtStart=" + new Date(dtStart).toString() + "(" + String.valueOf(dtStart) + "ms)");
                DebugFile.writeln("dtEnd=" + new Date(dtEnd).toString() + "(" + String.valueOf(dtEnd) + "ms)");
                DebugFile.writeln("dtSliceBegin=" + new Date(dtSliceBegin).toString() + "(" + String.valueOf(dtSliceBegin) + "ms)");
                DebugFile.writeln("dtSliceNext=" + new Date(dtSliceBegin+SliceLapsus).toString() + "(" + String.valueOf(dtSliceBegin+SliceLapsus) + "ms)");
              }
              aMeetings[slot][slice] = meeting;
              break;
            } // fi (aMeetings[slot][slice])
        dtSliceBegin += SliceLapsus;
      } // next (slice)
    } // next(meeting)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DayPlan.loadMeetingsForFellow()");
    }
  } // loadMeetingsForFellow

  // ----------------------------------------------------------

  /**
   * <p>Load scheduled meetings for a given Room.</p>
   * @param oConn Database Connection
   * @param iDomainId Domain Unique Identifier
   * @param sWorkAreaId WorkArea Global Unique Identifier
   * @param sNmRoom Room Name
   * @param dtToday Date for witch meeting are to be retrieved
   * @throws SQLException
   * @see {@link Fellow}
   * @since 4.0
   */
  public void loadMeetingsForRoom(JDCConnection oConn, int iDomainId, String sWorkAreaId, String sNmRoom, java.util.Date dtToday) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DayPlan.loadMeetingsForRoom([Connection], " + sNmRoom + "," + dtToday.toString() + ")");
      DebugFile.incIdent();
    }

    long lToday = dtToday.getTime();
    java.util.Date zero = new java.util.Date(lToday);
    java.util.Date four = new java.util.Date(lToday);

    zero.setHours(0) ; zero.setMinutes(0) ; zero.setSeconds(0) ;
    zero.setTime((zero.getTime()/1000l)*1000l); // truncar los milisegundos

    four.setHours(23); four.setMinutes(59); four.setSeconds(59);

    oMeetings  = new DBSubset(DB.k_meetings + " m",
                              "m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.df_before + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ",m." + DB.de_meeting,
                              "m." + DB.id_domain + "=? AND " + DB.gu_workarea + "=? AND " +
                              "m." + DB.dt_start + ">=" + DBBind.escape(zero, "ts") + " AND m." + DB.dt_start + "< " + DBBind.escape(four, "ts") + " AND " +
	  						  "m." + DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_x_meeting_room+" WHERE "+DB.nm_room+"=?)" +
                              
                              "ORDER BY m."+  DB.dt_start, 8);

    int mCount = oMeetings.load(oConn, new Object[] { new Integer(iDomainId), sWorkAreaId, sNmRoom });

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(mCount) + " meetings found");

    long dtStart, dtEnd, dtSliceBegin, dtZero = zero.getTime();

    for (int meeting=0; meeting<mCount; meeting++) {
      dtStart = oMeetings.getDate(2,meeting).getTime();
      dtEnd = oMeetings.getDate(3,meeting).getTime();

      dtSliceBegin = dtZero;
      for (int slice=0; slice<MaxSlices; slice++) {
        if ((dtStart>=dtSliceBegin && dtStart<dtSliceBegin+SliceLapsus) ||
            (dtStart<dtSliceBegin && dtEnd>dtSliceBegin+SliceLapsus))
          for (int slot=0; slot<MaxSlots; slot++)
            if (EmptySlot==aMeetings[slot][slice]) {
              if (DebugFile.trace) {
                DebugFile.writeln("set slot[" + String.valueOf(slot) + "][" + String.valueOf(slice) + "] to meeting " + String.valueOf(meeting) + " " + oMeetings.getStringNull(7,meeting,""));
                DebugFile.writeln("dtStart=" + new Date(dtStart).toString() + "(" + String.valueOf(dtStart) + "ms)");
                DebugFile.writeln("dtEnd=" + new Date(dtEnd).toString() + "(" + String.valueOf(dtEnd) + "ms)");
                DebugFile.writeln("dtSliceBegin=" + new Date(dtSliceBegin).toString() + "(" + String.valueOf(dtSliceBegin) + "ms)");
                DebugFile.writeln("dtSliceNext=" + new Date(dtSliceBegin+SliceLapsus).toString() + "(" + String.valueOf(dtSliceBegin+SliceLapsus) + "ms)");
              }
              aMeetings[slot][slice] = meeting;
              break;
            } // fi (aMeetings[slot][slice])
        dtSliceBegin += SliceLapsus;
      } // next (slice)
    } // next(meeting)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DayPlan.loadMeetingsForRoom()");
    }
  } // loadMeetingsForRoom

  // ----------------------------------------------------------

  /**
   * <p>Load scheduled meetings for a given Address.</p>
   * @param oConn Database Connection
   * @param iDomainId Domain Unique Identifier
   * @param sWorkAreaId WorkArea Global Unique Identifier
   * @param sAddressId Address Global Unique Identifier
   * @param dtToday Date for witch meeting are to be retrieved
   * @throws SQLException
   * @see {@link Fellow}
   * @since 4.0
   */
  public void loadMeetingsForAddress(JDCConnection oConn, int iDomainId, String sWorkAreaId, String sAddressId, java.util.Date dtToday) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DayPlan.loadMeetingsForAddress([Connection], " + sAddressId + "," + dtToday.toString() + ")");
      DebugFile.incIdent();
    }

    long lToday = dtToday.getTime();
    java.util.Date zero = new java.util.Date(lToday);
    java.util.Date four = new java.util.Date(lToday);

    zero.setHours(0) ; zero.setMinutes(0) ; zero.setSeconds(0) ;
    zero.setTime((zero.getTime()/1000l)*1000l); // truncar los milisegundos

    four.setHours(23); four.setMinutes(59); four.setSeconds(59);

    oMeetings  = new DBSubset(DB.k_meetings + " m",
                              "m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.df_before + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ",m." + DB.de_meeting,
                              "m." + DB.id_domain + "=? AND " + DB.gu_workarea + "=? AND m." + DB.gu_address + "=? AND " +
                              "m." + DB.dt_start + ">=" + DBBind.escape(zero, "ts") + " AND m." + DB.dt_start + "< " + DBBind.escape(four, "ts") + " AND " +                              
                              "ORDER BY m."+  DB.dt_start, 8);

    int mCount = oMeetings.load(oConn, new Object[] { new Integer(iDomainId), sWorkAreaId, sAddressId });

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(mCount) + " meetings found");

    long dtStart, dtEnd, dtSliceBegin, dtZero = zero.getTime();

    for (int meeting=0; meeting<mCount; meeting++) {
      dtStart = oMeetings.getDate(2,meeting).getTime();
      dtEnd = oMeetings.getDate(3,meeting).getTime();

      dtSliceBegin = dtZero;
      for (int slice=0; slice<MaxSlices; slice++) {
        if ((dtStart>=dtSliceBegin && dtStart<dtSliceBegin+SliceLapsus) ||
            (dtStart<dtSliceBegin && dtEnd>dtSliceBegin+SliceLapsus))
          for (int slot=0; slot<MaxSlots; slot++)
            if (EmptySlot==aMeetings[slot][slice]) {
              if (DebugFile.trace) {
                DebugFile.writeln("set slot[" + String.valueOf(slot) + "][" + String.valueOf(slice) + "] to meeting " + String.valueOf(meeting) + " " + oMeetings.getStringNull(7,meeting,""));
                DebugFile.writeln("dtStart=" + new Date(dtStart).toString() + "(" + String.valueOf(dtStart) + "ms)");
                DebugFile.writeln("dtEnd=" + new Date(dtEnd).toString() + "(" + String.valueOf(dtEnd) + "ms)");
                DebugFile.writeln("dtSliceBegin=" + new Date(dtSliceBegin).toString() + "(" + String.valueOf(dtSliceBegin) + "ms)");
                DebugFile.writeln("dtSliceNext=" + new Date(dtSliceBegin+SliceLapsus).toString() + "(" + String.valueOf(dtSliceBegin+SliceLapsus) + "ms)");
              }
              aMeetings[slot][slice] = meeting;
              break;
            } // fi (aMeetings[slot][slice])
        dtSliceBegin += SliceLapsus;
      } // next (slice)
    } // next(meeting)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DayPlan.loadMeetingsForAddress()");
    }
  } // loadMeetingsForAddress


  // ----------------------------------------------------------

  /**
   * <p>A shortcut for load scheduled meetings for a given Fellow.</p>
   * @param oConn Database Connection
   * @param sFellowId Fellow Unique Identifier
   * @param dtToday Date for witch meeting are to be retrieved
   * @throws SQLException
   * @see {@link Fellow}
   */

  public void load(JDCConnection oConn, String sFellowId, java.util.Date dtToday) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DayPlan.load([Connection], " + sFellowId + "," + dtToday.toString() + ")");
      DebugFile.incIdent();
    }

    long lToday = dtToday.getTime();
    java.util.Date zero = new java.util.Date(lToday);
    java.util.Date four = new java.util.Date(lToday);

    zero.setHours(0) ; zero.setMinutes(0) ; zero.setSeconds(0) ;
    zero.setTime((zero.getTime()/1000l)*1000l); // truncar los milisegundos

    four.setHours(23); four.setMinutes(59); four.setSeconds(59);

    oMeetings  = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
                              "m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.df_before + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ",m." + DB.de_meeting,
                              "m." + DB.gu_meeting +"=f." + DB.gu_meeting  + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + ">=" + DBBind.escape(zero, "ts") + " AND m." + DB.dt_start + "< " + DBBind.escape(four, "ts") + " ORDER BY m."+  DB.dt_start, 8);

    int mCount = oMeetings.load(oConn, new Object[] { sFellowId });

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(mCount) + " meetings found");

    long dtStart, dtEnd, dtSliceBegin, dtZero = zero.getTime();

    for (int meeting=0; meeting<mCount; meeting++) {
      dtStart = oMeetings.getDate(2,meeting).getTime();
      dtEnd = oMeetings.getDate(3,meeting).getTime();

      dtSliceBegin = dtZero;
      for (int slice=0; slice<MaxSlices; slice++) {
        if ((dtStart>=dtSliceBegin && dtStart<dtSliceBegin+SliceLapsus) ||
            (dtStart<dtSliceBegin && dtEnd>dtSliceBegin+SliceLapsus))
          for (int slot=0; slot<MaxSlots; slot++)
            if (EmptySlot==aMeetings[slot][slice]) {
              if (DebugFile.trace) {
                DebugFile.writeln("set slot[" + String.valueOf(slot) + "][" + String.valueOf(slice) + "] to meeting " + String.valueOf(meeting) + " " + oMeetings.getStringNull(7,meeting,""));
                DebugFile.writeln("dtStart=" + new Date(dtStart).toString() + "(" + String.valueOf(dtStart) + "ms)");
                DebugFile.writeln("dtEnd=" + new Date(dtEnd).toString() + "(" + String.valueOf(dtEnd) + "ms)");
                DebugFile.writeln("dtSliceBegin=" + new Date(dtSliceBegin).toString() + "(" + String.valueOf(dtSliceBegin) + "ms)");
                DebugFile.writeln("dtSliceNext=" + new Date(dtSliceBegin+SliceLapsus).toString() + "(" + String.valueOf(dtSliceBegin+SliceLapsus) + "ms)");
              }
              aMeetings[slot][slice] = meeting;
              break;
            } // fi (aMeetings[slot][slice])
        dtSliceBegin += SliceLapsus;
      } // next (slice)
    } // next(meeting)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DayPlan.load()");
    }
  } // load

  // ----------------------------------------------------------

  /**
   * <p>Slice count per day.</p>
   * <p>96 is the default and equals a day divided in 15 minutes slices</p>
   * @return Maximum number of slices per day
   */
  public int sliceCount() {
    return MaxSlices;
  }

  // ----------------------------------------------------------

  /**
   * @return Maximum number of allowed concurrent meetings per day slice
   */
  public int slotsPerSlice() {
    return MaxSlots;
  }

  // ----------------------------------------------------------

  /**
   * <p>Get count of concurrent meetings at a given slice</p>
   * @param slice [0...sliceCount()-1]
   * @throws ArrayIndexOutOfBoundsException If slice<0 or slice>=sliceCount()
   */

  public int concurrentMeetings(int slice) throws ArrayIndexOutOfBoundsException {
    int slots = 0;

    do {
      if (EmptySlot!=aMeetings[slots][slice])
        slots++;
      else
        break;
    }
    while (slots < MaxSlots);

    return slots;
  } // concurrentMeetings

  // ----------------------------------------------------------

  /**
   * <p>Get meeting information</p>
   * <p>Each meeting is asoociated with one or more day slices by having a list
   * at the slice that point to every meeting taking place on the slice.</p>
   * <p>Thus for retriving a meeting both the slice number and the relative ordinal
   * position of the meeting at the slice are needed.</p>
   * @param slice [0...sliceCount()-1]
   * @param slot [0...slotsPerSlice()-1]
   * @throws ArrayIndexOutOfBoundsException If slice<0 or slice>=sliceCount() or slot<0 or slot>=slotsPerSlice()
   * @return {@link Meeting} or <b>null</b> if no meeting was found at the given (slice,slot) pair.
   */
  public Meeting getMeeting(int slice, int slot) throws ArrayIndexOutOfBoundsException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DayPlan.getMeeting(" + String.valueOf(slice) + "," + String.valueOf(slot) + ")");
    }

    if (slice>=MaxSlices || slot>=MaxSlots) return null;

    int iMeeting = aMeetings[slot][slice];

    if (DebugFile.trace) DebugFile.writeln("iMeeting=" + String.valueOf(iMeeting));

    if (-1==iMeeting) return null;

    oMeeting.clear();

    if (DebugFile.trace) DebugFile.writeln("Meeting object cleared");

    oMeeting.put(DB.gu_meeting, oMeetings.getString(0,iMeeting));
    oMeeting.put(DB.gu_fellow,  oMeetings.getString(1,iMeeting));
    oMeeting.put(DB.dt_start,   oMeetings.getDate  (2,iMeeting));
    oMeeting.put(DB.dt_end,     oMeetings.getDate  (3,iMeeting));

    if (DebugFile.trace)
      if (oMeetings.getShort (4,iMeeting)!=(short)0)
        DebugFile.writeln("meeting is private");

    oMeeting.put(DB.bo_private, oMeetings.getShort (4,iMeeting));

    if (!oMeetings.isNull(5,iMeeting))
      oMeeting.put(DB.df_before,  oMeetings.getInt   (5,iMeeting));
    if (!oMeetings.isNull(6,iMeeting))
      oMeeting.put(DB.tp_meeting, oMeetings.getString(6,iMeeting));
    oMeeting.put(DB.tx_meeting, oMeetings.getStringNull(7,iMeeting,""));
    oMeeting.put(DB.de_meeting, oMeetings.getStringNull(8,iMeeting,""));

    if (DebugFile.trace) {
      DebugFile.writeln("End DayPlan.getMeeting() : " + oMeetings.getString(0,iMeeting));
    }

    return oMeeting;
  } // getMeeting()

  // ----------------------------------------------------------

  /**
   * <p>Lookup a meeting given its unique identifier</p>
   * @param sMeeting Meeting Unique Identifier
   * @return {@link Meeting} or <b>null</b> if no meeting was found with given identifier.
   */
  public Meeting seekMeeting(String sMeeting) {
    int iMeetings = oMeetings.getRowCount();

    for (int m=0; m<iMeetings; m++) {
      if (sMeeting.equals(oMeetings.getString(0, m))) {
        oMeeting.clear();

        oMeeting.put(DB.gu_meeting, oMeetings.getString(0,m));
        oMeeting.put(DB.gu_fellow,  oMeetings.getString(1,m));
        oMeeting.put(DB.dt_start,   oMeetings.getDate  (2,m));
        oMeeting.put(DB.dt_end,     oMeetings.getDate  (3,m));
        oMeeting.put(DB.bo_private, oMeetings.getShort (4,m));
        if (!oMeetings.isNull(5,m))
          oMeeting.put(DB.df_before,  oMeetings.getInt   (5,m));
        if (!oMeetings.isNull(6,m))
          oMeeting.put(DB.tp_meeting, oMeetings.getString(6,m));
        oMeeting.put(DB.tx_meeting, oMeetings.getStringNull(7,m,""));
        oMeeting.put(DB.de_meeting, oMeetings.getStringNull(8,m,""));

        return oMeeting;
      }
    }
    return null;
  } // seekMeeting
} // DayPlay