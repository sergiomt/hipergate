/*
  Copyright (C) 2010  Know Gate S.L. All rights reserved.

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

package com.knowgate.addrbook.client;

import java.io.IOException;

import java.util.Date;
import java.util.ArrayList;

import java.text.SimpleDateFormat;

import org.jibx.runtime.JiBXException;

import com.knowgate.addrbook.client.CalendarRoom;
import com.knowgate.addrbook.client.CalendarMeeting;

/**
 * Calendar Service Client Library
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class CalendarServices {

  private String sSecurityToken = null;
  private String sBaseURL = null;
  private int iErrCode = 0;
  private String sErrMsg = null;
  private SimpleDateFormat oFmt = new SimpleDateFormat("yyyyMMddHHmmss");

  /**
     * Connect to Calendar Service
     * @param sURL String Service base URL like http://localhost/hipergate/servlet/HttpCalendarServlet
     * @param sUser String User e-mail (must exist at k_users and k_fellows tables)
     * @param sPassword String User password
     * @return <b>true</b> if successfully connected to the service
     * @throws JiBXException
     * @throws IOException
     */ 
  public boolean connect(String sURL, String sUser, String sPassword) throws JiBXException, IOException {

	CalendarResponse oResponse = CalendarResponse.get(sURL+"?command=connect&user="+sUser+"&password="+sPassword);
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      sBaseURL = sURL;
      sSecurityToken = oResponse.value;
      return true;
    } else {
      sBaseURL = null;
      sSecurityToken = null;
      return false;
    }
  } // connect

  /**
     * Disconnect from Calendar Service
     * @return <b>true</b> if successfully disconnected from the service
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public boolean disconnect()
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=disconnect&token="+sSecurityToken);
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.value.equalsIgnoreCase("true");
    } else {
      return false;
    }
  } // disconnect

  /**
     * Check whether a resource is available between two given dates
     * @param sNmRoom String Resource name
     * @param dtFrom Start date
     * @param dtTo End date
     * @return <b>true</b> if resource is available at given dates
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public boolean isAvailableRoom(String sNmRoom, Date dtFrom, Date dtTo)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=isAvailableRoom&token="+sSecurityToken+"&room="+URLEncode(sNmRoom)+"&startdate="+oFmt.format(dtFrom)+"&enddate="+oFmt.format(dtTo));
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.value.equalsIgnoreCase("true");
    } else {
      return false;
    }
  }

  /**
     * Get all resources
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public ArrayList<CalendarRoom> getRooms() throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=getRooms&token="+sSecurityToken);
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oRooms;
    } else {
      return null;
    }
  } // getRooms

  /**
     * Get all resources of a given type
     * @param sType String Resource Type
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public ArrayList<CalendarRoom> getRooms(String sType) throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=getRooms&token="+sSecurityToken+"&type="+sType);
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oRooms;
    } else {
      return null;
    }
  } // getRooms

  /**
     * Get all available resources between two dates
     * @param dtFrom Start date
     * @param dtTo End date
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public ArrayList<CalendarRoom> getAvailableRooms(Date dtFrom, Date dtTo)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=getAvailableRooms&token="+sSecurityToken+"&startdate="+oFmt.format(dtFrom)+"&enddate="+oFmt.format(dtTo));
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oRooms;
    } else {
      return null;
    }
  }

  /**
     * Get all available resources of a given type between two dates
     * @param dtFrom Start date
     * @param dtTo End date
     * @param sType String Resource type
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public ArrayList<CalendarRoom> getAvailableRooms(Date dtFrom, Date dtTo, String sType)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=getAvailableRooms&token="+sSecurityToken+"&type="+sType+"&startdate="+oFmt.format(dtFrom)+"&enddate="+oFmt.format(dtTo));
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oRooms;
    } else {
      return null;
    }
  }

  /**
     * Get meetings between two dates
     * @param dtFrom Start date
     * @param dtTo End date
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public ArrayList<CalendarMeeting> getMeetings(Date dtFrom, Date dtTo)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=getMeetings&token="+sSecurityToken+"&startdate="+oFmt.format(dtFrom)+"&enddate="+oFmt.format(dtTo));
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oMeetings;
    } else {
      return null;
    }
  }

  /**
     * Get meetings between two dates using a given resource
     * @param dtFrom Start date
     * @param dtTo End date
     * @param sNmRoom String Resource name
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public ArrayList<CalendarMeeting> getMeetingsForRoom(Date dtFrom, Date dtTo, String sNmRoom)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=getMeetingsForRoom&token="+sSecurityToken+"&startdate="+oFmt.format(dtFrom)+"&enddate="+oFmt.format(dtTo)+"&room="+URLEncode(sNmRoom));
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oMeetings;
    } else {
      return null;
    }
  }

  /**
     * Get meeting given its unique identifier
     * @param sUid String Meeting iCalendar or Global Unique Identifier
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public CalendarMeeting getMeeting(String sUid)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=getMeeting&token="+sSecurityToken+"&meeting="+sUid);
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oMeetings.get(0);
    } else {
      return null;
    }
  }

  /**
     * Add or update meeting to calendar
     * @param oMeet CalendarMeeting
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public CalendarMeeting storeMeeting(CalendarMeeting oMeet)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

    String sReq = sBaseURL + "?command=storeMeeting&token=" + sSecurityToken;
    sReq += "&meeting=" + oMeet.getId();
    sReq += "&title=" + URLEncode(oMeet.getTitle());
    sReq += "&description=" + URLEncode(oMeet.getDescription());
    sReq += "&startdate=" + oFmt.format(oMeet.getStartDate());
    sReq += "&enddate=" + oFmt.format(oMeet.getEndDate());
    sReq += "&privacy=" + (oMeet.isPrivate() ? "1" : "0");
    if (oMeet.getRooms()!=null) {
      sReq += "&rooms=" + URLEncode(oMeet.roomsList());
    }
    if (oMeet.getAttendants()!=null) {
      sReq += "&attendants=" + URLEncode(oMeet.attendantsList());
    }

	CalendarResponse oResponse = CalendarResponse.get(sReq);
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return oResponse.oMeetings.get(0);
    } else {
      return null;
    }
  }

  /**
     * Delete meeting from calendar
     * @param sUid String Meeting iCalendar or Global Unique Identifier
     * @throws IllegalStateException if not connected to calendar service
     * @throws JiBXException
     * @throws IOException
     */ 
  public boolean deleteMeeting(String sUid)
  	throws IllegalStateException, JiBXException, IOException {

	if (null==sSecurityToken) throw new IllegalStateException("Not connected to calendar service");

	CalendarResponse oResponse = CalendarResponse.get(sBaseURL+"?command=deleteMeeting&token="+sSecurityToken+"&meeting="+sUid);
  
    iErrCode = oResponse.code;
    sErrMsg = oResponse.error;

    if (iErrCode==0) {
      return true;
    } else {
      return false;
    }
  }

  // ----------------------------------------------------------

  /**
   * Return text enconded as an URL.
   * For example, "Tom's Bookmarks" is encodes as "Tom%27s%20Bookmarks"
   * @param sStr Text to encode
   * @return URL-encoded text
   */
  private String URLEncode (String sStr) {
    if (sStr==null) return null;

    int iLen = sStr.length();
    StringBuffer sEscaped = new StringBuffer(iLen+100);
    char c;
    for (int p=0; p<iLen; p++) {
      c = sStr.charAt(p);
      switch (c) {
        case ' ':
          sEscaped.append("%20");
          break;
        case '/':
          sEscaped.append("%2F");
          break;
        case '"':
          sEscaped.append("%22");
          break;
        case '#':
          sEscaped.append("%23");
          break;
        case '%':
          sEscaped.append("%25");
          break;
        case '&':
          sEscaped.append("%26");
          break;
        case (char)39:
          sEscaped.append("%27");
          break;
        case '+':
          sEscaped.append("%2B");
          break;
        case ',':
          sEscaped.append("%2C");
          break;
        case '=':
          sEscaped.append("%3D");
          break;
        case '?':
          sEscaped.append("%3F");
          break;
        case 'á':
          sEscaped.append("%E1");
          break;
        case 'é':
          sEscaped.append("%E9");
          break;
        case 'í':
          sEscaped.append("%ED");
          break;
        case 'ó':
          sEscaped.append("%F3");
          break;
        case 'ú':
          sEscaped.append("%FA");
          break;
        case 'Á':
          sEscaped.append("%C1");
          break;
        case 'É':
          sEscaped.append("%C9");
          break;
        case 'Í':
          sEscaped.append("%CD");
          break;
        case 'Ó':
          sEscaped.append("%D3");
          break;
        case 'Ú':
          sEscaped.append("%DA");
          break;
        case 'à':
          sEscaped.append("%E0");
          break;
        case 'è':
          sEscaped.append("%E8");
          break;
        case 'ì':
          sEscaped.append("%EC");
          break;
        case 'ò':
          sEscaped.append("%F2");
          break;
        case 'ù':
          sEscaped.append("%F9");
          break;
        case 'À':
          sEscaped.append("%C0");
          break;
        case 'È':
          sEscaped.append("%C8");
          break;
        case 'Ì':
          sEscaped.append("%CC");
          break;
        case 'Ò':
          sEscaped.append("%D2");
          break;
        case 'Ù':
          sEscaped.append("%D9");
          break;
        case 'ñ':
          sEscaped.append("%F1");
          break;
        case 'Ñ':
          sEscaped.append("%D1");
          break;
        case 'ç':
          sEscaped.append("%E7");
          break;
        case 'Ç':
          sEscaped.append("%C7");
          break;
        case 'ô':
          sEscaped.append("%F4");
          break;
        case 'Ô':
          sEscaped.append("%D4");
          break;
        case 'ö':
          sEscaped.append("%F6");
          break;
        case 'Ö':
          sEscaped.append("%D6");
          break;
        case '`':
          sEscaped.append("%60");
          break;
        case '¨':
          sEscaped.append("%A8");
          break;
        default:
          sEscaped.append(c);
          break;
      }
    } // next

    return sEscaped.toString();
  } // URLEncode
  
} // CalendarServices
