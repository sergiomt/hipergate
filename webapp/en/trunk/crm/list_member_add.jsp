<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.crm.ListMember" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
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

  final String PAGE_NAME = "list_member_add";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = getCookie(request,"workarea","");
  String id_user = getCookie (request, "userid", null);
  
  ListMember oMbr = new ListMember();
	oMbr.put(DB.bo_active, (short)1);
	oMbr.put(DB.tp_member, (short)96);
	oMbr.put(DB.id_format, "TXT");
	oMbr.put(DB.gu_list, request.getParameter("gu_list"));
	oMbr.put(DB.de_list, request.getParameter("de_list"));
	oMbr.put(DB.tx_email, request.getParameter("tx_email"));
	if (request.getParameter("tx_name").length()>0) oMbr.put(DB.tx_name, request.getParameter("tx_name"));
	if (request.getParameter("tx_surname").length()>0) oMbr.put(DB.tx_surname, request.getParameter("tx_surname"));

  JDCConnection oConn = null;
    
  try {
		
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

		if (DBCommand.queryExists(oConn, DB.k_x_list_members, DB.gu_list+"='"+request.getParameter("gu_list")+"' AND "+DB.tx_email+"='"+request.getParameter("tx_email")+"'")) {
		  throw new SQLException(oMbr.getString(DB.tx_email)+" The email address is already on the list");
		}

    oConn.setAutoCommit (false);

    oMbr.store(oConn, request.getParameter("gu_list"));

    DBAudit.log(oConn, ListMember.ClassId, "AMBR", id_user, oMbr.getString(DB.gu_list), null, 0, 0, oMbr.getString(DB.tx_email), null);
    
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
  
  if (null==oConn) return;
  oConn = null;
  
  response.sendRedirect (response.encodeRedirectUrl ("member_listing.jsp?gu_list="+request.getParameter("gu_list")+"&de_list="+Gadgets.URLEncode(request.getParameter("de_list"))));

%><%@ include file="../methods/page_epilog.jspf" %>