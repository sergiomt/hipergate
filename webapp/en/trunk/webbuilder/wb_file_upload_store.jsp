<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.Statement,java.sql.SQLException,java.util.Enumeration,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Environment,com.knowgate.workareas.FileSystemWorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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
  String sImagesDir = sWrkAPut + sSep + gu_workarea + sSep + "apps" + sSep + "Mailwire" + sSep + "data" + sSep + "images";
  
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
    
    oFileSys.mkdirs("file://" + sWrkAPut + sSep + gu_workarea + sSep + "apps" + sSep + "Mailwire" + sSep + "data" + sSep + "images" + sSep + "thumbs");
    oFileSys = null;

    oReq = new MultipartRequest(request, sImagesDir, iMaxUpload, "UTF-8");
  }
  catch (IOException e) {

    oReq = null;
    if (request.getContentLength()>=iMaxUpload) {
      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", "File size exceeds maximum allowed of " + String.valueOf(iMaxUpload/1024));
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=File too big&desc=File length exceed maximum allowed " + String.valueOf(iMaxUpload/1024) + "Kb&resume=_back"));
      return;
    }
    else if (nullif(e.getMessage()).equals("Posted content type isn't multipart/form-data")) {
      oReq = null;
    }
    else {
      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "IOException", e.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + e.getMessage() + "&resume=_back"));
      return;
    }
  }  
  
  if (oReq!=null) {
    oFileNames = oReq.getFileNames();
  
    oCon1 = GlobalDBBind.getConnection("fileupload_store");
     
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
      oCon1.close("fileupload_store");
    }
    catch (SQLException sqle) {

      if (oStmt!=null) { oStmt.close(); oStmt = null; }
      
      if (oCon1!=null)
        if (!oCon1.isClosed()) {
          oCon1.rollback();
          oCon1.close("fileupload_store");      
        }

      oCon1 = null;

      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", sqle.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_close"));
    }
    catch (NullPointerException npe) {

      if (oStmt!=null) { oStmt.close(); oStmt = null; }
      
      if (oCon1!=null)
        if (!oCon1.isClosed()) {
          oCon1.rollback();
          oCon1.close("fileupload_store");      
        }

      oCon1 = null;

      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "NullPointerException", npe.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=Archive Format invalid&resume=_close"));
    }
		catch (Exception xcp) {

      if (oStmt!=null) { oStmt.close(); oStmt = null; }
      
      if (oCon1!=null)
        if (!oCon1.isClosed()) {
          oCon1.rollback();
          oCon1.close("fileupload_store");      
        }

      oCon1 = null;

      if (com.knowgate.debug.DebugFile.trace) {
        com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), xcp.getClass().getName(), xcp.getMessage());
      }

      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+xcp.getClass().getName()+"&desc=&resume=_close"));
    }    
  } // fi
  
  if (null==oCon1) return;  
  oCon1 = null;

%><HTML>
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

    if (window.opener) {
    	window.opener.document.location.reload();

<% if (!nullif(request.getParameter("gu_pageset"),"null").equals("null")) { %>
	    window.open ("wb_document.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=request.getParameter("gu_pageset")%>&doctype=<%=request.getParameter("doctype")%>",
	               "editPageSet", "top=" + (screen.height-parseInt(h))/2 + ",left=" + (screen.width-parseInt(w))/2 + ",scrollbars=yes,directories=no,toolbar=no,menubar=no,status=yes,resizable=yes,width=" + w + ",height=" + h);
<% } %>
      window.close();
    } else {
      document.location = "wb_document.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_pageset=<%=request.getParameter("gu_pageset")%>&doctype=<%=request.getParameter("doctype")%>";
    }
  //-->
</SCRIPT>
</HEAD>
</HTML>
<%@ include file="../methods/page_epilog.jspf" %>