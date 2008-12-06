<%@ page import="java.util.Set,java.util.Iterator,java.io.IOException,java.net.URLDecoder,com.knowgate.cache.DistributedCachePeer,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<% 
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
  
  if (request.getParameter("expireall")!=null) {
    GlobalCacheClient.expireAll();
    com.knowgate.misc.Environment.refresh();
  }
  
  String sSkin = "xp";
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Local Cache Inspector</TITLE>
  <LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css">
</HEAD>

<BODY >
<%@ include file="../common/header.jspf" %>
<FONT FACE="Arial,Helvetica,sans-serif">
Cached Entries: <% out.write(String.valueOf(GlobalCacheClient.size())); %>
</FONT>
<BR><BR>
<TABLE>
<%
  String sKey;
  Iterator oIter = GlobalCacheClient.keySet().iterator();
  while (oIter.hasNext()) {
    sKey = (String) oIter.next();
    out.write ("  <TR><TD><TT>" + sKey + "</TT></TD><TD><A HREF=\"cacheentry.jsp?key=" + Gadgets.URLEncode(sKey) + "\" TARGET=\"_blank\">View Entry</A></TD></TR>\n");
  } // wend
%>
</TABLE>
<BR><BR>
<FORM METHOD="get" ACTION="cache.jsp"><INPUT TYPE="hidden" NAME="expireall" VALUE="1"><INPUT CLASS="pushbutton" TYPE="submit" VALUE="Empty Cache"></FORM>
</BODY>
</HTML>
