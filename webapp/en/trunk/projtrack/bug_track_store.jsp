<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.projtrack.BugTrack,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "bug_track_store";

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);
  
  String gu_bug = request.getParameter("gu_bug");
  Integer pg_bug = new Integer(request.getParameter("pg_bug"));

  BugTrack oObj = new BugTrack();

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

    ACLUser oMe = new ACLUser(oConn, id_user);

    oObj.put(DB.gu_writer, id_user);
    oObj.put(DB.gu_bug, gu_bug);
    oObj.put(DB.pg_bug, pg_bug);
    oObj.put(DB.nm_reporter, (oMe.getStringNull(DB.nm_user,"")+" "+oMe.getStringNull(DB.tx_surname1,"")+" "+oMe.getStringNull(DB.tx_surname2,"")).trim());
    oObj.put(DB.tx_rep_mail, oMe.getStringNull(DB.tx_main_email,""));
    oObj.put(DB.tx_bug_track, Gadgets.left(request.getParameter("tx_bug_track"), 2000));

    oConn.setAutoCommit (false);
    
    oObj.store(oConn);
    
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

  out.write("1.0:OK");

%><%@ include file="../methods/page_epilog.jspf" %>