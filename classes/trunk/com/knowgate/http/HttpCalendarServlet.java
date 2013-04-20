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

package com.knowgate.http;

import java.io.IOException;

import java.sql.Timestamp;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;

import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.knowgate.acl.ACL;
import com.knowgate.acl.ACLUser;
import com.knowgate.jdc.JDCConnection;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.NameValuePair;

import com.knowgate.debug.DebugFile;

import com.knowgate.addrbook.Room;
import com.knowgate.addrbook.Fellow;
import com.knowgate.addrbook.Meeting;

public class HttpCalendarServlet extends HttpServlet {

  private static SimpleDateFormat oFmt = new SimpleDateFormat("yyyyMMddHHmmss");
  private static SimpleDateFormat oXmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  
  private static DBBind oDbb;
  private static HashMap<String,NameValuePair> oSecurityTokens;
  private static HashMap<String,String> oWorkAreas;
  
  // ---------------------------------------------------------------------------

  public void init() throws ServletException {
  			
    ServletConfig config = getServletConfig();

    String sProfile = config.getInitParameter("profile");

    if (sProfile==null) {
      oDbb = new DBBind();
    } else if (sProfile.trim().length()==0) {
      oDbb = new DBBind();
    } else {
      oDbb = new DBBind(sProfile);
    }

	oSecurityTokens = new HashMap<String,NameValuePair>();
    oWorkAreas = new HashMap<String,String>();
  } // init()

  // ---------------------------------------------------------------------------
  
  public void doGet(HttpServletRequest request, HttpServletResponse response)
    throws IOException, ServletException {

	DebugFile.writeln("ENCODING = "+request.getCharacterEncoding());

    if (DebugFile.trace) {
      String sParams = "";
      Iterator oIter = request.getParameterMap().keySet().iterator();
      
      while (oIter.hasNext()) {
        String sKey = (String) oIter.next();
        sParams += (sParams.length()>0 ? ", " : "") + sKey + "=" + request.getParameter(sKey);
      } // wend
      DebugFile.writeln("Begin HttpCalendarServlet.doGet("+sParams+")");
      DebugFile.incIdent();
    }

	short iAuth;
    String sUid,sUsr,sPwd,sWrkA,sDtStart,sDtEnd,sMeet,sRoom,sType;
    Date oDtStart, oDtEnd;
    StringBuffer oBuf = new StringBuffer();
    oBuf.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    
    JDCConnection oCon = null;
    String sTok;
    
    String sCmd = request.getParameter("command");
    if (null==sCmd) {
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter command is requiered");
    } else if (sCmd.length()==0) {
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter command is requiered");
    } else {
      String sOut = request.getParameter("output");
      if (null==sOut) sOut="xml";

	  if (sCmd.equalsIgnoreCase("connect")) {
        sUsr = request.getParameter("user");
        sPwd = request.getParameter("password");
        if (null==sUsr) {
          response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter user is requiered");
        } else if (null==sPwd) {
          response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter password is requiered");
        } else {
          iAuth = ACL.INTERNAL_ERROR;
          int iEnc = 0;
          try {
          	String sEnc = request.getParameter("encryption");
          	if (null==sEnc) sEnc = "0";
          	if (sEnc.length()==0) sEnc = "0";
		    iEnc = Integer.parseInt(sEnc);
		    oCon = oDbb.getConnection("HttpCalendarServlet.connect");
		    sUid = ACLUser.getIdFromEmail(oCon, sUsr);
		    if (sUid==null)
		      iAuth = ACL.USER_NOT_FOUND;
		    else
		      iAuth = ACL.autenticate(oCon, sUid, sPwd, iEnc);
            oCon.close("HttpCalendarServlet.connect");
          } catch (SQLException sqle) {
            try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.connect"); } catch (Exception ignore) { }          
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			return;
          } catch (NumberFormatException nfe) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid value for encryption parameter");
			return;
          } finally {
          	oCon = null;
          }
          if (iAuth<0) {
            oBuf.append("<calendarresponse command=\"connect\" code=\""+String.valueOf(iAuth)+"\"><error>"+ACL.getErrorMessage(iAuth)+"</error><value/></calendarresponse>");
          } else {
            sTok = Gadgets.generateRandomId(40, null, Character.LOWERCASE_LETTER);
            while (oSecurityTokens.containsKey(sTok))
              sTok = Gadgets.generateRandomId(40, null, Character.LOWERCASE_LETTER);
		    try {
		      oCon = oDbb.getConnection("HttpCalendarServlet.getid");
  			  sWrkA = DBCommand.queryStr(oCon, "SELECT "+DB.gu_workarea+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"='"+sUid+"'");
              oCon.close("HttpCalendarServlet.getid");
              if (null==sWrkA) {
            	oBuf.append("<calendarresponse command=\"connect\" code=\""+String.valueOf(ACL.WORKAREA_NOT_SET)+"\"><error>"+ACL.getErrorMessage(ACL.WORKAREA_NOT_SET)+"</error><value/></calendarresponse>");
              } else {
                oSecurityTokens.put(sTok, new NameValuePair(sUid, ACL.decript(sPwd,iEnc)));
                oWorkAreas.put(sTok, sWrkA);
                if (sOut.equalsIgnoreCase("xml")) {
                  oBuf.append("<calendarresponse command=\"connect\" code=\"0\"><error></error><value>"+sTok+"</value></calendarresponse>");
            	}
              }
            } catch (SQLException sqle) {
              try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.getid"); } catch (Exception ignore) { }          
              response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  return;
            }
          }
          response.setContentType("text/xml");
          response.setCharacterEncoding("UTF-8");
          response.getWriter().print(oBuf.toString());
        }
	  } else if (sCmd.equalsIgnoreCase("isAvailableRoom") || sCmd.equalsIgnoreCase("getAvailableRooms") ||
	  	         sCmd.equalsIgnoreCase("getMeetings") || sCmd.equalsIgnoreCase("getMeetingsForRoom") ||
	  	         sCmd.equalsIgnoreCase("getMeetingsOrganizedBy") ||
	  	         sCmd.equalsIgnoreCase("getMeeting") || sCmd.equals("getRooms") ||
	  	         sCmd.equalsIgnoreCase("storeMeeting") || sCmd.equalsIgnoreCase("deleteMeeting") ||
	  	         sCmd.equalsIgnoreCase("disconnect")) {
        sTok = request.getParameter("token");
		sMeet = request.getParameter("meeting");
		sType = request.getParameter("type");
		sRoom = request.getParameter("room");
		sDtStart = request.getParameter("startdate");
		sDtEnd = request.getParameter("enddate");
        if (null==sTok) {
          response.sendError(HttpServletResponse.SC_FORBIDDEN, "No security token was supplied");
        } else {
		  NameValuePair oUsrPwd = oSecurityTokens.get(sTok);
		  if (null==oUsrPwd) {
            oBuf.append("<calendarresponse command=\""+sCmd+"\" code=\""+String.valueOf(ACL.DOMAIN_NOT_FOUND)+"\"><error>Invalid security token</error><value/></calendarresponse>");
		  } else {
            try {
		      oCon = oDbb.getConnection("HttpCalendarServlet.authenticate");
		      iAuth = ACL.autenticate(oCon, oUsrPwd.getName(), oUsrPwd.getValue(), ACL.PWD_CLEAR_TEXT);
		  	  sUid = oUsrPwd.getName();
              oCon.close("HttpCalendarServlet.authenticate");
            } catch (SQLException sqle) {
              try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.authenticate"); } catch (Exception ignore) { }          
              response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  return;
            }
            if (iAuth<0) {
              oBuf.append("<calendarresponse command=\""+sCmd+"\" code=\""+String.valueOf(iAuth)+"\"><error>"+ACL.getErrorMessage(iAuth)+"</error><value/></calendarresponse>");
            } else {
              sWrkA = oWorkAreas.get(sTok);
			  if (sCmd.equalsIgnoreCase("isAvailableRoom")) {
			    if (null==sRoom) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter room is requiered");
			    } else if (null==sDtStart) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter startdate is requiered");			      
			    } else if (null==sDtEnd) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter enddate is requiered");			      
			    } else {
				  try {
				    oDtStart = oFmt.parse(sDtStart);
				    oDtEnd = oFmt.parse(sDtEnd);
		      		oCon = oDbb.getConnection("HttpCalendarServlet.isavailableroom",true);
					Room oRoom = new Room();
					boolean bIsAvail;
					if (oRoom.load(oCon, sRoom, sWrkA))
					  bIsAvail = oRoom.isAvailable(oCon, oDtStart, oDtEnd);
              		else
              		  bIsAvail = false;
              		oCon.close("HttpCalendarServlet.isavailableroom");
              		oBuf.append("<calendarresponse command=\"isAvailableRoom\" code=\"0\"><error></error><value>"+String.valueOf(bIsAvail)+"</value></calendarresponse>");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
				  } catch (ParseException dpe) {
            	    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid date it must be yyyyMMddHHmmss");
			  		return;
				  } catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.isavailableroom"); } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	  }	      
			    }
			  } else if (sCmd.equalsIgnoreCase("getRooms")) {
				try {
			        DBSubset oRooms;
			        int nRooms;
		      		oCon = oDbb.getConnection("HttpCalendarServlet.getrooms",true);
			        if (request.getParameter("type")==null) {
					  oRooms = new DBSubset(DB.k_rooms,DB.tp_room+","+DB.nm_room+","+DB.tx_comments, DB.gu_workarea+"=?", 100);
			          nRooms = oRooms.load(oCon, new Object[]{sWrkA});
			        } else if (request.getParameter("type").length()==0) {
					  oRooms = new DBSubset(DB.k_rooms,DB.tp_room+","+DB.nm_room+","+DB.tx_comments, DB.gu_workarea+"=?", 100);
			          nRooms = oRooms.load(oCon, new Object[]{sWrkA});
			        } else {
					  oRooms = new DBSubset(DB.k_rooms,DB.tp_room+","+DB.nm_room+","+DB.tx_comments, DB.gu_workarea+"=? AND "+DB.tp_room+"=?", 100);
			          nRooms = oRooms.load(oCon, new Object[]{sWrkA, request.getParameter("type")});
			        }
                    oBuf.append("<calendarresponse command=\"getRooms\" code=\"0\"><error></error><value>"+String.valueOf(nRooms)+"</value><rooms count=\""+String.valueOf(nRooms)+"\">");
                    for (int r=0; r<nRooms; r++) {
                      oBuf.append("<room type=\""+oRooms.getStringNull(0,r,"")+"\" active=\"1\"><name>"+oRooms.getStringNull(1,r,"")+"</name><comments>"+oRooms.getStringNull(2,r,"")+"</comments></room>");
                    } // next
              		oCon.close("HttpCalendarServlet.getavailablerooms");
                    oBuf.append("</rooms></calendarresponse>");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
				} catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.getrooms"); } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	}	
			  } else if (sCmd.equalsIgnoreCase("getAvailableRooms")) {
			    if (null==sDtStart) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter startdate is required");			      
			    } else if (null==sDtEnd) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter enddate is required");			      
			    } else {
				  try {
				    oDtStart = oFmt.parse(sDtStart);
				    oDtEnd = oFmt.parse(sDtEnd);
			        DBSubset oRooms = new DBSubset(DB.k_rooms,DB.tp_room+","+DB.nm_room+","+DB.tx_comments, DB.bo_available+"<>0 AND "+DB.gu_workarea+"=?", 100);
		      		oCon = oDbb.getConnection("HttpCalendarServlet.getavailablerooms",true);
			        int nRooms = oRooms.load(oCon, new Object[]{sWrkA});
                    oBuf.append("<calendarresponse command=\"getAvailableRooms\" code=\"0\"><error></error><value>"+String.valueOf(nRooms)+"</value><rooms count=\""+String.valueOf(nRooms)+"\">");
				    Room oRomn = new Room();
                    for (int r=0; r<nRooms; r++) {
				      if (oRomn.load(oCon, oRooms.get(1,r), sWrkA)) {
                        if (oRomn.isAvailable(oCon, oDtStart, oDtEnd))
                          oBuf.append("<room type=\""+oRooms.getStringNull(0,r,"")+"\" active=\"1\"><name>"+oRooms.getStringNull(1,r,"")+"</name><comments>"+oRooms.getStringNull(2,r,"")+"</comments></room>");
				      }
                    } // next
              		oCon.close("HttpCalendarServlet.getavailablerooms");
                    oBuf.append("</rooms></calendarresponse>");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
				  } catch (ParseException dpe) {
            	    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid date it must be yyyyMMddHHmmss");
			  		return;
				  } catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.getavailablerooms"); } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	  }	
			    }
			  } else if (sCmd.equalsIgnoreCase("getMeetings") || sCmd.equalsIgnoreCase("getMeetingsOrganizedBy")) {

    			if (DebugFile.trace) DebugFile.writeln("Executing command "+sCmd);	

			    if (null==sDtStart) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter startdate is requiered");			      
			    } else if (null==sDtEnd) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter enddate is requiered");			      
			    } else {

    			  if (DebugFile.trace) DebugFile.writeln("startdate and enddate parameters acknowledged");

				  try {
    			    if (DebugFile.trace) DebugFile.writeln("parsing startdate");
				    oDtStart = oFmt.parse(sDtStart);
    			    if (DebugFile.trace) DebugFile.writeln("parsing enddate");
				    oDtEnd = oFmt.parse(sDtEnd);
				    DBSubset oMeets;
				    int nMeets;				    
					if (sCmd.equalsIgnoreCase("getMeetings")) {
    			      oMeets = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f," + DB.k_fellows + " o",
    			                            "m." + DB.id_icalendar + ",m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.de_meeting +","+
    			                            "o." + DB.gu_fellow + ",o." + DB.id_ref + ",o." + DB.tx_name + ",o." + DB.tx_surname + ",o." + DB.tx_email + ",o." + DB.tx_timezone + ",m." + DB.tp_meeting,
				                            "m."+DB.gu_workarea+"=? AND f."+DB.gu_fellow+"=o."+DB.gu_fellow+" AND "+ 
    			                            "f." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN ? AND ? "+
    			                            (sType!=null ? " AND m."+DB.tp_meeting+"=?" : "")+" ORDER BY 3", 60);
					} else {
    			      oMeets = new DBSubset(DB.k_meetings + " m," + DB.k_fellows + " o",
    			                            "m." + DB.id_icalendar + ",m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.de_meeting +","+
    			                            "o." + DB.gu_fellow + ",o." + DB.id_ref + ",o." + DB.tx_name + ",o." + DB.tx_surname + ",o." + DB.tx_email + ",o." + DB.tx_timezone,
				                            "m."+DB.gu_workarea+"=? AND m."+DB.gu_fellow+"=o."+DB.gu_fellow+" AND "+ 
    			                            "m." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN ? AND ? "+
    			                            (sType!=null ? " AND m."+DB.tp_meeting+"=?" : "")+" ORDER BY 3", 60);					  
					}
		      		oCon = oDbb.getConnection("HttpCalendarServlet.getmeetings",true);
    			    if (sType==null)
    			      nMeets = oMeets.load(oCon, new Object[]{sWrkA, sUid, new Timestamp(oDtStart.getTime()), new Timestamp(oDtEnd.getTime())});
    			    else
    			      nMeets = oMeets.load(oCon, new Object[]{sWrkA, sUid, new Timestamp(oDtStart.getTime()), new Timestamp(oDtEnd.getTime()), sType});
    			    if (DebugFile.trace) DebugFile.writeln(String.valueOf(nMeets)+" meetings found");
                    oBuf.append("<calendarresponse command=\"getMeetings\" code=\"0\"><error></error><value>"+String.valueOf(nMeets)+"</value><meetings count=\""+String.valueOf(nMeets)+"\">");
                    for (int m=0; m<nMeets; m++) {
                      oBuf.append("<meeting type=\""+oMeets.getStringNull(13,m,"")+"\">");
                      oBuf.append("<id>"+oMeets.getStringNull(DB.id_icalendar,m,"")+"</id>");
                      oBuf.append("<gu>"+oMeets.getString(DB.gu_meeting,m)+"</gu>");
                      oBuf.append("<startdate>"+oMeets.getDateFormated(2,m,oXmt).replace(' ','T')+"</startdate>");
                      oBuf.append("<enddate>"+oMeets.getDateFormated(3,m,oXmt).replace(' ','T')+"</enddate>");
                      if (oMeets.isNull(4,m))
                        oBuf.append("<privacy>false</privacy>");
                      else
                        oBuf.append("<privacy>"+String.valueOf(oMeets.getShort(4,m)!=0)+"</privacy>");
                      oBuf.append("<title>"+oMeets.getStringNull(5,m,"")+"</title>");
                      oBuf.append("<description>"+oMeets.getStringNull(6,m,"")+"</description>");
                      oBuf.append("<organizer>");
                      oBuf.append("<id>"+oMeets.getStringNull(8,m,"")+"</id>");
                      oBuf.append("<gu>"+oMeets.getString(7,m)+"</gu>");
                      oBuf.append("<name>"+oMeets.getStringNull(9,m,"")+"</name>");
                      oBuf.append("<surname>"+oMeets.getStringNull(10,m,"")+"</surname>");
                      oBuf.append("<email>"+oMeets.getStringNull(11,m,"")+"</email>");
                      oBuf.append("<timezone>"+oMeets.getStringNull(12,m,"")+"</timezone>");
                      oBuf.append("</organizer>");
			          DBSubset oRomm = new DBSubset(DB.k_rooms+" r,"+DB.k_x_meeting_room+" m","r."+DB.tp_room+",r."+DB.nm_room+",r."+DB.tx_comments+",r."+DB.bo_available,
			      								    "r."+DB.gu_workarea+"=? AND m."+DB.gu_meeting+"=? AND r."+DB.nm_room+"=m."+DB.nm_room, 10);
				      int nRomm = oRomm.load(oCon, new Object[]{sWrkA, oMeets.getString(DB.gu_meeting,m)});
                      oBuf.append("<rooms count=\""+String.valueOf(nRomm)+"\">");                  
                      for (int r=0; r<nRomm; r++) {
                        oBuf.append("<room type=\""+oRomm.getStringNull(0,r,"")+"\" ");
                        if (oRomm.isNull(3,r))
                          oBuf.append("active=\"1\"");
                        else
                          oBuf.append("active=\""+String.valueOf(oRomm.getShort(3,r))+"\"");                        	
                        oBuf.append("><name>"+oRomm.getStringNull(1,r,"")+"</name><comments>"+oRomm.getStringNull(2,r,"")+"</comments></room>");
                      } // next
                      oBuf.append("</rooms>");
                      DBSubset oFlws = new DBSubset(DB.k_fellows +" f,"+DB.k_x_meeting_fellow +" x",
    			                            		"f." + DB.gu_fellow + ",f." + DB.id_ref + ",f." + DB.tx_name + ",f." + DB.tx_surname + ",f." + DB.tx_email + ",f." + DB.tx_timezone,
                      								"f."+DB.tx_email+" IS NOT NULL AND f."+DB.gu_fellow+"=x."+DB.gu_fellow+" AND x."+DB.gu_meeting+"=?", 10);
                      DBSubset oCnts = new DBSubset(DB.k_member_address+" c,"+DB.k_x_meeting_contact+" x",
    			                            		"c." + DB.gu_contact + ",c." + DB.id_ref + ",c." + DB.tx_name + ",c." + DB.tx_surname + ",c." + DB.tx_email + ",'+00:00' AS " + DB.tx_timezone,
                      								"c."+DB.tx_email+" IS NOT NULL AND c."+DB.gu_contact+"=x."+DB.gu_contact+" AND x."+DB.gu_meeting+"=?", 10);
                      oFlws.load(oCon, new Object[]{oMeets.getString(DB.gu_meeting,m)});
                      oCnts.load(oCon, new Object[]{oMeets.getString(DB.gu_meeting,m)});
                      oFlws.union(oCnts);
                      oBuf.append("<attendants count=\""+String.valueOf(oFlws.getRowCount())+"\">");
                      for (int f=0; f<oFlws.getRowCount(); f++) {
                        oBuf.append("<attendant>");
                        oBuf.append("<id>"+oFlws.getStringNull(1,f,"")+"</id>");
                        oBuf.append("<gu>"+oFlws.getString(0,f)+"</gu>");
                        oBuf.append("<name>"+oFlws.getStringNull(2,f,"")+"</name>");
                        oBuf.append("<surname>"+oFlws.getStringNull(3,f,"")+"</surname>");
                        oBuf.append("<email>"+oFlws.getStringNull(4,f,"")+"</email>");
                        oBuf.append("<timezone>"+oFlws.getStringNull(5,f,"")+"</timezone>");
                        oBuf.append("</attendant>");
                      }
                      oBuf.append("</attendants>");
                      oBuf.append("</meeting>");
                    } // next
              		oCon.close("HttpCalendarServlet.getmeetings");
                    oBuf.append("</meetings></calendarresponse>");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
				  } catch (ParseException dpe) {
            	    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid date it must be yyyyMMddHHmmss");
			  		return;
				  } catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.getmeetings"); } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	  }
            	}
			  } else if (sCmd.equalsIgnoreCase("getMeetingsForRoom")) {
			    if (null==sRoom) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter room is requiered");
			    } else if (null==sDtStart) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter startdate is requiered");			      
			    } else if (null==sDtEnd) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter enddate is requiered");			      
			    } else {
				  try {
				    oDtStart = oFmt.parse(sDtStart);
				    oDtEnd = oFmt.parse(sDtEnd);
    			    DBSubset oMeets = new DBSubset(DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f," +DB.k_x_meeting_room + " r," + DB.k_fellows + " o",
    			                                   "m." + DB.id_icalendar + ",m." + DB.gu_meeting + ",m." + DB.dt_start + ",m." + DB.dt_end + ",m." + DB.bo_private + ",m." + DB.tx_meeting + ",m." + DB.de_meeting+","+
    			                                   "o." + DB.gu_fellow + ",o." + DB.id_ref + ",o." + DB.tx_name + ",o." + DB.tx_surname + ",o." + DB.tx_email + ",o." + DB.tx_timezone + ",m." + DB.tp_meeting,
				                                   "m."+DB.gu_workarea+"=? AND r."+DB.nm_room+"=? AND "+
    			                                   "r." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND f."+DB.gu_fellow+"=o."+DB.gu_fellow+" AND "+
    			                                   "f." + DB.gu_meeting + "=m." + DB.gu_meeting + " AND " +
    			                                   "f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN ? AND ? ORDER BY 3", 60);
		      		oCon = oDbb.getConnection("HttpCalendarServlet.getmeetingsforroom",true);
    			    int nMeets = oMeets.load(oCon, new Object[]{sWrkA, sRoom, sUid, new Timestamp(oDtStart.getTime()), new Timestamp(oDtEnd.getTime())});
                    oBuf.append("<calendarresponse command=\"getMeetings\" code=\"0\"><error></error><value>"+String.valueOf(nMeets)+"</value><meetings count=\""+String.valueOf(nMeets)+"\">");
                    for (int m=0; m<nMeets; m++) {
                      oBuf.append("<meeting type=\""+oMeets.getStringNull(13,m,"")+"\">");
                      oBuf.append("<id>"+oMeets.getStringNull(DB.id_icalendar,m,"")+"</id>");
                      oBuf.append("<gu>"+oMeets.getString(DB.gu_meeting,m)+"</gu>");
                      oBuf.append("<startdate>"+oMeets.getDateFormated(2,m,oXmt).replace(' ','T')+"</startdate>");
                      oBuf.append("<enddate>"+oMeets.getDateFormated(3,m,oXmt).replace(' ','T')+"</enddate>");
                      if (oMeets.isNull(4,m))
                        oBuf.append("<privacy>false</privacy>");
                      else
                        oBuf.append("<privacy>"+String.valueOf(oMeets.getShort(4,m)!=0)+"</privacy>");
                      oBuf.append("<title>"+oMeets.getStringNull(5,m,"")+"</title>");
                      oBuf.append("<description>"+oMeets.getStringNull(6,m,"")+"</description>");
                      oBuf.append("<organizer>");
                      oBuf.append("<id>"+oMeets.getStringNull(8,m,"")+"</id>");
                      oBuf.append("<gu>"+oMeets.getString(7,m)+"</gu>");
                      oBuf.append("<name>"+oMeets.getStringNull(9,m,"")+"</name>");
                      oBuf.append("<surname>"+oMeets.getStringNull(10,m,"")+"</surname>");
                      oBuf.append("<email>"+oMeets.getStringNull(11,m,"")+"</email>");
                      oBuf.append("<timezone>"+oMeets.getStringNull(12,m,"")+"</timezone>");
                      oBuf.append("</organizer>");
			          Room oRoom = new Room();
			          oRoom.load(oCon, sRoom, sWrkA);
                      oBuf.append("<rooms count=\"1\">");                  
                      oBuf.append("<room type=\""+oRoom.getStringNull(DB.tp_room,"")+"\" active=\""+(oRoom.get(DB.bo_available)==null ? "1" : oRoom.get(DB.bo_available))+"\"><name>"+oRoom.getStringNull(DB.nm_room,"")+"</name><comments>"+oRoom.getStringNull(DB.tx_comments,"")+"</comments></room>");
                      oBuf.append("</rooms>");
                      DBSubset oFlws = new DBSubset(DB.k_fellows +" f,"+DB.k_x_meeting_fellow +" x",
    			                            		"f." + DB.gu_fellow + "f." + DB.id_ref + ",f." + DB.tx_name + "f." + DB.tx_surname + "f." + DB.tx_email + "f." + DB.tx_timezone,
                      					            "f."+DB.tx_email+" IS NOT NULL AND f."+DB.gu_fellow+"=x."+DB.gu_fellow+" AND x."+DB.gu_meeting+"=?", 10);
                      DBSubset oCnts = new DBSubset(DB.k_member_address+" c,"+DB.k_x_meeting_contact+" x", "c."+DB.tx_email, "c."+DB.tx_email+" IS NOT NULL AND c."+DB.gu_contact+"=x."+DB.gu_contact+" AND x."+DB.gu_meeting+"=?", 10);
                      oFlws.load(oCon, new Object[]{oMeets.getString(DB.gu_meeting,m)});
                      oCnts.load(oCon, new Object[]{oMeets.getString(DB.gu_meeting,m)});
                      oFlws.union(oCnts);
                      oBuf.append("<attendants count=\""+String.valueOf(oFlws.getRowCount())+"\">");
                      for (int f=0; f<oFlws.getRowCount(); f++) {
                        oBuf.append("<attendant>");
                        oBuf.append("<id>"+oFlws.getStringNull(1,f,"")+"</id>");
                        oBuf.append("<gu>"+oFlws.getString(0,f)+"</gu>");
                        oBuf.append("<name>"+oFlws.getStringNull(2,f,"")+"</name>");
                        oBuf.append("<surname>"+oFlws.getStringNull(3,f,"")+"</surname>");
                        oBuf.append("<email>"+oFlws.getStringNull(4,f,"")+"</email>");
                        oBuf.append("<timezone>"+oFlws.getStringNull(5,f,"")+"</timezone>");
                        oBuf.append("</attendant>");
                      }
                      oBuf.append("</attendants>");
                      oBuf.append("</meeting>");
                    } // next
              		oCon.close("HttpCalendarServlet.getmeetingsforroom");
                    oBuf.append("</meetings></calendarresponse>");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
				  } catch (ParseException dpe) {
            	    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid date it must be yyyyMMddHHmmss");
			  		return;
				  } catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.getmeetingsforroom"); } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	  }
            	}
			  } else if (sCmd.equalsIgnoreCase("getMeeting")) {
			    if (null==sMeet) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter meeting is requiered");
			    } else {
			      try {
		      		oCon = oDbb.getConnection("HttpCalendarServlet.getmeeting",true);
					Meeting oMeet = new Meeting();
					PreparedStatement oStm = oCon.prepareStatement("SELECT "+DB.gu_meeting+" FROM "+DB.k_meetings+" WHERE "+DB.gu_workarea+"=? AND ("+DB.gu_meeting+"=? OR "+DB.id_icalendar+"=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
					oStm.setString(1, sWrkA);
					oStm.setString(2, sMeet);
					oStm.setString(3, sMeet);
					ResultSet oRst = oStm.executeQuery();					
					if (oRst.next()) {
					  oMeet.load(oCon, oRst.getString(1));
                      oBuf.append("<calendarresponse command=\"getMeeting\" code=\"0\"><error></error><value>true</value><meetings count=\"1\"><meeting type=\""+oMeet.getStringNull(DB.tp_meeting,"")+"\">");
                      oBuf.append("<id>"+oMeet.getStringNull(DB.id_icalendar,"")+"</id>");
                      oBuf.append("<gu>"+oMeet.getString(DB.gu_meeting)+"</gu>");
                      oBuf.append("<startdate>"+oXmt.format(oMeet.getDate(DB.dt_start)).replace(' ','T')+"</startdate>");
                      oBuf.append("<enddate>"+oXmt.format(oMeet.getDate(DB.dt_end)).replace(' ','T')+"</enddate>");
                      if (oMeet.isNull(DB.bo_private))
                        oBuf.append("<privacy>0</privacy>");
                      else
                        oBuf.append("<privacy>"+String.valueOf(oMeet.getShort(DB.bo_private))+"</privacy>");
                      oBuf.append("<title>"+oMeet.getStringNull(DB.tx_meeting,"")+"</title>");
                      oBuf.append("<description>"+oMeet.getStringNull(DB.de_meeting,"")+"</description>");					    
					  Fellow oOrg = new Fellow(oCon, oMeet.getString(DB.gu_fellow));
                      oBuf.append("<organizer>");
                      oBuf.append("<id>"+oOrg.getStringNull(DB.id_ref,"")+"</id>");
                      oBuf.append("<gu>"+oOrg.getString(DB.gu_fellow)+"</gu>");
                      oBuf.append("<name>"+oOrg.getStringNull(DB.tx_name,"")+"</name>");
                      oBuf.append("<surname>"+oOrg.getStringNull(DB.tx_surname,"")+"</surname>");
                      oBuf.append("<email>"+oOrg.getStringNull(DB.tx_email,"")+"</email>");
                      oBuf.append("<timezone>"+oOrg.getStringNull(DB.tx_timezone,"")+"</timezone>");
                      oBuf.append("</organizer>");
			          DBSubset oRomm = new DBSubset(DB.k_rooms+" r,"+DB.k_x_meeting_room+" m","r."+DB.tp_room+",r."+DB.nm_room+",r."+DB.tx_comments,
			      								    "r."+DB.gu_workarea+"=? AND m."+DB.gu_meeting+"=? AND r."+DB.nm_room+"=m."+DB.nm_room, 10);
				      int nRomm = oRomm.load(oCon, new Object[]{sWrkA, oMeet.getString(DB.gu_meeting)});
                      oBuf.append("<rooms count=\""+String.valueOf(nRomm)+"\">");
                      for (int r=0; r<nRomm; r++) {
                        oBuf.append("<room type=\""+oRomm.getStringNull(0,r,"")+"\"><name>"+oRomm.getStringNull(1,r,"")+"</name><comments>"+oRomm.getStringNull(2,r,"")+"</comments></room>");
                      } // next
                      oBuf.append("</rooms>");
                      DBSubset oFlws = new DBSubset(DB.k_fellows +" f,"+DB.k_x_meeting_fellow +" x",
    			                            		"f." + DB.gu_fellow + ",f." + DB.id_ref + ",f." + DB.tx_name + ",f." + DB.tx_surname + ",f." + DB.tx_email + ",f." + DB.tx_timezone,
                      								"f."+DB.tx_email+" IS NOT NULL AND f."+DB.gu_fellow+"=x."+DB.gu_fellow+" AND x."+DB.gu_meeting+"=?", 10);
                      DBSubset oCnts = new DBSubset(DB.k_member_address+" c,"+DB.k_x_meeting_contact+" x",
    			                            		"c." + DB.gu_contact + ",c." + DB.id_ref + ",c." + DB.tx_name + ",c." + DB.tx_surname + ",c." + DB.tx_email + ",'+00:00' AS " + DB.tx_timezone,
                      								"c."+DB.tx_email+" IS NOT NULL AND c."+DB.gu_contact+"=x."+DB.gu_contact+" AND x."+DB.gu_meeting+"=?", 10);
                      oFlws.load(oCon, new Object[]{oMeet.getString(DB.gu_meeting)});
                      oCnts.load(oCon, new Object[]{oMeet.getString(DB.gu_meeting)});
                      oFlws.union(oCnts);
                      oBuf.append("<attendants count=\""+String.valueOf(oFlws.getRowCount())+"\">");
                      for (int f=0; f<oFlws.getRowCount(); f++) {
                        oBuf.append("<attendant>");
                        oBuf.append("<id>"+oFlws.getStringNull(1,f,"")+"</id>");
                        oBuf.append("<gu>"+oFlws.getString(0,f)+"</gu>");
                        oBuf.append("<name>"+oFlws.getStringNull(2,f,"")+"</name>");
                        oBuf.append("<surname>"+oFlws.getStringNull(3,f,"")+"</surname>");
                        oBuf.append("<email>"+oFlws.getStringNull(4,f,"")+"</email>");
                        oBuf.append("<timezone>"+oFlws.getStringNull(5,f,"")+"</timezone>");
                        oBuf.append("</attendant>");
                      }
                      oBuf.append("</attendants>");
					  oBuf.append("</meeting></meetings></calendarresponse>");
					} else {
                      oBuf.append("<calendarresponse command=\"getMeeting\" code=\"0\"><error></error><value>false</value><meetings/></calendarresponse>");
					}
              		oRst.close();
              		oStm.close();
              		oCon.close("HttpCalendarServlet.getmeeting");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
			      } catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) oCon.close("HttpCalendarServlet.getmeeting"); } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	  }
			    }
			  } else if (sCmd.equalsIgnoreCase("storeMeeting")) {
			    if (null==sMeet) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter meeting is required");
			    } else if (null==request.getParameter("title")) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter title is required");
			    } else {
			      String[] aRooms = null;
				  String sRooms = request.getParameter("rooms");
				  if (sRooms!=null) if (sRooms.length()>0) aRooms = Gadgets.split(sRooms,',');
			      try {
		      		oCon = oDbb.getConnection("HttpCalendarServlet.storemeeting",false);
					if (null!=aRooms) {
					  boolean bExists;
					  short iAvailable = 0;
					  PreparedStatement oAct = oCon.prepareStatement("SELECT "+DB.bo_available+" FROM "+DB.k_rooms+" WHERE "+DB.gu_workarea+"=? AND "+DB.nm_room+"=?");
					  for (int v=0; v<aRooms.length; v++) {
					    oAct.setString (1,sWrkA);
					    oAct.setString (2, aRooms[v]);
					    ResultSet oRct = oAct.executeQuery();
					    bExists = oRct.next();
					    if (bExists) iAvailable = oRct.getShort(1);
					    oRct.close();
					    if (!bExists) {
              			  oAct.close();
              			  oCon.close("HttpCalendarServlet.storemeeting");
                    	  oBuf.append("<calendarresponse command=\"storeMeeting\" code=\"-100\"><error>Room "+aRooms[v]+" was not found at WorkArea "+sWrkA+"</error><value>false</value><meetings count=\"0\"></meetings></calendarresponse>");
		            	  response.setContentType("text/xml");
          				  response.setCharacterEncoding("UTF-8");
          				  response.getWriter().print(oBuf.toString());
					      return;
					    } else if (0==iAvailable) {
              			  oAct.close();
              			  oCon.close("HttpCalendarServlet.storemeeting");
                    	  oBuf.append("<calendarresponse command=\"storeMeeting\" code=\"-101\"><error>Room "+aRooms[v]+" is not available for booking</error><value>false</value><meetings count=\"0\"></meetings></calendarresponse>");
		            	  response.setContentType("text/xml");
          				  response.setCharacterEncoding("UTF-8");
          				  response.getWriter().print(oBuf.toString());
					      return;
					    }
					  } // next
					  oAct.close();
					} // fi
					oCon.setAutoCommit(false);
					Meeting oMeet = new Meeting();
					PreparedStatement oStm = oCon.prepareStatement("SELECT "+DB.gu_meeting+" FROM "+DB.k_meetings+" WHERE "+DB.gu_workarea+"=? AND ("+DB.gu_meeting+"=? OR "+DB.id_icalendar+"=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
					oStm.setString(1, sWrkA);
					oStm.setString(2, sMeet);
					oStm.setString(3, sMeet);
					ResultSet oRst = oStm.executeQuery();					
					if (oRst.next()) {
					  oMeet.load(oCon, oRst.getString(1));
              		  oRst.close();
              		  oStm.close();
                      if (null!=sDtStart) oMeet.replace(DB.dt_start, oFmt.parse(sDtStart));
                      if (null!=sDtEnd) oMeet.replace(DB.dt_end, oFmt.parse(sDtEnd));					  
					  if (null!=sDtStart && null!=sDtEnd)
					  	if (oFmt.parse(sDtStart).getTime()>oFmt.parse(sDtEnd).getTime())
					  	  throw new IllegalArgumentException("Start date must be prior to end date");
					  if (null!=request.getParameter("type"))
					  	oMeet.replace(DB.tp_meeting, request.getParameter("type"));
					  if (null!=request.getParameter("privacy"))
					  	oMeet.replace(DB.bo_private, Short.parseShort(request.getParameter("privacy")));
					  oMeet.replace(DB.tx_meeting, Gadgets.left(request.getParameter("title"),100));
					  if (null!=request.getParameter("description"))
					  	oMeet.replace(DB.de_meeting, Gadgets.left(request.getParameter("description"),1000));					  
					  oMeet.store(oCon);
					} else {
              		  oRst.close();
              		  oStm.close();
              		  oMeet.put(DB.gu_meeting, Gadgets.generateUUID());
              		  oMeet.put(DB.id_icalendar, sMeet);
              		  oMeet.put(DB.id_domain, DBCommand.queryInt(oCon, "SELECT "+DB.id_domain+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sWrkA+"'"));
              		  oMeet.put(DB.gu_workarea, sWrkA);
              		  oMeet.put(DB.gu_fellow, sUid);
              		  oMeet.put(DB.gu_writer, sUid);
                      oMeet.put(DB.dt_start, oFmt.parse(sDtStart));
                      oMeet.put(DB.dt_end, oFmt.parse(sDtEnd));
					  if (null!=request.getParameter("type"))
					  	oMeet.put(DB.tp_meeting, request.getParameter("type"));
					  if (null!=request.getParameter("privacy"))
					  	oMeet.put(DB.bo_private, Short.parseShort(request.getParameter("privacy")));
					  oMeet.put(DB.tx_meeting, Gadgets.left(request.getParameter("title"),100));
					  if (null!=request.getParameter("description"))
					  	oMeet.put(DB.de_meeting, Gadgets.left(request.getParameter("description"),1000));
					  oMeet.store(oCon);
					}

					oMeet.clearRooms(oCon);
					if (aRooms!=null) {
					  PreparedStatement oPrm = oCon.prepareStatement("INSERT INTO "+DB.k_x_meeting_room+" ("+DB.gu_meeting+","+DB.nm_room+","+DB.dt_start+","+DB.dt_end+") VALUES (?,?,?,?)");
					  for (int a=0; a<aRooms.length; a++) {
					  	oPrm.setString(1, oMeet.getString(DB.gu_meeting));
					  	oPrm.setString(2, aRooms[a]);
					    oPrm.setTimestamp(3, new Timestamp(oMeet.getDate(DB.dt_start).getTime()));
					  	oPrm.setTimestamp(4, new Timestamp(oMeet.getDate(DB.dt_end).getTime()));
					  	oPrm.executeUpdate();
					  } // next
					  oPrm.close();
					} // fi

					oMeet.clearAttendants(oCon);
					boolean bSelf = false;
					String sAttendants = request.getParameter("attendants");
					if (sAttendants!=null) {
					  if (sAttendants.length()>0) {
					  	String sGuFellow;
					  	String[] aAttendants = Gadgets.split(sAttendants,',');
					  	PreparedStatement oAtd = oCon.prepareStatement("SELECT * FROM "+DB.k_fellows+" WHERE "+DB.gu_workarea+"=? AND ("+DB.gu_fellow+"=? OR "+DB.tx_email+"=?)");
					  	for (int a=0; a<aAttendants.length; a++) {
					  	  oAtd.setString(1, oMeet.getString(DB.gu_workarea));
					  	  oAtd.setString(2, aAttendants[a]);
					  	  oAtd.setString(3, aAttendants[a]);
					  	  ResultSet oRtd = oAtd.executeQuery();
					  	  if (oRtd.next())
					  	  	sGuFellow = oRtd.getString(1);
					  	  else
					  	  	sGuFellow = null;
					  	  oRtd.close();
					  	  if (sGuFellow!=null) oMeet.addAttendant(oCon, sGuFellow);
						  bSelf = sUid.equals(sGuFellow);
					  	} // next
					  	if (!bSelf) oMeet.addAttendant(oCon, sUid);					  	
					  	oAtd.close();
					  } // fi
					} // fi
					
					oCon.commit();

                    oBuf.append("<calendarresponse command=\"storeMeeting\" code=\"0\"><error></error><value>true</value><meetings count=\"1\"><meeting type=\""+oMeet.getStringNull(DB.tp_meeting,"")+"\">");
                    oBuf.append("<id>"+oMeet.getStringNull(DB.id_icalendar,"")+"</id>");
                    oBuf.append("<gu>"+oMeet.getString(DB.gu_meeting)+"</gu>");
                    oBuf.append("<startdate>"+oXmt.format(oMeet.getDate(DB.dt_start)).replace(' ','T')+"</startdate>");
                    oBuf.append("<enddate>"+oXmt.format(oMeet.getDate(DB.dt_end)).replace(' ','T')+"</enddate>");
                    if (oMeet.isNull(DB.bo_private))
                      oBuf.append("<privacy>0</privacy>");
                    else
                      oBuf.append("<privacy>"+String.valueOf(oMeet.getShort(DB.bo_private))+"</privacy>");
                    oBuf.append("<title>"+oMeet.getStringNull(DB.tx_meeting,"")+"</title>");
                    oBuf.append("<description>"+oMeet.getStringNull(DB.de_meeting,"")+"</description>");
					Fellow oOrg = new Fellow(oCon, oMeet.getString(DB.gu_fellow));
                    oBuf.append("<organizer>");
                    oBuf.append("<id>"+oOrg.getStringNull(DB.id_ref,"")+"</id>");
                    oBuf.append("<gu>"+oOrg.getString(DB.gu_fellow)+"</gu>");
                    oBuf.append("<name>"+oOrg.getStringNull(DB.tx_name,"")+"</name>");
                    oBuf.append("<surname>"+oOrg.getStringNull(DB.tx_surname,"")+"</surname>");
                    oBuf.append("<email>"+oOrg.getStringNull(DB.tx_email,"")+"</email>");
                    oBuf.append("<timezone>"+oOrg.getStringNull(DB.tx_timezone,"")+"</timezone>");
                    oBuf.append("</organizer>");
			        DBSubset oRomm = new DBSubset(DB.k_rooms+" r,"+DB.k_x_meeting_room+" m","r."+DB.tp_room+",r."+DB.nm_room+",r."+DB.tx_comments,
			      								    "r."+DB.gu_workarea+"=? AND m."+DB.gu_meeting+"=? AND r."+DB.nm_room+"=m."+DB.nm_room, 10);
				    int nRomm = oRomm.load(oCon, new Object[]{sWrkA, oMeet.getString(DB.gu_meeting)});
                    oBuf.append("<rooms count=\""+String.valueOf(nRomm)+"\">");                  
                    for (int r=0; r<nRomm; r++) {
                      oBuf.append("<room type=\""+oRomm.getStringNull(0,r,"")+"\"><name>"+oRomm.getStringNull(1,r,"")+"</name><comments>"+oRomm.getStringNull(2,r,"")+"</comments></room>");
                    } // next
                    oBuf.append("</rooms>");
                    DBSubset oFlws = new DBSubset(DB.k_fellows +" f,"+DB.k_x_meeting_fellow +" x",
    			                                  "f." + DB.gu_fellow + ",f." + DB.id_ref + ",f." + DB.tx_name + ",f." + DB.tx_surname + ",f." + DB.tx_email + ",f." + DB.tx_timezone,
                                                  "f."+DB.tx_email+" IS NOT NULL AND f."+DB.gu_fellow+"=x."+DB.gu_fellow+" AND x."+DB.gu_meeting+"=?", 10);
                    DBSubset oCnts = new DBSubset(DB.k_member_address+" c,"+DB.k_x_meeting_contact+" x",
    			                                  "c." + DB.gu_contact + ",c." + DB.id_ref + ",c." + DB.tx_name + ",c." + DB.tx_surname + ",c." + DB.tx_email + ",'+00:00' AS " + DB.tx_timezone,
                    							  "c."+DB.tx_email+" IS NOT NULL AND c."+DB.gu_contact+"=x."+DB.gu_contact+" AND x."+DB.gu_meeting+"=?", 10);
                    oFlws.load(oCon, new Object[]{oMeet.getString(DB.gu_meeting)});
                    oCnts.load(oCon, new Object[]{oMeet.getString(DB.gu_meeting)});
                    oFlws.union(oCnts);
                    oBuf.append("<attendants count=\""+String.valueOf(oFlws.getRowCount())+"\">");
                    for (int f=0; f<oFlws.getRowCount(); f++) {
                      oBuf.append("<attendant>");
                      oBuf.append("<id>"+oFlws.getStringNull(1,f,"")+"</id>");
                      oBuf.append("<gu>"+oFlws.getString(0,f)+"</gu>");
                      oBuf.append("<name>"+oFlws.getStringNull(2,f,"")+"</name>");
                      oBuf.append("<surname>"+oFlws.getStringNull(3,f,"")+"</surname>");
                      oBuf.append("<email>"+oFlws.getStringNull(4,f,"")+"</email>");
                      oBuf.append("<timezone>"+oFlws.getStringNull(5,f,"")+"</timezone>");
                      oBuf.append("</attendant>");
                    }
                    oBuf.append("</attendants>");
					oBuf.append("</meeting></meetings></calendarresponse>");

              		oCon.close("HttpCalendarServlet.storemeeting");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
			      } catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) { if (!oCon.getAutoCommit()) oCon.rollback(); oCon.close("HttpCalendarServlet.storemeeting"); } } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	  } catch (NumberFormatException nfe) {
              		try { if (oCon!=null) if (!oCon.isClosed()) { if (!oCon.getAutoCommit()) oCon.rollback(); oCon.close("HttpCalendarServlet.storemeeting"); } } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, nfe.getMessage());
			  		return;
            	  } catch (ParseException dpe) {
              		try { if (oCon!=null) if (!oCon.isClosed()) { if (!oCon.getAutoCommit()) oCon.rollback(); oCon.close("HttpCalendarServlet.storemeeting"); } } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_BAD_REQUEST, dpe.getMessage());
			  		return;
            	  } catch (IllegalArgumentException iae) {
              		try { if (oCon!=null) if (!oCon.isClosed()) { if (!oCon.getAutoCommit()) oCon.rollback(); oCon.close("HttpCalendarServlet.storemeeting"); } } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_BAD_REQUEST, iae.getMessage());
			  		return;
			      } 
			    }
			  } else if (sCmd.equalsIgnoreCase("deleteMeeting")) {
			    if (null==sMeet) {
            	  response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter meeting is requiered");
			    } else {
			      try {
		      		oCon = oDbb.getConnection("HttpCalendarServlet.deletemeeting",false);
					oCon.setAutoCommit(false);
					Meeting oMeet = new Meeting();
					PreparedStatement oStm = oCon.prepareStatement("SELECT "+DB.gu_meeting+" FROM "+DB.k_meetings+" WHERE "+DB.gu_workarea+"=? AND ("+DB.gu_meeting+"=? OR "+DB.id_icalendar+"=?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
					oStm.setString(1, sWrkA);
					oStm.setString(2, sMeet);
					oStm.setString(3, sMeet);
					ResultSet oRst = oStm.executeQuery();					
					if (oRst.next()) {
					  String sDlte = oRst.getString(1);
              		  oRst.close();
              		  oStm.close();
					  boolean bDeleted = Meeting.delete(oCon, sDlte);
					  oCon.commit();

                      oBuf.append("<calendarresponse command=\"deleteMeeting\" code=\"0\"><error></error><meetings count=\""+String.valueOf(bDeleted ? 1 : 0)+"\"><meeting>");
                      oBuf.append("<id>"+sMeet+"</id>");
                      oBuf.append("<gu>"+sDlte+"</gu>");
					  oBuf.append("</meeting><meetings></calendarresponse>");

					} else {
              		  oRst.close();
              		  oStm.close();
                      oBuf.append("<calendarresponse command=\"deleteMeeting\" code=\"0\"><error></error><meetings count=\"0\"></meetings></calendarresponse>");
					}
              		oCon.close("HttpCalendarServlet.storemeeting");
		            response.setContentType("text/xml");
          			response.setCharacterEncoding("UTF-8");
          			response.getWriter().print(oBuf.toString());
			      } catch (SQLException sqle) {
              		try { if (oCon!=null) if (!oCon.isClosed()) { if (!oCon.getAutoCommit()) oCon.rollback(); oCon.close("HttpCalendarServlet.storemeeting"); } } catch (Exception ignore) { }
              		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, sqle.getMessage());
			  		return;
            	  }
			    }
			  } else if (sCmd.equalsIgnoreCase("disconnect")) {
  				if (oSecurityTokens.containsKey(sTok)) {
  				  oSecurityTokens.remove(sTok);
              	  oBuf.append("<calendarresponse command=\"disconnect\" code=\"0\"><error></error><value>true</value></calendarresponse>");
  				} else {
              	  oBuf.append("<calendarresponse command=\"disconnect\" code=\"0\"><error></error><value>false</value></calendarresponse>");
  				}
		        response.setContentType("text/xml");
          		response.setCharacterEncoding("UTF-8");
          	    response.getWriter().print(oBuf.toString());
			  }
            } // fi (iAuth)
		  } // fi (oUsrPwd)
        }
	  } else {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid command "+sCmd);
	  }      
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpCalendarServlet.doGet()");
    }	
  } // doGet

  // ---------------------------------------------------------------------------

  public void doPost(HttpServletRequest request, HttpServletResponse response)
     throws IOException, ServletException {
  }
}
