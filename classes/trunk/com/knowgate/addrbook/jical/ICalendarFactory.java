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

package com.knowgate.addrbook.jical;

import java.io.File;

import java.util.Date;
import java.util.Locale;
import java.util.Iterator;
import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.ACL;
import com.knowgate.acl.ACLUser;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.hipergate.DBLanguages;
import com.knowgate.addrbook.*;

import org.jical.ICalendar;
import org.jical.ICalendarParser;
import org.jical.ICalendarVEvent;

/**
 * <p>Create an ICalendar object for a given hipergate Fellow meetings</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class ICalendarFactory {
  public ICalendarFactory() {
  }

  // ---------------------------------------------------------------------------

  private static String duration(Date dtStart, Date dtEnd) {
    final long lSecond = 1000;
    final long lMinute = lSecond*60l;
    final long lHour = lMinute*60l;
    final long lDay = lHour*24l;
    long lDuration = dtEnd.getTime()-dtStart.getTime();
    return (lDuration>=0 ? "" : "-")+"P"+String.valueOf(lDuration/lDay)+"DT"+String.valueOf(lDuration/lHour)+"H"+String.valueOf(lDuration/lMinute)+"M"+String.valueOf(lDuration/lSecond)+"S";
  }

  // ---------------------------------------------------------------------------

  /**
   * Get an <a href="http://www.ietf.org/rfc/rfc2445.txt">RFC 2445</a> calendar for a Fellow
   * @param oConn JDCConnection
   * @param sGuFellow String Fellow GUID from k_fellows table
   * @param dtFrom Date from which to start exporting meetings
   * @param dtTo Date when stop exporting meetings
   * @param sLanguage String Two letter identifier of language to be used if this parameter is <b>null</b> then the default Locale is used.
   * @return ICalendar
   * @throws SQLException If not fellow with specified GUID is found at k_fellows table
   * @throws IllegalArgumentException if dtFrom>dtTo
   * @throws NullPointerException if sGuFellow or dtFrom or dtTo is <b>null</b>
   */
  public static ICalendar createICalendar(JDCConnection oConn, String sGuFellow,
                                          Date dtFrom, Date dtTo, String sLanguage)
    throws SQLException,IllegalArgumentException,NullPointerException {
    ICalendarVEvent oEvt;
    String sTpRoom, sOrganizerName, sOrganizerMail;
    Date dtNow = new Date();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ICalendarFactory([JDCConnection],"+sGuFellow+","+dtFrom.toString()+","+dtTo.toString()+","+sLanguage+")");
      DebugFile.incIdent();
    }

    if (sGuFellow==null) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("ICalendarFactory.createICalendar() Fellow GUID parameter is required");
    }

    if (dtFrom==null || dtTo==null) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("ICalendarFactory.createICalendar() Both start and end date are required");
    }

    if (dtFrom.compareTo(dtTo)>0) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new IllegalArgumentException("ICalendarFactory.createICalendar() End date cannot be prior to start date");
    }

    if (sLanguage==null) sLanguage=Locale.getDefault().getLanguage();

    Fellow oFlw = new Fellow();
    if (!oFlw.load(oConn, new Object[]{sGuFellow})) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new SQLException("Fellow "+sGuFellow+" not found at "+DB.k_fellows+" table");
    }
    DBSubset oMeetings = new DBSubset (DB.k_meetings+" m,"+DB.k_x_meeting_fellow+" f",
                                       "m."+DB.gu_meeting+",m."+DB.dt_start+",m."+DB.dt_end+","+
                                       "m."+DB.bo_private+",m."+DB.gu_writer+",m."+DB.df_before+","+
                                       "m."+DB.tp_meeting+",m."+DB.tx_meeting+",m."+DB.de_meeting+","+
                                       "m."+DB.tx_status,
                                       "f."+DB.gu_fellow+"=? AND m."+DB.gu_fellow+"=f."+DB.gu_fellow, 100);
    int iMeetings = oMeetings.load(oConn, new Object[]{sGuFellow});

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iMeetings)+" meetings found");

    DBSubset oRooms = new DBSubset(DB.k_x_meeting_room+" x,"+DB.k_rooms+" r",
                                   "r."+DB.gu_workarea+",r."+DB.tp_room+",r."+DB.nm_room+","+"r."+DB.tx_location,
                                   "x."+DB.gu_meeting+"=? AND "+"x."+DB.nm_room+"=r."+DB.nm_room,2);
    int iRooms;

    ICalendar oCal = new ICalendar();
    oCal.setProdId("JICAL");
    oCal.setVersion("2.0");
    for (int m=0; m<iMeetings; m++) {
      if (DebugFile.trace) DebugFile.writeln("Loading meeting "+oMeetings.getStringNull(7,m,""));
      oEvt = new ICalendarVEvent(oMeetings.getDate(1,m),oMeetings.getDate(2,m),
                                 oMeetings.getStringNull(8,m,""),
                                 duration(oMeetings.getDate(1,m),oMeetings.getDate(2,m)),
                                 oMeetings.getStringNull(7,m,""), null, null);
      oEvt.setSequence(0);
      oEvt.setDateStamp(dtNow);
      oEvt.setCreated(dtNow);
      oEvt.setLastModified(dtNow);
      oEvt.setEventClass(oMeetings.getShort(3,m)==0 ? "PUBLIC" : "PRIVATE");
      oEvt.setTransparency("OPAQUE");
      if (!oMeetings.isNull(6,m)) oEvt.setCategories(oMeetings.getString(6,m));
      if (oMeetings.isNull(4,m) || sGuFellow.equals(oMeetings.get(4,m))) {
        sOrganizerName = (oFlw.getStringNull(DB.tx_name,"")+" "+oFlw.getStringNull(DB.tx_surname,"")).trim();
        sOrganizerMail = oFlw.getStringNull(DB.tx_email,"");
      } else {
        ACLUser oWrt = new ACLUser();
        if (oWrt.load(oConn, new Object[]{oMeetings.get(4,m)})) {
          sOrganizerName = (oFlw.getStringNull(DB.nm_user,"")+" "+oFlw.getStringNull(DB.tx_surname1,"")+" "+oFlw.getStringNull(DB.tx_surname2,"")).trim();
          sOrganizerMail = oFlw.getStringNull(DB.tx_main_email,"");
        } else {
          sOrganizerName = (oFlw.getStringNull(DB.tx_name,"")+" "+oFlw.getStringNull(DB.tx_surname,"")).trim();
          sOrganizerMail = oFlw.getStringNull(DB.tx_email,"");
        }
      }
      if (DebugFile.trace) DebugFile.writeln("Organizer is \""+sOrganizerName+"\" <"+sOrganizerMail+">");
      oEvt.setOrganizer("CN=:\""+sOrganizerName.replace((char)34,(char)32)+"\":MAILTO:"+sOrganizerMail);
      oEvt.setUid("hipergate-"+oMeetings.getString(0,m));
      oEvt.setPriority(3);
      if (!oMeetings.isNull(9,m)) oEvt.setStatus(oMeetings.getString(9,m));
      iRooms = oRooms.load(oConn, new Object[]{oMeetings.getString(0,m)});
      if (iRooms>0) {
        if (DebugFile.trace) DebugFile.writeln(String.valueOf(iRooms)+" rooms found");
        if (sLanguage!=null)
          sTpRoom = DBLanguages.getLookUpTranslation(oConn, DB.k_rooms_lookup, oRooms.getString(1,0), DB.tp_room, sLanguage, oRooms.getString(2,0));
        else
          sTpRoom = null;
        if (null==sTpRoom) sTpRoom=""; else sTpRoom+=" ";
        oEvt.setLocation(sTpRoom+oRooms.getString(2,0)+(oRooms.isNull(3,0) ? "" : " "+oRooms.getStringNull(3,0,"")));
      }
      oCal.icalEventCollection.add(oEvt);
    } // next
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ICalendarFactory()");
    }
    return oCal;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get an <a href="http://www.ietf.org/rfc/rfc2445.txt">RFC 2445</a> calendar for a Fellow
   * @param oConn JDCConnection
   * @param sTxEmail String Fellow e-mail. Must be that of tx_main-email of the corresponding User at k_users table.
   * @param sTxPwd String User password in clear text.
   * @param dtFrom Date from which to start exporting meetings
   * @param dtTo Date when stop exporting meetings
   * @param sLanguage String Two letter identifier of language to be used if this parameter is <b>null</b> then the default Locale is used.
   * @return ICalendar
   * @throws SQLException If not fellow with specified e-amil is found at k_users table
   * @throws IllegalArgumentException if dtFrom>dtTo
   * @throws NullPointerException if sGuFellow or dtFrom or dtTo is <b>null</b>
   * @throws SecurityException e-mail/password pair does not match the one set at the database
   */
  public static ICalendar createICalendar(JDCConnection oConn, String sTxEmail, String sTxPwd,
                                          Date dtFrom, Date dtTo, String sLanguage)
    throws SQLException,IllegalArgumentException,NullPointerException,SecurityException {

    String sGuFellow = ACLUser.getIdFromEmail(oConn, sTxEmail);

    if (null==sGuFellow)
      throw new SQLException(ACL.getErrorMessage(ACL.USER_NOT_FOUND));

    short iAuth = ACL.autenticate(oConn, sGuFellow, sTxPwd, ACL.PWD_CLEAR_TEXT);
    if (iAuth<0) throw new SecurityException(ACL.getErrorMessage(iAuth));

    return createICalendar(oConn, sGuFellow, dtFrom, dtTo, sLanguage);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Load a calendar file into k_meetings table</p>
   * @param oConn JDCConnection
   * @param sGuFellow String
   * @param oCalFile File
   * @param sEncoding String
   * @throws SQLException
   */
  public static void loadCalendar(JDCConnection oConn, String sGuFellow,
                                  File oCalFile, String sEncoding)
    throws SQLException {

    Meeting oMeet;
    String sGuid;
    String sCats;
    Fellow oFllw = new Fellow();
    if (!oFllw.load(oConn, new Object[]{sGuFellow})) {
      throw new SQLException(ACL.getErrorMessage(ACL.USER_NOT_FOUND));
    }
    Room oRoom = new Room();
    oRoom.put(DB.gu_workarea, oFllw.getString(DB.gu_workarea));

    ICalendarVEvent oEvnt;
    ICalendarParser oPrsr = new ICalendarParser();
    ICalendar oCal = oPrsr.parse(oCalFile, sEncoding);
    Iterator oIter = oCal.icalEventCollection.iterator();
    while (oIter.hasNext()) {
      oEvnt = (ICalendarVEvent) oIter.next();
      // remove - from Mozilla UIDs
      sGuid = Gadgets.removeChar(oEvnt.getUid(),'-').trim();
      sCats = oEvnt.getCategories();
      if (sCats!=null) sCats = (Gadgets.split(sCats,','))[0];
      oMeet = new Meeting();
      if (oMeet.load(oConn, new Object[]{sGuid})) {
        // Current meeting is only modified if the one comming in the iCalendar file is newer
        if (oMeet.lastModified().compareTo(oEvnt.getLastModified()==null ? new Date() : oEvnt.getLastModified())<0) {
          oMeet.replace(DB.dt_start, oEvnt.getDateStart());
          oMeet.replace(DB.dt_end, oEvnt.getDateEnd());
          if (null==oEvnt.getEventClass())
            oMeet.replace(DB.bo_private, (short)1);
          else
            oMeet.replace(DB.bo_private, (short)(oEvnt.getEventClass().equals("PRIVATE") ? 1 : 0));
          oMeet.replace(DB.tx_status, oEvnt.getStatus());
          oMeet.replace(DB.tp_meeting, sCats);
          oMeet.replace(DB.tx_meeting, oEvnt.getSummary());
          oMeet.replace(DB.tx_meeting, oEvnt.getDescription());
          oMeet.store(oConn);
        }
      } else {
        oMeet.put(DB.gu_meeting, sGuid);
        oMeet.put(DB.gu_workarea, oFllw.getString(DB.gu_workarea));
        oMeet.put(DB.id_domain, oFllw.getInt(DB.id_domain));
        oMeet.put(DB.gu_fellow, sGuFellow);
        oMeet.put(DB.gu_writer, sGuFellow);
        oMeet.put(DB.dt_start, oEvnt.getDateStart());
        oMeet.put(DB.dt_end, oEvnt.getDateEnd());
        if (null==oEvnt.getEventClass())
          oMeet.put(DB.bo_private, (short)1);
        else
          oMeet.put(DB.bo_private, (short)(oEvnt.getEventClass().equals("PRIVATE") ? 1 : 0));
        oMeet.put(DB.tx_status, oEvnt.getStatus());
        oMeet.replace(DB.tp_meeting, sCats);
        oMeet.put(DB.tx_meeting, oEvnt.getSummary());
        oMeet.put(DB.tx_meeting, oEvnt.getDescription());
        oMeet.store(oConn);
        oMeet.setAttendant(oConn, sGuFellow);
      }
      if (oEvnt.getLocation()!=null) {
        oRoom.replace(DB.nm_room, oEvnt.getLocation());
        if (oRoom.exists(oConn))
          oMeet.setRoom(oConn, oEvnt.getLocation());
      } // fi (getLocation())
    } // wend
  } // loadCalendar

  // ---------------------------------------------------------------------------

}
