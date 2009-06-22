<%@ page import="java.util.*,java.io.*,java.math.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.dataxslt.db.*,com.knowgate.dfs.FileSystem,com.knowgate.misc.*" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
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

  //Recuperar parametros generales
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = request.getParameter("gu_workarea");
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sEnvWorkPut = Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasput", sDefWrkArPut);  
  String sShellDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "shelldir", sStorage + File.separator + "shell");
  
  String sDocType = request.getParameter("doctype");
  String sUrl = "pageset_listing.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")+"&doctype=" + sDocType;  
  String nm_pageset;
  String sXMLFilePage;
  String sHTMLDirPage;
  String sHTMLPath = "";
  
  //Ruta a directorio de almacenamiento de archivos HTML
  if (sDocType.equals("newsletter"))
   sHTMLPath = new String(sEnvWorkPut + File.separator + gu_workarea + File.separator + "apps" + File.separator + "Mailwire" + File.separator + "html");
  else
   sHTMLPath = new String(sEnvWorkPut + File.separator + gu_workarea + File.separator + "apps" + File.separator + "WebBuilder" + File.separator + "html");
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  JDCConnection oCon = null;
  String[] aPKs = new String[1];
  PageSetDB oPageSetDB = new PageSetDB();
  FileSystem oFs = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));
    
  //Recuperar datos de formulario
  String chkItems = request.getParameter("checkeditems");  
  String a_items[] = Gadgets.split(chkItems, ',');
  
  try {
    oCon = GlobalDBBind.getConnection("pageset_edit_delete");
    oCon.setAutoCommit (false);
    
    for (int i=0;i<a_items.length;i++) {
      aPKs[0] = a_items[i];
   
      if (oPageSetDB.load(oCon,aPKs)) {
        nm_pageset = oPageSetDB.getString("nm_pageset");
   
        //Rutas de XML y HTML correspondientes al pageset
        sXMLFilePage = sStorage + oPageSetDB.getString(DB.path_data);
        sHTMLDirPage = sHTMLPath + "/" + a_items[i];
   
        // Eliminar registro de pageset
        oPageSetDB.delete(oCon);

        // Eliminación diferida de archivos y directorios del pageset

        oFs.mkdirs("file://" + sShellDir);
      
        oFs.delete("file://" + sXMLFilePage);
        oFs.delete("file://" + sHTMLDirPage, sShellDir + "/cleanup.txt");
      } // fi
    } // next
  
    // Ejecutar commit y liberar conexión
    oCon.commit();
    oCon.close("pageset_edit_delete");
  }
  catch (SQLException sqle) {
    if (oCon!=null)
      if (!oCon.isClosed()) {
        if (oCon.getAutoCommit()) oCon.rollback();
        oCon.close("pageset_edit_delete");
      }
    oCon = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", sqle.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_back"));
  }
  catch (IOException ioe) {
    if (oCon!=null)
      if (!oCon.isClosed()) {
        if (oCon.getAutoCommit()) oCon.rollback();
        oCon.close("pageset_edit_delete");
      }
    oCon = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", ioe.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "&resume=_back"));
  }
  catch (Exception xcpt) {
    if (oCon!=null)
      if (!oCon.isClosed()) {
        if (oCon.getAutoCommit()) oCon.rollback();
        oCon.close("pageset_edit_delete");
      }      
    oCon = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "Exception", xcpt.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + xcpt.getClass().getName() + "&desc=" + xcpt.getMessage() + "&resume=_back"));
  }

  if (null==oCon) return;
    
  //Vaciar instancias
  oCon = null;
  oPageSetDB = null;
  oFs = null;
  
  if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "", "");
  }

  // Recargar listado
  response.sendRedirect(sUrl);
  
%><%@ include file="../methods/page_epilog.jspf" %>