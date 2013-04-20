<%@ page import="java.text.SimpleDateFormat,java.util.Enumeration,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.marketing.Activity,com.knowgate.marketing.ActivityTag,com.knowgate.addrbook.Meeting,com.knowgate.hipermail.AdHocMailing,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.workareas.FileSystemWorkArea,com.oreilly.servlet.MultipartRequest" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/multipartreqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.

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

  final String PAGE_NAME = "activity_store";

  final int WebBuilder = 14;
  final int Hipermail = 21;
  final int CollaborativeTools = 17;

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = Gadgets.chomp(sTmpDir,java.io.File.separator);
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  SimpleDateFormat oDtFmt = new SimpleDateFormat("yyyy-MM-dd");
  SimpleDateFormat oTsFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  MultipartRequest oReq = null;

  try {
    oReq = new MultipartRequest(request, sTmpDir, Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760")), "UTF-8");
  }
  catch (IOException ioe) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + ioe.getMessage() + "&resume=_back"));
  }
  if (null==oReq) return;

  Integer id_domain = Integer.parseInt(oReq.getParameter("id_domain"));
  String gu_workarea = oReq.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  String id_language = getNavigatorLanguage(request);
  String gu_activity = oReq.getParameter("gu_activity");
  String gu_mailing = oReq.getParameter("gu_mailing");
  String gu_pageset = oReq.getParameter("gu_pageset");
  String gu_meeting = oReq.getParameter("gu_meeting");
  String id_template = oReq.getParameter("id_template");
  String lists = oReq.getParameter("lists");
  String rooms = oReq.getParameter("rooms");
  String tags = oReq.getParameter("tags");

  String[] aFellows = Gadgets.split(oReq.getParameter("fellows"),',');

  boolean bEMailing = nullif(oReq.getParameter("chk_emailing")).equals("1");
  boolean bMeeting = nullif(oReq.getParameter("chk_meeting")).equals("1");
  
  String sOpCode = gu_activity.length()>0 ? "NACY" : "MACY";

  String sSep = System.getProperty("file.separator");
  
  String sWrkAHome = sStorage + "domains" + sSep + id_domain.toString() + sSep + "workareas" + sSep + gu_workarea + sSep;
  String sCatPath = "apps/Marketing/";
      
  Activity oActy = new Activity();

  JDCConnection oConn = null;
  
  // try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 
  
    loadRequest(oConn, oReq, oActy);

    oConn.setAutoCommit (false);
    
		if (bEMailing && ((iAppMask & (1<<Hipermail))!=0) && ((iAppMask & (1<<WebBuilder))!=0)) {
		  if (id_template.equals("adhoc")) {
		    AdHocMailing oAdhm = new AdHocMailing();
		    if (gu_mailing.length()==0) {
		      oAdhm.put(DB.gu_workarea, gu_workarea);
		      oAdhm.put(DB.gu_writer, id_user);
		      oAdhm.put(DB.nm_mailing, oReq.getParameter("id_ref"));
		      oAdhm.put(DB.bo_urgent, Short.parseShort(nullif(oReq.getParameter("bo_urgent"),"0")));
		      oAdhm.put(DB.bo_reminder, Short.parseShort(nullif(oReq.getParameter("bo_reminder"),"0")));
		      oAdhm.put(DB.bo_html_part, (short)1);
		      oAdhm.put(DB.bo_plain_part, (short)1);
		      oAdhm.put(DB.bo_attachments, (short)1);
		      oAdhm.put(DB.dt_execution, oReq.getParameter("dt_execution"), oDtFmt);
          oAdhm.put("tx_subject", oReq.getParameter("tx_subject"));
          oAdhm.put("tx_email_from", oReq.getParameter("tx_email_from"));
          oAdhm.put("tx_email_reply", oReq.getParameter("tx_email_from"));
          oAdhm.put("nm_from", oReq.getParameter("nm_from"));
		    } else if (oAdhm.load(oConn, new Object[]{gu_mailing})) {
		    	DBCommand.executeUpdate(oConn, "DELETE FROM "+DB.k_x_adhoc_mailing_list+" WHERE "+DB.gu_mailing+"='"+gu_mailing+"'");
		      oAdhm.replace(DB.bo_urgent, Short.parseShort(nullif(oReq.getParameter("bo_urgent"),"0")));
		      oAdhm.replace(DB.bo_reminder, Short.parseShort(nullif(oReq.getParameter("bo_reminder"),"0")));
		      oAdhm.replace(DB.nm_mailing, oReq.getParameter("id_ref"));
		      oAdhm.replace(DB.dt_execution, oReq.getParameter("dt_execution"), oDtFmt);
          oAdhm.replace("tx_subject", oReq.getParameter("tx_subject"));
          oAdhm.replace("tx_email_from", oReq.getParameter("tx_email_from"));
          oAdhm.replace("tx_email_reply", oReq.getParameter("tx_email_from"));
          oAdhm.replace("nm_from", oReq.getParameter("nm_from"));
		    }
		    
		    oAdhm.store(oConn);
				oActy.put(DB.gu_mailing, oAdhm.getString(DB.gu_mailing));
				
		    if (lists.length()>0) {
		      String[] aLists = Gadgets.split(lists, ',');
		      for (int l=0; l<aLists.length; l++) {
		    	  DBCommand.executeUpdate(oConn, "INSERT INTO "+DB.k_x_adhoc_mailing_list+" ("+DB.gu_list+","+DB.gu_mailing+") VALUES ('"+aLists[l]+"','"+oAdhm.getString(DB.gu_mailing)+"')");
		      } // next
		    } // fi

		  } else {

		  }
		} // fi (bEMailing)

		if (bMeeting && ((iAppMask & (1<<CollaborativeTools))!=0)) {
		  Meeting oMeet = new Meeting();

		  if (gu_meeting.length()==0) {
				oMeet.put(DB.id_domain, id_domain);
				oMeet.put(DB.gu_workarea, gu_workarea);
				oMeet.put(DB.bo_private, (short)0);
				oMeet.put(DB.gu_writer, id_user);
				oMeet.put(DB.gu_fellow, aFellows[0]);
		    oMeet.put(DB.dt_start, oReq.getParameter("dt_start"), oTsFmt);
		    oMeet.put(DB.dt_end, oReq.getParameter("dt_end"), oTsFmt);
				if (oReq.getParameter("tp_meeting").length()>0) oMeet.put(DB.tp_meeting, oReq.getParameter("tp_meeting"));
				oMeet.put(DB.tx_meeting, oReq.getParameter("tl_activity"));
				oMeet.put(DB.de_meeting, oReq.getParameter("de_activity"));
				if (oReq.getParameter("gu_address").length()>0) oMeet.put(DB.gu_address, oReq.getParameter("gu_address"));
		    oMeet.store(oConn);
				for (int f=0; f<aFellows.length; f++) {
				  oMeet.addAttendant(oConn, aFellows[f]);
				} // next
				if (rooms.length()>0) {
				  String[] aRooms = Gadgets.split(rooms,',');
				  for (int r=0; r<aRooms.length; r++) {
				    oMeet.setRoom(oConn, aRooms[r]);
				  } // next
				} // fi
		  } else {
		  	oMeet.load(oConn, new Object[]{gu_meeting});		  	
				oMeet.replace(DB.id_domain, id_domain);
				oMeet.replace(DB.gu_workarea, gu_workarea);
				oMeet.replace(DB.gu_writer, id_user);
				oMeet.replace(DB.gu_fellow, aFellows[0]);
		    oMeet.replace(DB.dt_start, oReq.getParameter("dt_start"), oTsFmt);
		    oMeet.replace(DB.dt_end, oReq.getParameter("dt_end"), oTsFmt);
		    if (oReq.getParameter("tp_meeting").length()>0) 
				  oMeet.replace(DB.tp_meeting, oReq.getParameter("tp_meeting"));
				else
					oMeet.remove(DB.tp_meeting);
				oMeet.replace(DB.tx_meeting, oReq.getParameter("tl_activity"));
				oMeet.replace(DB.de_meeting, oReq.getParameter("de_activity"));
				if (oReq.getParameter("gu_address").length()>0)
				  oMeet.replace(DB.gu_address, oReq.getParameter("gu_address"));
		    else
		    	oMeet.remove(DB.gu_address);
		    oMeet.store(oConn);
				oMeet.clearAttendants(oConn);
				for (int f=0; f<aFellows.length; f++) {
				  oMeet.setAttendant(oConn, aFellows[f]);
				} // next
				oMeet.clearRooms(oConn);
				if (rooms.length()>0) {
				  String[] aRooms = Gadgets.split(rooms,',');
				  for (int r=0; r<aRooms.length; r++) {
				    oMeet.setRoom(oConn, aRooms[r]);
				  } // next
				} // fi
		  }
		  oActy.put(DB.gu_meeting, oMeet.getString(DB.gu_meeting));
		} // fi (bMeeting)

    oActy.store(oConn);

    if (tags.length()>0) {
      ActivityTag.storeMultiple(oConn, oActy.getString(DB.gu_activity), null, Gadgets.split(tags, "###"));
    }    
    
    Enumeration oFileNames = oReq.getFileNames();

    while (oFileNames.hasMoreElements()) {
      String sFileName = oReq.getOriginalFileName(oFileNames.nextElement().toString());
      if (sFileName!=null) {
        oActy.addAttachment(oConn, id_user, sTmpDir, sFileName, true);
      } // fi
    } // wend

    DBAudit.log(oConn, oActy.ClassId, sOpCode, id_user, oActy.getString(DB.gu_activity), null, 0, 0, oActy.getString(DB.tl_activity), null);

    oConn.commit();
    oConn.close(PAGE_NAME);
  /*
  } catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  */
  
  if (null==oConn) return;
  
  oConn = null;
  
  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>