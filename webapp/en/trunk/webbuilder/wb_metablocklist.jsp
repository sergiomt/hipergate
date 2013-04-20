<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.util.*,java.lang.*,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf"  %>
<%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf"   %>
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
  String sSkin = getCookie(request, "skin", "xp");

  // Obtener el dominio y la workarea
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 

  // Rutas y parámetros
  String sDefURLRoot = request.getRequestURI();
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));
  sDefURLRoot = sDefURLRoot.substring(0,sDefURLRoot.lastIndexOf("/"));

  String sURLRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver", sDefURLRoot);

  if (sURLRoot.endsWith("/") && sURLRoot.length()>0) sURLRoot = sURLRoot.substring(0, sURLRoot.length()-1);

  String sDefImgSrv = request.getRequestURI();
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv + "/images";
  
  String sImagesRoot    = Environment.getProfileVar(GlobalDBBind.getProfileName(),"imageserver",sDefImgSrv);
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");
  
  String gu_microsite = request.getParameter("gu_microsite");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = nullif(request.getParameter("gu_pageset"));
  String gu_page = nullif(request.getParameter("gu_page"));
  String sDocType = nullif(request.getParameter("doctype"));
  String sPage = nullif(request.getParameter("page"));

  String sURLEditBlock  = sURLRoot + "/webbuilder/wb_editblock.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_pageset="  + gu_pageset + "&gu_page=" + gu_page;
  
  // Recupero MicrositeDB
  JDCConnection oConn = GlobalDBBind.getConnection("wb_metablocklist");
  String sPathData = PageSetDB.filePath(oConn, gu_pageset);
  String sPathMetaData = MicrositeDB.filePath(oConn, gu_microsite);
  oConn.close("wb_metablocklist");

  Microsite oMicrosite = MicrositeFactory.getInstance (sStorage+sPathMetaData);

  Vector oMetablocks = oMicrosite.container(0).metablocks();
  
  PageSet oPageset = new PageSet(sStorage+sPathMetaData, sStorage+sPathData);
  
  Page oPage = oPageset.page(gu_page);
    
  Vector oBlocks;
  
  MetaBlock oCurMetaBlock;
  
  int iMaxOccurs;  
%>
<HTML>
<HEAD>
<TITLE>hipergate :: Block Types</TITLE>
<SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
<SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
<SCRIPT TYPE="text/javascript">
  <!--
    function openEdit(id,nm) { 
	    window.opener.document.location = "<%=sURLEditBlock%>&nm_metablock=" + escape(nm) + "&doctype=<%=sDocType%>&page=<%=sPage%>&id_domain=<%=id_domain%>&n_domain=<%=n_domain%>&id_metablock="+id;
      self.close();
    }
  //-->
</SCRIPT>
</HEAD>
<BODY  TOPMARGIN="0" MARGINHEIGHT="0" onclose="window.opener.setNull()">
<table cellspacing="0" cellpadding="0" border="0" width="98%">
  <tr><td valign="top" align="center" width="100%" >&nbsp;<img src="<% out.write(sURLRoot); %>/skins/<% out.write(sSkin); %>/hglogopeq.jpg" border="0"></td></tr><tr><td valign="center" align="center"  width="100%"><span class="title1">&nbsp;Block Types</span></td></tr><tr><td>&nbsp;</td></tr>
<%

  int iMetaBlockCount = oMetablocks.size();
  
  for (int i=0; i<iMetaBlockCount; i++)
  {
     oCurMetaBlock = (MetaBlock)(oMetablocks.elementAt(i));
     
     iMaxOccurs = oCurMetaBlock.maxoccurs();
     
     if (-1==iMaxOccurs) iMaxOccurs = 2147483647;
     
     oBlocks = oPage.blocks(oCurMetaBlock.id(), null, null);
     
     String counter = String.valueOf((i%2)+1);
     
     out.write("<tr>");
     out.write("<td class=\"strip" + counter + "\" width=\"100%\">");
     
     if (oBlocks.size()<iMaxOccurs) {
       out.write("<a href=\"#\" onclick=\"javascript:openEdit('" + oCurMetaBlock.id() + "','" + oCurMetaBlock.name() + "')\">");
       out.write(oCurMetaBlock.name());
       out.write("</a>");
     }
     else {
       out.write("<span title=\"Maximum blocks for this type was reached\">");
       out.write(oCurMetaBlock.name());
       out.write("</span>");
     }
     
     out.write("</td>");
     out.write("</tr>");
  } // next

  oMetablocks = null;

  oMicrosite = null;

%>
</table>
</BODY>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>