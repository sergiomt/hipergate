<%@ page import="java.util.zip.ZipEntry,java.util.zip.ZipInputStream,java.io.ByteArrayInputStream,java.io.ByteArrayOutputStream,java.io.File,java.io.FileOutputStream,java.io.IOException,java.net.URL,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.dfs.chardet.CharacterSetDetector,com.knowgate.workareas.FileSystemWorkArea,com.knowgate.hipermail.HtmlMimeBodyPart,com.knowgate.dataxslt.db.PageSetDB,com.knowgate.hipermail.AdHocMailing" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2010  Know Gate S.L. All rights reserved.
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
  
  String gu_microsite = request.getParameter("gu_microsite");
  String gu_pageset = request.getParameter("gu_pageset");

  URL oWebSrv = new URL(GlobalDBBind.getProperty("webserver"));

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut + sSep + "workareas/";
  String sWrkAPut = GlobalDBBind.getPropertyPath("workareasput");
	if (null==sWrkAPut) sWrkAPut = sDefWrkArPut;

  String sHost = oWebSrv.getProtocol()+"://"+oWebSrv.getHost()+(oWebSrv.getPort()==-1 ? "" : ":"+String.valueOf(oWebSrv.getPort()));

  FileSystemWorkArea oFs = new FileSystemWorkArea(GlobalDBBind.getProperties());

	JDCConnection oConn = GlobalDBBind.getConnection("wb_pageset_to_adhoc");
	oConn.setAutoCommit(true);
  
  PageSetDB oPgDb = new PageSetDB(oConn, gu_pageset);
  String sFileName = oPgDb.getFirstPage(oConn).getPage(oConn, GlobalDBBind.getPropertyPath("storage")).getTitle().replace(' ', '_') + ".html";
  Integer iApp = DBCommand.queryInt(oConn, "SELECT "+DB.id_app+" FROM "+DB.k_microsites+" WHERE "+DB.gu_microsite+"='"+oPgDb.getString(DB.gu_microsite)+"'");
  ByteArrayOutputStream oBaOut = new ByteArrayOutputStream();
  oFs.downloadhtmlpage(sHost+"/", Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/").substring(1) + oPgDb.getString(DB.gu_workarea) + "/apps/" + (iApp.intValue()==13 ? "Mailwire" : "WebBuilder") + "/html/" + gu_pageset + "/" + sFileName, oBaOut);
  ByteArrayInputStream oBaZip = new ByteArrayInputStream(oBaOut.toByteArray());
  ZipInputStream oZin = new ZipInputStream(oBaZip);
  oBaOut.close();

  AdHocMailing oAhm = new AdHocMailing();
  oAhm.put(DB.bo_plain_part, (short) 0);
	oAhm.put(DB.bo_html_part , (short) 1);
  oAhm.put(DB.bo_attachments,(short) 1);
  if (oPgDb.isNull(DB.bo_urgent))
    oAhm.put(DB.bo_urgent,(short) 0);
	else
    oAhm.put(DB.bo_urgent,oPgDb.getShort(DB.bo_urgent));
  if (!oPgDb.isNull(DB.id_status))
    oAhm.put(DB.id_status,oPgDb.getString(DB.id_status));
  oAhm.put(DB.gu_writer, id_user);
  oAhm.put(DB.gu_workarea, oPgDb.getString(DB.gu_workarea));
  oAhm.put(DB.nm_mailing, Gadgets.left(oPgDb.getString(DB.nm_pageset)+"*",30));
  oAhm.store(oConn);
  
  String nu_mailing = Gadgets.leftPad(String.valueOf(oAhm.getInt(DB.pg_mailing)), '0', 5);

  oConn.close("wb_pageset_to_adhoc");
	
  String sWrkAGet = sHost+Gadgets.chomp(GlobalDBBind.getProperty("workareasget"),"/")+gu_workarea+"/apps/Hipermail/html/"+nu_mailing+"/";
  
  String sTargetDir = sWrkAPut + gu_workarea + sSep + "apps" + sSep + "Hipermail" + sSep + "html" + sSep + nu_mailing;
  
  oFs.mkdirs("file://"+sTargetDir);
  
  String sFile = "";
  long lTotalBytes = 0;
  HtmlMimeBodyPart oHtml;
  int iReaded = 0;
  byte[] aEntry = null;
  
  try {
    ZipEntry oEntry;
    while ((oEntry=oZin.getNextEntry())!=null) {
			
      // Get original file name as uploaded from client and store it in sFile
      sFile = oEntry.getName();
    
      File oFile = new File(sTargetDir + sSep + sFile);
      if (oFile.exists()) oFile.delete();
      oFile = null;
      
      aEntry = new byte[oEntry.getSize()>0 ? (int) oEntry.getSize() : 4194304];
			iReaded = oZin.read(aEntry, 0, aEntry.length);
			int iRead;
			if (iReaded>0) {
			  while ((iRead=oZin.read(aEntry, iReaded, aEntry.length-iReaded))!=-1) {
			    iReaded += iRead;
			    if (iReaded>=aEntry.length) throw new IOException("The length of zipped files exceed the maximum allowed of 4Mb"); 
			  }			
			  lTotalBytes += iReaded;
        if (sFile.endsWith(".htm") || sFile.endsWith(".html") || sFile.endsWith(".HTM") || sFile.endsWith(".HTML")) {
          ByteArrayInputStream oBaEntry = new ByteArrayInputStream(aEntry,0,iReaded);
				  String sEncoding = new CharacterSetDetector().detect(oBaEntry,"UTF-8");
				  oBaEntry.close();
          oHtml = new HtmlMimeBodyPart (new String(aEntry,0,iReaded,sEncoding),sEncoding);
      	  oFs.writefilestr("file://"+sTargetDir+sSep+sFile, oHtml.addPreffixToImgSrc(sWrkAGet), sEncoding);
        } else {
 				  FileOutputStream oOutStrm = new FileOutputStream(sTargetDir+sSep+sFile);
          oOutStrm.write(aEntry,0,iReaded);
          oOutStrm.close();
        }
      }
      oZin.closeEntry();
      
    } // wend (available())
		oZin.close();
		oBaZip.close();

    oConn = GlobalDBBind.getConnection("wb_pageset_to_adhoc");
    oConn.setAutoCommit (true);
    DBCommand.executeUpdate(oConn, "UPDATE " + DB.k_users + " SET " + DB.len_quota + "=" + DB.len_quota + "+" + String.valueOf(lTotalBytes) + " WHERE " + DB.gu_user + "='" + id_user + "'");
    oConn.close("wb_pageset_to_adhoc");
  }
  catch (IndexOutOfBoundsException aiob) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("wb_pageset_to_adhoc");      
      }

    oConn = null;

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IndexOutOfBoundsException&desc=" + sFile + " ("+ String.valueOf(iReaded) + ")&resume=_topclose"));
  
  }
  catch (IOException ioe) {
      
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("wb_pageset_to_adhoc");      
      }

    oConn = null;

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "&resume=_topclose"));
  }
  catch (SQLException sqle) {
      
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("wb_pageset_to_adhoc");      
      }

    oConn = null;

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_topclose"));
  }
  catch (NullPointerException npe) {      
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("wb_pageset_to_adhoc");      
      }

    oConn = null;

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=The format of the graphic file is not valid&resume=_topclose"));
  }
  
  if (null==oConn) return;
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("adhoc_mailing_edit.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&pg_mailing="+nu_mailing));
%>