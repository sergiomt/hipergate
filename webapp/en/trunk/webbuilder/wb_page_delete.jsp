<%@ page import="com.knowgate.dataxslt.*,java.util.*,java.io.*,java.math.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.dataxslt.db.*,com.knowgate.dfs.FileSystem,com.knowgate.misc.*" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
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

  String id_domain = getCookie(request,"domainid","");
  String file_template = request.getParameter("file_template");
  String file_pageset  = request.getParameter("file_pageset");
  String gu_page       = request.getParameter("gu_page");
  String gu_pageset    = request.getParameter("gu_pageset");
  String gu_workarea   = request.getParameter("gu_workarea");
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  boolean bIsPowerUser = isDomainPowerUser (GlobalCacheClient, GlobalDBBind, request, response);
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  PageSet oPageSet = new PageSet(file_template,file_pageset);
  
  //Controlar que no se elimina Home o Recursos
  String sPageName = "";
  Vector vPages = oPageSet.pages();
  for (int i=0; i<vPages.size(); i++) {
    if (((Page)vPages.elementAt(i)).guid().equals(gu_page)) {
      sPageName = ((Page)vPages.elementAt(i)).getTitle();
      break;
    }
  }
%>
<HTML><HEAD><TITLE>Wait...</TITLE>
<%  
  if (!bIsAdmin && !bIsPowerUser)
    out.write("<script type=\"text/javascript\">alert('Your security access level does not allow you to delete pages');</script>");
  else if (sPageName.equals("Home"))
    out.write("<script type=\"text/javascript\">alert('It is not permitted to remove Home Page, as it is the start navigation point of the website.');</script>");
  else
   if (sPageName.equals("Recursos"))
     out.write("<script type=\"text/javascript\">alert('It is not permitted to remove Resources Page.');</script>");
  else
   if (sPageName.equals("Index"))
     out.write("<script type=\"text/javascript\">alert('The WebSite Home page cannot be deleted.');</script>");
   else
     oPageSet.removePage(file_pageset,gu_page);
  
  oPageSet = null;

  //Recargar listado
%>  
<script type="text/javascript">
  document.location="wb_document.jsp?id_domain<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&doctype=website";
</script>
</HEAD><BODY></BODY></HTML>
<%@ include file="../methods/page_epilog.jspf" %>