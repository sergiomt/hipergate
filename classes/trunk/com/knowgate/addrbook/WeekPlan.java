/*
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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
import java.sql.Time;
import java.sql.Timestamp;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.hipergate.Address;

/**
 * <p>Class for getting meetings of a week dividing each day in two halfs (morning and afternoon)</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */
 
public class WeekPlan {

    private static final long WeekMilis = 604800000l;
    
    private Time oMddyTime;	
	private DBSubset oMeetings;
    private int nMeetings;
    private Date dtFrom;
    private Integer oDomainId;
    private String sWorkAreaGuid;
    
    // ------------------------------------------------------------------------

    /**
     * Create empty WeekPlan and set midday time to 14:00
     * @param Id of domain for restricting meeting search
     */	
	public WeekPlan(int iIdDomain, Date dtFirstDate) {
	  oMeetings = null;
	  nMeetings = 0;
	  oMddyTime = new Time(14,0,0);
	  oDomainId = new Integer (iIdDomain);
	  sWorkAreaGuid = null;
	  dtFrom = dtFirstDate;
	}

    /**
     * Create empty WeekPlan and set midday time to 14:00
     * @param Id of domain for restricting meeting search
     * @param GUID of WorkArea for restricting meeting search
     */	
	public WeekPlan(int iIdDomain, String sGuWorkArea, Date dtFirstDate) {
	  oMeetings = null;
	  nMeetings = 0;
	  oMddyTime = new Time(14,0,0);
	  oDomainId = new Integer (iIdDomain);
	  sWorkAreaGuid = sGuWorkArea;
	  dtFrom = dtFirstDate;
	}

    // ------------------------------------------------------------------------

    /**
     * Get time used to split day between morning and afternoon
     * @return java.sql.Time
     */
	public Time getMiddayTime() {
	  return oMddyTime;
	}

    // ------------------------------------------------------------------------

    /**
     * Get time used to split day between morning and afternoon
     * @return int Hours and minutes are expressed as HHMM being HH[00-23] and MM[00-59]
     */
	public int getMiddayHoursAndMinutes() {
	  return (oMddyTime.getHours()*100)+oMddyTime.getMinutes();
	}

    // ------------------------------------------------------------------------

	public void setMiddayTime(Time oMidday) {
	  oMddyTime = oMidday;
	}

    // ------------------------------------------------------------------------

	public void setMiddayTime(int iHour, int iMinute) {
	  oMddyTime = new Time(iHour,iMinute,0);
	}

    // ------------------------------------------------------------------------

    /**
     * Load meetings organized by the given fellow from the given date and seven days ahead
     * @param oConn JDCConnection
     * @param sGuFellow GUID of Fellow organizing or attending the Meeting
     * @return Count of meetings loaded
     */
	public int loadMeetingsForFellow(JDCConnection oConn, String sGuFellow)
	  throws SQLException {

	  if (DebugFile.trace) {
	  	DebugFile.writeln("Begin WeekPlan.loadMeetingsForFellow([JDCConnection], "+sGuFellow+")");
	  	DebugFile.incIdent();	  	
	  }

	  Timestamp dtFirst = new Timestamp(dtFrom.getYear(),dtFrom.getMonth(),dtFrom.getDate(),0,0,0,0);
	  Timestamp dtLast = new Timestamp(dtFirst.getTime()+WeekMilis);

	  if (DebugFile.trace) {
	  	DebugFile.writeln("start date is between "+dtFirst.toString()+" to "+dtLast.toString());
	  	DebugFile.writeln("domain is "+oDomainId.toString());
	  }

	  if (null==sWorkAreaGuid) {
	    if (DebugFile.trace) {
	  	  DebugFile.writeln("workarea is null");
	    }
	    oMeetings = new DBSubset (DB.k_meetings,new Meeting().getTable(oConn).getColumnsStr(),
	  							  DB.id_domain+"=? AND "+
	  							  "(("+DB.gu_fellow+"=? AND "+DB.dt_start+" BETWEEN ? AND ?) OR "+
	  							  "("+DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_x_meeting_fellow+" WHERE "+DB.gu_fellow+"=? AND "+DB.dt_start+" BETWEEN ? AND ?)))"+
	  							  " ORDER BY "+DB.dt_start, 10);
	    nMeetings = oMeetings.load(oConn, new Object[]{oDomainId,sGuFellow,dtFirst,dtLast,sGuFellow,dtFirst,dtLast});	
	  } else {
	    if (DebugFile.trace) {
	  	  DebugFile.writeln("workarea is "+sWorkAreaGuid);
	    }
	    oMeetings = new DBSubset (DB.k_meetings,new Meeting().getTable(oConn).getColumnsStr(),
	  							  "("+DB.id_domain+"=? AND "+DB.gu_workarea+"=?) AND "+
	  							  "(("+DB.gu_fellow+"=? AND "+DB.dt_start+" BETWEEN ? AND ?) OR "+
	  							  "("+DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_x_meeting_fellow+" WHERE "+DB.gu_fellow+"=? AND "+DB.dt_start+" BETWEEN ? AND ?)))"+
	  							  " ORDER BY "+DB.dt_start, 10);
	    nMeetings = oMeetings.load(oConn, new Object[]{oDomainId,sWorkAreaGuid,sGuFellow,dtFirst,dtLast,sGuFellow,dtFirst,dtLast});	
	  }

	  if (DebugFile.trace) {
	  	DebugFile.decIdent();
	  	DebugFile.writeln("End WeekPlan.loadMeetingsForFellow() : "+String.valueOf(nMeetings));
	  }

	  return nMeetings;
	} // loadMeetingsForFellow

    // ------------------------------------------------------------------------

    /**
     * Load meetings organized at the given address from the given date and seven days ahead
     * @param oConn JDCConnection
     * @param sGuAddress GUID of the Address where the meeting takes place
     * @return Count of meetings loaded
     */
	public int loadMeetingsForAddress(JDCConnection oConn, String sGuAddress)
	  throws SQLException {

	  if (DebugFile.trace) {
	  	DebugFile.writeln("Begin WeekPlan.loadMeetingsForAddress([JDCConnection], "+sGuAddress+")");
	  	DebugFile.incIdent();	  	
	  }

	  Timestamp dtFirst = new Timestamp(dtFrom.getYear(),dtFrom.getMonth(),dtFrom.getDate(),0,0,0,0);
	  Timestamp dtLast = new Timestamp(dtFirst.getTime()+WeekMilis);

	  if (DebugFile.trace) {
	  	DebugFile.writeln("start date is between "+dtFirst.toString()+" to "+dtLast.toString());
	  	DebugFile.writeln("domain is "+oDomainId.toString());
	  }

	  if (null==sWorkAreaGuid) {
	    if (DebugFile.trace) {
	  	  DebugFile.writeln("workarea is null");
	    }
	    oMeetings = new DBSubset (DB.k_meetings,new Meeting().getTable(oConn).getColumnsStr(),
	  							  DB.id_domain+"=? AND "+
	  							  "(("+DB.gu_address+"=? AND "+DB.dt_start+" BETWEEN ? AND ?) OR "+
	  							  "("+DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_x_meeting_fellow+" WHERE "+DB.gu_address+"=? AND "+DB.dt_start+" BETWEEN ? AND ?)))"+
	  							  " ORDER BY "+DB.dt_start, 10);
	    nMeetings = oMeetings.load(oConn, new Object[]{oDomainId,sGuAddress,dtFirst,dtLast,sGuAddress,dtFirst,dtLast});	
	  } else {
	    if (DebugFile.trace) {
	  	  DebugFile.writeln("workarea is "+sWorkAreaGuid);
	    }
	    oMeetings = new DBSubset (DB.k_meetings,new Meeting().getTable(oConn).getColumnsStr(),
	  							  "("+DB.id_domain+"=? AND "+DB.gu_workarea+"=?) AND "+
	  							  "(("+DB.gu_address+"=? AND "+DB.dt_start+" BETWEEN ? AND ?) OR "+
	  							  "("+DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_x_meeting_fellow+" WHERE "+DB.gu_address+"=? AND "+DB.dt_start+" BETWEEN ? AND ?)))"+
	  							  " ORDER BY "+DB.dt_start, 10);
	    nMeetings = oMeetings.load(oConn, new Object[]{oDomainId,sWorkAreaGuid,sGuAddress,dtFirst,dtLast,sGuAddress,dtFirst,dtLast});	
	  }

	  if (DebugFile.trace) {
	  	DebugFile.decIdent();
	  	DebugFile.writeln("End WeekPlan.loadMeetingsForAddress() : "+String.valueOf(nMeetings));
	  }

	  return nMeetings;
	} // loadMeetingsForAddress

    // ------------------------------------------------------------------------

    /**
     * Load meetings organized at the given address from the given date and seven days ahead
     * @param oConn JDCConnection
     * @param dtFrom Date for first day to be loaded
     * @param sNmRoom Unique name of room used by meeting
     * @return Count of meetings loaded
     */
	public int loadMeetingsForRoom(JDCConnection oConn, String sNmRoom)
	  throws SQLException {

	  if (DebugFile.trace) {
	  	DebugFile.writeln("Begin WeekPlan.loadMeetingsForRoom([JDCConnection], "+sNmRoom+")");
	  	DebugFile.incIdent();	  	
	  }

	  Timestamp dtFirst = new Timestamp(dtFrom.getYear(),dtFrom.getMonth(),dtFrom.getDate(),0,0,0,0);
	  Timestamp dtLast = new Timestamp(dtFirst.getTime()+WeekMilis);

	  if (DebugFile.trace) {
	  	DebugFile.writeln("start date is between "+dtFirst.toString()+" to "+dtLast.toString());
	  	DebugFile.writeln("domain is "+oDomainId.toString());
	  }

	  if (null==sWorkAreaGuid) {
	    if (DebugFile.trace) {
	  	  DebugFile.writeln("workarea is null");
	    }
	    oMeetings = new DBSubset (DB.k_meetings,new Meeting().getTable(oConn).getColumnsStr(),
	  							  DB.id_domain+"=? AND "+
	  							  DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_x_meeting_room+" WHERE "+DB.nm_room+"=? AND "+DB.dt_start+" BETWEEN ? AND ?)"+
	  							  " ORDER BY "+DB.dt_start, 10);
	    nMeetings = oMeetings.load(oConn, new Object[]{oDomainId,sNmRoom,dtFirst,dtLast});
	  } else {
	    if (DebugFile.trace) {
	  	  DebugFile.writeln("workarea is "+sWorkAreaGuid);
	    }
	    oMeetings = new DBSubset (DB.k_meetings,new Meeting().getTable(oConn).getColumnsStr(),
	  							  DB.id_domain+"=? AND "+DB.gu_workarea+"=? AND "+
	  							  DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_x_meeting_room+" WHERE "+DB.nm_room+"=? AND "+DB.dt_start+" BETWEEN ? AND ?)"+
	  							  " ORDER BY "+DB.dt_start, 10);
	    nMeetings = oMeetings.load(oConn, new Object[]{oDomainId,sWorkAreaGuid,sNmRoom,dtFirst,dtLast});
	  }

	  if (DebugFile.trace) {
	  	DebugFile.decIdent();
	  	DebugFile.writeln("End WeekPlan.loadMeetingsForRoom() : "+String.valueOf(nMeetings));
	  }

	  return nMeetings;
	} // loadMeetingsForRoom

    // ------------------------------------------------------------------------

    /**
     * Get array of meeting for first half of a day
     * @param nDay Day of week from java.util.GregorianCalendar weekday integers
     * @return Array with meetings sorted by date or <b>null</b> if no meeting where found for given half day
     */	
	public Meeting[] getMeetingsForFirstHalfDayOfWeek(int nDay) {

	  if (DebugFile.trace) {
	  	DebugFile.writeln("Begin WeekPlan.getMeetingsForFirstHalfDayOfWeek("+String.valueOf(nDay)+")");
	  	DebugFile.incIdent();	  	
	  }

	  int nCount = 0;
	  Meeting[] aMeetings = null;
	  if (0!=nMeetings) {
	    Date dtStart;
	    int tmStart;
	    int tmMidday = getMiddayHoursAndMinutes();
	    int iCol = oMeetings.getColumnPosition(DB.dt_start);
	    for (int m=0; m<nMeetings; m++) {
		  dtStart = oMeetings.getDate(iCol, m);
		  tmStart = (dtStart.getHours()*100)+dtStart.getMinutes();
		  if (dtStart.getDay()==nDay && tmStart<=tmMidday) {
		    nCount++;
		  } // fi
	    } // next
	    if (nCount>0) {
	      int n = 0;
	      aMeetings = new Meeting[nCount];
	      for (int m=0; m<nMeetings; m++) {	      	
		    dtStart = oMeetings.getDate(iCol, m);
		    tmStart = (dtStart.getHours()*100)+dtStart.getMinutes();
		    if (dtStart.getDay()==nDay && tmStart<=tmMidday) {
		      aMeetings[n] = new Meeting();
		      aMeetings[n].putAll(oMeetings.getRowAsMap(m));
		      n++;
		    } // fi	        
	      } // next   
	    } // fi
	  } // fi (nCount>0)

	  if (DebugFile.trace) {
	  	DebugFile.decIdent();
	  	DebugFile.writeln("End WeekPlan.getMeetingsForFirstHalfDayOfWeek() : "+String.valueOf(nCount));
	  }

	  return aMeetings;
	} // getMeetingsForFirstHalfDayOfWeek

    // ------------------------------------------------------------------------
	
    /**
     * Get array of meeting for second half of a day
     * @param nDay Day of week from java.util.GregorianCalendar weekday integers
     * @return Array with meetings sorted by date or <b>null</b> if no meeting where found for given half day
     */	
	public Meeting[] getMeetingsForSecondHalfDayOfWeek(int nDay) {

	  if (DebugFile.trace) {
	  	DebugFile.writeln("Begin WeekPlan.getMeetingsForSecondHalfDayOfWeek("+String.valueOf(nDay)+")");
	  	DebugFile.incIdent();	  	
	  }

	  int nCount = 0;
	  Meeting[] aMeetings = null;
	  if (0!=nMeetings) {
	    Date dtStart;
	    int tmStart;
	    int tmMidday = getMiddayHoursAndMinutes();
	    int iCol = oMeetings.getColumnPosition(DB.dt_start);
	    for (int m=0; m<nMeetings; m++) {
		  dtStart = oMeetings.getDate(iCol, m);
		  tmStart = (dtStart.getHours()*100)+dtStart.getMinutes();
		  if (dtStart.getDay()==nDay && tmStart>tmMidday) {
		    nCount++;
		  } // fi
	    } // next
	    if (nCount>0) {
	      int n = 0;
	      aMeetings = new Meeting[nCount];
	      for (int m=0; m<nMeetings; m++) {	      	
		    dtStart = oMeetings.getDate(iCol, m);
		    tmStart = (dtStart.getHours()*100)+dtStart.getMinutes();
		    if (dtStart.getDay()==nDay && tmStart>tmMidday) {
		      aMeetings[n] = new Meeting();
		      aMeetings[n].putAll(oMeetings.getRowAsMap(m));
		      n++;
		    } // fi	        
	      } // next   
	    } // fi
	  } // fi (nCount>0)

	  if (DebugFile.trace) {
	  	DebugFile.decIdent();
	  	DebugFile.writeln("End WeekPlan.getMeetingsForSecondHalfDayOfWeek() : "+String.valueOf(nCount));
	  }

	  return aMeetings;
	} // getMeetingsForSecondHalfDayOfWeek

    // ------------------------------------------------------------------------

    /**
     * Get array of all fellows attending any meeting at this week
     */
	public Fellow[] getDistinctFellows(JDCConnection oConn)
	  throws SQLException {
	  	
	  if (DebugFile.trace) {
	    DebugFile.writeln("Begin WeekPlan.getDistinctFellows([JDCConnection])");
	    DebugFile.incIdent();
	  }
	  
	  DBSubset oFellows;
	  Timestamp dtFirst = new Timestamp(dtFrom.getYear(),dtFrom.getMonth(),dtFrom.getDate(),0,0,0,0);
	  Timestamp dtLast = new Timestamp(dtFirst.getTime()+WeekMilis);
	  int nFellows = 0;
	  Fellow[] aFellows;
	  if (null==sWorkAreaGuid) {
	    oFellows = new DBSubset (
	  	  DB.k_fellows+" f",
	  	  new Fellow().getTable(oConn).getColumnsStr(),
	      "f."+DB.id_domain+"=? AND ("+
	      "EXISTS (SELECT m."+DB.gu_fellow+" FROM "+DB.k_meetings+" m WHERE m."+DB.gu_fellow+"=f."+DB.gu_fellow+" AND m."+DB.dt_start+" BETWEEN ? AND ?) OR "+
	      "EXISTS (SELECT x."+DB.gu_fellow+" FROM "+DB.k_x_meeting_fellow+" x WHERE x."+DB.gu_fellow+"=f."+DB.gu_fellow+" AND x."+DB.dt_start+" BETWEEN ? AND ?))"+
	      " ORDER BY "+DB.tx_name+","+DB.tx_surname, 10);
	    nFellows = oFellows.load(oConn, new Object[]{oDomainId,dtFirst,dtLast,dtFirst,dtLast});
	  } else {
	    oFellows = new DBSubset (
	  	  DB.k_fellows+" f",
	  	  new Fellow().getTable(oConn).getColumnsStr(),
	      "f."+DB.id_domain+"=? AND f."+DB.gu_workarea+"=? AND ("+
	      "EXISTS (SELECT m."+DB.gu_fellow+" FROM "+DB.k_meetings+" m WHERE m."+DB.gu_fellow+"=f."+DB.gu_fellow+" AND m."+DB.dt_start+" BETWEEN ? AND ?) OR "+
	      "EXISTS (SELECT x."+DB.gu_fellow+" FROM "+DB.k_x_meeting_fellow+" x WHERE x."+DB.gu_fellow+"=f."+DB.gu_fellow+" AND x."+DB.dt_start+" BETWEEN ? AND ?))"+
	      " ORDER BY "+DB.tx_name+","+DB.tx_surname, 10);
	    nFellows = oFellows.load(oConn, new Object[]{oDomainId,sWorkAreaGuid,dtFirst,dtLast,dtFirst,dtLast});
	  } // fi
	  if (0==nFellows) {
	    aFellows = null;
	  } else {
	    aFellows = new Fellow[nFellows];
	    for (int f=0; f<nFellows; f++) {
	      aFellows[f] = new Fellow();
		  aFellows[f].putAll(oFellows.getRowAsMap(f));
	    } // next
	  } // fi (nFellows)

	  if (DebugFile.trace) {
	    DebugFile.decIdent();
	    if (null==aFellows)
	      DebugFile.writeln("End WeekPlan.getDistinctFellows() : 0");
	    else
	      DebugFile.writeln("End WeekPlan.getDistinctFellows() : " + String.valueOf(aFellows.length));
	  }

	  return aFellows;
	} // getDistinctFellows

    // ------------------------------------------------------------------------

	public Room[] getDistinctRooms(JDCConnection oConn)
	  throws SQLException {
	  DBSubset oRooms;
	  Timestamp dtFirst = new Timestamp(dtFrom.getYear(),dtFrom.getMonth(),dtFrom.getDate(),0,0,0,0);
	  Timestamp dtLast = new Timestamp(dtFirst.getTime()+WeekMilis);
	  int nRooms = 0;
	  Room[] aRooms;
	  if (null==sWorkAreaGuid) {
	    oRooms = new DBSubset (
	  	  DB.k_rooms+" r",
	  	  new Room().getTable(oConn).getColumnsStr(),
	      "r."+DB.id_domain+"=? AND "+
	      "EXISTS (SELECT x."+DB.nm_room+" FROM "+DB.k_x_meeting_room+" x WHERE x."+DB.nm_room+"=r."+DB.nm_room+" AND x."+DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_meetings+" WHERE "+DB.id_domain+"=? AND "+DB.dt_start+" BETWEEN ? AND ?))"+
	      " ORDER BY "+DB.nm_room, 10);
	    nRooms = oRooms.load(oConn, new Object[]{oDomainId,oDomainId,dtFirst,dtLast});
	  } else {
	    oRooms = new DBSubset (
	  	  DB.k_rooms+" r",
	  	  new Room().getTable(oConn).getColumnsStr(),
	      "r."+DB.id_domain+"=? AND r."+DB.gu_workarea+"=? AND "+
	      "EXISTS (SELECT x."+DB.nm_room+" FROM "+DB.k_x_meeting_room+" x WHERE x."+DB.nm_room+"=r."+DB.nm_room+" AND x."+DB.gu_meeting+" IN (SELECT "+DB.gu_meeting+" FROM "+DB.k_meetings+" WHERE "+DB.id_domain+"=? AND "+DB.gu_workarea+"=? AND "+DB.dt_start+" BETWEEN ? AND ?))"+
	      " ORDER BY "+DB.nm_room, 10);
	    nRooms = oRooms.load(oConn, new Object[]{oDomainId,sWorkAreaGuid,oDomainId,sWorkAreaGuid,dtFirst,dtLast});
	  } // fi
	  if (0==nRooms) {
	    aRooms = null;
	  } else {
	    aRooms = new Room[nRooms];
	    for (int r=0; r<nRooms; r++) {
	      aRooms[r] = new Room();
		  aRooms[r].putAll(oRooms.getRowAsMap(r));
	    } // next
	  }
	  return aRooms;
	} // getDistinctRooms

    // ------------------------------------------------------------------------

	public Address[] getDistinctAddresses(JDCConnection oConn)
	  throws SQLException {
	  DBSubset oAddresses;
	  Timestamp dtFirst = new Timestamp(dtFrom.getYear(),dtFrom.getMonth(),dtFrom.getDate(),0,0,0,0);
	  Timestamp dtLast = new Timestamp(dtFirst.getTime()+WeekMilis);
	  int nAddresses = 0;
	  Address[] aAddresses;
	  if (null==sWorkAreaGuid) {
	    oAddresses = new DBSubset (
	  	  DB.k_addresses+" a",
	  	  new Address().getTable(oConn).getColumnsStr(),
	      "EXISTS (SELECT m."+DB.gu_address+" FROM "+DB.k_meetings+" m WHERE m."+DB.gu_address+"=a."+DB.gu_address+" AND m."+DB.id_domain+"=? AND m."+DB.dt_start+" BETWEEN ? AND ?)",
	      10);
	    nAddresses = oAddresses.load(oConn, new Object[]{oDomainId,dtFirst,dtLast});
	  } else {
	    oAddresses = new DBSubset (
	  	  DB.k_addresses+" a",
	  	  new Address().getTable(oConn).getColumnsStr(),
	      "EXISTS (SELECT m."+DB.gu_address+" FROM "+DB.k_meetings+" m WHERE m."+DB.gu_address+"=a."+DB.gu_address+" AND m."+DB.id_domain+"=? AND m."+DB.gu_workarea+"=? AND m."+DB.dt_start+" BETWEEN ? AND ?)",
	      10);
	    nAddresses = oAddresses.load(oConn, new Object[]{oDomainId,sWorkAreaGuid,dtFirst,dtLast});
	  } // fi
	  if (0==nAddresses) {
	    aAddresses = null;
	  } else {
	    aAddresses = new Address[nAddresses];
	    for (int a=0; a<nAddresses; a++) {
	      aAddresses[a] = new Address();
		  aAddresses[a].putAll(oAddresses.getRowAsMap(a));
	    } // next
	  }
	  return aAddresses;
	} // getDistinctAddresses
}
