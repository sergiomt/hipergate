<%@ page import="java.util.Date,java.text.SimpleDateFormat,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBAudit,com.knowgate.dataobjs.DBPersist,com.knowgate.addrbook.Meeting,com.knowgate.misc.Gadgets,com.knowgate.debug.StackTraceUtil" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "meeting_store";
  final String gu_meeting = request.getParameter("gu_meeting");
  
  final String sOpCode = gu_meeting.length()>0 ? "NMET" : "MMET";
  
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  Date oDtStart=null, oDtEnd=null;
  
  try {
    oDtStart = oFmt.parse(request.getParameter("ystart")+"-"+request.getParameter("mstart")+"-"+request.getParameter("dstart")+" "+request.getParameter("hstart")+":"+request.getParameter("istart")+":00");
  } catch (Exception xcpt) {  
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Unparseable date&desc=Start date "+request.getParameter("ystart")+"-"+request.getParameter("mstart")+"-"+request.getParameter("dstart")+" is not valid&resume=meeting_edit.jsp"+(gu_meeting==null ? "" : "?gu_meeting="+gu_meeting)));
  }

  try {
    oDtEnd = oFmt.parse(request.getParameter("yend")+"-"+request.getParameter("mend")+"-"+request.getParameter("dend")+" "+request.getParameter("hend")+":"+request.getParameter("iend")+":00");
  } catch (Exception xcpt) {  
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Unparseable date&desc=End date "+request.getParameter("yend")+"-"+request.getParameter("mend")+"-"+request.getParameter("dend")+" is not valid&resume=meeting_edit.jsp"+(gu_meeting==null ? "" : "?gu_meeting="+gu_meeting)));
  }

  if (request.getParameter("tx_meeting").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Meeting title is required&desc=A title for the meeting is required&resume=meeting_edit.jsp"+(gu_meeting==null ? "" : "?gu_meeting="+gu_meeting)));
  }

  Meeting oMeet = new Meeting();
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

		if (gu_meeting.length()>0) {
		  oMeet.load(oConn, new Object[]{gu_meeting});
		  oMeet.clearRooms(oConn);
		} else {
		  oMeet.put(DB.id_domain, oUser.getInt(DB.id_domain));
		  oMeet.put(DB.gu_workarea, oUser.getString(DB.gu_workarea));
		  oMeet.put(DB.gu_fellow, oUser.getString(DB.gu_user));
		  oMeet.put(DB.bo_private, (short) 0);
		}

		oMeet.replace(DB.gu_writer, oUser.getString(DB.gu_user));
		oMeet.replace(DB.dt_start, oDtStart);
	  oMeet.replace(DB.dt_end, oDtEnd);
	  oMeet.replace(DB.tp_meeting, request.getParameter("tp_meeting"));
	  oMeet.replace(DB.tx_meeting, request.getParameter("tx_meeting"));
		if (request.getParameter("nm_room").length()>0) oMeet.setRoom(oConn, request.getParameter("nm_room"));

		oMeet.store(oConn);

		if (gu_meeting.length()==0) {
		  oMeet.addAttendant(oConn, oUser.getString(DB.gu_user));
		}

    DBAudit.log(oConn, Meeting.ClassId, sOpCode, oUser.getString(DB.gu_user), oMeet.getString(DB.gu_meeting), null, 0, 0, oMeet.getStringNull(DB.tx_meeting,""), null);
    
    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (Exception xcpt) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close(PAGE_NAME);
      }
    oConn = null;
    
		out.write("<?xml version=\"1.0\"?><wml><card>"+xcpt.getClass().getName()+"<br/>"+xcpt.getMessage()+"<br/>"+Gadgets.replace(StackTraceUtil.getStackTrace(xcpt),"\n","<br/>")+"</card></wml>");
  }

  if (null==oConn) return;
  oConn = null;
  
  response.sendRedirect ("home.jsp");
%>