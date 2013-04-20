<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.util.*,java.lang.*,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf"  %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/nullif.jspf"   %>
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

  // Obtener el idioma del navegador cliente
  String sLanguage = getNavigatorLanguage(request);

  // Obtener el skin actual
  String sSkin = getCookie(request, "skin", "default");

  String sDefURLRoot = request.getRequestURI();
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));

  String sURLRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver", sDefURLRoot);

  if (sURLRoot.endsWith("/") && sURLRoot.length()>0) sURLRoot = sURLRoot.substring(0, sURLRoot.length()-1);

  // Parámetros
  String sFilePageSet = request.getParameter("file_pageset");
  String sFileTemplate = request.getParameter("file_template");
  String sItemId = request.getParameter("itemid");
  
  PageSet oPageSet = new PageSet(sFileTemplate,sFilePageSet);
%>
<html>
<head>
<TITLE>hipergate :: Link to page</TITLE>
<SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
<SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
<SCRIPT LANGUAGE="JavaScript">
function setOpenerItem(value){window.opener.setItem('<%=sItemId%>',value);window.close();};
</SCRIPT>
</head>
<body  TOPMARGIN="0" MARGINHEIGHT="0">
<table cellspacing="0" cellpadding="0" border="0" width="99%"><tr><td valign="top" align="center" width="100%" >&nbsp;<img src="<%=sURLRoot%>/skins/xp/hglogopeq.jpg" border="0"></td></tr><tr><td valign="center" align="center"  width="100%"><span class="title1">&nbsp;Link to page</span></td></tr>
<tr><td>&nbsp;</td></tr>
<tr><td class="formplain">Select a website page as a target forcurrent link.</td></tr>
<tr><td>&nbsp;</td></tr>
<%
  java.util.Vector vPages = oPageSet.pages();
  for (int i=0; i<vPages.size(); i++)
  {
%>
<tr><td><img align="middle" src="../images/images/crm/note32.gif" border="0" height="16" width="16">&nbsp;<a class="formplain" style="color:#0066cc;text-decoration:none" href="#" onclick=setOpenerItem('javascript:callPage("<%=Gadgets.replace(((Page)(vPages.get(i))).getTitle()," ","_")%>");')><%=((Page)(vPages.get(i))).getTitle()%></a></td></tr>
<%
  }
%>
</table>
</body>
</html>
