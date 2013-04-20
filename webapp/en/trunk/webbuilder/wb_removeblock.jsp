<%@ page import="org.w3c.dom.*,com.knowgate.misc.*,java.io.File,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.dataxslt.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.db.*" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<html>
<head>
<TITLE>hipergate :: Remove</TITLE>
<SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
<SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
<SCRIPT TYPE="text/javascrip">
  <!--
    window.blur();
  //-->
</SCRIPT>
</head>
<body>
<br><br><br>
<center><span class="formstrong">Removing blocks. Please Wait...</span></center>
</body>
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
  String block_id = request.getParameter("block_id");
  String file_pageset = request.getParameter("file_pageset");
  String block_list = request.getParameter("block_list");
  
  String sDocType = request.getParameter("doctype");
  
  boolean bIsGuest = isDomainGuest (GlobalDBBind, request, response);
  
  if (!bIsGuest) {
    XMLDocument oXMLDocument = new XMLDocument(file_pageset);
  
    String[] arrayBloques = Gadgets.split(block_list, ',');
  
    for (int i=0; i<arrayBloques.length;i++)
      oXMLDocument.removeNodeAndSave("pageset/pages/page[@guid='" + gu_page + "']/blocks/block[@id='" + arrayBloques[i] + "']");
  } // fi (!bIsGuest)
%>
<script language="JavaScript" type="text/javascript">
  <!--
<% if (bIsGuest) { %>
     alert("Your credential level as Guest does not allow you to perform this action");
<% } %>
  window.open("wb_document.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&doctype=<%=sDocType%>" , "editPageSet");
  window.close();
  //-->
</script>
</html>
<%@ include file="../methods/page_epilog.jspf" %>