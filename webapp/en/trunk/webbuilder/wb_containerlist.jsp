<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.util.*,java.lang.*,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.dataobjs.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  boolean bIsPowerUser = isDomainPowerUser (GlobalCacheClient, GlobalDBBind, request, response);
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  if (!bIsAdmin && !bIsPowerUser) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Not enough security credentials&desc=Your security access level does not allow you to add new pages&resume=_close"));       
    return;
  }
  
  String sLanguage = getNavigatorLanguage(request);

  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String gu_microsite = request.getParameter("gu_microsite");

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
  String sURLStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(),"storage","");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = nullif(request.getParameter("gu_pageset"));
  String gu_page = nullif(request.getParameter("gu_page"));
  String id_block = nullif(request.getParameter("id_block"));
  
  String sMenuPath = sURLRoot + "/webbuilder/wb_mnuintegrador.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_pageset=" + gu_pageset;
  
  String sOutputPath = new String(sStorage + "domains/" + id_domain + "/workareas/" + gu_workarea + "/apps/Mailwire/html/" + gu_pageset + "/");
  
  String sURL = new String(sURLStorage + "/domains/" + id_domain + "/workareas/" + gu_workarea + "/apps/Mailwire/html/" + gu_pageset + "/");

  MicrositeDB oMicrositeDB = new MicrositeDB();
  Object aPKs[] = {gu_microsite};
  
  JDCConnection oConn = GlobalDBBind.getConnection("wb_metablocklist");
  oMicrositeDB.load(oConn,aPKs);
  oConn.close("wb_metablocklist");
  
  String sFileTemplate = sStorage + oMicrositeDB.getString(DB.path_metadata);
  
  
  Microsite oMicrosite = MicrositeFactory.getInstance(sFileTemplate);
  
  Vector oContainers = ((Vector)(oMicrosite.containers()));
  
  Container oCurContainer = (Container)(oContainers.elementAt(0));

  String sURLPageStore = sURLRoot + "/webbuilder/wb_page_store.jsp?id_domain=" + id_domain + "&gu_workarea=" + gu_workarea + "&gu_pageset="  + gu_pageset + "&gu_microsite="  + gu_microsite + "&path_metadata="  + Gadgets.URLEncode(Gadgets.escapeChars(sFileTemplate,"\\",'\\'));
%>
<html>
<head>
<TITLE>hipergate :: New Page</TITLE>
<SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
<SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
<SCRIPT TYPE="text/javascript">
<!--
  function createPage(nm) {
    if (document.forms[0].nm_page.value.length==0)
      document.forms[0].nm_page.value = nm;
    window.document.location = "<%=sURLPageStore%>&nm_page=" + escape(document.forms[0].nm_page.value) + "&nm_container=" +nm; 
  }
//-->
</SCRIPT>
</head>
<body  TOPMARGIN="0" MARGINHEIGHT="0">
<form>
<center>
<table cellspacing="0" cellpadding="0" border="0" width="70%">
<tr width="80%"><td colspan="2" valign="top" align="center" width="70%" >&nbsp;<img src="<%=sURLRoot%>/skins/xp/hglogopeq.jpg" border="0"></td></tr>
<tr><td colspan="2" valign="center" align="center"  width="100%" class="title1">&nbsp;New Page</td></tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr><td colspan="2" class="formplain"><p align="justify">Choose a name for the new page and click on the container type to base the page on.</p></td></tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr><td class="formstrong">Name:&nbsp;&nbsp;</td><td class="formplain"><input size="16" type="text" name="nm_page" id="nm_page"></td></tr>
<tr><td colspan="2">&nbsp;</td></tr>
<% 
  for (int i=0; i<oContainers.size(); i++){
     oCurContainer = (Container)(oContainers.elementAt(i));
     if(!oCurContainer.name().equals("Recursos") && !oCurContainer.name().equals("Home"))
     {
     int counter = (i%2)+1;
     out.print("<tr>");
     out.print("<td colspan=\"2\" class=\"strip" + counter + "\" width=\"80%\">");
     out.print("<a href=\"javascript:createPage('" + oCurContainer.name() + "')\">");
     out.print("New Page " + oCurContainer.name());
     out.print("</a>");
     out.print("</td>");
     out.print("</tr>");
     }
   }
%>
</table>
</center>
</form>
</body>
</html>
<%@ include file="../methods/page_epilog.jspf" %>
