<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Meeting" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  Form for editing a DBPersist subclass object.
  
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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
    oConn = GlobalDBBind.getConnection("meeting_repeat");
    oMeet.load(oConn, new Object[]{gu_meeting});        
    oConn.close("meeting_repeat");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("meeting_repeat");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }  
  if (null==oConn) return;    
  oConn = null;
  if (bIsGuest && !bIsAdmin) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=Your priviledge level as guest does not allow you to perform this action&resume=_close"));
    return;
  }
  if (!id_user.equals(oMeet.getString(DB.gu_fellow)) &&  !id_user.equals(oMeet.getStringNull(DB.gu_writer,null))) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=It is not allowed to repeat activities not created by you&resume=_close"));
    return;
  }
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Repeat Activity</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
</HEAD>
<BODY  TOPMARGIN="16" MARGINHEIGHT="16">
  <FORM METHOD="post" ACTION="meeting_repeat_store.jsp">
  <INPUT TYPE="hidden" NAME="gu_meeting" VALUE="<%=gu_meeting%>">
  <FONT CLASS="textplain"><BIG>Repeat&nbsp;<%=oMeet.getStringNull(DB.tx_meeting,"")%></BIG></FONT>
  <BR><BR>
  <FONT CLASS="textplain"><B>Frecuency</B></FONT>
  &nbsp;&nbsp;
  <INPUT TYPE="radio" NAME="frecuency" VALUE="1" onclick="document.getElementById('times_tag').innerHTML='<FONT CLASS=textplain>days</FONT>';">&nbsp;<FONT CLASS="textplain">Each working day</FONT>
  &nbsp;&nbsp;&nbsp;
  <INPUT TYPE="radio" NAME="frecuency" VALUE="7" onclick="document.getElementById('times_tag').innerHTML='<FONT CLASS=textplain>weeks</FONT>';" CHECKED>&nbsp;<FONT CLASS="textplain">Weekly</FONT>
  &nbsp;&nbsp;&nbsp;
  <INPUT TYPE="radio" NAME="frecuency" VALUE="28" onclick="document.getElementById('times_tag').innerHTML='<FONT CLASS=textplain>months</FONT>';">&nbsp;<FONT CLASS="textplain">Monthly</FONT>
  <BR><BR>
  <TABLE BORDER="0">
    <TR><TD><FONT CLASS="textplain"><B>During</B></FONT></TD><TD><SELECT NAME="sel_times"><% for (int t=1;t<=30; t++) out.write("<OPTION VALUE=\""+String.valueOf(t)+"\">"+String.valueOf(t)+"</OPTION>"); %></SELECT></TD><TD><DIV ID="times_tag"><FONT CLASS=textplain>weeks</FONT></DIV></TR></TABLE>
  <BR><BR>
  <CENTER>
  <INPUT TYPE="submit" ACCESSKEY="r" VALUE="Repeat" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+r">&nbsp;
  &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">  
  </FORM>
</BODY>
</HTML>