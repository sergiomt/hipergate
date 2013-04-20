<%@ page import="java.io.File,com.knowgate.misc.*,java.io.*,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.workareas.FileSystemWorkArea" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

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

  //if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "default");
  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "none");

  String gu_workarea = request.getParameter("gu_workarea");

  String sDocType = request.getParameter("doctype");
  String sRefreshItem = request.getParameter("refreshitem");
  String sObjectId = Gadgets.split2(sRefreshItem,'.')[1];

  // Rutas y parametros
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sWorkareasPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefWrkArPut);

  String sDefURLRoot = request.getRequestURI();
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));

  String sURLRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver", sDefURLRoot);

  String sDefWrkArGet = request.getRequestURI();
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet.substring(0,sDefWrkArGet.lastIndexOf("/"));
  sDefWrkArGet = sDefWrkArGet + "/workareas";

  String sWorkareasGet	= Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasget", sDefWrkArGet);

  String sApp = "Mailwire";

  //if (sDocType.equals("website")) sApp = "WebBuilder";
  
  String sImagesDir = sWorkareasPut + File.separator + gu_workarea + File.separator + "apps" + File.separator + sApp + File.separator + "data" + File.separator + "images";
  String sImagesUrl = sWorkareasGet + "/" + gu_workarea + "/apps/" + sApp + "/data/images";
  
  // Crear el directorio de thumbnails si no existe
  FileSystemWorkArea oFileSys = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));
  oFileSys.mkdirs("file://" + sWorkareasPut + File.separator + gu_workarea + File.separator + "apps" + File.separator + sApp + File.separator + "data" + File.separator + "images" + File.separator + "thumbs");
  oFileSys = null;

  int iFiles = 0;
  DBSubset oFiles = new DBSubset(DB.k_images,
    DB.gu_image + "," + DB.path_image + "," + DB.nm_image + "," + DB.dm_width + "," + DB.dm_height + "," + DB.len_file + "," + DB.url_addr,
  	DB.tp_image + "='webbuilder' AND " + DB.gu_workarea + "=? ORDER BY " + DB.dt_created + " DESC", 100);
  JDCConnection oConn = null;
 
  try {
    oConn = GlobalDBBind.getConnection("wb_imageslist");
    
    iFiles = oFiles.load (oConn, new Object[]{gu_workarea});
    
    oConn.close("wb_imageslist");
  }
  catch (SQLException sqle) {
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("wb_imageslist");      
    oConn = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", sqle.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;

  oConn = null;
  
  String sFileName;
  
%>
<html lang="<%=sLanguage%>">
<head>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript">
    <!--
      function uploadImage() {
        window.open('wb_file_upload.jsp','wUploadImage','top=' + (screen.height-360)/2 + ',left=' + (screen.width-450)/2 + ',height=360,width=450');
      }
     
      // ------------------------------------------------------
      
      function paintThumbs() {

        // Recorrer los thumbnails y cambiar el icono generico por la mini-imagen buena correspondiente

        var imgCount = document.images.length;
        var img;

        /* DEMO ONLY, do not uncomment
        for (var i=0; i<imgCount; i++) {
            img = document.images[i];
          if (img.width==80 && img.height==80)
          { 
            img.src = "<%=sImagesUrl%>/" + img.name;
          }
        }
        return true;
        END DEMO ONLY */
                        
        for (var i=0; i<imgCount; i++) {
          img = document.images[i];
          // Identificar los thumbnails entre las demas imagenes por su tamaño cuadrado de 80x80 pixels
          if (img.width==80 && img.height==80)
            img.src = "wb_thumbnail.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&nm_image=" + escape(img.name);
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
             alert("Must check at least one image");
           else
             document.location="images_delete.jsp?checkeditems=" + lista;
      }       

      // ------------------------------------------------------

      function setItems(pth,alt,wh,ht,url)
      {
        var opr = window.opener;
        opr.setItem("<%=sRefreshItem+".id"%>","<%=sObjectId%>");
        opr.setItem("<%=sRefreshItem+".path"%>","<%=sImagesUrl%>/"+pth);
        opr.setItem("<%=sRefreshItem+".alt"%>",alt);
        opr.setItem("<%=sRefreshItem+".width"%>",wh);
        opr.setItem("<%=sRefreshItem+".height"%>",ht);
        opr.setItem("<%=sRefreshItem+".url"%>",url);
        window.close();
		  } // setItems
       
    //-->    
  </SCRIPT> 
  <TITLE>hipergate :: Available Images</TITLE>
</head>
<body  TOPMARGIN="0" MARGINHEIGHT="0" onLoad="paintThumbs()">
<table cellspacing="0" cellpadding="0" border="0" width="99%">
<tr>
<td valign="top" bgcolor="#ffffff">
<img src="<%=sURLRoot%>/skins/<%=sSkin%>/hglogopeq.jpg" border="0">
</td>
<td align="right">
<input type="button" onclick="window.opener.focus();window.close();" class="closebutton" value="Close">
</td>
</tr>
<tr>
<td colspan="2" valign="center" bgcolor="#cccccc">
<span class="title1">Available Images</span>
</td>
</tr>
</table>
<TABLE CELLSPACING="2" CELLPADDING="2">
  <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  <TR>
    <TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Image"></TD>
    <TD ALIGN="LEFT" VALIGN="middle"><A HREF="#" onclick="uploadImage()" CLASS="linkplain">New Image</A></TD>
    <TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Remove images"></TD>
    <TD ALIGN="LEFT"VALIGN="middle"><A HREF="javascript:if (window.confirm('When images are removed, they will stop appearing at documents that use them. Are you sure?')) deleteImages()" CLASS="linkplain">Remove images</A></TD>
  </TR>
  <TR><TD COLSPAN="4" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
</TABLE>
<form name="frmDeleteImages" id="frmDeleteImages" method="post" action="image_delete.jsp">
<table cellspacing="0" cellpadding="2" border="0" width="99%">
<tr>
<%
  int contador = 0;

  for (int i=0; i<iFiles; i++) {
    sFileName = oFiles.getString(2,i).toLowerCase();
    if (sFileName.endsWith(".jpeg") || sFileName.endsWith(".jpg") || sFileName.endsWith(".gif") || sFileName.endsWith(".png"))
      {
%>
<td align="center" valign="middle" width="25%">
<table id="table<% out.write(String.valueOf(i));%>" cellspacing="0" cellpadding="0" border="0" width="100%" style="border:1px solid #000000" onmouseover="table<% out.write(String.valueOf(i)); %>.style.border='1px solid #ffd700';" onmouseout="table<% out.write(String.valueOf(i)); %>.style.border='1px solid #000000';">
  <tr>
    <td width="0"><img src="../images/images/spacer.gif" height="110" width="0"></td>
    <td align="center" valign="middle"><a href="#" onclick="setItems('<%=oFiles.getString(2,i)%>','<%=oFiles.getString(2,i)%>',<%=oFiles.get(3,i)%>,<%=oFiles.get(4,i)%>,'<%=oFiles.getStringNull(6,i,"")%>')"><img name="<%=oFiles.getString(2,i)%>" src="../images/images/webbuilder/nothumb.jpg" width="80" height="80" border="0"></a></td>
  </tr>
  <tr>
    <td height="20" colspan="2" align="center" valign="middle"><input type="checkbox" name="chk.<%=oFiles.getString(2,i)%>" value="<%=oFiles.getString(2,i)%>"><a href="#" onclick="setItems('<%=oFiles.getString(2,i)%>','<%=oFiles.getString(2,i)%>',<%=oFiles.get(3,i)%>,<%=oFiles.get(4,i)%>,'<%=oFiles.getStringNull(6,i,"")%>')"><font face="verdana" style="text-decoration:none;color:000080" size="-2"><%=oFiles.getString(2,i)%></font></a></td>
  </tr>
</table>
</td>
<%
        if (contador==3) {
          contador=0;
          out.write("</tr><tr>");
        }
        else {
          contador++; 
        }
      } //fi (extensions)
  } // next
%>
</tr>
</table>
</form>
</body>
</html>
<%@ include file="../methods/page_epilog.jspf" %>