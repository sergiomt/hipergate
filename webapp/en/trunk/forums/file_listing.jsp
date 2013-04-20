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
  
  String sApp = nullif(request.getParameter("app"), "Forum");
     
  String sImagesDir = sWorkareasPut + sSep + gu_workarea + sSep + "apps" + sSep + sApp;
  String sImagesUrl = sWorkareasGet + "/" + gu_workarea + "/" + "apps" + "/" + sApp;
  
  // Crear el directorio de thumbnails si no existe
  
  FileSystemWorkArea oFileSys = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));
  oFileSys.mkdirs("file://" + sImagesDir + sSep + "thumbs");
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
    
      var aFiles = new Array(<%=(aFiles.length>0 ? String.valueOf(aFiles.length) : "")%>);
<%
			for (int f=0; f<aFiles.length; f++) {
			  out.write("      aFiles[" + String.valueOf(f)+"] = \"" + Gadgets.escapeChars(aFiles[f].getName(), "\"", '\\') + "\";\n");
			}
%>

      // ------------------------------------------------------

      function insertImage(n) {
      	if (window.opener) {
      		var ed = window.opener.editor;
      	  ed.insertHTML("<img src=\"<%=sImagesUrl%>/"+escape(aFiles[n])+"\" border=\"0\" />");
      	  window.close();
      	} else {
      	  alert ("Files cannot be inserted because the window of the message has been closed");
      	}
      }

      // ------------------------------------------------------

      function insertLink(n) {
      	if (window.opener) {
      		var ed = window.opener.editor;
      	  ed.insertHTML("<a href=\"<%=sImagesUrl%>/"+escape(aFiles[n])+"\">"+aFiles[n]+"</a>");
      	  window.close();
      	} else {
      	  alert ("Files cannot be inserted because the window of the message has been closed");
      	}
      }

      // ------------------------------------------------------

      function uploadImage() { 
        window.open('file_upload.jsp','fUploadImage','top=' + (screen.height-360)/2 + ',left=' + (screen.width-450)/2 + ',height=360,width=450');
      }

      // ------------------------------------------------------
      
      function setCombos() {
			  setCombo(document.forms[0].sort_by, "<%=sSortBy%>");
			  document.forms[0].find.value = "<%=sFind%>";
      }

      // ------------------------------------------------------
      
      function deleteImages() {
      	  var frm = document.forms[0];
          var lista = '';
          var contador = 0;
          for (var i=0; i<frm.elements.length; i++)
            if (frm.elements[i].type=='checkbox')
              if (frm.elements[i].checked)
              {
                if (contador==0) 
          	  lista = lista + "<%=Gadgets.escapeChars(Gadgets.chomp(sImagesDir,sSep),"\\", '\\')%>" + frm.elements[i].value;
          	else
          	  lista = lista + ":" + "<%=Gadgets.escapeChars(Gadgets.chomp(sImagesDir,sSep),"\\", '\\')%>" + frm.elements[i].value;
          	contador++;
              }
              
           if (contador==0)
             alert("At least one file must be selected");
           else {
             frm.checkeditems.value = lista;
             frm.submit();
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
        window.location = "file_listing.jsp?find="+escape(frm.find.value)+"&sort_by="+sby;
      }      
    //-->    
  </SCRIPT> 
  <TITLE>hipergate :: Available files</TITLE>
</head>
<body  TOPMARGIN="0" MARGINHEIGHT="0" onLoad="setCombos()">
<form name="frmDeleteImages" id="frmDeleteImages" method="post" action="file_delete.jsp">
<input type="hidden" name="checkeditems">
<br/>
<table cellspacing="0" cellpadding="0" border="0" width="99%"><tr><td colspan="2" valign="center" class="striptitle"><font class="title1">Available files</font></td></tr></table>
<TABLE CELLSPACING="2" CELLPADDING="2">
<TR>
<TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New file"></TD>
<TD ALIGN="LEFT" VALIGN="middle"><A HREF="#" onclick="uploadImage()" CLASS="linkplain">New file</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete file"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><A HREF="javascript:if (window.confirm('After deleting the files these will no longer be shown at the messages that use them. Are you sure that you want to continue?')) deleteImages()" CLASS="linkplain">Delete files</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/selall16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Select All"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><A HREF="#" onclick="selectAll()" CLASS="linkplain">Select All</A></TD>
</TR>
<TR>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/resort.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Sort"></TD>
<TD ALIGN="LEFT" VALIGN="middle"><SELECT NAME="sort_by" CLASS="combomini" onchange="sortBy(this.options[this.selectedIndex].value)"><OPTION VALUE="date_desc">Date Descending</OPTION><OPTION VALUE="date_asc">Date</OPTION><OPTION VALUE="name_asc">Name A-Z</OPTION><OPTION VALUE="name_desc">Name Z-A</OPTION></SELECT></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/find16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Search"></TD>
<TD  ALIGN="LEFT"VALIGN="middle"><INPUT TYPE="text" NAME="find" CLASS="combomini" SIZE="14">&nbsp;<A HREF="#" CLASS="linkplain" onclick="sortBy(getCombo(document.forms[0].sort_by))">Buscar</A></TD>
<TD ALIGN="LEFT" WIDTH="18"><IMG SRC="../images/images/findundo16.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Select All"></TD>
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
    if (!aFiles[i].isDirectory()) {
%>
<td align="center" valign="middle" width="25%">
<table id="table<% out.write(String.valueOf(i)); %>" cellspacing="0" cellpadding="0" border="0" width="100%" style="border:1px solid #000000" onmouseover="document.getElementById('table<% out.write(String.valueOf(i)); %>').style.border='1px solid #ffd700';" onmouseout="document.getElementById('table<% out.write(String.valueOf(i)); %>').style.border='1px solid #000000';">
  <tr>
    <td width="0"><img src="../images/images/spacer.gif" height="110" width="0"></td>
    <td align="center" valign="middle" cellspacing="0" cellpadding="0"><a href="<%=sImagesUrl+"/"+Gadgets.URLEncode(aFiles[i].getName())%>")"><img lowsrc="../images/images/spacer.gif" src="../webbuilder/wb_thumbnail.jsp?nm_app=<%=sApp%>&id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&nm_image=<%=Gadgets.URLEncode(aFiles[i].getName())%>" width="80" height="80" border="0"></a></td>
  </tr>
  <tr>
    <td colspan="2" align="center" valign="middle">
    	<table border="0" cellpadding="2">
    		<tr>
    		  <td><font face="verdana" style="text-decoration:none;color:000080" size="-2"><%=aFiles[i].getName()%></font></td>
    			<td><input type="checkbox" name="chk.<%=aFiles[i].getName()%>" value="<%=aFiles[i].getName()%>"></td>
				</tr>
				<tr>
					<td><input type="button" class="minibutton" style="width:120px" value="Insert Image" onclick="insertImage(<%=String.valueOf(i)%>)"></td>
					<td></td>
				</tr>
				<tr>
					<td><input type="button" class="minibutton" style="width:120px" value="Insert link" onclick="insertLink(<%=String.valueOf(i)%>)"></td>
					<td></td>
				</tr>
      </table>
    </td>
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
  } // for
  } // fi isDirectory()
%>
</tr>
</table>
<br>
<center><input type="button" class="closebutton" value="Close" accesskey="c" onclick="window.close()"></center>
</form>
</body>
</html>
<%@ include file="../methods/page_epilog.jspf" %>