<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.scheduler.Event" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  final String PAGE_NAME = "events_store";

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  final String id_domain = request.getParameter("id_domain");
  final String gu_workarea = request.getParameter("gu_workarea");
  final String id_user = getCookie (request, "userid", null);
  final int nEvents = Integer.parseInt(request.getParameter("nu_events"));

  DBPersist oObj = new DBPersist(DB.k_events, "Event");
  oObj.put(DB.id_domain, Integer.parseInt(id_domain));
  oObj.put(DB.gu_writer, id_user);

  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 
  
    oConn.setAutoCommit (false);
    
    for (int e=0; e<nEvents; e++) {
      String s = String.valueOf(e);
      oObj.replace(DB.id_event, request.getParameter("id_"+s).toLowerCase());
      oObj.replace(DB.bo_active, Short.parseShort(nullif(request.getParameter("chk_"+s),"0")));
      if (request.getParameter("wrk_"+s).length()>0)
        oObj.replace(DB.gu_workarea, request.getParameter("wrk_"+s));
      else
      	oObj.remove(DB.gu_workarea);
      if (request.getParameter("app_"+s).length()>0)
        oObj.replace(DB.id_app, Integer.parseInt(request.getParameter("app_"+s)));
      else
      	oObj.remove(DB.id_app);
      oObj.replace(DB.id_command, request.getParameter("cmd_"+s));
      if (request.getParameter("de_"+s).length()>0)
        oObj.replace(DB.de_event, request.getParameter("de_"+s));
      else
      	oObj.remove(DB.de_event);
      if (request.getParameter("rt_"+s).equals("0"))
        oObj.remove(DB.fixed_rate);
      else
        oObj.replace(DB.fixed_rate, new Integer(request.getParameter("rt_"+s)));
      oObj.store(oConn);
      oConn.commit();
    } // next

    if (request.getParameter("id").length()>0) {
      oObj.replace(DB.bo_active, nullif(request.getParameter("chk"),"0"));
      oObj.replace(DB.id_event, request.getParameter("id").toLowerCase());
      if (request.getParameter("wrk").length()>0)
        oObj.replace(DB.gu_workarea, request.getParameter("wrk"));
      else
      	oObj.remove(DB.gu_workarea);
      if (request.getParameter("app").length()>0)
        oObj.replace(DB.id_app, Integer.parseInt(request.getParameter("app")));
      else
      	oObj.remove(DB.id_app);
      oObj.replace(DB.id_command, request.getParameter("cmd"));
      if (request.getParameter("de").length()>0)
        oObj.replace(DB.de_event, request.getParameter("de"));
      else
        oObj.remove(DB.de_event);      
      if (request.getParameter("rt").equals("0"))
        oObj.remove(DB.fixed_rate);
      else
        oObj.replace(DB.fixed_rate, new Integer(request.getParameter("rt")));
      oObj.store(oConn);
      oConn.commit();
	}

    oConn.close(PAGE_NAME);

		Event.reset();
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;
  
  response.sendRedirect (response.encodeRedirectUrl ("events.jsp"));

%><%@ include file="../methods/page_epilog.jspf" %>