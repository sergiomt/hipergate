<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.SQLException,java.util.Enumeration,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Environment,com.knowgate.workareas.FileSystemWorkArea" language="java" session="false" %>
<%@ include file="../../../../methods/page_prolog.jspf" %><%@ include file="../../../../methods/dbbind.jsp" %><%@ include file="../../../../methods/cookies.jspf" %><%@ include file="../../../../methods/authusrs.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sWrkAPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefWrkArPut);

  int iMaxUpload = Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "2097152"));
  
  String id_domain = getCookie(request,"domainid","");
  String id_user = getCookie(request,"userid","");
  String gu_workarea = getCookie(request,"workarea","");

  String sSep = System.getProperty("file.separator");  
  String sImagesDir = sWrkAPut + sSep + gu_workarea + sSep + "apps" + sSep + "Hipermail" + sSep + id_user + sSep + "images";
  
  File oFile;
  String sFile;
  Enumeration oFileNames;
  long lTotalBytes = 0;
  JDCConnection oCon1 = null;
  Statement oStmt = null;
  Image oImg;

  MultipartRequest oReq;
  FileSystemWorkArea oFileSys;
  
  try {
    oFileSys = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));
    oFileSys.mkdirs("file://" + sWrkAPut + sSep + gu_workarea + sSep + "apps" + sSep + "Hipermail" + sSep + id_user + sSep + "images" + sSep + "thumbs");
    oFileSys = null;

    oReq = new MultipartRequest(request, sImagesDir, iMaxUpload, "UTF-8");
  }
  catch (IOException e) {
    oReq = null;
    if (request.getContentLength()>=iMaxUpload) {
      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", "File size exceeds maximum allowed of " + String.valueOf(iMaxUpload/1024));
      }

      response.sendRedirect (response.encodeRedirectUrl ("../../../../common/errmsg.jsp?title=[~Archivo demasiado grande~]&desc=[~La longuitud del archivo excede el maximo permitido~] " + String.valueOf(iMaxUpload/1024) + "Kb&resume=_back"));
      return;
    }
    else {
      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", e.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../../../../common/errmsg.jsp?title=IOException&desc=" + e.getMessage() + "&resume=_back"));
      return;
    }
  }  
  
  
  oFileNames = oReq.getFileNames();
  
  oCon1 = GlobalDBBind.getConnection("image_upload_store");
     
  try { 
    oCon1.setAutoCommit (false);

    while (oFileNames.hasMoreElements()) {

      // Get original file name as uploaded from client and store it in sFile
      sFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
    
      oFile = new File(sImagesDir + sSep + sFile);
      if (oFile.exists()) lTotalBytes += oFile.length();
    
      oImg = new Image(oCon1, oFile, sImagesDir + sSep + sFile);
      
      oImg.setImagingLibrary(Image.USE_JAI);
      
      oImg.put(DB.gu_writer, id_user);
      oImg.put(DB.gu_workarea, gu_workarea);
      oImg.put(DB.nm_image, sFile);
      
      oImg.put(DB.tp_image, "webbuilder");
      oImg.put(DB.len_file, new Long(lTotalBytes).intValue());
      
      try {      
        if (!oImg.dimensions())
          com.knowgate.debug.DebugFile.writeln("Image.dimensions() Unrecognized graphic file format " + sImagesDir + sSep + sFile);
      }
      catch (Exception e) {
        com.knowgate.debug.DebugFile.writeln(e.getClass().getName() + " " + e.getMessage());
      }

      oImg.store(oCon1);
        
      oFile = null;
                            
    } // wend (oFileNames.hasMoreElements())
      
    oStmt = oCon1.createStatement();
    oStmt.execute("UPDATE " + DB.k_users + " SET " + DB.len_quota + "=" + DB.len_quota + "+" + String.valueOf(lTotalBytes) + " WHERE " + DB.gu_user + "='" + id_user + "'");
    oStmt.close();
    oStmt = null;
    
    oCon1.commit();
    oCon1.close("image_upload_store");
  }
  catch (SQLException sqle) {
    if (oStmt!=null) {
      oStmt.close();
      oStmt = null;
    }
      
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("image_upload_store");      
      }

    oCon1 = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", sqle.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../../../../common/errmsg.jsp?title=Error&desc=" + sqle.getMessage() + "&resume=_close"));
  }
  
  if (null==oCon1) return;
  
  oCon1 = null;
%>
<HTML>
<HEAD>
<TITLE>[~Espere~]...</TITLE>
<SCRIPT TYPE="text/javascript">
  <!--
  window.opener.document.location.reload();
  window.close();
  //-->
</SCRIPT>
</HEAD>
</HTML>
<%@ include file="../../../../methods/page_epilog.jspf" %>