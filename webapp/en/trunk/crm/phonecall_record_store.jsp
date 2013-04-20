<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.PhoneCall,com.knowgate.crm.Contact,com.knowgate.crm.Company,com.knowgate.hipergate.Address" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "phonecall_record_store";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_company = request.getParameter("gu_company");
  String gu_oportunity = request.getParameter("gu_oportunity");
  String telf = nullif(request.getParameter("telf"));
  String tx_other_phone = nullif(request.getParameter("tx_other_phone"));
  String tp_location = nullif(request.getParameter("tp_location"));

  String id_user = getCookie (request, "userid", null);
  
  PhoneCall oPhn = new PhoneCall();
  Contact oCnt = new Contact();

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 
  
    loadRequest(oConn, request, oPhn);

	  oCnt.load(oConn, request.getParameter("gu_contact"));

    oConn.setAutoCommit (false);

		if (gu_company.length()>0) {
	    oCnt.replace(DB.gu_company, gu_company);
		} else {
			oCnt.remove(DB.gu_company);
			if (request.getParameter("nm_company").length()>0) {
			  Company oCmp = new Company();
			  oCmp.put(DB.gu_workarea, gu_workarea);
			  oCmp.put(DB.bo_restricted, (short)0);
			  oCmp.put(DB.nm_legal, request.getParameter("nm_company"));
			  oCmp.put(DB.nm_commercial, request.getParameter("nm_company"));
			  oCmp.store(oConn);
        gu_company = oCmp.getString(DB.gu_company);
        DBAudit.log(oConn, Company.ClassId, "NCOM", id_user, gu_company, null, PhoneCall.ClassId, 0, oCmp.getString(DB.nm_legal), null);
	      oCnt.put(DB.gu_company, gu_company);
			} // fi (nm_company!="")
		} // fi (gu_company)
		
	  if (request.getParameter("tx_name").length()==0)
	    oCnt.remove(DB.tx_name);
	  else
	    oCnt.replace(DB.tx_name, request.getParameter("tx_name"));
	  if (request.getParameter("tx_surname").length()==0)
	    oCnt.remove(DB.tx_surname);
	  else
	    oCnt.replace(DB.tx_surname, request.getParameter("tx_surname"));
	  if (request.getParameter("de_title").length()==0)
	    oCnt.remove(DB.de_title);
	  else
	    oCnt.replace(DB.de_title, request.getParameter("de_title"));
	  oCnt.replace(DB.id_status, request.getParameter("id_contact_status"));
	  oCnt.store(oConn);
    
    if (telf.equals("O") && tx_other_phone.length()>0 && tp_location.length()>0) {
      Address oAdr = oCnt.getAddress(oConn, request.getParameter("tp_location"));
      if (oAdr!=null) {
        oAdr.replace(request.getParameter("tp_phone"),request.getParameter("tx_other_phone"));
        oAdr.store(oConn);
      } // fi
    } // fi
    
    oPhn.put(DB.contact_person, (oCnt.getStringNull(DB.tx_name,"")+" "+oCnt.getStringNull(DB.tx_surname,"")).trim());
    oPhn.store(oConn);

		if (gu_oportunity!=null) {
		  DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_oportunities+" SET "+DB.dt_last_call+"=(SELECT MAX("+DB.dt_start+") FROM "+DB.k_phone_calls+" WHERE "+DB.gu_phonecall+"='"+oPhn.getString(DB.gu_phonecall)+"') WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"'");
		  if (request.getParameter("lv_interest")!=null)
		    if (request.getParameter("lv_interest").length()>0)
		      DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_oportunities+" SET "+DB.lv_interest+"="+request.getParameter("lv_interest")+" WHERE "+DB.gu_oportunity+"='"+gu_oportunity+"'");
		}

    DBAudit.log(oConn, PhoneCall.ClassId, "NPHN", id_user, oPhn.getString(DB.gu_phonecall), request.getParameter("gu_contact"), 0, 0, null, null);
    
    oConn.commit();
    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }

  if (null==oConn) return;
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("oportunity_edit.jsp?id_domain="+id_domain+"&n_domain="+n_domain+"&gu_oportunity="+request.getParameter("gu_oportunity")+"&gu_company="+gu_company+"&gu_contact="+oCnt.getString(DB.gu_contact)));

%><%@ include file="../methods/page_epilog.jspf" %>