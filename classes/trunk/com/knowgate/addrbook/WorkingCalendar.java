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

import java.util.Arrays;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Iterator;
import java.util.Set;
import java.util.TreeSet;

import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.ACLUser;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Calendar;

/**
 * <p>Represents a working/non working time calendar</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class WorkingCalendar {

  // **********************************************************
  // Private Variables

  private static final short ONE = (short) 1;
  private static final short VOID = (short) -1; // Empty hours are stored as -1 at the database
  private DBPersist oCalendarInfo; // A register at k_working_calendar table
  private int[] aDates;            // Array with dates inluded at this calendar (one integer YYYYMMDD per day)
  private boolean[] aWorkingTimes; // true if the corresponding date from previous array is a working day or false if it is a holiday
  private short[] aStartHour1;     // Start hour 00-23 for morning time slice
  private short[] aStartMin1;      // Start minute 00-59 for morning time slice
  private short[] aStartHour2;     // Start hour 00-23 for evening time slice
  private short[] aStartMin2;      // Start minute 00-59 for evening time slice
  private short[] aEndHour1;       // End hour 00-23 for morning time slice
  private short[] aEndMin1;        // End minute 00-59 for morning time slice
  private short[] aEndHour2;       // End hour 00-23 for evening time slice
  private short[] aEndMin2;        // End minute 00-59 for evening time slice
  private String[] aDescs;         // Day description (mainly for special holidays)

  // --------------------------------------------------------------------------
  
  /**
   * Default constructor for an empty calendar
   */
  public WorkingCalendar() {
    oCalendarInfo = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
    oCalendarInfo.put(DB.nm_calendar,"");
    aDates = null;
    aDescs = null;
    aWorkingTimes = null;
    aStartHour1 = aStartHour2 = aEndHour1 = aEndHour2 = null;
    aStartMin1 = aStartMin2 = aEndMin1 = aEndMin2 = null;
  }

  // --------------------------------------------------------------------------

  /**
   * Create empty calendar with given GUID
   */
  public WorkingCalendar(String sGuCalendar) {
    oCalendarInfo = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
	oCalendarInfo.put(DB.gu_calendar, sGuCalendar);
    oCalendarInfo.put(DB.nm_calendar,"");
    aDates = null;
    aDescs = null;
    aWorkingTimes = null;
    aStartHour1 = aStartHour2 = aEndHour1 = aEndHour2 = null;
    aStartMin1 = aStartMin2 = aEndMin1 = aEndMin2 = null;
  }

  // --------------------------------------------------------------------------

  /**
   * Create calendar and load it from the database
   * @throws SQLException
   */
  public WorkingCalendar(JDCConnection oConn, String sGuCalendar)
  	throws SQLException {
    oCalendarInfo = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
    aDates = null;
    aDescs = null;
    aWorkingTimes = null;
    aStartHour1 = aStartHour2 = aEndHour1 = aEndHour2 = null;
    aStartMin1 = aStartMin2 = aEndMin1 = aEndMin2 = null;
    load(oConn, sGuCalendar);
  }

  // --------------------------------------------------------------------------
  
  protected WorkingCalendar(int nDays, String sNmCalendar, Date dtFrom, Date dtTo) {
  	if (DebugFile.trace) DebugFile.writeln("new WorkingCalendar("+String.valueOf(nDays)+","+sNmCalendar+","+dtFrom+","+dtTo+")");
    oCalendarInfo = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
    oCalendarInfo.put(DB.nm_calendar,sNmCalendar);
	oCalendarInfo.put(DB.dt_from, dtFrom);
	oCalendarInfo.put(DB.dt_to, dtTo);
	if (nDays==0) {
      aDates = null;
      aDescs = null;
      aWorkingTimes = null;
      aStartHour1 = aStartHour2 = aEndHour1 = aEndHour2 = null;
      aStartMin1 = aStartMin2 = aEndMin1 = aEndMin2 = null;
	} else {
	  aDates = new int[nDays];
	  aWorkingTimes = new boolean[nDays];
	  aStartHour1 = new short[nDays];
	  aStartMin1 = new short[nDays];
	  aStartHour2 = new short[nDays];
	  aStartMin2 = new short[nDays];
	  aEndHour1 = new short[nDays];
	  aEndMin1 = new short[nDays];
	  aEndHour2 = new short[nDays];	  
	  aEndMin2 = new short[nDays];
	  aDescs = new String[nDays];
	}
  }

  // --------------------------------------------------------------------------

  /**
   * Load calendar from database including working time
   * @param JDCConnection
   * @param sGuCalendar String GUID of Working Calendar to be loaded
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, String sGuCalendar)
  	throws SQLException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin.WorkingCalendar.load([JDCConnection], "+sGuCalendar+")");
	  DebugFile.incIdent();
	}
  		
  	// Load calendar information common to all days
	boolean bExists = oCalendarInfo.load(oConn, sGuCalendar);
	if (bExists) {

      PreparedStatement oStmt;
      ResultSet oRSet;
      String sSQL;


      sSQL = "SELECT COUNT(*) FROM "+DB.k_working_time+" WHERE "+DB.gu_calendar+"=?";

      if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");

      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1, sGuCalendar);
	  oRSet = oStmt.executeQuery();
	  oRSet.next();
	  int nDays = oRSet.getInt(1);
	  oRSet.close();
	  oStmt.close();

	  if (DebugFile.trace) DebugFile.writeln("WorkingTime has "+String.valueOf(nDays)+" days settings");

	  if (nDays>0) {
	    aDates = new int[nDays];
	    aWorkingTimes = new boolean[nDays];
	    aStartHour1 = new short[nDays];
	    aStartMin1 = new short[nDays];
	    aStartHour2 = new short[nDays];
	    aStartMin2 = new short[nDays];
	    aEndHour1 = new short[nDays];
	    aEndMin1 = new short[nDays];
	    aEndHour2 = new short[nDays];	  
	    aEndMin2 = new short[nDays];
	    aDescs = new String[nDays];

	    sSQL = "SELECT dt_day,bo_working_time,hh_start1,mi_start1,hh_end1,mi_end1,hh_start2,mi_start2,hh_end2,mi_end2,de_day FROM "+DB.k_working_time+" WHERE "+DB.gu_calendar+"=? ORDER BY 1";
	    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
	  
        oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sGuCalendar);
	    oRSet = oStmt.executeQuery();

	    for (int d=0; d<nDays; d++) {
	      if (oRSet.next()) {
	  	    aDates[d] = oRSet.getInt(1);
	  	    aWorkingTimes[d] = (oRSet.getShort(2)==ONE);	  	
	  	    aStartHour1[d] = oRSet.getShort(3);
	  	    aStartMin1[d] = oRSet.getShort(4);
	  	    aEndHour1[d] = oRSet.getShort(5);
	  	    aEndMin1[d] = oRSet.getShort(6);
	  	    aStartHour2[d] = oRSet.getShort(7);
	  	    aStartMin2[d] = oRSet.getShort(8);	  	  
	  	    aEndHour2[d] = oRSet.getShort(9);
	  	    aEndMin2[d] = oRSet.getShort(10);
		    aDescs[d] = oRSet.getString(11);
	      } else {
	  	    aDates[d] = 99991231;
	  	    aWorkingTimes[d] = false;
	  	    aStartHour1[d] = VOID;
	  	    aStartMin1[d] = VOID;
	  	    aEndHour1[d] = VOID;
	  	    aEndMin1[d] = VOID;
	  	    aStartHour2[d] = VOID;
	  	    aStartMin2[d] = VOID;	  	  
	  	    aEndHour2[d] = VOID;
	  	    aEndMin2[d] = VOID;
		    aDescs = null;   
	      }// fi
	    } // next

	    oRSet.close();
	    oStmt.close();
	  } // fi
	} // fi (bExists)

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End.WorkingTime.load() : "+String.valueOf(bExists));
	}

	return bExists;
  } // load

  // --------------------------------------------------------------------------

  public boolean store(JDCConnection oConn) throws SQLException {
    if (oCalendarInfo.isNull(DB.gu_calendar)) {
      oCalendarInfo.put(DB.gu_calendar, Gadgets.generateUUID());
    }
    oCalendarInfo.replace(DB.dt_modified, new java.util.Date());
    return oCalendarInfo.store(oConn);
  }

  // --------------------------------------------------------------------------

  /**
   * Get number of days from the earliest date to the latest date covered by this calendar
   */
  public int getDayCount() {
    if (aDates==null)
      return 0;
    else
      return aDates.length;
  } // getDayCount

  // --------------------------------------------------------------------------

  /**
   * Get working / non working day status
   * @param iDate An integer representing a date in format yyyymmdd
   * @return Boolean True if given date is a working day,
   * False if given date is a holiday, or <b>null</b> if given date
   * is not defined at this calendar
   */
  public Boolean isWorkingDay(int iDate)
  	throws NullPointerException {
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin WorkingCalendar.isWorkingDay("+String.valueOf(iDate)+")");
	  DebugFile.incIdent();
	}

	Boolean bRetVal;
  	
  	if (aDates==null) {
  	  bRetVal = null;
  	} else {
  	  int nDay = Arrays.binarySearch(aDates, iDate);

	  if (DebugFile.trace) DebugFile.writeln("day index is "+String.valueOf(nDay));
  	
  	  if (nDay>=0)
  	    bRetVal = new Boolean(aWorkingTimes[nDay]);
  	  else
  	    bRetVal = null;
    } // fi

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  if (null==bRetVal)
	    DebugFile.writeln("End WorkingCalendar.isWorkingDay() : null");
	  else
	    DebugFile.writeln("End WorkingCalendar.isWorkingDay() : " + String.valueOf(bRetVal.booleanValue()));
	} // fi
    return bRetVal;
  } // isWorkingDay

  // --------------------------------------------------------------------------

 
  /**
   * Get working / non working day status
   * @param oDate Date to be checked
   * @return Boolean True if given date is a working day,
   * False if given date is a holiday, or <b>null</b> if given date
   * is not defined at this calendar
   */
  public Boolean isWorkingDay(Date oDate)
  	throws NullPointerException {
	
	if (null==oDate) throw new NullPointerException("WorkingtCalendar.isWorkingDay() date cannot be null");

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin WorkingCalendar.isWorkingDay("+oDate.toString()+")");
	  DebugFile.incIdent();
	}

  	Boolean bRetVal = isWorkingDay((10000*(oDate.getYear()+1900))+(100*oDate.getMonth())+oDate.getDate());

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  if (bRetVal==null)
	    DebugFile.writeln("End WorkingCalendar.isWorkingDay() : null");
	  else
	    DebugFile.writeln("End WorkingCalendar.isWorkingDay() : " + String.valueOf(bRetVal.booleanValue()));
	}
	return bRetVal;
  }

  // --------------------------------------------------------------------------

  /**
   * Get working / non working day status
   * @param lDate An long representing a date in miliseconds
   * @return Boolean True if given date is a working day,
   * False if given date is a holiday, or <b>null</b> if given date
   * is not defined at this calendar
   */
  public Boolean isWorkingDay(long lDate) {
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin WorkingCalendar.isWorkingDay("+String.valueOf(lDate)+")");
	  DebugFile.incIdent();
	}
  	
  	Boolean bRetVal = isWorkingDay(new Date(lDate));

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  if (bRetVal==null)
	    DebugFile.writeln("End WorkingCalendar.isWorkingDay() : null");
	  else
	    DebugFile.writeln("End WorkingCalendar.isWorkingDay() : " + String.valueOf(bRetVal.booleanValue()));
	}
	return bRetVal;
  }
  
  // --------------------------------------------------------------------------

  /**
   * Check if a given hour and minute falls into the working intervals of a day
   * @param iDate 
   */
  public Boolean isWorkingTime(int iDate, int iHour, int iMin) {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin WorkingCalendar.isWorkingTime("+String.valueOf(iDate)+","+String.valueOf(iHour)+","+String.valueOf(iMin)+")");
	  DebugFile.incIdent();
	}

  	Boolean bRetVal;
  	int iGivenTime, iStartTime, iEndTime;

    // Search day at internal array
  	int nDay = Arrays.binarySearch(aDates, iDate);

    // If day was found, then check whether or not there are time slices of working hours
  	if (nDay>=0) {
  	  // Time slices are only checked if this is a working day, for holidays slices are ignored
  	  if (aWorkingTimes[nDay]) {
  	    bRetVal = new Boolean (true);	      
	    iGivenTime = (100*iHour)+iMin;
	    // If a morning starting hour exists then check if given hour:minute is between start and end time
	    if (VOID!=aStartHour1[nDay]) {
	      iStartTime = (100*aStartHour1[nDay])+aStartMin1[nDay];
	      iEndTime = (100*aEndHour1[nDay])+aEndMin1[nDay];
		  bRetVal = new Boolean(iGivenTime>=iStartTime && iGivenTime<=iEndTime);
	    }
	    // If given time did not belong to morning hours then check evening hours
	    if (!bRetVal.booleanValue() && VOID!=aStartHour2[nDay]) {
	      iStartTime = (100*aStartHour2[nDay])+aStartMin2[nDay];
	      iEndTime = (100*aEndHour2[nDay])+aEndMin2[nDay];
		  bRetVal = new Boolean(iGivenTime>=iStartTime && iGivenTime<=iEndTime);
	    }
  	  } else {
  	    bRetVal = new Boolean (false);
  	  }  	  
  	} else {
  	  bRetVal = null;
  	}

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End WorkingCalendar.isWorkingTime() : " + String.valueOf(bRetVal));
	}

    return bRetVal;
  } // isWorkingTime

  // --------------------------------------------------------------------------

  public Boolean isWorkingTime(Date dt) {
    return isWorkingTime(((dt.getYear()+1900)*10000)+(dt.getMonth()*100)+dt.getDate(), dt.getHours(), dt.getMinutes());
  }

  // --------------------------------------------------------------------------

  public void addTime(JDCConnection oConn, Date dtFrom,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd,
  					  short EveningHourStart, short EveningMinuteStart,
  					  short EveningHourEnd, short EveningMinuteEnd,
  					  boolean[] aWorking, String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {
    
    if (oCalendarInfo.isNull(DB.gu_calendar)) throw new IllegalStateException("WorkingCalendar.addTime() Calendar GUID not set");
	if (null==dtFrom) throw new NullPointerException("WorkingCalendar.addTime() date from cannot be null");

    int iFrom = (10000*(dtFrom.getYear()+1900))+(100*dtFrom.getMonth())+dtFrom.getDate();

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin WorkingCalendar.addTime([JDCConnection]"+dtFrom.toString()+","+
	  					String.valueOf(MorningHourStart)+":"+String.valueOf(MorningMinuteStart)+","+
	  					String.valueOf(MorningHourEnd)+":"+String.valueOf(MorningMinuteEnd)+","+
	  					String.valueOf(EveningHourStart)+":"+String.valueOf(EveningMinuteStart)+","+
	  					String.valueOf(EveningHourEnd)+":"+String.valueOf(EveningMinuteEnd)+","+
	  					"boolean [],"+sDescription+")");
	  DebugFile.incIdent();
	}	
	String sGuCalendar = getString(DB.gu_calendar);
    String sSQL = "INSERT INTO "+DB.k_working_time+" ("+DB.dt_day+","+DB.gu_calendar+","+DB.bo_working_time+","+DB.hh_start1+","+DB.mi_start1+","+DB.hh_end1+","+DB.mi_end1+","+DB.hh_start2+","+DB.mi_start2+","+DB.hh_end2+","+DB.mi_end2+","+DB.de_day+") VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
    if (DebugFile.trace) {
      DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    }
    PreparedStatement oStmt = oConn.prepareStatement(sSQL);
  	final int nDays = aWorking.length;
  	int iDt = iFrom;
  	for (int d=0; d<nDays; d++) {
      int nYear = iDt/10000;
      int nMnth = (iDt/100)-(nYear*100);
      int nDay = iDt-((iDt/100)*100);
      
      if (nMnth<=11 && nDay>0 && nDay<=Calendar.LastDay(nMnth,nYear)) {
        if (DebugFile.trace) {
          DebugFile.writeln("Adding date "+String.valueOf(iDt));
        }
      
  	    oStmt.setInt   (1, iDt);
  	    oStmt.setString(2, sGuCalendar);
  	    oStmt.setShort (3, (short) (aWorking[d] ? 1 : 0));
  	    oStmt.setShort (4, MorningHourStart);
  	    oStmt.setShort (5, MorningMinuteStart);
  	    oStmt.setShort (6, MorningHourEnd);
  	    oStmt.setShort (7, MorningMinuteEnd);
  	    oStmt.setShort (8, EveningHourStart);
  	    oStmt.setShort (9, EveningMinuteStart);
  	    oStmt.setShort (10, EveningHourEnd);
  	    oStmt.setShort (11, EveningMinuteEnd);
	    if (null==sDescription)
	  	  oStmt.setNull(12, java.sql.Types.VARCHAR);
	    else
  	      oStmt.setString(12, sDescription);
        if (DebugFile.trace) {
          DebugFile.writeln("PreparedStatement.executeUpdate()");
        }
	    oStmt.executeUpdate();
      } // 

	  if (nDay<Calendar.LastDay(nMnth,nYear))
	    iDt++;
	  else if (nMnth<11)
	    iDt = (nYear*10000)+((nMnth+1)*100)+1;
	  else
	    iDt = ((nYear+1)*10000)+1;      
  	} // next
    if (DebugFile.trace) {
      DebugFile.writeln("PreparedStatement.close()");
    }
  	oStmt.close();
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkingCalendar.addTime()");
    }
  } // addTime    
  // --------------------------------------------------------------------------

  public void addTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd,
  					  short EveningHourStart, short EveningMinuteStart,
  					  short EveningHourEnd, short EveningMinuteEnd,
  					  boolean bWorking, Set oWeeklyHolidays, String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {
    
    if (oCalendarInfo.isNull(DB.gu_calendar)) throw new IllegalStateException("WorkingCalendar.addTime() Calendar GUID not set");
	if (null==dtFrom) throw new NullPointerException("WorkingCalendar.addTime() date from cannot be null");
	if (null==dtTo) throw new NullPointerException("WorkingCalendar.addTime() date to cannot be null");

    int iFrom = (10000*(dtFrom.getYear()+1900))+(100*dtFrom.getMonth())+dtFrom.getDate();
    int iTo = (10000*(dtTo.getYear()+1900))+(100*dtTo.getMonth())+dtTo.getDate();

	if (iTo<iFrom) throw new IllegalArgumentException("WorkingCalendar.addTime() Date to cannot be prior date from");

	if (DebugFile.trace) {
	  String sWeekHolidays = "";
	  if (null!=oWeeklyHolidays) {
	  	Iterator oIter = oWeeklyHolidays.iterator();
	  	while (oIter.hasNext()) {
	      sWeekHolidays += (sWeekHolidays.length()==0 ? "" : ",") + Calendar.WeekDayName(Integer.parseInt(oIter.next().toString()), "en");
	  	} // wend
	  } // fi (oWeeklyHolidays)
	  sWeekHolidays = "{"+sWeekHolidays+"}";
	  DebugFile.writeln("Begin WorkingCalendar.addTime([JDCConnection]"+dtFrom.toString()+","+dtTo.toString()+","+
	  					String.valueOf(MorningHourStart)+":"+String.valueOf(MorningMinuteStart)+","+
	  					String.valueOf(MorningHourEnd)+":"+String.valueOf(MorningMinuteEnd)+","+
	  					String.valueOf(EveningHourStart)+":"+String.valueOf(EveningMinuteStart)+","+
	  					String.valueOf(EveningHourEnd)+":"+String.valueOf(EveningMinuteEnd)+","+
	  					(bWorking ? "Working Time" : "Non Working Time")+","+sWeekHolidays+","+sDescription+")");
	  DebugFile.incIdent();
	}	
	String sGuCalendar = getString(DB.gu_calendar);
	short iWorkingTime = (short) (bWorking ? 1 : 0);
    String sSQL = "INSERT INTO "+DB.k_working_time+" ("+DB.dt_day+","+DB.gu_calendar+","+DB.bo_working_time+","+DB.hh_start1+","+DB.mi_start1+","+DB.hh_end1+","+DB.mi_end1+","+DB.hh_start2+","+DB.mi_start2+","+DB.hh_end2+","+DB.mi_end2+","+DB.de_day+") VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
    if (DebugFile.trace) {
      DebugFile.writeln("Connection.prepareStatement("+sSQL+")");
    }
    PreparedStatement oStmt = oConn.prepareStatement(sSQL);
    int nYear = iFrom/10000;
    int nMnth = (iFrom/100)-(nYear*100);
    int nDay = iFrom-((iFrom/100)*100);  	
  	for (int iDt=iFrom; iDt<=iTo; iDt=(nDay<Calendar.LastDay(nMnth,nYear) ? iDt+1 : (nMnth<11 ? iDt = (nYear*10000)+((nMnth+1)*100)+1 : ((nYear+1)*10000)+1))) {
      nYear = iDt/10000;
      nMnth = (iDt/100)-(nYear*100);
      nDay = iDt-((iDt/100)*100);
      
      if (nMnth<=11 && nDay>0 && nDay<=Calendar.LastDay(nMnth,nYear)) {
        if (DebugFile.trace) {
          DebugFile.writeln("Adding date "+String.valueOf(iDt));
        }
      
  	    oStmt.setInt   (1, iDt);
  	    oStmt.setString(2, sGuCalendar);
  	    if (null!=oWeeklyHolidays) {
  	      Date dtCurrentDate = toDate(iDt);
          GregorianCalendar dtCalendarDate = new GregorianCalendar(dtCurrentDate.getYear()+1900, dtCurrentDate.getMonth(), dtCurrentDate.getDate());
          Integer iCurrentDayOfWeek = new Integer(dtCalendarDate.get(GregorianCalendar.DAY_OF_WEEK));
          if (DebugFile.trace) {
            DebugFile.writeln("Setting date "+dtCurrentDate.toString()+" to "+(oWeeklyHolidays.contains(iCurrentDayOfWeek) ? "Non Working Time" : "Working Time"));
          }
          iWorkingTime = (short)(oWeeklyHolidays.contains(iCurrentDayOfWeek) ? 0 : 1);
  	    } // fi (oWeeklyHolidays)
  	    oStmt.setShort (3, iWorkingTime);
  	    oStmt.setShort (4, MorningHourStart);
  	    oStmt.setShort (5, MorningMinuteStart);
  	    oStmt.setShort (6, MorningHourEnd);
  	    oStmt.setShort (7, MorningMinuteEnd);
  	    oStmt.setShort (8, EveningHourStart);
  	    oStmt.setShort (9, EveningMinuteStart);
  	    oStmt.setShort (10, EveningHourEnd);
  	    oStmt.setShort (11, EveningMinuteEnd);
	    if (null==sDescription)
	  	  oStmt.setNull(12, java.sql.Types.VARCHAR);
	    else
  	      oStmt.setString(12, sDescription);
        if (DebugFile.trace) {
          DebugFile.writeln("PreparedStatement.executeUpdate()");
        }
	    oStmt.executeUpdate();
      } // 
  	} // next
    if (DebugFile.trace) {
      DebugFile.writeln("PreparedStatement.close()");
    }
  	oStmt.close();
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkingCalendar.addTime()");
    }
  } // addTime

  // --------------------------------------------------------------------------

  public void addTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short HourStart, short MinuteStart,
  					  short HourEnd  , short MinuteEnd,
  					  boolean bWorking, Set oWeeklyHolidays, String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

    addTime(oConn, dtFrom, dtTo, HourStart, MinuteStart, HourEnd, MinuteEnd,
  			(short)-1, (short)-1, (short)-1, (short)-1,
  			bWorking, oWeeklyHolidays, sDescription);
  } // addTime

  // --------------------------------------------------------------------------

  public void addTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  boolean bWorking, Set oWeeklyHolidays, String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

    addTime(oConn, dtFrom, dtTo,
		    VOID, VOID, VOID, VOID,
  			VOID, VOID, VOID, VOID,
  			bWorking, oWeeklyHolidays, sDescription);
  } // addTime
  
  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd,
  					  short EveningHourStart, short EveningMinuteStart,
  					  short EveningHourEnd, short EveningMinuteEnd,
  					  Set oWeeklyHolidays, String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo,
  			MorningHourStart, MorningMinuteStart,
  			MorningHourEnd, MorningMinuteEnd,
  			EveningHourStart, EveningMinuteStart,
  			EveningHourEnd, EveningMinuteEnd,
  			true, oWeeklyHolidays, sDescription);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd,
  					  short EveningHourStart, short EveningMinuteStart,
  					  short EveningHourEnd, short EveningMinuteEnd,
  					  String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo,
  			MorningHourStart, MorningMinuteStart,
  			MorningHourEnd, MorningMinuteEnd,
  			EveningHourStart, EveningMinuteStart,
  			EveningHourEnd, EveningMinuteEnd,
  			true, null, sDescription);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd,
  					  Set oWeeklyHolidays, String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo,
  			MorningHourStart, MorningMinuteStart,
  			MorningHourEnd, MorningMinuteEnd,
  			true, oWeeklyHolidays, sDescription);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd,
  					  Set oWeeklyHolidays)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo,
  			MorningHourStart, MorningMinuteStart,
  			MorningHourEnd, MorningMinuteEnd,
  			true, oWeeklyHolidays, null);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd,
  					  String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo,
  			MorningHourStart, MorningMinuteStart,
  			MorningHourEnd, MorningMinuteEnd,
  			true, null, sDescription);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					  short MorningHourStart, short MorningMinuteStart,
  					  short MorningHourEnd, short MorningMinuteEnd)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo,
  			MorningHourStart, MorningMinuteStart,
  			MorningHourEnd, MorningMinuteEnd,
  			true, null, null);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					         Set oWeeklyHolidays, String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo, true, oWeeklyHolidays, sDescription);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					         String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo, true, null, sDescription);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo, true, null, null);
  } // addWorkingTime

  // --------------------------------------------------------------------------

  public void addNonWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo,
  					         String sDescription)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo, false, null, sDescription);
  } // addNonWorkingTime

  // --------------------------------------------------------------------------

  public void addNonWorkingTime(JDCConnection oConn, Date dtFrom, Date dtTo)
  	throws SQLException,IllegalStateException,IllegalArgumentException,NullPointerException {

  	addTime(oConn, dtFrom, dtTo, false, null, null);
  } // addNonWorkingTime

  // --------------------------------------------------------------------------

  public void delete(JDCConnection oConn) throws SQLException,NullPointerException {
	if (oCalendarInfo.isNull(DB.gu_calendar)) throw new NullPointerException("WorkingCalendar.delete() gu_calendar cannot be null");
  	delete(oConn, getString(DB.gu_calendar));
  }

  // --------------------------------------------------------------------------

  public int deleteTime(JDCConnection oConn, Date dtFrom, Date dtTo)
  	throws SQLException,IllegalStateException,IllegalArgumentException {

    if (oCalendarInfo.isNull(DB.gu_calendar)) throw new IllegalStateException("WorkingCalendar.deleteTime() Calendar GUID not set");
	if (null==dtFrom) throw new NullPointerException("WorkingCalendar.deleteTime() date from cannot be null");
	if (null==dtTo) throw new NullPointerException("WorkingCalendar.deleteTime() date to cannot be null");

    int iFrom = (10000*(dtFrom.getYear()+1900))+(100*dtFrom.getMonth())+dtFrom.getDate();
    int iTo = (10000*(dtTo.getYear()+1900))+(100*dtTo.getMonth())+dtTo.getDate();

	if (iTo<iFrom) throw new IllegalArgumentException("WorkingCalendar.deleteTime() Date to cannot be prior date from");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkingCalendar.deleteTime([JDCConnection], "+dtFrom.toString()+", "+dtTo.toString()+")");
      DebugFile.incIdent();
      DebugFile.writeln("Connection.prepareStatement(DELETE FROM "+DB.k_working_time+" WHERE "+DB.gu_calendar+"='"+getStringNull(DB.gu_calendar, null)+"' AND "+DB.dt_day+" BETWEEN "+String.valueOf(iFrom)+" AND "+String.valueOf(iTo)+")");
    }

	PreparedStatement oStmt = oConn.prepareStatement("DELETE FROM "+DB.k_working_time+" WHERE "+DB.gu_calendar+"=? AND "+DB.dt_day+" BETWEEN ? AND ?");
	oStmt.setString(1, getStringNull(DB.gu_calendar, null));
	oStmt.setInt(2, iFrom);
	oStmt.setInt(3, iTo);
	int nDeleted = oStmt.executeUpdate();
	oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkingCalendar.deleteTime() : "+String.valueOf(nDeleted));
    }

	return nDeleted;
  } // deleteTime

  // --------------------------------------------------------------------------

  public int deleteTime(JDCConnection oConn, Date dtFrom, long nDays)
  	throws SQLException,IllegalStateException,IllegalArgumentException {
    Date dtTo = new Date(dtFrom.getTime()+nDays*86400000l);
    return deleteTime(oConn, dtFrom, nDays);
  }
  	
  // --------------------------------------------------------------------------

  /**
   * Get array of working vs. non-working days for a months period
   * @param JDCConnection
   * @param iFromYear int Year to start from
   * @param iFromMonth int Month to start from [0..11]
   * @parm nMonths int Number of months to retrieve (>0)
   * @return Array of short values one for each day starting from the given year and month and lasting n-months.
   * Each value of the array may be 1 meaning a WorkDay, -1 meaning a Holyday or 0 meaning that the day is
   * not defined neither as Workday nor as Holyday at this calendar.
   * @throws IllegalArgumentException if iFromYear<1900 or iFromMonth not between 0 and 11 or nMonths is less than 1
   * @throws SQLException
   */
  public short[] getWorkDaysArray(JDCConnection oConn, int iFromYear, int iFromMonth, int nMonths)
  	throws IllegalArgumentException,SQLException {

	if (iFromYear<1900) throw new IllegalArgumentException("WorkingCalendar.getWorkDaysArray() year must be greater than 1900");
	if (iFromMonth<0 || iFromMonth>11) throw new IllegalArgumentException("WorkingCalendar.getWorkDaysArray() month must be between 0 and 11");
	if (nMonths<1) throw new IllegalArgumentException("WorkingCalendar.getWorkDaysArray() months must be greater than zero");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkingCalendar.getWorkDaysArray([JDCConnection],"+String.valueOf(iFromYear)+","+String.valueOf(iFromMonth)+","+String.valueOf(nMonths)+")");
      DebugFile.incIdent();
    }
  	
  	final short ISWORKDAY = (short) 1;
  	final short ISHOLIDAY = (short) -1;
  	final short ISUNDEFINED = (short) -1;

  	int iNextYear = iFromYear;
  	int iNextMonth = iFromMonth;	

	for (int m=0; m<nMonths; m++) {
	  if (++iNextMonth>11) {
	  	iNextMonth = 0;
	  	iNextYear++; 
	  } // fi	  
	} // next

  	GregorianCalendar cFrom = new GregorianCalendar(iFromYear, iFromMonth, 1);
  	GregorianCalendar cNext = new GregorianCalendar(iNextYear, iNextMonth, Calendar.LastDay(iNextMonth, iNextYear));
  	
  	int iFrom = (10000*(cFrom.get(GregorianCalendar.YEAR)))+(100*cFrom.get(GregorianCalendar.MONTH))+cFrom.get(GregorianCalendar.DAY_OF_MONTH);
    int iNext = (10000*(cNext.get(GregorianCalendar.YEAR)))+(100*cNext.get(GregorianCalendar.MONTH))+cNext.get(GregorianCalendar.DAY_OF_MONTH);

  	int nTotalDays = Calendar.DaysBetween(cFrom, cNext);
  	short[] aDays = new short[nTotalDays];
	Arrays.fill(aDays,ISUNDEFINED);
  	
  	DBSubset oWrkTime = new DBSubset (DB.k_working_time,
  	                                  DB.dt_day+","+DB.bo_working_time,
  									  DB.gu_calendar+"=? AND "+DB.dt_day+" BETWEEN ? AND ? ORDER BY 1", nTotalDays);
	oWrkTime.setMaxRows(nTotalDays);
	int nCalDays = oWrkTime.load (oConn, new Object[]{oCalendarInfo.get(DB.gu_calendar), new Integer(iFrom), new Integer(iNext)});
	
	if (nCalDays>0) {
	  int iCurDate = iFrom;
	  int iCurPos = 0, iCalPos = 0;
	  do {
	  	if (iCalPos<nCalDays) {		
		  if (oWrkTime.getInt(0,iCalPos)==iCurDate)
		    aDays[iCurPos] = (oWrkTime.getShort(1, iCalPos++)==0 ? ISHOLIDAY : ISWORKDAY);
	  	}// fi (iCalPos<nCalDays)

		iCurPos++;

	    // Move current date to next day
	    int iYear = (iCurDate / 10000);
	    int iMnth = (iCurDate / 100)-(iYear*100);
	    int iMDay = (iCurDate % 100);
	    if (iMDay<Calendar.LastDay(iMnth,iYear))
	      iCurDate++;
	    else if (iMnth<11)
	      iCurDate = (iYear*10000)+((iMnth+1)*100)+1;
	    else
	      iCurDate = ((iYear+1)*10000)+1;
	  } while (iCurPos<nTotalDays);
	} // fi (DefinedDays)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkingCalendar.getWorkDaysArray() : "+String.valueOf(nTotalDays));
    }

	return aDays;
	
  } // getWorkDaysArray

  // --------------------------------------------------------------------------
  
  public String getString(String sColumnName) {
  	return oCalendarInfo.getString(sColumnName);
  }

  // --------------------------------------------------------------------------
  
  public String getStringNull(String sColumnName, String sDefault) {
  	return oCalendarInfo.getStringNull(sColumnName,sDefault);
  }

  // --------------------------------------------------------------------------
  
  public String getName() {
  	return oCalendarInfo.getString(DB.nm_calendar);
  }

  // --------------------------------------------------------------------------
  
  public Date getCreationDate(JDCConnection oConn) throws SQLException {
  	return oCalendarInfo.getCreationDate(oConn);
  }

  // --------------------------------------------------------------------------
  
  public Date getFromDate() {
  	return oCalendarInfo.getDate(DB.dt_from);
  }

  // --------------------------------------------------------------------------
  
  public Date getToDate() {
  	return oCalendarInfo.getDate(DB.dt_to);
  }

  // --------------------------------------------------------------------------
  
  public void put(String sColunmName, String sValue) {
  	oCalendarInfo.put(sColunmName, sValue);
  }

  // --------------------------------------------------------------------------
  
  public void put(String sColunmName, int iValue) {
  	oCalendarInfo.put(sColunmName, iValue);
  }

  // --------------------------------------------------------------------------
  
  public void put(String sColunmName, Date dtValue) {
  	oCalendarInfo.put(sColunmName, dtValue);
  }
  
  // --------------------------------------------------------------------------

  private void copyDay(WorkingCalendar oSource, int iSourceDateIndex, int iTargetDateIndex) {
	aDates[iTargetDateIndex] = oSource.aDates[iSourceDateIndex];  	
	aWorkingTimes[iTargetDateIndex] = oSource.aWorkingTimes[iSourceDateIndex];
	aStartHour1[iTargetDateIndex] = oSource.aStartHour1[iSourceDateIndex];
	aStartMin1[iTargetDateIndex] = oSource.aStartMin1[iSourceDateIndex];
	aEndHour1[iTargetDateIndex] = oSource.aEndHour1[iSourceDateIndex];
	aEndMin1[iTargetDateIndex] = oSource.aEndMin1[iSourceDateIndex];
	aStartHour2[iTargetDateIndex] = oSource.aStartHour2[iSourceDateIndex];
	aStartMin2[iTargetDateIndex] = oSource.aStartMin2[iSourceDateIndex];
	aEndHour2[iTargetDateIndex] = oSource.aEndHour2[iSourceDateIndex];
	aEndMin2[iTargetDateIndex] = oSource.aEndMin2[iSourceDateIndex];
	aDescs[iTargetDateIndex] = oSource.aDescs[iSourceDateIndex];  
  } // copyDay

  // --------------------------------------------------------------------------

  public WorkingCalendar merge(WorkingCalendar oLocalCalendar)
    throws NullPointerException {
	WorkingCalendar oRetVal;

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin WorkingCalendar.merge("+oLocalCalendar.oCalendarInfo.getStringNull(DB.nm_calendar,"")+")");
	  DebugFile.writeln(getName()+" has "+String.valueOf(getDayCount())+" days settings");
	  DebugFile.writeln(oLocalCalendar.getName()+" has "+String.valueOf(oLocalCalendar.getDayCount())+" days settings");
	  DebugFile.incIdent();
	}

	int nThisDates = getDayCount();
	int nLocalDates = oLocalCalendar.getDayCount();
	
	if (nLocalDates==0) {
	  oRetVal = this;
	} else if (nThisDates==0) {
	  oRetVal = oLocalCalendar;
	} else {
	  TreeSet oUnionDates = new TreeSet();
	  for (int d=0; d<nThisDates; d++) {
	  	oUnionDates.add(String.valueOf(aDates[d]));
	  } // next
	  for (int d=0; d<nLocalDates; d++) {
	  	String sDate = String.valueOf(oLocalCalendar.aDates[d]);
	  	if (!oUnionDates.contains(sDate))
	  	  oUnionDates.add(sDate);
	  } // next
	  int nUnionDates = oUnionDates.size();
	  oRetVal = new WorkingCalendar(nUnionDates,
	  	                            getStringNull(DB.nm_calendar,"")+"+"+oLocalCalendar.getStringNull(DB.nm_calendar,""),
	  	                            toDate(oUnionDates.first().toString()),
	  	                            toDate(oUnionDates.last().toString()));
	  Iterator oIter = oUnionDates.iterator();
	  int iCurrentDateIndex = 0;
	  while (oIter.hasNext()) {
	    int iDate = Integer.parseInt((String) oIter.next());
  		int iLocalDateIndex = Arrays.binarySearch(oLocalCalendar.aDates, iDate);
		if (iLocalDateIndex>=0) {
		  if (DebugFile.trace) DebugFile.write("Taking "+String.valueOf(iDate)+" from "+oLocalCalendar.getName());
		  oRetVal.copyDay(oLocalCalendar, iLocalDateIndex, iCurrentDateIndex);
		} else {
		  if (DebugFile.trace) DebugFile.write("Taking "+String.valueOf(iDate)+" from "+getName());
  		  int iThisDateIndex = Arrays.binarySearch(aDates, iDate);
		  oRetVal.copyDay(this, iThisDateIndex, iCurrentDateIndex);
		} // fi
		iCurrentDateIndex++;
	  } // wend
	} // fi

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End WorkingCalendar.merge() : " + oRetVal.getName() + " " + String.valueOf(oRetVal.getDayCount()) +" days settings");
	}

	return oRetVal;
  } // merge

  // --------------------------------------------------------------------------

  public static WorkingCalendar create(JDCConnection oConn,
  									   int iDomainId, String sWorkAreaId, String sCalendarName,
                                       Date dtFrom, Date dtTo, String sGroupId, String sUserId,
                                       String sCountryId, String sStateId, String sZoneId,
  					  				   short MorningHourStart, short MorningMinuteStart,
  					  				   short MorningHourEnd, short MorningMinuteEnd,
  					  				   short EveningHourStart, short EveningMinuteStart,
  					  				   short EveningHourEnd, short EveningMinuteEnd,
  					  				   Set oWeeklyHolidays)
    throws SQLException, NullPointerException {
    	
    if (null==sWorkAreaId) throw new NullPointerException("WorkingCalendar.create workarea guid cannot be null");
    if (null==sCalendarName) throw new NullPointerException("WorkingCalendar.create calendar name cannot be null");
    if (sCalendarName.length()==0) throw new NullPointerException("WorkingCalendar.create calendar name cannot be empty");
    if (null==dtFrom) throw new NullPointerException("WorkingCalendar.create date from cannot be null");
    if (null==dtTo) throw new NullPointerException("WorkingCalendar.create date to cannot be null");

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin WorkingCalendar.create(JDCConnection,"+String.valueOf(iDomainId)+","+
  	  					sWorkAreaId+","+sCalendarName+","+dtFrom+","+dtTo+","+sGroupId+","+
  	  					sUserId+","+sCountryId+","+sStateId+","+sZoneId+")");
  	  DebugFile.incIdent();					
  	}
	Timestamp tmFrom = new Timestamp(dtFrom.getTime());
	Timestamp tmTo = new Timestamp(dtTo.getTime());
	
  	String sSQL = "SELECT NULL FROM "+DB.k_working_calendar+
  				  " WHERE "+DB.id_domain+"=? AND "+DB.gu_workarea+"=? AND "+
  				  DBBind.Functions.ISNULL+"("+DB.gu_acl_group+")=? AND "+DBBind.Functions.ISNULL+"("+DB.gu_user+")=? AND "+
  				  DBBind.Functions.ISNULL+"("+DB.id_country+")=? AND "+DBBind.Functions.ISNULL+"("+DB.id_state+")=? AND "+
  				  DBBind.Functions.ISNULL+"("+DB.gu_geozone+")=? AND "+
  				  "("+DB.dt_from+" BETWEEN ? AND ? OR "+DB.dt_to+" BETWEEN ? AND ? OR ("+DB.dt_from+"<=? AND "+DB.dt_to+">=?))";
  	PreparedStatement oStmt = oConn.prepareStatement(sSQL, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

  	oStmt.setInt   (1, iDomainId);
  	oStmt.setString(2, sWorkAreaId);
  	oStmt.setString(3, sGroupId==null ? "" : sGroupId);
  	oStmt.setString(4, sUserId==null ? "" : sUserId);
  	oStmt.setString(5, sCountryId==null ? "" : sCountryId);
  	oStmt.setString(6, sStateId==null ? "" : sStateId);
  	oStmt.setString(7, sZoneId==null ? "" : sZoneId);
  	oStmt.setTimestamp(8 , tmFrom);
  	oStmt.setTimestamp(9 , tmTo);
  	oStmt.setTimestamp(10, tmFrom);
  	oStmt.setTimestamp(11, tmTo);
  	oStmt.setTimestamp(12, tmFrom);
  	oStmt.setTimestamp(13, tmTo);
  	ResultSet oRSet = oStmt.executeQuery();
  	boolean bAlreadyExists = oRSet.next();
  	oRSet.close();
  	oStmt.close();
  	
  	if (bAlreadyExists) {
  	  DebugFile.decIdent();					
	  throw new SQLException("WorkingCalendar.create another calendar for the same time period, group, user and geographicla zone already exists");
  	}

    WorkingCalendar oNewCal = new WorkingCalendar();
    oNewCal.oCalendarInfo.put(DB.gu_calendar, Gadgets.generateUUID());
    oNewCal.oCalendarInfo.put(DB.nm_calendar, sCalendarName);
    oNewCal.oCalendarInfo.put(DB.gu_workarea, sWorkAreaId);
    oNewCal.oCalendarInfo.put(DB.id_domain, iDomainId);
    oNewCal.oCalendarInfo.put(DB.dt_from, dtFrom);
    oNewCal.oCalendarInfo.put(DB.dt_to, dtTo);
    if (null!=sGroupId) oNewCal.oCalendarInfo.put(DB.gu_acl_group, sGroupId);
    if (null!=sUserId) oNewCal.oCalendarInfo.put(DB.gu_user, sUserId);
    if (null!=sCountryId) oNewCal.oCalendarInfo.put(DB.id_country, sCountryId);
    if (null!=sStateId) oNewCal.oCalendarInfo.put(DB.id_state, sStateId);
    if (null!=sZoneId) oNewCal.oCalendarInfo.put(DB.gu_geozone, sZoneId);
	oNewCal.store(oConn);
	
	oNewCal.addWorkingTime(oConn, dtFrom, dtTo,
  					       MorningHourStart, MorningMinuteStart,
  					       MorningHourEnd, MorningMinuteEnd,
  					       EveningHourStart, EveningMinuteStart,
  					       EveningHourEnd, EveningMinuteEnd,
  					  	   oWeeklyHolidays, null);
		
  	if (DebugFile.trace) {
  	  DebugFile.decIdent();					
  	  DebugFile.writeln("End WorkingCalendar.create() : "+oNewCal.oCalendarInfo.getString(DB.gu_calendar));
  	}
	return oNewCal;
  } // create

  // --------------------------------------------------------------------------

  public static WorkingCalendar create(JDCConnection oConn,
  									   int iDomainId, String sWorkAreaId, String sCalendarName,
                                       Date dtFrom, Date dtTo, String sGroupId, String sUserId,
                                       String sCountryId, String sStateId, String sZoneId,
  					  				   Set oWeeklyHolidays)
    throws SQLException, NullPointerException {
  	return WorkingCalendar.create(oConn, iDomainId, sWorkAreaId, sCalendarName,
                                  dtFrom, dtTo, sGroupId, sUserId,
                                  sCountryId, sStateId, sZoneId,
  					  		      VOID, VOID, VOID, VOID,
  					  			  VOID, VOID, VOID, VOID,
  					  			  oWeeklyHolidays);
  } // create

  // --------------------------------------------------------------------------

  public static void delete(JDCConnection oConn, String sGuCalendar) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin WorkingCalendar.delete([JDCConnection], "+sGuCalendar+")");
      DebugFile.incIdent();
    }
	Statement oStmt = oConn.createStatement();

    if (DebugFile.trace) DebugFile.writeln("Connection.executeUpdate(DELETE FROM "+DB.k_working_time+" WHERE "+DB.gu_calendar+"='"+sGuCalendar+"'");

	oStmt.executeUpdate("DELETE FROM "+DB.k_working_time+" WHERE "+DB.gu_calendar+"='"+sGuCalendar+"'");

    if (DebugFile.trace) DebugFile.writeln("Connection.executeUpdate(DELETE FROM "+DB.k_working_calendar+" WHERE "+DB.gu_calendar+"='"+sGuCalendar+"'");

	oStmt.executeUpdate("DELETE FROM "+DB.k_working_calendar+" WHERE "+DB.gu_calendar+"='"+sGuCalendar+"'");
			
	oStmt.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WorkingCalendar.delete()");
    }
  } // delete

  // --------------------------------------------------------------------------

  public static Date toDate(int iDt) {
    return new Date((iDt/10000)-1900,(iDt/100)-((iDt/10000)*100), iDt-((iDt/100)*100));    
  }

  // --------------------------------------------------------------------------

  public static Date toDate(String sYear, String sMonth, String sDate)
  	throws NumberFormatException {
    return new Date(Integer.parseInt(sYear)-1900,Integer.parseInt(sMonth),Integer.parseInt(sDate));
  }

  // --------------------------------------------------------------------------

  public static Date toDate(String sYearMonthDate)
  	throws NumberFormatException {
    return new Date(Integer.parseInt(sYearMonthDate.substring(0,4))-1900,Integer.parseInt(sYearMonthDate.substring(4,6)),Integer.parseInt(sYearMonthDate.substring(6,8)));
  }

  // --------------------------------------------------------------------------

  public static DBSubset byGroup(JDCConnection oConn, int iDomainId, String sWorkAreaId)
    throws SQLException,NullPointerException {
    DBPersist oWCal = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
    DBSubset oCalendarsByGroup = new DBSubset(DB.k_working_calendar + " c",
											  oWCal.getTable(oConn).getColumnsStr(),
    									      DB.gu_workarea+"=? AND "+DB.id_domain+"=? AND "+
    									      DB.gu_acl_group+" IS NOT NULL ORDER BY "+DB.nm_calendar, 10);
    			
    oCalendarsByGroup.load(oConn, new Object[]{new Integer(iDomainId),sWorkAreaId});
    return oCalendarsByGroup;
  } // byGroup

  // --------------------------------------------------------------------------

  public static DBSubset byUser(JDCConnection oConn, int iDomainId, String sWorkAreaId)
    throws SQLException,NullPointerException {
    DBPersist oWCal = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
    DBSubset oCalendarsByUser = new DBSubset(DB.k_working_calendar + " c",
											  oWCal.getTable(oConn).getColumnsStr(),
    									      DB.gu_workarea+"=? AND "+DB.id_domain+"=? AND "+
    									      DB.gu_user+" IS NOT NULL ORDER BY "+DB.nm_calendar, 100);
    			
    oCalendarsByUser.load(oConn, new Object[]{new Integer(iDomainId),sWorkAreaId});
    return oCalendarsByUser;
  } // byUser

  // --------------------------------------------------------------------------

  public static DBSubset byCountry(JDCConnection oConn, int iDomainId, String sWorkAreaId, String sLanguage)
    throws SQLException,NullPointerException {
    DBPersist oWCal = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
    DBPersist oCntr = new DBPersist(DB.k_lu_countries,"Countries");
    String sTrCol;
    if (oCntr.getTable(oConn).getColumnsStr().indexOf(DB.tr_+sLanguage)>=0)
      sTrCol = DB.tr_+"country_"+sLanguage;
    else
      sTrCol = DB.tr_+"country_"+"en";

    DBSubset oCalendarsByCountry = new DBSubset(DB.k_working_calendar + " c",
											    oWCal.getTable(oConn).getColumnsStr()+", NULL AS nm_country",
    									        DB.gu_workarea+"=? AND "+DB.id_domain+"=? AND "+
    									        DB.id_country+" IS NOT NULL", 50);
    			
    int nCals = oCalendarsByCountry.load(oConn, new Object[]{new Integer(iDomainId),sWorkAreaId});
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+sTrCol+" FROM "+DB.k_lu_countries+" WHERE "+DB.id_country+"=?",
    												 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    for (int c=0; c<nCals; c++) {
	  oStmt.setString(1, oCalendarsByCountry.getString(DB.id_country,c));
	  ResultSet oRSet = oStmt.executeQuery();
	  if (oRSet.next()) {
	    oCalendarsByCountry.setElementAt(oRSet.getString(1),"nm_country",c);
	  } else {
	    oCalendarsByCountry.setElementAt("","nm_country",c);	  
	  }
	  oRSet.close();
    } // next
	oStmt.close();
	oCalendarsByCountry.sortBy(oCalendarsByCountry.getColumnPosition("nm_country"));
    return oCalendarsByCountry;
  } // byCountry

  // --------------------------------------------------------------------------

  public static DBSubset byState(JDCConnection oConn, int iDomainId, String sWorkAreaId, String sCountryId)
    throws SQLException,NullPointerException {
    DBPersist oWCal = new DBPersist(DB.k_working_calendar,"WorkingCalendar");
    DBSubset oCalendarsByState = new DBSubset(DB.k_working_calendar + " c",
											  oWCal.getTable(oConn).getColumnsStr()+", NULL AS "+DB.nm_state,
    									      DB.gu_workarea+"=? AND "+DB.id_domain+"=? AND "+
    									      DB.id_country+"=? AND "+DB.id_state+" IS NOT NULL", 50);
    			
    int nCals = oCalendarsByState.load(oConn, new Object[]{new Integer(iDomainId),sWorkAreaId,sCountryId});
    PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.nm_state+" FROM "+DB.k_lu_states+" WHERE "+DB.id_country+"='"+sCountryId+"' AND "+DB.id_state+"=?",
    												 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    for (int c=0; c<nCals; c++) {
	  oStmt.setString(1, oCalendarsByState.getString(DB.id_state,c));
	  ResultSet oRSet = oStmt.executeQuery();
	  if (oRSet.next()) {
	    oCalendarsByState.setElementAt(oRSet.getString(1),DB.nm_state,c);
	  } else {
	    oCalendarsByState.setElementAt("",DB.nm_state,c);	  
	  }
	  oRSet.close();
    } // next
	oStmt.close();
	oCalendarsByState.sortBy(oCalendarsByState.getColumnPosition(DB.nm_state));
    return oCalendarsByState;
  } // byState

  // --------------------------------------------------------------------------

  public static WorkingCalendar forUser(JDCConnection oConn, String sUserId,
  										Date dtFrom, Date dtTo,
  									    String sCountryId, String sStateId)
    throws SQLException,NullPointerException {

    WorkingCalendar oRetCal, oCurCal;
    String sName = "";
 
 	if (DebugFile.trace) {
 	  DebugFile.writeln("Begin WorkingCalendar.forUser([JDCConnection], "+sUserId+","+dtFrom+","+dtTo+","+sCountryId+","+sStateId);
 	  DebugFile.incIdent();
 	}

    ACLUser oUser = new ACLUser(oConn, sUserId);
	Timestamp tmFrom = new Timestamp(dtFrom.getTime());
	Timestamp tmTo = new Timestamp(dtTo.getTime());
    DBSubset oGroupCalendars = new DBSubset(DB.k_working_calendar + " c",
    										"c."+DB.gu_calendar+",c."+DB.gu_acl_group+",c."+DB.gu_user+",c."+DB.gu_geozone+",c."+DB.id_country+",c."+DB.id_state,
    									    "c."+DB.gu_workarea+"=? AND c."+DB.id_domain+"=? AND "+
    										"(c."+DB.gu_user+"=? OR EXISTS (SELECT g."+DB.gu_acl_group+" FROM "+DB.k_x_group_user+" g WHERE g."+DB.gu_acl_group+"=c."+DB.gu_acl_group+" AND g."+DB.gu_user+"=?)) AND "+
    										"(c."+DB.dt_from+" BETWEEN ? AND ? OR c."+DB.dt_to+" BETWEEN ? AND ? OR (c."+DB.dt_from+"<=? AND c."+DB.dt_to+">=?)) "+
    										"ORDER BY c."+DB.dt_from, 4);
    int nCals = oGroupCalendars.load(oConn, new Object[]{oUser.get(DB.gu_workarea),oUser.get(DB.id_domain),
                                                         sUserId, sUserId,
                                                         tmFrom,tmTo,tmFrom,tmTo,tmFrom,tmTo});
    if (0==nCals) {
      oRetCal = null;
    } else {
      oRetCal = new WorkingCalendar();
      // Place at the bottom of the stack the group calendars without country nor state
 	  if (DebugFile.trace) DebugFile.writeln("Scanning group calendars...");
      for (int c=0; c<nCals; c++) {
      	if (oGroupCalendars.isNull(DB.gu_user,c) && oGroupCalendars.isNull(DB.id_country,c) && oGroupCalendars.isNull(DB.id_state,c)) {
 	  	  if (DebugFile.trace) DebugFile.writeln("Found group calendar "+oGroupCalendars.getString(DB.gu_calendar,c));
      	  oCurCal = new WorkingCalendar (oConn, oGroupCalendars.getString(DB.gu_calendar,c));
      	  oRetCal = oRetCal.merge(oCurCal);
      	  sName += (sName.length()==0 ? "" : "+") + oCurCal.getName();
      	} // fi
      } // next
 	  if (DebugFile.trace) DebugFile.writeln("Scanning country calendars...");
      // The second layer are group calendars for whole countries
      if (sCountryId!=null) {
        for (int c=0; c<nCals; c++) {
      	  if (oGroupCalendars.isNull(DB.gu_user,c) && sCountryId.equals(oGroupCalendars.getStringNull(DB.id_country,c,"")) && oGroupCalendars.isNull(DB.id_state,c)) {
 	  	    if (DebugFile.trace) DebugFile.writeln("Found country calendar "+oGroupCalendars.getString(DB.gu_calendar,c));
      	    oCurCal = new WorkingCalendar (oConn, oGroupCalendars.getString(DB.gu_calendar,c));
      	    oRetCal = oRetCal.merge(oCurCal);
      	    sName += (sName.length()==0 ? "" : "+") + oCurCal.getName();
      	  } // fi
        } // next
      }
      // The third layer are calendars for states
      if (sStateId!=null) {
 	    if (DebugFile.trace) DebugFile.writeln("Scanning state calendars...");
        for (int c=0; c<nCals; c++) {
      	  if (oGroupCalendars.isNull(DB.gu_user,c) && !oGroupCalendars.isNull(DB.id_country,c) && sStateId.equals(oGroupCalendars.getStringNull(DB.id_state,c,""))) {
 	  	    if (DebugFile.trace) DebugFile.writeln("Found state calendar "+oGroupCalendars.getString(DB.gu_calendar,c));
      	    oCurCal = new WorkingCalendar (oConn, oGroupCalendars.getString(DB.gu_calendar,c));
      	    oRetCal = oRetCal.merge(oCurCal);
      	    sName += (sName.length()==0 ? "" : "+") + oCurCal.getName();
      	  } // fi
        } // next
      }
      // The top layer are calendars for a single user
      for (int c=0; c<nCals; c++) {
      	if (!oGroupCalendars.isNull(DB.gu_user,c)) {
      	  oCurCal = new WorkingCalendar (oConn, oGroupCalendars.getString(DB.gu_calendar,c));
      	  oRetCal = oRetCal.merge(oCurCal);
      	  sName += (sName.length()==0 ? "" : "+") + oCurCal.getName();
      	} // fi
      } // next
      oRetCal.oCalendarInfo.replace(DB.nm_calendar, sName);
    } // fi

 	if (DebugFile.trace) {
 	  DebugFile.decIdent();
 	  if (null==oRetCal)
 	    DebugFile.writeln("End WorkingCalendar.forUser() : null");
 	  else
 	    DebugFile.writeln("End WorkingCalendar.forUser() : " + sName + " " + String.valueOf(oRetCal.getDayCount()) + " days settings");
 	} // fi
    
    return oRetCal;
  } // forUser

  // --------------------------------------------------------------------------

  public static final short ClassId = 24;

}
