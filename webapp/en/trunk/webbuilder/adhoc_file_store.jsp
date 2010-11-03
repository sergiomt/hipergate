<%@ page import="java.io.File,java.io.IOException,java.net.URL,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.dfs.FileSystem,com.knowgate.hipergate.*,com.knowgate.hipermail.AdHocMailing,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
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

  final String PAGE_NAME = "adhoc_file_edit";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_mailing = request.getParameter("gu_mailing");
  String pg_mailing = request.getParameter("pg_mailing");
  String nm_file = request.getParameter("nm_file");
  String id_encoding = request.getParameter("id_encoding");

  String id_user = getCookie(request, "userid", "");

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(File.separator));
  sDefWrkArPut = sDefWrkArPut + File.separator + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;
	String sWrkGetDir = null;
  String sTargetDir = null;
  String sHtmlSource = request.getParameter("html_src");

  URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));
  AdHocMailing oObj = new AdHocMailing();    
  JDCConnection oConn = null;
  FileSystem oFs = new FileSystem();
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

		oConn.setReadOnly(true);
    
    oObj.load(oConn, new Object[]{gu_mailing});

		if (!oObj.isNull(DB.pg_mailing)) {
      sTargetDir = sWrkAPut + gu_workarea + File.separator + "apps" + File.separator + "Hipermail" + File.separator + "html" + File.separator + Gadgets.leftPad(String.valueOf(oObj.getInt(DB.pg_mailing)), '0', 5);
      sWrkGetDir = oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()))+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+request.getParameter("gu_workarea")+"/apps/Hipermail/html/"+Gadgets.leftPad(String.valueOf(oObj.getInt(DB.pg_mailing)),'0',5)+"/";

      oFs.writefilestr("file://"+sTargetDir+File.separator+nm_file,sHtmlSource,id_encoding);
    } else {
      throw new SQLException("Could not find mailing "+gu_mailing);
    }

    oConn.close(PAGE_NAME);
    

    response.sendRedirect (response.encodeRedirectUrl (sWrkGetDir+nm_file));  

  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.dispose(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
