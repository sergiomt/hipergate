<%@ page import="java.util.HashMap,java.util.StringTokenizer,java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.addrbook.Meeting,com.knowgate.addrbook.Fellow,com.knowgate.gdata.GCalendarSynchronizer" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);

  String ts_start, ts_end;
  final boolean bIsNew = nullif(request.getParameter("gu_meeting")).length()==0;
  String gu_meeting = nullif(request.getParameter("gu_meeting"));
  String bo_notify = nullif(request.getParameter("bo_notify"),"0");
  String gu_fellow = nullif(request.getParameter("gu_fellow"),id_user);
  String gu_writer = nullif(request.getParameter("gu_writer"),id_user);
  String gu_address = nullif(request.getParameter("gu_address"));
  String pr_cost = nullif(request.getParameter("pr_cost"));
  if (gu_writer.length()==0) gu_writer=id_user;
  if (gu_fellow.length()==0) gu_fellow=id_user;

  String tx_meeting = request.getParameter("tx_meeting");
  if (tx_meeting!=null) if (tx_meeting.length()==0) tx_meeting=null;

  String de_meeting = request.getParameter("de_meeting");
  if (de_meeting!=null) if (de_meeting.length()==0) de_meeting=null;
  
  String sOpCode = gu_meeting.length()>0 ? "NMET" : "MMET";
  String sSQL;
  PreparedStatement oStmt;
  Statement oUpdt;

  Meeting oMee;
  StringTokenizer oColTok;

  JDCConnection oConn = GlobalDBBind.getConnection("meetingeditstore");

  try {

    oConn.setAutoCommit (false);
    
    // //Si el usuario no existe en la tabla k_fellows,
    // //añadirlo automáticamente para que no casque
    // //la foreign key
    Fellow oFlw = new Fellow(gu_fellow);
    if (!oFlw.exists(oConn)) {
      oFlw.clone(new ACLUser(oConn, gu_fellow));
      oFlw.replace(DB.gu_workarea, gu_workarea);      
      oFlw.store(oConn);

      GlobalCacheClient.expire("k_fellows.id_domain[" + String.valueOf(id_domain) + "]");
      GlobalCacheClient.expire("k_fellows.gu_workarea[" + gu_workarea + "]");

    } // fi (!oFlw.exists())
    oFlw = null;
    
    // --------------------------------------------------------

    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_ORACLE:
  	ts_start = "TO_DATE('" + request.getParameter("ts_start") + "','YYYY-MM-DD HH24:MI:SS')";
  	ts_end = "TO_DATE('" + request.getParameter("ts_end") + "','YYYY-MM-DD HH24:MI:SS')";
        break;
      case JDCConnection.DBMS_POSTGRESQL:
  	ts_start = "TIMESTAMP '" + request.getParameter("ts_start") + "'";
  	ts_end = "TIMESTAMP '" + request.getParameter("ts_end") + "'";
        break;      
      case JDCConnection.DBMS_MYSQL:
  	ts_start = "TIMESTAMP ('" + request.getParameter("ts_start") + "')";
  	ts_end = "TIMESTAMP ('" + request.getParameter("ts_end") + "')";
        break;      
      default:
  	ts_start = "{ts '" + request.getParameter("ts_start") + "'}";
  	ts_end = "{ts '" + request.getParameter("ts_end") + "'}";
    }
        
    if (bIsNew) {
      gu_meeting = Gadgets.generateUUID();
            
      sSQL = "INSERT INTO " + DB.k_meetings + " (" + DB.gu_meeting + "," + DB.gu_workarea + "," + DB.id_domain + "," + DB.gu_fellow + "," + DB.dt_start + "," + DB.dt_end + "," + DB.bo_private + "," + DB.df_before + "," + DB.tp_meeting + "," + DB.tx_meeting + "," + DB.de_meeting + "," + DB.gu_writer + "," + DB.gu_address + "," + DB.pr_cost + ") VALUES (?,?,?,?," + ts_start + "," + ts_end + ",?,?,?,?,?,?,?,?)";
      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setString(1,gu_meeting);
      oStmt.setString(2,gu_workarea);
      oStmt.setInt(3,id_domain);
      oStmt.setString(4,gu_fellow);
      oStmt.setShort(5, Short.parseShort(nullif(request.getParameter("bo_private"),"0")));
      oStmt.setInt(6, Integer.parseInt(nullif(request.getParameter("df_before"),"-1")));
      oStmt.setString(7, request.getParameter("tp_meeting").length()>0 ? request.getParameter("tp_meeting") : null);
      oStmt.setString(8, tx_meeting);
      oStmt.setString(9, de_meeting);
      oStmt.setString(10, gu_writer);
      if (gu_address.length()>0)
        oStmt.setString(11, gu_address);
      else
      	oStmt.setNull(11, java.sql.Types.CHAR);
      if (pr_cost.length()>0)
        oStmt.setFloat(12, Float.parseFloat(pr_cost));
      else
      	oStmt.setNull(12, java.sql.Types.FLOAT);
      oStmt.execute();
      oStmt.close();
    }
    else {
      sSQL = "UPDATE " + DB.k_meetings + " SET " + DB.dt_start + "=" + ts_start + "," + DB.dt_end + "=" + ts_end + "," + DB.bo_private + "=?," + DB.df_before + "=?," + DB.tp_meeting + "=?," + DB.tx_meeting + "=?," + DB.de_meeting + "=?," + DB.gu_writer + "=?, " + DB.gu_address + "=?, " + DB.pr_cost + "=? WHERE " + DB.gu_meeting + "=?";
      oStmt = oConn.prepareStatement(sSQL);
      oStmt.setShort (1, Short.parseShort(nullif(request.getParameter("bo_private"),"0")));
      oStmt.setInt   (2, Integer.parseInt(nullif(request.getParameter("df_before"),"-1")));
      oStmt.setString(3, request.getParameter("tp_meeting").length()>0 ? request.getParameter("tp_meeting") : null);
      oStmt.setString(4, tx_meeting);
      oStmt.setString(5, de_meeting);
      oStmt.setString(6, gu_writer);
      if (gu_address.length()>0)
        oStmt.setString(7, gu_address);
      else
      	oStmt.setNull(7, java.sql.Types.CHAR);
      if (pr_cost.length()>0)
        oStmt.setFloat(8, Float.parseFloat(pr_cost));
      else
      	oStmt.setNull(8, java.sql.Types.FLOAT);
      oStmt.setString(9, gu_meeting);
      oStmt.execute();
      oStmt.close();      
    }

		oMee = new Meeting(oConn, gu_meeting);

    if (!bIsNew) {      
      oUpdt = oConn.createStatement();
      oUpdt.executeUpdate("DELETE FROM " + DB.k_x_meeting_fellow + " WHERE " + DB.gu_meeting + "='" + oMee.getString(DB.gu_meeting) + "'");
      oUpdt.executeUpdate("DELETE FROM " + DB.k_x_meeting_contact + " WHERE " + DB.gu_meeting + "='" + oMee.getString(DB.gu_meeting) + "'");
      oUpdt.close();
    }

    HashMap<String,String> oAttendants = new HashMap();
    oColTok = new StringTokenizer(request.getParameter("attendants"), ",");
    while (oColTok.hasMoreElements()) {
      String sAttendant = oColTok.nextToken();
      if (!oAttendants.containsKey(sAttendant)) {
        com.knowgate.http.portlets.HipergatePortletConfig.touch(oConn, sAttendant, "com.knowgate.http.portlets.CalendarTab", gu_workarea);
        oMee.addAttendant(oConn, sAttendant);
        oAttendants.put(sAttendant,sAttendant);
      } // fi
    } // wend
    oColTok = null;

    if (!bIsNew) {
      oUpdt = oConn.createStatement();
      oUpdt.executeUpdate("DELETE FROM " + DB.k_x_meeting_room + " WHERE " + DB.gu_meeting + "='" + oMee.getString(DB.gu_meeting) + "'");
      oUpdt.close();
    }

    oColTok = new StringTokenizer(request.getParameter("rooms"), ",");
		oStmt = oConn.prepareStatement("INSERT INTO " + DB.k_x_meeting_room + "(" + DB.gu_meeting + "," + DB.nm_room + "," + DB.dt_start + "," + DB.dt_end + ") VALUES (?,?,?,?)");
    while (oColTok.hasMoreElements()) {
			oStmt.setString(1, gu_meeting);
			oStmt.setString(2, oColTok.nextToken());
			oStmt.setTimestamp(3, oMee.getTimestamp(DB.dt_start));
		  oStmt.setTimestamp(4, oMee.getTimestamp(DB.dt_end));
			oStmt.executeUpdate();
    } // wend
	  oStmt.close();			
    oColTok = null;

    oMee = null;

    // Write meeting to Google Calendar if synchronization is activated and a valid email+password+calendar name is found at k_user_pwd table
    final String sGDataSync = GlobalDBBind.getProperty("gdatasync", "1");
    if (sGDataSync.equals("1") || sGDataSync.equalsIgnoreCase("true") || sGDataSync.equalsIgnoreCase("yes")) {
      GCalendarSynchronizer oGSync = new GCalendarSynchronizer();
      if (oGSync.connect(oConn, gu_fellow, gu_workarea, GlobalCacheClient)) {
        oGSync.writeMeetingToGoogle(oConn, new Meeting(oConn, gu_meeting));
      } // fi
    } // fi
    
    DBAudit.log(oConn, Meeting.ClassId, sOpCode, id_user, gu_meeting, null, 0, 0, null, null);

    oConn.commit();

    oConn.setAutoCommit (true);
    
    oConn.close("meetingeditstore");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("meetingeditstore");
        oConn=null;
      }
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("meetingeditstore");
        oConn=null;
      }
    if (com.knowgate.debug.DebugFile.trace) {      
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NumberFormatException", e.getMessage());
    }          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn = null;

  if (bo_notify.equals("1")) {
    response.sendRedirect (response.encodeRedirectUrl ("meeting_notify.jsp?gu_meeting="+gu_meeting));
    return;
  }
  else {
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.parent.opener.location.reload(true); parent.close();<" + "/SCRIPT" +"></HEAD></HTML>");
  }
  
%>
<%@ include file="../methods/page_epilog.jspf" %>