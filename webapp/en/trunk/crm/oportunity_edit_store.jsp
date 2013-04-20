<%@ page import="java.text.SimpleDateFormat,java.text.ParseException,java.util.Date,java.util.StringTokenizer,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.addrbook.Meeting,com.knowgate.misc.Gadgets,com.knowgate.http.portlets.HipergatePortletConfig,com.knowgate.scheduler.Event,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/customattrs.jspf" %>
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
  
  final int CollabTools = 17;
  
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_user = getCookie (request, "userid", null);  
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_company = request.getParameter("gu_company");
  String gu_contact = request.getParameter("gu_contact");
  String gu_list = request.getParameter("gu_list");
  String gu_oportunity = request.getParameter("gu_oportunity");
  String dt_next_action = request.getParameter("dt_next_action");
  String id_status = request.getParameter("id_status");
  String id_former_status = request.getParameter("id_former_status");
  String gu_meeting = null;
  boolean bCreateMeeting = nullif(request.getParameter("chk_meeting")).equals("1");
  boolean bOnWonOptions = false;
  final String sOpCode = gu_oportunity.length()>0 ? "NOPO" : "MOPO";
    
  JDCConnection oConn = null;  
  ResultSet oRSet;
  
  Oportunity oOprt = new Oportunity();
  
  try {

    oConn = GlobalDBBind.getConnection("oportunitystore");

    oOprt.allcaps(WorkArea.allCaps(oConn, gu_workarea));
		
    loadRequest(oConn, request, oOprt);
    
    oConn.setAutoCommit (false);    
    
    if (gu_list.length()==0) {
      if (gu_oportunity.length()>0 && request.getParameter("id_status").equals("GANADA")) {
        String sPreviousStatus = DBCommand.queryStr(oConn, "SELECT "+DB.id_status+" FROM "+DB.k_oportunities+" WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"'");
        if (sPreviousStatus!=null) bOnWonOptions = !sPreviousStatus.equals("GANADA");
      }
      oOprt.store(oConn);    

			Timestamp dtStart = null;
      PreparedStatement oUpdt = oConn.prepareStatement("SELECT MAX(dt_start) FROM k_oportunities AS s INNER JOIN k_phone_calls AS r ON r.gu_oportunity = s.gu_oportunity WHERE s.gu_oportunity=?");
      oUpdt.setString(1, oOprt.getString(DB.gu_oportunity));
      oRSet = oUpdt.executeQuery();
      if (oRSet.next()) {
        dtStart = oRSet.getTimestamp(1);
        if (oRSet.wasNull()) dtStart = null;
      }
      oRSet.close();
      oUpdt.close();
			if (null!=dtStart) {
			  oUpdt = oConn.prepareStatement("UPDATE k_oportunities SET dt_last_call=? WHERE gu_oportunity=?");
        oUpdt.setTimestamp(1, dtStart);
        oUpdt.setString(2, oOprt.getString(DB.gu_oportunity));
				oUpdt.executeUpdate();
        oRSet.close();
        oUpdt.close();
			}

			if (!id_status.equals(id_former_status)) {
				PreparedStatement oClog = oConn.prepareStatement("INSERT INTO k_oportunities_changelog (gu_oportunity,nm_column,dt_modified,gu_writer,id_former_status,id_new_status,tx_value) VALUES (?,'id_status',?,?,?,?,?)");
				oClog.setString(1, oOprt.getString(DB.gu_oportunity));
				oClog.setTimestamp(2, new Timestamp(new Date().getTime()));
				oClog.setString(3, id_user);
				oClog.setString(4, id_former_status);
				oClog.setString(5, id_status);
				oClog.setString(6, request.getParameter("tx_cause"));
				oClog.executeUpdate();
				oClog.close();
			}

      storeAttributes (request, GlobalCacheClient, oConn, DB.k_oportunities_attrs, gu_workarea, oOprt.getString(DB.gu_oportunity));

      DBAudit.log(oConn, com.knowgate.crm.Oportunity.ClassId, sOpCode, id_user, oOprt.getString(DB.gu_oportunity), null, 0, 0, oOprt.getStringNull(DB.tl_oportunity,""), null);    
    
      Event.trigger(oConn, Integer.parseInt(id_domain), sOpCode, oOprt, GlobalDBBind.getProperties());

    }
    else {
      DistributionList oList = new DistributionList(oConn, gu_list);
      String sContacts = oList.activeContacts(oConn);
      
      if (com.knowgate.debug.DebugFile.trace) com.knowgate.debug.DebugFile.writeln("contacts = {" + sContacts + "}");
       
      PreparedStatement oCont = oConn.prepareStatement("SELECT " + DB.gu_company + "," + DB.tx_name + "," + DB.tx_surname + " FROM " + DB.k_contacts + " WHERE " + DB.gu_contact + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      PreparedStatement oComp = oConn.prepareStatement("SELECT " + DB.nm_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      String sContactId, sCompanyId, sFullName, sSurName;
            
      StringTokenizer oStrTok = new StringTokenizer(sContacts, ",");

      while (oStrTok.hasMoreElements()) {
        sContactId = oStrTok.nextToken();
        
        oCont.setString(1, sContactId);
        oRSet = oCont.executeQuery(); 

	      if (oRSet.next()) {
          sCompanyId = oRSet.getString(1);
          if (oRSet.wasNull())  {
            oOprt.remove(DB.gu_company);
            oOprt.remove(DB.tx_company);
          }

          sFullName = oRSet.getString(2);
          if (oRSet.wasNull()) sFullName = "";
          sSurName = oRSet.getString(3);
          if (!oRSet.wasNull()) sFullName += " " + sSurName;
          
          oOprt.replace(DB.gu_contact, sContactId);    
          oOprt.replace(DB.tx_contact, sFullName);    
        }
        else
          sCompanyId = null;
          
        oRSet.close();

	      if (null!=sCompanyId) {
          oComp.setString(1, sCompanyId);
          oRSet = oComp.executeQuery(); 
	        oRSet.next();
          oOprt.replace(DB.gu_company, sCompanyId);
          oOprt.replace(DB.tx_company, oRSet.getString(1));
          oRSet.close();	  
	      }
	
        oOprt.replace(DB.gu_oportunity, Gadgets.generateUUID());

        oOprt.store(oConn);

        storeAttributes (request, GlobalCacheClient, oConn, DB.k_oportunities_attrs, gu_workarea, oOprt.getString(DB.gu_oportunity));

        DBAudit.log(oConn, com.knowgate.crm.Oportunity.ClassId, sOpCode, id_user, oOprt.getString(DB.gu_oportunity), null, 0, 0, oOprt.getStringNull(DB.tl_oportunity,""), null);

      } // wend
      
      oComp.close();
      oCont.close();
    } // fi
    
%><%@ include file="oportunity_create_meeting.jspf" %><%

    oConn.commit();
    
    oConn.close("oportunitystore");
    
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"oportunitystore");
    
    oConn = null;
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (ParseException e) {  
    disposeConnection(oConn,"oportunitystore");
    
    oConn = null;
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ParseException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  if (bOnWonOptions)
    response.sendRedirect (response.encodeRedirectUrl ("oportunity_won_options.jsp?gu_workarea="+gu_workarea+"&gu_oportunity="+gu_oportunity));
  else
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>