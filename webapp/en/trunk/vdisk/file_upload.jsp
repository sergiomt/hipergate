<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/cookies.jspf" %><%
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

  // Obtener el idioma del navegador cliente
  String sLanguage = getNavigatorLanguage(request);
  // Obtener el skin actual
  String sSkin = getCookie(request, "skin", "default");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 

  // Use the DIR parameter passed back from upload.asp to set the applet directory parameter
  String sDir = nullif(request.getParameter("dir"));

  String sAuth = new String("");
  if (nullif(request.getHeader("HTTP_AUTHORIZATION")).length() > 0)
    sAuth = request.getHeader("HTTP_AUTHORIZATION");
  else if (nullif(request.getHeader("AUTH_TYPE")).length() > 0)
    sAuth = "NTLM";   
%>
<html>
<head>
<title>hipergate :: Load Images</title>
<script type="text/javascript" src="../javascript/cookies.js"></script>  
<script type="text/javascript" src="../javascript/setskin.js"></script>
<script type="text/javascript">
  <!--
    function processUpload(form)
    {
       var applet = document.FileUpload;
       applet.addElement('TEXTAREA1',form.elements['TEXTAREA1'].value); 
       applet.upload(form.action,navigator.userAgent,document.cookie); 
       waitForCompletion(); 
       return false;
    }
    
    // --------------------------------------------------------
    
    function waitForCompletion()
    {
       var applet = document.FileUpload;
       var progress = applet.getUploadProgress();   
       if (progress == 100) {
              var form = document.forms['results'];
              form.elements['response'].value = applet.getUploadResponse();
    	  form.submit();
       }
       else if (progress >= 0)
          window.setTimeout('waitForCompletion()',1000);       
    }
  
  // -->
</script>
</head>
<body >
<%@ include file="../common/tabmenu.jspf" %>
<table><tr><td width="<%=iTabWidth*iActive%>" class="striptitle"><font class="title1">Upload images to server</font></td></tr></table>  
<br>
<!-- The Upload Applet is positioned where we want the file list to display -->
<applet code="com/infomentum/appletfile/FileUpload.class" archive="../applets/FileUpload.jar" codebase="../applets" width="420" height="128" name="FileUpload" MAYSCRIPT VIEWASTEXT id="Applet1">
<param name="cabbase" value="../applets/FileUpload.cab">
<param name="alternateUrl" value="alt.jsp">
<param name="filter1" value="All files (*.*)">
<param name="filter2" value="Images (*.jpg,*.jpeg,*.gif)">
<param name="bgColor" value="#FFE78F">
<param name="language" value="<%=sLanguage%>">
<param name="authorization" value="<%=sAuth%>">

<!-- Pass authentication info to the applet -->
<% if (nullif(request.getHeader("HTTP_AUTHORIZATION")).length() > 0) { %>
<param name="authorization" value="<%=request.getHeader("HTTP_AUTHORIZATION")%>">
<% } else if (nullif(request.getHeader("AUTH_TYPE")).length() > 0) { %>
<param name="authorization" value="NTLM">
<% } %>

<!-- Set the applet background to match the page background -->
<param name="bgColor" value="white">

<!-- Set the directory to the last directory browsed -->
<param name="directory" value="<%=sDir%>"></applet>
</p>

<!-- The form tag must contain correct action and onsubmit attributes -->
<form action="file_upload_store.jsp" name="form1" id="form1" onsubmit="return processUpload(this)">
    <!-- Here is a regular form element for non-file data -->
    <p><font face="textplain">Comentarios:<br></font>
    <textarea name="TEXTAREA1" rows="3" cols="48"></textarea><br>
    <br>
    <input type="submit" value="Submit"> </p>
</form>

<form method="post" action="file_upload_results.jsp" name="results" id="results">
<input type="hidden" name="response">
</form>
</td></tr>
</table>
</body>
</html>
