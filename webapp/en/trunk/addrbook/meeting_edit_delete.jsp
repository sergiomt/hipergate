<%@ page import="java.util.Date,com.knowgate.addrbook.Meeting,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.gdata.GCalendarSynchronizer" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_meeting = request.getParameter("gu_meeting");
    
  JDCConnection oCon = GlobalDBBind.getConnection("meeting_delete");
    
  try {

		String sTxMeeting = DBCommand.queryStr(oCon, "SELECT "+DB.tx_meeting+" FROM "+DB.k_meetings+" WHERE "+DB.gu_meeting+"='"+gu_meeting+"'");
		Date dtMeeting = DBCommand.queryDateTime(oCon, "SELECT "+DB.dt_start+" FROM "+DB.k_meetings+" WHERE "+DB.gu_meeting+"='"+gu_meeting+"'");
		String sGuFellow = DBCommand.queryStr(oCon, "SELECT "+DB.gu_fellow+" FROM "+DB.k_meetings+" WHERE "+DB.gu_meeting+"='"+gu_meeting+"'");

    oCon.setAutoCommit (false);

    // Delete meeting from Google Calendar if synchronization is activated and a valid email+password+calendar name is found at k_user_pwd table
    final String sGDataSync = GlobalDBBind.getProperty("gdatasync", "1");
    if (sGDataSync.equals("1") || sGDataSync.equalsIgnoreCase("true") || sGDataSync.equalsIgnoreCase("yes")) {
      GCalendarSynchronizer oGSync = new GCalendarSynchronizer();
      Meeting oMeet = new Meeting(oCon, gu_meeting);
      if (oGSync.connect(oCon, oMeet.getString(DB.gu_fellow), oMeet.getString(DB.gu_workarea), GlobalCacheClient)) {
        oGSync.deleteMeetingFromGoogle(oCon, oMeet);
      } // fi
    } // fi

    Meeting.delete(oCon, gu_meeting);

    DBAudit.log(oCon, Meeting.ClassId, "DMET", id_user, gu_meeting, sGuFellow, 0, getClientIP(request), sTxMeeting, dtMeeting.toString());

    oCon.commit();

    oCon.setAutoCommit (true);
    
    com.knowgate.http.portlets.HipergatePortletConfig.touch(oCon, id_user, "com.knowgate.http.portlets.CalendarTab", getCookie(request,"workarea",""));
    
    oCon.close("meeting_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"meeting_delete");

      oCon = null;
      
      if (com.knowgate.debug.DebugFile.trace) {      
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
      }
      
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  String sReferer = request.getParameter("referer");
  if (null==sReferer) sReferer = "schedule.jsp";
  
  response.sendRedirect(response.encodeRedirectUrl(sReferer+".jsp?id_domain="+request.getParameter("id_domain")+"&gu_workarea="+request.getParameter("gu_workarea")+"&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "&year=" + request.getParameter("year") + "&month=" + request.getParameter("month") + "&day=" + request.getParameter("day"))); 
 %>
<%@ include file="../methods/page_epilog.jspf" %>