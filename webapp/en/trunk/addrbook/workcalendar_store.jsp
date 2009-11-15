<%@ page import="java.util.GregorianCalendar,java.util.TreeSet,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.WorkingCalendar" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2007  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
        
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");
  
  JDCConnection oConn = null;
  
  TreeSet oHolidays = new TreeSet();
  if (request.getParameter("weekday_"+String.valueOf(GregorianCalendar.MONDAY))!=null)
    oHolidays.add(new Integer(GregorianCalendar.MONDAY));
  if (request.getParameter("weekday_"+String.valueOf(GregorianCalendar.TUESDAY))!=null)
    oHolidays.add(new Integer(GregorianCalendar.TUESDAY));
  if (request.getParameter("weekday_"+String.valueOf(GregorianCalendar.WEDNESDAY))!=null)
    oHolidays.add(new Integer(GregorianCalendar.WEDNESDAY));
  if (request.getParameter("weekday_"+String.valueOf(GregorianCalendar.THURSDAY))!=null)
    oHolidays.add(new Integer(GregorianCalendar.THURSDAY));
  if (request.getParameter("weekday_"+String.valueOf(GregorianCalendar.FRIDAY))!=null)
    oHolidays.add(new Integer(GregorianCalendar.FRIDAY));
  if (request.getParameter("weekday_"+String.valueOf(GregorianCalendar.SATURDAY))!=null)
    oHolidays.add(new Integer(GregorianCalendar.SATURDAY));
  if (request.getParameter("weekday_"+String.valueOf(GregorianCalendar.SUNDAY))!=null)
    oHolidays.add(new Integer(GregorianCalendar.SUNDAY));
  
  try {
    oConn = GlobalDBBind.getConnection("workcalendar_store"); 
  
    oConn.setAutoCommit (false);

    WorkingCalendar.create(oConn, id_domain, gu_workarea, request.getParameter("nm_calendar"),
		           oFmt.parse(request.getParameter("dt_from")),
		           oFmt.parse(request.getParameter("dt_to")),
		           decode(request.getParameter("gu_acl_group"),"",null),
		           decode(request.getParameter("gu_user"),"",null),
                           decode(request.getParameter("id_country"),"",null),
                           decode(request.getParameter("id_state"),"",null),
                           null,
  			   Short.parseShort(request.getParameter("hh_start1")), Short.parseShort(request.getParameter("mi_start1")),
  			   Short.parseShort(request.getParameter("hh_end1")), Short.parseShort(request.getParameter("mi_end1")),
  			   Short.parseShort(request.getParameter("hh_start2")), Short.parseShort(request.getParameter("mi_start2")),
  			   Short.parseShort(request.getParameter("hh_end2")), Short.parseShort(request.getParameter("mi_end2")),
  			   oHolidays);

    oConn.commit();
    oConn.close("workcalendar_store");
  }
  catch (Exception e) {  
    disposeConnection(oConn,"workcalendar_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;

  // Refresh parent and close window, or put your own code here
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
%>