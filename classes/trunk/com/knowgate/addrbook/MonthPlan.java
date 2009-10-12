/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

import java.util.Enumeration;
import java.util.NoSuchElementException;

import com.knowgate.addrbook.Meeting;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Calendar;
import com.knowgate.misc.Month;

/**
 * Enumeration of meetings for a given month
 */
 
public class MonthPlan implements Enumeration<Meeting> {

  private DBSubset oMeetings;
  private int iMeetCount;
  private int iIterator;
  private Month oThisMonth;
  private final long lOneDayMilis = 24l*60l*60l*1000l;
    
  public MonthPlan() {
  	oThisMonth = null;
  	oMeetings = null;
    iMeetCount = 0;
    iIterator = 2147483647;
  }
  
  /**
   * @return Date of first day of the month
   */
  public Date firstDay() {
  	return oThisMonth.firstDay();
  }

  /**
   * @return Date of last day of the month
   */
  
  public Date lastDay() {
  	return oThisMonth.lastDay();
  }

  /**
   * @return Date of first day of next month
   */
  public Date nextMonth() {
  	return new Date(firstDay().getTime()+(((long)Calendar.LastDay(oThisMonth.getMonth(),oThisMonth.getYear()+1900))*lOneDayMilis));
  }

  /**
   * @return <b>true</b> if the given month day [1..31] has any mettings
   * @since 5.0
   */

  public boolean hasAnyMeeting(int nMonthDay) {
	boolean bHasMeetings = false;
	long lDay = new Date(this.firstDay().getTime()+((long) nMonthDay-1)*lOneDayMilis).getTime();
    int m = 0;
    while (m<iMeetCount && oMeetings.getDate(1,m).getTime()<lDay) m++;
	lDay += lOneDayMilis;
	if (m<iMeetCount) {
	  bHasMeetings = oMeetings.getDate(1,m).getTime()<lDay;
	}
	return bHasMeetings;
  } // hasAnyMeeting

  /**
   * Load meetings for a Fellow
   * @param oConn JDCConnection
   * @param iDomainId int Domain Id.
   * @param sWorkAreaId Work Area GUID
   * @param sFellowId Fellow GUID
   * @param iYearMinus1900 int Desired year minus 1900
   * @param iMonthZeroBased int Desired month (zero based) [0..11]
   * @throws SQLException
   * @return Total number of meetings in given month
   */

  public int loadMeetingsForFellow(JDCConnection oConn, int iDomainId, String sWorkAreaId,
                                   String sFellowId, int iYearMinus1900, int iMonthZeroBased)
    throws SQLException {
  
    oThisMonth = new Month(iYearMinus1900, iMonthZeroBased);
    
    oMeetings = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
    			"m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.dt_end,
				"m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND "+
    			"f." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN " + DBBind.escape(firstDay(), "d") + " AND " + DBBind.escape(nextMonth(), "d") + " ORDER BY 2", 60);

    iMeetCount = oMeetings.load(oConn, new Object[]{new Integer(iDomainId), sWorkAreaId, sFellowId});    

    iIterator = 0;

    return iMeetCount;
  } // loadMeetingsForFellow

  /**
   * Load meetings taking place at a Room
   * @param oConn JDCConnection
   * @param iDomainId int Domain Id.
   * @param sWorkAreaId Work Area GUID
   * @param sFellowId Fellow GUID
   * @param iYearMinus1900 int Desired year minus 1900
   * @param iMonthZeroBased int Desired month (zero based) [0..11]
   * @throws SQLException
   * @return Total number of meetings in given month
   */
  
  public int loadMeetingsForRoom(JDCConnection oConn, int iDomainId, String sWorkAreaId,
                                 String sRoomNm, int iYearMinus1900, int iMonthZeroBased)
    throws SQLException {
  
    oThisMonth = new Month(iYearMinus1900, iMonthZeroBased);
    
    oMeetings = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_room + " f",
    			"m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.dt_end,
				"m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND "+
    			"f." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND f." + DB.nm_room + "=? AND m." + DB.dt_start + " BETWEEN " + DBBind.escape(firstDay(), "d") + " AND " + DBBind.escape(nextMonth(), "d") + " ORDER BY 2", 60);

    iMeetCount = oMeetings.load(oConn, new Object[]{new Integer(iDomainId), sWorkAreaId, sRoomNm});

    iIterator = 0;

    return iMeetCount;
  } // loadMeetingsForRoom

  /**
   * Load meetings taking place at an Address
   * @param oConn JDCConnection
   * @param iDomainId int Domain Id.
   * @param sWorkAreaId Work Area GUID
   * @param sAddrId Address GUID
   * @param iYearMinus1900 int Desired year minus 1900
   * @param iMonthZeroBased int Desired month (zero based) [0..11]
   * @throws SQLException
   * @return Total number of meetings in given month
   */

  public int loadMeetingsForAddress(JDCConnection oConn, int iDomainId, String sWorkAreaId,
                                    String sAddrId, int iYearMinus1900, int iMonthZeroBased)
    throws SQLException {
  
    oThisMonth = new Month(iYearMinus1900, iMonthZeroBased);
    
    oMeetings = new DBSubset(DB.k_meetings + " m",
    			"m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.dt_end,
				"m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND "+
    			"m." + DB.gu_address + "=? AND m." + DB.dt_start + " BETWEEN " + DBBind.escape(firstDay(), "d") + " AND " + DBBind.escape(nextMonth(), "d") + " ORDER BY 2", 60);

    iMeetCount = oMeetings.load(oConn, new Object[]{new Integer(iDomainId), sWorkAreaId, sAddrId});    

    iIterator = 0;

    return iMeetCount;
  } // loadMeetingsForAddress
  
  public boolean hasMoreElements() {
    return iIterator < iMeetCount;
  }

  public Meeting nextElement() throws NoSuchElementException {
    if (iIterator>=iMeetCount) throw new NoSuchElementException("MonthPlan.nextElement()");
	Meeting oMeet = new Meeting(getMeetingGuid(iIterator));
	oMeet.put(DB.tx_meeting, getMeetingTitle(iIterator));
	oMeet.put(DB.dt_start, getMeetingStart(iIterator));
	oMeet.put(DB.dt_end, getMeetingEnd(iIterator));
	oMeet.put(DB.bo_private, isMeetingPrivate(iIterator));
    iIterator++;
    return oMeet;
  }
  
  public String getMeetingGuid(int nMeeting) {
  	return oMeetings.getString(0, nMeeting);
  }

  public String getMeetingTitle(int nMeeting) {
  	return oMeetings.getStringNull(3, nMeeting, "");
  }

  public Date getMeetingStart(int nMeeting) {
  	return oMeetings.getDate(1, nMeeting);
  }

  public Date getMeetingEnd(int nMeeting) {
  	return oMeetings.getDate(4, nMeeting);
  }

  public boolean isMeetingPrivate(int nMeeting) {
  	return (oMeetings.getShort(2, nMeeting)!=(short) 0);
  }
  
} // MonthPlan
