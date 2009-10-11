<%@ page import="java.text.SimpleDateFormat,java.util.Date,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBSubset,com.knowgate.addrbook.Meeting,com.knowgate.misc.Gadgets,com.knowgate.hipergate.DBLanguages" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="inc/dbbind.jsp" %><%
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

  final String PAGE_NAME = "meetings_day";

  final String ye = request.getParameter("y");
  final String mo = request.getParameter("m");
  final String dt = request.getParameter("d");

  SimpleDateFormat oFmt = new SimpleDateFormat(sLanguage.startsWith("es") ? "dd MMM" : "MMM dd");
  
  Date dtToday = new Date(Integer.parseInt(ye), Integer.parseInt(mo), Integer.parseInt(dt));
  Timestamp ts00 = new Timestamp(new Date(Integer.parseInt(ye), Integer.parseInt(mo), Integer.parseInt(dt), 0, 0, 0).getTime());
  Timestamp ts24 = new Timestamp(new Date(Integer.parseInt(ye), Integer.parseInt(mo), Integer.parseInt(dt), 23, 59, 59).getTime());
  StringBuffer oMeetings = new StringBuffer();
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;

  final SimpleDateFormat oFmtHour = new SimpleDateFormat("HH:mm");

  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

    oStmt = oConn.prepareStatement("SELECT m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ", m." + DB.dt_start + ",m." + DB.dt_end + " FROM " +
                                  DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f WHERE " +
                                  "m." + DB.gu_meeting + "=f." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN ? AND ? ORDER BY m." + DB.dt_start,
                                  ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString (1, oUser.getString(DB.gu_user));
    oStmt.setTimestamp (2, ts00);
    oStmt.setTimestamp (3, ts24);
    oRSet = oStmt.executeQuery();
    while (oRSet.next()) {
      oMeetings.append("<br/>&nbsp;<a href=\"meeting_edit.jsp?gu_meeting="+oRSet.getString(1)+"\">"+oFmtHour.format(oRSet.getTimestamp(5))+"&nbsp;-&nbsp;"+oFmtHour.format(oRSet.getTimestamp(6))+"</a>&nbsp;"+oRSet.getString(4));
    } // wend
		oRSet.close();
		oStmt.close();

		oConn.close(PAGE_NAME);
    
  } catch (Exception xcpt) {
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+xcpt.getClass().getName()+"&desc=" + xcpt.getMessage() + "&resume=home.jsp"));    
    return;
  }
  
%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <head><meta http-equiv="cache-control" content="no-cache"/></head>
  <card id="meetings_day">
<%  out.write(oFmt.format(dtToday)+"<br/>"+oMeetings.toString()); %>
    <p><a href="home.jsp"><%=Labels.getString("a_home")%></a> <do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
  </card>
</wml>
