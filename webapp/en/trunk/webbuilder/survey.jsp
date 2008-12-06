<%@ page import="java.util.Properties,java.io.File,java.io.IOException,java.io.FileNotFoundException,java.net.URLDecoder,java.sql.SQLException,org.jibx.runtime.JiBXException,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.surveys.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  
  //if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sStyleSheet = "xslt"+File.separator+"templates"+File.separator+"Survey"+File.separator+"Survey.xsl";

  String sDefImgSrv = request.getRequestURI();
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv.substring(0,sDefImgSrv.lastIndexOf("/"));
  sDefImgSrv = sDefImgSrv + "/images"; 
  String sImgSrvr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "imageserver", sDefImgSrv);
       
  String gu_workarea = nullif(request.getParameter("gu_workarea"), getCookie (request, "workarea", null));
  String id_user = getCookie (request, "userid", null);
  String gu_pageset = nullif(request.getParameter("gu_pageset"),"012345678901234567890123456789PS");
  String gu_datasheet = nullif(request.getParameter("gu_datasheet"),Gadgets.generateUUID());
  String pg_page = nullif(request.getParameter("pg_page"), "1");
  String pg_previous = nullif(request.getParameter("pg_previous"), "0");
  
  int iPgPage = Integer.parseInt(pg_page);
  int nPages = 0;
  JDCConnection oConn = null;

  Survey oSrvy = null;
  SurveyPage oPage = null;

%><%@ include file="survey_getpage.jspf" %><%  

  Properties oParams = new Properties();
  oParams.setProperty("workarea", nullif(oSrvy.getStringNull(DB.gu_workarea,null), gu_workarea));
  oParams.setProperty("datasheet", gu_datasheet);
  oParams.setProperty("previous", pg_previous);
  oParams.setProperty("imageserver", sImgSrvr);
  oParams.setProperty("pages", String.valueOf(oSrvy.countPages()));  
  
  String sHtml = oPage.transform(sStorage, sStyleSheet, oParams);
  
  out.write(sHtml);

%><%@ include file="../methods/page_epilog.jspf" %>