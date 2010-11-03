<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Address,com.knowgate.crm.Contact,com.knowgate.crm.Company" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%
/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "audience_store";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_activity = request.getParameter("gu_activity");
  String gu_contact = request.getParameter("gu_contact");
  String gu_company = request.getParameter("gu_company");
  String gu_address = request.getParameter("gu_address");
  String nm_legal = request.getParameter("nm_legal");
  String tx_email = request.getParameter("tx_email");

  String sOpCode = "MAXA";
      
  DBPersist oAxa = new DBPersist(DB.k_x_activity_audience, "ActivityAudience");
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

    loadRequest(oConn, request, oAxa);
  
    oConn.setAutoCommit (false);

		if (gu_contact.length()==0) {
      Contact oCnt = new Contact();
      loadRequest(oConn, request, oCnt);
    	oCnt.store(oConn);
    	oAxa.put(DB.gu_contact,oCnt.getString(DB.gu_contact));
		} else {
    	oAxa.put(DB.gu_contact,gu_contact);		
		}

		if (gu_company.length()==0 && nm_legal.length()>0) {
		  String sGuCompany = Company.getIdFromName(oConn, nm_legal, gu_workarea);
		  if (null==sGuCompany) {
		    Company oCmp = new Company();
        loadRequest(oConn, request, oCmp);
    	  oCmp.store(oConn);
    	}
    	oAxa.put(DB.gu_company,sGuCompany);
		}

		if (gu_address.length()==0 && tx_email.length()>0) {
		  String sGuAddress = Address.getIdFromEmail(oConn, tx_email, gu_workarea);
      if (null==sGuAddress) {
        Address oAdr = new Address();
        loadRequest(oConn, request, oAdr);
    	  if (nm_legal.length()>0) oAdr.put(DB.nm_company, nm_legal);
    	  oAdr.put(DB.bo_active, (short) 1);
    	  oAdr.put(DB.gu_user, id_user);
    	  oAdr.put(DB.ix_address, Address.nextLocalIndex(oConn, DB.k_x_contact_addr, DB.gu_contact, oAxa.getString(DB.gu_contact)));
    	  oAdr.store(oConn);
    	  new Contact(oConn, oAxa.getString(DB.gu_contact)).addAddress(oConn, oAdr.getString(DB.gu_address));
    	}
    	oAxa.put(DB.gu_address,sGuAddress);
		} else {
		  oAxa.put(DB.gu_address,gu_address);
		}
    
    oAxa.store(oConn);

    DBAudit.log(oConn, (short) 311, sOpCode, id_user, oAxa.getString(DB.gu_activity), oAxa.getString(DB.gu_contact), 0, 0, tx_email, request.getParameter("tx_name")+" "+request.getParameter("tx_surname"));
    
    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
  oConn = null;
  
  response.sendRedirect (response.encodeRedirectUrl ("activity_audience.jsp?gu_activity="+gu_activity));

%><%@ include file="../methods/page_epilog.jspf" %>