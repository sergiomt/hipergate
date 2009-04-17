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

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Calendar;

public class MonthPlan {

  private DBSubset oMeetings;
  private int iMeetCount;
  
  private Date dtFirstDay, dtLastDay, dtNextMonth;
    
  public MonthPlan() { 
    iMeetCount = 0;    
  }
  
  private void setDays (int iYearMinus1900, int iMonthZeroBased)  {
  	final long lOneDayMilis = 24l*60l*60l*1000l;
    dtFirstDay = new Date(iYearMinus1900, iMonthZeroBased, 1);
    dtNextMonth = new Date(dtFirstDay.getTime()+(((long)Calendar.LastDay(iMonthZeroBased,iYearMinus1900+1900))*lOneDayMilis));
    dtLastDay = new Date(dtNextMonth.getTime()-lOneDayMilis);
  }

  public Date firstDay() {
  	return dtFirstDay;
  }
  
  public Date lastDay() {
  	return dtLastDay;
  }

  public Date nextMonth() {
  	return dtNextMonth;
  }

  public int loadMeetingsForFellow(JDCConnection oConn, int iDomainId, String sWorkAreaId,
                                   String sFellowId, int iYearMinus1900, int iMonthZeroBased)
    throws SQLException {
  
    setDays (iYearMinus1900, iMonthZeroBased);
    
    oMeetings = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
    			"m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.dt_end,
				"m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND "+
    			"f." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN " + DBBind.escape(dtFirstDay, "d") + " AND " + DBBind.escape(dtNextMonth, "d") + " ORDER BY 2", 60);

    iMeetCount = oMeetings.load(oConn, new Object[]{new Integer(iDomainId), sWorkAreaId, sFellowId});    

    return iMeetCount;
  } // loadMeetingsForFellow
  
  public int loadMeetingsForRoom(JDCConnection oConn, int iDomainId, String sWorkAreaId,
                                 String sRoomNm, int iYearMinus1900, int iMonthZeroBased)
    throws SQLException {
  
    setDays (iYearMinus1900, iMonthZeroBased);
    
    oMeetings = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_room + " f",
    			"m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.dt_end,
				"m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND "+
    			"f." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND f." + DB.nm_room + "=? AND m." + DB.dt_start + " BETWEEN " + DBBind.escape(dtFirstDay, "d") + " AND " + DBBind.escape(dtNextMonth, "d") + " ORDER BY 2", 60);

    iMeetCount = oMeetings.load(oConn, new Object[]{new Integer(iDomainId), sWorkAreaId, sRoomNm});

    return iMeetCount;
  } // loadMeetingsForRoom

  public int loadMeetingsForAddress(JDCConnection oConn, int iDomainId, String sWorkAreaId,
                                    String sAddrId, int iYearMinus1900, int iMonthZeroBased)
    throws SQLException {
  
    setDays (iYearMinus1900, iMonthZeroBased);
    
    oMeetings = new DBSubset(DB.k_meetings + " m",
    			"m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.dt_end,
				"m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND "+
    			"m." + DB.gu_address + "=? AND m." + DB.dt_start + " BETWEEN " + DBBind.escape(dtFirstDay, "d") + " AND " + DBBind.escape(dtNextMonth, "d") + " ORDER BY 2", 60);

    iMeetCount = oMeetings.load(oConn, new Object[]{new Integer(iDomainId), sWorkAreaId, sAddrId});    

    return iMeetCount;
  } // loadMeetingsForAddress
  
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
