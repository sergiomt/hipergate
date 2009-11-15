<%@ page import="java.util.*,java.math.*,java.io.*,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dataxslt.*,com.knowgate.dataxslt.db.*,com.knowgate.misc.*,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  boolean bIsPowerUser = isDomainPowerUser (GlobalCacheClient, GlobalDBBind, request, response);
  boolean bIsAdmin = isDomainAdmin (GlobalCacheClient, GlobalDBBind, request, response);

  if (!bIsAdmin && !bIsPowerUser) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Not enough security credentials&desc=Your security access level does not allow you to add new pages&resume=_close"));       
    return;
  }
  
  String id_domain = getCookie(request,"domainid","");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  String gu_pageset = request.getParameter("gu_pageset")==null ? "" : request.getParameter("gu_pageset");  
  String sDocType = request.getParameter("doctype");
  String gu_container = null;
  
  String sMetaFile = request.getParameter("path_metadata");
      
  Microsite msite = MicrositeFactory.getInstance(sMetaFile);
  
  Vector containers = msite.containers();

  String sContainerName = null;
  
  for (int i=0; i<containers.size(); i++)
  {
    if (((Container)(containers.elementAt(i))).name().equals(request.getParameter("nm_container")))
    {
     gu_container = ((Container)(containers.elementAt(i))).guid();
     sContainerName = ((Container)(containers.elementAt(i))).name();
     break;
    }
  }

  if (null==sContainerName) {
    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "DOMException", "Container " + request.getParameter("nm_container") + " not found");
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=DOMException&desc=Container not found " + request.getParameter("nm_container") + "&resume=_back"));
    return;
  }
  
  String sDataTemplateFile = Gadgets.replace(sMetaFile,".xml","_" + sContainerName + ".datatemplate.xml");

  FileSystem oFS = new FileSystem();
  
  String sTemplateData = oFS.readfilestr(sDataTemplateFile, "UTF-8");
  
  sTemplateData = Gadgets.replace(sTemplateData,":gu_pagex", Gadgets.generateUUID());
  sTemplateData = Gadgets.replace(sTemplateData,":page_title",request.getParameter("nm_page"));
  sTemplateData = Gadgets.replace(sTemplateData,":gu_container",gu_container);
  
  sTemplateData+= sTemplateData + "</pages>";
  
  try{
    sTemplateData = sTemplateData.substring(sTemplateData.indexOf("<pages>")+7, sTemplateData.indexOf("</pages>")-1) + "</pages>";
  }
  catch (StringIndexOutOfBoundsException sior) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "StringIndexOutOfBoundsException", sior.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=StringIndexOutOfBoundsException&desc=XML document is not valid " + sDataTemplateFile + "&resume=_back"));   
  }
  
  if (null==sTemplateData) return;
    
  JDCConnection oConn = GlobalDBBind.getConnection("wb_page_store");
  
  PageSetDB oPageSet = new PageSetDB();
  String aPK[] = {gu_pageset};
  oPageSet.load(oConn, aPK);
  
  String sFilePageSet = sStorage + oPageSet.getString(DB.path_data);

  oConn.close("wb_page_store");

  String sPageSetData = oFS.readfilestr(sFilePageSet, "UTF-8");
    
  sPageSetData = Gadgets.replace(sPageSetData,"</pages>",sTemplateData);

  oFS.writefilestr (sFilePageSet, sPageSetData, "UTF-8");

%>
<script language="JavaScript" type="text/javascript">
<!--
window.opener.document.location.href="wb_document.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=gu_pageset%>&doctype=website"; 
window.close();
-->
</script>
<%@ include file="../methods/page_epilog.jspf" %>