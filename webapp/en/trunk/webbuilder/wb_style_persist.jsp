<%@ page import="org.w3c.dom.*,com.knowgate.misc.*,java.io.File,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.db.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
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
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);  
  String id_domain = getCookie(request,"domainid","");
  String n_domain = request.getParameter("n_domain");
  
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = request.getParameter("gu_pageset");
  String gu_page = request.getParameter("gu_page");
  
  String sFileTemplate = request.getParameter("file_template");
  String sFilePageSet = request.getParameter("file_pageset");
  String doctype =request.getParameter("doctype");
  
  XMLDocument oXMLDocument = new XMLDocument(sFilePageSet);

  oXMLDocument.addNode("pageset/font","<font>" + request.getParameter("font") + "</font>");
  oXMLDocument.addNode("pageset/color","<color>" + request.getParameter("color") + "</color>");
  oXMLDocument.removeNodeAndSave("pageset/font");
  oXMLDocument.removeNodeAndSave("pageset/color");
%>
<HTML>
  <HEAD>
  <TITLE>Wait...</TITLE>
<script language="JavaScript" type="text/javascript">
  self.opener.document.location="wb_document.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&doctype=<%=doctype%>";
  self.close();
</script>
  </HEAD>
  <BODY></BODY>
</HTML>