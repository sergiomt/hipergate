<%@ page import="java.lang.System,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Enumeration,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.dfs.FileSystem,com.knowgate.misc.Environment,com.oreilly.servlet.MultipartRequest" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
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

  //if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = com.knowgate.misc.Gadgets.chomp(sTempDir,java.io.File.separator);

  // String sDefWrkArPut = request.getRealPath(request.getServletPath());
  // sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  // sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(java.io.File.separator));
  // sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  // String sWrkAPut = Environment.getProfileVar(GlobalDBBind.getProfileName(), "workareasput", sDefWrkArPut);
  // String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  // String sFileUsr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileuser", "");
  // String sFilePwd = Environment.getProfileVar(GlobalDBBind.getProfileName(), "filepassword", "");
  // String sFileProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  // String sFileServer = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  
  MultipartRequest oReq = new MultipartRequest(request, sTempDir, "UTF-8");

  String id_domain = getCookie(request,"domainid","");
  String id_workarea = getCookie(request,"workarea","");  
  String id_product = oReq.getParameter("id_product");
  String de_product = oReq.getParameter("de_product");
  String n_product = oReq.getParameter("n_product");
  String id_language = oReq.getParameter("id_language");
  String id_user = oReq.getParameter("id_user");
  String id_category = oReq.getParameter("id_category");
  String id_previous_cat = oReq.getParameter("id_previous_cat");
    
  
  Enumeration oFileNames;
  String sFile = null;
  File oTmpFile;
  FileSystem oFileSys = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));
    

    oFileNames = oReq.getFileNames();
  
    while (oFileNames.hasMoreElements()) {
      // Get original file name as uploaded from client and store it in sFile
      sFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
                  
    } // wend(oFileNames.hasMoreElements())
  
    oFileSys = null;
  
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE></HEAD><BODY>OK</BODY></HTML>");
%>
