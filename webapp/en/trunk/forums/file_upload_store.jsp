<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.util.Enumeration,com.oreilly.servlet.MultipartRequest,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Environment,com.knowgate.workareas.FileSystemWorkArea" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

  int iMaxUpload = Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760"));
  
  String id_domain = getCookie(request,"domainid","");
  String id_user = getCookie(request,"userid","");
  String gu_workarea = getCookie(request,"workarea","");

  String sSep = System.getProperty("file.separator");  
  String sImagesDir = sWrkAPut + sSep + gu_workarea + sSep + "apps" + sSep + "Forum";
  
  File oFile;
  String sFile;
  Enumeration oFileNames;
  long lTotalBytes = 0;

  MultipartRequest oReq;
  FileSystemWorkArea oFileSys;
  
  try {
    oFileSys = new FileSystemWorkArea(Environment.getProfile(GlobalDBBind.getProfileName()));
    oFileSys.mkdirs("file://" + sWrkAPut + sSep + gu_workarea + sSep + "apps" + sSep + "Forum");
    oFileSys = null;

    oReq = new MultipartRequest(request, sImagesDir, iMaxUpload, "UTF-8");
  }
  catch (IOException e) {
    oReq = null;
    if (request.getContentLength()>=iMaxUpload) {
      if (com.knowgate.debug.DebugFile.trace) {
        DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", "File size exceeds maximum allowed of " + String.valueOf(iMaxUpload/1024));
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File to big&desc=The length of the file exceed the maximum allowed " + String.valueOf(iMaxUpload/1024) + "Kb&resume=_back"));
      return;
    }
    else {
      if (com.knowgate.debug.DebugFile.trace) {
        DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", e.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + e.getMessage() + "&resume=_back"));
      return;
    }
  }  
  
  
  oFileNames = oReq.getFileNames();
       
  try { 

    while (oFileNames.hasMoreElements()) {

      // Get original file name as uploaded from client and store it in sFile
      sFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
    
      oFile = new File(sImagesDir + sSep + sFile);
      if (oFile.exists()) lTotalBytes += oFile.length();        
      oFile = null;
                            
    } // wend (oFileNames.hasMoreElements())
          
  }
  catch (NullPointerException npe) {

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", npe.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=Invalid graphic file format&resume=_close"));
  }  
%>
<HTML>
<HEAD>
<TITLE>Wait...</TITLE>
<SCRIPT TYPE="text/javascript">
  <!--
	  var w,h;
	  
	  switch (screen.width) {
	    case 640:
	      w="620";
	      h="460";
	      break;
	    case 800:
	      w="740";
	      h="560";
	      break;
	    case 1024:
	      w="960";
	      h="700";
	      break;
	    case 1152:
	      w="1024";
	      h="768";
	      break;
	    case 1280:
	      w="1152";
	      h="960";
	      break;
	    default:
	      w="740";
	      h="560";
	  }

    window.opener.document.location.reload();
    window.close();
  //-->
</SCRIPT>
</HEAD>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>