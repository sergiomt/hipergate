<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../../../../methods/page_prolog.jspf" %><%@ include file="../../../../methods/nullif.jspf" %><%@ include file="../../../../methods/cookies.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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
  
  // Rutas y parámetros
  String sRefreshItem = request.getParameter("refreshitem");
  
  String sAuth = new String("");
  
  if (nullif(request.getHeader("HTTP_AUTHORIZATION")).length() > 0)
    sAuth = request.getHeader("HTTP_AUTHORIZATION");
  else if (nullif(request.getHeader("AUTH_TYPE")).length() > 0)
    sAuth = "NTLM";

  String sTitle = request.getParameter("title");
%>
<html>
<head>
  <TITLE>hipergate :: [~Cargar Im&aacute;genes~]</TITLE>
  <style type="text/css">
      .sBox {
        width:300px;
        font-family:Tahoma,Verdana,Arial,Helvetica,sans-serif;
        font-size:8pt;
        color:#000080;
        background-color:#FFFFFF;
      }
      .cmdDiv {
        background-color:steelblue;
        padding-left:3px;
        padding-right:3px;
        padding-top:1px;
        padding-bottom:1px;
        border-top:1px solid #000080;
        border-left:1px solid #000080;
        border-bottom:1px solid #000040;
        border-right:1px solid #000040;
      }
      .actLink {
        font-family:Tahoma,Verdana,Arial,Helvetica,sans-serif;
        font-size:7.5pt;
        color:#FFFFFF;
        text-decoration:none;
      }
  </style>
  <script language="JavaScript" src="../../../../javascript/cookies.js"></script>  
  <script language="JavaScript" type="text/javascript">
  <!--
      var sSkinCookieValue = getCookie("skin");
    
      if (sSkinCookieValue!=null && sSkinCookieValue!='undefined' && sSkinCookieValue!="")
        document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../../../../skins/' + getCookie("skin") + '/styles.css">');
      else
        document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../../../../skins/xp/styles.css">');

      if(getCookie("appletFileShown")=="") {
        document.location="../../../../webbuilder/wb_file_upload_warning.jsp?url="+escape(document.location.href);
      }

      // ------------------------------------------------------
      
      function fu_add() {
        document.FileUpload.selectAdd();
      }

      // ------------------------------------------------------

      function fu_clearCombo() {
        var c = document.forms[0].f_list.length;
        for (var i=c;i>=0;i--) {
          document.forms[0].f_list.options[i] = null;
        }
      }

      // ------------------------------------------------------

      function fu_sync() {
        
        fu_clearCombo();
        
        var c = document.FileUpload.getFileCount();
        
        for (var i=1;i<=c;i++) {
          var n = document.FileUpload.getFile(i);
          var s = Math.round(document.FileUpload.getFileSize(i)/1024);
          document.forms[0].f_list.options[i-1] = new Option(n + " ("+s+" k)");
        }
      }
      
      // ------------------------------------------------------
      
      function fu_rem() {
        
        var c = document.forms[0].f_list.length;
        
        for (var i=(c-1);i>=0;i--) {
        
          if (document.forms[0].f_list.options[i].selected) {
            document.FileUpload.removeFile(i+1);
          }
        }
        fu_sync();
      }

      // ------------------------------------------------------
      
      function fu_remAll() {
        var c = document.forms[0].f_list.length;
        
        for (var i=(c-1);i>=0;i--) {
          document.FileUpload.removeFile(i+1);
        }
        
        fu_sync();
      }

      // ------------------------------------------------------

      function fu_poll() {
        if (document.FileUpload.hasInitialized()) {
          if (document.FileUpload.hasChanged()) {
            fu_sync();
          }
        }
        window.setTimeout('fu_poll()', 200);
      }

      // --------------------------------------------------------
    
      function processUpload(form) {
        var applet = document.FileUpload;
        
        applet.addElement('TEXTAREA1',form.elements['TEXTAREA1'].value); 
        
        applet.upload(form.action,navigator.userAgent,document.cookie); 
        
        waitForCompletion(); 
        
        return false;
      }
    
      // --------------------------------------------------------
    
      function waitForCompletion() {
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
  //-->
  </script>
</head>
<body  TOPMARGIN="0" MARGINHEIGHT="0" onLoad="fu_poll()">
<% if (request.getParameter("caller")!=null) { %>
    <TABLE width="100%"BORDER="0" CELLSPACING="0" CELLPADDING="2">
      <TR width="100%" VALIGN="middle"><TD align="left" CLASS="striptitle"><FONT CLASS="title1">[~Creaci&oacute;n de ~]<%=sTitle%></FONT></TD><TD ALIGN="right" CLASS="striptitle"><FONT CLASS="title1">[~Paso 2 de 2~]</font></TD></TR>
      <TR><TD colspan="2" class="formplain"><p ALIGN="justify">[~Esta pantalla le permite subir imagenes al servidor. Para seleccionarlas pulse sobre Añadir. Cuando no quiera subir más pulse Terminar. Si no desea cargar imagenes en el servidor pulse directamente Terminar.~]</p></TD></TR>
    </TABLE>
<% }
   else 
   { 
%>
<br>
<table cellspacing="0" cellpadding="0" border="0" width="99%">
<tr>
<td class="striptitle">
<span class="title1">[~Cargar Im&aacute;genes en el Servidor~]</span>
</td>
</tr>
</table>  
<% } %>
<!-- The form tag must contain correct action and onsubmit attributes -->
<form action="image_upload_store.jsp" name="form1" id="form1" onsubmit="return processUpload(this)">
  <SELECT name="f_list" class="sBox" size="8" multiple="multiple"></SELECT>
  <BR>
  <SPAN class="cmdDiv"><A class="actLink" href="javascript:;" onClick="fu_add()">[~Añadir~]</A></SPAN>
  <SPAN class="cmdDiv"><A class="actLink" href="javascript:;" onClick="fu_rem()">[~Quitar~]</A></SPAN>
  <SPAN class="cmdDiv"><A class="actLink" href="javascript:;" onClick="fu_remAll()">[~Borrar Todos~]</A></SPAN>
<p>
<span class="strip1">[~Comentarios:~]</span>
<br>
<textarea name="TEXTAREA1" rows="4" cols="50"></textarea>
<br>
<br>
<center>
<input class="pushbutton" type="submit" value="[~Terminar~]">
</center>
</p>
</form>
<form method="post" action="image_upload_results.jsp" name="results" id="results">
<input type="hidden" name="response">
</form>

<applet code="com/infomentum/appletfile/FileUpload.class" archive="../../../../applets/FileUpload.jar" codebase="../../../../applets" width="1" height="1" name="FileUpload" MAYSCRIPT VIEWASTEXT id="Applet1">
  <PARAM name="bgColor"	  	  value="#FF0000">
  <PARAM name="browseTitle"	  value="[~Seleccione sus archivos~]">
  <PARAM name="cabbase" 	  value="../applets/FileUpload.cab">
  <PARAM name="fileMask"          value="*.gif,*.png,*.jpg,*.jpeg">
  <PARAM name="errorLimit"	  value="0">
  <PARAM name="maxFiles" 	  value="100">
  <PARAM name="noAdd"	  	  value="true">
  <PARAM name="noFileList" 	  value="true">
  <PARAM name="noConfirm"	  value="true">
  <PARAM name="noProgress" 	  value="true">
  <PARAM name="noRemove"	  value="true">
  <PARAM name="selectFolders" 	  value="false">
  <PARAM name="authorization"     value="<%=sAuth%>">
  <PARAM name="language" 	  value="<%=sLanguage%>">
</applet>
</body>
</html>
<%@ include file="../../../../methods/page_epilog.jspf" %>