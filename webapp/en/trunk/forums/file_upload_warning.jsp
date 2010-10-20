<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/cookies.jspf" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

  // Obtener el idioma del navegador cliente
  String sLanguage = getNavigatorLanguage(request);

  // Obtener el skin actual
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 

  // Use the DIR parameter passed back from upload.asp to set the applet directory parameter
  // Rutas y parámetros
  // String sStorageRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"storage","");

  String sDefURLRoot = request.getRequestURI();
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));

  String sURLRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver", sDefURLRoot);

  if (sURLRoot.endsWith("/") && sURLRoot.length()>0) sURLRoot = sURLRoot.substring(0, sURLRoot.length()-1);

  String sRefreshItem = request.getParameter("refreshitem");

  String sAuth = new String("");
  if (nullif(request.getHeader("HTTP_AUTHORIZATION")).length() > 0)
    sAuth = request.getHeader("HTTP_AUTHORIZATION");
  else if (nullif(request.getHeader("AUTH_TYPE")).length() > 0)
    sAuth = "NTLM";   
%>
<html>
<head>
<script language="JavaScript" type="text/javascript" src="../javascript/cookies.js"></script>  
<script language="JavaScript" type="text/javascript" src="../javascript/setskin.js"></script>
<script language="JavaScript" type="text/javascript" >
  function continueLoad() {
    setCookie("appletFileShown","1");
    document.location='<%=request.getParameter("url")%>';
  }
</script>
<TITLE>hipergate :: Load Files</TITLE>
</head>
<body  TOPMARGIN="0" MARGINHEIGHT="0">
<table cellspacing="0" cellpadding="0" border="0" width="99%">
<tr>
<td valign="top" bgcolor="#ffffff">
<img src="<%=sURLRoot%>/skins/xp/hglogopeq.jpg" border="0">
</td>
</tr>
<tr>
<td class="striptitle">
<span class="title1">Warning</span>
</td>
</tr>
</table>  
<div class="formplain">Now a screen like this will be shown. For avoiding any more warnings in the future, select the option "Always trust in the content of..." and click Yes.</div>
<br>
<center><img src="../images/images/appletfile-warning.jpg" width="400" height="321" border="0"></center>
<br>
<center>
<input class="pushbutton" type="submit" value="Continue" onClick="continueLoad()">
</center>
</body>
</html>
<script>continueLoad()</script>
