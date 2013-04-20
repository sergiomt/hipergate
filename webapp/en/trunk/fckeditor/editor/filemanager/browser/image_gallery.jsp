<%@ page import="com.knowgate.debug.DebugFile,com.knowgate.misc.*,java.io.*,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.workareas.FileSystemWorkArea" language="java" session="false" contentType="text/html;charset=UTF-8"  %>
<%@ include file="../../../../methods/page_prolog.jspf" %><%@ include file="../../../../methods/dbbind.jsp" %><%@ include file="../../../../methods/cookies.jspf" %><%@ include file="../../../../methods/authusrs.jspf" %><%@ include file="../../../../methods/nullif.jspf" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "default");
  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "none");
  String gu_workarea = getCookie(request,"workarea","");
  String id_user = getCookie(request,"userid","");

  String sSep = java.io.File.separator;

  // Rutas y parámetros  

  String sWebServer = request.getRequestURL().substring(0, request.getRequestURL().length()-request.getServletPath().length());

  String sDefaultWorkAreasGet = request.getRequestURI();
  sDefaultWorkAreasGet = sDefaultWorkAreasGet.substring(0,sDefaultWorkAreasGet.lastIndexOf("/"));
  sDefaultWorkAreasGet = sDefaultWorkAreasGet.substring(0,sDefaultWorkAreasGet.lastIndexOf("/"));
  sDefaultWorkAreasGet = sDefaultWorkAreasGet + "/workareas";

  String sDefaultWorkAreasPut = request.getRealPath(request.getServletPath());
  sDefaultWorkAreasPut = sDefaultWorkAreasPut.substring(0,sDefaultWorkAreasPut.lastIndexOf(sSep));
  sDefaultWorkAreasPut = sDefaultWorkAreasPut.substring(0,sDefaultWorkAreasPut.lastIndexOf(sSep));
  sDefaultWorkAreasPut = sDefaultWorkAreasPut + sSep + "workareas";

  String sWorkareasPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefaultWorkAreasPut);
  String sWorkareasGet = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasget", sDefaultWorkAreasGet);
  
  String sApp = "Hipermail";
       
  String sImagesDir = sWorkareasPut + sSep + gu_workarea + sSep + "apps" + sSep + sApp + sSep + id_user + sSep + "images";
  String sImagesUrl = sWorkareasGet + "/" + gu_workarea + "/" + "apps" + "/" + sApp + "/" + id_user + "/" + "images";
  
  // Crear el directorio de thumbnails por usuario si no existe
  
  FileSystemWorkArea oFileSys = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));
  oFileSys.mkdirs("file://" + sWorkareasPut + sSep + gu_workarea + sSep + "apps" + sSep + sApp + sSep + id_user + sSep + "images" + sSep + "thumbs");
  oFileSys = null;
    
  File oDirectory = new File(sImagesDir);
  File[] aFiles = oDirectory.listFiles();
  String sFileName;
      
%>
<html lang="<%=sLanguage%>">
<head>
  <SCRIPT SRC="../../../../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../../../../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../../../../javascript/usrlang.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript">
    <!--

      var sSkinCookieValue = getCookie("skin");
    
      if (sSkinCookieValue!=null && sSkinCookieValue!='undefined' && sSkinCookieValue!="")
        document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../../../../skins/' + getCookie("skin") + '/styles.css">');
      else
        document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../../../../skins/xp/styles.css">');

      function uploadImage() { 
        window.open('../upload/image_upload.jsp','hUploadImage','top=' + (screen.height-360)/2 + ',left=' + (screen.width-450)/2 + ',height=360,width=450');
      }

      // ------------------------------------------------------
      
      function openPicture(pictureName) { 
      	var w2 = window.open("about:blank", null, "directories=no,toolbar=no,menubar=no,theatermode,resizable=false,width=1,height=1,top=" + screen.height/2 + ",left=" + screen.width/2); 
      	w2.blur();
      	window.focus();
      	w2.document.write("<html>"); w2.document.write("\n");
      	w2.document.write("<head>"); w2.document.write("\n");
      	w2.document.write("<title>"); w2.document.write("\n");
      	w2.document.write("[~Ver imagen ~](" + pictureName + ")"); w2.document.write("\n");
      	w2.document.write("</title>"); w2.document.write("\n");
      	w2.document.write("</head>"); w2.document.write("\n");
      	w2.document.write("<body topmargin=0 marginheight=0 leftmargin=0>"); w2.document.write("\n");
      	w2.document.write("<center>"); w2.document.write("\n");
      	w2.document.write("<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>"); w2.document.write("\n");
      	w2.document.write("<tr>"); w2.document.write("\n");
      	w2.document.write("<td align=middle valign=middle>"); w2.document.write("\n");
      	w2.document.write("<img name='laimagen' border='0' align='middle' src='<%=sImagesUrl%>/" + pictureName+ "'>"); w2.document.write("\n");
      	w2.document.write("</td>"); w2.document.write("\n");
      	w2.document.write("</tr>"); w2.document.write("\n");
      	w2.document.write("</table>"); w2.document.write("\n");
      	w2.document.write("</body>"); w2.document.write("\n");
      	w2.document.write("<script>"); w2.document.write("\n");
      	w2.document.write("window.resizeTo(laimagen.width+10,laimagen.height+20);"); w2.document.write("\n");
      	w2.document.write("window.moveTo(parseInt((screen.width-laimagen.width-10)/2),parseInt((screen.height-laimagen.height-20)/2));"); w2.document.write("\n");
      	w2.document.write("a=0;"); w2.document.write("\n");
      	w2.document.write("<"+"/"+"script"+"");
      	w2.document.write("\n");
      	w2.document.write("<"+"/"+"html"+">");
      	w2.document.write("\n");
      	w2.focus();
      }    

      // ------------------------------------------------------
      
      function paintThumbs() {
        // Recorrer los thumbnails y cambiar el icono generico por la mini-imagen buena correspondiente

        var imgc = document.images.length;
        var img;        
        
        for (var i=0; i<imgc; i++) {
          img = document.images[i];
          // Identificar los thumbnails entre las demas imagenes por su tamaño cuadrado de 80x80 pixels
          if (img.width==80 && img.height==80)
            img.src = "../../../../webbuilder/wb_thumbnail.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&nm_app=Hipermail&gu_writer="+getCookie("userid")+"&nm_image=" + escape(img.name);
        } // next (i)
      }

      // ------------------------------------------------------
      
      function deleteImages()
      {
          var lista = '';
          var contador = 0;
          for (var i=0; i<document.forms[0].elements.length; i++)
            if (document.forms[0].elements[i].type=='checkbox')
              if (document.forms[0].elements[i].checked)
              {
                if (contador==0) 
          	  lista = lista + '<%=sImagesDir%>/' + document.forms[0].elements[i].value;
          	else
          	  lista = lista + ',' + '<%=sImagesDir%>/' + document.forms[0].elements[i].value;
          	contador++;
              }
              
           if (contador==0)
             alert("[~Debe seleccionar al menos una imagen~]");
           else {
             document.forms[0].checkeditems.value = lista;
             document.forms[0].submit();
           }
      }       

      // ------------------------------------------------------
      
      function selectAll()
      {
        var frm = document.forms[0];
        var cnt = frm.elements.length;
        
        for (var i=0; i<cnt; i++) {
          if (frm.elements[i].type=="checkbox") {
            frm.elements[i].checked = !frm.elements[i].checked;
          }
        } // next
      } // selectAll
      
    //-->    
  </SCRIPT> 
  <TITLE>hipergate :: [~Imágenes disponibles~]</TITLE>
</head>
<body  onLoad="paintThumbs()">
<form name="frmDeleteImages" id="frmDeleteImages" method="post" action="../../../../webbuilder/images_delete.jsp">
<input type="hidden" name="checkeditems">
<br>
<table cellspacing="0" cellpadding="0" border="0" width="99%"><tr><td colspan="2" valign="center" class="striptitle"><font class="title1">[~Im&aacute;genes disponibles~]</font></td></tr></table>
<TABLE CELLSPACING="2" CELLPADDING="2">
<TR>
<TR><TD COLSPAN="6" BACKGROUND="../../../../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../../../../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Nueva imagen~]"></TD>
<TD ALIGN="LEFT" VALIGN="middle"><A HREF="#" onclick="uploadImage()" CLASS="linkplain">[~Nueva imagen~]</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../../../../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Eliminar imágenes~]"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><A HREF="javascript:if (window.confirm('[~Cuando elimina imagenes, estas dejaran de aparecer en los mensajes que las utilicen. ¿Esta seguro?~]')) deleteImages()" CLASS="linkplain">[~Eliminar imágenes~]</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../../../../images/images/selall16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="[~Seleccionar todas~]"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><A HREF="#" onclick="selectAll()" CLASS="linkplain">[~Seleccionar todas~]</A></TD>
<TR><TD COLSPAN="6" BACKGROUND="../../../../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
</TR>
</TABLE>
<table cellspacing="0" cellpadding="2" border="0" width="99%">
<tr>
<%
  int contador = 0;
  
  for (int i=0; i<aFiles.length; i++) {
    sFileName = aFiles[i].getName().toLowerCase();
    if (sFileName.endsWith(".jpeg") || sFileName.endsWith(".jpg") || sFileName.endsWith(".gif") || sFileName.endsWith(".png"))
      {
%>
<td align="center" valign="middle" width="25%">
<table id="table<% out.write(String.valueOf(i)); %>" cellspacing="0" cellpadding="0" border="0" width="100%" style="border:1px solid #000000" onmouseover="document.getElementById('table<% out.write(String.valueOf(i)); %>').style.border='1px solid #ffd700';" onmouseout="document.getElementById('table<% out.write(String.valueOf(i)); %>').style.border='1px solid #000000';">
  <tr>
    <td width="0"><img src="../../../images/images/spacer.gif" height="110" width="0"></td>
    <td align="center" valign="middle" cellspacing="0" cellpadding="0"><a href="#" onclick="window.opener.SetUrl('<%=sImagesUrl+"/"+aFiles[i].getName()%>');window.close();"><img name="<%=aFiles[i].getName()%>" src="../images/images/webbuilder/nothumb.jpg" width="80" height="80" border="0"></a></td>
  </tr>
  <tr>
    <td height="20" colspan="2" align="center" valign="middle">
    <a href="#" onclick="openPicture('<%=aFiles[i].getName()%>')" title="[~Ver a tama&ntilde;o real~]"><img src="../../../../images/images/viewtxt.gif" HEIGHT="16" WIDTH="16" BORDER="0" ALT="[~Ver a tama&ntilde;o real~]"></a>
    <input type="checkbox" name="chk.<%=aFiles[i].getName()%>" value="<%=aFiles[i].getName()%>"><a href="javascript:void(0)" onclick="openPicture('<%=aFiles[i].getName()%>')"><font face="verdana" style="text-decoration:none;color:000080" size="-2"><%=aFiles[i].getName()%></font></a></td>
  </tr>
</table>
</td>
<%
   if (contador==3)
   {
     contador=0;
     out.print("</tr><tr>");
   }
   else
   {
     contador++; 
   }
   } //if extensiones
  }//for
%>
</tr>
</table>
</form>
</body>
</html>
<%@ include file="../../../../methods/page_epilog.jspf" %>