<%@ page import="java.io.File,java.io.IOException,java.io.FileInputStream,java.net.URL,java.net.URLDecoder,java.sql.SQLException,java.util.Enumeration,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.dfs.chardet.CharacterSetDetector,com.knowgate.workareas.FileSystemWorkArea,com.knowgate.hipermail.HtmlMimeBodyPart" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  final String id_domain = getCookie(request,"domainid","");
  final String id_user = getCookie(request,"userid","");
  final String gu_workarea = getCookie(request,"workarea","");

  final String sSep = File.separator;  

  final int iMaxUpload = Integer.parseInt(GlobalDBBind.getProperty("maxfileupload", "10485760"));

  MultipartRequest oReq = null;
  
  try {
    oReq = new MultipartRequest(request, GlobalDBBind.getProperty("temp"), iMaxUpload, "UTF-8");
  } catch (IOException xcpt) {
    if (xcpt.getMessage().equals("Posted content type isn't multipart/form-data")) {
  	  out.write("<html><body onload=\"top.close()\"></body></html>");
    } else {
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc="+xcpt.getMessage()+"&resume=_topclose"));
    }
  	return;
  }
  
  String nu_mailing = request.getParameter("pg_mailing");
  String gu_pageset = request.getParameter("gu_pageset");

	JDCConnection oConn = GlobalDBBind.getConnection("adhoc_file_upload_store");

	Integer iPgMailing = DBCommand.queryInt(oConn, "SELECT "+DB.pg_mailing+" FROM "+DB.k_adhoc_mailings+" WHERE "+DB.gu_mailing+"='"+gu_pageset+"'");
  if (iPgMailing==null)
    nu_mailing = gu_pageset;
  else
  	nu_mailing = Gadgets.leftPad(iPgMailing.toString(), '0', 5);

  oConn.close("adhoc_file_upload_store");
  
  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut + sSep + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;
	
  URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));
  String sWrkAGet = oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()))+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+gu_workarea+"/apps/Hipermail/html/"+nu_mailing+"/";
  
  String sTargetDir = sWrkAPut + gu_workarea + sSep + "apps" + sSep + "Hipermail" + sSep + "html" + sSep + nu_mailing;

  FileSystemWorkArea oFs = new FileSystemWorkArea(GlobalDBBind.getProperties());
  oFs.mkdirs("file://"+sTargetDir);
  
  File oFile;
  String sFile;
  long lTotalBytes = 0;
  JDCConnection oCon1 = null;
  HtmlMimeBodyPart oHtml;
  
  Enumeration oFileNames = oReq.getFileNames();
       
  try { 
    while (oFileNames.hasMoreElements()) {

      // Get original file name as uploaded from client and store it in sFile
      sFile = oReq.getOriginalFileName(oFileNames.nextElement().toString());
    
      oFile = new File(sTargetDir + sSep + sFile);
      if (oFile.exists())
        oFile.delete();
      else
        lTotalBytes += oFile.length();
    
      if (sFile.endsWith(".htm") || sFile.endsWith(".html") || sFile.endsWith(".HTM") || sFile.endsWith(".HTML")) {
        File fHtml = new File(GlobalDBBind.getPropertyPath("temp")+sFile);
        FileInputStream oInStrm = new FileInputStream(fHtml);
				String sEncoding = new CharacterSetDetector().detect(oInStrm,"ISO-8859-1");
				oInStrm.close();
        oHtml = new HtmlMimeBodyPart (oFs.readfilestr("file://"+GlobalDBBind.getPropertyPath("temp")+sFile,sEncoding),sEncoding);
        fHtml.delete();
      	oFs.writefilestr("file://"+sTargetDir+sSep+sFile, oHtml.addPreffixToImgSrc(sWrkAGet), sEncoding);
      } else {
    	  oFs.move("file://"+GlobalDBBind.getPropertyPath("temp")+sFile, "file://"+sTargetDir+sSep+sFile);
      }
    	
      oFile = null;
                            
    } // wend (oFileNames.hasMoreElements())

    oCon1 = GlobalDBBind.getConnection("fileupload_store");

    oCon1.setAutoCommit (false);
    
    DBCommand.executeUpdate(oCon1, "UPDATE " + DB.k_users + " SET " + DB.len_quota + "=" + DB.len_quota + "+" + String.valueOf(lTotalBytes) + " WHERE " + DB.gu_user + "='" + id_user + "'");
    
    oCon1.commit();
    oCon1.close("fileupload_store");
  }
  catch (SQLException sqle) {
      
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("fileupload_store");      
      }

    oCon1 = null;

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_topclose"));
  }
  catch (NullPointerException npe) {      
    if (oCon1!=null)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("fileupload_store");      
      }

    oCon1 = null;

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=Invalid graphic file format&resume=_topclose"));
  }
  
  if (null==oCon1) return;
  oCon1 = null;

  if (request.getParameter("caller")!=null)
    response.sendRedirect (response.encodeRedirectUrl ("adhoc_mailing_edit.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&pg_mailing="+nu_mailing+"&gu_mailing="+gu_pageset));
  else
  	out.write("<html><body onload=\"top.close()\"></body></html>");
%>