<%@ page import="java.util.Arrays,com.knowgate.debug.DebugFile,com.knowgate.misc.*,java.io.*,java.lang.*,java.util.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.workareas.FileSystemWorkArea,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8"  %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%!

  public class SearchFilter implements FileFilter {
    private String sPattern;
    
    public SearchFilter(String s) {
      sPattern = s.toUpperCase();
    }
    
    public boolean accept(File oFile) {
      return oFile.getName().toUpperCase().indexOf(sPattern)>=0;
    }
  }

%><%
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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
  String sSkin = getCookie(request, "skin", "xp");
  String id_domain = getCookie(request, "domainid", "0");
  String n_domain = getCookie(request, "domainnm", "none");
  String gu_workarea = getCookie(request,"workarea","");

  String sDocType = request.getParameter("doctype");
  String sSortBy = nullif(request.getParameter("sort_by"), "date_desc");
  String sFind = nullif(request.getParameter("find"));
  String sSep = java.io.File.separator;

  // Rutas y parámetros  

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
  
  String sApp = nullif(request.getParameter("app"), "Mailwire");
  
  //if (sDocType.equals("website")) sApp = "WebBuilder";
     
  String sImagesDir = sWorkareasPut + sSep + gu_workarea + sSep + "apps" + sSep + sApp + sSep + "data" + sSep + "images";
  String sImagesUrl = sWorkareasGet + "/" + gu_workarea + "/" + "apps" + "/" + sApp + "/" + "data" + "/" + "images";
  
  // Crear el directorio de thumbnails si no existe
  
  FileSystemWorkArea oFileSys = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));
  oFileSys.mkdirs("file://" + sWorkareasPut + sSep + gu_workarea + sSep + "apps" + sSep + sApp + sSep + "data" + sSep + "images" + sSep + "thumbs");
  oFileSys = null;
    
  File oDirectory = new File(sImagesDir);
  File[] aFiles;
  if (sFind.length()==0) {
    aFiles = oDirectory.listFiles();
  } else {
    SearchFilter oFilter = new SearchFilter(sFind);
    aFiles = oDirectory.listFiles(oFilter);
  }
  	
  if (sSortBy.equals("date_desc")) {
    Arrays.sort( aFiles, new Comparator() { public int compare(Object o1, Object o2) { return new Long(((File)o2).lastModified()).compareTo(new Long(((File) o1).lastModified())); } });
  } else if (sSortBy.equals("date_asc")) {
    Arrays.sort( aFiles, new Comparator() { public int compare(Object o1, Object o2) { return new Long(((File)o1).lastModified()).compareTo(new Long(((File) o2).lastModified())); } });
  } else if (sSortBy.equals("name_asc")) {
    Arrays.sort( aFiles, new Comparator() { public int compare(Object o1, Object o2) { return ((File)o1).getName().compareTo(((File)o2).getName()); } });
  }  else if (sSortBy.equals("name_desc")) {
    Arrays.sort( aFiles, new Comparator() { public int compare(Object o1, Object o2) { return ((File)o2).getName().compareTo(((File)o1).getName()); } });
  } // fi
  
  String sFileName;
      
%><html lang="<%=sLanguage%>">
<head>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript">
    <!--
      function uploadImage() { 
        window.open('wb_file_upload.jsp','wUploadImage','top=' + (screen.height-360)/2 + ',left=' + (screen.width-450)/2 + ',height=360,width=450');
      }

      // ------------------------------------------------------
      
      function openPicture(pictureName) { 
      	var w2 = window.open("about:blank", null, "directories=no,toolbar=no,menubar=no,theatermode,resizable=false,width=1,height=1,top=" + screen.height/2 + ",left=" + screen.width/2); 
      	w2.blur();
      	window.focus();
      	w2.document.write("<html>"); w2.document.write("\n");
      	w2.document.write("<head>"); w2.document.write("\n");
      	w2.document.write("<title>"); w2.document.write("\n");
      	w2.document.write("View image(" + pictureName + ")"); w2.document.write("\n");
      	w2.document.write("</title>"); w2.document.write("\n");
      	w2.document.write("<script type='text/javascript'>"); w2.document.write("\n");
      	w2.document.write("function resizeWin() {"); w2.document.write("\n");
      	w2.document.write("window.resizeTo(laimagen.width+10,laimagen.height+20);"); w2.document.write("\n");
      	w2.document.write("window.moveTo(parseInt((screen.width-laimagen.width-10)/2),parseInt((screen.height-laimagen.height-20)/2));"); w2.document.write("\n");
      	w2.document.write("a=0;"); w2.document.write("\n");
      	w2.document.write("}"); w2.document.write("\n");
      	w2.document.write("<"+"/"+"script>");
      	w2.document.write("\n");
      	w2.document.write("</head>");
      	w2.document.write("\n");
      	w2.document.write("<body topmargin=0 marginheight=0 leftmargin=0 onload='resizeWin()'>"); w2.document.write("\n");
      	w2.document.write("<center>"); w2.document.write("\n");
      	w2.document.write("<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>"); w2.document.write("\n");
      	w2.document.write("<tr>"); w2.document.write("\n");
      	w2.document.write("<td align=middle valign=middle>"); w2.document.write("\n");
      	w2.document.write("<img name='laimagen' border='0' align='middle' src='<%=sImagesUrl%>/" + pictureName+ "'>"); w2.document.write("\n");
      	w2.document.write("</td>"); w2.document.write("\n");
      	w2.document.write("</tr>"); w2.document.write("\n");
      	w2.document.write("</table>"); w2.document.write("\n");
      	w2.document.write("</body>"); w2.document.write("\n");
      	w2.document.write("</html>"); w2.document.write("\n");
      	w2.focus();
      }    

      // ------------------------------------------------------
      
      function paintThumbs() {
        // Recorrer los thumbnails y cambiar el icono generico por la mini-imagen buena correspondiente

			  setCombo(document.forms[0].sort_by, "<%=sSortBy%>");
			  document.forms[0].find.value = "<%=sFind%>";
			  
        var imgCount = document.images.length;
        var img;        
        
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
          	  lista = lista + "<%=Gadgets.escapeChars(Gadgets.chomp(sImagesDir,sSep),"\\", '\\')%>" + document.forms[0].elements[i].value;
          	else
          	  lista = lista + ":" + "<%=Gadgets.escapeChars(Gadgets.chomp(sImagesDir,sSep),"\\", '\\')%>" + document.forms[0].elements[i].value;
          	contador++;
              }
              
           if (contador==0)
             alert("Must check at least one image");
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

      // ------------------------------------------------------
      
      function sortBy(sby)
      {
      	var frm = document.forms[0];
        window.location = "image_listing.jsp?selected="+getURLParam("selected")+"&subselected="+getURLParam("subselected")+"&find="+escape(frm.find.value)+"&sort_by="+sby;
      }      
    //-->    
  </SCRIPT> 
  <TITLE>hipergate :: Available Images</TITLE>
</head>
<body  TOPMARGIN="0" MARGINHEIGHT="0" onLoad="paintThumbs()">
<%@ include file="../common/tabmenu.jspf" %>
<form name="frmDeleteImages" id="frmDeleteImages" method="post" action="images_delete.jsp">
<input type="hidden" name="checkeditems">
<br/>
<table cellspacing="0" cellpadding="0" border="0" width="99%"><tr><td colspan="2" valign="center" class="striptitle"><font class="title1">Available Images</font></td></tr></table>
<TABLE CELLSPACING="2" CELLPADDING="2">
<TR>
<TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Image"></TD>
<TD ALIGN="LEFT" VALIGN="middle"><A HREF="#" onclick="uploadImage()" CLASS="linkplain">New Image</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Remove images"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><A HREF="javascript:if (window.confirm('When images are removed, they will stop appearing at documents that use them. Are you sure?')) deleteImages()" CLASS="linkplain">Remove images</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/selall16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Select all"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><A HREF="#" onclick="selectAll()" CLASS="linkplain">Select all</A></TD>
</TR>
<TR>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/resort.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Sort"></TD>
<TD ALIGN="LEFT" VALIGN="middle"><SELECT NAME="sort_by" CLASS="combomini" onchange="sortBy(this.options[this.selectedIndex].value)"><OPTION VALUE="date_desc">Date Descending</OPTION><OPTION VALUE="date_asc">Date Ascending</OPTION><OPTION VALUE="name_asc">Name A-Z</OPTION><OPTION VALUE="name_desc">Name Z-A</OPTION></SELECT></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/find16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Search"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><INPUT TYPE="text" NAME="find" CLASS="combomini" SIZE="14">&nbsp;<A HREF="#" CLASS="linkplain" onclick="sortBy(getCombo(document.forms[0].sort_by))">Buscar</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/findundo16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Select all"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><A HREF="#" onclick="document.forms[0].find.value=''; sortBy(getCombo(document.forms[0].sort_by))" CLASS="linkplain">Discard search</A></TD>
<TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
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
    <td width="0"><img src="../images/images/spacer.gif" height="110" width="0"></td>
    <td align="center" valign="middle" cellspacing="0" cellpadding="0"><a href="javascript:void(0)" onclick="openPicture('<%=aFiles[i].getName()%>')"><img name="<%=aFiles[i].getName()%>" src="../images/images/webbuilder/nothumb.jpg" width="80" height="80" border="0"></a></td>
  </tr>
  <tr>
    <td height="20" colspan="2" align="center" valign="middle"><input type="checkbox" name="chk.<%=aFiles[i].getName()%>" value="<%=aFiles[i].getName()%>"><a href="javascript:void(0)" onclick="openPicture('<%=aFiles[i].getName()%>')"><font face="verdana" style="text-decoration:none;color:000080" size="-2"><%=aFiles[i].getName()%></font></a></td>
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
   } // if extensiones
  } // for
%>
</tr>
</table>
</form>
</body>
</html>
<%@ include file="../methods/page_epilog.jspf" %>