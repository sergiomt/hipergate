<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Meeting" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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
      
  String gu_meeting = request.getParameter("gu_meeting");
  String id_user = getCookie (request, "userid", "");
  
  JDCConnection oConn = null;  
  Meeting oMeet = new Meeting();
  boolean bIsGuest = true;
  boolean bIsAdmin = true;
  
  try {
    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);
    oConn = GlobalDBBind.getConnection("meeting_repeat_store");
    oMeet.load(oConn, new Object[]{gu_meeting});
    if (bIsGuest && !bIsAdmin)
      throw new SQLException("Your priviledge level as guest does not allow you to perform this action");
    if (!id_user.equals(oMeet.getString(DB.gu_fellow)) &&  !id_user.equals(oMeet.getStringNull(DB.gu_writer,null)))
      throw new SQLException("It is not allowed to repeat activities not created by you");
    oConn.setAutoCommit (false);
    oMeet.repeat(oConn, Integer.parseInt(request.getParameter("frecuency")), Integer.parseInt(request.getParameter("sel_times")), true);
    oConn.commit();
    oConn.close("meeting_repeat_store");
  }
  catch (SQLException e) {
    disposeConnection(oConn,"meeting_repeat_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }  
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("meeting_repeat_store");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_close"));
  }  
  if (null==oConn) return;
  oConn = null;
%><HTML><BODY onload="window.close()"></BODY></HTML>